---
type: article
title: "如何評測一個 Claude Code Skill"
source_url: https://andrewou.pages.dev/posts/how-to-evaluate-a-claude-code-skill/
author: Andrew
site: Andrew's Blog
tags: [ai, llm, testing, evaluation, skill]
captured: 2026-08-23
read_status: read
---

## 📌 30 秒摘要（讀完用自己的話寫一句）
> 這篇在講：怎麼**證明**一個 Claude Code skill 真的有用——把同一題跑兩次（帶 skill／不帶 skill），用同一組**自然語言寫的 assertion**丟給另一個 LLM 當評審打 PASS／FAIL，比兩邊的通過率。重點不是分數多高，是**有沒有對照組**、以及**單次結果算不算數**。

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- 我自己在跑 skill 對照實測（[[moc/AI技能評比|AI 技能評比]]），這篇把同一套方法論寫成可照抄的腳本。
- 它替我那兩份報告的「⚠️ 限制」給出了理由：**評審本身會飄**，所以只評一次、沒有雜訊底線的排序不能信。
- 之後自己寫 skill 時，這是驗收的辦法——不然只能憑感覺說「好像變好了」。

## 🧰 這篇給我的工具（連到 tools/ 工具卡）
- [[工具-AI改動的AB對照評測]] — 當我想證明「這版 prompt／skill 真的有加分，不是模型本來就會」的時候

## ✨ 關鍵重點
- **test 與 eval 是兩種東西**。test 是 `assert result == 42`，同輸入同輸出、非黑即白。eval 面對的是「同一個 prompt 每次回答都不一樣、而且沒有唯一正解」，所以只能檢查**回答有沒有具備某些性質**（語氣對不對、有沒有類比、術語清乾淨了沒）。
- **A/B 對照是整套的核心**。每題跑兩個 config：A 帶 skill、B 是模型預設。**兩邊用同一組 assertion 評分**，才拿得到直接可比的數字。腳本也支援 A/B 兩個 skill 版本互比（`--a SKILL.md --b SKILL-v2.md`）。
- **assertion 用自然語言寫「好回答的性質」**，不寫預期輸出——因為評分的是 LLM 不是字串比對。一題約 4 條。
- **LLM-as-judge 要鎖輸出格式**：grader prompt 要求只准輸出 `PASS|<編號>|<證據>` 或 `FAIL|<編號>|<證據>`，不准有其他文字，才好機器統計。
- **評審會飄，所以單次不算數**。作者實測同一組 eval 跑兩次拿到不同分數（10/12 → 11/12）——「warm tone」這種判準，judge 這輪嚴、下輪鬆。結論是**多跑幾次看趨勢**：skill 穩定 80–90%、baseline 穩定 40–50%，那才是真訊號。
- **⚠️ 我自己讀腳本補的一點（文章沒點破）**：with-skill 那組是把「Read the skill at `<path>` first, then follow its instructions」塞進 prompt 前面。所以這套測的是「**SKILL.md 的內容有沒有用**」，**不是「這個 skill 會不會被 description 正確自動觸發」**——後者是實際使用時真正會失敗的地方，這套 eval 沒測到。

## 💬 原文摘錄
- 為什麼不能用 `==`：
  > "You can't check that with ==. You need a judge — and in this case, the judge is another LLM."
- 評審變異（這篇最該記的一句）：
  > "I ran the same eval twice and got different scores — the skill scored 10/12 one time and 11/12 the next. The judge might be stricter on 'warm tone' in one run and more lenient in another."
  > "Because of this, a single eval run isn't enough. Run it multiple times and look at the trend."
- test vs eval 對照（原文表格）：

  | | Tests | Evals |
  |---|---|---|
  | Output | Deterministic | Probabilistic |
  | Assertion | `assert x == 5` | "Uses child-friendly analogies" |
  | Judge | Code (exact match) | LLM (interpretation) |
  | Reruns | Same result every time | May vary between runs |
  | Goal | Correctness | Quality measurement |

## 🔗 相關
- [[moc/AI技能評比|AI 技能評比]] — 我自己跑的 skill 對照實測，這篇正是它用的方法論；我報告裡「只評第一次、沒有雜訊底線」的限制，理由就在這篇
- [[moc/AI技能收藏#eli5|eli5]] — 這套 eval 就是作者為自己的 eli5 skill 寫的，腳本與測資都在那個 repo
- [[工具-AI系統評估]] — 原則層（要有評估集、LLM-as-judge、持續監控），這篇補的是操作層
