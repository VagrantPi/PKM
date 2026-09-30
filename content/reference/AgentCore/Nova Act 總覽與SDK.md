---
type: reference
name: "Nova Act 總覽與 SDK 瀏覽器自動化 Agent Nova Act"
source: "[[AgentCore 與 Nova Act 研究]]"
source_type: docs
tags: [ai, llm, agent, aws, nova-act, browser-automation, playwright, python]
triggers: [想讓 agent 幫我操作沒有 API 的網站, Playwright 腳本網站一改版就壞掉, 要把一堆資料自動填進廠商後台表單, 想用自然語言描述操作流程取代 selector 腳本, 評估要用瀏覽器 agent 還是自己寫爬蟲]
---

> 原始研究：[GitHub](https://github.com/VagrantPi/AagentCore-Research/tree/main/nova-act)（依原研究，查證 2026-09-30）

## 🎯 什麼情境該想到我
當你「手上有一個沒有 API 的網頁系統（CRM、ERP、廠商入口），想讓 agent 像真人一樣看畫面、點按鈕、填表單，而且要能部署到 AWS 上穩定跑」的時候。

## ⚙️ 怎麼用

### 結論先講
- **Nova Act 是 AWS 專做「瀏覽器 UI 自動化」的 agent 服務。** 你寫 `nova.act("搜尋 rubber duck debugging")`，模型看著網頁截圖一步一步操作，直到完成或放棄；可以和一般 Python、Playwright 呼叫混著寫。
- **四件套：** 自家訓練的模型（**不能換成別的模型**）、Python SDK（`pip install nova-act`，**只有 Python**）、CLI 與 IDE 擴充（VS Code / Cursor / Kiro）、AWS Console（檢視每次執行的逐步紀錄）。另有免設定的網頁 Playground，可把試出來的操作下載成 Python 腳本。
- **瀏覽器不在 Nova Act 服務裡，而是在你的程式那一端。** 服務本身只做兩件事：「模型推論」與「執行紀錄」。你的程式透過 Playwright / CDP 操作本機、容器內或 AgentCore Browser 的 Chromium，每一步把截圖送給服務（資料面 API `InvokeActStep`），拿回下一個動作。
- **跟 AgentCore 不是替代而是疊加：** Nova Act 管「下一步點哪裡」，[[AgentCore Built-in Tools|AgentCore Browser]] 提供雲端瀏覽器，[[AgentCore Runtime]] 負責跑你的 workflow 程式。
- **只在 us-east-1**（依原研究查證日），官方沒有公布其他區域時程。

### 名詞與層級
| 名詞 | 白話 |
|------|------|
| act | 呼叫一次 `act()`＝交代模型一件事，內部是一段 agent loop |
| step | act 內的一輪「截圖觀察 → 決定一個動作（點擊、輸入、捲動）→ 執行」。預設最多 30 步，硬上限 200 步 |
| session | 一個瀏覽器實例。session 內的 act 依序執行、**只能單執行緒**；要平行就開多個 session |
| workflow / workflow run | 整件工作的定義（幾個 act ＋串接的 Python）／它的一次執行，像 CI 的 pipeline 與一次 pipeline run |

層級是 `Workflow definition → Workflow run → Session → Act → Step`，Console 就照這個層級呈現紀錄。後端類比：agent loop 是一個「由模型決定下一個狀態」的狀態機，概念上就是 [[ReAct 與 Agent Loop]] 的「觀察 → 決策 → 行動」迴圈套在 UI 上。

### 跟其他瀏覽器自動化方案比較（原研究的判斷，非官方說法）
| 方案 | 誰決定下一步 | 優點 | 代價 |
|------|------|------|------|
| Playwright / Selenium 腳本 | 寫死的 selector | 確定性高、便宜、快 | 網站改版就壞，維護成本高 |
| browser-use 等框架＋通用 LLM | 通用模型 | 可換模型、生態系大 | 按 token 計費，截圖很吃 token |
| **Nova Act** | 專為 UI 訓練的模型 | 官方宣稱在日期選擇器、下拉選單、彈窗等難點內部評測 >90%；按時間計費好預估；有 Console 紀錄 | 只有 Python、模型不能換、只在 us-east-1 |
| AgentCore Browser | 不決定，只提供瀏覽器 | microVM 雲端瀏覽器、Live View、錄影、profile | 要搭配上面任一種「大腦」 |

常見組合：**Nova Act（大腦）＋ Playwright（密碼、下載等確定性操作）＋ AgentCore Browser（雲端瀏覽器）＋ AgentCore Runtime（跑 workflow）**。

### 最小程式與兩個核心方法
```python
from nova_act import NovaAct
from pydantic import BaseModel

class Flight(BaseModel):
    departure: str
    price: float

with NovaAct(starting_page="https://nova.amazon.com/act/gym/next-dot/search") as nova:
    nova.act("Find flights from Boston to Wolf on Feb 22nd")          # 做事
    r = nova.act_get("Return the cheapest flight", schema=Flight.model_json_schema())
    flight = Flight.model_validate(r.parsed_response)                 # 做事＋取資料
```
- `act()` 做事；`act_get(schema=...)` 做事並回傳結構化資料。**要拿資料就一定要傳 schema**，否則回傳值沒有 response。不符合 schema 會拋 `ActInvalidModelGenerationError`——角色就像呼叫外部 API 時的 response DTO 驗證。
- 布林判斷：`act_get("Am I logged in?", schema=BOOL_SCHEMA)`，適合當流程分支條件。
- 參數：`max_steps`（預設 30）、`timeout`（官方建議優先用 `max_steps`，因每步時間會隨負載浮動）、`observation_delay_ms`（等動畫跑完再截圖）。
- 開發模式：Script（`with`）、Interactive（REPL 一句句試，`ctrl+x` 中斷 act 但保留瀏覽器）、Async（`nova_act.asyncio`）。每個 act 會產生一份 HTML trace（每步截圖＋動作）；`record_video=True` 可錄影。

### act() 的 prompt 寫法（官方指南濃縮）
1. **直接、精簡：** 寫「Navigate to the routes tab」，不要寫「Let's see what routes vta offers」。
2. **講完整：** 條件、偏好、**停在哪裡**都寫清楚（「stop when you get to the payment page」），當成交代一個不熟這網站的新同事。
3. **拆小：** 大任務拆成數個 act，用 Python 串接，前一個輸出當下一個輸入；還不穩就再拆。官方經驗是 **30 步內能完成的 act 最可靠**。
4. 擷取資料要**獨立一個 act**，不要「先操作再擷取」寫在同一句。
5. 小技巧：日期寫絕對日期；找不到搜尋鈕就加「type enter to initiate the search」。只支援英文 prompt。

拆小同時提升可靠度、速度與省錢（計費按時間）。最直接的優化是把確定性的部分（跳 URL、填帳密、下載）從 act 移到 Python / Playwright。

### 模型與程式碼的分工
`nova.page` 就是 Playwright 的 `Page`：
| 需求 | 做法 |
|------|------|
| 密碼、卡號 | 先 `act("click on the password field")`，再 `nova.page.keyboard.type(getpass())`——模型會拒絕處理密碼 |
| 換頁 | `nova.go_to_url(url)`，比 `page.goto` 更會等頁面真正載完 |
| 下載 | `with nova.page.expect_download() as d: nova.act("click download")` |
| 原生對話框 | `nova.page.on("dialog", handler)`（Playwright 預設會自動關掉） |
| 上傳 | 預設禁止，用 `SecurityOptions(allowed_file_upload_paths=[...])` 窄開 |

### 錯誤處理
例外都在 `nova_act.types.act_errors`，分四類：
| 類別 | 意思 | 例子 | 處理 |
|------|------|------|------|
| `ActAgentError` | 任務沒完成 | `ActAgentFailed`、`ActExceededMaxStepsError` | 改 prompt 或拆小重試 |
| `ActClientError` | 請求被拒 | `ActGuardrailsError`、`ActRateLimitExceededError` | 調整或退避重試 |
| `ActExecutionError` | 本機執行失敗 | `ActActuationError`、`ActCanceledError` | 回報 bug |
| `ActServerError` | 服務端錯誤 | `ActInternalServerError` | 回報 bug |

**重試陷阱：** `Workflow` 預設逾時會重試一次（`read_timeout` 60 秒），官方提醒同一請求可能真的被執行兩次、費用也算兩次。**act 不是冪等的**——「送出訂單」的 act 重試可能下兩次單，有副作用的 act 重試前先用 `act_get(schema=BOOL_SCHEMA)` 確認現況。

### 驗證、Workflow 與平行
- **API key**（nova.amazon.com 申請、免費試用，**互動資料會被收集改進服務**）vs **IAM**（AWS 服務條款）。**要用 IAM 就必須用 `Workflow` / `@workflow` 包住程式**，SDK 會自動呼叫 `CreateWorkflowRun` / `UpdateWorkflowRun`，把 session、act、step 掛在同一個 run 下。
- `@workflow` 靠 ContextVar 注入，**不會自動傳到新執行緒**：用 `get_current_workflow()` 手動傳入或 `copy_context().run`。**多 process 不支援**（boto3 client 無法 pickle）。
- 平行＝開多個 `NovaAct`（官方稱「瀏覽器版 map-reduce」），真正上限是 `InvokeActStep` 預設 **5 TPS／帳號**。

### 模型版本
| model_id | 行為 |
|------|------|
| `nova-act-latest` | 追最新 GA，永遠不會自動跳到 preview |
| `nova-act-preview` | 追最新 preview（查證時為 v1.1）；SDK 太舊會退回 GA 並警告 |
| `nova-act-v1.0` | 固定 2025-12-02 的 GA 版，承諾至少支援 1 年 |

原研究判斷：**正式環境固定版本號**，模型換版可能改變「同一句 prompt 會點哪裡」，UI 自動化對此很敏感。

### 保存登入狀態
預設每次都是乾淨瀏覽器。四種 provider：本機檔案、S3（SSE-KMS）、AgentCore Browser profile、Chromium profile 目錄。只有 Chromium profile 保得住 IndexedDB／快取，但不能跨機器；官方看法是大多數 OAuth / SAML 登入只存 cookie 就夠。部署到雲端容器時，本機檔案與 Chromium profile 重啟就沒了，實務上只剩 S3 或 AgentCore Browser profile。

### 計費與配額（依原研究查證日的牌價）
- **每 agent hour $4.75**，按 agent 實際工作的牆鐘時間；平行幾個算幾份；**HITL 等真人的時間不計**。部署產生的 AgentCore Runtime、ECR、S3 另計。計費頁沒有 token / step 費用。
- 試算：5 分鐘流程一天 1,000 次 → 1,000 × 5/60 ≈ 83 agent hours ≈ **$396/天**（未含 Runtime / Browser）。
- 配額：`InvokeActStep` 5 TPS（可調）、其他 API 100 TPS、每 act 最多 200 步（不可調）、act timeout 24 小時、workflow run 1 週、每 act 最多 100 個工具（spec 350 KB）。
- 原研究推論：若每步 2–5 秒（假設值），5 TPS 約撐 10–25 個同時 session；大批量前先申請提高。

### 文件矛盾
- README 說最佳化解析度是 `864×1296` 到 `1536×2304`，同段範例卻用 `1920×1080`（寬度已超出範圍）；且這個範圍寫法像直式畫面，實際尺寸需實測。
- AWS AI Service Card 寫「每任務最多 100 步、瀏覽器 session 最長 30 分鐘」，與配額頁的 200 步／24 小時不一致（見 [[Nova Act 與AgentCore整合及安全]]）。

## ⚠️ 注意 / 什麼時候不適用
- **非瀏覽器應用不支援**（不是通用 computer use）；瀏覽器本身的彈窗（例如位置權限）`act()` 碰不到。
- **模型拒絕處理密碼欄位**，要改用 Playwright；但之後的 act 截圖若畫面上看得到敏感資料，照樣會被送到服務端。
- 只有 Python（3.10+），**不能在 Jupyter / iPython 用**；只支援英文 prompt；3.0 以前的 SDK 已停止支援。
- 超出最佳化解析度範圍準確度可能下降。
- 流程完全固定、網站不常改版、追求便宜又快：直接寫 Playwright 比較划算。需要換模型、多語言或非 us-east-1：Nova Act 目前做不到。
- `Time worked` 印出的工作時間只是估計，官方聲明**不能拿來對帳**。

## 🧪 我實際套用的紀錄
- （尚無）原研究的平行執行範例是依 README 模式改寫，**尚未實測**；可靠度（大 act vs 拆小 act）、容量規劃都列為待實驗方向。

## 🔗 相關
- [[Nova Act 部署維運與HITL]]：部署到 AWS、監控、真人接手與工具
- [[Nova Act 與AgentCore整合及安全]]：接 AgentCore Browser / Identity、prompt injection 防線
- [[AgentCore Built-in Tools]]：AgentCore Browser 雲端瀏覽器
- [[AgentCore Runtime]]：workflow 的預設部署目標
- [[ReAct 與 Agent Loop]]：act 內部的觀察—決策—行動迴圈
