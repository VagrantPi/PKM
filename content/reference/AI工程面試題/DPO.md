---
type: reference
name: "直接偏好最佳化 DPO: Direct Preference Optimization"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, alignment, post-training, dpo, rlhf]
triggers: [DPO為什麼可以不用獎勵模型, DPO和PPO差在哪, 為什麼大家都改用DPO, 什麼時候還是得用線上RL, DPO訓練後模型變得很怪]
---

> **對應原題**（Common ‧ Fine-Tuning, Post-Training and Alignment）
> - What is **DPO** and **why did it displace PPO-based RLHF at many labs**? **When is online RL still better?**
>   — *Asked at: Hugging Face, Scale AI*
>
> 論文：Rafailov et al., *Direct Preference Optimization: Your Language Model is Secretly a Reward Model* (NeurIPS 2023)。

## 🎯 什麼情境該想到我
當你「**想做偏好對齊，但看到 PPO 要同時跑四個模型就退縮了**」的時候。
★ DPO 的價值在於：**它把一個強化學習問題，變回一個標準的監督式分類問題。**

## ⚙️ 怎麼用

### ★ 核心推導（三步，值得會講）

**Step 1：RLHF 的最佳解有閉式形式**

[[RLHF 全流程]] 的目標是
$$\max_\pi\ \mathbb{E}_{y\sim\pi}[r(x,y)] - \beta\,\mathrm{KL}(\pi \,\|\, \pi_{\text{ref}})$$

這個帶 KL 約束的最佳化問題**有已知的解析解**：

$$\pi^*(y|x) = \frac{1}{Z(x)}\,\pi_{\text{ref}}(y|x)\,\exp\!\left(\frac{r(x,y)}{\beta}\right)$$

**Step 2：反解出獎勵**

$$r(x,y) = \beta \log \frac{\pi^*(y|x)}{\pi_{\text{ref}}(y|x)} + \beta \log Z(x)$$

> ★ **這一步就是整篇論文的洞察**：
> **獎勵函數可以用「policy 與 reference 的對數機率比」來表達。**
> 換句話說——**語言模型本身就隱含著一個獎勵模型**（論文標題的由來）。

**Step 3：代進 Bradley-Terry，$Z(x)$ 消失**

$$P(y_w \succ y_l) = \sigma\big(r(x,y_w) - r(x,y_l)\big)$$

**因為是差值，那個難算的配分函數 $Z(x)$ 直接抵銷掉。** 得到：

$$\boxed{\ \mathcal{L}_{\text{DPO}} = -\mathbb{E}\left[\log \sigma\left(\beta \log \frac{\pi_\theta(y_w|x)}{\pi_{\text{ref}}(y_w|x)} - \beta \log \frac{\pi_\theta(y_l|x)}{\pi_{\text{ref}}(y_l|x)}\right)\right]\ }$$

**這是一個可以直接用 `backward()` 的損失函數。沒有 RM，沒有取樣，沒有 RL。**

```python
def dpo_loss(policy_logps_w, policy_logps_l, ref_logps_w, ref_logps_l, beta=0.1):
    # logps = 該回應所有 token 的 log-prob 總和
    pi_logratio  = policy_logps_w - policy_logps_l
    ref_logratio = ref_logps_w    - ref_logps_l
    return -F.logsigmoid(beta * (pi_logratio - ref_logratio)).mean()
```

### ★ 為什麼取代了 PPO-RLHF

| | **PPO-RLHF** | **DPO** |
|---|---|---|
| 需要幾個模型 | **4**（policy / ref / RM / value） | **2**（policy / ref，ref 凍結且可預先算完） |
| 要訓練幾個 | 2（policy + value）＋ 事先訓 RM | **1** |
| 訓練迴圈 | rollout → 評分 → 優勢估計 → 更新 | **標準監督式：batch → loss → backward** |
| 超參數 | 很多（$\epsilon$、GAE $\lambda$、value loss 係數、rollout 長度…） | **主要就 $\beta$ 和 lr** |
| 穩定性 | ⚠️ 惡名昭彰地難調 | ✅ 穩定、可復現 |
| 資源 | 高一個數量級 | **一般團隊做得起** |

> **一句話**：**PPO 需要一個 RL 工程團隊，DPO 只需要一個會用 `SFTTrainer` 的人。**
> 對「不是前沿實驗室」的所有人來說，這個差距就是能不能做的差距。

**`ref_logps` 可以離線預先算完**（reference 模型是凍結的），所以訓練時記憶體只要一份 policy —— 再配 LoRA 更省（見 [[LoRA 與 QLoRA]]、[[GPU 記憶體估算]]）。

### ★ 何時 online RL 仍然更好（題目的後半，也是重點）

**根源：DPO 是 off-policy 的。**

```
DPO：       在「資料集裡現成的那些回應」上學
            ★ 模型當前實際會生成的輸出，它從未見過，也從未被修正

Online RL： 在「policy 當下真的會產生的輸出」上學
            ★ 修正的正是它真的會犯的錯
```

**四個具體場景下 online RL 勝出**：

| 場景 | 為什麼 DPO 不行 |
|---|---|
| **★ 獎勵不可微 / 來自外部驗證** | 「程式碼能不能通過測試」「數學答案對不對」**無法寫成偏好配對來反傳**。RL 只需要一個純量分數，來源不限 → 見 [[GRPO 與 RLVR]] |
| **需要探索** | DPO 只能在既有資料的分布內移動，無法發現新策略 |
| **推理任務要衝上限** | 長鏈推理的正確路徑不在偏好資料裡，要靠 policy 自己搜出來 |
| **分布偏移嚴重** | 訓練久了 policy 已遠離資料分布，DPO 的梯度變得不相關 |

**★ DPO 的已知失效模式（能講出來是加分）**：
> DPO 的損失只保證 **$\log\pi(y_w) - \log\pi(y_l)$ 的差值變大**，
> **它完全不管絕對機率。** 實務上常觀察到**兩者的機率同時下降**——
> 模型把機率質量推到了 $y_w$ 和 $y_l$ **以外**的地方，而那裡沒有任何監督訊號。
> 結果是：偏好指標好看，實際輸出變得奇怪。
>
> → **對策：監控 chosen 的絕對 log-prob**，不要只看 reward margin；必要時混入 SFT loss 當正則。

### 折衷路線（實務主流）

| 方法 | 做法 |
|---|---|
| **★ Iterative / Online DPO** | 用**當前 policy** 生成候選 → 用 RM 或裁判模型標出好壞 → 做一輪 DPO → 重複。**拿回 on-policy 的好處，保留 DPO 的簡單** |
| **拒絕採樣微調（RFT）** | policy 生成 N 個候選，只留最好的做 SFT。極簡但有效 |

→ 這正是 [[工具-偏好對齊方法選擇]] 提到的「用拒絕採樣產生 on-policy 偏好資料」。

### 主要變體

| 變體 | 解決什麼 |
|---|---|
| **IPO** | DPO 在偏好接近確定性時會過擬合；IPO 換一個目標函數處理 |
| **KTO** | **不需要成對資料**，只要「這個好／這個壞」的單邊標記——**實務上資料好蒐集得多** |
| **ORPO** | 把 SFT 與對齊**合併成單階段**，且**不需要 reference 模型** |
| **SimPO** | 用長度正規化的平均 log-prob 當隱式獎勵，**不需要 reference 模型** |

## ⚠️ 注意 / 什麼時候不適用

- **$\beta$ 的角色等同 KL 係數**。太小 → 偏離 SFT 太多、輸出變怪；太大 → 學不動。常見 0.1，但要掃。
- **★ 仍然會 reward hacking**，只是換了形式。DPO 一樣會放大 length bias 與諂媚——**偏好資料裡有的偏誤，它照單全收**（見 [[RLHF 全流程]]）。
- **必須先做 SFT**。$\pi_{\text{ref}}$ 就是 SFT 模型；在一個不會聽指令的模型上做 DPO 沒有意義。
- **偏好資料的來源要和目標模型對得上**。用別的模型產生的偏好資料（off-policy）效果會打折。
- **要監控絕對 log-prob，不只是 margin**（見上）。
- **評估不能只看偏好勝率**。要同時跑能力評估——DPO 調過頭會傷害通用能力（見 [[災難性遺忘]]）。
- **DPO 不會讓模型變聰明**。它調整偏好分布，不增加能力。要提升推理能力請看 [[GRPO 與 RLVR]]。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開，尚未實際套用。

## 🔗 相關
- [[RLHF 全流程]] —— DPO 推導的起點
- [[GRPO 與 RLVR]] —— 另一條簡化路線，以及 online RL 真正不可取代的場景
- [[LoRA 與 QLoRA]] —— DPO 常配 LoRA 一起做
- [[GPU 記憶體估算]] —— 2 個模型 vs 4 個模型的差距
- [[工具-偏好對齊方法選擇]] —— 決策層
- [[工具-LLM微調實作路線]] —— 上游 SFT
