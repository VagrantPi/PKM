---
type: reference
name: "GPU 記憶體估算 Memory Budgeting"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, gpu, memory, training, inference, capacity-planning]
triggers: [這個模型要幾張卡, 微調7B要多少顯存, 為什麼訓練比推論貴這麼多, LoRA到底省了哪一塊, 一直OOM但算起來應該夠]
---

> **對應原題**（Common ‧ Inference / Fine-Tuning）
> - **Estimate the GPU memory needed to serve a 70B model**: weights, KV cache, activations, fragmentation. — *Asked at: NVIDIA*
> - **Do the GPU memory maths for full fine-tuning a 7B model in bf16 with Adam. Now with LoRA.**
>   — *Asked at: Mistral AI, Hugging Face*

## 🎯 什麼情境該想到我
當你「**要回答『這需要幾張卡』或一直莫名 OOM**」的時候。這是 AI 工程最常被要求**現場心算**的一題——**記住幾個 bytes/param 的常數就能秒答。**

## ⚙️ 怎麼用（兩本帳）

## 一、服務（推論）的帳

### 公式
$$\text{總顯存} = \underbrace{P \cdot b_w}_{\text{權重}} + \underbrace{\text{KV cache}}_{\text{隨流量成長}} + \underbrace{\text{啟動值}}_{\text{prefill 才大}} + \underbrace{\text{框架開銷}}_{\text{2–4 GB/卡}}$$

| 項目 | 怎麼算 | 特性 |
|---|---|---|
| **權重** | 參數量 × 每參數位元組 | **固定** |
| **KV cache** | $2 \cdot L \cdot N \cdot h_{kv} \cdot d_{head} \cdot p \cdot B$ | **隨併發 × 上下文線性成長** |
| **啟動值** | decode 可忽略；**prefill 時與 $N$ 成正比** | 尖峰 |
| **框架 / CUDA context** | 每張卡 2–4 GB | 固定 |
| **碎片化** | 傳統配置浪費 60–80%；PagedAttention 後 <4% | 見 [[PagedAttention 與 vLLM]] |

### ★ 實算：服務 Llama-2-70B

| 精度 | 權重 | 能否裝進 2×H100 (160GB) | 剩給 KV |
|---|---|---|---|
| **bf16** | 140 GB | 勉強 | **~14 GB → 約 11 條 4K 序列** |
| **FP8 / INT8** | 70 GB | 舒服 | **~84 GB → 約 67 條** |
| **INT4** | 35 GB | 很寬裕 | **~119 GB → 約 95 條** |

*(KV 用 [[KV Cache]] 算出的 1.25 GiB / 4K 序列；已扣 ~3 GB/卡 的框架開銷。)*

> ★ **這張表就是「量化為什麼是降本第一槓桿」的完整答案**：
> INT8 不只省一半權重，**它把可服務的併發提高了 6 倍**——因為省下的顯存全部變成 KV cache。
> 成本是「每 token 成本」，而每 token 成本 ∝ 1/併發。**降本 6× 不是 2×。**

## 二、訓練 / 微調的帳（★ 這題更常考）

### 全量微調：記住 **16 bytes/param**

bf16 混合精度 + Adam 的完整清單：

| 項目 | 精度 | bytes/param | 為什麼需要 |
|---|---|---|---|
| 模型權重 | bf16 | **2** | 前向/反向用 |
| 梯度 | bf16 | **2** | 反向產物 |
| **Adam 一階動量 $m$** | fp32 | **4** | 優化器狀態 |
| **Adam 二階動量 $v$** | fp32 | **4** | 優化器狀態 |
| **FP32 主權重** | fp32 | **4** | ⭐ 混合精度必需——bf16 只有 7 bit 尾數，小的更新量會被**直接吃掉**（見 [[量化 Quantization]]） |
| **合計** | | **16** | |

### ★ 實算：全量微調 Llama-2-7B（bf16 + Adam）

```
7B × 16 bytes = 112 GB        ← 還沒算啟動值！
```

**一張 H100 (80 GB) 裝不下。** 而且這只是「靜態」部分。

**加上啟動值**（開 gradient checkpointing，只存每層輸入）：
$$L \times s \times b \times h \times 2\ \text{bytes}$$
$$32 \times 2048 \times 8 \times 4096 \times 2 = \mathbf{4\ GiB}$$

（$L=32$ 層、序列 2048、batch 8、$h=4096$）

**不開 checkpointing 的話大約是這個的一個數量級以上**——因為每層內部的 attention 分數、FFN 中間值全都要留著。實際倍數依實作而異，**要量不要猜**。

**總計 ≈ 116 GB** → 需要 **2 張 H100** 並且用 ZeRO-2/3 或 FSDP 分片。

> **對照推論**：同一個 7B，推論只要 14 GB。**訓練貴 8 倍**——這個倍數就是「為什麼大家做 LoRA 不做全量」的全部原因。

### LoRA 的帳

LoRA 凍結底座，只訓練低秩旁路 $\Delta W = BA$（見 **LoRA 與 QLoRA**（本庫尚未建立，批次 2／3 補））：

| 項目 | 大小 |
|---|---|
| 底座權重（**凍結**，bf16） | 14 GB |
| LoRA 參數（$r=16$，套 q/v 投影，約 8M 參數） | 0.016 GB |
| LoRA 的梯度 + Adam 狀態（8M × 14 bytes） | **0.11 GB** |
| **★ 啟動值** | **4 GB（和全量微調一樣多！）** |
| **合計** | **≈ 18 GB** |

**從 116 GB 降到 18 GB，一張 A100/H100 輕鬆放下。**

> ★ **最常被誤解的一點**：**LoRA 不省啟動值記憶體。**
> 因為梯度仍然要**反向傳播穿過整個網路**才能到達 LoRA 層——只是不更新底座權重而已。
> 省的是「梯度 + 優化器狀態 + fp32 主權重」這 14 bytes/param，**不是計算圖**。
>
> → 推論：**LoRA 主要省的是「優化器記憶體」，不是「前向/反向計算」。訓練速度只快一點點（約 20–30%），記憶體卻省 85%。**

### QLoRA 的帳
底座量化成 4-bit（NF4）：

```
底座 4-bit:        3.5 GB
LoRA + 優化器:     0.13 GB
啟動值:            4 GB
反量化暫存等:      ~1 GB
─────────────────────────
合計 ≈ 9 GB      →  一張 24 GB 消費級顯卡可行
```

### 📌 速查表（面試心算用）

| 情境 | bytes/param | 7B | 70B |
|---|---|---|---|
| **推論 bf16** | 2 | 14 GB | 140 GB |
| **推論 INT8** | 1 | 7 GB | 70 GB |
| **推論 INT4** | 0.5 | 3.5 GB | 35 GB |
| **全量微調（bf16+Adam）** | **16** | **112 GB** | 1.1 TB |
| 全量微調 + ZeRO-3（$N$ 卡） | 16/N + 2 | — | — |
| **LoRA（bf16 底座）** | ~2.2 | ~16 GB | ~155 GB |
| **QLoRA（4-bit 底座）** | ~0.7 | ~6 GB | ~48 GB |
| **推論 fp32** | 4 | 28 GB | 280 GB |

（**全部還要加上啟動值與 2–4 GB/卡 的框架開銷。**）

## ⚠️ 注意 / 什麼時候不適用

- **「算起來夠」但 OOM 的三大原因**：
  1. **啟動值的尖峰**——prefill 或長序列那一瞬間
  2. **碎片化**——PyTorch 的 caching allocator 會留下用不到的空洞。`PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True` 常有幫助
  3. **忘了框架開銷**——CUDA context、NCCL buffer、編譯快取加起來好幾 GB
- **`nvidia-smi` 顯示的用量會虛高**。PyTorch 的 allocator 不會馬上還給系統。要看真實用量用 `torch.cuda.memory_allocated()`。
- **ZeRO-3 / FSDP 的記憶體不是乾淨地除以 N**。通訊 buffer 與 all-gather 的暫存都要算。
- **梯度累積不省啟動值的尖峰**，它省的是 batch 那一維——能降尖峰，但每個 microbatch 的啟動值還是要存。
- **MoE 的推論要裝全部專家**，不能只算激活參數（見 [[混合專家 MoE]]）。
- **KV cache 的成長沒有上界**。容量規劃要按**最壞情況的併發 × 上下文**算，不是平均。
- **這些是估算，不是保證**。上線前跑一次真實負載的壓測，留 15–20% 餘裕。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開。**待辦：把速查表印出來或存成 snippet。**

## 🔗 相關
- [[KV Cache]] —— 推論記憶體的變動部分
- [[量化 Quantization]] —— 直接改變 bytes/param
- **LoRA 與 QLoRA**（本庫尚未建立，批次 2／3 補） —— 微調記憶體的主要解法
- [[平行化策略]] —— 裝不下時怎麼切
- [[PagedAttention 與 vLLM]] —— 消除碎片化浪費
- [[Prefill 與 Decode]] —— 顯存 → 併發 → 成本的因果鏈
