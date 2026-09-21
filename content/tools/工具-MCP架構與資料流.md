---
type: tool
name: "MCP 架構與資料流 Host / Client / Server"
source: "[[MCP 官方文件]]"
source_type: article
tags: [software, mcp, ai, architecture, protocol, integration]
triggers: [MCP的host client server分別是什麼, MCP跟function calling差在哪, capability negotiation在協商什麼, MCP的通知機制怎麼用, 為什麼一個server要配一個client]
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

### ★ 為什麼是「一個 client 對一個 server」

```
Host（Claude Code / VS Code）
 ├─ Client A ──stdio──▶ Server: filesystem
 ├─ Client B ──stdio──▶ Server: git
 └─ Client C ──HTTP──▶ Server: 公司內部 API
```
★ **一對一的理由是「隔離」**：
- 每個連線有**獨立的生命週期**（一個 server 掛掉不影響其他）
- 每個連線有**獨立的能力協商結果**（各 server 支援的原語不同）
- **狀態不會互相污染**（通知、訂閱、會話狀態各自獨立）

★ **Host 的職責是「聚合」**：把多個 server 的工具彙整成一份清單交給模型
（這時就會遇到 [[工具集設計]] 的「幾個工具太多」問題）。

### ★ MCP 在整個堆疊中的位置（最常被問的區分）

```
┌────────────────────────────────────────┐
│ 模型層：Function Calling               │  ← 模型決定「呼叫哪個工具、帶什麼參數」
│   這是「模型的能力」，和 MCP 無關      │
└────────────────────────────────────────┘
                 ▲ 工具定義從哪來？
┌────────────────────────────────────────┐
│ 整合層：MCP                            │  ← 標準化「工具怎麼被發現、描述、呼叫」
│   Host/Client/Server + JSON-RPC        │
└────────────────────────────────────────┘
```
> ★★ **MCP 不取代 function calling，它解的是「M×N 問題」**：
> M 個 AI 應用要接 N 個資料源 → 原本要寫 M×N 個整合，**MCP 讓它變成 M+N**。
> **模型端仍然是用 function calling 的方式決定要呼叫什麼。**
> （完整對照見 [[Function Calling 與結構化輸出]]。）

### ★ 三大原語與它們的「誰主動」

| 原語 | 誰控制 | 用途 |
|---|---|---|
| **Tools** | ★ **模型決定何時呼叫** | 有副作用的動作、查詢 |
| **Resources** | ★ **應用/使用者決定要附帶什麼** | 檔案內容、資料庫 schema、文件 |
| **Prompts** | ★ **使用者主動選擇** | 預先寫好的提示模板（slash command） |

★ **這個「誰主動」的區分是 MCP 設計的核心**：
> **不是所有情境都該由模型決定。**
> Resources 讓**應用**決定附帶什麼情境（避免模型亂抓）；
> Prompts 讓**使用者**選擇工作流（可預測、可重複）。
> **把該給使用者的控制權還給使用者**，而不是全部丟給模型自己判斷。

### ★ 能力協商（capability negotiation）在協商什麼

```jsonc
// client → server
{ "method": "initialize", "params": {
    "protocolVersion": "2025-xx-xx",
    "capabilities": { "roots": { "listChanged": true }, "sampling": {} }
}}
// server → client
{ "result": {
    "protocolVersion": "2025-xx-xx",          // ★ 協商出單一版本，不相容就終止
    "capabilities": {
      "tools":     { "listChanged": true },   // ★ 我會在工具變動時通知你
      "resources": { "subscribe": true },     // ★ 我支援訂閱資源變更
      "prompts":   {}
    }
}}
```
★ **協商的是「雙方各自支援哪些可選功能」**，而不只是版本號。
→ **所以 client 不能假設 server 支援 `listChanged`**，要看協商結果再決定要不要監聽通知。

### ★ 通知（notification）：為什麼需要它

**JSON-RPC 的 notification 是「不需要回應的訊息」**，MCP 用它做**動態更新**：

| 通知 | 意思 |
|---|---|
| `notifications/tools/list_changed` | ★ 工具清單變了，**請重新 `tools/list`** |
| `notifications/resources/updated` | 你訂閱的資源變了 |
| `notifications/resources/list_changed` | 資源清單變了 |
| `notifications/initialized` | client 告訴 server「握手完成，可以開始了」 |

★ **`list_changed` 讓 server 可以在執行期改變它提供的工具**——
例如「使用者登入後才出現管理員工具」。
**沒有這個機制，工具清單就只能在連線時固定。**

### ★ 典型的完整資料流

```
① initialize            client → server   （含 capabilities）
② initialize result     server → client   （協商結果）
③ notifications/initialized  client → server
   ───────── 握手完成 ─────────
④ tools/list            client → server   （發現有哪些工具）
⑤ ★ host 把工具定義餵給模型（此時進入 function calling 的世界）
⑥ tools/call            client → server   （模型決定呼叫後）
⑦ result / error        server → client
⑧ notifications/tools/list_changed  server → client  （必要時）
   → 回到 ④
```
★ **⑤ 是 MCP 與模型的交界**：MCP 只負責「拿到工具定義」與「執行呼叫」，
**「決定呼叫什麼」完全是模型的事。**

## 🧪 我實際套用的紀錄
- 2026-07-26：（待填）

## ⚠️ 注意 / 什麼時候不適用

- **★★ 每個 MCP server 都是一個信任邊界**。第三方 server 看得到你餵進去的內容，
  而且**它的工具描述會進入你的 prompt**（注入載體，見 [[提示注入與分層防禦]]、[[工具-MCP安全防護要點]]）。
- **★ 工具太多會讓模型選錯**。接了五個 server = 可能有四十個工具 →
  **要做工具篩選或動態載入**（見 [[工具集設計]]）。
- **★ 協定版本會演進**。要優雅處理不相容，不要假設對方和你同版本。
- **不要假設 server 支援所有可選能力**。看協商結果，不要看文件上寫的。
- **server 的錯誤要能被模型理解**。回傳的錯誤訊息會進入模型的上下文——
  **寫成「模型看得懂並能修正」的形式**（見 [[工具集設計]] 的回傳設計）。
- **★ MCP 不是通用 RPC**。服務之間的一般通訊用 gRPC/HTTP；**MCP 是為「AI 應用取得情境與能力」設計的。**
- **stdio server 的 stdout 只能傳協定訊息**（見 [[工具-選擇MCP傳輸方式]]）。

## 🔗 相關工具
- [[Function Calling 與結構化輸出]] —— ★ MCP 與 function calling 在不同層
- [[工具-MCP三大伺服器原語]] —— Tools/Resources/Prompts 的細節
- [[工具-MCP用戶端原語]] —— sampling、roots、elicitation
- [[工具-選擇MCP傳輸方式]] —— 傳輸層
- [[工具-MCP安全防護要點]] —— 信任邊界
- [[工具集設計]] —— 工具數量與描述的設計
- [[提示注入與分層防禦]] —— 工具描述作為注入載體
- [[MCP 官方文件]]
