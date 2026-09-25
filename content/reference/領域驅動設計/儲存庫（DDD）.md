---
type: reference
name: "儲存庫 Repository"
source: "[[領域驅動設計]]"
source_type: book
tags: [ddd, domain-driven-design, building-blocks]
triggers: [想把資料庫細節藏起來, 領域層不想碰 SQL, 想像操作集合一樣拿物件, 存取聚合的統一入口]
---

## 🎯 什麼情境該想到我
> ★ **分工**：這頁講「**為什麼它屬於領域層、介面該長什麼樣**」（模型問題）；
> [[儲存庫]]（PoEAA）講「**它最常被做錯的地方，以及讀寫分離**」（實作與反模式）。

當你希望領域層「像操作一個記憶體集合那樣」取得與保存物件，而不必在領域邏輯裡摻進 SQL、ORM 或查詢細節時。

## ⚙️ 怎麼用（步驟 / 公式）
意圖：提供像集合的介面來存取聚合根，封裝背後的持久化細節。
1. **只對聚合根**設計 Repository，一個聚合對應一個 Repository（不替聚合內部物件設）。
2. 介面用領域語彙描述：如 `add`、`findById`、`remove`、依條件查詢，回傳的是完整、可用的聚合。
3. 把資料庫、快取、查詢組裝等細節藏在實作裡，領域層只依賴介面。
4. 需要複雜篩選時，讓 Repository 接受[[規格]]物件來表達查詢條件。

### ★★ DDD 的定義比一般人用的窄：一個聚合一個儲存庫

```
★ Evans 的原意：★★ 儲存庫是「聚合的集合」，讓你覺得所有聚合都在記憶體裡
→ ★ 三條直接推論：
  ① ★★ 一個儲存庫對應一個聚合（★ 不是一張表、不是一個實體）
  ② ★★ 它回傳完整的聚合（★ 不是部分載入的物件）
  ③ ★★ 它的介面用領域語言（★ FindOverdue，不是 SelectWhereStatusAndDate）
```
> ★★ **「一個儲存庫對應一個聚合」是最常被違反的一條**：
> ★ 實務上常看到 `OrderRepo`、`OrderLineRepo`、`OrderStatusRepo` 三個——
> **而 `OrderLine` 是聚合內部的實體，它不該有自己的儲存庫**（見 [[從屬對應]]）。
> → ★ **判準：這個型別是聚合根嗎？** 不是 → 它不該有儲存庫。

### ★★ Go 的實作：介面在哪一邊，是這一頁最實際的問題

```go
// ★★ Evans 的原意是「介面在領域層、實作在基礎設施層」（依賴反轉）
package order
type Repository interface {              // ★ 領域層宣告它需要什麼
    Get(ctx context.Context, id ID) (*Order, error)
    Save(ctx context.Context, o *Order) error
    FindOverdue(ctx context.Context, asOf time.Time) ([]*Order, error)
}

// ★★ 但 Go 的慣例是「介面定義在消費方」（見 [[分離介面]]）—— 兩者衝突嗎？
```
★★ **不衝突，因為領域層就是消費方。** ★ 但有兩個 Go 特有的調整：
```
① ★★ 介面要小，只放「這個使用場景需要的方法」
   ★ 不要一個十個方法的 Repository 介面（★ 替換性是零，見 [[工具-Go介面小而隱式]]）
   → ★ 一個 settlement 流程只需要 Get + Save，就宣告一個兩方法的介面

② ★★ 交易怎麼傳？—— ★ 這是 Evans 沒談、但 Go 必須決定的
   a. ★ Repository 方法收 Querier 參數（★ 明確，但★★ 領域層的介面出現了 db 型別）
   b. ★★ 把交易放 ctx（★ 隱式，★ 領域介面乾淨，但★★ 「有沒有在交易裡」看不出來）
   c. ★ 領域層只宣告不含交易的介面，交易邊界完全在 [[服務層]]，
      由 repo 實作自己從 ctx 或注入取得 tx
   → ★★ 實務上 (a) 最直白：★ 犧牲一點純度換來「交易邊界可見」
```
★ **我會選 (a)**：★★ 「交易邊界看得見」在除錯與 review 時的價值，
**高於「領域層完全不認識 db 型別」這個純度目標。**

### ★★ 儲存庫的介面最常見的三個腐敗

```go
// ❌★★ ① 退化成 CRUD（★ 那就不是儲存庫，是 [[表格資料閘道]] 的別名）
Create / GetByID / Update / Delete / List

// ❌★★ ② 每加一個列表頁就加一個 FindByXxx
FindByCustomer / FindByStatus / FindByDateRange / FindByCustomerAndStatus …
// → ★ 十五個方法，★★ 而且它們全部回傳完整聚合（列表頁只要五個欄位）
// → ✅ ★ 讀側直接用 [[表格資料閘道]] 回傳扁平 DTO（見 [[儲存庫]]）

// ❌★★ ③ 洩漏查詢語言
FindBy(ctx context.Context, criteria map[string]any) ([]*Order, error)
Find(ctx context.Context, sql string, args ...any) ([]*Order, error)
// → ★ 呼叫端開始依賴你的 schema，★★ 而且無法加索引、無法 EXPLAIN
```
★★ **② 是最常見的**，而它的正確解不是「把介面做得更通用」，
★ 而是**承認讀與寫是兩條路**（CQRS 最務實的一半）。

### ★★ 一個實務上的關鍵細節：Save 的語義

```go
// ★★ Save 是 upsert 還是 update？—— ★ 這個歧義會造成真實的 bug
func (r *Repo) Save(ctx context.Context, q db.Querier, o *order.Order) error

// ★ 三種可能的語義：
//   a. ★ upsert：新建與更新都用 Save（★ 方便，★★ 但新建時的 version=0 檢查很怪）
//   b. ★★ 分開：Add（新建）與 Save（更新）—— ★ 語義明確，推薦
//   c. ★ 只有 Save，靠 version==0 判斷新建（★★ 隱晦，而且 version 是實作細節）
```
★★ **選 (b)**：
```go
func (r *Repo) Add(ctx context.Context, q db.Querier, o *order.Order) error   // ★ INSERT
func (r *Repo) Save(ctx context.Context, q db.Querier, o *order.Order) error  // ★ UPDATE + 樂觀鎖
```
★ **理由**：★★ `Add` 撞唯一鍵 = 「已存在」（可以是冪等的訊號）；
`Save` 的 `RowsAffected()==0` = 「被別人改過」——★ **兩種失敗的意義完全不同**，
混在一個方法裡你分不出來。

### ★ 兄弟辨析
| | 差別 |
|---|---|
| [[儲存庫]]（PoEAA） | ★ 實作面：對應器 + 查詢介面，以及過度使用的警告 |
| [[聚合]] | ★ 一個儲存庫對應一個聚合 |
| [[工廠]] | ★ 建立聚合；儲存庫負責重建與持久化 |
| [[表格資料閘道]] | ★ 讀側該直接用它 |
| [[資料對應器]] | ★ 儲存庫內部用它做 reconstitute |

## 🧪 我實際套用的紀錄
- （待填）

## ⚠️ 注意 / 什麼時候不適用
- 不要替非聚合根的實體開 Repository，否則會繞過聚合根破壞邊界。
- Repository 是領域概念，別讓它退化成到處是 CRUD 方法的資料存取層（DAO）。
- 若只是單純建立物件、而非取回既有物件，那是[[工廠]]的職責，別混在一起。

- **★★ 一個儲存庫對應一個「聚合」，不是一張表也不是一個實體。** `OrderLineRepo` 是錯的——它是聚合內部實體。
- **★★ `Add`（新建）與 `Save`（更新）要分開。** `Add` 撞唯一鍵 = 已存在（可當冪等訊號）；`Save` 的 `RowsAffected()==0` = 被別人改過——兩種失敗意義完全不同。
- **★★ 每加一個列表頁就加一個 `FindByXxx` 是最常見的腐敗。** 正確解不是把介面做得更通用，而是承認讀與寫是兩條路。
- **★★ 不要洩漏查詢語言**（`FindBy(map[string]any)`、`Find(sql string)`）。呼叫端會依賴你的 schema，而且無法加索引、無法 EXPLAIN。
- **★ 交易怎麼傳：實務上「方法收 `Querier` 參數」最直白**——犧牲一點純度換來「交易邊界可見」。
- **★ 介面要小，只放這個使用場景需要的方法。** 十個方法的 Repository 介面替換性是零。
- **★ 判準：這個型別是聚合根嗎？** 不是 → 它不該有儲存庫。
- **退化成 CRUD 方法名就不是儲存庫，是 [[表格資料閘道]] 的別名。**

## 🔗 相關工具
- [[聚合]]
- [[工廠]]
- [[規格]]
- [[領域驅動設計]]
- [[儲存庫]] —— ★ 實作面與過度使用的警告（PoEAA）
- [[聚合]] —— 一個儲存庫對應一個聚合
- [[工廠]] —— 建立 vs 重建
- [[表格資料閘道]] —— ★ 讀側該直接用它
- [[資料對應器]] —— reconstitute
- [[分離介面]]、[[工具-Go介面小而隱式]] —— 介面該多小、放哪一邊
- [[樂觀離線鎖]] —— Save 的併發語義
