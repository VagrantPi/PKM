---
type: tool
name: "MCP 三大伺服器原語 Tools / Resources / Prompts"
source: "[[MCP 官方文件]]"
source_type: article
tags: [software, mcp, ai, llm, integration, protocol]
triggers: [搞不清楚MCP的tools resources prompts差在哪, 要在MCP server暴露什麼, 我的資料源該做成什麼, 設計MCP server功能, MCP server能提供什麼給AI]
---

## 🎯 什麼情境該想到我
當你要做 MCP server、卻分不清「該把某個能力做成 tool、resource 還是 prompt」的時候。關鍵是**問「誰控制它」**。

## ⚙️ 怎麼用（按「誰控制」對號入座）
1. **Tools（模型控制）**：LLM 主動決定何時呼叫的**動作**——寫資料庫、呼叫 API、改檔案。用 JSON Schema 定義 typed 輸入/輸出；`tools/list` 發現、`tools/call` 執行；執行前通常需**使用者同意**。例：`searchFlights`、`createCalendarEvent`。
2. **Resources（應用控制）**：唯讀的**情境資料**——檔案內容、DB schema、API 文件。每個有唯一 URI（`file:///...`）與 MIME type；支援**固定 URI** 與**帶參數的 Resource Template**（`travel://activities/{city}`）。`resources/list`、`resources/read`、`resources/subscribe`。由應用決定要塞多少進脈絡。
3. **Prompts（使用者控制）**：可重用的**指令模板**，需使用者**明確叫用**（非自動觸發），可帶參數、可引用 tools/resources。`prompts/list`、`prompts/get`。例：「Plan a vacation」帶 destination/duration/budget。
4. **設計法則**：一個 tool 只做一件事、schema 清楚；把「AI 要採取的行動」放 tools、「AI 需要知道的資料」放 resources、「引導使用者的流程」放 prompts。

## 🧪 我實際套用的紀錄
- 2026-07-26：（待填）

## ⚠️ 注意 / 什麼時候不適用
- Tools 由模型自動叫用，風險最高——務必留人類同意/核准的關卡（見 [[工具-MCP安全防護要點]]）。
- 別把唯讀資料硬做成 tool；resource 才是給脈絡的正解。

## 🔗 相關工具
- [[工具-MCP用戶端原語]]、[[工具-MCP架構與資料流]]、[[工具-建一個MCP-server的起手式]]
