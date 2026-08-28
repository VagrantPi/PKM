---
type: tool
name: "用 race 偵測器抓資料競爭"
source: "[[Go Blog 經典六篇]]"
source_type: article
tags: [software, go, concurrency, testing]
triggers: [偶爾才失敗的詭異bug, 懷疑有資料競爭但抓不到, 併發程式在正式環境才出事, 怎麼證明這段併發是安全的, CI要不要開race]
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

## 🧪 我實際套用的紀錄
- 2026-08-29：（待填）

## ⚠️ 注意 / 什麼時候不適用
- ⚠️ **來源文章（2013）說只支援 64-bit x86，這已經過時。** 現行支援清單（查證自官方文件）包含 `linux/amd64`、`linux/arm64`、`linux/ppc64le`、`linux/s390x`、`linux/loong64`、`freebsd/amd64`、`netbsd/amd64`、`darwin/amd64`、**`darwin/arm64`**、`windows/amd64`——**Apple Silicon 可以用**。
- **需要啟用 cgo**；非 Darwin 系統還需要安裝 C 編譯器。Windows 上（Go 1.21 起）需要 mingw-w64 v8 以上的 runtime。
- 🔴 **成本很高，不要開在正式環境的常態流量上**：官方數字是**記憶體 5–10 倍、執行時間 2–20 倍**。
- ⚠️ **一個容易中的坑**：開了 `-race` 之後，每個 `defer` 與 `recover` 會**額外配置 8 bytes，且到 goroutine 結束才回收**。長命 goroutine 週期性呼叫 defer/recover 會讓記憶體**無上限成長**——而且**這些配置不會出現在 `runtime.ReadMemStats` 或 `runtime/pprof` 的輸出裡**，所以你查不到。
- **race detector 抓的是資料競爭，不是邏輯競爭**。兩個 goroutine 都正確加鎖但順序錯了，它不會有意見。

## 🔗 相關工具
- [[工具-靠通訊共享記憶體]] —— 從設計上避免共享，就少掉大半的 race
- [[工具-Go切片的共享與陷阱]] —— 多個 goroutine 共用同一底層陣列是典型的 race 來源
- [[工具-select超時與競速]] —— 競速模式特別容易寫出 race
