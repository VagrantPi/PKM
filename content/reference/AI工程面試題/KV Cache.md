---
type: reference
name: "KV 快取 KV Cache"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, inference, memory, optimization]
triggers: [KV cache記憶體怎麼算, 長上下文為什麼會爆顯存, 推論時顯存被什麼吃掉, 一張卡能同時服務幾個對話, 要手刻單步decode]
---

> **對應原題**（Common ‧ LLM Internals / Inference）
> - What is the KV cache, and what are its memory implications at scale? **Derive the formula.**
>   — *Asked at: OpenAI, xAI, Mistral AI, Amazon, Apple, NVIDIA, Together AI, Character.AI*
> - Estimate the GPU memory needed to serve a 70B model: weights, KV cache, activations, fragmentation. — *Asked at: NVIDIA*
> - Implement a KV cache and single-step decode. — *Asked at: Moonshot AI*

## 🎯 什麼情境該想到我
當你「**要算一張 GPU 到底能同時撐幾個對話、或想知道長上下文為什麼突然 OOM**」的時候。這是 LLM 服務成本的核心變數——**權重是固定成本，KV cache 是隨流量成長的變動成本。**

## ⚙️ 怎麼用（推導與算帳）

### 它解決什麼
自迴歸生成每次只多產一個 token。若什麼都不存，生成第 $t$ 個 token 時要重算前面 $t-1$ 個 token 的 K/V——整段生成的總成本是 $O(N^2)$ 的重複勞動。

**KV cache 就是把已算過的 K、V 存起來**，每步只算**新 token 那一列**：

| | 不快取 | 快取後 |
|---|---|---|
| 每步計算 | 重算 $t$ 個 token 的 K/V | 只算 1 個 token 的 K/V |
| 每步 attention | $Q_{1:t} K_{1:t}^\top$ | $q_t K_{1:t}^\top$（1×t 向量） |
| 代價 | 算力 | **顯存 + 記憶體頻寬** |

這是典型的**拿空間換時間**，而換來的空間問題大到催生了 [[PagedAttention 與 vLLM]]。

### ★ 記憶體公式（現場推導版）

一個 token、一層，要存 K 和 V 各一份，每份 $h_{kv} \times d_{head}$ 個數：

$$\text{bytes} = \underbrace{2}_{K,V} \times L \times N \times h_{kv} \times d_{head} \times p \times B$$

| 符號 | 意義 |
|---|---|
| $L$ | 層數 |
| $N$ | 序列長度（prompt + 已生成） |
| $h_{kv}$ | **KV 頭數**（GQA 下 ≠ query 頭數，見 [[注意力機制]]） |
| $d_{head}$ | 每頭維度 |
| $p$ | 每個數的位元組數（fp16/bf16 = 2、fp8/int8 = 1） |
| $B$ | batch size（並行的序列數） |

**記法**：`2 × 層 × 長度 × KV維度 × 精度 × 批次`。

### 實例：Llama-2-70B

規格：$L=80$、$d_{model}=8192$、query 頭 64、**KV 頭 8（GQA）**、$d_{head}=128$。

```
每 token 每層  = 2 × 8 × 128 × 2 bytes = 4,096 bytes = 4 KiB
每 token 全模型 = 4 KiB × 80 層         = 320 KiB
4K 上下文一條序列 = 320 KiB × 4,096      ≈ 1.25 GiB
batch 32                                ≈ 40 GiB
```

**對照組：如果它用 MHA（64 個 KV 頭）**
每 token 變 8 倍 = 2.5 MiB，一條 4K 序列就要 **10 GiB**。
→ 這就是 GQA 的價值：**同樣顯存能多服務 8 倍的併發**。

### 整張卡的記憶體帳（NVIDIA 那題的標準答法）

服務 70B、bf16、2×H100 80GB = 160 GiB：

| 項目 | 大小 | 說明 |
|---|---|---|
| 權重 | **140 GiB** | 70B × 2 bytes。固定，不隨流量變 |
| 框架 / CUDA context / 啟動開銷 | ~2–4 GiB | 每張卡都有 |
| 啟動值 activations | 小（decode 階段） | decode 每步 batch×1 token，幾乎可忽略；**prefill 才大** |
| **剩給 KV cache** | **~16 GiB** | 160 − 140 − 開銷 |
| → 能撐多少 | **~13 條 4K 序列** | 16 GiB ÷ 1.25 GiB |

**結論很刺眼**：權重佔掉 87%，真正能服務的併發少得可憐。這直接推出三條路——**量化權重**（見 [[量化 Quantization]]）、**壓 KV**、**別浪費 KV**（見 [[PagedAttention 與 vLLM]]）。

> 加上碎片化：vLLM 論文指出，傳統做法（依 max_seq_len 預留連續空間）的**實際有效利用率常低於 40%**，其餘都浪費在內部/外部碎片與預留。這數字是論文情境下的量測，套到你的 workload 前要自己量。

### 單步 decode 的最小實作（coding 題）

```python
class KVCache:
    def __init__(self, B, n_layers, h_kv, d_head, max_len, dtype, device):
        shape = (n_layers, B, h_kv, max_len, d_head)
        self.k = torch.zeros(shape, dtype=dtype, device=device)
        self.v = torch.zeros(shape, dtype=dtype, device=device)
        self.len = 0                      # 目前已填長度

    def append(self, layer, k_new, v_new):   # k_new: (B, h_kv, 1, d_head)
        t = self.len
        self.k[layer, :, :, t:t+1] = k_new
        self.v[layer, :, :, t:t+1] = v_new
        return self.k[layer, :, :, :t+1], self.v[layer, :, :, :t+1]

# 單步 decode：注意 q 只有 1 個 token，但 K/V 是整段
def decode_step(x_t, layer, cache):          # x_t: (B, 1, d_model)
    q = proj_q(x_t)                          # (B, h_q, 1, d_head)
    k, v = cache.append(layer, proj_k(x_t), proj_v(x_t))
    if h_q != h_kv:                          # GQA：把 KV 頭重複到 Q 頭數
        rep = h_q // h_kv
        k, v = k.repeat_interleave(rep, dim=1), v.repeat_interleave(rep, dim=1)
    # 這一步不需要 causal mask——q 本來就只看得到 0..t
    return sdpa(q, k, v, causal=False)
```

**兩個面試官會挑的點**：
1. **decode 階段不需要 causal mask**——當前 token 的 query 天生只對到 cache 裡已有的位置。加 mask 是多餘甚至錯的。
2. **GQA 的 `repeat_interleave` 是邏輯上的展開**；高效實作會直接在 kernel 裡廣播，不真的複製記憶體。

### 壓縮 KV cache 的四條路

| 路線 | 做法 | 損失 |
|---|---|---|
| **架構層** | MQA / GQA / MLA —— 少存頭或壓低維度 | 要重訓或續訓 |
| **精度層** | KV 量化成 int8 / fp8 | 長序列上誤差會累積，要實測 |
| **長度層** | 滑動窗口、注意力池（StreamingLLM）、重要度驅逐（H2O） | 會真的丟掉資訊 |
| **配置層** | PagedAttention 分頁、前綴共享 | **無損**，純粹省浪費 —— 優先做這個 |

> 順序建議：**先做無損的（分頁、前綴共享）→ 再量化 → 最後才考慮丟資訊。**

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開，尚未實際套用。

## ⚠️ 注意 / 什麼時候不適用

- **別把 query 頭數當成 $h_{kv}$**。GQA 模型算錯會高估 8 倍。查 config 的 `num_key_value_heads`。
- **KV cache 隨 $B \times N$ 線性成長，且不可預測**——使用者可以一直聊下去。容量規劃要算「最壞情況的併發 × 上下文」，不是平均值。
- **它讓 decode 變成 memory-bound**。每生成一個 token 都要把整個 cache 讀過一遍；序列越長，每個 token 越慢。這是 TPOT 隨對話變長而劣化的主因。
- **前綴快取 ≠ KV cache**。KV cache 是單次請求內的；[[前綴快取 Prompt Caching]] 是跨請求重用。兩者疊加才有完整效益。
- **MLA 存的是 latent，不是 K/V**，上面的公式不能直接套。

## 🔗 相關
- [[注意力機制]] —— $h_{kv}$ 從哪來、GQA 怎麼減它
- [[PagedAttention 與 vLLM]] —— 解決這裡的碎片化浪費
- [[前綴快取 Prompt Caching]] —— 跨請求重用 KV
- [[量化 Quantization]] —— 把 $p$ 從 2 降到 1
- [[Prefill 與 Decode]] —— 為什麼 decode 是頻寬瓶頸
- [[GPU 記憶體估算]] —— 完整的服務／訓練記憶體帳
