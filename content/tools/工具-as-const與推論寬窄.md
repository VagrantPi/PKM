---
type: tool
name: "as const 與推論寬窄"
source: "[[Total TypeScript Essentials]]"
source_type: book
tags: [software, typescript, type-system]
triggers: [傳字串進函式說不能指派給union, 用const宣告了型別還是被推成string, 物件屬性的字面量型別跑掉了, 想讓設定物件整個唯讀, 明明值就是對的TS卻說不相容]
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

## 🧪 我實際套用的紀錄
- 2026-08-28：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **`as const` 會讓整個結構唯讀**。之後要改它就會報錯——那通常是好事，但如果那個物件本來就要被修改，就不該用。
- **不要對真的需要重新指派的變數硬套 `const`**。要可變就用 `let` 加標註，那才是對的工具。
- **`as const` 不是 `as`**。它是推論指示，不是型別斷言，不會繞過檢查。
- 書裡的觀察值得記：TS 這個設計會**自然推著你多用 `const`**，因為它比較嚴格。

## 🔗 相關工具
- [[工具-satisfies與型別標註]] —— 另一種控制推論的手段；要同時「約束形狀」與「保留字面量」時兩者搭配
- [[工具-判別聯集]] —— 判別欄位被推成 `string` 就整個失效，這張是它的前置修法
- [[工具-型別推導還是解耦]] —— `as const` 物件推導出型別，是「該推導」的典型案例
