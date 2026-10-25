---
type: tool
name: "用假 API 差分測試逆向 CLI 行為"
source: "[[Claude Code 隱藏設定分析 v2.1.239]]"
source_type: article
tags: [ai, llm, methodology, testing]
triggers: [想知道CLI到底送了什麼給API, 懷疑設定沒生效但看不出來, 想驗證某個flag真的有作用, 不確定skill有沒有真的進到prompt裡, 想逆向一個工具的內建行為]
---

## 🎯 什麼情境該想到我
當你「**懷疑某個設定／skill 根本沒生效，但從畫面上看不出來**」的時候——別猜，去看實際送出去的請求。

## ⚙️ 怎麼用（步驟 / 公式）
1. **架一個 loopback 假 API**：把工具的 base URL 指向本機，收下請求、把序列化的 body 存起來。
   附帶好處：**測試過程不會把 prompt 送給供應商**。
2. **用乾淨的隔離設定檔跑**（暫時的 profile／`--print` 之類的非互動模式），避免你既有的設定汙染結果。
3. **一次只動一個變因**，跑 A／B 兩次，diff 兩份 body。
4. **⭐ 每個 negative test 都要配一個 positive control**——這是整套方法的關鍵紀律。
   否則「字串沒出現」會被誤讀成「功能被關掉了」，但真相可能是**那段程式根本沒被執行到**。
5. **用大小當粗訊號、用字串比對做確認**：請求從 113 KB 掉到 73 KB 是強訊號，但仍要指出**消失的是哪一段**。
6. **把版本釘死**：記下版本號與執行檔的 SHA-256。行為宣稱只對那個 build 有效。

### 最小實作（以 Claude Code 為例）

**① 假伺服器**（14 行，只聽 127.0.0.1，收到什麼就原封不動存成檔案；檔名會去掉 `?beta=true` 這類 query string）：

```python
import json, sys, time
from http.server import BaseHTTPRequestHandler, HTTPServer
OUT = sys.argv[1] if len(sys.argv) > 1 else "."
class H(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        name = f"{OUT}/{time.time_ns()}{self.path.split('?')[0].replace('/', '_')}.json"
        open(name, "wb").write(body)                      # 原封不動存下請求
        resp = json.dumps({"id": "msg_fake", "type": "message", "role": "assistant",
            "model": "fake", "content": [{"type": "text", "text": "ok"}],
            "stop_reason": "end_turn", "usage": {"input_tokens": 0, "output_tokens": 1}}).encode()
        self.send_response(200); self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(resp))); self.end_headers(); self.wfile.write(resp)
HTTPServer(("127.0.0.1", 18787), H).serve_forever()      # 只聽 loopback
```

- 2026-10-25 我用 curl 打過一次，確認請求 body 會逐字存進 `out/`，例如 `…_v1_messages.json`。
- 請求是在回應**之前**就存檔的。所以即使 CLI 不接受這個假回應，例如它要的是串流格式，差分要用的請求也已經拿到了。
- 埠號自己挑一個沒被占用的。

**② 把 CLI 導過來**：Claude Code 官方文件說明可以用 `ANTHROPIC_BASE_URL` 指定 API 端點（LLM gateway 那一節，查證 2026-10-25）。

```bash
mkdir -p out && python3 fake_api.py out &
ANTHROPIC_BASE_URL=http://127.0.0.1:18787 ANTHROPIC_API_KEY=dummy \
  claude -p "hi"                      # A 組：不設要測的變數
ANTHROPIC_BASE_URL=http://127.0.0.1:18787 ANTHROPIC_API_KEY=dummy SOME_FLAG=0 \
  claude -p "hi"                      # B 組：只多一個變數
```

**③ 比對**：先比大小（`ls -l out/`），再用 `jq '.system'` 抽出兩份的 system prompt，跑 `diff`，指出到底少了哪一段。

**④ positive control 長什麼樣**：
- 要證明「設了 X 之後，段落 S 消失」，同一輪要先確認：
  - **不設 X 時，S 確實出現在請求裡**。
  - 而且這次請求確實走到會產生 S 的那條路。例如 S 是某個 skill 的說明，就要確認那個 skill 有被載入。
- 只有「控制組有 S、實驗組沒有 S」才算數。兩邊都沒有 S，代表那段程式根本沒執行，什麼都證明不了。
- 原文的寫法是：每個 negative test 都配一個 positive control，避免把「字串不存在」誤讀成「程式路徑沒跑到」。

## 🧪 我實際套用的紀錄
- 2026-08-23：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **「追到程式碼路徑」不等於「實測過」**。原文很誠實地把結論分成 `verified`（差分測試看到請求變了）與 `static`（只讀到程式碼路徑、沒重現條件）兩級——**自己做的時候也要分清楚，別把讀碼推論寫成實測結論**。
- **有些分支在假 API 下根本起不來**。原作者的 `--permission-mode auto` 在假 API 下沒初始化成功，只好改走另一條分支再用讀碼補推論——**這種時候要標明，不要假裝測到了**。
- **結論會隨版本失效**：byte offset、變數名、行為全都綁在特定 build 上。每次更新都要重跑。
- **別把它當成攻擊工具**：這是拿來理解自己機器上的工具在做什麼，不是繞過供應商的政策或安全機制。

## 🔗 相關工具
- [[工具-AI改動的AB對照評測]] —— 同樣是「靠對照組拿證據」，但那張比的是**模型輸出的品質**，這張比的是**送出去的請求內容**。想完整驗一個 skill，兩張要一起用：先確認它有進 prompt，再確認它讓輸出變好
- [[工具-ClaudeCode未文件化設定的取捨]] —— 量到某個未文件化設定有效之後，還要決定該不該真的用它
