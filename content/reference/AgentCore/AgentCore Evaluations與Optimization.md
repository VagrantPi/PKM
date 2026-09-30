---
type: reference
name: "AgentCore Evaluations 與 Optimization 評估與優化 Evaluations"
source: "[[AgentCore 與 Nova Act 研究]]"
source_type: docs
tags: [ai, llm, agent, aws, agentcore, evaluation, llm-as-judge, ci, ab-testing, prompt-optimization]
triggers: [想在CI裡自動擋下agent品質退化, LLM評審的分數敢不敢拿來擋部署, AI自動改寫的新prompt敢不敢直接上線, 線上AB測試要跑幾天結果才算數, 想自動檢查agent有沒有呼叫該呼叫的工具]
---

> 原始研究：[GitHub](https://github.com/VagrantPi/AagentCore-Research/tree/main/07-evaluations)（依原研究，查證 2026-09-30）

## 🎯 什麼情境該想到我
當你「**agent 回 HTTP 200 但其實答錯、選錯工具、沒完成任務，想把這種語意上的錯變成可自動量測、可擋部署、可做 A/B 的東西**」的時候。

## ⚙️ 怎麼用

### 結論先講
- **Evaluations 是「針對 agent 行為的自動化測試與品質監控」**，資料來源**只有** Observability 收進 CloudWatch 的 trace／span；沒開 observability（Transaction Search + ADOT instrumentation）就不能評估。
- **評分三個層級**：SESSION（整段對話有沒有達成目標）、TRACE（單次回答品質）、TOOL_CALL（這一步工具選得對不對、參數有沒有捏造）。
- **能用程式判斷的就用程式判斷**：軌跡比對不花 token、結果確定；LLM 評審只負責「需要理解語意」的部分，而且只在與人工的 kappa 夠高時才拿來擋部署。
- **服務端沒有「通過門檻」功能**，門檻要在 CI 腳本自己判斷；官方 CI 範例的門檻寫法過寬（見下）。
- **Optimization 是閉環**：trace → Recommendations 產生新 prompt／工具說明 → 存成 configuration bundle 新版本 → Gateway 分流 A/B → 用 gateway rules 漸進上線或回滾。但 **A/B 的統計幾乎是黑盒子，樣本數要自己算**。

### 四種評估器
| 類型 | 做法 | 適合 |
|---|---|---|
| **Built-in**（`Builtin.*`） | 官方 prompt（公開、不能改），模型不公開、不能換，可能跨區域推論 | 快速起步；`Trajectory*Match` 是程式判斷 |
| **CustomDerived** | 沿用內建／第三方的 prompt 與量表，**換成你指定的 Bedrock 模型**（可設 temperature） | 資料駐留、模型一致性 |
| **Custom LLM-as-judge** | 自寫評分指示與量表，可用 `{context}`、`{assistant_turn}`、`{expected_response}`、`{assertions}` 等 placeholder | 領域品質標準 |
| **Code-based**（Lambda） | 輸入整個 session 的 span（上限 6 MB，超過截斷），回 `label`／`value`／`explanation`，最長 300 秒 | 確定性不變式：JSON 合法、無個資、沒呼叫禁用工具、業務規則 |

內建評估器涵蓋 `GoalSuccessRate`、三種軌跡比對、`Correctness`、`Faithfulness`、`Helpfulness`、`InstructionFollowing`、安全類（`Harmfulness`／`Stereotyping`／`Refusal`）、`ToolSelectionAccuracy`、`ToolParameterAccuracy`、Skill 類等。

### 五種執行模式與測試金字塔
| 層 | 測什麼 | 用什麼 | 頻率 |
|---|---|---|---|
| 單元測試 | 工具商業邏輯、schema | pytest／jest，不呼叫模型 | 每次 commit |
| **確定性 agent 測試** | 該呼叫的工具、禁用工具、格式、個資 | **Dataset** + `Trajectory*Match` + code-based | 每次 PR |
| 品質回歸 | 正確性、目標達成 | Dataset + `Correctness`／`GoalSuccessRate`（LLM 評審） | 合併主線、改 prompt／模型時 |
| 情境擴展 | 多輪、使用者不照劇本走 | **Simulation**（LLM 扮演使用者，只能用 `assertions`） | 上線前、每週 |
| 正式監控 | 品質趨勢、低分 session | **Online** 抽樣（每設定最多 25 個評估器） | 持續 |

另有 **On-demand**（指定 trace／session，每請求 1 個評估器）與 **Batch**（非同步大量評分，**token 單價 75 折**，同時 5 個 job、每 job 500 session）。**Ground truth（預期回應、斷言、預期軌跡）只能離線用**，含 ground truth placeholder 的自訂評估器不能放進 online。

**軌跡比對三選一**（只比工具名，不比參數）：
- `ExactOrderMatch`：完全一致、不能多 → 只給「多做一步就是錯」的固定流程。
- `InOrderMatch`：依序出現、中間可夾別的 → **預設選它**。
- `AnyOrderMatch`：都有出現即可 → 只在乎「有沒有查」。

### CI 怎麼接
- **等資料進 CloudWatch**：採「先等 60 秒、再每 30 秒輪詢、最多 10 分鐘」而非固定睡 5 分鐘；並**區分「沒有結果」（基礎設施問題）與「分數太低」（品質退化）**，用不同結束碼。
- **門檻依評估器類型**：code-based 不變式 `min = 1.0`；軌跡比對 `min = 1.0` 或容許少數失敗；LLM 評審以 `mean` 為主、`min` 設寬。
- **官方 CI 範例的缺陷**：對每個評估器「保留最高分」再跟 0.8 比，等於十題中一題過就通過，幾乎不可能失敗。
- **門檻跟基準線比**（例如不得比主線低超過 0.05），而不是絕對值。
- **題數決定雜訊**：通過率 0.7 的二元分數，10 題標準誤約 0.14、50 題約 0.06、200 題約 0.03（= √(p(1−p)/n)，可自行驗算）。
- 成本直覺：每次內建評估約 $0.04（15,000 input + 300 output token），50 題 × 3 個 LLM 評估器 ≈ $6；所以 **PR 只跑確定性層，合併才跑 LLM 評審**。

### LLM 評審要校準
- 官方**沒給任何一致性數據或校準流程**，只說「tested and benchmarked」。
- 公開 prompt 讀得出**寬鬆傾向**：`Faithfulness` 預設給最高分、除非看到矛盾（捏造但不矛盾的內容可能漏抓）；`InstructionFollowing` 在沒有明確指示或回應迴避時也給「Yes」。
- 流程：分層抽 100–200 個 session → 至少兩人標註（先算人對人 kappa，這是評審的天花板）→ 跑各評審 → 算**一致率、Cohen's kappa、混淆矩陣** → 檢查分數是否跟長度等無關因素相關 → kappa 夠高才擋部署。
- **為什麼用 kappa**：90% 樣本是 Pass 時，永遠回答 Pass 的評審一致率 90%、kappa 為 0。kappa =（觀察一致率 − 碰巧一致率）/（1 − 碰巧一致率）；分級 <0.4 差、0.4–0.6 普通、0.6–0.8 良好、>0.8 很好。
- 評審 temperature 一律設 0（但沒有 seed 參數，仍不保證可重現）；CustomDerived／自訂評審要**固定模型版本**；內建評審模型 AWS 更新你不會知道，**每月用固定標註集重跑 kappa**。

### Optimization 閉環
1. **Configuration bundle**：放在 AgentCore 上、有版本的自由格式 JSON（最外層 key 是資源 ARN）。每次更新產生不可變版本，有 `parentVersionIds`／`branchName`，parent 不是分支最新就回 `ConflictException`（像 Git 拒絕非 fast-forward）。
   - **工具說明**由 Gateway 在 `tools/list` 時直接替換，agent 不用改；**system prompt、模型 ID** 要 agent 每次請求讀 `BedrockAgentCoreContext.get_config_bundle()`（SDK ≥ 1.8）。
   - **一定要有預設值**：沒有 A/B 時回空 dict，讀取失敗會拋例外。
   - 替換不作用在 `invoke_tool` 與語意搜尋；HTTP target 會忽略 bundle。
2. **Recommendations**：`SYSTEM_PROMPT_RECOMMENDATION` 需要剛好一個有數值分數的評估器當目標；`TOOL_DESCRIPTION_RECOMMENDATION` 不需要。每次只取樣 **20 個 session**，結果存成新 bundle 版本但**不會自動啟用**，官方只說「套用前請審查」。
   - 審查重點：`cb diff` 看有沒有順便改掉無關段落；**安全／業務約束有沒有被刪弱**（只最佳化單一分數時，刪掉「金額上限」可能讓分數變高——這類約束本該放 Policy）；是否對 20 個樣本過擬合；長度與 token 成本。
   - 上 A/B 前先用 **batch** 讓新舊版對同一批 session 評分，並看護欄指標（`Harmfulness`、`Refusal`、軌跡）有沒有退化。
3. **A/B test**：只能兩組（`C`／`T1`），每個 gateway 同時 1 個；以 session 固定分組；指標只能是 online 評估器的**數值**分數；實驗期間 online 抽樣調到 100%。
4. **上線與回滾靠 gateway rules**：`staticOverride` 固定版本、`weightedOverride` 做 95/5 → 80/20 → 50/50 → 0/100 的 canary；回滾就把 rule 指回舊版本 ID（版本不可變，所以回滾可靠）。把 bundle 版本 ID 也放進 Git／IaC。

**A/B 樣本數要自己算**（雙尾 α=0.05、檢定力 0.8）。二元比例的每組樣本數 n ≈ [z₀.₉₇₅·√(2p̄(1−p̄)) + z₀.₈·√(p₀(1−p₀)+p₁(1−p₁))]² /(p₁−p₀)²；連續分數 n = 2(z₀.₉₇₅+z₀.₈)²σ²/δ²。**n 跟差異平方成反比**，瓶頸是流量較小的那組，而 online 抽樣比例會直接乘上去。

## ⚠️ 注意 / 什麼時候不適用
- **文件矛盾（原研究整理）**：
  - 內建評估器數量：定價頁 13、文件 17 個評審範本、研究依清單寫 16。
  - 官方範例 temperature 一處 1.0、一處 0.0。
  - CloudWatch 等待時間一頁寫 2–5 分鐘、另一頁 2–3 分鐘。
  - Batch job 名稱規則 `[a-zA-Z][a-zA-Z0-9_]{0,47}` 不能有 `-`，但官方範例用了連字號，照抄會失敗。
  - `parentVersionIds` 同一頁先說必填、後說可省略。
  - A/B 停止後流量一頁說回對照組、一頁說回「預設設定」。
- **更正（原研究對自己本文）**：自訂評估器被啟用中的 online 設定引用就會**鎖住不能改刪**，適用**所有**自訂評估器，不只 code-based；Dataset 除了 SDK 端檔案格式，**控制面也有代管 Dataset 服務**（發布版本不可改），CI 應固定引用某版本。
- **A/B 的 `isSignificant` 不可盡信**：定義是「p < 0.05 且樣本數足夠」，但「足夠」沒寫，官方範例實驗組 **6 個樣本**就被標顯著；檢定方法、α、停止規則、MDE 都不能設。官方說「輪詢結果不影響有效性」忽略了**偷看問題**——每天看、一顯著就停，誤判率遠高於 5%。
- **`Evaluate` API 只回「最後 10 個 trace」**：15 輪的 session 前 5 輪被略過。
- code-based 評估器**一定要回 `value`**，否則不能用在 Recommendations 與 A/B。
- span 欄位名稱依框架而異，寫 code-based 前**先用 on-demand 撈一份真實 `sessionSpans` 對照**（原研究推論：最易出錯處）。
- 孟買、新加坡內建評估器速率只有其他區的 1/6（200 vs 1,200 次／分）；多個 PR 同時跑會撞 batch「同時 5 個」上限，要排隊重試。
- 內建評估器可能跨區域推論，有資料駐留要求時改用 CustomDerived。
- 流量很小的產品：A/B 可能永遠跑不到樣本數，此時靠 batch 離線比較與人工審查（推測）。

## 🧪 我實際套用的紀錄
- **CI 門檻（`ci-gate`，本機合成資料通過，未在 AWS 跑過）**：`gate.py` 以 `{"Builtin.Correctness": {"mean": 0.8, "min": 0.5}, "Custom.NoPII": {"min": 1.0}}` 測三情境——全部通過 exit 0；有一題 0.30 時 `mean 0.68 < 0.8；min 0.30 < 0.5（最差：s2）` exit 1；缺評估器結果 exit 2。範例 code-based 評估器擋「禁用工具 `AdminTarget___delete_user`」與「回覆含 email／台灣手機號」，格式錯誤回 `VALIDATION_FAILED`。
- **評審一致性（`judge-agreement`，只用合成資料，200 session、人工 Pass 比例 0.70）**：內建 Helpfulness 一致率 0.85、kappa 0.61、FP 23；自訂評審一致率 0.86、kappa 0.69、FN 17。**一致率幾乎相同但錯的方向相反**；內建評審對長回覆的偽陽率 0.59、短回覆 0.19，顯示被長度影響。擋部署時放過壞的（偽陽）通常比誤擋好的更危險，所以選自訂評審。
- **A/B 樣本數（`ab-sample-size`，已實跑，每天 2,000 session）**：通過率 0.70→0.80 每組 294；0.70→0.75 每組 1,251，50/50 約 2 天、80/20 約 4 天、**80/20 且評估只抽 10% 要 32 天**；0.70→0.72 每組 8,080（80/20 要 21 天）；連續分數 σ=0.25、差 0.05 每組 393。評估費以 $0.04／次計，2,500 session × 1 評估器 ≈ $100。即使樣本早夠，也至少跑**完整一週**涵蓋平日與週末。

## 🔗 相關
- [[AgentCore Observability]] —— 唯一的資料來源，沒開就不能評估
- [[AgentCore Gateway]] —— A/B 分流、gateway rules 上線與回滾、工具說明替換
- [[AgentCore Policy]] —— 互補：Policy 事前阻擋、Evaluations 事後評分；被 Recommendations 刪掉的約束應放這裡
- [[AgentCore 總覽與Harness vs Runtime]] —— Harness 可直接從設定開啟評估與 Optimization
- [[LLM-as-Judge]] —— 評審偏誤與校準的通用機制
- [[Agent 評估]] —— 軌跡、目標達成等 agent 專屬指標
- [[上線閘門與線上評估]] —— 通用的分層閘門與線上 A/B 設計，本頁是 AgentCore 上的落地
- [[工具-AI改動的AB對照評測]] —— 分辨改動效果與雜訊
