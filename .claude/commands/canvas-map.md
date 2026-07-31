---
description: 為某個來源（書/文件）畫一張 Obsidian Canvas 心智圖，節點連到實際工具卡，並嵌入該來源筆記
---

為指定的來源 `$ARGUMENTS`（書卡、文章或文件地圖）產生一張 **Obsidian Canvas 心智圖**，並把它嵌回該來源。

## 產出與擺放的判斷（預設做法）
Canvas 是獨立的 `.canvas` 檔，無法把 JSON 內嵌進 `.md`。因此：
- **生成 `.canvas` 檔**放在**來源同資料夾**、同名：例如 `books/軟體工程/clean-code/重構.canvas`。
- **在來源筆記嵌入**：在來源的 30 秒摘要之後插入一段
  ```
  ## 🗺 心智圖（Canvas）
  ![[<來源檔名>.canvas]]
  ```
  （`![[...]]` 是嵌入，會直接在筆記裡顯示可縮放的心智圖；同時它本身就是一頁獨立 Canvas。）
- 這樣「索引到新頁」與「插入來源」兩者兼得，不必二選一。

> 發布：`sync.sh` 已一併複製 `.canvas`，且 **Quartz v5 原生支援 Canvas**——`![[X.canvas]]` 會在網站上 render（另會產生一頁獨立 `X.canvas.html`）。所以心智圖在 Obsidian 與網站都看得到。

## 步驟
1. **定位來源**：找到來源筆記（`books/…/X.md`、`articles/X.md` 或文件地圖）。讀它，並讀它連到的工具卡／`reference` 條目，掌握「中心 → 分類/主題 → 具體工具」的層次。
2. **設計層次（3 層為主）**：
   - **中心節點**＝來源標題（`text` 節點）。
   - **分類/主題節點**＝書卡裡的分區（如溝通的「傾聽/表達/衝突」，或型錄的家族）（`text` 節點）。
   - **葉節點**＝實際的工具卡／reference 條目，用 **`file` 型節點**指向該檔（可點擊導航）；沒有對應卡的關鍵概念才用 `text` 節點。
3. **控制規模（重要，別畫成一團亂）**：
   - 一般書（3–7 工具）：全畫出來。
   - **大型型錄**（reference 條目 20+）：**只畫到「家族/分類」層**，每個家族一個 `text` 節點，連到型錄書卡即可，不要把 65 個條目全塞進一張圖。
4. **產生 `.canvas` JSON**（格式與座標見下），寫成檔案。
5. **嵌入來源**：在來源筆記插入 `## 🗺 心智圖（Canvas）` + `![[來源檔名.canvas]]`（若已存在則更新，不重複插入）。
6. **回報**：建立/更新了哪個 `.canvas`、幾個節點、嵌到哪個來源。

## Canvas JSON 格式（Obsidian 1.0）
一個 `.canvas` 檔就是一份 JSON：
```json
{
  "nodes": [
    {"id":"c","type":"text","text":"# 溝通的藝術","x":-140,"y":-40,"width":280,"height":80,"color":"6"},
    {"id":"t1","type":"text","text":"👂 傾聽","x":320,"y":-260,"width":200,"height":60,"color":"5"},
    {"id":"l1","type":"file","file":"tools/工具-反應式傾聽.md","x":620,"y":-300,"width":320,"height":110}
  ],
  "edges": [
    {"id":"e1","fromNode":"c","toNode":"t1","fromSide":"right","toSide":"left"},
    {"id":"e2","fromNode":"t1","toNode":"l1","fromSide":"right","toSide":"left"}
  ]
}
```
- **node 共同欄位**：`id`（唯一字串）、`type`、`x`、`y`（左上角座標，可負）、`width`、`height`、`color`（選填）。
- **type**：`text`（`text` 欄放 Markdown）、`file`（`file` 欄放 vault 相對路徑，會嵌入該檔）、`link`（`url`）、`group`（框住一群）。
- **color**：預設 `"1"`紅 `"2"`橙 `"3"`黃 `"4"`綠 `"5"`青 `"6"`紫，或 `"#rrggbb"`。建議：中心紫`6`、分類青`5`、葉節點不設色。
- **edge**：`id`、`fromNode`、`toNode`、`fromSide`/`toSide`（`top|right|bottom|left`）；可選 `label`、`color`。
- **`file` 路徑用 vault 相對路徑**（如 `tools/工具-X.md`、`reference/設計模式/觀察者模式.md`），務必指向存在的檔，否則節點空白。

## 座標佈局規則（左→右樹狀，避免重疊）
用簡單公式算座標（可寫個小 script 算，別手 key 到重疊）：
- 中心：`x=-140, y=-40, w=280, h=80`。
- 分類節點在 `x=320`，共 C 個垂直排開：第 i 個 `y = (i-(C-1)/2)*GAP_CAT`，`GAP_CAT≈ max(200, 該類葉子數*140)`，`w=200,h=60`。
- 葉節點在 `x=620`，屬第 i 類的第 j 個（共 K 個）：`y = cat_y + (j-(K-1)/2)*140`，`w=320,h=110`。
- 邊：中心→分類、分類→葉，一律 `fromSide:"right"`→`toSide:"left"`。
- 節點多時把 `x` 間距與 `GAP` 放大，寧可散開也不要疊。

## 原則
- 忠實於來源的既有結構（沿用書卡的分區與工具清單），不自創內容。
- 葉節點盡量用 `file` 連到真卡，讓 Canvas 成為可導航的視覺索引。
- JSON 必須合法（`python -m json.tool` 檢查），`file` 路徑必須存在。
