---
type: article
title: "AI 工程面試題庫（公司別）"
source_url: https://github.com/pallavi-shekhar/ai-engineering-interview-questions-company-wise
author: Outcome School（維護者 pallavi-shekhar）
site: GitHub
tags: [ai, llm, interview, career, reference, catalogue]
captured: 2026-09-20
read_status: read
---

## 📌 30 秒摘要
> 這篇在講：**35 家 AI 公司真實被問過的 602 道面試題**，依公司分組、附公開回報的面試流程。
> 它**只有題目沒有答案**（答案是外連到 outcomeschool.com 的文章），所以本知識庫把它的
> **「Common Questions」119 題展開成 19+ 頁自足的概念筆記**，放在 [[moc/AI工程面試準備|AI 工程面試準備]]。

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- **當作 AI 工程知識的完整性檢查表**——不是為了面試，而是「業界認為一個 AI 工程師該知道什麼」的最佳代理指標
- 它的分類（LLM 內部 / 推論服務 / RAG / Agent / 微調對齊 / 評估 / 安全 / 多模態 / 系統設計 / Coding）本身就是一張**領域地圖**
- **公司考點差異**能反映各家的技術重心，選工具、評估供應商時有參考價值

## ⚠️ 這份來源的限制（先講清楚）
| 限制 | 說明 |
|---|---|
| **沒有答案** | 每題下方的 `Answer:` 全是外部連結。**觀念不在這份檔案裡** —— 這正是本庫把它展開的原因 |
| **二手資料** | README 自述題目「compiled from publicly reported interview experiences」，非官方發布 |
| **面試流程會變** | 原文自己警告：把公司章節當作「這家在乎什麼的地圖」，不是「你會被問什麼的腳本」 |
| **是廣告載體** | 維護者是付費課程 Outcome School，答案連結指向自家內容 |
| **規模小** | 撷取時 163 stars、12 forks、8 commits。**不是權威來源，是有用的線索** |
| 授權 | Apache-2.0，Copyright (C) 2026 Outcome School |

## ✨ 關鍵重點

### 題目分布（2026-09-20 撷取）
**總計 602 題**，分兩區。**Common 區 119 題已全數展開成 56 頁機制層筆記**（見 [[moc/AI工程面試準備|AI 工程面試準備]]）：

| 區 | 題數 | 用途 |
|---|---|---|
| **Common Questions Asked Across Companies** | **119** | 跨公司重複出現的**核心概念**——原文建議先做這區 |
| 35 家公司各自的專屬題 | 483 | 公司口味、產品情境、文化題 |

Common 區的十個主題：

| 主題 | 題數 | 本庫展開 |
|---|---|---|
| LLM Internals and Architecture | 16 | ✅ [[注意力機制]]、[[KV Cache]]、[[FlashAttention]]、[[分詞與 BPE]]、[[位置編碼與 RoPE]]、[[混合專家 MoE]]、[[正規化與激活函式]]、[[取樣與解碼策略]]、[[Scaling Laws 與 Chinchilla]]、[[前向傳播全流程]] |
| Inference, Serving and GPU Performance | 14 | ✅ [[Prefill 與 Decode]]、[[連續批次 Continuous Batching]]、[[PagedAttention 與 vLLM]]、[[推測解碼 Speculative Decoding]]、[[前綴快取 Prompt Caching]]、[[量化 Quantization]]、[[平行化策略]]、[[GPU 記憶體估算]]、[[服務棧選型與降本]] |
| RAG and Retrieval | 12 | ✅ [[切塊與文件解析]]、[[稀疏與密集檢索]]、[[Reranker 重排序]]、[[向量索引 ANN]]、[[查詢改寫與 HyDE]]、[[權限感知檢索與引用歸因]]、[[RAG 評估與營運]] |
| Agents and Tool Use | 12 | ✅ [[ReAct 與 Agent Loop]]、[[Function Calling 與結構化輸出]]、[[工具集設計]]、[[Agent 記憶設計]]、[[多 Agent 編排與 Agent Drift]]、[[可逆性、審計與人類把關]] |
| Fine-Tuning, Post-Training and Alignment | 12 | ✅ [[RLHF 全流程]]、[[DPO]]、[[GRPO 與 RLVR]]、[[LoRA 與 QLoRA]]、[[PEFT 方法比較]]、[[災難性遺忘]]、[[知識蒸餾]] |
| Evaluation and Observability | 10 | ✅ [[LLM-as-Judge]]、[[沒有標註時怎麼建評估集]]、[[幻覺偵測]]、[[上線閘門與線上評估]]、[[Benchmark 污染與分數失真]]、[[LLM 可觀測性]]、[[Agent 評估]] |
| Safety, Security and Responsible AI | 10 | ✅ [[提示注入與分層防禦]]、[[OWASP LLM Top 10]]、[[Guardrails 護欄設計]]、[[Constitutional AI 與 RLAIF]]、[[PII、紅隊與公平性稽核]] |
| Multimodal, Speech and Voice AI | 10 | ✅ [[視覺語言模型]]、[[即時語音 Agent]]、[[級聯與原生語音]] |
| AI System Design | 11 | ✅ [[AI 系統設計框架]]（11 題各自的骨架） |
| Coding and Data Structures | 12 | ✅ [[AI 工程 Coding 題型]]（12 題分類 + B 類完整實作） |

### 📊 35 家公司考點地圖

**怎麼讀**：「主要考點」是該公司專屬題中題數最多的三個主題，**能反映他們的技術重心**。

#### 前沿實驗室

| 公司 | 題數 | 主要考點 | 面試流程特色（原文轉述） |
|---|---|---|---|
| **Anthropic** | 37 | Coding 12 ‧ 系統設計 5 ‧ 安全 4 | 招募面談（~30 分，**會刷人**）→ CodeSignal 式編碼（70–90 分，**一題分四個漸進關卡**）→ 五輪 onsite，含專屬的 values 輪。部分 MLE loop 已加入 **AI 協作輪**：給你 Claude，評你怎麼指揮與驗證它 |
| **OpenAI** | 31 | Coding 7 ‧ 系統設計 5 ‧ ML 基礎 4 | 技術篩選偏「**做出一個真的東西**」而非 LeetCode |
| **Google DeepMind** | 22 | **ML 基礎 8** ‧ 系統設計 5 ‧ Coding 4 | RE loop 加研究深潛 + 數學/機率 + **從零實作**；有 hiring committee 與 team matching |
| **Meta (FAIR/Llama)** | 26 | Coding 8 ‧ 系統設計 6 ‧ 行為 3 | 篩選 45 分兩題；2026 起部分 loop 有**三階段 AI 輔助編碼輪** |
| **xAI** | 10 | Coding 3 ‧ 微調 3 ‧ 推論 2 | **流程最短**。常有四小時限時產品建置。**重「出貨速度」** |
| **Mistral AI** | 8 | LLM 內部 2 ‧ 推論 2 | 有 pair-programming 建小型 LLM 服務；歐洲**企業/地端部署**情境貫穿全程 |
| **Cohere** | 10 | **RAG 4** ‧ 其餘各 1 | 實務 Python、streaming/API 形狀的題；遠端優先，**明確測自主性** |
| **DeepSeek** | 10 | LLM 內部 4 ‧ 微調 4 | **研究與系統並重**。會直接問**他們自己發表的論文** |
| **Moonshot AI (Kimi)** | 10 | LLM 內部 4 ‧ 推論 2 | **長上下文系統**為核心 |
| **Zhipu AI (GLM)** | 11 | LLM 內部 5 ‧ 微調 3 | 架構 + 後訓練深度、**RL 基礎設施**、GUI agent 設計 |
| **Alibaba (Qwen)** | 10 | LLM 內部 4 ‧ 微調 2 | 經典阿里結構：技術輪 + **主管交叉盤問**輪 + HR；加上 Qwen 架構與**多語言**題 |
| **Sarvam AI** | 12 | **多模態/語音 3** ‧ 微調 2 | **印度語系 NLP 與 tokenizer 深度**、受限硬體部署、政府/企業情境 |

#### 大廠 AI 組織

| 公司 | 題數 | 主要考點 | 流程特色 |
|---|---|---|---|
| **Microsoft** | 10 | Coding 2 ‧ 推論 2 ‧ 系統設計 2 ‧ 安全 2 | Azure AI / Copilot 職缺加**客戶架構輪** |
| **Amazon (AWS)** | 23 | **ML 基礎 12** ‧ 行為 3 | 每輪錨定 **Leadership Principles**，含 bar-raiser；Applied Scientist 加研究簡報 |
| **Apple** | 11 | **推論 4** ‧ 微調 2 | **裝置端與效率深度**。保密制度下**你可能面的是不能被告知的工作** |
| **NVIDIA** | 13 | **ML 基礎 4** ‧ 推論 3 ‧ Coding 3 | CUDA/C++ 編碼 + **roofline 推理** + LLM 推論深度 |
| **Tesla** | 11 | ML 基礎 4 ‧ Coding 2 | 視覺與訓練管線深度 + **動手除錯輪** |
| **Uber/Netflix/LinkedIn/Airbnb/Pinterest/Spotify** | 14 | **系統設計 8** | 形狀一致：**ML 系統設計輪是勝負手**；2024 後都加了 GenAI 輪 |

#### AI 基礎設施與平台

| 公司 | 題數 | 主要考點 | 流程特色 |
|---|---|---|---|
| **Databricks** | 9 | Coding 5 ‧ FDE 情境 2 | 併發或資料密集的實務編碼 + Spark 內部 |
| **Groq** | 12 | **推論 5** ‧ Coding 4 | **編譯器 IR 設計**、**SRAM-only 機器的 roofline 與記憶體階層**、單位經濟 |
| **Together AI** | 7 | 推論 3 | 推論效能深度 + **排程器/服務設計** + 分散式訓練除錯 |
| **Hugging Face** | 11 | Coding 3 ‧ LLM 內部 3 | **函式庫內部深潛**、維護者 code review 輪。**你的公開 GitHub 紀錄真的被列入評估** |
| **Scale AI** | 12 | **評估 3** ‧ Coding 2 | **資料品質/標註設計**輪 + 評估設計輪 |
| **Perplexity** | 15 | **系統設計 5** ‧ Coding 4 | 網路規模的檢索/排序設計；**對自家 App 的產品品味被明確評估** |

#### AI 原生產品公司

| 公司 | 題數 | 主要考點 | 流程特色 |
|---|---|---|---|
| **Cursor (Anysphere)** | 17 | Coding 5 ‧ **系統設計 5** ‧ Agent 2 | **在 Cursor 真實 codebase 上寫**；**兩天現場專案** onsite（或 8 小時遠端版）。**scoping、自主性、AI 工具使用被明確評分** |
| **Cognition (Devin)** | 9 | **Agent 3** ‧ 系統設計 2 | 建 agent / 除錯 agent 的實作輪 + agent 評估輪 |
| **Sierra** | 12 | **Agent 3 ‧ 評估 3** | **兩小時建置，可用任何 AI 工具**。核心訊號是「**護欄該放哪裡**的判斷力」 |
| **Harvey** | 11 | **安全 3** ‧ RAG 2 | 法律工作流架構簡報輪 + 評估設計輪。**領域嚴謹性 > 演算法謎題** |
| **Glean** | 10 | 系統設計 3 ‧ RAG 2 ‧ Agent 2 | **權限與連接器**系統輪 |
| **Character.AI** | 12 | **推論 4** ‧ 安全 3 | **推論經濟學**深度 + 安全系統設計 + 產品輪 |
| **ElevenLabs** | 8 | **多模態/語音 3** | **即時音訊系統**輪 + 語音模型深度 + **聲音複製的安全輪** |
| **Abridge** | 11 | **安全 3** ‧ 評估 2 | 臨床 ASR 深度 + **「很少有唯一正確的病歷」的評估設計**輪 + 隱私合規 |
| **Figure AI** | 12 | ML 基礎 3 ‧ 多模態 3 | 機器人學習（VLA、模仿、RL）+ **sim-to-real** + 安全架構 |
| **Waymo** | 12 | ML 基礎 3 ‧ 系統設計 3 ‧ 評估 3 | 感知或規劃深度 + 模擬設計；**資深職缺極重 safety case 推理** |
| **Palantir** | 20 | Coding 7 ‧ **FDE 情境 6** | 篩選 = 編碼 + SQL + API 三件；onsite 三輪抽自 decomposition / learning / coding / re-engineering / 系統設計。**decomposition 是招牌輪** |

### 這張地圖告訴我的三件事
1. **「AI 工程師」不是一個職缺，是至少四種**：推論效能（NVIDIA/Groq/Together/Character.AI）、RAG 與企業檢索（Glean/Cohere/Harvey）、Agent 產品（Cursor/Cognition/Sierra）、研究與後訓練（DeepSeek/Zhipu/DeepMind）。**考點幾乎不重疊。**
2. **Coding 題仍然佔最大宗**（Anthropic 12 題、Palantir 7 題），但形狀變了——**漸進式加需求、真實 codebase、可用 AI 工具**，考的是「在模糊需求下持續交付」而不是演算法。
3. **評估（Evaluation）已經是獨立的一輪**（Scale AI、Sierra、Waymo、Abridge 都有專輪）。這和 [[工具-AI系統評估]] 的判斷一致：**評估能力是 AI 工程最被低估的核心技能。**

## 💬 原文摘錄
> "Questions are compiled from publicly reported interview experiences. Nothing here is confidential. Interview loops change constantly and vary by team, level, and region, so **treat each company section as a map of what that company cares about, not a script of what you will be asked**."

> "Start with Common Questions Asked Across Companies. These are the questions that recur across many companies."

## 🔗 相關
- **概念展開全在這裡** → [[moc/AI工程面試準備|AI 工程面試準備]]
- 決策層工具卡 → [[moc/AI工程|AI 工程]]
- 同屬「型錄式來源逐項展開」的做法 → [[moc/以太坊協議標準|以太坊協議標準]]
