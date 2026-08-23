---
type: article
title: "Claude Code 隱藏設定分析 v2.1.239"
source_url: https://github.com/charliie-dev/claude-code-hidden-settings/blob/main/claude-code-hidden-settings-2.1.239.md
author: charliie-dev
site: GitHub
tags: [ai, llm, tooling, security, methodology]
captured: 2026-08-23
read_status: read
---

## 📌 30 秒摘要（讀完用自己的話寫一句）
> 這篇在講：有人把 Claude Code `2.1.239` 的**執行檔拆開**，比對官方文件與 JSON schema，找出**234 個「binary 讀得到、公開文件查不到」的環境變數**，並用**假 API 差分測試**驗證其中哪些真的會改變送給模型的 system prompt。最有價值的不是那份名單，是它建立的兩件事：**一套嚴謹的證據分級**，和**「`=0` 到底關不關得掉」的判讀規則**。

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- 我天天在用 Claude Code，但**官方文件只講「有什麼設定」，不講「這些設定怎麼互相蓋過」**。這篇補的正是那層。
- 它把「agent 為什麼會有這些內建行為」攤開來——我常覺得被某些內建提醒綁手綁腳，這篇給了**可操作的關法**，以及**哪些根本關不掉**。
- 方法論可以搬走：用 loopback 假 API 做差分測試，能驗證任何 CLI 到底送了什麼出去。這對我驗證 skill 有沒有真的進到 prompt 很有用。

## 🧰 這篇給我的工具（連到 tools/ 工具卡）
- [[工具-關掉ClaudeCode塞給模型的提醒]] — 當我覺得「agent 被內建提醒綁手綁腳、想關掉」的時候
- [[工具-ClaudeCode未文件化設定的取捨]] — 當我「想用文件沒寫的設定，但不確定該不該碰」的時候
- [[工具-用假API差分測試逆向CLI行為]] — 當我「想知道這個工具到底送了什麼給 API」的時候

## ✨ 關鍵重點

### 1. 它先定義「hidden」，而且定義得很克制
**hidden ＝「這支執行檔讀得到，但目前公開來源查不到」**——作者明講這**不等於**支援、穩定、安全、或有意讓你設定。
234 這個數字也被刻意降溫：原文說「deliberately not presented as *234 useful flags*」，因為裡面大量是 host 協定欄位、測試 fixture、憑證、telemetry 管線。**這種自我設限，比數字本身更值得學。**

### 2. 全篇最可操作的一點：`env || modelBundle || remoteGate`
這決定了「設 `=0` 到底關不關得掉」，也是最反直覺的地方：

| parser 型別 | 行為 | `=0` 有用嗎 |
|---|---|---|
| `triBool` | 真雙向開關 | ✅ 真的關得掉 |
| `bool` 單獨使用 | 一般開關 | ✅ 通常關得掉 |
| **`bool` 串在 `env \|\| model \|\| remoteGate` 裡** | **單向 force-on** | ❌ **關不掉**——模型 bundle 或遠端 gate 還是能把它打開 |
| `str`/`enum`/`int` | 依呼叫點驗證 | ⚠️ 無效值通常 fallback 回預設，不會「關掉」 |

作者用實測釘死這件事：在 `claude-opus-5[1m]` 上設 `BISON_CAIRN=0`、`LARCH_CISTERN=0`**沒有**移除對應段落；在 `claude-fable-5[1m]` 上設 `AMBER_ASTROLABE=0` 也**沒有**移除自主性附錄。

### 3. 代號式命名本身就是訊號
`BISON_CAIRN`、`LARCH_CISTERN`、`AMBER_ASTROLABE`、`THISTLE_GREBE`、`TOASTY_THIMBLE`、`PEWTER_OWL`、`HARBOR_KITE`、`GAULT_KESTREL`、`GORSE_PLOVER`、`PARCHMENT_FERN`、`BASALT_COVE`、`WALNUT_SPIRE`、`LANTERN_PRISM`、`JUNIPER_SUNDIAL`、`THRIFTY_SONIC`——隨機雙字代號。
**⚠️ 這段是我的解讀**：刻意不自我描述的命名，等於在說「這不是給你用的」。看到代號式變數就該預期它**隨時會變、不保證相容**。

### 4. 這些變數實際控制的是「system prompt 裡有沒有那一段」
不是玄學開關，是很具體的文字增減。作者的差分測試量到大小變化：

| 變數 | 效果 | 請求大小變化 |
|---|---|---|
| `BISON_CAIRN=1` | 加上 `# Delivering work`（範圍、假設、卡住、完成度） | +約 2 KB |
| `LARCH_CISTERN=1` | 加上 `# Corrections`（少做無謂自我修正） | +約 1.25 KB |
| `AMBER_ASTROLABE=1` | 加上自主性附錄（可逆的事別中途問） | +約 1.37 KB |
| `DISABLE_GIT_INSTRUCTIONS=1` | 移除內建 git 段落 | **−約 6.4 KB** |
| `SIMPLE_SYSTEM_PROMPT=1` | 換成精簡 harness | **113 KB → 73 KB** |

最後兩個是**有文件的**，作者特別註明那是控制組、不是 hidden 發現。

### 5. 一個明確的安全警訊
`CLAUDE_CODE_GAULT_KESTREL` 會**移除一句護欄**——原本那句是「當目標與其描述矛盾、或不是 agent 自己建立的東西時，要停下來」。原文自己標「it weakens a guardrail and should not be enabled casually」。
另外 `autoUploadSessions` 會把本機 session 鏡像到 claude.ai（作者標「Privacy/data-transfer impact；do not enable casually」）。

### 6. 21 個沒被官方索引的 `settings.json` key
執行檔實際接受 159 個 root key，官方索引只列 145 個。扣掉 `$schema` 與兩個別名，**21 個是文件沒有的**。從低風險到別亂碰：`breakReminder`、`quietHours`、`showMessageTimestamps`、`modelSettings`（存 per-model `effortLevel`）、`precomputeCompactionEnabled` → 到 `doneMeansMerged`（改變 agent 自主性與任務長度）、`autoUploadSessions`、`proxyAuthHelper`（帶憑證）、`xaaIdp`（企業身分驗證）。

### 7. ⚠️ 我在這個 session 直接核對到的兩點（我的觀察，非原文）
- 原文說 `padded-countdown` 的預設 budget 是 **15,000,000**——我這個 session 的 context 裡出現的正是 `<total_tokens>15000000 tokens left</total_tokens>`，**數字吻合**。
- 原文說在 `claude-opus-5[1m]` 上，bundle 本身就帶 `# Delivering work` 與 `# Corrections`——我正是這個模型，而我的 system prompt **確實有這兩段**。這與「它們是 model bundle 帶的、不是環境變數開的」一致。

### 8. 文章自己標明的限制
- **byte offset 與行為宣稱只對 pinned 的 `2.1.239` 有效**，每次更新都要重跑。
- 表格裡標 `static` 的項目**只做了程式碼路徑追蹤，沒有實際跑起來重現**；只有標 `verified` 的做過差分測試。
- headless `--permission-mode auto` 在假 API 下沒有初始化 Auto Mode attachment，所以 THRIFTY 那條走的是 `bypassPermissions` 分支，Auto 專屬分支**是靠讀碼推論、不是實測**。
- **沒有檢查本機 `settings.json`**，公開來源分析與 binary 分析是兩段獨立的證據鏈。

## 💬 原文摘錄
- hidden 的定義（全篇的立場）：
  > "Here, **hidden** means 'read by this exact executable but absent from the current public sources checked.' It does not mean supported, stable, safe, or intentionally user-configurable."
- 對自己數字的降溫：
  > "That number is deliberately not presented as '234 useful flags': many are host protocol fields, test fixtures, credentials, telemetry plumbing, or implementation handshakes rather than reasonable user configuration."
- 差分測試的紀律：
  > "Each negative test has a positive control so 'string absent' is not mistaken for 'code path never ran.' No prompt payload was sent to Anthropic during these tests."
- 單向閘的結論：
  > "That confirms the static `env || modelBundle || remoteGate` reading: these boolean codenames are force-on switches, not symmetric kill switches."
- 實務建議：
  > "Prefer a documented top-level setting when one exists."
  > "Re-run this analysis after every Claude Code update."

## 🔗 相關
- [[工具-AI改動的AB對照評測]] — 同樣是「不憑感覺、用對照組證明」，但那張測的是輸出品質，這篇測的是**送出去的請求本身**
