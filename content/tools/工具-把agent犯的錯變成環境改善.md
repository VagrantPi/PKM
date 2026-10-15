---
type: tool
name: "把 agent 犯的錯變成環境改善（agent session 回顧）"
source: "[[Skills For Real Engineers]]"
source_type: article
tags: [ai, llm, agent, devex, tooling, linting]
triggers: [agent一直犯同樣的錯, CLAUDE.md越寫越長越來越沒用, 每次都要提醒agent同一條規範, agent找個檔案要找半天, 想讓下一次agent做得更順]
---

## 🎯 什麼情境該想到我
當你「發現 agent 反覆犯同一類錯、你一直在 CLAUDE.md／AGENTS.md 補規則，但下次它還是錯」的時候。

## ⚙️ 怎麼用（步驟 / 公式）

**核心想法**：別只修這次的程式碼，要改的是**讓錯誤更難發生的環境**。來自 Matt Pocock 的 `retro` skill，在一個 coding session 結束後跑。

### 1. 讀第一手紀錄，不靠記憶
回顧的對象是 session 本身：本機的 session log、指令與輸出。要在 `/clear` 之前、在被回顧的那個 session 裡做；clear 之後就只能指向 log 檔。

### 2. 依七類找改善點（每類都有「什麼時候才看」）

| 類別 | 問什麼 | 何時看 |
|---|---|---|
| **導航** | agent 花多久才找到對的檔案？檔案之間有沒有隱藏依賴？加一行**導航指標**會不會更快？ | 找資訊花了很久 |
| **自動檢查** | 有沒有 lint、型別、測試、檔案規則能抓到這個錯？**先讀 repo 既有的 check 指令與 CI**：已經存在卻沒接上、或悄悄壞掉的檢查，本身就是發現；完全沒有防護（沒有 pre-commit、CI 也不跑 lint／typecheck／test）也是發現 | agent 犯了機器抓得到的錯 |
| **程式規範** | reviewer 該不該多執行一條規則？該刪或改清楚哪一條？ | reviewer 漏抓 |
| **全域 AGENTS.md** | 哪些指示該搬去規範或自動檢查？ | 檔案太大 |
| **工具經濟** | 有沒有昂貴的工具呼叫可以精簡？哪個 CLI 或 MCP 特別耗 token？ | 出現昂貴呼叫 |
| **No-op** | 哪些指示根本沒改變 agent 的行為？ | 指示檔又大又亂 |
| **資訊取得** | 能不能讓 agent 看到更多？例如把 dev server log 接出來、開第三方服務的唯讀權限 | 關鍵資訊 agent 拿不到 |

### 3. ★ 規範要先分類：機械性的寫成檢查，判斷性的才寫成文字
- **機械性違規**（固定的語法模式、禁用的 API、import 形狀、檔案位置規則）→ **一律做成確定性檢查**：repo 自己 linter 的自訂規則、新的 pre-commit hook，或新的 CI job，挑最便宜的一種。**預設是寫檢查，不是寫規則**。
- **判斷性的事**（跨檔一致性、「跟周邊風格一致」這類任何防護都取代不了的）→ 才寫進 `CODING_STANDARDS.md`。

理由很直接：寫在文字裡的規則要靠 agent 每次記得，而且一直佔 context；檢查則每次都會跑、而且確定。

### 4. 把規範交給壓力最小的角色
- **實作 agent** 的 context 壓力最大（要探索、寫碼、除錯）；**review agent** 只收一份 diff，壓力最小。所以**程式規範由 reviewer 執行，不由實作者執行**。
- 對應的檔案分工：
  - `CLAUDE.md`／`AGENTS.md` 會推進每個 agent 的 context，**只放導航指標**。
  - `CODING_STANDARDS.md` 只在 review 時讀，超過約 1000 行就拆檔，用指標連過去。
  - 文件當參考檔，由其他檔指過去。

### 5. 刪掉 no-op
逐句問：「這句跟模型本來就會做的比，有沒有改變行為？」沒有就整句刪。太弱的詞換成有力的詞，例如「be thorough」換成「relentless」。這條出自同一個 repo 的 `writing-for-agents`，`retro` 第一步就是載入它。

### 6. 依嚴重度排序後提給人決定
產出是一份建議清單，由人挑要做哪些；`retro` 本身不改檔。

## 🧪 我實際套用的紀錄
- 2026-10-13：對照本庫，`/obsidian-kb:lint-wiki` 的機械掃描已經腳本化，語意判斷交給 `lint-depth`，剛好就是「機械性寫成檢查、判斷性才給 LLM」的分法。

## ⚠️ 注意 / 什麼時候不適用
- 需要讀得到 session log；harness 不保留紀錄時只能回顧當下這一輪。
- 順利的 session 不必做：原文件建議在「值得學點什麼」的 build 之後跑，順利的 build 可以跳過；每次 session 都跑多半只會產出沒人需要的規則（retro 文件）。會反覆在同一個 repo 工作的 agent 回報最大（我的判斷）。
- 建議會越來越多，要依嚴重度挑，不是每次全做；每類的「何時看」條件就是用來避免每次七類都跑一遍。
- 「把規範交給 reviewer」的前提是你真的有 review 階段，例如雙軸 code review 或 CI；沒有的話，規則只能留給實作者（推論）。

## 🔗 相關工具
- [[Skills For Real Engineers]] —— 這個做法所在的 skill 集合，以及整條流程裡 retro 的位置
- [[工具-skill集合的分層與維護]] —— 規則、skill、指示檔要放哪一層
- [[工具-防止agent造假通過驗收]] —— 確定性的檢查也是防止 agent 自稱完成的手段
- [[工具-知識庫定期健檢]] —— 同樣的分法套在知識庫上：機械項先腳本化
