---
type: reference
name: "重複的 switch Repeated Switches"
source: "[[重構]]"
source_type: book
tags: [refactoring, code-smell]
triggers: [同一組 switch/if-else 依型別分支在好幾處出現, 新增一種型別要去很多地方補 case, 到處看到 switch(type), 一連串 if 在判斷同一個型別碼]
---

## 🎯 什麼情境該想到我
當你「同樣一組依型別（或型別碼）分支的 switch / if-else，在程式的好幾個地方重複出現」的時候——每次新增一種型別，都得記得去每一處補上對應的 case。

## ⚙️ 怎麼用（步驟 / 公式）
這味道是什麼徵兆：重複的 switch 讓「新增一種型別」變成散彈式的苦工——漏補一處就出錯。它是一種特別惱人的重複：同一個分類判斷邏輯被複製到多處。

通常用哪些重構手法對治：
- **以多型取代條件式（Replace Conditional with Polymorphism）**：讓每種型別成為一個類別，各自實作對應行為；原本重複的 switch 由多型分派取代。新增型別時，只要加一個類別，不必回去改每個 switch。
- 前置作業常搭配**以子類取代型別碼**、**以多型取代型別碼**。

### ★ 怎麼具體認出來

```bash
# ★ 找出對同一個欄位做 switch 的所有位置
grep -rn 'switch.*\.Kind' --include='*.go' . | sed 's/:.*switch/ → switch/'
# ★ 更準的做法：數 case 標籤的出現次數
grep -rhoE 'case Kind[A-Za-z]+' --include='*.go' . | sort | uniq -c | sort -rn
#   ★ 如果 KindCreated 出現 6 次，就是 6 個地方在分派同一組型別
```
**最硬的證據**：問「上次加一種 Kind，動了哪些檔案？」——`git show --stat` 那個 commit。

```bash
# golangci-lint（2026-09-24 查證的官方清單）
#   exhaustive        —— ★ 檢查 enum switch 的窮盡性（針對具名常數型別）
#   gochecksumtype    —— 檢查 sum type switch 的窮盡性
```
★ **`exhaustive` 是這個味道在 Go 裡最高槓桿的一招**：
它讓「漏補一個 case」變成 CI 失敗，**成本遠低於重構成多型**。

### ★★ 為什麼會痛 vs 為什麼常常不該重構

```go
// ★ 痛：加一種 Kind 要改六個地方，漏一個不會報錯
// handler.go   switch e.Kind { … }
// validator.go switch e.Kind { … }
// metrics.go   switch e.Kind { … }
// audit.go     switch e.Kind { … }
```

**但改成多型的代價同樣真實：**
```go
// ★ 重構後：一眼看完「所有 Kind 怎麼被處理」的能力消失了
type Event interface {
    Handle(context.Context) error
    Validate() error
    MetricName() string
    AuditRecord() Record
}
// ★ 現在 Created / Updated / Deleted 各自一個型別，
//   想知道「metrics 怎麼命名」得開三個檔案
```

> ★★ **判準不是「有幾個 switch」，是「這兩個維度哪一個變化得比較頻繁」**：
>
> | 常變的是什麼 | 該怎麼做 |
> |---|---|
> | ★ **常加「新的型別」**（新 Kind） | **多型**——加一個型別就好，不用碰既有的 |
> | ★ **常加「新的操作」**（新的 switch） | ★ **保留 switch**——加一個函式就好，不用碰既有的 N 個型別 |
> | 兩者都常變 | 沒有好答案（這是「表達式問題」）→ 選變化較快的那一維 |
>
> **這是最重要的一段。** 「重複的 switch」被當成味道，是因為 GoF 那個年代假設「型別常增加」；
> 但在很多實際系統裡，**型別是固定的（三種事件、五種狀態），操作才一直增加**——
> 那時 switch 是正確答案，而多型會讓你每加一個操作就要改五個型別。

### ★ Go 特有的三個現實

```go
// ① ★★ Go 沒有窮盡檢查（語言層面）
switch e.Kind {
case KindCreated: …
// ★ 漏了 KindDeleted —— 編譯器不會說話
}
// → 一定要寫 default
default:
    return fmt.Errorf("unhandled kind %v", e.Kind)      // ★ 至少讓它大聲失敗

// ② ★ 分派表 + 覆蓋率測試：實務上最划算的折衷
var handlers = map[Kind]func(Event) error{ … }
func TestAllKindsHandled(t *testing.T) {
    for _, k := range AllKinds {
        if _, ok := handlers[k]; !ok { t.Errorf("missing handler for %v", k) }
    }
}
// ★ 這個測試把「編譯期窮盡檢查」換成「CI 窮盡檢查」，成本是十行

// ③ 封印介面：讓外部 package 無法新增實作
type Event interface { Handle() error; isEvent() }       // ★ 未匯出方法
```

### ★ TypeScript 完勝：判別聯集 + `never`
```ts
switch (e.kind) {
  case 'created': …
  default: { const _: never = e; return _; }    // ★★ 漏一個 case → 編譯錯誤
}
```
> ★ **在 TS 裡這個味道幾乎不成立**：窮盡檢查解掉了「漏改」這個唯一的真痛點，
> 而「所有分支在一起」比散到五個類別更好讀。→ 見 [[工具-判別聯集]]。

### ★ 對治的決策順序
```
能開 exhaustive linter 嗎？ ── 能 ─▶ ★ 先開它。可能就不需要重構了
      │不能／已開但仍然痛
型別常增加，操作固定？ ── 是 ─▶ [[以多型取代條件式]]（前置：[[以子類取代型別碼]]）
      │否（操作常增加）
★ 保留 switch，但用分派表 + 覆蓋率測試收攏
      │
switch 內容只是「查表」？ ─▶ 換成 map[Kind]T，連 switch 都不需要
```

## 🧪 我實際套用的紀錄
- （待填）

## ⚠️ 注意 / 什麼時候不適用
- 若整個系統只有「一處」switch，且分支邏輯簡單，直接用 switch 反而清楚，未必要引入多型體系。
- 現代語言的 switch 已比以往清爽；味道的重點在「重複」而非 switch 本身。

- **★★ 判準是「型別常增加還是操作常增加」**。操作常增加時，switch 才是正確答案，多型會讓每加一個操作都要改 N 個型別。
- **★ 先開 `exhaustive` linter**。讓漏改變成 CI 失敗，成本遠低於重構。
- **★ 重構成多型會失去「一眼看完所有分支」的能力**，這是真實的代價。
- **★ Go 沒有窮盡檢查**。一定要寫 `default` 讓未處理的情況大聲失敗。
- **分派表 + 覆蓋率測試是最划算的折衷**（十行測試換 CI 窮盡檢查）。
- **只有一處 switch 不是味道**。味道的重點在「重複」而非 switch 本身。
- **★ 在 TypeScript 裡通常不該重構**——判別聯集 + `never` 已經解掉真痛點。

## 🔗 相關工具
- [[基本型別偏執|基本型別偏執 Primitive Obsession]]（型別碼常是該被物件化的訊號）
- [[重複程式碼|重複程式碼 Duplicated Code]]（重複的 switch 是重複的一種特例）
- [[重構]]
- [[以多型取代條件式]] —— 型別常增加時的對治
- [[以子類取代型別碼]] —— 前置步驟
- [[霰彈式修改]] —— 這是它最常見的具體形態
- [[工具-判別聯集]] —— ★ TS 的窮盡檢查
- [[基本型別偏執]] —— 型別碼用 string 是另一個問題
- [[策略模式]] —— 單一操作的分派
