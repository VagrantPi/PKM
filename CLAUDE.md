# 知識庫操作規則（給 Claude Code）

這是一個 **LLM Wiki 個人知識庫**。你的角色是「有紀律的 wiki 維護員」。
核心原則：**來源（books/articles）與工具（tools）分開存；未來的使用者是用「情境/關鍵字」找工具，不是用書名找。**

> **語言規則：所有筆記內容一律使用繁體中文書寫。** 即使來源是簡體中文或英文，地圖、工具卡、triggers、摘要都要用繁體中文（可保留必要的英文原文術語/金句於引用處）。

## 資料夾規則

| 資料夾 | 放什麼 | 模板 |
|--------|--------|------|
| `books/` | 一本書一頁「地圖」＋原始檔（PDF 等） | `templates/book-map.md` |
| `articles/` | 一篇網頁文章一頁筆記 | `templates/article.md` |
| `tools/` | 從書/文章萃取的「工具卡」★檢索核心（只放少數即用工具） | `templates/tool.md` |
| `reference/` | 型錄式工具書的**逐項展開**（每個模式/手法一頁），依書分子資料夾 | `type: reference`（沿用 tool.md 結構） |
| `moc/` | 主題索引頁（Map of Content），把跨書的相關工具聚在一個主題下 | — |
| `templates/` | 三種模板，勿改動內容 | — |

## 命名慣例

- 書：`books/書名.md`（中文書名，例：`books/原子習慣.md`）
- 文章：`articles/文章標題.md`
- 工具：`tools/工具-名稱.md`（例：`tools/工具-習慣堆疊.md`）
- 型錄條目：`reference/<書名>/<條目名>.md`——**乾淨命名，不加 `工具-` 前綴**（例：`reference/設計模式/觀察者模式.md`、`reference/企業整合模式/內容路由器.md`）。命名要與同型錄其他條目一致。
- 檔名要有描述性、可被搜尋，禁止 `note3.md` 這種。

## 三種筆記的格式規格

一律照 `templates/` 內對應模板的 frontmatter 欄位與段落結構產出，不要自創欄位。
- **book-map**：`type: book-map`，含 30 秒摘要、工具清單、Layer 1–2 重點、金句。
- **article**：`type: article`，必填 `source_url`。
- **tool**：`type: tool`，必填 `triggers`（見下）。
- **reference**（型錄條目）：`type: reference`，沿用 `templates/tool.md` 的段落結構（🎯情境／⚙️怎麼用／🧪紀錄／⚠️注意／🔗相關），`source:` 指回書卡。**有標準英文名的工程術語，`name:` 一律寫「中文 English」**（例：`name: "觀察者模式 Observer"`）。

## ⭐ triggers 撰寫規則（最重要，決定未來檢索成敗）

每張工具卡的 `triggers:` 是「未來的使用者在什麼情境下會想到這個工具」：
1. **一律用白話情境**，不要用書中術語。（要「一直拖延」不要「執行意圖缺失」）
2. 每卡 **3–5 個** trigger，涵蓋不同說法（拖延 / 遲遲無法開始 / 動不了）。
3. 同時在工具卡的「🎯 什麼情境該想到我」段落用一句白話重述。
4. 沿用既有的受控詞彙（見 `_meta/taxonomy.md`，若存在），避免同義詞散掉。

## 工作流程

- 收到「做一本書」→ 走 `/ingest-book` 流程。
- 收到「收一個網址」→ 走 `/ingest-url` 流程。
- 收到「整個官方文件站／整站文件」→ 走 `/ingest-docs` 流程（爬完同路徑下所有頁面，做成文件地圖＋工具卡，最後重掃關聯與標籤）。
- 定期健檢 → 走 `/lint-wiki` 流程。
（流程細節見 `.claude/commands/`）

## 鐵律

1. **一本書/一篇文章只抓 3–7 個「可執行的工具」**放 `tools/`，貪多變倉庫。
   - **型錄書例外**：GoF《設計模式》、EIP《企業整合模式》、PoEAA《企業應用架構模式》、《重構》這類「每個項目本身就是一個具名工具」的**型錄書**，可**逐項展開**——但要放 `reference/<書名>/`（`type: reference`），**不要塞進 `tools/`**，也**不要列進首頁「工具卡」索引**；`tools/` 只留該書少數「即用心法/快速工具」。書卡與 MOC 可連到完整型錄。目的：主索引維持精簡，型錄另存但仍連結成網。
2. 來源頁與工具卡**必須雙向 `[[連結]]`**：來源頁列出工具、工具卡 `source:` 指回來源。
3. **不杜撰**。內容要基於實際來源；書就讀 PDF/內文、文章就讀原網頁，關鍵定義/公式要核對原文。
4. 產出後**簡短回報**做了哪些檔、抓了哪些工具，讓使用者過目。
5. 修改既有筆記前先讀過現況，變更僅限必要範圍。
6. **相關連結寧缺勿濫**：「相關」區只放真正有實質關係的連結（同概念/互補/對照），**不要為了連而硬跟既有書籍找關聯**；牽強就不連、既有牽強的就拿掉。
7. **不要在筆記中連結原始 PDF/書檔**（PDF 不上站，會變斷連結）。
8. **主題 MOC 是廣泛情境的入口**：ingest 新內容時，若某主題相關工具夠多（約 ≥4 張），在 `moc/` **建立或更新**對應主題索引頁，並從首頁「主題地圖」連入。廣泛情境（如「想累積財富」）應先落在 MOC，再導向具體工具卡。
9. **重複書籍要偵測**：ingest 前先掃 `books/` 是否已有相同/相似的書（含不同語言、版本、檔名的同一本書）。**完全相同 → skip 不重建**；**主題高度重疊的不同書 → 只補獨有工具並交叉連結，不重造重複卡**；不確定則先問使用者。
10. **工程專有名詞補英文**：設計模式、架構模式、重構手法這類**有標準英文名**的術語，`reference` 卡的 `name:` 用「中文 English」；在**書卡與 MOC 列出**它們時，用別名連結顯示英文——`[[觀察者模式|觀察者模式 Observer]]`。別讓列表只有中文（讀者不該被迫已知英文原名才看得懂）。已有刻意 alias 的連結（如 `[[MCP|MCP（…）]]`）不要動。

## 發布到網站（Quartz + GitHub Pages）

這個知識庫可發布成公開網站：**https://vagrantpi.github.io/PKM/**
（GitHub repo：`VagrantPi/PKM`；Quartz 專案在本機 `~/WS/kais/Obsidian-quartz`）

### 架構
```
vault(books/articles/tools/moc/reference) --sync.sh 複製--> Quartz content/
   --git push--> GitHub main --Actions 自動 build--> GitHub Pages
```

### 日常發布：新增或修改筆記後，執行一行指令
```bash
~/WS/kais/Obsidian-quartz/sync.sh          # 同步 + 推送 → 約 1–2 分鐘後網站更新
~/WS/kais/Obsidian-quartz/sync.sh --serve  # 只在本機預覽 http://localhost:8099（不推送）
```
`sync.sh` 會把 `books/`、`articles/`、`tools/`、`moc/`、`reference/` 的 `.md` 複製進 Quartz，commit 並 push；
GitHub Actions 接手 build 與部署。網站首頁在 `~/WS/kais/Obsidian-quartz/content/index.md`（非 vault 內）。

### 注意
- **只發布** `books/`、`articles/`、`tools/`、`moc/`、`reference/` 的 `.md`；PDF、`templates/`、`CLAUDE.md`、`.claude/` 都不會上站。
- GitHub Pages 是**公開**的，發布內容可能被搜尋引擎/網路檔案庫快取。放筆記前留意隱私。
- 未來要轉為私密：Quartz build 產物不變，改部署到 Cloudflare Pages + Access 即可。
