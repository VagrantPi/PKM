---
type: tool
name: "defer / panic / recover"
source: "[[Go Blog 經典六篇]]"
source_type: article
tags: [software, go, language]
triggers: [想確保檔案或鎖一定會被釋放, defer印出來的值跟我想的不一樣, 多個defer的執行順序, Go該不該用panic, 想在函式返回前改掉回傳的error]
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

## 🧪 我實際套用的紀錄
- 2026-08-29：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **不要用 panic 取代錯誤回傳**。Go 的設計就是要你在錯誤發生處明確檢查；panic 是給「不可能發生」與內部展開用的。
- **參數提前求值最常咬人的地方**是 `defer` 一個會變的變數；要延後求值就包一層 closure。
- **迴圈裡的 defer 會累積到函式結束才執行**——長迴圈裡開檔案會爆 fd。要在迴圈內釋放就包成一個小函式。
- **recover 只在同一個 goroutine 有效**。別的 goroutine panic 你 recover 不到，整個程式還是會掛。
- ⚠️ 開了 `-race` 時每個 `defer`／`recover` 會**多配置 8 bytes 且到 goroutine 結束才回收**——長命 goroutine 週期性呼叫會讓記憶體無上限成長 → [[工具-用race偵測器抓資料競爭]]。

## 🔗 相關工具
- [[工具-Go現代錯誤處理]] —— defer 改具名回傳值最常見的用途，就是統一包裝 error
- [[工具-用例外處理錯誤]] —— 其他語言的例外觀；對照著看更清楚 Go 為什麼不這樣做
