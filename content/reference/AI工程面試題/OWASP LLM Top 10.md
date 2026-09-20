---
type: reference
name: "OWASP LLM 十大風險 OWASP Top 10 for LLM Applications"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, security, owasp, risk, checklist]
triggers: [LLM應用的資安風險有哪些, OWASP的LLM清單是什麼, 哪些風險實務上真的會咬人, 模型輸出被下游當可信會怎樣, 成本失控算不算資安問題]
---

> **對應原題**（Common ‧ Safety, Security and Responsible AI）
> - Walk me through the **OWASP Top 10 for LLM applications** and **which ones actually bite in practice**.
>
> **清單查證於 2026-09-20**，來源 <https://genai.owasp.org/llm-top-10/>（**2025 版**）。
> 該專案另有 2023/24 版仍在線上——**面試時先確認對方問的是哪一版**。

## 🎯 什麼情境該想到我
當你「**要對 LLM 應用做一次系統性的資安盤點**」的時候。
★ 題目的後半「**哪些真的會咬人**」才是重點——背完十條但沒有輕重判斷，是不及格的答案。

## ⚙️ 2025 版清單

| 編號 | 名稱 | 一句話 |
|---|---|---|
| **LLM01** | **Prompt Injection** | 使用者或資料中的內容改變了模型的行為 |
| **LLM02** | **Sensitive Information Disclosure** | 模型或應用洩漏了敏感資訊 |
| **LLM03** | **Supply Chain** | 模型、資料集、套件、adapter 的供應鏈風險 |
| **LLM04** | **Data and Model Poisoning** | 預訓練／微調／embedding 資料被下毒 |
| **LLM05** | **Improper Output Handling** | 模型輸出未經驗證就交給下游系統 |
| **LLM06** | **Excessive Agency** | 系統被賦予過大的權限、自主性或功能 |
| **LLM07** | **System Prompt Leakage** | system prompt 的內容被洩漏 |
| **LLM08** | **Vector and Embedding Weaknesses** | 向量與嵌入層的弱點（RAG 特有） |
| **LLM09** | **Misinformation** | 模型產出錯誤資訊而被信賴 |
| **LLM10** | **Unbounded Consumption** | 資源消耗無上限（成本、算力、額度） |

**相對 2023/24 版的變化值得知道**：新增了 **System Prompt Leakage** 與 **Vector and Embedding Weaknesses**（反映 RAG 的普及）；**Misinformation** 取代了原本的 Overreliance；**Unbounded Consumption** 從原本的 Model DoS 擴大——**從「服務被打掛」擴大到「帳單被打爆」**。

## ★ 哪些真的會咬人（題目的重點）

### 🔴 高頻且高衝擊

| 風險 | 為什麼常見 | 對策 |
|---|---|---|
| **LLM01 Prompt Injection** | ★ **無法根本解決**，而且 agent 化之後間接注入的威脅急遽上升 | 見 [[提示注入與分層防禦]] |
| **LLM06 Excessive Agency** | ★ **它是所有其他風險的放大器**。注入成功之後，後果的嚴重度完全取決於 agent 能做什麼 | 最小權限、動作分級、人類把關（見 [[可逆性、審計與人類把關]]） |
| **★ LLM05 Improper Output Handling** | ★ **最被低估的一條** | 見下方專節 |
| **LLM10 Unbounded Consumption** | ★ **實務上「事故」發生頻率最高的一條**——一個迴圈沒設上限就燒掉一個月預算 | 步數/token/金額三層預算（見 [[ReAct 與 Agent Loop]]）、速率限制、per-tenant 額度 |
| **LLM02 Sensitive Information Disclosure** | 洩漏管道比想像多：**日誌、trace、跨租戶快取、向量庫、錯誤訊息** | 見 [[PII、紅隊與公平性稽核]]、[[權限感知檢索與引用歸因]] |

### 🟠 RAG 系統特有

**LLM08 Vector and Embedding Weaknesses** —— RAG 普及後才浮上來的一整面：
- **向量可被反演**出近似原文 → **向量庫是機密資料，不是「匿名化的數字」**
- **跨租戶檢索洩漏**（過濾沒做對，見 [[向量索引 ANN]] 的 filtered search）
- **知識庫投毒** —— 任何人能寫入的來源（wiki、工單、客戶上傳）都是注入載體
- **embedding 服務是外部依賴** —— 你的文件被送去哪裡

### 🟡 重要但不常直接咬到應用開發者

| 風險 | 說明 |
|---|---|
| **LLM04 Data and Model Poisoning** | **大多數應用團隊不訓練模型**，所以這條主要是模型提供者的責任。但**你做微調就要負這個責任**（見 [[災難性遺忘]]：微調會削弱安全對齊） |
| **LLM03 Supply Chain** | 重要，但和一般軟體供應鏈風險高度重疊。**LLM 特有的部分是：模型權重來源、LoRA adapter、資料集、以及 MCP server** |
| **LLM09 Misinformation** | ★ **它其實是品質問題不是資安問題**。用評估解決（見 [[幻覺偵測]]），不是用資安控制解決。放在資安清單裡是因為後果嚴重 |

### ★ 對 LLM07 System Prompt Leakage 的看法

> **真正的問題不是「system prompt 被看到」，而是「你把不該放的東西放進去了」。**
>
> System prompt **一定會被洩漏**——夠努力的人總能撬出來。所以正確的防禦不是「防止洩漏」，而是：
> - **不要在裡面放密鑰、內部 URL、資料庫 schema、未公開的商業規則**
> - **不要把它當成存取控制**（「只有 VIP 才能用這個功能」不能只寫在 prompt 裡）
> - 把它當成「會被公開的文件」來寫
>
> 面試時講這個觀點比講「怎麼防洩漏」更有價值。

## ★ 專節：LLM05 Improper Output Handling（最被低估）

**模型的輸出是不可信輸入。** 但大量系統把它直接交給下游：

| 下游 | 後果 |
|---|---|
| 渲染成 HTML | **XSS** |
| 拼進 SQL | **SQL injection** |
| 丟進 shell | **命令執行** |
| 當成檔案路徑 | **路徑穿越** |
| **自動載入模型產生的 URL** | ★ **資料外洩**（見 [[提示注入與分層防禦]]） |
| 直接 `eval` | RCE |

> ★ **這是「傳統資安漏洞透過 LLM 復活」的一整類。**
> 而且它特別危險，因為**攻擊鏈是 LLM01 → LLM05**：
> 注入讓模型輸出惡意字串，輸出處理不當讓它變成真的攻擊。
>
> **規則：模型輸出要套用和使用者輸入一模一樣的驗證與編碼紀律。**

## 使用建議

| 用法 | 說明 |
|---|---|
| **當檢查清單，不當設計方法** | 它是盤點工具，不會告訴你怎麼設計架構 |
| **★ 依你的架構加權** | 純問答系統和有工具權限的 agent，風險排序完全不同 |
| **配合威脅建模** | 先畫出資料流與信任邊界，再對照清單逐項檢查 |
| **agent 系統另外看** | OWASP 另有 **Agentic Security** 的專門工作項目——agent 的風險面超出這 10 條 |

## ⚠️ 注意 / 什麼時候不適用

- **清單會改版**。本頁查證於 2026-09-20 的 2025 版；引用前先確認最新版與對方問的版本。
- **排名不是你的排名**。OWASP 的順序反映社群整體觀察，**你的系統的風險排序要自己做威脅建模得出**。
- **「合規」不等於「安全」**。逐條打勾不代表擋得住針對性攻擊。
- **它涵蓋不到的**：模型能力本身的風險（危險知識、說服力）、多模態特有的攻擊面、長期的記憶污染。
- **別用它嚇唬人**。工程上要能區分「理論上可能」與「實際上會被利用」，否則會把資源花在錯的地方。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開，清單已對官方站查證。

## 🔗 相關
- [[提示注入與分層防禦]] —— LLM01 與 LLM05 的攻擊鏈
- [[Guardrails 護欄設計]] —— 輸入輸出的過濾層
- [[可逆性、審計與人類把關]] —— LLM06 Excessive Agency 的對策
- [[PII、紅隊與公平性稽核]] —— LLM02 的處理
- [[權限感知檢索與引用歸因]]、[[向量索引 ANN]] —— LLM08
- [[幻覺偵測]] —— LLM09 其實該用評估解
- [[ReAct 與 Agent Loop]] —— LLM10 的三層預算
- [[工具-LLM安全防護]]、[[工具-MCP安全防護要點]] —— 決策層
