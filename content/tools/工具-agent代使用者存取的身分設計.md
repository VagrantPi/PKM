---
type: tool
name: "agent 代使用者存取的身分設計（OBO／3LO）"
source: "[[AgentCore 與 Nova Act 研究]]"
source_type: article
tags: [software, ai, agent, security, oauth, identity, multi-tenant]
triggers: [agent要代替使用者呼叫內部API, 直接把使用者的token轉給下游安不安全, agent要讀使用者的Google或Slack資料, 多租戶的第三方授權token怎麼保管]
---

## 🎯 什麼情境該想到我
當你「的 agent 要代表某位使用者去呼叫下游服務（內部 API、使用者的行事曆或 Slack），得決定用什麼身分、帶哪張 token」的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 1. 先分清三種 outbound 模式

| 模式 | OAuth 流程 | 適合 |
|---|---|---|
| **自主（M2M／2LO）** | client credentials | agent 以**自己的身分**存取系統資源（查公司內部 API） |
| **使用者授權（3LO）** | authorization code | 要**使用者本人同意**才能碰他的資料（他的 Google 行事曆） |
| **代理換發（OBO）** | token exchange（RFC 8693）或 JWT bearer（RFC 7523） | 使用者已登入你的系統，**不再詢問同意**，換一張只給下游用的新 token |

### 2. 不要直接轉傳使用者的 token

| | 直接轉傳 | OBO |
|---|---|---|
| audience | 前端 app（下游其實不該接受） | **下游自己** |
| scope | 前端要的所有權限 | 只有下游需要的 |
| 下游知不知道是 agent 在操作 | 不知道 | 知道 |
| 外洩的影響 | 可冒充使用者呼叫**所有接受這張 token 的服務** | 只能呼叫那一個下游 |
| 撤銷 | 只能撤掉使用者整個登入 | 可只撤 agent 的權限（依 IdP） |

★ 直接轉傳之所以「能動」，通常是因為**下游根本沒檢查 audience**，這本身就是漏洞。

### 3. OBO 的每一層：audience 只寫自己、scope 一路縮小
以「客服 agent 代使用者查訂單」為例：`使用者 →(1) agent →(2) 工具閘道 →(3) 內部訂單 API`

| 段 | `aud` | `scope` | 誰驗證 |
|---|---|---|---|
| (1) 使用者登入的 token | agent 的 app ID | `agent.invoke` | agent 的 JWT 驗證 |
| (2) 第一次換發 | 閘道的 app ID | `tools.invoke` | 閘道 inbound 驗證 |
| (3) 第二次換發 | 訂單 API 的 app ID | `orders.read` | **訂單 API 自己** |

- 每一層都要在 IdP 註冊成獨立的 app（resource server），才能當換發對象。
- **最後一段最重要**：真正存取資料的 API 必須**同時驗使用者與 agent**，才做得到「本人可以改訂單，透過 agent 只能查」：
```python
claims = verify_jwt(token, issuer=ISSUER, audience="api://orders")  # 簽章、到期、aud
user  = claims["sub"]
agent = claims.get("xms_act", {}).get("sub")   # Entra 的寫法；claim 名稱依 IdP 而定
if agent is not None and request.method != "GET":
    deny()   # 透過 agent 只能查
```
- **「agent 是誰」放在哪個 claim 由 IdP 決定**，不是 RFC 8693 標準的 `act`。例如 Entra 把使用者放 `sub`、中間層放 `xms_act.sub`。換 IdP 就要改驗證碼。

### 4. 看你的 IdP 支不支援（依原研究，查證 2026-09-30）
- **Entra ID**：最成熟（`JWT_AUTHORIZATION_GRANT`，自動帶 `requested_token_use=on_behalf_of`）。常見錯誤 `AADSTS500131`：使用者 token 的 `aud` 不是 agent app，登入 scope 要用 `<AGENT_CLIENT_ID>/.default`。
- **Okta**：支援 token exchange，要多帶 `audience`；預設不發 `client_id` claim。
- **Cognito**：**token 端點不支援 token exchange**。實際做法：閘道用 service role 或 M2M 呼叫下游，使用者身分用 header 傳遞，並靠「只有閘道能呼叫下游」保證 header 可信（見 [[工具-讓Gateway當agent唯一入口]]）。這不是真正的 OBO，但好維護。
- 能用私鑰簽章（`PRIVATE_KEY_JWT`）或雲端 IAM 簽發的 JWT 當 client 驗證，就不要用 client secret，少一個要輪替的機密。

### 5. 3LO：使用者同意流程的重點
- **有兩個 callback，別搞混**：第三方（Google、Slack）後台註冊的是**平台的 callback**（平台用授權碼換 token）；**你自己的 callback** 要自己實作，負責確認「按下同意的人」是誰，再通知平台完成（AgentCore 是 `CompleteResourceTokenAuth`）。
- **session binding 只有一句話**：callback 裡的使用者身分，**只能從瀏覽器自己的登入 session（cookie）取得**，不能從 query string 或遠端快取拿。否則攻擊者把授權連結丟給受害者，就能讓平台誤以為同意的人就是發起者，受害者的第三方授權因此綁到攻擊者身上（後半句為推論）。
- 補強做法：發出授權連結時記下「這個連結是給誰的」、**一次性使用**、10 分鐘過期；兩邊一致才完成。原研究的本機測試：沒登入 400、別人拿到連結 403、重放 400、過期 400。
- **授權 URL 怎麼送到前端**：SDK 預設會卡住工具呼叫、每 5 秒輪詢、最多 10 分鐘。對話型應用通常更適合「中斷這一輪 → 把 URL 推給前端 → 授權完再重來」。
- **一定要開 refresh token**（Google 帶 `access_type=offline`、Microsoft 加 `offline_access`…），不然 access token 1–2 小時一過期就要重新授權。
- **使用者在第三方撤銷授權，平台偵測不到**，會照樣回舊 token。在工具層包一層：呼叫第三方收到 401 → 強制重新授權（AgentCore 的 `forceAuthentication=true`）→ 送出新的授權 URL，不要讓模型自己對著 401 重試。

### 6. 多租戶的 token 保管
- **credential provider 不是租戶單位**：正常設計是**每個第三方服務一個 provider**（`google`、`slack`），由 vault 依「agent＋使用者」分開存每個人的 token。AgentCore 預設每帳號每區域各 50 個 provider（可調高）。
- 租戶隔離靠**使用者 ID 命名**（例如 `tenantA+user123`）加 IAM 條件（資源 ARN、`aws:ResourceTag` 做 ABAC）。命名錯了就會拿到別人的 token，這是共用模型的主要風險。
- 企業客戶要求自帶 IdP／OAuth app → 為他們建專屬 provider。需要**租戶各自一把 KMS 金鑰**或完全隔離 → **分帳號**（AgentCore 每帳號每區域只有一個 vault、一把 vault 金鑰）。
- **稽核「誰替誰拿了哪張 token」**：CloudTrail 裡的 workload token 被遮蔽，看不到終端使用者，要靠 trace span 或串接其他事件還原。

機制細節 → [[AgentCore Identity]]

## 🧪 我實際套用的紀錄
- 2026-09-30：原研究的 3LO callback 做過本機實驗；OBO 設計**沒有實際部署驗證**，是依官方文件與範例推導。

## ⚠️ 注意 / 什麼時候不適用
- **下游一定要驗 `aud`**，這是 OBO 安全性的來源；不驗的話，做了 OBO 也沒用。
- 只需要 agent 自己的身分（例如查公共資料、內部報表）時，用 M2M 就好，不必上 OBO。
- AgentCore 的 IAM ARN 格式文件前後不一致（`oauth2-credential-provider` vs `oauth2credentialprovider`）。**寫錯格式不會報錯，只是靜默地不符合**，一律以 IAM service reference 為準。
- 禁止「呼叫端自己指定要代表哪個使用者」（AgentCore 的 `ForUserId` 類 API）要在兩處都 Deny；只 Deny agent 的 execution role 可能無效（推論：平台是透過 service-linked role 取 token）。

## 🔗 相關工具
- [[AgentCore Identity]] —— 三種模式的 API、3LO 參考實作、多租戶配額的完整說明
- [[工具-讓Gateway當agent唯一入口]] —— 身分鏈要成立，前提是沒人能繞過閘道
