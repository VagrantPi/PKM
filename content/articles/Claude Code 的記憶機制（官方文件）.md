---
type: article
title: "How Claude remembers your project（Claude Code 的記憶機制）"
source_url: https://code.claude.com/docs/en/memory
author: Anthropic（Claude Code 官方文件）
site: code.claude.com
tags: [ai, agent, claude-code, configuration, tooling]
captured: 2026-11-14
read_status: read
---

## 📌 30 秒摘要
> 每個 Claude Code session 都從空的 context 開始，靠兩套機制把知識帶到下一次：
> - **CLAUDE.md**（或 AGENTS.md）：**你寫的**指示與規則，分組織、使用者、專案、本機四層，啟動時載入；`.claude/rules/` 可以用 `paths:` 只在碰到特定檔案時才載入。
> - **auto memory**：**Claude 自己寫的**筆記，記你的糾正、偏好和程式碼推不出的背景，每個 repo 一個資料夾，啟動時只載入索引 `MEMORY.md` 的前 200 行或 25KB。
>
> 兩者都只是 context、不是強制設定；一定要執行的事要用 hook 或 settings。

## 🗺 心智圖（Canvas）
![[Claude Code 的記憶機制（官方文件）.canvas]]

## 🎯 為什麼存這篇 / 未來想拿它做什麼
- 這個 vault 本身就靠 CLAUDE.md、`.claude/rules/`、auto memory 運作，這篇是它們的官方規格。
- 下次 Claude 不照規則做時，先照「沒生效怎麼查」的順序檢查，不要先急著改寫規則。
- 專案要同時給 Codex 等其他 agent 用時，照 AGENTS.md 的那張表決定怎麼放。

## 🧰 這篇給我的工具
- [[工具-ClaudeCode指示該放哪一層]] — 不確定規則該寫進 CLAUDE.md、rules、skill、hook，還是讓它自己記的時候
- [[工具-CLAUDE.md沒生效時怎麼查]] — 明明寫了規則、它卻像沒看到，或想知道它記了什麼的時候

## ✨ 關鍵重點
- **兩套記憶的分工**：CLAUDE.md 由你寫，放規則、流程、架構；auto memory 由 Claude 寫，放偏好、糾正、程式碼推不出的背景。
- **CLAUDE.md 以 user message 的形式送在 system prompt 之後**，不是 system prompt 本身，所以沒有嚴格遵守的保證。
- **載入規則**：工作目錄往上的 CLAUDE.md 啟動時載入並串接（根目錄在前）；子目錄的等 Claude 碰到該目錄的檔案才載入；HTML 區塊註解注入前會被拿掉。
- **`@path` import**：相對路徑以 import 所在檔案為基準、最多 4 層；路徑有空格要用反斜線跳脫；寫在反引號裡就不會被 import。
- **auto memory 的四種類型**：user、feedback、project、reference；寫入時會在 frontmatter 自動記 `modified` 時間戳。
- **新工具**：`/doctor prompt-audit`（v2.1.283 起）找出過時或矛盾的指示；`CLAUDE_CODE_NEW_INIT=1` 讓 `/init` 變成多階段互動流程，可一起建 CLAUDE.md、skill、hook。
- **版本**：文中多處行為綁版本（AGENTS.md 支援 v2.1.277 起等），查證日 2026-11-14。

## 💬 原文摘錄
- "Claude treats them as context, not enforced configuration. To block an action regardless of what Claude decides, use a PreToolUse hook instead."
- "Treat CLAUDE.md as the place you write down what you'd otherwise re-explain."
- "Imports help you organize a long file but don't reduce its context cost, because imported files load together with the CLAUDE.md that imports them."

## 🔗 相關
- [[moc/Claude Code 深度使用|Claude Code 深度使用]] —— Claude Code 相關的其他筆記
- [[Claude Code 隱藏設定分析 v2.1.239]] —— 官方文件沒寫的設定；這篇是官方寫了的部分
