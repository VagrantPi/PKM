---
type: article
title: "Archify 架構圖 skill"
source_url: https://github.com/tt-a1i/archify
author: tt-a1i
site: GitHub
tags: [ai, llm, skill, tooling, architecture, methodology]
captured: 2026-08-27
read_status: read
---

## 📌 30 秒摘要（讀完用自己的話寫一句）
> 這篇在講：**Archify** 這個 agent skill——把 codebase 或系統描述變成一頁自足的互動式架構圖 HTML。但真正值得研究的不是它畫得漂亮，是它的**架構選擇**：**不讓模型直接產最終產物**，而是讓模型產 typed JSON IR，再由確定性編譯器渲染，中間卡一道分級驗證閘，失敗時回傳**機器可讀的修復收據**。它的 `SKILL.md` 是我看過把「不准造假通過」寫得最徹底的一份。

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- 我自己在寫 skill，這份 `SKILL.md` 是**教科書等級的範本**——尤其是「怎麼讓 agent 不要謊報成功」與「怎麼管 agent 的 context 預算」。
- 它示範的「typed IR ＋ 確定性編譯」是一個可以搬到任何「要 LLM 產結構化產物」場景的架構。
- 工具本身：要跟人解釋一個系統時，這比 Mermaid 好用的地方在**它會驗證**。

## 🧰 這篇給我的工具（連到 tools/ 工具卡）
- [[工具-讓LLM產出可驗證的產物]] — 當我想「讓 AI 產的東西能自動驗，而不是憑肉眼看」的時候
- [[工具-防止agent造假通過驗收]] — 當我寫 skill、要定義「什麼叫做完」的時候

## ✨ 關鍵重點

### 1. 核心架構：模型不產最終產物，只產 typed IR
```
agent → typed JSON IR → 確定性編譯 → HTML + inline SVG（單一檔案）
              ↓
        分級驗證閘（失敗回結構化診斷）
```
規格自己的話：「the agent chooses hierarchy, spacing, routes, and emphasis」——**版面判斷交給模型，像素計算交給編譯器**。這個分工是整個設計的樞紐。

### 2. 「Artifact first」——直接反制 LLM 的規劃癱瘓
`SKILL.md` 的第 3 步寫得極硬：
> "Artifact first: the next tool action **must** write the candidate. Write the candidate before inspecting renderer internals. **Do not plan exact coordinates in prose.**"

**我的補註**：這是針對 LLM 一個非常具體的失敗模式——在散文裡把座標算來算去、算到自己都亂掉。乾脆禁止，強迫先產出再依診斷修。

### 3. Context 預算被寫進指令
> "**Do not read** `renderers/shared/geometry.mjs`, renderer source, validator source, tests, or benchmarks before the first candidate."
> "Read one matching schema... and one matching JSON example. **Read only those files.**"
> "Read `references/viewer-runtime.md` **only when** the user explicitly asks for Share Cards, motion, guided stories, deep links..."

主 `SKILL.md` 保持精簡，深度內容切成 `references/authoring-contract.md`、`delivery-contract.md`、`viewer-runtime.md`，**按需才讀**。

### 4. 驗證分級，而且明令不准拿低標當通過
> "A receipt with **only 4 artifact checks is basic validation, never showcase acceptance**. A showcase pass must report **all 9 artifact checks with 0 composition errors and 0 warnings**."

### 5. 修復是「有界的」——三重限制
- **只改被診斷的那一項**：「change only the diagnosed `subject`, verify `evidence`, choose from `supportedFixes`」。
- **一次只套一個幾何控制**：「apply at most one diagnosed geometry control per repair」。
- **收斂條件寫死**：「Continue focused correction **while the objective error count reaches a new minimum**. If **two consecutive rounds do not improve** that best count, **stop and report the unresolved diagnostics truthfully**.」

**我的補註**：最後這條解決的是 agent 最貴的失敗模式——無止境地重試同一個修不好的東西。它給了客觀的停止條件（最佳錯誤數兩輪沒進步），而不是模糊的「試幾次就好」。

### 6. ⭐ 誠實條款——這是全篇最值得抄的部分
它不只說「要誠實」，而是**逐條列舉作弊手法並禁止**：
> "**Never counterfeit a pass with `overflow: hidden`, clipped content, an internal diagram scroller, stretched SVG height, or smaller typography.**"
> "**A non-zero exit can never be described as success.**"
> "Never delete a meaningful label **merely to pass** `showcase`."
> "must not remove the engineering profile **merely to pass validation**; repair the facts or report the diagnostics truthfully."
> "Do not claim success for a non-zero command **or claim visual inspection you did not perform**."

還有一個結構性設計：`visual-check` 的自動收據**永遠回報 `visualReview: "pending"`**——截圖是**證據**，不是自動的通過宣稱。工具刻意不給 agent 一個可以自我宣告「看起來很好」的欄位。

### 7. 交付是原子的
`deliver` 會：凍結規格的確切 bytes 成私有同目錄快照 → 渲染並檢查該快照 → **通過才原子替換**目標 HTML → 回報規格與產物各自的 SHA-256 與 byte counts。
搭配「A passing final validation **freezes** the candidate: never edit it afterward」——通過即凍結，杜絕「驗完再偷偷改一下」。

### 8. 真實性延伸到產物本身
互動功能（搜尋、上下游追溯、路徑探測、角色比較、導覽故事）規格都強調**重用已授權的節點與關係，不發明拓撲、不宣稱執行期影響**。
`deployment-ownership` 這個工程剖面是 **fail closed**：缺 owner、缺單一區域配置、缺私有資料庫範圍、缺具名邊界跨越就直接失敗，而且**永不靜默啟用**。

### 9. 明確的非目標
Mermaid 自動解析、通用 auto-layout、hosted sharing、WYSIWYG 編輯——**都刻意排除在範圍外**。
它對 Mermaid 輸入的處理也很有意思：「讀 Mermaid 取得拓撲與語義，然後**重新撰寫** Archify JSON；不要機械式地照搬 Mermaid 樣式。」

### 10. 基本資料
`skill` · Claude Code／Codex／Cursor／opencode／Raven · MIT · ★20.6k · 最新 release v2.15.0（2026-08-17），README 標示開發版 v2.16.0-dev.0。
五種圖：`architecture`／`workflow`／`sequence`／`dataflow`／`lifecycle`。
基於 `Cocoon-AI/architecture-diagram-generator`（MIT, v1.0）。

## 💬 原文摘錄
- 分工的核心：
  > "Layout judgment over generic auto-layout — the agent chooses hierarchy, spacing, routes, and emphasis"
- 失敗回饋的形狀：
  > "Failures come with a repair receipt — `validate --json` and `deliver --json` return stable rule codes, the exact subject, measured evidence, and only supported repair controls instead of a Node stack or an unstructured retry guess."
- 定位：
  > "Archify is not a general-purpose drawing editor or a Mermaid theme. It turns technical intent into a communication artifact."
- 對互動真實性的要求：
  > "Truthful interaction — focus, upstream/downstream reach, exact routes, role comparison, and stories reuse authored nodes and relationships instead of inventing topology or claiming runtime impact."

## 🔗 相關
- [[moc/AI技能收藏#archify|收藏頁的 archify 卡]] — 怎麼裝、怎麼用的速查
- [[工具-把重複的prompt包成skill]] — 這份 `SKILL.md` 正是「一個寫得極好的 skill」長什麼樣的實例
