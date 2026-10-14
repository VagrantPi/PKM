---
type: article
title: "讓 AI 讀懂你的系統：Knowledge Graph × Agent-First 實戰（Graphify 工作坊）"
source_url: https://share.neohsu.dev/graphify-workshop
author: Neo Hsu
site: share.neohsu.dev
tags: [ai, llm, agent, knowledge-graph, context-engineering, codebase]
captured: 2026-10-14
read_status: read
---

## 📌 30 秒摘要
> 一場 35 頁投影片的工作坊，用開源工具 **Graphify** 示範：把 repo、文件、需求先建成一張**可查詢的知識圖譜**，讓 agent 沿著關係找 context，而不是每次 grep 一堆孤立片段。
>
> 三個帶走重點：
> 1. **會建圖、查圖**：`query`、`path`、`explain`。
> 2. **會判斷可信度**：每條邊標 `EXTRACTED`／`INFERRED`／`AMBIGUOUS`。
> 3. **知道要補哪些文件**，讓團隊的圖更準。
>
> 結論是「圖不是答案機，而是 context 地圖」。圖連不起來時，通常是在提醒有些關係本來就沒寫成文件。

## 🔍 查證與評比
> **可信度 21/30**｜查證 2026-10-14｜✅ 6　⚠️ 1　❌ 0｜判定：門檻邊界，使用者決定完整收
> 來源是講者個人站上的投影片。工具相關的斷言我逐條對過 Graphify 的 README、ARCHITECTURE.md 與 CHANGELOG。

| 原文斷言 | 查證 | 依據 |
|---|---|---|
| 程式碼用 AST 抽「硬關係」、文件用 LLM 抽「軟關係」 | ✅ | README：程式碼用 tree-sitter，不呼叫 LLM、不出本機；文件、PDF、圖片走模型做語意抽取 |
| 每條邊標 EXTRACTED／INFERRED／AMBIGUOUS | ✅ | ARCHITECTURE.md 的 Confidence labels 表（README 只寫前兩種） |
| 產出 graph.html／graph.json／GRAPH_REPORT.md，加上 manifest.json 給 `--update` 判斷改過的檔 | ✅ | README 列出三個產出檔；manifest.json 見 CHANGELOG（`graphify update` 寫 manifest） |
| `--mode deep`、`--max-concurrency` | ✅ | CHANGELOG：`extract --mode deep` 做較豐富的語意抽取；`--max-concurrency` 與 `--max-workers` 一起加入 |
| `.graphifyignore` 降噪、`--update` 增量、`--cluster-only` 只重新分群 | ✅ | README |
| 社群分群、god nodes、意外連結 | ✅ | README：Leiden 分群；報告列 god nodes 與 surprising connections |
| Karpathy 說「讓 LLM 預先建立並持續維護一個結構化的**知識圖譜**」 | ⚠️ | 意譯且有偏差。〈LLM Wiki〉原文講的是互相連結的 markdown **wiki**，不是圖；精神相同，但不能當原話引用 → [[LLM Wiki（Karpathy）]] |

六維評分：
- A 正確性：4
- B 深度：2，投影片形式，機制只點到為止
- C 可操作：4
- D 相關性：4
- E 原創：3，PM／QA／FAE 的使用情境、bridge doc、agent-first 的 graph repo 是講者自己的整理
- F 非重複：4，庫裡有只看程式碼的 codegraph，但沒有「文件與需求一起進圖」的做法

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- agent 在大 repo 或跨 repo 上答不出跨檔案問題時，拿這套「先建圖、再依可信度使用」的流程。
- PM、QA、RD 要一起確認「需求有沒有對應到程式碼」時，可以當協作工具。
- 跟庫裡的 LLM Wiki 想法一致，都是先把知識結構化，查詢時不必重撈原始檔。差別在這篇的對象是 codebase。

## 🧰 這篇給我的工具（連到 tools/）
- [[工具-用知識圖譜幫agent找對context]] —— agent 讀過整個 repo 卻答不出跨檔案問題、找錯 context 時

## ✨ 關鍵重點

### 問題：agent 最容易壞在「找 context」
agent 的流程是理解目標 → 找 context → 推理 → 修改或回答 → 驗證。**最容易壞的是找 context**，找錯了後面的推理全建立在錯的前提上。「Agent 讀過文件，不代表可以關聯得起來」。PM 會發現文件都丟進去了還是答錯，RD 會發現搜尋只撈回孤立片段。

### grep 找「字」，圖找「關係」
- grep：快、準、可預期，適合 function name、error code、config key；但只知道字在哪，分不出哪個是核心，也看不到關聯。
- 圖：關心實體與關係（A 呼叫 B、文件描述 module、測試覆蓋路徑），能跨檔案找最短路徑。
- 例子：要改登入流程，`grep login` 會撈到 UI 按鈕文字、測試 fixture、README、舊的 migration 說明，真正核心的 auth service 混在裡面；圖則能從 login command 一路追到 handler、service、config、test。

### Graphify 怎麼建圖
1. **結構抽取**：程式碼做 AST 解析，抓 import、call、reference。
2. **語意抽取**：文件、spec、issue、圖片抽出概念與關係。
3. **社群分群**：把相關節點自動分群，浮現 god nodes（被很多東西依賴的核心）與**跨社群的意外連結**，也就是你原本不會想到去問的關聯。
4. **稽核軌跡**：每條邊標可信度。

### 怎麼信這張圖
| 等級 | 意思 | 怎麼用 |
|---|---|---|
| EXTRACTED | 原始資料明確寫的 | 可高度參考，仍回原始碼驗證 |
| INFERRED | 工具依語意或結構推論 | 當探索線索 |
| AMBIGUOUS | 不確定 | 一定要人確認 |

- **程式碼關係較「硬」**，可驗證；但動態派發、runtime 設定、feature flag、外部服務呼叫，AST 看不到。
- **文件關係較「軟」**，適合縮小範圍，不適合當最終判決。
- 「graphify 幫你縮小探索範圍，不取代 source of truth」。

### 讓圖變準的三件事
- **降噪**：測試 fixture、產生的程式碼、migration、locales、vendor、大型 csv／parquet 用 `.graphifyignore` 排除。圖不是越密越好，太密代表雜訊把重要關係淹掉了。
- **多 repo 補 bridge doc**：`architecture.md`（各服務職責、誰呼叫誰）、`data-flow.md`（一筆資料怎麼穿過各服務）、`ubiquitous-language.md`（同一概念在各 repo 的命名對照）。各 repo 各自建圖，再用這層文件接起來，「孤島變大陸」。
- **從小開始**：第一版只選一個產品功能、一個主要 repo、對應的 spec／PRD／Jira／Confluence，加少量架構文件。「目標不是建最大的 graph，而是建一張會被用的 graph」。

### 兩個練習任務
- **PM 視角**：需求文件能不能連到實作？哪些是 EXTRACTED、哪些只是 INFERRED？「找不到明確關聯 ≠ 一定沒實作」，那是要 PM 和 RD 一起確認的落差候選。
- **RD 視角**：改 auth flow 前先做影響分析：entry point、相關 service、config、test；不只列檔案，要說明「為什麼相關」並標出信心高低。

### Agent-first：把 agent 當第一個使用者
講者建議做一個專門的 graph repo：
- `AGENTS.md`：規定任何任務都先用 graphify。
- `repos.lock.json`：鎖住各 repo 的 commit。
- `mise.toml`／`uv.lock`：固定工具版本。
- `.graphifyignore`：降噪。
- `Makefile`：負責 clone、build、安裝 skill。
- `repos/`：要建圖的 repo。
- `docs/`：bridge doc。
- `skills/graphify/`：專案用的 skill 定義。

同一份結構可以給 Claude、Copilot、Cursor、Codex 共用。

## 💬 原文摘錄
- 「找錯 context，後續推理就可能建立在錯誤的前提上。」
- 「多 repo 最大的問題通常不是不會 merge，而是 repo 之間本來就缺一層描述關係的 doc。」
- 「Graph 不準通常不是失敗，而是在提醒：有些關係本來就沒被文件化。」
- 「你只要提供足夠的工具和文件給 Agent 就可以自行運作，方向由工具驗證就好了，不需要靠語意去控制 Agent 走向。」（講者自己的話）

## 🔗 相關
- [[moc/AI技能收藏#graphify|Graphify 工具卡]] —— 安裝、指令、注意事項
- [[LLM Wiki（Karpathy）]] —— 同一個「先建好結構，查詢時不重撈原始檔」的想法，對象是個人知識
- [[工具-通用語言]] —— bridge doc 裡的 ubiquitous-language.md 就是 DDD 的通用語言
