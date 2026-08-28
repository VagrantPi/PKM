---
type: tool
name: "Go 切片的共享與陷阱"
source: "[[Go Blog 經典六篇]]"
source_type: article
tags: [software, go, language, performance]
triggers: [append之後另一個切片的值也變了, 切片傳進函式改了外面也跟著改, 只留幾個位元組卻佔著整份檔案的記憶體, Go的slice跟array差在哪, 什麼時候該用copy]
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

## 🧪 我實際套用的紀錄
- 2026-08-29：（待填）

## ⚠️ 注意 / 什麼時候不適用
- ⚠️ **來源文章（2011）的範例用 `ioutil.ReadFile`，該套件 Go 1.16 起已整包棄用**——現在用 `os.ReadFile`。（原文：「Deprecated: As of Go 1.16, the same functionality is now provided by package io or package os」）
- **Go 1.21 起有 `slices` 套件**，`slices.Clone` 比手寫 `make` + `copy` 清楚；許多手動迴圈也有現成函式 → [[Modern Go Guidelines]]。
- **`copy` 只複製到較短的那個長度為止**，忘了先 `make` 足夠長度會靜默少複製。
- 這些是**機制層的事實，不會過期**——切片表頭與共享語義從 2011 到現在沒有改變。

## 🔗 相關工具
- [[工具-用race偵測器抓資料競爭]] —— 多個 goroutine 共用同一底層陣列是典型 race 來源
- [[Modern Go Guidelines]] —— `slices` 套件的現代替代寫法
