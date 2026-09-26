---
type: article
title: "SillyTavern 角色扮演系統技術文件（原始碼分析）"
source_url: https://github.com/SillyTavern/SillyTavern
author: 自撰（依 SillyTavern 原始碼分析整理）
site: github.com/SillyTavern
tags: [software, ai, llm, prompting, roleplay, sillytavern, memory, context-management]
captured: 2026-09-26
read_status: read
---

## 📌 30 秒摘要
> 這套文件拆解開源角色扮演前端 SillyTavern **怎麼把一張角色卡變成送給模型的 prompt**。它的核心結論是：AI 不會「記得」任何東西，所有的角色一致性、世界觀、劇情走向、長期記憶，都等於**在 prompt 的某個位置放某段文字**。於是整個系統就是一條組裝管線，外加幾個「決定放什麼、放哪、放多少」的子系統：
> - World Info：用關鍵字觸發設定
> - Token 預算：固定的先放、聊天從新往舊填
> - 深度注入：指令跟著聊天尾巴走
> - 長期記憶：摘要＋向量＋知識庫
> - 正則引擎：人看的跟模型讀的分開
>
> 原文件共 19 篇、約 15 萬字元。

## 🎯 為什麼存這套文件 / 未來想拿它做什麼
- 做任何「長對話、有角色、有設定」的 LLM 產品（陪伴、客服、遊戲 NPC）時，這些問題 SillyTavern 都已經踩過一輪：設定太多塞不下、聊久了忘規則、忘前情。
- 它的解法都是 prompt 層的工程手段，不必動模型，可直接移植到自己的系統。
- 要設計 prompt 組裝器時，拿它的「誰要注入」與「注入到哪」解耦的做法當參考架構。

## 🧰 這套文件給我的工具（連到 tools/）
- [[工具-關鍵字觸發的設定注入]] —— 設定／知識太多，每輪只想載入話題相關的那幾條時
- [[工具-長對話的Token預算分配]] —— 系統提示、設定、聊天記錄要一起塞進固定大小的 context 時
- [[工具-用深度注入讓指令不被遺忘]] —— 系統提示裡的規則聊久了就失效時
- [[工具-對話型AI的長期記憶分層]] —— 聊天機器人對話一長就忘了前面的事時

## 🗂 型錄：逐主題展開（`reference/SillyTavern角色扮演/`）

**資料層：放什麼**
- [[World Info世界書|World Info 世界書 Lorebook]] —— 關鍵字觸發的設定條目、遞迴掃描、包含組、sticky/cooldown/delay
- [[宏系統|宏系統 Macros]] —— `{{char}}`、`{{user}}`、變數、`{{random}}` 與 `{{pick}}`、替換時機
- [[長期記憶三層架構|長期記憶三層架構 Long-term Memory]] —— 滾動摘要、向量召回、Data Bank

**管線層：怎麼組、放哪、放多少**
- [[Token預算管理|Token 預算管理 Token Budget]] —— Reserve → Add → Fill → Free，附完整算帳
- [[Authors Note與深度注入|Author's Note 與深度注入 Depth Injection]] —— 浮動提示、Extension Prompts 注入框架
- [[提示覆蓋與系統提示預設|提示覆蓋與系統提示預設 Prompt Override]] —— 角色卡覆蓋、`{{original}}`、PromptManager 排序
- [[生成類型|生成類型 Generation Types]] —— normal／swipe／regenerate／continue／impersonate／quiet，以及 Tool Calling

**處理與設計**
- [[正則替換引擎|正則替換引擎 Regex Engine]] —— 作用域（UI／prompt／存檔）、深度過濾、串流期間每幀重跑
- [[場景與故事走向控制|場景與故事走向控制 Story Steering]] —— 靜態基礎 → 動態引導 → 即時修正 → 自動化四層
- [[Prompt設計哲學|Prompt 設計哲學 Prompt Design Philosophy]] —— 舞台指令比喻、方括號元語言、避開中段低注意力區

> 原文件的「角色卡 V2/V3 格式」「Prompt 管線總覽」「Chat／Text Completion 兩條路徑」「Instruct Mode」「完整 prompt 範例集」這幾篇，這次沒有展開成獨立頁。「群組聊天」一篇原文件本身缺漏。

## ✨ 關鍵重點
- **引導 AI＝在 prompt 的不同位置放不同資訊**。模型越接近生成點的內容越在意，所以「是什麼」放前段（穩定），「現在要怎樣」放聊天歷史深處（有力）。
- **知識按需載入不一定要向量**：World Info 用字面關鍵字觸發，換來可預測、可除錯；再用 sticky／cooldown 補「提到後要記幾輪」「別每輪洗版」。
- **預算是先佔位再填**：位置固定的控制訊息先扣額度，固定內容超額直接報錯，聊天從最新往舊填、遇到放不下就停。檢索知識必須有獨立上限（預設 context 的 25%）。
- **注入來源與注入位置解耦**：摘要、向量記憶、人設、作者註都只是用一個 key 註冊內容、宣告位置，組裝器統一處理。
- **長期記憶三層互補**：摘要保大綱（有損）、向量保原文細節、知識庫補對話以外的知識；寫入在訊息進來時做，召回在生成時做。
- **人看的和模型讀的可以不一樣**：正則腳本可以只改畫面、只改 prompt，或改存檔。
- **同一條生成管線、六種進入方式**：重抽、續寫、代寫、背景靜默生成，都只差一個 `type` 參數。

## 💬 原文摘錄
- 「AI 不會『記住』劇情計畫。它只能根據 prompt 中的資訊來決定下一句話。因此，『引導故事走向』等同於在 prompt 的不同位置放置不同的引導資訊。」

## 🔗 相關
- [[工具-提示工程]] —— 通用的提示寫法；這套文件補的是長對話下「放哪、放多少」的工程面
- [[工具-RAG檢索增強生成]] —— 向量召回與 Data Bank 的通用版
- [[moc/AI工程|AI 工程]]
