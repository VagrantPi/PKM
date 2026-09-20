---
type: reference
name: "分頁注意力 PagedAttention"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, inference, serving, memory, vllm]
triggers: [KV cache記憶體為什麼浪費這麼多, 顯存還很多卻說裝不下, vLLM到底做了什麼, 同一個system prompt能不能共用, 作業系統的分頁怎麼用在GPU上]
---

> **對應原題**（Common ‧ Inference, Serving and GPU Performance）
> - How does **PagedAttention** work, and what problem of **KV-cache fragmentation** does it solve?
>   — *Asked at: NVIDIA, Together AI*
> - How does vLLM work?
>
> 論文：Kwon et al., *Efficient Memory Management for Large Language Model Serving with PagedAttention* (SOSP 2023)。

## 🎯 什麼情境該想到我
當你「**顯存明明還有一大半，服務卻說塞不下更多請求**」的時候。這是一個**把作業系統六十年前的老招式搬到 GPU 上**的漂亮案例——而且效果大到重寫了整個產業的服務棧。

## ⚙️ 怎麼用（機制）

### 問題：KV cache 的配置方式爛透了

傳統做法（HuggingFace `generate`、FasterTransformer 早期版本）：
**每個請求一開始就配一塊連續的顯存，大小 = `max_seq_len`。**

因為你不知道它會生成多長，只好照最壞情況預留。結果：

```
請求 A（max_seq_len = 2048，實際只用 300）
┌──────────┬────────────────────────────────────────┐
│ 已用 300 │  預留但永遠用不到的 1748 格             │  ← 浪費
└──────────┴────────────────────────────────────────┘
```

三種浪費：

| 種類 | 說明 |
|---|---|
| **內部碎片**（internal） | 預留了 2048 但只生成 300 —— **剩下的 85% 永遠浪費** |
| **預留浪費**（reservation） | 未來可能用到，但**現在**閒置 —— 這段時間不能給別人 |
| **外部碎片**（external） | 不同請求要求不同大小的連續區塊，之間卡出用不了的空隙 |

> ★ **vLLM 論文的量測**：當時主流系統中，**只有 20.4%–38.2% 的 KV cache 記憶體真正裝著 token**。
> 也就是**六到八成的顯存在空轉**——而顯存正是限制併發的唯一資源（見 [[KV Cache]]）。

### ★ 解法：照抄作業系統的虛擬記憶體分頁

這個對應關係要能背出來，面試就答完一半了：

| 作業系統 | PagedAttention |
|---|---|
| 行程（process） | 一個請求 / 序列 |
| 虛擬記憶體頁 | **邏輯 KV block** |
| 實體記憶體頁框 | **實體 KV block** |
| 頁表（page table） | **block table** |
| 頁大小 4 KB | **block 大小 = 16 個 token**（可調） |
| 寫時複製 COW | **block 的 copy-on-write** |
| 換頁到磁碟 | **swap 到 CPU 記憶體** |

**核心改變：KV cache 不需要連續。**

```
序列 A 的邏輯視圖        block table          GPU 實體顯存
┌────┬────┬────┐        ┌───┬───┐           ┌──────┐ #0  ← 序列 B
│ b0 │ b1 │ b2 │  ───▶  │b0 │ #3│      ┌───▶│      │ #1  ← 序列 A.b1
└────┴────┴────┘        │b1 │ #1│      │    ├──────┤ #2  ← 序列 C
 token 0-15,16-31,...   │b2 │ #7│──┐   │    ├──────┤ #3  ← 序列 A.b0
                        └───┴───┘  │   └────┤      │ #4  ← free
                                   └───────▶│      │ #7  ← 序列 A.b2
```

**需要時才配一個 block**（每 16 個 token 配一次），用完就還。

**浪費降到只剩「最後一個 block 沒填滿的部分」——平均 8 個 token 的空位，論文量到 **< 4%**。**

### PagedAttention kernel
Attention 原本假設 K、V 在記憶體中連續。改成分頁後，kernel 必須：
1. 查 block table 找出這個序列的每個 block 在哪
2. **逐 block 載入**，在各自的 block 內算 attention
3. 跨 block 合併結果（用和 [[FlashAttention]] 同樣的 online softmax 技巧）

非連續存取會損失一點記憶體效率，但**換來的併發提升遠大於損失**。

### ★ 額外紅利一：Copy-on-Write 共享

同一個 prompt 要生成多個候選（parallel sampling、best-of-n、beam search）時：

```
prompt 的 block 只存一份，n 個序列的 block table 都指向它（refcount = n）
         ↓
某個序列要寫入時 → 複製那一個 block，改自己的 table（COW）
```

**prompt 越長，省越多。** 論文報告 parallel sampling 與 beam search 的記憶體節省最高達 55%。

### ★ 額外紅利二：自動前綴快取（APC）

既然 block 可以共享，那**不同請求之間**共用相同前綴的 block 也行：

```
請求 1: [長長的 system prompt][使用者問題 A]
請求 2: [長長的 system prompt][使用者問題 B]
              ▲
        這段的 KV block 直接重用，prefill 不用重算
```

用 block 內容的 hash 當 key 做查表。對 system prompt 很長、few-shot 很多的應用，**TTFT 可以掉一個數量級**。
→ 這就是 [[前綴快取 Prompt Caching]] 的底層機制。

### 效果
vLLM 論文：在相同延遲下，吞吐量是當時 SOTA（FasterTransformer、Orca）的 **2–4×**。

機制很直白：**浪費從 ~70% 降到 <4% → 同樣顯存能裝更多序列 → batch 更大 → 算術強度更高 → 吞吐更高**（見 [[Prefill 與 Decode]]）。

### vLLM 的整體樣貌
```
請求 ─▶ Scheduler（連續批次：waiting / running / swapped 三佇列）
         │
         ├─▶ BlockManager（配置、釋放、COW、前綴快取查表）
         │
         └─▶ Worker（模型執行）
                └─▶ PagedAttention kernel + FlashAttention
```
**PagedAttention 是顯存層，連續批次是排程層——兩者缺一不可。**

## ⚠️ 注意 / 什麼時候不適用

- **block size 要調**。太小 → block table 大、kernel 開銷高；太大 → 內部碎片回來。vLLM 預設 16，長序列場景有時 32 更好。**要量，不要猜。**
- **前綴快取不是免費的**。hash 計算與查表有開銷；**前綴不重複的流量會純虧**。vLLM 需要顯式開啟（`--enable-prefix-caching`）是有原因的。
- **`gpu_memory_utilization` 設太高會 OOM**。它是「權重之外 vLLM 可用的比例」，還要留啟動值與 CUDA context 的空間。0.9 通常是上限。
- **preemption 仍然會發生**。分頁減少浪費，但沒有變出顯存。**看到 log 裡大量 preemption 就是該加卡或降 `max_num_seqs` 的訊號**——這是 p99 惡化最常見的根因。
- **這是服務層優化，不改變模型**。品質完全不變，也不會讓單一請求更快（batch 1 沒有增益）。
- **TensorRT-LLM 有等價機制**（paged KV cache），不是 vLLM 獨有。選型見 [[服務棧選型與降本]]。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開，尚未實際套用。

## 🔗 相關
- [[KV Cache]] —— 被管理的那個東西
- [[連續批次 Continuous Batching]] —— 排程層的另一半，兩者配套
- [[前綴快取 Prompt Caching]] —— 建立在 block 共享之上
- [[Prefill 與 Decode]] —— 為什麼省顯存就等於省錢
- [[服務棧選型與降本]] —— 各框架怎麼選
