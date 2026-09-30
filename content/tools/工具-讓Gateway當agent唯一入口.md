---
type: tool
name: "讓 Gateway 當 agent 的唯一入口"
source: "[[AgentCore 與 Nova Act 研究]]"
source_type: article
tags: [software, ai, agent, security, api-gateway, architecture, aws]
triggers: [agent前面加了閘道但使用者還是能直接打到後面, 限流授權稽核該放在agent的哪一層, 怕有人繞過檢查直接呼叫agent, 閘道後面的服務怎麼知道是哪個使用者]
---

## 🎯 什麼情境該想到我
當你「在 agent 前面放了閘道做驗證、限流、授權規則，卻不確定有沒有人能繞過它直接呼叫後面的 agent」的時候。

## ⚙️ 怎麼用（步驟 / 公式）

**核心**：閘道上的所有控制（授權規則、限流、攔截器、guardrail）**只對經過閘道的流量有效**。只要使用者能直接呼叫 agent 執行環境，這些控制全部可以繞過。所以「加閘道」只做了一半，另一半是**鎖死後門**。

### 1. 架構
```
使用者／前端
   │ JWT（inbound 驗證：audience、scope）
   ▼
Gateway ─ 限流（以使用者 sub 為維度）→ 攔截器 → 授權規則 → 路由
   │ outbound：閘道自己的 service role（或 OAuth）
   ▼
Agent Runtime（只接受這個閘道的請求）
```
以 AgentCore 為例：把 Runtime 用 HTTP target 接到 Gateway 後面。**這種 target 只能加到沒設定 protocol type 的 gateway**，MCP 型的不行，所以要規劃兩個 gateway，或一開始就不設。原本呼叫 Runtime 的 client 只要換 endpoint。

### 2. 鎖住後門：依執行環境的驗證方式
- **IAM 型**：resource-based policy 只 Allow 閘道的 execution role，**再加一條明確的 Deny 給其他所有 principal**。只寫 Allow 的話，帳號內其他有呼叫權限的角色照樣能直接打。閘道 role 的 trust policy 也要用 `aws:SourceArn` 鎖住：**能 assume 這個 role 的人就能直接呼叫**。
- **JWT 型**：在執行環境的 JWT 驗證加上「只接受身分鏈裡有指定閘道的請求」（AgentCore 的 `allowedWorkloadConfiguration`）。這樣使用者拿**同一張有效的 JWT** 直接打，也會被拒。
  - 陷阱：AgentCore CLI 不會設這個欄位；`UpdateAgentRuntime` 會**整個取代**設定，要「讀出 → 合併 → 寫回」，否則其他設定被清掉。
- **網路層**（PrivateLink、VPC endpoint policy）只是補充，同一個 VPC 裡的其他服務仍能繞過；主要防線是上面的身分層。

### 3. 各種控制放哪一層

| 控制 | 放哪 | 不該拿來做 |
|---|---|---|
| inbound 驗證 | 閘道 | — |
| 授權規則（見 [[工具-把業務規則從prompt搬到授權層]]） | 閘道 | — |
| 攔截器（Lambda） | 閘道：格式轉換、補 header、遮罩 | 當主要授權機制 |
| 限流 | 閘道：流量管理、防單一使用者用光額度 | **安全控制**（它是 fail-open 的） |
| 路由、canary、A/B | 閘道 | — |
| **payload 驗證** | **執行環境** | — |

### 4. 使用者身分怎麼傳到後面
outbound 用閘道自己的 service role 時，後面看到的是閘道的身分。需要使用者身分，就用 REQUEST 攔截器把 JWT 的 `sub` 放進 header，並加進執行環境的 header allowlist。**這個 header 可信的前提是「只有閘道能呼叫」**，所以第 2 步不能省（推論：官方沒有這個情境的完整範例）。要真正代表使用者呼叫下游，改用 OBO（見 [[工具-agent代使用者存取的身分設計]]）。

### 5. 限流的兩個坑
- 維度用 `$.context.jwt.sub` 做到每位使用者每分鐘 N 次；**維度建立後不能改**。
- **fail-open**：JWT 缺少當維度的 claim 時，**整條限制被略過**。要搭配 inbound 驗證的「必須有某 claim」條件。

### 6. 部署檢查清單
1. 建沒設 protocol type 的 gateway；inbound 用 JWT 驗 audience 與 scope。
2. 加執行環境的 target，outbound 用 service role。
3. 鎖後門：IAM 型用 Allow＋Deny 並鎖 trust policy；JWT 型用身分鏈白名單（讀、合併、寫回）。
4. 設限流並確保維度 claim 一定存在。
5. ★ **驗證繞不過去**：用同一張 JWT（或同一個 IAM 身分）**直接呼叫執行環境必須被拒**，經過閘道則成功。這步最常被跳過，卻是整套設計的目的。
6. client 換成閘道的 URL。

機制細節 → [[AgentCore Gateway]]

## 🧪 我實際套用的紀錄
- 2026-09-30：原研究依官方文件與範例推導，**沒有實際部署驗證**。

## ⚠️ 注意 / 什麼時候不適用
- **官方的「快速導入」組合，inbound 都不做授權**（IAM 的 `AUTHENTICATE_ONLY`＋呼叫者 IAM；JWT 的 `NONE`＋token 直通）。它們只是把流量先導進閘道，**只適合過渡期**。
- token 直通（passthrough）官方不建議用於正式環境；要代表使用者就走 OBO。AgentCore 文件寫 Runtime target 不支援 OBO，但官方範例用了，要實測。
- AgentCore 的攔截器**不支援串流**：SSE 回應不能用 RESPONSE 攔截器加工；Lambda 可能被重試，要做成冪等；同步呼叫有 6 MB 上限。
- 限流排在路由規則之前評估；攔截器與授權規則誰先，文件沒寫。
- 內部服務之間的呼叫全程用 IAM 最簡單，不一定需要這整套。

## 🔗 相關工具
- [[AgentCore Gateway]] —— target 類型、工具語意搜尋、LLM 代理等完整機制
- [[工具-agent代使用者存取的身分設計]] —— 閘道之後要代表使用者呼叫下游時
- [[工具-把業務規則從prompt搬到授權層]] —— 閘道上該放的授權規則怎麼寫
- [[工具-限流器設計]] —— 限流演算法本身；這張卡只管它放在哪、怎麼避免 fail-open
