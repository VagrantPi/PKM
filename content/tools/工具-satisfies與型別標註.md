---
type: tool
name: "satisfies 與型別標註"
source: "[[Total TypeScript Essentials]]"
source_type: book
tags: [software, typescript, type-system]
triggers: [標了型別之後存取欄位反而報錯, 想檢查形狀又想保留推論結果, 不知道該標型別還是用satisfies, 設定物件的值被推成string不是字面量]
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

## 🧪 我實際套用的紀錄
- 2026-08-28：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **`satisfies` 之後不能再加新 key**（TS 已推論成固定的一組 key）。需要後續動態新增就用標註。
- **要的就是「抹平成介面型別」時，標註才是對的**——例如函式參數、要當作抽象契約傳遞的東西。
- **`satisfies` 是 TS 4.9+**。
- **別跟斷言 `as` 搞混**：`satisfies` 是**檢查**（不符就報錯），`as` 是**強制**（叫 TS 閉嘴）。能用 `satisfies` 就不要用 `as`。

## 🔗 相關工具
- [[工具-as-const與推論寬窄]] —— 另一種控制推論寬窄的手段；兩者常一起用
- [[工具-判別聯集]] —— 設定物件裡的字面量被推寬時，判別欄位就會失效
