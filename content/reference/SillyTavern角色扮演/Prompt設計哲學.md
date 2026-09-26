---
type: reference
name: "Prompt 設計哲學 Prompt Design Philosophy"
source: "[[SillyTavern 角色扮演系統技術文件]]"
source_type: docs
tags: [ai, llm, roleplay, sillytavern, prompt-engineering, attention]
triggers: [角色扮演的prompt各段該怎麼排先後, 放在中間的設定模型好像都沒在看, 模型把範例對話當成真的聊天內容, 群聊時模型一次扮演好幾個角色, 想讓模型代替使用者寫下一句]
---

## 🎯 什麼情境該想到我
當你「要設計一個角色扮演 prompt 的結構——每段放什麼、依什麼順序、用什麼格式包裝、控制指令怎麼跟對話內容分開」的時候。

## ⚙️ 怎麼用

### 根本原則：prompt 是一場戲的舞台指令

模型沒有真正的記憶或理解，它只根據 prompt 預測下一個 token。所以設計問題只有一個：**在有限 token 預算內，資訊怎麼擺，最能讓模型生成想要的回覆**。SillyTavern 的 prompt 可以用劇場來理解：

| 劇場角色 | prompt 區段 | 說的是 |
|---|---|---|
| 導演指令 | Main Prompt | 你要演誰、怎麼演 |
| 佈景 | Description、Scenario | 場景與角色是什麼 |
| 劇本參考 | Dialogue Examples | 以前類似場景怎麼演 |
| 過往場次 | Chat History | 剛才發生了什麼 |
| 耳語提示 | Jailbreak / Author's Note | 接下來該怎麼演 |

### 兩條格式路線：為什麼不統一

| | Chat Completion | Text Completion |
|---|---|---|
| 代表 | OpenAI、Claude、Gemini | KoboldAI、llama.cpp |
| 輸入 | `[{role, content}, …]` | 一整段字串 |
| 角色區分 | API 原生 `system/user/assistant` | 靠標記（如 `<\|im_start\|>user`） |
| 誰負責格式化 | API 伺服器 | 本地（SillyTavern） |
| 排序機制 | PromptManager（可拖曳） | Context 預設＋Instruct 預設 |

兩種 API 的輸入本質不同，硬統一只會讓其中一邊變差，所以各走各的設計。

### Chat Completion：「每個意圖一個 message」

每個區段是一條帶 identifier 的獨立 message，預設順序：

```
main → worldInfoBefore → personaDescription → charDescription → charPersonality
→ scenario → enhanceDefinitions(預設停用) → nsfw → worldInfoAfter
→ dialogueExamples → chatHistory(user/assistant) → jailbreak
```

**為什麼這個順序？** 依據注意力分布：開頭高（首因效應）、中段容易被忽略、結尾最高（近因效應）。

| 位置 | 放什麼 | 理由 |
|---|---|---|
| 最前 | Main Prompt | 開頭的指令替整個生成「定調」 |
| 前段 | 角色描述、個性、場景 | 需要持續遵循的靜態資訊 |
| 中段 | World Info、對話範例 | 補充資訊，部分被忽略也不致命 |
| 後段 | 聊天歷史 | 模型會自然銜接最近脈絡 |
| 最末 | Jailbreak / Post-History Instructions | 最後說的話影響最大，行為控制放這裡 |

### 預設提示逐句拆解

**Main Prompt**
```
Write {{char}}'s next reply in a fictional chat between {{charIfNotGroup}} and {{user}}.
```
- `Write {{char}}'s next reply`：任務是**寫角色的下一句**，不是摘要或分析。
- `fictional chat`：建立虛構框架，這是創作。
- `between … and {{user}}`：講清楚參與者，避免角色混淆。
- 為什麼只有一句？★ **預設極簡、自訂極大**——Main Prompt 是最常被改寫的區段，預設不該替使用者做決定。

**NSFW / Auxiliary Prompt**：預設空。通用工具不預設內容方向，這格留給任何額外規則。

**Jailbreak / Post-History Instructions**：預設空。名稱源自 GPT-3.5 時代用來繞過限制；實際功能是「聊天歷史之後、生成之前的最後一條指引」。想強制格式或行為，放這裡最有效。

**Impersonation Prompt**（讓模型替使用者寫）
```
[Write your next reply from the point of view of {{user}}, using the chat history
so far as a guideline for the writing style of {{user}}. Don't write as {{char}}
or system. Don't describe actions of {{char}}.]
```
模型預設行為是「以角色身分生成」，切換視角違反慣性，所以要用**多重否定**（Don't…）把預設行為壓下去，並要求模仿使用者**先前的文風**而不是模型自己的預設文風。

**Continue Nudge**：`[Continue your last message without repeating its original content.]`——少了 `without repeating`，模型傾向把整段重寫一次。

**Group Nudge**：`[Write the next reply only as {{char}}.]`——群聊 prompt 裡有多個角色描述，沒有 `only` 模型可能一次演好幾個人。

**New Chat / New Example Chat**：`[Start a new Chat]`、`[Example Chat]`——邊界標記，把對話範例和真實聊天隔開，避免模型把範例當成已發生的事。

### 方括號 `[]` = 元語言邊界

所有控制指令都包在 `[]` 裡，這是 roleplay 社群長期形成的慣例：訓練資料裡常見 `[instruction]` 格式；方括號內的字不會被當成角色台詞；清楚劃出「系統指令 vs 角色對話」的界線。對比：`Alice: Hello there!` 會被當成要延續的對話，`[Write the next reply only as Alice.]` 會被當成要遵守的規則。

### squash：合併連續 system message

部分 API（尤其 OpenAI）對一連串 system message 處理不佳，可能忽略中間幾條，每條 message 也有額外 overhead。所以把連續的 system message 合併成一條——**但分隔符不合併**：`newMainChat`（分隔範例與真實聊天）、`newChat`（分隔不同範例組）、`groupNudge`（必須獨立出現在聊天末尾）。合併省 token，分隔符保住語義邊界。

### Text Completion：「模擬一段連續文本」

模型只看到一段文字，prompt 必須像一段能自然往下寫的文本。

**Story String**（Handlebars）：
```handlebars
{{#if system}}{{system}}\n{{/if}}
{{#if description}}{{description}}\n{{/if}}
{{#if personality}}{{char}}'s personality: {{personality}}\n{{/if}}
{{#if scenario}}Scenario: {{scenario}}\n{{/if}}
{{#if persona}}{{persona}}\n{{/if}}
```
- `{{#if}}`：欄位空就整段不輸出，不留多餘空行。
- **為什麼 personality 加標籤、description 不加？** description 通常是完整敘述句（"Alice is a cheerful tavern waitress…"），自帶語義；personality 常是關鍵字列表（"cheerful, energetic, kind"），沒有 `Alice's personality:` 前綴，模型不知道這串詞是什麼。scenario 是獨立背景，也需要 `Scenario:` 區隔。

**Instruct Mode：為什麼要特殊標記**。模型訓練時用特定標記區分發言者；少了它，`Alice: 你好！\nBob: 嗨！\nAlice:` 可能被當成故事敘述而非待補全的對話。

| 預設 | 標記 | 來源 |
|---|---|---|
| ChatML | `<\|im_start\|>role … <\|im_end\|>` | OpenAI |
| Llama 3 | `<\|start_header_id\|>role<\|end_header_id\|> … <\|eot_id\|>` | Meta |
| Alpaca | `### Instruction:` / `### Response:` | Stanford Alpaca |

★ 用錯標記＝模型看不懂對話結構＝品質大幅下降。標記必須配合模型訓練格式。

**Story String 位置**：`IN_PROMPT`（0）放最前當舞台設定；`IN_CHAT`（1）像 Author's Note 一樣浮動在聊天中，利用近因效應讓模型回答前再看一次角色設定，適合要求角色高度一致的情境。

### 格式模板：CC 不加前綴、TC 要加前綴

Chat Completion 的 `personality_format`、`scenario_format` 預設就是 `{{personality}}`、`{{scenario}}`，`wi_format` 是 `{0}`（可改成 `[World Info: {0}]`）。**為什麼不加前綴？** message 結構本身就帶語義，每段已是獨立 message 並有 identifier，再寫 "Scenario:" 是冗餘。Text Completion 則全部混在一段文字裡，標籤是唯一的語義線索。

### 深度注入：避開「中段低注意力區」

不放在 prompt 的絕對位置，而是放在**距離最後一則訊息的相對位置**——無論聊天多長，指令都在注意力範圍內。

| depth | 位置 | 適合 |
|---|---|---|
| 0 | 緊接最後一則訊息 | 最強的即時指令 |
| 1–2 | 最近 1–2 輪之間 | 強烈行為引導 |
| 4（預設） | 最近 4 輪之間 | 溫和背景引導 |
| 8+ | 更早的歷史中 | 淡化的背景資訊 |

### 比 prompt 更底層的控制

- **Logit Bias**：把字 tokenize 成 ID，放進 `logit_bias` 參數直接調機率。預設 anti-bond bias：`bond -50、future -50、bonding -50、connection -25`，壓制某些模型過度使用「羈絆」類詞彙的偏差。
- **Assistant Prefill**：在 messages 末尾放一條 `{role: "assistant", content: "Alice:"}`，模型會順著這個開頭接寫——群聊時用來明確「現在是誰在說話」。
- **send_if_empty**：歷史最後一條是 assistant 時，有些 API 要求有 user message 才肯繼續，自動補一條避免報錯。

### 六條設計總結

1. **分離關注點**：一段只負責一個語義目的。
2. **利用注意力分布**：重要的放頭尾，補充的放中間。
3. **預設極簡、自訂極大**。
4. **元指令邊界清晰**：`[]` 包系統指令。
5. **漸進式引導**：你是誰 → 世界長怎樣 → 發生了什麼 → 接下來做什麼。
6. **多層防護**：prompt 文字引導＋token 級控制（bias / banned tokens）＋回覆後過濾。

## ⚠️ 注意 / 什麼時候不適用

- 「首因／近因、中段被忽略」是經驗性的注意力假設，不同模型差異大；排序要實測，不是定理。
- 末尾指令影響最強，也最容易讓回覆變得生硬或一直重複那條指令的內容。
- `[]` 慣例對 roleplay 微調過的模型最有效；對某些模型，方括號內文字仍可能被當成內容輸出，要搭配 [[正則替換引擎]] 事後清理。
- Instruct 標記必須跟模型對應；換模型沒換 Instruct 預設，是 Text Completion 品質崩壞最常見的原因。
- Prefill 並非所有 Chat Completion API 都支援 assistant 結尾的 messages。
- Logit Bias 是以 token 為單位，禁一個英文詞不代表禁掉它的所有變形或其他語言的同義詞。

## 🧪 我實際套用的紀錄
- （尚無）

## 🔗 相關
- [[工具-提示工程]] — 通用 prompt 技巧；本卡是角色扮演場景的具體化
- [[提示覆蓋與系統提示預設]] — 預設提示如何被覆寫與排序
- [[Authors Note與深度注入]] — 深度注入的機制
- [[Token預算管理]] — 有限預算下的取捨
- [[場景與故事走向控制]] — 同一套位置原則用在劇情引導
