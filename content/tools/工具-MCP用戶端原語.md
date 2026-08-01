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

## 🧪 我實際套用的紀錄
- 2026-07-26：（待填）

## ⚠️ 注意 / 什麼時候不適用
- Roots 只是「請 server 自律」，不能當防線；不受信任的 server 仍可能越界。
- Sampling/Elicitation 都應保留使用者審核關卡，避免 server 藉此偷渡敏感操作。

## 🔗 相關工具
- [[工具-MCP三大伺服器原語]] —— 對稱的另一半，server 端的 Tools/Resources/Prompts，兩張配成完整的能力表
- [[工具-MCP架構與資料流]] —— 上位圖，解釋為什麼這三個能力是 client 反過來提供給 server 的
- [[工具-AI-Agent設計]] —— Sampling 的實際用途：讓 server 借用 client 的模型做多步推理，就落在 agent 這一塊

