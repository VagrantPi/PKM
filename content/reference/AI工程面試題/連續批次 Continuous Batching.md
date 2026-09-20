---
type: reference
name: "連續批次 Continuous / In-flight Batching"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, inference, serving, throughput, scheduling]
triggers: [為什麼LLM不能用一般的批次推論, GPU利用率上不去, 請求要等前一批做完才開始, 新請求可不可以插進正在跑的批次, 吞吐量怎麼一口氣拉高]
---

> **對應原題**（Common ‧ Inference, Serving and GPU Performance）
> - What is **continuous (in-flight) batching** and **why did it replace static batching**?
>   — *Asked at: Anthropic, xAI, Mistral AI, NVIDIA, Together AI*
>
> 論文：Yu et al., *Orca: A Distributed Serving System for Transformer-Based Generative Models* (OSDI 2022)——提出 iteration-level scheduling。

## 🎯 什麼情境該想到我
當你「**GPU 利用率明明只有 30% 卻已經開始排隊**」的時候。這是 LLM 服務**投報率最高**的單一優化——不用改模型、不損品質，吞吐量可以是倍數級提升。

## ⚙️ 怎麼用（機制）

### 靜態批次為什麼在 LLM 上特別糟

傳統做法：湊滿一批 → 一起算 → 一起回傳 → 收下一批。

這在 CNN 上沒問題，因為**每個輸入的計算量一樣**。但 LLM 的輸出長度**不可預測且方差巨大**——同一批裡可能有人要 10 個 token，有人要 2000 個。

```
靜態批次（batch = 4）

req A |████| 4 步就結束
req B |████████████████████████| 24 步
req C |██████| 6 步
req D |████████| 8 步
      └───────── 整批被 B 綁住 24 步 ─────────┘
       ▲    ▲     ▲
       └────┴─────┴── A/C/D 結束後，它們的 slot 在空轉
```

**有效利用率** = $\frac{4+24+6+8}{4 \times 24} = \frac{42}{96} \approx \mathbf{44\%}$。

而且雪上加霜：
1. **A 的使用者已經拿到完整答案，卻要等 B 才收得到**（回傳也被綁在一起）
2. **新來的 E 必須等整批做完才能進來**，排隊延遲直接 +24 步

**批次開得越大，這兩個問題越嚴重**——但不開大 batch 又吃不滿算力（見 [[Prefill 與 Decode]] 的算術強度）。這是個死結。

### ★ 連續批次：把排程單位從「請求」降到「迭代」

**核心一句話：每一個 forward step 之後重新決定下一步要跑哪些序列。**

```
連續批次

step:  1  2  3  4  5  6  7  8 ...
A      ██ ██ ██ ██ ✓
B      ██ ██ ██ ██ ██ ██ ██ ██ ...
C      ██ ██ ██ ██ ██ ██ ✓
D      ██ ██ ██ ██ ██ ██ ██ ██ ✓
E              ↑ A 一走就補進來
F                        ↑ C 一走就補進來
```

- 某個序列吐出 EOS → **立刻移出批次、立刻回傳給使用者**
- 有空位 → **立刻從等待佇列拉一個新請求進來**
- **批次的組成每一步都在變**，所以叫 continuous / in-flight

**GPU 幾乎永遠滿載。**

### 實作上的難點

#### 1. Attention 不能像 linear 層那樣直接 batch
批次裡每個序列的 KV cache 長度都不同（有的 100 有的 5000），沒辦法堆成一個整齊的張量。

Orca 的解法是 **selective batching**：
- **Linear / LayerNorm / FFN** —— 與序列長度無關，把所有 token 攤平成 `(total_tokens, d)` 一起算 ✅
- **Attention** —— 拆開，每個序列各自對自己的 KV cache 做 ❌

現代實作（FlashAttention 的 varlen kernel、PagedAttention 的 kernel）已經能在一個 kernel 內處理不等長序列，效率更好。

#### 2. 顯存必須能動態分配
要「隨時加入新請求」，就得隨時能配 KV cache 空間。傳統的「依 `max_seq_len` 預留連續空間」做法下，**顯存早就被預留光了，根本沒空位**。

> ★ **這是為什麼連續批次和 [[PagedAttention 與 vLLM]] 必須一起看**：
> 連續批次提供**排程機制**，PagedAttention 提供**顯存機制**。
> 只有前者沒有後者，你能插隊的空間非常有限。

#### 3. 排程策略要選
vLLM 維護三個佇列：

| 佇列 | 狀態 |
|---|---|
| `waiting` | 還沒開始（尚未 prefill） |
| `running` | 正在 decode |
| `swapped` / `preempted` | 被踢出去的（顯存不夠時） |

每步要決定：**優先拉新請求進來做 prefill（好 TTFT），還是優先讓現有的繼續 decode（好 TPOT）？**

- **prefill 優先** → 新使用者很快看到第一個字，但現有使用者卡頓
- **decode 優先** → 現有使用者順暢，新使用者等更久

沒有標準答案，取決於你的 SLO。多數框架給的是可調旋鈕（vLLM 的 `--scheduling-policy`、TensorRT-LLM 的 scheduler policy）。

#### 4. 顯存不夠時要搶佔（preemption）
所有 slot 都滿、KV cache 又在成長時，要踢掉某個序列：

| 策略 | 做法 | 代價 |
|---|---|---|
| **Swap** | KV cache 搬到 CPU 記憶體，之後搬回 | PCIe 頻寬，慢 |
| **Recompute** | 直接丟掉，之後重跑 prefill | 重算的算力 |

短序列通常 recompute 划算（prefill 很快），長序列 swap 划算。

### 效果

| 來源 | 回報 |
|---|---|
| Orca 論文 vs FasterTransformer | 同延遲下吞吐 **~36.9×** |
| Anyscale 實測 vLLM vs 靜態批次 | 吞吐最高 **~23×** |

> ⚠️ **都是特定模型、特定負載分布下的數字。** 你的增益取決於**輸出長度的變異程度**——變異越大，靜態批次浪費越多，連續批次贏越多。**輸出長度固定的任務（如分類）幾乎沒有增益。**

## ⚠️ 注意 / 什麼時候不適用

- **TPOT 會變得不穩定**。批次組成一直變，每步的計算量就一直變 → **ITL 有抖動**。平均 TPOT 漂亮不代表使用者體感順（見 [[Prefill 與 Decode]] 的 TPOT vs ITL）。
- **新請求的 prefill 會插隊卡住 decode**。這是連續批次引入的新問題，解法是 **chunked prefill**（見 [[服務棧選型與降本]]）。
- **必須有 admission control**。連續批次讓你「總是能再塞一個」，結果是**過載時所有人都慢**而不是部分人被拒絕。要設 `max_num_seqs`、`max_num_batched_tokens` 上限。
- **搶佔會造成長尾**。被 preempt 又 recompute 的請求，延遲可能是正常請求的數倍。**p99 的元兇常常是它**。
- **不要自己實作**。vLLM、TensorRT-LLM、SGLang、TGI 都內建。自己寫排程器是造輪子，而且很難寫對。
- **輸出長度同質的場景增益有限**。批次分類、embedding 服務不需要這套。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開，尚未實際套用。

## 🔗 相關
- [[Prefill 與 Decode]] —— 為什麼需要大 batch（算術強度）
- [[PagedAttention 與 vLLM]] —— 讓連續批次真正可行的顯存機制
- [[服務棧選型與降本]] —— chunked prefill、排程參數怎麼調
- [[KV Cache]] —— 被搶佔時搬來搬去的就是它
