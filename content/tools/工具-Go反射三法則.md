---
type: tool
name: "Go 反射三法則 Laws of Reflection"
source: "[[Go Blog 經典六篇]]"
source_type: article
tags: [software, go, language]
triggers: [用reflect改不動值, 不知道reflect.Value跟reflect.Type差在哪, 想從interface拿出實際型別, reflect設值時panic說unaddressable, 該不該用反射]
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

## 🧪 我實際套用的紀錄
- 2026-08-29：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **能不用就不用**。反射會失去編譯期型別檢查、變慢、而且讓程式難讀。**Go 1.18 起有泛型，很多以前只能靠反射的抽象現在有型別安全的寫法。**
- **反射錯誤多半是執行期 panic**，不是編譯錯誤——所以要有測試覆蓋。
- **未匯出欄位不可設定**，即使透過指標也一樣。
- 三法則本身是**語言層的事實，沒有過期**；但周邊 API 有增補（例如 `reflect.TypeFor`，Go 1.22）→ [[Modern Go Guidelines]]。

## 🔗 相關工具
- [[工具-Go介面小而隱式]] —— 反射操作的就是 interface 裡那組（型別, 值）；先懂介面才懂反射
- [[Modern Go Guidelines]] —— `reflecttypefor` 診斷
