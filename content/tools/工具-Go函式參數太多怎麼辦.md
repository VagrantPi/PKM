---
type: tool
name: "Go 函式參數太多怎麼辦"
source: "[[Google Go 風格指南]]"
source_type: article
tags: [software, go, design, api]
triggers: [Go函式的參數越加越多, 呼叫端一排true false看不懂在幹嘛, 想加新設定又不想改所有呼叫端, functional options值不值得, 相鄰的同型別參數很容易傳反]
---

## 🎯 什麼情境該想到我
當函式簽章長到一行放不下，或呼叫端出現 `Do(ctx, cfg, a, b, true, false, time.Hour, 100, w)` 這種**看不出哪個是哪個**的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 0. 先問：是不是該拆成好幾個函式？
在跳到 options 之前，原文的第一建議是：**把一個高度可設定、簽章不斷膨脹的函式，拆成數個比較簡單的函式**，必要時共用一個未匯出的實作。

```go
// Bad
func EnableReplication(ctx context.Context, config *replicator.Config,
    primaryRegions, readonlyRegions []string, replicateExisting,
    overwritePolicies bool, replicationInterval time.Duration,
    copyWorkers int, healthWatcher health.Watcher) { ... }
```
問題有三個：參數一多，**每個參數的角色就變模糊**；**相鄰的同型別參數容易傳反**（上面有兩個 `[]string` 和兩個 `bool` 緊鄰）；呼叫端讀起來記不住。

### 1. Option struct：把參數收進一個結構，當最後一個參數傳
```go
// Good
type ReplicationOptions struct {
    Config              *replicator.Config
    PrimaryRegions      []string
    ReadonlyRegions     []string
    ReplicateExisting   bool
    OverwritePolicies   bool
    ReplicationInterval time.Duration
    CopyWorkers         int
    HealthWatcher       health.Watcher
}

func EnableReplication(ctx context.Context, opts ReplicationOptions) { ... }
```
```go
// 複雜的呼叫
storage.EnableReplication(ctx, storage.ReplicationOptions{
    Config:              config,
    PrimaryRegions:      []string{"us-east1", "us-central2"},
    OverwritePolicies:   true,
    ReplicationInterval: 1 * time.Hour,
    CopyWorkers:         100,
})

// 簡單的呼叫
storage.EnableReplication(ctx, storage.ReplicationOptions{
    Config:         config,
    PrimaryRegions: []string{"us-east1", "us-central2"},
})
```
好處：欄位名讓呼叫端**自我說明且難以傳反**；不相關的欄位可以直接省略；呼叫端可以共用同一份 options 並寫 helper 去加工；godoc 上每個欄位有自己的說明；**之後加欄位不影響現有呼叫端**。

⚠️ **`context.Context` 永遠不放進 option struct**，它仍然是第一個參數。
⚠️ struct 只在被匯出的函式使用時才匯出。

**什麼時候選它**：
- 大部分呼叫端**都得指定**一個以上的選項。
- 很多呼叫端要指定很多選項。
- 這組選項會被**多個函式共用**。

### 2. Variadic options：匯出一組回傳 closure 的函式
```go
// Good
type replicationOptions struct {   // 未匯出
    readonlyCells       []string
    replicateExisting   bool
    replicationInterval time.Duration
    copyWorkers         int
}

// A ReplicationOption configures EnableReplication.
type ReplicationOption func(*replicationOptions)

// ReadonlyCells adds additional cells that should additionally
// contain read-only replicas of the data.
//
// Passing this option multiple times will add additional read-only cells.
//
// Default: none
func ReadonlyCells(cells ...string) ReplicationOption {
    return func(opts *replicationOptions) {
        opts.readonlyCells = append(opts.readonlyCells, cells...)
    }
}

var DefaultReplicationOptions = []ReplicationOption{
    OverwritePolicies(true),
    ReplicationInterval(12 * time.Hour),
    CopyWorkers(10),
}

func EnableReplication(ctx context.Context, config *placer.Config,
    primaryCells []string, opts ...ReplicationOption) {
    var options replicationOptions
    for _, opt := range DefaultReplicationOptions { opt(&options) }
    for _, opt := range opts { opt(&options) }
}
```
```go
// 簡單的呼叫：完全不佔版面
storage.EnableReplication(ctx, config, []string{"po", "is", "ea"})
```
好處：**不需要設定時，呼叫端一個字都不用寫**；選項仍是值，可以共用、累積、寫 helper；一個選項可以吃多個參數（`cartesian.Translate(dx, dy int) TransformOption`）；有具名型別可以在 godoc 裡聚成一組；可以選擇**讓或不讓**第三方套件定義自己的選項（靠參數型別未匯出來控制）。

**什麼時候選它**（原文說「多數條件成立時」）：
- 大部分呼叫端**不需要**指定任何選項。
- 多數選項很少被用到。
- 選項數量很多。
- 選項需要帶參數。
- 選項可能**失敗或被設錯**（這時 option function 可以回傳 error）。
- 選項需要大量文件，塞在 struct 欄位註解裡會很擠。
- 想讓使用者或其他套件提供自訂選項。

### 3. ⭐ 兩條容易踩的 variadic options 設計規則
**（1）選項要吃參數，不要用「有沒有傳」來表達值。**
```go
rpc.FailFast(enable bool)   // ✅
rpc.EnableFailFast()        // ❌

log.Format(log.Capacitor)   // ✅
log.CapacitorFormat()       // ❌
```
理由很實際：如果使用者要**動態決定**要不要開某個選項，前者只要改參數，後者得去改「要組哪幾個參數」的結構。不要假設所有使用者都在編譯期就知道完整的選項集合。

**（2）依序處理，後者覆蓋前者。** 有衝突、或非累加型的選項被傳多次時，**最後一個贏**。而且每個選項的文件要寫清楚它是累加（`Passing this option multiple times will add additional...`）還是覆蓋（`Passing this option again will overwrite earlier values.`），以及 `Default:` 是什麼。

### 4. 選哪一個：看呼叫端長什麼樣
原文給的首要判準是——**在所有預期的使用情境下，呼叫端讀起來像什麼？** 不是看實作端漂不漂亮。

粗略的分水嶺：**「大家都要設一堆」→ option struct；「大部分人什麼都不用設」→ variadic options。**

## 🧪 我實際套用的紀錄
- 2026-09-20：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **Variadic options 要寫的樣板碼很多**（看上面那段就知道）。原文明說「只有在好處蓋過這份開銷時才用」——這正是[[工具-Go可讀性五原則|最少機制]]原則的實例。
- **這些建議主要針對匯出的 API**，標準比未匯出的高。套件內部的函式多半不需要這些機制。
- **第一步永遠是「能不能拆函式」**，不是「用哪種 options」。
- Option struct 版本要注意零值即預設：欄位省略時拿到的是零值，如果某個選項的合理預設不是零值，就得在函式內部補，或改用 variadic options（它有明確的 `DefaultXxxOptions`）。

## 🔗 相關工具
- [[工具-Go可讀性五原則]] —— 「最少機制」正是判斷要不要上 variadic options 的依據
- [[工具-函式短小且單一職責]] —— 參數爆炸常常是職責過多的症狀，先治本
- [[工具-介面設計原則]] —— 同方向：API 要讓呼叫端難以用錯
