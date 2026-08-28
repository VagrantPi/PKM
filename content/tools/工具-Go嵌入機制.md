---
type: tool
name: "Go 嵌入機制 Embedding"
source: "[[Effective Go]]"
source_type: article
tags: [software, go, language, design]
triggers: [Go沒有繼承要怎麼重用, struct嵌入之後receiver是誰, 嵌入的方法名稱撞在一起怎麼辦, 想借用別的型別的方法, 要不要寫一堆轉發方法]
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

## 🧪 我實際套用的紀錄
- 2026-08-28：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **不要把它當繼承用**。想要「子型別覆寫父型別行為，且父型別會呼叫到覆寫版」——**Go 做不到**，那要改用介面注入。
- **嵌入會把內層的匯出方法全部提升上來**，包括你不想要的。介面契約因此可能被意外擴大；只想要幾個方法時，具名欄位加手寫轉發反而更清楚。
- **嵌入指標與嵌入值語義不同**（nil 的嵌入指標會在呼叫時 panic）。
- 這是**組合的一種語法糖**，判斷「該不該共用行為」仍然回到 [[工具-優先組合而非繼承]]。

## 🔗 相關工具
- [[工具-優先組合而非繼承]] —— 通用原則；Go 直接把它做進語言裡，連選項都沒給你
- [[工具-Go介面小而隱式]] —— 嵌入之所以威力大，是因為介面小、隱式滿足，嵌進來就自動滿足
