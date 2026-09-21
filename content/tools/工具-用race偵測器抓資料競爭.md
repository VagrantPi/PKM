---
type: tool
name: "用 race 偵測器抓資料競爭"
source: "[[Go Blog 經典六篇]]"
source_type: article
tags: [software, go, concurrency, testing]
triggers: [懷疑有資料競爭但重現不了, race偵測器要怎麼跑, 為什麼CI沒抓到但線上會出事, race偵測器會慢多少, 常見的資料競爭長什麼樣]
---

## 🎯 什麼情境該想到我
當你有一個「**偶爾才壞、重跑又好了**」的併發 bug 的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 1. 加一個旗標就好
```bash
go test -race ./...      # 測試（最常用）
go run -race main.go     # 直接跑
go build -race ./cmd/x   # 建置
```
編譯器會對**所有記憶體存取插樁**，runtime 監看未同步的共享變數存取，發現就印警告。

### 2. ⭐ 它只抓「真的被跑到」的競爭
> the race detector can detect race conditions **only when they are actually triggered by running code**

這是根本限制，決定了怎麼用它：
- **在測試裡用**，讓測試盡量覆蓋併發路徑。
- **接進 CI**（Go 團隊自己就是這樣做的）。
- **也可以在真實負載下跑**，例如金絲雀部署跑一個 `-race` 的實例。
- **沒報錯不等於沒有 race**，只代表這次沒跑到。

### 3. 讀報告
報告會告訴你**哪兩個 goroutine、在哪個位址、分別做了什麼存取、各自的建立位置**。順著兩邊的堆疊看，通常一眼就能看出少了哪個同步。

### 4. ★ 怎麼跑（三個層次）

```bash
go test -race ./...                  # ★ 最常用：測試時開
go build -race -o app . && ./app     # 建置時開（壓測或 staging 環境）
go run -race main.go                 # 開發時單次跑
```

**★ 關鍵：`-race` 只能偵測「實際執行到」的競態。**
沒跑到那條路徑就抓不到 → **所以它的效果完全取決於你的測試覆蓋率與併發程度。**

**讓它更容易抓到**：
```bash
go test -race -count=10 ./...        # ★ 重複跑，增加不同交錯順序的機會
go test -race -cpu=1,2,4,8 ./...     # ★ 不同 GOMAXPROCS，改變排程行為
```

```go
func TestConcurrent(t *testing.T) {
    t.Parallel()                     // ★ 讓測試之間也並行
    var wg sync.WaitGroup
    for i := 0; i < 100; i++ {       // ★ 刻意製造併發壓力
        wg.Add(1)
        go func() { defer wg.Done(); target.Do() }()
    }
    wg.Wait()
}
```

### 5. ★ 成本：為什麼不能一直開著

| 面向 | 影響 |
|---|---|
| **執行速度** | ★ **慢 2–20 倍**（官方說法約 10 倍量級） |
| **記憶體** | ★ **增加 5–10 倍** |
| **goroutine 上限** | 有數量限制（歷史上是 8192，會隨版本變） |
| 平台 | 需要 cgo 支援的平台；**Apple Silicon（darwin/arm64）已支援** |

> ★ **實務配置**：
> - **CI 的單元測試一律 `-race`**（值得那點時間）
> - **整合測試與 E2E 也盡量開**（併發路徑更多）
> - **生產環境不開**（成本太高），但**可以在 staging 用 `-race` 跑壓測**

### 6. ★ 四種最常見的資料競爭

**① 迴圈變數**（Go < 1.22）
```go
for _, v := range items {
    go func() { use(v) }()      // ★ 1.22 前：共用同一個 v
}
```
→ **Go 1.22 起每輪新建變數，這個 bug 消失了**（見 [[工具-靠通訊共享記憶體]]）。
**但 `go.mod` 的 go 版本要 ≥ 1.22。**

**② 未保護的 map**
```go
var cache = map[string]int{}
go func() { cache["a"] = 1 }()   // ★ 並行寫 map → runtime 直接 panic
```
Go runtime 會主動偵測並 `fatal error: concurrent map writes`——**這個連 recover 都攔不住。**

**③ 以為「只是讀」就安全**
```go
if !initialized {           // ★ 讀
    initialized = true      // ★ 寫 —— 兩個 goroutine 可能都進來
    doInit()
}
```
→ 用 `sync.Once`（見 [[單例模式]]）。

**④ ★ 用 channel 傳遞「指標」，以為就安全了**
```go
ch <- &bigStruct          // ★ 傳的是位址
// 送出方繼續改 bigStruct → 和接收方競態
```
> ★ **channel 保證的是「傳遞」的同步，不是「內容」的獨占。**
> 傳指標之後**就不要再碰它**——這是「所有權轉移」的約定，**編譯器不會幫你檢查。**

### 7. 讀懂 race 報告

```
WARNING: DATA RACE
Write at 0x00c0000b4010 by goroutine 8:      ← ★ 誰在寫、在哪一行
  main.(*Counter).Inc()
      /app/counter.go:14 +0x3c

Previous read at 0x00c0000b4010 by main goroutine:   ← ★ 誰在讀
  main.main()
      /app/main.go:22 +0x8c

Goroutine 8 (running) created at:            ← ★ 這個 goroutine 是誰開的
  main.main()
      /app/main.go:20 +0x64
```
★ **三段一起看**：衝突的兩次存取 + goroutine 的建立點。
**「created at」那一段最有用**——它告訴你這個並行是從哪裡來的。

## 🧪 我實際套用的紀錄
- 2026-08-29：（待填）

## ⚠️ 注意 / 什麼時候不適用

- **★★ 沒報告 ≠ 沒有競態**。它只偵測「這次執行實際發生的」存取。
  **race detector 是找 bug 的工具，不是正確性的證明。**
- **★ 要有併發的測試才抓得到**。單執行緒跑過所有測試，race detector 一個都不會報。
  → **刻意寫並行壓力測試**（見上）。
- **不要用 `sync/atomic` 來「消掉 race 警告」**。atomic 保證的是單一操作的原子性，
  **不保證多個操作之間的不變式**。`atomic.Load` + 判斷 + `atomic.Store` 仍然是競態。
- **★ 競態不只是「值錯了」**。Go 的記憶體模型下，資料競爭是**未定義行為**——
  可能觀察到撕裂的值、編譯器重排、或完全違反直覺的結果。**不要試圖推理「最壞也只是拿到舊值」。**
- **`-race` 會改變時序**，有時反而讓某些競態不出現（Heisenbug）。**兩種都跑。**
- **第三方套件的競態也會被報出來**——先確認是自己的還是別人的，再決定怎麼處理。
- **`go vet` 不能取代它**。vet 抓的是靜態的可疑模式（如 copylocks），**競態要靠執行期偵測**。

## 🔗 相關工具
- [[工具-靠通訊共享記憶體]] —— ★ 從設計上避免競態，而不是事後抓
- [[工具-select超時與競速]] —— 並行模式
- [[工具-Go表格測試與子測試]] —— 怎麼寫出能觸發競態的測試
- [[單例模式]] —— `sync.Once` 取代「檢查再初始化」
- [[雜湊表]] —— 為什麼 Go 的 map 並行寫會 panic
- [[工具-系統化除錯]] —— 難以重現的 bug 怎麼查
- [[Go Blog 經典六篇]]
