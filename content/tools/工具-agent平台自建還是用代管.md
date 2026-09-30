---
type: tool
name: "agent 平台：自建還是用代管"
source: "[[AgentCore 與 Nova Act 研究]]"
source_type: article
tags: [software, ai, llm, agent, architecture, aws, build-vs-buy]
triggers: [agent要上線但不知道該自己架還是用雲端服務, 擔心用了代管平台會被綁死, 開源agent框架都有了還缺什麼, 老闆問自己做agent平台要多少人力]
---

## 🎯 什麼情境該想到我
當你「agent 要從 demo 走到正式環境，得決定是在自己的 K8s 上組一套，還是買雲端的代管平台（例如 AWS Bedrock AgentCore）」的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 1. 先認清難點不在 agent loop
開源框架（LangGraph、Strands、Claude Agent SDK）已經把「模型決定下一步 → 呼叫工具 → 看結果」的迴圈寫好了。自建真正難的是三件事，也是代管平台最值錢的地方：

| 難點 | 為什麼難 |
|---|---|
| **① 每個 session 的強隔離** | agent 可能執行它自己產生的程式碼。一般 container 共用 kernel，隔離不夠；要做到「每個 session 一台 microVM（Firecracker／gVisor／Kata）、用完即清、能縮到 0」得自己寫排程器 |
| **② 代替每位使用者保管第三方 OAuth token** | 每家 SaaS 的 OAuth 細節都不同；token 要加密保存、自動刷新、撤銷，還要處理「agent 代替這位使用者行事」的授權鏈（見 [[工具-agent代使用者存取的身分設計]]） |
| **③ 長期記憶的萃取** | 什麼時候萃取、怎麼合併去重、新舊衝突怎麼辦、怎麼依使用者隔離，全部要自己設計，萃取本身還要花 token |

其餘元件（hosting、短期記憶、inbound 驗證、可觀測性）用現成方案接上就好，難度低。

### 2. 評估綁定程度：按「離開的代價」排序
以 AgentCore 為例（依原研究，查證 2026-09-30）：

| 元件 | 離開代價 | 原因 |
|---|---|---|
| 模型、Runtime、Observability、Policy | **低** | 模型不綁廠商；Runtime 契約就是一般 HTTP container（`POST /invocations`、`GET /ping`）；OTel；Cedar 是開源語言 |
| Harness（設定式 agent） | 中低 | 可 export 成 Python 程式碼，**單向** |
| Gateway、Identity | 中 | agent 端是標準 MCP／OAuth，但 proxy 設定與 token vault 要重建；vault 裡的使用者 token 能否匯出，文件沒寫（推論：使用者要重新授權） |
| **Memory** | **中高** | 原始資料可以匯出，但**萃取與檢索的行為帶不走**，換方案後 agent「記事情的方式」會變 |

★ **真正黏的只有記憶層**。很在意綁定的話，只把記憶層自建，其他用代管。

### 3. 成本的形狀（判斷，無實測數據）
- 代管平台多半按「實際用量」計費，等待 I/O 的時間不收 CPU 費用。agent 大部分時間都在等模型回應，正好吃到這個優勢；沒流量時費用趨近 0。
- 自建是「固定成本＋人力」：叢集常駐、要有人值班、要追每季都在變的標準（MCP、A2A）。
- **流量高且穩定**時自建才可能較便宜；但**人力通常才是主要差距**：光 ① 和 ② 兩項就是以「人月」計的工作量。

### 4. 決策表

| 情境 | 建議 |
|---|---|
| 資料必須留在特定地區，而平台在那裡沒有區域（例如 AgentCore 沒有台灣區） | **硬限制**：自建或找當地雲 |
| 多雲、地端是硬需求 | 自建，或只把代管用在該雲那一側 |
| 已有成熟 K8s 平台團隊，且 agent **不執行**不受信任的程式碼 | hosting 自建；只買 Identity 或程式碼沙箱 |
| 流量極高又穩定、成本優先 | 先評估平台的自帶機器方案（AgentCore Runtime Instances：用自己的 EC2，加 12% 管理費）；還不划算才自建 |
| **以上都不是** | 用代管，從最簡單的設定式 agent 開始 |

### 5. 混合策略
1. 全部代管，只有記憶層自建：降低最大的綁定點。
2. agent 跑在自己的 EKS，只買最難的：outbound OAuth、程式碼／瀏覽器沙箱、工具治理（Gateway＋Policy）。
3. 先全部代管快速上線，把「export 成程式碼」當退場路線，規模起來再逐個替換。

### 6. 設定式 vs 程式碼式：什麼時候「畢業」
代管平台常分兩層：設定式（AgentCore 叫 Harness，改設定不用重新部署，換模型與 prompt 的實驗成本趨近零）與程式碼式（Runtime，自己寫 agent loop）。**只有一種需求逼你畢業：要改變 agent loop 本身**：
- 指定其他框架、graph／workflow 式編排、複雜多 agent 路由
- 在迴圈中改寫訊息或工具輸入（Harness 的 hook 只能 allow／deny，不能改內容）
- 不同階段用不同 prompt、雙向串流（即時語音）

其他客製需求（人工核准、內網 API、固定前後處理腳本、特殊工具鏈）通常都有逃生口，先別急著畢業。**先用設定式找出模型×prompt 的組合，確定要掌控迴圈時再 export**；export 之後，prompt 實驗就回到「改程式、重新部署」的循環。

機制細節 → [[AgentCore 總覽與Harness vs Runtime]]

## 🧪 我實際套用的紀錄
- 2026-09-30：AgentCore 研究的結論。這是官方文件加上工程判斷，自建端的難度沒有實際做過。

## ⚠️ 注意 / 什麼時候不適用
- 表中「自建難度」是工程判斷，會隨團隊能力大幅變動：有現成 microVM 平台的團隊，① 就不難。
- 代管平台的預設值要逐項檢查。例如 AgentCore Harness 用 API 建立時**預設開啟代管記憶**（持續計費）、`maxTokens` **預設無上限**、內建 shell 工具每次呼叫多吃約 900 input token。
- 「按用量計費比較便宜」只對流量不穩定的工作負載成立；穩定高流量要實算。
- 平台的區域、價格、配額變動很快，決策前重新查證。

## 🔗 相關工具
- [[AgentCore 總覽與Harness vs Runtime]] —— AgentCore 各元件與兩種部署模式的完整說明
- [[工具-agent代使用者存取的身分設計]] —— 難點 ② 的設計
- [[工具-AI-Agent設計]] —— agent 本身怎麼設計；這張卡管的是「跑在哪」
