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
| [mono-color](#mono-color) | skill | Claude Code・多平台 | 單色／雙色編輯印刷風格圖像，最多兩塊印版的硬約束 | [repo↗](https://github.com/yanliudesign/mono-color-skill) | ⬜ |
| [MiniMax-H3 skills](#minimax-h3-skills) | skill | npx skills | H3 全模態影音模型附的九個 prompt／影片生成 skill | [repo↗](https://github.com/MiniMax-AI/MiniMax-H3) | ⬜ |
| [ai-short-drama-screenwriter](#ai-short-drama-screenwriter) | skill | Codex | 繁中短劇編劇：八階段流程＋可拍性檢查，只做劇本不越界 | [repo↗](https://github.com/POUND0423/AI-drama-pound) | ⬜ |
| [scroll-world](#scroll-world) | skill | Claude Code・Codex・多平台 | 生成 AI 場景＋鏡頭影片，做捲動穿梭的沉浸式落地頁（**會扣真錢**） | [repo↗](https://github.com/oso95/scroll-world) | ⬜ |
| [superpowers](#superpowers) | plugin | 15+ harness | 一整套強制執行的開發方法論：腦力激盪→計劃→TDD→subagent 執行→審查 | [repo↗](https://github.com/obra/superpowers) | ⬜ |
| [Skills For Real Engineers](#skills-for-real-engineers) | plugin | Claude Code・多平台 | Matt Pocock 的 38 個 skill（v1.3.1）：拷問→規格→票→實作→審查→PR→回顧 | [repo↗](https://github.com/mattpocock/skills) | ⬜ |
| [archify](#archify) | skill | 多平台 | codebase／描述 → 會自我驗證的互動架構圖 HTML | [repo↗](https://github.com/tt-a1i/archify) | ⬜ |
| [architecture-diagram-generator](#architecture-diagram-generator) | skill | Claude.ai・Claude Code | 描述 → 深色主題架構圖 HTML；純 prompt＋設計規範，**不驗證** | [repo↗](https://github.com/Cocoon-AI/architecture-diagram-generator) | ⬜ |
| [i-have-adhd](#i-have-adhd) | plugin | Claude・Codex | 逼 agent 答案先講、不鋪陳客套 | [repo↗](https://github.com/ayghri/i-have-adhd) | ⬜ 📊 |
| [ponytail](#ponytail) | plugin | 多平台 | 寫碼前爬「該不該寫」階梯，砍過度設計 | [repo↗](https://github.com/dietrichgebert/ponytail) | ⬜ 📊 |
| [go-modern-guidelines](#go-modern-guidelines) | plugin | 多平台 | 給 agent 一份現代 Go 對照表，別再產出過時寫法 | [repo↗](https://github.com/JetBrains/go-modern-guidelines) | ⬜ |
| [karpathy-guidelines](#karpathy-guidelines) | plugin | Claude Code・Cursor | 四條原則治 LLM 寫碼的老毛病：亂假設、過度設計、順手亂改 | [repo↗](https://github.com/multica-ai/andrej-karpathy-skills) | ⬜ |
| [eli5](#eli5) | skill | Claude Code | 依聽眾（5 歲／主管／工程師／家人）換一套講法解釋同一件事 | [repo↗](https://github.com/DreambigOu/ELI5) | ⬜ |
| [codegraph](#codegraph) | MCP | 多平台 | 本機碼圖譜，讀流程強；caller 10 月重測全中 | [repo↗](https://github.com/colbymchenry/codegraph) | ✅ 📊 |
| [codebase-memory-mcp](#codebase-memory-mcp) | MCP | 多平台 | 同路線，caller 完整、只給名稱無 body | [repo↗](https://github.com/DeusData/codebase-memory-mcp) | ✅ 📊 |
| [graphify](#graphify) | skill | 多平台 | 程式碼＋文件＋PDF 建成一張圖，每條邊標可信度（EXTRACTED／INFERRED／AMBIGUOUS） | [repo↗](https://github.com/Graphify-Labs/graphify) | ⬜ 📊 |
| [GitNexus](#gitnexus) | MCP | 多平台 | 程式碼圖資料庫＋19 個 MCP 工具（影響分析、執行流、改名），**非商用授權** | [repo↗](https://github.com/abhigyanpatwari/GitNexus) | ⬜ 📊 |
| [Understand-Anything](#understand-anything) | plugin | Claude Code・多平台 | 多 agent 分析 codebase → 互動式儀表板＋導覽，給新人看懂專案 | [repo↗](https://github.com/Egonex-AI/Understand-Anything) | ✅ 📊 |

---

## 🎨 影像與內容創作

### gc-minimal-zine-poster
`skill` · Codex · MIT · ★7.3k（2026-10-15） · ⬜ 待試

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
`skill` · Codex · MIT · ★227（2026-10-15） · ⬜ 待試

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

### mono-color
`skill` · Claude Code（其他 agent 可載入 `SKILL.md`） · MIT（**例外見注意**） · ★3.4k（2026-10-15） · ⬜ 待試

**做什麼**：把主題／句子／物件／照片，做成**單色或受控雙色的編輯印刷風格圖像**——海報、zine、肖像、包裝、視覺筆記。輸出是「一張印出來的紙」，不是數位單色濾鏡。

**核心**（靈魂是**把印刷的物理限制當成設計約束**）
- ⭐ **最多兩塊印版**，這是硬規則。預設受控雙色：**主版佔 70–85%、輔版 15–30%，而且輔版必須有明確任務**（日期、註記、選定物件、疊印交界）。明確要求單色才走單版。
  - **紙張不是第三色，兩版疊印產生的深色也不是第三種墨。**
- **紙張要看得見**、**留白佔 25–55% 且有結構**、照片一律走機械複製（網點、顆粒、爆亮部、油墨堆積、輕微套印偏移）。
- **色票是寫死的**：八種單色墨（Cobalt `#2148B8`、Signal Red `#C83232`、Charcoal `#30343A`…）與九組雙色配方，都附 hex。
- ⭐ **`design-system/` 是機器可讀的目錄**（色彩 token、字體角色、構圖幾何、節奏、受控印刷瑕疵各自成檔）。文件明說 **catalog ID 是「參考板、配方、驗證」三者之間的共同契約**——把視覺語彙從散文流程裡抽出來，變成可檢查的資料。
- ⭐ **`rhythm.json` 對「放鬆」的定義很特別**：放鬆是**不均勻的能量**，不是整體降低強度。每頁挑**一個大膽的焦點事件**（超大字、極端裁切、單一巨大細節、集中疊印、異常尺度關係），其餘用紙張、淡網與稀疏功能字釋放。
- **有評測合約與 CI**：`validate_evals.py`、`validate_design_system.py`，GitHub Actions 在每次 PR 與推送都跑。
- **明確的「不要什麼」清單**（8 條）：不要全彩照片套單色濾鏡、不要玻璃質感 mockup／3D／漸層、不要置中模板或貼紙拼貼、**不要因為用了網點與限色就自動做成復古泛黃**、不要編造品牌與 QR code、不要重建參考海報。
- **參考是文法不是模板**：從任何提供的參考至少改動**四個結構變數**。

**裝**
```bash
git clone https://github.com/yanliudesign/mono-color-skill.git   ~/.claude/skills/mono-color
```
裝完重啟 Claude Code。其他 agent 環境可直接把 `SKILL.md` 當入口載入。

**用**：`用 mono-color 做一張關於午夜便利商店的直式海報，標題就用「still open」。`
可指定墨色與模式，例「Charcoal + Signal Red 的混凝土建築展覽海報，紅版只用在日期、地點與一個幾何干擾」。

**⚠️ 注意**
- 🔴 **授權有例外，不是整包 MIT**：程式碼、skill 指令與腳本是 MIT，但 **`examples/` 的原創作品 © 2026 Yan Liu，不在 MIT 範圍內**；作為研究依據的十二張第三方參考圖仍屬各自權利人。**拿它產圖沒問題，直接轉用 repo 裡的範例圖要看清楚。**
- **圖像生成工具不可用時不會假裝成功**：會回傳 production-ready prompt 並明說限制。
- **驗證腳本要 `python3`**（repo 語言 100% Python）。
- **沒有發布任何 release、單一貢獻者**。

**🔗 相關**
- [gc-minimal-zine-poster](#gc-minimal-zine-poster)、[editorial-vision-studio](#editorial-vision-studio) —— 三張海報 skill 的分工：`gc-` **鎖死一種** zine 風；`editorial-vision-studio` 開放**可選風格與可換模型**；`mono-color` 走**印刷限制**這條路（最多兩塊版），約束來自製程而非品味。
- [[工具-讓LLM產出可驗證的產物]] —— 它的 `design-system/*.json` ＋ 驗證腳本 ＋ CI，正是那張卡講的「把判斷交給模型、把可驗證的部分交給程式」，只是套用在美學上。

### MiniMax-H3 skills
`skill` · npx skills · MiniMax H3 Community License · ★10k（2026-10-15） · ⬜ 待試

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

### ai-short-drama-screenwriter
`skill` · Codex（桌面版／CLI／IDE extension） · MIT · ★562（2026-10-15） · ⬜ 待試

**做什麼**：**繁體中文**的短劇／豎屏短劇編劇——選題、全劇與單集結構、角色關係、分場、臺詞、衝突、反轉、鉤子、格式與修改。輸出是**標準短劇格式**（場次、內／外景、地點、時間、動作、角色名、臺詞、畫面文字），可直接進製作。

**核心**（靈魂是**範圍紀律**，不是文采）
- **任務路由**：完整專案／單點創作／混合交付／格式化／審閱修改，各走不同路徑，只讀對應的 `references/`（`workflow.md`／`format.md`／`checklists.md`）——主 SKILL.md 保持精簡。
- **可拍性的硬規則**：每場至少改變資訊、關係、目標、風險或情緒**其中一項**；反轉**必須能由前文線索回看成立**；集尾鉤子必須產生下一步問題或代價；優先寫「正在發生的可見行動」而非解說性對白。
- ⭐ **明確拒絕越界**：只要劇本時**不輸出**逐鏡分鏡、景別、運鏡或影片模型提示詞。混合請求時**先完成劇本，再銜接環境中已安裝的分鏡／影片 skill**。
- 保留使用者指定的集數、時長、觀眾、類型、平台、預算、場景與交付形式；只問「會實質改變結果」的缺漏，其餘採合理假設並標示。

**裝**（Codex standalone skill，個人技能位置是 `$HOME/.agents/skills`）
```bash
git clone --depth 1 https://github.com/POUND0423/AI-drama-pound.git
mkdir -p "$HOME/.agents/skills/ai-short-drama-screenwriter"
cp -R "AI-drama-pound/skill-src/ai-short-drama-screenwriter/." \
  "$HOME/.agents/skills/ai-short-drama-screenwriter/"
test -f "$HOME/.agents/skills/ai-short-drama-screenwriter/SKILL.md" && echo "Skill installed"
```
眉角：**skill 資料夾內要直接有 `SKILL.md`**（不能多包一層）；裝完沒出現就重啟 Codex。README 另附 Windows PowerShell 版本。

**用**：顯式 `使用 $ai-short-drama-screenwriter，把以下故事前提規劃成 8 集、每集 90 秒的都市懸疑短劇…`；也支援隱式觸發（符合範圍就自動啟動）。

**⚠️ 注意**
- **只有 Codex**。README 沒有 Claude Code／Cursor 的安裝路徑。
- **本身不含分鏡或影片提示詞 skill**，混合交付要環境裡另有適用技能才接得上（可搭 [MiniMax-H3 skills](#minimax-h3-skills) 那條產線）。
- **v0.1.0、4 個 commit、單一貢獻者**，很新。
- 涉及平台偏好／演算法／市場趨勢時，SKILL.md 要求**先查證再當事實**——別把它的產業判斷當現況。

**📐 它的驗證方法值得抄**：repo 的 `validation/` 完整留下 RED 基線、GREEN 行為測試，以及**觸發邊界微測試 A–F 各 5 次**的結果表（含一次 `3/5` 的失敗、最小修補、重跑全組）。→ [[工具-測試skill的觸發邊界]]

**🔗 相關**：[MiniMax-H3 skills](#minimax-h3-skills) —— 劇本 → 分鏡／影片生成是同一條產線的下游，這張 skill 明說要在那個階段交棒。

### scroll-world
`skill` · Claude Code・Codex・多平台（skills CLI） · MIT · ★10.2k（2026-10-15） · ⬜ 待試

**做什麼**：把一個品牌或產業變成**捲動穿梭的落地頁**——捲動時鏡頭從場景外一路飛進室內，再無縫接到下一個場景，**全程沒有剪接點**。就是 Apple 產品頁那套技術：**預先算好影片，捲動只驅動時間軸**，鏡頭是真的在動。

**核心**（靈魂是**接縫**，不是生圖）
- 產出是 **N 張場景靜圖 → N 支「飛入」鏡頭 → N−1 支「連接」鏡頭 → 一支可攜的 scrub 引擎**。
- ⭐ **成敗只有一條規則：接縫必須逐格相同**。連接鏡頭是**用相鄰場景實際算出來的畫格**去生成的，所以接得起來。SKILL.md 明說這是「最常見的單一失敗點」，做錯就會看到「跳一下」。因此**只選能 frame-lock 的模型**。
- **行動版是另外原生算一條 9:16 直式鏈**，不是把橫式裁切——但這會讓影片生成數量翻倍，所以**一定要單獨問過**。
- **框架無關**：scrub 引擎是自足的 vanilla JS，丟進純 HTML／Next.js／Vue／Python 服務的頁面都行。作者自己說「這個 skill 的價值是管線、提示詞與接縫方法，不是框架」。

**裝**
```bash
# Claude Code
/plugin marketplace add oso95/scroll-world
/plugin install scroll-world@scroll-world
```
```bash
# Codex 與其他 agent
npx skills add oso95/scroll-world -a codex
```

**⚠️ 注意（這張的注意事項比功能重要）**
- 🔴 **會花真錢，而且不便宜**：預設走 Monid（Seedance 2.0，按支計費 USD）。實測 **1080p 六場景一條鏈約 $27**、720p 約 $11。選了行動版影片生成量**翻倍**。
- **前置一大串**：Monid CLI＋API key＋餘額、Higgsfield CLI（已登入、有 credit，靜圖與備援都靠它）、`ffmpeg`／`ffprobe`、Python 3＋Pillow；Codex CLI 可選（用 ChatGPT 訂閱出圖，省 credit）。
- **生成很慢**：單次 3–8 分鐘，skill 會背景執行並輪詢。
- **它的成本紀律做得很好**：先報估算（`N 靜圖 + (2N−1) 影片 + ~15% 重跑餘裕`）、先跑一張一支**校準實際單價**、超過餘額 ~70% 會警告、核准後才生成，並提供便宜的 draft 預覽路徑。
- macOS 的 bash 3.2 沒有 `declare -A`，SKILL.md 自己有標這個坑。

**📐 值得抄的兩件事**：→ [[工具-會花錢的skill該怎麼設計]]、[[工具-該問開放題還是選擇題]]（它的訪談段明講：**主題要開放地問，絕不給捏造的多選題**）。

---

## 📐 架構圖與技術溝通

> 跟上面的生圖 skill 差在**輸出的正確性有沒有人管**：那些產的是美術品，好看就是成功；這類產的是**技術陳述**，畫得漂亮但接錯線就是有害。所以要看的重點是「它會不會驗自己」。

### archify
`skill` · Claude Code・Codex・Cursor・opencode・Raven · MIT · ★83.9k（2026-10-15） · ⬜ 待試

**做什麼**：把 codebase 或一段系統描述，變成**一頁自足的互動式架構圖 HTML**（可搜尋節點、追上下游、探測路徑、比較角色、播導覽章節），並能匯出 PNG／SVG／WebM 與 1200×630 分享卡。五種圖：`architecture`／`workflow`／`sequence`／`dataflow`／`lifecycle`。

**核心**（它的靈魂不是畫得漂亮，是**不讓模型直接產最終產物**）
- **agent 產 typed JSON IR → 確定性編譯器渲染 HTML/SVG**。版面判斷交給模型，像素計算交給程式。
- **分級驗證閘**：4 項檢查＝基本；**9 項全過 ＋ 0 錯誤 ＋ 0 警告**才是可交付級。
- **失敗回「修復收據」**：穩定的規則碼 ＋ 確切 subject ＋ 量到的 evidence ＋ 可用修法清單——不是 Node stack trace。
- **原子交付**：凍結規格 bytes → 私有快照渲染檢查 → 通過才原子替換 → 回報 SHA-256。通過即凍結，不准再改。
- **Architecture Delta**：拿兩份驗證過的快照比 Before／Delta／After，列出確切的新增／移除／變更／移動／改道。

**裝**
```bash
npx skills add tt-a1i/archify -g
```
```bash
# 不想安裝先試用
npx skills use tt-a1i/archify@archify --agent codex
```
切換器支援 `cursor`／`codex`／`claude-code`／`opencode`。Raven 要手動把 `archify.zip` 解到 `~/.raven/workspace/skills`。Claude.ai 則在 Settings → Capabilities → Skills 上傳 zip（**能不能用取決於沙箱有沒有 Node.js**）。

**用**：`Use archify to map this repository's runtime architecture.`
規格建議一次只要一個有界視圖——8–12 個核心元件、一條主路徑、外部相依與信任邊界，**細節放卡片而不是加更多線**。

**⚠️ 注意**
- **需要 Node.js**。純 prompt 環境（Project Knowledge、無 shell 的沙箱）只能退化成提示驅動的替代路徑，拿不到驗證與渲染。
- **刻意不做**：Mermaid 自動解析、通用 auto-layout、hosted sharing、WYSIWYG 編輯。它明說自己「不是繪圖編輯器，也不是 Mermaid 佈景主題」。
- 餵 Mermaid 進去時它是**重寫**成自己的 JSON，不是照搬樣式。

**🔗 相關**：[[Archify 架構圖 skill]] —— **詳細筆記在那裡**：`SKILL.md` 的設計拆解（context 預算怎麼寫進指令、修復怎麼收斂、以及那組「不准造假通過」的條款）。


### architecture-diagram-generator
`skill` · Claude.ai・Claude Code · MIT · ★7.4k（2026-10-15） · v1.1 · ⬜ 待試

**做什麼**：把一段系統描述變成**一頁自足的深色主題架構圖 HTML**（內嵌 SVG＋CSS），頁首自帶 Copy／PNG／PDF 匯出按鈕，瀏覽器打開就能用。同作者另有畫流程圖的姊妹 skill [process-flow-diagram-generator](https://github.com/Cocoon-AI/process-flow-diagram-generator)（★103（2026-10-15）），設計語言相同。

**核心**：整個 skill 就是**一份設計規範寫進 `SKILL.md`**，外加一個 `resources/template.html`，沒有任何程式或驗證步驟。
- **語意配色**：前端 cyan、後端 emerald、資料庫 violet、雲 amber、資安 rose、訊息匯流排 orange、外部 slate。
- **版面規則交給模型自己算座標**：元件高 60px、垂直間距至少 40px、匯流排放在間隙正中、圖例放在所有邊界框外至少 20px，並附「錯誤／正確」的座標範例。
- **箭頭 z-order 的小技巧**：箭頭先畫；元件先墊一個不透明底框，再疊半透明色框，箭頭才不會透出來。

**跟 [archify](#archify) 的差別**：archify 讓模型產 JSON 再用編譯器渲染，還有 9 項驗證閘；這個是**模型直接手寫 SVG 座標**，好看與否靠規範，**接錯線、元件重疊沒有任何檢查**。換來的是零依賴，不需要 Node.js。

**裝**
```bash
# Claude Code：解到 skills 目錄（zip 在 repo 根目錄）
unzip architecture-diagram.zip -d ~/.claude/skills/     # 全域
unzip architecture-diagram.zip -d ./.claude/skills/     # 專案內
```
Claude.ai：**Customize → Skills → + → Create skill → Upload a skill** 上傳 zip。前提是先在 **Settings → Capabilities** 開啟 Code Execution（Team／Enterprise 要管理員在組織設定開）。

**用**：`Use your architecture diagram skill to create an architecture diagram from this description: …`。README 建議先讓 agent 分析 codebase 產出「元件＋連線＋技術」清單，再貼給它畫；之後用對話迭代（「把 XYZ 改成…」）。

**⚠️ 注意**
- **不驗證**：技術圖畫錯線是有害的，產出要自己對一遍。
- **輸出會連 Google Fonts** 載 JetBrains Mono，離線或內網環境字型會退回預設。
- 只有深色一種風格；要淺色、要符合公司 CI 得自己改規範。
- 介紹文（掘金 MacroZheng，2026-08-27）寫 ★6.3k，查證時（2026-09-27）已 ★7.3k。

**🔗 相關**：[archify](#archify) —— 同類但會自我驗證，產出要拿去對外溝通時優先選它。

---

## 🛠 工程工作流

> 這類不是改語氣、也不是給單一新能力，而是**把整條開發流程包起來**：對齊 → 規格 → 拆票 → 實作 → 審查。
> 挑選時看兩件事：**它願不願意讓你改**（框架型的會接管流程，出錯很難修），以及**它有沒有處理集合層級的維護**（skill 一多就會互相打架）。

### superpowers
`plugin` · Claude Code・Codex・Cursor・Gemini・Copilot・Grok・Kimi・OpenCode・Devin 等 15+ harness · MIT · ★299.5k（2026-10-15） · ⬜ 待試

**做什麼**：不是一組工具，是**一整套會自動接管的軟體開發方法論**。你一開口要做東西，它不會直接寫碼——先反問你要解決什麼、逼出規格、分段給你確認；你點頭後產出「一個熱心但沒品味、沒判斷力、沒專案脈絡、討厭寫測試的菜鳥也照得動」的實作計劃；說 go 之後派 subagent 逐項執行並兩階段審查。**作者說 agent 常能照著計劃自主跑上好幾小時。**

**核心**（靈魂是「**強制**，不是建議」）
- **七步流程自動觸發**：`brainstorming` → `using-git-worktrees` → `writing-plans`（任務切到 **2–5 分鐘**一顆，每顆都有確切檔案路徑、完整程式碼、驗證步驟）→ `subagent-driven-development`／`executing-plans` → `test-driven-development` → `requesting-code-review` → `finishing-a-development-branch`。
- 文件原話：**"Mandatory workflows, not suggestions."** 且 **`test-driven-development` 會刪掉在測試之前寫的程式碼。**
- **四條哲學**：測試先行、系統化勝過臨場發揮、複雜度降低、**證據勝過宣稱**（verify before declaring success）。
- ⭐ **`writing-skills` 內含一套 skill 測試方法論**（`testing-skills-with-subagents.md`）——**把 TDD 套用在流程文件上**：不帶 skill 跑壓力情境看它失敗、逐字記下藉口、寫 skill、再用多重壓力測服從度。→ [[工具-用壓力情境測試skill]]

**裝**（每個 harness 要各裝一次）
```
# Claude Code（Anthropic 官方 marketplace，不用先加來源）
/plugin install superpowers@claude-plugins-official
```
```bash
# 其他：Gemini CLI / Devin / Droid 等各有自己的指令
gemini extensions install https://github.com/obra/superpowers
devin plugins install obra/superpowers
```

**⚠️ 注意**
- 🔴 **它會接管流程，這是特性也是代價**。想保有逐步控制權的人會覺得綁手綁腳——**這正是 [Skills For Real Engineers](#skills-for-real-engineers) 明講要反對的那種設計**（那份的立場是「框架接管流程會奪走你的控制權，流程出錯還很難修」）。**兩者是同一個問題的兩種答案，不是誰比較好。**
- ⚠️ **預設有 telemetry**：`brainstorming` 的視覺伴隨功能會從作者網站載入 logo，**帶上 Superpowers 版本號**（不含專案、prompt 或 agent 資訊）。關法：`SUPERPOWERS_DISABLE_TELEMETRY`，它也尊重 `DISABLE_TELEMETRY` 與 `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`（那兩個變數 → [[Claude Code 隱藏設定分析 v2.1.239]]）。
- **有商業支援方案**（primeradiant.com），這是一個有公司在後面的專案。

**🔗 相關**
- [Skills For Real Engineers](#skills-for-real-engineers) —— **直接對照組**：同樣是「整條開發流程的 skill 集合」，但 superpowers 走**強制方法論**、Matt Pocock 走**小而可組合、你自己編排**。選哪邊取決於你要控制權還是要自動駕駛。
- [[工具-用壓力情境測試skill]] —— 它 `writing-skills` 裡那套方法論，我單獨抽出來的卡

### Skills For Real Engineers
`plugin` · Claude Code（官方 marketplace）・Codex・Copilot・Gemini CLI／skills.sh · MIT · ★292.1k（2026-10-15）· v1.3.1 · ⬜ 待試

**做什麼**：Matt Pocock 每天在用的 **38 個 skill**（engineering 20、productivity 7、misc 4 已凍結、in-progress 7 beta），涵蓋整條流程：`/grill-with-docs`（拷問對齊）→ `/to-spec`（轉規格）→ `/to-tickets`（拆成垂直切片）→ `/implement` 或 `/implement-spec`（平行實作）→ `code-review`（雙軸審查）→ `pr`（PR 內文）→ `/retro`（改善 agent 環境）。旁路入口有 `/triage`、`diagnosing-bugs`、`/wayfinder`。每個 skill 的拆解見 [[Skills For Real Engineers#🗂 全部 38 個 skill 拆解（2026-10-13，依 v1.3.1）|筆記]]。

**核心**（靈魂是**組織方式**，不是任何單一 skill）
- **反框架的立場**：明講 GSD／BMAD／Spec-Kit 那類「接管流程」的做法**奪走你的控制權、流程出錯難修**；他要的是**小、好改、可組合**。
- ⭐ **用「誰能叫它」分兩層**：**user-invoked** 只有人能叫，職責是**編排**；**model-invoked** 人和模型都能叫，持有**可複用的紀律**。**user-invoked 可呼叫 model-invoked，但絕不呼叫另一個 user-invoked。**
  實例：`grilling` 這個面談原語被 5 個編排型 skill 共用。
- **診斷了四個 agent 失敗模式**：沒做我要的（對齊落差）／太囉唆（缺共享語言）／code 不能跑（回饋迴路不足）／一團爛泥（agent 加速軟體熵）。
- **`GLOSSARY.md` 共享語言**（1.3.0 前叫 `CONTEXT.md`，舊專案要自己 `git mv`），他自稱是整個 repo 最酷的技術——把專案行話固定下來，命名一致、agent 好導航、**思考花的 token 更少**。

**裝**（**兩種哲學，別同時裝**——會拿到每個 skill 兩份）
```bash
# 訂閱：整包唯讀、自動更新（已在 Claude Code 官方 marketplace）
claude plugin install mattpocock-skills@claude-plugins-official
```
```bash
# 分叉：把可編輯的檔案寫進你的 repo，你擁有它
npx skills@latest add mattpocock/skills
```
裝完要**在每個 repo 各跑一次** `/setup-matt-pocock-skills`（選 issue tracker、triage 標籤、文件位置）。Codex、Copilot 也有原生 plugin（依 README，2026-10-13 查證）。

**用**：不確定用哪個就 `/ask-matt`（它是所有 user-invoked skill 的路由）。最常用的是 `/grill-me` 與 `/grill-with-docs`。

**⚠️ 注意**
- **它預設你有 issue tracker**（GitHub／Linear／本機檔案），整套流程繞著票在跑。只想要單點工具的話會覺得包袱重。
- `improve-codebase-architecture` 作者自己標明是 **"a survey, not a rescue"**——老專案上它找得出候選，但**不會幫你把爛泥解開**。
- **四個失敗模式的解法都是既有的軟體工程基本功**（見下方筆記的對照表），不是新發明。作者自己就說 "Software engineering fundamentals matter more than ever"。

**🔗 相關**：[[Skills For Real Engineers]] —— **詳細筆記在那裡**：四個失敗模式對應到我既有工具卡的表、集合分層規則、以及 `CLAUDE.md` 裡那組維護紀律（含「會說謊的路由」）。

---

## 🧠 回應風格與寫碼紀律

> 都是「**改 agent 怎麼寫／怎麼答**」而不是「給新能力」。差別在觸發時機：前兩個裝上**每輪生效**，會改變你所有對話的預設；`go-modern-guidelines` 只在**碰到 Go 任務時**才被叫起來，平常不影響。
>
> 📊 已跑對照實測 → [[moc/AI技能評比|AI 技能評比]]（2026-08-05）。結論：答案確實變短，但**短在少講三分之一概念**，且 **output token 沒省到**。

### i-have-adhd
`plugin` · Claude Code・Codex · MIT · ★57.2k（2026-10-15） · ⬜ 待試 · 📊

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
`plugin` · 多平台 · MIT · ★164k（2026-10-15） · ⬜ 待試 · 📊

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

### go-modern-guidelines
`plugin` · Junie・Claude Code・Codex・Cursor・opencode · Apache-2.0 · ★3.9k（2026-10-15） · ⬜ 待試

**做什麼**：JetBrains 官方出的 Go 專用 plugin，塞給 agent 一份**現代 Go 寫法對照表**，讓它別再產出過時的 Go——`max(a,b)` 而不是 if-else、`slices.Contains` 而不是手寫迴圈、`cmp.Or(a,b,c)` 而不是一串 nil 檢查。涵蓋 Go 1.0–1.27，對齊官方 `modernize` analyzer。

**核心**（它的靈魂是**動機分析**，不是那份清單）
它指名 coding agent 產出過時程式碼有**兩個不同原因**：
- **訓練資料落後**——模型沒看過 cutoff 之後的特性，例如 Go 1.26 的 `errors.AsType[T]`。
- **頻率偏誤**——**就算模型知道**新寫法，訓練語料裡 `for i := 0; i < n; i++` 就是比 `for i := range n` 多，所以出來的是舊的。

第二個是關鍵：**光叫它「用最新寫法」沒用，要給明確的對照表。**
另外它**會先從 `go.mod` 偵測專案 Go 版本**，只用到該版本為止可用的特性——否則就是把編不過的程式碼塞給你。

**裝**
```bash
# Claude Code（在 session 內）
/plugin marketplace add JetBrains/go-modern-guidelines
/plugin install modern-go-guidelines@goland-claude-marketplace
```
```bash
# Codex（terminal）
codex plugin marketplace add JetBrains/go-modern-guidelines
codex plugin add modern-go-guidelines@goland-codex-marketplace
```
```bash
# 其他 agent（opencode 等）
npx skills add JetBrains/go-modern-guidelines
```
Junie 用 `/extensions marketplace add` ＋ `/extensions install modern-go-guidelines`；Cursor 用 `cursor-agent plugin marketplace add <repo-url>` 再以 `/plugins` 安裝。

**用**：碰到 Go 任務會自動觸發。Claude Code 要明確叫用：`/modern-go-guidelines:use-modern-go`。

**⚠️ 注意**
- **需要 Go toolchain 在 PATH 上**——marketplace 整合會在首次使用時 `go install` 一支小 CLI（快取在 `~/.cache/go-modern-guidelines`，不會動你的專案）。目標 Go 1.25+，較舊版本靠 `GOTOOLCHAIN=auto` 自動抓相容工具鏈。
- **第三方 marketplace 的自動更新預設是關的**：Claude Code 要進 `/plugin` → Marketplaces → 選 `goland-claude-marketplace` → Enable auto-update，更新後還要 `/reload-plugins` 才會套用到當前 session。
- **Cursor 沒有非互動的更新指令**，只能重開再用 `/plugins` 重裝。
- `FEATURES.md` 自標 **“Work in progress — inconsistencies may be present.”**

**🔗 相關**：[[Modern Go Guidelines]] —— **詳細筆記在那裡**：Critical／High 條目的舊→新速查表，以及那組「兩個失敗原因」的分析。

### karpathy-guidelines
`plugin` · Claude Code・Cursor · README 標 MIT（**但 repo 沒有 LICENSE 檔**） · ★220k（2026-10-15） · ⬜ 待試

> ⚠️ **先講清楚歸屬**：**這不是 Andrej Karpathy 做的，也不是他背書的。** 是第三方（`multica-ai`，作者 X 帳號 `@jiayuan_jy`）把 Karpathy 公開談 LLM 寫碼缺陷的說法，整理成一份 `CLAUDE.md`。README 本身講得誠實（用的是 "derived from"、"Karpathy-Inspired"），**但 repo 名字 `andrej-karpathy-skills` 讀起來像是他本人的**——引用時要注意別誤植。

**做什麼**：一份 `CLAUDE.md`（也包成 plugin 與 Cursor rule），用**四條原則**對付 Karpathy 點名的 LLM 寫碼老毛病。

**核心**（它的價值在「問題 → 原則」的對應很乾淨）
| 原則 | 治什麼毛病 |
|---|---|
| **Think Before Coding** | 替你亂做假設、藏著困惑不講、不攤開取捨 |
| **Simplicity First** | 過度複雜化、臃腫的抽象（「100 行夠的寫成 1000 行」） |
| **Surgical Changes** | 動到不該動的、改掉它沒真的看懂的程式碼與註解 |
| **Goal-Driven Execution** | 用可驗證的成功標準換取「它能自己跑」 |

其中最值得記的是那句引用的洞察：
> **"Don't tell it what to do, give it success criteria and watch it go."**

**裝**
```
# Claude Code
/plugin marketplace add forrestchang/andrej-karpathy-skills
/plugin install andrej-karpathy-skills@karpathy-skills
```
```bash
# 或直接當 CLAUDE.md 用（單一專案）
curl -o CLAUDE.md https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/main/CLAUDE.md
```
⚠️ **安裝指令裡的 `forrestchang` 與 repo 現址 `multica-ai` 不一致**——實測 `forrestchang/...` 會被 GitHub 轉址到現址，所以目前可用，但**這靠的是轉址，舊名一旦被別人註冊就會裝到別的東西**。保險起見改用現址。

**⚠️ 注意**
- **README 寫 MIT，但 repo 裡沒有 LICENSE 檔**（GitHub 側欄的 Resources 也沒偵測到授權）。要在公司專案裡用，這個授權狀態偏弱。
- **它自己標了取捨**：這份指引**偏向謹慎而非速度**。改錯字、明顯的一行修正這類瑣事不需要全套嚴謹——目標是減少非瑣碎工作上的昂貴錯誤。
- **與 [ponytail](#ponytail) 高度重疊**：兩者都在治「過度設計」。ponytail 給的是一道**決策階梯**（需不需要存在 → codebase 有沒有 → 標準庫行不行…），這份給的是**四條原則加驗收判準**。**同開意義不大，挑一個。**
- 沒有發布任何 release。

**📐 抽出來的兩張卡**：→ [[工具-外科手術式修改]]（「每一行改動都要能追溯到使用者的要求」）、[[工具-把命令變成可驗證的目標]]。
另外兩條原則 vault 已有對應：Think Before Coding → [[工具-讓agent反過來拷問你]]；Simplicity First → [ponytail](#ponytail) 那張卡的決策階梯。

---

## 🗣 解釋與表達

> 跟上面的「回應風格」差在**生效時機**：那些是 plugin，裝上每輪都在改你的 agent；這類是 skill，**被觸發才上場**，平常不動預設行為。所以風險低、但也要留意觸發詞會不會誤觸。

### eli5
`skill` · Claude Code · MIT · ★1.7k（2026-10-15） · ⬜ 待試

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
> ⚠️ 2026-10-17 重測，codegraph 的 caller 在同兩個符號上全中，「影響分析用 codebase-memory」的理由變弱了；codebase-memory 這次沒重測，它獨有的 Cypher、複雜度指標、語意搜尋仍成立。
>
> ~~同時裝兩套沒有意義，選一套即可。~~ ← 我自己的推論，已被實測推翻，留著當紀錄。
>
> **四個以上的工具怎麼分（依各自 README 整理，查證 2026-10-16）**：差別在「圖要給誰用」和「素材有哪些」。
> - 給 agent 當索引、少讀檔、做影響分析 → [codegraph](#codegraph)、[codebase-memory-mcp](#codebase-memory-mcp)
> - agent 要做自動化重構、追執行流、跑 Cypher → [GitNexus](#gitnexus)（注意非商用授權）
> - 程式碼以外還有文件、SQL、PDF 要一起進圖 → [graphify](#graphify)
> - 給人看、新人 onboarding、架構導覽 → [Understand-Anything](#understand-anything)
>
> 📊 **四方實測（2026-10-17）推翻了「照用途挑」這個順序：要先看你的呼叫寫法撞不撞到工具的盲點** → [[moc/AI技能評比|評比]]。
> - 同一個 codebase（大量用 `export default new XService()`），隨機抽 30 個跨檔的 singleton 呼叫，各工具建出的邊數：
>   - codegraph 30/30
>   - Understand-Anything 24/30（class 層級）
>   - GitNexus 0/30
>   - graphify 0/30
> - 最小重現顯示三個確定性工具的盲點各不相同：
>   - `export default new X()`：只有 codegraph 抓得到。
>   - `export const x = new X()`：只有 GitNexus 抓得到（codegraph 1.4.1 的盲點，1.6.2 已修）。
>   - 一般具名函式：三個都抓得到。
> - 選之前先用自己最常見的 2–3 種寫法，做一個 3 檔的最小重現，每個工具跑一次只要幾秒。
> - **跨 repo（2026-10-18 實測，真實的 TS ↔ Go，75 個 HTTP 端點、1 條 gRPC）**：codebase-memory、codegraph、GitNexus、graphify 自動連上的跨 repo 呼叫**都是 0**。5 題實戰題各組都靠 grep 完成跨 repo 的銜接。跨 repo 要自己用腳本維護「呼叫點 → 路由 → handler」的合約表，並在 CI 檢查 → [[moc/AI技能評比|評比]]
>
> 程式碼部分四者都用 tree-sitter／AST 做確定性抽取，差在要不要呼叫 LLM：codegraph、GitNexus 不需要（GitNexus 的 embedding 是選配）；graphify 只在文件、媒體上用；Understand-Anything 每個檔案都會用 LLM 寫摘要和導覽，所以 token 成本最高。實測（2026-10-17）還發現，Understand-Anything 的 `calls` 邊也是 LLM 寫的，不是解析器產出 → [[moc/AI技能評比|評比]]。來源文章：替代方案有限公司〈Understand-Anything vs. GitNexus vs. CodeGraph vs. graphify〉（<https://altsol.tw/understand-anything-gitnexus-codegraph-comparison>，評比見 `_meta/來源評比紀錄.md`），文中把 graphify 說成「非 MCP Server」不正確（它有選配的 MCP stdio server），也沒提 GitNexus 的授權限制。

### codegraph
`MCP` · 多平台 · MIT · ★74.2k（2026-10-15） · ✅ 已在用 · 📊

**做什麼**：本機程式碼知識圖譜（Rust kernel）。核心工具 `codegraph_explore` 一次給相關 symbol 的**逐字源碼**＋**呼叫路徑**（含 grep 追不到的 dynamic dispatch）＋改動 blast radius。

**裝**
```bash
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
codegraph install               # 接上各家 agent，不建索引
cd your-project && codegraph init  # 每個專案各自建圖
```
auto-sync 預設開，改檔即更新。本機 v1.4.1，官方最新 v1.6.2（2026-10-03 發布；查證 2026-10-15），用 `codegraph upgrade` 升級。

**用**：只在有 `.codegraph/` 目錄的 repo 用（建索引我自己決定，不讓 agent 代跑 `init`）。已寫進全域 `CLAUDE.md`。

**📊 實測**：
- 2026-08-05：讀流程、快速讀懂勝出，但 **caller 會漏**（巢狀函式、singleton 方法）。
- 2026-10-17：同一個 repo、同兩個符號重測，CLI 1.4.1 查新、舊兩份索引都是 **2/2、5/5 全中**，8 月的漏抓重現不出來，原因未查證。
- 兩次都一樣：介面型別的 dispatch 解不出來，涉及介面多型的邊仍要用 grep 收尾。
- 2026-10-17 四方實測：`export default new X()` 的 singleton 呼叫抽 30 個全中，四個工具裡最好。但最小重現發現，**具名的 `export const x = new X()` 透過實例呼叫方法，1.4.1 建不出邊**（1.6.2 已修）。
- 2026-10-18 重測（新 HEAD，type checker 真值）：TS 跨檔召回／精確度 1.4.1 是 91%／64%，**1.6.2 是 97%／81%**，四個工具裡最好。Go 服務的 route → handler（`cfg.X.Method` 寫法）130 條只有 53 條對，其餘連到同名方法，包括測試替身。沒有跨 repo 連結（2026-10-18 跨 repo 實測）。
- 2026-10-17 再驗證（type checker 當真值）：
  - 精確度不如原本以為的高：1.4.1 整體 76%、跨檔 60%（1.6.2：90%／76%）。錯誤多半是同名退化，例如 `xxxRepository.findById` 被連到別的 service 的 `findById`；常見方法名的 caller 要用 grep 篩。

→ [[moc/AI技能評比|評比]]

**宣稱數字**（README，未驗證）：工具呼叫 −89%、token −69%、7 repo 檔案讀取全部歸零；但小 repo 有地板效應、強模型直接 grep wall-clock 更快（只是燒 5–10 倍 token）。

### codebase-memory-mcp
`MCP` · 43 client surface · MIT · ★46.6k（2026-10-15） · ✅ 已在用 · 📊

**做什麼**：同是本機程式碼知識圖譜，路線差在**廣度與速度**：tree-sitter AST 覆蓋 **158 種語言**（其中 12 種另加 LSP 語意型別解析），單一靜態 binary、零依賴。15 個 MCP 工具（死碼偵測／跨服務 HTTP 串接／Cypher／ADR），另把 Dockerfile／K8s／Kustomize 也建進圖。

**裝**
```bash
curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash
# 要 3D 圖譜視覺化(localhost:9749)：加 -s -- --ui
```
重啟 agent 後說「Index this project」。快取在 `~/.cache/codebase-memory-mcp/`。

**⚠️ 注意**：它**會讀你的 codebase、也會寫你的 agent 設定檔**；跨 client 共用一個 coordination daemon（無 opt-in，第一個 session 啟動、最後一個關掉）；所有 CBM process 版本**必須完全一致**，否則被 admission barrier 擋下。

**📊 實測（2026-10-18，本機 7 月 5 日編譯的 dev build，也就是 8 月報告寫的「pro」）**：
- **TS 漏抓嚴重**：跨檔召回率 25%，`export default new X()` 的 singleton 只有 4%，具名 const 實例 0%。兩個測試方法的 caller 是 0/6、0/4。精確度 83%。Go 小型重現 7/8，明顯比 TS 好。
- **跨 repo**：要另外手動跑 `index_repository` 的 `cross-repo-intelligence` 模式。實測產生 136 條連結，**全錯**：
  - Go 1.22 的 `mux.Handle("POST /path")` 被丟棄，因為解析器要求路徑以 `/` 開頭。
  - TS 的純字串 URL 漏掉，只認得樣板字串。
  - 邊上沒有 README 說的 confidence。
  - 重新索引會清掉 CROSS 邊。
- **8 月的「caller 完整性全勝」重現不出來**：同一個 build，在 a6fb1d3e（10-17 報告記為與 8 月同一個 commit；8 月報告本身沒記 commit）重測是 0/5。
- **團隊導入風險**：
  - 這個 build 之後已發布 14 個 release（含 2 個 pre-release），沒有官方簽章。
  - 每次 MCP 初始化都會連 GitHub 檢查版本，沒辦法關，跟 README 寫的不一致。
  - UI 在 127.0.0.1:9749 監聽，沒有驗證，也沒有檢查 Host header。
  - `install` 會改寫多個全域設定與 hooks。
- 原本的紀錄（8 月）：Cypher／跨程序迴圈深度／語意搜尋／co-change 耦合是它獨有；但只給名稱清單、無 body → [[moc/AI技能評比|評比]]（實測用 **pro 版**，與開源版功能集是否相同未查證）

**宣稱數字**（README，未驗證）：Linux kernel 28M LOC 3 分鐘建完、結構查詢 <1ms；preprint arXiv:2603.27277，31 repo：品質 83%、token 少 10×、工具呼叫少 2.1×。

---

### graphify
`skill` · Claude Code・Cursor・Codex・Gemini CLI・Copilot 等 20+ · Apache-2.0 · ★126.7k（2026-10-15）· ⬜ 未安裝（用 `uvx` 臨時跑過 0.9.92）· 📊

**做什麼**：把整個資料夾（程式碼、文件、SQL schema、設定、PDF、圖片、影片）建成一張**可查詢的知識圖譜**，用「沿著關係走」取代 grep。跟上面兩個的差別：它不只看程式碼，**文件和需求也進同一張圖**，所以能問「這個需求對應到哪些 module」。

**核心**
- **兩種抽取**：程式碼用 tree-sitter 解析 AST，**確定性、不呼叫 LLM、不出本機**；文件、PDF、圖片走模型做語意抽取（用你助手的模型，或另外設定的 API key）。
- ★ **每條邊都標可信度**（ARCHITECTURE.md）：`EXTRACTED`（原文明確寫的，例如 import、直接呼叫）、`INFERRED`（合理推論，例如呼叫圖的第二輪解析、在同一段上下文共同出現）、`AMBIGUOUS`（不確定，會列在報告裡請人確認）。
- **不是向量索引**：沒有 embedding，是真的圖，可以走路徑。社群切分用 Leiden。
- **三個產出**：`graph.html`（給人點著看）、`GRAPH_REPORT.md`（god nodes、社群、意外連結、建議提問）、`graph.json`（給 agent 查）。另有 `manifest.json` 記錄每個檔的狀態，`--update` 靠它只重抽改過的檔。

**裝**
```bash
uv tool install graphifyy      # 套件名有兩個 y（或 pipx install graphifyy），需要 Python 3.10+
graphify install               # 偵測你的 agent 並註冊 /graphify skill
```
選配：`graphifyy[mcp]`（MCP stdio server）、`graphifyy[video]`、`graphifyy[neo4j]`。

**用**
```
/graphify .                          # 建圖
/graphify . --update                 # 只重抽改過的檔
/graphify . --cluster-only           # 只重新分群
/graphify . --no-viz                 # 不產 HTML，只要報告和 JSON
/graphify query "auth flow 是怎麼運作的？"
/graphify path "Login Page" "Auth Service"   # 兩個概念之間的最短路徑
/graphify explain "Auth Service"             # 一個節點跟誰有關、哪些邊是推論的
```
`.graphifyignore`（加上 `.gitignore`、`--exclude`）用來排除雜訊；純程式碼的話加 `--code-only`，完全離線、不需要 API key。

**⚠️ 注意**
- **文件、PDF、圖片的部分會送到模型**：碼不外流，但文件會。公司文件要先確認可以送。
- **推論的邊只能當線索**：`INFERRED`／`AMBIGUOUS` 要回原始碼確認；動態派發、runtime 設定、feature flag、外部服務呼叫，AST 也看不到。
- **README 一直在推付費的 Graphify Cloud**（宣稱「agent token 省 80%」，未驗證）；開源版是本機 CLI 加 skill。
- 跟 codegraph／codebase-memory 功能重疊，差別在**文件也進圖**、而且有可信度標記；純看程式碼結構時，那兩個已經夠用。
- 🔴 **singleton 呼叫解析不了**（0.9.92 實測）：
  - `export default new X()` 和 `export const x = new X()` 兩種寫法，透過實例呼叫方法都建不出呼叫邊，只剩檔案層級的 import 邊。
  - 大量用 service singleton 的後端，跨檔呼叫幾乎都看不到：232 檔只有 87 條跨檔 calls 邊。
  - barrel `index.ts` 建不出符號，`.proto` 直接跳過。
- 不想全域安裝的話，可以用 `uvx --from graphifyy graphify extract <path> --code-only --out <dir>` 臨時跑；產出寫到 `--out` 指定的位置，不會動到原 repo。

**📊 實測（2026-10-17，`--code-only`）**：
- 232 個 TS 檔：4.2 秒、0 token，2,058 節點、4,440 邊，重建結果完全一樣。
- 抽 30 條 calls 邊用名稱判定都正確，但嚴格再驗證後整體精確度是 87%（跨檔 98%，不過跨檔的邊很少）；28 條 INFERRED 都對。
- Go 的 receiver 方法呼叫，8 種寫法漏了 5 種（合成小樣本）。
- 流程解說題 10/10，但「額度在哪裡檢查」只能靠 import 邊加讀原始碼。
- 跨 repo：`merge-graphs` 後兩張圖之間 0 條直接邊（2026-10-18 實測 TS ↔ Go）。repo 內 TS 跨檔召回率 22%。

→ [[moc/AI技能評比|評比]]

**🧪 工作坊**：Neo Hsu 的 Graphify 工作坊整理成筆記 → [[讓AI讀懂你的系統（Graphify工作坊）]]，裡面有可信度分級怎麼用、降噪、多 repo 的 bridge doc、從小開始，以及查證表。方法本身抽成 [[工具-用知識圖譜幫agent找對context]]。

**🔗 相關**：[codegraph](#codegraph)、[codebase-memory-mcp](#codebase-memory-mcp) —— 只看程式碼的同類工具。[[工具-讓LLM維護的個人Wiki]] —— 同樣是「先建好結構、查詢時不必重撈原始檔」的想法。

---

### GitNexus
`MCP` · Claude Code・Cursor・Codex・Antigravity 等 · **PolyForm Noncommercial** · ★47.9k（2026-10-16）· ⬜ 未安裝（用 `npx` 臨時跑過 1.6.12）· 📊

**做什麼**：把 codebase 建成一張存在嵌入式圖資料庫裡的知識圖譜，再透過 MCP 工具給 agent 查。自我定位是「像 DeepWiki，但更深：DeepWiki 幫你理解，GitNexus 讓你分析」。另有瀏覽器版 Web UI（不用安裝）。

**核心**
- **儲存**：LadybugDB（前身 KuzuDB）。CLI 用原生版、持久化；Web UI 用 WASM 版、只在記憶體裡、每個 session 重建。
- **解析**：tree-sitter；社群分群用 Leiden；本機 embedding 是選配（預設不裝）。
- **19 個 MCP 工具**，比同類多出「會動手」的那一層：`impact`（影響範圍，依深度分組並附信心）、`trace`（兩個符號間的有向最短路徑）、`detect_changes`（把 git diff 對到受影響的執行流）、`rename`（語意改名，預設只預覽）、`cypher`（直接下 Cypher）、`route_map`／`api_impact`（API 路由與改動影響）、`pdg_query`（敘述層級的控制與資料依賴，要另外建 `--pdg` 索引）。
- `gitnexus analyze --skills` 會依分群結果幫每個功能區產生一份專案 skill（`.claude/skills/gitnexus-area-<name>/`）。

**裝**
```bash
npx gitnexus analyze    # 在 repo 根目錄：建索引
npx gitnexus setup      # 一次性：自動偵測編輯器並寫入 MCP 設定
```
npm 11 會在安裝時崩潰（README 寫的已知問題），改用 pnpm 或 `npm i -g gitnexus`。全域安裝也能避免 `npx` 冷啟動超過 Claude Code 的 MCP 逾時（約 30 秒）。

**用**：`gitnexus query`／`context`／`impact`／`trace`／`cypher` 在終端機下的用法和 MCP 工具同名。`gitnexus analyze --watch` 會監看檔案、增量更新（需要 git repo）。

**⚠️ 注意**
- 🔴 **授權是 PolyForm Noncommercial**：開源版只能非商業使用，公司內使用要另外買授權（README：commercial use … with proper licensing）。這是跟另外三個工具最大的差別。
- **`analyze` 會改你的 repo**：除了建索引，還會安裝 agent skills、註冊 Claude Code hooks、建立 `AGENTS.md`／`CLAUDE.md`。要移除用 `gitnexus uninstall`（預設只預覽，加 `--force` 才執行）。
- 來源文章示範的 `gitnexus impact --function processPayment`，README 沒有 `--function` 這個參數；`impact` 指令是有的，參數以 `gitnexus impact --help` 為準。
- **只想建索引、不想被改 repo**：`GITNEXUS_HOME=<自訂目錄> npx gitnexus analyze <path> --index-only`（不是 git repo 的話再加 `--skip-git`）。1.6.12 實測只寫 `.gitnexus/`，不裝 skills、hooks、AGENTS.md，也不寫 `~/.gitnexus`。
- 🔴 **`export default new X()` 的 singleton 解析不了**（1.6.12 實測）：
  - 透過預設匯出的實例呼叫方法，建不出呼叫邊；具名的 `export const x = new X()` 可以。
  - 大量用 service singleton 的後端會漏掉大部分跨檔呼叫：232 檔只有 151 條跨檔 calls 邊，`assertWithinQuota` 的 caller 是 0/5。
  - 好在 `impact` 查不到時回 `risk: UNKNOWN`，並附註「沒有邊不代表沒人用，請用文字搜尋確認」，不會假裝安全。
- **README 和 npm 版本不同步**：
  - README 上的 `--skip-embeddings`，1.6.12 沒有（embedding 預設本來就不開）。
  - `rename` 在 1.6.12 的 CLI 裡沒有，只有 MCP 有。
  - 全文搜尋需要連網下載 LadybugDB 的 FTS 擴充，下載失敗就停用。

**📊 實測（2026-10-17，`--index-only`）**：
- 232 個 TS 檔：22 秒、0 token，4,038 節點、8,061 邊、236 條執行流。
- 562 個入口候選裡有 362 個沒有追成執行流，這是它自己警告的。
- 抽 30 條 calls 邊都正確，嚴格再驗證後精確度 99%；但 TS 跨檔召回率只有 24%。重建結果完全一樣。
- `handleUserText` 的 caller 2/2，而且精確指到巢狀的 `onMessage`／`onUserTurn`，是四個工具裡最準的。
- 流程解說題 10/10，但最貴：11.2 萬 token、17 次工具呼叫，因為 singleton 呼叫都要回頭讀碼。
- **跨 repo `group`（2026-10-18 實測 TS ↔ Go）**：
  - 自動模式下 HTTP 0/75、gRPC 0/1。Go 服務的 HTTP provider 數是 0，推測是認不得 Go 1.22 的 `mux.Handle("POST /path")`（10-17 那輪讀過它 npx 快取裡的 extractor 原始碼才得出這個結論，這次沒有重讀）。
  - 手寫 manifest 宣告了 75 條，但兩端都對不到程式碼符號；gRPC 解到產生出來的 stub。

→ [[moc/AI技能評比|評比]]

**🔗 相關**：[codegraph](#codegraph)、[codebase-memory-mcp](#codebase-memory-mcp) —— 同樣是給 agent 用的程式碼圖譜；GitNexus 多了改名、Cypher、PDG 這些重度功能，代價是授權限制。

---

### Understand-Anything
`plugin` · Claude Code（另支援 Codex、Cursor、Copilot、Gemini CLI 等）· MIT · ★86.5k（2026-10-16）· ✅ 已安裝 v2.9.7 · 📊

**做什麼**：用多 agent 流程分析整個專案，把每個檔案、函式、類別、依賴建成知識圖譜（存在 `.ua/knowledge-graph.json`），再提供**互動式儀表板**讓人點著看，附白話摘要和導覽路線。定位是「給人看懂專案」，不是給 agent 省 token。2026 年從 `Lum1104/Understand-Anything` 移到 `Egonex-AI` 組織，舊網址會轉址。

**核心**
- **tree-sitter＋LLM 分工**：README 的說法是 tree-sitter 做確定性的結構抽取（import、export、定義、呼叫、繼承），LLM 寫解析器給不了的東西（白話摘要、標籤、架構層、業務領域對應、導覽）。⚠️ 實測 2.9.7 的情況不同：
  - 只有 import、檔案與 class 節點是腳本產生的。
  - **`calls` 邊是 file-analyzer 讀碼後由 LLM 寫的**，同一批重跑會變（Jaccard 0.79）。
  - 節點以檔案、匯出的 class／函式為主，class 方法幾乎不建。
- **多 agent 流程**：`/understand` 由 5 個 agent 組成：project-scanner、file-analyzer、architecture-analyzer、tour-builder、graph-reviewer。file-analyzer 平行跑，最多 5 個；實測每批 3–25 個檔，零散的小檔會合併成 misc 批。`/understand-domain`、`/understand-knowledge` 各再加 1 個 agent。支援增量更新，只重分析改過的檔。
- `/understand-knowledge` 能吃 **Karpathy 式的 LLM wiki**，畫出知識庫的力導向圖和社群分群 → [[LLM Wiki（Karpathy）]]。

**裝**
```
/plugin marketplace add Egonex-AI/Understand-Anything
/plugin install understand-anything
```

**用**
```
/understand                      # 分析整個專案（--language zh-TW 產繁中內容；--auto-update 自動更新）
/understand-dashboard            # 開互動式儀表板
/understand-chat 付款流程怎麼跑？
/understand-diff                 # 分析目前的改動
/understand-explain src/auth/login.ts
/understand-onboard              # 產新人導覽
/understand-domain               # 抽業務領域與流程
/understand-knowledge ~/path/to/wiki
```

**⚠️ 注意**
- **第一次 `/understand` 很吃 token**：README 明說大專案會用掉大量 token，建議先從子目錄開始（`/understand src/frontend`）。四個工具裡它的 LLM 成本最高。實測 232 個 TS 檔約用了 156 萬 token、10 分鐘；codegraph 同範圍 1.7 秒、0 token。
- 🔴 **把子目錄當專案根，會悄悄漏掉路徑別名**：`tsconfig.json` 落在範圍外，`@/` 別名就解析不了。實測 import 邊只剩 128 條（正確是 278 條）。file-analyzer 又只依 import 資料建 `calls` 邊，跨檔呼叫跟著被丟掉，而且不會報錯。縮小範圍時，專案根要包含 tsconfig，再用 `--exclude` 排除不要的目錄。
- **別拿它回答「誰呼叫這個方法」**：它是 class 層級的圖。實測問「誰呼叫 `assertWithinQuota`」，漏了 1 個、多了 2 個假陽性（同一個 class 呼叫的其實是別的方法）。抽樣 30 條 `calls` 邊沒有捏造的，它的問題是漏和不穩。
- **程式碼內容會送給模型**：摘要由 LLM 產生。公司 codebase 要用時，README 建議改接本機模型（如 Ollama）。
- 儀表板本身可以在內網用 Node 起服務瀏覽，但**建圖那一步一定要 LLM**；來源文章說「不呼叫 LLM」只對瀏覽成立。

**📊 實測（2026-10-17）**：拿同一題流程解說比較，以它的圖當地圖的 agent 和用 codegraph 的 agent 答得一樣準（事實抽查都是 10/10），每題都花約 8 萬 token。它的分層和導覽讓答案涵蓋面較廣。結論：它是給人看的地圖，codegraph 是給 agent 查的索引 → [[moc/AI技能評比|評比]]

**🔗 相關**：[graphify](#graphify) —— 同樣混合 tree-sitter 和 LLM，但 graphify 只在文件上用 LLM、程式碼完全本機；Understand-Anything 是每個檔都用 LLM 寫摘要。

---

## 🔗 相關
- 📊 自己跑的對照實測報告 → [[moc/AI技能評比|AI 技能評比]]
- 自己在用的 gstack skills（/browse、/review、/ship 等）不收在這頁，那些是工作流不是收藏
- 打造自己的 AI 工具：[[moc/MCP|MCP]]、[[moc/AI工程|AI工程]]
