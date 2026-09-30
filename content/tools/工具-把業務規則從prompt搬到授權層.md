---
type: tool
name: "把業務規則從 prompt 搬到授權層"
source: "[[AgentCore 與 Nova Act 研究]]"
source_type: article
tags: [software, ai, llm, agent, security, authorization, cedar]
triggers: [在system prompt寫了規則但模型不一定照做, agent可能退錯款或看到別人的資料, 哪些規則該寫在prompt哪些該硬擋, 工具參數要怎麼設計才好做權限檢查]
---

## 🎯 什麼情境該想到我
當你「把『退款不能超過 500 美元』『只能處理本人訂單』這類規則寫在 system prompt，卻沒辦法保證模型每次都照做」的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 為什麼不能只靠 prompt

| 做法 | 問題 |
|---|---|
| 寫在 system prompt | 模型是機率性的，**不保證遵守**；惡意輸入能誘導它違反 |
| 每個工具的後端各自檢查 | 規則散在各服務，難以一致、難以稽核；後端也不一定知道「哪個使用者透過哪個 agent」在呼叫 |
| **在工具呼叫的必經之路上做確定性授權** | 單一檢查點、宣告式、可驗證、可版本控管，**跟模型行為完全無關** |

類比：**IAM policy 之於 AWS API，就是授權層之於 agent 的工具呼叫**。AgentCore 的實作是 Gateway＋Cedar；自建可以在工具 proxy 前放 OPA 或 Cedar 開源引擎。

### 第 1 步：逐句分類 prompt 裡的規則
**判準只有一條：模型不照做時，後果能不能接受？**

| prompt 裡的句子 | 不照做的後果 | 放哪裡 |
|---|---|---|
| 單筆退款不能超過 500 美元，主管可到 5,000 | 直接損失金錢 | **授權層**（數值比較＋角色） |
| 只能處理使用者本人的訂單 | 越權存取 | **授權層**（`customerId` 比對呼叫者） |
| 只服務美國和加拿大 | 違反法規或合約 | **授權層** |
| 退款一定要記錄原因 | 稽核缺漏 | 授權層，或直接把 schema 欄位設成必填 |
| 退款前先查訂單狀態 | 重複退款 | 需要「看歷史」的時序規則（AgentCore 叫 temporal policy） |
| 回覆裡不要透露其他客戶資料 | 個資外洩 | **根本做法是工具就不回傳別人的資料**；輸出過濾只是補強 |
| 回答要禮貌、用繁體中文 | 體驗不佳 | **留在 prompt** |

★ 搬過去之後，**prompt 裡的規則照樣保留**：prompt 讓模型「一開始就不會去做」，減少被擋後的亂重試；授權層保證「真的做了也會被擋」。沒寫在 prompt 的話，模型被拒後可能一直換參數重試。

### 第 2 步：確認規則「看得到」需要的欄位
授權層**只看得到工具呼叫的參數與呼叫者身分**，看不到對話內容，也不會自己去查資料庫。所以很多規則搬不過去，**問題不在 policy 語言，而在工具設計**。為 policy 設計工具 schema：
1. **金額用整數的「分」**（`amountCents: integer`），不要用浮點數：Cedar 的 decimal 會截到小數點後 4 位，時序加總也只能加整數。
2. **資料歸屬要是明確欄位**（`customerId`），才能比對「這是不是呼叫者的」。後端 API 自己最好也再驗一次。
3. **會被 policy 引用的欄位設成必填**，不然每條規則都得先寫 `has` 檢查，漏寫就出事。
4. 避開 `anyOf`／`oneOf`、自由格式物件；被引用的欄位先別用 `enum`（開源 schema 轉換器會把它轉成列舉 entity，不是字串）。
5. **一個工具只做一件事**：`manage_order(action: refund|cancel|query)` 拆成三個工具，規則才能直接用工具名區分。
6. 「角色」「負責哪些客戶」要嘛放進 JWT claim，要嘛放進工具參數。

### 第 3 步：寫成 policy
```cedar
// 一般使用者：上限 500 美元、只限美加、一定要有原因
permit (principal is AgentCore::OAuthUser,
        action == AgentCore::Action::"OrderTarget___process_refund",
        resource == AgentCore::Gateway::"<gateway ARN>")
when { context.input.amountCents <= 50000 &&
       ["US", "CA"].contains(context.input.country) &&
       context.input has reason };

// 只能退自己的訂單，主管例外；forbid 永遠優先
forbid (principal is AgentCore::OAuthUser,
        action == AgentCore::Action::"OrderTarget___process_refund",
        resource == AgentCore::Gateway::"<gateway ARN>")
when   { context.input.customerId != principal.id }
unless { principal.hasTag("role") && principal.getTag("role") == "supervisor" };
```
- **「允許什麼」用 `permit`，「絕對不行」用 `forbid`**。Cedar 預設拒絕，`forbid` 永遠優先，之後有人加了過寬的 `permit` 也繞不過它。
- 讀 tag 前先 `hasTag`、讀非必填欄位前先 `has`；**每個工具都要有 `permit`**，漏寫的會全被擋。

### 第 4 步：本機先驗證，別等部署
- 雲端建立 policy 的驗證常是**非同步**的，而且有些錯（引用了請求沒帶的欄位）建立時不報錯，**到執行時才一律拒絕**。
- 用開源 Cedar（例如 Python 的 `cedarpy`）加一份近似的 schema，在 CI 裡跑兩件事：schema 驗證、授權案例測試（「誰、帶什麼參數、預期允許或拒絕」）。原研究的實驗 10 個案例全過，而且本機 validator 直接抓到「沒先 `has` 就讀非必填欄位」的錯。
- 上線順序：本機測試 → 部署 → **只記錄不攔截（LOG_ONLY）** 對照正式流量 → 切到強制執行。

機制細節 → [[AgentCore Policy]]

## 🧪 我實際套用的紀錄
- 2026-09-30：原研究的本機實驗（`cedarpy` 4.12.1）。正確的 policy 驗證通過；故意寫錯的那份被 validator 擋下（`unable to guarantee safety of access to optional attribute`）；10 個授權案例全數符合預期。

## ⚠️ 注意 / 什麼時候不適用
- **本機 schema 是手寫近似版**，跟平台從工具 schema 自動產生的可能有差（`enum`、巢狀物件）。CI 測邏輯，上線前還是要用只記錄模式對照。
- **policy 看不到對話內容**：「不要透露某資訊」這類輸出規則，授權層只能部分處理，根本解法在工具的回傳設計。
- **誰能關掉 policy 也要算進攻擊面**：AgentCore 裡有 `UpdatePolicy` 權限的人能把單條 policy 改成只記錄不攔截。
- AgentCore 的 policy **沒有版本管理**（`UpdatePolicy` 直接覆蓋），版本要靠自己的 Git。
- 風格、語氣、行為引導類規則留在 prompt，硬擋只會讓體驗變差。

## 🔗 相關工具
- [[AgentCore Policy]] —— Cedar／時序規則／Guardrails 的完整機制與配額
- [[可逆性、審計與人類把關]] —— 高風險動作的分級：授權層擋「不該做的」，把關流程處理「要人確認的」
- [[工具集設計]] —— 工具 schema 設計的通用規則，這張卡補上「為授權而設計」的角度
- [[提示注入與分層防禦]] —— prompt 會被注入攻破，正是要把規則搬出 prompt 的原因
