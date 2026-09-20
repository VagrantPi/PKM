---
type: reference
name: "混合專家 Mixture of Experts"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, moe, architecture, scaling]
triggers: [參數變大但算力不變怎麼做到, 8x7B到底是不是56B, MoE省的是顯存還是算力, 專家負載不平衡會怎樣, 為什麼開源大模型都改用MoE]
---

> **對應原題**（Common ‧ LLM Internals）
> - What is a mixture-of-experts architecture and **how does it scale capacity without scaling FLOPs**?
>   — *Asked at: Mistral AI, Cohere, DeepSeek, Moonshot AI, Zhipu AI, Alibaba*
>
> 六家問這題，**其中五家是 MoE 模型的發表者**。問的不是定義，是你懂不懂它的代價。

## 🎯 什麼情境該想到我
當你「**看到 8x7B 這種命名搞不懂它到底多大、或在評估 MoE 模型值不值得自架**」的時候。

## ⚙️ 怎麼用（機制）

### 基本結構

Transformer 每層有 attention + FFN。**MoE 把 FFN 換成 $N$ 個平行的 FFN（專家）+ 一個路由器**：

```
        ┌─────────────────────────┐
x ──▶ Router ──▶ top-k 分數        │
        │                          │
        ├──▶ Expert 1  ─┐          │   只有被選中的 k 個
        ├──▶ Expert 2  ─┤          │   真的被計算
        ├──▶ ...        ├──▶ 加權和 ──▶ y
        └──▶ Expert N  ─┘          │
        └─────────────────────────┘
```

$$
g = \text{softmax}(x W_{router}), \qquad
\mathcal{T} = \text{top-}k(g), \qquad
y = \sum_{i \in \mathcal{T}} \frac{g_i}{\sum_{j \in \mathcal{T}} g_j} \, E_i(x)
$$

**路由是 per-token per-layer 的**——同一句話的不同字會走不同專家，同一個字在不同層也會走不同專家。「專家」不對應到人類可理解的領域分工，這是常見誤解。

### ★ 為什麼能「不增 FLOPs 擴容量」

拆成兩個獨立的量：

| 量 | 正比於 | 決定什麼 |
|---|---|---|
| **總參數** | $N$（專家數） | **記憶容量** —— 模型能裝多少知識 |
| **激活參數 / FLOPs** | $k$（選幾個） | **計算成本** —— 每個 token 多少運算 |

$N$ 可以一直加而 $k$ 固定在 2。**知識容量隨 $N$ 成長，計算成本不變。**

理論根據是 Scaling Laws（見 [[Scaling Laws 與 Chinchilla]]）：loss 同時受參數量與計算量影響，MoE 讓你在**固定計算預算**下換到更多參數。

### 實例：數字對得上嗎

| 模型 | 結構 | 總參數 | 每 token 激活 | 比例 |
|---|---|---|---|---|
| **Mixtral 8x7B** | 8 專家 top-2 | **46.7B**（不是 56B！） | **~12.9B** | 28% |
| **Mixtral 8x22B** | 8 專家 top-2 | 141B | ~39B | 28% |
| **DeepSeek-V3** | 細粒度 + 共享專家 | **671B** | **37B** | 5.5% |

> ★ **「8x7B 為什麼不是 56B」是高頻追問**：因為 **attention 層、embedding、LayerNorm 全部共享**，只有 FFN 被複製 8 份。所以是 $8 \times \text{FFN} + 1 \times \text{其他}$，不是 $8 \times 7\text{B}$。
>
> 而激活的 12.9B > 7B，是因為 top-2 要跑**兩個** FFN，加上共享的部分。

### ★ 負載平衡：MoE 真正難的地方

路由器會**自我強化**：某個專家早期表現好 → 被選得多 → 訓練得更好 → 被選得更多。最後少數專家吃掉全部流量，其餘變死參數（**expert collapse**）。

| 對策 | 做法 | 出處 / 問題 |
|---|---|---|
| **輔助損失 aux loss** | 加一項懲罰，鼓勵 token 均勻分佈到專家 | Switch Transformer (Fedus et al., 2021)。**問題：它和主任務目標衝突，會傷品質** |
| **專家容量 + 丟棄** | 每個專家設容量上限，超額 token 直接跳過 FFN（只走殘差） | 丟 token 會傷品質，且訓練/推論行為不一致 |
| **Expert Choice** | 反過來讓**專家挑 token**，天然平衡 | 不適用於自迴歸（會看到未來） |
| **無輔助損失平衡** | 給每個專家一個**可調偏置** $b_i$ 加在路由分數上，依負載動態增減；偏置只影響選擇、不影響輸出權重 | DeepSeek-V3。**避開了 aux loss 傷品質的問題** |
| **router z-loss** | 懲罰過大的 router logits，穩定訓練 | ST-MoE |

### 細粒度 + 共享專家（DeepSeekMoE 的貢獻）

兩個調整：
1. **細粒度**：把專家切更小更多（例如 64 個小專家選 6 個，而不是 8 個大專家選 2 個）→ **組合數暴增**，專業化程度更高
2. **共享專家**：保留 1–2 個**所有 token 都走**的專家，負責通用知識 → 其他專家不必重複學共通的東西

這解釋了 DeepSeek-V3 為什麼能把激活比例壓到 5.5% 還保持品質。

## ⚠️ 注意 / 什麼時候不適用（★ 這題的殺手級追問）

### 1. ★ MoE 省計算，**不省顯存**
推論時**所有專家的權重都必須在顯存裡**——你不知道下一個 token 會路由到誰。

Mixtral 8x7B 要 **46.7B 的顯存**（bf16 約 94 GB），但只有 13B 的算力成本。
→ **它讓你用 13B 的速度跑，但要付 47B 的顯存錢。** 對個人/小團隊自架來說，這個交易常常不划算。

### 2. batch 大了就不省頻寬
單一 token 只碰 2 個專家。但 batch 128 時，**幾乎每個專家都會被某個 token 選到**——整層的權重還是得全部讀進來。
→ **MoE 的效率優勢在低 batch 最明顯，高吞吐服務下會被稀釋。**

### 3. 通訊成本（expert parallelism）
專家散在不同 GPU 上時，每層都要做兩次 **all-to-all**（把 token 送去對應的專家，再送回來）。這是 MoE 訓練與推論的主要工程難點，且**跨節點時特別痛**。

### 4. 批次大小不均衡 → 尾延遲
不同專家拿到的 token 數不同，快的等慢的。**p99 latency 比同等 dense 模型更難控**。

### 5. 微調比 dense 難
路由器對分佈變化敏感，小資料微調容易讓路由塌掉。LoRA 該加在哪（專家？attention？router？）也沒有統一答案。

### 6. 什麼時候**不要**選 MoE
- 顯存是你的瓶頸（大多數自架情境）
- 需要穩定的尾延遲
- 要做大量領域微調
→ 這些情況選同等**激活參數**的 dense 模型更省事。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開，尚未實際套用。

## 🔗 相關
- [[Scaling Laws 與 Chinchilla]] —— MoE 為什麼在 scaling 上划算
- [[正規化與激活函式]] —— 被替換掉的那個 FFN 長什麼樣
- [[平行化策略]] —— expert parallelism 與 all-to-all
- [[KV Cache]] —— MoE 不影響 KV cache，attention 是共享的
- [[量化 Quantization]] —— MoE 的顯存問題常靠量化緩解
