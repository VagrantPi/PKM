---
type: article
title: "Redis 常見的資料型別及底層結構"
source_url: https://juejin.cn/post/7688910933353054244
author: xyLJ
site: 掘金
tags: [backend, redis, data-structure, memory, performance]
captured: 2026-09-25
read_status: read
---

## 📌 30 秒摘要
> 一個 Redis 資料型別**對外穩定、對內會換結構**：資料少時用連續緊湊的結構省記憶體（listpack／intset／embstr），資料多時換成雜湊表或跳表保效能。五型別逐一拆解——String 的 **SDS**（`len`/`alloc`/`flags` 換來 O(1) 取長度、二進位安全、不會緩衝區溢位）與 int／embstr／raw 三種編碼；List 的 **quicklist**＝雙向鏈結串列 + listpack；Set 的 intset／listpack／hashtable 三態；ZSet 的 **skiplist + dict 雙索引**（member→score 靠 dict 的 O(1)，排名與範圍查詢靠跳表的 O(logN)）；Hash 的 listpack／hashtable 與**漸進式 rehash**。主線是記憶體與效能的平衡。

## 🗺 心智圖（Canvas）
![[Redis 資料型別的底層結構.canvas]]

## 🔍 查證與評比
> **可信度 26/30**｜查證 2026-09-25｜✅ 7　⚠️ 2　❌ 0｜判定：完整收
> 來源是 UGC 平台（掘金），作者非知名帳號（1 篇文、24 閱讀）。**作者聲量不計分**，以下關鍵斷言我逐條對 `redis/redis` 原始碼查過。

| 原文斷言 | 查證 | 依據 |
|---|---|---|
| embstr／raw 分界是 **44 bytes** | ✅ | `src/object.c`：`#define OBJ_ENCODING_EMBSTR_SIZE_LIMIT 44` |
| 跳表最大層高 **32**（「不是 64」）、機率 **0.25** | ✅ | `src/server.h`：`ZSKIPLIST_MAXLEVEL 32`、`ZSKIPLIST_P 0.25` |
| 層高用「隨機數 < 0.25 就加一層」決定 | ✅ | `src/t_zset.c` `zslRandomLevel()`：`while (random() < ZSKIPLIST_P*RAND_MAX) level += 1`，並夾在 MAXLEVEL |
| `hash-max-listpack-entries 512`、`hash-max-listpack-value 64` | ✅ | `src/config.c` 兩者預設值正是 512 / 64，且各自掛著 `hash-max-ziplist-*` 舊別名 |
| ziplist 連鎖更新：prevlen 以 **254** 為界、**0xFF** 是 zlend | ✅ | `src/ziplist.c`：`#define ZIP_END 255`、`#define ZIP_BIG_PREVLEN 254` |
| dict 與 skiplist **共用同一份 member**，不複製兩份 | ✅ | `src/t_zset.c` 開頭註解：「the SDS string representing the element is the same in both the hash table and skiplist in order to save memory」 |
| Redis **7.4** 起有 `HEXPIRE`（field 級 TTL） | ✅ | `src/commands/hexpire.json`：`"since": "7.4.0"` |
| 「List 底層主要是 quicklist」 | ⚠️ | **不完整**。Redis 7.2 起**小 List 直接是 listpack 編碼**（`OBJ_ENCODING_LISTPACK`），超過 `list-max-listpack-size` 才轉 quicklist（`src/t_list.c`）。原文只講「quicklist 節點內放 listpack」，漏了外層也可能根本沒有 quicklist |
| 文中 `zskiplistNode` 結構含 `sds ele` 欄位 | ⚠️ | **對到 Redis 7.x 為止**。現行 unstable 已把 SDS **內嵌**在 `level[]` 之後（`/* sds ele is embedded after level[] array */`），並把 level 0 的 `span` 挪去存節點資訊。不影響原文論點，但抄原始碼時要留意版本 |

**結論**：版本敏感的數字原文幾乎都自己標了（6.0 多執行緒 I/O、7.0 listpack 取代 ziplist、7.2 Set 用 listpack、7.4 HEXPIRE），還主動糾正了「最大層高 64」這個網路上流傳的錯誤——在掘金這個平台算相當可靠的一篇。兩個 ⚠️ 都是**不完整**而非錯誤，已在下方工具卡補齊。

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- 知識庫裡完全沒有 Redis 內部結構的內容，而 Redis 是後端日常。這篇補的是「**為什麼我的 key 吃那麼多記憶體**」「**為什麼資料變多之後突然變慢**」這兩個實務問題的底層答案。
- 剛建的 [[工具-延遲任務方案選型]] 方案 A 整個壓在 ZSet 上，這篇正好把 skiplist + dict 為什麼能同時撐排序與查分講清楚。
- **跳表**在整個 vault 裡一頁都沒有（CLRS 不收），這篇是把它補進來的好起點。

## 🧰 這篇給我的工具
- [[工具-Redis資料型別的底層編碼]] — 當我在設計 Redis key、或發現記憶體吃太兇的時候
- [[工具-跳表]] — 當我需要「有序 + 範圍查詢 + 算排名」，在想該用什麼結構的時候
- [[工具-Redis單執行緒下的阻塞風險]] — 當 Redis 偶爾卡一下、或我要下一個作用在大 key 上的指令的時候

## ✨ 關鍵重點

- **一個型別對應多種底層結構，根本原因是「資料量」**。少量資料用連續記憶體（listpack／intset／embstr）省掉指標與物件頭的開銷；量大了換成雜湊表／跳表，避免線性掃描。**轉換通常是單向的**——Hash 從 listpack 轉成 hashtable 後，就算後來刪到剩三個欄位，也不會自動轉回去（避免在閾值邊界反覆抖動）。
- **SDS 的三個欄位各買到一件事**：`len` → O(1) 取長度；只認長度不認 `\0` → **二進位安全**（`0x41 0x42 0x00 0x43` 不會被截斷）；`alloc - len` 算得出剩餘空間 → **追加時自動擴容，不會緩衝區溢位**。`flags` 低三位標示 5 種 SDS 型別（`SDS_TYPE_5/8/16/32/64`），決定 `len`/`alloc` 各佔幾個位元組——短字串就用小頭部。
- **ziplist 省記憶體的代價是連鎖更新**。省在不存前後指標（64 位元系統兩個指標就 16 bytes），改用 `prevlen` + `encoding` 定位鄰居。但 `prevlen` 長度是變動的：前節點 < 254 bytes 時用 1 byte，否則用 5 bytes。一個節點變長 → 下個節點的 `prevlen` 要擴張 → 再下一個也要……骨牌一路傳。**Redis 7.0 用 listpack 取代 ziplist 就是為了拔掉 `prevlen` 這個設計。**
- **ZSet 為什麼要兩個結構**：只有 dict → member 查 score 是 O(1)，但無序，做不了排名與範圍查詢；只有 skiplist → 有序但 member 查 score 要走查找。所以兩個都留，**而 member 的 SDS 是共享的，不會存兩份**（原始碼註解明講）。
- **跳表的 span 是拿來算排名的**：每層前進指標額外記「這一跳跨過幾個元素」，`ZRANK` 沿路把 span 加起來就是名次，不必從頭數。
- **為什麼跳表不是 B+ 樹**：B+ 樹壓低樹高是為了減少**磁碟 I/O**，Redis 純記憶體，這個優勢發揮不出來；而 B+ 樹有頁分裂（填充率下降、寫入抖動），跳表沒有。加上跳表程式碼短得多、好維護好擴充。
- **漸進式 rehash 是「把一次大操作拆成很多次小操作」的範本**。字典內部留兩張表，擴縮容時不一次搬完，而是每次增刪改查順手搬一部分桶，直到舊表清空。**這個心法在單執行緒模型下到處適用**，值得偷。
- **List 做訊息佇列的三個不足**（原文寫得好）：彈出即刪，消費失敗會丟；沒有 ACK；不支援消費者組與訊息回溯。要這些就用 **Redis Stream**。`BRPOP key 0` 至少能讓消費者阻塞等待而不是空轉輪詢。
- **Hash vs JSON 字串存物件**：Hash 可以只改一個欄位（`HINCRBY product:1001 stock -1`），JSON 字串要整包讀出→反序列化→改→序列化→寫回。但 Hash 不適合巢狀結構。
- **過期時間的粒度**：預設只能設在整個 Redis key 上，**Redis 7.4 起才有 `HEXPIRE` 能對單一 field 設 TTL**。7.4 以前別把 Hash 的 field 當獨立 key 用。

## 💬 原文摘錄
- 「Redis 對外提供穩定的資料型別，對內根據資料規模和操作特點選擇最合適的資料結構，從而做到小資料省記憶體、大資料保效能。」
- 「這裡的『單執行緒』指的是命令執行是單執行緒的……需要注意，Redis 6.0 起網路 I/O 已經支援多執行緒，只有命令執行仍然是單執行緒。」
- 「Redis 處理資料的時候只認長度，不認特殊字元，從而保證存進去的資料是什麼樣，拿出來資料就是什麼樣。」
- 「Redis 中最大層高是 ZSKIPLIST_MAXLEVEL = 32（不是 64）。」
- 「不會一次性遷移全部資料，避免長時間阻塞主執行緒……把一次大操作拆成許多次小操作，降低單次阻塞時間。」

## 🔗 相關
- [[工具-延遲任務方案選型]] — 那張卡的方案 A 整個建立在 ZSet 上，這篇解釋了它憑什麼快
- [[雜湊表|雜湊表 Hash Table]]（[[演算法導論]]）— 對照組：CLRS 講雜湊表的理論，這篇講 Redis 實際怎麼做漸進式 rehash
- [[工具-儲存引擎B-Tree與LSM-Tree]] — 對照組：磁碟導向的結構為什麼長得不一樣（正是「跳表不用 B+ 樹」那一節的反面）
