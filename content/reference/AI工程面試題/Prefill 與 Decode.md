---
type: reference
name: "預填與解碼 Prefill & Decode"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, inference, performance, gpu, latency]
triggers: [為什麼第一個字特別慢後面就快了, GPU算力明明很高卻跑不快, TTFT和TPOT是什麼該看哪個, 一張H100一秒能吐幾個字, 加大batch為什麼會讓使用者變慢]
---

> **對應原題**（Common ‧ Inference, Serving and GPU Performance）
> - Explain the prefill and decode phases. **Why is prefill compute-bound and decode memory-bandwidth-bound?**
>   — *Asked at: Moonshot AI, NVIDIA, Together AI*
> - What are **TTFT, TPOT, ITL and throughput**, and how do they trade against each other? — *Asked at: Microsoft, Apple, Perplexity*
> - **Do the roofline maths**: how many tokens/sec can one H100 produce for a 70B model at batch size 1? — *Asked at: NVIDIA, Together AI*

## 🎯 什麼情境該想到我
當你「**要解釋為什麼 LLM 服務又慢又貴、或要估一張卡能撐多少流量**」的時候。**這是整個 B 區的地基**——連續批次、PagedAttention、推測解碼、PD 分離，全部都是為了解決這一頁揭露的不對稱。

## ⚙️ 怎麼用（機制與算帳）

### 兩個階段，兩種完全不同的機器

| | **Prefill（預填）** | **Decode（解碼）** |
|---|---|---|
| 做什麼 | 一次處理**整個 prompt**，建立 KV cache | 一次產生**一個** token |
| 執行次數 | **1 次** | 輸出長度次 |
| 並行度 | $N$ 個 token 同時算 | **1 個 token** |
| 矩陣運算形狀 | 矩陣 × 矩陣（GEMM） | **矩陣 × 向量**（GEMV） |
| 瓶頸 | **算力（compute-bound）** | **記憶體頻寬（memory-bound）** |
| 對應指標 | **TTFT** | **TPOT / ITL** |

**一次請求 = 一次 prefill + 數百次 decode。** 而且這兩段對硬體的需求**剛好相反**——這是 LLM 服務所有工程難題的根源。

### ★ 為什麼一個 compute-bound、一個 memory-bound

用**算術強度**（每搬 1 byte 做幾次 FLOP）來看。設模型參數量 $D$、bf16（每參數 2 bytes）：

| | 讀取量 | 計算量 | 算術強度 |
|---|---|---|---|
| **Decode（batch=1）** | $2D$ bytes（**整份權重**） | $2D$ FLOPs | **1 FLOP/byte** |
| **Decode（batch=$B$）** | $2D$ bytes（**權重只讀一次！**） | $2DB$ FLOPs | **$B$ FLOP/byte** |
| **Prefill（$N$ tokens）** | $2D$ bytes | $2DN$ FLOPs | **$N$ FLOP/byte** |

**關鍵洞察**：分母（權重讀取量）是固定的 $2D$，**不管你一次算幾個 token**。所以：

> **算術強度 ≈ 一次同時處理的 token 數。**
> prefill 天然有幾百上千個 token → 強度高 → compute-bound。
> decode 只有 batch 個 token → 強度低 → memory-bound。

### 臨界點：硬體的 roofline

$$\text{臨界算術強度} = \frac{\text{峰值算力 (FLOP/s)}}{\text{記憶體頻寬 (byte/s)}}$$

**H100 SXM**（bf16 dense ≈ 989 TFLOP/s、HBM3 ≈ 3.35 TB/s）：

$$\frac{989 \times 10^{12}}{3.35 \times 10^{12}} \approx \mathbf{295\ \text{FLOP/byte}}$$

→ **同時處理的 token 數要超過 ~295，才吃得滿 H100 的算力。**
→ batch 1 的 decode（強度 = 1）只用到 **1/295 ≈ 0.3%** 的算力。**GPU 有 99.7% 的時間在等記憶體。**

*（H100 PCIe 是 HBM2e ~2 TB/s、H200 是 ~4.8 TB/s，臨界點各不同。查你實際的卡。）*

### ★ Roofline 實算：一張 H100、70B、batch 1

**權重讀取**（decode 的真正成本）：
```
70B × 2 bytes = 140 GB   ← 但 H100 只有 80 GB，實際要 2 張卡做 tensor parallel
```

**單卡假想值**（面試常要的乾淨答案，先不管裝不裝得下）：
```
時間 = 140 GB ÷ 3.35 TB/s = 41.8 ms/token
速度 = 1 / 0.0418        ≈ 24 tokens/s
```

**2× H100 tensor parallel**（每卡持 70 GB，同時讀）：
```
時間 = 70 GB ÷ 3.35 TB/s ≈ 20.9 ms/token   →  ≈ 48 tokens/s
```
*（理想值。扣掉 all-reduce 通訊與 kernel 啟動開銷，實測通常落在 30–40 tok/s 區間，要自己量。）*

**對照計算時間**：
```
每 token FLOPs = 2 × 70e9 = 140 GFLOPs
時間 = 140e9 ÷ 989e12 ≈ 0.14 ms
```

> **41.8 ms vs 0.14 ms —— 差 300 倍。**
> 這個數字就是整套推論最佳化的動機：**別再優化計算了，去想辦法少搬權重、或讓一次搬運服務更多請求。**

### Prefill 的 crossover
令兩者相等：$\frac{2DN}{989\text{T}} = \frac{2D}{3.35\text{T}}$ → $N \approx 295$。

→ **prompt 超過約 300 個 token，prefill 就進入 compute-bound。**
→ 而 prefill 的 attention 部分是 $O(N^2)$，所以**長 prompt 的 TTFT 會超線性惡化**。

### 四個指標（別搞混）

| 指標 | 定義 | 使用者感受 | 主要受什麼影響 |
|---|---|---|---|
| **TTFT**<br>Time To First Token | 送出請求 → 收到第一個 token | 「它有沒有在動」 | prefill 時間 + **排隊時間** + prompt 長度 |
| **TPOT**<br>Time Per Output Token | decode 階段每 token 的**平均**時間 | 「吐字速度」 | batch 大小、KV cache 長度、頻寬 |
| **ITL**<br>Inter-Token Latency | **每一步**的間隔（是分布，不是平均） | 「有沒有一卡一卡的」 | 批次排程、有沒有被 prefill 插隊 |
| **Throughput** | 全系統每秒 token 數 | （使用者無感） | batch 大小、GPU 利用率 |

**端到端延遲**：
$$\text{E2E} = \text{TTFT} + \text{TPOT} \times (L_{out} - 1)$$

> **TPOT vs ITL 的差別常被問**：TPOT 是平均值，ITL 是逐步的分布。
> **平均很好但 p99 ITL 很爛**＝使用者看到文字卡頓——平均值會騙人，要看分布。

### ★ 核心取捨：吞吐 vs 延遲

```
batch ↑
  ├─▶ 算術強度 ↑ ──▶ GPU 利用率 ↑ ──▶ throughput ↑ ──▶ 每 token 成本 ↓  😀
  └─▶ 每步要算更多 ──▶ TPOT ↑ ──▶ 單一使用者變慢                      😞
```

**沒有「最佳」batch size，只有「符合你 SLO 的最大 batch」。**

實務做法是定 **goodput**：
> 「p95 TTFT < 500 ms 且 p95 TPOT < 50 ms 的前提下，每秒能服務幾個請求。」

然後**往上推 batch 直到 SLO 快破**。單看 throughput 會得到一個沒人能用的系統；單看 latency 會得到一個燒錢的系統。

### 兩階段互相干擾（這是 chunked prefill 與 PD 分離的動機）

在同一張卡上混跑時：**一個長 prompt 的 prefill 會佔住 GPU 好幾十毫秒，期間所有正在 decode 的請求全部卡住**——這些使用者會看到文字突然停頓。

| 解法 | 做法 | 代價 |
|---|---|---|
| **Chunked prefill** | 把長 prefill 切成小塊，和 decode 交錯執行 | 該請求自己的 TTFT 變差 |
| **PD 分離**（disaggregation） | prefill 和 decode 跑在**不同的 GPU 池**，各自用最適合的硬體與批次策略 | 要把 KV cache 從 P 搬到 D，需高速互連 |

→ 詳見 [[服務棧選型與降本]]

## ⚠️ 注意 / 什麼時候不適用

- **上面的 roofline 是理論上界**。實測通常只到 60–80%：kernel 啟動開銷、記憶體存取不連續、tensor parallel 的 all-reduce、Python 層的開銷都會吃掉。**當估算用，不當承諾用。**
- **decode 的成本不只權重**。還要讀 KV cache——序列越長讀得越多，所以**同一個請求越聊越慢**（見 [[KV Cache]]）。長上下文服務下 KV 的讀取量可能超過權重。
- **MoE 不適用這個簡單公式**。要算的是激活參數，但高 batch 下幾乎所有專家都會被讀到（見 [[混合專家 MoE]]）。
- **量化改變 roofline**。int8 把權重讀取量減半 → decode 直接快 ~2×。**這是量化在 decode 階段收益最大的原因**，而不是因為算得比較快（見 [[量化 Quantization]]）。
- **TTFT 裡有排隊時間**。高負載下排隊可能比 prefill 本身長得多。只優化 prefill kernel 而不看排隊，是常見的走錯方向。
- **別用單請求 benchmark 推估產能**。batch 1 的數字和生產環境毫無關係。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開。**待辦：對實際要用的卡算一次臨界算術強度，存成基準。**

## 🔗 相關
- [[連續批次 Continuous Batching]] —— 把 batch 撐大，直接對抗低算術強度
- [[PagedAttention 與 vLLM]] —— 讓同樣顯存能塞更大的 batch
- [[推測解碼 Speculative Decoding]] —— 在 batch 1 也能提高算術強度
- [[量化 Quantization]] —— 把分母（讀取量）砍半
- [[KV Cache]] —— decode 階段的另一個讀取來源
- [[服務棧選型與降本]] —— chunked prefill、PD 分離、p99 診斷
- [[FlashAttention]] —— 主要優化 prefill 的那一半
