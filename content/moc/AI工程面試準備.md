---
type: moc
title: "AI 工程面試準備"
tags: [moc, ai, llm, interview, engineering, reference]
---

> 型錄入口：**AI 工程的核心概念逐項展開**，詳解在 `reference/AI工程面試題/`。
> 來源是 [[AI 工程面試題庫（公司別）]]（35 家公司 602 題）—— 但**原始來源只有題目沒有答案**，
> 所以這裡的每一頁都是**自己講完整個機制**：有公式、有推導、有失效模式，**不點任何外連就該讀得懂**。
>
> **和 [[moc/AI工程|AI 工程]] 的分工**：
> - `moc/AI工程` 的工具卡＝**決策層**（「該不該用、選哪個」）
> - 這裡的 reference＝**機制層**（「它到底怎麼運作、公式長怎樣、什麼時候壞掉」）
> 兩層互相連結，不重抄。

## 📖 型錄

### 🧠 A. LLM 內部與架構

從 token 進去到機率出來，模型裡發生了什麼。

- [[前向傳播全流程]] — ★ **先讀這篇**。逐個張量追完一次 forward，順便驗算 Llama-2-7B 的 6.74B 參數是怎麼湊出來的。其他頁都是它的展開。
- [[注意力機制]] — $\text{softmax}(QK^\top/\sqrt{d_k})V$。為什麼是 $\sqrt{d_k}$（推導）、causal mask 怎麼寫、MHA → MQA → GQA → MLA 各省了什麼。
- [[KV Cache]] — **記憶體公式的完整推導**與 70B 的實際算帳。為什麼它是服務成本的變動成本。
- [[FlashAttention]] — 「不減 FLOPs 為什麼更快」的標準答案：算術強度、online softmax 的數學、tiling 與重算。
- [[分詞與 BPE]] — 訓練與編碼的完整實作。**中文為什麼特別燒 token**、模型為什麼不會數字母、prompt 結尾別留空白。
- [[位置編碼與 RoPE]] — 旋轉為什麼會變成相對位置（推導）。**Position Interpolation / NTK / YaRN 三種撐長上下文的手法**，以及 lost-in-the-middle 的七個對策。
- [[混合專家 MoE]] — 「8x7B 為什麼不是 56B」、負載平衡的四種解法，以及 **MoE 省計算但不省顯存**這個關鍵代價。
- [[正規化與激活函式]] — Pre-LN 為什麼取代 Post-LN、RMSNorm 拿掉了什麼、SwiGLU 為什麼有三個矩陣、`intermediate_size: 11008` 這個數字哪來的。
- [[取樣與解碼策略]] — greedy / beam / top-k / top-p / min-p 各自的失效模式，含可直接用的實作與兩個經典 bug。**以及 `temperature=0` 為什麼不保證可重現。**
- [[Scaling Laws 與 Chinchilla]] — Kaplan 與 Chinchilla 差在哪、為什麼今天大家又不照 Chinchilla 做，以及 scaling law 怎麼影響**安全評估**。

### ⚡ B. 推論、服務與 GPU 效能

> 這一區是 AI 工程最「工程」的部分，**也是成本的全部來源**。

- [[Prefill 與 Decode]] — ★ **B 區的地基**。為什麼一個 compute-bound 一個 memory-bound（算術強度推導）、H100 的 roofline 實算、TTFT/TPOT/ITL/throughput 怎麼取捨。
- [[連續批次 Continuous Batching]] — 靜態批次在 LLM 上為什麼特別糟（44% 利用率的算式）、iteration-level 排程怎麼做。
- [[PagedAttention 與 vLLM]] — 把作業系統的分頁搬到 GPU。**浪費從 ~70% 降到 <4%** 的機制，以及 COW 共享與前綴快取的由來。
- [[前綴快取 Prompt Caching]] — 省錢又省延遲且無損。**什麼會讓快取失效**（Anthropic 官方失效表，2026-09-20 查證）與那個「時間戳放錯位置」的經典坑。
- [[推測解碼 Speculative Decoding]] — 為什麼品質**數學上**完全不變（rejection sampling 的證明），以及**高 batch 下為什麼反而更慢**。
- [[量化 Quantization]] — FP16/BF16/FP8/INT8/INT4/FP4 **逐級會壞掉什麼**。為什麼訓練用 BF16、離群值為什麼讓激活難量化、weight-only 為什麼只加速 decode。
- [[平行化策略]] — DP / TP / PP / SP / EP 五種切法的通訊量對照、**TP 為什麼不能跨節點**、pipeline 氣泡怎麼算、怎麼組合成 3D。
- [[GPU 記憶體估算]] — ★ **含速查表**。服務 70B 要幾張卡、全量微調 7B 的 **16 bytes/param**、LoRA 省了哪一塊（**不省啟動值**）。
- [[服務棧選型與降本]] — vLLM/SGLang/TensorRT-LLM 怎麼選、**降本十倍的槓桿排序**、chunked prefill 與 PD 分離、**p99 突然變兩倍的七步診斷手冊**。

### 🔎 C–I 區（規劃中）
RAG 與檢索 ‧ Agent 與工具使用 ‧ 微調與對齊 ‧ 評估與可觀測性 ‧ 安全 ‧ 多模態與語音 ‧ 系統設計與 Coding
→ 題目清單見 [[AI 工程面試題庫（公司別）]]

## 🧭 怎麼用這份型錄

- **想搞懂一個名詞** → 直接搜。每頁都自足，不用先讀前面。
- **想建立全貌** → [[前向傳播全流程]] → [[Prefill 與 Decode]]，這兩篇是兩區的入口。
- **要做容量規劃 / 估成本** → [[GPU 記憶體估算]] 的速查表 + [[服務棧選型與降本]] 的槓桿排序。
- **線上出事** → [[服務棧選型與降本]] 的 p99 七步診斷。
- **真的要面試** → 先掃 [[AI 工程面試題庫（公司別）]] 的公司考點地圖，確認你面的是哪一種「AI 工程師」，再回來挑對應區。

## ⚠️ 這份型錄的可信度邊界
- **來源只給題目，答案是我寫的**。可推導的都附了推導（參數量、記憶體公式、roofline、氣泡率），**請自己驗算**。
- **論文結論標了出處**，廠商數字標了「論文/廠商自報、特定設定」。
- **版本敏感的東西會過期**：框架效能排名、硬體規格、API 價格與 TTL。各頁都標了查證日期。
- 硬體數字以 **H100 SXM** 為基準（bf16 ~989 TFLOP/s、HBM3 ~3.35 TB/s），你的卡要自己查。

## 🔗 相關
- [[moc/AI工程|AI 工程]] — 決策層工具卡
- [[moc/軟體工程|軟體工程]] — 通用工程紀律
- [[AI 工程面試題庫（公司別）]] — 來源與 35 家公司考點地圖
