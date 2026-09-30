---
type: reference
name: "AgentCore Identity 代理身分與憑證 Identity"
source: "[[AgentCore 與 Nova Act 研究]]"
source_type: docs
tags: [ai, llm, agent, aws, agentcore, identity, oauth, security]
triggers: [agent要代替使用者去存取他的Google或Slack, 第三方OAuth token不想自己存在資料庫, 使用者授權連結被轉傳給別人怎麼辦, agent呼叫內部API時下游分不出是人還是agent, 多租戶共用一個OAuth app怕拿錯別人的token]
---

> 原始研究：[GitHub](https://github.com/VagrantPi/AagentCore-Research/tree/main/04-identity)（依原研究，查證 2026-09-30）

## 🎯 什麼情境該想到我
當你「要讓 agent 代表某個登入的使用者，去呼叫他的 Google Drive、Slack、GitHub 或公司內部 API，又不想讓 token 外洩或被冒用」的時候。

## ⚙️ 怎麼用

### 一句話定位
Identity 同時處理兩個身分：**「誰在呼叫 agent」（inbound）**與**「agent 代表誰、用哪張憑證去呼叫外部服務」（outbound）**。設計目標是每一次存取都說得清楚「哪個 agent、代表哪個使用者、拿哪張憑證、存取什麼資源」，而且憑證只有同一組「agent + 使用者」拿得回來。

為什麼不用一般後端做法：

| 一般做法 | 問題 |
|---|---|
| agent 用共用服務帳號存取所有人的資料 | 分不出是誰的請求；prompt injection 一成功就能讀所有人的資料 |
| 把使用者 token 直接傳給 agent | audience 太寬，任何一方外洩影響都大；下游不知道是 agent 在代操作 |
| 自己 DB 存第三方 refresh token | 要自己處理加密、刷新、撤銷，還要對付每家 SaaS 不同的 OAuth 實作 |

### 核心名詞

| 名詞 | 作用 |
|---|---|
| **Workload identity** | agent 自己的身分；用 Runtime / Gateway 時自動建立，名稱就是 runtime ID 或 gateway ID |
| **Workload access token** | AWS 簽發的不透明 token，**同時綁定 agent 與使用者**，只能拿來呼叫 AgentCore 自家服務（例如向 vault 取憑證） |
| **Credential provider** | 對某個外部服務的連線設定（OAuth client ID/secret、API key）。內建 20 多家範本（Google、Microsoft、GitHub、Slack、Salesforce、Okta…），也可自訂 |
| **Token vault** | 以「agent + 使用者」為 key 保管 OAuth access/refresh token 與 API key |
| **Consent portal** | AWS 代管的同意頁，掛在用 JWT 驗證的 Gateway 上；整個 OAuth 流程在伺服器端完成，瀏覽器拿不到 token |

### 一次 outbound 存取怎麼跑（Runtime 模式）
1. 使用者登入 IdP 拿到 JWT，前端帶著 JWT 呼叫 `InvokeAgentRuntime`。
2. Runtime 驗證 JWT，取出 `iss` + `sub`，呼叫 `GetWorkloadAccessTokenForJWT` 換到 workload access token，放進請求 header 交給 agent 程式。
3. agent 程式用 SDK 的 `@requires_access_token` 裝飾器，背後呼叫 `GetResourceOauth2Token(provider=google)`。
4. vault 有有效 token（或能用 refresh token 換新）→ 直接回 access token；第一次或已失效 → 回傳**授權 URL + session URI**，進入 3LO（見下）。
5. 拿到 token 後呼叫第三方 API。

重點：Runtime/Gateway 自動建立的 workload identity **不能被 agent 程式直接拿去換 token**（官方刻意設計），agent 只能用 Runtime 放進 header 的那一張。

### 三種 outbound 模式

| 模式 | OAuth 類型 | 適用 |
|---|---|---|
| **M2M / 2LO** | Client credentials | agent 以自己身分查公司內部系統 |
| **3LO（使用者授權）** | Authorization code | 要使用者本人同意才能碰他的資料，例如行事曆 |
| **OBO（代表使用者換發）** | Token exchange（RFC 8693）或 JWT bearer（RFC 7523） | 使用者已登入你的系統，**不再問同意**就換一張只給下游用的 token |

### 3LO：兩個 callback 與 session binding
**有兩個 callback，最容易搞混：**
1. **AgentCore 的 callback**：`CreateOauth2CredentialProvider` 回傳、每個 provider 各一個，要註冊到 Google/Slack 的 OAuth app 後台。第三方把授權碼送到這裡，由 AgentCore 換 token。
2. **你的 callback**：用 `update-workload-identity --allowed-resource-oauth2-return-urls` 註冊到 workload identity。AgentCore 授權完把瀏覽器導回這裡（帶 `session_id`），由你確認「按同意的人是誰」後呼叫 `CompleteResourceTokenAuth`。**這個一定要自己實作**；本機 `agentcore dev` 會代管，部署後才發現沒做是常見坑。

**Session binding 的攻擊情境：** A 把授權 URL 傳給 B，B 按同意後，B 的帳號就被綁到 A 的 agent session 上（或反過來）。防法的核心只有一句：**callback 裡的使用者身分只能從瀏覽器自己的登入 session（cookie）取得**，官方原文要求「should NOT be pulled from any remote session cache」。`CompleteResourceTokenAuth` 的 `userIdentifier`（`userId` 或 `userToken`）必須跟發起時換 workload token 用的是同一個身分；比對是 AgentCore 做，你的責任是確保傳進去的身分是真的。不一致時官方建議「什麼都不做或記錄」。

其他數字與欄位：授權 URL 與 session URI **10 分鐘**有效；`customState`（最多 4,096 字元）用來防 CSRF；`forceAuthentication=true` 會強制重新授權並清掉 refresh token。

**授權 URL 怎麼送到前端：** SDK 預設拿到 URL 後呼叫你的 `on_auth_url`，接著**每 5 秒輪詢、最多 600 秒**，也就是工具呼叫會卡住最多 10 分鐘。

| 送法 | 適合 |
|---|---|
| 串流：把 `{"type":"authorization_required",...}` 寫進 SSE/WebSocket | 對話型應用（最常見） |
| Callback/webhook：後端推播、Email、Slack 通知 | 非同步長時 agent（10 分鐘就過期要留意） |
| 輪詢：URL 存起來讓前端查 | 前端不支援串流 |

研究的判斷：大多數對話型應用適合**「中斷重來」**——`on_auth_url` 丟例外、這一輪結束、使用者授權後重送；比「卡住等待」省 Runtime 計費、逾時行為清楚（AWS 2026-05 的 ECS 範例亦然）。經過 Gateway 的 MCP 工具不用自己處理：Gateway 回 MCP URL 型 elicitation 錯誤（JSON-RPC `-32042`）帶著授權 URL。

**Refresh token 要各家各自開啟**，否則 access token 一過期（通常 1–2 小時）就要重按同意：Google `access_type=offline`；Microsoft、Atlassian 加 `offline_access` scope；Salesforce 加 `refresh_token` scope 並開 PKCE；GitHub 開「User-to-server token expiration」；Slack 開 token rotation；LinkedIn 開 refresh token。Refresh token 也過期（通常約 30 天）時會回新的授權 URL。**使用者在第三方撤銷授權，AgentCore 偵測不到**，照樣回舊 token——要在工具層包一層「收到 401 → 帶 `forceAuthentication=true` 重拿 → 送出授權 URL」，不要讓模型自己看著 401 亂重試。

### OBO：每一層的 audience 只寫自己
OBO 的做法：Identity 拿「使用者的 inbound token」＋「credential provider 的 client 憑證」向你的 IdP 換一張**只給下游用**的新 token，裡面同時帶使用者與 agent 身分，**核不核准由 IdP 決定**。呼叫方式 `GetResourceOauth2Token(oauth2Flow=ON_BEHALF_OF_TOKEN_EXCHANGE, …)`。

以「客服 agent 代使用者查訂單」為例，每層各註冊一個 app、scope 一路縮小：

| 段 | `aud` | scope | 誰驗證 |
|---|---|---|---|
| 使用者 → Runtime | Agent app | `agent.invoke` | Runtime JWT authorizer |
| Runtime → Gateway（第一次換發） | Gateway app | `tools.invoke` | Gateway inbound |
| Gateway → 訂單 API（第二次換發） | 訂單 API | `orders.read` | 訂單 API 自己，**同時驗使用者與 agent** |

最後一段最重要：下游只驗使用者，就做不出「本人可改訂單、透過 agent 只能查」這種規則；OBO 讓下游能依「是否經 agent」套不同規則，直接轉傳做不到。

**跟直接轉傳比：** 轉傳的 token `aud` 是前端 app、scope 是全部、外洩後能冒充使用者呼叫所有接受它的服務；轉傳「能運作」通常只是因為下游沒認真驗 `aud`。

**設定：** `onBehalfOfTokenExchangeConfig` 的 `grantType` 為 `TOKEN_EXCHANGE`（送 `subject_token`＋`actor_token`）或 `JWT_AUTHORIZATION_GRANT`（送 `assertion`）。actor token 來源：`M2M`（最常見）、`AWS_IAM_ID_TOKEN_JWT`（`sts:GetWebIdentityToken`，不必在 IdP 存 client secret）、`NONE`。研究建議能用 `PRIVATE_KEY_JWT`（KMS 簽章）或 `AWS_IAM_ID_TOKEN_JWT` 就別用 client secret，少一個要輪替的機密。

**IdP 差異：**
- **Entra ID 最成熟**：內建 `MicrosoftOauth2`，走 JWT bearer 並自動加 `requested_token_use=on_behalf_of`。換發後使用者在 `sub`、中間層在 `xms_act.sub`（**不是 RFC 8693 標準 `act`**）。常見錯誤 `AADSTS500131`：使用者 token 的 `aud` 不是 Agent app，登入 scope 要用 `<AGENT_CLIENT_ID>/.default`。
- **Okta**：`TOKEN_EXCHANGE`，要在 `customParameters` 多帶 `audience`；預設不發 `client_id` claim，要用 `allowedClients` 得先加。
- **Cognito 不支援**：token 端點沒有這兩種 grant；AWS 有「兩個 user pool＋CUSTOM_AUTH」的變通範例，等於自己維護換發邏輯。研究判斷：此時較實際的是 Gateway 用 service role/M2M 呼叫下游、使用者身分以 header 傳遞，靠「只有 Gateway 能呼叫下游」保證可信——不是真 OBO，但好維護。

### 安全重點

**ForJWT vs ForUserId（最重要）：**

| | `GetWorkloadAccessTokenForJWT` | `GetWorkloadAccessTokenForUserId` |
|---|---|---|
| 使用者身分來源 | JWT 的 `iss`+`sub`，**驗簽章與過期** | 呼叫端給的字串，**不驗證** |
| 適合 | 正式環境 | 開發，或上游已確認身分的架構 |

vault 以「agent + 使用者」為 key，**userId 被偽造就能拿到別人的第三方 token**。禁用要放對地方：
- **Runtime 上的 agent**：在呼叫端 role（或 SCP）Deny `InvokeAgentRuntimeForUser`（它對應 header `X-Amzn-Bedrock-AgentCore-Runtime-User-Id`）。研究推論：2025-10-13 之後建立的 Runtime 是透過 service-linked role 取 token，只 Deny execution role 可能沒效。
- **自架 agent**：在 agent role Deny `GetWorkloadAccessTokenForUserId`。最保險是整個 OU 用 SCP Deny 兩者，再開例外。
- 非用不可時（例如 ALB 前接 Entra，後端只有 ALB 簽章的 `x-amzn-oidc-data`）：userId 必須從已驗證來源推導、多 IdP 加前綴（`cognito+user123`），研究推論可用 condition key `bedrock-agentcore:userid` 以 `StringLike "tenantA+*"` 強制租戶前綴。

**權限範圍：** 官方**沒有強制**「哪個 agent 只能用哪個 provider」，全靠 IAM `Resource` 寫到具體 workload identity ARN 與 provider ARN；`GetResourceOauth2Token`／`GetResourceApiKey` 沒有 condition key，只能限資源，可用 `aws:ResourceTag` 做 ABAC。VM 內程式拿得到 execution role 憑證，被 prompt injection 時能拿到該 role 允許的所有 provider 的 token（限當前使用者）。

**Inbound JWT authorizer：** Runtime 與 Gateway 同一套 `customJWTAuthorizer`：`discoveryUrl` 必填，`allowedAudience`／`allowedClients`／`allowedScopes`／`customClaims`（`EQUALS`、`CONTAINS`、`CONTAINS_ANY`）至少設一項，設了的全部要過。**一定要設 audience**，否則別的服務的 token 也能打你的 agent。

**加密：** vault 預設 AWS 擁有的 KMS 金鑰，可換 CMK（僅單區域對稱金鑰、要填 ARN 不能用 alias）；provider 的 secret 在 Secrets Manager。

### 多租戶切分
每帳號每區域**只有 1 個 vault、1 個 identity directory、1 把 vault KMS 金鑰**（研究依 API 結構推論）。三種模型：
- **共用 provider（建議預設）**：每個第三方服務一個 provider，使用者 ID 帶租戶前綴。代價是租戶間只靠 ID 區分。
- **租戶自帶 OAuth app**：每租戶一個 provider（如 `acme-okta`），50 個很快用完。
- **每租戶一個帳號**：法規或租戶要各自 KMS 金鑰時，維運成本最高。

### 稽核：誰替誰拿了哪張 token
- **CloudTrail 回答不了「替誰」**：`GetResourceOauth2Token` 事件的 `workloadIdentityToken` 被遮成 `HIDDEN_DUE_TO_SECURITY_REASONS`；能看到哪個 role、哪個 provider、scope。
- **Span**（開啟 identity observability 後）：`GetWorkloadAccessTokenForJWT` 有 `issuer`、`user_sub`；`GetResourceOAuth2Token` 有 `workload.identity.id`、`credential.provider.name`；以 trace ID 串起來就能還原「使用者 → agent → provider」。**ForUserId 的 span 沒有使用者 ID**，這是禁用它的另一個理由。
- 研究建議：對 `GetWorkloadAccessTokenForUserId`、`UpdateOauth2CredentialProvider`、`UpdateWorkloadIdentity` 設告警，並在自己的 log 記「使用者、服務、trace ID」補缺口。

### 配額與計費（研究查證日 2026-09-30）
Workload identity 11,000；OAuth2／API key／Payment credential provider **各 50**（可調高）；`GetWorkloadAccessToken*` 與 `GetResourceOauth2Token`／`GetResourceApiKey` 各 200 TPS；`CompleteResourceTokenAuth` 100 TPS。計費：存取非 AWS 資源每千次 $0.010，**經 Runtime/Gateway 使用免費**。每次工具呼叫都要先取 token，所以 200 TPS 也是帳號工具呼叫量的上限之一（研究推論）。

## ⚠️ 注意 / 什麼時候不適用
- **文件矛盾（研究指出）：**
  - AgentCore callback URL 格式兩頁不同（`…/identities/callback/<id>` vs `…<region>…/identities/oauth2/callback/<uuid>`），以 API 實際回傳為準。
  - provider ARN 有 `oauth2-credential-provider` 與 `oauth2credentialprovider` 兩種寫法，**寫錯的 policy 不報錯、只是靜默不符合**，一律用 IAM service reference 的無連字號格式。
  - 標籤頁 ABAC 範例的 `bedrock-agentcore:ResourceTag/Owner` 不是列出的 condition key，標準是 `aws:ResourceTag/Owner`。
  - 取 token 事件是管理事件還是資料事件，CloudTrail 文件與部落格範例互相矛盾；若是資料事件預設不記錄，建議兩種都開再實測。
  - Gateway 的 OBO 文件寫只支援 MCP server 與 OpenAPI target、不支援 Runtime target，但官方範例用了。
- `customState` 帶回 callback 用的 query 參數名稱文件沒寫，要實測；Consent portal 的「Disconnect」會不會呼叫第三方撤銷端點也沒寫。
- 官方 3LO 範例的 callback server 只在記憶體存**一個**使用者、不檢查 cookie，只適合單人測試，不符合官方自己的 session binding 要求。
- Gateway 的 DYNAMIC 模式 MCP target 不能搭配 3LO；Consent portal target 的 `defaultReturnUrl` 必須是 `<portalUrl>/connect/callback`，連線清單快取 5 分鐘。
- JWT 的 `sub` 會進 CloudTrail，不要放個資。
- Nova Act 官方範例把 `@requires_access_token` 拿到的 token **直接寫進 act 的 prompt**，研究視為反例：token 只該在程式碼層使用，不要讓模型看到。
- 不適用：完全不代表使用者的內部工具，M2M 就夠，不需要 3LO/OBO（推測）。

## 🧪 我實際套用的紀錄
- **3LO callback 參考實作**（[experiments/3lo-callback](https://github.com/VagrantPi/AagentCore-Research/tree/main/04-identity/experiments/3lo-callback)）：純 Python 標準函式庫 WSGI，`CompleteResourceTokenAuth` 以假 client 代替、未接真實服務。在官方要求之外多做三個檢查：記下 `sessionUri → 發起者`（一次性、10 分鐘過期）、只從 cookie 取回來的人、兩者一致才完成。6 個案例本機全通過：未登入 400、mallory 拿 alice 的連結 403、alice 正常 200、同 session_id 重放 400、被轉傳過的連結 alice 自己再用也失效 400（刻意設計：被別人用過一次就作廢）、超過 10 分鐘 400。正式環境要把記憶體儲存換成有 TTL 的共享儲存（DynamoDB、Redis）。
- OBO 設計與多租戶 IAM policy **未實際部署驗證**；Logs Insights 稽核查詢也沒實跑過。

## 🔗 相關
- [[AgentCore Runtime]]
- [[AgentCore Gateway]]
- [[AgentCore Payments]]
- [[AgentCore Observability]]
- [[Nova Act 與AgentCore整合及安全]]
- [[工具-MCP安全防護要點]]
- [[可逆性、審計與人類把關]]
