---
type: article
title: "How the Claude Code team does code review（Claude Code 團隊怎麼做程式碼審查）"
source_url: https://claude.dev/blog/solving-code-review-at-anthropic/
author: Addy Osmani, Morgan Westlee Lunt, Qing Wang（Anthropic）
site: claude.dev
tags: [ai, agent, code-review, devops, quality, evaluation]
captured: 2026-10-31
read_status: read
---

## 📌 30 秒摘要
> 這篇在講：Claude 寫了 Claude Code 約 90% 的程式碼之後，審查量大到沒辦法逐行讀，團隊怎麼重新設計審查。他們沒有拿掉審查，而是三件事：
> - **把大部分「讀」交給機器**：開 PR 前先驗證、每個 PR 都有 AI 審查與資安審查，未處理的發現會擋合併。
> - **人工核准依風險分級**：由變更內容決定要 0、1 或 2 個人看。
> - **大量投資在快速復原**：功能開關、先給內部用、分階段發布、一步回滾。
>
> 指標是「人花的時間」，護欄是回滾率與事故率。2026 年 6 到 9 月，合併的 PR 增加一倍多，需要回滾的比例反而降了 40% 以上。

## 🗺 心智圖（Canvas）
![[Claude Code 團隊怎麼做程式碼審查.canvas]]

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- 團隊開始讓 agent 開 PR 時，拿它的「七層把關」「風險分級表」「導入清單」當藍本，逐項對照自己缺哪一層。
- 它把「審查的目的」換成一個可以量的目標：人的時間，加上回滾與事故當護欄。以後要說服團隊調整審查流程，可以直接用這套指標。
- 調校 AI 審查器的三招（用事故當評估集、看人怎麼回應來量雜訊、限制輪數讓審查收斂）可以直接套到自己的 AI 審查設定。

## 🧰 這篇給我的工具
- [[工具-分層把關取代單一審查關卡]] — 當 agent 讓變更多到人審不完，要重新設計整條審查流程的時候
- [[工具-依風險分級的審查核准]] — 當我想讓部分變更不用人看就合併，要決定「這個變更要幾個人核准」的時候
- [[工具-調校AI程式碼審查器]] — 當 AI 審查不知道準不準、雜訊太多，或 agent 之間來回改不停的時候

## ✨ 關鍵重點
- **規模**（原文數據，2026-10-15）：
  - Anthropic monorepo 每天合進的變更，從 5 月約 2,500 個增加到 9 月超過 30,000 個。
  - AI 審查進入研究預覽後，拿到實質審查意見的內部 PR 比例從 16% 升到 54%。
  - 1,000 行以上的 PR 多半會有發現，小 PR 多半是乾淨的。
- **問對問題**：不是「有沒有人讀過」，而是「這個變更可能出什麼錯，哪一道檢查最適合抓到它」。審查從最後一道閘門，變成像拼字檢查一樣持續進行。
- **開 PR 前就驗證**：給 Claude 能執行的東西（測試、build、對照設計的截圖），要它貼出輸出而不是說「做完了」，再讓一個新 context 的 subagent 審 diff。Claude Code 的作者 Boris Cherny 估計，讓 Claude 能驗證自己的工作，結果會好兩到三倍。
- **CLAUDE.md 與 REVIEW.md 的分工**：
  - **CLAUDE.md** 說明專案是什麼：技術棧、慣例、目標與非目標。每次審查都會載入，所以要短，用連結指到其他文件。
  - **REVIEW.md** 由 code owner 寫，告訴審查器自己那一塊什麼最重要。好的 REVIEW.md 很短，內容包括：
    - 說清楚在這個 repo 裡「出錯」長什麼樣子，例如文件出錯是「說謊」、設定出錯是「導錯路」；
    - 限制小意見的數量；
    - 列出要跳過的路徑；
    - 要求以檔案與行號為證據，不准只看名稱就猜；
    - 摘要開頭先寫數量，沒有問題就直說。
- **AI 審查**：多個 agent 平行找 bug，另一組 agent 對每個發現投票，夠多人同意才張貼。每個發現都要處理：修掉，或寫理由關掉。
- **人留下來做的事**：決定要不要做、審高風險程式碼、審會被照抄的架構、讀證據、為結果負責。
- **「誰合進去誰負責」**：變更要小、什麼都能復原、依爆炸半徑決定審查強度、回歸要能很快從遙測冒出來。這不是究責，是因為修的人最有 context。
- **共享理解**：團隊沒有正式流程，想懂哪一塊就叫 Claude 寫那一塊的說明，有人還會請它做成互動小工具，再加上預設在公開頻道工作。
- **還沒做到的**：還沒有「事故數字變動時自動收緊核准」的熔斷機制，工程師希望先有它，再讓更多變更走零人工合併。

## 💬 原文摘錄
- "We think 'did a human read the code?' is an imprecise proxy for 'what could go wrong with this change, and which check—automated or human—is the right one to catch it?'"
- "Revert and incident rates are the guardrail: if they rise, we haven't saved human time, we've only moved it."
- "Noise costs more when the author is an agent."
- "One colleague said slowing down does lower your error rate, but mostly because you're doing less of everything. We'd rather get faster at noticing and fixing problems."

## 🔗 相關
- [[程式碼審查準則]] —— DevOps 手冊的人工審查準則；這篇是 agent 時代把大部分「讀」移給機器之後的版本
- [[同儕審查取代變更審批]] —— 同樣把審查交給離變更最近的人與自動檢查，而不是遠端簽核
- [[工具-把agent犯的錯變成環境改善]] —— 「同一類發現反覆出現就在源頭修」的同一個思路
- [[moc/Claude Code 深度使用|Claude Code 深度使用]] —— Claude Code 相關的其他筆記
