---
type: tool
name: "trigram 相似度搜尋"
source: "[[PostgreSQL pg_trgm]]"
source_type: article
tags: [software, database, search]
triggers: [想做你是不是要找這種拼字建議, 使用者打錯字就查不到東西, 想找名稱相近的資料, 要按相似度排序取前幾筆, 比對兩個字串有多像]
---

## 🎯 什麼情境該想到我
當你要做「**找長得像的**」——拼字容錯、去重、「你是不是要找⋯」——的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 1. 三個函式，先選對比對範圍
| 函式 | 比什麼 | 什麼時候用 |
|---|---|---|
| `similarity(a, b)` | 兩字串**整體**重疊度，0～1 | 比對整個欄位值 |
| `word_similarity(a, b)` | a 與 b 中**任一段連續 trigram** 的最大相似度 | 找**詞的一部分** |
| `strict_word_similarity(a, b)` | 同上但**切在詞邊界** | 找**完整的詞** |

文件的例子最能看出差別：
```sql
word_similarity('word', 'two words')        -- 0.8      抓到 words 裡的 word 那段
strict_word_similarity('word', 'two words') -- 0.571429 被迫整個 words 一起算
```

### 2. 用運算子查詢才吃得到索引
```sql
-- 相似度超過門檻（走索引）
SELECT t, similarity(t, 'word') AS sml
FROM test_trgm
WHERE t % 'word'
ORDER BY sml DESC, t;
```
`%`／`<%`／`<<%` 分別對應上面三個函式的門檻比較。
⚠️ **在 `WHERE` 裡直接寫 `similarity(t,'word') > 0.3` 是走不到索引的**，要用運算子。

### 3. 取「最相近的前 N 筆」用距離運算子
```sql
SELECT t, t <-> 'word' AS dist
FROM test_trgm
ORDER BY dist LIMIT 10;
```
`<->` 就是 `1 - similarity()`。
⭐ **這種寫法只有 GiST 索引做得有效率，GIN 不行。** 而且文件說：**只要少數幾筆最相近結果時，這種寫法通常比 `%` 那種寫法更快。**
對應的還有 `<<->`（word）與 `<<<->`（strict word）。

### 4. 調門檻用 GUC，不要用舊函式
```sql
SET pg_trgm.similarity_threshold = 0.3;              -- % 用，預設 0.3
SET pg_trgm.word_similarity_threshold = 0.6;         -- <% 用，預設 0.6
SET pg_trgm.strict_word_similarity_threshold = 0.5;  -- <<% 用，預設 0.5
```
⚠️ `set_limit()` 與 `show_limit()` **文件標為 deprecated**，改用上面的 `SET`／`SHOW`。

### 5. 拼字建議的完整配方（搭配全文檢索）
```sql
-- 1) 產出所有未經詞幹處理的唯一詞（刻意用 simple 設定）
CREATE TABLE words AS
SELECT word FROM ts_stat('SELECT to_tsvector(''simple'', bodytext) FROM documents');

-- 2) 在詞表上建 trigram 索引
CREATE INDEX words_idx ON words USING GIN (word gin_trgm_ops);

-- 3) 拿使用者的錯字去查相似詞
```
文件的兩個實務提醒：**再加一個「候選詞長度與錯字相近」的條件**會更準；這張詞表是靜態的**要定期重建**，但「保持完全即時通常沒有必要」。

### 除錯用
`show_trgm('cat')` 會列出實際切出來的 trigram —— 搞不懂為什麼比對不中時就先看這個。

## 🧪 我實際套用的紀錄
- 2026-09-01：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **門檻是全域 session 設定，不是每個查詢的參數**。同一個 session 裡不同查詢想要不同鬆緊度，得自己 `SET` 來回切，或改用距離運算子直接比數值。
- **短字串不準也不快**：trigram 少，相似度會失真。搜尋詞太短時考慮改用前綴比對。
- **相似不等於相關**。`similarity` 只看字面重疊，語意完全不管——需要語意相近要走向量檢索，那是另一回事。
- **預設編譯下比較不分大小寫**。
- ⚠️ **CJK 未驗證**：文件沒有針對中日韓說明，中文沒有空格分詞，效果要用自己的資料實測。

## 🔗 相關工具
- [[工具-用trigram索引加速模糊查詢]] —— 同一擴充的另一半：替既有的 `LIKE`／正規表達式查詢加速
