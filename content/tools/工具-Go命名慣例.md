---
type: tool
name: "Go 命名慣例"
source: "[[Effective Go]]"
source_type: article
tags: [software, go, language, naming]
triggers: [Go的命名跟其他語言哪裡不一樣, 套件名該怎麼取, 介面要不要加I或Impl, 縮寫的大小寫怎麼處理, getter要不要叫GetXxx]
---

## 🎯 什麼情境該想到我
當你在 Go 裡「**想不到這個 package／型別／方法該叫什麼**」，或是把別的語言的命名習慣直接搬過來的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 0. 先知道：Go 的命名有語義效果
**首字母大寫決定它在 package 外看不看得到。** 在多數語言這只是風格，在 Go 是語言規則——所以命名不只是可讀性問題。

### 1. Package 名：短、精簡、有畫面
- **小寫、單字、不用底線也不用駝峰**。
- **寧短勿長**——每個使用者都要打這個名字。
- 就是原始目錄的 base name：`src/encoding/base64` 匯入路徑是 `encoding/base64`，但名字是 `base64`，不是 `encoding_base64`。
- **不用預先擔心撞名**：package 名只是匯入時的預設名，撞到時匯入方可以自己改。

### 2. ⭐ 用套件名幫你省字（最常被忽略的一條）
使用者看到的永遠是 `套件.名稱`，所以**不要在型別名裡重複套件名**：
```go
bufio.Reader   // ✅ 不是 bufio.BufReader
ring.New()     // ✅ 不是 ring.NewRing（Ring 是這個套件唯一匯出的型別）
once.Do(setup) // ✅ 不是 once.DoOrWaitUntilDone(setup)
```
而且 `bufio.Reader` 跟 `io.Reader` **不會衝突**，因為總是帶著套件名。

### 3. Getter 不要加 `Get`
欄位叫 `owner`（小寫未匯出），getter 就叫 **`Owner()`**，不是 `GetOwner()`。大小寫本身就是區分欄位與方法的鉤子。setter 才叫 `SetOwner()`。
```go
owner := obj.Owner()
if owner != user {
    obj.SetOwner(user)
}
```

### 4. 單方法介面用 `-er`
`Reader`、`Writer`、`Formatter`、`CloseNotifier`——方法名加 `-er` 構成施事名詞。
**反過來的規則同樣重要**：
- `Read`／`Write`／`Close`／`Flush`／`String` 有**規範化的簽章與意義**——除非你的方法簽章與意義完全相同，**否則不要用這些名字**。
- 反之，如果你的方法跟知名型別的方法意義相同，**就用同一個名字與簽章**：字串轉換方法叫 `String()`，不叫 `ToString()`。

### 5. 多字用 MixedCaps／mixedCaps，不用底線

### ★ 具體對照表（照抄即可）

| 場景 | ❌ 別這樣 | ✅ Go 的慣例 |
|---|---|---|
| **套件名** | `utils`、`common`、`helpers`、`base` | ★ **`bytes`、`http`、`user`** —— 單一名詞、小寫、不用底線或駝峰 |
| **避免重複** | `chubby.ChubbyFile` | ★ **`chubby.File`** —— 呼叫端看到的是 `套件.型別` |
| **介面** | `IUserService`、`UserServiceInterface` | ★ **`Reader`、`Writer`** —— 單方法介面用 **`-er`** |
| **實作** | `UserServiceImpl` | ★ **`postgresUserStore`**（用「它是什麼」命名，不是「它實作了什麼」） |
| **Getter** | `GetName()` | ★ **`Name()`** —— Go **不用 Get 前綴**；Setter 才用 `SetName()` |
| **縮寫** | `Url`、`Id`、`Http`、`Api` | ★ **`URL`、`ID`、`HTTP`、`API`** —— **整個縮寫同大小寫**；未匯出時 `url`、`id` |
| **錯誤變數** | `NotFoundError` | ★ **`ErrNotFound`** —— sentinel 用 `Err` 前綴 |
| **錯誤型別** | `NotFoundErr` | ★ **`NotFoundError`** —— 型別用 `Error` 後綴 |
| **變數長度** | `userRepository` | ★ **作用域越小名字越短**：`for i`、`r *http.Request`、`u User` |
| **接收者** | `(this *User)`、`(self *User)` | ★ **`(u *User)`** —— 一到兩個字母，且**同一型別全部統一** |
| **常數** | `MAX_RETRIES` | ★ **`MaxRetries`** —— Go 沒有全大寫的慣例 |
| **測試** | `TestFoo1`、`TestFoo2` | ★ **`TestFoo`** + `t.Run("空輸入", ...)` 子測試（見 [[工具-Go表格測試與子測試]]） |

### ★ 三條背後的原則

**① 名字的長度該和作用域成正比**
```go
for i := range s { ... }                       // ★ 三行內，一個字母就夠
func (c *Client) Do(r *Request) (*Response, error)   // 參數，短
var defaultRetryBackoffMultiplier = 1.5        // ★ 套件層級，要完整
```
> **這和多數語言的「名字越長越清楚」直覺相反。**
> Go 的理由：**短作用域裡上下文已經很清楚，長名字只是噪音。**

**② 匯出名要能和套件名一起讀**
`http.Get`、`bytes.Buffer`、`io.Reader`——**呼叫端讀到的是「套件.名字」這一整串**。
所以 `http.HTTPClient` 是重複的（應該是 `http.Client`）。

**③ ★ 不要用 `utils` / `common` 這種套件名**
它們是「我不知道這東西屬於哪裡」的自白。
**結果是所有人都往裡面丟，最後變成一個誰都要 import 的巨大耦合點。**
→ **按「領域」而不是按「種類」分套件**：`user`、`billing`、`auth`，不是 `models`、`services`、`utils`。

### ★ 註解的慣例（`godoc` 會直接用）

```go
// Reader 從底層資料流讀取位元組。    ← ★ 以「名字」開頭
//
// Read 在讀到 0 個位元組時回傳 io.EOF。   ← 說明保證
type Reader interface{ ... }

// ErrNotFound 表示請求的資源不存在。
var ErrNotFound = errors.New("not found")
```
- **匯出的東西一定要有註解，且以該名字開頭**（`golint` 會檢查）
- **套件註解**放在 `doc.go` 或任一檔案的 `package` 前
- ★ **註解寫「為什麼」與「保證什麼」，不要複述程式碼**

### ★ 錯誤訊息的慣例
```go
// ✅ 小寫開頭、不加標點 —— 因為它會被嵌進更長的句子
return fmt.Errorf("open config: %w", err)
// → 上層包裝後：「load settings: open config: permission denied」

// ❌ errors.New("Failed to open config file.")
```
（例外：以專有名詞或縮寫開頭時保留原大小寫，如 `HTTP request failed`。）

## 🧪 我實際套用的紀錄
- 2026-08-28：（待填）

## ⚠️ 注意 / 什麼時候不適用

- **★ 一致性勝過個人偏好**。進到既有專案就照它的慣例走，**不要為了「更正確」而製造兩套風格**。
- **`gofmt` 管格式，不管命名**。命名靠 review 與 linter（`revive`、`staticcheck`、`golangci-lint`）。
- **★ 短名字有邊界**。函式超過二三十行，`i`、`v`、`c` 就會開始不清楚——
  **那通常代表函式該拆了**，而不是名字該變長。
- **接收者名稱不要用 `this`/`self`**，也**不要在同一型別的不同方法間換名字**。
- **`Err` 前綴只給 sentinel error**（可比較的哨兵值）。動態產生的錯誤不需要變數名。
- **測試檔案命名**：`foo_test.go` 與被測檔案同套件（白箱）或 `package foo_test`（黑箱，**只能用匯出的 API**）。
- **不要過度縮寫**。`cfg`、`ctx`、`req`、`db` 是公認的；`usrMgrSvc` 不是。

## 🔗 相關工具
- [[工具-Go可讀性五原則]] —— 命名之外的可讀性紀律
- [[工具-有意義的命名]] —— 跨語言的命名原則
- [[工具-Go介面小而隱式]] —— `-er` 命名與介面設計
- [[工具-Go現代錯誤處理]] —— `ErrXxx` 與 `XxxError` 的分工
- [[工具-Go表格測試與子測試]] —— 測試命名
- [[工具-註解是必要之惡]] —— 註解該寫什麼
- [[Effective Go]]、[[Modern Go Guidelines]]
