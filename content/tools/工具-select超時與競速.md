---
type: tool
name: "select 超時與競速"
source: "[[Go Blog 經典六篇]]"
source_type: article
tags: [software, go, concurrency]
triggers: [想等最多幾秒就放棄, 向多個來源查詢只要最快的那個回應, goroutine送不出去卡住不結束, channel該開多大的緩衝, Go怎麼做逾時]
---

## 🎯 什麼情境該想到我
當你要「**最多等 N 秒**」或「**同時問多個來源、只要最快回來的那一個**」的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 1. 逾時：`select` ＋ 一個會自己響的 channel
```go
select {
case v := <-ch:
    // 拿到值
case <-time.After(time.Second):
    // 逾時，放棄這次接收
}
```
`time.After` 回傳一個會在指定時間後送值的 channel。

### 2. ⭐ 但跨越 API 邊界時，正解是 `context`
來源文章寫於 2010 年、`context` 還不存在。今天的分工是：
- **函式內部的一次性等待** → `select` + `time.After` 就夠。
- **要能被呼叫端取消、要往下游傳遞、要設整體期限** → **用 `context.WithTimeout`**，把 `ctx` 當第一個參數傳下去。

### 3. 競速：向多個來源查詢，取最快的
```go
func Query(conns []Conn, query string) Result {
    ch := make(chan Result, len(conns))   // ⭐ 緩衝是關鍵
    for _, conn := range conns {
        go func(c Conn) { ch <- c.DoQuery(query) }(conn)
    }
    return <-ch
}
```
**為什麼一定要有緩衝**：主函式只收一個值就走了，剩下的 goroutine 還想送。若 channel 無緩衝，它們會**永遠卡在送出那一行**——goroutine 洩漏。
給足 `len(conns)` 的緩衝，每個 goroutine 都送得出去然後正常結束，沒被讀走的值交給 GC。

**原文用的是「非阻塞送出（`select` + `default`）」加緩衝**，並自己點出：如果結果比主函式抵達接收點更早到，非阻塞送出會失敗——**修法就是把 channel 開緩衝**。

## 🧪 我實際套用的紀錄
- 2026-08-29：（待填）

## ⚠️ 注意 / 什麼時候不適用
- ⚠️ **「`time.After` 會洩漏，要改用 `NewTimer` + `Stop`」這條廣為流傳的建議，本身已經過時。** 現行 `time.After` 文件：
  > "**As of Go 1.23**, the garbage collector can recover unreferenced, unstopped timers. **There is no reason to prefer NewTimer when After will do.**"
- **逾時不等於取消**：`select` 逾時只是「我不等了」，**對面那個 goroutine 還在跑**。要真的讓它停下來，得靠 `context` 或別的訊號。
- **緩衝大小要涵蓋所有可能的送出者**，少算一個就有一個 goroutine 洩漏。
- **競速模式會浪費資源**：所有來源都會被查一遍。只在延遲比成本重要時才用。

## 🔗 相關工具
- [[工具-靠通訊共享記憶體]] —— channel 的心智模型；那張也提醒了 channel 不是萬用解
- [[工具-用race偵測器抓資料競爭]] —— 競速模式很容易寫出 race，跑測試時開 `-race`
- [[Modern Go Guidelines]] —— `contextcause`／`contexttimeoutcause` 等現代 context 用法
