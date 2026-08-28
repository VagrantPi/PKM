---
type: article
title: "Skills For Real Engineers"
source_url: https://github.com/mattpocock/skills
author: Matt Pocock
site: GitHub
tags: [ai, llm, skill, tooling, methodology]
captured: 2026-08-28
read_status: read
---

## 📌 30 秒摘要（讀完用自己的話寫一句）
> 這篇在講：Matt Pocock 每天在用的 ~24 個 agent skill。它的論點是**反 GSD／BMAD／Spec-Kit 那種「接管整個流程」的做法**——那類框架奪走你的控制權，流程出錯還很難修；他主張 skill 要**小、好改、可組合**。而他組織這套 skill 的方式（**user-invoked 負責編排、model-invoked 持有可複用紀律**）比任何單一 skill 都值得抄。

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- 我自己在寫 skill（`/ingest-book`、`/ingest-skill`…），這份 repo 的 `CLAUDE.md` 是**怎麼把 skill 集合維護到不腐爛**的實戰範本。
- 它的四個失敗模式，恰好是我知識庫裡既有工具卡的 agent 版對照——**可以直接複用我已經懂的東西**。
- 作者是 TypeScript 圈的人，但這套 skill 本身**與語言無關**。

## 🧰 這篇給我的工具（連到 tools/ 工具卡）
- [[工具-skill集合的分層與維護]] — 當我的 skill 開始變多、互相呼叫、開始亂的時候
- [[工具-讓agent反過來拷問你]] — 當我「講完需求，agent 做出來的不是我要的」的時候

## ✨ 關鍵重點

### 1. ⭐ 四個失敗模式——而且每個都對應我已經有的工具卡
Matt 的論證主線是「**軟體工程的基本功在 AI 時代更重要**」，他每一段都引經典（Pragmatic Programmer、DDD、XP、A Philosophy of Software Design）。所以這四條在我知識庫裡都已經有對應：

| 失敗模式 | 他的診斷 | 他的解法 | **我 vault 裡的對應卡** |
|---|---|---|---|
| **agent 沒做我要的** | 溝通落差；「沒有人確切知道自己要什麼」 | grilling session：讓 agent 拷問你 | [[工具-建構的先決條件]]（人的版本）＋ [[工具-讓agent反過來拷問你]] |
| **agent 太囉唆** | 缺少共享語言，被丟進專案自己猜行話，用 20 個字講 1 個字的事 | 建 `CONTEXT.md`，把行話固定下來 | [[工具-通用語言]]（DDD 的 ubiquitous language，同一件事） |
| **產出的 code 不能跑** | 回饋迴路不足，agent 在盲飛 | 靜態型別、瀏覽器存取、**紅綠重構** | [[工具-紅綠重構循環]]、[[工具-測試先行的設計]] |
| **建成一團爛泥** | agent 加速編碼，也**加速軟體熵** | 每天投資設計；深模組 | [[大泥球]]、[[工具-可靠可擴展可維護]] |

**我的補註**：這張對照表才是這篇對我最大的價值——**我不需要重學這四件事，只需要知道它們的 agent 版本長怎樣**。所以我沒有為前三項另建工具卡（[[工具-通用語言]] 等已經在了），只補了 vault 真正沒有的兩張。

### 2. ⭐ 集合的分層：誰能叫它，決定它是什麼
> "These split on one axis: **who can invoke them**. **User-invoked** skills are reachable only when you type them; their job is to **orchestrate**. **Model-invoked** skills can be invoked by you or reached for automatically; they hold the **reusable discipline**. A user-invoked skill may invoke model-invoked skills, but **never another user-invoked one**."

具體實例：`grilling` 是 model-invoked 的**可複用面談原語**，被 `grill-me`、`grill-with-docs`、`triage`、`wayfinder`、`improve-codebase-architecture` **五個** user-invoked skill 共用。
技術上是靠 `disable-model-invocation: true` ＋ `agents/openai.yaml` 裡的 `policy.allow_implicit_invocation: false` 標記 user-invoked。

### 3. `CONTEXT.md` ——他自稱整個 repo 最酷的技術
用他自己的例子看差別：
> **BEFORE**: "There's a problem when a lesson inside a section of a course is made 'real' (i.e. given a spot in the file system)"
> **AFTER**: "There's a problem with the **materialization cascade**"

三個附帶收益（他列的）：變數／函式／檔案的命名跟著一致、codebase 對 agent 更好導航、**agent 思考時花的 token 更少**（因為有更精簡的語言可用）。
這就是 DDD 的通用語言，只是對象換成 agent → [[工具-通用語言]]。

### 4. 維護紀律（`CLAUDE.md` 裡的規則，比 skill 本身更難得）
- **bucket 分級**：`engineering/`／`productivity/` 是 **promoted**（必須出現在 README 與 `plugin.json`）；`misc/`／`in-progress/`／`deprecated/` **禁止**出現在兩者。有明確的晉升／降級生命週期。
- ⭐ **"a router that lies"**：`ask-matt` 是所有 user-reachable skill 的路由。規則寫死——新增／改名／移除／改變任何 user-reachable skill 時，**必須同步更新它**；「一個它從沒提過的新 skill，或一個它還在路由過去的舊 skill，就是一個會說謊的路由。」
- **文件頁四段固定模板**：What it does／When to reach for it／Common questions／**It's working if**。最後一段很少見，卻是最實用的——告訴你怎麼判斷它真的在生效。
- **用 symlink 連進 harness 目錄**（`~/.claude/skills`、`~/.agents/skills`），這樣 `git pull` 就等於更新已安裝的 skill。
- 連文風都有規範：**全 repo 禁用破折號**，而且明講「不要做盲目的字元替換，要重寫句子」。

### 5. 兩種安裝哲學，別同時裝
- **Claude Code plugin** ＝ **訂閱**：整包唯讀、我出新版你自動拿到。
- **skills.sh** ＝ **分叉**：把可編輯的檔案複製進你的專案，你擁有它，要更新才 `npx skills update`。
> "installing both leaves you with **every skill twice**."

裝完要在**每個 repo 各跑一次** `/setup-matt-pocock-skills`（選 issue tracker、triage 標籤、文件位置）。

## 💬 原文摘錄
- 它的立場（為什麼不做成框架）：
  > "Approaches like GSD, BMAD, and Spec-Kit try to help by owning the process. But while doing so, they take away your control and make bugs in the process hard to resolve. These skills are designed to be small, easy to adapt, and composable."
- 對 agent 加速熵的診斷：
  > "Because agents can radically speed up coding, they also accelerate software entropy. Codebases get more complex at an unprecedented rate."
- 對 `improve-codebase-architecture` 的誠實定位：
  > "It is a **survey, not a rescue**: on a genuinely old codebase it will find real candidates, but it won't untangle the mud for you."
- 結論：
  > "Software engineering fundamentals matter more than ever."

## 🔗 相關
- [[moc/AI技能收藏#skills-for-real-engineers|收藏頁的卡]] — 安裝與 skill 清單速查
- [[Archify 架構圖 skill]] — 另一份寫得極好的 `SKILL.md`；那份強在驗證與誠實條款，這份強在**集合層級的組織與維護**
