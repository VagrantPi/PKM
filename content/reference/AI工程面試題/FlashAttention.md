---
type: reference
name: "FlashAttention"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, attention, gpu, performance, optimization]
triggers: [FLOPs沒變為什麼會變快, attention爆記憶體怎麼辦, GPU的SRAM和HBM差在哪, softmax要看全列怎麼分塊算, 長上下文的平方記憶體怎麼消掉]
---

> **對應原題**（Common ‧ LLM Internals）
> - Explain FlashAttention. **It does not reduce FLOPs, so why is it faster?** — *Asked at: Together AI*
>
> 論文：Dao et al., *FlashAttention: Fast and Memory-Efficient Exact Attention with IO-Awareness* (NeurIPS 2022)；
> FlashAttention-2 (2023)；FlashAttention-3 (2024, Hopper)。

## 🎯 什麼情境該想到我
當你「**想不通為什麼一個不減計算量的算法能快好幾倍**」的時候。這題的答案是整個 GPU 效能思維的縮影：**現代 GPU 的瓶頸幾乎不是算力，是搬資料。**

## ⚙️ 怎麼用（機制）

### 前提：GPU 的記憶體階層

| 層級 | A100 容量 | 頻寬 | 角色 |
|---|---|---|---|
| **SRAM**（on-chip，每個 SM） | 192 KB × 108 SM ≈ **20 MB** | **~19 TB/s** | 快，但塞不下東西 |
| **HBM**（顯存） | 40–80 GB | 1.5–2.0 TB/s | 大，但慢 **10 倍** |

*（數字取自 FlashAttention 原論文對 A100 的描述；不同卡不同，H100/B200 要另查。）*

### 標準 attention 在幹嘛（IO 的角度）

```
S = QKᵀ / √d     → 把 N×N 的 S 寫回 HBM
P = softmax(S)   → 從 HBM 讀 S、算、把 N×N 的 P 寫回 HBM
O = PV           → 從 HBM 讀 P、算、寫回 O
```

**兩個 $N \times N$ 矩陣被完整具體化（materialize）並來回搬過 HBM。** $N = 8192$ 時，一個 fp16 的 $N^2$ 矩陣就是 128 MB——而且每層每頭都來一次。

### ★ 為什麼「不減 FLOPs 卻更快」：算術強度

**算術強度（arithmetic intensity）= 每搬 1 byte 做幾次浮點運算。**

A100 的 fp16 算力約 312 TFLOP/s、HBM 頻寬約 2 TB/s → **臨界算術強度約 156 FLOP/byte**。低於這個值，你就是 memory-bound：**算力閒置，全部時間在等資料。**

標準 attention 裡的 softmax 與 mask 都是 elementwise 操作，算術強度接近 1——**遠遠 memory-bound**。所以：

> **減 FLOPs 沒用，因為 FLOPs 本來就不是瓶頸。FlashAttention 減的是 HBM 存取次數。**

IO 複雜度上，標準版是 $\Theta(N^2 + Nd)$ 次 HBM 存取，FlashAttention 是 $\Theta(N^2d^2/M)$（$M$ 為 SRAM 大小）。典型設定下 $d^2/M \ll 1$，所以是**數量級的減少**。

### 三招

#### 1. Tiling（分塊）
把 Q、K、V 切成能塞進 SRAM 的小塊。對每個 Q 塊，依序載入 K/V 塊，**在 SRAM 內算完 $S$、softmax、乘 $V$，只把最後的 $O$ 寫回 HBM**。$N \times N$ 矩陣從頭到尾沒有在 HBM 出現過。

#### 2. Online Softmax（讓 softmax 可以分塊）

這是整件事的數學關鍵。softmax 要先知道**整列的最大值與總和**才能正規化，看起來無法分塊。解法是**邊走邊修正**：

維護每列的 running max $m$、running sum $\ell$、未正規化輸出 $O$。處理第 $j$ 塊時：

$$
\begin{aligned}
m^{(j)} &= \max\left(m^{(j-1)},\ \text{rowmax}(S^{(j)})\right) \\
P^{(j)} &= \exp\left(S^{(j)} - m^{(j)}\right) \\
\ell^{(j)} &= e^{m^{(j-1)} - m^{(j)}}\,\ell^{(j-1)} + \text{rowsum}\left(P^{(j)}\right) \\
O^{(j)} &= \operatorname{diag}\!\left(e^{m^{(j-1)} - m^{(j)}}\right) O^{(j-1)} + P^{(j)}V^{(j)}
\end{aligned}
$$

最後才除一次：$O = \operatorname{diag}(\ell^{(\text{last})})^{-1} O^{(\text{last})}$。

**直覺**：每遇到更大的 max，就用 $e^{m_{old} - m_{new}}$ 把先前累積的結果「降權」——等價於一開始就用新的 max 算。

> ★ 所以 **FlashAttention 是精確（exact）的，不是近似**。這點面試常被追問：它和稀疏注意力、線性注意力完全不同陣營——後者改變了數學，它沒有。

#### 3. Recomputation（反向傳播）
訓練時反向傳播需要 $P$。FlashAttention **不存 $P$**，只存 $O$ 和 softmax 的統計量 $(m, \ell)$，反向時**在 SRAM 裡重算**。多花 FLOPs、少搬一堆資料——再次用算力換頻寬，而且淨賺。

### 效果

| | 記憶體 | 論文回報的加速 |
|---|---|---|
| **FlashAttention** | $O(N^2) \to O(N)$ | GPT-2 訓練 ~3×；BERT-large 端到端 ~15% |
| **FlashAttention-2** | 同上 | 約 FA1 的 2×；A100 上達理論峰值 FLOP/s 的 50–73% |
| **FlashAttention-3** | 同上 | H100 上約 FA2 的 1.5–2.0×；FP8 可再往上 |

*（皆為論文自報數字、特定硬體與設定；當作量級參考，不要當成你的 workload 的承諾。）*

FA2 主要改的是**工作分割**——減少非 matmul 運算（Tensor Core 對 matmul 快得多）、把平行度加到序列維度、改善 warp 之間的分工。FA3 則吃 Hopper 的新特性（TMA、warp specialization、FP8）。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開，尚未實際套用。

## ⚠️ 注意 / 什麼時候不適用

- **時間複雜度仍是 $O(N^2)$**。省的是記憶體與 IO，不是漸進計算量。長上下文最終還是會被 $N^2$ 吃掉。
- **decode 階段幫助有限**。decode 每步的 query 只有 1 個 token，$N \times N$ 矩陣根本不存在；那裡的瓶頸是讀 KV cache（見 [[Prefill 與 Decode]]）。**FlashAttention 主要贏在 prefill 與訓練。** 針對 decode 的變體是 FlashDecoding。
- **硬體綁定**。FA2 要 Ampere 以上，FA3 專為 Hopper 寫。你的卡不對就退回較慢的後端——而且是**靜默退回**，要主動確認實際用到哪個 kernel。
- **不要自己裝**。`torch.nn.functional.scaled_dot_product_attention` 會自動選後端；vLLM/TensorRT-LLM 也都內建。自己 build FA 常在 CUDA 版本上卡住。
- **head_dim 有限制**。早期版本只支援到 128，超過就不走 Flash 路徑。

## 🔗 相關
- [[注意力機制]] —— 它加速的那個公式
- [[KV Cache]] —— decode 階段真正的瓶頸在那裡
- [[Prefill 與 Decode]] —— 為什麼這招只對其中一半有效
- [[服務棧選型與降本]] —— 實務上透過哪些框架吃到它
