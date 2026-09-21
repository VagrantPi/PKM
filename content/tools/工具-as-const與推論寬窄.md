---
type: tool
name: "as const 與推論寬窄"
source: "[[Total TypeScript Essentials]]"
source_type: book
tags: [software, typescript, type-system]
triggers: [推論出來的型別太寬變成string, 陣列被推成string陣列但我要元組, 常數表想拿來當型別用, as const跟satisfies該用哪個, readonly會不會影響執行期]
---

## 🎯 什麼情境該想到我
當你「**明明傳的就是那個字串，TS 卻說 `string` 不能指派給 `"rock" | "country"`**」的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 先理解為什麼會被推寬——TS 是照「還能不能被改」推的
| 宣告 | 推論結果 | 原因 |
|---|---|---|
| `let x = "rock"` | `string` | `let` 可以重新指派，所以推寬以容納未來的值 |
| `const x = "rock"` | `"rock"` | `const` 不能重新指派，可以安全地推成字面量 |
| `const o = { s: "rock" }` | `{ s: string }` | ⚠️ **物件屬性即使在 `const` 下仍可變**，所以照樣推寬 |

第三列是最常踩的坑：**你用了 `const`，但物件裡面的屬性還是被推成 `string`。**

### 三種修法，按情境挑
```ts
// 1. 標註變數：可以重新指派，但限制在聯集內
let genre: AlbumGenre = "rock";

// 2. 標註物件：整體受約束（但會抹掉精確推論）
const attrs: AlbumAttributes = { status: "on-sale" };

// 3. as const：整個結構凍成唯讀的字面量
const attrs = { status: "on-sale" } as const;
```

### `as const` 拿來做 JS 風格的列舉
這是它最有價值的用法之一——**一份來源，同時給你執行期的值與型別**：
```ts
const albumTypes = {
  CD: "cd",
  VINYL: "vinyl",
  DIGITAL: "digital",
} as const;

type AlbumType = (typeof albumTypes)[keyof typeof albumTypes];
// "cd" | "vinyl" | "digital"
```
比起手寫一份 `type AlbumType = "cd" | "vinyl" | "digital"`，這樣**不會有兩份會走鐘的來源**。

### 4. ★ 推論寬窄的完整規則表

```ts
let   a = "hello";                 // string          ★ let → 拓寬
const b = "hello";                 // "hello"         ★ const → 字面量

const o = { k: "v" };              // { k: string }   ★ 物件屬性「仍然」被拓寬
const o2 = { k: "v" } as const;    // { readonly k: "v" }

const arr = [1, 2];                // number[]        ★ 陣列被拓寬
const t = [1, 2] as const;         // readonly [1, 2] ★ 變成元組（tuple）
```

> ★ **最容易踩的一條：`const` 只讓「變數本身」不可重新賦值，不讓「內部屬性」保持字面量。**
> 所以 `const o = { kind: "circle" }` 的 `o.kind` 型別是 `string`，
> **拿去當判別聯集的判別欄位就失效了**（見 [[工具-判別聯集]]）。

### 5. ★ 三個 `as const` 真正必要的場景

**① 判別聯集的判別欄位**
```ts
const action = { type: "increment", by: 1 };
dispatch(action);        // ★ 錯誤：type 是 string，不符合 Action 聯集

const action = { type: "increment", by: 1 } as const;
dispatch(action);        // ✅
```

**② 從常數表推導型別（★ 最有價值的用法）**
```ts
const ROLES = ["admin", "editor", "viewer"] as const;
type Role = typeof ROLES[number];       // ★ "admin" | "editor" | "viewer"

function can(r: Role) { ... }
can("admin");   // ✅
can("admn");    // ★ 編譯錯誤

// 執行期也能用同一份資料
if (ROLES.includes(input as Role)) { ... }
```
> ★ **「一份資料，同時給執行期用和給型別用」** —— 這是 TS 最實用的型別技巧之一。
> **不用維護 `type Role = ...` 和 `const ROLES = [...]` 兩份會不同步的清單。**

**③ 元組（tuple）**
```ts
function useToggle(): [boolean, () => void] { ... }
// 內部 return [v, fn] as const   ← ★ 否則會被推成 (boolean | (() => void))[]
```

### 6. ★ `as const` vs `satisfies`：該用哪個

| 你要的 | 用 |
|---|---|
| 保留字面量 + 變成 readonly | **`as const`** |
| 檢查形狀符合某個型別 + 保留字面量 | **`satisfies T`** |
| ★ 兩者都要 | **`as const satisfies T`**（順序不能反） |

```ts
const theme = {
  primary: "#0af",
  danger:  "#f33",
} as const satisfies Record<string, `#${string}`>;
// ★ 既檢查了是合法 hex，又保留了 "#0af" 這個字面量，而且是 readonly
```

### 7. `readonly` 的邊界（常見誤解）

```ts
const c = { a: 1 } as const;
c.a = 2;                       // ★ 編譯錯誤

// ★ 但執行期完全沒有保護
const d = c as { a: number };
d.a = 2;                       // ★ 編譯通過，而且真的改掉了
```
> ★ **`readonly` 是純編譯期的**。執行期要真正凍結要用 `Object.freeze()`——
> 而 `Object.freeze` **只凍一層**（巢狀物件仍可改）。
>
> **兩者是互補的，不是替代**：`as const` 給開發期的保護，`Object.freeze` 給執行期的。

### 8. ★ 與 Go 的對照
Go 沒有字面量型別，`const ROLES = []string{...}` **無法產生型別**。
Go 的作法是：
```go
type Role string
const (
    RoleAdmin  Role = "admin"
    RoleEditor Role = "editor"
)
```
★ **但 Go 的這個做法不防止 `Role("typo")`** —— 它只是個字串別名。
**TS 的 `typeof ROLES[number]` 在這一點上是嚴格更強的。**
（跨語言 API 設計時要知道這個落差，見 [[工具-判別聯集]]。）

## 🧪 我實際套用的紀錄
- 2026-08-28：（待填）

## ⚠️ 注意 / 什麼時候不適用

- **★ `as const` 會讓整個結構變 `readonly`（遞迴）**。
  之後要 `push`、`sort`、`splice` 就過不了——**需要可變副本時用 `[...arr]` 展開**。
- **★ 不要對「會變的資料」用 `as const`**。它是給常數、設定、列舉用的，不是給執行期資料用的。
- **`as const` 不是 `as`**。前者是推論指示（安全），後者是型別斷言（危險）。名字像但完全不同。
- **巨大的 `as const` 物件會讓型別提示與錯誤訊息很難讀**，編譯也會變慢。
- **★ 執行期沒有保護**（見上）。安全性相關的不可變要靠 `Object.freeze` 或結構設計。
- **`as const satisfies T` 的順序不能反**（`satisfies T as const` 不合法）。
- **從 API 回來的資料不會有字面量型別**。`JSON.parse` 是 `any`——
  **邊界上要驗證 + narrow**，`as const` 幫不上忙。

## 🔗 相關工具
- [[工具-satisfies與型別標註]] —— ★ 兩者怎麼搭配
- [[工具-判別聯集]] —— 判別欄位為什麼需要字面量
- [[工具-型別推導還是解耦]] —— 推導的邊界
- [[工具-tsconfig基準設定]] —— strict 是前提
- [[值物件]] —— 不可變性的設計思路
- [[Total TypeScript Essentials]]
