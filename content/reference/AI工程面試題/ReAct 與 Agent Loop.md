---
type: reference
name: "ReAct 與 Agent 迴圈 ReAct & Agent Loop"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, agent, tool-use, reliability]
triggers: [ReAct比CoT多了什麼, agent的迴圈怎麼寫才不會爆, 工具呼叫失敗要重試還是餵回給模型, 怎麼確保agent會停下來, agent一直重複同一個動作]
---

> **對應原題**（Common ‧ Agents and Tool Use / Coding）
> - Explain the **ReAct pattern** and **what it solves over chain-of-thought alone**.
> - How do you handle **tool-call errors, timeouts and retries** in an agentic loop? — *Asked at: OpenAI, Cognition*
> - What makes an agent loop **terminate correctly**? How do you **bound cost and steps**?
> - Implement a **minimal agent loop** with tool dispatch, error handling and a **step budget**. — *Asked at: Cognition*

## 🎯 什麼情境該想到我
當你「**要寫一個 agent、或你的 agent 跑到一半失控**」的時候。這一頁是 D 區的地基——記憶、多 agent、人類把關全都長在這個迴圈上。

## ⚙️ 怎麼用

### ★ ReAct 比 CoT 多了什麼

**Chain-of-Thought 是開環的**：
```
問題 → 想 → 想 → 想 → 答案
       └─ 全程在模型腦內，沒有任何外部輸入 ─┘
```
三個結構性缺陷：
1. **拿不到外部資訊** —— 不知道今天日期、不知道你的資料庫裡有什麼
2. **無法驗證** —— 推理的每一步都沒有事實檢核
3. **★ 錯誤會累積** —— 第二步錯了，後面全部建立在錯誤之上，而且**模型不會察覺**

**ReAct（Yao et al., 2022）把迴圈閉上**：
```
Thought      →  Action       →  Observation  →  Thought → …
（我該做什麼）   （呼叫工具）      ★ 外部世界的真實回應
```

> ★ **核心一句話：`Observation` 是外部世界的真實回傳，它把推理「接地」（grounding）。**
> CoT 是「自己說服自己」，ReAct 是「每一步都去現實撞一下」。
> 所以 ReAct 解決的是 **CoT 的幻覺累積問題**，而不是讓它「更會想」。

**代價**：每一步多一次 round-trip（延遲）、每一步重放整段歷史（token 成本）、工具可能失敗（新的失效面）。

### 最小可用的 Agent Loop

```python
import time, hashlib, json

class Budget:
    def __init__(self, max_steps=20, max_seconds=120, max_tokens=200_000):
        self.max_steps, self.max_seconds, self.max_tokens = max_steps, max_seconds, max_tokens
        self.steps, self.tokens, self.t0 = 0, 0, time.monotonic()
    def check(self):
        if self.steps >= self.max_steps:                 return "STEP_LIMIT"
        if time.monotonic() - self.t0 > self.max_seconds: return "TIME_LIMIT"
        if self.tokens >= self.max_tokens:                return "TOKEN_LIMIT"
        return None

def run_agent(goal, tools, llm, budget=None):
    budget = budget or Budget()
    messages = [{"role": "user", "content": goal}]
    seen = {}                                   # ★ 迴圈偵測

    while True:
        stop = budget.check()
        if stop:
            return {"status": stop, "messages": messages}   # ★ 預算用盡也要回可用的部分結果

        resp = llm(messages, tools=tools.schemas())
        budget.steps += 1
        budget.tokens += resp.usage.total_tokens
        messages.append(resp.message)

        if not resp.tool_calls:                 # 模型認為做完了
            return {"status": "DONE", "answer": resp.message["content"], "messages": messages}

        for call in resp.tool_calls:
            # ★ 迴圈偵測：同一個 (工具, 參數) 重複太多次就是卡住了
            key = hashlib.sha256(
                f"{call.name}:{json.dumps(call.args, sort_keys=True)}".encode()).hexdigest()
            seen[key] = seen.get(key, 0) + 1
            if seen[key] > 3:
                messages.append(tool_result(call,
                    "ERROR: 你已經用相同的參數呼叫這個工具 3 次了。"
                    "請改變做法，或說明你為什麼卡住。"))
                continue

            messages.append(tool_result(call, dispatch(call, tools)))
```

```python
def dispatch(call, tools, max_retries=3):
    """★ 錯誤分三類處理，這是這題的重點"""
    tool = tools.get(call.name)
    if tool is None:                                   # ③ 模型的錯
        return f"ERROR: 沒有名為 {call.name} 的工具。可用的工具：{tools.names()}"

    try:
        args = tool.validate(call.args)                # ③ 參數不合 schema
    except ValidationError as e:
        return f"ERROR: 參數不合法：{e}\n正確的 schema：{tool.schema_str()}"

    for attempt in range(max_retries):
        try:
            return tool.run(args, timeout=tool.timeout)
        except Transient as e:                         # ① 暫時性：靜默重試
            if attempt == max_retries - 1:
                return f"ERROR: {tool.name} 重試 {max_retries} 次仍失敗：{e}。請改用其他方式。"
            time.sleep(min(2 ** attempt, 8) * (0.5 + random.random()))   # 指數退避 + jitter
        except Permanent as e:                         # ② 永久性：立刻回報給模型
            return f"ERROR: {e}"
```

### ★ 三類錯誤，三種處理（面試重點）

| 類別 | 例子 | 處理 | 模型看得到嗎 |
|---|---|---|---|
| **① 暫時性** | 429、5xx、逾時、網路中斷 | **程式自己重試**（指數退避 + jitter） | ❌ **不要讓模型看到**——它會開始「思考網路問題」，浪費 token 又容易亂改計畫 |
| **② 永久性** | 404、403、參數在業務上不合法 | **不重試**，把錯誤**當成 observation 餵回去** | ✅ **這是 agent 特有的**：錯誤訊息本身是有價值的資訊，能讓模型改變策略 |
| **③ 模型自己的錯** | 工具名不存在、參數不合 schema、JSON 壞掉 | 餵回**具體錯誤 + 正確 schema** | ✅ 但**要限制修正次數**（通常 2–3 次），否則會陷入修正迴圈 |

> **①/② 的分界是這題的核心**：
> 靜默重試的目的是**不污染模型的上下文**；餵回去的目的是**讓模型能繞路**。搞混了，agent 要嘛太笨（該繞路時在等）要嘛太吵（把重試噪音當成推理素材）。

### ★ 終止：四個條件 + 三層預算

**終止條件（依可靠度排序）**：

| # | 條件 | 可靠度 |
|---|---|---|
| **1** | **可驗證的目標達成**（測試通過、檔案存在、API 回 200） | ✅ **最可靠。有可能就用這個** |
| 2 | 模型說「我做完了」 | ⚠️ **不可信**，要搭配驗證（見 [[工具-防止agent造假通過驗收]]） |
| 3 | **預算耗盡** | ✅ 兜底，一定要有 |
| 4 | **偵測到迴圈** | ✅ 必要 |

**★ 三層預算缺一不可**：

| 預算 | 擋住什麼 | 為什麼單獨不夠 |
|---|---|---|
| **步數** | 無限迴圈 | 20 步裡每步都塞 50 萬 token 照樣爆 |
| **時間（wall-clock）** | 單步卡死、外部服務掛住 | 卡在第 3 步的 10 分鐘，步數看起來很正常 |
| **★ token / 金錢** | 成本失控 | **最容易被忽略、代價最直接**。上下文每步成長，token 是超線性的 |

**預算耗盡時不要直接丟例外**——要**回傳已完成的部分結果與軌跡**，讓上層決定是否續跑或交給人。

### ★ 上下文的超線性成長（最常被忽略的成本問題）

Agent 每一步都要**重放整段歷史**：
```
第 1 步：  1k token
第 5 步：  8k token
第 10 步: 25k token
第 20 步: 80k token
────────────────────
總 token 是 O(n²)，不是 O(n)
```

**三個對策**：
1. **★ [[前綴快取 Prompt Caching]]** —— agent 迴圈是前綴快取**收益最大**的場景（歷史是天然成長的前綴）。**先做這個，投報率最高**
2. **壓縮舊的 observation** —— 大段工具輸出（檔案內容、API 回應）保留摘要 + 引用，需要時再重讀
3. **分段交接** —— 到達門檻就摘要整段軌跡、開新的上下文（見 [[Agent 記憶設計]]）

## ⚠️ 注意 / 什麼時候不適用

- **★ 工具必須冪等，或帶 idempotency key**。重試 + 非冪等 = 重複下單、重複發信。**這是會上新聞的那種 bug。**
- **能用固定流程就別用 agent**。「檢索 → 生成」固定兩步能解的問題，不要讓模型自己決定步數。自由度是成本也是風險（見 [[工具-AI-Agent設計]]）。
- **迴圈偵測不能只看完全相同的參數**。模型常會做「語意相同但參數微調」的重複嘗試（`limit=10` → `limit=11`）。必要時比對語意相似度。
- **工具逾時要比模型逾時短**。否則整個 agent 卡在一個工具上。
- **錯誤訊息要對模型友善**：講清楚**發生什麼**、**為什麼**、**可以怎麼辦**。丟一個 stack trace 給模型是浪費 token。
- **並行工具呼叫要小心**。速度快，但錯誤處理與副作用順序都變複雜；有相依或有副作用的操作不要並行。
- **完整 trace 是必需品不是加分項**。沒有逐步的 trace，agent 的問題無法除錯（見批次 3 的可觀測性）。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開。**待辦：檢查現有 agent 有沒有三層預算與迴圈偵測。**

## 🔗 相關
- [[Function Calling 與結構化輸出]] —— 迴圈裡那一步「呼叫工具」的機制
- [[工具集設計]] —— 給模型哪些工具、schema 怎麼寫
- [[Agent 記憶設計]] —— 上下文成長的長期解法
- [[多 Agent 編排與 Agent Drift]] —— 長跑失控的診斷
- [[可逆性、審計與人類把關]] —— 有副作用的動作怎麼辦
- [[前綴快取 Prompt Caching]] —— agent 最賺的優化
- [[工具-AI-Agent設計]] —— 決策層：該不該上 agent
- [[工具-防止agent造假通過驗收]] —— 「我做完了」不可信
