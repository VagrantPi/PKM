---
type: tool
name: "用 trigram 索引加速模糊查詢"
source: "[[PostgreSQL pg_trgm]]"
source_type: article
tags: [software, database, performance, search]
triggers: [LIKE前後都有百分號查詢很慢, 搜尋框輸入片段就全表掃描, 建了索引但LIKE還是沒用到, 正規表達式查詢跑不動, 不想為了搜尋另外裝Elasticsearch]
---

## 🎯 什麼情境該想到我
當你的 `WHERE col LIKE '%keyword%'` **慢到不能用**，而且你發現**加了 B-tree 索引也沒用**的時候。

**原因**：B-tree 只能從字串開頭比對，所以 `LIKE 'abc%'` 走得到索引，`LIKE '%abc%'` 走不到——它只能全表掃描。

## ⚙️ 怎麼用（步驟 / 公式）

### 1. 裝擴充
```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```
它是 **trusted 模組**——有該資料庫 `CREATE` 權限的一般使用者就能裝，不需要超級使用者。

### 2. 建索引，先決定 GiST 還是 GIN
```sql
-- GIN：查詢較快，索引較大、建得較慢。一般模糊查詢的預設選擇
CREATE INDEX trgm_idx ON test_trgm USING GIN (t gin_trgm_ops);

-- GiST：索引較小，且支援 KNN 排序
CREATE INDEX trgm_idx ON test_trgm USING GIST (t gist_trgm_ops);
```

⭐ **決定性的功能差異，不只是效能**：
`ORDER BY t <-> 'word' LIMIT 10`（取最相近的 K 筆）**GiST 做得很有效率，GIN 做不到**。
要做「最相近前 N 筆」就選 GiST；只做布林式的比對就用 GIN。

GiST 還可調簽章長度（預設 12 bytes，範圍 1–2024）：
```sql
CREATE INDEX trgm_idx ON test_trgm USING GIST (t gist_trgm_ops(siglen=32));
```
**越長越精準（掃更少索引與 heap page），代價是索引更大。**

### 3. 這些查詢現在都能走索引了
```sql
SELECT * FROM test_trgm WHERE t LIKE '%foo%bar';   -- 9.1 起
SELECT * FROM test_trgm WHERE t ILIKE '%foo%';
SELECT * FROM test_trgm WHERE t ~ '(foo|bar)';     -- 正規表達式，9.3 起
```
運作方式是**從搜尋字串（或正規表達式）抽出 trigram，再去索引裡查**。
**搜尋字串抽得出的 trigram 越多，索引越有效。**

### 4. 驗證它真的有用到
```sql
EXPLAIN ANALYZE SELECT * FROM test_trgm WHERE t LIKE '%foo%';
```
沒看到 Bitmap Index Scan 就是沒吃到索引——多半是下一節的原因。

## 🧪 我實際套用的紀錄
- 2026-09-01：（待填）

## ⚠️ 注意 / 什麼時候不適用
- 🔴 **抽不出 trigram 的樣式會退化成全索引掃描**（文件原文）。
  記住 trigram 的取法：每個詞前補兩空格、後補一空格，`'cat'` → `" c"`、`" ca"`、`"cat"`、`"at "`。
  **所以搜尋字串太短（一兩個字元）幾乎沒有效果**，`LIKE '%a%'` 這種等於沒索引。
- **非英數字元會被忽略**：`'foo|bar'` 被當成兩個詞處理。
- **不支援不等式運算子**；而且**做等值比對時未必比 B-tree 有效率**——需要等值查詢就照常建 B-tree，兩種索引可以並存。
- **預設編譯下比較是不分大小寫的**，所以 `LIKE` 與 `ILIKE` 行為會比你預期的接近。
- **索引不是免費的**：GIN 索引在寫入密集的表上維護成本明顯，上線前量寫入延遲。
- ⚠️ **中日韓文字的效果我沒有驗證過**。文件只說「對許多自然語言有效」，沒有針對 CJK 說明；中文沒有空格分詞，trigram 的切法與效果**要拿你自己的資料實測**再決定，別直接假設可用。

## 🔗 相關工具
- [[工具-trigram相似度搜尋]] —— 同一個擴充的另一半：不是加速既有查詢，而是做「找相似的」
- [[工具-儲存引擎B-Tree與LSM-Tree]] —— 懂 B-tree 為什麼只能靠左錨定，才知道這張補的是什麼
