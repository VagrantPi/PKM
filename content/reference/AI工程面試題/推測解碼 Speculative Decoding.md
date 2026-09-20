---
type: reference
name: "推測解碼 Speculative Decoding"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, inference, latency, optimization]
triggers: [用小模型猜大模型為什麼品質不會掉, 單一使用者的生成速度怎麼加快, batch很大時哪些優化會失效, 不重訓怎麼降低延遲, prompt裡有的內容能不能直接抄]
---

> **對應原題**（Common ‧ Inference, Serving and GPU Performance）
> - What is speculative decoding? **Why is output quality preserved, and when does it not help?**
>   — *Asked at: NVIDIA, Together AI*
>
> 論文：Leviathan et al., *Fast Inference from Transformers via Speculative Decoding* (ICML 2023)；
> Chen et al., *Accelerating Large Language Model Decoding with Speculative Sampling* (DeepMind, 2023)。

## 🎯 什麼情境該想到我
當你「**單一使用者覺得吐字太慢，但又不能換小模型犧牲品質**」的時候。這是少數能**同時**滿足「更快」和「輸出分布完全不變」的技術。

## ⚙️ 怎麼用（機制）

### 動機：免費的算力

[[Prefill 與 Decode]] 算過：batch 1 的 decode，H100 有 **99.7% 的算力在空轉**，全部時間在讀權重。

關鍵觀察：
> **一次 forward 驗證 1 個 token 和驗證 5 個 token，成本幾乎一樣**——因為兩者都要把整份權重讀一遍（分母固定）。

那何不**先猜幾個，再一次驗證**？

### 流程

```
狀態：已生成 "台北的天氣"

1. Draft（小模型，自迴歸跑 γ=4 步，很快）
      猜：" 今天" " 很" " 好" "。"
      同時記下每步的分布 q(·)

2. Verify（大模型，★ 一次 forward 跑完 5 個位置）
      輸入 "台北的天氣 今天 很 好 。"
      得到 5 組分布 p(·)   ← 因為 causal mask，每個位置看到的都只有它前面的

3. 逐一判定接受 / 拒絕
      接受 " 今天" " 很"  →  在 " 好" 處拒絕
      →  從修正分布重新採一個 token，例如 " 熱"

4. 結果：這一輪拿到 3 個 token（" 今天" " 很" " 熱"），只花了 1 次大模型 forward
```

**第 2 步是整件事的關鍵**：驗證 γ 個猜測只需要**一次**大模型前向，因為 causal attention 讓每個位置天然只看得到它之前的內容。

### ★ 為什麼品質完全不變（必考的證明）

用的是 **modified rejection sampling**。設 target 分布 $p$、draft 分布 $q$，draft 猜了 $x$：

$$
\text{接受 } x \text{ 的機率} = \min\left(1, \frac{p(x)}{q(x)}\right)
$$

- $q(x) \le p(x)$（draft 比 target 更不看好它）→ **必定接受**
- $q(x) > p(x)$（draft 太樂觀）→ 以 $p(x)/q(x)$ 的機率接受

**拒絕時，從修正後的殘差分布重新採樣：**

$$
p'(x) = \frac{\max\big(0,\; p(x) - q(x)\big)}{\sum_{x'} \max\big(0,\; p(x') - q(x')\big)}
$$

**可以證明：這樣得到的 token 分布嚴格等於 $p$。**

直覺：接受的部分覆蓋了 $\min(p, q)$ 的質量，拒絕後重採補上 $p$ 超出 $q$ 的那一塊 $\max(0, p-q)$，兩者相加剛好還原 $p$。

> ★ **所以它是「數學上精確」，不是「近似」。** 這和量化、蒸餾、換小模型**完全不同性質**——那些都要拿品質換速度，這個不用。
>
> **而且拒絕時也至少拿到 1 個 token**（重採的那個），所以**永遠不會比原本慢（以步數計）**。

**greedy（$T=0$）時退化成更簡單的規則**：draft 猜的和 target 的 argmax 相同就接受，不同就採用 target 的。

### 期望加速

設每個 token 的接受率為 $\alpha$，一輪猜 $\gamma$ 個，則每輪期望產出：

$$
\mathbb{E}[\text{tokens}] = \frac{1 - \alpha^{\gamma+1}}{1 - \alpha}
$$

| $\alpha$ | $\gamma=4$ 的期望產出 |
|---|---|
| 0.9 | 4.1 |
| 0.8 | 3.4 |
| 0.7 | 2.8 |
| 0.5 | 1.9 |
| 0.3 | 1.4 |

扣掉 draft 本身的成本 $c$（相對 target 的比例），**實際加速 ≈ $\frac{\mathbb{E}[\text{tokens}]}{1 + \gamma c}$**。

> **所以 draft 模型必須又準又便宜。** 若 draft 是 target 的 1/10 成本、$\gamma=4$，分母是 1.4——$\alpha = 0.8$ 時加速約 **2.4×**。

$\gamma$ 也有最佳值：**猜太多，後面的接受率是 $\alpha^k$ 指數衰減，白算。** 通常 3–8。

### 主要變體

| 方法 | 怎麼產生猜測 | 特點 |
|---|---|---|
| **標準 speculative** | 獨立的小模型（如 Llama-70B 配 Llama-8B） | 要有同 tokenizer 的小模型 |
| **Medusa** | 在原模型上加**多個預測頭**，平行預測位置 +1、+2、+3 | 不用第二個模型；要訓練那些頭 |
| **EAGLE** | 在**特徵層**（而非 token 層）做自迴歸預測 | 接受率明顯較高，目前實務常見 |
| **★ Prompt lookup / n-gram** | **直接從 prompt 或已生成內容裡抄**匹配的 n-gram | **零模型、零訓練、零記憶體** |
| **Self-speculative** | 同一個模型跳過部分層當 draft | 不用額外權重 |

> ★ **Prompt lookup 值得特別記住**：它完全不需要額外模型，只要在上下文裡找重複的 n-gram。
> **對「輸出大量重複輸入」的任務效果極佳**——RAG 摘要與引用、程式碼編輯（大部分內容不變）、翻譯、結構化改寫。
> 這類場景是**幾行程式碼就能拿到 2–3× 的加速**，投報率極高。vLLM / TensorRT-LLM 都內建。

## ⚠️ 注意 / 什麼時候不適用（★ 這題的重點）

### 1. ★ 高 batch 下沒用，甚至更慢
這是最重要的一點。推測解碼**消費的是閒置算力**。

| 情境 | 算力狀態 | 結果 |
|---|---|---|
| batch 1–4 | 幾乎全閒 | **加速明顯** |
| batch 32+ | 已接近 compute-bound | 增益急遽縮小 |
| batch 很大 | 完全 compute-bound | **變慢**（驗證多算的那些 token 是純浪費） |

→ **它是延遲優化，不是吞吐優化。** 兩者在這裡直接衝突。
→ 生產系統常見做法：**依當前 batch 大小動態開關**（vLLM 有相關的動態推測長度機制）。

### 2. 接受率會依任務劇烈變化
- **高 $\alpha$**：格式化輸出、程式碼樣板、複述、事實性短答
- **低 $\alpha$**：創意寫作、高 temperature、draft 沒見過的領域
→ **一定要在自己的流量上量 $\alpha$，別用 benchmark 數字。**

### 3. 高 temperature 會殺死接受率
$T$ 越高分布越平，$p$ 和 $q$ 越容易分歧。**$T=0$ 時接受率最高。**

### 4. draft 必須和 target 同 tokenizer
不同 tokenizer 就無法逐 token 對應。這大幅限制了 draft 的選擇（實務上多半得用同系列的小模型）。

### 5. 記憶體成本
多一個模型就多一份權重與 KV cache。**在顯存已經吃緊時，這些顯存拿去加大 batch 可能更划算。**

### 6. 實作正確性很難驗
接受規則寫錯**不會報錯**，只會讓輸出分布悄悄偏掉。
→ **驗證方法**：固定 seed，比對「開啟推測解碼」與「關閉」的輸出。在 greedy 下**必須逐 token 完全相同**。這是上線前的必要檢查。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開。**待辦：先試 prompt lookup（零成本），量自己場景的接受率。**

## 🔗 相關
- [[Prefill 與 Decode]] —— 那 99.7% 閒置算力的由來
- [[取樣與解碼策略]] —— 被嚴格保持的就是那個取樣分布
- [[連續批次 Continuous Batching]] —— 兩者的目標互相衝突，要協調
- [[知識蒸餾]] —— draft 模型常用蒸餾產生
- [[服務棧選型與降本]] —— 什麼時候值得開
