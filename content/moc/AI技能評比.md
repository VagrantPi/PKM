---
type: moc
title: "AI 技能評比"
tags: [moc, ai, skills, benchmark]
---

> 自己實際跑出來的 **skill 對照評比**。點連結開原始報告網頁（完整排版與圖表）。
>
> ⚠️ **這頁只索引、不轉寫內容。** 每份報告記「一句話結論」＋「**報告自己標明的限制**」（後者照抄，不是我另下的判斷）。半年後回看，**先讀限制再讀結論**。
>
> 工具本身怎麼裝、做什麼 → [[moc/AI技能收藏|AI 技能收藏]]。

## 📇 報告清單

| 日期 | 題目 | 受測對象 | 開啟 |
|---|---|---|---|
| 2026-08-05 | 任務系統解說題：四組對照評分 | base・ponytail・i-have-adhd・兩個同開 | [報告 ↗](https://vagrantpi.github.io/PKM/static/skill-eval/2026-08-05-ponytail-vs-i-have-adhd/) |
| 2026-08-05 | backend 索引能力：真值裁判對決 | codegraph・codebase-memory-pro | [報告 ↗](https://vagrantpi.github.io/PKM/static/skill-eval/2026-08-05-codegraph-vs-codebase-memory/) |
| 2026-10-17 | 給人看的地圖 vs 給 agent 查的索引 | Understand-Anything・codegraph | [報告 ↗](https://vagrantpi.github.io/PKM/static/skill-eval/2026-10-17-understand-anything-vs-codegraph/) |
| 2026-10-17 | 程式碼圖譜四方評比：寫法決定一切 | codegraph・GitNexus・graphify・Understand-Anything | [報告 ↗](https://vagrantpi.github.io/PKM/static/skill-eval/2026-10-17-code-graph-four-way/) |
| 2026-10-18 | 跨 repo（TS ↔ Go）：四個工具都連不上 | codebase-memory・codegraph・GitNexus・graphify・grep 基線 | [報告 ↗](https://vagrantpi.github.io/PKM/static/skill-eval/2026-10-18-cross-repo/) |

---

## 2026-08-05 · 任務系統解說題：四組對照評分

<a href="https://vagrantpi.github.io/PKM/static/skill-eval/2026-08-05-ponytail-vs-i-have-adhd/" target="_blank" rel="noopener"><strong>開啟完整報告 ↗</strong></a>

**受測**：`base`・[[moc/AI技能收藏#ponytail|ponytail]]・[[moc/AI技能收藏#i-have-adhd|i-have-adhd]]・兩個同開　**設定**：`claude-opus-5`、`claude -p` headless、基線 `--safe-mode`、工具只給 Read／Grep／Glob、四組交錯各 3 次（12 次全數有效）　**題目**：「幫我解說這個專案的任務系統設計」

**一句話結論**：四組都寫得很好，**base 沒有比較差**。開 skill 之後答案真的變短——但**短在少講了三分之一的概念**，不是少講廢話。

**關鍵證據**

| 發現 | 數字 | 為什麼可信 |
|---|---|---|
| 概念覆蓋變少 | ponytail −31%、i-have-adhd −17%、兩個同開 −33% | base 自跑三次全距只有 9 個概念，−18／−19 是這條雜訊線的**兩倍** |
| 內容沒換方向 | 組內概念重疊 42.7%、跨組 38.9% | 兩者幾乎一樣 → 是**從同一概念池挑得更少**，不是挑了不同的東西 |
| **token 沒省到** | 四組差距最大 864，base 自跑三次就差 2,348 | token 大宗是 26–29 輪工具呼叫的推理，不是最終答案 |

反直覺的一點：**兩個同開不是相加**（應該接近 −48%，實際 −33%），壓縮由 ponytail 主導、adhd 被吸收；但兩個同開是**四組裡最穩的**（概念數全距只有 5）。

**怎麼用**
1. **想完整就別開**——base 完整度與資訊密度最高，研究沒碰過的模組時，多出來的 18 個知識點值得那 1,600 字。
2. **想快速掌握輪廓**開 ponytail 或兩個同開，少三分之一概念換短四分之一篇幅，骨架不會少。
3. **要可預期產出**用兩個同開。
4. **別為省 token 開任何一個**（三輪實驗都在雜訊裡；真要省往 rtk、[[moc/AI技能收藏#codegraph|codegraph]]、subagent 隔離找）。

**⚠️ 限制（報告照抄）**
- **評分只評了每組第一次**，沒有雜訊底線可比，**排序不可靠**——同組跑三次答案長度能差 30%、概念數能差 17 個，單次判讀的變異很可能大於 47 與 55 的差距。**別拿那張評分表做決定。**
- **N=3，不做統計顯著性宣稱。**
- 概念數與重疊率是**代理指標**（抽反引號識別字與檔名、去前綴轉小寫後比對集合），**不是真正語意比對**；不代表少講的正好是 base 講過的那 18 個。
- 事實抽查約 25 處（四組全命中、無捏造），但**非全文查證**。
- **評分由本次實驗的執行者自評。**

---

## 2026-08-05 · backend 索引能力：真值裁判對決

<a href="https://vagrantpi.github.io/PKM/static/skill-eval/2026-08-05-codegraph-vs-codebase-memory/" target="_blank" rel="noopener"><strong>開啟完整報告 ↗</strong></a>

**受測**：[[moc/AI技能收藏#codegraph|codegraph]]・**codebase-memory-pro**（報告用 pro 版，收藏頁記的是 [[moc/AI技能收藏#codebase-memory-mcp|codebase-memory-mcp]]）　**標的**：`ai_family_backend`（backend＋frontend，排除 `node_modules`）　**方法**：四維度各 0–10 分；**每處差異都用 `grep` 對過真值**

**一句話結論**：不是誰比較好，是**哪件事用哪個**。總分 codebase-memory-pro 34／codegraph 29，但真正該記的是分工：**分析引擎勝在度量，閱讀引擎勝在追蹤。**

**關鍵證據：caller 完整性**

| 符號 | 真值 | codebase-memory | codegraph |
|---|---|---|---|
| `handleUserText` callers | 2 | **2/2** | 1/2（漏巢狀 async fn） |
| `assertWithinQuota` callers | 5 | **5/5** | 3/5（漏巢狀 async fn 與一個普通 class method） |

> ⚠️ **2026-10-18 重現不出來**：使用者確認的「pro」就是本機 7 月 5 日編譯的 codebase-memory-mcp dev build。拿它在 a6fb1d3e 重建索引（10-17 報告記為與 8 月同一個 commit；8 月報告本身沒記 commit），`assertWithinQuota`、`handleUserText` 的 caller 都是 **0**，節點數也不同（16,090 對 17,187）。這兩行的 codebase-memory 數字可能來自另一個 build，原因未查證。codegraph 那欄在 10-17 也重現不出來（重測是全中）。

codegraph 漏的都是**巢狀函式與 singleton 實例方法**；codebase-memory 的 type-aware LSP 全中 → **影響分析（誰呼叫我）用 codebase-memory**。反過來**讀流程用 codegraph**：trace 回傳整條路徑並 **inline 每一跳源碼**，codebase-memory 只給名稱清單、無 body。

**只有一邊做得到**：任意 Cypher 查詢、複雜度／效能指標（跨程序 `transitive_loop_depth`）、語意向量搜尋、co-change 耦合、Leiden 社群偵測——這幾件 codegraph **完全沒有對應能力**。

**⚠️ 共同盲點（報告明確標出）**：**介面多型 dispatch 兩邊都會錯**。`this.transport.isOpen()` 這類介面型別方法呼叫，兩者都會把 callee 誤指到 mock 或同名前端實作——涉及介面多型的調用邊，**任一工具的結果都要用 `grep` 收尾複核**。

**⚠️ 限制（我的自註，非報告原文）**：報告本身沒附「條件與限制」段，以下我自己標——
- **單一 repo、N=1**，沒有重複執行，也沒有雜訊底線可比。
- 節點數差異（12,509 vs 17,187）是**建模哲學不同**（codegraph 把 import／constant／enum_member 也物化成節點），**不是覆蓋率高低**。
- **冷啟索引只有 codebase-memory 實測 9s，codegraph 未重測**——那一維的 8 vs 7 沒有對等實測基礎。
- 受測的是 **codebase-memory-pro**，與收藏頁的開源版是否同一功能集未查證。
- ⚠️ **2026-10-17 重測推翻了「codegraph 漏 caller」這一條**：同 commit、同兩個符號，codegraph 2/2、5/5 全中（見下一份報告）。

---

## 2026-10-17 · 給人看的地圖 vs 給 agent 查的索引

<a href="https://vagrantpi.github.io/PKM/static/skill-eval/2026-10-17-understand-anything-vs-codegraph/" target="_blank" rel="noopener"><strong>開啟完整報告 ↗</strong></a>

**受測**：[[moc/AI技能收藏#understand-anything|Understand-Anything]] 2.9.7・[[moc/AI技能收藏#codegraph|codegraph]] CLI 1.4.1
**標的**：`ai_family_backend` 的 `backend/src/services`（232 個 TS 檔，commit 同 8 月）
**方法**：
- 沿用 8 月的 grep 真值。
- 另外加測三項：抽 30 條邊驗精確度、同一批重跑看重現性、兩邊各答一次同一題流程解說。

**一句話結論**：兩者不是同一類工具。**Understand-Anything 是給人看的地圖，codegraph 是給 agent 查的索引。**

**關鍵證據**

| 發現 | 數字 | 為什麼可信 |
|---|---|---|
| 建圖成本差四個數量級以上 | UA 約 156 萬 token、10 分鐘；codegraph 1.7 秒、0 token | 同範圍同 commit，UA 用的是正確設定那一輪 |
| UA 答不了方法層級的問題 | 問「誰呼叫 `assertWithinQuota`」：UA 漏 1 個、多 2 個假陽性；codegraph 5/5 | UA 只有 class 層級的 `calls` 邊，每處都用 grep 對到外層函式 |
| LLM 建的邊不會捏造，但會漏、會飄 | 抽樣精確度兩邊都 30/30（⚠️ codegraph 這格已被再驗證推翻，見 10-18 跨 repo 報告）；UA 同批重跑，`calls` 邊 Jaccard 0.79 | 抽樣用固定 seed；重跑時節點與 imports 完全相同，只有 LLM 寫的 `calls` 邊會變 |
| 給新人看懂，兩邊一樣準 | 事實抽查都 10/10，答一題都花約 8 萬 token | UA 的導覽與分層讓答案涵蓋面較廣，codegraph 在單一路徑上答得更深 |
| 8 月的「codegraph 漏巢狀 caller」重現不出來 | 新、舊兩份索引都是 2/2、5/5 | 舊索引是 7/18 建在原 repo 的那份副本 |

**踩到的坑**：第一次把 `services/` 當專案根直接跑。`tsconfig` 落在範圍外，`@/` 別名解析不了，import 邊只剩 128 條，正確應該是 278 條，跨檔呼叫跟著被丟掉，而且不會報錯。這一輪約 89 萬 token 全部作廢。**縮小範圍時，專案根要包含 tsconfig，再用 `--exclude` 排除。**

**怎麼用**
1. **agent 改 code、做影響分析** → codegraph：方法層級、結果確定、幾乎免費。
2. **很多人會反覆問「這專案在幹嘛」的 repo** → Understand-Anything：建圖那筆錢分攤得掉，分層和導覽才划算。
3. **不要**拿 Understand-Anything 回答「誰呼叫這個方法」。
4. 介面型別的 dispatch 兩邊都解不出來，仍要用 grep 收尾。

**⚠️ 限制（報告照抄）**
- **N=1**：只有 voice-call 那一批重跑過一次，不做統計顯著性宣稱。
- **範圍只有 services/**，範圍外的 caller 兩邊都看不到。
- **顆粒度不同**：第 ② 維本質上是拿 UA 回答它不擅長的問題。
- **UA 管線是手動照 SKILL.md 編排的**，有三處偏離：
  - 批次參數用檔案傳。
  - 第二輪的 scan 由腳本組出。
  - 跳過 fingerprint。
  
  跟一鍵跑 `/understand` 的結果可能有差。
- **評分由本次實驗的執行者自評**；第 ⑤ 維只抽查 10 條事實，兩份答案的差距在雜訊內。
- 8 月結果重現不出來的**原因未查證**。

---

## 2026-10-17 · 程式碼圖譜四方評比：寫法決定一切

<a href="https://vagrantpi.github.io/PKM/static/skill-eval/2026-10-17-code-graph-four-way/" target="_blank" rel="noopener"><strong>開啟完整報告 ↗</strong></a>

**受測**：
- [[moc/AI技能收藏#codegraph|codegraph]] CLI 1.4.1
- [[moc/AI技能收藏#gitnexus|GitNexus]] 1.6.12（`--index-only`）
- [[moc/AI技能收藏#graphify|graphify]] 0.9.92（`--code-only`）
- [[moc/AI技能收藏#understand-anything|Understand-Anything]] 2.9.7（沿用上一份）

**標的**：同上一份，`backend/src/services` 加上 tsconfig，四個工具吃同一份碼。

**方法**：
- 沿用 grep 真值。
- 新增「隨機抽 30 個跨檔 singleton 呼叫點」的召回率測試，以及 3 檔的最小重現。
- 抽 30 條邊驗精確度、重建一次比對邊。
- 四個工具各答一次同一題流程解說。

**一句話結論**：**先看你的 codebase 怎麼寫，再挑程式碼圖譜。** 三個確定性工具的重現性都滿分，但各有解析不了的呼叫寫法（⚠️ 原本寫「精確度也滿分」，已被再驗證推翻：codegraph 1.4.1 只有 76%，見 10-18 跨 repo 報告）。這個 codebase 大量用 `export default new XService()`，GitNexus 和 graphify 因此幾乎看不到跨 service 的呼叫。

**關鍵證據**

| 發現 | 數字 | 為什麼可信 |
|---|---|---|
| singleton 跨檔呼叫的召回率天差地別 | codegraph 30/30、UA 24/30（class 層級）、GitNexus 0/30、graphify 0/30 | 從 265 個不重複的真實呼叫點隨機抽 30 個（seed 7），逐一查各工具的邊 |
| 盲點各不相同 | default 實例只有 codegraph 抓得到；具名 `export const` 實例只有 GitNexus 抓得到（⚠️ 只限 codegraph 1.4.1，1.6.2 已修）；一般函式三個都抓得到 | 3 檔的最小重現，排除 codebase 其他因素 |
| 確定性工具不飄（⚠️「不捏造」已被推翻） | 原本精確度三個都 30/30，但判定只看名稱，太鬆；嚴格判定後 codegraph 76%（跨檔 60%）、GitNexus 99%、graphify 87%。重建後的邊 Jaccard 都是 1.0（成立） | 固定 seed 抽樣；graphify 的 28 條 INFERRED 逐條人工看過 |
| 解說題四份都 10/10，差在成本 | GitNexus 11.2 萬 token、17 次工具呼叫最貴；其他三個 7.8–8.5 萬 | 工具查不到的關係由答題 agent 讀碼補上，準確度被補平，代價轉成成本 |
| `handleUserText` 的 caller 名稱 | GitNexus 最精確（寫到巢狀的 `onMessage@179`） | 跟真值的外層函式逐一對照 |

**怎麼用**
1. **第 0 步每次都做**：用自己 codebase 最常見的 2–3 種呼叫寫法做 3 檔最小重現，看各工具能不能建出邊。
2. 影響分析用寫法沒撞到盲點的那個確定性工具。這個 codebase 是 codegraph。
3. GitNexus 的 `impact` 查不到時會回 `risk: UNKNOWN`，**這時要用 grep 確認**，不要當成沒人呼叫。
4. graphify 的強項是文件也能進圖；純程式碼時要先驗跨檔召回率。

**⚠️ 限制（報告照抄）**
- **單一 codebase、單一範圍**，結論高度依賴這個 codebase 的寫法；最小重現只測了 3 種寫法。
- **N=1**：每個工具只答一次解說題，重現性也只做一次重建。
- **graphify 只測 `--code-only`**，語意抽取沒測。
- **GitNexus 用 `--index-only`**：沒有 embedding，全文搜尋也沒裝起來，MCP 工具沒測，查詢能力可能被低估。授權是 PolyForm Noncommercial，用在公司程式碼上是否構成商業使用由使用者自行判斷。
- **評分由本次實驗執行者自評**；事實抽查每份只有 10 條。

---

## 2026-10-18 · 跨 repo（TS ↔ Go）：四個工具都連不上

<a href="https://vagrantpi.github.io/PKM/static/skill-eval/2026-10-18-cross-repo/" target="_blank" rel="noopener"><strong>開啟完整報告 ↗</strong></a>

**受測**：
- [[moc/AI技能收藏#codebase-memory-mcp|codebase-memory]]（本機 dev build）
- [[moc/AI技能收藏#codegraph|codegraph]] 1.4.1（repo 內另測 1.6.2）
- [[moc/AI技能收藏#gitnexus|GitNexus]] 1.6.12
- [[moc/AI技能收藏#graphify|graphify]] 0.9.92
- 只用 grep 的基線

**標的**：一組真實的 TS backend ↔ Go 服務，兩邊都用量測當時工作分支的 HEAD，完整範圍。兩邊之間有 75 個 HTTP 端點和 1 條 gRPC。

**方法**：由多個 subagent 分工：
- 串接盤點，當作真值。
- 跨 repo 機制實驗。
- repo 內再驗證，用 TS type checker 當真值。
- 文件研究。
- 5 組實戰題，每組 5 題。

最後由對抗式驗證逐條核對。

**一句話結論**：**跨 repo 的呼叫，四個工具自動連上的都是 0 條；5 題實戰題，各組都靠 grep 完成跨 repo 的銜接。** 工具的差異在 repo 內，那裡 codegraph 1.6.2 明顯領先。

**關鍵證據**

| 發現 | 數字 | 為什麼可信 |
|---|---|---|
| 跨 repo 自動連結全部是 0 | HTTP 0/75、gRPC 0/1。codebase-memory 跑完 cross-repo pass 產生 136 條，**全錯**；GitNexus 2 條全錯；graphify 0 條；codegraph 沒有這個功能 | 真值由腳本產生、逐條驗證；codebase-memory 認不得 Go 1.22 的 `mux.Handle("POST /path")` 和純字串 URL（讀過原始碼確認），GitNexus 推測是同一個原因 |
| 實戰題各組幾乎全對，token 相對 grep 基線 −5%～+24% | grep 16.2 萬、codegraph 15.5 萬、graphify 15.5 萬、GitNexus 17.8 萬、codebase-memory 20.1 萬 token；codebase-memory 組 Q5a 只有 5/7 | 每一組都說跨 repo 的部分是靠 grep |
| repo 內呼叫圖 codegraph 1.6.2 最好 | TS 跨檔召回／精確度：codegraph 1.6.2 97%／81%、1.4.1 91%／64%、codebase-memory 25%／83%、GitNexus 34%／97%、graphify 22%／98% | type checker 真值，跨檔 1,395 個呼叫點，嚴格判定 |
| Go 服務 route → handler | codegraph 53/130，其他工具都是 0 | 對照 `cfg.X.Method` 的定義 |
| 8 月「codebase-memory caller 5/5」重現不出來 | 同一個 build，在 a6fb1d3e（10-17 報告記為與 8 月同一個 commit）重測是 0/5 | 見上一段的 8 月報告加註 |

**怎麼用**
1. repo 內導航用 codegraph 1.6.2。caller 只當候選，常見方法名要用 grep 篩；Go 的 router 直接讀原始碼。
2. 跨 repo 用腳本產生合約表，在 CI 雙向檢查（含 SSE 事件名稱），再讓 agent 先查表。
3. codebase-memory 這個 build 不建議導入：TS 漏抓嚴重、每次 session 都會連 GitHub、UI 沒有驗證。等它出簽章過的 release、並支援 Go 1.22 路由後再重評。

選型建議（脫敏的團隊版：導入步驟、合約表做法、試點與退場條件）→ [[程式碼圖譜工具選型（跨 repo 實測後的建議）]]

**⚠️ 限制（報告照抄）**
- **只測一組 repo**：命名規律、URL 多寫成字面值，對 grep 有利。
- **N=1**：每組只答一次，由主線依真值自評；真值在實驗中修正過兩次。
- 版本限制：codebase-memory 測的是 7 月 5 日的 dev build；codegraph 1.6.2 只測過 repo 內的 TS；GitNexus 用 `--index-only`；graphify 只測 `--code-only`。
- codebase-memory 組作答時，同一個 store 正在跑 cross-repo pass，不過那些連結全錯，不影響結論。
- 這份取代已下架的 10-17 跨 repo 報告。

---

## 🔗 相關
- 工具本身怎麼裝、做什麼 → [[moc/AI技能收藏|AI 技能收藏]]
- 這套對照評測的方法論 → [[如何評測一個 Claude Code Skill]]（為什麼「只評第一次」是限制，理由在這篇）
- 報告原始檔存在 Quartz 專案的 `quartz/static/skill-eval/` 下（有進版控）；vault 的 `sync.sh` 只搬 `.md` 與 `.canvas`，HTML 無法從 vault 同步
