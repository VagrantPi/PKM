---
type: article
title: "Introducing Contextual Retrieval（Anthropic 研究文章）"
source_url: https://www.anthropic.com/research/contextual-retrieval
author: Anthropic
site: anthropic.com
tags: [ai, llm, rag, retrieval, embedding, search]
captured: 2026-11-02
read_status: read
---

## 📌 30 秒摘要
> 這篇在講（2024-09-19 發布）：傳統 RAG 把文件切塊後，片段會失去脈絡。例如「營收比上季成長 3%」，看不出是哪家公司、哪一季，於是檢索不到。
> 解法是 **Contextual Retrieval**：先用 LLM 替每一段寫 50–100 token 的「這段在整份文件的哪裡」，接在片段前面，**再**做 embedding 和建 BM25 索引。
> 在他們的測試資料上，前 20 段裡漏掉相關資料的比例：
> - 加了脈絡的 embedding：5.7% → 3.7%（−35%）；
> - 再加 BM25：→ 2.9%（−49%）；
> - 再加重排：→ 1.9%（−67%）。

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- 這是庫裡多張 RAG 卡引用的原始出處。之前是透過掘金轉述查證的，這次直接收原文。
- 要做 RAG 時，照它的順序疊：BM25＋向量混合 → 加脈絡 → 重排 → 放 20 段。每一步都有它量過的增益可以參考。
- 它的「知識庫小於 20 萬 token 就直接整包放進 prompt」是動工前的第一個判斷。

## 🧰 這篇給我的工具
- 不另建工具卡。這篇的每個環節，庫裡都已經有對應的卡，這次把原文細節補進去：
  - [[切塊與文件解析]] — 補了產生脈絡的 prompt、脈絡長度、試過但沒效的做法、成本試算
  - [[工具-RAG檢索增強生成]] — 「需不需要 RAG」的 20 萬 token 分界
  - [[稀疏與密集檢索]] — BM25 與向量混合、用 rank fusion 合併結果
  - [[Reranker 重排序]] — 先撈 150、重排後取 20

## ✨ 關鍵重點
- **為什麼要 BM25**：embedding 擅長語意，但會漏掉精確字串。原文的例子是查「Error code TS-999」：向量檢索找到一堆講錯誤碼的文件，BM25 才能對到 TS-999。
- **脈絡要同時進兩種索引**：接上脈絡的文字，既拿去 embed，也拿去建 BM25。只做一邊就少了一半的增益（−35% 對 −49%）。
- **產生脈絡的 prompt**很短：整份文件放進 `<DOCUMENT>`、片段放進 `<CHUNK>`，要求只回答一段簡潔的脈絡，用來改善這段的檢索。
- **成本靠 prompt caching**：同一份文件的每一段都要呼叫一次 LLM，但文件可以放進快取，只寫一次。原文估算一次性成本是每百萬文件 token $1.02（Claude 3 Haiku，2024 年價格）。用現行價格重算見 [[切塊與文件解析]]。
- **他們試過、效果有限的做法**：每段加整份文件的通用摘要、HyDE、以摘要建索引。
- **結論的六點**：
  - Embedding＋BM25 比單用 embedding 好；
  - Voyage 與 Gemini 的 embedding 最好；
  - 放 20 段比 10 段、5 段好；
  - 加脈絡大幅提升準確率；
  - 有重排比沒重排好；
  - 以上全部可以疊加。
- **注意**：這些數字是 Anthropic 在自己選的資料集上量的（程式碼庫、小說、arXiv 論文、科學論文），指標是 1 − recall@20。方向可信，幅度要在自己的資料上重新量。

## 💬 原文摘錄
- "If your knowledge base is smaller than 200,000 tokens (about 500 pages of material), you can just include the entire knowledge base in the prompt that you give the model, with no need for RAG or similar methods."
- "Contextual Retrieval solves this problem by prepending chunk-specific explanatory context to each chunk before embedding ('Contextual Embeddings') and creating the BM25 index ('Contextual BM25')."

## 🔗 相關
- [[Claude Cookbooks]] —— 原文說可以用 cookbook 實作；cookbook 的 `capabilities/` 裡有「Enhancing RAG with contextual retrieval」這篇 notebook
- [[前綴快取 Prompt Caching]] —— 讓「每段都呼叫一次 LLM」的成本壓得下來
