---
type: moc
title: "AI 技能評比"
tags: [moc, ai, skills, benchmark]
---

> 自己實際跑出來的 **skill 對照評比**報告。點連結會開啟原始報告網頁（完整排版與圖表）。
>
> ⚠️ **這頁只是索引，不轉寫內容。** 每份報告底下記的是「一句話結論」與「**報告自己標明的限制**」——後者照抄，不是我另外下的判斷。半年後回頭看時，先讀限制再讀結論。
>
> 工具本身的介紹在 [[moc/AI技能收藏|AI 技能收藏]]。

## 📇 報告清單

| 日期 | 題目 | 受測對象 | 開啟 |
|---|---|---|---|
| 2026-08-05 | 任務系統解說題：四組對照評分 | base・ponytail・i-have-adhd・兩個同開 | [報告 ↗](https://vagrantpi.github.io/PKM/static/skill-eval/2026-08-05-ponytail-vs-i-have-adhd/) |
| 2026-08-05 | backend 索引能力：真值裁判對決 | codegraph・codebase-memory-pro | [報告 ↗](https://vagrantpi.github.io/PKM/static/skill-eval/2026-08-05-codegraph-vs-codebase-memory/) |

---

## 2026-08-05 ・ 任務系統解說題：四組對照評分

<a href="https://vagrantpi.github.io/PKM/static/skill-eval/2026-08-05-ponytail-vs-i-have-adhd/" target="_blank" rel="noopener"><strong>開啟完整報告 ↗</strong></a>

**受測對象**：`base`（無客製化）・[ponytail](https://vagrantpi.github.io/PKM/moc/ai%E6%8A%80%E8%83%BD%E6%94%B6%E8%97%8F#ponytail)・[i-have-adhd](https://vagrantpi.github.io/PKM/moc/ai%E6%8A%80%E8%83%BD%E6%94%B6%E8%97%8F#i-have-adhd)・兩個同開
**設定**：`claude-opus-5`、`claude -p` headless、基線 `--safe-mode`、工具只給 Read／Grep／Glob、四組交錯執行各 3 次（12 次全數有效）
**題目**：「幫我解說這個專案的任務系統設計」

### 一句話結論

**四組都寫得很好，base 沒有比較差。** 開 skill 之後答案真的變短了——但短在**少講了三分之一的概念**，不是少講廢話。

### 三個站得住的數字

| 發現 | 數字 | 為什麼可信 |
|---|---|---|
| 概念覆蓋變少 | ponytail −31%、i-have-adhd −17%、兩個同開 −33% | base 自己跑三次的全距只有 9 個概念，−18／−19 是這條雜訊線的**兩倍** |
| 內容沒有換方向 | 組內概念重疊 42.7%、跨組 38.9% | 兩者幾乎一樣 → 是**從同一個概念池裡挑得更少**，不是挑了不同的東西 |
| **token 沒省到** | 四組差距最大 864，base 自己三次就差 2,348 | token 大宗是 26–29 輪工具呼叫的推理，不是最終答案 |

還有一個反直覺的：**兩個同開不是相加**（−31% ＋ −17% 應該接近 −48%，實際是 −33%），壓縮由 ponytail 主導、adhd 的效果被吸收。但兩個同開是**四組裡最穩的**，三次概念數全距只有 5（base 9、adhd 11、ponytail 17）。

### 怎麼用（報告的四條建議）

1. **想要完整就別開**——base 的完整度與資訊密度都是最高分，研究沒碰過的模組時，多出來的 18 個知識點值得那 1,600 字。
2. **想要快速掌握輪廓就開 ponytail** 或兩個同開，少三分之一概念換短四分之一篇幅，骨架不會少。
3. **要可預期的產出就兩個同開。**
4. **別為了省 token 開任何一個**——三輪實驗都在雜訊裡。真要省該往 rtk、[codegraph](https://vagrantpi.github.io/PKM/moc/ai%E6%8A%80%E8%83%BD%E6%94%B6%E8%97%8F#codegraph)、subagent 隔離去找。

### ⚠️ 報告自己標明的限制（照抄）

- **評分只評了每組第一次**，沒有雜訊底線可比，**排序不可靠**——同一組跑三次，答案長度能差 30%、概念數能差 17 個，單次判讀的變異很可能大於 47 與 55 的差距。**別拿那張評分表做決定。**
- **N=3，不做統計顯著性宣稱。**
- 概念數與重疊率是**代理指標**：抽反引號識別字與檔名、去前綴轉小寫後比對集合，**不是真正的語意比對**。概念數是計數比較不是集合比較——不代表少講的正好是 base 講過的那 18 個。
- 事實抽查約 25 處（四組全部命中、無捏造），但**非全文查證**。
- **評分由本次實驗的執行者自評。**

---

## 2026-08-05 ・ backend 索引能力：真值裁判對決

<a href="https://vagrantpi.github.io/PKM/static/skill-eval/2026-08-05-codegraph-vs-codebase-memory/" target="_blank" rel="noopener"><strong>開啟完整報告 ↗</strong></a>

**受測對象**：[codegraph](https://vagrantpi.github.io/PKM/moc/ai%E6%8A%80%E8%83%BD%E6%94%B6%E8%97%8F#codegraph)・**codebase-memory-pro**（報告用的是 pro 版，收藏頁記的是 [codebase-memory-mcp](https://vagrantpi.github.io/PKM/moc/ai%E6%8A%80%E8%83%BD%E6%94%B6%E8%97%8F#codebase-memory-mcp)）
**標的**：`ai_family_backend`（backend ＋ frontend，排除 `node_modules`）
**方法**：四個維度各 0–10 分；**每一處差異都用 `grep` 對過真值**

### 一句話結論

**不是誰比較好，是哪件事用哪個。** 總分 codebase-memory-pro 34 ／ codegraph 29，但真正該記的是分工：**分析引擎勝在度量，閱讀引擎勝在追蹤。**

### 決定性證據：caller 完整性

| 符號 | 真值 | codebase-memory | codegraph |
|---|---|---|---|
| `handleUserText` 的 callers | 2 | **2/2** | 1/2（漏巢狀 async fn） |
| `assertWithinQuota` 的 callers | 5 | **5/5** | 3/5（漏巢狀 async fn 與一個普通 class method） |

codegraph 漏掉的都是**巢狀函式與 singleton 實例方法**；codebase-memory 的 type-aware LSP 在這兩種情況全中。**要做影響分析（誰呼叫我）就用 codebase-memory。**

反過來，**讀流程用 codegraph**：它的 trace 回傳整條路徑並 **inline 每一跳的原始碼**，`context` / `explore` 一次取多個符號的源碼，搜尋直接帶型別簽章；codebase-memory 只給名稱清單、沒有 body。

### 只有一邊做得到的能力

**只有 codebase-memory 有**：任意 Cypher 查詢、複雜度／效能指標（跨程序 `transitive_loop_depth`）、語意向量搜尋、co-change 耦合（`FILE_CHANGES_WITH`）、Leiden 社群偵測。這幾件事 codegraph **完全沒有對應能力**。

### ⚠️ 共同盲點（報告明確標出）

**介面多型 dispatch 兩邊都會錯。** `this.transport.isOpen()` 這類介面型別的方法呼叫，兩者都會把 callee 誤指到 mock 或同名的前端實作——只是猜錯的對象不同。**涉及介面多型的調用邊，任一工具的 callee 結果都要用 grep 收尾複核。**

### ⚠️ 讀這份時要留意的（我的註記，非報告原文）

報告本身**沒有像第一份那樣附「條件與限制」段落**，所以以下是我自己標的：

- **單一 repo、N=1**，沒有重複執行，也沒有雜訊底線可比。
- 節點數差異（12,509 vs 17,187）報告解釋為**建模哲學不同**（codegraph 把 import／constant／enum_member 也物化成節點），**不是覆蓋率高低**，別當成品質指標讀。
- **冷啟索引只有 codebase-memory 實測 9s，codegraph 標的是「未重測」**——索引速度那一維的 8 vs 7 沒有對等的實測基礎。
- 受測的是 **codebase-memory-pro**，與收藏頁記錄的開源 `codebase-memory-mcp` 是否同一套功能集，我沒有查證。

---

## 🔗 相關
- 工具本身怎麼裝、做什麼 → [[moc/AI技能收藏|AI 技能收藏]]
- 報告原始檔存在 Quartz 專案的 `quartz/static/skill-eval/` 下（有進版控）；vault 的 `sync.sh` 只搬 `.md` 與 `.canvas`，HTML 無法從 vault 同步
