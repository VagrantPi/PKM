---
type: tool
name: "儲存引擎：B-Tree vs LSM-Tree"
source: "[[資料庫底層原理]]"
source_type: book
tags: [software, database, storage-engine, performance]
triggers: [選哪種資料庫, 讀多還是寫多, 資料庫為何寫很快讀很慢, 寫放大, 該用RocksDB還是MySQL, 儲存引擎差異]
---

## 🎯 什麼情境該想到我
當你在選資料庫/儲存引擎，或想理解「為什麼某個 DB 寫很快但讀較慢（或相反）」時。

## ⚙️ 怎麼用（依讀寫特性選）
1. **B-Tree（就地更新）**：資料原地排序更新，**讀優化**、範圍查詢好；寫入需隨機 I/O。傳統關聯式 DB（MySQL InnoDB…）。
2. **LSM-Tree（追加寫）**：寫入先進記憶體，再批次刷成不可變的 **SSTable**，背景合併（compaction）。**寫優化**、順序 I/O 快；讀要查多層 + 靠 **Bloom filter** 加速。RocksDB、Cassandra、LevelDB…
3. **用「三種放大」判斷取捨**：讀放大、寫放大、空間放大——沒有引擎三者全贏。**寫重 → LSM；讀重/範圍查多 → B-Tree。**

## 🧪 我實際套用的紀錄
- 2026-07-15：（待填）

## ⚠️ 注意
- LSM 的 compaction 會吃 I/O、造成延遲抖動；B-Tree 的頁分裂會造成寫放大。按工作負載實測。

## 🔗 相關工具
- [[工具-預寫日誌與崩潰復原]]、[[工具-可靠可擴展可維護]]
