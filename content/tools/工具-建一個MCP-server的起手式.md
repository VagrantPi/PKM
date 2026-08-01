---
type: tool
name: "建一個 MCP server 的起手式 Build Your First MCP Server"
source: "[[MCP 官方文件]]"
source_type: article
tags: [software, mcp, ai, integration, protocol]
triggers: [想自己做一個MCP server, 怎麼開始寫MCP server, 把我的API包成MCP, MCP server怎麼測試除錯, 讓AI能呼叫我的工具]
---

## 🎯 什麼情境該想到我
當你想把「自己的 API／資料源／工具」包成 MCP server，讓 Claude 這類 AI 應用能即插即用地呼叫的時候。

## ⚙️ 怎麼用（從零到能被呼叫）
1. **選 SDK**：官方提供 Python / TypeScript / Java / Kotlin / C# / Ruby / Rust / Go；挑你熟的語言，SDK 會把 JSON-RPC、生命週期等細節抽象掉。
2. **決定要暴露什麼**：依 [[工具-MCP三大伺服器原語]] 對號入座——動作放 **Tools**、唯讀資料放 **Resources**、引導流程放 **Prompts**。（多數 server 從 Tools 開始，如教學的 `get_alerts`、`get_forecast`。）
3. **定義 Tool**：給 `name`、`description`、`inputSchema`（JSON Schema，標好 properties 與 required）；讓描述清楚到模型能自己判斷何時呼叫。
4. **實作協定方法**：`tools/list`（回傳工具清單與 schema）、`tools/call`（執行並回結果）；SDK 通常用 decorator/註冊即可。
5. **選傳輸**：本地自用先走 **stdio**（見 [[工具-選擇MCP傳輸方式]]）。
6. **接到 host**：在 host（如 Claude for Desktop）的設定檔登記你的 server 啟動指令，重啟後即可被呼叫。
7. **測試除錯**：用 **MCP Inspector**（互動式測試工具）逐一叫 `tools/list`/`tools/call` 驗證；問題多時看 Debugging 頁與 log。
8. **要上遠端/多人**：改用 Streamable HTTP + OAuth，並過一遍 [[工具-MCP安全防護要點]]。

## 🧪 我實際套用的紀錄
- 2026-07-26：（待填）

## ⚠️ 注意 / 什麼時候不適用
- 一個 tool 只做一件事、schema 寫清楚，模型才叫得準；別把十件事塞進一個 tool。
- 上線前務必補上使用者同意關卡與授權（tool 會實際改資料/呼叫外部）。

## 🔗 相關工具
- [[工具-MCP架構與資料流]] —— 動手前先看，建立 Host / Client / Server 的整體圖，才知道自己寫的是哪一塊、一次連線怎麼跑
- [[工具-MCP三大伺服器原語]] —— 第 2 步「決定暴露什麼」的判準：用「誰控制它」把能力分到 Tools / Resources / Prompts
- [[工具-選擇MCP傳輸方式]] —— 第 5 步選傳輸時看，本地 stdio 與遠端 Streamable HTTP 的取捨與認證需求
- [[工具-MCP安全防護要點]] —— 要開放給別人用之前的檢查清單，授權、同意關卡與攻擊面一次過完
