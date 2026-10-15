---
type: tool
name: "MCP 用戶端原語 Sampling / Elicitation / Roots"
source: "[[MCP 官方文件]]"
source_type: article
tags: [software, mcp, ai, llm, integration, protocol]
triggers: [MCP server想用LLM但不想綁模型, server想跟使用者要輸入或確認, 想限制server能存取哪些目錄, MCP client要實作什麼能力, MCP server怎麼做互動]
---

## 🎯 什麼情境該想到我
當你的 MCP server「需要 LLM、需要問使用者、或需要知道能碰哪些檔案」，但又想保持乾淨、把控制權留給 client 的時候。這三個是 **client 反過來提供給 server** 的能力。

## ⚙️ 怎麼用（三選一，對應需求）
1. **Sampling（借用 LLM）**：server 用 `sampling/createMessage` 請 client 幫忙做 LLM 補全——這樣 server **不必自帶模型 SDK、不必自付 API 費、保持模型無關**。可帶 `modelPreferences`（cost/speed/intelligence 權重）、systemPrompt、maxTokens。設計上是 **human-in-the-loop**：使用者可審核/修改請求與回應。例：`findBestFlight` 把 47 個航班丟給 LLM 選最佳。
2. **Elicitation（向使用者要資訊）**：server 用 `elicitation/create` 帶一個 JSON schema，在流程中**動態要輸入或要確認**（別一開始就逼使用者填完所有欄位）。使用者可提供/拒絕/取消，client 會依 schema 驗證。**絕不可用來要密碼或 API key**。
3. **Roots（限定檔案範圍）**：client 用 `file://` URI 告訴 server「你該聚焦哪些目錄」；可隨使用者切換專案動態更新（`roots/list_changed`）。**這是協調機制、不是安全邊界**——真正的隔離要靠 OS 權限/sandbox。

### 先確認 client 有沒有宣告：能力協商（capability negotiation）
> 依 MCP 規格整理（查證 2026-10-15；目前最新規格版本 **2026-07-28**，來源筆記寫的是當時的 2025-11-25）。

這三個原語**都是選配**：client 支援才可以用，server 不可以假設對方一定有。

- **規格 2025-11-25（握手式，多數既有實作）**：連線一開始 client 送 `initialize`，在 `capabilities` 裡宣告自己支援哪些——例如 `"roots": {"listChanged": true}`、`"sampling": {}`、`"elicitation": {"form": {}, "url": {}}`。規格要求雙方「**只使用協商成功的能力**」。sampling 的子能力也要另外宣告：client 沒宣告 `sampling.tools`，server 就**不可**送帶 `tools` 的 sampling 請求。
- **規格 2026-07-28（目前最新）**：拿掉了 `initialize` 握手，改成 client 在**每一個請求**的 `_meta["io.modelcontextprotocol/clientCapabilities"]` 裡宣告能力。server 要 sampling／elicitation 時，不再主動發請求，而是在回應裡回傳 `InputRequiredResult`（`resultType: "input_required"`），把要問的東西放進 `inputRequests`，client 處理完再帶著 `inputResponses` **重送原請求**（Multi Round-Trip Requests）。規格明訂：client 沒宣告的能力，server **不可**放進 `inputRequests`（例：沒宣告 `elicitation` 就不能塞 `elicitation/create`）；elicitation 還要看模式，client 只宣告 `form` 就不能送 `url` 模式。
- **2026-07-28 已把 Sampling 與 Roots 標為 Deprecated**（SEP-2577；最早可移除的時間是 2027-07-28 之後發布的版本）：新實作**不應**再採用。官方遷移路徑——Sampling → **server 直接串 LLM 供應商 API**；Roots → 改由**工具參數、resource URI 或 server 設定**傳目錄。Elicitation 沒有被棄用。

**server 端的退路（fallback）怎麼設計**（自寫範例，非規格原文）：

| 想用的能力 | client 沒宣告時的退路 |
|---|---|
| Sampling | 改用 server 自己的模型 API key（失去「模型無關、不付費」的好處）；或不靠 LLM 做確定性的處理（例：航班照價格＋轉機次數排序取前 3）；或把候選結果整包回傳，讓 host 那邊的 LLM 在主對話裡挑 |
| Elicitation | 把需要的欄位直接寫進工具的 input schema 設成必填，一開始就要；缺了就回一個清楚說明「缺哪個參數」的錯誤，讓 host 的 LLM 回頭問使用者 |
| Roots | 讓使用者在 server 設定或工具參數裡明確給路徑；沒給就拒絕操作，不要自己猜一個目錄 |

實務上**很多 client 從沒實作 sampling**（推測：sampling 一直是選配、也是需要 UI 審核的重功能；2026-07-28 被棄用也印證採用度有限），所以**依賴 sampling 才能運作的 server，等於只在少數 client 上能用**——一定要有上面的退路。

最小 `sampling/createMessage` 請求骨架（2025-11-25 的 JSON-RPC 形式，依規格範例精簡）：

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "sampling/createMessage",
  "params": {
    "messages": [
      { "role": "user", "content": { "type": "text", "text": "從下列 47 個航班挑出最划算的 3 個：..." } }
    ],
    "modelPreferences": { "costPriority": 0.3, "speedPriority": 0.5, "intelligencePriority": 0.8 },
    "systemPrompt": "你是訂票助理。",
    "maxTokens": 300
  }
}
```

client 回傳的 `result` 形如 `{"role":"assistant","content":{"type":"text","text":"..."},"model":"<實際用的模型>","stopReason":"endTurn"}`；使用者在審核關卡按拒絕時，client 應回錯誤碼 `-1`（"User rejected sampling request"），server 要能接住這個錯誤走退路。在 2026-07-28 裡，同一份 `{"method": "sampling/createMessage", "params": {...}}` 不帶 `jsonrpc`／`id`，而是包在 `InputRequiredResult.inputRequests` 裡以自訂鍵名（例 `"pick_flights"`）回給 client。

## 🧪 我實際套用的紀錄
- 2026-07-26：（待填）

## ⚠️ 注意 / 什麼時候不適用
- Roots 只是「請 server 自律」，不能當防線；不受信任的 server 仍可能越界。
- Sampling/Elicitation 都應保留使用者審核關卡，避免 server 藉此偷渡敏感操作。
- **沒先檢查能力就直接用**：server 對沒宣告 sampling／elicitation 的 client 發請求，是違反規格的；輕則請求失敗，重則整個工具呼叫卡住沒回應（推測）。寫 server 時先讀 client 宣告的能力再決定走哪條路。
- **新專案別再把 Sampling、Roots 當核心依賴**（查證 2026-10-15）：兩者在規格 2026-07-28 已被棄用，最早 2027-07-28 之後的版本就可能移除。

## 🔗 相關工具
- [[工具-MCP三大伺服器原語]] —— 對稱的另一半，server 端的 Tools/Resources/Prompts，兩張配成完整的能力表
- [[工具-MCP架構與資料流]] —— 上位圖，解釋為什麼這三個能力是 client 反過來提供給 server 的
- [[工具-AI-Agent設計]] —— Sampling 的實際用途：讓 server 借用 client 的模型做多步推理，就落在 agent 這一塊

