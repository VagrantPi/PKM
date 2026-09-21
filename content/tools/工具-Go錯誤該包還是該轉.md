---
type: tool
name: "Go 錯誤該包還是該轉"
source: "[[Google Go 風格指南]]"
source_type: article
tags: [software, go, error-handling, design]
triggers: [不知道該用%v還是%w, 錯誤訊息一層層疊起來又臭又長, 同一個錯誤被記了好幾次log, 設計錯誤時要不要讓呼叫端能分辨種類, 對外的API該不該暴露內部錯誤]
---

## 🎯 什麼情境該想到我
當你手上有一個 `err`，要決定「**往上丟的時候要加什麼、用什麼包、還是根本重造一個**」的時候。

> 這張卡講**決策**（該不該包、包什麼、誰記 log）；「怎麼辨識錯誤」的 API 機制（`errors.Is`／`As`／`Join`）在 [[工具-Go現代錯誤處理]]。

## ⚙️ 怎麼用（步驟 / 公式）

### 1. ⭐ `%v` 還是 `%w`：先問「呼叫端需要程式化地判斷嗎」

| | `%v` | `%w` |
|---|---|---|
| 做什麼 | 把錯誤壓成字串嵌進新錯誤，**丟掉結構** | 建立 `Unwrap()` 鏈，**保留原始錯誤** |
| 呼叫端能不能 `errors.Is`／`As` | ❌ | ✅ |
| 什麼時候用 | 只是加人看的說明；要記 log／顯示；在系統邊界重造錯誤 | 呼叫端需要判斷底層錯誤種類，而且這是你**承諾**的契約 |

```go
// %v：加上這一層的意義，但不承諾底層錯誤型別
if err != nil {
    return fmt.Errorf("launch codes unavailable: %v", err)
}

// %w：明確允許上層 errors.Is(err, fs.ErrNotExist)
if err != nil {
    return fmt.Errorf("couldn't find remote file: %w", err)
}
```

**關鍵心態：用了 `%w`，被包住的錯誤就成為你套件 API 的一部分。** 原文的判準是——只有當你「明確文件化並測試過」這些底層錯誤可以被解開檢查時，才用 `%w`。之後想換底層實作就是破壞性變更。

### 2. 在系統邊界要「翻譯」而不是「包裝」
RPC／IPC／儲存這種跨系統的邊界上，**不要把內部錯誤原封不動 `%w` 往外拋**。客戶端不在乎你內部是哪個檔案系統錯誤，他在乎的是標準化的結果（`Internal`／`NotFound`／`PermissionDenied`）。

```go
// Good: 邊界上翻譯成標準錯誤空間
func (*FortuneTeller) SuggestFortune(ctx context.Context, req *pb.SuggestionRequest) (*pb.SuggestionResponse, error) {
    if err != nil {
        return nil, fmt.Errorf("couldn't find fortune database: %v", err)
    }
}
```

### 3. ⭐ `%w` 放在結尾（哨兵錯誤例外，放開頭）
包裝會形成錯誤鏈，**每包一層就往鏈的前端加一個節點**。`%w` 的位置不影響鏈的結構，但影響**印出來的順序**：

```go
// Good: 印出來跟鏈的方向一致（新 → 舊）
err2 := fmt.Errorf("err2: %w", err1)
err3 := fmt.Errorf("err3: %w", err2)
fmt.Println(err3) // err3: err2: err1

// Bad: 鏈是新→舊，卻印成舊→新
err2 := fmt.Errorf("%w: err2", err1)
err3 := fmt.Errorf("%w: err3", err2)
fmt.Println(err3) // err1: err2: err3

// Bad: 夾在中間，印出來兩邊開花
err2 := fmt.Errorf("err2-1 %w err2-2", err1)
err3 := fmt.Errorf("err3-1 %w err3-2", err2)
fmt.Println(err3) // err3-1 err2-1 err1 err2-2 err3-2
```

所以預設寫成 `fmt.Errorf("做什麼的時候失敗: %w", err)`。

**例外：哨兵錯誤放開頭。** 哨兵錯誤是「這次失敗的主要分類」（not found、invalid argument），把它放最前面，讀的人一眼就知道類別：

```go
var ErrParse = fmt.Errorf("parse error")
var ErrParseInvalidHeader = fmt.Errorf("%w: invalid header", ErrParse)

func parseHeader() error {
    err := checkHeader()
    return fmt.Errorf("%w: invalid character in header: %v", ErrParseInvalidHeader, err)
}
```

### 4. 加資訊的兩條反例（幾乎每個 codebase 都在犯）
```go
// Bad: os 的錯誤本來就含路徑 → 印出來檔名出現兩次
return fmt.Errorf("could not open settings.txt: %v", err)
// could not open settings.txt: open settings.txt: no such file or directory

// Good: 只加這一層才知道的意義
return fmt.Errorf("launch codes unavailable: %v", err)
// launch codes unavailable: open settings.txt: no such file or directory

// Bad: 純雜訊，「有 error」本身就代表失敗了
return fmt.Errorf("failed: %v", err)   // → 直接 return err
```

判準：**這一層加的字，是呼叫端與被呼叫端都不知道、只有我知道的資訊嗎？** 不是就別加。

### 5. 要讓呼叫端分辨錯誤，就給它結構——絕不讓它比對字串
```go
// Good: 哨兵值
var (
    ErrDuplicate  = errors.New("duplicate")
    ErrMarsupial  = errors.New("marsupials are not supported")
)
// 呼叫端
switch {
case errors.Is(err, ErrDuplicate): ...
case errors.Is(err, ErrMarsupial): ...
}

// Bad
if regexp.MatchString(`duplicate`, err.Error()) { ... }
```
需要帶額外資料就給結構化型別（像 `os.PathError` 把路徑放在欄位讓人取用），而不是塞進訊息字串等人 parse。

### 6. 錯誤字串的格式：小寫、無句號
```go
err := fmt.Errorf("something bad happened")   // ✅ 它會被嵌進別人的句子裡
err := fmt.Errorf("Something bad happened.")  // ❌
```
例外是開頭本來就是匯出名稱、專有名詞或縮寫。**反過來，完整顯示的訊息要大寫**（log、測試失敗、API 回應、UI）：
```go
log.Errorf("Operation aborted: %v", err)
t.Errorf("Op(%q) failed unexpectedly; err=%v", args, err)
```

### 7. ⭐ 回傳了就別自己記 log
> 如果你要回傳這個錯誤，通常就不要自己記 log，讓呼叫端決定。

呼叫端可以選擇記、可以限流（`rate.Sometimes`）、可以嘗試恢復、也可以直接結束程式。自己記一次又往上丟，就變成同一件事在 log 裡出現 N 次。

代價要知道：讓呼叫端記，**log 的行號就是呼叫端的行號**，不是出錯的那一行。

另外三條：
- **注意 PII**，很多 log sink 不適合放使用者敏感資料。
- **`log.Error` 要省著用**：ERROR 級別會觸發 flush，比低級別貴得多。判準不是「比 warning 嚴重」，而是**這條訊息是否可行動（actionable）**。
- 決定要不要 log 之前，先確認是不是該回傳。

### 8. 處理錯誤只有三個合法選項
1. 當場處理掉
2. 回傳給呼叫端
3. 例外情況下 `log.Fatal`／（真的必要時）`panic`

**不要用 `_` 丟掉錯誤。** 真的要忽略（例如文件明說不會失敗的 `(*bytes.Buffer).Write`），要附註解說明為什麼安全：
```go
n, _ := b.Write(p) // never returns a non-nil error
```

## 🧪 我實際套用的紀錄
- 2026-09-20：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **不要每一層都包。** 每層加一句很快就變成又臭又長的訊息。只在**跨越有意義的邊界**時加。
- **`%w` 是單向承諾**：加上去容易，拿掉是破壞性變更。不確定呼叫端需不需要時，預設 `%v`。
- **哨兵放開頭的例外只適用於哨兵**。一般的上下文說明仍然放前面、`%w` 放最後。
- 原文的 `status.Errorf`／canonical codes 是 Google 內部與 gRPC 的做法；沒有 gRPC 的專案，對應概念是「在邊界上定義一組自己的對外錯誤分類」。
- 編排一組會一起失敗或一起取消的操作時，只取第一個錯誤是合理的——用 `errgroup`。

## 🔗 相關工具
- [[工具-Go現代錯誤處理]] —— 互補：那張講辨識錯誤的 API（`Is`／`As`／`Join`），這張講包裝與傳遞的決策
- [[工具-讓測試失敗訊息有用]] —— 同一個原則的測試版：訊息要讓維護者知道發生什麼、且不要靠字串比對錯誤
- [[工具-用例外處理錯誤]] —— 對照：那是例外式語言的做法，Go 刻意選了回傳值
