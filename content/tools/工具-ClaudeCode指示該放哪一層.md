---
type: tool
name: "Claude Code 的指示該放哪一層"
source: "[[Claude Code 的記憶機制（官方文件）]]"
source_type: article
tags: [ai, agent, claude-code, tooling, configuration]
triggers: [不知道規則該寫在CLAUDE.md還是skill, 只跟某個資料夾有關的規則, 團隊規則和我個人偏好混在一起, 一定要遵守的規則agent卻會略過, 專案同時給好幾種coding agent用]
---

## 🎯 什麼情境該想到我
當你想讓 Claude Code「記住」某件事，卻不確定該寫進哪裡：專案的 CLAUDE.md、自己的 CLAUDE.md、`.claude/rules/`、skill、hook，還是讓它自己記（auto memory）。
**核心判斷：先問這件事是「每次都要知道的事實」、「只在某些檔案才相關」、「多步驟流程」，還是「一定要被執行」。**

## ⚙️ 怎麼用（步驟 / 公式）

### 1. 依性質選機制
| 這件事是… | 放哪裡 | 為什麼 |
|---|---|---|
| 每個 session 都該知道的事實：build／test 指令、命名慣例、專案結構、「一律做 X」 | **CLAUDE.md** | 每次啟動都載入 |
| 只跟某類檔案或某個目錄有關 | **`.claude/rules/` 加 `paths:`** | 碰到符合的檔案才載入，平常不佔 context |
| 多步驟的流程、只在某種任務才需要 | **skill** | 叫用或模型判斷相關時才載入 |
| **一定要執行或一定要擋**（每次 commit 前跑 lint、禁止某個指令） | **hook** 或 settings 的 `permissions.deny` | CLAUDE.md 只是 context，不是強制設定；hook 與 settings 不管模型怎麼決定都會生效 |
| 你糾正過它的事、你的偏好、從程式碼推不出來的專案背景 | **auto memory**（讓 Claude 自己記） | 你說「記住…」它就存；想進 CLAUDE.md 要明說「加到 CLAUDE.md」 |

官方的判準：CLAUDE.md 寫的是「**你本來會一再重新解釋的事**」。觸發點包括：同一個錯犯第二次、code review 抓到它本該知道的事、這次 session 又打了上次打過的糾正、新同事也需要同樣的背景。

### 2. CLAUDE.md 選位置（由廣到窄，越後面的越晚進 context）
| 範圍 | 位置 | 跟誰共用 |
|---|---|---|
| 組織 | macOS `/Library/Application Support/ClaudeCode/CLAUDE.md`；Linux／WSL `/etc/claude-code/CLAUDE.md`；也可寫在 managed settings 的 `claudeMd` 鍵 | 這台機器的所有使用者，**不能被排除** |
| 使用者 | `~/.claude/CLAUDE.md`（另有 `~/.claude/rules/`） | 只有你，所有專案 |
| 專案 | `./CLAUDE.md` 或 `./.claude/CLAUDE.md` | 團隊，進版控 |
| 本機 | `./CLAUDE.local.md`（加進 `.gitignore`） | 只有你，這個專案 |

- **檔案是串接、不是覆蓋**：從檔案系統根目錄一路到工作目錄，所有找到的檔案依序接起來；同一層 `CLAUDE.local.md` 排在 `CLAUDE.md` 後面。兩條規則衝突時，Claude **可能任選一條**，所以要自己保持一致。
- **子目錄的 CLAUDE.md 不在啟動時載入**：Claude 讀寫該子目錄的檔案時才載入。
- **多個 worktree 共用個人指示**：`CLAUDE.local.md` 只存在建立它的那個 worktree；要跨 worktree，改在 CLAUDE.md 裡 import 家目錄的檔案（`@~/.claude/my-project-instructions.md`）。

### 3. 寫法：具體到能驗證、短、不矛盾
- 「用 2 個空格縮排」而不是「格式要好」；「commit 前跑 `npm test`」而不是「要測試」。
- **每個 CLAUDE.md 目標 200 行以內**，越長越佔 context、越不會被遵守。
- **`@path` import 只幫你整理，不省 context**：被 import 的檔案會跟著一起載入；最多遞迴 4 層。要真的省，改用有 `paths:` 的 rule。
- 想給人類維護者看、不想佔 token 的備註，寫成 HTML 註解 `<!-- ... -->`：區塊級的註解注入前會被拿掉（程式碼區塊內的不會）。

### 4. `.claude/rules/` 的 `paths:` 寫法
```markdown
---
paths:
  - "src/api/**/*.ts"
---
# API Development Rules
- All API endpoints must include input validation
```
- `paths` 是 rule 唯一被讀的欄位，其他欄位會被忽略；YAML 解析失敗時整份當成**沒有 `paths`**，也就是每次都載入（用 `claude --debug` 看錯誤）。
- 沒有 `paths` 的 rule 在啟動時載入，優先序和 `.claude/CLAUDE.md` 相同。
- 使用者層的 rule 先載入、專案層後載入，**兩者不會互相覆蓋**，衝突時一樣可能任選。

### 5. 同時給別的 coding agent 用：AGENTS.md
Claude Code 能直接讀 AGENTS.md（v2.1.277 起，查證 2026-11-14），但**預設只在「工作目錄往上沒有任何 CLAUDE.md、`.claude/CLAUDE.md`、CLAUDE.local.md」時才讀**。

| repo 裡有 | Claude 讀 |
|---|---|
| 只有 AGENTS.md | AGENTS.md |
| AGENTS.md ＋ CLAUDE.md 或 CLAUDE.local.md | **只讀 CLAUDE.md** |
| CLAUDE.md 裡 `@AGENTS.md` | 兩者（AGENTS.md 經由 import） |

最穩的共用做法：CLAUDE.md 第一行寫 `@AGENTS.md`，下面再加 Claude 專屬的指示。想兩個都讀，在 `/config` 把 Project instructions 設成 `claude-md-and-agents-md`。

## 🧪 我實際套用的紀錄
- 2026-11-14：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **CLAUDE.md 不是強制層**：它是以 user message 的形式送在 system prompt 之後，Claude 會盡量照做，但沒有保證。要保證就用 hook 或 settings；要放到 system prompt 層級只能用啟動參數 `--append-system-prompt`（適合腳本，不適合日常互動）。
- **加一個 CLAUDE.local.md 會讓 AGENTS.md 不再被讀**：專案靠 AGENTS.md、你又想放自己的本機指示時，要記得改 Project instructions 設定，或在 CLAUDE.local.md 裡 import AGENTS.md。
- **用 symlink 讓 CLAUDE.md 指向 AGENTS.md 的兩個坑**：Edit／Write 工具不會穿過 symlink 寫入；Windows 上建 symlink 要管理員或開發者模式，而且 Git 預設會把 symlink checkout 成一個只有一行路徑的純文字檔。團隊有人用 Windows 就改用 `@AGENTS.md` import。
- **外部 import 第一次要核准**：專案層的 CLAUDE.md import 了工作目錄外的檔案，第一次會跳出核准對話框；拒絕後就一直停用、不再詢問。這是為了防別人 commit 進來的檔案偷帶指示。
- **組織的 managed CLAUDE.md 用來給指引，強制要靠 managed settings**：官方的分工是「擋工具、指令、路徑 → `permissions.deny`；沙箱 → `sandbox.enabled`；行為與程式風格 → managed CLAUDE.md」。
- 版本號與設定名稱都是 2026-11-14 查證的官方文件內容，Claude Code 更新很快，用之前再核對。

## 🔗 相關工具
- [[工具-把agent犯的錯變成環境改善]] —— 什麼錯該變成 CLAUDE.md 規則、什麼該變成 lint 或 skill；這張講寫進去之後放哪一層
- [[工具-把重複的prompt包成skill]] —— 表格裡「多步驟流程 → skill」那一列的做法
- [[工具-CLAUDE.md沒生效時怎麼查]] —— 放對地方之後還是沒效果時的除錯清單
