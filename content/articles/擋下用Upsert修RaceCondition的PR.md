---
type: article
title: "那個用 Upsert 修 Race Condition 的 PR，我把它擋下來了"
source_url:            # 手動貼入的文章，無原始網址
author:
site:
tags: [backend, concurrency, message-queue, code-review, architecture, root-cause]
captured: 2026-07-13
read_status: read
---

## 📌 30 秒摘要
> 同事用 `INSERT ... ON DUPLICATE KEY UPDATE`（upsert）去修一個 race condition，diff 本身沒錯，但作者在 review 時追問「為什麼這裡會需要 upsert」，一路追到真正的 root cause：**message sender 把發送 MQ 包在 DB transaction 裡、還沒 commit 就發訊息**，導致 worker 比 commit 更早收到訊息、查不到資料。upsert 只是掩蓋症狀（還會造出殘缺資料與 rollback 幽靈記錄）。正解是 **Transactional Outbox Pattern + 下游 retry + 消費端 idempotent**。核心體悟：**reasoning 比 coding 更值錢。**

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- 當團隊出現「用 upsert / 加 retry / try-catch」這類「直覺修法」時，用它提醒自己**先追 root cause**。
- 設計「DB 寫入 + 發事件」的流程時，當作 Outbox pattern 的實戰參考。

## 🧰 這篇給我的工具
- [[工具-Transactional-Outbox-Pattern]] — 當我要讓「DB 寫入」與「發事件」不會不同步時
- [[工具-區分修復與掩蓋症狀]] — 當我在 review 一個修法、想判斷它是真修還是藏 bug 時
- [[工具-MQ消費端防禦三原則]] — 當我在寫 message queue 的 consumer / worker 時

## ✨ 關鍵重點
- **問題時序**：上游在 transaction 內、commit 前就發 MQ message → worker 收到時 DB 還查不到。
- **upsert 的三個危害**：① worker 只憑 payload 補資料 → 殘缺資料；② 上游 rollback 後 → 幽靈記錄（業務從未成立）；③ 症狀消失但時序仍錯 → 沒人再發現問題。
- **三層正解**：上游 Outbox（時序/遺失）、下游 retry with backoff（replication lag/極端時序）、消費端 idempotent（at-least-once 重複投遞）。
- **worker 找不到資料的正確姿勢**：retry / requeue，而不是自己造資料。

## 💬 原文摘錄
- 「worker 收到 message，代表上游宣稱這筆資料存在；但 DB 裡卻沒有——這不是 worker 該補資料的問題，這是上游在說謊。」
- 「補丁最大的危害不是它沒修好問題，而是它把問題藏起來了。」
- 「不要比 AI 更會 coding。要比它更會 reasoning。」

## 🔗 相關
- 延伸：Transactional Outbox Pattern、Dual Write Problem、At-least-once Delivery Semantics
