---
type: tool
name: "Transactional Outbox Pattern"
source: "[[擋下用Upsert修RaceCondition的PR]]"
source_type: article
tags: [backend, message-queue, architecture, consistency]
triggers: [寫完資料庫再發訊息中間掛了怎麼辦, 雙寫問題要怎麼解, Outbox的relay要怎麼實作, CDC跟輪詢outbox哪個好, 訂單建了但事件沒發出去]
---

## 🎯 什麼情境該想到我
當你的流程是「寫 DB + 發一則 MQ / event」，而兩者可能不同步時（訊息比 commit 早到、或 commit 成功但發送失敗）。
> 症狀：worker 收到 message，去 DB 卻查不到對應資料。

## ⚙️ 怎麼用（三個層次，由淺到深）
1. **最小修法**：把發送**移出** transaction，commit 成功後才發。
   ```ts
   const order = await prisma.$transaction(tx => tx.order.create({ data }))
   await sendMessageToMq(order.id) // commit 之後才發送
   ```
   → 仍留邊界：commit 成功但 send 失敗（crash/網路），訊息遺失。
2. **Outbox Pattern**（嚴謹解）：把「業務寫入」與「事件記錄」放**同一個 transaction**：
   ```ts
   await prisma.$transaction(async tx => {
     const order = await tx.order.create({ data })
     await tx.outbox.create({ data: { topic: "order.created", payload: { orderId: order.id } } })
   })
   // 另有獨立 relay（polling 或 CDC）讀 outbox 表再發到 MQ
   ```
   → DB commit 與 event 產生變成原子操作，要嘛都有要嘛都沒有。

### ★ 為什麼「commit 後再發」仍然不夠

```
BEGIN; INSERT order; COMMIT;     ✅ 訂單存了
★ 這裡程序被 kill / 機器斷電 / 網路斷
publish(event)                   ❌ 永遠不會執行
→ ★ 訂單存在，但下游永遠不知道
```
> ★ **這不是「機率很低」的問題，是「一定會發生」的問題。**
> 每天十萬筆訂單，就算只有萬分之一，每天也有 10 筆靜默遺失——
> **而且你不會知道，直到客戶來抱怨。**

**反過來「先發再寫」也不行**：訊息發了但交易失敗 → **下游收到不存在的訂單的事件。**

★ **這就是雙寫問題（dual write）：兩個獨立的系統無法原子地一起成功或一起失敗。**

### ★ Outbox 的核心：把「跨系統」化約成「單一資料庫的本地交易」

```sql
BEGIN;
  INSERT INTO orders (...) VALUES (...);
  INSERT INTO outbox (id, aggregate_id, type, payload, created_at)
       VALUES (gen_random_uuid(), :order_id, 'OrderPlaced', :json, now());
COMMIT;                          -- ★ 要嘛都成功，要嘛都失敗
```
★ **而單一資料庫的交易是可靠的**（見 [[工具-交易與隔離等級]]）——
**問題被化約成了一個已經被解決的問題。**

### ★ Relay 的兩種實作

| | **① 輪詢 outbox 表** | **② ★ CDC（讀 WAL）** |
|---|---|---|
| 做法 | `SELECT * FROM outbox WHERE published_at IS NULL LIMIT 100` | Debezium 讀 PG 邏輯解碼 / MySQL binlog |
| 延遲 | 輪詢間隔（通常 100ms–1s） | ★ **接近即時** |
| 對主庫負載 | ★ 有（持續查詢 + 更新） | ★ **幾乎零**（讀 WAL 不碰資料表） |
| 運維 | ★ **簡單**（就是一段程式） | 要跑 Debezium/Kafka Connect |
| 順序保證 | 要自己處理 | ★ **天然有序**（WAL 就是順序） |
| **建議** | ★ **中小規模的預設** | 規模大或已有 Kafka 生態時 |

★ **輪詢版的關鍵細節**：
```sql
-- ★ 用 FOR UPDATE SKIP LOCKED 讓多個 relay 實例可以並行而不重複
SELECT * FROM outbox
 WHERE published_at IS NULL
 ORDER BY created_at
 LIMIT 100
 FOR UPDATE SKIP LOCKED;
```
**`SKIP LOCKED` 是這裡的關鍵**——它讓多個 worker 各自取走不同的一批，**不會互相阻塞也不會重複。**

### ★ 必須配套的三件事

| 事項 | 為什麼 |
|---|---|
| **★ 消費端冪等** | Outbox 是**至少一次**：relay 發送成功但標記失敗 → 會重發（見 [[工具-MQ消費端防禦三原則]]） |
| **★ 清理舊資料** | outbox 表會無限成長 → 定期刪除已發布且超過保留期的（★ 或用分區表按時間 DROP） |
| **★ 監控積壓** | `未發布訊息的最舊時間` 是關鍵指標。relay 掛了要立刻知道 |

### ★ 常見的實作錯誤

| 錯誤 | 後果 |
|---|---|
| ★ **relay 用「先發送再標記」** | 發送成功但標記失敗 → 重發（可接受，靠冪等）。<br>★ **反過來「先標記再發送」會丟訊息**——這是嚴重錯誤 |
| ★ **payload 只存 ID 不存內容** | 消費端拿到 ID 回頭查 → **查到的是「現在」的狀態，不是「事件發生當下」的狀態** |
| 沒有 `aggregate_id` | 無法做分區與順序保證 |
| outbox 和業務表在不同資料庫 | ★ **完全失去意義**——那又變回雙寫了 |
| 沒有清理 | 表膨脹 → 查詢變慢 → relay 越來越慢 |

### ★ 什麼時候不需要 Outbox
| 情況 | 替代 |
|---|---|
| ★ **訊息遺失可接受**（遙測、分析、通知） | 直接發，失敗就算了 |
| 下游可以主動來查 | ★ **輪詢 / API 查詢**——不需要推送就不需要保證投遞 |
| 只有一個下游且能容忍延遲 | 定期批次同步 |
| ★ **根本不該跨服務** | **合併回同一個交易**（見 [[工具-服務邊界與演進式拆分]]） |

## 🧪 我實際套用的紀錄
- 2026-07-13：（待填）

## ⚠️ 注意 / 什麼時候不適用

- **★★ outbox 表必須和業務表在「同一個資料庫」**，否則完全沒有意義。
- **★ relay 一定要「先發送、後標記」**（見上）。順序反了會丟訊息。
- **★ 消費端冪等不是可選的**。
- **outbox 寫入會增加主交易的成本**（多一次 INSERT）。高頻寫入時要量，必要時用分區表。
- **★ 一定要監控積壓**。relay 悄悄掛掉 → 訊息全部堆在表裡沒人發現，**幾小時後才發現下游什麼都沒收到。**
- **事件內容要是「當時的快照」**，不要只存 ID（見上）。
- **CDC 的 replication slot 會洩漏**：CDC 工具離線 → ★ **主庫的 WAL 無法回收 → 磁碟爆掉**
  （見 [[工具-預寫日誌與崩潰復原]]）。**要監控 slot 落後量。**
- **★ 這解決的是「投遞」不是「處理」**。下游收到了但處理失敗，是另一個問題（DLQ，見 [[工具-訊息傳遞整合模式]]）。

## 🔗 相關工具
- [[工具-分散式事務的取捨]] —— ★ Outbox 是其中的預設方案
- [[工具-交易與隔離等級]] —— 本地交易是它的基礎
- [[工具-MQ消費端防禦三原則]] —— 冪等與重試
- [[工具-預寫日誌與崩潰復原]] —— CDC 的原理與 slot 洩漏
- [[工具-訊息傳遞整合模式]] —— 投遞之後的處理
- [[命令模式]] —— 序列化的事件/命令與版本相容
- [[工具-資料編碼與演進]] —— 事件 schema 的演進
