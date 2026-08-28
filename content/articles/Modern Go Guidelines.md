---
type: article
title: "Modern Go Guidelines"
source_url: https://github.com/JetBrains/go-modern-guidelines
author: JetBrains
site: GitHub
tags: [ai, llm, go, tooling, skill]
captured: 2026-08-28
read_status: read
---

## 📌 30 秒摘要（讀完用自己的話寫一句）
> 這篇在講：JetBrains 出的 agent plugin，塞給 coding agent 一份「**現代 Go 寫法對照表**」，讓它別再產出過時的 Go。真正值得記的是它的**動機分析**——它指名了 coding agent 產出過時程式碼的**兩個不同原因**，其中第二個（**頻率偏誤**）是所有語言、所有 agent 共通的問題，跟 Go 無關。

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- 「模型知道某個 API ≠ 它會用」這個洞察，我可以套到任何快速演進的技術棧上。
- 高影響那幾條（`slices.Contains`／`for i := range n`／`errors.Is`／`cmp.Or`）是 **code review 時人眼該認得的**——就算不裝 plugin，知道這幾條也有用。
- 這是我知識庫裡**第一份 Go 相關筆記**。

## 🧰 這篇給我的工具（連到 tools/ 工具卡）
- [[工具-讓agent別寫出過時的程式碼]] — 當我發現「AI 寫出來的是三年前的寫法」的時候

## ✨ 關鍵重點

### 1. ⭐ 它指名了兩個不同的失敗原因——而且解法不同
> **Training data lag.** Models don't know about features added after their training cutoff.
> **Frequency bias.** Even for features the model knows, it often picks older patterns. There's more `for i := 0; i < n; i++` in the training data than `for i := range n`, so that's what comes out.

**我的補註**：第二個才是真正麻煩的。訓練資料落後可以靠「餵它新文件」解決；但**頻率偏誤不會因為模型知道新寫法就消失**——它的輸出跟隨訓練語料的**分布**，不是新穎度或品質。所以光說「請用最新的寫法」沒用，**要給它明確的對照表**。

### 2. 它會先偵測專案的 Go 版本
從 `go.mod` 讀出版本，只用**到該版本為止**可用的特性。這點很重要——否則就是把編不過的程式碼塞給你。

### 3. 涵蓋 Go 1.0 → 1.27，對齊官方 `modernize` analyzer
定位講得很清楚：官方的 `modernize` analyzer 是**把既有程式碼自動更新**成新慣用法；這份 guidelines 是讓 agent **一開始就寫對**，減少之後要修的量。

### 4. 高影響條目速查（Critical／High，共 38 條中的一部分）

**Critical（幾乎每個專案都有、數十處）**
| 診斷 | Go | 舊寫法 → 新寫法 |
|---|---|---|
| `slicescontains` | 1.21 | 手寫搜尋迴圈 → `slices.Contains(s, needle)` |
| `rangeint` | 1.22 | `for i := 0; i < n; i++` → `for i := range n` |
| `efaceany` | 1.18 | `interface{}` → `any` |
| `erris` | 1.13 | `err == os.ErrNotExist` → `errors.Is(err, os.ErrNotExist)`<br>`err.(*os.PathError)` → `errors.As(err, &e)` |

**High（常見、每專案 5–20 處）**
| 診斷 | Go | 舊寫法 → 新寫法 |
|---|---|---|
| `cmpor` | 1.22 | 一串 `if x == "" { x = ... }` → `cmp.Or(a, b, "default")` |
| `minmax` | 1.21 | `if a < b {...} else {...}` → `min(a, b)` / `max(a, b)` |
| `sortslice` | 1.21 | `sort.Slice` → `slices.SortFunc` ＋ `cmp.Compare` |
| `forvar` | 1.22 | 迴圈裡的 `v := v` → **不再需要**（1.22 改了迴圈變數語義） |
| `errorsjoin` | 1.20 | `fmt.Errorf("multiple: %v", errs)` → `errors.Join(errs...)`（可被 `errors.Is`/`As` 穿透） |
| `stringsseq` | 1.24 | `range strings.Split(...)` → `range strings.SplitSeq(...)`（省掉中間 slice 配置） |
| `stringscutprefix` | 1.20 | `HasPrefix` ＋ `TrimPrefix` → `strings.CutPrefix` |
| `waitgroup` | 1.25 | `wg.Add(1)` ＋ `go func(){ defer wg.Done() ... }` → `wg.Go(func(){...})` |
| `testingcontext` | 1.24 | `context.WithCancel` → `t.Context()` |
| `mapkeysvalues` | 1.23 | 手動蒐集 → `maps.Keys` / `maps.Values` |
| `timesince` | 1.0 | `time.Now().Sub(t)` → `time.Since(t)` |
| `newliteral` | **1.26** | `x := 42; p := &x` → `p := new(42)`（任何型別都適用） |

其餘 Medium／Low 條目涵蓋 `clear()`、`maps.Clone`、`slices.Reverse`、`context.WithCancelCause`、`sync.OnceValue`、`atomic.Pointer[T]`、`fmt.Appendf`、`b.Loop()`、`omitzero`、`http.ServeMux` 新路由語法等。

**注意**：`FEATURES.md` 開頭自標 **“Work in progress — inconsistencies may be present.”**

### 5. 一個值得學的安全設計
README 明說：`scripts/dev-install.sh` **刻意與 agent 面對的 wrapper 分開，好讓 agent 永遠無法觸發建置**。
**我的補註**：這跟 [[工具-防止agent造假通過驗收]] 的第 5 點是同一個心法——**能造成危害的路徑，就從結構上讓 agent 碰不到**，而不是靠指令叫它別做。

## 💬 原文摘錄
- 兩個失敗原因（本篇最值得記的一段）：
  > "Training data lag. Models don't know about features added after their training cutoff. They can't use `errors.AsType[T]` (Go 1.26) if they've never seen it."
  > "Frequency bias. Even for features the model knows, it often picks older patterns. There's more `for i := 0; i < n; i++` in the training data than `for i := range n`, so that's what comes out."
- 與官方工具的分工：
  > "The `modernize` analyzer exists to automatically update existing code to use newer idioms. These guidelines serve the same goal for new code: agents write modern Go from the start, so there's less to fix later."
- 安全邊界：
  > "`scripts/dev-install.sh`, which is intentionally separate from the agent-facing wrapper so an agent can never trigger a build."

## 🔗 相關
- [[Effective Go]] — **搭配看**：那篇講「Go 為什麼長這樣」（心智模型，變得慢），這篇講「現在該怎麼寫」（語法與 API，變得快）。那篇的 Errors 章教的 type switch 辨識錯誤，正是這裡標為 Critical 的 `erris` 要換掉的寫法
- [[moc/AI技能收藏#go-modern-guidelines|收藏頁的卡]] — 四個平台的安裝指令速查
