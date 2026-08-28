---
type: tool
name: "Go 命名慣例"
source: "[[Effective Go]]"
source_type: article
tags: [software, go, language, naming]
triggers: [Go的package該怎麼取名, getter要不要加Get, Go的介面名稱怎麼取, Go要用底線還是駝峰, 型別名跟套件名重複很囉唆]
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

## 🧪 我實際套用的紀錄
- 2026-08-28：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **長名字不會自動讓東西更好讀**。原文的說法：一段有幫助的 doc comment，往往比一個更長的名字更有價值。
- **不要用 `import .`**：它能簡化「必須在被測套件外執行」的測試，但其他情況一律避免。
- 這幾條是**慣例不是編譯規則**，所以 linter 不一定會擋——但違反它們的程式碼對其他 Go 開發者來說會很刺眼。
- 從 Java／C# 過來最常帶錯的兩個習慣：`GetXxx()` 與在型別名裡重複模組名。

## 🔗 相關工具
- [[工具-Go介面小而隱式]] —— `-er` 命名慣例背後的前提是「介面很小」
- [[工具-有意義的命名]] —— 語言無關的命名原則；這張是 Go 特有的落地版
- [[Modern Go Guidelines]] —— 命名以外的現代寫法對照表
