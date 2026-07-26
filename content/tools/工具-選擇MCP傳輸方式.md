---
type: tool
name: "選擇 MCP 傳輸方式 stdio vs Streamable HTTP"
source: "[[MCP 官方文件]]"
source_type: article
tags: [software, mcp, ai, integration, protocol, architecture]
triggers: [MCP server要用stdio還是http, 本地還是遠端MCP server, MCP要怎麼連線傳輸, 遠端MCP server怎麼認證, MCP server給多人用]
---

## 🎯 什麼情境該想到我
當你要決定 MCP server「怎麼跟 client 通訊」——本地程序還是網路服務、單人還是多人、要不要認證——的時候。

## ⚙️ 怎麼用（二選一）
1. **stdio transport（本地）**：
   - 用標準輸入/輸出跟**同一台機器上的**程序直接溝通，**無網路開銷、效能最好**。
   - 典型服務**單一 client**（host 直接啟動它，如 Claude Desktop 起 filesystem server）。
   - 適合：本地檔案/工具、個人用、不需跨網路。
2. **Streamable HTTP transport（遠端）**：
   - client→server 用 HTTP POST，回應可用 **Server-Sent Events** 串流。
   - 支援**遠端**、可同時服務**多個 client**。
   - 支援標準 HTTP 認證（bearer token、API key、自訂 header），**MCP 建議用 OAuth 取得 token**。
   - 適合：雲端託管、多使用者、需授權的 server。
3. **決策捷徑**：本地／單人／要快 → **stdio**；遠端／多人／要認證 → **Streamable HTTP + OAuth**。傳輸層對資料層透明，換傳輸不影響 JSON-RPC 訊息格式。

## 🧪 我實際套用的紀錄
- 2026-07-26：（待填）

## ⚠️ 注意 / 什麼時候不適用
- 遠端 server 一旦上網路，授權與攻擊面就要認真處理（見 [[工具-MCP安全防護要點]]）。
- 「本地／遠端」是就傳輸而言；同一個 server 邏輯常可同時提供兩種傳輸。

## 🔗 相關工具
- [[工具-MCP架構與資料流]]、[[工具-MCP安全防護要點]]、[[工具-建一個MCP-server的起手式]]
