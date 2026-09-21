---
type: tool
name: "Go 表格測試與子測試"
source: "[[Google Go 風格指南]]"
source_type: article
tags: [software, go, testing]
triggers: [一堆長得很像的測試案例重複貼, 子測試的名字該怎麼取, 想用-run只跑其中一個案例, 表格的迴圈裡開始長出if判斷, 測試案例要不要拆成兩個測試函式]
---

## 🎯 什麼情境該想到我
當你正在**貼第四、第五個長得幾乎一樣的測試函式**，或是表格測試的迴圈裡開始長出 `if` 的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 1. 什麼時候該用表格測試
兩種情況：
- 驗證**輸出等於預期**（像 `fmt.Sprintf` 的那堆測試）。
- 驗證**輸出恆滿足同一組不變量**（像 `net.Dial` 的測試）。

共同前提是**測試邏輯相同**，只有資料不同。

最小結構就長這樣，不一定要子測試：
```go
func TestCompare(t *testing.T) {
    compareTests := []struct {
        a, b string
        want int
    }{
        {"", "", 0},
        {"a", "", 1},
        {"abc", "ab", 1},
        // test runtime·memeq's chunked implementation
        {"abcdefghi", "abcdefghj", -1},
    }
    for _, test := range compareTests {
        got := Compare(test.a, test.b)
        if got != test.want {
            t.Errorf("Compare(%q, %q) = %v, want %v", test.a, test.b, got, test.want)
        }
    }
}
```
注意失敗訊息**報出了函式名與輸入**，所以**不需要再報「第幾列」**。（訊息規則見 [[工具-讓測試失敗訊息有用]]。）

### 2. ⭐ 子測試名字要像識別字，不是像句子
`t.Run` 的第一個參數會進到測試輸出、也會被 `-run` 與 Bazel test filter 用來篩選。所以：

- 想成**函式名**，不是散文描述。
- **測試執行器會把空白換成底線、跳脫非可列印字元**，所以避免這些字元，log 才對得回原始碼。
- **斜線最毒**——它對 test filter 有特殊意義：
  ```bash
  # 假設 TestTime 裡有 t.Run("America/New_York", ...)
  bazel test :mytest --test_filter="Time/New_York"    # 什麼都沒跑！
  bazel test :mytest --test_filter="Time//New_York"   # 對，但很難打
  ```

```go
// Bad
t.Run("check that there is no mention of scratched records or hovercrafts", ...)
t.Run("AM/PM confusion", ...)

// Good
t.Run("hu=en_bug-1234", ...)
```

**需要長描述時，另開一個欄位**，在失敗訊息裡印出來：
```go
data := []struct {
    name, desc, srcLang, dstLang, srcText, wantDstText string
}{
    {
        name:        "hu=en_bug-1234",
        desc:        "regression test following bug 1234. contact: cleese",
        srcLang:     "hu",
        srcText:     "cigarettát és egy öngyújtót kérek",
        dstLang:     "en",
        wantDstText: "cigarettes and a lighter please",
    },
}
for _, d := range data {
    t.Run(d.name, func(t *testing.T) {
        got := Translate(d.srcLang, d.dstLang, d.srcText)
        if got != d.wantDstText {
            t.Errorf("%s\nTranslate(%q, %q, %q) = %q, want %q",
                d.desc, d.srcLang, d.dstLang, d.srcText, got, d.wantDstText)
        }
    })
}
```

### 3. 子測試之間不可以互相依賴
子測試**必須能被單獨執行**（`go test -run` 或 Bazel filter 隨時會只跑其中一個），所以不能依賴別的案例先跑過、也不能依賴前一個案例留下的狀態。

### 4. ⭐ 迴圈裡開始長 `if`，就該拆成多個測試函式
這是最實用的判準。表格測試的價值來自**所有列走同一條邏輯**；一旦列的值開始決定迴圈裡走哪條分支，可讀性就開始崩。

可以容忍的程度（簡單的錯誤檢查、不製造分支邏輯）：
```go
for _, test := range tests {
    got, err := Divide(test.dividend, test.divisor)
    if (err != nil) != test.wantErr {
        t.Errorf("Divide(%d, %d) error = %v, want error presence = %t",
            test.dividend, test.divisor, err, test.wantErr)
    }
    if err != nil {
        continue   // 這裡只驗成功情況的值
    }
    if got != test.want {
        t.Errorf("Divide(%d, %d) = %d, want %d", test.dividend, test.divisor, got, test.want)
    }
}
```
原文提醒：**今天看起來很單純的東西，會有機地長成無法維護的東西。**

該拆的時候就拆成兩個表格測試函式——一個測正常輸出、一個測錯誤輸入。若「邏輯不同但 setup 相同」，則改用一連串子測試會更好讀。

### 5. ⭐ 不要把「用哪個依賴」放進表格欄位
這是 data-driven 的經典陷阱：把 setup 的選擇塞進資料列，讀的人就得在腦中模擬才知道這一列跑的是哪個版本。

```go
// Bad: codex 欄位讓每一列的 setup 都不一樣
type decodeCase struct {
    name   string
    input  string
    codex  testCodex   // fake 還是 real？要回去查表
    output string
    err    error
}
```

正解是**共用資料列型別，但寫兩個測試函式**，各自決定依賴：
```go
// Good
type decodeCase struct {
    name   string
    input  string
    output string
    err    error
}

func TestDecode(t *testing.T) {
    codex := setupCodex(t)        // 真的（慢）
    for _, test := range tests {
        t.Run(test.name, func(t *testing.T) { /* ... */ })
    }
}

func TestDecodeWithFake(t *testing.T) {
    codex := newFakeCodex()       // 假的（快）
    for _, test := range tests {
        t.Run(test.name, func(t *testing.T) { /* ... */ })
    }
}
```
重複兩段迴圈看起來不 DRY，但**這份重複換來的清楚是值得的**。

### 6. 子測試裡用 `t.Fatal`，沒子測試用 `t.Error` + `continue`
- 用了 `t.Run`：`t.Fatal` 只結束當前子測試，其他列照跑。
- 沒用 `t.Run`：`t.Fatal` 會終止整個測試函式，所以要 `t.Error` 後面接 `continue`。
- 表格迴圈**之前**的整體 setup 失敗，用 `t.Fatal` 是對的。

## 🧪 我實際套用的紀錄
- 2026-09-20：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **子測試不是必需品。** 原文明說「可以很有用，但不是強制的」。案例少、不需要個別篩選時，純表格就夠。
- **表格不是萬用錘。** 測試邏輯本身不同的案例，本來就該是不同的測試函式。
- 斜線那條在純 `go test -run` 下也成立（`-run` 用 `/` 分隔子測試層級）。
- 表格列裡塞太多欄位本身就是訊號：可能是被測函式的參數太多（見 [[工具-Go函式參數太多怎麼辦]]），或是這個表格該拆了。

## 🔗 相關工具
- [[工具-讓測試失敗訊息有用]] —— 表格測試的失敗訊息規則全在那張
- [[工具-Go全域狀態的判準]] —— 「子測試不可互相依賴」失守最常見的原因就是全域狀態
- [[工具-DRY原則]] —— 對照：這裡刻意容許重複，因為清楚優先於不重複
