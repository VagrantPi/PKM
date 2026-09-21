---
type: article
title: "Google Go 風格指南"
source_url: https://google.github.io/styleguide/go/index
author: Google
site: google.github.io/styleguide
tags: [software, go, language, methodology, testing]
captured: 2026-09-20
read_status: read
---

## 📌 30 秒摘要（讀完用自己的話寫一句）
> 這套文件在講：Google 內部審 Go code 時到底依據什麼。它跟 [[Effective Go]] 的差別是——Effective Go 講「Go 為什麼長這樣」，這套講「**兩種寫法都合法時，該選哪個、依據什麼排序**」。最值得拿走的不是條目，而是它把可讀性拆成**五個有明確優先序的屬性**，以及**把文件本身分成三種權威等級**（哪些是鐵律、哪些只是建議）。

## 🗺 心智圖（Canvas）
![[Google Go 風格指南.canvas]]

## 🎯 為什麼存這套文件 / 未來想拿它做什麼
- Go 是我的主力語言。知識庫裡既有的 Go 卡多半在講「語言機制」（介面、切片、錯誤 API），缺的是**做取捨時的裁決依據**——這套補的正是這塊。
- 它的**文件分級設計本身可以偷**：把團隊規範分成「不可違反／可討論／僅供參考」三層，比一份扁平的 500 條規則好用太多。
- 錯誤處理與測試那兩章是**可以直接照做的**，而且是我既有的 [[工具-Go現代錯誤處理]] 沒有涵蓋的另一半（那張講「怎麼辨識錯誤」，這套講「該不該包、包什麼、誰負責記 log」）。

## ⚠️ 使用前要知道的三件事
1. **它明說假設你已讀過 Effective Go**：原文 "This guide assumes the reader is familiar with Effective Go"。所以它不重複講語言基礎，直接從取捨開始。
2. **有一部分是 Google 內部專用，外面照抄會踩空**：文中的 `log`（其實是 glog 變體，有 `log.Exit`、`log.V`，**沒有** `log.Panic`）、`flag`（內部變體）、`status`／canonical codes、Bazel test filter、「同一目錄多個 `go_library`」等，都是 Google 內部環境。觀念可移植，API 不能直接抄。
3. **三份文件權威等級不同，衝突時有明確優先序**（見下方「文件涵蓋範圍」）。

## 🧰 這套文件給我的工具（連到 tools/）
- [[工具-Go可讀性五原則]] — 當我「兩種寫法都合法、不知道該選哪個」或 code review 吵不出結論的時候
- [[工具-Go錯誤該包還是該轉]] — 當我在想「這個錯誤要 `%v` 還是 `%w`、要不要加字、誰負責記 log」的時候
- [[工具-讓測試失敗訊息有用]] — 當我看著紅掉的測試卻得點進原始碼才知道哪裡錯的時候
- [[工具-Go表格測試與子測試]] — 當我在貼第五個長得很像的測試案例的時候
- [[工具-Go全域狀態的判準]] — 當我想加一個 package 層級變數／註冊表／全域 client 的時候
- [[工具-Go函式參數太多怎麼辦]] — 當函式簽章越長越可怕、呼叫端出現一排 `true, false, true` 的時候

> 介面的部分（consumer 端定義介面、accept interfaces return concrete types）與既有的 [[工具-Go介面小而隱式]] 高度重疊，不另開卡；Google 補的觀點寫在下方「關鍵重點 §6」。

## 🗂 文件涵蓋範圍（共 4 頁，全部讀過）

| 頁面 | 受眾 | Normative | Canonical | 內容 |
|---|---|---|---|---|
| **Overview** | 所有人 | — | — | 三份文件的定位、canonical／normative／idiomatic 的定義 |
| **Style Guide**（guide） | 所有人 | ✅ | ✅ | 五個可讀性原則、最少機制、gofmt／MixedCaps／行長／命名／區域一致性 |
| **Style Decisions**（decisions） | Readability mentor | ✅ | ❌ | 命名細則、註解、import、錯誤、語言特性、常用函式庫、測試失敗訊息、測試結構 |
| **Best Practices**（best-practices） | 有興趣的人 | ❌ | ❌ | 錯誤結構與 `%w`、文件撰寫、變數宣告、函式參數列、測試、字串串接、全域狀態、介面設計 |

三個詞的定義（原文自己下的）：
- **Canonical**：規定性、且**不預期會變**的規則。新舊程式碼都該遵守，門檻最高，所以 canonical 文件反而最短。
- **Normative**：為了讓**審查者之間一致**而訂的。會隨時間改；**不要求寫 code 的人熟記**，是審查者的參考書。
- **Idiomatic**：普遍且好認的慣例。同樣達成目的時，慣用的優於不慣用的。

**衝突時 Style Guide 勝**，且 Decisions 要被改成跟它一致。

## ✨ 關鍵重點

### 1. ⭐ 可讀性五屬性，有明確排序
原文是「依重要性排序」的五條：

1. **Clarity（清楚）** — 讀者看得懂它在做什麼、以及**為什麼**這樣做
2. **Simplicity（簡單）** — 用最簡單的方式達成目標
3. **Concision（精簡）** — 訊噪比高
4. **Maintainability（可維護）** — 容易被下一個人正確地改
5. **Consistency（一致）** — 跟更大範圍的 codebase 一致

關鍵在最後一條的定位：**一致性不凌駕前面任何一條，但當前四條打平時，往一致性那邊倒。** 這一句就解掉大部分「要不要跟既有爛寫法保持一致」的爭論。

另外它把 Clarity 拆成兩個獨立面向——**「在做什麼」**（靠命名、切分函式、留白）與**「為什麼這樣做」**（靠註解）。而且明講註解該解釋 why 而不是 what，因為重述 what 的註解會變成雜訊與維護負擔。

### 2. ⭐ 最少機制（least mechanism）：抽象的升級階梯
同一件事有多種表達方式時，**用最標準的工具**。順序是：

1. 核心語言構件（channel、slice、map、loop、struct）
2. 標準函式庫（HTTP client、template engine）
3. 公司／專案既有的核心庫
4. 才考慮新依賴或自己造

理由原文寫得很好：**「要加複雜度隨時可以加，但發現複雜度沒必要之後要拿掉就難得多。」**

兩個具體例子：
- 要在測試裡覆蓋 flag 綁定的變數，**直接改那個變數**，不要用 `flag.Set`（除非你測的就是 CLI 本身）。
- 需要集合成員檢查，`map[string]bool` 通常就夠了；只有在需要 map 做不到或做起來很醜的操作時才引入 set 函式庫。

### 3. 區域一致性（local consistency）有明確邊界
風格指南沒規定的地方，可以照你喜歡的寫——**除非附近的程式碼（通常同檔案／同 package）已經有一致的立場**。

- **算有效的在地風格**：錯誤格式化用 `%s` 還是 `%v`；用 buffered channel 取代 mutex。
- **不算的**：自訂行長限制；使用 assertion 風格的測試函式庫。

而且有個止血條款：**如果這次改動會讓既有偏差惡化、擴散到更多檔案、露出到更多 API 表面，或真的引入 bug，「跟旁邊一致」就不再是正當理由。**

### 4. 錯誤：`%v` 與 `%w` 是一個 API 決策，不是格式選擇
- **`%v`**：把錯誤壓成字串，丟掉結構。用在「單純加註說明」「要記 log 或顯示給人看」「在系統邊界（RPC／IPC／儲存）把內部錯誤翻譯成對外的標準錯誤空間」。
- **`%w`**：建立 `Unwrap()` 鏈，讓呼叫端能用 `errors.Is`／`errors.As`。**一旦用了 `%w`，被包住的錯誤就成為你套件契約的一部分**——原文明說這該是「你明確文件化並測試過要暴露的錯誤」。

還有一條很少見但很實用的排版規則：**`%w` 放在錯誤字串結尾**（`"...: %w"`），這樣印出來的順序才會跟錯誤鏈的方向一致（新 → 舊）。**例外是哨兵錯誤**：`fmt.Errorf("%w: invalid header", ErrParse)` 放開頭，讓最重要的分類資訊最先被看到。

以及兩條幾乎每個 codebase 都在犯的：
- **不要重複底層已有的資訊**：`os` 的錯誤本來就含路徑，再寫 `"could not open settings.txt: %v"` 會印出兩次檔名。
- **`return fmt.Errorf("failed: %v", err)` 是純雜訊**——「有錯誤」這件事本身就表示失敗了，直接 `return err`。

→ 決策細節整理在 [[工具-Go錯誤該包還是該轉]]。

### 5. ⭐ 測試：失敗訊息是第一公民
整章的出發點只有一句：**不看測試原始碼就要能診斷失敗**。由此推出的一整套慣例（函式名、輸入、got 在 want 前、`t.Error` 讓測試跑完、用 `cmp.Diff` 並標明方向）整理在 [[工具-讓測試失敗訊息有用]]。

另外兩條值得單獨記：
- **不要自製 assertion library**。它把「驗證」跟「產生失敗訊息」綁在一起，結果通常是訊息更少、又因為內部呼叫 `t.Fatalf` 讓測試提早死掉。要共用邏輯就**回傳值或 error**，讓測試自己組訊息。
- **不要用錯誤字串比對來判斷錯誤種類**，那會把單元測試變成 change detector。要嘛 `errors.Is`，要嘛在 table 裡只放一個 `wantErr bool`。

### 6. 介面：消費端定義，且先別急著定義
- **介面由使用它的那一方定義**，只放它真正用到的方法。
- 三種例外（由提供方匯出介面）：介面**本身就是產品**（`io.Writer`、`hash.Hash`、protobuf 生成的 server 介面）；大型系統中為了避免每個 client 都要 import 整個實作包；避免多個 package 各自複製同一份介面造成的維護負擔。
- **Accept interfaces, return concrete types**——回傳具體型別讓呼叫端拿得到完整能力，要當介面用隨時可以傳進去。回傳介面的正當理由只有：封裝（限制 API 表面，例：`error`）、runtime 決定回傳哪個實作（factory／strategy／chaining）、打破循環依賴。
- **不要為了測試而把 RPC client 包一層手寫介面**，也**不要為了測試匯出 test double**——原文的理由很犀利：那會讓讀者從理解一個東西變成理解三個（介面、真實實作、測試替身）。

→ 與既有的 [[工具-Go介面小而隱式]] 對照著看。

### 7. Context 的兩條硬規則
- **`context.Context` 永遠是第一個參數**，而且**不要放進 struct**（唯一例外是簽章必須符合外部介面）。
- **不要自訂 context 型別，「這條規則沒有例外」**。理由是如果每個團隊都有自己的 context，任兩個 package 之間呼叫都要做轉換，自動化重構也會變成不可能。

（Go 1.24 起測試裡優先用 `(testing.TB).Context()` 而不是 `context.Background()`。）

### 8. 幾條零成本就能記住的小規則
- **錯誤字串不要大寫開頭、不要加句號**（因為它會被嵌進別的句子裡）；但**完整顯示的訊息**（log、測試失敗、UI）該大寫。
- **不要用 in-band error**（回傳 `-1`／空字串表示失敗）。多回傳一個 `ok bool` 或 `error`，順帶讓 `Parse(Lookup(key))` 這種錯誤寫法**編譯不過**。
- **錯誤流程往外推**：`if err != nil { ...; return }` 之後直接寫正常流程，不要用 `else` 把正常路徑縮排進去。
- **不要用 `math/rand` 產金鑰**，即使是用完就丟的。未 seed 完全可預測；用 `time.Nanoseconds()` seed 也只有幾個 bit 的熵。用 `crypto/rand`。
- **不要為了省幾個 byte 而傳指標**。如果函式全程只用 `*x`，那參數就不該是指標（`*string`、`*io.Reader` 是常見誤用）。大 struct 與 protobuf 訊息例外。
- **package 不要叫 `util`／`helper`／`common`**。判準是看呼叫端讀起來像什麼：`spannertest.NewDatabaseFromFile(...)` vs `test.NewDatabaseFromFile(...)`。
- **泛型別急著用**：「Write code, don't design types.」只有一種型別會被實例化時，就先別泛型化——之後要加多型很簡單，要拿掉沒必要的抽象很難。

## 💬 原文摘錄
- 可讀性的視角歸屬：
  > "Clarity is to be viewed through the lens of the reader, not the author of the code. **It is more important that code be easy to read than easy to write.**"
- 一致性的定位（我認為全套文件最有用的一句）：
  > "Consistency concerns do not override any of the principles above, but if a tie must be broken, it is often beneficial to break it in favor of consistency."
- 最少機制的理由：
  > "It is easy to add complexity to code as needed, whereas it is much harder to remove existing complexity after it has been found to be unnecessary."
- 測試章的總綱：
  > "It should be possible to diagnose a test's failure without reading the test's source."
- 無例外的規則（全套文件唯一一句這樣講的）：
  > "Do not create custom context types or use interfaces other than `context.Context` in function signatures. **There are no exceptions to this rule.**"
- 介面歸屬：
  > "The consumer of the interface should define it (not the package implementing the interface), ensuring it includes only the methods they actually use."
- 沒資訊的錯誤包裝：
  > "Don't add an annotation if its sole purpose is to indicate a failure without adding new information."
- 全域狀態：
  > "Global state should be approached with extreme scrutiny."
- 泛型：
  > "Write code, don't design types."

## 🔗 相關
- [[Effective Go]] — 這套文件明說以它為前提。兩者分工：Effective Go 講「Go 為什麼長這樣」，這套講「合法的寫法之間怎麼選」
- [[Modern Go Guidelines]] — 補的是「哪個 API 是現在的寫法」；這套不談 API 新舊，只談取捨
- [[Go Blog 經典六篇]] — 那六篇的 Errors 章已過時，這套的錯誤章可以當作它的現代替代
- [[moc/軟體工程|軟體工程]] — 語言層章節
