---
type: tool
name: "MQ 消費端防禦三原則"
source: "[[擋下用Upsert修RaceCondition的PR]]"
source_type: article
tags: [backend, message-queue, idempotency, reliability]
triggers: [寫MQ worker, 寫message consumer, 處理重複訊息, worker查不到資料, worker收到訊息卻查不到對應資料, at-least-once]
---

## 🎯 什麼情境該想到我
> **分工**：這張是消費端的即用清單。各模式的完整展開（含 Kafka、RabbitMQ、SQS 的行為差異）→ [[冪等接收者]]、[[死信通道]]、[[保證投遞]]；用資料庫條件更新做冪等的完整做法 → [[工具-用條件更新做狀態機冪等]]。

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

### ★ 冪等的兩種做法（Go 骨架）

**做法 A：記錄已處理的訊息 ID（與業務寫入在同一個交易裡）**

```go
func (h *Handler) Handle(ctx context.Context, msg Message) error {
	tx, err := h.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// 同一則訊息第二次進來時，這裡影響 0 列 → 直接視為成功
	res, err := tx.ExecContext(ctx,
		`INSERT INTO processed_messages (id) VALUES ($1) ON CONFLICT DO NOTHING`, msg.ID)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return nil // 已處理過
	}

	if err := h.apply(ctx, tx, msg); err != nil { // 業務邏輯，用同一個 tx
		return err
	}
	return tx.Commit()
}
```

**關鍵是同一個交易**：如果「記錄 ID」和「業務寫入」分開提交，兩者之間當機，就會出現「記了 ID 但沒做事」或「做了事但沒記 ID」。

**做法 B：讓操作本身冪等**——用條件更新推進狀態機，例如 `UPDATE orders SET status='shipped' WHERE id=$1 AND status='paid'`，第二次執行影響 0 列。詳見 [[工具-用條件更新做狀態機冪等]]。

### ★ 重試要有上限與退避

| 要素 | 為什麼 |
|---|---|
| **指數退避**（1s、2s、4s…） | 讓下游有時間恢復，也讓複本延遲有時間追上 |
| **隨機抖動** | 避免大量消費者在同一時刻一起重試，造成新的尖峰 |
| **最大次數** | 確定性的錯誤重試再多次也不會成功 |
| **超過上限 → 死信佇列** | 不阻塞後面的訊息，也不讓失敗的訊息消失；有人工檢查的入口 |

判斷該不該重試：**暫時性錯誤**（網路逾時、複本上查不到剛寫入的資料、下游 503）重試；**確定性錯誤**（格式錯誤、業務規則不允許）直接送死信，重試只是浪費時間。

### ★ 「查不到資料」的三種可能

消費者收到訊息，但資料庫裡查不到對應的資料：
1. **複本延遲**：讀的是複本，主庫已經寫入但還沒同步 → 退避重試，或改讀主庫。
2. **生產端時序錯誤**：訊息在交易提交**之前**就送出了 → 根本的修法在生產端（Outbox）。
3. **交易被回滾**：訊息送出了，但交易最後失敗 → 這則訊息本來就不該存在，同樣要靠 Outbox 修。

**三種情況都不該在消費端自己補一筆資料**——那會製造出殘缺的「幽靈資料」（見 [[工具-區分修復與掩蓋症狀]]）。

## 🧪 我實際套用的紀錄
- 2026-07-13：（待填）

## ⚠️ 注意 / 什麼時候不適用
- 「worker 找不到資料 → 自己補一筆」是**反模式**，會造出殘缺／幽靈資料。

## 🔗 相關工具
- [[工具-Transactional-Outbox-Pattern]] —— 從生產端根治同一個問題：這張防的是「訊息比 commit 早到」的症狀，Outbox 讓它一開始就不會發生
- [[工具-區分修復與掩蓋症狀]] —— 判準卡：consumer 端加 retry 或 upsert 到底是真修好還是把症狀藏起來，用它檢查

