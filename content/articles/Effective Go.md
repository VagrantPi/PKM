---
type: article
title: "Effective Go"
source_url: https://go.dev/doc/effective_go
author: The Go Authors
site: go.dev
tags: [software, go, language, methodology]
captured: 2026-08-28
read_status: read
---

## 📌 30 秒摘要（讀完用自己的話寫一句）
> 這篇在講：Go 官方的慣用寫法指南——但它**寫於 2009 年、官方明說不再主動更新**。它今天的價值不在語法，而在**解釋 Go 為什麼長成這樣**：為什麼介面要小、為什麼用嵌入不用繼承、為什麼「靠通訊共享記憶體」。**心智模型的部分沒過期，語法與函式庫的部分過期了。**

## ⚠️ 時效性（先讀這段再讀其他）
官方在文件頂端自己標了警語，原文照抄：
> "Note: This document was written for Go's release in **2009** and **is not actively updated**. While it **remains a good guide for using the core language**, it **does not cover significant changes to the language (generics), ecosystem (modules), or libraries added since.** See issue 28782 for context."

我實際掃過全文（2517 行）核對，確認以下**完全沒有出現**：
`generics`／型別參數、`go.mod`／modules、`errors.Is`／`errors.As`、`%w` 錯誤包裝、`log/slog`、`errgroup`、range over func。

| 章節 | 現況 |
|---|---|
| Names、Interfaces、Embedding、Concurrency 的**觀念** | ✅ **仍然成立**，而且是最好的來源 |
| Formatting（`gofmt`）、Semicolons、MixedCaps | ✅ 仍然成立 |
| **Errors** | ❌ **明顯過時**：它教你用 type switch／type assertion 去辨識錯誤，而 Go 1.13 之後正解是 `errors.Is`／`errors.As`。這正是 [[Modern Go Guidelines]] 裡標為 **Critical** 的 `erris` 診斷 |
| **Concurrency 的範例寫法** | ⚠️ **觀念對、寫法舊**：手動用 channel 計數等待，現在有 `sync.WaitGroup.Go`（1.25）與 `errgroup` |
| 泛型能解決的地方（如 `Generality` 章的抽象手法） | ⚠️ 有些在 1.18 之後有更直接的寫法 |
| modules、依賴管理、工具鏈 | ❌ 完全沒提 |

**結論：值得讀，但要跟 [[Modern Go Guidelines]] 搭配著看。**
- **Effective Go** 回答「**為什麼這樣設計**」——心智模型，變得慢。
- **Modern Go Guidelines** 回答「**現在該怎麼寫**」——語法與 API，變得快。

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- Go 是我的主力語言之一，但知識庫裡的軟體工程卡幾乎都是語言無關的。這篇補的是 **Go 特有的設計直覺**。
- 從別的語言帶過來的習慣（繼承、getter 命名、用鎖保護共享變數）在 Go 裡都會卡住，這篇解釋卡在哪。
- **它的過時本身也是有用的資訊**：知道哪幾章不能信，比整篇不讀更有價值。

## 🧰 這篇給我的工具（連到 tools/ 工具卡）
- [[工具-Go命名慣例]] — 當我在想「這個 package／介面／getter 該叫什麼」的時候
- [[工具-Go介面小而隱式]] — 當我在想「這個介面該放幾個方法、建構函式該回傳什麼」的時候
- [[工具-Go嵌入機制]] — 當我想「借用別的型別的行為」的時候
- [[工具-靠通訊共享記憶體]] — 當我在 goroutine 之間傳資料、猶豫該用 channel 還是 mutex 的時候

## ✨ 關鍵重點（仍然成立的部分）
- **命名有語義效果**：首字母大小寫**決定可見性**，這在多數語言裡只是風格，在 Go 裡是語言規則。
- **用套件結構幫你命名**：`bufio` 裡的型別叫 `Reader` 不叫 `BufReader`，因為使用者看到的是 `bufio.Reader`。「長名字不會自動讓東西更好讀。」
- **介面小到只有一兩個方法是常態**，而且**隱式滿足**——型別不需要宣告自己實作了什麼。
- **只為了實作某介面而存在的型別，不必匯出**；建構函式回傳介面而非具體型別，換演算法就只是換一次建構呼叫。
- **嵌入不是繼承**：方法會被提升到外層，但**呼叫時的 receiver 是內層型別，不是外層**。這一條是所有「以為是繼承」的誤解來源。
- **並行的標語**：「不要透過共享記憶體來通訊；要**透過通訊來共享記憶體**。」
- 而且原文自己就給了那條標語的邊界：**"This approach can be taken too far."**——引用計數之類的，用 mutex 包一個整數反而best。

## 💬 原文摘錄
- 最有名的那句：
  > "Do not communicate by sharing memory; instead, share memory by communicating."
- 但緊接著的自我節制（很多人只記前半句）：
  > "This approach can be taken too far. Reference counts may be best done by putting a mutex around an integer variable, for instance."
- 關於命名長度：
  > "Long names don't automatically make things more readable. A helpful doc comment can often be more valuable than an extra long name."
- 關於嵌入與繼承的關鍵差異：
  > "There's an important way in which embedding differs from subclassing. When we embed a type, the methods of that type become methods of the outer type, but **when they are invoked the receiver of the method is the inner type, not the outer one**."
- 關於 Go 程式該怎麼寫：
  > "A straightforward translation of a C++ or Java program into Go is unlikely to produce a satisfactory result — Java programs are written in Java, not Go."

## 🔗 相關
- [[Go Blog 經典六篇]] — 同期官方素材的逐篇查證；它的 Errors 章與這篇一樣停在 2009 年的做法
- [[Modern Go Guidelines]] — **一定要搭配看**：那份補的正是這篇沒有的現代語法與 API
- [[moc/軟體工程|軟體工程]] — 語言層章節
