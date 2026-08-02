---
type: moc
title: "MCP（Model Context Protocol）"
tags: [moc, mcp, ai, llm, protocol]
---

> 主題索引（MOC）：當你要「讓 AI 應用連上外部資料/工具」——理解或打造 MCP server/client 時，從這裡進入。來源：[[MCP 官方文件]]。

## 🧠 先建心智模型
- Host/Client/Server 怎麼連、一次互動怎麼跑 → [[工具-MCP架構與資料流]]（入口/總覽）

## 🧩 核心原語（MCP 的靈魂）
- server 能對外提供什麼：Tools/Resources/Prompts → [[工具-MCP三大伺服器原語]]
- client 反過來給 server 的能力：Sampling/Elicitation/Roots → [[工具-MCP用戶端原語]]

## 🛠 動手做
- 從零做一個能被 AI 呼叫的 server → [[工具-建一個MCP-server的起手式]]
- 本地(stdio) 還是遠端(HTTP)、怎麼認證 → [[工具-選擇MCP傳輸方式]]

## 🔐 安全
- 發布/串接前的授權與攻擊面檢查 → [[工具-MCP安全防護要點]]

## 🔗 相關
- [[工具-AI-Agent設計]]（MCP 是 agent 用外部工具的標準協定）、見主題 [[moc/AI工程|AI工程]]

## 📚 來源
[[MCP 官方文件]]
