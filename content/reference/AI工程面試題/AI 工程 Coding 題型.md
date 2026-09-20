---
type: reference
name: "AI 工程 Coding 題型"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, coding, interview, engineering, python]
triggers: [AI工程面試會考什麼coding題, 手刻attention要注意什麼, 串流JSON被切斷怎麼解析, 分散式限流怎麼寫才對, 餘弦相似度搜尋為什麼不能上線]
---

> **對應原題**（Common ‧ Coding and Data Structures，12 題）
> Anthropic 12 題、Palantir 7 題、OpenAI 7 題——**Coding 在多數公司仍是題數最多的一輪**。
> 但形狀變了：**漸進式加需求、在真實 codebase 上寫、可以用 AI 工具**（見 [[AI 工程面試題庫（公司別）]] 的考點地圖）。

## 🎯 什麼情境該想到我
當你「**要準備 AI 工程的 coding 輪，想知道該練什麼**」的時候。

## ⚙️ 兩大類

| 類別 | 考什麼 | 題目 |
|---|---|---|
| **A. 模型內部** | **你是真的懂 transformer，還是只會呼叫 API** | 1–5 |
| **B. 工程基本功** | **你能不能寫出可上線的 LLM 基礎設施** | 6–12 |

> ★ **B 類才是多數職缺真正在做的事**，而且它們**不是 LeetCode**——
> 是**限流、重試、串流解析、併發控制**這些「呼叫 LLM API 一定會遇到」的東西。

## 📗 A 類：模型內部（實作已在對應頁面）

| # | 題目 | 關鍵陷阱 | 完整實作 |
|---|---|---|---|
| **1** | scaled dot-product attention + causal mask<br>*Anthropic, DeepMind, Amazon* | ★ mask 用 `torch.finfo(dtype).min` 不要寫死 `-1e9`（fp16 溢位）；`-inf` 要在 softmax **之前**加 | [[注意力機制]] |
| **2** | MHA → GQA<br>*DeepMind, Mistral, Alibaba* | ★ `num_key_value_heads ≠ num_attention_heads`；`repeat_interleave` 把 KV 頭展開到 Q 頭數 | [[注意力機制]] |
| **3** | KV cache + 單步 decode<br>*Moonshot* | ★ **decode 階段不需要 causal mask**（q 天生只看得到 cache 裡的）；預配置 buffer 而非每步 concat | [[KV Cache]] |
| **4** | BPE 訓練與編碼 | ★ 編碼時必須**按學到的順序**套用合併，不能貪婪取最長；`decode` 要 `errors="replace"`（token 可能切斷 UTF-8） | [[分詞與 BPE]] |
| **5** | top-k / top-p / temperature<br>*DeepMind, Apple* | ★ top-p 的 mask 要**右移一格**（否則 $p_{max} > p$ 時全砍光）；mask 要 `scatter` 回原始索引 | [[取樣與解碼策略]] |

## 📘 B 類：工程基本功

### ⑥ LRU Cache（O(1) get/put）→ 再加 TTL
*OpenAI, xAI, Alibaba*

**為什麼考**：LLM 系統到處是快取（答案快取、embedding 快取、KV 快取）。

```python
from collections import OrderedDict
import time

class LRUCacheTTL:
    def __init__(self, capacity: int, default_ttl: float | None = None):
        self.cap, self.default_ttl = capacity, default_ttl
        self.d: OrderedDict[str, tuple] = OrderedDict()   # key -> (value, expire_at)

    def get(self, key):
        item = self.d.get(key)
        if item is None:
            return None
        value, expire_at = item
        if expire_at is not None and time.monotonic() > expire_at:   # ★ 惰性過期
            del self.d[key]
            return None
        self.d.move_to_end(key)                                      # O(1) 更新 LRU 順序
        return value

    def put(self, key, value, ttl=None):
        ttl = ttl if ttl is not None else self.default_ttl
        expire_at = (time.monotonic() + ttl) if ttl else None
        if key in self.d:
            del self.d[key]
        self.d[key] = (value, expire_at)
        while len(self.d) > self.cap:
            self.d.popitem(last=False)                               # 淘汰最舊的
```

**面試官會追問的三點**：
1. **★ 為什麼用 `time.monotonic()` 不用 `time.time()`** —— 後者會被 NTP 校時往回調，造成 TTL 錯亂
2. **惰性過期的缺陷**：過期但沒被存取的 entry 仍佔容量 → **會把還有效的項目擠掉**。修法：`put` 時順手掃幾個、或另維護一個依 `expire_at` 排序的堆
3. **執行緒安全**：`OrderedDict` 的複合操作不是原子的，多執行緒要加鎖

### ⑦ Token Bucket 限流 → 再做成分散式
*Anthropic, OpenAI, xAI, Cohere*

**為什麼考**：★ **呼叫 LLM API 一定會撞 rate limit**，而且自己對外也要限流。

```python
import time

class TokenBucket:
    """rate: 每秒補充多少 token；capacity: 桶容量（= 可容忍的突發量）"""
    def __init__(self, rate: float, capacity: float):
        self.rate, self.cap = rate, capacity
        self.tokens = capacity
        self.last = time.monotonic()

    def allow(self, n: float = 1.0) -> bool:
        now = time.monotonic()
        # ★ 惰性補充：不需要背景執行緒，用時間差算出這段期間該補多少
        self.tokens = min(self.cap, self.tokens + (now - self.last) * self.rate)
        self.last = now
        if self.tokens >= n:
            self.tokens -= n
            return True
        return False
```

**★ 分散式版本：必須原子**

```lua
-- Redis Lua：讀取 → 計算 → 寫回 必須在一次原子操作內完成
-- ❌ 用 GET 再 SET 會有 race condition，高併發下限流直接失效
local key, rate, cap, now, n = KEYS[1], tonumber(ARGV[1]), tonumber(ARGV[2]),
                                tonumber(ARGV[3]), tonumber(ARGV[4])
local b = redis.call('HMGET', key, 'tokens', 'last')
local tokens = tonumber(b[1]) or cap
local last   = tonumber(b[2]) or now
tokens = math.min(cap, tokens + (now - last) * rate)
local allowed = 0
if tokens >= n then tokens = tokens - n; allowed = 1 end
redis.call('HMSET', key, 'tokens', tokens, 'last', now)
redis.call('EXPIRE', key, 3600)
return allowed
```

**追問準備**：
- **時鐘偏移** —— `now` 由客戶端傳入時各節點時鐘不一致 → 改用 Redis 的 `TIME` 指令
- **★ Redis 掛掉怎麼辦** —— fail-open（放行，可能被打爆）還是 fail-closed（全拒，服務中斷）？**這是產品決策，要問清楚**
- **熱 key** —— 單一租戶的限流 key 會集中在一個 shard
- **LLM 特有**：通常要**同時限 RPM 和 TPM**（token 數），而 token 數在呼叫前只能估

### ⑧ 非同步批次處理器（併發上限 + 退避重試 + 錯誤隔離）
*Anthropic, Perplexity*

**為什麼考**：★ **「用 LLM 處理 5 萬份文件」是這個職位最典型的日常工作。**
（Anthropic 的原題就是：50,000 份文件、API 約 100 併發、偶爾回 429 與逾時，寫 Python。）

```python
import asyncio, random

async def process_all(items, worker, concurrency=100, max_retries=5):
    sem = asyncio.Semaphore(concurrency)          # ★ 併發上限

    async def one(idx, item):
        async with sem:
            for attempt in range(max_retries):
                try:
                    return idx, await worker(item), None
                except RateLimited as e:
                    # ★ 尊重伺服器給的 Retry-After，別自己亂猜
                    delay = e.retry_after or min(2 ** attempt, 60)
                except (Timeout, ServerError):
                    delay = min(2 ** attempt, 60)
                except Exception as e:
                    return idx, None, e           # ★ 永久性錯誤不重試
                # ★ full jitter：避免所有 worker 同時醒來再打一次（thundering herd）
                await asyncio.sleep(delay * random.random())
            return idx, None, RuntimeError("max retries exceeded")

    tasks = [one(i, it) for i, it in enumerate(items)]
    results = [None] * len(items)
    errors = {}
    # ★ as_completed：邊完成邊處理，可即時回報進度 / 落盤，而不是等全部跑完
    for coro in asyncio.as_completed(tasks):
        idx, value, err = await coro
        if err:
            errors[idx] = err                     # ★ 錯誤隔離：一筆失敗不影響其他
        else:
            results[idx] = value
    return results, errors
```

**五個得分點**：
1. **`Semaphore` 控併發**，不是切成一批一批（那會有長尾等待）
2. **★ jitter 是必要的**，不是可選——沒有它，退避會讓所有 worker 同步化，反而製造尖峰
3. **★ 區分可重試與不可重試**（429/5xx/逾時 vs 400/401）
4. **錯誤隔離** —— 回傳「哪些成功、哪些失敗」，而不是整批拋例外
5. **★ 進度與續跑** —— 5 萬筆跑到一半掛掉，要能從斷點續跑（落盤 checkpoint）

### ⑨ 串流 SSE / JSON 解析器（處理任意 chunk 邊界）
*Cohere*

**為什麼考**：★ **所有 LLM 串流 API 都是這個形狀，而且邊界問題一定會咬人。**

```python
class SSEParser:
    def __init__(self):
        self.buf = b""          # ★ 必須用 bytes，不是 str

    def feed(self, chunk: bytes):
        """餵入任意大小的 chunk，吐出完整的事件"""
        self.buf += chunk
        while b"\n\n" in self.buf:                      # SSE 以空行分隔事件
            raw, self.buf = self.buf.split(b"\n\n", 1)
            data_lines = [
                line[5:].lstrip()                        # 去掉 "data:" 前綴
                for line in raw.split(b"\n")
                if line.startswith(b"data:")             # ★ 一個事件可能有多行 data
            ]
            if not data_lines:
                continue                                 # 忽略 comment / event: 行
            payload = b"\n".join(data_lines)
            if payload == b"[DONE]":
                return
            yield json.loads(payload.decode("utf-8"))
```

**★ 三個必踩的邊界陷阱**：
1. **★ 一定要用 `bytes` buffer 不是 `str`** —— chunk 可能**切在 UTF-8 多位元組字元中間**。
   中文一個字 3 bytes，切在第 2 個 byte 就 `UnicodeDecodeError`。
   **先累積 bytes、湊齊完整事件再 decode**（或用 `codecs.getincrementaldecoder`）。
2. **chunk 可以切在任何地方** —— `dat` / `a: {"x` / `":1}\n\n`。所以**不能對單一 chunk 做任何假設**。
3. **`\r\n` vs `\n`** —— 規格允許 `\r\n`、`\n`、`\r`。實務上至少要處理前兩者。

**追問**：不完整的 JSON 要不要做增量解析（部分渲染）？逾時與斷線重連（`Last-Event-ID`）？背壓？

### ⑩ 帶 overlap、不切開語意單位的 chunker
*Harvey* → 完整實作見 [[切塊與文件解析]]
**★ 關鍵**：用 tokenizer 計數不用 `len()`；分隔符要有優先序且可遞迴降級；先保護程式碼區塊。

### ⑪ 餘弦相似度搜尋 → **再解釋為什麼你不會把它上線**

**★ 這題的重點全在後半句。** 實作很簡單：

```python
import numpy as np

def search(query: np.ndarray, matrix: np.ndarray, k: int = 10):
    # matrix 已 L2 正規化 → 內積即餘弦相似度
    q = query / np.linalg.norm(query)
    scores = matrix @ q                       # (N,)
    idx = np.argpartition(-scores, k)[:k]     # O(N)，比 argsort 快
    return idx[np.argsort(-scores[idx])], scores[idx]
```

**為什麼不上線**：

| 缺什麼 | 說明 |
|---|---|
| **可擴展性** | $O(N)$ 全掃。1000 萬向量 × 768 維每次查詢要幾十億次運算 |
| **記憶體** | 全部向量必須常駐（見 [[向量索引 ANN]] 的算式：50M × 768 × 4B = 154 GB） |
| **持久化與增刪改** | 沒有。重啟就沒了；新增一筆要重建整個矩陣 |
| **過濾** | 沒有 metadata 過濾 → **沒有權限控制、沒有多租戶** |
| **recall / 延遲旋鈕** | 沒有。要嘛精確要嘛沒有 |
| **維運** | 沒有備份、複本、監控、分片 |

> ★ **但要補上一句**：**「它仍然有一個不可取代的用途——當 ground truth。」**
> 評估 ANN 索引的實際 recall 時，**必須有一個精確搜尋當基準**（見 [[向量索引 ANN]]）。
> 這句話會把答案從「我知道要用向量資料庫」提升到「我知道它在系統裡的位置」。

### ⑫ 最小 Agent Loop（工具分派 + 錯誤處理 + 步數預算）
*Cognition* → 完整實作見 [[ReAct 與 Agent Loop]]
**★ 關鍵**：三類錯誤三種處理（暫時性靜默重試 / 永久性餵回模型 / 模型自己的錯附上 schema）；三層預算（步數、時間、token）；迴圈偵測。

## ⚠️ 注意 / 什麼時候不適用

- **★ 這一輪考的常常不是演算法，是「漸進式加需求」的應對**。Anthropic 的題目明說是「一題分四個漸進關卡」，xAI 的是「每十分鐘我加一個需求」。**考的是你的程式碼能不能被改。**
- **★ 可以用 AI 工具的輪次，考的是你怎麼指揮與驗證它**（Anthropic、Cursor、Sierra 都明說了）。盲目接受生成的程式碼是扣分的。
- **邊界條件比主流程重要**。空輸入、單一元素、超長、併發、逾時——面試官多半在這裡出手。
- **講清楚取捨再寫**。「我先用 `OrderedDict` 換取簡潔，如果需要自訂淘汰策略再換成手刻的雙向鏈表」。
- **這些實作都是面試用的最小版本**。生產環境請用成熟的函式庫（`tenacity`、`aiolimiter`、`httpx-sse`、向量資料庫）。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開。**待辦：⑦⑧⑨ 這三題是日常真的會寫的，值得各實作一次並收進自己的工具箱。**

## 🔗 相關
- A 類實作 → [[注意力機制]]、[[KV Cache]]、[[分詞與 BPE]]、[[取樣與解碼策略]]
- B 類實作 → [[切塊與文件解析]]、[[ReAct 與 Agent Loop]]、[[向量索引 ANN]]
- [[AI 系統設計框架]] —— 另一半的設計題
- [[AI 工程面試題庫（公司別）]] —— 各公司的 coding 輪形狀
- [[工具-程式面試解題套路]]、[[工具-防禦式編程]] —— 通用解題與邊界處理紀律
