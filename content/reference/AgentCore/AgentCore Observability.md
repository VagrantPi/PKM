---
type: reference
name: "AgentCore Observability 可觀測性 Observability"
source: "[[AgentCore 與 Nova Act 研究]]"
source_type: docs
tags: [ai, llm, agent, aws, agentcore, observability, opentelemetry, cloudwatch]
triggers: [agent上線後不知道它每一步呼叫了什麼, 部署在AWS的agent看不到trace, 怕使用者對話內容全被寫進log, agent的監控費用比跑agent本身還貴, 想對agent陷入迴圈或session快滿設警報]
---

> 原始研究：[GitHub](https://github.com/VagrantPi/AagentCore-Research/tree/main/06-observability)（依原研究，查證 2026-09-30）

## 🎯 什麼情境該想到我
當你「把 agent 部署上 AgentCore（或 EKS、Lambda）之後，想知道它某次為什麼選了那個工具、花了多少 token、在哪一步出錯，又不想把使用者對話全部裸放在 log 裡」的時候。

## ⚙️ 怎麼用

### 一句話定位
用 **OpenTelemetry（OTel）** 追蹤、除錯、監控 agent：每一步呼叫了哪個模型、用了哪個工具、花了多少 token、在哪裡出錯。資料最後落在 **CloudWatch**。

### 為什麼 agent 需要專門的可觀測性

| 一般服務 | Agent |
|---|---|
| 同輸入走同樣程式路徑 | 同輸入，模型每次可能選不同工具、走不同步數 |
| 錯誤多是例外或 5xx | 很多錯誤是**語意上的**（答錯、選錯工具、陷入迴圈），HTTP 卻是 200 |
| 延遲主要來自 I/O | 主要來自**模型推論**，與輸出 token 數成正比 |
| 成本約與請求數成正比 | 與 **token 用量**成正比，差距可達百倍，要逐次追蹤 |

因為問題很難重現，**trace 幾乎是唯一能事後還原「它當時為什麼這樣做」的依據**。trace 除了時間，還要記模型輸入輸出、選了哪個工具、工具參數與結果、token 用量——這些也正是 Evaluations 自動評分的原始資料，**沒有 observability 就沒辦法做線上評估**。

### 資料模型：Session → Trace → Span

```
Session（session.id，透過 header 或 OTel baggage 傳遞）
└── Trace（一次 invoke）
      └── Span 樹
            ├── InvokeAgentRuntime（服務自動產生）
            ├── agent loop（框架產生，需要 ADOT）
            │     ├── chat / invoke_model（模型名稱、token 數、可選 prompt 與回應）
            │     └── execute_tool（工具名稱、參數、結果）
            └── Memory / Gateway / Identity 各自產生的 span
```

- **Session** 是一整段對話，**Trace** 是一次請求與回應，**Span** 是其中一個步驟。
- 屬性名稱遵循 OTel 的 **GenAI semantic conventions**（OTel 為 LLM 定義的標準屬性，例如 token 用量、模型名稱）。
- **分工：** Runtime、Memory、Gateway、內建工具、Identity 會自動提供 metric 與部分 span/log；但 **agent「內部」的 span（呼叫模型、呼叫工具）要在 agent 程式裡加 ADOT 才會有**。Harness 例外，預設全開。

### 資料放在哪

| 資料 | 位置 |
|---|---|
| Span | 新建的 Runtime agent：`/aws/bedrock-agentcore/runtimes/<agent_id>-<endpoint>` log group 的 `spans` stream（**每個 agent 各自獨立**，需 ADOT ≥ 0.18.0）；舊 agent：共用的 `aws/spans`。可用 `UNIFIED_TRACES_DESTINATION_ENABLED` 切換 |
| stdout/stderr | 同 log group 的 `runtime-logs` stream |
| OTel 結構化 log | `…/otel-rt-logs` |
| agent 自訂 metric | `bedrock-agentcore` namespace（EMF 格式） |
| 服務 metric | `AWS/Bedrock-AgentCore` namespace |
| Memory/Gateway/內建工具的 log | **要自己設定 delivery**（CloudWatch Logs、S3、Firehose），預設不送 |
| 瀏覽介面 | CloudWatch 的 **GenAI Observability** 頁：agent → session → trace 逐層往下，另有 Transaction Search |

每個 agent 獨立 log group 的好處：可以**針對個別 agent 設存取權限與 KMS 加密**，也方便匯出，對多團隊、多租戶很重要。

**一次性前置作業：** 帳號要先開 **CloudWatch Transaction Search**，否則看不到任何 span。

### 服務自動提供的 metric 與 log

| Metric | 用途 |
|---|---|
| `Invocations`、`Latency`（端到端，到最後一個 token） | 流量與延遲 |
| `Throttles`、`SystemErrors`、`UserErrors` | 錯誤分類：throttle 回 429、quota 回 **402** |
| `SessionCount` | 新建 session 數，**累計值** |
| **`ActiveSessionCount`** | 目前進行中的 session 數，可依 Runtime / CodeInterpreter / Browser 篩；**用來監控 session 配額，建議設警報** |
| `CPUUsed-vCPUHours`、`MemoryUsed-GBHours` | 資源用量，接近帳單但**最多延遲 60 分鐘、不等於實際帳單** |
| `ActiveStreamingConnections`、進出 byte 數 | WebSocket 雙向串流容量規劃 |

| Log 類型 | 內容 |
|---|---|
| `APPLICATION_LOGS` | 每次呼叫的 trace/span ID，**加上完整的 `request_payload` 與 `response_payload`**（即使用者對話全文） |
| `USAGE_LOGS` | 每個 session 每秒的 vCPU-hours 與 GB-hours，可用來把成本分攤到個別 session 或使用者 |

### 在 agent 程式裡加 instrumentation

| 情境 | 做法 |
|---|---|
| **Runtime 上的 agent** | 加 `aws-opentelemetry-distro>=0.18.0`，用 `opentelemetry-instrument python main.py` 啟動；框架要開 OTel（Strands 內建；LangChain、CrewAI 等用 OpenInference、OpenLLMetry、OpenLit、Traceloop 等套件） |
| **AgentCore 之外（EKS、EC2）** | 同上，再設 `AGENT_OBSERVABILITY_ENABLED=true`、`OTEL_PYTHON_DISTRO=aws_distro`、`OTEL_RESOURCE_ATTRIBUTES=service.name=…,aws.log.group.names=…`、`OTEL_EXPORTER_OTLP_LOGS_HEADERS=x-aws-log-group=…`、`OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf`；**session ID 要用 OTel baggage 的 `session.id` 帶入** |
| **Lambda** | 用 AWS 的 OpenTelemetry Lambda Layer，設 `AWS_LAMBDA_EXEC_WRAPPER=/opt/otel-instrument` |
| **送到 Datadog、Langfuse 等** | Runtime 設 `DISABLE_ADOT_OBSERVABILITY=true` 取消預設 ADOT 設定，再自行設定 exporter |
| **Harness** | 預設全開，不用設定 |

- **不支援 ADOT Collector**：只能直接用 ADOT SDK 或 Lambda Layer 送出。
- **跨服務串接 trace**：呼叫時帶 `X-Amzn-Trace-Id`（X-Ray 格式）或 `traceparent`（W3C 格式），加上 `baggage`；內建工具與 Identity 的 API 也吃這些 header，整條 trace 能接起來。

### 隱私治理（研究判斷）
個資會出現在三處：`APPLICATION_LOGS` 的 payload、span 裡的 prompt 與工具結果、CloudTrail 裡的 JWT `sub`。建議：
- log group 用 **KMS CMK** 加密，依法規設保留天數。
- 用 CloudWatch Logs 的 **data protection policy** 遮罩個資（CloudWatch 功能，另計費）。
- 不想讓 prompt 落地：確認 span 內容擷取設定、不開 `APPLICATION_LOGS` 或在前面加遮罩。
- 用「每個 agent 獨立 log group」把存取權限限縮到負責該 agent 的團隊。

### 成本
- 全依 CloudWatch 計價：span ingestion 約每 GB $0.35、log 約每 GB $0.50，另有儲存與查詢費（研究日 2026-09-30 的價格）。
- **agent 的 span 很大**：含 prompt 與回應，一輪對話可能數 KB 到數十 KB，工具結果是長文件時更大。研究判斷：**流量大時 CloudWatch 費用可能超過 Runtime 本身**。
- 自己推一下量級（推測）：假設每輪 20 KB span、每天 100 萬輪 ≈ 20 GB/天 × $0.35 ≈ $7/天 ingestion，再加上同量級的 application log（×$0.50）與儲存；若工具常回傳長文件，每輪 200 KB 就是十倍。
- 控制手段：Transaction Search 的**索引抽樣比例**（`UpdateIndexingRule`）、縮短 log 保留期、只在需要的環境開 payload 記錄。

### 多帳號
用 CloudWatch **cross-account observability**（OAM 的 sink 與 link）在一個監控帳號看所有來源帳號的 agent；要分享 Metrics 與 Logs 兩種；**只能在同一區域內**；部分操作（例如跳到 Bedrock Console 看資源細節）必須登入來源帳號。

### 建議的警報（研究判斷）

| 警報 | 依據 |
|---|---|
| Session 配額快用完 | `ActiveSessionCount` 超過配額 80% |
| Throttle/quota 錯誤增加 | `Throttles`、`UserErrors` 中的 `ServiceQuota` |
| 延遲異常 | `Latency` p90 |
| 記憶萃取失敗 | Memory 的 `FailedExtraction` |
| 成本異常 | `CPUUsed-vCPUHours`／`MemoryUsed-GBHours` 日增量，搭配 Budgets |
| agent 陷入迴圈 | 單一 trace 的工具呼叫次數或 token 數超過門檻（從 span 用 Logs Insights 算） |

## ⚠️ 注意 / 什麼時候不適用
- **文件疑似名實相反：** `AWS_GENAI_CONTENT_EXTRACTION_OPT_OUT=true` 看名字像「不要擷取內容」，官方說明卻是「讓模型 payload 與工具請求回應**保留在 span 上**」。上線前一定要實測 span 裡到底有沒有 prompt。
- 踩雷清單：
  1. 沒開 Transaction Search 就看不到 span（帳號層級一次性設定）。
  2. 只靠 Runtime 自動產生的 span 不夠，agent 內部 span 需要 ADOT（Harness 除外）。
  3. ADOT 要 ≥ 0.18.0 才能把 span 送進 agent 自己的 log group。
  4. `APPLICATION_LOGS` 記錄完整 payload，等於把使用者對話全寫進 CloudWatch。
  5. 資源用量 metric 最多延遲 60 分鐘，不等於帳單。
  6. 不支援 ADOT Collector。
  7. 跨帳號監控僅限同區域。
  8. Memory、Gateway、內建工具的 log delivery 預設不送，要自己設定。
- 不適用：已經全面用 Datadog、Langfuse 等第三方平台的團隊，重點會變成關掉預設 ADOT、改接自家 exporter，AgentCore 的 GenAI Observability 頁就用不上（推測）。

## 🧪 我實際套用的紀錄
- （尚無）原研究本篇沒有附實驗；隱私設定（`APPLICATION_LOGS`、內容擷取變數）、每輪 span 大小的成本模型、以 trace 做迴圈偵測告警，都列為研究的待調研方向。
- 關聯：Nova Act 可用 ADOT 加 OTel baggage 帶入 Nova Act 的 session ID，把 CloudWatch trace 與 Nova Act Console 的逐步紀錄串起來；Nova Act 另有自己的 `AWS/NovaAct` 指標。Identity 的 span 則能還原「使用者 → agent → 哪個 credential provider」。

## 🔗 相關
- [[LLM 可觀測性]]
- [[AgentCore Runtime]]
- [[AgentCore Evaluations與Optimization]]
- [[AgentCore Identity]]
- [[AgentCore Memory]]
- [[Nova Act 部署維運與HITL]]
- [[AgentCore 總覽與Harness vs Runtime]]
