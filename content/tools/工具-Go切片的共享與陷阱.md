---
type: tool
name: "Go 切片的共享與陷阱"
source: "[[Go Blog 經典六篇]]"
source_type: article
tags: [software, go, language, performance]
triggers: [切片傳進函式被改到, append之後資料莫名其妙變了, 一小段切片把整個檔案釘在記憶體, nil切片和空切片差在哪, Go1.21之後切片有哪些新工具]
---

## 🎯 什麼情境該想到我
當你「**改了一個切片，另一個切片的內容也跟著變**」，或「**只留下一小段資料，記憶體卻降不下來**」的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 1. 心智模型：切片是「指向陣列的表頭」
一個切片值只有三個欄位：**指標、長度（len）、容量（cap）**。它**不擁有資料**，只是描述底層陣列的一段。
→ 所以**重新切片不會複製**，兩個切片可能指向同一塊記憶體。這是所有陷阱的根源。

### 2. 陷阱一：共享底層陣列
把切片傳進函式、或 `s[1:3]` 這樣切，**得到的是同一塊記憶體的另一個視角**。改其中一個，另一個看得到。
要真的獨立，就 `copy`：
```go
c := make([]byte, len(b))
copy(c, b)
```

### 3. ⭐ 陷阱二：一小段切片會把整塊記憶體釘住
```go
func FindDigits(filename string) []byte {
    b, _ := os.ReadFile(filename)     // 讀進整個檔案
    return digitRegexp.Find(b)        // ⚠️ 回傳的切片指向整份檔案的陣列
}
```
> 回傳的 `[]byte` 指向包含**整個檔案**的陣列……只要這個切片還在，GC 就不能釋放那個陣列；**幾個有用的位元組，讓整份檔案留在記憶體裡**。

修法就是回傳前複製一份：
```go
b = digitRegexp.Find(b)
c := make([]byte, len(b))
copy(c, b)
return c
```

### 4. append 的行為
`append` 在容量夠時**就地寫入**（會影響共用同一陣列的其他切片）；容量不夠時**配置新陣列並複製**（從此與原本脫鉤）。
**所以 `append` 之後兩個切片是否還共享，取決於當時 cap 夠不夠——這是不確定的，不要依賴它。**

### 5. ★★ 最陰險的一個：`append` 覆寫「別人的」資料

```go
base := []int{1, 2, 3, 4, 5}
a := base[:2]              // [1 2]      len=2, cap=5  ← ★ cap 是 5 不是 2
b := base[2:4]             // [3 4]

a = append(a, 99)          // ★ cap 還夠，就地寫進 base[2]
fmt.Println(b)             // [99 4]     ★ b 被改掉了！
fmt.Println(base)          // [1 2 99 4 5]
```

**根因：`s[:n]` 不會限制 cap**，所以 `append` 會往後覆寫還在被別人使用的區段。

**修法：三索引切片 `s[low:high:max]`，把 cap 釘住**
```go
a := base[:2:2]            // ★ len=2, cap=2 → append 必定重新配置，不會碰到 base
a = append(a, 99)
fmt.Println(base)          // [1 2 3 4 5]  ★ 安全
```
> ★ **回傳「內部 slice 的一段」給外部時，一定要用三索引或 `slices.Clone`。**
> 否則呼叫端一 `append` 就會默默改壞你的內部狀態。

### 6. `nil` 切片 vs 空切片

```go
var a []int              // nil：a == nil，len=0，cap=0
b := []int{}             // 非 nil：b != nil，len=0
```

| 行為 | `nil` 切片 | 空切片 |
|---|---|---|
| `len` / `cap` / `range` / `append` | ✅ 完全正常 | ✅ |
| `== nil` | **true** | **false** |
| **`json.Marshal`** | ★ **`null`** | ★ **`[]`** |

★ **JSON 那一行是實務上最常咬人的**：API 回傳 `null` 而不是 `[]`，前端就炸了。
→ **回傳 slice 的 API，要嘛保證初始化成 `[]T{}`，要嘛在前端處理 null。**
**慣例：內部用 `var s []T`（零值可用），對外序列化前確保非 nil。**

### 7. Go 1.21+ 的 `slices` 套件（別再自己寫）

```go
slices.Clone(s)                 // ★ 深一層複製，取代手寫 make+copy
slices.Delete(s, i, j)          // 刪除區間（★ 會就地搬移，原 slice 失效）
slices.Insert(s, i, v...)       // 插入
slices.Contains(s, v)           // 有沒有
slices.Index(s, v)              // 位置
slices.Sort(s) / SortFunc       // 見 [[快速排序]]
slices.BinarySearch(s, v)       // 見 [[二分搜尋]]
slices.Equal(a, b)              // 逐元素比較
slices.Reverse(s)
```
> ⚠️ **`slices.Delete` 會把後面的元素往前搬，並把尾端清零（Go 1.22 起）**——
> 原本的 slice 變數在呼叫後就**不該再使用**，要用回傳值。

### 8. ★ 記憶體釘住：`slices.Clip` 與明確複製
```go
// 大 buffer 裡只要一小段時
small := slices.Clone(big[100:110])     // ★ 徹底脫鉤，big 可被 GC
```
`slices.Clip(s)` 則是把 cap 縮到 len（釋放尾端多餘容量，但底層陣列仍是同一塊）。

## 🧪 我實際套用的紀錄
- 2026-08-29：（待填）

## ⚠️ 注意 / 什麼時候不適用

- **★★ 回傳內部 slice 的一段給外部 = 把內部狀態交出去**。用 `slices.Clone` 或三索引 `s[a:b:b]`。
- **★ 不要依賴 `append` 會不會重新配置**。cap 夠就就地改、不夠就複製——**這是實作細節，且會隨版本變**。
- **`copy` 只複製 `min(len(dst), len(src))` 個**。`dst` 沒配置長度（只有 cap）時 `copy` 會複製 0 個——
  **一定要 `make([]T, len(src))` 而不是 `make([]T, 0, len(src))`。**
- **`slices.Clone` 只複製一層**。`[][]int`、`[]*T`、`map` 欄位要再往下（見 [[原型模式]]）。
- **大 slice 傳值不貴**（只有 24 bytes 的表頭），**但傳進去被改了就是被改了**。要唯讀語義就用 `iter.Seq` 或複製。
- **★ Go 1.22 起迴圈變數每輪新建**，所以 `for _, v := range s { go func(){ use(v) }() }` 不再有「所有 goroutine 看到同一個 v」的經典 bug。**但 go.mod 的 go 版本要 ≥ 1.22 才生效。**
- **`s = append(s[:i], s[i+1:]...)` 刪除元素會留下尾端的懸掛參考**（若元素是指標）→ 記憶體洩漏。用 `slices.Delete`（它會清零）。
- **並行讀寫同一個 slice 仍然是資料競爭**。slice 本身沒有任何同步保證（見 [[工具-用race偵測器抓資料競爭]]）。

## 🔗 相關工具
- [[原型模式]] —— ★ 深淺拷貝的完整說明（哪些欄位要手動複製）
- [[鏈結串列]] —— 為什麼 Go 幾乎總是該用 slice
- [[堆疊與佇列]] —— slice 當堆疊/佇列的正確寫法與記憶體洩漏
- [[二分搜尋]]、[[快速排序]] —— `slices.BinarySearch` / `slices.Sort`
- [[工具-用race偵測器抓資料競爭]] —— 並行存取 slice
- [[工具-Go現代錯誤處理]] —— 同屬 Go 的語言細節
- [[Effective Go]]、[[Go Blog 經典六篇]]
