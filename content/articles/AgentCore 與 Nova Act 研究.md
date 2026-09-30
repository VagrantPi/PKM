---
type: article
title: "AgentCore 與 Nova Act 研究（Amazon Bedrock AgentCore＋Amazon Nova Act）"
source_url: https://github.com/VagrantPi/AagentCore-Research
author: 自撰（依 AWS 官方文件、官方範例與本機實驗整理）
site: github.com/VagrantPi
tags: [software, ai, llm, agent, aws, agentcore, nova-act, security, evaluation]
captured: 2026-09-30
read_status: read
---

## 📌 30 秒摘要
> 自己對 **Amazon Bedrock AgentCore** 與 **Amazon Nova Act** 的研究。原始研究共 42 篇，另附本機實驗；資料查核日期是 2026-09-30。
>
> **AgentCore** 是 AWS 給 AI agent 的一組代管基礎設施：執行環境（Runtime／Harness）、記憶、工具入口（Gateway）、身分與憑證、內建沙箱工具、可觀測性、評估、授權（Cedar）、自動付費。定位類似「agent 專用的 Lambda／ECS，再加上 Cognito、API Gateway、CloudWatch 的組合包」。**模型和框架都不綁定，各元件可以單獨使用**。
>
> **Nova Act** 是 AWS 的瀏覽器自動化 agent：用自然語言＋Python 寫 workflow，由專門訓練的模型「看畫面、決定下一步」，可以跑在 AgentCore 的 Runtime 與 Browser 上。
>
> 研究的價值不在翻譯文件，而在三件事：**每篇開頭的判斷**、**踩雷清單**，以及**官方文件自相矛盾之處**（例如 IAM ARN 格式、區域、配額前後不一）。

## 🗺 架構速覽
```text
User Request → Runtime → Gateway → Policy (Cedar) → Backend / Tools
                  │         │
                  │         └─ Identity（inbound 驗證 / outbound 憑證）
                  ├─ Memory（短期 / 長期記憶）
                  ├─ Payments（x402 自動付費）
                  ├─ Built-in Tools（Code Interpreter / Browser / Web Search）
                  │                                 ▲ CDP
                  │        Nova Act（瀏覽器 agent：看畫面 → 決定下一步）
                  └─ Observability（OTel → CloudWatch） → Evaluations
```

## 🎯 為什麼存這份研究 / 未來想拿它做什麼
- 要把 agent 放上正式環境時，先用這份研究回答「自建還是代管」「哪幾塊最難自建」。
- 設計 agent 的**身分、授權、入口**這三件安全相關的事，研究裡的判斷是廠商中立的，換平台也用得上（抽成下面的工具卡）。
- 做 agent 的 CI 與評估時，拿它的測試金字塔與門檻設計當範本。
- 有沒有 API 的網頁系統要自動化時，評估 Nova Act。

## 🧰 這份研究給我的工具（連到 tools/）
- [[工具-agent平台自建還是用代管]] —— agent 要上線，得決定自己架還是用雲端代管時
- [[工具-把業務規則從prompt搬到授權層]] —— 寫在 system prompt 的規則沒辦法保證模型照做時
- [[工具-agent代使用者存取的身分設計]] —— agent 要代表使用者呼叫內部 API 或第三方服務時
- [[工具-讓Gateway當agent唯一入口]] —— agent 前面加了閘道，卻擔心有人繞過時
- [[工具-agent的測試金字塔]] —— 想在 CI 擋住 agent 退化，但輸出每次都不一樣時

## 🗂 型錄：逐元件展開（`reference/AgentCore/`）

**全局**
- [[AgentCore 總覽與Harness vs Runtime|AgentCore 總覽與 Harness vs Runtime Overview]] —— 元件地圖、計費、Harness 還是 Runtime、自建 vs 代管（[原始研究](https://github.com/VagrantPi/AagentCore-Research/tree/main/00-overview)）
- [[AgentCore 框架整合|框架整合 Framework Integrations]] —— Strands、LangGraph、Claude Agent SDK、OpenAI Agents SDK 等接上各元件的方式（[原始研究](https://github.com/VagrantPi/AagentCore-Research/tree/main/90-integrations)）

**執行與狀態**
- [[AgentCore Runtime|Runtime 代管執行環境 Runtime]] —— 每個 session 一台 microVM、長時間任務、coding agent 架構、多 agent（[原始研究](https://github.com/VagrantPi/AagentCore-Research/tree/main/01-runtime)）
- [[AgentCore Memory|Memory 代管記憶 Memory]] —— 短期／長期記憶、namespace 與多租戶、memory poisoning（[原始研究](https://github.com/VagrantPi/AagentCore-Research/tree/main/02-memory)）
- [[AgentCore Built-in Tools|內建工具 Built-in Tools]] —— Code Interpreter、Browser、Web Search（[原始研究](https://github.com/VagrantPi/AagentCore-Research/tree/main/05-built-in-tools)）

**入口、身分與授權**
- [[AgentCore Gateway|Gateway 統一入口 Gateway]] —— MCP 工具、HTTP 代理、LLM 代理、Registry、當 Runtime 唯一入口（[原始研究](https://github.com/VagrantPi/AagentCore-Research/tree/main/03-gateway)）
- [[AgentCore Identity|Identity 代理身分與憑證 Identity]] —— M2M／3LO／OBO、多租戶的 token 保管（[原始研究](https://github.com/VagrantPi/AagentCore-Research/tree/main/04-identity)）
- [[AgentCore Policy|Policy 工具呼叫授權 Policy (Cedar)]] —— Cedar、時序規則（Dogwood）、Guardrails 門檻校準（[原始研究](https://github.com/VagrantPi/AagentCore-Research/tree/main/08-policy)）
- [[AgentCore Payments|Payments 代理自動付費 Payments]] —— x402／MPP、錢包與預算控管（[原始研究](https://github.com/VagrantPi/AagentCore-Research/tree/main/09-payments)）

**品質與營運**
- [[AgentCore Observability|Observability 可觀測性 Observability]] —— Session → Trace → Span、instrumentation、隱私與成本（[原始研究](https://github.com/VagrantPi/AagentCore-Research/tree/main/06-observability)）
- [[AgentCore Evaluations與Optimization|Evaluations 與 Optimization 評估與優化]] —— 評估器、LLM 評審校準、測試金字塔、A/B 與 Optimization 閉環（[原始研究](https://github.com/VagrantPi/AagentCore-Research/tree/main/07-evaluations)）

**Nova Act（瀏覽器自動化）**
- [[Nova Act 總覽與SDK|Nova Act 總覽與 SDK]] —— 定位、計費、`act()` 的 prompt 寫法、錯誤處理（[原始研究](https://github.com/VagrantPi/AagentCore-Research/tree/main/nova-act)）
- [[Nova Act 部署維運與HITL|Nova Act 部署維運與 HITL]] —— 部署、監控、真人核准與接手（[原始研究](https://github.com/VagrantPi/AagentCore-Research/tree/main/nova-act/02-deploy-operate)）
- [[Nova Act 與AgentCore整合及安全|Nova Act 與 AgentCore 整合及安全]] —— 接上 Runtime／Browser／Identity、網頁內容的 prompt injection、IAM 最小權限（[原始研究](https://github.com/VagrantPi/AagentCore-Research/tree/main/nova-act/04-agentcore)）

## ✨ 關鍵重點
- **自建的難點不在 agent loop**，而在三件事：每個 session 的強隔離（agent 會執行自己產生的程式碼）、代替每位使用者保管第三方 OAuth token、長期記憶的萃取。代管平台最值錢的正是這三塊。
- **綁定程度比想像低**：Runtime 契約是一般 HTTP container，可觀測性用 OTel，授權用開源的 Cedar，Harness 可以 export 成程式碼。**真正黏的只有 Memory**：資料帶得走，萃取與檢索的行為帶不走。
- **最關鍵的選擇是 Harness 還是 Runtime**。只有「要改 agent loop 本身」才非得用 Runtime。其他客製需求有逃生口：inline function 把工具交回呼叫端、hook、直接下 shell 指令、自訂 container。
- **成本直覺**（依原研究，2026-09 美國區牌價）：一個 session 用 1 vCPU 算 60 秒、2 GB 記憶體 5 分鐘，運算費約 0.0895×60/3600 ＋ 0.00945×2×5/60 ≈ **$0.003**。**模型 token 費才是大宗**；AgentCore 帳單裡要注意的是 Web Search（每千次 $7）、評估，以及 CloudWatch 日誌量。
- **規則要搬出 prompt**：金額、資料歸屬、地區這類「不照做就出事」的規則放 Cedar，在每次工具呼叫前確定性地判斷；語氣、風格留在 prompt。
- **閘道只有在「繞不過去」時才有用**：要驗證「同一張 JWT 直接打 Runtime 會被拒」。
- **agent 的 CI 要靠確定性的底層**：軌跡比對不花 token 又抓得到最常見的退化；LLM 評審看平均、要先校準；平台沒有「通過門檻」功能，要自己在 CI 判斷。
- **官方文件本身會出錯**：ARN 格式、區域、配額、範例程式都有前後矛盾，各頁的「⚠️ 注意」有逐條列出。寫錯格式的 IAM policy 不會報錯，只會靜默地不生效。

## 💬 原文摘錄
- 「真正的硬邊界只有一種：你需要改變 agent loop 本身的行為。」（談 Harness 的極限）
- 「分類標準只有一條：『模型不照做時，後果能不能接受？』」
- 「用同一張 JWT（或同一個 IAM 身分）直接呼叫 Runtime，必須被拒絕；經過 Gateway 則成功。這一步最容易被跳過，但它才是整套設計的目的。」

## 🔗 相關
- [[MCP 官方文件]] —— Gateway 對 agent 暴露的是標準 MCP
- [[工具-AI-Agent設計]] —— agent 本身怎麼設計；這份研究補的是「跑在哪、怎麼治理」
- [[moc/AI工程|AI 工程]]
