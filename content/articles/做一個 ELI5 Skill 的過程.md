---
type: article
title: "做一個 ELI5 Skill 的過程"
source_url: https://andrewou.pages.dev/posts/building-an-eli5-skill-for-claude/
author: Andrew
site: Andrew's Blog
tags: [ai, llm, skill, methodology, testing]
captured: 2026-08-23
read_status: read
---

## 📌 30 秒摘要（讀完用自己的話寫一句）
> 這篇在講：作者做 [[moc/AI技能收藏#eli5|eli5]] skill 的完整過程——用 Claude Code 內建的 **skill-creator**，從一段起始 prompt 開始，讓它草擬 SKILL.md、提三個測試案例、跑六個平行實例（三個帶 skill、三個 baseline）對照評分。收在一句話：**skill 就是一個 markdown 檔，沒有特殊格式**；發現自己一直在下同一種 prompt，就該把它包起來。

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- 我自己在寫 skill（`/ingest-book`、`/ingest-url`、`/ingest-skill`…），這篇補的是我缺的那一半：**做完之後怎麼驗收**，而不是憑感覺覺得好像有用。
- **起始 prompt 的寫法值得抄**：不要描述你要的輸出，描述**變數有哪些維度** ＋ 給幾句觸發例句，剩下交給 skill-creator 展開。
- 它記錄了一次「自動評分與人工評分結果不同」的實例，這正好解釋了 eli5 repo 裡兩份數字對不起來的原因。

## 🧰 這篇給我的工具（連到 tools/ 工具卡）
- [[工具-把重複的prompt包成skill]] — 當我發現「這段指示我每次都要重講一遍」的時候

## ✨ 關鍵重點
- **skill-creator 是內建的**，它會做三件事：草擬 SKILL.md、寫測試案例、跑對照評測。作者只給了一段起始 prompt。
- **起始 prompt 的結構**：講清楚要解決什麼（依對象調整解釋深度）→ **列出 audience 變數的四個維度**（年齡／學程／職務／關係）→ **給幾句觸發例句**（"ELI5 what a database index is"、"Explain Like I am a manager"）。維度＋例句給足，草稿的品質就決定了。
- **測試案例是它提的、你可以改**：三題各打不同聽眾與不同素材（概念／整包 codebase／操作流程）。跑之前有機會調整。
- **評測跑六個平行實例**：三個帶 skill、三個 baseline，直接對照。
- **自動評分與人工評分會不一致**——這是這篇最值錢的一段實例：auto-grader 抓到「主管那題超過 500 字」（人工漏了），卻放過了「phone book 類比算不算 jargon」（人工判 fail）。最後 auto-grader 給 10/12（83.3%）vs baseline 5/12（41.6%）。
- **四點心得**：① 出貨前先測，有測試案例與 baseline 才擋得住問題；② 自動評分不是決定性的，**要跑多輪看趨勢**；③ 本地要有自己的 eval 腳本才迭代得動，不然每次都要走完整 skill-creator 流程；④ **skill 就是 markdown**，好版控、好分享、好改。

## 💬 原文摘錄
- 這篇的結論句：
  > "Skills are just markdown files. There's no special format or schema — it's a SKILL.md with instructions. This makes them easy to version, share, and iterate on. If you find yourself repeating the same kind of prompt, it's worth packaging into a skill."
- 自動評分的變異：
  > "The LLM-based grader gave different scores than the manual grading session. If you're relying on this for quality checks, run multiple iterations and look at the trend rather than any single result."
- 為什麼要先測：
  > "Test before you ship. ... having test cases and baselines before you commit to an implementation catches problems early."

## 🔗 相關
- [[如何評測一個 Claude Code Skill]] — 同作者的後續篇。這篇是「做」，那篇是「怎麼證明它有用」，把這裡的評測步驟寫成可跑的腳本
- [[moc/AI技能收藏#eli5|eli5]] — 這篇做出來的成品；repo 裡 README 與 `eval-results.md` 兩份數字對不起來的原因就在這篇（**一份是人工評分、一份是 auto-grader**）
