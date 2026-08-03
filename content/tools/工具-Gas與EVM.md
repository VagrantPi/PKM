---
type: tool
name: "Gas 與 EVM Gas & the Ethereum Virtual Machine"
source: "[[精通以太坊]]"
source_type: book
tags: [blockchain, ethereum, evm, gas]
triggers: [gas費是什麼, 交易為何要付手續費, 鏈上運算怎麼計費, 合約為何要省gas, 交易失敗還扣錢, EVM原理]
---

## 🎯 什麼情境該想到我

當你想搞懂「以太坊上的成本到底從哪來」時——為什麼每個運算都要收費、為什麼寫 storage 特別貴、為什麼交易失敗了錢還是不見、為什麼一個無窮迴圈不會把整條鏈弄死。

本卡完全依據《Mastering Ethereum》(O'Reilly, 2018) Ch.13「The Ethereum Virtual Machine」。

## ⚙️ 怎麼用（理解機制）

### 1. EVM 是什麼樣的機器

先把它定位成「一台只會算數的虛擬機」，不是虛擬化整台電腦：

> "The EVM operates in a much more limited domain: it is just a computation engine, and as such provides an abstraction of just computation and storage, similar to the Java Virtual Machine (JVM) specification, for example."
> （譯文：EVM 運作的領域侷限得多：它就只是一個運算引擎，因此提供的抽象也只有運算與儲存，類似於 Java 虛擬機（JVM）規格那樣。）
> —— Ch.13 "Comparison with Existing Technology"（PDF p.546）

由此推出三個「它沒有的東西」（同小節）：

- **沒有排程能力**——執行順序由外部決定，以太坊客戶端跑過已驗證的區塊交易，決定哪些合約要執行、以什麼順序執行。
- **以太坊世界電腦是單執行緒的，就像 JavaScript。**
- **沒有「系統介面」處理、也沒有「硬體支援」**——根本沒有實體機器可介接，這台世界電腦完全是虛擬的。

再來是它的架構。這句是整章的骨幹：

> "The EVM has a stack-based architecture, storing all in-memory values on a stack. It works with a word size of 256 bits (mainly to facilitate native hashing and elliptic curve operations) and has several addressable data components:"
> （譯文：EVM 採用堆疊式（stack-based）架構，把所有記憶體內的值都存放在一個堆疊上。它的字組大小（word size）是 256 位元（主要是為了方便原生的雜湊與橢圓曲線運算），並且有數個可定址的資料元件：）
> —— Ch.13 "What Is the EVM?"（PDF p.543）

書列的三個可定址元件：

| 元件 | 書中定義（譯文） |
|---|---|
| **program code ROM** | 不可變的程式碼 ROM，載入待執行的智能合約 bytecode |
| **memory** | 揮發性記憶體，每個位置都明確初始化為零 |
| **storage** | 永久儲存，是以太坊狀態的一部分，同樣初始化為零 |

外加「一組在執行期間可取得的環境變數與資料」。

### 2. 三種空間：stack / memory / storage

這是寫合約時最該內化的區分。書的資訊分散在架構說明、opcode 分類與 gas 三處，整理如下：

| | 生命週期 | 存取用的 opcode | 書中怎麼說 |
|---|---|---|---|
| **stack（堆疊）** | 單次執行內 | `PUSHx`（x = 1–32 bytes）、`POP`、`DUPx`（x = 1–16）、`SWAPx`（x = 1–16） | 所有 in-memory 值都放在 stack 上；一個 word 是 256 bits |
| **memory（記憶體）** | 揮發性，每次 EVM 實例化時「設為全零」 | `MLOAD`、`MSTORE`（存一個 word）、`MSTORE8`（存一個 byte）、`MSIZE` | 「使用 EVM memory 是有 gas 成本的」 |
| **storage（儲存）** | 永久，屬於以太坊狀態的一部分 | `SLOAD`、`SSTORE` | 是「只有智能合約會用到的永久資料倉」；「把資料存進合約的鏈上 storage 也有 gas 成本」 |

運算怎麼吃到這些值：

> "As you might expect, all operands are taken from the stack, and the result (where applicable) is often put back on the top of the stack."
> （譯文：如你所料，所有運算元都取自堆疊，而結果（若適用）通常會被放回堆疊頂端。）
> —— Ch.13 "The EVM Instruction Set (Bytecode Operations)"（PDF p.547）

書用 `MSTORE` 走了一遍：它需要兩個引數，跟大多數 EVM 操作一樣從 stack 取得；每取一個引數就 pop 一次（頂端的值被拿走、其餘全部往上移一格）。第一個引數是 memory 位址、第二個是要存的值。

**成本的相對關係**，書只給了這幾句與這幾個數字（"Gas Accounting Considerations"，p.569）：

- 「運算越密集的操作，gas 越貴」——`SHA3`（30 gas）比 `ADD`（3 gas）貴 10 倍。
- 有些操作（例如 `EXP`）還要「依運算元大小額外付費」。
- 使用 memory、以及把資料寫進合約鏈上 storage，都各自有 gas 成本。

反過來，**清掉 storage 是會退錢的**（見下方第 6 節「負的 gas 成本」），從退款金額就看得出書把 storage 佔用當成很貴的資源。

> ⚠️ 書的正文**沒有**列出 `SSTORE`、memory 展開等的具體 gas 數字，只說完整的 opcode 與對應 gas 成本表在 **Appendix C（Table C-1）**。本卡不代書填這些數字。

### 3. 一次執行的生命週期：sandbox 與 world state

先看狀態長什麼樣（"Ethereum State"，p.551）：**world state 是「以太坊地址（160-bit 值）到帳戶」的對映**；每個帳戶包含 ether 餘額（以 wei 計）、nonce、帳戶的 storage（永久資料倉，只有智能合約會用）、以及帳戶的程式碼（同樣只有合約帳戶才有）。**EOA 永遠沒有程式碼，storage 也是空的。**

當一筆交易導致合約程式碼執行，EVM 會被實例化（同小節）：

1. program code ROM 載入被呼叫的合約帳戶程式碼
2. program counter 設為 0
3. storage 從合約帳戶的 storage 載入
4. memory 設為全零
5. 所有區塊與環境變數設好
6. **關鍵變數：gas supply**，設成交易開始時發送者已付費購買的 gas 數量

接著：

> "As code execution progresses, the gas supply is reduced according to the gas cost of the operations executed. If at any point the gas supply is reduced to zero we get an “Out of Gas” (OOG) exception; execution immediately halts and the transaction is abandoned. No changes to the Ethereum state are applied, except for the sender’s nonce being incremented and their ether balance going down to pay the block’s beneficiary for the resources used to execute the code to the halting point."
> （譯文：隨著程式碼執行推進，gas 供給量會依照所執行操作的 gas 成本而減少。如果在任何時點 gas 供給量降到零，我們就會得到一個「Out of Gas」（OOG）例外；執行立即中止，該筆交易被放棄。以太坊狀態不會套用任何變更，唯一的例外是發送者的 nonce 會遞增、且其 ether 餘額會減少，用以支付區塊受益者為了執行程式碼到中止點所耗用的資源。）
> —— Ch.13 "Ethereum State"（PDF p.551–552）

書給的心智模型是**沙盒**：EVM 跑在以太坊 world state 的一份沙盒副本上，只要執行因任何理由無法完成，這份沙盒版本就被整份丟棄；若順利完成，真實狀態才更新成沙盒版本（包含被呼叫合約的 storage 變更、新建立的合約、以及所有已發起的 ether 餘額轉移）。

**執行是遞迴的**：合約可以呼叫其他合約，每次呼叫都會在新目標上再實例化一個 EVM，其沙盒狀態由上一層的沙盒初始化，並被指定一份 gas supply（當然不能超過上一層剩下的量），因此**子層自己也可能因為分到的 gas 太少而以例外中止**；這種情況下沙盒狀態被丟棄，執行回到上一層的 EVM。

### 4. opcode 的完整分類

書先給了一個概觀：EVM 指令集提供「算術與位元邏輯運算、執行脈絡查詢、stack/memory/storage 存取、控制流程操作、記錄（logging）／呼叫與其他運算子」，另外還能取得帳戶資訊（地址、餘額）與區塊資訊（區塊編號、當前 gas price）。

接著是那句分類宣告——"The available opcodes can be divided into the following categories:"（譯文：可用的 opcode 可以分成下列幾類：），完整 **7 類**如下（"The EVM Instruction Set (Bytecode Operations)"，p.547–550）：

| 分類 | 書中說明 | 代表 opcode |
|---|---|---|
| **Arithmetic operations**（算術） | 所有算術都是模 2²⁵⁶ 運算（除非另有說明），且 0⁰ 視為 1 | `ADD` `MUL` `SUB` `DIV` `SDIV` `MOD` `SMOD` `ADDMOD` `MULMOD` `EXP` `SIGNEXTEND` `SHA3` |
| **Stack operations**（堆疊） | stack、memory、storage 的管理指令 | `POP` `MLOAD` `MSTORE` `MSTORE8` `SLOAD` `SSTORE` `MSIZE` `PUSHx` `DUPx` `SWAPx` |
| **Process flow operations**（流程） | 控制流程指令 | `STOP` `JUMP` `JUMPI` `PC` `JUMPDEST` |
| **System operations**（系統） | 給執行該程式的系統用的 opcode | `LOGx` `CREATE` `CALL` `CALLCODE` `RETURN` `DELEGATECALL` `STATICCALL` `REVERT` `INVALID` `SELFDESTRUCT` |
| **Logic operations**（邏輯） | 比較與位元邏輯 | `LT` `GT` `SLT` `SGT` `EQ` `ISZERO` `AND` `OR` `XOR` `NOT` `BYTE` |
| **Environmental operations**（環境） | 處理執行環境資訊 | `GAS` `ADDRESS` `BALANCE` `ORIGIN` `CALLER` `CALLVALUE` `CALLDATALOAD` `CALLDATASIZE` `CALLDATACOPY` `CODESIZE` `CODECOPY` `GASPRICE` `EXTCODESIZE` `EXTCODECOPY` `RETURNDATASIZE` `RETURNDATACOPY` |
| **Block operations**（區塊） | 取得當前區塊的資訊 | `BLOCKHASH` `COINBASE` `TIMESTAMP` `NUMBER` `DIFFICULTY` `GASLIMIT` |

幾個值得記住的語意差異（書中註解原文）：

- `REVERT`：中止執行、**回復狀態變更，但仍回傳資料與剩餘的 gas**。
- `INVALID`：指定的無效指令。
- `SELFDESTRUCT`：中止執行並把帳戶登記為待刪除。
- `DELEGATECALL`：用「別的帳戶的程式碼」對本帳戶做訊息呼叫，但 **sender 與 value 沿用當前值**。
- `GAS`：取得可用的 gas 量（已扣掉本指令的部分）。
- `BLOCKHASH`：只拿得到**最近 256 個**已完成區塊的雜湊。

### 5. Turing completeness and gas：gas 就是停機問題的解

這一節是整章的中心論證。

> "This capability, however, comes with an very important caveat: some programs take forever to run. An important aspect of this is that we can’t tell, just by looking at a program, whether it will take forever or not to execute. … This is called the halting problem and would be a huge problem for Ethereum if it were not addressed."
> （譯文：然而這個能力帶著一個非常重要的但書：有些程式會永遠跑不完。其中很關鍵的一點是，我們無法光看一支程式就判斷它會不會永遠執行下去。……這就是所謂的停機問題，若不加以處理，對以太坊會是個大麻煩。）
> —— Ch.13 "Turing Completeness and Gas"（PDF p.566）

為什麼對以太坊特別致命：前面說過它像一台**沒有排程器的單執行緒機器**，一旦卡進無窮迴圈就整台不能用了。

解法：

> "However, with gas, there is a solution: if after a prespecified maximum amount of computation has been performed, the execution hasn’t ended, the execution of the program is halted by the EVM. This makes the EVM a quasi–Turing-complete machine: it can run any program you feed into it, but only if the program terminates within a particular amount of computation."
> （譯文：然而有了 gas 就有解：如果在執行完預先指定的最大運算量之後程式還沒結束，EVM 就會中止這支程式的執行。這使得 EVM 成為一台**準圖靈完備**（quasi–Turing-complete）的機器：你餵給它的任何程式它都能跑，但前提是這支程式要在某個特定的運算量之內終止。）
> —— Ch.13 "Turing Completeness and Gas"（PDF p.566）

同樣的話在章首出現過一次（"What Is the EVM?"，p.543）：EVM 是準圖靈完備的狀態機，「quasi」是因為所有執行過程都被該次合約執行可用的 gas 量限制在有限步數內；因此停機問題「被解決了」（所有程式執行都會停），而執行可能（不論意外或惡意）永遠跑下去、進而讓整個以太坊平台停擺的情況也被避免了。

書特別註明那個上限**不是固定的**：你可以付錢把它提高，最高到「block gas limit」，而大家也可以隨時間一起同意調高那個上限；但在任一時刻上限都存在，執行時消耗太多 gas 的交易會被中止。

### 6. gas 的角色與計費

**gas 是什麼**（"Gas"，p.567）：

> "Gas is Ethereum’s unit for measuring the computational and storage resources required to perform actions on the Ethereum blockchain. In contrast to Bitcoin, whose transaction fees only take into account the size of a transaction in kilobytes, Ethereum must account for every computational step performed by transactions and smart contract code execution."
> （譯文：gas 是以太坊用來衡量「在以太坊區塊鏈上執行動作所需的運算與儲存資源」的單位。相對於比特幣——它的交易手續費只考慮交易以 KB 計的大小——以太坊必須為交易與智能合約程式碼執行所進行的每一個運算步驟記帳。）
> —— Ch.13 "Gas"（PDF p.567）

書從 Yellow Paper 舉的三個例子：**兩數相加 3 gas**；**算一次 Keccak-256 是 30 gas ＋ 每 256 bits 被雜湊的資料再加 6 gas**；**送出一筆交易 21,000 gas**。

**為什麼需要 gas**——書明講是「雙重角色」（dual role）：

1. 當作**波動的以太幣價格**與**礦工工作報酬**之間的緩衝；
2. 當作**對阻斷服務攻擊（DoS）的防禦**。為了防止意外或惡意的無窮迴圈及其他網路運算浪費，每筆交易的發起者都必須為「自己願意付費的運算量」設一個上限。gas 制度因此讓攻擊者無法免費發垃圾交易——他們必須按所消耗的運算、頻寬與儲存資源等比例付錢。

**執行期間怎麼記帳**（"Gas Accounting During Execution"，p.568）：

- EVM 一開始拿到的 gas supply ＝ 交易中指定的 gas limit。
- 每個被執行的 opcode 都有 gas 成本，EVM 一步步走、供給量一路減少。
- **每個操作之前**，EVM 會先檢查 gas 夠不夠付這個操作；不夠就中止執行、交易回滾。
- 成功跑完（沒耗盡 gas）：用掉的 gas 成本按交易指定的 gas price 換成 ether 付給礦工當手續費。

```
miner fee = gas cost * gas price
remaining gas = gas limit - gas cost
refunded ether = remaining gas * gas price
```

- **out of gas**：操作立即終止，拋出 out of gas 例外，交易回滾、所有狀態變更被撤銷。

> "Although the transaction was unsuccessful, the sender will be charged a transaction fee, as miners have already performed the computational work up to that point and must be compensated for doing so."
> （譯文：雖然這筆交易失敗了，發送者仍會被收取交易手續費，因為礦工已經執行了到那個時點為止的運算工作，必須獲得補償。）
> —— Ch.13 "Gas Accounting During Execution"（PDF p.568）

**gas cost 與 gas price 是兩回事**（"Gas Cost Versus Gas Price"，p.570）——書自己做的 recap：

- **Gas cost**：執行某個特定操作所需的 gas「單位數」。
- **Gas price**：你送交易到以太坊網路時，願意為「每一單位 gas」支付的 ether 金額。

```
transaction fee = total gas used * gas price paid   (in ether)
```

發送者指定自己願付的 gas price，**讓市場去決定以太幣價格與運算成本（以 gas 計）之間的關係**；礦工在組新區塊時可以從待處理交易中挑出價較高的，所以出高一點的 gas price 會誘使礦工把你的交易納入、更快確認。實務上發送者設的 gas limit 會**大於或等於**預期用量，設得比實際消耗高的話多的部分會退還，因為礦工只為實際做的工作獲得補償。

書還附了一個容易搞混的提醒：

> "While gas has a price, it cannot be “owned” nor “spent.” Gas exists only inside the EVM, as a count of how much computational work is being performed."
> （譯文：gas 雖然有價格，但它無法被「擁有」也無法被「花用」。gas 只存在於 EVM 之內，作為「執行了多少運算工作」的計數。）
> —— Ch.13 "Gas Cost Versus Gas Price"（PDF p.570）

發送者被收取的是 **ether** 手續費，這筆錢被換算成 gas 供 EVM 記帳，最後再換回 ether 付給礦工。

**退款機制：負的 gas 成本**（"Negative gas costs"，p.571）。以太坊用「退還部分執行期間用掉的 gas」來鼓勵刪除不再需要的 storage 變數與帳戶，EVM 中有兩個負 gas 成本的操作：

| 操作 | 退款 |
|---|---|
| 刪除一份合約（`SELFDESTRUCT`） | 24,000 gas |
| 把某個 storage 位址從非零值改成零（`SSTORE[x] = 0`） | 15,000 gas |

> "To avoid exploitation of the refund mechanism, the maximum refund for a transaction is set to half the total amount of gas used (rounded down)."
> （譯文：為避免退款機制被濫用，一筆交易的最高退款額被設定為「所使用 gas 總量的一半」（無條件捨去）。）
> —— Ch.13 "Negative gas costs"（PDF p.571）

**block gas limit**（"Block Gas Limit"，p.572）：一個區塊中所有交易可消耗的 gas 上限，限制了一個區塊能塞進多少交易。書的例子：五筆交易 gas limit 分別為 30,000／30,000／40,000／50,000／50,000，若 block gas limit 是 180,000，其中任四筆可進同一個區塊，第五筆要等下一個區塊。礦工若想塞進一筆需要 gas 超過當前 block gas limit 的交易，整個區塊會被網路拒絕；多數以太坊客戶端會先給你「transaction exceeds block gas limit」的警告擋下來。

上限由誰決定：**礦工集體決定**。協定內建投票機制，每個區塊的礦工可以把 block gas limit 往任一方向調整 **1/1,024（0.0976%）**，形成隨網路需求浮動的區塊大小；預設挖礦策略是投給「至少 4.7 million gas，但以近期每區塊平均總用量的 150% 為目標（用 1,024 個區塊的指數移動平均）」。

### 7. 額外：dispatcher 為什麼要檢查 calldata 有沒有 4 bytes

Ch.13 的 "Disassembling the Bytecode"（p.560–565）把 `Faucet.sol` 的 runtime bytecode 拆開看，開頭那段就是 **dispatcher**：讀進交易的 data 欄位，把相關部分送到對應的 function。

它做的第一件事是 `PUSH1 0x4` / `CALLDATASIZE` / `LT` / `JUMPI`——檢查 calldata 是不是**少於 4 bytes**。原因是 function identifier 的機制：

> "Each function is identified by the first 4 bytes of its Keccak-256 hash."
> （譯文：每個函式都由它的 Keccak-256 雜湊值的前 4 個位元組來識別。）
> —— Ch.13 "Disassembling the Bytecode"（PDF p.560）

`keccak256("withdraw(uint256)") = 0x2e1a7d4d…`，所以 `withdraw(uint256)` 的 identifier 就是 `0x2e1a7d4d`。identifier 固定 4 bytes，因此若整個 data 欄位不足 4 bytes，就不可能對應到任何 function——除非有定義 fallback function。`Faucet.sol` 有實作 fallback，所以 calldata 少於 4 bytes 時 EVM 就跳到 fallback；**如果沒實作 fallback，合約會直接丟出例外。**（編碼那一側在 [[工具-以太坊帳戶與交易]]。）

順帶一個部署時的坑（"Contract Deployment Code"，p.557–558）：建立合約的交易 `to` 填特殊的 `0x0` 位址、data 放**初始化程式碼**；新合約帳戶的程式碼**不是** data 欄位裡的東西，而是「那段部署程式碼執行後的輸出」。所以 `solc --bin`（deployment bytecode）與 `solc --bin-runtime`（runtime bytecode）不同，而 **runtime bytecode 完整包含在 deployment bytecode 之內**。

## 🧪 我實際套用的紀錄
- 2026-07-15：（待填）

## ⚠️ 注意 / 什麼時候不適用

- **本卡的 gas 機制是本書（2018）當時的單一 `gasPrice` 市場模型**：發送者自己指定一個 gas price，礦工挑高價的先打包，手續費全額付給礦工（`transaction fee = total gas used * gas price paid`）。**書裡就是這樣寫的，本卡完全不做現代化改寫**（見下方「刻意不寫的東西」）。
- **具體 gas 數字要查 Appendix C。** 本章正文只給了 `ADD` 3 gas、`SHA3` 30 gas（+ 每 256 bits 資料 6 gas）、一筆交易 21,000 gas，以及兩筆退款（24,000 / 15,000）。其餘一律指向 Appendix C 的 Table C-1，本卡不代填。
- **gas 定價本身就出過事**：2016 年有攻擊者找到並利用了「gas 成本與真實資源成本不匹配」的漏洞，製造出運算極貴的交易，讓以太坊主網幾乎停擺；後來以 **Tangerine Whistle** 硬分叉調整了相對 gas 成本才解決（"Gas Accounting Considerations"，p.569）。**「gas 表是對的」不是天經地義的假設。**
- **失敗也照收費**，而且狀態全部回滾——你付的是礦工已經做掉的運算，不是結果。
- **退款有上限**：最多退到該筆交易總用量的一半（無條件捨去），所以不要指望靠大量 `SSTORE[x]=0` 把成本壓到接近零。
- **子呼叫的 gas 是被分配的**：合約呼叫合約時，每一層拿到的 gas 不能超過上一層剩餘量，所以子層可能單獨 OOG 而中止，執行回到上一層——這正是很多安全反模式的溫床，見 [[工具-智能合約安全反模式]]（例如只給 2300 gas 的 `transfer`、未檢查回傳值的 `send`、以及靠迴圈撐爆 block gas limit 的 DoS）。
- **書中的 block gas limit 是「寫作當時」的 8 million gas**（約可容納 380 筆 21,000 gas 的基本交易），這是 2018 年的快照，不是常數。
- **這張卡不談交易欄位怎麼組**：`gasPrice`、`gasLimit` 這兩個欄位在交易結構裡的位置與簽章流程，見 [[工具-以太坊帳戶與交易]]。

### 刻意不寫的東西

本書出版於 2018 年，以下都在本書之後，**本卡一律不寫、也不用它們覆蓋書中說法**：

- **EIP-1559 的 base fee / priority fee（小費）/ base fee 燒毀機制**——書中完全沒有這個概念。書寫的是**單一 `gasPrice`**、手續費**全額付給礦工**、礦工按價格高低排序挑交易。本卡照書寫。
- **The Merge / PoS**——本章結尾說「接下來 Chapter 14 要看以太坊達成去中心化共識的機制」，書中脈絡是**礦工（miners）**、挖礦程式（Ethminer）、`DIFFICULTY` opcode、區塊受益者（block beneficiary）。本卡通篇沿用「礦工」。
- **Layer 2 / rollup / blob（EIP-4844）** 等擴容方案——書談的擴容只有「礦工投票調整 block gas limit（每次 ±1/1,024）」。
- **後來新增或改語意的 opcode**（如 `CHAINID`、`SELFBALANCE`、`BASEFEE`、`PUSH0`、`SHL`/`SHR`/`SAR` 位移指令、transient storage `TLOAD`/`TSTORE`）——上面的 7 類 opcode 表**就是書中列的那些**，一個沒加。
- **`SELFDESTRUCT` 退款已被移除、`SSTORE` 退款上限改成 1/5** 等後續調整——本卡照書寫 24,000 / 15,000 與「一半」的上限。

## 🔗 相關工具
- [[工具-以太坊帳戶與交易]] —— 同書：那張講一筆交易送出了哪些欄位（含 `gasPrice`／`gasLimit`）與簽章；本卡接手講這些欄位進了 EVM 之後怎麼被消耗。
- [[工具-智能合約安全反模式]] —— 同書 Ch.9：gas 的邊界（2300 gas 的 `transfer`、block gas limit、依 `gasPrice` 排序造成的搶跑）正是多個漏洞的成因。
- [[工具-智能合約]] —— 合約是什麼、為什麼不可變。
- [[工具-代幣標準與DApp]] —— 同書 Ch.10：代幣轉帳為什麼一定要有 ether 才付得出 gas。
- [[工具-去中心化儲存與命名]] —— 同書 Ch.12：「gas 太貴、block gas limit 太低，所以大檔案不要上鏈」的另一半答案。
- [[工具-時間複雜度分析]] —— gas 優化本質也是成本分析。
- [[精通以太坊]] —— 來源書卡
