---
type: tool
name: "Go 嵌入機制 Embedding"
source: "[[Effective Go]]"
source_type: article
tags: [software, go, language, design]
triggers: [想省掉一堆轉發方法, 嵌入是不是繼承, 嵌入之後方法呼叫到錯的地方, 嵌入mutex好不好, 嵌入的欄位JSON會怎麼序列化]
---

## 🎯 什麼情境該想到我
當你想「**借用另一個型別的行為**」，但 Go 沒有繼承的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 1. 嵌入省掉的是「轉發方法」這種苦工
不嵌入的話你要自己寫一堆轉發：
```go
type ReadWriter struct {
    reader *Reader
    writer *Writer
}
func (rw *ReadWriter) Read(p []byte) (n int, err error) {
    return rw.reader.Read(p)   // 每個方法都要來一次
}
```
直接嵌入就沒這回事：
```go
type ReadWriter struct {
    *Reader
    *Writer
}
```
`bufio.ReadWriter` 因此**同時滿足 `io.Reader`、`io.Writer`、`io.ReadWriter`** 三個介面，一行都不用寫。

### 2. ⭐ 嵌入不是繼承——差別在 receiver
> 嵌入一個型別時，它的方法會變成外層型別的方法，**但呼叫時的 receiver 是內層型別，不是外層。**

這一條是所有「以為是繼承」的誤解來源：**內層的方法看不到外層**，沒有多型覆寫、沒有 virtual dispatch。效果等同你自己手寫的那個轉發方法，不多不少。

### 3. 嵌入也可以只是圖方便
```go
type Job struct {
    Command string
    *log.Logger
}
job.Println("starting now...")   // 直接有 Logger 的方法
```

### 4. 要指名嵌入欄位時，型別名就是欄位名
去掉套件前綴即可——`job.Logger`。這在**想「加工」內層方法**時很有用：
```go
func (job *Job) Printf(format string, args ...interface{}) {
    job.Logger.Printf("%q: %s", job.Command, fmt.Sprintf(format, args...))
}
```
這是 Go 版的「包一層」，但要**自己明寫**，不會自動發生。

### 5. 名稱衝突的兩條規則
1. **淺的蓋深的**：外層的欄位或方法 `X`，會遮蔽更深層的同名 `X`。
2. **同一層同名通常是錯**：`Job` 已經有個叫 `Logger` 的欄位，就不能再嵌入 `log.Logger`。
   **但如果那個重名在型別定義之外從沒被用到，就沒事**——這條保護你不被外部型別新增欄位所波及。

### 6. ★ 介面嵌入：Go 標準庫最漂亮的用法

```go
type Reader interface{ Read(p []byte) (int, error) }
type Writer interface{ Write(p []byte) (int, error) }

// ★ 用嵌入組合出大介面，而不是重寫方法
type ReadWriter interface {
    Reader
    Writer
}
```
> ★ **這才是嵌入在 Go 裡最主要的正當用途**：**把小介面組合成大介面**。
> `io` 套件的 `ReadWriter`、`ReadCloser`、`ReadWriteSeeker` 全部這樣來的。

### 7. ★ 嵌入介面做「部分覆寫」（很好用的技巧）

```go
type loggingStore struct {
    Store                              // ★ 嵌入介面：其餘方法自動轉發
    log *slog.Logger
}

func (s loggingStore) Put(ctx context.Context, k string, v []byte) error {
    s.log.Info("put", "key", k)
    return s.Store.Put(ctx, k, v)      // ★ 只覆寫這一個
}
```
**好處**：`Store` 介面日後加方法，`loggingStore` **自動跟著有**，不用改。
**風險**：新方法會「靜默地」不被 log 到——**這是可接受的取捨，但要知道。**

★ 這正是 [[裝飾者模式]] 在 Go 裡的寫法。

### 8. ★ 嵌入的三個實務陷阱

**① 嵌入 `sync.Mutex` 會把 `Lock()/Unlock()` 變成公開 API**
```go
type Counter struct {
    sync.Mutex        // ❌ 外部可以 c.Lock() 鎖住你的物件
    n int
}
type Counter struct {
    mu sync.Mutex     // ✅ 具名私有欄位
    n  int
}
```
★ **除非你真的想讓呼叫端參與鎖定，否則一律用具名私有欄位。**

**② 嵌入會暴露被嵌入型別的「所有」匯出方法**
包含你不想要的。`Job` 嵌入 `*log.Logger` → `Job` 也有 `SetOutput`、`SetFlags`——**這些多半不該是 Job 的 API。**

**③ ★ JSON 序列化會「攤平」嵌入的欄位**
```go
type Base struct{ ID string `json:"id"` }
type User struct {
    Base                                   // ★ 嵌入
    Name string `json:"name"`
}
// 序列化結果：{"id":"...","name":"..."}   ← ★ 攤平，不是 {"Base":{...}}

type User2 struct {
    Base Base   `json:"base"`              // 具名欄位 → 巢狀
    Name string `json:"name"`
}
// {"base":{"id":"..."},"name":"..."}
```
**嵌入介面時 JSON 會用動態型別的欄位**——這常常不是你要的，而且**反序列化會失敗**（不知道要建哪個具體型別）。

## 🧪 我實際套用的紀錄
- 2026-08-28：（待填）

## ⚠️ 注意 / 什麼時候不適用

- **★★ 沒有虛擬分派**。嵌入型別的方法**永遠呼叫自己的方法**，不會分派到外層：
  ```go
  func (b Base) Greet() string { return "hi, " + b.Name() }   // b 永遠是 Base
  ```
  → **不能用嵌入模擬 [[範本方法模式]]**。要可覆寫的步驟，就用函式欄位或介面參數。
- **★ 嵌入不是「is-a」**。它只是方法轉發的語法糖。**不要為了表達分類關係而嵌入。**
- **★ 方法集的 receiver 規則**：嵌入 `T` 只帶來 `T` 的方法；嵌入 `*T` 帶來 `T` 和 `*T` 的方法。
  **介面滿足不成立時，先檢查這裡。**
- **名稱衝突**：同一層兩個嵌入型別有同名方法 → **呼叫時才編譯錯誤**（宣告時不會錯）。
- **多層嵌入會讓「這個方法從哪來」變得難追**。**兩層以上就該考慮改用具名欄位 + 明確轉發。**
- **嵌入 `context.Context` 是反模式**。context 應該當參數傳，不該存進 struct。
- **`sync.Mutex` / `sync.WaitGroup` 被嵌入後，整個 struct 就不可複製**（`go vet` 的 copylocks 會警告）。

## 🔗 相關工具
- [[工具-優先組合而非繼承]] —— ★ 嵌入是組合不是繼承，以及為什麼這件事重要
- [[工具-Go介面小而隱式]] —— 介面嵌入與方法集
- [[範本方法模式]] —— ★ 為什麼 Go 不能用嵌入模擬它
- [[裝飾者模式]] —— 嵌入介面做部分覆寫的完整說明
- [[工具-資料編碼與演進]] —— 嵌入對 JSON 序列化的影響
- [[Effective Go]]
