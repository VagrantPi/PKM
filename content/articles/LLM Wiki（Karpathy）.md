---
type: article
title: "LLM Wiki —— 用 LLM 建個人知識庫的模式（Andrej Karpathy）"
source_url: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
author: Andrej Karpathy
site: gist.github.com
tags: [ai, llm, knowledge-management, obsidian, learning]
captured: 2026-09-26
read_status: read
---

## 📌 30 秒摘要
> 一份「點子檔」（idea file，2026-04-04 發布），設計成讓你**直接貼給自己的 LLM agent**（Claude Code、Codex…），由 agent 跟你一起把細節做出來。
>
> 核心主張是：多數人用 LLM 讀文件的方式是 RAG，每次提問都從原始檔重新撈片段、重新拼答案，**什麼都沒累積**。改成讓 LLM **持續建立並維護一個互相連結的 markdown wiki**：新來源進來時，LLM 不只是建索引，而是讀完、萃取重點，再整合進既有頁面——更新實體頁、修訂主題摘要、標出新舊說法的矛盾。
>
> 知識「編譯一次、之後保持最新」，wiki 會隨每個來源、每個問題**複利成長**。人負責挑來源、提問、思考意義；LLM 負責其他所有雜務。
>
> **本知識庫就是照這個模式建的**：「有紀律的 wiki 維護員」這個定位、CLAUDE.md 當規則檔、ingest／lint 流程，都出自這篇。

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- 這是本知識庫架構的**出處**。以後要調整規則、或跟別人解釋這套系統為什麼長這樣，回來看原始設計意圖。
- 原文有幾個做法我還沒用，之後可以補：`log.md` 時間紀錄、把好答案存回 wiki、wiki 變大後用本機搜尋引擎。
- 可以把同一套模式搬到非個人場景，例如團隊內部 wiki、研究某個主題、盡職調查。

## 🧰 這篇給我的工具（連到 tools/）
- [[工具-讓LLM維護的個人Wiki]] —— 讀了很多東西卻沒累積、筆記維護不下去時
- [[工具-把好答案存回知識庫]] —— 問 AI 得到一份好分析，卻只留在聊天紀錄裡時
- [[工具-知識庫定期健檢]] —— 知識庫長大後，開始出現矛盾、孤兒頁、過時說法時

## ✨ 關鍵重點

**三層架構**

| 層 | 內容 | 誰擁有 |
|---|---|---|
| 原始來源 Raw sources | 文章、論文、圖片、資料檔。**不可改動**，是事實的最終依據 | 人挑選，LLM 只讀 |
| Wiki | LLM 產生的 markdown：摘要、實體頁、概念頁、比較、總覽、綜合 | **LLM 全權擁有**：建頁、更新、維護交叉連結 |
| 規則檔 Schema | 例如 CLAUDE.md／AGENTS.md，寫 wiki 的結構、慣例與各流程怎麼走 | 人與 LLM 一起演化 |

★ 規則檔是關鍵：它讓 LLM 成為「**有紀律的 wiki 維護員**」，而不是一般的聊天機器人。

**三個操作**
- **Ingest（收錄）**：丟一個新來源進來。LLM 讀完、跟你討論重點，接著寫摘要頁、更新索引、更新相關實體與概念頁，最後記一筆日誌。**一個來源可能動到 10–15 頁**。作者偏好一次收一個、自己全程參與，但也可以批次處理。
- **Query（提問）**：對 wiki 提問，LLM 先找相關頁、讀完，再附引用回答。答案可以是頁面、比較表、Marp 投影片、matplotlib 圖表、canvas。★ **好答案要存回 wiki 變成新頁**，探索成果才會跟來源一樣累積。
- **Lint（健檢）**：定期檢查頁面間的矛盾、被新來源推翻的過時說法、沒有連入的孤兒頁、被提到卻沒有自己頁面的重要概念、缺漏的交叉連結、可以上網補的資料缺口。

**兩個特殊檔案**
- **`index.md`**（照內容組織）：每頁一行連結＋一行摘要，按類別分組，每次收錄都更新。回答問題時 LLM 先讀索引再深入。作者說在約 100 個來源、數百頁的規模下**出奇地好用，不需要 embedding RAG**。
- **`log.md`**（照時間排序）：只追加的紀錄。每筆用固定開頭（例：`## [2026-04-02] ingest | Article Title`），就能用 `grep "^## \[" log.md | tail -5` 看最近 5 筆。

**比喻**：「Obsidian 是 IDE；LLM 是程式設計師；wiki 是 codebase。」一邊開 agent、一邊開 Obsidian，即時看它改了什麼、看 graph view。

**為什麼行得通**：維護知識庫的苦差事不在閱讀或思考，而在**記帳**——更新交叉連結、保持摘要最新、標出矛盾、維持幾十頁的一致性。人類放棄 wiki，是因為維護負擔長得比價值快。LLM 不會無聊、不會忘了更新連結、一次能改 15 個檔，**維護成本趨近零，wiki 才維持得住**。

**精神源頭**：Vannevar Bush 的 Memex（1945）——私人、主動策展、文件之間的關聯跟文件本身一樣有價值。Bush 解決不了的是「誰來維護」，這件事現在由 LLM 接手。

**選配工具**
- **qmd**：本機 markdown 搜尋引擎，混合 BM25 與向量搜尋，並用 LLM 重排，有 CLI 和 MCP 兩種介面。wiki 大到索引檔不夠用時再上。
- **Obsidian Web Clipper**：把網頁轉成 markdown。
- **圖片存到本機**：把附件資料夾設成固定位置，再綁一個快捷鍵執行「Download attachments for current file」。LLM 沒辦法一次讀完含內嵌圖的 markdown，要先讀文字，再個別看圖。
- **Dataview**：查詢 frontmatter，自動產生表格。
- **Marp**：markdown 投影片。
- **git**：wiki 本身就是一個 markdown 的 git repo，版本紀錄、分支、協作都免費拿到。

**刻意抽象**：原文只講模式、不講實作。目錄結構、頁面格式、工具全部選配，「分享給你的 LLM agent，一起做出適合你的版本」。

**本知識庫與原文的差異**

| 原文 | 本知識庫 |
|---|---|
| 以實體頁／概念頁為中心 | 以「工具卡＋白話 triggers」為中心：憑情境找工具，不是憑書名找 |
| 單一 `index.md` | 主題 MOC 當入口，另有公開網站首頁 |
| 有 `log.md` | 沒有時間日誌；進度追蹤放在 `_meta/` |
| 個人在 Obsidian 瀏覽 | 另外用 Quartz 發布成公開網站 |
| 無品質門檻 | 鐵律 1–11：只抓 3–7 個工具、深度自足、UGC 來源先查證 |

## 💬 原文摘錄
- "The wiki is a persistent, compounding artifact."
- "Obsidian is the IDE; the LLM is the programmer; the wiki is the codebase."
- "Humans abandon wikis because the maintenance burden grows faster than the value."
- "The human's job is to curate sources, direct the analysis, ask good questions, and think about what it all means. The LLM's job is everything else."

## 🔗 相關
- [[工具-RAG檢索增強生成]] —— 原文拿來對照的「每次都重新推導」做法；LLM Wiki 則是把知識先編譯好
- [[工具-主題閱讀]] —— 同一個主題整合多份來源、形成自己的觀點；原文「Research」用途的人工版
