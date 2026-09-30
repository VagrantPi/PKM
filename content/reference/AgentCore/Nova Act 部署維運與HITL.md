---
type: reference
name: "Nova Act 部署維運與 HITL Deploy & Human-in-the-loop"
source: "[[AgentCore 與 Nova Act 研究]]"
source_type: docs
tags: [ai, llm, agent, aws, nova-act, browser-automation, deployment, observability, human-in-the-loop]
triggers: [瀏覽器自動化腳本要搬上雲端定時跑, 自動化流程卡在驗證碼或簡訊碼過不去, 付款前想讓人看一眼再按送出, 想知道雲端的瀏覽器 agent 每一步做了什麼, 網頁自動化要順便查資料或呼叫其他 API]
---

> 原始研究：[GitHub](https://github.com/VagrantPi/AagentCore-Research/tree/main/nova-act/02-deploy-operate)（依原研究，查證 2026-09-30）

## 🎯 什麼情境該想到我
當你「本機的 Nova Act 腳本已經能跑，要把它部署到 AWS、觸發、監控，並且在遇到 CAPTCHA、MFA 或需要核准的關鍵步驟時交給真人」的時候。

## ⚙️ 怎麼用

### 結論先講
- **「部署」其實是兩件事：** ① 在 Nova Act 服務**註冊 workflow definition**（一個名字＋選填的 S3 匯出設定）；② 把你的 Python 程式**放到某個運算平台跑**。Nova Act 服務本身不幫你跑程式。
- **三條路徑：** CLI / IDE 一鍵部署（自動包容器、推 ECR、建 IAM role 與 S3，部署到 [[AgentCore Runtime]]）、官方 CDK 範例（Lambda / Fargate / ECS / AgentCore 四選一）、自己寫 IaC。
- **CLI 官方明說只是快速上手工具：**「SHOULD NOT be used as a dependency in production code」。正式環境用 CDK 或自己的 IaC。
- **紀錄三層：** Nova Act Console（run → session → act → step）、CloudWatch `AWS/NovaAct`（API 層級指標）、CloudTrail（控制面預設記錄，資料面要自己開）。
- **HITL 兩種模式：** Human approval（看截圖按核准／拒絕，非同步）與 UI takeover（真人直接操作瀏覽器，要即時在線）。**SDK 只給介面，不是代管服務**。
- **工具使用（Preview）：** `@tool` 把 Python 函式變工具；MCP 要借 Strands 的 `MCPClient`；也可反過來把 Nova Act 包成 Strands agent 的工具。

### 路徑一：Nova Act CLI
```bash
pip install "nova-act[cli]"
act workflow create --name my-workflow                          # 註冊 definition
act workflow deploy --name my-workflow --source-dir ./project   # 建置＋部署
act workflow run    --name my-workflow --payload '{"input": "data"}'
```
- 入口慣例：`main.py` 裡要有 `def main(payload):`（可用 `--entry-point` 改）。
- 自動建立：共用 ECR `nova-act-cli-default`、IAM role `nova-act-{workflow}-role`（可用 `--execution-role-arn` 改用自己的）、S3 `nova-act-{account}-{region}`（也是預設匯出位置）、每個 workflow 一個 AgentCore Runtime、CloudWatch log group `/aws/bedrock-agentcore/runtimes/{agent-id}-default`。
- **部署狀態只存在個人電腦**（`~/.act_cli/state/...`，建置產物不自動清除）。原研究判斷：這和早期 Terraform 本機 state 的問題一樣，換機器或換人就接不上，是它不適合正式環境的原因之一。
- payload 裡的 `AC_HANDLER_ENV` 會在執行前寫進 `os.environ`，官方範例拿來傳 `NOVA_ACT_API_KEY`。⚠️ 密鑰會進呼叫端程式、shell history、呼叫紀錄；正式環境改用 IAM（根本不需要 API key），其他密鑰走 Secrets Manager 或 [[AgentCore Identity]]。
- `--region` 可把 Runtime 放到別區，但 **Nova Act 服務只在 us-east-1**，每一步推論都要跨區呼叫。

### 路徑二：CDK 範例選運算平台
| 平台 | 適合 | 限制 |
|------|------|------|
| Lambda | 事件驅動、短流程 | **最長 15 分鐘** |
| Fargate | 一般長流程；私有子網路＋VPC endpoint＋NAT | — |
| ECS（EC2） | 大量、要控制主機 | 自己管容量 |
| AgentCore | 要接 Identity、Browser、Observability | ARM64 容器 |

四種都用 IAM role 驗證，瀏覽器一律 headless，共用參數 `--disable-gpu --disable-dev-shm-usage --no-sandbox --single-process`。原研究判斷：選擇關鍵是**流程跑多久**與**要不要接 AgentCore**——5 分鐘內事件觸發選 Lambda、長流程要控網路選 Fargate、要接 AgentCore 元件選 Runtime（microVM 最長 8 小時、Instances 最長 14 天）。Nova Act 自己的 act timeout 24 小時、run 1 週，**上限通常卡在運算平台而非 Nova Act**。

### Workflow definition
```bash
aws nova-act create-workflow-definition --name my-workflow \
  --export-config '{"s3BucketName": "my-bucket", "s3KeyPrefix": "nova-act-workflows"}' \
  --region us-east-1
```
- **只建一次，不要在執行時建**（官方特別提醒）。
- 服務只**暫存** agent trajectory（prompt、截圖、模型回應）；要長期保存就設 `exportConfig`，呼叫端要有 `s3:PutObject`，**bucket 必須同帳號**（不支援跨帳號），官方強烈建議加密（截圖可能含個資）。
- 類比：definition 像 CI 的 pipeline 定義，本身不含程式碼。原研究推論：definition 與運算平台鬆耦合，同一個 definition 可以從本機、Lambda、AgentCore 各自執行，適合拿來比較環境差異。

### 觸發與排程
官方沒有排程功能，觸發方式看平台：`act workflow run`、`InvokeAgentRuntime`、EventBridge Scheduler / SQS / API Gateway。批次情境（例如每天 1,000 筆）要自己做扇出：用佇列控制併發，讓 `InvokeActStep` 總速率維持在預設 5 TPS 配額內。

### 觀察
- **Console：** definition 清單 → run 清單（狀態、起訖、下載 artifact）→ run 詳情（含**使用的 model ID**，追查「模型升版後行為改變」很有用）→ Step view。
- **CloudWatch `AWS/NovaAct`：** `Invocations`、`Latency`（p50/p90/p99）、`UserErrors`、`SystemErrors`、`Throttles`；維度只有 `Workflow` 與 `ApiName`。建議告警 SystemErrors、Latency p90/p99、Throttles（出現就該申請提高配額）。⚠️ **沒有「任務成功率」**——`ActAgentFailed` 對服務來說可能是一次正常 API 呼叫，業務成功率要自己發自訂指標。
- **CloudTrail**（event source `nova-act.amazonaws.com`）：管理事件預設記錄（`CreateWorkflowDefinition`、`ListWorkflowRuns` 等）；資料事件（`CreateSession`、`CreateAct`、`UpdateAct`、`InvokeActStep`）要用 advanced event selectors 自己開，可依 definition / run ARN 過濾，部分個資欄位會被遮蔽。

### Human-in-the-loop
| | Human approval | UI takeover |
|---|---|---|
| 真人做什麼 | 看截圖，核准／拒絕或選一個選項 | 直接操作遠端瀏覽器 |
| 同步性 | 非同步 | 即時，要有人在線 |
| 典型情境 | 費用、採購核准、送出前確認 | CAPTCHA、登入、MFA |
| 回呼 | `approve(message) -> ApprovalResponse` | `ui_takeover(message) -> UiTakeoverResponse` |

```python
class MyCallbacks(HumanInputCallbacksBase):
    def approve(self, message): ...      # 發通知、等人回覆
    def ui_takeover(self, message): ...  # 給真人可操作瀏覽器的連結，等他完成

with NovaAct(starting_page="...", tty=False, human_input_callbacks=MyCallbacks()) as nova:
    nova.act("Submit the expense report. Ask for approval before clicking submit.")
```
- **沒傳 `human_input_callbacks`，模型就不會發出請求人類輸入的工具呼叫**；**何時找人是模型依 prompt 與畫面判斷的**，回呼只負責怎麼找、怎麼等。
- 原研究推論：HITL 機制上就是 SDK 內建的兩個工具，觸發是機率性的。**付款這類一定要核准的步驟不要靠模型自己判斷**，在 Python 明確拆成「act 到付款頁 → 程式呼叫核准 → 核准後才 act 付款」，讓核准變成確定性邏輯（同 [[可逆性、審計與人類把關]] 的思路）。
- UI takeover 要看得到、操作得到瀏覽器：本機 headed 直接操作；headless 開 `--remote-debugging-port` 傳 `devtoolsFrontendUrl`；AgentCore Browser 用 Live View 或 DCV 串流。原研究判斷：雲端正式環境實際上只能走 AgentCore Browser＋DCV，暴露 CDP 除錯埠等於交出瀏覽器完整控制權。
- 官方參考實作 **Human Intervention Service（HIS）** 是部署在你帳號的 CDK 專案：API Gateway WebSocket ＋ Step Functions（生命週期、每 30 秒輪詢、逾時）＋ DynamoDB（TTL 24 小時）＋ S3（截圖 KMS 加密、1 天後刪）＋ Slack / SES 通知＋ CloudFront 審核頁＋ DCV。client 以 WebSocket 阻塞等待，範例逾時 `HITL_EXECUTION_TIMEOUT=7200`（2 小時）。
- 官方建議：依情境設逾時（登入比 CAPTCHA 久）、被拒或逾時要能乾淨停下、所有 HITL 互動留紀錄以供稽核。
- 類比：像 Step Functions 的 `waitForTaskToken`，但**等待期間瀏覽器 session 必須一直開著**，所以受運算平台上限約束；Nova Act 不收等待時間，運算平台照收。

### 工具（Preview）
```python
@tool
def read_row_as_dict(file_path: str, row_number: int) -> dict:
    """Reads a specific row from an Excel file ... (docstring 就是給模型的說明書)"""
    ...
with NovaAct(starting_page="https://example.com/form", tools=[read_row_as_dict]) as nova:
    nova.act("Read row 1 from data.xlsx using read_row_as_dict, then fill the form with it")
```
- docstring 的描述、參數、回傳型別要寫清楚；工具越少越好；prompt 用詞對上工具描述。
- 需要直接操作瀏覽器的工具設 `requires_unlocked_actuator_context = True`，執行期間 SDK 暫停自己對瀏覽器的控制。
- **MCP：** SDK 沒有自己的 MCP client，要裝 `strands-agents` 借 `MCPClient`，把 `list_tools_sync()` 傳給 `tools=`。這步不需要瀏覽器時，prompt 要明寫「Ignore the web browser」，否則模型可能還是去點網頁。
- **反過來當 Strands 工具：** 把 `NovaAct(...).act_get(instr, max_steps=10)` 包進 `@tool`，Strands 的通用 LLM 負責規劃、Nova Act 負責在網頁把事做完；SDK 與 Strands agent 跑在同一台機器。成本是兩份（LLM 按 token＋Nova Act 按 agent hour），上層可能反覆呼叫，工具要設 `max_steps` 上限。

| 架構 | 誰是大腦 | 適合 |
|------|------|------|
| 純 Nova Act workflow | Python＋Nova Act 模型 | 流程固定、以網頁操作為主 |
| Nova Act＋工具 | Nova Act 模型 | 網頁流程中需少量外部資料 |
| Strands＋Nova Act 當工具 | 通用 LLM | 跨系統推理，網頁只是其中一步 |

### 文件矛盾
- **CDK README：** Prerequisites 要求準備 Nova Act API key 並 `export NOVA_ACT_API_KEY`，同文件 Authentication 段卻說「All examples use IAM Role authentication — no API keys required」。原研究判斷 API key 步驟像舊版殘留，需實際部署確認。
- **CloudTrail 缺漏：** `CreateWorkflowRun`、`UpdateWorkflowRun` 列在配額表的資料面 API，但 CloudTrail 兩張清單都沒列；要稽核「誰觸發了哪次 run」前需實測。
- **HIS 名稱：** 使用者指南與 README 都說 HITL「不是代管的 AWS 服務」，同頁卻稱 HIS 為「**Managed** Human Intervention Service（Recommended）」；實際上要自己部署維運。

## ⚠️ 注意 / 什麼時候不適用
- CLI 不要進正式環境（本機 state、官方明說不可當 production 相依）。
- Lambda 15 分鐘上限：長流程或含 HITL 等待的流程不要放 Lambda。
- HIS README 說「用 Administrator 權限跑比較簡單」；正式環境改用部署產生的 `NovaAct-HITL-AssumeExecutionRole-*` 最小權限 policy。
- `AWS/NovaAct` 指標看不到業務成功率，別只靠它告警。
- Tool use 仍是 Preview，正式環境不要依賴；工具多、推理重的任務交給通用 LLM agent，Nova Act 當它的工具。

## 🧪 我實際套用的紀錄
- （尚無）原研究列出待實測：CDK 部署樣板取代 CLI、CDK README API key 矛盾、HIS 端到端延遲與等待期間的運算成本、確定性核准閘門 vs prompt 觸發的可靠度。

## 🔗 相關
- [[Nova Act 總覽與SDK]]：`act()`、Workflow、錯誤處理與計費
- [[Nova Act 與AgentCore整合及安全]]：Runtime / Browser 整合細節與 IAM
- [[AgentCore Runtime]]：CLI 預設部署目標與時長上限
- [[AgentCore Observability]]：Runtime 端的 trace 與 log
- [[可逆性、審計與人類把關]]：不可逆操作前的確定性核准
