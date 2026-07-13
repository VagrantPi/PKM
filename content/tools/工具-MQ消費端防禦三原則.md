---
type: tool
name: "MQ 消費端防禦三原則"
source: "[[擋下用Upsert修RaceCondition的PR]]"
source_type: article
tags: [backend, message-queue, idempotency, reliability]
triggers: [寫MQ worker, 寫message consumer, 處理重複訊息, worker查不到資料, replication lag, at-least-once]
---

## 🎯 什麼情境該想到我
當你在寫 message queue 的 consumer / worker，要讓它在真實世界（重複投遞、replica 延遲）下不出錯時。

## ⚙️ 怎麼用（三件事一起做）
1. **Idempotent（冪等）**：MQ 是 **at-least-once**，重複投遞是常態 → 同一則訊息處理多次，結果要一致。
2. **Retry with backoff / requeue**：查不到資料時**退避重試或重新入列**，因為可能是 replication lag 或極端時序 → **絕不自己造資料補上**。
3. **搭配上游修好時序**：下游防禦不能取代上游正確性，兩邊都要做（上游見 [[工具-Transactional-Outbox-Pattern]]）。

| 層級 | 做法 | 解決 |
|------|------|------|
| 上游 | Outbox pattern | 時序錯誤、事件遺失 |
| 下游 | Retry with backoff | replication lag、極端時序 |
| 消費端 | Idempotent 處理 | at-least-once 重複投遞 |

## 🧪 我實際套用的紀錄
- 2026-07-13：（待填）

## ⚠️ 注意 / 什麼時候不適用
- 「worker 找不到資料 → 自己補一筆」是**反模式**，會造出殘缺／幽靈資料。

## 🔗 相關工具
- [[工具-Transactional-Outbox-Pattern]]、[[工具-區分修復與掩蓋症狀]]
