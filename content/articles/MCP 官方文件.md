---
type: article
title: "MCP 官方文件 Model Context Protocol Docs"
source_url: https://modelcontextprotocol.io/docs/getting-started/intro
author: Model Context Protocol（Anthropic 發起，現為 LF Projects）
site: modelcontextprotocol.io
tags: [software, mcp, ai, llm, agents, protocol, integration]
captured: 2026-07-26
read_status: read
---

## 📌 30 秒摘要
> MCP 是「AI 應用的 USB-C」——一套開放標準，讓 Claude、ChatGPT 這類 AI 應用用統一介面連上外部的資料、工具與工作流。核心是 **Host／Client／Server 架構** ＋ **JSON-RPC 資料層** ＋ 三大伺服器原語（**Tools／Resources／Prompts**）與三大用戶端原語（**Sampling／Elicitation／Roots**）；傳輸走 **stdio（本地）** 或 **Streamable HTTP（遠端，OAuth 授權）**。

## 🎯 為什麼存這套文件 / 未來想拿它做什麼
- 想把自己的 API／資料源包成 MCP server，讓 AI 應用即插即用時的權威依據。
- 搞懂「tools / resources / prompts / sampling / elicitation / roots」到底各自幹嘛、誰控制。
- 決定本地(stdio) vs 遠端(HTTP) 傳輸、以及遠端授權與安全防護怎麼做。

## 🧰 這套文件給我的工具（連到 tools/）
- [[工具-MCP三大伺服器原語]] — 想搞懂 MCP server 能對外提供什麼、該暴露哪些東西時
- [[工具-MCP用戶端原語]] — server 想借用 LLM、向使用者要資訊、或限定檔案範圍時
- [[工具-MCP架構與資料流]] — 想理解 Host/Client/Server 怎麼連、一次連線怎麼跑時
- [[工具-選擇MCP傳輸方式]] — 不確定 MCP 要用 stdio 還是 HTTP、本地還是遠端時
- [[工具-MCP安全防護要點]] — 要串接／發布 MCP server、想顧好授權與攻擊面時
- [[工具-建一個MCP-server的起手式]] — 想從零做出一個能被 AI 呼叫的 MCP server 時

## 🗂 文件涵蓋範圍（已收錄 16 頁）
- **Get started**：What is MCP?（總覽、USB-C 比喻）
- **About MCP**：Architecture（架構總覽）、Servers（伺服器概念）、Clients（用戶端概念）、Versioning（版本管理，YYYY-MM-DD、目前 2025-11-25）
- **Develop**：Connect to local servers、Connect to remote servers、Build with Agent Skills、Build an MCP server、Build an MCP client、Client best practices、SDKs
- **Developer tools**：MCP Inspector、Debugging
- **Security**：Understanding Authorization（OAuth）、Security Best Practices（攻擊面與緩解）

## ✨ 關鍵重點
- **三個參與者**：**Host**（AI 應用，如 Claude Code）為每個 server 建立一個 **Client**，每個 Client 對一個 **Server** 維持連線。
- **兩層**：**資料層**（JSON-RPC 2.0：生命週期、原語、通知）＋ **傳輸層**（stdio 或 Streamable HTTP；HTTP 建議用 OAuth）。
- **生命週期**：連線先 `initialize` 握手做 **capability negotiation**（雙方宣告支援哪些原語與通知），協商出單一 protocol 版本才建立 session。
- **伺服器原語**：Tools（模型控制的動作）、Resources（應用控制的唯讀資料）、Prompts（使用者控制的模板）；用 `*/list` 發現、`*/get`/`*/read` 取得、`tools/call` 執行。
- **用戶端原語**：Sampling（server 借用 client 的 LLM）、Elicitation（server 向使用者要結構化輸入）、Roots（client 告知 server 可存取的檔案目錄，屬協調非強制安全邊界）。

## 💬 原文摘錄
- 「Think of MCP like a **USB-C port for AI applications**.」
- 「MCP defines three core primitives that servers can expose: **Tools**（executable functions）, **Resources**（data sources）, **Prompts**（reusable templates）.」
- 「Roots serve as a **coordination mechanism** between clients and servers, **not a security boundary**.」
- 「Elicitation **never requests passwords or API keys**.」

## 🔗 相關
- [[工具-AI-Agent設計]]（《AI工程》）——MCP 正是「讓 agent 安全地用外部工具／取得情境」的標準協定，兩者互補
- [[LLM Course 課程文件]]——互補的另一半：MCP 管「怎麼安全接工具」，那份管「模型本身怎麼練、怎麼跑得快」
