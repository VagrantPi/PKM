---
type: reference
name: "LoRA 與 QLoRA Low-Rank Adaptation"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, fine-tuning, peft, lora, quantization]
triggers: [LoRA的數學是什麼, rank要設多少, LoRA為什麼推論時沒有額外延遲, QLoRA的記憶體是怎麼省下來的, NF4和int4差在哪]
---

> **對應原題**（Common ‧ Fine-Tuning, Post-Training and Alignment）
> - **Explain the LoRA decomposition mathematically.** Why does it work, and **how do you choose the rank r**?
> - How does **QLoRA** achieve its memory reduction, and **what are the quantization trade-offs**? — *Asked at: Hugging Face*
>
> 論文：Hu et al., *LoRA* (ICLR 2022)；Dettmers et al., *QLoRA* (NeurIPS 2023)。
> 📌 **分層**：該選 Full / LoRA / QLoRA、框架怎麼挑 → [[工具-LLM微調實作路線]]（決策層）。

## 🎯 什麼情境該想到我
當你「**要微調但顯存不夠、或被問到 rank 該設多少**」的時候。
★ LoRA 是目前**唯一一個讓一般團隊做得起大模型微調**的技術，也是面試最常要求現場推導的一個。

## ⚙️ Part 1：LoRA

### 數學

凍結預訓練權重 $W_0 \in \mathbb{R}^{d \times k}$，只學一個**低秩的增量**：

$$W' = W_0 + \Delta W = W_0 + \frac{\alpha}{r} B A$$

其中 $B \in \mathbb{R}^{d \times r}$、$A \in \mathbb{R}^{r \times k}$，且 $r \ll \min(d, k)$。

前向：
$$h = W_0 x + \frac{\alpha}{r}\,B(Ax)$$

**注意計算順序**：先 $Ax$（降到 $r$ 維）再乘 $B$（升回 $d$ 維）——**中間永遠不具體化 $d \times k$ 的 $\Delta W$**。

```python
class LoRALinear(nn.Module):
    def __init__(self, base: nn.Linear, r=16, alpha=32, dropout=0.05):
        super().__init__()
        self.base = base
        for p in self.base.parameters():
            p.requires_grad = False                      # ★ 凍結底座
        d_out, d_in = base.weight.shape
        self.A = nn.Parameter(torch.empty(r, d_in))
        self.B = nn.Parameter(torch.zeros(d_out, r))     # ★ B 初始化為 0
        nn.init.kaiming_uniform_(self.A, a=math.sqrt(5))
        self.scaling = alpha / r
        self.dropout = nn.Dropout(dropout)

    def forward(self, x):
        return self.base(x) + self.dropout(x) @ self.A.T @ self.B.T * self.scaling
```

### ★ 三個必考的實作細節

**1. `B` 初始化為零，`A` 隨機初始化**
$\Delta W = BA = 0$，所以**訓練第一步的模型行為與底座完全相同**。
→ 不會有隨機初始化造成的品質震盪。
（兩個都設 0 就永遠學不動——梯度全為 0；兩個都隨機則一開始就破壞模型。）

**2. 縮放 $\alpha / r$**
讓你**改變 $r$ 時不用重調學習率**。$r$ 變大時 $BA$ 的量級會變，除以 $r$ 抵銷掉。
慣例：$\alpha = r$ 或 $\alpha = 2r$。

**3. ★ 推論時可合併，零延遲開銷**
$$W_{\text{merged}} = W_0 + \frac{\alpha}{r}BA$$
合併後就是一個普通的權重矩陣。
→ **這是 LoRA 相對於 Adapter 的決定性優勢**：Adapter 在網路中插入了額外的層，推論時**永遠**多一段串列計算；LoRA 合併後**完全沒有**。

（不合併的話，可以**多個 adapter 熱插拔**——同一個底座服務多個客製版本，這是 LoRA 服務化的基礎。）

### 參數量

| | 參數量 | 例：$d = k = 4096$ |
|---|---|---|
| 原矩陣 | $d \times k$ | **16,777,216** |
| LoRA | $r(d + k)$ | $r=16$ → **131,072（0.78%）** |

### ★ 為什麼有效

**Intrinsic dimension 假說**（Aghajanyan et al., 2020；LoRA 論文沿用）：
> **預訓練模型在微調時的權重更新 $\Delta W$，具有很低的「內在秩」。**

直覺：預訓練已經把通用能力學好了，**微調只是在做一個低維度的方向調整**，不是重新學習。

> ⚠️ **誠實地講**：這是**實證觀察 + 假說**，不是定理。
> LoRA 論文觀察到即使 $r = 1$ 或 $2$ 在某些任務上也夠用，支持這個假說；但它**沒有被證明對所有任務成立**——
> 學習大量新知識的任務上，LoRA 確實不如全量微調。面試時講出這個邊界比背誦假說有說服力。

### ★ rank 怎麼選

| 任務類型 | 建議 $r$ |
|---|---|
| 風格、語氣、輸出格式、指令遵循 | **8–16** |
| 領域適應（新術語、新任務型態） | **32–64** |
| 大量新知識、接近全量微調的效果 | **128–256**（此時該重新考慮值不值得） |

> ★ **但 QLoRA 論文的發現更重要**：
> **「掛在哪些層」比「$r$ 設多大」影響更大。**
> 只掛 `q_proj`/`v_proj` 而把 $r$ 開到 256，**不如**把 $r=16$ **掛在所有 linear 層**（q、k、v、o、gate、up、down）。
>
> **實務起手式：$r=16$、$\alpha=32$、掛所有 linear 層。** 不夠再往上調。

### 記憶體（★ 最常見的誤解）

見 [[GPU 記憶體估算]] 的完整算式。一句話結論：

> **LoRA 省的是「梯度 + 優化器狀態 + fp32 主權重」這 14 bytes/param，不省 activation。**
> 因為梯度**仍然要反向傳播穿過整個網路**才能到達 LoRA 層。
> → 7B 全量微調 112 GB，LoRA ≈ 18 GB（其中 4 GB 是 activation）。

## ⚙️ Part 2：QLoRA

**一句話**：**把底座量化成 4-bit 凍結起來，只用 bf16 訓練 LoRA adapter。**

### 三個技術創新

#### ① 4-bit NormalFloat（NF4）
一般的 int4 假設數值**均勻分布**，但**神經網路權重接近常態分布**。

NF4 是**分位數量化**：讓 16 個量化點落在標準常態分布的等機率分位上——
**每個量化桶裡的權重數量大致相等**，資訊論上對常態分布資料是最優的。

> **面試答法**：「NF4 不是『更好的 int4』，是**針對權重實際分布設計的資料型別**。
> 量化的第一原則是**讓格點跟著資料分布走**，而不是均勻鋪開。」（對照 [[量化 Quantization]] 的離群值討論。）

#### ② 雙重量化（Double Quantization）
量化需要對每個 block（QLoRA 用 64）存一個 fp32 的縮放常數。

```
block size 64，每 block 一個 fp32 scale
→ 32 bits / 64 params = 0.5 bits/param  ← 不小的開銷！
```

**把縮放常數本身也量化**（8-bit，每 256 個 scale 再共用一個 fp32）：
→ 省下約 **0.37 bits/param**。65B 模型省約 **3 GB**。

#### ③ 分頁優化器（Paged Optimizers）
用 NVIDIA 的統一記憶體，**在記憶體尖峰時自動把優化器狀態分頁到 CPU RAM**，尖峰過後再換回來。

> 這解的是**長序列造成的突發 OOM**——平均用量沒問題，但某個 batch 的尖峰把你炸了。
> （概念上和 [[PagedAttention 與 vLLM]] 同源：**用分頁處理不可預測的記憶體尖峰**。）

### 運作流程
```
底座權重（NF4，凍結）
  │ 前向時：逐層反量化成 bf16 → 計算 → 立刻丟棄
  ▼
計算  h = W_dequant·x + (α/r)·BA·x
                          └── LoRA，bf16，有梯度
```
**★ 只有「當前正在用的那一層」被反量化**，不是整個模型——這是記憶體節省的關鍵。

### 成果與取捨

論文成果：**單張 48 GB GPU 微調 65B 模型**，並宣稱達到 16-bit 全量微調的效能水準。
*（論文自報、特定評估設定，當作量級參考。）*

**★ 取捨（題目明確問的部分）**：

| 取捨 | 說明 |
|---|---|
| **訓練變慢** | 每一層每一步都要反量化。實測常慢 **30–40%**（依硬體與實作） |
| **★ 推論端的兩難** | adapter 是**針對量化過的底座**訓練的。<br>• 保持 4-bit 推論 → 一致，但有量化的品質損失<br>• 合併回 bf16 底座 → 全精度，但**adapter 與底座不匹配**，品質可能反而掉<br>→ **要兩種都評估過再決定** |
| **量化誤差可能累積** | 長訓練、大 rank 下要注意 |
| **不省 activation** | 和 LoRA 一樣（見上） |

## ⚠️ 注意 / 什麼時候不適用

- **★ LoRA 不擅長灌新知識**。它調整的是「怎麼回答」，不是「知道什麼」。要新知識請走 RAG（見 [[工具-微調與RAG的取捨]]）。
- **多個 LoRA 合併會互相干擾**。同時合併兩個 adapter 不等於同時具備兩種能力，通常會互相削弱。要並用就別合併，走熱插拔。
- **$r$ 太大會失去 LoRA 的意義**。$r = 512$ 的參數量已經接近全量微調，卻還帶著低秩的限制——此時該直接做全量。
- **dropout 對小資料集重要**。LoRA 參數少但仍會過擬合。
- **學習率通常比全量微調大 10–100 倍**（常見 1e-4 ~ 3e-4），因為只更新極少參數。
- **合併後一定要重新評估**。合併的數值行為與訓練時不完全一致。
- **QLoRA 的速度損失在小模型上不划算**。7B 在一張 80GB 卡上直接 LoRA 就好，不必 QLoRA。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開。**待辦：起手式固定成 r=16 / α=32 / 掛所有 linear。**

## 🔗 相關
- [[GPU 記憶體估算]] —— 完整的記憶體帳，以及「不省 activation」的推導
- [[量化 Quantization]] —— NF4 與其他 4-bit 格式的比較
- [[PEFT 方法比較]] —— LoRA vs prefix / prompt tuning / 全量
- [[DPO]] —— DPO + LoRA 是實務上最常見的對齊組合
- [[災難性遺忘]] —— LoRA 為什麼比全量微調不容易遺忘
- [[工具-LLM微調實作路線]] —— 決策層
- [[工具-微調與RAG的取捨]] —— 上游決策
