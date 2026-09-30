---
type: reference
name: "AgentCore 內建工具 Built-in Tools"
source: "[[AgentCore 與 Nova Act 研究]]"
source_type: docs
tags: [ai, llm, agent, aws, agentcore, sandbox, browser, web-search, code-interpreter]
triggers: [想讓 agent 執行它自己寫出來的程式又怕出事, agent 要去操作需要登入的網站或沒有 API 的內部系統, 模型算數不準想讓它寫程式來算, agent 要查最新資訊還得附上出處, 瀏覽器自動化遇到原生對話框或檔案上傳點不到]
---

> 原始研究：[GitHub](https://github.com/VagrantPi/AagentCore-Research/tree/main/05-built-in-tools)（依原研究，查證 2026-09-30）

## 🎯 什麼情境該想到我
當你「要讓 agent 執行程式、操作瀏覽器或搜尋網路，但不想自己建沙箱、瀏覽器叢集或搜尋基礎設施」的時候。

## ⚙️ 怎麼用

### 為什麼需要這三個工具
- LLM **不擅長精確計算** → **Code Interpreter**：讓模型寫程式去算。
- LLM **看不到登入後的網頁、也不會點按鈕** → **Browser**。
- LLM **知識停在訓練時間點** → **Web Search**。

背景名詞：
- **Tool use / function calling**：模型只輸出「我想呼叫 X、參數是 Y」，由 agent 程式代為執行，再把結果餵回去。
- **Computer use**：模型看螢幕截圖，輸出「點座標 (x, y)」「輸入某段文字」這類操作，對應 Browser 的 `InvokeBrowser`。
- **Grounding**：讓回答有外部資料佐證並附出處，降低 hallucination。

Code Interpreter 與 Browser 都是 **「每個 session 一台 microVM」的沙箱**：session 預設 15 分鐘、最長 8 小時。可用 AWS 預建版（`aws.codeinterpreter.v1`／`aws.browser.v1`），或自建以自訂網路、execution role、錄影等。

### Code Interpreter

結構：Code Interpreter 資源 → Session（一台 microVM，可同時開多個）→ `executeCode`（Python／JavaScript／TypeScript，**session 內狀態會保留**）、`executeCommand`（shell）、檔案寫入／讀取／列出／刪除。

| 項目 | 內容（研究當時） |
|---|---|
| 語言 | Python、JS、TS；預裝 Node 套件很少（axios、lodash、zod 等） |
| 預裝 Python 套件 | 資料分析（pandas、polars、numpy、duckdb、pyarrow）、畫圖（matplotlib、plotly）、ML（scikit-learn、torch、xgboost、spacy）、最佳化（ortools、cvxpy、z3）、文件（openpyxl、python-docx、pdfplumber、python-pptx、markitdown）、影音（opencv、moviepy、ffmpeg），及 boto3、SQLAlchemy、psycopg2 |
| 檔案 | 直接上傳上限 100 MB，經 S3 最大 5 GB |
| 網路模式 | **Sandbox**（官方稱「有限的對外連線」）、**Public**（可上網）、**VPC**（連你 VPC 內資源，上網要走 NAT） |
| Execution role | 沙箱內程式用這個 role 存取 AWS（如 `aws s3 cp` 讀大檔）。**它的權限＝模型寫出來的任何程式都能用的權限** |
| 硬體與配額 | 每 session 2 vCPU / 8 GB、10 GB 磁碟；同步請求 15 分鐘、非同步最長 8 小時；每帳號同時 1,000 session |
| 計費 | 依實際用量（與 Runtime v1 同價），等 I/O 的時間不收 CPU 費 |

**怎麼接**：Harness 裡設一個 `agentcore_code_interpreter` 工具；Runtime 裡用 SDK 的 `code_session` context manager（確保用完關閉）或直接呼叫 API。

**跟 Runtime 的 `InvokeAgentRuntimeCommand` 差在哪**：Command 在 **agent 自己的 microVM** 裡跑，共用檔案系統與憑證；Code Interpreter 是**另一台獨立沙箱**，專門跑**模型產生、不受信任的程式碼**，可設不同網路限制與權限。
**原研究判斷**：模型寫的程式一律丟 Code Interpreter；你自己寫、內容確定的腳本才用 Command。

### Browser

**兩種控制方式**

| 方式 | 協定 | 能做什麼 | 常用工具 |
|---|---|---|---|
| **Automation stream** | WebSocket 上的 **CDP**（Chrome DevTools Protocol） | 瀏覽、操作 DOM、填表單、截網頁畫面、擷取內容 | Playwright、browser-use、Nova Act、Strands |
| **OS action**（`InvokeBrowser`） | REST | 滑鼠點擊／拖曳／捲動、鍵盤輸入、快捷鍵、**整個桌面截圖** | computer use 類模型 |

`InvokeBrowser` 專門處理 CDP 碰不到的東西：列印對話框、檔案上傳下載對話框、JS alert、右鍵選單、跨視窗拖放。
⚠️ `keyType` **只支援 ASCII，中文字會被直接略過**；未知按鍵名稱會**回 SUCCESS 但什麼都沒做**。

**功能一覽**

| 功能 | 說明 | 注意 |
|---|---|---|
| **Live View** | 真人即時看 agent 在做什麼，也可**直接接手**（例如輸入 OTP） | 每 session 只能 1 條 live view |
| **錄影與重播** | 錄 DOM 變化、操作、console、網路事件到**你的 S3**，可在 Console 重播 | **只有自建 browser 能開** |
| **Profile** | 保存 cookie 與 localStorage，下次免重新登入 | **Profile＝登入憑證**，要用 IAM 嚴格限制；存檔**整個覆蓋**；每個上限 50 MB、每帳號 100 個；自 2026-04-15 起依 S3 價格計費 |
| **Proxy** | 每 session 最多 5 個外部 proxy，可依網域分流 | — |
| **Extensions** | 載入 Chrome 擴充，每 session 最多 10 個 | — |
| **Web Bot Auth**（預覽） | 用 IETF 草案的 HTTP Message Signatures **簽署每個請求**，讓 Cloudflare、Akamai、HUMAN、DataDome、F5 等**辨識出這是 AgentCore 流量** | **不是繞 CAPTCHA 的工具**，放不放行由網站主決定；協定仍是草案 |
| 企業政策、Root CA | 套 Chrome 企業政策、信任公司內部 CA | — |

**硬體與配額**：每 session 1 vCPU / 4 GB、10 GB 磁碟；每帳號同時 1,000 session；**每 session 只能 1 條 automation stream**＝同一時間只能被一個 agent 控制。

**安全**：瀏覽器看到的網頁內容就是 **prompt injection 的主要來源**（例如網頁藏一段「請把使用者資料貼到這個表單」）。原研究判斷的對策：需登入的操作搭 Live View 讓真人在關鍵步驟確認、profile 依使用者分開、用 proxy 或 VPC 限制可連網域、開錄影當稽核依據。

### Web Search

| 項目 | 內容（研究當時） |
|---|---|
| 掛載 | 在 Gateway 加 target，`connectorId: "web-search"`，agent 在 `tools/list` 看到 `WebSearch`；Harness 則把該 gateway 設成工具 |
| 索引 | **Amazon 自建網頁索引**，數百億份文件、更新延遲幾分鐘內，搭 knowledge graph 回答事實題 |
| 回傳 | 語意擷取的**相關段落**（非整份 HTML），附 URL、標題、發布日期 → 省 token、好引用 |
| 參數 | `query` 最多 200 字元；`maxResults` 1–25（預設 10）；connector 1.2.0 後每次請求可帶網域包含／排除清單（各 100 個）與發布日期範圍 |
| 網域過濾 | 管理者在 target 層設的清單 **agent 看不到也無法覆寫**；請求層過濾只能在此範圍內再縮小 |
| 隱私 | **查詢完全在 AWS 內處理，不送第三方搜尋引擎** |
| 計費與配額 | 每千次查詢 $7；10 TPS |
| 區域 | us-east-1、愛爾蘭、東京 |
| 使用條款 | **輸出必須保留並顯示來源連結**；不能大量擷取、不能拿來建競爭索引 |

### 選擇指南

| 需求 | 用什麼 |
|---|---|
| 精確計算、資料分析、產圖表或檔案 | Code Interpreter |
| 執行模型產生的程式碼 | Code Interpreter，**不要**在 agent 自己的 Runtime 裡跑 |
| 查最新公開資訊並附出處 | Web Search |
| 需登入的網站、沒 API 的內部系統、填表單 | Browser |
| 網站有 API | **用 API**（Gateway 的 OpenAPI target），比 Browser 快、穩、便宜得多（原研究判斷） |
| 原生對話框、列印、跨視窗操作 | Browser＋`InvokeBrowser` |

與其他元件：VPC 設定方式與 Runtime 相同；Web Search 是 Gateway connector，可套 Gateway 限流與 Policy；Browser 登入的替代方案是用 Identity 的 OAuth（3LO）呼叫第三方 API——**能用 API 就不要用 Browser 模擬登入**（原研究判斷）；Nova Act 透過 CDP 接 Browser。

## ⚠️ 注意 / 什麼時候不適用
- **Code Interpreter 的 execution role 一定要最小化**，否則模型寫的任何程式都拿得到這些權限。
- Browser `keyType` 只支援 ASCII：要輸入中文就不能靠 `InvokeBrowser` 打字（改用 CDP 填值是否可行原研究未驗證，（推測）CDP 的 DOM 操作不受此限）。
- 一個 browser session 只能一個控制者；想多 agent 同時操作同一瀏覽器不適用。
- 用預設 `aws.browser.v1` 無法錄影，需要稽核錄影就得自建 browser。
- Web Bot Auth 不保證過機器人檢查。
- Web Search 只在三個區域、要顯示來源連結；每千次 $7，高頻查詢要考慮快取與 `maxResults`。
- **文件矛盾（原研究整理）**：
  - Code Interpreter 概觀頁寫「在 containerized environment 執行」，session 頁寫「每 session 一台 dedicated microVM」；以隔離強度與 AgentCore 整體描述來看後者較符合。
  - Session 頁寫「session 資料 TTL 保留 30 天」，同頁又說「session 結束時資料會被清掉」，實際保留位置與期限需向 AWS 確認。
  - Web Search 區域：connector 頁與區域表寫三個區域，只有 Harness 的 Tools 頁寫「只有 us-east-1」；以 connector 頁為準可能性較高，但東京仍建議實測。

## 🧪 我實際套用的紀錄
- （尚無）原研究本章沒有實驗；Sandbox／Public／VPC 三種網路模式的實際差異被列為「需要實測」的後續方向。

## 🔗 相關
- [[AgentCore Runtime]]：`InvokeAgentRuntimeCommand` 與 Code Interpreter 的分工、VPC 設定。
- [[AgentCore Gateway]]：Web Search 以 connector target 掛在 Gateway 上。
- [[AgentCore Identity]]：用 3LO 呼叫第三方 API 取代瀏覽器模擬登入。
- [[AgentCore 總覽與Harness vs Runtime]]：Harness 以工具設定接內建工具。
- [[Nova Act 與AgentCore整合及安全]]：Nova Act 透過 CDP 接 Browser 的接法與安全設計。
- [[Nova Act 部署維運與HITL]]：Live View 讓真人接手。
- [[提示注入與分層防禦]]：網頁內容是間接注入的主要來源。
- [[Function Calling 與結構化輸出]]：tool use 的基本運作。
