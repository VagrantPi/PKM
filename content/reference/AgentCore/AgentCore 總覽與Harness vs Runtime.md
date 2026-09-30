---
type: reference
name: "AgentCore 總覽與 Harness vs Runtime AgentCore Overview"
source: "[[AgentCore 與 Nova Act 研究]]"
source_type: docs
tags: [ai, llm, agent, aws, agentcore, harness, runtime, architecture, pricing]
triggers: [想把agent搬上AWS但不知道要用哪些服務, 該寫設定檔讓AWS跑agent還是自己寫迴圈, agent該自己架在K8s還是買代管服務, 舊的Bedrock Agents建不了新agent要換什麼, 想估算agent代管平台每個session要花多少錢]
---

> 原始研究：[GitHub](https://github.com/VagrantPi/AagentCore-Research/tree/main/00-overview)（依原研究，查證 2026-09-30）

## 🎯 什麼情境該想到我
當你「要把 AI agent 放上 AWS 正式環境，卻搞不清楚 AgentCore 十幾個元件各管什麼、該讓 AWS 跑 agent 迴圈（Harness）還是自己寫程式碼丟上去跑（Runtime）、以及到底要不要乾脆自建」的時候。

## ⚙️ 怎麼用

### 一句話定位
AgentCore 是 AWS 為 AI agent 提供的**一組託管基礎設施服務**，可以想成「agent 專用的 Lambda/ECS」再加上 Cognito、API Gateway、CloudWatch 這類周邊服務的組合包。三個關鍵性質：
- **模型、框架都不綁定**：可以用 Bedrock 的模型，也可以用 OpenAI、Gemini；可以用 LangGraph、Strands，或自己寫迴圈。
- **元件可以單獨使用**：例如只用 Memory，agent 本身跑在自己的 EKS 上也行。
- **模型呼叫不經過 AgentCore**：agent 自己去打模型供應商，token 費用另外算，不在 AgentCore 帳單裡。

### 為什麼 agent 不能直接丟 Lambda
原研究歸納 agent 工作負載的四個特性，AgentCore 各元件就是對著這四點設計的：
1. **執行時間長、大多在等**：一次任務可能呼叫模型十幾次，每次數秒，總長從數分鐘到數小時，CPU 大半閒著。Lambda 最長 15 分鐘，而且等待也計費。
2. **有狀態**：多輪對話要在同一個環境累積上下文和檔案。
3. **行為不確定**：同輸入不保證同輸出，agent 還可能執行自己產生的程式碼 → 需要**每個 session 硬隔離（microVM）**。
4. **一定會碰外部系統**：要代替使用者存取 Slack、GitHub，憑證管理與授權是核心而非附加功能。

### 元件地圖（官方 12 個，分四層）

| 層 | 元件 | 做什麼（類比） |
|----|------|----------------|
| 執行層 | Harness | 宣告模型、system prompt、工具，AWS 幫你跑 agent loop（像 Heroku 給設定就能跑） |
| | Runtime | Serverless 執行你寫的 agent / tool，每個 session 一台 microVM（Lambda + Fargate 綜合體，session 最長 8 小時） |
| | Built-in Tools | Code Interpreter / Browser / Web Search 代管沙箱 |
| 連接與治理層 | Gateway | 把 REST API、Lambda、既有 MCP server 包成 MCP 工具端點 |
| | Identity | inbound 驗證呼叫者；outbound 代管 OAuth token / API key |
| | Policy | 每次工具呼叫前用 Cedar 做確定性允許／拒絕 |
| | Payments | 遇到 HTTP 402 自動付款後重試，有預算上限 |
| | Registry | 組織內 agent、MCP server、skill 的目錄（像 Backstage） |
| 狀態層 | Memory | 短期對話歷史 + 萃取後的長期知識 |
| 營運層 | Observability | 每一步輸出 OpenTelemetry trace 到 CloudWatch |
| | Evaluations | 對 trace 自動評分（LLM-as-a-judge） |
| | Optimization | 讀 trace 產生 prompt／工具描述修改建議，用 A/B test 驗證 |

**Harness 底層跑在 Runtime 上**，配額也共用 Runtime 的。

### 一個請求怎麼走（Runtime 模式，客服退款為例）
1. Client 帶 JWT 或 SigV4 和 `sessionId` 呼叫 `InvokeAgentRuntime`。
2. Runtime 請 Identity 驗 inbound token，向 Memory 讀這位使用者的歷史與長期記憶。
3. 進入 agent loop：送 prompt + 工具清單給模型 → 模型說「呼叫 `refund(order=123)`」→ Runtime 經 Gateway 發 MCP `tools/call` → **Gateway 先問 Policy**（Cedar 評估 JWT claims）→ 允許後 Gateway 向 Identity 取後端要的 OAuth token → 呼叫真正的 API → 結果回到迴圈。
4. 結束後寫入這輪對話到 Memory（之後非同步萃取成長期記憶），串流回應給使用者；每一步都輸出 OTel span。

關鍵在 **Policy 掛在 Gateway 上而不是 agent 上**：授權發生在工具被呼叫之前，由確定性規則決定而非交給 LLM，所以就算模型被 prompt injection 騙了也繞不過。Harness 模式流程相同，只是迴圈改由 AWS 提供。

### Harness vs Runtime：最重要的一個選擇

|  | Harness | Runtime |
|--|---------|---------|
| Agent loop 由誰寫 | AWS（底層 Strands Agents） | 你自己（任何框架或不用框架） |
| 怎麼定義 | 設定：model、system prompt、tools、memory、limits | 程式碼 + `BedrockAgentCoreApp` entrypoint，打包成 ARM64 container 或 zip |
| 接 Memory / Gateway / Browser / outbound 憑證 | 一個設定欄位 | 自己呼叫 SDK |
| 換模型供應商 | 改設定，甚至同一 session 中途切換 | 自己實作 |
| 額外費用 | 無，只付底層資源 | 無 |

**Harness 心智模型：建立時給預設值、呼叫時可覆寫。** `CreateHarness` 給預設值，每次 `InvokeHarness` 可覆寫 `model`、`tools`、`systemPrompt`、`maxIterations`、`maxTokens`、`timeoutSeconds`、`skills`、`allowedTools`、`actorId`，**不用重新部署**。用意是讓「哪個模型 × 哪段 prompt」的實驗成本趨近零——這一輪用 Claude、下一輪換 GPT，上下文自動延續。

**Harness 能力比想像廣**：
- 工具 5 種接法：`remote_mcp`（header 可引用 Identity token vault ARN，執行時才換成真 key）、`agentcore_gateway`、`agentcore_browser`、`agentcore_code_interpreter`、`inline_function`；另有每個 session 預設開啟的 `shell` 與 `file_operations`。`allowedTools` 支援 glob（如 `@git/read_*`、`@builtin`）。
- Skills 採 AgentSkills.io 格式，平時只把約 100 token 的摘要放進 system prompt，用到才載入全文。
- Memory 用 `actorId` 做使用者隔離，長期記憶有 semantic、summarization、user preference、episodic 四種萃取策略；Context 超長時用 `sliding_window`（預設）或 `summarization`。
- 執行上限預設：`maxIterations` 75、`timeoutSeconds` 3600、`maxTokens` **無上限**、閒置 900 秒、最長 28800 秒（8 小時）。
- 版本不可變、endpoint 具名，回滾就是把 endpoint 指回舊版。

**四個逃生口（不離開 Harness 也能客製）**：
1. **Inline function**：模型決定呼叫某工具時，串流以 `stopReason = "tool_use"` 結束，由呼叫端自己執行（例如跳核准視窗），再用同一個 sessionId 帶 `toolResult` 呼叫回來續跑。等同 Classic 的 return of control，適合 human-in-the-loop 或內網 API。
2. **Lifecycle hooks**：`before_invocation`（deny → 整次停止）、`before_tool_call`（deny → 跳過該工具、迴圈繼續）、`after_tool_call`（deny → 保留結果但整次停止）、`after_invocation`（只回報）。只有 Lambda 目標是同步、能改變流程；SNS / EventBridge 只通知。每個 harness 最多 20 個 hook，同事件多個 Lambda 平行跑、一個 deny 就算 deny。**Hook 只能 allow/deny，不能改寫內容。**
3. **`InvokeAgentRuntimeCommand`**：不經模型直接在 microVM 下 shell 指令，確定、不花 token。agent 管需要判斷的部分，腳本管固定流程（clone、裝套件、跑測試）。
4. **自訂 container 與 Gateway**：工具鏈做成 image；複雜工具邏輯寫成 Lambda 放 Gateway 後面，Harness 只看到一個 MCP 工具。

**硬邊界——出現就改用 Runtime**：指定特定框架（LangGraph、CrewAI、Claude Agent SDK）；graph/workflow 或狀態機編排；複雜多 agent 協作（Harness 只支援 agent-as-tool）；迴圈中改寫訊息或工具輸入（middleware）；分階段不同 prompt；雙向串流（如即時語音）。

**決策順序**：有既有 agent 程式碼要搬 → Runtime；要 graph 編排或複雜多 agent → Runtime；要中途改寫訊息或雙向串流 → Runtime；其餘先看四個逃生口能否解決，能就 Harness，不能就先用 Harness 做原型再 export。

**畢業路徑**：`agentcore export harness --name X [--build CodeZip|Container]` 產出 Strands Python 專案（Claude Agent SDK 版官方標「即將推出」），帶走模型設定、工具、memory、上限、截斷策略、skills、檔案系統掛載、authorizer；另產生 `EXPORT_NOTES.md` 列出需人工處理項目，部署前必看。可部署到 Runtime，**也可部署到任何跑得動 Python 3.12+ 的地方**。官方沒提反向匯入，視為**單向**。代價是 prompt 實驗回到「改碼、重新部署」循環。

### 自建 vs 買：難點在三塊
自建的難處**不在 agent loop**（開源框架都寫好），而在：
1. **每個 session 強隔離**：一般 container 共用 kernel，跑不受信任程式碼不夠；要做「每 session 一台 microVM、用完清、縮到 0、最長 8 小時」得自寫排程器（高）。
2. **outbound OAuth**：每個 SaaS 的 OAuth 實作不同，還要加密保存、自動刷新、撤銷，處理「agent 代替這位使用者行事」的授權鏈（高）。
3. **長期記憶萃取 pipeline**：何時萃取、合併去重、新舊衝突、依使用者隔離 namespace，而且萃取本身花 token（中–高）。

**綁定程度比想像低**（離開代價由低到高）：模型（低）、Runtime（低，契約就是 `0.0.0.0:8080` 的 `POST /invocations` + `GET /ping`）、Observability（低，OTel）、Policy（低，Cedar 開源）、Harness（中低，可 export）、Evaluations（中低）、Gateway（中，agent 端是標準 MCP 但 target 設定專有）、Identity（中，token vault 能否匯出官方沒說）、**Memory（中高：原始資料可用 `ListEvents` / `ListMemoryRecords` 匯出，但萃取與檢索行為帶不走）**。

**該自建的情境**：資料必須留在台灣（AgentCore 沒有台灣區，硬限制）；多雲／地端是硬需求；已有成熟 K8s 平台團隊且 agent 不跑不受信任程式碼；流量極高且穩定、成本為首要（先評估 Runtime Instances）；需要 AgentCore 不支援的隔離或網路模型。**以上皆非 → 用 AgentCore，從 Harness 開始。**

**混合策略**（原研究判斷）：① 全用 AgentCore、只自建 Memory；② agent 跑自己的 EKS，只買 Identity、Code Interpreter/Browser、Gateway + Policy；③ 先全用 AgentCore 快速上線，把 Harness export 當退場路線。

### 計費、區域、配額（2026-09 研究當下，美國區牌價，數字請以官方為準）
- Runtime microVM v1：$0.0895 / vCPU-hour、$0.00945 / GB-hour，**等 I/O 的時間不收 CPU 費**，按秒計、最少 1 秒；v2：$0.1276 / $0.0169，閒置 120 秒後回收記憶體；Instances：EC2 On-Demand 價 + 12% 管理費（GPU 機型 7.8%）。
- Harness 不另收費；Web Search 每千次 $7；Gateway InvokeTool / ListTools 每千次 $0.005、Search $0.025；Identity 每千次 $0.010（透過 Runtime 或 Gateway 用免費）；Memory 短期每千事件 $0.25；Policy 每次 $0.000025；Evaluations 內建評估器每千 input token $0.0024。
- **成本直覺（可自行驗算）**：1 vCPU 實際運算 60 秒 → 0.0895 × 60/3600 ≈ $0.0015；2 GB 維持 5 分鐘 → 0.00945 × 2 × 5/60 ≈ $0.0016；合計**每 session 約 $0.003**。實務上模型 token 費才是大宗，AgentCore 端要盯的是 Web Search、Evaluations 這類按次／按 token 計費項目與 CloudWatch 日誌量。
- 區域：**沒有台灣區**；亞太區**東京 `ap-northeast-1` 元件最齊**（只缺 Payments），Runtime V2 在亞太區只有東京有；`us-east-1`、`us-west-2` 功能與配額最完整。
- 影響架構的配額：單 session 2 vCPU / 8 GB（不可調）；session 最長 8 小時、閒置 15 分鐘（可調）；同步請求 15 分鐘（不可調）；**新 session 建立 25 TPS／帳號**（流量尖峰最先撞到）；同時 session 數 us-east-1 / us-west-2 為 5,000、其他區 2,500；image 2 GB；Gateway 工具呼叫 200 TPS。

### 跟 Bedrock Agents Classic 的關係
2026-07-30 起舊 Bedrock Agents 更名 **Bedrock Agents Classic**、進入維護模式：過去 12 個月沒用過的帳號呼叫 `CreateAgent` 會收到 403 且無例外管道；模型清單凍結，新模型只上 AgentCore；尚無終止日期；Bedrock 推論、Knowledge Bases、Guardrails 不受影響。概念對應：託管 orchestration → Harness；Action groups → Gateway 包成的 MCP 工具；Prompt override（分階段）→ **只有整體 system prompt**；Multi-agent collaboration → Harness 只支援 agent-as-tool，複雜協作要 Runtime；Return of control → inline function。

## ⚠️ 注意 / 什麼時候不適用
- **Harness 踩雷**：
  - 用 API 建立時**預設開啟 managed memory**（持續產生費用），用 AgentCore CLI 建立則預設關閉；刪 harness 預設連同 memory 一起刪，要保留得帶 `deleteManagedMemory=false`。
  - 內建 `shell` / `file_operations` 預設開，每次呼叫模型多約 900 input token，且 agent 在 microVM 內有 root shell，不需要就用 `allowedTools` 關掉。
  - `allowedTools` 管不到 `InvokeAgentRuntimeCommand`，要靠 IAM 不授權該 action。
  - `maxTokens` 預設無上限，陷入重複迴圈會跑到 75 次或 1 小時才停，正式環境必設。
  - 自訂 container 的 `ENTRYPOINT` / `CMD` 會被覆寫，背景服務要在 session 開始後用 shell 指令另外啟動。
  - inline function 的結果由呼叫端提供，`after_tool_call` 不能證明呼叫端真的執行了動作，拿來稽核前要自己驗證。
  - `additionalParams` 能改 endpoint、憑證、region，轉送使用者設定前一定要過濾。
  - 同步 hook 最長可等 900 秒，SDK read timeout 要設更長；經 NAT/NLB 時 TCP keepalive 要小於 350 秒。
  - CloudTrail 上 Harness 操作記成 `AWS::BedrockAgentCore::Runtime`，稽核查詢要注意。
- **文件矛盾**：Web Search 可用區域，區域表寫 us-east-1、愛爾蘭、東京，Harness 的 Tools 頁卻寫「只有 us-east-1」，使用前自行驗證。
- **自建比較的成本部分是原研究的工程判斷，沒有實際數據**；Identity token 遷移時使用者需重新授權所有第三方服務，是原研究的推論、未經證實。
- 資料必須留在台灣、或必須多雲／地端時，AgentCore 本身就不適用。

## 🧪 我實際套用的紀錄
- （尚無）00 篇為文件調研，無實驗；Runtime 冷啟動實驗見 [[AgentCore Runtime]]。

## 🔗 相關
- [[AgentCore Runtime]]：Harness 底層就跑在 Runtime 上
- [[AgentCore 框架整合]]：選 Runtime 後要搭哪個框架
- [[AgentCore Gateway]]、[[AgentCore Policy]]：請求路徑中的工具入口與授權點
- [[AgentCore Memory]]：綁定程度最高的元件
- [[AgentCore Identity]]：自建最難的 outbound OAuth
- [[ReAct 與 Agent Loop]]：Harness 代管的就是這個迴圈
- [[可逆性、審計與人類把關]]：inline function 的人工核准模式
