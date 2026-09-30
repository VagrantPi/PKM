---
type: reference
name: "AgentCore Policy 工具呼叫授權 Policy (Cedar)"
source: "[[AgentCore 與 Nova Act 研究]]"
source_type: docs
tags: [ai, llm, agent, aws, agentcore, policy, cedar, authorization, guardrails, security]
triggers: [寫在prompt裡的金額上限擋不住模型, 想讓agent只能動使用者自己的資料, 規定agent一定要先查詢過才能執行操作, 工具回傳的資料有個資不想讓模型看到, 擔心有人能悄悄關掉agent的授權限制]
---

> 原始研究：[GitHub](https://github.com/VagrantPi/AagentCore-Research/tree/main/08-policy)（依原研究，查證 2026-09-30）

## 🎯 什麼情境該想到我
當你「**發現 system prompt 裡寫的『退款不能超過 500』只是建議、模型可能不照做或被 prompt injection 騙過，想把規則移到模型外面、在每次工具呼叫前確定性地允許或拒絕**」的時候。

## ⚙️ 怎麼用

### 結論先講
- **Policy 之於 agent 的工具呼叫，就像 IAM policy 之於 AWS API。** 掛在 Gateway 上，用 Cedar（與相容 Cedar 的 Dogwood）判斷，**跟模型行為完全無關**。
- **分類標準只有一條：「模型不照做時，後果能不能接受？」** 不能接受（金額上限、資料歸屬、地區限制）→ 搬到 Policy；能接受（語氣、格式）→ 留在 prompt。
- **Policy 只看得到工具參數與呼叫者身分，看不到對話。** 很多規則搬不過去，原因不在 Cedar，而在**工具 schema 沒帶到判斷所需的欄位**。
- **上線流程：先 `LOG_ONLY` 觀察，再切 `ENFORCE`。** 最弱的一環是權限：`UpdateGateway` 能把整個 engine 切回 `LOG_ONLY` 或拔掉，`UpdatePolicy` 能讓單條 policy 只記錄不攔截。

### 一次授權請求的樣子
| Cedar 元素 | 來源 |
|---|---|
| principal | JWT 的 `sub`（`AgentCore::OAuthUser`，其他 claim 變成字串 **tag**：`principal.getTag("role")`）；或 IAM ARN（`AgentCore::IamEntity`，沒有 tag） |
| action | 工具名稱 `<Target>___<Tool>`，例如 `OrderTarget___process_refund` |
| resource | gateway ARN |
| context | 工具參數 `context.input.<欄位>`；時間 `context.system.now`；輸出 `context.output` 只能用在 guardrail 條件與 temporal 歷史 |

- **預設拒絕、forbid 優先於 permit。** 拒絕時回 `isError: true` 與 `AuthorizeActionException – Tool Execution Denied`。
- **Cedar schema 由 gateway 的工具定義自動產生**，建立 policy 時就驗證引用的工具與欄位，並用**自動推理**標出「永遠允許／永遠拒絕」的 policy。
- **`tools/list` 也被過濾**：只要「有任何情況可能被允許」就會列出，所以**列得出來不代表呼叫一定成功**（金額超限仍會拒絕）；好處是 agent 看不到完全不能用的工具，省 token 也少被誘導。Policy **只管 MCP tools**，prompts 與 resources 永遠放行。

### 把 prompt 規則搬成 Cedar（範例精簡）
```cedar
// 一般使用者：上限 500 美元、只限美加、一定要有原因
permit (principal is AgentCore::OAuthUser,
  action == AgentCore::Action::"OrderTarget___process_refund",
  resource == AgentCore::Gateway::"arn:...:gateway/demo")
when { context.input.amountCents <= 50000 &&
       ["US","CA"].contains(context.input.country) &&
       context.input has reason };

// 只能退自己的訂單，主管例外；forbid 壓過任何 permit
forbid (principal is AgentCore::OAuthUser,
  action == AgentCore::Action::"OrderTarget___process_refund",
  resource == AgentCore::Gateway::"arn:...:gateway/demo")
when   { context.input.customerId != principal.id }
unless { principal.hasTag("role") && principal.getTag("role") == "supervisor" };
```
- 「絕對不行」寫成 `forbid`：之後就算有人加了過寬的 `permit` 也繞不過。
- **讀 tag 前先 `hasTag`、讀非必填欄位前先 `has`**；每個工具都要有 `permit`，否則全擋。
- **prompt 裡的規則可以保留**：prompt 讓模型一開始就不去做，Policy 保證做了也會被擋；沒寫說明的話，模型被拒後可能一直換參數重試。

### 為 policy 設計工具 schema
| JSON Schema | Cedar | 注意 |
|---|---|---|
| `integer` | `Long` | **最推薦**，比較與 temporal `sum` 都能用 |
| `number` | `Decimal` | 截斷到小數 4 位；原研究推論 `sum` 只能加 `Long` |
| `array` | `Set` | 順序消失、重複值合併 |
| `object` | `Record` | `required` 決定必填 |

原則：**金額用整數「分」**（`amountCents`）；**資料歸屬做成明確欄位**（`customerId`），後端也要再驗；**被 policy 引用的欄位設必填**；不要用 `anyOf`／`oneOf`／自由 object；**一個工具只做一件事**（萬用 `manage_order(action=…)` 會讓每條規則都先判斷 action）。不能用萬用字元比對 action，要分組就放同一 target 再用 `action in AgentCore::Action::"<Target>"`——**target 切分本身就是 policy 的分組設計**。原研究也建議會被引用的欄位先別用 `enum`（開源 generator 會把它轉成列舉 entity，AgentCore 是否相同未說明）。

### Temporal policy（Dogwood）：有狀態的流程規則
Cedar 只看當下這次請求；Dogwood 加上 `formerly within`、`since within`、`count`、`sum`，事件分 `::request`（已授權）、`::response`（成功，含 output）、`::error`（被拒或出錯），時間窗最長 24 小時。

| 模式 | 寫法重點 |
|---|---|
| **先查詢再操作** | `formerly within 1h …get_account_balance::response{ eventResource: resource, output.accountId: context.input.toAccount }` —— 比對的是**查詢工具的真實輸出**，模型捏造的帳號不會出現在歷史裡 |
| **核准一次只能用一次** | `!…transfer_funds::response since within 1h …get_account_balance::response` |
| **總額上限** | `sum` 加總 5 分鐘內金額 ≥ 3000 就 `forbid`；**必須帶 `(t: Timepoint)` 與 `tp(t)`**，否則同金額兩筆會被去重只算一次；`count`／`sum` 含當前這一筆 |
| 次數、冷卻、互斥、拒絕後封鎖 | `count`；`formerly within 1m` + forbid；兩條對稱 forbid；比對 `::error` |

陷阱：
- **前置步驟也要 permit**（dependency trap）：查詢沒被允許就被記成 `error`，`::response` 永遠比對不到。
- `response` 是工具完成後「稍晚」才寫入歷史：模型**平行**呼叫查詢與轉帳時，轉帳可能被誤拒；依賴的步驟要依序執行。
- Session ID 由**呼叫端**放在 `x-amzn-bedrock-agentcore-policy-session-id`，閒置 24 小時刪除；engine 有 temporal policy 時沒帶 header 會報錯。session key **包含呼叫者身分**（不同人用同 ID 不共享歷史，但 inbound 驗證設 `NONE` 時例外），可是**同一人換個 ID 計數就歸零**。
- **新增／修改 temporal policy 會讓 engine 上所有進行中 session 收到 409**，同 ID 重試無效，要換新 ID 且歷史歸零——**不能只重送失敗那一步**，要讓 agent 從流程起點重走（例如轉成「授權狀態已重置，請重新查詢餘額」給模型看）。挑離峰、合併變更一次部署。
- 核准者與執行者是不同 principal 時，核准事件記在主管的 session，這個模式行不通，要交給後端工作流（原研究推論）。

**定位**：temporal 用來保證「agent 照流程走」，**不是防濫用的總量控制**。跨 session 總量用 Gateway rate limit（以 JWT `sub` 為維度，但它 fail-open）、session ID 由後端產生、最終由**後端額度系統**再檢查一次。

### Guardrails in policy 與 `suppressOutput`
可用三類 Bedrock Guardrails：`ContentFilter`、`PromptAttack`（含 PROMPT_INJECTION）、`SensitiveInformation`。寫法如 `forbid … when guardrails { BedrockGuardrails::PromptAttack([...],[context.input.prompt])["PROMPT_INJECTION"].confidenceScore.greaterThan(decimal("0.6")) }`。
- **分數只有 0、0.2、0.4、0.6、0.8、1.0**，門檻實際只有 5 個選項；ContentFilter／PromptAttack 的分數是**強度**不是機率，不能跨類別比。預設門檻（0.2／0.4／0.2）**只在自然語言產生 policy 時套用**，手寫要自己設。
- **用成本選門檻、依工具設定**：`LOG_ONLY` 收分數 → 分層抽樣標註（「如果這次被擋，是對的嗎？」）→ 每個門檻算混淆矩陣 × 誤擋／漏擋成本。高風險工具低門檻、低風險工具高門檻。
- **`suppressOutput` 是整個輸出拿掉，不是遮罩**，而且**工具副作用已經發生**。適合讀取型工具（不讓個資進 context）；寫入型工具要在輸入端 `forbid`。真正的遮罩應由後端 API 做。
- **縱深分工**：Policy 只看得到「工具參數與輸出」；使用者原始輸入與模型最終回覆要在 Runtime 呼叫 ApplyGuardrail、payload 格式在 Runtime 驗證、寫進 Memory 的內容要在 Memory 過濾、整體安全表現交給 Evaluations 的 `Harmfulness`／`Refusal` 事後量測（`Refusal` 上升可能代表門檻太嚴）。

### 上線與保護
本機 Cedar validator + 案例測試（CI）→ 部署 gateway → 建 policy（保留預設 `validationMode = FAIL_ON_ANY_FINDINGS`）→ engine 用 `LOG_ONLY`，看 **`LogOnlyDecisionFlips`**（「若切強制決策會改變」的次數，持續為 0 才安全）→ 切 `ENFORCE`。把 `UpdateGateway`、`UpdatePolicy` 只給極少數人，對 `policyEngineConfiguration` 變更設 CloudTrail 警報。**Policy 沒有版本欄位，`UpdatePolicy` 直接覆蓋**，版本管理靠自己的 Git。

## ⚠️ 注意 / 什麼時候不適用
- **文件矛盾（原研究整理）**：
  - schema 限制頁寫「只有 `context.input`」，時間規則頁卻用 `context.system.now`。
  - 文件說 Gateway 不會代產 session ID、沒帶就報錯；官方範例 FAQ 說會自動建立並回傳——client 兩種都要能處理。
  - 定價頁說每 engine 前 100 條 temporal policy 免授權費，但配額上限是 20 條。
  - guardrail 說明頁說 `when guardrails` 不能混一般條件，temporal 撰寫頁卻有混用範例。
  - guardrail 說明頁說每筆紀錄含被評估內容，span 屬性列表卻沒有內容欄位——要假設拿不到原文，自己用 trace ID join 應用 log。
  - 刪除 temporal policy 是否也造成 409：範例說會、文件沒提，保險視為會。
- **更正（原研究對自己本文）**：`suppressOutput` 不是「遮蔽個資」而是整個拿掉；每條 policy 另有 `enforcementMode`，`UpdatePolicy` 也是弱點；temporal session key 含身分，比原先寫的安全一點。
- 引用了請求沒帶的欄位，policy 可能照樣 `ACTIVE`、執行時才一律 403（看 `PolicyMismatch` metric）；`CreatePolicy` 先回 202、之後才變 `CREATE_FAILED`。
- **Cedar schema 上限 400 KB 是 engine 關聯的所有 gateway 工具加總**，工具多要拆 engine；單條 policy 10 KB；名稱不能有 `-`。
- 指定 action 的 policy 必須寫死 gateway ARN，要先建 gateway 才能寫 policy。
- Cedar 沒有 regex（只有 `like` + `*`）、沒有浮點；同一次呼叫不能同時引用 `context.input` 與 `context.output`。
- 控制面速率極低（Policy 5 TPS、engine 1 TPS，不可調），IaC 一次建上百條要節流重試。
- 陣列型 JWT claim（如 `cognito:groups`）怎麼編碼成 tag 文件沒寫，需實測。
- Guardrail 支援區域少（亞太僅東京、雪梨）；gateway role 需 `bedrock:InvokeGuardrailChecks`；只有三類 guardrail，沒有 denied topics、自訂詞彙、regex。
- 被擋的錯誤訊息會帶 policy 名稱，**名稱不要透露規則細節**（原研究推論）。
- 所有流量必須經過 Gateway，Policy 才有意義；能繞過 Gateway 直連後端就等於沒有。

## 🧪 我實際套用的紀錄
- **Prompt 規則改寫成 Cedar（`prompt-to-policy`，已在本機實跑、全部通過）**：用 `cedarpy` 4.12.1（Cedar 4.x）加一份手寫、仿 AgentCore 結構的 schema。`policies.cedar` 驗證 PASS；反例 `bad-policy.cedar`（直接寫 `context.input.reason != ""` 沒先 `has`）被 validator 抓出「unable to guarantee safety of access to optional attribute `input.reason`」。10 個授權案例全部符合：自己的 $120 允許、剛好 $500 允許、$500.01 拒絕、退款到日本拒絕、沒填原因拒絕、退別人訂單被 forbid 拒絕、主管退別人 $3,000 允許、主管 $6,000 拒絕、沒有 role claim 的人退自己 $50 允許、查詢訂單允許。**限制**：本機 schema 是近似版，Dogwood 與 guardrail 條件本機跑不了，只能在 AgentCore 用 `LOG_ONLY` 驗。
- **Guardrail 門檻校準（`guardrail-threshold`，只用合成資料，500 筆、應擋 40）**：門檻 0.2 → recall 0.93、誤擋率 0.31；0.4 → 0.82／0.19；0.6 → 0.65／0.09；0.8 → 0.33／0.04；1.0 → 0.10／0.02。漏擋成本 = 誤擋 20 倍時最佳門檻 0.2（成本 203）；兩者成本相等時最佳門檻 1.0。**同一份資料，成本假設不同答案就不同**，所以門檻要依工具設定。
- Temporal 範例**沒有在 AgentCore 上實際執行過**，僅整理自官方文件與範例。

## 🔗 相關
- [[AgentCore Gateway]] —— Policy 唯一的執行點；rate limit、target 分組
- [[AgentCore Identity]] —— principal 與 tag 來自 inbound JWT；temporal 依賴 Workload Access Token 傳遞
- [[AgentCore Memory]] —— Gateway 的 Memory connector 用 Cedar 做 per-user FGAC；記憶污染 Policy 管不到
- [[AgentCore Runtime]] —— payload 驗證與使用者輸入／最終回覆的 guardrail 在這層
- [[AgentCore Observability]] —— `LogOnlyDecisionFlips`、`PolicyMismatch`、guardrail 分數 span
- [[AgentCore Evaluations與Optimization]] —— 事前阻擋 vs 事後評分；`Refusal` 分數回饋門檻
- [[Guardrails 護欄設計]] —— 護欄放哪一層、誤擋與漏擋取捨
- [[提示注入與分層防禦]] —— 為什麼 prompt 規則擋不住注入
- [[可逆性、審計與人類把關]] —— 高風險動作的核准與稽核
