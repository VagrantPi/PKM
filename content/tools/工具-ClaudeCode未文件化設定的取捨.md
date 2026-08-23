---
type: tool
name: "未文件化設定的取捨"
source: "[[Claude Code 隱藏設定分析 v2.1.239]]"
source_type: article
tags: [ai, llm, tooling, security]
triggers: [想用官方文件沒寫的設定, 看到別人分享的隱藏設定不知道能不能跟, 不確定某個設定有沒有隱私風險, 想調工具但文件找不到對應選項, 團隊共用設定該放什麼]
---

## 🎯 什麼情境該想到我
當你「**看到一份『隱藏設定大全』，手很癢想全部貼進 settings.json**」的時候。

## ⚙️ 怎麼用（步驟 / 公式）
1. **先分清楚證據等級**，別把四種東西當成同一回事：

   | 來源 | 意義 |
   |---|---|
   | 官方 reference | ✅ 目前的支援契約 |
   | JSON schema | ⚠️ 官方自己警告**會落後 CLI**；schema 有、reference 沒有的名字要當**過時或非公開** |
   | CHANGELOG | ⚠️ **release 歷史 ≠ 現行支援**。只在 changelog 出現過的名字不算數 |
   | 拆執行檔挖出來的 | ❌ 只代表「這支 binary 讀得到」，**不等於支援、穩定、安全、或有意讓你設定** |

2. **有官方設定就用官方的**。同一件事若已有 top-level key（`includeGitInstructions`、`disableWorkflows`、`autoMemoryEnabled`、`fileCheckpointingEnabled`…），不要改用環境變數別名。
3. **按風險決定要不要碰**（以 v2.1.239 那 21 個未索引 key 為例）：
   - **低風險、可以玩**：`breakReminder`、`quietHours`、`showMessageTimestamps`、`modelSettings`（存 per-model `effortLevel`）、`precomputeCompactionEnabled`。
   - **會改變 agent 行為，想清楚再開**：`doneMeansMerged`（要求做到 PR 可合併才算完成——會拉長任務與自主性）、`todoFeatureEnabled`、`feedbackDrafts`、`autoDreamEnabled`、`autoContinueAtUsageLimit`（可能延長無人看管的執行時間）。
   - **牽涉隱私／憑證／權限，別亂碰**：`autoUploadSessions`（把本機 session 鏡像到 claude.ai）、`proxyAuthHelper`（產生 `Proxy-Authorization` 標頭）、`policyHelpers`、`xaaIdp`、`skipWorkflowUsageWarning`（這是**同意紀錄**，不該預先塞值）。
4. **看命名判斷意圖**：`BISON_CAIRN`、`THISTLE_GREBE` 這種**隨機雙字代號**是刻意不自我描述的內部 flag——看到就預期它隨時會變。名字寫得清楚的（`disableWorkflows`）才是給你用的。
5. **記錄你設了什麼、為什麼設**，並在每次工具更新後重驗。

## 🧪 我實際套用的紀錄
- 2026-08-23：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **別碰這幾類**：驗證／host 協定／remote session／policy／測試 fixture／`DISABLE_*` 安全類變數。其中數個本來就被擋在低信任度的設定範圍外，有些會**削弱核可或政策行為**。
- **設定範圍是有意義的**：部分 key 只認 user 或 managed，project／local 會被直接忽略。設了沒反應時先確認範圍，不要一直加值。
- **`env` 的移除不會立即生效**：拿掉一個 key 要**重啟**才會真的 unset；且啟動時才讀的消費端本來就要重啟。
- **未文件化設定不該進團隊共用設定**——沒有相容性承諾，下一版壞掉時沒人知道為什麼。

## 🔗 相關工具
- [[工具-關掉ClaudeCode塞給模型的提醒]] —— 決定「要碰」之後，那張是具體怎麼關、哪些關不掉
- [[工具-用假API差分測試逆向CLI行為]] —— 想確認某個設定到底有沒有生效，用那張的方法自己量，不要憑感覺
