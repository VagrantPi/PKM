---
type: tool
name: "CLAUDE.md 沒生效時怎麼查"
source: "[[Claude Code 的記憶機制（官方文件）]]"
source_type: article
tags: [ai, agent, claude-code, debugging, configuration]
triggers: [寫在CLAUDE.md的規則agent好像沒看到, compact之後規則好像不見了, 不知道agent自己記住了什麼, AGENTS.md放了卻沒被讀, 子目錄的CLAUDE.md後半段被忽略]
---

## 🎯 什麼情境該想到我
當你明明寫了規則，Claude Code 卻像沒看到；或你想知道它到底載入了哪些指示、自己記了什麼。
**先確認「有沒有進 context」，再懷疑「寫得好不好」。**

## ⚙️ 怎麼用（步驟 / 公式）

### 1. 先看有沒有載入
- **`/context all`** → 看「Memory files」清單：啟動時該載入的 CLAUDE.md、CLAUDE.local.md 有沒有在裡面。不在清單上，Claude 就看不到。
- **子目錄的 CLAUDE.md 本來就不會出現在清單**：它要等 Claude 讀寫那個子目錄的檔案才載入，載入時終端機會印一行 Loaded。測試新檔案時，**自己用 shell 建立**，再叫 Claude 讀該子目錄的某個檔案。
- **`InstructionsLoaded` hook**：可以記錄每個 CLAUDE.md 與 rule 在什麼時候、為什麼載入，適合查有 `paths:` 的 rule 和延遲載入的檔案。
- **`/memory`**：列出各層 CLAUDE.md 與 auto memory 資料夾，可以直接打開編輯；連還不存在的使用者層、專案層 CLAUDE.md 也會列出，選了就建立。

### 2. 有載入但沒照做
依序檢查：
1. **寫得夠具體嗎**：「用 2 個空格縮排」比「排版好一點」有效。
2. **有沒有互相矛盾**：使用者層、專案層、子目錄的 CLAUDE.md 和 rules 之間，同一件事寫法不同時 Claude 可能任選一條。可以跑 `/doctor prompt-audit` 找出過時、指向不存在檔案、互相矛盾的指示（v2.1.283 起；它只產出報告和修改建議，你同意才改）。
3. **有沒有跟內建指示打架**：例如你在 CLAUDE.md 寫了 commit／PR 規則，要用 `includeGitInstructions` 關掉內建的那套，署名文字用 `attribution` 設定。
4. **必須在固定時間點發生的事改用 hook**：每次 commit 前、每次改檔後要做的事，寫成 hook 才保證執行。

### 3. compact 之後規則不見了
- **專案根目錄的 CLAUDE.md 會在 `/compact` 後重新從磁碟讀入**。
- 會消失的是三種：**只在對話裡講過的指示**、還沒重新載入的子目錄 CLAUDE.md、還沒再碰到符合檔案的 `paths:` rule。
- 解法：在對話裡反覆交代的事，寫進 CLAUDE.md。

### 4. 檔案太大
| 對象 | 限制（查證 2026-11-14） | 超過會怎樣 |
|---|---|---|
| 一般 CLAUDE.md | 建議 200 行內；硬上限 4 MiB | 超過 4 MiB **整份不載入**；太長會在啟動與 `/status` 時警告 |
| 隨需載入的檔案（子目錄 CLAUDE.md、有 `paths:` 的 rule、子目錄的 rules） | 200K context：40,000 字元；1M context：Opus 4.6／Sonnet 4.6 為 200,000 字元，之後的模型為 150,000 字元 | **只收到前段**，結尾附一句要 Claude 用 Read 讀其餘部分；它沒去讀，後段就不在 context |
| auto memory 的 `MEMORY.md` | 前 200 行或前 25KB，先到者為準 | 超過的部分下次不載入 |

用 `wc -m path/to/CLAUDE.md` 算字元數。`/doctor` 也會建議刪減：砍掉從程式碼就推得出來的東西（目錄結構、依賴清單、架構總覽），保留坑、理由、跟工具預設不同的慣例。

### 5. AGENTS.md 沒被讀
1. 工作目錄往上有沒有 CLAUDE.md、`.claude/CLAUDE.md`、CLAUDE.local.md（`~/.claude/CLAUDE.md` 不算）？有的話**預設只讀 CLAUDE.md**。
2. `claude --version` 要 v2.1.277 以上；v2.1.281 以前，Bedrock 或關閉 telemetry 的 session 也讀不到。
3. `/config` 裡 Project instructions 不是 `claude-md` 或 `managed-only`。看不到這個選項，代表這個 session 不支援讀 AGENTS.md。
4. 最保險：在旁邊放一個 CLAUDE.md，內容寫 `@AGENTS.md`。

### 6. 不知道 auto memory 記了什麼
- 位置：`~/.claude/projects/<project>/memory/`，裡面一個 `MEMORY.md` 索引加上一主題一檔。同一個 git repo 的所有 worktree、子目錄共用一份；只存在這台機器，不跨機器同步。
- **啟動時只載入 `MEMORY.md` 的前 200 行或 25KB**，主題檔是 Claude 需要時才去讀。
- 它記四類：user（你的角色與偏好）、feedback（你給的糾正與確認過的做法）、project（從程式碼或 git 推不出來的進行中工作與決策）、reference（外部資訊在哪）。能從程式碼推出的、CLAUDE.md 已經寫的，它不記。
- `/memory` → 打開 auto memory 資料夾，全是純 markdown，可以直接改或刪。
- 關掉：`/memory` 的開關，或單一專案設 `"autoMemoryEnabled": false`，或環境變數 `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`。

## 🧪 我實際套用的紀錄
- 2026-11-14：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **subagent 拿不到主對話的 auto memory**（fork 例外，它繼承父對話）；subagent 要自己的記憶得另外設定 `memory` 欄位，是另一個資料夾。
- **auto memory 不會被 session 清理刪掉**：舊的對話紀錄會依 `cleanupPeriodDays` 刪除，但記憶檔不受影響，留到有人改或刪為止。記錯的東西要自己清。
- **背景 session、或由另一個 Claude Code session 啟動的 session**，只能把 auto memory 關掉、不能打開；要開得在終端機直接跑 `claude` 的 session 裡切。
- **專案設定可以把 auto memory 指到別的資料夾**（`autoMemoryDirectory`），跟 hook 一樣受工作區信任規則管；開了 `permissions.blockReadsOutsideWorkingDirectories` 時，repo 指定的外部記憶資料夾既不讀也不寫。
- 字元上限與版本號都綁在 2026-11 的版本，Claude Code 更新後要重新核對。

## 🔗 相關工具
- [[工具-ClaudeCode指示該放哪一層]] —— 先把指示放到對的地方，這張才派得上用場
- [[工具-用假API差分測試逆向CLI行為]] —— 要確定設定「真的有進送出去的請求」時，比 `/context` 更底層的驗證法
- [[工具-關掉ClaudeCode塞給模型的提醒]] —— 你的規則跟內建提醒打架時，另一個方向的解法
