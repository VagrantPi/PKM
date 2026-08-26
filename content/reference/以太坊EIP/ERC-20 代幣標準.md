---
type: reference
name: "代幣標準 ERC-20 Token Standard"
source: "[[moc/以太坊協議標準|以太坊協議標準]]"
source_type: spec
tags: [blockchain, ethereum, token, erc, standard]
triggers: [要實作或串接ERC-20介面, 不確定transfer失敗是回false還是revert, approve改額度為什麼要先歸零, decimals可不可以不實作, 轉0個代幣要不要發事件]
---

> **EIP-20**｜Standards Track: ERC｜狀態 **Final**｜建立 2015-11-19
> 作者：Fabian Vogelsteller、Vitalik Buterin｜授權 CC0
> 規格原文：<https://eips.ethereum.org/EIPS/eip-20>

## 🎯 什麼情境該想到我
當你「**要實作或串接一個 ERC-20 代幣，需要知道每個函式的確切語義**」的時候——不是「要不要發幣」（那是 [[工具-代幣標準與DApp]]），是「介面到底保證了什麼、沒保證什麼」。

## ⚙️ 怎麼用（步驟 / 公式）

### 六個必要函式
| 函式 | 簽章 | 語義 |
|---|---|---|
| `totalSupply` | `() → uint256` | 代幣總發行量 |
| `balanceOf` | `(address _owner) → uint256` | 查某地址餘額 |
| `transfer` | `(address _to, uint256 _value) → bool` | 自己轉出。**MUST** 發 `Transfer` 事件；餘額不足 **SHOULD** throw |
| `transferFrom` | `(address _from, address _to, uint256 _value) → bool` | 代轉（提款流程）。**MUST** 發 `Transfer`；除非 `_from` 已授權呼叫者，否則 **SHOULD** throw |
| `approve` | `(address _spender, uint256 _value) → bool` | 授權 `_spender` 可從你帳戶多次提領，累計上限 `_value`。**再次呼叫會直接覆寫舊額度** |
| `allowance` | `(address _owner, address _spender) → uint256` | 查剩餘可提領額度 |

### 三個選配函式（`name` / `symbol` / `decimals`）
規格明寫 **OPTIONAL**，而且「介面與其他合約 **MUST NOT** 預期這些值存在」。
`decimals` 只是顯示用的除數——回傳 8 代表把數量除以 100000000 才是使用者看到的數字。**鏈上金額一律是整數，沒有小數。**

### 兩個事件
```solidity
event Transfer(address indexed _from, address indexed _to, uint256 _value)
event Approval(address indexed _owner, address indexed _spender, uint256 _value)
```
- `Transfer` **MUST** 在代幣轉移時觸發，**包含零值轉帳**。
- **鑄造新幣時 SHOULD 發出 `_from` 為 `0x0` 的 `Transfer`**（這就是為什麼掃鏈時 `0x0` 是鑄幣、不是真的有人從零地址轉出）。
- `Approval` **MUST** 在任何成功的 `approve` 呼叫後觸發。

### 實作參考
規格點名 OpenZeppelin 與 ConsenSys 的實作，並說明不同團隊在 **省 gas ↔ 提升安全性** 之間取捨不同。

## 🧪 我實際套用的紀錄
- 2026-08-26：（待填）

## ⚠️ 注意 / 什麼時候不適用

### 1. 回傳 `false` 一定要處理——這是規格的第一條 NOTES
> "Callers **MUST** handle false from `returns (bool success)`. Callers **MUST NOT** assume that false is never returned!"

**我的補註**：這條之所以存在，是因為餘額不足時規格寫的是 **SHOULD** throw 而不是 MUST。所以合規的實作**可以選擇回 `false` 而不 revert**。呼叫端如果只寫 `token.transfer(...)` 不檢查回傳值，遇到這種代幣會**靜默失敗**——交易成功、幣沒動。

### 2. `approve` 有規格自己承認的競態
規格明白指出這是已知攻擊向量，處理方式是：
- **client SHOULD** 在改額度前，先把 allowance 設為 `0`，再設成新值。
- **但合約本身不該強制這件事**——為了與更早部署的合約向後相容。

**我的補註**：這是「規格已知有洞、但選擇把責任推給 UI 層」的經典案例。所以**責任在你的前端／整合程式**，不能指望代幣合約幫你擋。

### 3. 零值轉帳是正常轉帳
`transfer` 與 `transferFrom` 的零值呼叫 **MUST** 當成正常轉帳處理並發出事件。**不要把 `_value == 0` 當成無效輸入擋掉**，那是不合規的。

### 4. 不能假設 metadata 存在
串接任意代幣時，`name`／`symbol`／`decimals` 可能根本沒實作。硬呼叫會 revert，UI 要有 fallback。

### 5. 這份規格沒有規定的事
沒有轉帳通知的 hook／callback——**代幣被直接 `transfer` 進一個不懂代幣的合約，就永久卡在那裡**，規格沒有任何機制阻止或回退。

## 🔗 相關工具
- [[工具-代幣標準與DApp]] —— 概念與決策層（該不該發幣、ERC-20 vs 721、DApp 架構），出自《精通以太坊》2018。**這張卡是它的規格層**：那張回答「要不要／是什麼」，這張回答「介面到底保證什麼」
- [[工具-智能合約安全反模式]] —— `approve` 競態屬於前跑類攻擊；上線前照那張的清單掃一遍
- [[工具-智能合約]] —— 合約的生命週期與部署模型
