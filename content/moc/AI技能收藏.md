---
type: moc
title: "AI 技能收藏"
tags: [moc, ai, skills, agent, tooling]
---

> 收藏值得一試的 **AI agent 外掛**——skill、plugin、MCP server 都收（Claude Code / Codex / 其他 agent 平台）。
>
> ⚠️ **這頁與其他 MOC 不同**：其他 MOC 索引的是「我從書裡萃取出來的知識」，這裡收的是**外部現成的工具**。所以每條記的是「它做什麼、裝在哪、我試了沒」，而不是心法。

## 📇 快速索引

| Skill | 型態 | 平台 | 一句話 | 我的狀態 |
|---|---|---|---|---|
| [gc-minimal-zine-poster](#gc-minimal-zine-poster) | skill | Codex | 把一個主題／句子／照片變成極簡 zine 風海報 | ⬜ 待試 |
| [i-have-adhd](#i-have-adhd) | plugin | Claude Code・Codex | 逼 agent 把答案放最前面，不要鋪陳與客套 | ⬜ 待試・📊 已實測 |
| [ponytail](#ponytail) | plugin | Claude Code・Codex・多平台 | 寫碼前先爬「該不該寫」的階梯，砍掉過度設計 | ⬜ 待試・📊 已實測 |
| [codegraph](#codegraph) | MCP | 多平台 | 本機程式碼知識圖譜，一次呼叫換掉 grep 迴圈 | ✅ 已在用 |
| [codebase-memory-mcp](#codebase-memory-mcp) | MCP | 多平台 | 同上路線的另一套，主打極速索引與 158 語言 | ✅ 已在用 |

---

## 🎨 圖像與設計

### gc-minimal-zine-poster

**平台：Codex**（不是 Claude Code —— 安裝路徑是 `~/.codex/skills/`）
**可呼叫名稱：** `gc-minimal-zine-poster-v0-1`
**來源：** https://github.com/LiamGvchi/gc-minimal-zine-poster ・ MIT ・ 113 ★（2026-08 查看時）

**做什麼**
把一個主題、句子、物件、心情、文章點子、照片或內容簡報，編譯成「安靜的極簡 zine 風編輯海報」的生成 prompt，並直接產出圖。

**它固定往哪個方向壓**（這是這個 skill 的靈魂——它不是通用生圖，而是把風格鎖死）
- 3:5 的**老化紙張**畫布
- **70–90% 留白**
- **只有一個**小的可成像主體或視覺聚落
- 襯線體、打字機體或等寬字
- **一個清楚可見的高彩度色錨**
- xerox／risograph／halftone／凸版印刷／掃描紙張的瑕疵感
- 日韓獨立誌或極簡編輯設計的安靜氛圍

**它刻意避開**
商業廣告版面、光亮的 mockup、電影感打光、3D 算圖、霓虹、密集拼貼式 scrapbook、長段乾淨的文字塊。

**安裝**
```bash
git clone https://github.com/LiamGvchi/gc-minimal-zine-poster.git \
  ~/.codex/skills/gc-minimal-zine-poster-v0-1
```
裝完若沒出現就重啟 Codex。

**用法**
呼叫 skill 名稱並給一個主題或簡報即可，例如「用 $gc-minimal-zine-poster-v0-1 做一張關於雨天舊書店的海報」。也可以餵句子、文章點子、物件、心情或參考圖。

**輸出三件事**
產出的海報圖 ＋ 最終的生圖 prompt ＋ 選用的變體配方與一小段詮釋註記。

> 預設走 Standard Mode 並直接生圖；只有在你明確要求「只要 prompt」時才會停在 prompt 輸出。

**我的狀態：** ⬜ 待試
**試用筆記：**（待填）

---

## 🧠 回應風格與寫碼紀律

> 這兩個都是「**改 agent 的行為**」而不是「給 agent 新能力」。裝上去之後每一輪都會生效，所以要清楚自己想要哪種預設。
>
> 📊 **這兩個我已經跑過對照實測** → [[moc/AI技能評比|AI 技能評比]]（2026-08-05）。結論先講：答案確實變短，但**短在少講了三分之一的概念**；而且 **output tokens 完全沒省到**。

### i-have-adhd

**平台：** Claude Code、Codex（其他 agent 見 repo 的 `INSTALL.md`）
**來源：** https://github.com/ayghri/i-have-adhd ・ MIT ・ 16,688 ★（2026-08-05 查看時）

**做什麼**
一條讓 coding agent **不要把答案埋起來**的規則集。動作先講、多步驟編號、不要「Hope this helps!」。名字雖然叫 ADHD，README 明說**不需要有 ADHD 診斷**也適用。

**十條規則**（全文在 repo 的 `SKILL.md`）
1. 先講下一個動作
2. 多步驟任務要編號
3. 結尾給一個具體的下一步
4. 壓掉離題
5. 每一輪重述目前狀態
6. 時間估算要具體（講分鐘，不要講「一下下」）
7. 讓進展看得見
8. 錯誤就事論事
9. 清單最多 5 項
10. 沒有開場白、沒有回顧、沒有結語

**安裝**
```bash
# Claude Code
claude plugin marketplace add ayghri/i-have-adhd
claude plugin install i-have-adhd@i-have-adhd

# Codex
codex plugin marketplace add ayghri/i-have-adhd --ref main
codex plugin add i-have-adhd@i-have-adhd
```

**出處**
鬆散取材自 J. Russell Ramsay 與 Anthony L. Rostain 的 *The Adult ADHD Tool Kit*，但**改寫成「LLM 該怎麼回應」而不是「人該怎麼安排一天」**。

**我的狀態：** ⬜ 待試（📊 已有實測 → [[moc/AI技能評比|AI 技能評比]]）
**試用筆記：** 實測中概念覆蓋 **−17%**，是三個實驗組裡壓縮最輕的；四組裡最會給「起點與終點」（開場指向權威設計文件、結尾指到行號）。

> ⚠️ 想清楚再裝：它會壓掉推理過程與脈絡說明。對「已經知道自己要什麼」的任務很爽，對「需要一起想清楚」的任務可能反而礙事。

### ponytail

**平台：** Claude Code、Codex、GitHub Copilot CLI、OpenCode、Gemini CLI、Qoder、Pi
**來源：** https://github.com/dietrichgebert/ponytail ・ MIT ・ 95,739 ★（2026-08-05 查看時）

**做什麼**
把「公司裡待最久、看你五十行程式碼一句話不說就換成一行」的那位資深工程師塞進 agent 裡。核心是寫碼前先爬一道**階梯**，停在第一個成立的階：

```
1. 這東西需要存在嗎？        → 不需要：跳過（YAGNI）
2. 這個 codebase 裡已經有了？ → 沿用，不要重寫
3. 標準函式庫做得到？        → 用它
4. 平台原生功能做得到？      → 用它
5. 已安裝的依賴做得到？      → 用它
6. 一行寫得完？              → 一行
7. 到這裡才動手：能動的最小量
```

**關鍵的兩個限定**（很容易被誤讀成「叫 AI 偷懶」）
- 階梯是在**讀懂問題之後**才跑，不是拿來取代理解：README 說它會先讀改動觸及的程式碼、追出真正的流程，再挑要停在哪一階。**對解法懶，對閱讀絕不懶。**
- **懶但不失職**：信任邊界的驗證、資料遺失的處理、資安、無障礙，永遠不在被砍的名單上。

**它自己給的數字**（README 原文，未經我驗證）
在 tiangolo 的 full-stack-fastapi-template 上跑 12 個 feature ticket、Haiku 4.5、n=4：LOC −54%、token −22%、成本 −20%、時間 −27%、安全性維持 100%。README 自己也標明：**−54% 是平均值**，過度設計的情境（date picker）可到 −94%，本來就寫得很精簡的情境則接近 0；而且「YAGNI + 寫一行」的土法 prompt 對照組會掉一個安全防護。

**安裝**（Claude Code 要分**兩則**訊息送）
```
/plugin marketplace add DietrichGebert/ponytail
/plugin install ponytail@ponytail
```
```bash
# Codex
codex plugin marketplace add DietrichGebert/ponytail
codex plugin add ponytail@ponytail
```
需要 `node` 在 PATH 上（Claude Code／Codex 版會跑兩個 Node.js lifecycle hook）；沒有的話 skill 還是能用，只是常駐啟動會安靜地失效。

**用法**
六個指令：`/ponytail`、`/ponytail-review`、`/ponytail-audit`、`/ponytail-debt`、`/ponytail-gain`、`/ponytail-help`；強度分 `lite` / `full` / `ultra` / `off`。

**我的狀態：** ⬜ 待試（📊 已有實測 → [[moc/AI技能評比|AI 技能評比]]）
**試用筆記：** 實測中概念覆蓋 **−31%**，壓縮幅度最大；與 i-have-adhd 同開時**由它主導**（同開 −33%，不是兩者相加的 −48%）。**但 output tokens 沒省到**，別為了省錢開。

> ⚠️ README 自己承認：對「花 thinking token 去反覆推敲階梯」的推理模型，成本可能**反而變高**（它點名 GPT-5.5）。

---

## 🔍 程式碼理解（MCP）

> **這兩個做的是同一件事**：在本機把整個 codebase 建成知識圖譜（symbol、呼叫邊、依賴），讓 agent 一次呼叫就拿到相關原始碼＋呼叫路徑，取代「grep → glob → 一個檔一個檔讀」的迴圈。兩套都主打 100% 本機、程式碼不外流。**同時裝兩套沒有意義，選一套即可。**

### codegraph

**平台：** Claude Code、Cursor、Codex CLI、opencode、Hermes Agent、Gemini CLI、Antigravity IDE、Kiro
**來源：** https://github.com/colbymchenry/codegraph ・ MIT ・ 64,496 ★（2026-08-05 查看時）

**做什麼**
Rust kernel 的程式碼知識圖譜。核心工具 `codegraph_explore` 一次回傳：相關 symbol 的**逐字原始碼**＋它們之間的**呼叫路徑**（含 grep 追不到的 dynamic dispatch）＋改動的 blast radius。

**它自己給的數字**（README 原文，未經我驗證）
7 個開源專案、7 種語言、Claude Opus 4.8 headless、每組 4 次取中位數：工具呼叫 −89%、成本 −60%、token −69%、**七個 repo 的檔案讀取全部歸零**。README 自己標註兩個誠實的但書：小型 repo 有「地板效應」，強模型直接 grep 反而 wall-clock 更快（只是燒 5–10 倍 token）；OkHttp 那組成本幾乎打平。

**安裝**
```bash
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
codegraph install     # 偵測並接上各家 agent（這步才會接上 MCP）
cd your-project && codegraph init   # 每個專案各自建圖
```
`codegraph install` **只接 agent、不建索引**；建索引是各專案的 `codegraph init`。裝好後 auto-sync 預設開啟，檔案一改就更新，不用手動重建。

**我的狀態：** ✅ 已在用（本機 v1.4.1；官方已出 1.5.0，`codegraph upgrade` 可更新）
**試用筆記：** 已寫進全域 `CLAUDE.md` 的使用規則——**只在有 `.codegraph/` 目錄的 repo 才用**，沒有就跳過（要不要建索引是我自己決定，不該由 agent 代跑 init）。

### codebase-memory-mcp

**平台：** 43 個 client surface（自動／條件式偵測）
**來源：** https://github.com/DeusData/codebase-memory-mcp ・ MIT ・ 37,430 ★（2026-08-05 查看時）

**做什麼**
同樣是本機程式碼知識圖譜，路線差異在**廣度與速度**：tree-sitter AST 覆蓋 **158 種語言**（其中 Python／TS／JS／PHP／C#／Go／C／C++／Java／Kotlin／Rust／Perl 另外加 LSP 語意型別解析），單一靜態 binary、零依賴。15 個 MCP 工具，含死碼偵測、跨服務 HTTP 串接、Cypher 查詢、ADR 管理。另外會把 Dockerfile／K8s manifest／Kustomize 也建進圖裡。

**它自己給的數字**（README 原文，未經我驗證）
Linux kernel（28M LOC、75K 檔）3 分鐘建完索引，結構查詢 <1ms；5 個結構查詢約 3,400 token vs 逐檔搜尋約 412,000 token。另附 preprint（arXiv:2603.27277），31 個真實 repo：答案品質 83%、token 少 10×、工具呼叫少 2.1×。

**安裝**
```bash
curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash
# 要 3D 圖譜視覺化（localhost:9749）：加 -s -- --ui
```
重啟 agent 後說「Index this project」即可。

**我的狀態：** ✅ 已在用（快取在 `~/.cache/codebase-memory-mcp/`）
**試用筆記：**
- 它會**跨 client 共用一個 coordination daemon**（Claude Code、Codex、OpenCode…），沒有 opt-in 開關；第一個 session 啟動它、最後一個關掉它。日誌在 `~/.cache/codebase-memory-mcp/logs/`。
- 所有 CBM process **必須版本完全一致**，否則會被 admission barrier 擋下並寫進 `daemon-conflicts.ndjson`。多 client 混用時升級要一次升完。

> ⚠️ README 自己寫明：它**會讀你的 codebase、也會寫你的 agent 設定檔**。這是設計如此，但值得知道。

---

## 🔗 相關
- 📊 自己跑的對照實測報告 → [[moc/AI技能評比|AI 技能評比]]
- 自己在用的 gstack skills（/browse、/review、/ship 等）不收在這頁，那些是工作流不是收藏
- 打造自己的 AI 工具：[[moc/MCP|MCP]]、[[moc/AI工程|AI工程]]
