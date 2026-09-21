---
type: tool
name: "選擇 MCP 傳輸方式 stdio vs Streamable HTTP"
source: "[[MCP 官方文件]]"
source_type: article
tags: [software, mcp, ai, integration, protocol, architecture]
triggers: [MCP要用stdio還是HTTP, 本地server跟遠端server怎麼選, MCP的認證要怎麼做, 多個使用者共用一個MCP server可以嗎, MCP server部署到雲端要注意什麼]
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

### ★ 決策表

| 問題 | stdio | Streamable HTTP |
|---|---|---|
| server 在哪 | ★ **同一台機器** | 本地或遠端皆可 |
| 誰啟動它 | ★ **host 直接 spawn 子程序** | 獨立部署的服務 |
| 服務幾個 client | ★ **一個**（一對一） | ★ **多個** |
| 認證 | ★ **不需要**（同一個使用者的程序） | ★ **需要**（bearer / OAuth） |
| 延遲 | ★ **最低**（無網路） | 有網路開銷 |
| 部署與更新 | 隨 host 走 | ★ **可獨立部署、集中更新** |
| 存取本機資源 | ★ **天然可以**（檔案、git、本機工具） | ❌ 看不到使用者的機器 |
| 觀測與稽核 | 難（散在各使用者的機器上） | ★ **集中、可稽核** |

★ **一句話判準**：
> **要碰使用者機器上的東西 → stdio；要集中管理、多人共用、需要授權 → HTTP。**

### ★ stdio 的實務細節（容易踩的地方）

```
★★ stdout 只能傳 MCP 訊息 —— 任何 print/log 寫到 stdout 都會破壞協定
   → 所有日誌一律寫 stderr
```
```go
// ❌ 會把協定搞爛
fmt.Println("server started")

// ✅
fmt.Fprintln(os.Stderr, "server started")
slog.SetDefault(slog.New(slog.NewTextHandler(os.Stderr, nil)))
```
★ **這是寫 MCP server 最常見的第一個 bug**，而且症狀是「client 完全連不上但沒有錯誤訊息」。

**其他細節**：
- **環境變數是傳設定的主要途徑**（host 啟動時注入）
- **子程序的生命週期由 host 管**——要正確處理 SIGTERM 並清理資源
- **不要假設有 TTY**，也不要做互動式提示

### ★ HTTP 的實務細節

| 事項 | 說明 |
|---|---|
| **★ 授權** | MCP 建議用 **OAuth 取得 token**；簡單情境可用 bearer token / API key |
| **★ 多租戶隔離** | 一個 server 服務多個使用者 → **每個請求都要驗證身分並隔離資料**<br>（見 [[權限感知檢索與引用歸因]]） |
| **串流** | 回應可用 **SSE**（見 [[AI 工程 Coding 題型]] 的 SSE 解析器） |
| **可觀測性** | ★ **集中式的日誌與追蹤——這是 HTTP 相對 stdio 的主要優勢** |
| **限流** | 多使用者 → 需要 per-tenant 配額（見 [[工具-限流器設計]]） |

### ★ 安全考量（兩種傳輸都適用）

> ★★ **MCP server 是一個新的信任邊界，而且是雙向的。**

| 風險 | 說明 |
|---|---|
| **★ server 看得到你餵進去的內容** | 第三方 server = 把資料交給第三方。**內部資料要用自己部署的** |
| **★ 工具描述是注入載體** | 工具的 `description` 會進入模型的 prompt → **惡意 server 可以在描述裡藏指令**（見 [[提示注入與分層防禦]]） |
| **★ 遠端 server 的可用性** | 它掛了你的 agent 就少一半能力 → 要有降級 |
| **本地 server 的權限** | stdio server 以使用者的身分執行 → **它能做的事和使用者一樣多** |

★ **實務建議**：
- **第三方 MCP server 當成不可信的外部依賴**，不要給它超出必要的資料
- **自己部署的 server 才用在敏感資料上**
- **工具描述要 review**（尤其自動安裝的 server）

## 🧪 我實際套用的紀錄
- 2026-07-26：（待填）

## ⚠️ 注意 / 什麼時候不適用

- **★★ stdio 的 stdout 絕對不能寫非協定內容**（見上）。
- **★ 不要為了「看起來比較專業」而用 HTTP**。本地工具用 stdio 更簡單、更快、不用處理認證。
- **HTTP server 要處理並行**。多個 client 同時呼叫 → **狀態不能存在全域變數裡**（見 [[工具-Go全域狀態的判準]]）。
- **★ 協定版本會演進**。`initialize` 時要協商版本並**優雅地處理不相容**，不要假設對方版本和你一樣。
- **★ 工具描述的品質決定一切**。不管哪種傳輸，模型選不選得對工具取決於描述（見 [[工具集設計]]）。
- **不要把 MCP 當成通用的 RPC**。它是給「AI 應用取得情境與能力」設計的；
  **服務之間的一般通訊還是用 gRPC/HTTP。**

## 🔗 相關工具
- [[工具-MCP架構與資料流]] —— 協定層的完整說明
- [[工具-MCP安全防護要點]] —— 安全的完整討論
- [[工具-建一個MCP-server的起手式]] —— 實作
- [[Function Calling 與結構化輸出]] —— ★ MCP 與 function calling 在不同層
- [[工具集設計]] —— 工具描述怎麼寫
- [[提示注入與分層防禦]] —— 工具描述作為注入載體
- [[MCP 官方文件]]
