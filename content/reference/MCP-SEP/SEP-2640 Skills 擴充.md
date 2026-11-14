---
type: reference
name: "Skills 擴充 SEP-2640 Skills Extension"
source: "[[moc/MCP協議標準|MCP協議標準]]"
source_type: spec
tags: [mcp, ai, agent, skill, protocol, standard, security]
triggers: [想把skill跟MCP server綁在一起發布, server的說明太長塞不進instructions, 遠端server給的skill能不能信, skill://網址到底怎麼組, 使用者核准過的skill內容被偷換]
---

> **SEP-2640**｜Extensions Track｜狀態 **Final**｜建立 2026-04-23｜擴充識別碼 `io.modelcontextprotocol/skills`
> 作者：Peter Alexander、Ola Hungerford、Sambhav Kothari、Aditya Kumar（代表 Skills Over MCP 工作小組）｜Sponsor：@pja-ant｜PR #2640
> 原文：<https://modelcontextprotocol.io/seps/2640-skills-extension>（擷取 2026-11-09）
> ⚠️ **SEP 定案後就凍結成歷史紀錄**，之後的修改不會回寫到 SEP。現行規格在 [ext-skills repo](https://github.com/modelcontextprotocol/ext-skills) 與官方的 [Skills 擴充頁](https://modelcontextprotocol.io/extensions/skills/overview)；官方頁寫「SDK 與 host 支援仍在實作中」；擴充階段是 **Beta**，最終要轉 Stable 還是併進核心規格「尚未決定」（查證 2026-11-09）。Beta 代表可以實際使用，但仍可能改，breaking change 會記錄。

## 🎯 什麼情境該想到我
當你想讓 **MCP server 連同「教 agent 怎麼用這些工具的 skill」一起發布**，或你要做一個會讀取遠端 skill 的 host（client 端）的時候。
一句話定位：**skill 不是新原語，而是「一組用 Resources 提供的檔案」加上兩個列舉／查詢方法**。skill 的格式（目錄結構、frontmatter、命名、漸進揭露）全部交給 Agent Skills 規格，這份 SEP 只定義「怎麼透過 MCP 傳」。

**它要解決的三個問題**（原文 Motivation）：
- **分開發布**：server 跟教 agent 用它的 skill 各自版本、各自安裝，從 registry 裝 server 的人不知道有配套 skill。
- **instructions 裝不下**：server 的 `instructions` 欄位實務上有長度上限，像 875 行的 mcpGraph skill 就放不進去。
- **各做各的**：好幾個實作各自發明了 `skill://` 的網址結構，語義互相衝突。

## ⚙️ 怎麼用（步驟 / 公式）

### 1. 檔案對應成 resource：`skill://<skill-path>/<file-path>`
skill 目錄裡**每個檔案都是一個 MCP resource**，server **SHOULD** 用 `skill://` scheme：

| skill-path | 檔案 | resource URI |
|---|---|---|
| `git-workflow` | `SKILL.md` | `skill://git-workflow/SKILL.md` |
| `pdf-processing` | `scripts/extract.py` | `skill://pdf-processing/scripts/extract.py` |
| `acme/billing/refunds` | `SKILL.md` | `skill://acme/billing/refunds/SKILL.md` |

- `<skill-path>` 的**最後一段 MUST 等於 SKILL.md frontmatter 的 `name`**，前面幾段是 server 自訂的分類前綴（`acme/billing`）。所以**光看 URI 就知道 skill 名稱**，不必讀 frontmatter。
- skill 根目錄是 `skill://<skill-path>`（去掉 `/SKILL.md`，結尾不加斜線）。SKILL.md 裡的相對路徑（`references/GUIDE.md`）以**該 skill 的根目錄**解析，跟檔案系統一樣。
- URI 第一段在 RFC 3986 裡佔的是 authority 位置，但 client **MUST NOT** 拿它去做 DNS 或網路解析。
- 也可以用別的 scheme（例 `github://owner/repo/skills/refunds/SKILL.md`），結構限制一樣。**不能因為 URI 是 `skill://` 就認定它是 skill**；身分只來自 `skills/list` 的條目，或由 `skills/get` 確認。

### 2. 宣告擴充
```json
{ "capabilities": { "extensions": {
    "io.modelcontextprotocol/skills": { "directoryRead": true }
} } }
```
宣告了就**必須**實作 `skills/list` 與 `skills/get`，也**必須**同時宣告 `resources` 能力。`directoryRead` 預設 false；沒宣告為 true 時，client **MUST NOT** 呼叫 `resources/directory/read`。

### 3. `skills/list`：一次拿到完整清單（manifest）
每個條目有三個必填欄位：
- `uri`：該 skill 的 SKILL.md 網址。
- `frontmatter`：**SKILL.md 的 YAML frontmatter 原樣轉成 JSON**，作者寫了什麼就有什麼，不挑選。
- `resources`：**完整的檔案清單**，每個檔案都是 `{uri, digest, size}`。`digest` 格式是 `sha256:<64 個小寫十六進位>`，`size` 是原始位元組數。內容是動態產生的 skill 改寫成字串 `"dynamic"`；沒有 `resources` 的條目無效，host 不得載入。

設計重點：**一個條目本身就是完整的 manifest**。host 翻完清單就能建 registry、讓使用者核准、把核准綁到內容，以及之後驗證每個讀到的檔案，**不用每個 skill 再多打一次**。
- 清單可以是空的或不完整（catalog 太大、按需產生）；host **MUST NOT** 把空清單當成「這個 server 沒有 skill」。
- 支援 cursor 分頁，**一個 skill 的檔案不會被拆到兩頁**。2026-07-28 起的協定版本還會帶 `ttlMs`、`cacheScope`（SEP-2549 的清單快取屬性）。

### 4. `skills/get`：用 URI 查單一 skill
- 參數是 SKILL.md 的 URI，回傳的條目格式跟 `skills/list` 一樣。
- server **MUST** 對自己提供的每個 skill 都能回答，**包括沒出現在清單裡的**；不是它的 skill 就回 `-32602`（Invalid params）。
- 兩個用途：digest 對不上時**只刷新這一個 skill**，不用重列整個 catalog；以及驗證「從 instructions、別的 skill 或使用者那裡拿到的 URI」。

### 5. 讀取 ≠ 啟用
檔案一律用標準的 `resources/read` 讀。但**用 `resources/read` 讀到 SKILL.md 不等於載入這個 skill**：只有 host 自己的載入流程（驗證內容、取得使用者核准）才算啟用。從別的路徑讀到的內容，只能當一般 resource 交給模型。

### 6. `resources/directory/read`（選配）
SKILL.md 常寫「從 `templates/` 挑一個範本」，agent 需要知道目錄裡有什麼。`resources/list` 列的是整個 server、不是某個子目錄，所以另定這個方法：
- 只列**直接子項**，不遞迴；子目錄的 `mimeType` 是 `inode/directory`。
- 對有 manifest 的 skill，它提供不了新資訊。它真正的用途是 `"dynamic"` skill，以及不是 skill 的 resource 樹。
- **兩邊不一致時以 manifest 為準**：目錄列出 manifest 沒有的新檔案時，host **MUST NOT** 讀它，要先用 `skills/get` 刷新條目，而這會讓之前的核准失效、需要重新核准。

### 7. host 端的驗證規則
- 讀到的檔案**MUST** 對照條目的 digest 驗證；`size` 不符等同 digest 不符。驗不過的內容**不得使用**。
- 讀 SKILL.md 後，**逐欄比對**它的 frontmatter 和條目裡的 `frontmatter`，不一致就不載入。這保證使用者在清單上核准的，就是模型實際拿到的。
- 從載入 SKILL.md 起，到它離開 context 為止（host 可以延長，不能縮短），**只能讀條目 `resources` 裡列出的檔案**；讀到沒列出的檔案視同驗證失敗。
- **不得預先抓檔**：連線時、拿到清單時、核准時都不抓；SKILL.md 在載入時抓，附屬檔案在被讀時才抓。抓過的可以快取，用 digest 驗證快取很便宜。
- 每個 skill 的上限：**最多 512 個檔案、總大小 16 MiB**（16,777,216 bytes，算 `size` 總和）。host **MUST** 支援到這個上限；因為清單完整，不用抓任何檔案就能先檢查。拒載時 **SHOULD** 告訴使用者原因。

### 8. 名稱只是標籤，身分是「server ＋ URI」
- 同一個清單裡也可能有兩個都叫 `refunds` 的 skill（`acme/billing/refunds` 和 `acme/support/refunds`）；兩個 server 也可能都提供 `skill://refunds/SKILL.md`，它們是兩個不相干的 skill。
- 因此 host 的 registry、已存的核准、快取、給模型的工具，**都 MUST 以「host 指定的 server 標籤 ＋ URI」為鍵**，不能只用 URI，更不能用名稱。名稱撞了要**加上區別後一起顯示**，不能默默丟掉其中一個。

### 9. host 整合範例（非規範性）
原文建議 host 提供兩個工具：`read_skill(server, uri)` 是唯一的啟用路徑；`read_resource(server, uri)` 讀附屬檔案。也可以把每個 server 的 `skill://` 掛成一個虛擬目錄（**每個 server 一個掛載根目錄**，讓路徑本身帶有 server 身分），讀取時才轉成 `resources/read`。

## 🧪 我實際套用的紀錄
- 2026-11-09：（待填）

## ⚠️ 注意 / 什麼時候不適用

### 1. ⭐ 它比遠端工具呼叫更危險（規格自己說的）
skill 內容是交給模型的指示文字，**本身就是 prompt injection 的入口**；而且它能把 server 寫的內容放到 host 的檔案系統，再指示模型用 host 的工具執行。所以規格要求 host **把 MCP 提供的 skill 當成比遠端工具更高風險的東西**：
- **內容一律視為不可信輸入**；連上了 server 不代表它的 skill 有權威。
- **來源要讓模型看得到**：進 context 時標明是哪個 server 的，不得假裝成本機 skill。
- **不准隱性執行本機程式**：frontmatter 裡的 hooks、腳本，以及 skill 內文要模型去跑的任何指令，都要**每個 skill 經使用者明確核准**。
- **`allowed-tools` 對遠端 skill 預設無效**：本機 skill 用它宣告執行時可用的工具；遠端 server 填這個欄位等於在**要求提權**，除非使用者針對這個 skill 明確核准，否則 MUST 忽略。
- **讀取要綁在來源 server**：A server 的 skill **MUST NOT** 讓 host 去讀 B server 的 resource（跨 server 的 confused deputy）；要跨就逐次問使用者，並寫出兩個 server 的名字。server 身分用 **host 指定的標籤**，不能用 server 自報的 `serverInfo.name`。
- **名稱冒充**：惡意 server 可以用熱門 skill 的名字發布；遠端 skill **不得默默蓋掉**同名的本機 skill 或別的 server 的 skill。

### 2. digest 不是安全邊界
digest 沒有簽章，又跟內容出自同一個 server，**只能證明「清單和內容一致」，不能證明內容可信**；中間的 gateway 可以把兩者一起改掉。核准綁定（下一條）保護的是**核准之後**不被偷換，沒辦法證明核准當下的內容是好的。

### 3. 核准要綁內容，內容一變就作廢
host 若保存「這個 skill 已核准」，**MUST 綁在核准當下的整份 `resources`（每個 uri 和 digest）**。之後任何新條目的檔案集合不同（換檔、新增、刪除），就視為撤銷、重新詢問。`"dynamic"` 的 skill 無法綁定，host 可以拒載。

### 4. 巢狀 skill 要另外核准
skill 目錄裡可以再放 skill。從外層看，內層只是普通的附屬檔案，**host 不得依內層的 frontmatter 行事**；要把內層當成 skill 啟用，需要**重新取得使用者同意**，外層的核准不能延伸過去。

### 5. 快取不會「升級」成本機信任
快取在磁碟上的 skill 內容，要嘛放在只有 host 能寫的地方而且不原地修改，要嘛每次使用時重算 SHA-256 再比對（比對存下來的 digest 字串或修改時間都不算驗證）。快取目錄**必須排除在所有本機 skill 的搜尋路徑之外**；重啟後、server 斷線後，仍要當成「從 MCP 來的」看待。

### 6. 刻意拿掉的功能：壓縮檔打包
早期版本允許用 tar.gz／zip 一次下載整個 skill（還能保留執行權限與 symlink），審查時被 Core Maintainers 拿掉，原因有兩個：
- **解壓縮的攻擊面太大**：decompression bomb、路徑穿越、指到目錄外的連結、大小寫或 Unicode 正規化碰撞把 SKILL.md 蓋掉、setuid／setgid、裝置檔……每個 host 都要全部做對。
- **同一份內容兩種讀法會破壞相容**：只提供壓縮檔的 skill，對只實作逐檔讀取的 host 就讀不到。
代價是多檔的 skill 要一個檔案一次往返，也表達不了執行權限與 symlink；但因為按需讀取，成本只跟實際用到的檔案數成正比。

### 7. 相容性與落地狀態
- 舊 client 只會把 `skill://` 當成一般 resource，不受影響；新方法都要看到宣告才會被呼叫。
- **既有的 `skill://` 實作要改**：原文點名 FastMCP 的 `SkillsProvider` 在網址結構、探索方式、metadata 對應上都不一樣，遷移是工作小組的近期重點。
- 參考實作（原文所列）：Python、C#、Go SDK 的 PR，conformance 測試，以及 gemini-cli、fast-agent、codex 的原型 host，和 GitHub MCP Server 的原型 server；**Claude Code 寫的是「Anthropic 內部做了原型，尚未公開」**。現況以官方 client 支援表為準。

## 🔗 相關工具
- [[工具-MCP三大伺服器原語]] —— 這份擴充完全建立在 Resources 原語上
- [[工具-MCP安全防護要點]] —— MCP 的一般攻擊面；這張是 skill 特有的那幾條（隱性執行、提權、跨 server 讀取、名稱冒充）
- [[工具-把重複的prompt包成skill]] —— skill 本身怎麼寫；這張只管怎麼透過 MCP 傳
- [[工具-skill集合的分層與維護]] —— 本機 skill 多了之後的維護；遠端 skill 加進來後，名稱衝突與來源標示更要注意
