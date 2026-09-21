---
type: tool
name: "defer / panic / recover"
source: "[[Go Blog 經典六篇]]"
source_type: article
tags: [software, go, language]
triggers: [defer的執行順序和參數什麼時候求值, 在迴圈裡defer會怎樣, recover為什麼沒攔到panic, 想在defer裡改回傳值, goroutine裡的panic會怎樣]
---

## 🎯 什麼情境該想到我
當你「**函式有很多條 return 路徑，怕漏掉清理**」，或在猶豫「**這裡該 panic 還是回 error**」的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### defer 的三條規則（背這三條就夠）
1. **參數在 `defer` 那一行就求值**，不是執行時：
   ```go
   func a() {
       i := 0
       defer fmt.Println(i)   // 印 0，不是 1
       i++
   }
   ```
2. **LIFO 順序**，在外層函式 return 之後執行：
   ```go
   for i := 0; i < 4; i++ { defer fmt.Print(i) }   // 印 3210
   ```
3. ⭐ **defer 可以讀寫具名回傳值**：
   ```go
   func c() (i int) {
       defer func() { i++ }()
       return 1        // 實際回傳 2
   }
   ```
   這條是**在返回前統一加工 error** 的關鍵手法。

### 用法：開了就馬上 defer 關
```go
src, err := os.Open(srcName)
if err != nil { return }
defer src.Close()          // 就寫在 Open 旁邊

dst, err := os.Create(dstName)
if err != nil { return }   // src 仍會被關掉
defer dst.Close()
return io.Copy(dst, src)
```
兩個好處：**不會忘記關**（之後加新的 return 路徑也不會漏），以及**關的地方就在開的旁邊**，比擺在函式尾端清楚。
同樣用在 `mu.Lock(); defer mu.Unlock()`。

### ⭐ panic 的邊界——這條慣例是 Go 的標準
> **Go 函式庫的慣例是：即使套件內部使用 panic，它對外的 API 仍然回傳明確的 error 值。**

標準庫的實例：`encoding/json` 用遞迴函式編碼，遇到錯誤時用 `panic` 把堆疊一路展開回最上層，**在那裡 recover 並轉成 error 回傳**。
所以判準是：**panic 可以當內部的控制流捷徑，但不可以穿過套件邊界。**

`recover` 只在 deferred 函式裡有效；沒被 recover 的 panic 會一路到 goroutine 堆疊頂端並終止程式。

### 5. ★ `defer` 的兩個時機規則（最常搞錯的地方）

```go
func f() {
    x := 1
    defer fmt.Println("A:", x)      // ★ 參數「現在」就求值 → 印 A: 1
    defer func() {
        fmt.Println("B:", x)        // ★ 閉包「執行時」才讀 → 印 B: 2
    }()
    x = 2
}
// 輸出（後進先出）：B: 2  然後  A: 1
```

| 規則 | 說明 |
|---|---|
| **① 參數在 `defer` 那一行就求值** | `defer f(x)` 記下的是「當下的 x」 |
| **② 函式本體在 return 之後才執行** | 閉包裡讀到的是「最終的值」 |
| **③ 後進先出（LIFO）** | 多個 defer 反序執行 |

★ **想要「執行時才決定」就包一層閉包**；想要「當下的快照」就直接傳參數。

### 6. ★ `defer` + 具名回傳值 = 可以改回傳值

```go
func doWork() (err error) {                    // ★ 具名回傳值
    defer func() {
        if r := recover(); r != nil {
            err = fmt.Errorf("panic: %v", r)   // ★ 改掉回傳的 err
        }
    }()
    mustSucceed()
    return nil
}
```
這是 **把 panic 轉成 error 的標準寫法**，也是把「內部用 panic 簡化錯誤傳遞」的技巧封裝在套件邊界的方法
（`encoding/json` 與 `text/template` 內部都這樣做）。

**另一個常用場景：包裝錯誤**
```go
func query(ctx context.Context) (err error) {
    defer func() {
        if err != nil { err = fmt.Errorf("query: %w", err) }   // ★ 所有 return 路徑統一包裝
    }()
    ...
}
```

### 7. ★★ `defer` 在迴圈裡 = 資源洩漏

```go
// ❌ 所有檔案都要等函式結束才關 —— 檔案數多就爆 fd
for _, name := range files {
    f, err := os.Open(name)
    if err != nil { return err }
    defer f.Close()             // ★ 累積到函式結束
    process(f)
}

// ✅ 包成一個函式，讓 defer 有正確的邊界
for _, name := range files {
    if err := func() error {
        f, err := os.Open(name)
        if err != nil { return err }
        defer f.Close()         // ★ 每輪結束就關
        return process(f)
    }(); err != nil {
        return err
    }
}
```
★ **「defer 的作用域是函式，不是區塊」** —— 這是它和 C++ RAII / Rust drop 最大的差異。

### 8. ★ `recover` 只在「被 defer 直接呼叫的函式」裡有效

```go
// ❌ 沒用：recover 不在 defer 直接呼叫的函式裡
defer func() { helper() }()
func helper() { recover() }              // ★ 攔不到

// ❌ 沒用：不是在 defer 裡
if r := recover(); r != nil { }          // ★ 永遠是 nil

// ✅ 正確
defer func() { if r := recover(); r != nil { ... } }()
```

**★ 而且 panic 跨不過 goroutine 邊界**：
```go
go func() {
    panic("boom")        // ★★ 直接終止「整個程式」，呼叫端的 recover 攔不到
}()
```
→ **每個 `go` 出去的函式都該有自己的 `defer recover()`**，尤其是處理外部輸入的 worker。

### 9. 什麼時候該用 panic（很少）

| 該用 | 不該用 |
|---|---|
| **程式設計錯誤**（不變式被破壞、不可能到達的分支） | ★ **可預期的失敗**（檔案不存在、網路錯誤、輸入不合法） |
| **套件初始化失敗**（`regexp.MustCompile`） | 業務邏輯的分支 |
| **內部深層遞迴的錯誤傳遞**（★ 但必須在套件邊界 recover 轉成 error） | 跨 API 邊界 |

> ★ **Go 的慣例很明確：錯誤用回傳值，panic 留給「程式寫錯了」。**
> 一個函式會 panic 這件事**沒有出現在它的簽章裡**，呼叫端無從得知——這就是為什麼它不該是常規的錯誤機制。

## 🧪 我實際套用的紀錄
- 2026-08-29：（待填）

## ⚠️ 注意 / 什麼時候不適用

- **★★ 迴圈裡的 `defer` 會累積到函式結束**（見上）。這是 fd / 連線洩漏最常見的來源。
- **★ `defer` 的錯誤不要吞掉**。`defer f.Close()` 會丟掉 Close 的錯誤——
  **寫入的檔案尤其致命**（Close 才會 flush，錯誤代表資料沒寫進去）：
  ```go
  defer func() {
      if cerr := f.Close(); cerr != nil && err == nil { err = cerr }
  }()
  ```
- **★ `recover` 之後程式狀態是不確定的**。panic 發生時可能有一半的工作做完了、鎖還鎖著、資料半寫。
  **recover 適合「記錄並讓這一個請求失敗」，不適合「假裝沒事繼續跑」。**
- **★ goroutine 裡的 panic 會終止整個程式**（見上）。HTTP server 的 handler 有內建 recover，
  **但你自己 `go` 出去的沒有。**
- **`defer` 有成本**（雖然 Go 1.14 之後的 open-coded defer 已經很便宜）。極熱的迴圈上可以手動處理。
- **`os.Exit` 不會執行 defer**。`log.Fatal` 也是（它內部呼叫 `os.Exit`）——
  ★ **所以 `log.Fatal` 不該在需要清理資源的地方用，也不該在函式庫裡用。**
- **panic 訊息會印出整個 goroutine 堆疊**，可能含敏感資料——**生產環境的 panic 處理要過濾。**

## 🔗 相關工具
- [[工具-Go現代錯誤處理]] —— 錯誤該用回傳值，panic 是例外
- [[工具-Go錯誤該包還是該轉]] —— defer + 具名回傳值統一包裝
- [[工具-靠通訊共享記憶體]] —— ★ 每個 goroutine 都要自己 recover
- [[工具-用例外處理錯誤]] —— 其他語言的對照
- [[工具-防禦式編程]] —— 什麼該斷言、什麼該回錯
- [[Effective Go]]、[[Go Blog 經典六篇]]
