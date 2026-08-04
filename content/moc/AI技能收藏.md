---
type: moc
title: "AI 技能收藏"
tags: [moc, ai, skills, agent, tooling]
---

> 收藏值得一試的 **AI skill**（Claude Code / Codex / 其他 agent 平台）。
>
> ⚠️ **這頁與其他 MOC 不同**：其他 MOC 索引的是「我從書裡萃取出來的知識」，這裡收的是**外部現成的工具**。所以每條記的是「它做什麼、裝在哪、我試了沒」，而不是心法。

## 📇 快速索引

| Skill | 平台 | 一句話 | 我的狀態 |
|---|---|---|---|
| [gc-minimal-zine-poster](#gc-minimal-zine-poster) | Codex | 把一個主題／句子／照片變成極簡 zine 風海報 | ⬜ 待試 |

---

## 🎨 圖像與設計

### gc-minimal-zine-poster

**平台：Codex**（不是 Claude Code —— 安裝路徑是 `~/.codex/skills/`）
**可呼叫名稱：** `gc-minimal-zine-poster-v0-1`
**來源：** https://github.com/LiamGvchi/gc-minimal-zine-poster ・ MIT ・ 113 ★（2026-08 查看時）

**做什麼**
把一個主題、句子、物件、心情、文章點子、照片或內容簡報，編譯成「安靜的極簡 zine 風編輯海報」的生成 prompt，並直接產出圖。

**它固定往哪個方向壓**（這是這個 skill 的靈魂——它不是通用生圖，而是把風格鎖死）
- 3:5 的**老化紙張**畫布
- **70–90% 留白**
- **只有一個**小的可成像主體或視覺聚落
- 襯線體、打字機體或等寬字
- **一個清楚可見的高彩度色錨**
- xerox／risograph／halftone／凸版印刷／掃描紙張的瑕疵感
- 日韓獨立誌或極簡編輯設計的安靜氛圍

**它刻意避開**
商業廣告版面、光亮的 mockup、電影感打光、3D 算圖、霓虹、密集拼貼式 scrapbook、長段乾淨的文字塊。

**安裝**
```bash
git clone https://github.com/LiamGvchi/gc-minimal-zine-poster.git \
  ~/.codex/skills/gc-minimal-zine-poster-v0-1
```
裝完若沒出現就重啟 Codex。

**用法**
呼叫 skill 名稱並給一個主題或簡報即可，例如「用 $gc-minimal-zine-poster-v0-1 做一張關於雨天舊書店的海報」。也可以餵句子、文章點子、物件、心情或參考圖。

**輸出三件事**
產出的海報圖 ＋ 最終的生圖 prompt ＋ 選用的變體配方與一小段詮釋註記。

> 預設走 Standard Mode 並直接生圖；只有在你明確要求「只要 prompt」時才會停在 prompt 輸出。

**我的狀態：** ⬜ 待試
**試用筆記：**（待填）

---

## 🔗 相關
- 自己在用的 gstack skills（/browse、/review、/ship 等）不收在這頁，那些是工作流不是收藏
- 打造自己的 AI 工具：[[moc/MCP|MCP]]、[[moc/AI工程|AI工程]]
