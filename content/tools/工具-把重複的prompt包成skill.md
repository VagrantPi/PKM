---
type: tool
name: "把重複的 prompt 包成 skill"
source: "[[做一個 ELI5 Skill 的過程]]"
source_type: article
tags: [ai, llm, skill, methodology]
triggers: [同一種指示每次都要重講一遍, 想把自己的偏好固定成AI的預設, 不知道什麼時候該把流程做成skill, 想自己做一個skill但不知從何開始, 重複的工作流想固定下來讓AI照做]
---

## 🎯 什麼情境該想到我
當你發現「**這段指示我每次開新對話都要再打一遍**」的時候——那就是該把它包成 skill 的訊號。

## ⚙️ 怎麼用（步驟 / 公式）
1. **判斷值不值得包**：判準只有一條——**你是不是一直在重下同一種 prompt**。是就包。成本很低：skill 本體就是一個資料夾裡的 `SKILL.md`（markdown），不用寫程式——但它**不是完全沒有格式**，開頭要有一段 YAML frontmatter（至少 `description`），見下方「最小結構」。
2. **寫起始 prompt 給 skill-creator**（Claude Code 內建）。不要描述你要的輸出，要給這兩樣：
   - **變數有哪些維度**——例如 eli5 給的是「聽眾」的四個維度：年齡／學程／職務／關係。
   - **幾句真實的觸發例句**——例如「ELI5 什麼是 database index」「解釋這個給我主管聽」。
   維度與例句給足，草稿的品質就決定了大半。
3. **審它提的測試案例**：skill-creator 會提幾題，跑之前先改成**真正涵蓋不同維度**的題目（不同對象 × 不同素材類型）。這步別跳。
4. **跑對照評測收尾**：帶 skill vs 不帶 skill 各跑一輪比較——細節見 [[工具-AI改動的AB對照評測]]。
5. **把 eval 腳本留在本地**：之後每改一次 `SKILL.md` 就重跑一次比較，不用每次都走完整 skill-creator 流程。**沒有這步就迭代不動。**

### 最小結構：一個資料夾＋一個 SKILL.md（查證 2026-10-15）
> 以下依 Claude Code 官方文件 Skills 頁與 Agent Skills 開放標準（agentskills.io specification）整理，非來源文章內容。來源文章原句說「沒有特殊格式或 schema」，應理解為「不用寫程式、就是 markdown」，不是「完全沒有格式」。

- **檔案結構**：一個 skill = 一個資料夾，裡面**必須**有 `SKILL.md`；需要時可再放 `scripts/`、`references/`、`assets/` 等輔助檔（選用）。
- **`SKILL.md` 分兩段**：
  1. 開頭用 `---` 包起來的 **YAML frontmatter**——告訴模型「什麼時候該用我」；
  2. 底下的 **markdown 正文**——被啟用後模型要照做的指示。
- **兩個關鍵欄位**：
  - `name`：skill 名稱，也是在 Claude Code 裡輸入 `/名稱` 的指令名。開放標準規定**必填**、最多 64 字元、只能小寫英數與連字號、**必須與資料夾同名**；Claude Code 則允許省略，省略時**預設用資料夾名稱**。
  - `description`：做什麼＋什麼時候用。開放標準規定**必填**（最多 1024 字元）；Claude Code 標為「建議」，省略時拿正文第一個非空行頂替。**它決定模型會不會自動觸發這個 skill**——因為啟動時模型只載入每個 skill 的 `name`＋`description`（約 100 tokens），正文要等被選中才載入。所以 description 要把「使用者會怎麼說」寫進去（例：「使用者說 ELI5、解釋給主管聽、講白話一點時使用」）。Claude Code 會把 `description`＋`when_to_use` 合併後截斷在 1,536 字元，**最關鍵的使用情境放最前面**。
- **放在哪（Claude Code）**：
  - 個人（所有專案可用）：`~/.claude/skills/<skill名>/SKILL.md`
  - 專案（commit 進 repo 給團隊）：`<repo>/.claude/skills/<skill名>/SKILL.md`
  - 同名時個人版優先於專案版；舊式的 `.claude/commands/<名稱>.md` 仍可用，但新的建議做成 skill。

最小骨架（自寫範例，存成 `~/.claude/skills/explain-simple/SKILL.md`）：

```markdown
---
name: explain-simple
description: 依聽眾程度用白話解釋概念或程式碼。使用者說「ELI5」「解釋給我主管聽」「講白話一點」時使用。
---
# 依聽眾解釋
1. 先確認聽眾（年齡／職務／和使用者的關係），沒給就只問一句。
2. 先用一個生活類比開場，再給一句精確定義。
3. 全文 150 字內；非用不可的術語後面附一句白話。
```

驗證方式：開新的 Claude Code session，打 `/explain-simple` 測「手動叫得到」；再直接說「ELI5 什麼是 database index」測「自動觸發得到」——後者失敗通常是 description 寫得不像使用者的說法。

## 🧪 我實際套用的紀錄
- 2026-08-23：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **只用一次的東西不要包**。判準是「重複」，不是「複雜」——複雜但只做一次的事，直接下 prompt 就好。
- **skill-creator 的初次評測是人工評分，跟你之後本地跑的 auto-grader 結果會不一樣**（原作者實測兩者對「超過字數」與「類比夠不夠白話」的鬆緊剛好相反）。**別把兩份數字混著比。**
- **測到的是內容、不是觸發**：評測是把 skill 內容直接餵進 prompt 跑的，`description` 的觸發詞寫得好不好沒被測到——而那是實際使用時最常失敗的一環，要自己另外試。
- **格式小錯會讓 skill 在別的工具上失效**（查證 2026-10-15）：Claude Code 對 `name` 很寬鬆（可省略、預設用資料夾名），但開放標準要求 `name` 必填、小寫連字號、與資料夾同名。只在 Claude Code 測過就拿去別的支援 Agent Skills 的工具用，可能直接載不進來——要跨工具共用就照標準寫滿 `name`＋`description`（推測：實際行為依各工具實作而定）。

## 🔗 相關工具
- [[工具-AI改動的AB對照評測]] —— 這張講「怎麼做出來」，那張講「怎麼證明做出來的真的有用」，是同一條流程的前後段
- [[工具-提示工程]] —— skill 本質就是把調好的 prompt 固定下來；prompt 還沒調到穩就急著包成 skill，只是把不穩定固定住
