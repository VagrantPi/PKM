---
type: tool
name: "Go 反射三法則 Laws of Reflection"
source: "[[Go Blog 經典六篇]]"
source_type: article
tags: [software, go, language]
triggers: [要寫通用的序列化或映射, 該用反射還是泛型還是程式碼產生, 反射慢在哪裡, 反射改不動值是為什麼, 用了反射之後編譯器就不幫我檢查了]
---

## 🎯 什麼情境該想到我
當你用 `reflect`，**卡在「為什麼我改不動這個值」**的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 三條法則
**1. 反射從介面值走到反射物件。**
反射的本質就是**檢視 interface 變數裡存的那組（型別, 值）配對**。入口是兩個型別：
```go
t := reflect.TypeOf(x)    // reflect.Type
v := reflect.ValueOf(x)   // reflect.Value
```

**2. 反射從反射物件走回介面值。**
```go
i := v.Interface()   // 把型別與值資訊包回 interface{}
```
所以它是可逆的——這也是為什麼 `fmt.Println(v.Interface())` 會印出原本的值。

**3. ⭐ 要修改反射物件，這個值必須是「可設定的」（settable）。**
這是最微妙的一條，也是絕大多數 `reflect` 卡關的原因。

### 為什麼改不動：你傳的是複本
```go
var x float64 = 3.4
v := reflect.ValueOf(x)
v.SetFloat(7.1)   // ❌ panic: reflect: reflect.Value.SetFloat using unaddressable value
```
`reflect.ValueOf(x)` 拿到的是 **`x` 的一份複本**——就算能改也改不到原本的 `x`，所以 Go 直接禁止。

**解法：傳指標，再取 `Elem()`**
```go
p := reflect.ValueOf(&x)   // 這是 *float64 的複本，但它指向 x
v := p.Elem()              // 解參考 → 這個才是可設定的
v.SetFloat(7.1)            // ✅ x 變成 7.1
```
判斷用 `v.CanSet()`。

### 一個 API 慣例
為了讓 API 精簡，`Value` 的 getter／setter **操作的是能容納該值的最大型別**：所有有號整數都用 `int64`。所以 `v.Int()` 回傳 `int64`、`SetInt` 也吃 `int64`，要用實際型別時得自己轉換。

### 4. ★ 反射的成本（決定要不要用的關鍵數字）

| 成本 | 說明 |
|---|---|
| **速度** | 比直接存取**慢一到兩個數量級**。每次 `Field(i)`、`MethodByName` 都要查型別資訊 |
| **配置** | ★ `reflect.ValueOf(x)` 會讓 `x` **逃逸到 heap** → GC 壓力 |
| **編譯期檢查全失效** | 型別錯誤變成**執行期 panic**，而且常常在生產環境才爆 |
| **工具失效** | ★ **重新命名欄位時 IDE 不會幫你改 struct tag**；靜態分析看不到反射用到的欄位 |
| **可讀性** | 讀的人無法從程式碼看出「這裡會碰到哪些欄位」 |

★ **所以規則是：能不用就不用。** 但**該用的時候它不可取代**。

### 5. ★ 三個替代方案的決策表

| 需求 | 首選 | 為什麼 |
|---|---|---|
| **同樣邏輯、不同型別**（Map、Filter、Sort、Min） | ★ **泛型（Go 1.18+）** | 編譯期特化、可內聯、型別安全 |
| **大量重複的樣板程式碼**（DTO 轉換、mock、enum 字串） | ★ **程式碼產生**（`go:generate` + `stringer` / `mockgen` / `sqlc`） | **零執行期成本、可讀、可除錯、可 diff** |
| **編譯期無法得知型別**（JSON、ORM、DI 容器、template） | **反射** | 沒有別的辦法 |
| 只有幾個具體型別 | **type switch** | 最簡單直接 |

> ★ **實務上最常見的誤用**：用反射寫「通用的 struct 欄位複製」。
> **這在 Go 1.18 之後多半該用泛型或 `go:generate` 產生的程式碼**——
> 反射版又慢又不安全，而且重構時會默默壞掉。

### 6. ★ 第三法則的實務含意：什麼時候「改不動」

```go
var x float64 = 3.4
v := reflect.ValueOf(x)
v.SetFloat(7.1)                  // ★ panic: reflect: reflect.Value.SetFloat using unaddressable value

// ✅ 要傳指標，並且 Elem() 進去
v := reflect.ValueOf(&x).Elem()
v.SetFloat(7.1)                  // ok

// ★ 未匯出欄位永遠改不動（CanSet() == false），即使傳了指標
```
**三個檢查點**：`CanSet()` 為 false 時，原因只會是——**沒傳指標、沒 `Elem()`、或欄位未匯出。**

### 7. 實務上該怎麼寫反射程式碼

```go
// ★ 一定要先檢查再操作，不要直接 panic
func setField(obj any, name string, val any) error {
    v := reflect.ValueOf(obj)
    if v.Kind() != reflect.Ptr || v.IsNil() {
        return fmt.Errorf("obj must be a non-nil pointer, got %T", obj)
    }
    v = v.Elem()
    if v.Kind() != reflect.Struct {
        return fmt.Errorf("obj must point to a struct, got %s", v.Kind())
    }
    f := v.FieldByName(name)
    if !f.IsValid()  { return fmt.Errorf("no field %q on %T", name, obj) }
    if !f.CanSet()   { return fmt.Errorf("field %q is not settable (unexported?)", name) }
    rv := reflect.ValueOf(val)
    if !rv.Type().AssignableTo(f.Type()) {
        return fmt.Errorf("cannot assign %s to field %q of type %s", rv.Type(), name, f.Type())
    }
    f.Set(rv)
    return nil
}
```
★ **用反射的程式碼要「防禦性地」寫**：每一步都檢查並回傳**有用的錯誤訊息**，
而不是讓它 panic（見 [[工具-讓測試失敗訊息有用]]）。

**快取 `reflect.Type` 的分析結果**：ORM 與 JSON 庫都會把「這個型別的欄位對應」算一次存進 `sync.Map`，
**不要每次呼叫都重新走一遍欄位**——這是反射程式碼最大的效能改善點。

## 🧪 我實際套用的紀錄
- 2026-08-29：（待填）

## ⚠️ 注意 / 什麼時候不適用

- **★ 有泛型或程式碼產生能解就不要用反射**（見決策表）。
- **★ struct tag 是字串，沒有編譯期檢查**。打錯 `json:"naem"` 不會報錯，只會默默序列化成錯的名字。
  → **一定要有序列化的往返測試（marshal → unmarshal → 比對）。**
- **★ 重新命名欄位時 tag 不會跟著改**，靜態分析與 IDE 都看不到反射的使用。
  **這是「改了程式卻在執行期才爆」的主要來源之一。**
- **反射看不到未匯出欄位**（讀得到型別資訊，但 `CanSet()` 為 false）。
  → 深拷貝、diff 這類通用工具會**默默略過**未匯出欄位（見 [[原型模式]]）。
- **`reflect.DeepEqual` 不適合當測試斷言**：它對 nil vs 空 slice、未匯出欄位、函式欄位的行為常常不是你要的。
  **用 `google/go-cmp` 的 `cmp.Diff`**，它的失敗訊息也好得多。
- **反射 + 並行**：`reflect.Value` 不是並行安全的，快取型別資訊時要用 `sync.Map` 或 `sync.Once`。
- **效能敏感路徑上要量**。`pprof` 裡看到 `reflect.` 佔比高，就是該換方案的訊號。

## 🔗 相關工具
- [[工具-Go介面小而隱式]] —— 介面的 (型別, 值) 二元組是反射的基礎
- [[原型模式]] —— 反射式深拷貝的限制
- [[工具-資料編碼與演進]] —— 序列化與 struct tag
- [[工具-讓測試失敗訊息有用]] —— 反射錯誤訊息該怎麼寫
- [[訪問者模式]] —— type switch 作為反射的替代
- [[工具-程式碼調校]] —— 先量再優化
- [[Go Blog 經典六篇]]
