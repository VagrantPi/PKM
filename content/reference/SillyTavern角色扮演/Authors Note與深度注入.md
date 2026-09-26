---
type: reference
name: "Author's Note 與深度注入 Depth Injection"
source: "[[SillyTavern 角色扮演系統技術文件]]"
source_type: docs
tags: [ai, llm, roleplay, sillytavern, authors-note, depth-injection, extension-prompts]
triggers: [寫在系統提示的規則聊久了 AI 就忘了, 想臨時改變劇情氛圍又不想改角色卡, 摘要或記憶檢索結果要插在 prompt 哪裡, 多個外掛都想往 prompt 裡塞東西, 想讓某句指令靠近 AI 回答的位置]
---

## 🎯 什麼情境該想到我
當你「發現寫在最前面的指令，聊了幾十輪後 AI 就不理了，想把提醒插到靠近最新訊息的地方」的時候。

## ⚙️ 怎麼用

### Author's Note 是什麼：浮動提示
Author's Note（AN，作者註）是一段**不固定在 prompt 開頭**、而是**注入在聊天歷史特定深度**的提示。它讓你不修改角色卡就能影響 AI 的行為，典型內容像：
- 「場景轉換到夜晚」
- 「增加描述細節」
- 「讓角色表現得更警覺」

**為什麼放在聊天歷史中間？** 模型對**離當前生成位置越近**的內容關注度越高。系統提示放在最前面，聊天一長就被幾千 token 的對話隔開；AN 則永遠跟著聊天的尾巴走，距離生成點始終只差固定幾則訊息。

### AN 的參數

| 參數 | 例 | 意義 |
|------|----|------|
| `prompt` | 「增加描述細節」 | 注入內容 |
| `depth` | 4 | 從聊天底部往上數第幾則的位置插入 |
| `interval` | 1 | 每幾則使用者訊息插入一次 |
| `position` | 0 / 1 / 2 | 0 = 場景後、1 = 聊天中（in-chat）、2 = 場景前 |
| `role` | 0 / 1 / 2 | 0 = system、1 = user、2 = assistant |
| `allowWIScan` | false | 是否讓 World Info 掃描 AN 內容找關鍵詞 |

**depth 怎麼數**：depth=4 表示「AN 之後還有 4 則訊息」。以 7 則聊天為例：

```
Message 1 (最舊)
Message 2
Message 3
  ← AN 注入在這裡 (depth=4)
Message 4
Message 5
Message 6
Message 7 (最新)
```

depth=0 就是貼在最後一則訊息之後，最接近生成點、影響力最強也最容易「喧賓奪主」。

★ `interval` 的用意（推測）：不必每輪都插，讓提示「間歇提醒」，減少模型把它當作對話內容而照抄的機會。
★ `allowWIScan` 預設關閉（推測理由）：AN 常寫著劇情關鍵字，若讓 WI 掃它，可能每輪都觸發同一批設定條目。

### 角色專屬 AN 與全域 AN 的合成
每個角色可有自己的 AN，與全域 AN 的關係由 `chara_note_position` 決定：

| 值 | 模式 | 結果 |
|----|------|------|
| 0 | replace | 只用角色 AN，全域 AN 被忽略 |
| 1 | before | 角色 AN 在前、全域 AN 在後 |
| 2 | after | 全域 AN 在前、角色 AN 在後 |

例：全域 AN「增加描述細節」＋ 角色 AN「Alice 總是用比喻說話」，選 before 時兩句都會出現，角色那句在上。

### 與 World Info 合成一個區塊
World Info 條目可以指定 `position=ANTop(2)` 或 `ANBottom(3)`，與 AN 本體組成一個**合成區塊**：

```
[WI 條目 (position=ANTop)]      ← 在 AN 之上
[Author's Note 內容]             ← AN 本體
[WI 條目 (position=ANBottom)]   ← 在 AN 之下
```

★ 這讓 WI 的動態內容可以「搭便車」進入 AN 的高注意力位置——被關鍵詞觸發的設定，不必擠在 prompt 前段被遺忘。

### Extension Prompts：通用注入框架
AN 其實只是 Extension Prompts 中的一種。Extension Prompts 是一個通用機制，讓各擴展以一個 **key** 註冊內容，並指定注入位置：

| 位置類型 | 值 | 說明 | 使用情境 |
|----------|---|------|---------|
| NONE | -1 | 不自動注入（outlet 模式） | 只供 `{{outlet::key}}` 讀取 |
| IN_PROMPT | 0 | 放在 prompt 區段中（scenario 前後） | 靜態的系統級指令 |
| IN_CHAT | 1 | 聊天歷史的特定深度（配 depth、role） | 動態上下文指引 |
| BEFORE_PROMPT | 2 | 整個 prompt 之前 | 最高優先級指令 |

已知的 key：

| Key | 來源 | 用途 | 典型位置 |
|-----|------|------|---------|
| `1_memory` | Summarize | 聊天摘要 | IN_PROMPT |
| `2_floating_prompt` | Author's Note | 浮動提示 | IN_CHAT（depth=4） |
| `3_vectors` | Vectors | 向量記憶搜尋結果 | IN_PROMPT |
| `4_vectors_data_bank` | Data Bank | 向量資料庫搜尋結果 | IN_PROMPT |
| `chromadb` | ChromaDB | 智慧上下文 | IN_PROMPT |
| `PERSONA_DESCRIPTION` | 人設系統 | 使用者角色描述 | IN_PROMPT |
| `QUIET_PROMPT` | 系統內部 | 靜默提示（不顯示於 UI） | 末尾 |
| `DEPTH_PROMPT` | 角色卡 | 角色的深度提示 | IN_CHAT |

★ 設計重點：把「誰要注入」和「注入到哪」解耦。摘要、向量記憶、人設、AN 各自只管產生文字與宣告位置，組裝器統一處理。要新增一種記憶來源，不必改組裝流程。

### IN_CHAT 深度注入的演算法（`doChatInject`）
1. 把聊天歷史**反轉**（最新在前），此時陣列索引剛好等於 depth；
2. 從 depth=0 跑到 maxDepth，每一層收集所有 depth=i 的注入；
3. 同一深度有多筆時，依角色優先序 **SYSTEM → USER → ASSISTANT** 排列，插到位置 i；
4. 再把聊天歷史**反轉回來**。

反轉的好處：depth 是「從底部數」的概念，反轉後直接用索引插入，不用每次拿長度去換算。

### 固定位置 vs 深度注入：怎麼選

| 考量 | 固定位置（IN_PROMPT） | 深度注入（IN_CHAT） |
|------|---------------------|-------------------|
| 模型注意力 | 離生成點遠，較低 | 可貼近生成點，較高 |
| 穩定性 | 永遠在同一位置 | 位置隨聊天長度浮動 |
| 適合 | 角色定義、世界觀 | 情境提示、行為指引 |
| 被裁切風險 | 低（固定內容先放入預算） | 有（聊天歷史太長時） |

經驗法則：**「是什麼」放固定位置，「現在要怎樣」放深度注入**。

## ⚠️ 注意 / 什麼時候不適用
- **depth 太淺會壓過對話本身**：depth=0 的強指令可能讓每則回覆都在呼應它，失去自然感；先從 depth 3–5 試。
- **role 選 user/assistant 可能有副作用**（經驗推論，非原文件結論）：模型可能把它當成真實對話的一部分而回應或模仿；中性的指令用 system 較安全（但部分 API 對聊天中段的 system 訊息支援度不同，需實測）。
- **深度注入跟著聊天被裁切**：Token 預算不足時聊天從舊的砍起，注入點附近的訊息若被砍，位置會移動；極端情況下整段聊天放不下時注入也沒地方放。
- **多個擴展同時 IN_CHAT 注入同一深度**會擠在一起，順序只依角色優先序決定，彼此的前後關係不一定是你要的。
- 原文件中 AN 的 `position=2` 描述為「場景前」，而 Extension Prompts 的值 2（BEFORE_PROMPT）描述為「整個 prompt 之前」，兩處說法不一致，實作前以程式碼為準。

## 🧪 我實際套用的紀錄
- （尚無）

## 🔗 相關
- [[World Info世界書]]——ANTop/ANBottom/atDepth 三種位置與 AN 合成
- [[Token預算管理]]——IN_CHAT 注入會隨聊天被裁切
- [[宏系統]]——`{{outlet::key}}` 讀取 NONE 位置的擴展內容
- [[長期記憶三層架構]]——摘要（`1_memory`）與向量記憶（`3_vectors`）就是透過此框架注入
- [[場景與故事走向控制]]——AN 是控制劇情走向最常用的方向盤
