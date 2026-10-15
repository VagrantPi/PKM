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
> 這篇在講：Matt Pocock 每天在用的 agent skill（2026-08 收錄時約 24 個；**2026-10-13 依 v1.3.1 重新拆解，共 38 個**，見下方〈全部 38 個 skill 拆解〉）。它的論點是**反 GSD／BMAD／Spec-Kit 那種「接管整個流程」的做法**——那類框架奪走你的控制權，流程出錯還很難修；他主張 skill 要**小、好改、可組合**。而他組織這套 skill 的方式（**user-invoked 負責編排、model-invoked 持有可複用紀律**）比任何單一 skill 都值得抄。

## 🗺 心智圖（Canvas）
![[Skills For Real Engineers.canvas]]

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- 我自己在寫 skill（`/ingest-book`、`/ingest-skill`…），這份 repo 的 `CLAUDE.md` 是**怎麼把 skill 集合維護到不腐爛**的實戰範本。
- 它的四個失敗模式，恰好是我知識庫裡既有工具卡的 agent 版對照——**可以直接複用我已經懂的東西**。
- 作者是 TypeScript 圈的人，但這套 skill 本身**與語言無關**。

## 🧰 這篇給我的工具（連到 tools/ 工具卡）
- [[工具-skill集合的分層與維護]] — 當我的 skill 開始變多、互相呼叫、開始亂的時候
- [[工具-讓agent反過來拷問你]] — 當我「講完需求，agent 做出來的不是我要的」的時候
- [[工具-把agent犯的錯變成環境改善]] — 當 agent 反覆犯同一類錯、CLAUDE.md 越補越長的時候（來自 `retro`）

## ✨ 關鍵重點

### 1. ⭐ 四個失敗模式——而且每個都對應我已經有的工具卡
Matt 的論證主線是「**軟體工程的基本功在 AI 時代更重要**」，他每一段都引經典（Pragmatic Programmer、DDD、XP、A Philosophy of Software Design）。所以這四條在我知識庫裡都已經有對應：

| 失敗模式 | 他的診斷 | 他的解法 | **我 vault 裡的對應卡** |
|---|---|---|---|
| **agent 沒做我要的** | 溝通落差；「沒有人確切知道自己要什麼」 | grilling session：讓 agent 拷問你 | [[工具-建構的先決條件]]（人的版本）＋ [[工具-讓agent反過來拷問你]] |
| **agent 太囉唆** | 缺少共享語言，被丟進專案自己猜行話，用 20 個字講 1 個字的事 | 建 `GLOSSARY.md`（原名 `CONTEXT.md`），把行話固定下來 | [[工具-通用語言]]（DDD 的 ubiquitous language，同一件事） |
| **產出的 code 不能跑** | 回饋迴路不足，agent 在盲飛 | 靜態型別、瀏覽器存取、**紅綠重構** | [[工具-紅綠重構循環]]、[[工具-測試先行的設計]] |
| **建成一團爛泥** | agent 加速編碼，也**加速軟體熵** | 每天投資設計；深模組 | [[大泥球]]、[[工具-可靠可擴展可維護]] |

**我的補註**：這張對照表才是這篇對我最大的價值——**我不需要重學這四件事，只需要知道它們的 agent 版本長怎樣**。所以我沒有為前三項另建工具卡（[[工具-通用語言]] 等已經在了），只補了 vault 真正沒有的兩張。

### 2. ⭐ 集合的分層：誰能叫它，決定它是什麼
> "These split on one axis: **who can invoke them**. **User-invoked** skills are reachable only when you type them; their job is to **orchestrate**. **Model-invoked** skills can be invoked by you or reached for automatically; they hold the **reusable discipline**. A user-invoked skill may invoke model-invoked skills, but **never another user-invoked one**."

具體實例：`grilling` 是 model-invoked 的**可複用面談原語**，被 `grill-me`、`grill-with-docs`、`triage`、`wayfinder`、`improve-codebase-architecture` **五個** user-invoked skill 共用。
技術上是靠 `disable-model-invocation: true` ＋ `agents/openai.yaml` 裡的 `policy.allow_implicit_invocation: false` 標記 user-invoked。

### 3. `GLOSSARY.md`（原名 `CONTEXT.md`）——他自稱整個 repo 最酷的技術
> 1.3.0 起整個 repo 把 `CONTEXT.md`／`CONTEXT-MAP.md` 改名為 `GLOSSARY.md`／`GLOSSARY-MAP.md`，skill 只認新名字；舊專案要自己 `git mv`。

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

## 🗂 全部 38 個 skill 拆解（2026-10-13，依 v1.3.1）

> 由三個子代理逐一讀完每個 `SKILL.md` 與支援檔，主線抽查原文。🧑 = user-invoked（只有人打指令能叫，負責編排）；🤖 = model-invoked（模型也會自己叫，持有可重用的紀律）。

### 主流程與呼叫關係
```
前置（每個 repo 一次）：🧑 /setup-matt-pocock-skills
                     （寫 docs/agents/issue-tracker.md：把「發布／抓單／claim／frontier」翻譯成 gh、glab 或本地檔）

1 對齊：🧑 /grill-with-docs ─► 🤖 grilling ＋ 🤖 domain-modeling（寫 GLOSSARY／ADR）
        🧑 /grill-me ──────► 🤖 grilling（無狀態版）
   └ 旁支：需要可執行的答案 → /handoff → 🤖 prototype → /handoff 帶回
2 成文：🧑 /to-spec（只綜合、不再訪談）→ 🧑 /to-tickets（垂直切片＋blocking）
3 實作：🧑 /implement（一張票）或 🧑 /implement-spec（task graph 平行）
          └─► 🤖 tdd ─► 🤖 codebase-design      最後 ─► 🤖 code-review（Standards／Spec 雙軸）
        🤖 pr（寫 PR 內文時自動用）
4 回顧：🧑 /retro ─► 🤖 writing-for-agents

旁路入口：🧑 /triage（外來 issue）、🤖 diagnosing-bugs（難纏 bug）、🧑 /wayfinder（大而模糊的工作 → 交棒 /to-spec）
路由：🧑 /ask-matt（不確定用哪個就問它）
```
- **步驟 1–3 要在同一個不中斷的 context 裡完成**，`/to-tickets` 之前不 compact；每次 `/implement` 從新 context 開始；`/retro` 要在 `/clear` 之前跑。`ask-matt` 把約 150k token 稱為「smart zone」。
- **鐵律**：🧑 可以呼叫 🤖，但**任何 skill 都叫不到 🧑**。所以需要 setup 當前置條件時，一律寫成「請使用者去跑 `/setup-matt-pocock-skills`」。跨 skill 呼叫一律寫「Call the Skill tool with "x"」，因為只在散文裡提到名字不保證會載入。

### engineering（20 個，每天寫程式用）

**對齊與領域語言**
- 🧑 **grill-with-docs**：全文只有一行，「呼叫兩次 Skill tool，分別呼叫 grilling 和 domain-modeling」。薄入口加厚原語的典型。
- 🤖 **domain-modeling**：維護 `GLOSSARY.md` 與 `docs/adr/`，**有內容才建檔**；術語一定案就當場寫進去，不累積到最後；每個詞附 `_Avoid_` 同義詞。ADR 要**同時**符合三條才提議：難以逆轉、沒脈絡會讓人意外、是真實取捨的結果；一段話就可以是一份 ADR。
- 🤖 **codebase-design**：deep module 的共用詞彙（Module、Interface、Depth、Seam、Adapter、Leverage、Locality），每個詞附 `_Avoid_` 清單，還列出「拒絕的說法」。判準有兩個：**deletion test**（刪掉這個模組，複雜度是消失還是散到 N 個呼叫端）、「一個 adapter 是假想的 seam，兩個才是真的」。內含 Design It Twice：平行開 3 個以上 sub-agent，各給不同約束（最小介面、最大彈性、最常見呼叫者、ports & adapters），比較後給出有主見的推薦。

**成文與拆票**
- 🧑 **to-spec**：把對話整理成 spec 發到 tracker，明令**不再訪談**。模板是使用者視角的問題與解法、很長且編號的 user stories、實作決策、測試決策（seam 越少越好，理想是一個）、out of scope。**不寫檔案路徑與程式碼**，只有原型產出的精確片段（state machine、schema）可以例外。
- 🧑 **to-tickets**：拆成 tracer-bullet 垂直切片（每片貫穿 schema、API、UI、測試），**一片大小要放得進一個新開的 context window**，prefactor（先讓改動變容易）排最前。例外是大範圍機械性重構，改走 **expand–contract**：新舊並存 → 依影響範圍分批遷移、每批 CI 都綠 → 刪舊。依依賴順序建 issue，後建的才能引用真實 id；絕不修改 parent issue。
- 🧑 **wayfinder**：大到一個 session 裝不下的模糊工作。在 tracker 上畫一張「決策 ticket 地圖」：map 只當索引，每個決策只存在自己的 ticket 裡。ticket 分 Research（交給背景 agent）、Prototype、Grilling（預設）、Task 四類。判斷要不要開票，看的是「能不能把問題**精確陳述**」，不是能不能回答；陳述不清的先放在 Not yet specified。用 assignee 當 claim、用原生 blocking 讓 frontier 在 UI 上直接看得到，**每個 session 最多解一張**，地圖完成後交棒給 `/to-spec`。

**實作**
- 🧑 **implement**：一張 ticket、單一 context。開工前先**說出 ticket 標題**確認抓對單 → 在事先談好的 seam 上呼叫 tdd → 頻繁跑 typecheck 與單一測試檔、最後跑一次全部測試 → 呼叫 code-review → commit 到目前分支。不開 PR。
- 🧑 **implement-spec**：一次做完整份 spec。把 tickets 當**有 blocking 關係的 task graph**，持續找出可接手的 frontier，每張票開一個背景 implementer（各自的 worktree 與分支，先吸收 integration branch 的最新版再回報），由 **merger sub-agent** 合進同一條 integration branch，最後跑一次 code-review。tracker 靠 PR 關單或使用者要求時，在第一次 merge 後開 draft PR。**動作最重**：建分支、worktree、merge、可能開 PR、在 tracker 關單。
- 🤖 **tdd**：測試守則。寫測試前先列出 seam **經使用者確認**；點名三個反模式：耦合實作、**同義反覆的斷言**（期望值用跟程式碼一樣的方式算，例如 `expect(add(a,b)).toBe(a+b)`）、先寫完全部測試再實作。一次一個 seam、一個測試、一份最小實作；**重構不在 loop 內**，交給 code-review。只在系統邊界 mock。
- 🤖 **prototype**：拋棄式原型回答一個設計問題。先判斷是「邏輯／狀態對不對」（產出單一 HTML，邏輯寫成可直接搬進正式碼的純模組，附 guided walkthrough）還是「該長什麼樣」（3–5 個**結構不同**的 UI 變體，用 `?variant=` 切換）。原型 commit 到 main 以外的分支，issue 留指標指過去，main 只留決策。
- 🤖 **wizard**：產生互動式 bash 精靈，帶人完成只有人能做的手動程序（去後台拿 API key、設 GitHub secret）。UX 函式庫寫死在模板裡不准改，模型只寫各個 stage；每步有「Done when」。agent **不執行**腳本，改成靜態追蹤：每個 `set_secret` 名稱都要跟 CI 的 `secrets.*` 完全一致。

**品質與收尾**
- 🤖 **code-review**：對某個固定點以來的 diff 做**雙軸**審查。Standards 看有沒有照 repo 規範，Spec 看有沒有照 issue 做。兩個 sub-agent 平行跑，報告**不合併、不跨軸重排**，免得「規範都對但做錯東西」被另一軸蓋過。開 sub-agent 前先驗證 ref 和 diff，壞了就在主線失敗。內建 Fowler 12 種 code smell 當基準，但 repo 自己的規範優先。
- 🤖 **pr**：PR 內文固定三段：**Summary**（能講清楚的最小視覺：pseudocode、call tree、file tree、Mermaid、依主題調整形狀的 diff）、**Evidence**（before／after；截圖是 S 級、執行輸出是 A 級，要寫出「現在會失敗、修完會通過」的那支測試）、**Merge Danger**（one-way 或 two-way door，加一個詞描述影響範圍）。視覺選單取自 Dex Horthy 的 `show-me`，**刻意複製而不依賴**，並用 CREDITS.md 標註出處。
- 🧑 **retro**：回顧 session、改善 agent 的**環境**而不是程式碼 → [[工具-把agent犯的錯變成環境改善]]

**旁路入口**
- 🤖 **diagnosing-bugs**：六階段診斷。★ 第一階段「建回饋迴路」就是整個 skill 的核心：要能指名**一個已經實際跑過的指令**，而且能重現使用者的確切症狀、結果確定、快、agent 自己能跑。「沒有會變紅的指令，就不進第二階段」。接著最小化重現 → 列 3–5 個可證偽假設 → 一次改一個變數（debug log 加唯一前綴，最後一次 grep 清乾淨）→ **有正確 seam 才寫回歸測試**；找不到 seam 本身就是一個架構發現。顯示的指令與輸出一律遮蔽秘密。
- 🧑 **triage**：外來 issue 與外部 PR 的狀態機（2 個分類 × 5 個狀態），每則 AI 留言都要加免責聲明。先查重（用領域概念、不是字面去搜既有實作）和查**被拒絕過的需求**（`.out-of-scope/` 一個概念一個檔），再實際重現 bug 或跑 PR 測試，必要時 grill，最後寫 agent brief（行為契約，不寫路徑與行號）。注意：驗證外部 PR 會在本機執行陌生程式碼，skill 本身沒有提醒這個風險。
- 🧑 **improve-codebase-architecture**：用 git log 熱點決定範圍，開 sub-agent 探索，對疑似淺層的模組做 deletion test，產出寫到 **OS 暫存目錄**的 HTML 報告（不進 repo）。**這階段刻意不提介面設計**，只問「想深入哪一個？」，選定後才進入 grilling；被否決的提議寫成 ADR，下次就不會再提。作者自稱「a survey, not a rescue」。

**輔助**
- 🧑 **ask-matt**：所有 user-reachable skill 的路由，回答前**一定要先讀目標 SKILL.md**，不靠摘要。附一份「階段交界」決策樹：依序判斷 Continue → `/clear` → `/handoff` → 開 sub-agent → `/compact`，第一個答 yes 的勝出；`/compact` 是預設選項，但不是第一個想到的。
- 🧑 **setup-matt-pocock-skills**：先探索 repo，再一節一節問，每節先給推薦答案，草稿確認後才寫入。產出 `docs/agents/{issue-tracker,domain,triage-labels}.md`，並在 CLAUDE.md／AGENTS.md 的 `## Agent skills` 段落原地更新。★ 這是**可抽換後端**的抽象層：其他 skill 只說「發布到 issue tracker」，由這份文件翻譯成 gh、glab 或本地 `.scratch/` 檔，所以換 tracker 不必改任何 skill。
- 🤖 **research**：派背景 agent 只查**第一手來源**（官方文件、原始碼、規格），每個論點都追到擁有它的來源，寫成一份附出處的 Markdown。全文只有 12 行。

### productivity（7 個，每天的非程式工作）
- 🤖 **grilling**：所有拷問的本體，被 grill-me、grill-with-docs、triage、wayfinder、improve-codebase-architecture 五個 skill 共用。把題目展開成**決策樹**，每輪問完所有「前置條件已定」的題目，每題附建議答案。★ 措辭要讓回答「yes」就等於採用建議。**事實由 agent 派 sub-agent 去查，決策才問人**；frontier 問空、且使用者確認雙方有共識才結束。刻意不設題數上限、不用原生提問 UI → [[工具-讓agent反過來拷問你]]
- 🧑 **grill-me**：一行，呼叫 grilling。沒有工作目錄時用它，有的話用 grill-with-docs。
- 🧑 **handoff**：把對話壓成交接文件，存在 OS 暫存目錄、不進工作區；**只放指標不複製**（spec、ADR、issue、commit 只寫連結）；附「建議下一個 agent 用哪些 skill」；遮蔽秘密。
- 🧑 **teach**：把目前目錄變成有狀態的教學工作區（MISSION、learning-records、lessons 等）。原則是「不信任模型記憶，先找可信來源」；區分流暢度與記憶強度，運用提取練習、間隔、交錯練習；**「教過不等於學會，要等到證據」**才寫學習紀錄；測驗選項要等長、正解位置要輪換，避免從格式猜出答案。
- 🧑 **to-questionnaire**：自己答不了的決策，做成一份給別人填的問卷。只問使用者答得出來的事（要寄給誰、要拿回什麼），再用答案去瞄準資訊落差；題目依重要性排序，因為非同步作答可能只有一次機會。
- 🧑 **wait-what**：看不懂上一則回覆時用，一句話要求 agent 補脈絡、改用 ASD-STE100 簡化技術英文、用 GLOSSARY 的詞。★ 以「聽者的狀態」命名，比 `/tldr` 這種以「輸出」命名更能同時要求「少一點字」和「補上缺的脈絡」。
- 🤖 **writing-for-agents**：寫 skill、AGENTS.md、被指向的文件時的準則。重點有四：決定內容會不會被讀到的是**指標的措辭**（先磨利措辭，不行才把內容內嵌）；區分常駐的 context 負載與人要記住東西的認知負載；逐句刪掉 no-op；環境本身就是真實來源，文件只快取查不到的東西（慣例、理由、地雷）。原名 `writing-great-skills`。

### misc（4 個，已凍結不維護，不進 plugin）
四個都是 🤖，而且都有實際副作用。要抄的話建議改成 🧑。
- **git-guardrails-claude-code**：安裝 PreToolUse hook 擋 `git push`、`reset --hard`、`clean -f` 等，安裝後用假輸入驗證 exit code 2。已知漏洞官方不會修：沒有 `jq` 時直接放行，`git -C x push` 能繞過。
- **setup-pre-commit**：裝 Husky、lint-staged、Prettier，把 typecheck 與 test 接進 pre-commit；**最後自動 commit 一次，當作 hook 的冒煙測試**。
- **migrate-to-shoehorn**：把測試裡的 `as` 斷言換成 `@total-typescript/shoehorn`。安裝指令寫死 `npm i` 而且沒加 `-D`。
- **scaffold-exercises**：建 AI Hero 課程的練習目錄並跑到 lint 通過，綁定作者的私有 CLI，別的專案用不上。

### in-progress（7 個，beta，不進 plugin，隨時會變）
全部是 🧑。
- **chief-of-staff**：單一長 session 當「幕僚長」，所有工作交給 sub-agent 保護主 context；每個任務都同時想戰術（做完眼前這件）與戰略（讓下一件更順）。沒有步驟和完成判準。
- **claude-handoff**：寫好交接後直接 `claude --bg --name … -- "$(cat 檔)"` 開背景 agent 接手；用讀檔的方式傳 prompt，避開 shell 展開反引號和 `$`。
- **loop-me**：有狀態的 grilling，產出 `workflows/*.md` 工作流規格。詞彙有 Trigger、Checkpoint、**Push right**（人工確認點盡量往後延）、**Brief**（給人看的是可直接決策的摘要，不是原始輸出）。完成判準是「實作的 agent 不需要再問任何問題」。
- **setup-ts-deep-modules**：用 dependency-cruiser 規定每個 TS package 只能從根目錄的 entry point 匯入。★ 完成判準是「**證明規則會咬人**」：先 pass → 故意加一個越界 import → 必須 fail → 還原 → pass。
- **writing-fragments**、**writing-shape**、**writing-beats**：寫作三件套。fragments 是發散階段，只附加片段、寫入前先重讀檔案、保住使用者的手動編輯；shape 與 beats 是收斂階段，追蹤讀者已經理解的概念，不准用還沒建立的概念，beats 一次只寫一步。

### 2026-08 → 10 的變化（依 CHANGELOG，CHANGELOG 本身沒有日期）
- **改名或合併**：
  - `diagnose` 改名為 `diagnosing-bugs`；`to-prd` 改名為 `to-spec`。
  - `to-issues` 與 `to-plan` 合併成 `to-tickets`。
  - `ubiquitous-language` 退役，併入 `domain-modeling`。
  - `review` 改名為 `code-review`；`decision-mapping` 改名為 `wayfinder`。
  - `write-a-skill` 改由 `writing-great-skills` 取代，後者再改名為 `writing-for-agents`。
- **移除**：
  - `design-an-interface` 併入 codebase-design 的 Design It Twice。
  - `request-refactor-plan` 由 to-spec 與 improve-codebase-architecture 吸收。
  - `zoom-out`、`caveman`、`qa`、`edit-article`、`obsidian-vault` 移除。
  - `resolving-merge-conflicts` 在 1.3.0 移除，沒有替代品。
- **升級到正式桶**：`implement-spec`、`pr`、`retro`、`wizard`、`to-questionnaire`。
- **慣例**：`CONTEXT.md` 改為 `GLOSSARY.md`；跨 skill 呼叫統一寫成「Call the Skill tool」；修掉 6 處「呼叫了 user-invoked skill」的違規；全 repo 移除破折號後，有 6 個 skill 的 description 因冒號造成 YAML 失效、裝不起來，已修正。

### 跨 skill 值得抄的 8 個模式
1. **薄入口、厚原語**：人叫的入口一行就好，可重用的紀律放在模型也能叫的原語裡，邏輯只有一份。
2. **硬閘門＋可觀察的完成判準**：「沒有會變紅的指令就不進下一步」「證明規則會咬人」「先問完介面以外的事」。直接點名要防的失敗模式。
3. **context 預算是一級設計參數**：一張票放得進一個新 context、wayfinder 一個 session 一張、規範交給壓力最小的 reviewer、溝通給指標不貼全文。
4. **可抽換的後端抽成一份文件**：tracker 操作集中在 setup 產生的檔案，skill 只講抽象動作。
5. **耐久性優先**：spec、ticket、agent brief 都不寫路徑與行號，寫行為契約。
6. **記住被拒絕的決策**：ADR 和 `.out-of-scope/` 讓下一輪不重提、能去重。
7. **產出不污染 repo**：報告與交接放 OS 暫存目錄，原型與研究放 main 以外的分支，文件有內容才建。
8. **事實由 agent 查，決策由人做**，而且問題措辭讓「yes」等於採用建議，壓低人的回答成本。

### 讀檔時發現的不一致（非官方）
- README 說 tdd 是「red-green-refactor」，SKILL.md 卻說重構不在 loop 內。
- to-spec 說「不訪談」，卻要求跟使用者確認測試 seam。
- beta 桶沒照自家慣例：
  - loop-me、writing-fragments 只在散文裡提到 grilling，CHANGELOG 說這種寫法不保證會載入。
  - claude-handoff 把 handoff 的規則整段複製一份。
  - chief-of-staff 沒列在 in-progress 的 README。
  - setup-ts-deep-modules 說有四條規則，設定檔實際有五條。

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
