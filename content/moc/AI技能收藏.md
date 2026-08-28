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
| [ai-short-drama-screenwriter](#ai-short-drama-screenwriter) | skill | Codex | 繁中短劇編劇：八階段流程＋可拍性檢查，只做劇本不越界 | [repo↗](https://github.com/POUND0423/AI-drama-pound) | ⬜ |
| [archify](#archify) | skill | 多平台 | codebase／描述 → 會自我驗證的互動架構圖 HTML | [repo↗](https://github.com/tt-a1i/archify) | ⬜ |
| [i-have-adhd](#i-have-adhd) | plugin | Claude・Codex | 逼 agent 答案先講、不鋪陳客套 | [repo↗](https://github.com/ayghri/i-have-adhd) | ⬜ 📊 |
| [ponytail](#ponytail) | plugin | 多平台 | 寫碼前爬「該不該寫」階梯，砍過度設計 | [repo↗](https://github.com/dietrichgebert/ponytail) | ⬜ 📊 |
| [go-modern-guidelines](#go-modern-guidelines) | plugin | 多平台 | 給 agent 一份現代 Go 對照表，別再產出過時寫法 | [repo↗](https://github.com/JetBrains/go-modern-guidelines) | ⬜ |
| [eli5](#eli5) | skill | Claude Code | 依聽眾（5 歲／主管／工程師／家人）換一套講法解釋同一件事 | [repo↗](https://github.com/DreambigOu/ELI5) | ⬜ |
| [codegraph](#codegraph) | MCP | 多平台 | 本機碼圖譜，讀流程強、caller 會漏 | [repo↗](https://github.com/colbymchenry/codegraph) | ✅ 📊 |
| [codebase-memory-mcp](#codebase-memory-mcp) | MCP | 多平台 | 同路線，caller 完整、只給名稱無 body | [repo↗](https://github.com/DeusData/codebase-memory-mcp) | ✅ 📊 |

---

## 🎨 影像與內容創作

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

### ai-short-drama-screenwriter
`skill` · Codex（桌面版／CLI／IDE extension） · MIT · ★375 · ⬜ 待試

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

---

## 📐 架構圖與技術溝通

> 跟上面的生圖 skill 差在**輸出的正確性有沒有人管**：那些產的是美術品，好看就是成功；這類產的是**技術陳述**，畫得漂亮但接錯線就是有害。所以要看的重點是「它會不會驗自己」。

### archify
`skill` · Claude Code・Codex・Cursor・opencode・Raven · MIT · ★20.6k · ⬜ 待試

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

---

## 🧠 回應風格與寫碼紀律

> 都是「**改 agent 怎麼寫／怎麼答**」而不是「給新能力」。差別在觸發時機：前兩個裝上**每輪生效**，會改變你所有對話的預設；`go-modern-guidelines` 只在**碰到 Go 任務時**才被叫起來，平常不影響。
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

### go-modern-guidelines
`plugin` · Junie・Claude Code・Codex・Cursor・opencode · Apache-2.0 · ★2.2k · ⬜ 待試

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
