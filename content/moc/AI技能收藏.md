---
type: moc
title: "AI 技能收藏"
tags: [moc, ai, skills, agent, tooling]
---

> 收藏值得一試的 **AI agent 外掛**——skill、plugin、MCP server 都收（Claude Code / Codex / 其他平台）。
>
> 📌 **只收「裝進 agent 裡用的」**。自己打開來用的網站、本機應用、素材庫（就算背後有 AI）收在 [[moc/工具收藏|工具收藏]]。
>
> ⚠️ **這頁收的是外部現成工具**（不是我從書裡萃取的心法）。每張卡記「做什麼、裝哪、怎麼用、我試了沒」；**我自己跑的對照實測結論在 [[moc/AI技能評比|AI 技能評比]]**，這裡只放一句話 + 連結，不重抄。

**圖例**　型態：`skill` `plugin` `MCP`　狀態：⬜ 待試・✅ 已在用・📊 已跑實測
（★ 為查看當時概數，非即時。）

## 📇 快速索引

依下方分段分組；每組點名稱跳到卡片。

**🎨 影像與內容創作**（11）

| 名稱 | 型態 | 平台 | 一句話 | 來源 | 狀態 |
|---|---|---|---|---|---|
| [gc-minimal-zine-poster](#gc-minimal-zine-poster) | skill | Codex | 主題／照片 → 極簡 zine 風海報，直接生圖 | [repo↗](https://github.com/LiamGvchi/gc-minimal-zine-poster) | ⬜ |
| [editorial-vision-studio](#editorial-vision-studio) | skill | Codex | 視覺導演引擎：決策管線＋可換模型 adapter | [repo↗](https://github.com/Yu-0312/editorial-vision-studio) | ⬜ |
| [mono-color](#mono-color) | skill | Claude Code・多平台 | 單色／雙色編輯印刷風格圖像，最多兩塊印版的硬約束 | [repo↗](https://github.com/yanliudesign/mono-color-skill) | ⬜ |
| [MiniMax-H3 skills](#minimax-h3-skills) | skill | npx skills | H3 全模態影音模型附的九個 prompt／影片生成 skill | [repo↗](https://github.com/MiniMax-AI/MiniMax-H3) | ⬜ |
| [ai-short-drama-screenwriter](#ai-short-drama-screenwriter) | skill | Codex | 繁中短劇編劇：八階段流程＋可拍性檢查，只做劇本不越界 | [repo↗](https://github.com/POUND0423/AI-drama-pound) | ⬜ |
| [scroll-world](#scroll-world) | skill | Claude Code・Codex・多平台 | 生成 AI 場景＋鏡頭影片，做捲動穿梭的沉浸式落地頁（**會扣真錢**） | [repo↗](https://github.com/oso95/scroll-world) | ⬜ |
| [video-shotcraft](#video-shotcraft) | skill | Claude Code・Codex・npx skills | 用自己產品的真實截圖＋124 張動效配方卡，以 Remotion 程式碼做出可再編輯的產品宣傳片 MP4（不是 AI 生影片） | [repo↗](https://github.com/Vincentwei1021/video-shotcraft) | ⬜ |
| [drama-skills](#drama-skills) | skill | Claude Code・Codex・npx skills | 12 個 skill 串起 AI 短劇／漫劇整條產線：原著→劇本→分鏡→圖／影片提示詞→確認後才花錢生成→剪成片；腳本檢查跨鏡一致性 | [repo↗](https://github.com/zenstory-ai/drama-skills) | ⬜ |
| [awesome-short-drama-skills](#awesome-short-drama-skills) | skill（＋清單） | 多平台（npx skills） | 86 個 AI 短劇／漫劇 skill 的人工核對清單，附三輪盲比實測（劇本、選題、全劇骨架各哪幾個贏過「不裝 skill」）；本身也是幫你挑 skill 的 skill | [repo↗](https://github.com/UnderleveledBuilder/awesome-short-drama-skills) | ⬜ |
| [漫劇老李 manju-laoli-skill](#漫劇老李-manju-laoli-skill) | skill（1 總控＋10 子技能） | OpenClaw・通用 agent | Seedance 專用的漫劇導演規則庫：5 道前置鎖逼你先選定、資產先鎖再分鏡、七段式提示詞，出稿前跑腳本機檢 | [repo↗](https://github.com/lixiaoxiao9888-create/manju-laoli-skill) | ⬜ |
| [Agent Sprite Forge](#agent-sprite-forge) | plugin | Claude Code・Codex・Grok | 一張角色定稿圖 → 每個動作各生一段影片 → Python 工具去背、選循環、調節奏，打包成 Godot／Aseprite／網頁可用的遊戲 sprite（**接付費 API 會花錢**） | [repo↗](https://github.com/0x0funky/agent-sprite-forge) | ⬜ |

**📐 架構圖與技術溝通**（3）

| 名稱 | 型態 | 平台 | 一句話 | 來源 | 狀態 |
|---|---|---|---|---|---|
| [archify](#archify) | skill | 多平台 | codebase／描述 → 會自我驗證的互動架構圖 HTML | [repo↗](https://github.com/tt-a1i/archify) | ⬜ |
| [architecture-diagram-generator](#architecture-diagram-generator) | skill | Claude.ai・Claude Code | 描述 → 深色主題架構圖 HTML；純 prompt＋設計規範，**不驗證** | [repo↗](https://github.com/Cocoon-AI/architecture-diagram-generator) | ⬜ |
| [diagram-design](#diagram-design) | skill | Claude Code・Codex・多平台 | 描述 → 套你品牌色的編輯風圖表 HTML（45 種，含架構、時序、ER、甘特、Sankey），能把 Mermaid／draw.io 重畫 | [repo↗](https://github.com/cathrynlavery/diagram-design) | ⬜ |

**🖌 前端與 UI 設計**（1）

| 名稱 | 型態 | 平台 | 一句話 | 來源 | 狀態 |
|---|---|---|---|---|---|
| [UI UX Pro Max](#ui-ux-pro-max) | plugin／skill | Claude Code・20+ 平台 | 做 UI 前先依產品類型查出一整套設計系統（版型、風格、配色、字體、該避免的寫法、交付前檢查清單），再照著寫 | [repo↗](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | ⬜ |

**🛠 工程工作流**（3）

| 名稱 | 型態 | 平台 | 一句話 | 來源 | 狀態 |
|---|---|---|---|---|---|
| [superpowers](#superpowers) | plugin | 15+ harness | 一整套強制執行的開發方法論：腦力激盪→計劃→TDD→subagent 執行→審查 | [repo↗](https://github.com/obra/superpowers) | ⬜ |
| [Skills For Real Engineers](#skills-for-real-engineers) | plugin | Claude Code・多平台 | Matt Pocock 的 38 個 skill（v1.3.1）：拷問→規格→票→實作→審查→PR→回顧 | [repo↗](https://github.com/mattpocock/skills) | ⬜ |
| [code-modernization](#code-modernization) | plugin | Claude Code | Anthropic 官方：舊系統現代化的整套流程（評估→抽業務規則→計畫→改寫→**用腳本證明新舊行為一致**），人在 6 個關卡拍板 | [repo↗](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-modernization) | ⬜ |

**🧠 回應風格與寫碼紀律**（4）

| 名稱 | 型態 | 平台 | 一句話 | 來源 | 狀態 |
|---|---|---|---|---|---|
| [i-have-adhd](#i-have-adhd) | plugin | Claude・Codex | 逼 agent 答案先講、不鋪陳客套 | [repo↗](https://github.com/ayghri/i-have-adhd) | ⬜ 📊 |
| [ponytail](#ponytail) | plugin | 多平台 | 寫碼前爬「該不該寫」階梯，砍過度設計 | [repo↗](https://github.com/dietrichgebert/ponytail) | ⬜ 📊 |
| [go-modern-guidelines](#go-modern-guidelines) | plugin | 多平台 | 給 agent 一份現代 Go 對照表，別再產出過時寫法 | [repo↗](https://github.com/JetBrains/go-modern-guidelines) | ⬜ |
| [karpathy-guidelines](#karpathy-guidelines) | plugin | Claude Code・Cursor | 四條原則治 LLM 寫碼的老毛病：亂假設、過度設計、順手亂改 | [repo↗](https://github.com/multica-ai/andrej-karpathy-skills) | ⬜ |

**🗣 解釋與表達**（1）

| 名稱 | 型態 | 平台 | 一句話 | 來源 | 狀態 |
|---|---|---|---|---|---|
| [eli5](#eli5) | skill | Claude Code | 依聽眾（5 歲／主管／工程師／家人）換一套講法解釋同一件事 | [repo↗](https://github.com/DreambigOu/ELI5) | ⬜ |

**🔍 程式碼理解（MCP）**（6）

| 名稱 | 型態 | 平台 | 一句話 | 來源 | 狀態 |
|---|---|---|---|---|---|
| [codegraph](#codegraph) | MCP | 多平台 | 本機碼圖譜，讀流程強；caller 10 月重測全中 | [repo↗](https://github.com/colbymchenry/codegraph) | ✅ 📊 |
| [codebase-memory-mcp](#codebase-memory-mcp) | MCP | 多平台 | 同路線，caller 完整、只給名稱無 body | [repo↗](https://github.com/DeusData/codebase-memory-mcp) | ✅ 📊 |
| [graphify](#graphify) | skill | 多平台 | 程式碼＋文件＋PDF 建成一張圖，每條邊標可信度（EXTRACTED／INFERRED／AMBIGUOUS） | [repo↗](https://github.com/Graphify-Labs/graphify) | ⬜ 📊 |
| [GitNexus](#gitnexus) | MCP | 多平台 | 程式碼圖資料庫＋19 個 MCP 工具（影響分析、執行流、改名），**非商用授權** | [repo↗](https://github.com/abhigyanpatwari/GitNexus) | ⬜ 📊 |
| [Understand-Anything](#understand-anything) | plugin | Claude Code・多平台 | 多 agent 分析 codebase → 互動式儀表板＋導覽，給新人看懂專案 | [repo↗](https://github.com/Egonex-AI/Understand-Anything) | ✅ 📊 |
| [Floorplan](#floorplan) | plugin | Claude Code・Codex | 給「用 AI 做出 app 但沒讀過程式碼」的人：白話的互動式 app 地圖，前後端請求跨 repo 對上，附常見資安漏洞健檢與「AI 剛改了什麼」 | [repo↗](https://github.com/haydenschmitty/floorplan) | ⬜ |

**🎮 遊戲開發**（1）

| 名稱 | 型態 | 平台 | 一句話 | 來源 | 狀態 |
|---|---|---|---|---|---|
| [awesome-gamedev-agent-skills](#awesome-gamedev-agent-skills) | skill（79 個＋router） | 多平台（npx skills）・Claude Code plugin | 12 個遊戲引擎的 79 個 skill，router 依專案檔案判斷引擎、只載入 2–3 個相關的；版本釘在官方文件 | [repo↗](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | ⬜ |

**💼 職能與知識工作**（1）

| 名稱 | 型態 | 平台 | 一句話 | 來源 | 狀態 |
|---|---|---|---|---|---|
| [Knowledge Work Plugins](#knowledge-work-plugins) | plugin（11 個） | Claude Cowork・Claude Code | Anthropic 官方：業務、客服、PM、行銷、法務、財務、資料等職能各一個 plugin，全是 markdown＋JSON，要改成自家流程才好用 | [repo↗](https://github.com/anthropics/knowledge-work-plugins) | ⬜ |

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


### video-shotcraft
`skill` · Claude Code・Codex・npx skills · Apache-2.0 · ★17.0k（2026-11-05） · ⬜ 待試

**做什麼**：跟 agent 說「幫我的產品做支宣傳片」，它會截你產品的真實頁面、從鏡頭庫挑動效、排分鏡、用 **Remotion** 寫成動畫、卡 BGM 節拍、配音效、逐格檢查，交出 **1920×1080／30fps 的 MP4 加上整個 Remotion 專案原始碼**。它**不是影片生成模型**：每一格都是程式碼用你的截圖和文案畫出來的，所以畫面清楚、跟品牌一致、之後還能改。

**核心**（靈魂是**鏡頭配方卡＋調好的 demo 原始碼**，不是 prompt）
- **124 張鏡頭配方卡、150 個鏡頭、10 類**（開場、運鏡、轉場、字體、UI 進場、互動、數據、光效、節奏、收尾），每張卡在 `references/shots/`，對應的 Remotion 實作在 `demos/`。[Gallery](https://vincentwei1021.github.io/video-shotcraft/) 可以先看動態樣片、直接複製卡名。
- ⭐ **SKILL.md 規定用卡一定要讀準確的 demo 原始碼**：卡上只有語意和參數表，demo 才是調校過的參數（緩動、時值、已知坑）。「憑卡名重寫＝放棄全部調校」，卡上標為命門的參數不准降檔。
- **視覺語言從產品本身長出來**：先從產品的設計系統／原始碼抽出字體、字級、間距、圓角、配色寫成 spec，片中所有字卡、轉場、光效都沿用；模板只繼承鏡頭結構與節奏，外觀要依目標產品重新上皮。
- **三種模式不混用**：直接套 Ink Press 模板／agent 自主一路做完／共同創作（產品簡報、視覺方向、鏡頭對應、分鏡逐關讓你確認）。沒選模式前，它只做一次唯讀的產品檢查，然後問你要哪種。
- **節奏規則很具體**：品牌字標落定後停 ≥1 秒、批量動效收尾留 0.5 秒靜止；強節奏 BGM 先做拍點分析，轉場卡在拍上，成片回測切點誤差 ≤3 格；整個畫面的節拍衝擊全片最多 3 處。
- **交付前一定派乾淨 context 的 subagent 做獨立終檢**，要附帶格號的證據；渲染必須可重現（禁 `Date.now()`／`Math.random()`，亂數用固定種子）。

**裝**（照抄 README）
```bash
# 最簡單：把連結丟給 agent
#   Install this skill for me: https://github.com/Vincentwei1021/video-shotcraft
npx skills add Vincentwei1021/video-shotcraft
```
```bash
# 手動
git clone https://github.com/Vincentwei1021/video-shotcraft.git
cd video-shotcraft
ln -s "$(pwd)" ~/.claude/skills/video-shotcraft   # Claude Code
ln -s "$(pwd)" ~/.codex/skills/video-shotcraft    # Codex
```
需要 Node.js＋npm、`ffmpeg`／`ffprobe`；`uv` 只有分析 BGM 節拍時要；puppeteer 在截圖時才自動安裝。Remotion 第一次渲染會自己下載 headless Chrome。作者在 macOS 測過；headless Linux 要加 `--concurrency=1`、改用 `chrome-headless-shell`，連不到 `remotion.media` 時用 `--browser-executable` 指定本機瀏覽器。

**用**：不用指令，直接描述，例如：
- `Use video-shotcraft to make a promo for my product.`
- `Make a launch film for this repo with the Ink Press template.`（點名模板就不再問模式）
- `Use the deck-deal-flyin and row-embed shot cards to present this feature.`（從 Gallery 複製卡名指定鏡頭）
- 只想幫既有影片找音效也行：它只搜 Freesound 候選，不下載、不改畫面。

交付後會**主動開一個類似剪映的瀏覽器編輯器**（Motion Workbench，`node workbench/scripts/open.mjs <專案>`），可以改文案、字級、顏色、剪輯片段、換鏡頭再匯出。也可選擇匯出剪映草稿（作者在剪映專業版 11.2 macOS 驗證過）。

**⚠️ 注意**
- **會碰你的專案**：要截真實頁面會起你專案的本機 dev server、用 headless 瀏覽器截全頁。SKILL.md 要求客戶、個人、內部、金鑰等資料先換成虛構或去識別化內容，但截圖前還是自己確認畫面上沒有敏感資料。
- **Remotion 有自己的授權**：個人與小團隊免費，**公司可能要付費授權**（README 原文）。做公司的宣傳片前先查。
- **交付後會自動開 dev server（5198 port）**，不用的話記得關。
- **可選的社群發布**會透過 Upload-Post 的 API 發到 TikTok、YouTube、X 等平台；只有你要求才會做，而且先確認文案、先 dry-run。
- 音效從 Freesound 下載，各自有授權，CC BY 的要保留出處清單並標示作者。
- README 有贊助商廣告（API 中轉平台等），跟 skill 功能無關。

**🔗 相關**
- [[moc/工具收藏#Motion Library 動態收藏|Motion Library 動態收藏]] —— 同樣是「動效圖鑑＋複製名稱給 AI」的思路；那邊是網頁 UI 動效，這邊是影片鏡頭。
- [scroll-world](#scroll-world) —— 同樣產出產品展示影像，但 scroll-world 用付費影片模型生成畫面，這張全部用程式碼畫、不花生成費。


### drama-skills
`skill`（12 個一組） · Claude Code・Codex・npx skills · MIT · ★3.8k · v0.10.2（2026-11-05） · ⬜ 待試

**做什麼**：AI 短劇／漫劇從點子或原著一路做到成片的整套流程：原著分析 → 分集劇本 → 視覺設定 → 圖片提示詞與分鏡 → 影片提示詞 → 確認後生產 → 剪成片 → 審查。寫作用的就是你 agent 本身的模型；生成圖片、影片、配音、音樂才呼叫外部供應商。作者是 ZenStory 的漫劇工作室，說這套是把他們 2025 年以來上千個專案的工程與提示詞蒸餾出來的（README 自述，未驗證）。

**核心**（靈魂是**用檔案當唯一事實來源，再用腳本核對**）
- **五份 Markdown 各管一層**：`劇本.md`（發生什麼）、`視覺設定.md`（造型與場景）、`分鏡.md`（每鏡的起點、終點、運鏡理由、凍結關鍵幀）、`圖片提示詞.md`、`影片提示詞.md`（只寫起點到終點之間的動作）；剪片時再加 `剪輯單.md`。創作決定一律以這些文件為準。
- ⭐ **連續性鎖**：要跨鏡頭保持的造型寫成一條能**原樣貼進提示詞**的短語（例 `LOCK-JIANGCHEN-DRESS` · 鎖面 `pine-green lapel service jacket`），並列出用到它的鏡頭。`creator_markdown_check.py` 會核對五份文件之間的引用：例如關鍵幀提示詞寫到某個人物、但「視覺依據」沒列他，或分鏡時長和影片提示詞時長不一致，都會直接報錯並指出哪一鏡。
- **參考圖分三種編號**：`IMG-*` 是要生成的參考板、`PLAN-*` 是「這鏡該掛哪幾張、什麼順序、各管什麼」的計畫、`REF-*` 只留給專案裡**真的存在並檢查過**的圖。參考圖你在別的介面自己出也行，照樣產出圖生影片提示詞，不會偷偷改成文生影片。
- **先預覽、明確確認，才花錢**：生產 skill 先在檔案裡列出這批任務的準確數量、內容、參考圖、參數與 adapter，你確認後才呼叫外部 API。供應商憑證不進專案。提交後斷線時用 `audit` 找出已付費的孤兒任務、`collect` 取回結果，**不重投**。
- **剪輯也寫理由**：每段的入點出點為什麼選在那裡寫進剪輯單，字幕逐字取自劇本，統一響度後渲染；核對與量測腳本只回報事實，不下判斷。

**裝**（照抄 README）
```bash
npx skills add zenstory-ai/drama-skills -y -g   # -g 全域；拿掉只裝在目前目錄。更新就重跑同一行
```
```bash
# 手動：可以全裝，也可以只連需要的那幾個
git clone https://github.com/zenstory-ai/drama-skills.git && cd drama-skills
mkdir -p "$HOME/.claude/skills"
for skill in skills/*; do
  ln -s "$PWD/$skill" "$HOME/.claude/skills/$(basename "$skill")"
done
# Codex 改連到 "${CODEX_HOME:-$HOME/.codex}/skills"
```
腳本要 Python 3.9 以上；剪片要 `ffmpeg`／`ffprobe` 在 PATH 上。不需要 GPU。

**用**：Claude Code 用 `/short-drama`，Codex 用 `$short-drama`，也可以直接講自然語言。
- `short-drama`：初始化專案、路由、視覺方向、本機創作台（`/short-drama dashboard`，只聽本機）。
- `novel-analyze`（原著抽樣快評、值不值得拆）、`breakdown`（量對標劇的集長、鏡長、對白密度並對照）、`develop`（改編與分集地圖）、`write`、`assets`、`image-prompts`、`storyboard`、`video-prompts`、`produce`、`edit`、`review`。
- 靜態漫劇（關鍵幀切換＋配音）可以跳過影片提示詞，直接從關鍵幀進生產。
- 匯出：`project_tool.py export <project> --out <專案外目錄>`，加 `--no-media` 只交文字。

**⚠️ 注意**
- 🔴 **生成媒體要花真錢**，走你自己的供應商帳號（內建 adapter 支援 Seedance、GPT Image 2、MiniMax H3 影片、MiniMax Music）。README 的 68 秒樣片，影片生成成本約 40 元人民幣（作者自述）。
- **升級後既有專案要重跑檢查**：規則會收緊（例如 v0.7.0 起時長不一致直接報錯），每集要重跑 `creator_markdown_check.py`，剪過的要再跑 `edit_tool.py check`。
- **H3 的眉角是小樣本觀察**：中文對白約 4.1 個字／秒，太密會趕讀或被截斷；口型可能落到畫面裡更顯眼的那張臉上。作者自己標了樣本小。
- 改編原著要有權利：README 的範例明寫「我擁有或獲准改編的」。
- 文件以簡體中文為主；更新很頻繁（403 commits、25 tags）。

**🔗 相關**
- [ai-short-drama-screenwriter](#ai-short-drama-screenwriter) —— 同領域。那張只寫劇本、刻意不碰分鏡；這套從劇本一路管到成片。只要劇本可以用那張，要整條產線用這套。
- [MiniMax-H3 skills](#minimax-h3-skills) —— 這套的影片提示詞有 MiniMax H3 專用寫法，生產也能直接接 H3。
- [[工具-會花錢的skill該怎麼設計]] —— 「先預覽、確認才花錢、斷線不重投」是那張卡的實例。
- [awesome-short-drama-skills](#awesome-short-drama-skills) —— 第三方清單；它的第一輪劇本盲比（2026-10-18）裡，這套是勝過「不裝 skill」對照組的 4 個之一


### Agent Sprite Forge
`plugin`（含 `generate2dsprite`、`video2dsprite`、`generate2dmap` 等 skill） · Claude Code（plugin）・Codex・Grok · MIT · ★5.7k · v0.6.0（2026-11-14） · ⬜ 待試

**做什麼**：做 2D 遊戲角色動畫。你先核准**一張角色定稿圖**（master still），agent 再用它替每個動作（待機、走、跑、攻擊、跳、受傷）各生成一段**圖生影片**，最後由**確定性的 Python 工具**把影片去背、對齊、選出循環段、把動作調回遊戲節奏、統一顏色，打包成 Godot、Aseprite 或網頁遊戲能直接用的 sprite。另外也能做地圖（分層地圖、tile、橫向卷軸關卡），匯出到 Tiled、Godot、LDtk。

**核心**（靈魂是**生成交給模型，品質交給可量測的程式**）
- **先定稿一張，再展開整套**：`master_still.py` 產生 3 個候選，小問題用編輯修（`THE ONLY CHANGE: ...`），核准一張寫進 `master.json`；之後每個動作的提示詞都會重複其中的角色特徵摘要，維持同一個角色。
- ⭐ **每段影片過一長串關卡才收**：角色大小、腳、身分、縮放、轉身、邊緣、背景、多出的物件、動作量、結束姿勢、顏色滲漏、時間長度；不合格最多重拍 3 次並附上修正指示。但 README 明說**數字看不出武器被換掉或臉被擋住**，所以 agent 接受每個動作前都要看過總覽圖。
- **把影片模型的毛病修掉**：圖生影片會把快速的攻擊拍成慢動作，`retime.py --auto-oneshot` 剪掉停格、把命中幀釘住（攻擊 4.1 秒 → 0.7 秒）；走路循環依實測挑選，跑速依著地腳量，腳不會滑；「顏色鎖」把快速移動的肢體顏色拉回定稿圖的顏色。
- **像素風不叫模型畫像素**：模型畫出來的「像素圖」格子大小不一、顏色上萬種。hibit 風格改叫模型畫**平塗無線稿**的圖，再用 8×8 多數決縮小（每格取覆蓋最多的調色盤顏色、不混色）、從角色本身學調色盤、自動描邊；v0.6.0 的 pixel looks 則把模型畫的圖**讀回真正的網格**（例：1254×1254、88,410 色的圖 → 33×55、48 色、2.5 KB，作者實測）。
- **生成路線依序選**：有設定 API key 就用 API（OpenAI、Gemini、xAI、BytePlus、fal.ai）→ 否則用你已登入的 Codex 或 Grok CLI（吃訂閱額度，不用 API key）→ 最後才用程式畫（會明說是程式畫的）。審查拒絕、或可能已經花錢的失敗，**不會換路線重試**。

**裝**（照抄 README）
```bash
# Claude Code（plugin）
claude plugin marketplace add 0x0funky/agent-sprite-forge --sparse .claude-plugin skills
claude plugin install agent-sprite-forge@agent-sprite-forge
python -m pip install "numpy>=1.26" "Pillow>=10.1" "scipy>=1.11"
```
```bash
# Codex（Grok 把 --host 換成 grok）
git clone https://github.com/0x0funky/agent-sprite-forge.git
cd agent-sprite-forge
python -m pip install -r requirements.txt
python tools/install_skills.py --apply --host codex
```
眉角：`--sparse` 只抓 plugin 設定和 skill，不下載展示影片；影片處理要 `ffmpeg` 5.1 以上；裝完要開新的 agent session 才會載入。`install_skills.py --check` 可以檢查已裝版本有沒有被改動。

**用**：
- `Use $generate2dsprite to make a master still of Aria, ...`（先做定稿圖）
- `Use $video2dsprite to animate the approved Aria master: idle, walk, run, attack, jump and hurt. Package them for Godot and the web.`
- 底層是 `sprite_set.py plan → run → review → accept → report`；`run` 中斷後會接著做，**同一段影片不會生成兩次**。

**⚠️ 注意**
- 🔴 **設定了 API key 就直接花錢、不逐次詢問**：README 原文是「key 就是你的同意」。而且**預設沒有花費上限**，要自己設 `--budget-usd`、`--max-calls` 或 `FORGE_MAX_PAID_REQUESTS`。每次呼叫都會記在 `<專案>/.forge/ledger.jsonl`，`media_ledger.py summary` 看總額。
- **沒設 key 會用你已登入的 Codex／Grok CLI**，吃的是訂閱額度。
- **API key 放在使用者設定資料夾**（macOS／Linux：`~/.config/agent-sprite-forge/config.json`，要 `chmod 600`），不要放進專案。README 說 key 只在程序內讀取、不印出、不寫 log、不傳給子程序（未驗證）。
- **編輯器匯入還沒驗證**：README 自己寫，沒有人實際在 Godot、LDtk、Aseprite 編輯器裡開過 0.4.0 的匯出檔；目前只證明到檔案解析層級的來回轉換。
- 文中的數字（顏色數、時間、QC 誤判率）都是作者在自己 live run 上量的，未驗證。
- 用 hibit 特效建議另裝 pixelfx（MIT，需 Node 18+），它的 render 會附上授權檔；Gemini 產圖會帶 SynthID 浮水印。

**🔗 相關**
- [scroll-world](#scroll-world) —— 同樣是「先定稿靜圖、再圖生影片」的管線、同樣會花錢；scroll-world 做網頁捲動背景，這張做遊戲角色。
- [[工具-會花錢的skill該怎麼設計]] —— 這張的花費紀錄（ledger）和「可能已花錢就不重試」是實例；但它**預設沒有上限、有 key 就不逐次問**，跟那張卡「講出估計總額、拿到 go 才開始生成」的原則相反，用之前自己先設好預算上限。


### awesome-short-drama-skills
`skill`（`short-drama-skill-finder`）＋精選清單 · 多平台（npx skills） · CC0 · ★2.3k（2026-11-14） · ⬜ 待試

**做什麼**：AI 短劇、漫劇 skill 的精選清單（[shortdramaskills.com](https://shortdramaskills.com)），收 86 個 skill 專案和 16 個相關開源平台（元資料更新於 2026-11-02），依類型（全流程、編劇、分鏡與提示詞、IP 評估、編劇基本功、去 AI 味）、創作階段和適配的影片模型（Seedance、可靈、MiniMax H3、通義萬相…）整理。每個條目標了 ★、最後更新日、skill 數、授權，以及「整合了別人的內容卻沒註明」這類備註。

**核心**（比一般 awesome list 多做的事）
- ⭐ **三輪盲比實測**，都有「不裝 skill」的對照組，兩位 AI 評審（Opus 和 GPT）盲比，只用 claude-opus-5-5 一個模型寫：
  - **寫劇本**（2026-10-18）：10 個 skill，各寫 3 次。兩位評審都判三次全贏對照組的有 4 個，包括 [drama-skills](#drama-skills)。
  - **定選題**（2026-10-20）：11 個 skill，兩兩盲比排名；**不裝 skill 的對照組排第 9，有 3 個 skill 排在它後面**。
  - **寫 60 集全劇骨架**（2026-10-31）：20 個 skill；兩位評審 630 對裡只有 332 對結論一致，有 6 個兩位評審都排在對照組後面。
  - 每輪都把限制寫出來（評審意見不一、只有一張選題卡、只測一個模型、有些稿件超字數被截斷）。
- **「人工核對」只代表核對過 README、目錄與分類，不代表實測過效果**，清單自己寫明了。
- **推薦組合**（例如「小說改編短劇」「用 Seedance 出片」）標明是依 README 搭配、**尚未實測**。

**裝／用**
```bash
npx skills add UnderleveledBuilder/awesome-short-drama-skills   # 裝上 short-drama-skill-finder
```
裝好後問 agent：「我用 Codex 做小說改編短劇，裝哪個 skill？」。清單裡各 skill 的安裝指令是依 skills CLI 寫的預設，**清單自己標明未逐個驗證**，以各 repo 的 README 為準。

**⚠️ 注意**
- 清單提醒：**skill 可能附帶腳本，安裝前先讀一遍它的 SKILL.md**。
- 評測是「交給 AI 從頭拍成片」的標準，評審也是 AI；換題材、換模型，名次可能不同。
- 收錄的多是簡體中文 skill；有些條目沒有授權（清單有標註）。

**🔗 相關**
- [drama-skills](#drama-skills) —— 清單裡的精選之一，也是第一輪劇本評測勝過對照組的 4 個之一
- [ai-short-drama-screenwriter](#ai-short-drama-screenwriter) —— 繁中短劇編劇 skill，這份清單沒收
- [[工具-AI改動的AB對照評測]] —— 「有不裝 skill 的對照組、多跑幾次、雙評審盲比」正是那張卡的做法


### 漫劇老李 manju-laoli-skill
`skill`（1 總控 `short-drama-director`＋10 個 `sd-*-engine` 子技能） · OpenClaw・WorkBuddy・扣子(Coze)・Dify 等 · MIT · ★2.1k · V7.5.0-SLIM（2026-11-14） · ⬜ 待試

**做什麼**：AI 短劇、漫劇（也適用廣告片、分鏡預演、打戲設計）從立項、劇本、資產、分鏡到**影片模型提示詞**與質檢的規則庫。它**不產圖**，交付的是「提示詞＋接線說明書」，圖由你在即夢、Seedance、豆包等平台自己生成。

**核心**（靈魂是**硬門檻**：「使用者看到 5 個步驟，AI 內部跑 100 條規則」）
- ⭐ **五道前置鎖＋畫風鎖，任何一道沒選就停下來問**：素材來源（原創／改編／對標爆款／熱點速成）、模型版本（**Seedance 2.5 或 2.0 二選一**，語法完全分流）、畫幅、交付形態、多段之間怎麼銜接。README 明寫「禁止預設跳過、禁止替使用者推斷」。
- **資產先鎖再分鏡（Asset-First）**：角色、場景、道具先建台帳並鎖定，再進分鏡，避免跨鏡頭、跨集漂移。
- **七段式提示詞**：畫幅風格 → 場景資產 → 核心人物 → 站位聲明 → 時間軸分鏡 → 音效 → 強制禁止項。它對「模型對否定詞不敏感」的處理是換詞、改句式、移除觸發詞，禁止項只放負面清單。
- **出稿前腳本機檢**：`gate_check.py` 一次跑完投餵層閘門與 C 系列檢查，FAIL 清零才交付；另有 `audit_contract.py` 檢查「該交的東西交了沒」、`build_board_lite.py` 把專案 md 轉成單檔離線分鏡看板。
- 打戲分三個專門子技能：通用、玄幻仙俠、真人寫實。

**裝／用**（照抄 README）
```bash
openclaw skills install ./short-drama-director --as short-drama-director   # 總控＋10 子技能同級部署
python3 short-drama-director/scripts/check_package.py                      # 包級自檢
python3 sd-feed-engine/scripts/gate_check.py <稿>.md --model 2.5 --aspect 16:9
```
只支援單一 SKILL.md 的平台，以 `short-drama-director/SKILL.md` 為入口，子技能放同一層。常用指令：`/寫劇本`、`/做分鏡`、`/生成視頻提示詞`、`/看板`、`/審查`。

**⚠️ 注意**
- **只支援 Seedance 一條模型線**；README 列的 agent 平台以 OpenClaw、國內平台為主，沒有寫 Claude Code 的安裝方式。
- [awesome-short-drama-skills](#awesome-short-drama-skills) 的標註：**作者標為測試版，整合了其他開源內容**。
- README 有贊助商廣告（漫劇平台、IP 庫），與規則本身無關。
- 規則量很大（48 份規則庫、C1–C41 檢查碼），文件為簡體中文。

**🔗 相關**
- [drama-skills](#drama-skills) —— 同樣管整條短劇產線、也用腳本核對；drama-skills 用檔案事實核對跨鏡一致性、支援多家模型，這套鎖死 Seedance、規則更細
- [awesome-short-drama-skills](#awesome-short-drama-skills) —— 收錄並標記這套的清單

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

### diagram-design
`skill`（Claude Code／Codex 另有 plugin 包，帶斜線指令） · Claude Code・Codex・Qoder・多平台（skills CLI） · MIT · ★62.8k · v2.6.136（2026-10-30） · ⬜ 待試

**做什麼**：用一句話叫 agent 畫圖，產出**一個自足的 HTML＋內嵌 SVG 檔**，雙擊就能開，而且套的是**你網站的品牌色與字型**。涵蓋 45 種圖：架構、架構前後對照、時序、狀態機、ER、甘特、Sankey、魚骨、Wardley map 等，每種都有淺色、深色、完整編輯版三種變體。作者的出發點是「模型懂內容，缺的是品味」，所以把品味寫成規則。

**核心**
- **一套寫死的設計系統**：只用一個強調色，標在讀者該先看的 1–2 個元素；1px 細線、不用陰影、圓角最多 10px；**所有座標都要能被 4 整除**，作者說這條「不可妥協，是讓圖不像 AI 畫的關鍵」；目標密度 4/10，「最有品質的動作通常是刪除」。
- **先說計畫再畫**：agent 動筆前要先講選了哪種圖、版面多大、打算刪掉什麼。每次只載入一份圖型參考檔，以及最多兩份核心參考，不把 45 種全讀進 context。
- **品牌 onboarding**：說「onboard diagram-design to https://你的網站」，它會抓首頁的配色與字型，對應到 paper、ink、accent 等角色，先給你看 diff，同意後才寫入 `style-guide.md`，並先檢查 WCAG AA 對比。之後在新專案第一次畫圖時，如果風格檔還是預設值，它會先停下來問你。也可以存成多個品牌 profile，用專案裡的 `.diagram-design` 標記檔切換。
- **重畫既有的圖**：可匯入 `.drawio`、Mermaid、Excalidraw，有四個參數：格式、尺寸、細節（`faithful` ≤24 節點／`balanced` ≤12／`simplified` ≤7）、受眾（`engineer`／`mixed`／`executive`，會改標籤用詞）。最後附一份清單，列出哪些節點被合併、哪些被丟掉。

**裝**
```bash
# 任何支援 Agent Skills 的 host（Cursor、Codex、Copilot、Gemini CLI…）
npx skills add cathrynlavery/diagram-design
```
```text
# Claude Code（有斜線指令、可自動更新）
/plugin marketplace add cathrynlavery/diagram-design
/plugin install diagram-design@diagram-design
```
```bash
# Codex
codex plugin marketplace add cathrynlavery/diagram-design
codex plugin add diagram-design@diagram-design
```
- Claude Code 對第三方 marketplace 預設**不自動更新**。要自己在 `/plugin` → Marketplaces → diagram-design 開 **Enable auto-update**。
- 用 `npx skills add` 裝的**只有 skill 本體**，沒有 `/export-diagram`、`/import-mermaid` 這些指令。

**用**：直接講白話，例如「幫我的 app 畫架構圖：前端、後端、資料庫、Redis」。指令有 `/diagram-design:import-drawio`、`import-mermaid`、`import-excalidraw`、`export-diagram`（輸出 SVG 或 PNG，可加 `--scale=3`）、`profile`、`doctor`。

**⚠️ 注意**
- **它驗的是「檔案合格」，不是「圖畫對」**：安裝後附的 `self_check.py` 只檢查無障礙標記、有沒有載入外部資源、檔案是否完整、內容有沒有超出 viewBox。節點重疊的幾何檢查要在 repo checkout 裡才能跑。**接錯線不會被抓到**，對外用之前要自己對一遍。作者自己也承認，同一句 prompt 兩次排版可能不同。
- **輸出不是可編輯的原始格式**：PR 裡沒有文字可以 diff，也沒有畫布可以拖。作者明說，放在 Git 裡、每個 sprint 都會改的文件圖，Mermaid 還是比較適合。這個 skill 適合「要發表的那張圖」。
- **預設會連 Google Fonts**（字型），這是唯一的網路請求；要求改用系統字型就完全不連網。品牌 onboarding 會讓 agent 去抓你指定的網站。PRIVACY.md 寫明它沒有伺服器、沒有 telemetry。
- **PNG 匯出要先裝 Playwright**：`pip install playwright && playwright install chromium`。
- **版本跳很快**：每次 merge 都會自動升 patch 版，目前在 2.6.x。
- 作者列的不該用的時機：清單、前後對照，用表格就好；只有一個框的圖，直接寫一句話。動筆前先問：讀者從這張圖學到的，會比一段好文字多嗎？

**🔗 相關**：[archify](#archify) —— 同樣要拿去對外的技術圖，但 archify 有驗證閘，比較在意「畫得對」；diagram-design 圖型多很多、能套品牌，比較在意「畫得好看」。[architecture-diagram-generator](#architecture-diagram-generator) —— 一樣不驗接線，但只有深色一種風格。

---

## 🖌 前端與 UI 設計

> 讓 agent 寫前端時**先決定設計再寫碼**。這類工具多半是一大份設計知識庫加上搜尋腳本；要看的是它的建議能不能被檢查（對比、焦點、響應式），還是只是風格偏好。

### UI UX Pro Max
`plugin`／`skill` · Claude Code（marketplace）・Cursor、Codex、Gemini CLI 等 20 多個平台（CLI 安裝） · MIT · ★149k（2026-11-14） · ⬜ 待試

**做什麼**：你請 agent 做 UI（「幫我的美容 SPA 做 landing page」），它先用內建的搜尋引擎查出一整套**設計系統**：版型（Hero＋社群證明、CTA 放哪）、風格、配色（含色碼）、字體搭配（附 Google Fonts）、主要效果、**這個產業該避免的寫法**、交付前檢查清單，然後才照著寫程式。

**核心**
- **資料庫＋規則**：192 種產品類型的推理規則（每種產業對應版型、風格、配色、字體與反模式，例如銀行不要用「AI 紫粉漸層」）、80 種可搜尋的 UI 風格（51 種預設啟用）、192 組配色、74 組字體搭配、34 種 landing 版型、25 種圖表、22 個技術棧的寫法、120 條 UX 準則。用 BM25 排序，搜尋腳本只用 Python 標準函式庫、不連網。
- **交付前檢查清單值得抄**：不用 emoji 當圖示（改用 SVG）、可點的元素有 `cursor-pointer`、淺色模式文字對比至少 4.5:1、鍵盤焦點看得到、尊重 `prefers-reduced-motion`、文字與標籤在窄寬度不被裁掉、在 375／768／1024／1440px 都檢查。
- **改既有 app 的主題有一套流程**：先盤點寫死的顏色值 → 對應到既有的語意 token（background、primary、border…），缺的才新增 → 一次改一小批元件 → 每批都檢查對比、焦點、響應式與深淺色。README 提醒：**只改 token 不會影響寫死樣式的元件**。

**裝**（照抄 README）
```bash
# Claude Code（marketplace）
/plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill
/plugin install ui-ux-pro-max@ui-ux-pro-max-skill
```
```bash
# CLI（官方推薦），套件名是 ui-ux-pro-max-cli，指令仍叫 uipro
npm install -g ui-ux-pro-max-cli
cd /path/to/your/project
uipro init --ai claude            # 或 cursor、codex、gemini…；--global 裝到 ~/.claude/skills/
```
眉角：需要 Python 3；舊的 `uipro-cli` 套件已經過時，不要裝。`uipro init --dry-run` 可以先看會寫哪些檔。

**用**：Claude Code 裝好後自動觸發，直接說「Build a landing page for my SaaS product」即可；Kiro、Roo Code 等用 `/ui-ux-pro-max ...`。

**⚠️ 注意**
- **開源版與付費版**：這個 repo 是基本版；品牌識別、logo、簡報、AI 生圖素材、企業級 design token 在付費的 Premium 版（uupm.cc）。
- **它給的是設計建議，不是驗證**：README 說搜尋結果只提供指引、不會自動改你的 app；生成的配色與檢查清單仍要自己在瀏覽器裡驗（例如實際量對比）。
- ★149k、開放的 issue 與 PR 各 40 多個（2026-11-14），更新很頻繁。

**🔗 相關**
- [[moc/工具收藏#Fontshare|Fontshare]]、[[moc/工具收藏#PulsoIcon|PulsoIcon]] —— 它推薦的字體與「用 SVG 圖示、別用 emoji」可以直接換成這兩個素材來源

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

### code-modernization
`plugin` · Claude Code · Anthropic 官方（`claude-plugins-official`） · ⬜ 待試（2026-11-14）

**做什麼**：把 Claude 指向一個舊系統，拿到四樣東西：**看懂它是什麼、你核准的計畫、現代化後的程式碼、新程式碼行為跟舊的一樣的證明**。不限語言，三種方向都支援：同技術升版（uplift，例如 Java 8→17、Spring Boot 2→3）、換技術逐模組改寫（transform，例如 COBOL→Java、PHP→Python）、換架構重建（reimagine）。

**核心**（靈魂是**證明不靠模型的意見，靠腳本檢查得了的證據**）
- **一步一指令、每步都能停下來審**：`modernize`（說你要什麼，寫成 `INTENT.md`）→ `preflight`（問 5 個只有人能答的問題、證明能 build）→ `assess`（盤點、複雜度、技術債、資安）→ `map`（依賴與資料流的互動地圖）→ `extract-rules`（業務規則寫成 Given/When/Then 卡，附 `file:line`，每張由第二個 agent 複查）→ `review`（人確認或更正）→ `brief`（分階段計畫，**沒核准就不動工**）→ uplift／transform／reimagine → `verify` → `harden`（資安掃描，產出 patch 讓你自己套）。
- ⭐ **`modernize-verify` 怎麼證明**（最好在新 session 跑，重做一遍、不信前一步留下的筆記）：
  - 刪掉 build 產物、整套測試重跑，數字取自測試工具自己的結果檔；**一個測試都沒跑或被 skip 算失敗**。
  - 舊系統能跑時，新舊吃同一組輸入，**腳本逐 byte 比對**；只有時間戳、產生的 id 這類欄位可以遮，遮了什麼都要列出。
  - **自己再生至少 10 組沒用過的輸入**（邊界、空的、超大、順序怪、格式壞掉的紀錄）再比一次，抓「測試只在模型自選的案例上通過」。
  - **故意改壞一行（canary），測試必須變紅**；比對本身也用改一個 byte 驗證。
  - 每條 P0 規則都要有一個**真的跑過且通過**的測試；只被 skip 的測試點到，列為「named, not run」。
  - 每個模組一個判定：PROVEN／PARTLY PROVEN／NOT PROVEN，由 `scripts/proof_pack.py` 從證據算出，每次重算、不沿用上次。舊系統跑不起來（大型主機、只在正式環境跑）時，**最好只能 PARTLY PROVEN**。
- **人在 6 個點拍板，plugin 從不代決**：preflight 的 5 個答案、看起來不對的規則、核准計畫、接受新舊差異、簽核證明、套用資安 patch。

**裝／用**
```bash
/plugin install code-modernization@claude-plugins-official
```
開一個工作資料夾，打 `/code-modernization:modernize`，它問幾個問題後給你第一個指令；或逐步跑 `/code-modernization:modernize-preflight <name> --source <舊程式路徑>`，隨時用 `modernize-status <name>` 看進度與下一步。`--source` 只建連結不複製；所有產出寫到 `analysis/<name>/` 和 `modernized/`，並更新一頁 `REPORT.html`。

**⚠️ 注意**
- **很耗用量**：重的步驟一次開很多 agent，`extract-rules` 在作者的實測裡開了 50–200 個（大規模執行前會先問）。**先拿一個模組當試點**，百萬行級的系統一次一個模組。
- **「不改舊碼」只是慣例**：README 建議在工作區的 `.claude/settings.json` 加 `deny: ["Edit(/legacy/**)"]`、只允許寫 `analysis/` 和 `modernized/`；`--source` 建的是 symlink，要另外 deny 它的真實路徑。自己開檔的腳本不受這條規則管，大量 agent 寫檔的兩步要讓 Bash 維持需要確認的權限模式。
- **舊程式碼當作不可信輸入**：程式裡可能埋「ignore previous instructions」之類的字。README 說 agent 只把檔案內容當資料、列出看起來像指令的文字、不照做；他們用一個故意埋陷阱的 codebase 測過（作者自述）。找到的金鑰會遮蔽，原值放在 gitignore 的檔案。
- **會送使用統計**：透過 Claude Code 自己的 telemetry 送整數計數（指令、進度、錯誤代碼），README 說不送程式碼、檔名、路徑、prompt；Claude Code 的 telemetry 關掉就不送。
- README 的實測（AWS CardDemo COBOL→Java、Jetty Java 8→17、osCommerce PHP→Python 等）都是作者跑的，同一個指令跑兩次數字也會不同；而且**多數案例最後是 PARTLY 或 NOT PROVEN**，作者照實寫出來了。

**🔗 相關**
- [[工具-防止agent造假通過驗收]] —— 「沒跑測試算失敗、故意改壞要變紅、判定由腳本算」正是那張卡的完整實作
- [[工具-特徵測試]] —— 《修改程式碼的藝術》裡先把現有行為原樣釘住再改的做法；這個 plugin 改用「新舊吃同一組輸入、腳本逐 byte 比對」來釘住行為

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

### Floorplan
`plugin` · Claude Code・Codex · MIT · ★4.2k（2026-11-14） · ⬜ 待試

**做什麼**：讓 Claude 或 Codex 讀你的程式碼，畫出一張**可縮放的互動 app 地圖**：每個部分、檔案、API 都有白話名稱（「結帳時收信用卡款」而不是「Stripe API wrapper」），以及它們之間的連線。對象是**用 AI 做出 app、但自己沒讀過程式碼的人**，答「有人結帳時發生什麼事」「改這個會壞什麼」。

**核心**
- **腳本做機械活，模型做只有讀者能做的事**：找 repo、解析十幾種語言、把前端的每個請求對到回應它的後端 endpoint（**跨 repo 也行**）、排版，都由無依賴的 Node 腳本做；模型只負責決定 app 分成哪幾塊、用白話描述每個檔案。
- **從畫面出發**：挑一個你知道的頁面，看它背後的元件、請求、伺服器程式、資料和外部服務。
- **問地圖**：「退款怎麼回到客人的卡？」回答會附一張只含相關元件的小地圖和逐步說明。
- **健檢（Health check）**：抓 AI 做的 app 常見的錯：金鑰寫在程式碼裡或送到瀏覽器、任何人都能讀的 Supabase 表、開放的 Firebase 規則、可以偽造的 Stripe webhook、不用登入就能呼叫的 endpoint；每項附可直接貼上的修正 prompt。README 說這是**檢查，不是稽核**。
- **Recent work**：AI 剛改過的卡片變綠，附上「這次改動怎麼服務你的需求」。更新時只重讀有改的部分。
- 也能從 PRD 或規格畫出還沒寫的系統藍圖（卡片用虛線標成計畫）。

**裝**（照抄 README，需要 Node.js 18+，不用 API key）
```bash
claude plugin marketplace add haydenschmitty/floorplan
claude plugin install floorplan@floorplan
```
```bash
# Codex（也可以在 Codex app 的 Plugins 介面加 marketplace）
codex plugin marketplace add haydenschmitty/floorplan
codex plugin add floorplan@floorplan
```
**用**：在專案裡說「Make me a floorplan of this app」（Codex 也可以打 `$floorplan`），地圖會自己打開；之後說「Update the floorplan」。前後端分在不同 repo 時，打開包含兩者的上層資料夾。

**⚠️ 注意**
- **會在專案裡加東西**：一個 `floorplan/` 資料夾（自己 gitignore 掉）；Claude Code 裡你同意的話，還會在 `CLAUDE.local.md` 加一小段，讓之後的 session 知道有地圖，`CLAUDE.local.md` 放進 clone 的私人忽略清單。不會改 `.gitignore` 或其他追蹤中的檔案。
- **地圖的問答走你自己的 Claude Code CLI 或 Codex 帳號**（能讀碼、不能改碼）；掃描、地圖和小型本機伺服器都在本機，伺服器只接受本機連線。README 說沒有分析追蹤，只會問一次要不要收 Floorplan Cloud 上線通知。
- 健檢只顯示密鑰的位置、不顯示值；但它不是完整的資安稽核。

**🔗 相關**
- [Understand-Anything](#understand-anything) —— README 自己做了對照：Understand-Anything 給開發者逐函式讀懂大 codebase；Floorplan 給不讀程式碼的人看懂、檢查自己的 app
- [archify](#archify) —— 同一張對照表：archify 是為文件或簡報畫一張清楚的圖；README 建議先用 Floorplan 看懂，再用 archify 畫一條流程去報告

---

## 🎮 遊戲開發

> 遊戲引擎版本變動快、API 改名頻繁，agent 最容易寫出舊版寫法。這類 skill 要看的是**有沒有釘版本、有沒有在真的引擎上跑過**。

### awesome-gamedev-agent-skills
`skill`（79 個＋router） · 多平台（npx skills）・Claude Code plugin · Apache-2.0 · ★8.8k（2026-11-14） · ⬜ 待試

**做什麼**：讓 coding agent 用你原本的引擎做遊戲。涵蓋 12 個引擎（Godot、Unity、Unreal、Ebitengine、Phaser、PixiJS、three.js、Bevy、pygame、LÖVE、Defold、Roblox）共 79 個 skill，分引擎、領域（AI、shader、存檔）、遊戲類型（平台跳躍、roguelike）、發布流程（game jam、Steam、itch）。

**核心**
- ⭐ **router 自動挑 skill**：從專案檔判斷引擎（有 `project.godot` 就是 Godot、`*.uproject` 是 Unreal，判斷不出來就問），再從需求判斷主題與類型，**只載入 2–3 個**：引擎基礎 → 主題 → 類型。例如「幫我的 Godot 角色加二段跳」只載 `godot-2d-movement`＋`platformer`。引擎互斥，其他可疊加。
- **版本釘在官方文件**：Godot 4.7.2、Unity 6.3 LTS、Unreal 5.8、Phaser 4.2.1、three.js r187 等（作者查證 2026-11-11）；作者說 12 個引擎裡有 10 個的範例程式在真的工具鏈上跑過或編譯過，366 個盲測 prompt 中 98.7% 載入了正確的 skill（作者自述，未驗證）。
- **美術流程**：先鎖定視覺目標、做成系列、用確定性的方式正規化，再在遊戲裡檢查，而不是一張一張生。

**裝**（照抄 README）
```bash
npx skills add gamedev-skills/awesome-gamedev-agent-skills   # 全裝；--list 先預覽、-g 全域、-a claude-code 指定 agent（需 Node.js 22.20+）
```
```bash
# Claude Code plugin：只做一種引擎時裝 router＋該引擎就好
claude plugin marketplace add gamedev-skills/awesome-gamedev-agent-skills
claude plugin install router@awesome-gamedev-agent-skills
claude plugin install godot@awesome-gamedev-agent-skills   # 或 unity、unreal、ebitengine、web-engines、other-engines
```

**⚠️ 注意**
- ⭐ **skill 裝太多，描述會被截掉**：README 提醒 agent 列出 skill 描述有長度上限，Claude Code 是 context 的 1%，超過的描述會被截，正確的 skill 就更難被挑中。已經裝很多 skill 的人，只裝 router＋自己的引擎；或用 `skillListingBudgetFraction`（例如 0.02）、環境變數 `SLASH_COMMAND_TOOL_CHAR_BUDGET` 調高上限（README 說法，未驗證）。
- README 有贊助位廣告，作者說贊助不影響 router 選 skill。

**🔗 相關**
- [Agent Sprite Forge](#agent-sprite-forge) —— 做 2D 遊戲角色動畫素材；這套管遊戲程式碼和美術流程
- [[工具-skill集合的分層與維護]] —— skill 一多會互相搶觸發；這套用 router 只載入少數幾個，是同一個問題的一種解法

---

## 💼 職能與知識工作

> 不是寫程式用的，是把 Claude 變成某個職能的助手（業務、客服、法務、財務…）。這類 plugin 的價值多半在**接上公司自己的工具和流程之後**，開箱只是起點。

### Knowledge Work Plugins
`plugin`（11 個） · Claude Cowork・Claude Code · Anthropic 官方 · Apache-2.0 · ★35.7k（2026-11-14） · ⬜ 待試

**做什麼**：Anthropic 開源的 11 個職能 plugin，主要給 Claude Cowork 用，也相容 Claude Code。每個 plugin 打包了該職能的 skill、slash 指令、子代理和 connector（MCP）：
- **productivity**：任務、行事曆、日常流程、個人背景
- **sales**：研究客戶、準備會議、檢視 pipeline、寫開發信、競品對照卡
- **customer-support**：分類工單、草擬回覆、整理升級案、把解決的問題寫成知識庫文章
- **product-management**：寫規格、排 roadmap、整理使用者研究、更新利害關係人
- **marketing**、**legal**（合約、NDA、合規）、**finance**（分錄、對帳、財報、結帳）、**data**（SQL、統計、儀表板，分享前先驗證）、**enterprise-search**（跨 email、聊天、文件一次搜）、**bio-research**（文獻、基因體、標的排序）
- **cowork-plugin-management**：幫你建新的 plugin 或客製既有的

**核心**
- **全部是檔案**：`.claude-plugin/plugin.json`（manifest）、`.mcp.json`（工具連線）、`commands/`（手動觸發的指令）、`skills/`（自動引用的領域知識），只有 markdown 和 JSON，沒有程式碼、不用 build。
- **客製才是重點**：README 自己說這些是通用起點，要換掉 `.mcp.json` 接上自家工具、把公司術語與流程寫進 skill、照團隊實際做法改流程。也可以當成「一個職能 plugin 該怎麼切」的範本來看。

**裝／用**
```bash
claude plugin marketplace add anthropics/knowledge-work-plugins
claude plugin install sales@knowledge-work-plugins
```
裝好後 skill 會自動觸發，指令例如 `/sales:call-prep`、`/data:write-query`、`/finance:reconciliation`、`/product-management:write-spec`。Cowork 使用者從 claude.com/plugins 安裝。

**⚠️ 注意**
- **connector 會連到外部服務**：Slack、HubSpot、Jira、Notion、Snowflake 等，接上之後 Claude 讀得到這些系統的資料，權限要自己把關。
- 預設內容是通用的，不客製就只是「一般水準的職能助手」。

**🔗 相關**
- [[Claude Cookbooks]] —— 同為 Anthropic 官方 repo；cookbooks 是 API 範例，這邊是現成可裝的職能 plugin

---

## 🔗 相關
- 📊 自己跑的對照實測報告 → [[moc/AI技能評比|AI 技能評比]]
- 自己在用的 gstack skills（/browse、/review、/ship 等）不收在這頁，那些是工作流不是收藏
- 打造自己的 AI 工具：[[moc/MCP|MCP]]、[[moc/AI工程|AI工程]]
