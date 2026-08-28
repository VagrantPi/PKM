---
type: book-map
title: "Total TypeScript Essentials"
author: Matt Pocock
status: reading
tags: [software, typescript, language, type-system]
started: 2026-08-28
finished:
rating:
---

> 免費線上書，16 章：<https://www.totaltypescript.com/books/total-typescript-essentials>

## 📌 30 秒摘要（Layer 3｜讀完用自己的話寫一句）
> 這本書的一句話：TypeScript 的功力不在於「會不會寫型別」，而在於**知道什麼時候該讓 TS 自己推論、什麼時候該出手約束**——書裡幾乎每一章都在處理這條界線。

## 🧰 這本書給我的工具（連到 tools/ 工具卡）
- [[工具-判別聯集]] — 當我的狀態物件長出一堆「可有可無」的欄位的時候
- [[工具-satisfies與型別標註]] — 當我「標了型別，存取欄位反而壞掉」的時候
- [[工具-as-const與推論寬窄]] — 當我「傳個字串進去卻說不能指派給 union」的時候
- [[工具-型別推導還是解耦]] — 當我猶豫「這個型別要不要從別的型別挖出來」的時候
- [[工具-tsconfig基準設定]] — 當我開新專案、不知道 tsconfig 該怎麼設的時候

## ✨ 關鍵重點（Layer 1–2｜高亮遞進）
- **貫穿全書的主軸是「寬 ↔ 窄」**：`unknown` 是最寬的型別，`never` 是最窄的。多數 TS 的痛點都是「推論出來的型別比我要的寬」或「我約束得比實際需要更寬」。
- **`unknown` 與 `any` 的差別是安全性**：`unknown` 是型別系統的一部分（寬到不能指派給任何東西）；`any` 是**退出型別檢查**，它同時比所有型別更寬也更窄。書的說法很好記——**`unknown` 是「我不知道這是什麼」，`any` 是「我不在乎這是什麼」**。
- **宣告方式決定推論寬窄**：`let` 推成寬型別（因為可以被重新指派），`const` 推成字面量。但**物件屬性即使在 `const` 底下也會推成寬型別**，因為物件本身可變。
- **標註 vs 值，是一場拉鋸**：標註變數 → 變數贏，值的型別被丟掉；不標註 → 值贏，但失去約束；`satisfies` → 兩者兼得。
- **推導（deriving）是一種耦合**。書明確警告：**`Pick` 之所以誘人，是因為它讓你覺得自己很聰明**——但關注點不同的兩個型別，寧可各自寫清楚。
- **章節涵蓋**：設定與 IDE（1–3）、基礎型別（4）、聯集與收窄（5）、物件（6）、可變性（7）、類別（8）、TS 專屬特性（9）、型別推導（10）、標註與斷言（11）、詭異的部分（12）、模組與宣告檔（13）、tsconfig（14）、設計你的型別（15）、工具資料夾（16）。

## 💬 金句原文（Layer 0｜讀時貼進來）
- 關於 `unknown` 與 `any`：
  > "`unknown` means 'I don't know what this is', while `any` means 'I don't care what this is'."
- 關於過度設計型別的心理陷阱（本書最該記的一句）：
  > "What can make decoupling a difficult decision is that deriving can make you feel 'clever'. `Pick` tempts us because it uses a more advanced feature of TypeScript, which makes us feel good for applying the knowledge we've gained. But often, **it's smarter to do the simple thing, and keep your types decoupled**."
- 關於「選配欄位袋」這種壞型別：
  > "I'd describe this type as a **'bag of optionals'**. It's a type that's too loose."
- 標註與值的三條規則：
  > "When you use a variable annotation, the variable's type wins. When you don't use a variable annotation, the value's type wins. When you use `satisfies`, you can tell TypeScript that a value must satisfy certain criteria, but still allow TypeScript to infer the type."

## 🔗 相關
- [[Skills For Real Engineers]] — 同一位作者的 agent skill 集合
- [[moc/軟體工程|軟體工程]] — 主題索引
