---
type: reference
name: "AgentCore Runtime 代管執行環境 Runtime"
source: "[[AgentCore 與 Nova Act 研究]]"
source_type: docs
tags: [ai, llm, agent, aws, agentcore, runtime, microvm, serverless, coding-agent, security]
triggers: [自己寫好的agent要找地方跑而且每個使用者要隔開, agent任務一跑好幾個小時怕被砍掉, 做會改repo跑測試的coding-agent要怎麼架, 使用者A會不會連進使用者B的agent環境, 冷啟動太慢想讓每次開新session都一樣快]
---

> 原始研究：[GitHub](https://github.com/VagrantPi/AagentCore-Research/tree/main/01-runtime)（依原研究，查證 2026-09-30）

## 🎯 什麼情境該想到我
當你「已經有自己寫的 agent 程式碼（任何框架），要找一個能讓每位使用者各自隔離、能跑好幾小時、還能保存工作區的地方部署」的時候。

## ⚙️ 怎麼用

### 資源模型：像 Lambda，但多了 session 這層狀態
```
Agent Runtime（一個 agent 或 tool，有自己的 execution role）
├── Version 1, 2, 3 …（不可變；改 image／協定／網路都產生新版；每個 agent 最多 1,000 個）
├── Endpoint（每個 agent 最多 10 個）
│     ├── DEFAULT → 永遠指向最新版（自動建立）
│     └── prod / staging … → 手動指定版本，控制上線與回滾
└── Session（以 runtimeSessionId 識別）→ 一台專屬 microVM，CPU／記憶體／檔案系統與其他 session 隔離
```
- **版本切換不影響進行中的 session**：每台 microVM 用的是建立當下的程式碼，session 最長 8 小時，所以新舊版本並存期間比 Lambda 長。
- **inbound 驗證每個版本只能擇一**：IAM（SigV4）或 JWT（OAuth），兩種都要就分成不同版本或 endpoint。

### 對開發者的要求很薄：服務契約
一個 ARM64 container，監聽 `0.0.0.0`，依協定只差 port 和路徑：

| 協定 | Port | 路徑 | 用途 |
|------|------|------|------|
| HTTP | 8080 | `POST /invocations`（JSON 或 SSE）、`/ws`、`GET /ping` | 一般 agent API |
| MCP | 8000 | `POST /mcp`（streamable HTTP） | 把 Runtime 當 MCP 工具伺服器 |
| A2A | 9000 | `/` | agent 互相呼叫，靠 Agent Card 做服務發現 |
| AG-UI | 8080 | `/invocations`（SSE）、`/ws` | 把中間步驟逐步渲染到前端 |

`/ping` 回 `{"status": "Healthy"}` 或 `{"status": "HealthyBusy"}`。用 Python SDK 的 `BedrockAgentCoreApp` 會代管這些 endpoint；不用 SDK 也行，只要符合契約——這就是 Runtime 綁定程度低的原因。

### 兩個正交的選擇

**運算型態：microVM（預設）vs Instances**

|  | microVM | Instances |
|--|---------|-----------|
| 管理 | 全託管 serverless | AWS 在**你的帳號**代管 EC2 |
| Session 最長 | 8 小時 | 14 天 |
| 架構 | 只有 `arm64` | `x86_64`、`arm64` |
| 網路 | PUBLIC 或 VPC | 只能 VPC |
| 一個 session 的 agent 數 | 1 | 多個（同 session ID 落在同一台機器、共享檔案系統） |
| GPU | 不支援 | g4dn、g5、g6、g6e、g7e、inf2 等 |
| 持久儲存 | Session storage（預覽）、EFS、S3 Files | EBS（由 capacity provider 定義） |
| 硬體上限 | 2 vCPU / 8 GB | 看機型 |

運算型態建立後不能改；capacity provider 建立後只能改描述。**預設 microVM，要超過 8 小時、要 GPU、或多 agent 共用一台機器才用 Instances。**

**平台版本：V1（預設）vs V2**——V2 原理同 Lambda SnapStart：初始化後拍記憶體快照，每個新 session 從快照還原。V2 冷啟動不受 image 大小與並發量影響、較穩定；但建立／更新要**幾分鐘**（製作快照）、啟動後 120 秒內 `/ping` 必須健康、環境變數上限縮到 1.5 KB（direct code）/ 2.5 KB（container）（V1 為 4 KB）、單價較高但閒置 120 秒回收記憶體、只在 us-east-1、us-east-2、us-west-2、eu-west-1、東京可用，且 **CloudFormation / CDK 目前無法設定 `platformVersion`**。

**V2 的程式碼規則**——啟動階段做的事會凍結進快照，每個還原實例拿到一模一樣的狀態：
- 隨機數／UUID／token 不要在啟動時產生（`random` 的 seed 也相同），改在 handler 裡用 `secrets` 或 `os.urandom()`；OpenSSL 等密碼學函式庫還原後目前**不會重新取亂數種子**（官方已知限制）。
- 時間與 `time.monotonic()` 會停在拍快照那刻；hostname 一律 `localhost`、PID 一律 `1`，不能當實例 ID。
- 短效憑證與 Gateway 工具清單不要在啟動時快取（會過期／被凍結）。
- 適合放啟動階段的：import、靜態設定、建立 client 並暖機（連線不延續，但解析好的 endpoint 與憑證設定快取會保留）。

### 打包：Container vs Direct code（zip）
Container 上限 2 GB、任何語言、**你**負責定期用新 base image 重 build；zip 壓縮後 250 MB／解壓 750 MB、Python 3.12–3.14 與 Node.js 22、**AWS 自動修補且無法關閉**、第二次後部署明顯較快。官方建議先用 zip 快速迭代，超過 250 MB、要系統相依套件、或已有 container CI/CD 再換 container。

### Session 生命週期
- 狀態：第一次 invoke 配置 microVM → Active；處理完且 `/ping` Healthy → Idle；同 ID 再呼叫回 Active；`HealthyBusy` 則維持 Active；閒置逾時（預設 15 分鐘）或 `StopRuntimeSession` → Stopped；到 `maxLifetime`（預設 8 小時）或不健康 → Stopped。
- **Session 不會過期，消失的是 microVM**：Stopped 後同 ID 再呼叫會拿到新 microVM，記憶體狀態沒了；session ID 有效到 runtime 被刪除為止。
- Session ID **至少 33 字元**，可由呼叫端給或第一次由 Runtime 產生。路由靠 header：HTTP / A2A / AG-UI 用 `X-Amzn-Bedrock-AgentCore-Runtime-Session-Id`，MCP 用 `Mcp-Session-Id`；**不帶就可能每次都冷啟動**。
- 在 session 建立或銷毀中送請求會得到 409 `RetryableConflictException`：AWS SDK 會自動重試，但 MCP 回 HTTP 200、錯誤包在 JSON-RPC body 裡，**不會自動重試**。
- Lifecycle：`idleRuntimeSessionTimeout` 預設 900 秒（microVM 可設 60–28,800；Instances 60–1,209,600）、`maxLifetime` 預設 28,800 秒。閒置計時每次呼叫重設，`maxLifetime` 不重設。閒置越短越省（記憶體閒置仍計費），但冷啟動機率越高。

### 狀態存哪一層
| 位置 | 存活範圍 | 適合 |
|------|---------|------|
| microVM 記憶體／本機磁碟 | 到 microVM 停止 | 暫存 |
| Session storage（預覽） | 跨停止與恢復；**14 天沒呼叫就清空；更新 runtime 版本也清空**；上限 1 GB | coding agent 專案目錄 |
| EFS / S3 Files（需 VPC） | 永久，可跨 session／agent 共享 | 共用工具庫、資料集、模型權重 |
| Instances 的 EBS | 到 session 被刪除 | 長任務 checkpoint |
| AgentCore Memory | 永久、結構化 | 對話歷史、使用者偏好 |

每個 runtime 最多掛 5 個檔案系統，路徑須為 `/mnt/<名稱>`。

### 串流與長任務
- 同步 15 分鐘、payload 100 MB；SSE 60 分鐘、每 chunk 10 MB；WebSocket 60 分鐘、每 frame 64 KB、每秒 250 frame；WebRTC（語音 agent）需要 VPC 模式與 TURN relay。
- MCP 預設建議 stateless（平台產生 `Mcp-Session-Id`，server 不能拒絕）；需要 elicitation 或 sampling 才用 stateful（MCP `2026-07-28` 規格改用 multi round-trip 後 stateless 也能做）。
- **長任務做法**：handler 先回「已開始」，工作丟背景執行緒，`app.add_async_task()` 讓 `/ping` 自動變 `HealthyBusy`，完成後 `complete_async_task()` 回到 Healthy。最長 8 小時（再長用 Instances）。官方**沒有完成通知機制**，文件模式是使用者晚點用同 session ID 回來查；要主動通知得自己送 SNS / EventBridge / webhook（原研究判斷）。

### 網路
PUBLIC 模式能上網但連不到你 VPC；VPC 模式透過 service-linked role 在子網建 ENI——**放 public subnet 也出不了網**，要 private subnet + NAT；**AZ 有白名單**（東京只支援 `apne1-az1`、`az2`、`az4`，不含 `az3`）；建議加 ECR、S3 gateway、CloudWatch Logs endpoint（container 會定期重拉 image，否則全算 NAT 費）；runtime 刪除後 ENI 最多殘留 8 小時。

### 安全要點
1. **AgentCore 不管 session 屬於誰**：平台只檢查 session ID 格式。後端若直接轉送前端給的 session ID，A 猜到或拿到 B 的 ID 就能進 B 的 microVM。session ID 要由後端依已驗證使用者產生，並限制每人 session 數。高安全場景讓每個租戶用不同 IAM principal 呼叫（官方稱最強控制），並用 CloudTrail（同事件記錄呼叫者與 `sessionId`）偵測跨 principal 存取。
2. **VM 內任何程式都拿得到 execution role 憑證**（經 MMDS，類似 EC2 IMDS），agent 又可能執行自己產生的碼 → role 最小權限，且不可大於「能呼叫此 agent 的人」的權限，否則是權限提升。
3. **MMDSv2 自 2026-06-30 強制**：沒設 `metadataConfiguration.requireMMDSV2 = true` 的 runtime 呼叫會得到 `ValidationException`。
4. **驗證 `prompt` 型別**：payload 是任意 JSON，若被塞成 `toolUse` 結構，某些框架會直接執行工具、跳過模型判斷與 guardrail；用 Pydantic 或 Zod 定 schema。
5. **Gateway 放 Runtime 前面並鎖定只收 Gateway 請求**（IAM 型用 resource policy；JWT 型用 `allowedWorkloadConfiguration`），Policy、Guardrails 才繞不過。
6. **限制 agent 打 localhost**：microVM 內有平台服務管 session、儲存與 shell，HTTP 工具任意打 localhost 就成 SSRF 入口。
7. `InvokeAgentRuntimeCommand` / `InvokeAgentRuntimeCommandShell` 是獨立 IAM action，能呼叫 agent 不代表該能下指令；AgentCore CLI 產生的 IAM policy 只適合開發環境。

### Coding agent 架構（延伸篇重點）
- **分工（官方建議）**：需要判斷的交給 agent（`InvokeAgentRuntime`），clone、裝套件、跑測試、git 這類固定流程交給 `InvokeAgentRuntimeCommand`，不讓 LLM 代勞。**測試過沒過由後端依 exit code 判斷**，不是 LLM 說了算。
- 指令 API：每次開新 bash、**不保留 `cd` 與環境變數**，要寫成 `cd /mnt/ws/repo && npm test`；長度 1 byte–64 KB、timeout 1–3600 秒（預設 300）、stdout/stderr 串流最多 100 MB、以 root 執行、可與 agent 同時跑；**CloudWatch 只記錄指令字串，不記 stdout/stderr**；互動 shell 每連線最長 1 小時、每 runtime 最多 10 條；2026-03-17 前部署的 runtime 要重新部署才支援。
- **幾乎一定要 container**：direct code 沒有 git、編譯器（原研究判斷）。
- **工作區**：多租戶用 session storage（每 session 獨立）；**EFS 不適合多租戶**——所有 session 共用掛載點、每 runtime 最多 2 個 EFS access point，agent 有 root shell，目錄區隔形同虛設。1 GB 常不夠（`node_modules` + build + `.git`），可把相依快取放 image、用 shallow clone，再大就改 Instances。
- **更新版本清空工作區**是最大挑戰，建議把 **git remote 當唯一事實來源**：每輪結束由後端經指令 API 取 patch 推到 `wip/<session>` 分支，發現工作區空了就重新 clone 並 checkout。打包 tar 存 S3 不理想（S3 權限是整個 execution role 共用，任何 session 讀得到別人的 prefix）；用 endpoint 固定版本時會不會清空，官方沒說明。
- **推送權杖不進 VM**（原研究判斷）：repo 內容可能夾帶 prompt injection，VM 內憑證 agent 都讀得到。VM 只產出 patch（`git format-patch --stdout` 或 base64 的 `git bundle`），由受信任後端推送；非得讓 VM clone private repo 就用短效、單 repo 唯讀的 GitHub App installation token；權杖不要寫進指令字串（會進 CloudWatch Logs）；VPC 模式加 egress 白名單。
- MVP 先用 Harness（內建 shell／檔案工具）+ 後端指令 API 流程；需要在迴圈內強制插關卡（例如每次改檔都自動 lint）再 export 改 Runtime。

### Instances 上的多 agent 共居（延伸篇重點）
多個 runtime 綁**同一個 capacity provider** 並用**同一 session ID** 呼叫，就會落在同一台 EC2（第一次呼叫開機），可掛同一個 EBS `volumeName` 共享 `/mnt/ws`。每 session 最多 20 個 agent（不可調）。session 停止時 EC2 終止、volume 保留，同 ID 再呼叫會開新機（可能已套新修補）並重掛 volume。
- **隔離單位是 session 不是 agent**：官方原文「neither provides a security boundary」，只能放互相信任的 agent；沒掛載也不代表隔離。
- **權限實際疊加**（原研究推論）：機器上任何程式讀得到可取得的憑證，同機有效權限應視為所有 agent role 的聯集。
- 溝通方式官方只描述共享檔案系統；localhost 互連、agent 自己呼叫其他 runtime 文件未提。
- Infrastructure role 權限大，建議用 IAM 條件限定 VPC、subnet、機型；組織 SCP 唯一管不到的是清理用 service-linked role；instance profile 只收系統 log、不授權給 agent。
- 計費從開機到關機（最少約 1 分鐘）、**閒置照算**；EBS 在 session 停止後持續計費直到刪除 session；會吃你帳號的 EC2 / EBS / ENI 配額。
- **多 agent 模式判斷**：大多數需求先考慮 A2A 或 Harness 的 agent-as-tool（各自 microVM、隔離最好）；只有頻繁交換大量檔案、要 GPU 或超過 8 小時才值得付 Instances 的維運與閒置成本。microVM + 共享 EFS 可讓運算隔離但檔案彼此看得到。

## ⚠️ 注意 / 什麼時候不適用
- **踩雷清單**：handler 阻塞會卡住單執行緒的 `/ping`，15 分鐘後被當閒置砍掉；自寫 `/ping` 每次都把 `time_of_last_update` 設為現在，session 永不閒置、跑滿 8 小時耗光配額；`UpdateAgentRuntime` 是完整覆寫（full PUT），只改一項也要帶 `roleArn`、`agentRuntimeArtifact`、`networkConfiguration` 等必填欄位；direct code 的 Python 3.10 / 3.11 已於 2026-06-30 標示淘汰、**2026-08-31 起禁止更新**；掛 EFS / S3 Files 每個掛載逾時 30 秒、平行掛載，任一失敗整個請求 HTTP 424。
- **文件矛盾**：新 session 建立速率——Direct code 頁寫「container 部署每秒只能建立 1.6 個新 session」，Quotas 頁寫「25 TPS，container 與 direct code 共用」。有流量尖峰就先實測。
- **官方沒公布冷啟動數字**，影響因素只有定性描述（版本、image 大小、VPC、檔案系統掛載、有沒有帶 session header、閒置逾時、Instances 首次開機）。
- Session storage 計費方式定價頁（2026-09）沒寫。
- 單一 session 2 vCPU / 8 GB 上限，大型 monorepo build 可能不夠；不需自訂迴圈、不想碰程式碼時直接用 Harness 即可。

## 🧪 我實際套用的紀錄
- 冷啟動與 session 建立速率實驗（[實驗資料夾](https://github.com/VagrantPi/AagentCore-Research/tree/main/01-runtime/experiments/cold-start)）：**實驗工具已完成、本機驗證通過，但尚未在 AWS 上實跑**（撰寫時沒有 AWS 憑證），結果表是空的。
  - 設計：V1/V2 × container/zip × PUBLIC/VPC，外加 1 GB 填充的大 image，最多 10 個變體，預設東京區（亞太區唯一有 V2）。冷啟動 = 新 session 第一個請求延遲 − 同 session 第二個請求延遲。
  - 用啟動時 `os.urandom` 產生的 `boot_token` 驗證 V2 快照狀態是否在 session 間重複（預期 V1 每次不同、V2 重複）；用關閉自動重試的 burst 測試驗證 1.6/s vs 25/s 的文件矛盾。
  - 順帶發現：boto3 1.43.105 的 service model 中 `CreateAgentRuntime` 沒有 `metadataConfiguration` 參數（只有 Update 有），腳本在遇到 MMDS 錯誤時會補 `UpdateAgentRuntime` 設 `requireMMDSV2=true` 再重試。

## 🔗 相關
- [[AgentCore 總覽與Harness vs Runtime]]：何時該選 Runtime 而非 Harness
- [[AgentCore 框架整合]]：各框架的部署方式
- [[AgentCore Memory]]：長期資料寫這裡
- [[AgentCore Gateway]]、[[AgentCore Identity]]：放在 Runtime 前面的入口與 inbound/outbound 憑證
- [[AgentCore Observability]]：自動輸出 trace、log、metric
- [[Nova Act 部署維運與HITL]]：Nova Act 一鍵部署底層就是 Runtime 容器
- [[提示注入與分層防禦]]：coding agent 讀進的 repo 內容就是不受信任輸入
- [[多 Agent 編排與 Agent Drift]]：Instances 共居 vs A2A vs agent-as-tool 的取捨
