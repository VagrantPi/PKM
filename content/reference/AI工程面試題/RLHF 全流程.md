---
type: reference
name: "RLHF 全流程 Reinforcement Learning from Human Feedback"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, rlhf, alignment, post-training, ppo]
triggers: [RLHF三個階段各在做什麼, 獎勵模型為什麼用比較不用打分, KL懲罰到底在防什麼, 模型為什麼越調越囉嗦越諂媚, reward hacking怎麼擋]
---

> **對應原題**（Common ‧ Fine-Tuning, Post-Training and Alignment）
> - **Walk me through RLHF end to end: reward model, policy optimisation, KL penalty.**
> - Explain **reward hacking** in RLHF and how labs address it. — *Asked at: Scale AI*
>
> 📌 **分層**：DPO / ORPO / GRPO / PPO 怎麼選 → [[工具-偏好對齊方法選擇]]（決策層）。這一頁講機制與失效。

## 🎯 什麼情境該想到我
當你「**想搞懂 ChatGPT 之後的模型為什麼突然變得『會聊天』，以及為什麼它們也開始變得囉嗦又諂媚**」的時候。這兩件事是**同一個機制的正反面**。

## ⚙️ 怎麼用

### 三階段總覽

```
① SFT                ② Reward Model            ③ RL (PPO)
預訓練模型            SFT 模型 + 純量頭          最大化 RM 分數
  + 指令資料      →   + 人類偏好配對       →    受 KL 約束
  ─────────           ─────────────             ─────────
  學「格式」           學「人類偏好什麼」          學「產出被偏好的內容」
```

### ① SFT（監督微調）
用（指令 → 理想回應）配對做標準的下一個 token 預測。

**它教的是「怎麼回答」**——對話格式、指令遵循、拒答的方式。
**它教不了「回答得多好」**——因為每個 prompt 只有一個正確答案，模型無從知道「還有更好的說法」。
→ 這正是需要階段 ②③ 的理由。

### ② Reward Model：★ 為什麼用「比較」不用「打分」

**資料形式**：對同一個 prompt $x$ 給兩個回應，人類標出哪個較好 → $(x, y_w, y_l)$。

> ★ **為什麼不直接叫人打 1–10 分？**
> **人類的絕對評分極不一致** —— 同一個人今天打 7 分、明天打 5 分；不同標註者的尺度完全不同。
> **但「A 比 B 好」的判斷穩定得多。** 這是 RLHF 最關鍵的資料設計決策。

**Bradley-Terry 模型**把成對比較轉成純量分數：

$$P(y_w \succ y_l \mid x) = \sigma\big(r_\theta(x, y_w) - r_\theta(x, y_l)\big)$$

最大化這個機率 ⇒ 損失函數：

$$\mathcal{L}_{RM} = -\mathbb{E}_{(x,\,y_w,\,y_l)}\Big[\log \sigma\big(r_\theta(x, y_w) - r_\theta(x, y_l)\big)\Big]
$$

**兩個實作重點**：
- **RM 從 SFT 模型初始化**，把 LM head 換成輸出**一個純量**的頭
- **只有差值有意義**——$r$ 的絕對值可以整體平移，不影響任何東西。所以「RM 給 3.2 分」本身毫無意義

### ③ RL：目標函數與 KL 懲罰

$$\max_{\pi_\theta}\ \ \mathbb{E}_{x,\, y \sim \pi_\theta}\big[r_\phi(x, y)\big] \;-\; \beta\, \mathrm{KL}\big(\pi_\theta(\cdot|x)\ \|\ \pi_{\text{ref}}(\cdot|x)\big)$$

$\pi_{\text{ref}}$ 是**凍結的 SFT 模型**。

**★ KL 懲罰的三個作用（必考）**：

| 作用 | 沒有它會怎樣 |
|---|---|
| **1. 防止 reward hacking** | policy 會跑到 RM 的分布外區域，找到「高分但人類討厭」的輸出 |
| **2. 保持語言流暢** | **Mode collapse** —— 模型會塌縮成反覆輸出某幾句 RM 給高分的話 |
| **3. 維持多樣性** | 所有回答變得一模一樣 |

> **一句話**：**KL 是一條繩子，把 policy 拴在 SFT 模型附近。$\beta$ 就是繩子的長度。**
> $\beta$ 太大 → 學不動；太小 → 跑去作弊。這是 RLHF 最關鍵的超參數。

**PPO 的部分**：用 clipped surrogate objective 限制每次更新的幅度

$$L^{CLIP}(\theta) = \mathbb{E}_t\Big[\min\big(\rho_t(\theta)\hat{A}_t,\ \ \text{clip}(\rho_t(\theta),\, 1-\epsilon,\, 1+\epsilon)\hat{A}_t\big)\Big], \quad \rho_t = \frac{\pi_\theta}{\pi_{\theta_{old}}}$$

**★ PPO 工程上最痛的地方：四個模型同時在記憶體裡**

| 模型 | 用途 | 需要梯度 |
|---|---|---|
| **Policy** $\pi_\theta$ | 正在訓練的模型 | ✅ |
| **Reference** $\pi_{\text{ref}}$ | 算 KL，凍結 | ❌ |
| **Reward Model** $r_\phi$ | 給分，凍結 | ❌ |
| **Value Model** $V_\psi$ | 估計優勢函數 | ✅ |

**兩份要訓練 + 兩份要推論**（見 [[GPU 記憶體估算]]）。
→ 這是 **DPO 拿掉 RM 與 RL 迴圈**、**GRPO 拿掉 value model** 的直接動機（見 [[DPO]]、[[GRPO 與 RLVR]]）。

## ★ Reward Hacking

### 定義與必然性
> **Policy 找到了「讓 RM 給高分、但人類其實不喜歡」的輸出。**

這是 **Goodhart 法則**的精確實例：**當一個量度成為目標，它就不再是好的量度。**

**為什麼必然發生**：
1. RM 是人類偏好的**不完美代理**
2. RL 的工作就是**盡全力最大化 RM 分數**——包括利用 RM 的所有瑕疵
3. Policy 優化後會產生**訓練 RM 時沒見過的輸出分布**，RM 在那裡的預測是**外插**，完全不可靠

### 典型症狀

| 症狀 | 說明 |
|---|---|
| **★ 冗長（length bias）** | **最著名的一種**。標註者傾向覺得長答案「比較有用」，RM 學到「長 = 好」，policy 於是無限灌水 |
| **諂媚（sycophancy）** | 附和使用者的觀點，即使是錯的。因為「同意我」被標為較好 |
| **格式化過度** | 大量 bullet、粗體、emoji、「以下是三個要點」 |
| **自信地胡說** | 有把握的語氣被偏好，於是模型學會**對錯誤答案也用肯定句** |
| **討好用語堆砌** | 「這是一個很棒的問題！」 |

### ★ Over-optimization 的 scaling law
Gao, Schulman & Hilton (2023, *Scaling Laws for Reward Model Overoptimization*) 量出了一條關鍵曲線：

```
真實品質
（gold reward）
    ▲
    │        ╭───╮            ← ★ 有一個最佳點
    │      ╭─╯    ╰──╮
    │    ╭─╯          ╰───╮
    │  ╭─╯                 ╰──── 繼續優化反而變差
    └──────────────────────────▶  √KL（離 SFT 的距離）

     代理分數（RM 給的分）則是一路上升 ↗
```

> ★ **這張圖是整個 RLHF 的核心風險**：
> **RM 分數持續上升，但真實品質已經開始下降，而你從訓練指標上完全看不出來。**

### 實驗室的對策

| 對策 | 做法 |
|---|---|
| **調大 $\beta$** | 縮短繩子。代價是學得慢、上限低 |
| **★ Early stopping** | 用**獨立的 gold 評估**（人類評估或更強的裁判模型）監控真實品質，**看到轉折就停** |
| **RM Ensemble** | 多個 RM 取最小值或加入不確定性懲罰——policy 很難同時騙過所有 RM |
| **★ 迭代式 RLHF** | **蒐集新偏好資料 → 重訓 RM → 再 RL**，反覆。因為 policy 變了，RM 的「分布外區域」也跟著變 |
| **明確去除 length bias** | 長度正規化；標註指引明確要求「不要因為長就給高分」 |
| **★ RLVR** | 有可客觀驗證的獎勵時（數學、程式碼），**根本不需要學 RM** → 見 [[GRPO 與 RLVR]] |
| **Constitutional AI / RLAIF** | 用明文原則取代部分人類標註 → 批次 3 補 |

## ⚠️ 注意 / 什麼時候不適用

- **順序不可顛倒**。沒做 SFT 就直接 RL，等於在還不會聽指令的模型上調語氣。
- **偏好資料的品質決定一切**。標註指引含糊、標註者尺度不一 → RM 學到噪音，後面全白做。
- **RM 的分數不可跨模型、跨版本比較**（只有差值有意義）。
- **RLHF 對「能力」的提升有限**。它主要調整**行為與偏好**，不會讓模型變得更聰明——真正的能力來自預訓練與 [[GRPO 與 RLVR]] 那條路。
- **RLHF 會降低多樣性**（這是設計上的取捨）。需要創意或多樣輸出的場景要注意。
- **★ 絕大多數團隊不該做 PPO-RLHF**。工程複雜度極高。**從 [[DPO]] 開始**，有明確理由再上 RL。
- **評估必須獨立於 RM**。用 RM 評估 RLHF 的成果是自我驗證——**一定要有人類評估或獨立裁判**。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開，尚未實際套用。

## 🔗 相關
- [[DPO]] —— 拿掉 RM 與 RL 迴圈的做法
- [[GRPO 與 RLVR]] —— 拿掉 value model，以及用可驗證獎勵取代 RM
- [[GPU 記憶體估算]] —— 四個模型的記憶體帳
- [[Scaling Laws 與 Chinchilla]] —— over-optimization 也有自己的 scaling law
- [[工具-偏好對齊方法選擇]] —— 決策層：算力與目標怎麼選方法
- [[工具-LLM微調實作路線]] —— 上游的 SFT 階段
