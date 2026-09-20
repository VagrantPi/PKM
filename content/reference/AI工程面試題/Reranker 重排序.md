---
type: reference
name: "重排序器 Reranker / Cross-Encoder"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, rag, retrieval, reranking, latency]
triggers: [檢索有撈到但排序很爛, cross-encoder為什麼不能拿來做檢索, 該送幾個候選去重排, 上下文只能放5段要挑哪5段, reranker會讓延遲增加多少]
---

> **對應原題**（Common ‧ RAG and Retrieval）
> - What is a reranker, **when should you use one**, and **what does a cross-encoder cost you**?
>   — *Asked at: Cohere, Microsoft, Perplexity*

## 🎯 什麼情境該想到我
當你「**檢查檢索結果，發現正確答案明明在第 23 名，但你只餵前 5 名給模型**」的時候。這是 RAG 投報率極高的一步——**通常比換 embedding 模型、比調 chunk size 有效得多。**

## ⚙️ 怎麼用

### ★ 核心差別：Bi-Encoder vs Cross-Encoder

```
Bi-Encoder（檢索用）                Cross-Encoder（重排用）
┌──────┐      ┌──────┐            ┌─────────────────────────┐
│ query│      │ doc  │            │  [CLS] query [SEP] doc   │
└──┬───┘      └──┬───┘            └───────────┬─────────────┘
   ▼             ▼                             ▼
 Encoder      Encoder                       Encoder
   ▼             ▼                             ▼
   q ────dot──── d                       單一相關性分數
                                    ★ query 與 doc 的每個 token
★ 兩邊從未互相「看到」                    在每一層互相 attend
★ doc 可離線算好                       ★ 完全無法預先計算
```

**這一個差別決定了一切**：

| | Bi-Encoder | Cross-Encoder |
|---|---|---|
| query 與 doc 有互動嗎 | **沒有**（只有最後一次內積） | **有**，逐 token、逐層 |
| 文件可否離線編碼 | ✅ | ❌ |
| 查詢時成本 | 1 次 encode + ANN | **N 次完整 forward** |
| 百萬文件可行嗎 | ✅ | ❌ **完全不可能** |
| 精準度 | 中 | **高** |

> **面試一句話**：**「Bi-encoder 用可預先計算換取規模，cross-encoder 用不可預先計算換取精準度。所以它們不是競爭關係，是管線的兩段。」**

### 標準三段式管線

```
1M 文件
  │  ① 檢索（bi-encoder + BM25，RRF 融合）   ~10 ms
  ▼
top-50 候選
  │  ② 重排（cross-encoder，50 次 forward）  ~30–100 ms
  ▼
top-5
  │  ③ 生成
  ▼
答案
```

**第一段要的是 recall（別漏），第二段要的是 precision（排對）。** 兩段的目標不同，所以用不同的模型是合理的。

### ★ 成本到底多少（題目明確問的部分）

**計算量**：$N$ 個候選各要一次 forward，輸入長度 ≈ query + chunk。

以 50 個候選、每個 512 token 為例：**總共 ~25,600 token 的 prefill**。
在一個 100M–500M 參數的 reranker 上，**單張 GPU 約 20–100 ms**（依模型大小、批次、硬體，要自己量）。

**三筆代價**：
1. **延遲** —— 直接加在 **TTFT** 上（見 [[Prefill 與 Decode]]）。使用者等第一個字的時間變長
2. **金錢** —— 自架要多一組 GPU；用 API（Cohere Rerank 等）按次計費
3. **架構複雜度** —— 多一個要監控、要版本管理、會掛掉的服務

**可調的旋鈕**：候選數 $k$。成本**與 $k$ 線性成長**，所以 $k$ 是延遲與品質的直接交換。

### ★ 什麼時候該用（判準要量化）

**量兩個數字**：

| 指標 | 意義 |
|---|---|
| **recall@50** | 正確答案有沒有被撈進候選池 |
| **recall@5**（或 nDCG@5） | 正確答案有沒有排進最終送給模型的那幾段 |

| 診斷 | 意思 | 該做什麼 |
|---|---|---|
| **recall@50 高、recall@5 低** | **撈得到但排不好** | ✅ **這正是 reranker 的場景** |
| recall@50 也低 | **根本沒撈到** | ❌ reranker 救不了。先修切塊／embedding／查詢改寫 |
| 兩個都高 | 已經夠好 | 不用加，省延遲 |

> ★ **「reranker 只能重排已經撈到的東西」** —— 這句話是這題的標準扣分點。沒撈到的文件，reranker 永遠看不到。

**其他該用的理由**：
- **上下文預算有限** —— 只能放 5 段時，「哪 5 段」的價值極高
- **對抗 lost-in-the-middle** —— 少而精，勝過多而雜（見 [[位置編碼與 RoPE]]）
- **統一 hybrid 的排序** —— RRF 只用排名，reranker 給出真正可比的相關性分數
- **省生成成本** —— 從 20 段降到 5 段，input token 直接砍 75%

### 中間路線：ColBERT / Late Interaction

不是一個向量，而是**每個 token 一個向量**；相似度用 **MaxSim**：

$$\text{score}(q, d) = \sum_{i \in q} \max_{j \in d} \left(E_{q_i} \cdot E_{d_j}\right)$$

**每個查詢 token 去找文件中最匹配的那個 token，再加總。**

| | 精準度 | 可預先計算 | 索引體積 |
|---|---|---|---|
| Bi-encoder | 中 | ✅ | 小 |
| **ColBERT** | **中高** | **✅（文件端可預算）** | **大（每 token 一個向量）** |
| Cross-encoder | 高 | ❌ | — |

**它把互動延後到最後一步**，所以文件端仍可離線算好——用索引體積換精準度。

### 還有一條：LLM-as-Reranker
直接叫 LLM 排序（RankGPT 那類 listwise 作法：「把這 20 段依相關性排序」）。

- ✅ **零訓練**、能處理複雜或多條件的相關性判準
- ❌ **慢、貴**、受順序偏誤影響（見 **LLM-as-Judge**，批次 3 補）
- **listwise 的優勢**：模型能同時看到所有候選互相比較，而不是逐一打分

## ⚠️ 注意 / 什麼時候不適用

- **★ 注意 reranker 的最大長度**。多數 cross-encoder 上限 512 token。**超過就被截斷，而且是靜默的**——你的 1000 token chunk 只有前半被評分。要嘛縮小 chunk，要嘛選長上下文的 reranker。
- **分數不可跨查詢比較**。cross-encoder 的分數是相對於「這個 query」的，**拿它當全域閾值（「> 0.8 才算相關」）會失準**。要設閾值就得自己校準。
- **領域不匹配時可能比不 rerank 更差**。通用 reranker 在高度專業的語料（法律、醫療、內部術語）上可能排錯。**上線前一定要 A/B。**
- **多語言要挑對模型**。英文 reranker 處理中文常會退化。
- **$k$ 要用 recall@k 曲線的拐點決定**，不是拍 50。畫出 recall@k 對 k 的曲線，找邊際效益開始平的地方。
- **它是單點故障**。reranker 服務掛掉時要能降級成「直接用檢索排序」，而不是整個 RAG 掛掉。
- **別用它掩蓋上游的問題**。切塊爛、解析爛的情況下加 reranker 是在排序垃圾。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開。**待辦：做 RAG 時先量 recall@50 與 recall@5 的落差，再決定要不要加。**

## 🔗 相關
- [[稀疏與密集檢索]] —— 上游，提供候選池
- [[切塊與文件解析]] —— chunk 大小要配合 reranker 的長度上限
- [[向量索引 ANN]] —— 第一段的召回怎麼做快
- [[位置編碼與 RoPE]] —— lost-in-the-middle，少而精的理由
- [[RAG 評估與營運]] —— recall@k / nDCG 怎麼量
- [[Prefill 與 Decode]] —— 重排的延遲加在 TTFT 上
