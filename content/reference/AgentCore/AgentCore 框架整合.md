---
type: reference
name: "AgentCore 框架整合 Framework Integrations"
source: "[[AgentCore 與 Nova Act 研究]]"
source_type: docs
tags: [ai, llm, agent, aws, agentcore, strands, langgraph, claude-agent-sdk, mcp, framework]
triggers: [團隊已經用LangGraph寫好agent想接上AWS代管服務, 不確定哪個agent框架在AWS上支援最完整, 用Claude-Agent-SDK寫的agent上雲後評估數據怪怪的, 怕綁死某個框架以後很難換, TypeScript團隊想做agent但範例都是Python]
---

> 原始研究：[GitHub](https://github.com/VagrantPi/AagentCore-Research/tree/main/90-integrations)（依原研究，查證 2026-09-30）

## 🎯 什麼情境該想到我
當你「手上已經有某個 agent 框架（Strands、LangGraph、Claude Agent SDK、OpenAI Agents SDK…）或正要選框架，想知道它接上 AgentCore 各元件時哪些有原生整合、哪些得自己接、會踩到什麼坑」的時候。

## ⚙️ 怎麼用

### 核心觀念：AgentCore 不綁框架，接法只有三種
任何框架（或不用框架）接 AgentCore，都落在這三條路之一：

1. **框架專用 adapter**：例如 Strands 的 memory session manager、LangGraph 的 checkpointer 與 store、Payments 的 plugin / middleware。整合最深、要寫的程式碼最少，但只有少數框架有。
2. **透過 Gateway 走 MCP**：任何支援 MCP client 的框架都能用 Gateway 上的工具、Memory connector、Web Search 等。**這是最通用的接法。**
3. **直接呼叫 AWS SDK 或 AgentCore SDK**：例如 Identity 的 `@requires_access_token` 裝飾器、Code Interpreter 的 client，任何 Python 框架都能用。

原研究的判斷：**能走 MCP 的就走 MCP**（工具、Memory connector），框架間差異降到最低、日後換框架也容易；只有需要「深入框架內部生命週期」的功能才用專用 adapter——例如 checkpoint、每次呼叫模型前的 hook、自動攔截 HTTP 402。

### 支援度排名
- **Strands 是一等公民**：Harness 底層就是 Strands，`agentcore export harness` 產出的也是 Strands 程式碼，Payments plugin、Memory、評估整合都最完整。
- **LangGraph 次之**：Memory（checkpoint + store）、Payments（middleware）、評估都有官方整合。
- **語言**：以 Python 為主，**TypeScript 也有完整支援**（AgentCore CLI、Strands TS、Node 22 CodeZip、Vercel AI SDK、LangGraph JS 的評估）。其他語言可用 container + AWS SDK——因為 Runtime 的契約只是 `0.0.0.0:8080` 上的 `POST /invocations` 與 `GET /ping`。

### 框架 × 元件對照
「✓」＝官方有專屬整合或文件；「MCP/SDK」＝透過 Gateway 或自己呼叫 API；「—」＝官方文件沒提。

| 框架 | Runtime 部署 | Memory 原生 | 評估／可觀測 instrumentation | Payments | Harness |
|------|:---:|:---:|------|:---:|:---:|
| Strands（Py/TS） | ✓ | ✓ `AgentCoreMemorySessionManager` | ✓ 內建 OTel（TS 需 ≥ 1.5.0） | ✓ plugin | 底層框架；export 目標 |
| LangGraph / LangChain（Py/TS） | ✓ | ✓ `langgraph-checkpoint-aws`（`AgentCoreMemorySaver` / `Store`） | ✓ OTel 或 OpenInference（Py）；ADOT、Traceloop、OpenInference（TS） | ✓ middleware | — |
| OpenAI Agents SDK（Py/TS） | ✓ | MCP/SDK | ✓ OTel 或 OpenInference | — | — |
| Google ADK | ✓ | MCP/SDK | ✓ OpenInference | — | — |
| LlamaIndex | ✓ | ✓（官方列為 Memory 支援框架） | ✓ OTel 或 OpenInference | — | — |
| Claude Agent SDK | ✓ | MCP/SDK | ✓ OpenInference（≥ 0.1.3）；⚠️ 只有 `AGENT`、`TOOL` span | — | export「即將推出」 |
| Vercel AI SDK（TS） | ✓（Node 22） | MCP/SDK | ✓ ADOT-native | — | — |
| CrewAI | ✓（官方列在 Runtime 支援框架） | MCP/SDK | Observability 有提到；**評估支援清單沒有**，只能走通用 instrumentation | — | — |
| 自己寫的迴圈 | ✓（符合 HTTP 契約即可） | SDK | 自訂 OTel span，遵循 GenAI semantic conventions | 自己呼叫 `ProcessPayment` | — |

### 各元件的接法

| 元件 | 通用接法 | 框架專用接法 |
|------|---------|--------------|
| Runtime | 包一層 `BedrockAgentCoreApp` 的 `@app.entrypoint`，或自己實作 `/invocations` 與 `/ping` | 官方範例有 Strands、LangGraph、ADK、OpenAI Agents |
| Memory | `MemoryClient` 或 AWS SDK 的 `CreateEvent` / `RetrieveMemoryRecords`；或 Gateway 的 Memory connector 走 MCP | Strands：session manager；LangGraph：`AgentCoreMemorySaver` 管短期記憶與 checkpoint、`AgentCoreMemoryStore` 管長期記憶，`thread_id` 對應 session、`actor_id` 對應 actor |
| Gateway | 任何 MCP client（streamable HTTP） | 各框架 MCP adapter，如 Strands 的 `MCPClient`、`langchain-mcp-adapters` |
| Identity | `@requires_access_token`、`@requires_api_key` 裝飾器（Python）或 AWS SDK | — |
| 內建工具 | SDK 的 `code_session`、browser client；Browser 可接 Playwright、browser-use、Nova Act | Strands 有內建工具包裝 |
| Observability | ADOT + `opentelemetry-instrument` | 依框架挑 instrumentation 套件（見上表） |
| Evaluations / Optimization | span 符合支援的 scope name 就能評估；讀 configuration bundle 用 `BedrockAgentCoreContext.get_config_bundle()` | 官方有 Strands（hook）、LangGraph、ADK、OpenAI SDK 讀 bundle 的範例 |
| Policy | **在 Gateway 上生效，跟框架無關** | — |
| Payments | `PaymentManager.generate_payment_header()` 或直接呼叫 `ProcessPayment` | Strands：`AgentCorePaymentsPlugin`；LangGraph：`AgentCorePaymentsMiddleware` |

**為什麼評估會跟框架有關**：Evaluations 服務是**依 span 的 scope name 判斷是哪個框架**產生的 trace，再依該框架的 span 結構去解讀「哪一段是模型呼叫、哪一段是工具呼叫」。所以 instrumentation 套件版本不夠新、或你自己改寫／包裝 instrumentation，評估服務就可能讀不懂 span。

### Claude Agent SDK 的重點
- **是什麼**：Claude Code 背後的 agent 框架，內建檔案操作、shell、MCP 等工具，特別擅長 coding 與檔案類任務。
- **在 AgentCore 的位置**：走「程式碼定義 agent」路線部署到 Runtime（官方在 Bedrock Agents Classic 遷移指南中也列為可選框架）；工具把 Gateway 當遠端 MCP server 接上，一併取得 Policy、Identity 等治理；模型可透過 Bedrock 用 Claude；評估用 `openinference-instrumentation-claude-agent-sdk`（≥ 0.1.3），在 Runtime 上由 ADOT 自動啟用，只要把套件加進相依清單。
- **⚠️ span 結構差異**：這個 instrumentation **只產生 `AGENT` 與 `TOOL` 兩種 span，沒有獨立的模型呼叫 span**，模型名稱與 token 用量記在 `AGENT` span 上。依賴「模型呼叫 span」的分析或評估方式要另外調整（原研究判斷）。
- **跟 Harness 的關係**：Harness 目前只能 export 成 Strands，Claude Agent SDK 版官方標「即將推出」。

### 延伸：Bedrock Managed Agents（with OpenAI，預覽中）
這是跟 AgentCore Harness **平行的另一個「代管 harness」選項**：
- AWS 執行 **OpenAI Codex 的 harness**（agent 迴圈），模型是 `openai.gpt-5.6-luna`。
- 需要執行指令或處理檔案時才把工作交給「環境」：可以是你本機的 `codex exec-server`，或**你帳號裡的 AgentCore Runtime**（每 session 一台 microVM，可接 VPC 或用 Instances）。
- **模型呼叫留在 Bedrock Managed Agents 那側**，你的 container 只負責執行 agent 送來的指令。
- 呼叫端用 OpenAI SDK 的 `client.beta.agents`，端點是 `bedrock-mantle`。
- 跟 Harness（底層 Strands）的差別在於 agent 迴圈的實作與模型供應商。

### 選框架的建議（原研究判斷）

| 情境 | 建議 |
|------|------|
| 新專案，想用最多 AgentCore 功能、寫最少程式碼 | **先用 Harness**，要掌控迴圈時 export 成 Strands |
| 需要 graph / workflow 編排、狀態機 | LangGraph（Memory、Payments、評估整合都完整） |
| Coding agent、大量檔案與 shell 操作 | Claude Agent SDK，或 Harness（內建 shell 與檔案工具）；評估時注意 span 結構差異 |
| 團隊已熟悉某框架 | 沿用，透過 MCP 或 SDK 接 AgentCore，**不必為了 AgentCore 換框架** |
| TypeScript 為主的團隊 | Strands TS 或 Vercel AI SDK，搭配 Node 22 CodeZip 部署 |
| 網頁操作為主（填表、擷取、UI 測試）且目標網站沒 API | Nova Act workflow 跑在 Runtime + Browser；需要跨系統推理時由 Strands 等框架把 Nova Act 當工具 |

**一個實用的思考順序**（推測，依上述判斷整理）：先問「Harness 能不能滿足」→ 不能再問「需要哪種迴圈控制（graph？coding？）」選框架 → 最後逐一元件決定「走 MCP 還是專用 adapter」，預設 MCP，只有 checkpoint、402 自動處理這類深入生命週期的需求才用 adapter。

## ⚠️ 注意 / 什麼時候不適用
- **踩雷清單**：
  1. **Instrumentation 套件有最低版本**：LangGraph 的 OTel 需 ≥ 0.55.0、Claude Agent SDK 需 ≥ 0.1.3、Strands TS 需 ≥ 1.5.0；版本不夠，評估服務讀不懂 span。
  2. **評估依 scope name 認框架**，自行改寫或包裝 instrumentation 可能導致無法評估。
  3. **Claude Agent SDK 沒有模型呼叫 span**。
  4. **Strands Memory 的 `batch_size > 1` 時一定要 `close()` 或用 `with`**，否則最後一批還沒送出的訊息會遺失。
  5. **LangGraph 的 `thread_id` 與 `actor_id` 是對應 Memory session 與 actor 的必填欄位**，要跟 Runtime 的 session 設計一致。
  6. **Payments 的自動 402 處理只有 Strands 與 LangGraph 有**，其他框架要自己攔 402 並呼叫 API。
  7. **CrewAI 不在評估支援清單**。
  8. **Harness 只能 export 成 Strands**。
- 走 MCP 雖通用，但原研究也列為待驗證方向：以 MCP 為核心的「框架中立」做法跟框架專用 adapter 在功能與延遲上的差距**尚未量化**。
- Bedrock Managed Agents 仍在預覽，模型與 API 名稱以官方為準。
- 對照表的「—」代表「官方文件沒提」，不等於確定不支援。

## 🧪 我實際套用的紀錄
- （尚無）90 篇為文件調研，無實驗。原研究列出的後續方向：Claude Agent SDK on AgentCore 完整參考架構（含補足模型呼叫 span）、MCP 為核心的框架中立策略量化、LangGraph 與 Strands 用同一客服情境比較整合深度。

## 🔗 相關
- [[AgentCore 總覽與Harness vs Runtime]]：Harness 底層是 Strands、export 路徑
- [[AgentCore Runtime]]：所有框架的部署落點與 HTTP 契約
- [[AgentCore Memory]]：Strands session manager 與 LangGraph checkpointer/store 對接的對象
- [[AgentCore Gateway]]：最通用的 MCP 接法
- [[AgentCore Evaluations與Optimization]]：span scope name 決定能否評估
- [[AgentCore Observability]]：各框架 instrumentation 的輸出端
- [[AgentCore Payments]]：只有 Strands 與 LangGraph 有自動 402 處理
- [[Nova Act 與AgentCore整合及安全]]：Nova Act 當工具、跑在 Runtime + Browser
- [[LLM 可觀測性]]：OTel / OpenInference span 結構的通用觀念
