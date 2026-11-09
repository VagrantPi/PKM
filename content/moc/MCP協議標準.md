---
type: moc
title: "MCP協議標準"
tags: [moc, mcp, ai, protocol, standard, sep]
---

> 型錄入口：MCP 規格改進提案（**SEP**，Specification Enhancement Proposal）的逐條展開，詳解在 `reference/MCP-SEP/`。
>
> 這裡收的是**規格原文的逐條語義**：哪條是 `MUST`、哪條是 `SHOULD`、規格自己承認了什麼洞、審查時刻意拿掉了什麼。
> 概念與決策層（MCP 架構、三大原語、傳輸、安全）在 [[moc/MCP|MCP]] 的工具卡，兩層互相連結、不重抄。做法比照 [[moc/以太坊協議標準|以太坊協議標準]]。

## 📖 型錄

### 擴充（Extensions Track）
- [[SEP-2640 Skills 擴充|SEP-2640 Skills 擴充 Skills Extension]] — 讓 MCP server 連同 skill 一起提供。skill 的每個檔案都是 `skill://` resource，`skills/list` 一次給完整 manifest（含 SHA-256 digest），`skills/get` 查單一 skill；規格把遠端 skill 視為**比遠端工具更高風險**，列了一整組 host 端的 `MUST`。

## 🧭 怎麼讀一份 SEP

- **先看類型（Track）**：SEP 有四類（查證 2026-11-09）：Standards Track（新的協定功能或互通標準）、Extensions Track（選配擴充，要雙方協商才啟用）、Informational（設計議題或指引，沒有新功能）、Process（MCP 的流程或流程變更）。**這裡只收 Standards 與 Extensions**；治理流程類（如 SEP-932 治理、SEP-2148 貢獻者階梯）不展開。
- **狀態 `Final` ≠ 現行規格**：這是跟 EIP 最大的不同。EIP 定案後本身就是規格；**SEP 定案後凍結成歷史紀錄**，之後的修改只會進規格本文或擴充 repo，不會回寫到 SEP。所以每張卡都要另外對照**現行規格**，並標查證日期。
- **Extensions Track 的 `Final` 只代表進入 Beta**：擴充的生命週期是 Experimental → Beta → Stable（或由 Standards Track SEP 併進核心規格）。第一份 Extensions Track SEP 定案把擴充推到 **Beta**（可實際使用、仍可能改，breaking change 會記錄）；要再一份 SEP，加上兩個能互通的獨立實作（client 與 server 各一）和 conformance 測試，才會變 Stable。各擴充的目前階段看官方的 [Extensions 總覽](https://modelcontextprotocol.io/extensions/overview)。
- **`MUST` / `SHOULD` / `MAY` 要分清楚**：互通性的坑多半長在 `SHOULD` 和 `MAY` 上。
- **讀 Rationale 和「Deferred Features」**：被拿掉的功能和拿掉的理由，常常比留下來的內容更能說明設計取捨。
- **看參考實作**：Extensions Track 要求進審查前至少有一個官方 SDK 的參考實作；規格定案不代表你用的 SDK 或 host 已經支援。

## 🔗 相關
- [[moc/MCP|MCP]] —— 概念與決策層的工具卡
- [[MCP 官方文件]] —— 官方文件全站地圖
- SEP 總表：<https://modelcontextprotocol.io/seps>
