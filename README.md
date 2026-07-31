# PKM — 個人知識庫（LLM Wiki）

一套「**快速讀懂 → 未來憑關鍵字調用工具**」的個人知識庫。把書與文章讀過後，萃取成可被情境檢索的「工具卡」，用 [Quartz](https://quartz.jzhao.xyz/) 發布成公開網站。

🔗 **線上網站**：https://vagrantpi.github.io/PKM/

---

## 這個 repo 是什麼

這是**發布端**（Quartz 靜態網站專案）。筆記本身在本機的 Obsidian vault（`~/WS/kais/Obsidian`）撰寫，經由 `sync.sh` 單向同步進 `content/`，再由 GitHub Actions build 並部署到 GitHub Pages。

```
Obsidian vault(來源) --sync.sh 複製 .md--> content/ --git push--> GitHub Actions build --> Pages
```

> 筆記的**操作規範**見 [`CLAUDE.md`](./CLAUDE.md)（給 AI 維護員的鐵律）。本 repo 的 `CLAUDE.md` 與 `.claude/` 是從來源 vault 複製過來版本控管的副本。

---

## 內容結構（`content/`）

| 資料夾 | 放什麼 | 筆記 type |
|--------|--------|-----------|
| `books/` | 一本書一頁「地圖」（30 秒摘要、工具清單、重點、金句），依主題分子資料夾 | `book-map` |
| `articles/` | 一篇網頁文章一頁筆記 | `article` |
| `tools/` | 從書/文章萃取的**可執行工具卡**——★檢索核心，只放少數即用工具 | `tool` |
| `reference/` | **型錄式工具書**的逐項展開（每個模式/手法一頁），依書分子資料夾 | `reference` |
| `moc/` | 主題索引頁（Map of Content），把跨書的相關工具聚在一個主題下 | `moc` |
| `index.md` | 網站首頁：主題地圖 + 書單 + 工具卡索引（**站台自訂，不被 sync 覆蓋**） | — |

### 三種顆粒度
- **工具卡（`tools/`）**：憑白話情境關鍵字（如「一直拖延」）就能找到、可直接照做的工具。每本書只抓 3–7 個，避免變倉庫。
- **參考型錄（`reference/`）**：GoF《設計模式》、EIP《企業整合模式》、PoEAA《企業應用架構模式》、《重構》這類「每個項目本身就是具名工具」的型錄書，逐項展開放這裡，不塞進主索引。
- **主題地圖（`moc/`）**：廣泛情境（如「想累積財富」「怎麼跟人溝通」）的入口，再導向具體工具卡。

一切用 `[[wikilink]]` 連成網：來源書 ↔ 工具卡 ↔ 型錄 ↔ 主題地圖。

---

## 可用的 Skills（`.claude/commands/`）

在 vault 用 Claude Code 維護知識庫時可呼叫：

| 指令 | 用途 |
|------|------|
| `/ingest-book` | 把一本書做成「一頁地圖 + 3–7 張工具卡」（型錄書則逐項展開放 `reference/`） |
| `/ingest-url` | 把一個網頁文章收進知識庫，做成文章筆記 + 可萃取工具卡 |
| `/ingest-docs` | 爬完一整個官方文件站，做成「一頁文件地圖 + 工具卡」，最後重掃關聯與標籤 |
| `/lint-wiki` | 健檢知識庫：找斷連結、孤兒卡、缺 triggers、trigger 重疊，並提供標準修法 |
| `/canvas-map` | 為某來源畫一張 Obsidian Canvas 心智圖（節點連到實際工具卡），並嵌回該來源；Quartz v5 會在站上 render |

---

## 發布

```bash
./sync.sh          # 同步 vault → content/，commit 並 push（約 1–2 分鐘後網站更新）
./sync.sh --serve  # 只在本機預覽 http://localhost:8099（不推送）
```

`sync.sh` 只複製 `books/`、`articles/`、`tools/`、`moc/`、`reference/` 的 `.md` 與 `.canvas`；PDF、`templates/`、`CLAUDE.md`、`.claude/` 不會上站。

> ⚠️ 別直接編輯 `content/` 底下由 sync 管理的資料夾，下次同步會被整個刪除重建。真正的來源是 Obsidian vault。

---

本專案基於 [Quartz](https://quartz.jzhao.xyz/)（MIT License）發布。
