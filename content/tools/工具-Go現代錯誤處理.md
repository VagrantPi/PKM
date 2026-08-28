---
type: tool
name: "Go 現代錯誤處理"
source: "[[Go Blog 經典六篇]]"
source_type: article
tags: [software, go, language, error-handling]
triggers: [判斷是不是某個特定錯誤, 錯誤被包裝之後就認不出來了, 想在錯誤裡帶上下文又不想弄丟原因, 好幾個操作都可能失敗要一起回報, 該不該重試這個網路錯誤]
---

## 🎯 什麼情境該想到我
當你要**包裝、辨識或合併**錯誤的時候。

> ⚠️ **這張卡是用來取代官方 2011 年〈Error handling and Go〉的做法的。** 那篇教的 type assertion 辨錯與 `net.Error.Temporary()`，今天照做會錯（查證見 [[Go Blog 經典六篇]]）。

## ⚙️ 怎麼用（步驟 / 公式）

### 1. 包裝時用 `%w`，保留原因
```go
if err := doThing(); err != nil {
    return fmt.Errorf("處理訂單 %s: %w", id, err)   // %w 而不是 %v
}
```
`%v` 會把錯誤壓成字串、**切斷追溯鏈**；`%w` 保留原始錯誤，讓下游還認得出來。

### 2. 辨識「是哪一個」用 `errors.Is`（Go 1.13+）
```go
if errors.Is(err, os.ErrNotExist) { ... }   // ✅
if err == os.ErrNotExist { ... }            // ❌ 被包裝過就失效
```
`Is` 會沿著 `Unwrap` 鏈整棵樹找。

### 3. 辨識「是哪一種型別」用 `errors.AsType`（Go 1.26+）或 `errors.As`（1.13+）
```go
// Go 1.26 起，官方文件明說「For most uses, prefer AsType」
if pathErr, ok := errors.AsType[*os.PathError](err); ok {
    log.Println(pathErr.Path)
}

// 1.26 之前
var pathErr *os.PathError
if errors.As(err, &pathErr) { ... }
```
兩者都會走整棵錯誤樹；**直接用 type assertion `err.(*os.PathError)` 只看最外層**，被包裝就漏掉——這正是 2011 那篇的做法。

### 4. 多個錯誤一起回報用 `errors.Join`（1.20+）
```go
return errors.Join(err1, err2, err3)   // nil 會被忽略
```
合併後**仍可被 `errors.Is`／`AsType` 穿透**，比 `fmt.Errorf("multiple: %v", errs)` 好得多。

### 5. 自訂錯誤要能被解開
帶結構化欄位時，實作 `Unwrap() error`（或多錯誤的 `Unwrap() []error`），否則 `Is`／`AsType` 走不進去。

## 🧪 我實際套用的紀錄
- 2026-08-29：（待填）

## ⚠️ 注意 / 什麼時候不適用
- 🔴 **不要用 `net.Error.Temporary()` 決定要不要重試。** 現行標準函式庫的原文：
  > "Deprecated: Temporary errors are not well-defined. Most 'temporary' errors are timeouts, and the few exceptions are surprising. **Do not use this method.**"

  要判斷逾時用 `Timeout()`；要重試就依你自己的業務語義定義可重試的錯誤，別依賴這個。
- **`%w` 會讓錯誤字串成為你的 API 表面**。下游可能開始依賴它的措辭與可解開性，改動要當成破壞性變更看待。
- **不要每一層都包裝**。每層加一句上下文很快就變成又長又重複的訊息；只在**跨越有意義的邊界**時包。
- **`errors.Is` 比較的是「同一個哨兵值」**，所以哨兵錯誤要用 `var ErrXxx = errors.New(...)` 宣告成套件層級變數。
- `errors.AsType` 是 **Go 1.26** 才有的，要支援舊版就用 `errors.As`。

## 🔗 相關工具
- [[工具-defer-panic-recover]] —— 用 defer 改具名回傳值，可以在返回前統一包裝 error
- [[Modern Go Guidelines]] —— `erris`／`errorsjoin` 兩條診斷就是在講這張卡的內容
- [[Effective Go]] —— 它的 Errors 章同樣停留在 2009 年的做法，別照抄
