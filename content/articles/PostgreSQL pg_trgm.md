---
type: article
title: "PostgreSQL pg_trgm"
source_url: https://www.postgresql.org/docs/current/pgtrgm.html
author: Oleg Bartunov, Teodor Sigaev, Alexander Korotkov
site: postgresql.org
tags: [software, database, search, performance]
captured: 2026-09-01
read_status: read
---

> 對照的是 **PostgreSQL 18** 現行文件（`/docs/current/`，2026-08 發布 18.6）。**這次沒有時效問題**——不像那些 2010 年代的部落格文章，官方文件會跟著版本走。

## 📌 30 秒摘要（讀完用自己的話寫一句）
> 這篇在講：`pg_trgm` 這個內建擴充——把字串切成**連續三字元的片段（trigram）**，用「兩個字串共用多少 trigram」來衡量相似度。它做兩件事：**模糊比對**（找長得像的字串）與**替 `LIKE '%foo%'` 建索引**。後者是很多人不知道的殺手級用途：**B-tree 對前面沒錨定的 `LIKE` 完全無能為力，trigram 索引可以。**

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- 「搜尋框輸入片段要找資料」是後端最常見的需求之一，而預設寫法 `LIKE '%keyword%'` 一定全表掃描。這是標準解法，而且**不用額外裝搜尋引擎**。
- 「你是不是要找⋯」這種拼字建議，用它就能做，不必接外部服務。
- 它是 **trusted 模組**——有 `CREATE` 權限的非超級使用者就能裝，不必找 DBA。

## 🧰 這篇給我的工具（連到 tools/ 工具卡）
- [[工具-用trigram索引加速模糊查詢]] — 當我的 `LIKE '%keyword%'` 查詢慢到不行的時候
- [[工具-trigram相似度搜尋]] — 當我要做「找相似的」「你是不是要找⋯」的時候

## ✨ 關鍵重點

### trigram 到底是什麼（這個細節決定它什麼時候有效）
> 每個「詞」在取 trigram 時，會被**前面補兩個空格、後面補一個空格**。

所以 `'cat'` 的 trigram 集合是 **`" c"`、`" ca"`、`"cat"`、`"at "`** —— 四個，不是一個。
`'foo|bar'` 是 `" f"`、`" fo"`、`"foo"`、`"oo "`、`" b"`、`" ba"`、`"bar"`、`"ar "` ——**非文字字元（非英數）被忽略**，等於切成兩個詞各自處理。

**推論：字串越短，trigram 越少，索引越沒力。** 兩個字元的搜尋字串幾乎榨不出 trigram。

### 三種相似度函式，差別在「比對範圍」
| 函式 | 比什麼 |
|---|---|
| `similarity(a, b)` | 兩個字串**整體**的 trigram 重疊，0～1 |
| `word_similarity(a, b)` | a 與 b 中**任一段連續 trigram** 的最大相似度（可以是詞的一部分） |
| `strict_word_similarity(a, b)` | 同上，但**強制切在詞邊界上** |

文件的例子把差別講得很清楚：
```
word_similarity('word', 'two words')        → 0.8
strict_word_similarity('word', 'two words') → 0.571429
similarity('word', 'words')                 → 0.571429
```
`word_similarity` 抓到的是 `words` 裡的 `word` 那一段（0.8）；`strict_` 被迫整個 `words` 一起算，就掉到 0.571。
**要比對完整的詞用 `strict_`，要比對詞的一部分用 `word_similarity`。**

### 索引能加速的不只相似度
GiST／GIN 的 trigram opclass 除了相似度運算子，**還支援 `LIKE`、`ILIKE`、`~`、`~*`、`=` 的索引搜尋**：
- **`LIKE`／`ILIKE` 自 9.1 起**——`WHERE t LIKE '%foo%bar'` 可以走索引。
- **正規表達式 `~`／`~*` 自 9.3 起**——`WHERE t ~ '(foo|bar)'` 也可以。
- 關鍵優勢：**搜尋字串不需要靠左錨定**，這正是 B-tree 做不到的地方。

⚠️ 但有個硬限制：**榨不出 trigram 的樣式會退化成全索引掃描。**

### GiST 與 GIN 的實質差異（不只是「效能特性不同」）
文件明確點出一個功能差異：**`ORDER BY t <-> 'word' LIMIT 10` 這種取最近 K 筆的查詢，GiST 做得很有效率，GIN 不行。**
另外 `gist_trgm_ops` 有 `siglen` 參數（預設 12 bytes，可設 1–2024）：**簽章越長比對越精準（掃更少索引、更少 heap page），代價是索引更大。**

### 拼字建議的做法（跟全文檢索搭配）
1. 用 `ts_stat` 產一張所有**未經詞幹處理**的唯一詞表（刻意用 `simple` 設定，不用語言特定設定）。
2. 在那張詞表上建 GIN trigram 索引。
3. 對使用者的錯字做相似度查詢，就得到建議詞。
4. **文件自己提醒**：這張詞表是靜態的，要定期重建；但「保持完全即時通常沒有必要」。
   另外建議加一個條件——**要求候選詞的長度與錯字相近**。

## 💬 原文摘錄
- 核心概念：
  > "A trigram is a group of three consecutive characters taken from a string. We can measure the similarity of two strings by counting the number of trigrams they share."
- 最實用的一句（為什麼它能贏 B-tree）：
  > "Unlike B-tree based searches, **the search string need not be left-anchored**."
- 最重要的警告：
  > "For both LIKE and regular-expression searches, keep in mind that **a pattern with no extractable trigrams will degenerate to a full-index scan**."
- GiST／GIN 的功能差異：
  > "This can be implemented quite efficiently by GiST indexes, **but not by GIN indexes**."

## 🔗 相關
- [[工具-儲存引擎B-Tree與LSM-Tree]] — 懂 B-tree 為什麼幫不上 `LIKE '%x%'`，才知道 trigram 索引補的是什麼
- [[moc/軟體工程|軟體工程]]
