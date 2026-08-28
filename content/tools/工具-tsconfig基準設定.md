---
type: tool
name: "tsconfig 基準設定"
source: "[[Total TypeScript Essentials]]"
source_type: book
tags: [software, typescript, tooling, configuration]
triggers: [開新TS專案不知道tsconfig怎麼設, 陣列取值可能是undefined卻沒被擋下來, 用esbuild或babel編譯還要設module嗎, 做函式庫要開哪些選項, 只想引入型別卻讓副作用跑掉了]
---

## 🎯 什麼情境該想到我
當你「**開一個新的 TS 專案，對著空白的 `tsconfig.json` 發呆**」的時候。

## ⚙️ 怎麼用（步驟 / 公式）

### 第一步：先貼這份基準（適用多數應用）
```jsonc
{
  "compilerOptions": {
    /* Base Options */
    "skipLibCheck": true,        // 跳過 .d.ts 的型別檢查，加快編譯
    "target": "es2022",          // 隨時間往上調
    "esModuleInterop": true,     // CJS 與 ESM 的互通性
    "allowJs": true,             // 允許引入 .js
    "resolveJsonModule": true,   // 允許引入 .json
    "moduleDetection": "force",  // 所有 .ts 都當成 module，不是 script
    "isolatedModules": true,     // 每個檔案都能被獨立轉譯

    /* Strictness */
    "strict": true,
    "noUncheckedIndexedAccess": true  // ⭐ 見下方
  }
}
```

### 第二步：問自己四個問題，決定要補什麼
| 問題 | 要加的設定 |
|---|---|
| **用 tsc 轉譯嗎？** | `"module": "NodeNext"`，並設 `outDir`、`sourceMap`、`verbatimModuleSyntax` |
| **不是用 tsc**（esbuild／Babel 等）？ | `"module": "Preserve"` ＋ `"noEmit": true` |
| **要做函式庫嗎？** | `"declaration": true`；monorepo 再加 `"composite": true` 與 `"declarationMap": true` |
| **程式跑在 DOM 嗎？** | 是 → `"lib": ["dom", "dom.iterable", "es2022"]`；否 → `["es2022"]` |

### ⭐ `noUncheckedIndexedAccess` 是最值得單獨提的一項
它讓索引存取回傳 `T | undefined`，逼你處理「取不到」的情況。**`strict: true` 不含這一項**，但沒有它，`arr[999]` 會被當成一定有值——這正是最典型的執行期爆炸。

### 順帶：`import type` 的意義不只是好看
純型別的 import 在編譯後會被移除（elide）。問題是**模組可能有副作用**（例如頂層的 `console.log`）：
```ts
import type { Album } from "./album";      // 整行都會被移除
import { type Album, createAlbum } from "./album";  // 只移除型別部分
```
`verbatimModuleSyntax` 就是要求你把這件事講清楚，避免「引入被悄悄拿掉、副作用沒跑」這種難查的問題。

## 🧪 我實際套用的紀錄
- 2026-08-28：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **`target` 會過期**。書自己就說「等你讀到這本書時，可能該指定更新的版本了」——這份設定要定期回顧。
- **`skipLibCheck: true` 是速度與嚴謹的取捨**：它跳過依賴的 `.d.ts` 檢查，所以第三方型別的錯不會被你發現。多數專案划算，但要知道自己放棄了什麼。
- **`noUncheckedIndexedAccess` 導入既有專案會炸出一堆錯**。新專案直接開；舊專案要排時間。
- **框架的 starter 通常已經設好了**（Next.js、Vite…），不要無腦覆蓋掉——先看它為什麼那樣設。

## 🔗 相關工具
- [[工具-建構的先決條件]] —— 專案開場該先確立的事，設定檔是其中最容易被跳過的一項
- [[工具-防禦式編程]] —— `noUncheckedIndexedAccess` 就是把防禦式思維交給編譯器執行
