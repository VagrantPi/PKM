---
type: tool
name: "MCP 安全防護要點 MCP Security Checklist"
source: "[[MCP 官方文件]]"
source_type: article
tags: [software, mcp, security, ai, integration, protocol]
triggers: [MCP server安全怎麼顧, 遠端MCP授權OAuth怎麼做, MCP有什麼攻擊面, 串接第三方MCP server風險, MCP的token session怎麼處理]
---

## 🎯 什麼情境該想到我
當你要**發布**一個遠端 MCP server，或**串接**別人的 MCP server，想確認授權與攻擊面有沒有顧好的時候。

## ⚙️ 怎麼用（發布/串接前的檢查清單）
1. **授權用 OAuth、全程 HTTPS**：遠端 server 用 OAuth 取得 token；授權 URL **只允許 `http://`/`https://` scheme** 並**必須用 `https://`**、驗證 redirect/authorization URL，別接受任意 URL。
2. **別拿 session 當身分驗證**：`MUST NOT use sessions for authentication`；session ID 要**不可預測（non-deterministic）**並**綁定使用者資訊**，防 session 劫持/冒充。
3. **禁止 Token Passthrough**：server 不可把「不是發給自己」的 token 直接轉發給下游 API——這會繞過授權邊界（Confused Deputy）。
4. **執行動作前先取得同意**：`MUST implement proper consent mechanisms prior to executing commands`；tool 由模型自動叫用，務必留人類核准關卡。
5. **防 SSRF**：server 若會依輸入去打 URL，要驗證/白名單目標，避免被誘導打內網。
6. **最小權限（Scope Minimization）**：只要必要的 scope 與資源存取；Roots 只是協調非強制邊界，真正隔離靠 OS 權限/sandbox。
7. **本地 server 也有風險**：本地 MCP server 若被植入惡意程式會直接在你機器上執行；`MUST NOT` 用未信任輸入去**組裝 shell 指令**。只裝可信/審過的 server。

## 🧪 我實際套用的紀錄
- 2026-07-26：（待填）

## ⚠️ 注意 / 什麼時候不適用
- 這是要點清單；正式實作請對照官方 Authorization 規格與 Security Best Practices 全文。
- 安全不是單點——授權、傳輸、同意、範圍要一起做才有效。

## 🔗 相關工具
- [[工具-選擇MCP傳輸方式]] —— 安全需求直接影響傳輸選型：走遠端 HTTP 才需要認證與授權那一整套
- [[工具-MCP用戶端原語]] —— 攻擊面主要在這裡：Sampling 會用到 LLM、Roots 決定能碰哪些檔案，都需要同意關卡
- [[工具-服務容錯設計]] —— 補上可用性那一面：安全顧的是「不被打」，容錯顧的是「下游掛了不要雪崩」

