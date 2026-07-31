---
type: reference
name: "重複的 switch Repeated Switches"
source: "[[重構]]"
source_type: book
tags: [refactoring, code-smell]
triggers: [同一組 switch/if-else 依型別分支在好幾處出現, 新增一種型別要去很多地方補 case, 到處看到 switch(type), 一連串 if 在判斷同一個型別碼]
---

## 🎯 什麼情境該想到我
當你「同樣一組依型別（或型別碼）分支的 switch / if-else，在程式的好幾個地方重複出現」的時候——每次新增一種型別，都得記得去每一處補上對應的 case。

## ⚙️ 怎麼用（步驟 / 公式）
這味道是什麼徵兆：重複的 switch 讓「新增一種型別」變成散彈式的苦工——漏補一處就出錯。它是一種特別惱人的重複：同一個分類判斷邏輯被複製到多處。

通常用哪些重構手法對治：
- **以多型取代條件式（Replace Conditional with Polymorphism）**：讓每種型別成為一個類別，各自實作對應行為；原本重複的 switch 由多型分派取代。新增型別時，只要加一個類別，不必回去改每個 switch。
- 前置作業常搭配**以子類取代型別碼**、**以多型取代型別碼**。

## 🧪 我實際套用的紀錄
- （待填）

## ⚠️ 注意 / 什麼時候不適用
- 若整個系統只有「一處」switch，且分支邏輯簡單，直接用 switch 反而清楚，未必要引入多型體系。
- 現代語言的 switch 已比以往清爽；味道的重點在「重複」而非 switch 本身。

## 🔗 相關工具
- [[基本型別偏執|基本型別偏執 Primitive Obsession]]（型別碼常是該被物件化的訊號）
- [[重複程式碼|重複程式碼 Duplicated Code]]（重複的 switch 是重複的一種特例）
- [[重構]]
