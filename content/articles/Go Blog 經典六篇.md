---
type: article
title: "Go Blog 經典六篇"
source_url: https://go.dev/blog/
author: The Go Authors
site: go.dev/blog
tags: [software, go, language, concurrency, methodology]
captured: 2026-08-29
read_status: read
---

## 📌 30 秒摘要（讀完用自己的話寫一句）
> 這頁在講：Go 官方部落格 2010–2013 年的六篇經典。**我逐篇對照現行文件查證過**——結論是過時程度差很多：`defer/panic/recover` 與反射三法則**一字未改仍成立**；切片與 race detector **機制對、周邊 API 或平台清單過時**；而 **error handling 那篇今天照做會錯**。

## ⚠️ 查證結果（2026-08-29，逐篇對照 pkg.go.dev 現行文件）

| 文章 | 年份 | 判定 | 具體證據 |
|---|---|---|---|
| [Defer, Panic, and Recover](https://go.dev/blog/defer-panic-and-recover) | 2010 | ✅ **完全成立** | defer 三規則與 panic/recover 語義從未變動 |
| [Concurrency: timeouts](https://go.dev/blog/concurrency-timeouts) | 2010 | ⚠️ **技巧成立、缺口大** | 完全沒有 `context`（現在跨 API 邊界的逾時與取消靠它） |
| [Slices intro](https://go.dev/blog/slices-intro) | 2011 | ⚠️ **機制成立、API 過時** | 範例用 `ioutil.ReadFile`，**Go 1.16 起整包 `io/ioutil` 已棄用** |
| [Error handling and Go](https://go.dev/blog/error-handling-and-go) | 2011 | ❌ **明顯過時，照做會錯** | 見下方 |
| [Laws of Reflection](https://go.dev/blog/laws-of-reflection) | 2011 | ✅ **三法則成立** | 反射三法則與 settability 概念未變 |
| [Race Detector](https://go.dev/blog/race-detector) | 2013 | ⚠️ **工具成立、平台清單過時** | 2013 說只支援 64-bit x86；**現行已含 `darwin/arm64`** |

### ❌ Error handling 那篇為什麼是「照做會錯」
兩個具體點，都對照過現行文件：

1. **它教你用 type assertion 辨識錯誤**（`err.(*json.SyntaxError)`）。Go 1.13 起正解是 `errors.Is`／`errors.As`，因為錯誤會被 `%w` 包裝，直接斷言會**漏掉被包在裡面的錯誤**。
2. ⭐ **它教你用 `net.Error.Temporary()` 決定要不要重試**。現行 `net` 套件的原文是：
   > ```go
   > // Deprecated: Temporary errors are not well-defined.
   > // Most "temporary" errors are timeouts, and the few exceptions are surprising.
   > // Do not use this method.
   > Temporary() bool
   > ```
   標準函式庫明講 **Do not use this method**。

正確做法 → [[工具-Go現代錯誤處理]]。

### ⚠️ 一個「連修正本身都過時了」的案例
Concurrency: timeouts 建議用 `time.After`。多年來社群的標準修正是「`time.After` 在迴圈裡會洩漏，改用 `NewTimer` + `Stop`」——**這條修正現在也過時了**。現行 `time.After` 文件：
> "Before Go 1.23, this documentation warned that the underlying Timer would not be recovered by the garbage collector until the timer fired... **As of Go 1.23, the garbage collector can recover unreferenced, unstopped timers. There is no reason to prefer NewTimer when After will do.**"

**教訓：查證舊文件時，連「大家都知道的那個修正」也要一起查。**

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- Go 是我的主力語言，這六篇是官方對「語言為什麼這樣運作」講得最清楚的地方。
- **查證結果本身就是資產**：知道哪一篇不能信、不能信在哪一句，比重讀六篇更省時間。
- 用一頁地圖收六篇，而不是六頁——它們是同一組東西，**分開放會讓「哪篇能信」這個最重要的比較消失**。

## 🧰 這六篇給我的工具（連到 tools/ 工具卡）
- [[工具-defer-panic-recover]] — 當我要確保清理一定會執行、或在想 panic 該不該外露的時候
- [[工具-Go切片的共享與陷阱]] — 當我 append 之後發現另一個切片的值也變了的時候
- [[工具-Go現代錯誤處理]] — 當我要包裝、辨識或合併錯誤的時候（**取代那篇 2011 的做法**）
- [[工具-select超時與競速]] — 當我要等最多 N 秒、或要取最快回應的時候
- [[工具-Go反射三法則]] — 當我要用 `reflect` 卻搞不清楚為什麼改不動值的時候
- [[工具-用race偵測器抓資料競爭]] — 當我懷疑有 race 卻抓不到的時候

## 💬 原文摘錄
- panic 的邊界（這條慣例仍然是 Go 的標準做法）：
  > "The convention in the Go libraries is that even when a package uses panic internally, **its external API still presents explicit error return values**."
- 切片的記憶體陷阱：
  > "the returned []byte points into an array containing the entire file... the few useful bytes of the file keep the entire contents in memory."
- 反射第三法則：
  > "To modify a reflection object, the value must be settable."
- race detector 的根本限制：
  > "the race detector can detect race conditions **only when they are actually triggered by running code**"

## 🔗 相關
- [[Effective Go]] — 同樣是 2009–2011 的官方素材，同樣要分層讀
- [[Modern Go Guidelines]] — 現代語法對照表；這六篇的過時處多半在那裡有對應的現代寫法
- [[moc/軟體工程|軟體工程]] — 語言層章節
