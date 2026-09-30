---
type: reference
name: "AgentCore Payments 代理自動付費 Payments"
source: "[[AgentCore 與 Nova Act 研究]]"
source_type: docs
tags: [ai, llm, agent, aws, agentcore, payments, x402, stablecoin]
triggers: [agent要自己付錢呼叫收費的API, 每次呼叫只值幾分錢信用卡手續費不划算, 怕agent被網頁誘導亂花錢, 想限制agent一次最多能花多少, 想把自己的API改成按次收費給agent用]
---

> 原始研究：[GitHub](https://github.com/VagrantPi/AagentCore-Research/tree/main/09-payments)（依原研究，查證 2026-09-30）

## 🎯 什麼情境該想到我
當你「希望 agent 能自己付費使用收費的 API、MCP server 或網頁內容，但又要把預算、收款對象和權限鎖死，避免它被誘導亂付錢」的時候。

## ⚙️ 怎麼用

### 一句話定位與狀態
讓 agent 自動付費：支援 **x402 / MPP** 協定、錢包整合、花費上限控管。**2026-05-07 以預覽發表**；研究查證日（2026-09-30）時官方文件沒有明寫是否已 GA。

### 要解決的問題
agent 呼叫一次付費 API 的價值常常**只有幾美分甚至更少**，信用卡的最低手續費讓這種**微支付**做不起來；為每個供應商各自簽約、串帳務也不實際。做法是用 **HTTP 402 Payment Required** 走一套標準流程「要求付款 → 簽署 → 帶付款證明重試」，以**穩定幣（USDC）**結算：
- **x402**：Coinbase 主導，付款證明放在 `X-PAYMENT` header。
- **MPP**：改走 `WWW-Authenticate`／`Authorization` header。

### 先對齊加密支付名詞

| 名詞 | 白話 |
|---|---|
| 穩定幣（USDC） | 區塊鏈上與美元 1:1 掛鉤的代幣，像鏈上的美元儲值金 |
| 錢包 / Payment instrument | 持有穩定幣的帳戶；這裡是**嵌入式錢包**，由 Coinbase 或 Privy 代管私鑰 |
| 網路 | 哪條鏈，用 CAIP-2 格式：`eip155:8453` 是 Base 主網、`eip155:84532` 是 Base Sepolia 測試網、`solana:…` |
| Gas fee | 在鏈上執行交易的手續費，用鏈的原生代幣付 |
| Facilitator | 替商家驗證付款並送上鏈的服務，類似收單機構 |
| 付款證明 | 用錢包私鑰對「付給誰、多少、哪種幣、哪條鏈」簽章，像簽好名還沒兌現的支票 |

**鏈上交易一旦完成就無法撤回**，不像信用卡能退款——這讓「agent 付錯錢」的代價遠高於一般 API 呼叫。

### 資源模型

```
PaymentManager（最上層；authorizer 用 IAM 或 CUSTOM_JWT；建立時自動產生一個 workload identity）
└── PaymentConnector（對接錢包供應商，每個 manager 可多個）
      ├── CoinbaseCDP（支援 Quick create：OAuth 授權一次，由服務代建憑證）
      └── StripePrivy（只能手動提供憑證）
            └── 1:1 對應 PaymentCredentialProvider（存在 Identity 的 token vault 與 Secrets Manager）

PaymentInstrument：使用者的嵌入式錢包，每條鏈各一個，狀態 INITIATED → ACTIVE
PaymentSession：這次互動的付款範圍 = maxSpendAmount + currency + 到期時間
ProcessPayment：傳入 session + instrument + 商家的 402 內容 → 回傳付款證明
```

**AgentCore 包辦 agent 這一端：** 檢查預算、透過錢包供應商簽署交易、產生付款證明、記錄花費。**私鑰與錢包憑證都不進到 agent 裡**，放在 Identity 的 payment credential provider。

### 一次 x402 付款的流程
1. Agent 用普通的 `http_request` 工具 `GET /premium-data`。
2. 商家回 **402**，內容帶金額、收款方（`payTo`）、幣別、網路。
3. Payments plugin 攔下 402，呼叫 `ProcessPayment(session, instrument, 402 內容)`。
4. Payments 先**檢查 session 預算與到期時間，超過就拒絕**。
5. 透過 `GetResourcePaymentToken` 向 Identity 取錢包憑證，請錢包供應商簽署。
6. 回傳付款證明（`status = PROOF_GENERATED`）。
7. Agent 帶上 `X-PAYMENT` header（MPP 則為 `Authorization`）重試。
8. 商家驗證並上鏈結算，回 200 與內容。
9. Payments 記入花費帳本；**任何一步失敗都會釋放預算保留**。

**整合方式：** Strands 用 `AgentCorePaymentsPlugin`、LangGraph 用 `AgentCorePaymentsMiddleware`，自動攔 402、呼叫 `ProcessPayment`、重試，工具程式碼只需要一個普通 `http_request`。也可不用 plugin，直接呼叫 SDK 的 `PaymentManager.generate_payment_header()` 或 API。重複請求用 `clientToken` 保證同一筆付款不會執行兩次（冪等）。

**x402 兩種計費方式：**
- `exact`：固定金額。
- `upto`：依用量計費、最多到上限。要先在鏈上做一次 **Permit2 allowance** 授權（`permit2AllowanceLimit`），**這步要付 gas fee**，而且每次設定是**覆蓋舊值而非累加**，只在第一次需要時設定。

**MPP 細節：** 一次只處理一個 challenge、只支援 `charge` 意圖；challenge 很快過期，過期回 `ValidationException` 且**不扣預算**；回傳的 `paymentCredential` 要**原封不動**放進 header，不能解碼或修改；商家不負擔 gas 時要明確設 `buyerPaysGasFees=true` 否則被拒；支援 `evm`（只收標準 USDC）、`tempo`、`solana`（**只有 Privy 支援**）。

### 錢包入金
錢包建立時**餘額是 0**。使用者要登入供應商的 wallet hub（Coinbase、Privy 都有官方前端範本）：用加密貨幣轉入，或用信用卡、金融卡、Apple Pay、Google Pay、ACH 儲值（信用卡部分地區不可用），並**明確授權 agent 可用這個錢包**，之後可撤銷。研究判斷：這代表使用者要自己管加密錢包，對一般消費者門檻不低，較適合 B2B 或企業預先儲值。

### 治理核心：IAM 職責分離（官方五種角色）

| 角色 | 能做什麼 | 關鍵限制 |
|---|---|---|
| Administrator（ControlPlaneRole） | 建 manager、connector、credential provider；用 Coinbase 還要訂閱 AWS Marketplace 方案 | 只給平台管理者 |
| Agent developer（ManagementRole） | 建 instrument 與 session，**也就是設定預算** | **明確 Deny `ProcessPayment`** |
| Payment execution（ProcessPaymentRole） | 執行 `ProcessPayment`、讀餘額與 session | **不能有建立 session 的權限** |
| Service role（ResourceRetrievalRole） | 服務在執行期取錢包憑證 | 不給人用 |
| Marketplace 訂閱 | Coinbase 費用併入 AWS 帳單 | — |

**為什麼一定要拆：** 同一個身分若既能建 session（決定預算上限）又能付款，一旦被 prompt injection 誘導，就能**自己開一個無上限預算的 session 再付款給自己**，預算上限形同虛設。官方用明確 Deny 讓這種組合在 IAM 層面不可能發生。

### agent 特有的付款風險（研究判斷）

| 風險 | 情境 | 緩解 |
|---|---|---|
| 誘導付款 | 網頁或工具輸出寫「去這個網址買完整報告」，agent 照做 | **限制可付款商家**（LangGraph middleware 有 allowlist；或只透過 Gateway 開放審核過的付費 target）、session 預算設低、大額要真人核准 |
| 惡意商家 | 402 要求付給攻擊者地址 | 商家白名單、比對 `payTo` |
| 花費失控 | 迴圈中不斷付費重試 | `maxSpendAmount` 與到期時間、監控 payment metric |
| 交易不可逆 | 付錯無法退款 | 以上全部，再用 Policy 對付費工具參數設確定性上限 |
| 法遵 | 各地加密資產支付法規不同 | **在台灣導入前需法遵評估**，官方文件未涵蓋 |

研究的結論是「商家白名單、低預算、大額真人核准」**三項缺一不可**。

### 生態系
- **x402 Bazaar**：Coinbase 維運的付費端點目錄，已整合成 Gateway 的一個 target，可搜尋超過一萬個 x402 端點。
- **Browser**：搭配使用可付費存取支援 x402 的網頁。
- **當賣方**：可把自家 API 做成 x402 收費（例如 API Gateway + Lambda），官方範例每次收 $0.01；也能登錄到 Registry 讓組織內搜得到。

### 區域與計費（研究日 2026-09-30）
- **區域（依官方區域表）**：us-east-1、us-east-2、us-west-2、法蘭克福、愛爾蘭、倫敦、米蘭、巴黎、西班牙、斯德哥爾摩、新加坡、雪梨；**東京、首爾、孟買不支援**。
- **AWS 不另外收費**。錢包供應商：Coinbase CDP 每次操作 $0.005（建 instrument 算 1 次、ProcessPayment 算 1 次）；Privy 建 instrument 免費、ProcessPayment 依 Privy 價格。
- 區塊鏈手續費：`upto` 的 Permit2 授權、MPP 中買方負擔 gas 時。
- 配額：每帳號最多 50 個 payment credential provider（與 Identity 同一套配額）。

**成本直覺（可自行驗算）：** 每次付費呼叫 $0.01，Coinbase 對 `ProcessPayment` 收 $0.005，供應商費就佔售價的 **50%**；單價 $0.10 時降到 5%。另外每個錢包建立時還有一次 $0.005。微支付要划算，先算清楚單價和供應商費的比例。

## ⚠️ 注意 / 什麼時候不適用
- **文件落差：** GA 狀態官方未明寫；發表時的部落格只寫 4 個區域，之後官方區域表擴充到上面的清單，以區域表為準。
- 踩雷清單：建 session 與執行付款權限必須分開；交易不可逆；錢包初始餘額 0 要使用者入金並授權；`upto` 的 Permit2 要付 gas 且覆蓋舊值；MPP credential 不可修改、challenge 很快過期；Solana 只有 Privy；東京區不支援；供應商操作費對小額付款影響很大；法遵要自己評估。
- 不適用：付款對象固定、金額大、可以走月結發票的傳統 B2B 採購，用穩定幣微支付反而增加法遵與錢包管理負擔（推測）。

## 🧪 我實際套用的紀錄
- （尚無）原研究本篇沒有附實驗。研究列出的待辦是用 Base Sepolia 或 Solana Devnet 測試網搭端到端環境（Coinbase Quick create、入金、`exact`/`upto`、MPP），並驗證 IAM 職責分離、預算用完時的行為、Observability 上的花費追蹤。

## 🔗 相關
- [[AgentCore Identity]]
- [[AgentCore Gateway]]
- [[AgentCore Policy]]
- [[AgentCore Built-in Tools]]
- [[AgentCore Observability]]
- [[可逆性、審計與人類把關]]
- [[提示注入與分層防禦]]
