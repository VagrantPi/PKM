---
type: article
title: "MiniMax H3 全模態生成模型"
source_url: https://github.com/MiniMax-AI/MiniMax-H3
author: MiniMax AI
site: GitHub
tags: [ai, 生成模型, 影片生成, 全模態, 開源模型]
captured: 2026-08-09
read_status: read
---

## 📌 30 秒摘要
> 這篇在講：**MiniMax H3** 是一套開源的**全模態生成系統**，能統一理解文字／圖／影／音的混合輸入，直接生成**帶原生立體聲的影片**（最高 2K、4–15 秒、24fps、32kHz stereo）。核心是一顆 **33B 單流 Omni-Transformer**，設計走「任務泛化」而非為每個任務做專屬結構，所以在預訓練階段就有廣泛的多模態理解與生成能力。

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- 想在本機部署或用 API 生「有聲影片」時的第一手參考——能力邊界、輸入規格、部署方式一次看清。
- 研究全模態生成架構的具體、開源、可讀權重的案例（統一 packed sequence ＋ 各模態 VAE ＋ MM-RoPE）。
- 它綁了九個可直接裝的 skill，若要實際用它生圖／生影 → 見下方工具區。

## 🧰 這篇給我的工具
- [[moc/AI技能收藏#minimax-h3-skills|MiniMax-H3 skills]] — 想用 H3 寫 prompt 或做風格化影片時（九個 skill，`npx skills add` 一鍵裝）

## ✨ 關鍵重點

**能力與輸出規格**
- 輸出 4–15 秒、多種比例（21:9／16:9／4:3／1:1／3:4／9:16…）、短邊預設 768px（**2K 需 H3-Regenerate-2K**）、24fps、32kHz 立體聲。
- 對話穩定支援 11 種語言（阿、中、英、法、德、義、日、韓、葡、俄、西）。

**兩個開源 checkpoint**（BF16、CFG-distilled、各為自足的 HF 式 repo）
- **H3-Base-FL2VA**（首尾幀模式）：0／1／2 張輸入圖 → 文生影、首幀或尾幀生影、首尾幀生影。
- **H3-Base-Ref2VA**（全參考模式）：多模態參考輸入，圖 ≤9、影片 ≤3 段（各 2–15s、總 ≤15s）、音訊 ≤3 段（須搭圖或影、不能單獨用）；跨類型檔案最多 12 個。

**三個模組（開源狀態不同）**
- **H3-Context-IR**：把自由形式的多模態輸入解析成結構化中介表示（Context Intermediate Representation）餵給 Base，過程含指令解析、跨模態關聯、時序理解、複雜邏輯推理。**多階段、依賴多個託管服務，未開源**；官方給 API，或照 Prompting Guidance 自建。官方強烈建議把它納入生成流程，品質關鍵。
- **H3-Base**：吃 Context-IR 產 **768p** 影音。**已開源**。
- **H3-Regenerate-2K**：把 768p 結果 ＋ 原始 context 餵回 H3，**in-context 自我重生成 2K**（不是傳統超解析度模組，能還原小字與細節）。**尚未開源**，先給 API 驗證。

**架構**
- 各模態各自 encoder／VAE → 組成統一 packed multimodal sequence → **MM-RoPE**（t,h,w 三維）→ **H3-Omni-Transformer** 聯合預測 video／audio latent → 各自解碼成影片與立體聲。
- **H3-Encoder**：用 **Qwen3-VL-32B** 完整權重，取其**第 50 層** hidden state；tokenizer 加了 `<d>` 等特殊 token（必須用 repo 附的 tokenizer 與設定）。
- **H3-VisualVAE**：時間因果影片 autoencoder，`f16t4d24`（空間 16×、時間 4×、24 channel），再 patchify 1×2×2 → 有效空間降採樣 32×、時間維持 4×；另訓 ViT decoder 降解碼成本。
- **H3-AudioVAE**：左右聲道共用 encoder／decoder 但各自獨立處理，32kHz 壓成 40Hz latent，支援立體聲進出。
- **H3-Omni-Transformer**：**33B dense 單流**，其中約 **13B 在 AdaLN 分支**（modulation 輸出可預算快取，inference-only 可不載）；attention／FFN 無模態專屬結構，模態專屬只在 I/O 層與 AdaLN。訓練末期引入 **native sparse attention**，但**開源版目前只給 full attention**，sparse 之後才放。

**其他**
- 授權：**MiniMax H3 Community License**；輸入與強化後 prompt 會過自動內容審核 guardrail。
- 用法：本機部署 H3-Base 驗 768p；「Full 2K Workflow」= Open Platform API ＋ 本機 Base。也可直接用 API／App（platform.minimax.io、hailuoai.video 等）。

## 💬 原文摘錄
- "MiniMax H3 is a general-purpose, omni-modal generative system... generate video with native stereo audio at resolutions up to 2K and durations of up to 15 seconds."
- "H3-Omni-Transformer is a 33B-parameter dense, single-stream Transformer, with approximately 13B parameters residing in AdaLN-related branches."
- "The H3-Encoder uses the full pretrained weights of Qwen3-VL-32B and provides the hidden states from its 50th layer to the H3-Omni-Transformer."

## 🔗 相關
- 九個可裝的 skill → [[moc/AI技能收藏#minimax-h3-skills|AI 技能收藏：MiniMax-H3 skills]]
- 打造／理解 AI 系統 → [[moc/AI工程|AI工程]]
