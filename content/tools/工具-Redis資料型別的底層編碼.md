---
type: tool
name: "Redis 資料型別的底層編碼 Object Encoding"
source: "[[Redis 資料型別的底層結構]]"
source_type: article
tags: [backend, redis, data-structure, memory, performance]
triggers: [Redis記憶體吃太兇, 存物件該用Hash還是JSON字串, Redis的key要怎麼設計才省記憶體, 資料量變大後Redis突然變慢, 想知道某個key底層到底是什麼結構]
---

## 🎯 什麼情境該想到我
當你「Redis 記憶體用量不合理、或某個 key 資料變多之後操作突然變慢」，想知道**Redis 在背後幫你換了什麼結構**的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 核心規則：型別對外穩定，編碼對內會換

同一個 Redis 型別，**資料少時用連續緊湊的結構省記憶體，資料多時換成雜湊表／跳表保效能**。

| 型別 | 小資料量 | 大資料量 | 切換門檻（預設值） |
|---|---|---|---|
| String | `int`（可用 long 表示的整數）、`embstr`（≤ 44 bytes） | `raw`（> 44 bytes） | 44 bytes（原始碼硬寫，不可設定） |
| List | `listpack`（7.2 起，小 List 直接就是 listpack） | `quicklist`（雙向鏈結串列，每個節點內放 listpack） | `list-max-listpack-size`（預設 `-2`，即每節點 8 KB） |
| Hash | `listpack` | `hashtable` | `hash-max-listpack-entries 512`、`hash-max-listpack-value 64` |
| Set | `intset`（全是整數）、`listpack`（7.2 起） | `hashtable` | `set-max-intset-entries 512`、`set-max-listpack-entries 128` |
| ZSet | `listpack` | `skiplist` + `dict`（兩個同時存在） | `zset-max-listpack-entries 128`、`zset-max-listpack-value 64` |

> **查證 2026-09-25**：以上門檻值全部取自 `redis/redis` 的 `src/config.c` 與 `src/object.c`
> （`OBJ_ENCODING_EMBSTR_SIZE_LIMIT 44`）。Redis **7.0** 用 listpack 取代 ziplist（Hash／ZSet／quicklist 節點），
> **7.2** 讓 Set 與小 List 也能用 listpack。`hash-max-listpack-*` 這組設定都保留了 `hash-max-ziplist-*` 舊別名。

### ★ 兩個一定要記住的行為

**1. 轉換是單向的。** Hash 從 listpack 轉成 hashtable 之後，就算你把欄位刪到剩三個，**也不會自動轉回去**——Redis 刻意不做，免得在閾值邊界反覆轉換抖動。所以「先塞一萬筆再刪到剩十筆」的 key，記憶體用量會一直停在 hashtable 的水準。要救只能砍掉重建。

**2. 用 `OBJECT ENCODING` 直接問，不要用猜的。**

```
> RPUSH mylist a b c
> OBJECT ENCODING mylist
"listpack"
> SET n 12345
> OBJECT ENCODING n
"int"
> SET s "0123456789012345678901234567890123456789012345"   # 46 bytes
> OBJECT ENCODING s
"raw"
```
搭配 `MEMORY USAGE key` 量實際佔用，比任何估算公式都準。

### 怎麼利用這件事

- **拆大 key 成多個小 key**，讓每個都落在 listpack 區間。一萬個欄位的 Hash → 用 `field % 100` 拆成 100 個 Hash，總記憶體通常明顯下降（省掉一萬份雜湊節點與指標），代價是多一層路由邏輯。
- **短字串盡量壓在 44 bytes 內**。`embstr` 把 SDS 與 redisObject 放在**同一塊連續記憶體**，只要一次 malloc；`raw` 要兩次分配、兩塊記憶體。另外 `embstr` 是唯讀最佳化——**對它執行任何修改類命令（`APPEND`、`SETRANGE`）都會轉成 `raw`**，且不會轉回去。
- **存物件時 Hash 常優於 JSON 字串**：能只改一個欄位（`HINCRBY product:1001 stock -1`），不必整包讀出→反序列化→改→序列化→寫回。反過來，**需要巢狀結構時 JSON 字串比較實際**，Hash 只有一層 field-value。
- **不要為了省記憶體把門檻調很大**。listpack 查一個 field 是**順序掃描 O(N)**，之所以能用是因為 N 小。把 `hash-max-listpack-entries` 調到 5000，等於讓每次 `HGET` 掃 5000 個 entry。

### SDS：String 底下那層

`String` 的字串內容由 **SDS（Simple Dynamic String）** 承載，四個部分：`len`、`alloc`、`flags`、`buf[]`。三個欄位各買到一件事：

| 欄位 | 換到什麼 |
|---|---|
| `len` | **O(1) 取長度**（C 字串要 `strlen` 掃到 `\0`，O(N)） |
| `len`（只認長度不認 `\0`） | **二進位安全**——`0x41 0x42 0x00 0x43 0x44` 存進去不會在 `0x00` 被截斷 |
| `alloc` | `alloc - len` = 剩餘空間，追加時不夠就自動擴容，**不會緩衝區溢位**（C 的 `strcat` 會） |
| `flags` | 低三位標示 5 種型別（`SDS_TYPE_5/8/16/32/64`），決定 `len`/`alloc` 各佔幾 bytes——**短字串用小頭部**省記憶體 |

`buf` 結尾仍留一個 `\0`（分配時 `s_malloc_usable(hdrlen+initlen+1, ...)` 的那個 `+1`），**但不計入 `len` 也不計入 `alloc`**——純粹為了能直接餵給部分 C 標準庫函式。

## 🧪 我實際套用的紀錄
- 2026-09-25：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **門檻值是可設定的，別把預設值當常數**。線上環境先 `CONFIG GET hash-max-listpack-entries` 確認，有些託管服務（雲端 Redis）會改預設。
- **`intset` 只在「全部成員都是整數」時成立**。塞進一個非整數成員，整個 Set 立刻轉走，而且回不去。
- **listpack ≠ 一定省**。成員大但數量少時（例如 10 個各 1 KB 的 field），連續記憶體反而造成大塊分配與搬移成本，這也是 `hash-max-listpack-value 64` 存在的原因。
- **省記憶體和避免阻塞是兩件事**。把 key 塞大即使編碼沒轉，一個 `HGETALL` 照樣能卡住主執行緒 → [[工具-Redis單執行緒下的阻塞風險]]。
- 這張卡講的是**單機資料結構**，不涵蓋叢集分片、持久化（RDB／AOF）與淘汰策略。

## 🔗 相關工具
- [[工具-跳表]] — ZSet 大資料量時那半邊的結構
- [[工具-Redis單執行緒下的阻塞風險]] — 結構選對了，指令還是可能把你卡住
- [[工具-延遲任務方案選型]] — ZSet 當延遲佇列時，記憶體估算就是靠這張卡
- [[雜湊表|雜湊表 Hash Table]] — 對照組：CLRS 的理論 vs Redis 的漸進式 rehash 實作
