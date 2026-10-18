---
type: article
title: "程式碼圖譜工具選型（跨 repo 實測後的建議）"
source_url: https://vagrantpi.github.io/PKM/static/skill-eval/2026-10-18-cross-repo/
author: 自己（以多個 subagent 分工實測，再由對抗式驗證逐條核對）
site: PKM 技能評比
tags: [ai, agent, code-graph, mcp, 選型, 跨repo]
captured: 2026-10-18
read_status: read
---

> 這是一份**脫敏後的選型指南**。原稿是寫給團隊的內部文件，裡面有系統名稱、端點清單和程式碼位置，只收不發布。這裡留下的是結論、數字、建議和做法；具體系統一律用泛稱。
> 數字的出處見公開報告 → [10-18 跨 repo 實測報告 ↗](https://vagrantpi.github.io/PKM/static/skill-eval/2026-10-18-cross-repo/)；四個工具本身的介紹見 [[moc/AI技能收藏|AI 技能收藏]]。

## 📌 30 秒摘要（讀完用自己的話寫一句）
> 這篇在講：拿一組真實的「TS 後端（A）↔ Go 服務（B）」測四個程式碼圖譜工具：codebase-memory、codegraph、GitNexus、graphify。結果**沒有一個工具能自動連起跨 repo 的呼叫**（HTTP 0/75、gRPC 0/1）。5 題跨 repo 實戰題，四個工具組和只用 grep 的基線幾乎都答對，跨 repo 的銜接全靠 grep。工具真正的差別在 **repo 內**：那裡 codegraph 1.6.2 明顯領先。跨 repo 要靠自己維護一份**合約表**。

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- 下次有人問「我們的 agent 要接哪個程式碼圖譜？跨 repo 的問題怎麼辦？」，直接給這份。
- 導入前照「⚠️ 導入前一定要做的檢查」跑一次，因為結論高度依賴你的 codebase 怎麼寫。

## 🧰 這篇給我的工具（連到 tools/ 工具卡）
- （沒有抽出工具卡。四個工具的安裝與注意事項都在 [[moc/AI技能收藏|AI 技能收藏]]；這篇的「合約表」做法之後若重複用到，再抽成工具卡。）

## ✨ 關鍵重點

### 1. 受測系統長什麼樣（脫敏）

| 項目 | 內容 |
|---|---|
| 兩個 repo | TS 後端（A）、Go 服務（B），用量測當時工作分支的 HEAD（A 沒有測最新的開發分支），完整範圍 |
| HTTP | A 打 B 共 **75 個端點**（其中 2 個是 SSE），呼叫點分布在 A 的 12 個 client 檔。B 的 v1 路由共 130 條 |
| gRPC | 1 條 server-stream。A 在執行期用 protoLoader 載入一份**手抄的 proto**，沒有產生的 stub |
| 身分 | API key、使用者識別等幾個 header |
| 跨邊界的 ID | A 的資料庫有十來個欄位存 B 給的 ID |
| 反向呼叫、共用基礎設施 | 0 |

### 2. 跨 repo 自動連結：四個工具都是 0

| 工具 | 跨 repo 連結 | HTTP /75 | gRPC /1 | B 的 route → handler /130 |
|---|---|---|---|---|
| codebase-memory（只建索引） | 0 | 0 | 0 | 0 |
| codebase-memory（加跑 cross-repo pass） | 136，**全錯** | 0 | 0 | 0 |
| codegraph 1.4.1 | 沒有這個功能 | 0 | 0 | 53 |
| GitNexus group | 2，全錯 | 0 | 0 | 0 |
| graphify merge | 0 | 0 | 0 | 0 |

**為什麼連不起來**：
- **Go 1.22 的路由寫法**：`mux.Handle("POST /path")` 把 HTTP 方法寫進路徑字串。codebase-memory 的解析器要求路徑以 `/` 開頭，這一行直接被丟掉（已從它的原始碼確認）。GitNexus 在 B 端抽出的 HTTP provider 也是 0，推測是同一個原因。
- **TS 的呼叫寫法**：`this.client.post("/path")`，baseURL 寫在父類別、路徑是純字串。codebase-memory 只認得樣板字串（認出 50/75 個呼叫點，但認出來也配不上 B 端）；GitNexus 幾乎沒有把 A 的 client 認成呼叫方。
- **gRPC**：A 端在執行期才載入 proto，沒有任何工具把它連到 B 端真正的 handler。GitNexus 手寫 manifest 時，B 端會解到產生出來的 stub。
- **假連結從哪裡來**：codebase-memory 那 136 條的來源全是 B 的測試、scripts、web 工具，目標是 A 的 benchmark 假 handler（91）、泛用路由（44）和 middleware（1）。**用完整 repo 建索引，測試和 mock 就會產生假的跨 repo 連結。**
- **codegraph 的 53/130**：其餘 77 條都連到同名方法，包括測試替身。原因是 handler 透過 struct 欄位取方法的寫法，它只能靠方法名配對。

### 3. 實戰題：工具沒有比 grep 好，也沒有比較省

5 題跨 repo 實戰題：
- Q1：proto 欄位改名的兩邊影響。
- Q2：從 worker 正向追到 B 的應用層。
- Q3：回傳格式改變的反向影響。
- Q4：列出全部 75 個端點。
- Q5：找出合約漂移。

每組 1 個 agent 作答：

| 分組 | Q1（6） | Q2（7） | Q3（10） | Q4（75） | Q5a（7） | Q5b（4） | 錯 | token | 工具呼叫 |
|---|---|---|---|---|---|---|---|---|---|
| 只用 grep | 6 | 7 | 10 | 75 | 7 | 4 | 1 | 162,414 | 49 |
| codegraph | 6 | 7 | 10 | 75 | 7 | 4 | 1 | 155,351 | 53 |
| GitNexus | 6 | 7 | 10 | 75 | 7 | 4 | 1 | 177,576 | 66 |
| graphify | 6 | 7 | 10 | 75 | 7 | 4 | 0 | 154,966 | 59 |
| codebase-memory | 6 | 7 | 10 | 75 | 5 | 4 | 1 | 200,628 | 71 |

- **每一組都說 HTTP 路由字串、proto、SSE 事件名稱是用 grep 找的。** token 相對 grep 基線在 −5% 到 +24% 之間，最貴的是 codebase-memory 組。
- 「錯 1」的四組，都多列了一個只在 switch 裡有型別對應、實際上沒有任何地方產生的事件。
- **真值表在實驗中被作答的 agent 修正了兩次**：我一開始漏掉經其他管道送出的事件，後來又排除那個不會送的事件。這次不是工具在糾正我，而是「多個 agent 各自從原始碼找答案」這個做法本身在糾正我。

### 4. repo 內才是工具的戰場

TS type checker 當真值，A 的 service 層有 1,395 個跨檔呼叫點：

| 工具 | 跨檔召回 | `export default new X()` singleton | `export const x = new X()` | 跨檔精確度 | 主要錯誤 |
|---|---|---|---|---|---|
| codegraph 1.4.1 | 91% | 96% | 0% | 64% | 同名退化、只連到接收者常數 |
| **codegraph 1.6.2** | **97%** | 95% | 100% | **81%** | 範圍外的 repository／第三方函式庫被同名猜測 |
| codebase-memory | 25% | 4% | 0% | 83% | 漏抓匯入的 singleton |
| GitNexus | 34% | 0% | 100% | 97% | 漏 default singleton；介面 dispatch 連到所有實作 |
| graphify | 22% | 0% | 0% | 98% | 漏掉所有成員呼叫 |

- **取捨**：codegraph 召回率高、精確度中等，要用 grep **篩掉假陽性**；GitNexus、graphify、codebase-memory 精確度高、召回率低，要用 grep **補上漏掉的**。
- 抽兩個方法查 caller（6 處、4 處）：codegraph 兩邊全中；GitNexus 只中後者；graphify、codebase-memory 幾乎都漏。
- 8 月一份舊報告寫 codebase-memory 的 caller「全中」，用同一個 build 重測是 0，那份報告已加註。

### 5. 順帶查到的合約漂移（脫敏）
實戰題 Q5 本身就在找漂移，而且找到的都是真問題：
- **SSE 事件**：B 在某個串流端點會送 7 種 A 沒處理的事件，A 直接丟掉，其中 1 種會造成**功能缺失**。
- **DTO**：同一個回應有 **4 處不一致**：1 個欄位的 optional 屬性兩邊不一致（Go `omitempty` 對上 TS 必填），3 個欄位 A 沒有定義。另外，B 有 2 個欄位已經恆回固定值，A 仍在讀，其中 1 個還拿來分支，那段程式碼等於死碼。
- **手抄的 proto 和上限常數**：兩份 proto 目前只差註解，batch 上限、上傳大小等常數也是兩邊各寫一份，都沒有任何同步檢查。如果 proto 欄位改名、A 卻漏改 wire key，proto-loader 會靜默丟掉那個欄位（依它會忽略未知鍵推論）。

這幾類問題，任何一個程式碼圖譜工具都不會告訴你。要靠下面的合約表。

## 💬 原文摘錄
- （本篇是自己的實驗紀錄，沒有原文；數字以報告為準。）

## ✅ 建議（給團隊）
1. **repo 內導航用 codegraph 1.6.2**：
   - 升級並重建索引，安裝時加 `--no-permissions`，shell 設 `DO_NOT_TRACK=1`。
   - caller 結果只當候選，常見方法名（`find*`／`update`／`create`／`get`／`set`）一定要用 grep 收尾。
   - Go 的路由直接讀 router 原始碼，不要信它的 route → handler。
2. **跨 repo 不靠工具，自己維護合約表**：
   - 用一支小腳本，從 A 抓 `client.<verb>("<path>")` 這類呼叫，從 B 抓 `mux.Handle("<METHOD> <path>")` 和對應的 handler，正規化路徑參數（`${x}`、`{x}` 都轉成 `{}`）後配對，產出「呼叫點 → 路由 → handler」表。這次真值表就是這樣做的。
   - CI 雙向檢查：A 呼叫了 B 沒有的路由就報錯；B 刪了 A 還在用的路由也報錯。**SSE 事件名稱也一起比對**，第 5 點那種漂移就抓得到。
   - 給 agent 一個查表的 skill：先查表，再到各 repo 用 codegraph 或 grep。
3. **proto 收斂成單一來源**：用共用 package 或 submodule，CI 比對 hash，再加一個契約測試（wire key 必須和 proto 欄位一致）。
4. **其他三個工具**：
   - codebase-memory：受測的是自己編譯、沒有簽章的 dev build，每次 session 都會連 GitHub 檢查版本，本機 UI 也沒有驗證。改用官方簽章的 release，並等它支援 Go 1.22 路由和純字串 URL，再重評。
   - GitNexus：授權是非商用，公司要用得另外買。
   - graphify：只在文件也要進圖時才考慮。

## ⚠️ 導入前一定要做的檢查
- **拿自己的寫法做最小重現**：挑你 codebase 最常見的呼叫寫法和路由寫法（default singleton、具名 const 實例、Go 1.22 路由、純字串 URL），各寫 2–3 個檔，每個工具跑一次。這只要幾秒，卻決定上面的結論在你的系統上還成不成立。
- **跨 repo 先跑一次合約抽取**：看工具到底抽出幾個合約、配對上幾條。這次文件寫「支援」，實際一條都沒配上。
- **建索引時排除測試、scripts、mock**，否則會產生假的跨 repo 連結。

## 🧪 試點計畫與退場條件
- **範圍**：2 週，2–3 人，codegraph 1.6.2 加合約表 skill。
- **量測**：每週挑 5 個真實任務（跨 repo 和 repo 內各半），記錄「agent 答案被人工修正的次數」和 token，對照不開工具的基線。
- **退場條件**：
  - 修正率沒有比基線低。
  - 或 token 沒有省下 10% 以上。
  - 或出現一次因為圖譜假邊造成的錯誤改動。
  
  任一條成立，就退回「grep 加合約表」。

## 限制
- **只測一組 repo**：命名規律、URL 大多寫成字面值，對 grep 特別有利。換成動態組 URL 或端點更多的系統，結論可能不同。
- **N=1**：5 題每組只答一次，由我依真值表自評；真值表在實驗中修正過兩次。
- **版本**：
  - codebase-memory 測的是自己編譯的 dev build，最新 release 沒測。
  - codegraph 1.6.2 只測過 repo 內的 TS 和小型重現。
  - GitNexus 用 `--index-only`。
  - graphify 只測 `--code-only`。

## 🔗 相關
- [[moc/AI技能評比|AI 技能評比]]：10-18 跨 repo 報告，以及 10-17 四方評比（寫法決定一切）。
- [[moc/AI技能收藏|AI 技能收藏]]：四個工具的安裝方式、盲點和實測紀錄。
