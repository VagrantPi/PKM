---
type: tool
name: "MCP 架構與資料流 Host / Client / Server"
source: "[[MCP 官方文件]]"
source_type: article
tags: [software, mcp, ai, architecture, protocol, integration]
triggers: [MCP的host client server分別是什麼, MCP連線怎麼建立, 想理解MCP整體架構, capability negotiation是什麼, 一次MCP互動怎麼跑]
---

## 🎯 什麼情境該想到我
當你想先建立 MCP 的整體心智模型——「誰跟誰連、一次連線從頭到尾怎麼跑」——再去看細節的時候。

## ⚙️ 怎麼用（記住三個角色＋兩層＋生命週期）
1. **三個參與者**：
   - **Host**：AI 應用本體（Claude Code、VS Code），協調多個 client。
   - **Client**：協定層元件，**一個 client 對一個 server** 維持連線；host 每連一個 server 就 new 一個 client。
   - **Server**：提供情境／能力的程式（可本地或遠端）。
2. **兩層**：
   - **資料層**：JSON-RPC 2.0，定義訊息與語義——生命週期、原語（tools/resources/prompts）、通知。這是最該懂的一層。
   - **傳輸層**：實際通道——stdio 或 Streamable HTTP，處理連線建立、訊息封裝、授權（見 [[工具-選擇MCP傳輸方式]]）。
3. **生命週期（一次連線怎麼開始）**：client 送 `initialize` → 雙方做 **capability negotiation**（宣告支援哪些原語、是否支援 `listChanged` 通知）＋協商單一 protocol 版本 → client 送 `notifications/initialized` → 開始互動。版本不相容就終止連線。
4. **典型資料流**：`initialize`（握手）→ `tools/list`（發現）→ `tools/call`（執行）→ 需要時 server 發 `notifications/tools/list_changed` 通知 client 重新拉清單。

## 🧪 我實際套用的紀錄
- 2026-07-26：（待填）

## ⚠️ 注意 / 什麼時候不適用
- 「Server」指的是提供資料的程式，跟它跑在本地或雲端無關；別把 server 等同於「遠端服務」。
- MCP 是**有狀態**協定，需要生命週期管理；SDK 幫你把大部分細節抽象掉了。

## 🔗 相關工具
- [[工具-MCP三大伺服器原語]]、[[工具-選擇MCP傳輸方式]]、[[工具-建一個MCP-server的起手式]]
