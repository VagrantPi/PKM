---
type: tool
name: "select 超時與競速"
source: "[[Go Blog 經典六篇]]"
source_type: article
tags: [software, go, concurrency]
triggers: [要給操作加一個逾時, 想取最快回應的那一個, time.After會不會漏記憶體, select要怎麼動態關掉某個分支, 逾時該用select還是context]
---

## 🎯 什麼情境該想到我
當你要「**最多等 N 秒**」或「**同時問多個來源、只要最快回來的那一個**」的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 1. 逾時：`select` ＋ 一個會自己響的 channel
```go
select {
case v := <-ch:
    // 拿到值
case <-time.After(time.Second):
    // 逾時，放棄這次接收
}
```
`time.After` 回傳一個會在指定時間後送值的 channel。

### 2. ⭐ 但跨越 API 邊界時，正解是 `context`
來源文章寫於 2010 年、`context` 還不存在。今天的分工是：
- **函式內部的一次性等待** → `select` + `time.After` 就夠。
- **要能被呼叫端取消、要往下游傳遞、要設整體期限** → **用 `context.WithTimeout`**，把 `ctx` 當第一個參數傳下去。

### 3. 競速：向多個來源查詢，取最快的
```go
func Query(conns []Conn, query string) Result {
    ch := make(chan Result, len(conns))   // ⭐ 緩衝是關鍵
    for _, conn := range conns {
        go func(c Conn) { ch <- c.DoQuery(query) }(conn)
    }
    return <-ch
}
```
**為什麼一定要有緩衝**：主函式只收一個值就走了，剩下的 goroutine 還想送。若 channel 無緩衝，它們會**永遠卡在送出那一行**——goroutine 洩漏。
給足 `len(conns)` 的緩衝，每個 goroutine 都送得出去然後正常結束，沒被讀走的值交給 GC。

**原文用的是「非阻塞送出（`select` + `default`）」加緩衝**，並自己點出：如果結果比主函式抵達接收點更早到，非阻塞送出會失敗——**修法就是把 channel 開緩衝**。

### 4. ★ `time.After` 的記憶體問題已經在 Go 1.23 修掉了（2026-09-21 查證）

**過去的標準建議是「在迴圈裡不要用 `time.After`，要用 `NewTimer` + `Stop`」。這個建議現在過時了。**

官方文件（`pkg.go.dev/time#After`）現在寫：
> *"Before Go 1.23, this documentation warned that the underlying Timer would not be recovered by the garbage collector until the timer fired... **As of Go 1.23, the garbage collector can recover unreferenced, unstopped timers.** There is no reason to prefer NewTimer when After will do."*

★ **所以在 Go 1.23+ 上，`select` 裡直接用 `time.After` 是正確且推薦的。**
（但如果你的 `go.mod` 還在 1.22 以下，舊建議仍然適用。）

### 5. ★ 三個 `select` 的實用技巧

**① nil channel 動態關掉分支**
```go
var tick <-chan time.Time          // ★ nil：這個 case 永遠不會被選中
if enabled {
    t := time.NewTicker(time.Second)
    defer t.Stop()
    tick = t.C
}
for {
    select {
    case <-tick:                   // ★ enabled 為 false 時自動「消失」
        doPeriodic()
    case <-ctx.Done():
        return
    }
}
```
**比 `if enabled { ... }` 包在外面乾淨得多**，也避免了兩份幾乎一樣的迴圈。

**② `default` 做非阻塞操作**
```go
select {
case ch <- v:
    // 送出去了
default:
    // ★ 滿了就丟棄（或記一筆 metric）—— 不阻塞發布者
}
```
→ **這是背壓的取捨點**：丟棄 vs 阻塞，沒有第三種選擇（見 [[觀察者模式]]）。

**③ `select {}` 永久阻塞**
`select{}`（沒有任何 case）會永遠阻塞當前 goroutine。偶爾用在 `main` 的結尾讓服務不退出——
**但更好的做法是等一個 signal channel，才能優雅關閉。**

### 6. ★ 逾時的完整決策表

| 情境 | 用什麼 |
|---|---|
| 函式內部的一次性等待 | `select` + `time.After` |
| **★ 跨 API 邊界、要能被上游取消** | **`context.WithTimeout` / `WithCancel`，`ctx` 當第一個參數** |
| 整個請求的總期限 | `context.WithDeadline`（★ **deadline 會沿著呼叫鏈往下傳**） |
| HTTP client | `http.Client{Timeout: ...}` **或** `req.WithContext(ctx)` |
| 逾時後要做收尾動作 | ★ **`context.AfterFunc(ctx, f)`**（Go 1.21+） |
| 週期性執行 | `time.NewTicker` + `defer Stop()`（★ **Ticker 一定要 Stop**，它不像 Timer 會被 GC 回收） |

> ★ **最重要的一條**：**逾時必須是「端到端」的，不是每一層各設一個。**
> 每層各設 5 秒 → 三層就是 15 秒。**用 `context` 傳遞同一個 deadline，才是正確的總時限控制。**

### 7. 競速模式的兩個變體

```go
// ① 取最快的一個（原文的作法）
func first(ctx context.Context, conns []Conn, q string) (Result, error) {
    ch := make(chan Result, len(conns))     // ★ 緩衝 = len，避免 goroutine 洩漏
    ctx, cancel := context.WithCancel(ctx)
    defer cancel()                          // ★ 拿到結果後通知其他人可以停了
    for _, c := range conns {
        go func(c Conn) {
            if r, err := c.Query(ctx, q); err == nil {
                ch <- r
            }
        }(c)
    }
    select {
    case r := <-ch:  return r, nil
    case <-ctx.Done(): return Result{}, ctx.Err()
    }
}

// ② 對沖請求（hedged request）：先送一個，N 毫秒後沒回應才送第二個
//    ★ 只在尾延遲異常時才付雙倍成本，比「總是送兩個」省得多
```
★ **對沖請求是降低 p99 的實用手法**（見 [[AI 系統設計框架]] 的分散式搜尋題）。

## 🧪 我實際套用的紀錄
- 2026-08-29：（待填）

## ⚠️ 注意 / 什麼時候不適用

- **★ 逾時了不代表對方停了**。`select` 的 timeout case 只是「你不等了」——
  **下游的工作還在跑、資源還佔著**。真正要停就必須傳 `ctx` 下去並讓對方檢查它。
- **★ `time.Ticker` 一定要 `Stop()`**（和 `time.After` 不同，Ticker 會持續發送，GC 收不掉）。
- **★ 競速的 channel 一定要有 `len(n)` 的緩衝**，否則沒被讀走的那些 goroutine 會永遠卡在送出那一行 → 洩漏。
- **`select` 的多個就緒 case 是隨機選的**（規格保證），**不要依賴順序**。
  需要優先序就用巢狀 select（先試高優先的 + `default`）。
- **`context` 的 `Err()` 要區分**：`context.Canceled`（上游取消）vs `context.DeadlineExceeded`（逾時）——
  **前者通常不該記成錯誤，後者要**（見 [[工具-Go錯誤該包還是該轉]]）。
- **不要把 `context` 存進 struct**。它是請求範圍的值，應該當參數傳。
- **逾時值要有依據**。從 p99 latency 往上加一點，**不是拍一個 30 秒**（見 [[工具-服務容錯設計]]）。

## 🔗 相關工具
- [[工具-靠通訊共享記憶體]] —— channel 的語義表與 goroutine 洩漏
- [[工具-服務容錯設計]] —— 逾時、重試、斷路器的正確順序
- [[工具-用race偵測器抓資料競爭]] —— 並行正確性的驗證
- [[觀察者模式]] —— `select` + `default` 的背壓取捨
- [[裝飾者模式]] —— middleware 裡 Retry 與 Timeout 的順序
- [[AI 系統設計框架]] —— 對沖請求與尾延遲
- [[Go Blog 經典六篇]]
