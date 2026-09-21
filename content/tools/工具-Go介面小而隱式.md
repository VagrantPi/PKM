---
type: tool
name: "Go 介面小而隱式"
source: "[[Effective Go]]"
source_type: article
tags: [software, go, language, design]
triggers: [Go的介面該怎麼設計, 介面要定義在哪一邊, 為什麼回傳的error不等於nil, 該用介面還是泛型, 介面抽太多變成噪音]
---

## 🎯 什麼情境該想到我
當你在 Go 裡設計介面，**帶著「先宣告 implements、介面要完整」的其他語言直覺**的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 1. 隱式滿足：型別不宣告自己實作了什麼
Go 沒有 `implements`。**只要方法都有，就滿足了。**
多數介面轉換是**靜態**的、編譯期就檢查——把 `*os.File` 傳給要 `io.Reader` 的函式，不滿足就編不過。

### 2. 介面要小
只有一兩個方法的介面在 Go 裡是**常態**，不是例外（`io.Reader` 只有一個方法）。

### 3. ⭐ 只為實作介面而存在的型別，不要匯出
> 如果一個型別的存在只是為了實作某個介面，而且不會有介面以外的匯出方法，**就沒必要匯出這個型別**。

這時**建構函式應該回傳介面值，而不是實作型別**：
```go
// crc32.NewIEEE 與 adler32.New 都回傳 hash.Hash32
```
好處是**換演算法只要改建構呼叫**，其餘程式碼完全不動。
只匯出介面也讓「這個值除了介面描述的以外沒有別的有趣行為」變得清楚，還省掉在每個實作上重複寫文件。

### 4. 用空白識別碼做編譯期介面檢查
有些檢查發生在**執行期**（例如 `encoding/json` 用型別斷言看你有沒有實作 `json.Marshaler`）。這很危險——**沒實作到的話 encoder 照樣能跑，只是不會用你的自訂邏輯**。

要在編譯期釘死，用這個宣告：
```go
var _ json.Marshaler = (*RawMessage)(nil)
```
介面一改，這個套件就編不過，你會馬上知道要更新。

**但不要每個型別都寫。** 慣例是**只在程式碼裡本來就沒有靜態轉換時才用**，而那很罕見。

### 5. 判斷「有沒有實作」而不需要用它時，用空白識別碼
```go
if _, ok := val.(json.Marshaler); ok { /* ... */ }
```

### 6. ★ 介面該定義在「消費方」，不是「實作方」

這是 Go 相對 Java 最大的差異，也是**隱式滿足真正的價值所在**：

```go
// ❌ Java 式：實作方定義大介面
package storage
type Storage interface { Get; Put; List; Delete; Stat }   // ★ 消費者只用 Get 卻被迫依賴全部

// ✅ Go 式：消費方定義小介面
package app
type Getter interface { Get(context.Context, string) ([]byte, error) }
func Process(g Getter) { ... }        // ★ storage 套件完全不知道 app.Getter 存在
```

**"accept interfaces, return structs"** —— 函式**收介面**（讓呼叫端自由替換），**回傳具體型別**（讓呼叫端拿到完整能力）。
→ 完整討論見 [[工具-針對介面編程]]。

### 7. ★★ 最惡名昭彰的陷阱：非 nil 的 nil 介面

```go
type MyError struct{ Code int }
func (e *MyError) Error() string { return "boom" }

func mayFail() error {
    var e *MyError = nil          // ★ 指標是 nil
    return e                      // ★ 但包成 error 介面後就「不是 nil」了
}

if err := mayFail(); err != nil {
    // ★★ 這裡會進來！
}
```

**為什麼**：介面值是一組 **(型別, 值)**。`return e` 得到的是 `(*MyError, nil)` ——
**型別欄位非空，所以整個介面值不等於 nil。**

**修法：不要宣告具體型別的錯誤變數再回傳它。**
```go
func mayFail() error {
    if ok { return nil }          // ★ 直接回傳字面的 nil
    return &MyError{Code: 1}
}
```
> ★ **這個 bug 幾乎每個 Go 工程師都踩過一次**，而且它不會有任何編譯警告。
> `go vet` 有 `nilness` 分析可以抓部分情況，但不是全部。

### 8. 介面 vs 泛型（Go 1.18+）

| 用介面 | 用泛型 |
|---|---|
| **行為**不同（各自有各自的實作） | **型別**不同但**邏輯相同** |
| 需要執行期多型（一個 slice 裝不同實作） | 編譯期就知道型別 |
| `io.Reader`、`http.Handler` | `slices.Sort`、`maps.Keys` |
| 動態分派，無法內聯 | ★ **可特化、可內聯，通常更快** |

★ **判準：問「這些型別的行為一樣嗎？」** 一樣（只是型別不同）→ 泛型；不一樣 → 介面。
**不要用泛型取代 `io.Reader` 這種真正的行為抽象。**

## 🧪 我實際套用的紀錄
- 2026-08-28：（待填）

## ⚠️ 注意 / 什麼時候不適用

- **★★ 非 nil 的 nil 介面**（見上）。這是 Go 最常見的執行期 bug 之一。
- **★ 介面污染（interface pollution）**：為每個 struct 配一個同名介面（`Service` + `IService`）
  **在 Go 裡沒有任何好處**——它不會讓程式更解耦，只是多一層間接和一個要同步維護的檔案。
  **只有一個實作且測試不需要替換 → 不要抽。**
- **介面太大 = 沒有介面**。十個方法的介面只有原本那個型別滿足得了，替換性是零。
- **回傳介面通常是錯的**。例外：實作型別未匯出、或真的有多種實作（`sql.Driver`、`hash.Hash`）。
- **動態分派有成本**：無法內聯、可能造成逃逸到 heap。**極熱的迴圈上具體型別更快——但先 profile。**
- **介面不描述保證**。它只說「有這些方法」，不說複雜度、是否阻塞、是否並行安全。**那些要寫在註解裡。**
- **空介面 `any` 不是抽象**，是放棄型別。Go 1.18 之後多數 `any` 的用法應該改成泛型。
- **嵌入介面會繼承它的全部方法**，包含你不想要的（見 [[工具-Go嵌入機制]]）。

## 🔗 相關工具
- [[工具-針對介面編程]] —— ★ 介面該定義在哪一邊（Go 與 Java 相反的結論）
- [[工具-Go嵌入機制]] —— 介面嵌入與方法集
- [[工具-Go錯誤該包還是該轉]] —— error 也是一個介面，nil 陷阱最常在這裡爆
- [[配接器模式]] —— 隱式滿足讓 Adapter 幾乎免費（`http.HandlerFunc`）
- [[策略模式]] —— 什麼時候用 `func` 型別就夠、什麼時候需要介面
- [[工具-優先組合而非繼承]] —— 組合的前置條件
- [[Modern Go Guidelines]]、[[Effective Go]]
