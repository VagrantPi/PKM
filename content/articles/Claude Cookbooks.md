---
type: article
title: "Claude Cookbooks（Anthropic 官方 notebook 食譜集）"
source_url: https://github.com/anthropics/claude-cookbooks
author: Anthropic
site: github.com/anthropics
tags: [ai, llm, agent, claude-api, tool-use, cost]
captured: 2026-11-02
read_status: read
---

## 📌 30 秒摘要
> 這是 Anthropic 官方維護的 Claude API 範例集：約 100 個可以直接跑的 Jupyter notebook，主題涵蓋 Managed Agents、工具呼叫、Agent SDK、RAG、評估、多模態、prompt caching、成本最佳化。日期從 2023-08 到 2026-10（MIT，★54k，查證 2026-11-02）。
> 量太大，這次不整包收，只挑庫裡缺的 4 篇讀完、核對官方文件，寫成工具卡或補進既有的卡。完整分類導覽放在 [[moc/工具收藏|工具收藏]] 的收藏卡。

## 🗺 心智圖（Canvas）
![[Claude Cookbooks.canvas]]

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- 要用 Claude API 做某件事（批次、快取、工具呼叫、agent）時，先翻這裡有沒有官方範例，再決定自己怎麼寫。
- 這次挑的 4 篇，正好補上庫裡「agent 怎麼組流程、怎麼省 token、怎麼省錢」的缺口。

## 🧰 這篇給我的工具
- [[工具-agent工作流的基本模式]] — 一次呼叫做不好、想拆成幾步，不知道該串、分流、平行還是自我修正的時候
- [[工具-讓模型寫程式一次呼叫多個工具]] — 工具回傳很大、要逐筆查很多資料，token 被塞爆的時候
- [[工具-agent成本最佳化清單]] — agent 上線後帳單太高，想省錢又怕品質掉的時候
- 補充：[[前綴快取 Prompt Caching]] 新增「使用者還在打字時先暖快取」一節，並依官方文件更新讀取倍率與最低長度

## ✨ 關鍵重點
- **先用固定流程，不夠再升級成 agent**：prompt chaining、routing、parallelization、orchestrator-workers、evaluator-optimizer 五種模式，各自對應一種「一次呼叫做不好」的原因。
- **程式化工具呼叫**：讓模型寫一段程式在沙箱裡呼叫工具，中間結果不進對話。notebook 的實驗 token 從 110,473 降到 15,919（−85.6%），時間幾乎沒省。
  - ⚠️ notebook 用的 `code_execution_20250825` 和 beta header 已經過時。官方文件現在規定要 `code_execution_20260120` 以上，而且不需要 beta header（查證 2026-11-02）。工具卡兩種寫法都列了。
- **成本最佳化要同時看通過率**：只看帳單會悄悄掉品質。notebook 用 10 筆保險理賠任務量測每任務成本，再找出「比所有更便宜的設定都更準」的 Pareto 前緣。
- **預先暖快取**：notebook 的實驗首字延遲從 20.87 秒降到 1.94 秒。但它是等暖身跑完才開始計時，實際省下的大約是打字時間與 prefill 時間取較短的那個（推論，見快取卡）。
- **notebook 都沒有實際執行**：會呼叫付費 API。以上數字都是 notebook 裡留下的輸出，部分輸出是舊模型跑的。

## 💬 原文摘錄
- 官方對 PTC 的提醒："Do not rely on `allowed_callers` as a security boundary."（platform.claude.com 的 programmatic tool calling 文件，查證 2026-11-02）

## 🔗 相關
- [[moc/工具收藏|工具收藏]] —— Claude Cookbooks 收藏卡：完整分類導覽與什麼時候去翻
- [[Agent 記憶設計]] —— context 壓力的四種解法表，PTC 是其中一列
- [[Claude Code 團隊怎麼做程式碼審查]] —— 同為 Anthropic 官方的實務文章
