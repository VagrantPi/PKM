---
type: tool
name: "Go 全域狀態的判準"
source: "[[Google Go 風格指南]]"
source_type: article
tags: [software, go, design, testing]
triggers: [想加一個package層級變數, 用init註冊一堆東西, 測試互相影響換順序就壞, 想做一個全域的client或singleton, 測試要換掉某個依賴卻換不掉]
---

## 🎯 什麼情境該想到我
當你正要寫下 `var somethingGlobal = ...` 或 `func Register(name string, ...)` 的時候——**在動手前跑一次下面的 litmus test**。

## ⚙️ 怎麼用（步驟 / 公式）

### 1. 先認出四種常見的「套件層級狀態」
它們都是同一個問題的不同外表：

1. **頂層變數**（不管有沒有匯出）
   ```go
   // Bad
   package logger
   var Sinks []Sink
   ```
2. **Service locator 定義成全域**（pattern 本身沒問題，全域才有問題）
3. **註冊表／callback 清單**
   ```go
   // Bad
   package health
   var unhealthyFuncs []func
   func OnUnhealthy(f func()) { unhealthyFuncs = append(unhealthyFuncs, f) }
   ```
4. **厚 client 單例**（backend、storage、DAL 等系統資源）
   ```go
   // Bad
   package useradmin
   var client pb.UserAdminServiceClientInterface
   func Client() *pb.UserAdminServiceClient {
       if client == nil { client = ... }
       return client
   }
   ```

### 2. ⭐ Litmus test：出現以下任一項就是不安全
- 兩個**本來互不相干**的函式（不同作者、不同目錄）因為全域狀態而互相影響。
- **獨立的測試案例透過全域狀態互相干擾**。
- 使用者會**想為了測試去抽換／取代**這份全域狀態（換成 stub／fake／spy／mock）。
- 使用者必須**考慮呼叫順序**：要在 `func init` 裡嗎？flag 解析完了沒？`main` 之前還之後？

### 3. 反過來，符合以下任一項才算安全
- **全域狀態邏輯上是常數**。
- **套件的可觀察行為是無狀態的**。例如用私有全域變數當快取，但呼叫端分不出 cache hit 還是 miss——那就是無狀態。
- **狀態不外溢到程式之外**（sidecar 行程、共享檔案系統…）。
- **本來就沒有可預期行為的期待**。

標準庫的正面例子是 `image.RegisterFormat`：多次呼叫 `image.Decode` 彼此不會干擾；沒人想把 PNG decoder 換成測試替身；註冊撞名理論上可能但實務罕見；decoder 是**無狀態、冪等、純的**。

### 4. 看懂它為什麼會壞：順序相依的測試
```go
func TestEndToEnd(t *testing.T) {
    // 依賴「production 的 cloud logger 已經被註冊」
}

func TestRegression_NetworkUnavailability(t *testing.T) {
    sidecar.Register("cloudlogger", cloudloggertest.UnavailableLogger)  // 蓋掉了
}

func TestRegression_InvalidUser(t *testing.T) {
    // 掛掉：上一個測試留下的 UnavailableLogger 還在
}
```
Go 測試預設循序執行，於是第三個測試壞掉。後果是連鎖的：**不能用 test filter 單跑、不能平行、不能分片。**

### 5. 正解：讓呼叫端自己建實例，用參數傳進去
```go
// Good
package sidecar

type Registry struct{ plugins map[string]*Plugin }

func New() *Registry { return &Registry{plugins: make(map[string]*Plugin)} }

func (r *Registry) Register(name string, p *Plugin) error { ... }
```
```go
// Good
func main() {
    sidecars := sidecar.New()
    if err := sidecars.Register("Cloud Logger", cloudlogger.New()); err != nil {
        log.Exitf("Could not setup cloud logger: %v", err)
    }
    cfg := &myapp.Config{Sidecars: sidecars}
    myapp.Run(context.Background(), cfg)
}
```
遷移既有程式碼的主要手法就一種：**把依賴當參數往下傳**——建構函式參數、函式參數、方法參數、或 struct 欄位。

**基礎設施提供者要特別注意**：如果你的套件會被別的團隊 import，它**不能**依賴自己所 import 的那些套件的套件層級狀態。給別人用的形狀應該長這樣：
```go
// Good
package cloudlogger

func New() *Logger { ... }
func Register(r *sidecar.Registry, l *Logger) { r.Register("Cloud Logging", l) }
```

### 6. 真的要提供方便的預設實例，有四個條件
原文的立場是「不建議，但可接受」，前提是：
1. 套件**必須**同時提供建立獨立實例的能力。
2. 用到全域狀態的公開 API 必須是**前者的薄包裝**（標竿：`http.Handle` 只是去呼叫 `http.DefaultServeMux` 的 `Handle`）。
3. 這組 package 層級 API **只能被 binary target 使用，不能被函式庫使用**（正在重構往依賴傳遞走的除外）。
4. 必須**文件化並強制它的不變量**（什麼生命週期階段可以呼叫、能不能併發使用），而且**要提供一個把全域狀態重置回已知良好預設值的 API**，好讓測試能用。

### 7. 設計前先回答這七個問題
如果你回答不出來，就不該用全域狀態：
- 同一個行程裡要用**兩組彼此獨立**的 plugin（例如支援多台 server）怎麼辦？
- 測試想把某個 plugin 換成測試替身怎麼辦？
- 測試之間要互相隔離（hermetic）怎麼辦？
- 多個 client 用同一個名字 `Register` 誰贏？
- 錯誤怎麼處理？如果它 panic 或 `log.Fatal`，在所有呼叫場景都恰當嗎？
- 呼叫端能不能**事先檢查**自己會不會做錯？
- 有沒有「只能在某個階段呼叫」的限制？呼叫時機錯了會怎樣？

最後一個有個隱藏後果：作者若假設「反正只在程式初始化時被呼叫」，就會把錯誤處理設計成 Must 那種**直接中止程式**的形狀——而中止程式對一個可以在任何階段被呼叫的通用函式庫並不恰當。

## 🧪 我實際套用的紀錄
- 2026-09-20：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **標準庫裡有反例**（`http.DefaultServeMux`、`flag` 的全域狀態），原文明說：**遺留 API 違反這條，不構成繼續這樣做的先例。**
- Sidecar 類的東西**未必是 process-local** ——它常被多個應用行程共用，還會連外部分散式系統。所以「不外溢到程式外」這條要照 sidecar 自己的程式碼再驗一次。
- 這條對**函式庫作者**最關鍵；只有自己團隊用的 binary 內部，壓力小得多（但測試互相干擾的痛一樣會來）。
- flag 也是全域狀態的一種：**flag 只能定義在 `package main` 或等價處**，通用套件要用 Go API 設定，不要靠 import 副作用長出新 flag。

## 🔗 相關工具
- [[工具-Go表格測試與子測試]] —— 「子測試不可互相依賴」失守的頭號原因就是這張卡的問題
- [[工具-打破依賴以便測試]] —— 已經被全域狀態綁死的舊 code 怎麼拆開
- [[工具-縮小變數作用域]] —— 語言無關的同一方向；這張是 Go 套件層級的版本與明確判準
