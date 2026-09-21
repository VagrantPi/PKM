---
type: tool
name: "Go 現代錯誤處理"
source: "[[Go Blog 經典六篇]]"
source_type: article
tags: [software, go, language, error-handling]
triggers: [錯誤要用哨兵還是型別還是不透明, 什麼時候該包裝什麼時候不該, 錯誤訊息該怎麼寫, errors.Join什麼時候用, 同一個錯誤被log了好幾次]
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

### 5. ★ 三種錯誤設計，怎麼選

| 設計 | 長相 | 呼叫端怎麼判斷 | 何時用 |
|---|---|---|---|
| **① 不透明（opaque）** | `fmt.Errorf("...")` | **只能印出來** | ★ **預設就用這個**——呼叫端不需要分辨時 |
| **② 哨兵（sentinel）** | `var ErrNotFound = errors.New("not found")` | `errors.Is(err, ErrNotFound)` | 呼叫端要**區分幾種固定情況** |
| **③ 型別（typed）** | `type ValidationError struct{ Field string }` | `errors.AsType[*ValidationError](err)` | ★ 呼叫端需要**錯誤裡的資料**（哪個欄位錯了、retry-after 幾秒） |

> ★ **從①開始，有需求再升級。**
> **哨兵與型別錯誤都是 API 的一部分**——一旦公開，就不能隨便改，而且呼叫端會依賴它。
> **不要一開始就為每種失敗定義一個 sentinel**，那是把內部細節變成契約。

### 6. ★ 什麼時候該包裝、什麼時候不該

```go
// ✅ 加上「這層在做什麼」的脈絡
if err := db.Query(ctx, q); err != nil {
    return fmt.Errorf("load user %s: %w", id, err)
}

// ❌ 沒有新資訊，只是讓訊息變長
if err := doThing(); err != nil {
    return fmt.Errorf("doThing failed: %w", err)     // ★ 呼叫堆疊已經說了是 doThing
}

// ❌ 每一層都包 → 「a: b: c: d: e: connection refused」
```

**三條規則**：
| 規則 | 說明 |
|---|---|
| **① 只在「加得出新脈絡」時包裝** | 識別碼、操作名稱、參數——**呼叫端看不到的東西** |
| **② ★ 跨套件邊界時包裝** | 內部錯誤往外傳時，加上你這一層的語義 |
| **③ ★ 用 `%w` 還是 `%v` 是一個 API 決定** | `%w` = **公開承諾「底層錯誤可被判斷」**；`%v` = **切斷**，把它變成不透明。<br>不想讓呼叫端依賴底層是哪個資料庫的錯 → **用 `%v`** |

### 7. ★ 錯誤訊息的寫法

```go
// ✅ 小寫開頭、不加句點、不加 "error"/"failed" —— 因為它會被嵌進更長的句子
errors.New("connection refused")
fmt.Errorf("open %s: %w", path, err)
// → 最終使用者看到：「sync config: open /etc/app.yaml: permission denied」

// ❌ errors.New("Error: Failed to connect.")
// → 「sync config: Error: Failed to connect.: ...」  ★ 讀起來很糟
```
★ **把錯誤訊息想成「句子的一節」而不是「一個完整的句子」。**

### 8. `errors.Join`（Go 1.20+）：多個錯誤一起回報

```go
var errs []error
for i, item := range items {
    if err := validate(item); err != nil {
        errs = append(errs, fmt.Errorf("item %d: %w", i, err))
    }
}
if err := errors.Join(errs...); err != nil {   // ★ 全 nil 時回傳 nil
    return err
}
// errors.Is / AsType 會走整棵樹，所以 Join 起來的每一個都判斷得到
```
**適用**：表單驗證（要一次回報所有錯誤）、批次處理、多個清理動作的 `defer`。
**不適用**：只要第一個錯誤就該中止的流程。

### 9. ★★ 只在一個地方處理錯誤：**處理 or 回傳，不要兩個都做**

```go
// ❌ 最常見的錯誤處理反模式
if err != nil {
    log.Error("failed to save", "err", err)   // ★ log 了
    return err                                 // ★ 又回傳了
}
// → 同一個錯誤在每一層各 log 一次，一個請求失敗產生五筆重複的 error log
```

> ★ **規則：中間層只「包裝並回傳」，只有最上層（HTTP handler、main、worker 迴圈）才 log。**
> 這樣一個失敗**只會有一筆 log，而且帶著完整的包裝鏈**：
> `handle request: load user abc: query: connection refused`

**最上層該做的事**：
```go
if err != nil {
    // ① 記錄（含 trace id）
    slog.ErrorContext(ctx, "request failed", "err", err, "path", r.URL.Path)
    // ② 轉成對外的表示（★ 不要把內部錯誤訊息直接回給使用者）
    switch {
    case errors.Is(err, ErrNotFound):    http.Error(w, "not found", 404)
    case errors.Is(err, ErrForbidden):   http.Error(w, "forbidden", 403)
    default:                             http.Error(w, "internal error", 500)
    }
}
```

## 🧪 我實際套用的紀錄
- 2026-08-29：（待填）

## ⚠️ 注意 / 什麼時候不適用

- **★★ 不要「log 了又回傳」**（見上）。這是 Go 錯誤處理最常見的反模式，會讓日誌無法使用。
- **★ `%w` 是 API 承諾**。一旦用了，呼叫端就可能開始 `errors.Is(err, sql.ErrNoRows)`——
  **你之後換資料庫就是 breaking change**。不想承諾就用 `%v`。
- **`errors.Is` 比較的是「值」，`AsType`/`As` 比較的是「型別」**。搞混會永遠判斷失敗。
- **★ 自訂錯誤型別要實作 `Unwrap() error`**，否則 `errors.Is/As` 走不進去。
  包裝多個時實作 `Unwrap() []error`（配合 `errors.Join` 的語義）。
- **★ 非 nil 的 nil 錯誤**：回傳 `var e *MyError = nil` 給 `error` 介面 → **`err != nil` 為真**。
  見 [[工具-Go介面小而隱式]] 的完整說明。
- **不要把 `context.Canceled` 當成錯誤記錄**。使用者取消是正常行為，記成 ERROR 會污染告警。
  `errors.Is(err, context.Canceled)` 時降級成 INFO 或直接忽略。
- **不要用錯誤做流程控制**。`if errors.Is(err, ErrNotFound) { create() }` 可以，
  但「用 panic/error 取代正常分支」不行。
- **錯誤訊息不要洩漏內部資訊**給外部使用者（SQL、路徑、堆疊）——**log 裡留完整的，回應裡給概括的。**

## 🔗 相關工具
- [[工具-Go錯誤該包還是該轉]] —— 更深入的包裝 vs 轉換決策
- [[工具-Go介面小而隱式]] —— ★ 非 nil 的 nil error
- [[工具-defer-panic-recover]] —— 什麼時候該用 panic（很少）
- [[工具-讓測試失敗訊息有用]] —— 同一套「訊息要有用」的紀律
- [[工具-Go命名慣例]] —— `ErrXxx` vs `XxxError`
- [[工具-遙測與監控]] —— 錯誤該在哪一層被記錄
- [[Go Blog 經典六篇]]、[[Modern Go Guidelines]]
