---
type: article
title: "LLM Course 課程文件 mlabonne/llm-course"
source_url: https://deepwiki.com/mlabonne/llm-course
author: Maxime Labonne（DeepWiki 產生的結構化版本）
site: deepwiki.com
tags: [software, ai, llm, fine-tuning, alignment, quantization, rag, agents, security]
captured: 2026-08-01
read_status: read
---

## 📌 30 秒摘要
> 一份把 LLM 從零到上線拆成**三條學習路徑**的地圖：**LLM Fundamentals**（數學／Python／神經網路／NLP，可跳過）、**The LLM Scientist**（架構、預訓練、後訓練資料、SFT、偏好對齊、評估、量化、新趨勢）、**The LLM Engineer**（跑模型、向量儲存、RAG、進階 RAG、Agent、推論最佳化、部署、安全）。24 個理論主題 ＋ 23 本 Colab notebook ＋ 150 多個外部參考，本身不含可執行程式碼，定位是**導航中樞**。

## 🗺 心智圖（Canvas）
![[LLM Course 課程文件.canvas]]

## 🎯 為什麼存這套文件 / 未來想拿它做什麼
- 手上已有《AI工程》的應用層工具卡，但**訓練與部署這一段是空白**——這份文件正好補上 SFT／對齊／量化／推論最佳化。
- 要決定「微調還是 RAG」之後，如果選了微調，需要一條具體可走的實作路線與框架選擇。
- 想在自己機器上跑大模型時，用它的量化對照表估算硬體需求。
- 上線前的安全盤點：它的攻擊面分類比我原本零散的印象完整。

## 🧰 這份文件給我的工具（連到 tools/）
- [[工具-LLM微調實作路線]] — 決定要微調了，但不知道 Full／LoRA／QLoRA 該選哪個時
- [[工具-偏好對齊方法選擇]] — SFT 完成後想調語氣、降毒性、或衝推理表現時
- [[工具-模型量化格式選擇]] — 想把大模型塞進手上硬體、看不懂 Q4_K_M 這種代號時
- [[工具-LLM推論最佳化]] — 模型夠好但太慢太貴、長上下文就爆記憶體時
- [[工具-LLM安全防護]] — LLM 功能要開放給外部輸入、上線前要盤點攻擊面時

## 🗂 文件涵蓋範圍（已收錄 32 頁）
- **總覽**：Overview（倉庫定位與導航模型）、Course Structure（三條路徑與相依關係）、Learning Resources（資源型態）
- **🧩 LLM Fundamentals（選修）**：Mathematics for ML、Python for ML、Neural Networks、Natural Language Processing
- **🧑‍🔬 The LLM Scientist（核心 8 題）**：LLM Architecture、Pre-Training Models、Post-Training Datasets、Supervised Fine-Tuning、Preference Alignment、Evaluation、Quantization、New Trends
- **👷 The LLM Engineer（核心 8 題）**：Running LLMs、Vector Storage、Retrieval Augmented Generation、Advanced RAG、Agents、Inference Optimization、Deployment、Security
- **實務資源**：Automated Tools（LLM AutoEval／LazyMergekit／LazyAxolotl／AutoQuant／Model Family Tree／ZeroSpace／AutoAbliteration／AutoDedup）、Fine-tuning Notebooks、Quantization Notebooks、Advanced Technique Notebooks、External Learning Resources

## ✨ 關鍵重點
- **SFT 只是「重新啟用」預訓練裡已有的知識**，教不了模型全新的領域——想灌新知識該走預訓練或 RAG。這句話直接改寫了我對微調的期待值。
- **資料品質勝過超參數調整**：微調成敗的主要變數在資料集，不在 learning rate。
- **後訓練是有順序的兩段**：先 SFT 讓模型會聽指令，再做偏好對齊調語氣與品質；順序顛倒沒有意義。
- **偏好對齊的四個選項按成本排列**：ORPO（低）→ DPO（低—中）→ GRPO（中—高）→ PPO（高，需獎勵模型）。算力有限就走 DPO／ORPO。
- **量化的品質損失有量級可循**：INT8 約 1–2%、INT4 約 3–5%、INT2 就掉到 10–15%——2-bit 通常已不堪用。
- **推論慢有三種不同的病因**（注意力平方成長／重複計算／逐字生成），分別對應 Flash Attention／KV Cache／Speculative Decoding，不能亂套。
- **提示注入最危險的形態是「間接注入」**——惡意指令藏在 RAG 檢索到的文件裡，使用者根本沒打那句話。
- 這個倉庫**刻意不放可執行程式碼**，價值在於把散落的外部資源組織成有相依關係的學習路徑。

## 💬 原文摘錄
- 「Fine-tuning **reactivates knowledge already present in the base model** rather than teaching entirely new domains.」
- 「**Data quality matters more than hyperparameter tuning** for successful fine-tuning.」
- 「QLoRA **reduces memory usage by up to 33% compared to LoRA**, making it particularly useful when GPU memory is constrained.」
- 「Q4_K_M ... offers the **best quality/size balance** for most use cases.」
- 「Indirect injection: malicious instructions **embedded in retrieved documents**.」
- 「Standard attention mechanisms require **O(N²) memory** relative to sequence length.」

## 🔗 相關
- [[工具-微調與RAG的取捨]]（《AI工程》）——這份文件接在那個決策的「選了微調」分支之後，補上具體怎麼做
- [[工具-AI系統評估]]（《AI工程》）——微調／對齊／量化每一步的成效都得靠評估集驗收，是貫穿全程的驗收關卡
- [[工具-RAG檢索增強生成]]（《AI工程》）——文件的 Engineer 路徑同樣以 RAG 為核心，兩邊可互相對照補完
- [[MCP 官方文件]]——同屬 LLM 應用層的外部文件，MCP 管「怎麼安全接工具」，這份管「模型本身怎麼練與怎麼跑」
