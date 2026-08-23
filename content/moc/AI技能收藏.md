---
type: moc
title: "AI 技能收藏"
tags: [moc, ai, skills, agent, tooling]
---

> 收藏值得一試的 **AI agent 外掛**——skill、plugin、MCP server 都收（Claude Code / Codex / 其他平台）。
>
> ⚠️ **這頁收的是外部現成工具**（不是我從書裡萃取的心法）。每張卡記「做什麼、裝哪、怎麼用、我試了沒」；**我自己跑的對照實測結論在 [[moc/AI技能評比|AI 技能評比]]**，這裡只放一句話 + 連結，不重抄。

**圖例**　型態：`skill` `plugin` `MCP`　狀態：⬜ 待試・✅ 已在用・📊 已跑實測
（★ 為查看當時概數，非即時。）

## 📇 快速索引

| Skill | 型態 | 平台 | 一句話 | 來源 | 狀態 |
|---|---|---|---|---|---|
| [gc-minimal-zine-poster](#gc-minimal-zine-poster) | skill | Codex | 主題／照片 → 極簡 zine 風海報，直接生圖 | [repo↗](https://github.com/LiamGvchi/gc-minimal-zine-poster) | ⬜ |
| [editorial-vision-studio](#editorial-vision-studio) | skill | Codex | 視覺導演引擎：決策管線＋可換模型 adapter | [repo↗](https://github.com/Yu-0312/editorial-vision-studio) | ⬜ |
| [MiniMax-H3 skills](#minimax-h3-skills) | skill | npx skills | H3 全模態影音模型附的九個 prompt／影片生成 skill | [repo↗](https://github.com/MiniMax-AI/MiniMax-H3) | ⬜ |
| [i-have-adhd](#i-have-adhd) | plugin | Claude・Codex | 逼 agent 答案先講、不鋪陳客套 | [repo↗](https://github.com/ayghri/i-have-adhd) | ⬜ 📊 |
| [ponytail](#ponytail) | plugin | 多平台 | 寫碼前爬「該不該寫」階梯，砍過度設計 | [repo↗](https://github.com/dietrichgebert/ponytail) | ⬜ 📊 |
| [eli5](#eli5) | skill | Claude Code | 依聽眾（5 歲／主管／工程師／家人）換一套講法解釋同一件事 | [repo↗](https://github.com/DreambigOu/ELI5) | ⬜ |
| [codegraph](#codegraph) | MCP | 多平台 | 本機碼圖譜，讀流程強、caller 會漏 | [repo↗](https://github.com/colbymchenry/codegraph) | ✅ 📊 |
| [codebase-memory-mcp](#codebase-memory-mcp) | MCP | 多平台 | 同路線，caller 完整、只給名稱無 body | [repo↗](https://github.com/DeusData/codebase-memory-mcp) | ✅ 📊 |

---

## 🎨 圖像與影片

### gc-minimal-zine-poster
`skill` · Codex · MIT · ★113 · ⬜ 待試

**做什麼**：把主題／句子／物件／心情／文章點子／照片，編譯成「安靜極簡 zine 風編輯海報」的生成 prompt，並直接產圖。

**核心**（它的靈魂——不是通用生圖，而是把風格鎖死往一個方向壓）
- 3:5 **老化紙張**畫布、**70–90% 留白**
- **只有一個**小主體或視覺聚落
- 襯線／打字機／等寬字 ＋ **一個高彩度色錨**
- xerox／riso／halftone／凸版／掃描紙張的瑕疵感、日韓獨立誌的安靜氛圍
- 刻意避開：商業廣告版面、光亮 mockup、電影感打光、3D、霓虹、拼貼 scrapbook、大段乾淨文字

**裝**
```bash
git clone https://github.com/LiamGvchi/gc-minimal-zine-poster.git \
  ~/.codex/skills/gc-minimal-zine-poster-v0-1
```
可呼叫名稱 `gc-minimal-zine-poster-v0-1`；沒出現就重啟 Codex。

**用**：呼叫名稱給一個主題／簡報，例「用 $gc-minimal-zine-poster-v0-1 做一張關於雨天舊書店的海報」（也可餵句子／點子／物件／心情／參考圖）。輸出＝海報圖＋最終 prompt＋變體配方與詮釋註記；預設直接生圖，明確說「只要 prompt」才停。

**🔗 相關**：[editorial-vision-studio](#editorial-vision-studio) 是它的演進版——把「鎖死一種 zine 風」開放成可選風格與版面。

### editorial-vision-studio
`skill` · Codex · MIT · ★96 · ⬜ 待試

**做什麼**：AI 圖像／編輯設計的「視覺導演引擎」。不直接寫 prompt，先跑決策管線（**判斷用途 → 分析畫面 → 定視覺語言 → 規劃版面與風格 → 補救 → 產出模型無關的 VisionSpec**），最後才用 adapter 轉成該模型的 prompt。哲學：「不要裝飾，一律詮釋。」

**核心**
- **決策引擎固定、模型 adapter 可抽換**：換模型（GPT Image → Flux → Ideogram）只重跑 adapter，不重新分析。
- adapter：`gpt-image`（照片保真，預設）／`flux`（小誌質感）／`ideogram`（封面字體）／`generic`。
- 十種風格 DNA（Swiss／MUJI／Kinfolk／Monocle／COS／Brutalist／Wallpaper*／Apartamento／Purple／POPEYE）× 多版面（海報／封面／展覽圖／小誌／首圖／活動／品牌主視覺／產品編輯圖／moodboard）。
- 產圖前 **Reviewer 擋風格衝突**（MUJI 配重標題、Swiss 配 Kinfolk 有機感、展覽圖塞太多字）。
- **Panter Mode**：低對比／灰掉的照片，用暖冷衝突色＋高彩度色錨＋拉開明暗來救（只補色、不加材質）。

**裝**
```bash
mkdir -p ~/.codex/skills
git clone https://github.com/Yu-0312/editorial-vision-studio.git \
  ~/.codex/skills/editorial-vision-studio
```
沒出現就重啟 Codex。

**用**：描述用途或給照片，例「用 editorial-vision-studio，把這張照片重新構圖為極簡展覽插畫提示詞，別保留寫實細節」。可指定 `style:`（如 `kinfolk`）或 `model:`（如 `flux`），指定時跳過自動推導但 Reviewer 仍驗證風格相容。輸出預設＝方向摘要＋GenerationRequest（prompt 英文、摘要跟隨你語言）；分析照片才附 Image Report，換模型才附完整 VisionSpec。

**🔗 相關**：[gc-minimal-zine-poster](#gc-minimal-zine-poster)（前身之一）。

### MiniMax-H3 skills
`skill` · npx skills · MiniMax H3 Community License · ★1.6k · ⬜ 待試

**做什麼**：MiniMax 開源全模態影音生成模型 **H3** 附的**九個 skill**，把「怎麼對 H3 下 prompt／做特定風格影片」包成可直接裝的技能。（模型本身的能力與架構 → [[articles/MiniMax H3 全模態生成模型|模型筆記]]）

**九個 skill**
- `h3-prompt-writing`：H3 的 prompt 寫法指南（附 `base-en.txt` 給 text／keyframe 模式、`ref-en.txt` 給 full-reference Ref2VA 模式）。
- 八個風格化影片生成：`minimalist-product-ad-generator`、`3d-animation-short-generator`、`papercraft-stop-motion-explainer`、`brand-promo-video-generator`、`music-video-subtitle-generator`、`co-op-game-intro-generator`、`paper-collage-explainer-generator`、`handdrawn-live-video-generator`。

**裝**（以 prompt-writing 為例，其餘換 `--skill` 名稱）
```bash
npx skills add https://github.com/MiniMax-AI/MiniMax-H3 --skill h3-prompt-writing
```

**用**：skill 本身是 prompt 與流程指南，實際生成靠 H3 模型——搭配 H3 的 API／App，或本機部署的 H3-Base（768p，2K 需官方 Regenerate-2K API）。

**🔗 相關**：[[articles/MiniMax H3 全模態生成模型|MiniMax H3（模型筆記）]]

---

## 🧠 回應風格與寫碼紀律

> 這兩個是「**改 agent 行為**」不是「給新能力」，裝上每輪生效——想清楚要哪種預設。
>
> 📊 已跑對照實測 → [[moc/AI技能評比|AI 技能評比]]（2026-08-05）。結論：答案確實變短，但**短在少講三分之一概念**，且 **output token 沒省到**。

### i-have-adhd
`plugin` · Claude Code・Codex · MIT · ★16.7k · ⬜ 待試 · 📊

**做什麼**：讓 coding agent **不要把答案埋起來**——動作先講、多步驟編號、不「Hope this helps!」。不需 ADHD 診斷也適用。

**核心**（十條規則，全文在 repo 的 `SKILL.md`）
先講下一動作／多步驟編號／結尾給下一步／壓離題／每輪重述狀態／時間估算講分鐘／進展看得見／錯誤就事論事／清單 ≤5 項／無開場白回顧結語。出處：鬆散取材《The Adult ADHD Tool Kit》，改寫成「LLM 該怎麼回應」。

**裝**
```bash
# Claude Code
claude plugin marketplace add ayghri/i-have-adhd
claude plugin install i-have-adhd@i-have-adhd
# Codex
codex plugin marketplace add ayghri/i-have-adhd --ref main
codex plugin add i-have-adhd@i-have-adhd
```

**⚠️ 注意**：會壓掉推理過程與脈絡。「已知道要什麼」的任務很爽，「需要一起想清楚」的可能反而礙事。

**📊 實測**：概念覆蓋 **−17%**（三組裡壓最輕），四組裡最會給「起點與終點」 → [[moc/AI技能評比|評比]]

### ponytail
`plugin` · 多平台 · MIT · ★95.7k · ⬜ 待試 · 📊

**做什麼**：把「看你五十行程式碼一句話不說就換成一行」的資深工程師塞進 agent。寫碼前先爬一道階梯，停在第一個成立的階。

**核心**（決策階梯）
```
1 需要存在嗎？   → 不需要:跳過 (YAGNI)
2 codebase 已有？ → 沿用，不重寫
3 標準函式庫可以？ → 用它
4 平台原生可以？   → 用它
5 已裝依賴可以？   → 用它
6 一行寫得完？     → 一行
7 才動手：能動的最小量
```
兩個限定（別誤讀成「叫 AI 偷懶」）：階梯是**讀懂問題之後**才跑（對解法懶、**對閱讀絕不懶**）；信任邊界驗證／資料遺失／資安／無障礙**永遠不在被砍名單**。

**裝**（Claude Code 要分兩則訊息送）
```
/plugin marketplace add DietrichGebert/ponytail
/plugin install ponytail@ponytail
```
```bash
# Codex
codex plugin marketplace add DietrichGebert/ponytail
codex plugin add ponytail@ponytail
```
需 `node` 在 PATH（跑兩個 lifecycle hook；沒有的話常駐會安靜失效）。

**用**：六指令 `/ponytail`・`-review`・`-audit`・`-debt`・`-gain`・`-help`；強度 `lite`/`full`/`ultra`/`off`。

**⚠️ 注意**：對「花 thinking token 反覆推敲階梯」的推理模型，成本可能**反而變高**（README 點名 GPT-5.5）。

**📊 實測**：概念覆蓋 **−31%**（壓最多），與 i-have-adhd 同開由它主導（−33% 非相加）；**output token 沒省到，別為省錢開** → [[moc/AI技能評比|評比]]

**宣稱數字**（README，未驗證）：fastapi-template 12 ticket、Haiku 4.5、n=4：LOC −54%、token −22%、成本 −20%、時間 −27%、安全 100%（−54% 是均值，過度設計可到 −94%，本來精簡的接近 0）。

---

## 🗣 解釋與表達

> 跟上面的「回應風格」差在**生效時機**：那些是 plugin，裝上每輪都在改你的 agent；這類是 skill，**被觸發才上場**，平常不動預設行為。所以風險低、但也要留意觸發詞會不會誤觸。

### eli5
`skill` · Claude Code · MIT · ★143 · ⬜ 待試

**做什麼**：把同一個東西（概念／一段 code／一則錯誤訊息）**換一套講法講給不同的人聽**——5 歲小孩、5 年級生、主管、設計師、研究生、你媽。不是「講簡單一點」，是換分析框架。

**核心**（它的靈魂＝一張「聽眾 → 校準參數」對照表，不是一句「說人話」）
- **四類聽眾**：年齡（5／10／15／20–30／40+）、學程（5 年級／國中／高中／大學／研究所）、職務（主管／工程師／設計師／總監／PM／同事）、關係（伴侶／父母／小孩／朋友）。
- **五個校準維度**：用詞、類比、語氣、深度、**框架**。框架是重點——主管框「影響／風險／要做什麼決定」、設計師框「使用者體驗與互動」、工程師框「架構與取捨」。
- **會反向加難度**：對工程師／研究生**刻意用術語**（「不用專有名詞他們會覺得被當白痴」），對主管**砍掉實作細節**。所以它不是單向的簡化器。
- 固定結構：一句話講「是什麼」→ 給類比 → 補細節 → 收在「所以這對**你**有什麼影響」。
- **沒指定聽眾就預設 Age 5。**
- 明講的取捨：對非技術聽眾，**「80% 正確但聽得懂」勝過「100% 正確但聽不下去」**。

**裝**
```bash
git clone https://github.com/DreambigOu/ELI5.git
cp -r ELI5/skills/eli5 ~/.claude/skills/eli5
```
眉角：repo 名是大寫 `ELI5`，但 skill 本體在子目錄 `skills/eli5`——**只 clone 不 `cp` 不會生效**。

**用**：講白話就會觸發，例「ELI5 什麼是 database index」「把這段 code 解釋給我主管聽」「用 5 年級生聽得懂的方式講 git merge conflict」「解釋這個錯誤給我媽」。

**⚠️ 注意**
- **不讀 codebase、不改設定檔**——就是一個 prompt 檔，裝了不會有副作用。
- **沒講聽眾就當你是 5 歲**。想要「簡潔的專業說明」時會過頭，要明講對象。
- **觸發詞很寬**（`explain this to my`／`break this down for`／`dumb it down`／`simplify this for`），只想要一般說明時可能被誤觸。
- SKILL.md **全英文**，類比取材也是英語語境（玩具、遊樂場、社群媒體）。**用中文問時類比貼不貼，未驗證。**

**宣稱數字**（README，未驗證）
- repo 裡**兩份數字對不起來**，原因在作者的 blog（[[做一個 ELI5 Skill 的過程]]）：
  - `eval-results.md` 的 **91.7% vs 33.3%（+58.3%）**、token +23%、平均快 14.4s ← skill-creator 那次的**人工評分**。
  - README 的 **83.3% vs 41.6%（+41.7%）** ← 後來本地腳本的 **LLM auto-grader**。
  - 兩者鬆緊剛好相反：auto-grader 抓到「主管那題超過 500 字」，卻放過了人工判 fail 的「phone book 類比」。**別把兩份混著比。**
- 條件：**3 題 × 4 條 assertion＝12 條**，每組**各只跑 1 次**，無重複、無雜訊底線；`claude -p` **未指定 model**；**評分由 Claude 自評**。
- 最該知道的一點：with-skill 那組是在題目前面加「Read the skill at `<path>` first, then follow its instructions」——所以它測的是「**SKILL.md 的內容有沒有用**」，**不是「這個 skill 會不會被正確自動觸發」**。後者沒測。
- 作者自陳最大增益在**主管**這一類（baseline 0/4 → 3/4）。

**🔗 相關**
- [[做一個 ELI5 Skill 的過程]] — 作者怎麼做出它的（skill-creator 流程），以及上面那兩份數字的來歷
- [[如何評測一個 Claude Code Skill]] — 它的 eval 腳本怎麼運作、為什麼單次結果不能信
- [i-have-adhd](#i-have-adhd) 是另一頭——同樣在動輸出風格，但它是 plugin **每輪生效改紀律**（怎麼排版答案），eli5 是 skill **被叫才上場換框架**（講給誰聽）。想同時裝要想清楚要哪種預設。

---

## 🔍 程式碼理解（MCP）

> **兩者表面做同一件事**：本機把 codebase 建成知識圖譜（symbol、呼叫邊、依賴），一次呼叫拿到相關源碼＋呼叫路徑，取代「grep → 逐檔讀」的迴圈。都主打 100% 本機、碼不外流。
>
> 📊 **實測顯示互補、不是二選一**：影響分析（誰呼叫我）用 codebase-memory；讀流程／快速讀懂機制用 codegraph → [[moc/AI技能評比|AI 技能評比]]（2026-08-05）。
>
> ~~同時裝兩套沒有意義，選一套即可。~~ ← 我自己的推論，已被實測推翻，留著當紀錄。

### codegraph
`MCP` · 多平台 · MIT · ★64k · ✅ 已在用 · 📊

**做什麼**：本機程式碼知識圖譜（Rust kernel）。核心工具 `codegraph_explore` 一次給相關 symbol 的**逐字源碼**＋**呼叫路徑**（含 grep 追不到的 dynamic dispatch）＋改動 blast radius。

**裝**
```bash
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
codegraph install               # 接上各家 agent，不建索引
cd your-project && codegraph init  # 每個專案各自建圖
```
auto-sync 預設開，改檔即更新。本機 v1.4.1，官方已出 1.5.0（`codegraph upgrade`）。

**用**：只在有 `.codegraph/` 目錄的 repo 用（建索引我自己決定，不讓 agent 代跑 `init`）。已寫進全域 `CLAUDE.md`。

**📊 實測**：讀流程／快速讀懂贏；**caller 會漏**（巢狀函式、singleton 方法），影響分析別只信它 → [[moc/AI技能評比|評比]]

**宣稱數字**（README，未驗證）：工具呼叫 −89%、token −69%、7 repo 檔案讀取全部歸零；但小 repo 有地板效應、強模型直接 grep wall-clock 更快（只是燒 5–10 倍 token）。

### codebase-memory-mcp
`MCP` · 43 client surface · MIT · ★37.4k · ✅ 已在用 · 📊

**做什麼**：同是本機程式碼知識圖譜，路線差在**廣度與速度**：tree-sitter AST 覆蓋 **158 種語言**（其中 12 種另加 LSP 語意型別解析），單一靜態 binary、零依賴。15 個 MCP 工具（死碼偵測／跨服務 HTTP 串接／Cypher／ADR），另把 Dockerfile／K8s／Kustomize 也建進圖。

**裝**
```bash
curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash
# 要 3D 圖譜視覺化(localhost:9749)：加 -s -- --ui
```
重啟 agent 後說「Index this project」。快取在 `~/.cache/codebase-memory-mcp/`。

**⚠️ 注意**：它**會讀你的 codebase、也會寫你的 agent 設定檔**；跨 client 共用一個 coordination daemon（無 opt-in，第一個 session 啟動、最後一個關掉）；所有 CBM process 版本**必須完全一致**，否則被 admission barrier 擋下。

**📊 實測**：**caller 完整性全勝**（type-aware LSP）；Cypher／跨程序迴圈深度／語意搜尋／co-change 耦合是它獨有；但只給名稱清單、無 body → [[moc/AI技能評比|評比]]（實測用 **pro 版**，與開源版功能集是否相同未查證）

**宣稱數字**（README，未驗證）：Linux kernel 28M LOC 3 分鐘建完、結構查詢 <1ms；preprint arXiv:2603.27277，31 repo：品質 83%、token 少 10×、工具呼叫少 2.1×。

---

## 🔗 相關
- 📊 自己跑的對照實測報告 → [[moc/AI技能評比|AI 技能評比]]
- 自己在用的 gstack skills（/browse、/review、/ship 等）不收在這頁，那些是工作流不是收藏
- 打造自己的 AI 工具：[[moc/MCP|MCP]]、[[moc/AI工程|AI工程]]
