---
type: tool
name: "satisfies 與型別標註"
source: "[[Total TypeScript Essentials]]"
source_type: book
tags: [software, typescript, type-system]
triggers: [標註型別之後具體資訊就消失了, 想檢查形狀又想保留字面量, satisfies跟as差在哪, 設定物件要怎麼寫才又安全又好用, keyof typeof怎麼用]
---

## 🎯 什麼情境該想到我
當你「**幫變數標了型別，結果存取它的 key 反而壞掉**」的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 三條規則，記這個就夠
| 寫法 | 誰贏 | 後果 |
|---|---|---|
| `const x: T = {...}` | **變數贏** | 值通過檢查，然後**值的型別被丟掉**，只剩 `T` |
| `const x = {...}` | **值贏** | 保留精確推論，但**沒有任何約束** |
| `const x = {...} satisfies T` | **兩者兼得** | 用 `T` 檢查，但**保留值的推論結果** |

### 為什麼標註會壞事
```ts
const config: Record<string, Color> = {
  foreground: { r: 255, g: 255, b: 255 },
  border: "transparent",
};

config.foreground.r;  // ❌ 錯：TS 只知道值是 Color，不知道 foreground 存在
```
標註之後 TS 只記得「這是一個 `Record<string, Color>`」——**它不知道有哪些 key，也不知道每個 key 是 `Color` 的哪一支**。

### 換成 satisfies
```ts
const config = {
  foreground: { r: 255, g: 255, b: 255 },
  border: "transparent",
} satisfies Record<string, Color>;

config.foreground.r;          // ✅
config.border.toUpperCase();  // ✅ TS 知道這支是 string
config.primary = 123;         // ✅ 仍然會被擋下來
```

### `satisfies` 也會收窄
常被誤解成「不影響值的型別」，其實會：
```ts
const album = { format: "Vinyl" } satisfies Album;
// album.format 推論為 "Vinyl"，不是 "CD" | "Vinyl" | "Digital"
```
所以要把它傳給只吃 `"Vinyl"` 的函式時，`satisfies` 可行、標註不行。

### 4. ★ 三種寫法的完整對照

```ts
type Config = Record<string, { url: string; retries: number }>;

// ① 標註（annotation）—— 檢查了，但★ 具體資訊被吃掉
const a: Config = { prod: { url: "...", retries: 3 } };
a.prod;          // ★ 可以，但 a.typo 也「可以」（因為型別是 Record<string, ...>）

// ② as（斷言）—— ★ 不檢查，只是叫編譯器閉嘴
const b = { prod: { url: "...", retries: "3" } } as Config;   // ★ retries 是字串也不報錯！

// ③ satisfies —— ★ 檢查形狀，同時保留具體推論
const c = { prod: { url: "...", retries: 3 } } satisfies Config;
c.prod;          // ✅
c.typo;          // ★ 編譯錯誤：Property 'typo' does not exist
```

| | 檢查形狀 | 保留具體型別 | 錯誤時會報 |
|---|---|---|---|
| **`: Type` 標註** | ✅ | ❌ **被拓寬成標註的型別** | ✅ |
| **`as Type` 斷言** | ❌ | ⚠️ 變成斷言的型別 | ❌ **危險** |
| **★ `satisfies Type`** | ✅ | ✅ | ✅ |

> ★ **`as` 不是型別轉換，是「我保證，別檢查」。**
> 它是 TS 裡最容易製造執行期錯誤的語法——**看到 `as` 就該問「為什麼需要它」。**
> （少數正當用途：`as const`、縮窄 `unknown`、跟型別定義不完整的第三方庫打交道。）

### 5. ★ 最有價值的組合：`satisfies` + `keyof typeof`

```ts
const routes = {
  home:    { path: "/",        auth: false },
  profile: { path: "/me",      auth: true  },
  admin:   { path: "/admin",   auth: true  },
} satisfies Record<string, { path: string; auth: boolean }>;

type RouteName = keyof typeof routes;        // ★ "home" | "profile" | "admin"

function go(name: RouteName) { ... }
go("home");     // ✅
go("hom");      // ★ 編譯錯誤
```

> ★ **這個組合解決了「兩份清單要同步維護」的問題**：
> 型別 `RouteName` **從實作自動推導出來**——加一個路由，型別自動跟著更新。
> **不用維護一個 `type RouteName = "home" | "profile" | "admin"` 的重複定義。**

**Go 沒有這個能力**：Go 得手動維護 `const` 列舉與 map 兩份，**加一筆忘了另一邊也不會報錯。**

### 6. 三個高頻實務場景

**① 設定物件的預設值**
```ts
const defaults = { timeout: 30_000, retries: 3 } satisfies Partial<Options>;
const opts = { ...defaults, ...userOpts };   // ★ 見 [[建造者模式]]
```

**② 策略表**
```ts
const handlers = {
  create: (p: CreatePayload) => { ... },
  update: (p: UpdatePayload) => { ... },
} satisfies Record<string, (p: any) => void>;

type Action = keyof typeof handlers;         // ★ 自動推導
```
→ 見 [[策略模式]]

**③ 顏色／常數表**
```ts
const theme = {
  primary: "#0af",
  danger:  "#f33",
} satisfies Record<string, `#${string}`>;    // ★ 檢查是合法的 hex 形狀

theme.primary;                                // ★ 型別是 "#0af"（字面量），不是 string
```

### 7. ★ 什麼時候該用「標註」而不是 `satisfies`

| 用標註 `: T` | 用 `satisfies T` |
|---|---|
| **函式參數與回傳值**（★ 這是 API 契約，應該明寫） | **常數／設定物件** |
| 希望**隱藏**具體實作細節 | 希望**保留**具體型別供後續推導 |
| 變數之後會被重新賦值成別的值 | 值是固定的 |

★ **判準：這個型別是「契約」還是「檢查」？**
契約（別人依賴它）→ 標註；只是想確認我寫對了 → `satisfies`。
（更完整的討論見 [[工具-型別推導還是解耦]]。）

## 🧪 我實際套用的紀錄
- 2026-08-28：（待填）

## ⚠️ 注意 / 什麼時候不適用

- **★ `satisfies` 需要 TypeScript 4.9+**。舊專案要先升版。
- **★ 不要用 `satisfies` 取代所有標註**。函式簽章應該明寫型別——
  那是 API 契約，**讓它被推導會讓改動意外地變成 breaking change**（見 [[工具-型別推導還是解耦]]）。
- **`satisfies` 不會讓值變成不可變**。要不可變要配 `as const`（見 [[工具-as-const與推論寬窄]]）：
  ```ts
  const x = { a: 1 } as const satisfies Config;   // ★ 兩個一起用
  ```
- **`as` 的正當用途很少**。看到它就該問：**是型別定義不夠好，還是我在騙編譯器？**
  `as unknown as T` 幾乎一定是設計問題。
- **★ 執行期沒有型別**。`satisfies` 只在編譯期檢查；**外部資料（API 回應、JSON）仍然要執行期驗證**
  （zod / valibot），否則型別只是裝飾。
- **推導出來的型別會出現在錯誤訊息與 hover 裡**。巨大的物件字面量會讓型別提示變得難讀——
  這時明確標註反而更好維護。

## 🔗 相關工具
- [[工具-as-const與推論寬窄]] —— 另一半：怎麼控制推論的寬窄
- [[工具-型別推導還是解耦]] —— ★ 什麼時候該推導、什麼時候該明寫
- [[工具-判別聯集]] —— 判別欄位需要字面量型別
- [[工具-tsconfig基準設定]] —— 前置設定
- [[策略模式]] —— `satisfies` + `keyof typeof` 的策略表
- [[建造者模式]] —— TS 用物件字面量取代 Builder
- [[Total TypeScript Essentials]]
