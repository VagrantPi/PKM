---
type: reference
name: "位置編碼與旋轉位置嵌入 Positional Encoding & RoPE"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, transformer, rope, long-context, architecture]
triggers: [attention怎麼知道字的先後順序, RoPE到底在旋轉什麼, 模型上下文能不能硬撐更長, 長文件中間的資訊為什麼被忽略, YaRN和位置內插差在哪]
---

> **對應原題**（Common ‧ LLM Internals）
> - What is positional encoding in transformers, and how has it evolved (sinusoidal → learned → RoPE → ALiBi)?
> - Explain RoPE and how **position interpolation / YaRN** extend context beyond the trained length.
>   — *Asked at: Meta, Moonshot AI, Alibaba*
> - What is the **lost-in-the-middle** problem in long contexts and how do you address it? — *Asked at: Moonshot AI*

## 🎯 什麼情境該想到我
當你「**想知道模型怎麼感知順序、或想把上下文撐到訓練長度以外**」的時候。長上下文產品（Kimi、Claude、Gemini）的技術護城河大半在這一頁。

## ⚙️ 怎麼用（機制）

### 為什麼需要位置編碼
純 attention 是 **permutation-equivariant** 的：打亂輸入順序，輸出只是跟著換位，**內容完全一樣**。
$$\text{Attention}(\pi X) = \pi\,\text{Attention}(X)$$
也就是說「狗咬人」和「人咬狗」對它一模一樣。**位置必須外加。**

（causal mask 提供了「誰在誰之前」的粗略資訊，但沒有距離概念。）

### 四代演進

| 世代 | 做法 | 位置類型 | 外推能力 | 代表 |
|---|---|---|---|---|
| **Sinusoidal**（2017） | 固定的 sin/cos 向量**加到 input embedding** | 絕對 | 理論可、實際差 | 原始 Transformer |
| **Learned absolute**（2018–） | 學一張 `max_len × d` 的查表 | 絕對 | **完全不能**（表外沒有值） | BERT、GPT-2 |
| **RoPE**（2021） | 在**每層 attention 內**旋轉 Q、K | **相對**（湧現的） | 需要調整，但可以 | Llama、Qwen、Mistral、GPT-NeoX |
| **ALiBi**（2022） | 不加向量，直接在 attention score 上加線性懲罰 | 相對 | **原生可外推** | BLOOM、MPT |

**Sinusoidal**：$PE_{(pos, 2i)} = \sin(pos / 10000^{2i/d})$，$PE_{(pos, 2i+1)} = \cos(\cdot)$。不同維度是不同波長的正弦波，像二進位計數器。

**ALiBi**：$\text{score}_{ij} \mathrel{+}= -m_h \cdot |i - j|$，$m_h$ 是每個頭固定的斜率。**距離越遠扣分越多**，簡單粗暴但外推性極好。代價是它強制了一個「近的比較重要」的先驗，不利於需要看遠處的任務。

### ★ RoPE：旋轉，而不是相加

**核心想法**：不要把位置「加」進向量，而是把向量**依位置旋轉一個角度**。

把 $d_{head}$ 維向量拆成 $d/2$ 組二維子空間 $(x_{2i}, x_{2i+1})$，第 $i$ 組在位置 $m$ 時旋轉 $m\theta_i$：

$$
\begin{pmatrix} x'_{2i} \\ x'_{2i+1} \end{pmatrix}
=
\begin{pmatrix} \cos m\theta_i & -\sin m\theta_i \\ \sin m\theta_i & \cos m\theta_i \end{pmatrix}
\begin{pmatrix} x_{2i} \\ x_{2i+1} \end{pmatrix},
\qquad \theta_i = 10000^{-2i/d}
$$

用複數寫更清楚：把每組看成複數 $z_i$，RoPE 就是 $z_i \mapsto z_i e^{\mathrm{i} m\theta_i}$。

**★ 為什麼這樣就得到相對位置**（這是必考的一步）：

$$\langle R_m q,\ R_n k\rangle = \mathrm{Re}\left[\sum_i q_i \bar{k_i}\, e^{\mathrm{i}(m-n)\theta_i}\right]$$

旋轉矩陣是正交的，內積只留下 **$(m-n)$**。也就是：
> **雖然是對絕對位置做旋轉，attention 分數只看得到相對距離。** 這就是 RoPE 同時具備「實作簡單（絕對）」和「泛化好（相對）」的原因。

**其他性質**：
- **不加參數**，純函數
- **在每層都作用**，不像絕對位置只在輸入加一次
- 每組的波長 $\lambda_i = 2\pi/\theta_i$ 從 $2\pi$（高頻，管近距離）到 $2\pi \cdot 10000$（低頻，管遠距離）

### ★ 撐長上下文的三種手法

問題：模型只在 $L_{train}$（如 4K）內見過那些旋轉角度。輸入 32K 時，**位置 30000 的角度從未見過**，注意力分數直接崩潰。

| 方法 | 做什麼 | 需微調？ | 代價 |
|---|---|---|---|
| **直接外推** | 什麼都不做 | — | **壞掉**。perplexity 爆炸 |
| **Position Interpolation (PI)**<br>Chen et al., 2023 | 位置索引**除以** $s = L_{new}/L_{train}$，把 32K 壓回 4K 的角度範圍 | **要**（少量，千步級） | 高頻被壓扁，**近距離解析度下降**，短文本能力會退 |
| **NTK-aware scaling** | 不均勻：改 base $b' = b \cdot s^{\frac{d}{d-2}}$。**高頻幾乎不動、低頻大幅拉伸** | 可免 | 比 PI 溫和，但仍有損失 |
| **YaRN**<br>Peng et al., 2023 | NTK-by-parts + attention 溫度 | 少量（論文稱約 PI 的 1/10 步數） | 目前實務常見的預設 |

**PI 的直覺**：與其讓模型看沒見過的大角度，不如**把新位置線性壓縮進訓練過的角度範圍**。位置 8000 在 $s=2$ 時當作 4000 處理。代價是 token 之間的角度差變小了——原本相鄰兩字差 $\theta$，現在差 $\theta/2$，**近距離的區分度被犧牲**。

**NTK-aware 的直覺**：PI 的問題是「一視同仁」。但高頻維度負責區分「隔壁字 vs 隔兩個字」，最不該被壓；低頻維度管長程，壓了也還好。所以**按波長分別處理**。

**YaRN 的三段式**（NTK-by-parts）：
1. **波長 < 上下文長度**（高頻）→ **完全不內插**，保住近距離解析度
2. **波長 > 上下文長度**（低頻）→ **完全內插**（等同 PI）
3. **中間** → 線性混合

加上一項**注意力溫度**修正：$\text{softmax}(\frac{qk^\top}{t\sqrt{d}})$，補償序列變長後注意力熵上升導致的分布過度平坦。

> **面試答法**：「PI 是均勻壓縮，NTK 是按頻率不均勻拉伸，YaRN 是按波長分三段處理再加溫度修正。三者的共同前提是 RoPE 的角度可以被重新參數化——這是 RoPE 相對於 learned embedding 的結構性優勢。」

### ★ Lost in the Middle（長上下文的另一半問題）

Liu et al., 2023（TACL）的發現：把答案藏在長上下文的不同位置，模型的正確率呈 **U 型**——

```
正確率
  ▲
  │●                                    ●
  │  ●                                ●
  │     ●                          ●
  │        ●  ●  ●  ●  ●  ●  ●  ●
  └──────────────────────────────────────▶ 答案所在位置
   開頭            中間               結尾
```

**「上下文塞得下」不等於「模型用得到」。** 而且在某些設定下，把文件塞進長上下文的表現**還不如只給少數精選文件**。

成因（部分假說，仍在研究中）：
- 預訓練資料本身的位置偏置（文件開頭與結尾資訊密度高）
- 注意力的 recency bias 與 attention sink（開頭 token 天然吸走大量注意力）
- 位置外推方法在中段的近似誤差

**七個實務對策**：
1. **重排序**：檢索結果**最相關的放頭尾、最不相關的塞中間**（跟直覺相反但有效）
2. **少即是多**：與其塞 50 段，不如 rerank 後只留 5 段（見 **Reranker 重排序**（本庫尚未建立，批次 2／3 補））
3. **要求引用**：強制模型輸出「依據第幾段」，逼它真的去讀（見 **權限感知檢索與引用歸因**（本庫尚未建立，批次 2／3 補））
4. **分段處理再合併**：map-reduce 式，每段各自抽取再彙整
5. **結構化標記**：用明確的分隔符與編號，別給一團連續文字
6. **針對性測試**：needle-in-a-haystack，**並且要在你自己的位置分布上測**
7. **問題重述**：長上下文之後再重述一次問題（把指令放在結尾的有效區）

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開，尚未實際套用。

## ⚠️ 注意 / 什麼時候不適用

- **宣稱的 context window ≠ 可用的 context window**。128K 的模型在 100K 處的檢索能力可能已經很差。上線前自己跑 needle-in-haystack。
- **RoPE 縮放會傷短文本**。用 PI 擴到 32K 的模型，在 2K 的任務上通常比原版差。若兩種流量都有，考慮分開部署。
- **改 RoPE 參數要和推論框架一致**。`rope_scaling` 設錯（type/factor 不匹配訓練時的設定）會**靜默地**產生品質下降，不會報錯。
- **ALiBi 不是免費午餐**。它的線性衰減是硬先驗，對「答案在遠處」的任務不利。
- **長上下文的成本是平方成長的**（prefill 的 attention）。32K 的 prefill 不是 4K 的 8 倍，是 64 倍的 attention 計算。見 [[Prefill 與 Decode]]。
- **RAG 沒有被長上下文取代**。成本、延遲、lost-in-the-middle 三件事都還在。見 [[工具-RAG檢索增強生成]]。

## 🔗 相關
- [[注意力機制]] —— RoPE 作用在 Q、K 上
- [[KV Cache]] —— 長上下文的顯存帳
- [[Prefill 與 Decode]] —— 長上下文為什麼 TTFT 特別糟
- **Reranker 重排序**（本庫尚未建立，批次 2／3 補） —— 對抗 lost-in-the-middle 的主要武器
- [[工具-RAG檢索增強生成]] —— 決策層：長上下文 vs 檢索怎麼選
