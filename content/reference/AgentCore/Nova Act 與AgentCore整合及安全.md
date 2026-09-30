---
type: reference
name: "Nova Act 與 AgentCore 整合及安全 Integration & Security"
source: "[[AgentCore 與 Nova Act 研究]]"
source_type: docs
tags: [ai, llm, agent, aws, nova-act, browser-automation, agentcore, security, iam, prompt-injection]
triggers: [瀏覽器 agent 讀到網頁上的惡意文字會不會被帶走, 怕自動化 agent 亂跑到別的網站, 網頁自動化要拿到第三方登入 token, 要替瀏覽器 agent 寫最小權限的 IAM, 雲端瀏覽器和 agent 大腦要怎麼接在一起]
---

> 原始研究：[GitHub](https://github.com/VagrantPi/AagentCore-Research/tree/main/nova-act/04-agentcore)（依原研究，查證 2026-09-30）

## 🎯 什麼情境該想到我
當你「要把 Nova Act 放到 AgentCore 上跑（雲端瀏覽器、第三方 OAuth、trace、工具入口），並且要擋住網頁內容對 agent 的 prompt injection、把 IAM 權限收到最小」的時候。

## ⚙️ 怎麼用

### 結論先講
- **分工：** Nova Act 負責「看畫面、決定下一步」；AgentCore 提供跑程式的地方（[[AgentCore Runtime|Runtime]]）、雲端瀏覽器（[[AgentCore Built-in Tools|Browser]]）、身分（[[AgentCore Identity|Identity]]）、觀測（[[AgentCore Observability|Observability]]）、工具入口（[[AgentCore Gateway|Gateway]]）。Memory、Policy、Evaluations、Payments **沒有官方整合說明**。
- **成本：** Nova Act agent hour（依原研究查證日 $4.75/h）遠高於 Runtime＋Browser 運算費，AgentCore 部分只占幾個百分點。**省錢關鍵是減少步數與 act 時間**。
- **安全最大風險是 prompt injection：** 網頁上的文字（貼文、搜尋結果、留言、附件）可能被模型當指令。官方說有訓練防禦但**不保證擋得住**，所以設計重點是**限制影響範圍**，不是相信模型。
- ⚠️ **官方範例不能照抄：** Identity 範例把 OAuth token 寫進 prompt、CDK handler 把 CDP 認證 header 寫進 log、範例 import 的套件名是錯的。

### 整合地圖
```text
呼叫者（API / 排程 / 其他 agent 透過 Gateway）
   │ InvokeAgentRuntime（Identity 驗證 inbound JWT）
   ▼
AgentCore Runtime（workflow 容器，ARM64）
   ├─ Identity：@requires_access_token → 第三方 OAuth token
   ├─ Observability：ADOT → CloudWatch（baggage 帶 Nova Act session.id）
   ├─ Gateway：呼叫 MCP 工具
   ├─ CDP（WebSocket + SigV4 header）──▶ AgentCore Browser（microVM、Live View、profile、錄影）
   └─ HTTPS ──▶ Nova Act 服務（us-east-1）：InvokeActStep、workflow run 紀錄
```

### Runtime：自己寫 handler
```python
from bedrock_agentcore.runtime import BedrockAgentCoreApp
from bedrock_agentcore.tools.browser_client import browser_session
from nova_act import NovaAct

app = BedrockAgentCoreApp()

@app.entrypoint
def handler(payload):
    with browser_session(region) as client:             # 開 AgentCore Browser session
        ws_url, headers = client.generate_ws_headers()  # CDP 端點＋SigV4 header
        with NovaAct(starting_page=payload["starting_page"],
                     cdp_endpoint_url=ws_url, cdp_headers=headers,
                     headless=True, clone_user_data_dir=False) as nova:
            return {"status": "success", "response": str(nova.act(payload["prompt"]))}
```
- 容器 ARM64（microVM 模式只支援 ARM64）；時長受 Runtime 限制（microVM 8 小時、Instances 14 天）。
- 原研究判斷：瀏覽器放 AgentCore Browser 而不塞進 Runtime 容器，好處是映像檔不用裝 Chromium、可用 Live View / DCV 讓真人接手、瀏覽器在隔離 microVM 裡被惡意網頁攻破時影響較小；代價是多一段網路延遲與跨 OS 鍵盤問題。

### Browser：三種接法
| 寫法 | 來源 | 適合 |
|------|------|------|
| `browser_session(region)` ＋ `generate_ws_headers()` | `bedrock_agentcore` SDK | 最簡單 |
| `AgentCoreBrowserSessionProvider(profile=...)` ＋ `cdp_session()`，傳 `browser_auth=provider` | Nova Act SDK 內建 | **跨 run 保存登入狀態** |
| 自訂 `AgentCoreBrowserActuator` | samples | 把開關 session 藏進 `start()` / `stop()`，還提供 `console_live_view_url` |

注意：
- **跨 OS 鍵盤：** SDK 在 macOS、Browser 在 Linux 時，`ControlOrMeta+A` 這類快捷鍵可能對應錯誤（README 說是預期行為）；SDK 也部署到 Linux 就沒事。
- **`NovaAct(proxy=...)` 接 CDP 時無效**，要改用 AgentCore Browser 自己的 proxy。
- 一個 Browser session 只能一條 automation stream；平行就各開一個（帳號上限同時 1,000 個）。
- **Profile 就是登入憑證**：用 IAM 限制讀寫；存檔會整個覆蓋，平行 session 不要共用同一 profile 寫回。

### Identity：token 只在程式碼層用
官方範例用 `@requires_access_token(provider_name="custom-oauth-provider")` 拿到 token 後，執行 `browser.act(f"Use OAuth token {access_token} to: 1. Log into the site ...")`。問題：token 會送到 Nova Act 服務、進 trajectory、可能被寫進 S3 匯出；違反同一份指南「不要在 act() 裡放敏感資訊」；而且模型本來就拒絕處理密碼類輸入，能否跑成功都有疑問。

正確做法（原研究判斷）：用 Playwright 設 header（`nova.page.context.set_extra_http_headers(...)`）或塞 cookie，或 `act()` 只負責點到欄位再 `nova.page.keyboard.type(token)`。代表使用者的情境走 Identity 3LO 並做好 session binding。

### Observability 與 Gateway
- 安裝 `aws-opentelemetry-distro`、設 `AGENT_OBSERVABILITY_ENABLED=true`；`nova.start()` 後用 `nova.get_session_id()` 放進 OTel baggage `session.id`，ADOT 把 trace 送到 CloudWatch GenAI Observability。原研究推論：這樣能用同一個 session ID 串起 AgentCore trace、Nova Act Console step 紀錄、`AWS/NovaAct` 指標；但官方沒說每一步會不會自動變成 span，需實測。
- Gateway 兩個方向：Nova Act 當 client 把 Gateway 上的 MCP 工具傳給 `tools=`（Preview）；或把 workflow 掛上 Gateway 讓其他 agent 當工具呼叫（官方只說「可以」）。原研究判斷：後者是組織內共用瀏覽器自動化能力最乾淨的方式，一份 workflow 所有 agent 共用，再用 [[AgentCore Policy]] 控制誰能呼叫。

### 成本疊加（5 分鐘流程，依原研究牌價）
| 項目 | 估算 |
|------|------|
| Nova Act | $4.75 × 5/60 ≈ **$0.396** |
| AgentCore Browser（1 vCPU / 4 GB，CPU 滿載上限） | ≈ $0.0075 ＋ 記憶體 $0.0032 ≈ **$0.011** |
| AgentCore Runtime（等推論的 I/O 時間不收 CPU） | 通常 < $0.005 |

Nova Act 約占 97%（原研究推論，實際 CPU 使用率看網頁複雜度）。

### 安全：威脅模型
```text
你的 prompt ──┐
網頁內容（不可信、注入點）──▶ Nova Act 模型 ──▶ 點擊 / 輸入 / 上傳 / 呼叫工具 / 跳轉
                                  影響範圍＝瀏覽器登入了哪些網站＋開放的檔案路徑
                                           ＋註冊的工具＋執行環境的 IAM 權限
```
被注入操縱的 agent 本身就是 confused deputy（權限高的一方被騙代為執行）。Prompt injection 像 SQL injection，但資料和指令混在同一段自然語言裡，沒有 prepared statement 可用（詳見 [[提示注入與分層防禦]]）。

### SDK 防線
- **預設關閉：** `allowed_file_open_paths`（`file://` 瀏覽）與 `allowed_file_upload_paths` 預設 `[]`。要開就只開單一任務目錄（`"/srv/job-123/uploads/*"`），官方警告開太寬會讓惡意網頁誘導 agent「上傳」機器上其他檔案外洩。
- **`state_guardrail`（要自己加）：** 每次觀察後檢查網址，回傳 `GuardrailDecision.PASS` / `BLOCK`，越界時拋 `ActStateGuardrailError`。採白名單、預設拒絕：

```python
ALLOWED = ["portal.example.com", "*.sso.example.com"]
def url_guardrail(state: GuardrailInputState) -> GuardrailDecision:
    host = urlparse(state.browser_url).hostname
    if host and any(fnmatch.fnmatch(host, p) for p in ALLOWED):
        return GuardrailDecision.PASS
    return GuardrailDecision.BLOCK
```
- 原研究推論：guardrail 是「**到了之後才擋**」，頁面已載入；若目標頁一載入就有副作用（GET 即執行動作），擋不住。更嚴格要在網路層限制（AgentCore Browser 的 proxy / VPC、自建 egress proxy）。Service Card 建議在 prompt 寫「不要離開某網域」只能當輔助，prompt 本身可能被注入覆蓋。
- **截圖外洩：** 密碼用 Playwright 輸入，但之後截圖時畫面上的卡號、個資仍會送到服務端、可能進 S3 匯出。無 keyring 的 Linux 上 Chromium 密碼管理器是明文。

### 資料保護
| 項目 | IAM（AWS 服務） | API key（nova.amazon.com） |
|------|------|------|
| 拿你的資料訓練 | **不會** | 收集互動資料與截圖改進服務 |
| 條款 | AWS Service Terms | nova.amazon.com Terms of Use |

IAM 模式：DynamoDB 與 S3 以 **AWS owned key** 加密，**不支援 CMK**、**不支援 PrivateLink**（私有子網路要經 NAT 走公開端點），官方說之後會加。WorkflowDefinition 名稱與 Run ID **不加密**，不要放個資或客戶編號。TLS 1.2+。原研究判斷：無 CMK、無 PrivateLink 對金融醫療常是採用門檻。

### IAM
- 只支援 identity-based policy；資源層級可限定 `workflow-definition`、`workflow-run`；**不支援 ABAC（tag）**、沒有服務專屬 condition key（只有全域 key 與 `aws:RequestedRegion`）；**沒有 AWS 代管存取 policy**；service-linked role 只用來發指標。
- ARN：`arn:aws:nova-act:{region}:{account}:workflow-definition/{Name}`、run 為 `.../workflow-definition/{Name}/workflow-run/{RunId}`。`CreateSession`、`CreateAct`、`InvokeActStep`、`UpdateAct`、`UpdateWorkflowRun`、`GetWorkflowRun` **同時需要兩種資源**；`CreateWorkflowRun`、`ListWorkflowRuns` 只需 definition。
- 原研究整理的執行用最小權限（只能跑 `book-flight`；action 清單是依 Workflow 生命週期推出，SDK 是否還呼叫其他 API 需實測）：

```json
{ "Effect": "Allow",
  "Action": ["nova-act:CreateWorkflowRun","nova-act:UpdateWorkflowRun","nova-act:GetWorkflowRun",
             "nova-act:CreateSession","nova-act:CreateAct","nova-act:UpdateAct","nova-act:InvokeActStep"],
  "Resource": ["arn:aws:nova-act:us-east-1:123456789012:workflow-definition/book-flight",
               "arn:aws:nova-act:us-east-1:123456789012:workflow-definition/book-flight/workflow-run/*"] }
```
另加 `nova-act:ListModels` on `*`。角色分工：平台管理者管 definition 建刪＋S3 匯出；每個 workflow 一個執行角色；維運稽核只給 `Get*` / `List*`。因不支援 ABAC，workflow 多了要靠**命名慣例＋ARN 萬用字元**（`workflow-definition/team-a-*`）分組，名稱一開始就要設計好。

### 文件矛盾
- **ARN 格式：** 「How Nova Act works with IAM」資源表的 run ARN 是 `workflow-definition/{name}/workflow-run/{id}`，同頁範例卻寫 `arn:aws:nova-act:us-east-1:123456789012:workflow-run/{id}`（少了 definition 段）。以資源表與服務授權參考為準。
- 同頁說建立類 action 只能用 `*`，但授權參考的 `CreateWorkflowDefinition` 列出 `workflow-definition` 資源類型；能否限定名稱需實測。資源 ARN 還一下寫 `${WorkflowDefinitionName}`、一下寫 `${WorkflowDefinitionId}`。
- **上限矛盾：** Service Card 寫每任務最多 **100 步**、瀏覽器 session 最長 **30 分鐘**、prompt 約 10,000 字元；配額頁／README 是每 act **200 步**、act timeout **24 小時**、run 1 週（payload 5 MB 兩邊一致）。原研究判斷：兩者可能一個是模型行為邊界、一個是 API 限制；確認前保守設計，一個 act 控制在 30 步內，session 超過 30 分鐘先實測。
- **範例程式碼：** 指南 Identity 範例 `from nova_act_sdk import NovaAct`（實際套件是 `nova_act`）、`NovaAct()` 沒傳必填的 `starting_page`；CDK handler 用 `NOVA_ACT_API_KEY`，與 CDK 總覽「全用 IAM」矛盾，還 `logger.info(f"headers are {headers}")` 把 SigV4 header 寫進 CloudWatch。

### 負責任使用（Service Card）
禁止 EU AI Act 禁止的用途、監控、操縱等；高風險領域客戶**必須**自評風險並加人工監督。官方評測有害指令拒絕率 96.4%、偏見內容 99.5%——**約每 28 個有害指令有 1 個沒擋下**，不能只靠模型。同一 prompt 不保證每次動作一樣。預設 UA 含 `NovaAct`，自訂時官方建議保留。

### 安全檢查清單（摘要）
1. 正式環境用 IAM，不用 API key，也不用 payload 傳密鑰。
2. 每個 workflow 一個執行角色，資源限定到 definition 與 run。
3. `state_guardrail` 白名單、預設拒絕；網路層再限制一次（proxy / VPC）。
4. 上傳與 `file://` 維持關閉或只開單一目錄；只註冊必要工具，MCP 工具視為不可信輸入（參考 [[工具-MCP安全防護要點]]）。
5. 密碼、token 走程式碼層；檢查截圖會不會截到敏感資訊；log 不留 CDP header 與 token。
6. 不可逆操作前加確定性核准。
7. 登入 profile 依使用者隔離並加密；S3 trajectory bucket 加密、設保存期限、限存取。
8. 開 CloudTrail 資料事件稽核 `InvokeActStep`。

## ⚠️ 注意 / 什麼時候不適用
- 法遵要求 CMK、PrivateLink 或 ABAC 的環境，目前 Nova Act 不支援（依原研究查證日）。
- `state_guardrail` 不是網路防火牆，擋不住「一載入就有副作用」的頁面。
- 官方 Identity 與 CDK 範例有安全問題，照抄會洩漏 token / header。
- Memory、Policy、Evaluations 與 Nova Act 的整合沒有官方說明，自己接要自負驗證。

## 🧪 我實際套用的紀錄
- （尚無）原研究列為待實測：最小權限 policy 實跑、ARN 矛盾與 `CreateWorkflowDefinition` 能否限名、步數 100 vs 200 與 session 30 分鐘上限、ADOT 能否自動產生 step span、prompt injection 紅隊測試。

## 🔗 相關
- [[Nova Act 總覽與SDK]]：`act()`、`nova.page`、登入狀態 provider
- [[Nova Act 部署維運與HITL]]：CLI / CDK 部署、HITL 與 Human Intervention Service
- [[AgentCore Built-in Tools]]：AgentCore Browser 的 proxy、VPC、profile
- [[AgentCore Identity]]：3LO 與 session binding
- [[AgentCore Gateway]]、[[AgentCore Policy]]：把 workflow 當工具共用並控管呼叫者
- [[提示注入與分層防禦]]：網頁內容注入的防禦思路
- [[工具-MCP安全防護要點]]：MCP 工具當不可信輸入
