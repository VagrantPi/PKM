---
type: reference
name: "AgentCore Gateway 統一入口 Gateway"
source: "[[AgentCore 與 Nova Act 研究]]"
source_type: docs
tags: [ai, llm, agent, aws, agentcore, gateway, mcp, llm-proxy, security]
triggers: [agent 接的工具一多每輪都在燒 token, 想把公司內部 API 變成 agent 能呼叫的工具, 怕使用者繞過入口直接打到後面的 agent, 想讓各團隊共用一個 LLM 端點又要分別限額, 不想讓每個應用都拿著 OpenAI 或 Anthropic 的金鑰]
---

> 原始研究：[GitHub](https://github.com/VagrantPi/AagentCore-Research/tree/main/03-gateway)（依原研究，查證 2026-09-30）

## 🎯 什麼情境該想到我
當你「要讓 agent 透過單一入口使用工具、其他 agent 與模型，並在這個入口集中做驗證、限流、授權與憑證管理」的時候。

## ⚙️ 怎麼用

### 三種角色、三種 target
Gateway 已從「API 轉 MCP 工具」擴大成**agent 流量的統一入口**：

| 類別 | 做什麼 | 後端 | 不支援 |
|---|---|---|---|
| **MCP target** | 把多個後端聚合成**一個虛擬 MCP server**（路徑 `/mcp`），單一 `tools/list` | Lambda、API Gateway stage、OpenAPI、Smithy、遠端 MCP server、內建 connector（KB、Web Search、Memory…） | — |
| **HTTP target** | 直接轉送、不做協定轉換，依 `/<target>/…` 分流 | AgentCore Runtime、A2A、任意 HTTP 端點 | 能力同步、語意搜尋 |
| **Inference target** | LLM 代理：依請求 `model` 欄位轉送 | Bedrock（Mantle）、OpenAI、Anthropic、任何 OpenAI 相容端點 | — |

- 工具名稱一律是 **`${target名稱}___${工具名稱}`**（三個底線），後端（如 Lambda）要自己去掉前綴。
- 遠端 MCP server 兩種同步：**DEFAULT** 建立／更新時同步一次，之後後端變動要**手動呼叫 `SynchronizeGatewayTargets`**（非同步，大目錄要好幾分鐘）；**DYNAMIC** 每次呼叫即時查，但**不能搭語意搜尋與 3LO**。
- 支援 MCP 版本 `2026-07-28`、`2025-11-25`、`2025-06-18`、`2025-03-26`。`2026-07-28` 是無狀態版，elicitation／sampling 改用 multi round-trip，**往返的 `requestState` 是否屬於同一使用者要你的 server 自己驗**，Gateway 不檢查。

### Inbound：誰能呼叫

| 類型 | Gateway 做什麼 | 用途 |
|---|---|---|
| `CUSTOM_JWT` | 驗 discovery URL、audience、client、scope、自訂 claim；缺 scope 回 403＋`WWW-Authenticate` 讓 MCP client 自動發現 | 終端使用者、外部 agent |
| `AWS_IAM` | 驗 SigV4＋`InvokeGateway` 權限 | AWS 內部服務互呼 |
| `AUTHENTICATE_ONLY` | **只驗簽章不授權** | 過渡期把既有 Runtime 接到後面 |
| `NONE` | **什麼都不查** | 真的要公開、且已有自己的防護 |

後兩種**Gateway 本身不做授權**，沒搭 Policy／interceptor／後端授權，任何人都能打到你的後端。可用 `bedrock-agentcore:GatewayAuthorizerType` condition key 在組織層級禁建 `NONE`。JWT 的 `sub` **會進 CloudTrail**，不要放個資，用 GUID。

### Outbound：Gateway 用誰的身分呼叫後端
選項：service role（SigV4）、呼叫者 IAM、OAuth 2LO、3LO、**OBO 換發**、token 直通、API key，依 target 類型支援度不同（Lambda 只能 service role；Smithy 只有 service role 與 2LO）。
- **Service role 是所有 target 共用的**，它的權限＝任何呼叫者透過此 gateway 能碰到的上限。官方最小權限原則：**不同信任等級的 target 拆成不同 gateway**。
- **OBO 是官方建議的正式做法**：拿使用者 token 換一張範圍更小、audience 只限目標服務的新 token，同時帶「使用者是誰」與「agent 是誰」，下游每層都能各自授權。Token 直通只建議試驗期。
- **3LO**：使用者第一次用到需授權工具時回傳授權 URL（有效 10 分鐘）；同意後應用呼叫 `CompleteResourceTokenAuth`，由 Identity 驗證「發起的人＝按同意的人」（session binding），防授權 URL 被轉傳。

### 治理手段與分工

| 手段 | 能做 | 限制 |
|---|---|---|
| **Interceptor**（Lambda） | REQUEST：驗證、改寫、短路回應；RESPONSE：遮罩加工 | 每 gateway 各最多 1 個；Lambda 同步 **6 MB** 上限（大回應用 `payloadFilter` 排除 body）；可能被重試要冪等；HTTP／Runtime／inference target **不支援串流，只能 buffered**；MCP 串流時每個事件呼叫一次 |
| **Rate limit** | 依 JWT claim、IAM 身分、target、工具、模型（最多 10 維度）限流；inference 可限每分鐘 token；速率 0＝封鎖 | **預設 fail-open**（限流服務不可用或解析不到維度就放行）；變更最多 30 秒生效；每 gateway 50 條；**維度建立後不能改** |
| **Gateway rules** | 依呼叫者或路徑導流、切 configuration bundle、A/B | 每 gateway 20 條；權重只分 2 組；`weightedRoute` **只記載支援 HTTP target** |
| **Policy**（Cedar） | 呼叫工具前做確定性允許／拒絕 | 見 Policy 卡 |

原研究判斷：**授權用 Policy（宣告式、可稽核）、內容加工用 interceptor、防濫用用 rate limit（不能當安全邊界）、灰度用 rules**。Rate limit 在 rules 之前評估；interceptor 與授權規則的先後文件沒寫。

### 把內部 API 接成工具
**選 target 順序**：已在 API Gateway（REST）→ API Gateway stage target；有 OpenAPI 規格 → OpenAPI target；要組合多個 API 或自訂邏輯 → Lambda target；已有 MCP server → MCP server target。**Smithy 實際只能呼叫 AWS 服務**（官方：不支援非 AWS 的自訂 Smithy model）。

OpenAPI 限制重點：每個要曝露的 operation 必須有 `operationId`（它就是工具名，沒有就不會變工具——可刻意當白名單用）；不支援 `oneOf/anyOf/allOf`、`securitySchemes`（驗證改在 outbound 設）、callbacks、binary 等；伺服器 URL 不要用 host 變數；私有 IP 會被擋（用 `privateEndpoint`）；**SigV4 只在後端是 API Gateway、Lambda Function URL 或另一個 AgentCore Gateway 時有效**。API Gateway stage target 只支援 REST API，`{proxy+}` 資源會被排除。Lambda target 的 `event` 就是參數本身，工具名在 `context.client_context.custom["bedrockAgentCoreToolName"]`，`toolSchema` 沒有 enum。

**名稱與說明**：完整名稱含 target 名，Gateway 允許 256 字元，但許多模型限 64 字元左右（原研究推論）→ **target 名要短**；用「動詞＋名詞」（`get_order`）。說明是寫給模型的 API 文件：寫做什麼／回傳什麼、何時該用何時不該用、參數格式與來源、副作用；不寫實作細節與 HTTP 狀態碼。可用 `toolOverrides.description` 或 gateway 層 MCP `instructions`（最多 2,048 字元）不改後端地調整。

**API 設計 ≠ 工具設計**（原研究判斷）：細粒度多次往返、回傳幾十個欄位、萬用 `actions` 端點、用錯誤碼表達業務狀態、分頁 cursor，對 agent 都不友善。API 細碎時用一個 **Lambda 做 agent 專用 facade**（例如 `find_orders_by_email`）。

### 工具很多：語意搜尋
每個工具定義每輪都送進模型（兩個內建工具就約 900 token），幾百個工具既貴又易選錯。建立時設 `protocolConfiguration.mcp.searchType: "SEMANTIC"`，會多一個排在最前面的 `x_amz_bedrock_agentcore_search` 工具，模型先用自然語言搜再呼叫。
- 只適用 MCP target，DYNAMIC 不適用；DEFAULT 模式變更後要同步才更新索引。
- **預設每分鐘只有 25 次搜尋**（可調）——每輪搜一次約只能撐每分鐘 25 輪對話。
- 費用（研究當時）：搜尋每千次 $0.025、索引每月每 100 工具 $0.02。
- 用 configuration bundle 覆寫的說明**只套用在 `tools/list`，不套用在搜尋**。
- 建議（判斷）：<20 個工具不需要；20–50 看相似度；>50 開啟或拆 gateway。**不同 agent 用不同 gateway** 比靠搜尋過濾可靠。

### 當 Runtime 的唯一入口
Gateway 上的控制只對經過它的流量有效，使用者若能直接打 Runtime 就全被繞過。
1. 建一個**沒有設定 `protocolType`** 的 gateway（Runtime 的 HTTP target `http.agentcoreRuntime` 只能加在這種 gateway，MCP 型不行 → 常要規劃兩個 gateway）。
2. Inbound 設 JWT（驗 audience、scope），outbound 用 service role。Client 只需把 endpoint 換成 `https://{gatewayId}.gateway.bedrock-agentcore.{region}.amazonaws.com/{targetName}/invocations`，支援 SSE。
3. **鎖住 Runtime**：IAM 型用 resource-based policy「Allow gateway role＋**明確 Deny 其他 principal**」（只有 Allow 擋不住帳號內其他有權限者），並用 `aws:SourceArn`／`aws:SourceAccount` 鎖 gateway role 的 trust policy；JWT 型在 `customJWTAuthorizer` 加 `allowedWorkloadConfiguration`，只接受身分鏈中有指定 Gateway 的請求。**AgentCore CLI 不會設這欄位；`UpdateAgentRuntime` 會整個取代設定，要先讀出、合併再寫回**。
4. Rate limit 以 `$.context.jwt.sub` 為維度，並用 inbound `customClaims` 確保 claim 一定存在（缺 claim 整條限制會被略過）。
5. **驗證繞不過去**：同一張 JWT 直打 Runtime 必須被拒、經 Gateway 則成功——最容易被跳過的一步。

需要使用者身分時，可用 REQUEST interceptor 把 `sub` 放進 header 並加進 Runtime 的 header allowlist（原研究推論，前提是只有 Gateway 能呼叫 Runtime）。網路層 PrivateLink 只是補充，主防線是身分層鎖定。

### 當企業 LLM 代理（inference target）
- 設定：**connector**（`bedrock-mantle`／`openai`／`anthropic`，零設定）或 **provider**（自訂 endpoint；`operations` 就是**模型白名單**，支援 `*`、`?`）。
- 端點：`/inference/v1/chat/completions`、`/responses`、`/messages`、`/models`；OpenAI SDK 的 `base_url` 設 `.../inference/v1`，Anthropic SDK 設 `.../inference`。SSE 原封轉送，**不做格式轉換**。
- 供應商 key 放 Identity token vault，使用者只需通過 inbound 驗證；但全公司共用同一把 key 與供應商 TPM。
- **Token 限流機制**：請求進來先估 input token 預扣，不夠直接 429；結束後依供應商回報的實際用量校正；**已開始的回應不中斷**（額度可暫時變負）；只能以分鐘為單位；另有 `connections` 限同時請求數。官方警告：Gateway 對串流長度**沒有上限**，不設 token 限制時單一使用者可用光整個供應商額度。每團隊額度：IdP 加 `team` claim，維度用 `$.context.jwt.team`。
- **缺的**：沒有文件記載的自動重試、跨供應商 fallback、回應快取；沒有依團隊的 token metric（成本分攤要從 `aws/spans` 或帳單自己彙整）。模型分流要用 REQUEST interceptor 改寫 `model`；interceptor 看不到後端失敗，**做不了 fallback**（原研究推論）。
- **選型**（判斷）：統一入口＋憑證集中＋依團隊限流、全在 AWS → inference target；要 fallback／快取／成本報表 → LiteLLM；兩者都要 → Gateway 在前做驗證限流，provider target 指向 LiteLLM。
- 計費（研究當時）：Gateway 每千次呼叫 $0.005，inference 無額外費用項目。

### AWS Agent Registry
組織層級目錄，收錄 MCP server、agent（依 A2A schema 驗證）、skill 與自訂類型，附審核流程（送審 → EventBridge → 你的審核 → `UpdateRegistryRecordStatus`）；每個 registry 有 MCP 端點可讓 coding assistant 搜尋；可搭 AWS Organizations 自動偵測成員帳號的 Runtime 與 Gateway。分工：**Registry 負責「找」，Gateway 負責「用」**。⚠️ 預覽版 `bedrock-agentcore` namespace **2026-10-30 停止支援**，要遷到 `agent-registry`。

### 配額（研究當時預設，皆可申請調高）
每 gateway 100 target、每 target 1,000 工具；工具呼叫與 `tools/list` **每 gateway 200 TPS，整個帳號也是 200 TPS**（拆多個 gateway 不會增加總額度）；並發連線每 gateway／帳號 5,000；逾時 15 分鐘、payload 6 MB；語意搜尋每分鐘 25 次；Web Search 10 TPS。

## ⚠️ 注意 / 什麼時候不適用
- `AUTHENTICATE_ONLY`／`NONE` 不做授權；rate limit fail-open，**都不能當安全邊界**。
- HTTP／Runtime target 的 interceptor 不支援串流：agent 若回 SSE，就不能用 RESPONSE interceptor 加工內容。
- 需要 LLM fallback、快取、成本分攤報表時，inference target 目前不夠。
- **文件矛盾（原研究整理）**：
  - Runtime target 的 OBO：支援表寫不支援，官方 Entra ID A2A 範例卻用了 `TOKEN_EXCHANGE`，要實測。
  - Token 直通：outbound 頁說要搭 `AUTHENTICATE_ONLY`，inbound 頁說不能搭（SigV4 請求沒有 bearer token）；後者邏輯才對。
  - OpenAPI 版本：同頁一說只支援 3.0、一說 3.0／3.1 都支援；content type 一處說只完整支援 JSON、功能表卻列 XML 等——保守只用 JSON。
  - Inference 多 target 符合時：connector 頁寫「隨機」、provider 頁寫「round-robin」。
  - Provider target 文件說能設每模型 token 上限，API 卻沒有該欄位（改用 `qualifiedModelId` 維度的 rate limit）。
  - 本文把權重 A/B 列為 rules 功能，但它不直接適用 inference target。
  - 官方 Lambda 範例有變數名 bug（存成 `toolName`、判斷用 `tool_name`）。
- runtime-front-door 與 llm-proxy 兩篇**沒有實際部署驗證**（撰寫時無 AWS 憑證）。

## 🧪 我實際套用的紀錄
- **OpenAPI 事前檢查（已實跑）**：原研究寫了一支只用 Python 標準函式庫的 lint 腳本，接入前檢查規格是否符合 Gateway 限制，有 ERROR 時結束碼 1、可放進 CI。對刻意埋問題的範例規格跑出：2 個工具、`tools/list` 約 744 字元（粗估約 186 token）；ERROR：`oneOf` 不支援、`DELETE` 缺 `operationId` 不會變工具；WARN：`securitySchemes` 會被忽略、工具名稱 72 字元可能超過模型限制、缺 description。「64 字元」與 token 估算是經驗值，非官方限制。程式見 [experiments/openapi-lint](https://github.com/VagrantPi/AagentCore-Research/tree/main/03-gateway/experiments/openapi-lint)。

## 🔗 相關
- [[AgentCore Runtime]]：Gateway 當 Runtime 唯一入口。
- [[AgentCore Identity]]：outbound OAuth／API key 存在 token vault，3LO session binding。
- [[AgentCore Policy]]：Cedar 的評估點在 Gateway 上。
- [[AgentCore Memory]]：Memory connector＋Cedar 做 per-user 隔離。
- [[AgentCore Built-in Tools]]：Web Search 是 Gateway 的 connector target。
- [[AgentCore Evaluations與Optimization]]：A/B 靠 gateway rules 分流、工具說明自動改寫。
- [[AgentCore Observability]]：token 成本分攤要從 spans 自己彙整。
- [[工具集設計]]：工具數量、命名與說明的通用原則。
- [[工具-MCP安全防護要點]]：遠端 MCP 的 OAuth 與攻擊面。
