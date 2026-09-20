---
type: reference
name: "前綴快取 Prefix / Prompt Caching"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, inference, cost, latency, serving]
triggers: [同樣的system prompt每次都重算太浪費, 怎麼讓TTFT變快又省錢, 快取為什麼一直沒命中, prompt裡放時間戳會怎樣, agent每一步都重放歷史很貴]
---

> **對應原題**（Common ‧ Inference, Serving and GPU Performance）
> - Explain prefix caching / prompt caching. **When should you use it, and what invalidates a cached prefix?**
>   — *Asked at: Moonshot AI, Character.AI*

## 🎯 什麼情境該想到我
當你「**有一段很長的 system prompt / few-shot / 工具定義每次請求都要重送**」的時候。這是**唯一一個能同時砍掉延遲和成本、而且完全不影響輸出品質**的優化——而且多數人設定錯了還不知道。

## ⚙️ 怎麼用（機制）

### 它在快取什麼
不是快取「答案」，是**快取 prefill 算出來的 KV cache**。

```
請求 1: [system prompt 2000 tok][few-shot 3000 tok][問題 A]
            └──── prefill 一次，KV 存起來 ────┘
請求 2: [system prompt 2000 tok][few-shot 3000 tok][問題 B]
            └──── 直接載入，不用重算 ────┘  只 prefill 問題 B
```

同樣的輸入必然算出同樣的 K、V，**所以重用是數學上無損的**——輸出品質完全不變。

### ★ 為什麼「只能是前綴」
因為 **causal attention**：位置 $i$ 的 K、V 只依賴 $0 \dots i$ 的內容。

**所以只要有任何一個 token 改變，它之後的所有 KV 全部作廢。** 前面不變、後面變 → 可以重用前面。前面變了 → 全丟。

這一條推論出後面所有的設計原則。

### ★ 設計原則：穩定的放前面，變動的放後面

這是唯一真正重要的實務規則：

```
✅ 正確的排列
┌────────────┬──────────┬─────────┬──────────┬──────────┬────────┐
│ 工具定義    │ system   │ few-shot│ 檢索文件  │ 對話歷史  │ 當前問題│
└────────────┴──────────┴─────────┴──────────┴──────────┴────────┘
  ←─────────── 越左邊越穩定 ───────────────────────────────→ 每次都變

❌ 常見錯誤
┌──────────────────────┬────────────┬──────────┐
│ "現在時間 2026-09-20  │ 工具定義    │ system   │   ← 整個快取永遠不命中
│  14:23:07，使用者 ID…"│            │          │
└──────────────────────┴────────────┴──────────┘
```

> **把時間戳、request ID、使用者 ID 放在 prompt 最前面，是一個能讓快取命中率歸零的單行 bug。**
> 需要它們就放最後面。

### Anthropic API 的實作（2026-09-20 查證自官方文件）

**兩種用法**：
| 方式 | 做法 |
|---|---|
| **自動快取** | 在 request body **頂層**加 `cache_control`，系統自動把斷點放在最後一個可快取區塊，並隨對話成長自動前移 |
| **顯式斷點** | 在個別 content block 上放 `cache_control`，精確控制快取邊界 |

**快取的範圍**：**tools → system → messages（照這個順序）**，一路到標有 `cache_control` 的那個 block 為止。

**價格結構**（相對 base input token 價）：
| 項目 | 倍率 |
|---|---|
| 5 分鐘 TTL 寫入 | **1.25×** |
| 1 小時 TTL 寫入 | **2×** |
| **快取讀取** | **0.1×**（Fable 5.1 / Mythos 5.1 為 0.025×） |

→ **寫入貴一點點，讀取便宜 10 倍。** 只要同一個前綴被重用 **≥ 2 次**就開始賺。

**最低可快取長度**（不到就靜默不快取，**不會報錯**）：
| 模型 | 最低 token |
|---|---|
| Fable 5.1 / Mythos 5.1 / Opus 5 / Fable 5 / Mythos 5 | **512** |
| Opus 4.8 / Sonnet 5 / Sonnet 4.6 / Sonnet 4.5 | **1,024** |
| Mythos Preview / Opus 4.7 | **2,048** |
| Opus 4.6 / Opus 4.5 | **4,096** |

> **驗證有沒有命中**：看 response 的 `cache_creation_input_tokens` 與 `cache_read_input_tokens`。**兩個都是 0 就代表根本沒快取到**（多半是沒達到最低長度）。差一點點就達標時，**把快取內容補長到門檻反而更省錢**。

**其他機制**：
- **20 個 block 的 lookback window** —— 斷點只在你標記處寫入，不會自動往回找穩定內容
- **多個斷點不額外收費** —— 只按實際快取與讀取的量計價，所以可以大方地標多個邊界，讓不同變動頻率的區段各自快取

### ★ 一個必踩的坑（官方文件明確點名）

> 你的 prompt 是：block 1–5 是大段靜態內容，block 6 是「時間戳 + 使用者訊息」。你把 `cache_control` 放在 **block 6**。
>
> **結果：永遠不命中。** 因為快取寫入只發生在斷點處，而斷點的 hash 包含了每次都在變的 block 6。lookback **不會回頭幫你快取斷點之前的穩定內容**——它只找「先前的請求已經寫入的條目」。
>
> **正解：把 `cache_control` 放在 block 5**（最後一個跨請求不變的 block）。
>
> ⚠️ **自動快取也會踩同一個坑**——它把斷點放在「最後一個可快取區塊」，在這種結構下正好是每次都變的那個。**後綴會變（時間戳、per-request context、當前訊息）時，一定要用顯式斷點放在靜態前綴的結尾。**

## ★ 什麼會讓快取失效（面試題的後半，2026-09-20 查證）

### 一、內容本身
- 前綴的**任何一個 token** 不同——包含空白、標點、JSON 欄位順序
- **在前面插入內容** → 後面所有 token 的位置都偏移 → RoPE 角度全變 → **KV 全部作廢**（這是為什麼「在中間插一段」比「在後面加一段」貴得多）

### 二、請求參數（Anthropic 官方的失效表）
| 變動 | tools 快取 | system 快取 | messages 快取 |
|---|---|---|---|
| **修改工具定義**（名稱／描述／參數） | ✘ | ✘ | ✘ —— **整個快取失效** |
| 開關 web search | ✓ | ✘ | ✘（會改動 system prompt） |
| 開關 citations | ✓ | ✘ | ✘ |
| 切換 `speed: "fast"` | ✓ | ✘ | ✘ |
| 改 `tool_choice` | ✓ | ✓ | ✘ |
| 增刪**任何位置**的圖片 | ✓ | ✓ | ✘ |
| 改 thinking 參數（模式 / budget） | 視模型 | 視模型 | ✘ |
| 改 `output_config.effort` | 視模型 | 視模型 | ✘ |

（✓ = 仍有效、✘ = 失效）

**兩個反直覺的重點**：
1. **改工具定義會把整個快取打掉**——連 system 和 messages 都一起。**工具 schema 要穩定，別動態生成。**
2. **thinking / effort 的設定是被渲染進 prompt 的**，所以改它一定讓 message 快取失效。

**不影響快取的**：`temperature`、`top_p`、`max_tokens` 等取樣參數——因為 KV 與取樣無關。

### 三、時間與容量
- **TTL 到期**（Anthropic 預設 5 分鐘，可選 1 小時）
- 自架時的 **LRU 驅逐**——顯存不夠就丟

### 四、環境
- 模型版本、量化方式、推論框架版本、tensor parallel 配置改變 → 全部作廢

## 什麼場景該用

| 場景 | 效益 |
|---|---|
| **長 system prompt / 大量 few-shot** | ⭐⭐⭐ 典型用例 |
| **Agent loop** | ⭐⭐⭐ 每一步都重放整段歷史+工具定義，**這是最賺的場景** |
| **多輪對話** | ⭐⭐⭐ 歷史是天然的成長前綴（自動快取就是為此設計） |
| **同一份文件問很多問題** | ⭐⭐⭐ 文件當前綴 |
| **批次處理同模板不同資料** | ⭐⭐ 模板在前、資料在後 |
| 每次 prompt 都完全不同 | ❌ 純虧（付了寫入費卻沒人讀） |
| prompt 短於最低門檻 | ❌ 靜默失效 |

## ⚠️ 注意 / 什麼時候不適用

- **上面的價格、TTL、最低長度會變**。本頁數字查證於 **2026-09-20**，以 <https://platform.claude.com/docs/en/docs/build-with-claude/prompt-caching> 為準。
- **不同廠商機制不同**：OpenAI 是自動、無需標記；Google 需要顯式建立 context cache。跨廠商時不能假設行為一致。
- **失敗是靜默的**。沒達到最低長度不會報錯，只會安靜地照全價算。**一定要監控 `cache_read_input_tokens` 的比例**。
- **快取不減少 context window 佔用**。省的是計算與錢，不是 token 額度。
- **thinking block 不能直接用 `cache_control` 快取**，但出現在先前 assistant 回合時可以隨其他內容一起被快取；從快取讀出時**仍計入 input token**。
- **自架（vLLM）的前綴快取要顯式開啟**（`--enable-prefix-caching`），且前綴不重複的流量會純虧 hash 開銷。
- **安全考量**：多租戶環境下要確保不同使用者的快取不會互相命中——別把使用者資料放進共用前綴。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開，Anthropic 側細節已查證官方文件。**待辦：檢查自己的 agent 是否把變動內容放在了前面。**

## 🔗 相關
- [[PagedAttention 與 vLLM]] —— 自架時的底層機制（block 共享）
- [[KV Cache]] —— 被快取的東西
- [[Prefill 與 Decode]] —— 省掉的是 prefill，直接改善 TTFT
- [[服務棧選型與降本]] —— 降本槓桿排序中最優先的一項
- [[ReAct 與 Agent Loop]] —— 受益最大的場景
