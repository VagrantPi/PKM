---
type: tool
name: "skill 集合的分層與維護"
source: "[[Skills For Real Engineers]]"
source_type: article
tags: [ai, llm, skill, methodology, tooling]
triggers: [skill越寫越多開始互相打架, 好幾個skill裡有一模一樣的段落, 不知道哪些skill該讓模型自動叫, 改了一個skill其他就壞掉, 自己的skill清單過期了沒人維護]
---

## 🎯 什麼情境該想到我
當你的 skill 從 3 個長到 15 個，**開始重複、開始互相呼叫、開始沒人記得哪個還能用**的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 1. ⭐ 用「誰能叫它」分成兩層——這一條決定其他所有事
| 層 | 誰能叫 | 職責 |
|---|---|---|
| **user-invoked** | **只有人**打指令 | **編排**：把一連串步驟串起來 |
| **model-invoked** | 人或模型都能 | **持有可複用的紀律**：一件事的正確做法 |

**規則：user-invoked 可以呼叫 model-invoked，但絕不呼叫另一個 user-invoked。**
這條把依賴圖壓成兩層，不會長成任意呼叫的網。

### 2. 重複的段落要抽成 model-invoked 原語
發現三個 skill 裡有同一段「怎麼訪談使用者」，那就抽出來變成一個 model-invoked skill，讓上層共用。
實例：`grilling` 這個面談原語被 `grill-me`、`grill-with-docs`、`triage`、`wayfinder`、`improve-codebase-architecture` **五個**編排型 skill 共用。
**判準：同一段紀律出現第二次，就該抽。**

### 3. 給 skill 一個晉升生命週期
用資料夾分級，並明確規定**哪一級才會出現在對外清單**：

| bucket | 意義 | 出現在 README／清單？ |
|---|---|---|
| `engineering/`、`productivity/` | **promoted**，正式供應 | ✅ 必須 |
| `in-progress/` | 公開但未出貨，徵求回饋 | ❌ 禁止 |
| `misc/` | 留著但很少用，不推廣 | ❌ 禁止 |
| `deprecated/` | 已停用 | ❌ 禁止 |

沒有這層分級，實驗品跟正式品會混在一起，清單很快失去可信度。

### 4. ⭐ 有路由就要維護——「會說謊的路由」
如果你有一個「該用哪個 skill」的入口，**把同步更新寫成硬規則**：
> 新增、改名、移除、或改變任何 user-reachable skill 時，必須重讀路由的 `SKILL.md` 並更新它。
> **一個它從沒提過的新 skill，或一個它還在路由過去的舊 skill，就是一個會說謊的路由。**

### 5. 每個 skill 的文件用固定四段
**What it does**／**When to reach for it**／**Common questions**／**It's working if**。
最後那段最少見也最有用——**它讓使用者能自己判斷 skill 是否真的生效**，而不是只能猜。

### 6. 用 symlink 連進 harness 目錄
把 skill 以 symlink 連進 `~/.claude/skills`／`~/.agents/skills`，這樣 `git pull` 就等於更新已安裝的版本，不必重裝。新增或改名後重跑連結腳本。

## 🧪 我實際套用的紀錄
- 2026-08-28：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **少於 5 個 skill 不需要這套**。分層與 bucket 是規模到了才有的問題，太早做只是額外負擔。
- **分層要落到設定、不能只寫在文件上**：user-invoked 要真的關掉模型觸發（例如 `disable-model-invocation: true` 加上對應 agent 設定裡的 `allow_implicit_invocation: false`），否則規則會被繞過。
- **抽共用原語會增加一層間接**。只在同一段紀律**真的出現第二次**時才抽；為了「將來可能會用」而抽，是在製造維護成本。
- **路由是最容易腐爛的一環**，因為它不會報錯。要靠流程規則盯住，不能靠自覺。
- 改了共用的 model-invoked 原語，**上層每一個編排 skill 都要重驗** → [[工具-測試skill的觸發邊界]]。

## 🔗 相關工具
- [[工具-把重複的prompt包成skill]] —— 那張是「單一 skill 怎麼誕生」，這張是「一堆 skill 怎麼不腐爛」
- [[工具-測試skill的觸發邊界]] —— 分層之後，哪些能被模型自動叫起來就是可測的行為，要驗
- [[工具-防止agent造假通過驗收]] —— 「It's working if」跟那張的心法一致：把「成功」定義成可判定的東西
