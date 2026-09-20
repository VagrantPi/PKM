---
type: reference
name: "分詞與位元組對編碼 Tokenization & BPE"
source: "[[AI 工程面試題庫（公司別）]]"
source_type: interview-questions
tags: [ai, llm, tokenization, nlp, cost]
triggers: [中文為什麼特別燒token, 模型為什麼不會數字母, BPE到底怎麼合併, 為什麼算術題會算錯, prompt結尾多一個空格會怎樣]
---

> **對應原題**（Common ‧ LLM Internals / Coding）
> - How does Byte Pair Encoding work, and what are its **failure modes (numbers, code, non-Latin scripts)**?
>   — *Asked at: Alibaba, Sarvam AI, Hugging Face*
> - Implement BPE training and encoding from scratch.

## 🎯 什麼情境該想到我
當你「**想搞懂中文為什麼比英文貴、或模型為什麼連字母都數不對**」的時候。分詞是模型看世界的第一道濾鏡，**幾乎所有「LLM 為什麼笨得莫名其妙」的案例都能追到這裡。**

## ⚙️ 怎麼用（演算法）

### BPE 的一句話
**從最小單位出發，反覆把「最常一起出現的相鄰兩個單位」合併成一個新單位，做 $V$ 次。**

原本是 1994 年的資料壓縮算法，Sennrich et al. (2016) 拿來做 NMT 的 subword。

### 訓練（學合併規則）

```python
from collections import Counter

def train_bpe(corpus_bytes: bytes, num_merges: int):
    ids = list(corpus_bytes)              # 起點：0..255，每個 byte 一個 id
    merges = {}                           # (a, b) -> new_id
    vocab = {i: bytes([i]) for i in range(256)}

    for i in range(num_merges):
        pairs = Counter(zip(ids, ids[1:]))        # 統計所有相鄰對
        if not pairs: break
        top = max(pairs, key=pairs.get)           # ★ 貪婪：只挑最高頻那一對
        new_id = 256 + i
        merges[top] = new_id
        vocab[new_id] = vocab[top[0]] + vocab[top[1]]
        ids = merge(ids, top, new_id)             # 全文替換
    return merges, vocab

def merge(ids, pair, new_id):
    out, i = [], 0
    while i < len(ids):
        if i < len(ids) - 1 and (ids[i], ids[i+1]) == pair:
            out.append(new_id); i += 2
        else:
            out.append(ids[i]); i += 1
    return out
```

### 編碼（套用規則）

**關鍵：必須按照學到的順序套用，不能貪婪地挑最長匹配。**

```python
def encode(text: str, merges: dict) -> list[int]:
    ids = list(text.encode("utf-8"))
    while len(ids) >= 2:
        pairs = set(zip(ids, ids[1:]))
        # 挑「最早被學到」的那一對（merges 的插入順序 = 優先序）
        pair = min(pairs, key=lambda p: merges.get(p, float("inf")))
        if pair not in merges: break
        ids = merge(ids, pair, merges[pair])
    return ids

def decode(ids, vocab) -> str:
    return b"".join(vocab[i] for i in ids).decode("utf-8", errors="replace")
```

> **面試官會挑的點**：為什麼 `decode` 要 `errors="replace"`？因為**單一 token 的 byte 序列可能是不完整的 UTF-8 字元**——串流輸出時尤其常見（中文一個字 3 bytes，可能跨 token）。串流 API 必須緩衝到能解碼為止，否則會吐出亂碼。

### Byte-level BPE（GPT-2 起的標準做法）
先把文字轉成 **UTF-8 bytes**，用 256 個 byte 當 base vocabulary。好處是**永遠不會有 OOV**——任何字元、任何語言、任何 emoji 都能被表示，最差就是切得很碎。

### 幾種分詞器的差別

| 方法 | 選擇準則 | 用者 |
|---|---|---|
| **BPE** | 頻率最高的相鄰對 | GPT 系列、Llama、tiktoken |
| **WordPiece** | 最大化語言模型似然（挑 $\frac{P(ab)}{P(a)P(b)}$ 高的） | BERT |
| **Unigram LM** | 反過來：從大詞彙表**刪**掉損失最小的 | SentencePiece 預設、T5、多語模型常用 |

## ⚠️ 注意 / 失效模式（★ 這題的重點在這裡）

### 1. 數字 —— 算術能力的隱形殺手
BPE 依頻率合併，所以 `"2024"` 可能是 1 個 token，`"2025"` 卻被切成 `"202"+"5"`。**同一個數量級的數字被切成不同形狀**，模型很難學到穩定的位值概念。

→ **Llama 系列的做法是強制把所有數字逐位切開**（`1`,`2`,`3`,`4`），犧牲 token 效率換取算術一致性。
→ 實務對策：要精算就給工具（calculator / code interpreter），別讓模型心算。

### 2. 程式碼 —— 空白與縮排
GPT-2 的 tokenizer 把每個空格當一個 token，**Python 的 4 層縮排就吃掉 16 個 token**。後來的 `cl100k_base`（GPT-3.5/4）加入了「連續空白」token 才改善。

→ 影響：老模型寫 Python 特別貴、特別容易在縮排出錯。評估 code 場景一定要看實際 tokenizer。

### 3. 非拉丁語系 —— ★ 中文使用者最有感
UTF-8 下一個常見漢字是 **3 個 bytes**。如果 tokenizer 的訓練語料以英文為主、中文合併規則學得少：

| 情況 | 「知識庫」3 字 | 效果 |
|---|---|---|
| 中文覆蓋好（如 Qwen） | 1–2 tokens | 正常 |
| 中文覆蓋差 | **最多 9 tokens** | **成本 ×N、有效上下文 ÷N、延遲 ×N** |

這不只是錢的問題：**同樣的 128K context window，中文能裝的實際內容可能只有英文的三分之一。**

→ 這正是 Sarvam AI（印度語系）、Alibaba（Qwen 多語）會考這題的原因——**為目標語言重訓或擴充 tokenizer 是他們的核心工作**。
→ 自己要驗的話：拿你真實的中文語料跑一次 tokenizer，量 `tokens / 字元` 比值，不要用別人的數字。

### 4. Glitch tokens
tokenizer 的訓練語料和模型的訓練語料**不是同一份**時，會出現「詞表裡有、但模型幾乎沒見過」的 token。餵給模型會產生完全失控的行為（著名的 `SolidGoldMagikarp`，Rumbelow & Watkins, 2023）。

### 5. 「strawberry 有幾個 r」
模型看到的是 token 不是字母。拼字、反轉字串、數字元這類任務，**失敗是結構性的，不是模型笨**。再怎麼 prompt 也治不好——要用工具。

### 6. 尾隨空白
`"The capital is "`（結尾有空格）會讓模型很難接——因為正確的下一個 token 通常是 `" Paris"`（**含前導空格**），而空格已經被你用掉了。

→ **規則：prompt 結尾不要留空白。** 這是實務上極常見又極難察覺的品質 bug。

### 7. 換 tokenizer = 換模型
tokenizer 與模型權重綁死。擴充詞表要重新初始化 embedding 並續訓，不是改個設定檔的事。

## 🧪 我實際套用的紀錄
- 2026-09-20：從面試題庫展開。**待辦：拿自己的中文語料量一次各家 tokenizer 的 tokens/字元比。**

## 🔗 相關
- [[注意力機制]] —— tokenize 之後才進得了模型
- [[位置編碼與 RoPE]] —— token 數直接決定上下文預算
- [[服務棧選型與降本]] —— token 數就是錢，分詞效率是降本的第一道槓桿
