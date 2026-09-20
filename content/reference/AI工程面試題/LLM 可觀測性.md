---
type: reference
name: "LLM 可觀測性 Observability: Traces, Spans, Costs, Feedback"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, observability, monitoring, tracing, cost, operations]
triggers: [LLM系統該記哪些遙測, 一個請求跨好幾個步驟怎麼追, 成本要怎麼歸因到功能, 出事了要怎麼重現, 告警該設在哪些指標]
---

> **對應原題**（Common ‧ Evaluation and Observability）
> - What **observability** does a production LLM system need: **traces, spans, costs, feedback**?

## 🎯 什麼情境該想到我
當你「**線上出了問題，卻只有一句「模型回答不好」可以查**」的時候。
★ **這題的關鍵是講出「LLM 系統的可觀測性和傳統服務有什麼結構性差異」**，而不是背誦三大支柱。

## ⚙️ 怎麼用

### ★ 五個結構性差異

| # | 差異 | 後果 |
|---|---|---|
| **1** | **一次請求是一棵樹，不是一條線** | 檢索 → rerank → LLM → 工具 → LLM → 護欄。**沒有 trace 就完全看不到內部** |
| **2** | **「成功」是軟的** | HTTP 200 + 低延遲 **完全不代表答案是對的**。傳統的 RED/USE 指標抓不到品質 |
| **3** | **★ 輸入輸出是非結構化自然語言** | 無法用傳統的 metric 聚合。需要**額外的評估層**把它變成數字 |
| **4** | **成本是每請求可變的** | token 數差 100 倍很正常。**成本必須被當成一等公民遙測** |
| **5** | **★ 不可重現** | 同樣輸入不保證同樣輸出（見 [[取樣與解碼策略]]）→ **必須存下完整輸入才能重放** |

### 四根支柱（傳統三根 + LLM 特有的第四根）

```
Traces / Spans   ← 結構：這次請求內部發生了什麼
Metrics          ← 量  ：延遲、成本、錯誤率的聚合
Logs             ← 內容：完整的輸入輸出
★ Evaluations    ← 品質：groundedness、裁判分數、使用者回饋
   / Feedback       這一根是 LLM 系統獨有的
```

### Trace / Span 設計

```
root span: user_interaction                         總延遲、總成本、版本
├── span: guardrail.input                           觸發了哪些規則
├── span: retrieve                                  query、top_k、doc_ids、分數、快取命中
│   └── span: rerank                                候選數、耗時
├── span: llm_call #1                               ← 見下方屬性
│   └── span: tool_call.search_docs                 名稱、參數、回傳大小、重試次數
├── span: llm_call #2
└── span: guardrail.output                          是否改寫/攔截
```

**`llm_call` span 至少要記的屬性**：

| 屬性 | 為什麼 |
|---|---|
| `model` + 版本 | 模型換了要能立刻看出來 |
| **`prompt_version` / `prompt_hash`** | ★ 沒這欄就無法歸因（見 [[上線閘門與線上評估]]） |
| `temperature` / `top_p` / `max_tokens` | 參數飄移是常見事故源 |
| `input_tokens` / `output_tokens` | 成本 |
| **`cache_read_tokens` / `cache_creation_tokens`** | ★ **快取命中率是降本與 p99 診斷的關鍵訊號**（見 [[前綴快取 Prompt Caching]]） |
| `ttft` / `total_latency` | 效能分解（見 [[Prefill 與 Decode]]） |
| **`finish_reason`** | ★ `max_tokens` 代表被截斷——這是一種**靜默的品質事故** |
| `tool_calls` 數量 | agent 行為 |

> **OpenTelemetry 的 GenAI semantic conventions** 是目前的標準化方向，值得對齊——但它**仍在演進**，各家 SDK 的欄位名不完全一致，不要假設可攜。

### 指標分類

| 類別 | 指標 |
|---|---|
| **效能** | TTFT / TPOT / ITL 的 p50·p95·p99、排隊時間、端到端延遲 |
| **★ 成本** | 每請求 / 每使用者 / **每功能** / 每版本 的成本；**快取命中率**；output/input token 比 |
| **可靠性** | 錯誤率（依類型分）、工具失敗率、重試率、`finish_reason=max_tokens` 比例、（自架）preemption 率 |
| **品質**（抽樣算） | groundedness、contradiction 率、拒答率、護欄觸發率、裁判分數 |
| **業務** | 任務完成率、追問率、複製率、負回饋率 |

### ★ 成本歸因：沒有歸因就無法降本

```
總成本
 ├── 依功能：摘要 38% / 問答 31% / 建議 22% / 其他 9%
 ├── 依階段：檢索 2% / 主要生成 71% / 護欄 12% / 重排 15%
 ├── 依版本：v3 比 v2 每請求貴 40%   ← ★ 這個數字能擋下一次糟糕的上線
 └── 依使用者：前 1% 的使用者吃掉 34% 的成本
```

> [[服務棧選型與降本]] 的槓桿排序，**沒有這張表就是憑感覺猜**。
> 「每功能成本」尤其值得做——它常常會揭露一個沒人在用卻很貴的功能。

### 告警該設在哪

| ❌ 不要對這些告警 | ✅ 對這些告警 |
|---|---|
| 平均品質分數（雜訊太大、滯後） | **安全事件、PII 洩漏偵測**（單筆就告警） |
| 單一回答的裁判分數 | **contradiction 率突增**（硬錯誤） |
| | **★ 快取命中率斷崖**（通常代表有人改了 prompt 前綴） |
| | **成本尖峰 / 每請求 token 數突增** |
| | **p95 TTFT / p99 ITL 超過 SLO** |
| | **工具失敗率、重試率突增** |
| | **`finish_reason=max_tokens` 比例突增**（回答被截斷） |
| | **拒答率大幅變動**（兩個方向都要告警） |

### ★ 可重放性：LLM 除錯的必要條件

> **要能回答「當時到底發生了什麼」，就必須能把那一次請求原封不動地重跑。**

所以要完整存下：
```
完整 prompt（含 system、工具 schema、檢索到的文件全文或 doc_id+版本）
+ 模型與參數
+ 工具的回傳值
```
**只存「使用者問了什麼」是不夠的** —— 檢索結果、記憶注入、工具回傳都會影響輸出，而它們每次都不同。

## ⚠️ 注意 / 什麼時候不適用

- **★ Trace 是 PII 的匯聚點**。完整輸入輸出含使用者資料、檢索到的內部文件。**存取控制、保留期限、欄位遮罩都要設計**（見 [[PII、紅隊與公平性稽核]]）。
- **多租戶的 trace 要隔離**。工程師能不能看客戶內容，是合約與法遵問題。
- **全量存完整內容很貴**。全量存 metadata + 抽樣存內容（見 [[上線閘門與線上評估]] 的抽樣策略）。
- **品質指標要抽樣算**，全量跑 NLI/裁判的成本可能超過主要生成本身。
- **遙測本身會增加延遲**。span 的建立與匯出要非同步，不要阻塞回應。
- **不要只在出事後才加遙測**。缺欄位的歷史資料補不回來——**上線前就要把 prompt_version 與 cache token 記進去**。
- **告警要有 runbook**。沒有處置步驟的告警最後會被靜音。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開。**待辦：確認現有系統有沒有記 prompt_version、cache_read_tokens、finish_reason 三欄。**

## 🔗 相關
- [[上線閘門與線上評估]] —— log / 抽樣 / A/B 的完整設計
- [[服務棧選型與降本]] —— 成本歸因的用途，以及 p99 七步診斷
- [[前綴快取 Prompt Caching]] —— 快取命中率為什麼是關鍵訊號
- [[幻覺偵測]] —— 品質指標的來源
- [[Agent 評估]] —— agent 的 trace 是樹狀的，更難讀
- [[可逆性、審計與人類把關]] —— 審計日誌與遙測的異同
- [[工具-遙測與監控]] —— 通用的遙測紀律
