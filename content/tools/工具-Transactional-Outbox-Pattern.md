---
type: tool
name: "Transactional Outbox Pattern"
source: "[[擋下用Upsert修RaceCondition的PR]]"
source_type: article
tags: [backend, message-queue, architecture, consistency]
triggers: [DB寫入和發事件不同步, MQ收到訊息但DB查不到, 該先commit還是先發訊息, dual write問題, 發完MQ上游卻rollback]
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

## 🧪 我實際套用的紀錄
- 2026-07-13：（待填）

## ⚠️ 注意 / 什麼時候不適用
- 反面教材：**不要在 DB transaction 內直接發 MQ**（commit 前發訊息 = 時序災難）。
- 上游修好後，下游仍要防禦，見 [[工具-MQ消費端防禦三原則]]。

## 🔗 相關工具
- [[工具-MQ消費端防禦三原則]]、[[工具-區分修復與掩蓋症狀]]
