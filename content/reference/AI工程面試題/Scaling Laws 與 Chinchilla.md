---
type: reference
name: "規模律與 Chinchilla Scaling Laws"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, scaling, training, research]
triggers: [模型該做多大資料該給多少, Chinchilla最佳比例是什麼, 為什麼小模型卻用超多資料訓練, 能力可不可以預測, 訓練預算怎麼分配]
---

> **對應原題**（Common ‧ LLM Internals；Anthropic ‧ Fine-Tuning）
> - What do the **Chinchilla scaling laws** say, and how do they differ from earlier scaling intuitions? — *Asked at: Anthropic*
> - How do scaling laws influence the **safety evaluation** of large models? — *Asked at: Anthropic*
>
> 論文：Kaplan et al., *Scaling Laws for Neural Language Models* (2020)；
> Hoffmann et al., *Training Compute-Optimal Large Language Models* (2022, "Chinchilla")。

## 🎯 什麼情境該想到我
當你「**要決定訓練預算怎麼分、或看不懂為什麼 8B 的模型要餵 15T token**」的時候。這也是唯一能回答「花 N 塊錢能得到多好的模型」的量化工具。

## ⚙️ 怎麼用（結論與推導）

### 基本形式
語言模型的 loss 對**參數量 $N$**、**資料量 $D$**、**計算量 $C$** 都呈**冪律（power law）**——在 log-log 圖上是直線，而且直得驚人，跨越好幾個數量級。

計算量的經驗式（記起來，面試常要現場估）：
$$\boxed{C \approx 6ND}$$
（前向 2、反向 4，每個參數每個 token 約 6 FLOPs。）

### ★ Kaplan (2020) vs Chinchilla (2022)：差在哪

| | **Kaplan et al. 2020** | **Chinchilla 2022** |
|---|---|---|
| 給定計算預算，該加什麼 | **主要加參數** | **參數與資料等比例加** |
| 指數 | $N \propto C^{0.73}$，$D \propto C^{0.27}$ | $N \propto C^{0.50}$，$D \propto C^{0.50}$ |
| 實務結論 | 「模型越大越好，資料夠用就行」 | **「當時的大模型全都嚴重欠訓練」** |
| 經驗法則 | — | **每個參數約 20 個 token** |

**Chinchilla 的實驗證明**（同樣的計算預算下）：

| 模型 | 參數 | 訓練 token | 結果 |
|---|---|---|---|
| Gopher | 280B | 300B（≈1.1 tok/param） | 基準 |
| **Chinchilla** | **70B** | **1.4T**（=20 tok/param） | **幾乎全面勝出** |

**參數只有 1/4，但贏了。** 而且推論成本也只有 1/4——雙贏。這篇論文直接改寫了 2022 之後所有實驗室的訓練配方。

**Kaplan 為什麼算錯**：後續分析指出主因是**學習率排程沒有隨 token 數對齊**（cosine schedule 的週期固定，短訓練的模型被不當地懲罰了），另外參數量計算是否含 embedding 也有影響。**不是概念錯，是實驗設計的瑕疵。**

### 擬合出來的公式
$$L(N, D) = E + \frac{A}{N^{\alpha}} + \frac{B}{D^{\beta}}$$

Chinchilla 論文的擬合值：$E = 1.69$、$A = 406.4$、$B = 410.7$、$\alpha = 0.34$、$\beta = 0.28$。

三項的意義很清楚：
- $E = 1.69$ —— **自然語言的不可約熵**。再多參數再多資料也降不下去的下限
- $A/N^\alpha$ —— 模型容量不足造成的損失
- $B/D^\beta$ —— 資料不足造成的損失

在 $C = 6ND$ 的約束下對這個式子求極值，就得到 $\alpha \approx \beta$ 時「兩者等比例成長」的結論。

### ★ 後 Chinchilla 時代：為什麼大家又不照做了

看 Llama 3 8B：**15T token**，等於 **~1875 tokens/param**，是 Chinchilla 建議的 **90 倍**。

不是他們算錯，是**目標函數換了**：

> **Chinchilla 最佳化的是「訓練計算」，但真實世界要最佳化的是「訓練 + 推論的總成本」。**

- 訓練是**一次性**成本
- 推論是**永久**成本，而且和參數量成正比

如果一個模型會被呼叫幾兆次，那**多花 10 倍訓練成本去換一個小 2 倍的模型，是划算的**。這就是「over-training」——刻意訓到 Chinchilla 點以外，因為報酬遞減的曲線仍然是往下走的，只是變慢。

| 目標 | 最佳點 |
|---|---|
| 訓練計算最省 | Chinchilla（~20 tok/param） |
| **部署總成本最省** | **遠超 Chinchilla，小模型 + 超量資料** |
| 極限能力 | 兩者都最大化 |

### 其他重要的 scaling 現象

- **資料牆**：高品質 token 是有限的。這推動了合成資料、多輪 epoch、資料品質過濾的研究。
- **MoE 改變了方程式**：容量（總參數）與計算（激活參數）解耦，見 [[混合專家 MoE]]。
- **推論時計算（test-time compute）**：新一代的 scaling 軸——讓模型在推論時多想，而不是把參數做大。

### ★ 對安全評估的意義（Anthropic 那題）

這是這一頁最容易被忽略、但 Anthropic 一定追問的部分：

**1. Loss 可預測，能力不一定。**
pretraining loss 是平滑的冪律，**可以從小模型外推**。但下游任務的表現常呈現**湧現（emergence）**——某個規模之前接近隨機，之後突然跳起來。

> 但要注意：Schaeffer et al. (2023, *Are Emergent Abilities of Large Language Models a Mirage?*) 指出，**許多「湧現」是評估指標造成的假象**——用「完全正確才給分」這種不連續指標會製造斷崖，換成連續指標（如 token-level 的編輯距離）後曲線是平滑的。
> 面試時提這一點很加分：**「湧現」有一部分是真的，有一部分是我們量錯了。**

**2. 所以安全評估不能等訓完才做。**
- 在**一系列小模型**上建立能力與危險能力的 scaling 曲線
- **外推**到目標規模，預測「這個規模會不會具備 X 能力」
- 這正是 Anthropic 的 **Responsible Scaling Policy**、OpenAI 的 Preparedness Framework 這類制度的技術基礎：**先預測，再決定要不要訓／要不要放**

**3. 反過來也成立**：如果某個危險能力在曲線上還沒起來，但外推顯示下一代會起來，**現在就要把緩解措施準備好**。

## ⚠️ 注意 / 什麼時候不適用

- **這些常數不是普適的**。$E, A, B, \alpha, \beta$ 依架構、資料分布、tokenizer 而變。**別把 Chinchilla 的數字直接套到你的領域模型。**
- **「20 tokens per param」是 2022 年那批設定下的結論**，不是物理定律。今天的最佳實踐遠高於它。
- **冪律預測的是 loss，不是「有沒有用」**。loss 降 0.05 可能對你的任務毫無差別。
- **微調沒有同樣乾淨的 scaling law**。這一頁講的是預訓練。
- **報酬遞減是真的**。冪律意味著**每一次能力提升都要指數級的投入**。
- **資料重複的影響**還沒有定論（Muennighoff et al. 2023 指出約 4 個 epoch 內重複資料的效益接近新資料，之後快速衰減）——這個數字要自己驗。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開，尚未實際套用。

## 🔗 相關
- [[混合專家 MoE]] —— 把「容量」與「計算」解耦，改寫了 scaling 的取捨
- [[知識蒸餾]] —— 另一條「小模型也能強」的路
- [[GPU 記憶體估算]] —— $C = 6ND$ 之外，實際跑得動嗎
- **Benchmark 污染與分數失真**（本庫尚未建立，批次 2／3 補） —— 評估能力時的陷阱
