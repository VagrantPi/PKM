---
type: tool
name: "關掉 Claude Code 塞給模型的提醒"
source: "[[Claude Code 隱藏設定分析 v2.1.239]]"
source_type: article
tags: [ai, llm, tooling]
triggers: [覺得agent被一堆內建提醒綁手綁腳, 想關掉某個內建行為但設了沒用, 每輪都跑出不想要的提醒文字, 想讓送出去的system-prompt瘦一點, 設成0卻關不掉]
---

## 🎯 什麼情境該想到我
當你「**受不了 agent 每輪都被內建提醒推著走**，想關掉，卻發現設了 `=0` 沒反應」的時候。

## ⚙️ 怎麼用（步驟 / 公式）
1. **先找有沒有官方設定**。有文件的一律優先，例如 `includeGitInstructions`、`disableWorkflows`、`autoMemoryEnabled`、`fileCheckpointingEnabled`。**別為了關一件小事去用未文件化的環境變數。**
2. **確認這個開關是哪一型**——這決定 `=0` 有沒有用：

   | 型別 | `=0` 的效果 |
   |---|---|
   | `triBool`（`1/true/yes/on` ↔ `0/false/no/off`） | ✅ 真的關得掉 |
   | `bool` 串在 `env \|\| model \|\| remoteGate` | ❌ **關不掉**，只是「單向 force-on」 |
   | `str`/`enum`/`int` | ⚠️ 無效值多半 fallback 回預設，不是關掉 |

3. **這些是實測有效的「真 off 開關」**（v2.1.239）：
   ```bash
   CLAUDE_CODE_THRIFTY_SONIC=0          # 關掉「改用 Bash 讀寫搜尋」的指示
   CLAUDE_CODE_ACT_DONT_REDERIVE=0      # 關掉「別重推已確立的事」那段
   CLAUDE_CODE_SILENT_TURN_REMINDER=0   # 關掉連續沉默工具輪之後的提醒
   CLAUDE_CODE_TOTAL_TOKENS_REMINDER=off  # 移除 <total_tokens> 區塊
   CLAUDE_CODE_TODO_REMINDER_MODE=off   # 關掉十輪沒維護待辦的提醒
   CLAUDE_CODE_THISTLE_GREBE=no_nudges  # 移除鼓勵委派 subagent 的引導
   ```
   微調而非全關：`SILENT_TURN_REMINDER_TURNS`（預設 5）、`TOTAL_TOKENS_REMINDER_BUDGET`（預設 15,000,000）、`JUNIPER_SUNDIAL`（待辦維護間隔，預設 10 輪）。
4. **這些設 `0` 沒用**（單向閘，只能開不能關）：`BISON_CAIRN`、`LARCH_CISTERN`、`AMBER_ASTROLABE`、`GAULT_KESTREL`、`GORSE_PLOVER`、`PARCHMENT_FERN`、`BASALT_COVE`。
5. **想大幅瘦身就用有文件的**：`CLAUDE_CODE_SIMPLE_SYSTEM_PROMPT=1`（實測 113 KB → 73 KB）、`CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS=1`（−6.4 KB）。

## 🧪 我實際套用的紀錄
- 2026-08-23：（待填）

## ⚠️ 注意 / 什麼時候不適用
- **關不掉不是你設錯，是設計如此**。model bundle 自己就會帶那些段落——`claude-opus-5` 的 bundle 本身就含 `# Delivering work` 與 `# Corrections`，環境變數的 `0` 蓋不過它。
- **`TOASTY_THIMBLE` 的語意是反的**：它吃任意文字當自訂提醒，所以 `0`／`false`／甚至 `true` 這種布林字串**全都被當成「沒有自訂文字」**。
- **這幾個只能放 user 或 managed `env`**：`TOASTY_THIMBLE` 與三個 silent-turn 變數會被 binary 明確從 project／local 設定過濾掉。
- **絕對別碰 `GAULT_KESTREL`**：它移除的是一句護欄（目標與描述矛盾、或不是 agent 建立的東西就該停下來），原文自己標「不該隨意開啟」。
- **版本綁死**：以上只對 `2.1.239` 成立，更新後要重新確認 → [[工具-用假API差分測試逆向CLI行為]]。
- 這些名字**沒有官方支援承諾**，別寫進團隊共用設定當成穩定契約 → [[工具-ClaudeCode未文件化設定的取捨]]。

## 🔗 相關工具
- [[工具-ClaudeCode未文件化設定的取捨]] —— 這張講「怎麼關」，那張講「該不該碰、風險怎麼分級」
- [[工具-用假API差分測試逆向CLI行為]] —— 版本一更新，用那張的方法自己重驗一次，不要照抄舊清單
