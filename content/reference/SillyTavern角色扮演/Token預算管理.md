---
type: reference
name: "Token 預算管理 Token Budget"
source: "[[SillyTavern 角色扮演系統技術文件]]"
source_type: docs
tags: [ai, llm, roleplay, sillytavern, token-budget, context-window]
triggers: [聊天越聊越長 prompt 超過模型上限, 不知道舊訊息該從哪裡開始砍, 固定提示和聊天紀錄要怎麼分配空間, 某些控制訊息一定要塞得進去不能被擠掉, 不同模型同一段字 token 數差很多]
---

## 🎯 什麼情境該想到我
當你「要把角色設定、世界觀、聊天紀錄全擠進一個有限的 context window，還得決定誰先被犧牲」的時候。

## ⚙️ 怎麼用

### 問題定義：一個固定大小的箱子
每個模型有固定 context window（例如 8K、128K tokens）。系統提示、角色描述、World Info、聊天歷史全部要塞進去，**還要替模型的回應留位置**。所以第一步永遠是：

```
可用空間 = max_context − max_tokens(回應長度)
例：8192 − 300 = 7892
```

可用空間再分給三類內容：
- **固定 prompts**：main、角色描述、個性、場景、使用者人設、WI、jailbreak 等——定義角色，不能少；
- **聊天歷史**：填滿剩下的空間；
- **控制訊息**：`[Start a new Chat]`、群組引導（Group Nudge）、Tool Calling 等。

★ 設計原則：**固定的先放、可伸縮的後放、必須出現在特定位置的先預留**。

### Chat Completion 路徑：Reserve → Add → Fill → Free

#### 為什麼不能從前往後依序塞？
控制訊息必須出現在**固定位置**——`[Start a new Chat]` 要在聊天歷史之前、群組引導在聊天歷史之後、控制提示在最末。但它們的 token 數必須在聊天歷史填充**之前**就被算進去；否則聊天歷史會把空間吃光，控制訊息就放不進去了。解法是先「佔位」（只扣額度、不放內容），等聊天填完再把佔位釋放、把真內容插到正確位置。

#### 四個階段
1. **Reserve（預留）**：先扣掉之後一定要放的東西——每則 assistant 回應的格式標記（3）、控制提示（impersonate / quiet / continue）、`[Start a new Chat]`（分隔對話範例與正式聊天）、群組引導（如 `[Write the next reply only as Alice.]`）、工具定義與呼叫空間。
2. **Add（加入固定內容）**：依序加入 main、worldInfoBefore、personaDescription、charDescription、charPersonality、scenario、worldInfoAfter、jailbreak。任何一項超過剩餘預算 → 拋出 `TokenBudgetExceededError`。
3. **Fill（填聊天）**：把所有聊天訊息**從最新往舊**逐則放入，放不下就停。這是 LIFO：最新的最先保留。
4. **Free + Insert（釋放並歸位）**：釋放 newChat 的預留、把它插到聊天歷史開頭；釋放 groupNudge、插到聊天歷史結尾；釋放控制提示、加到最後。

### 算一次帳（worked example）
設定：`max_context = 8192`、`max_tokens = 300`，可用 7892。

| 階段 | 項目 | 扣除 | 剩餘 |
|------|------|-----:|-----:|
| 初始 | | | 7892 |
| Reserve | 助理回應標記 | 3 | 7889 |
| | controlPrompts | 130 | 7759 |
| | newChat | 9 | 7750 |
| | groupNudge | 15 | 7735 |
| | toolTokens | 200 | **7535** |
| Add | main | 150 | 7385 |
| | worldInfoBefore | 800 | 6585 |
| | charDescription | 200 | 6385 |
| | charPersonality | 100 | 6285 |
| | scenario | 80 | 6205 |
| | personaDescription | 50 | 6155 |
| | worldInfoAfter | 800 | 5355 |
| | jailbreak | 100 | **5225** |
| Fill | Message 10（最新） | 150 | 5075 ✓ |
| | Message 9 | 200 | 4875 ✓ |
| | Message 8 | 180 | 4695 ✓ |
| | …（7、6） | | |
| | Message 5 | 190 | **394** ✓ |
| | Message 4 | 500 | ✗ 超出 → 停止 |
| Free+Insert | free(newChat) / insert | +9 / −9 | 394 |
| | free(groupNudge) / insert | +15 / −15 | 394 |
| | free(control) / add | +130 / −130 | **394** |

自己驗算幾個關鍵數字：
- Reserve 共 3+130+9+15+200 = **357**，7892 − 357 = 7535 ✓
- Add 共 150+800+200+100+80+50+800+100 = **2280**，7535 − 2280 = 5225 ✓
- Fill 用掉 5225 − 394 = **4831**，放進了 Message 10 到 5 共 6 則（10、9、8、5 已知為 150+200+180+190 = 720，推得 7、6 兩則合計 4111）
- 最終：7892 − 394 = **7498** 已使用；7498 + 300（回應）+ 394（緩衝）= 8192 ✓

★ 從帳上可以看出：Free+Insert 階段的淨值永遠為零——因為預留時已經扣過，它只是「把佔位換成真內容並移到正確位置」。預留的價值在於 Fill 階段**不會**把那 154 tokens（9+15+130）當成可用空間拿去塞聊天。
★ 另一個觀察：兩段 WI 共 1600 tokens，佔固定內容 2280 的七成。WI 若不另設上限，會直接吃掉聊天記憶的空間——這就是下面 WI 獨立預算存在的理由。

### Text Completion 路徑：反覆修剪
Text Completion 用更簡單的策略——先全放，超過再砍：

```
loop:
  total = storyString + examples + chatHistory + cache
  if total <= max_context: 完成
  elif 還有對話範例: 移除一條對話範例
  elif 還有聊天訊息: 移除最舊的一條聊天訊息
  else: 無法再刪，強制送出
```

| 刪除順序 | 理由 |
|----------|------|
| 1. 對話範例 | 只是 few-shot 示範，拿掉後模型仍能從角色定義理解角色 |
| 2. 最舊的聊天訊息 | 近期脈絡比遠期脈絡重要 |
| 永不刪除 | Story String（角色定義）是基礎 |

兩條路徑的差別：Chat Completion 是「先算好額度再逐項放」（加法），Text Completion 是「全放再逐項減」（減法），但保護優先序一致：角色定義 > 近期聊天 > 範例／遠期聊天。

### World Info 的獨立預算
WI 有自己的額度，與主預算分開計算：

```
WI 預算 = max_context × world_info_budget%
若 world_info_budget_cap > 0：WI 預算 = min(上式, cap)
例：8192 × 25% = 2048 tokens
```

激活時逐條累計：A 300（累計 300 ✓）→ B 500（800 ✓）→ C 800（1600 ✓）→ D 600（2200 ✗ 超過 2048，不激活）→ E 400 但 `ignoreBudget=true`（不受限 ✓）。

| 設定 | 預設 | 說明 |
|------|------|------|
| `world_info_budget` | 25 | 佔 max_context 的百分比 |
| `world_info_budget_cap` | 0 | 絕對上限，0 表示只看百分比 |
| `entry.ignoreBudget` | false | 單條可無視預算 |

### Tokenizer：計數本身就是變數
同一段文字在不同分詞器下 token 數可能差很多，所以預算一定要用**目標模型的 tokenizer** 算：

| Tokenizer | 對應 | 備註 |
|-----------|------|------|
| OPENAI | GPT-3.5/4 | tiktoken 系列 |
| CLAUDE | Claude | WebTokenizer |
| LLAMA3 | Llama 3 | WebTokenizer |
| MISTRAL | Mistral | SentencePiece |
| BEST_MATCH | 自動 | 依目前 API 與模型選擇 |
| NONE | 後備 | 粗估每 3.35 字元 ≈ 1 token |

Token 計數是高頻操作（每次組 prompt 要算數十次），因此用 per-chat 快取：key = tokenizer 類型 + 字串 hash + 模型 hash + padding，存在瀏覽器本地（localforage）。

## ⚠️ 注意 / 什麼時候不適用
- **固定內容太大會直接失敗**：Add 階段超額是拋錯，不是自動裁切。角色卡＋WI 過肥時，聊天歷史會被壓到只剩幾則甚至放不下。
- **LIFO 是硬切**：Message 4 放不下就整則丟掉，不會截半；後面更舊但更短的訊息也不會被撿回來（Fill 遇到第一個放不下的就停止）。被砍掉的遠期記憶要靠摘要或向量記憶補回。
- **NONE 的 3.35 字元估法對中文很不準**，中文一個字常常就是一個以上 token；上線產品應接真實 tokenizer。
- **剩餘緩衝不等於浪費**：例子裡最後剩 394，是因為下一則訊息 500 太大；緩衝大小取決於訊息粒度。
- 原文件的階段圖把 personaDescription 排在 main 之後，數值範例卻把它排在 scenario 之後；總和不受影響，但實際順序以程式為準。

## 🧪 我實際套用的紀錄
- （尚無）

## 🔗 相關
- [[World Info世界書]]——WI 預算如何影響條目激活
- [[Authors Note與深度注入]]——深度注入的內容會隨聊天被裁而移動或消失
- [[生成類型]]——impersonate / continue / quiet 對應的控制提示預留
