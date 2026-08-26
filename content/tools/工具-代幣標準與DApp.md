---
type: tool
name: "代幣標準與 DApp Token Standards & DApps"
source: "[[精通以太坊]]"
source_type: book
tags: [blockchain, ethereum, token, dapp]
triggers: [想發代幣, ERC-20是什麼, NFT怎麼運作, 做去中心化應用, DApp架構, 為何要用標準介面]
---

## 🎯 什麼情境該想到我

當你要「發一個代幣、做 NFT，或是先決定這個專案到底該不該發幣」時。

本卡完全依據《Mastering Ethereum》(O'Reilly, 2018) Ch.10「Tokens」。

## ⚙️ 怎麼用

### 0. 先搞清楚「token」在講什麼

書從字源講起：「token」來自古英語 "tācen"，意思是**記號或象徵**，過去多半指私人發行、內在價值微不足道的類硬幣物件（公車代幣、洗衣代幣、電玩代幣）。而現在：

> "Nowadays, “tokens” administered on blockchains are redefining the word to mean blockchain-based abstractions that can be owned and that represent assets, currency, or access rights."
> （譯文：如今，在區塊鏈上管理的「代幣」正在重新定義這個詞，使它意指「可被擁有、且代表資產、貨幣或存取權的區塊鏈式抽象物」。）
> —— Ch.10 章首（PDF p.424）

書順帶點破那個「代幣＝沒什麼價值」的既定印象從哪來：實體代幣通常被限制在特定商家、組織或地點，不易交換、通常只有單一功能。區塊鏈代幣把這些限制拿掉了——或者更準確地說，**變成可重新定義的**。（這個伏筆在後面的 utility token 段落會被回收。）

### 1. 一枚代幣可以代表什麼：10 種用途

"How Tokens Are Used"（p.425–426）明說**貨幣只是第一個「app」**，而且一枚代幣常常同時身兼數種功能：

| 用途 | 書中舉例（譯文） |
|---|---|
| **Currency**（貨幣） | 價值由私下交易決定的一種貨幣形式 |
| **Resource**（資源） | 分享經濟／資源共享環境中賺得或產出的資源，例如代表可在網路上共享的儲存或 CPU 的代幣 |
| **Asset**（資產） | 內生或外生、有形或無形資產的所有權；黃金、不動產、汽車、石油、能源、MMOG 道具等 |
| **Access**（存取權） | 對數位或實體財產的存取權，例如討論區、專屬網站、飯店房間、租車 |
| **Equity**（股權） | 數位組織（如 DAO）或法律實體（如公司）的股東權益 |
| **Voting**（投票權） | 數位或法律系統中的投票權 |
| **Collectible**（收藏品） | 數位收藏品（如 CryptoPunks）或實體收藏品（如一幅畫） |
| **Identity**（身分） | 數位身分（如 avatar）或法律身分（如國民身分證） |
| **Attestation**（證明） | 由某個權威或去中心化聲譽系統做出的認證或事實證明，如結婚記錄、出生證明、大學學位 |
| **Utility**（效用） | 用來存取或支付某項服務 |

書給的洞見是：實體世界裡這些功能常被綁死（駕照同時是「證明」也是「身分」，兩者分不開），**而在數位領域，這些原本混在一起的功能可以被拆開、各自獨立發展**（例如匿名的證明）。

### 2. 同質化（fungibility）：ERC20 與 ERC721 的分水嶺

> "Tokens are fungible when we can substitute any single unit of the token for another without any difference in its value or function."
> （譯文：當我們能用代幣的任一單位替換另一單位，而其價值或功能毫無差異時，這種代幣就是同質化的。）
> —— Ch.10 "Tokens and Fungibility"（PDF p.427）

兩個容易被忽略的補充：

- **嚴格說來，只要代幣的歷史來源（provenance）可被追蹤，它就不是完全同質化的**——追蹤來源的能力會導致黑名單與白名單，進而削弱或消滅同質性。
- **非同質化代幣**各自代表一個獨特的有形或無形物件，因此不可互換（代表某幅梵谷的代幣不等同於代表畢卡索的代幣，即使兩者屬於同一套「藝術品所有權代幣」系統；某隻特定 CryptoKitty 也不能跟另一隻互換）。**每個非同質化代幣都關聯到一個唯一識別碼，例如序號。**

書另外用一個 NOTE 澄清：日常語境裡「fungible」常被拿來指「可直接兌換成錢」（賭場籌碼能兌現、洗衣代幣通常不能），**這不是本書使用這個詞的意思**。

### 3. 交易對手風險與 intrinsicality：代幣背後有沒有人握著東西

**Counterparty risk**（p.428）是「交易的另一方未能履行義務的風險」。書的關鍵推論：當一項資產是透過「所有權代幣」間接交易時，**保管人（custodian）會額外帶來交易對手風險**——他們真的持有那項資產嗎？他們會不會承認（或允許）「代幣移轉＝所有權移轉」？

接著是 intrinsicality（p.429）。「intrinsic」源自拉丁文 "intra"，意為「從內部而來」：

- **內生（intrinsic）資產**受共識規則管轄，跟代幣本身一樣。**代表內生資產的代幣不帶額外的交易對手風險**——你持有某隻 CryptoKitty 的金鑰，就沒有別人替你保管牠，你直接擁有它；持有私鑰＝擁有資產，沒有中介。
- **外生（extrinsic）資產**（不動產、公司投票股份、商標、金條）的所有權由法律、習俗與政策管轄，與管轄代幣的共識規則分開，因此**必然帶有額外的交易對手風險**（保管人、外部登記、鏈外法規）。

> "One of the most important ramifications of blockchain-based tokens is the ability to convert extrinsic assets into intrinsic assets and thereby remove counterparty risk."
> （譯文：以區塊鏈為基礎的代幣，最重要的後果之一，就是能把外生資產轉換成內生資產，藉此消除交易對手風險。）
> —— Ch.10 "Tokens and Intrinsicality"（PDF p.429）

書舉的例子：從「公司股權（外生）」搬到「DAO 或類似組織中的股權／投票代幣（內生）」。

### 4. utility token vs equity token：這個專案該不該發幣

書把當時所有專案的發幣動機收斂成兩類，並直說**這兩種角色常常被混為一談**（"Using Tokens: Utility or Equity"，p.430）：

| | 定義（譯文） |
|---|---|
| **Utility token** | 使用該代幣是取得某項服務、應用或資源的必要條件。例如代表共享儲存等資源的代幣，或存取社群網路等服務的代幣 |
| **Equity token** | 代表對某物（例如一家新創）的控制權或所有權的份額。可以窄到只是分配股利與利潤的無投票權股份，也可以寬到是 DAO 中的投票股份，由代幣持有者透過複雜治理系統管理平台 |

然後書開了一個以本章最直白的標題寫成的小節——**"It's a Duck!"**（p.431）：代幣是很棒的募資機制，但**向公眾發行證券（股權）在多數司法管轄區是受監管的行為**。許多新創把 equity token 偽裝成 utility token，希望繞過監管、把公開募資包裝成「服務存取憑證」的預售。書的判斷是：

> "As the popular saying goes: “If it walks like a duck and quacks like a duck, it’s a duck.” Regulators are not likely to be distracted by these semantic contortions; quite the opposite, they are more likely to see such legal sophistry as an attempt to deceive the public."
> （譯文：如同那句俗諺：「如果牠走起來像鴨子、叫起來也像鴨子，那牠就是鴨子。」監管機關不太可能被這些語意上的扭曲所迷惑；恰恰相反，他們更可能把這種法律詭辯視為欺騙公眾的意圖。）
> —— Ch.10 "It's a Duck!"（PDF p.431）

接著是 "Utility Tokens: Who Needs Them?"（p.432–434），論證非常值得抄進產品決策清單：

1. **每一項創新都是一道市場濾網。** 你的新創本來就已經在走人跡罕至的路；再加一個 utility token、要求使用者為了用你的服務先去採用代幣，等於把濾網疊上第二層——你要求早期採用者同時採用**兩種**全新技術：你的產品，以及代幣經濟。
2. **風險是疊加的。** 加上 utility token，你就一併繼承了底層平台（以太坊）、更廣泛的經濟（交易所、流動性）、監管環境（股權／商品監管機關）與技術（智能合約、代幣標準）的所有風險。
3. **你可能親手重建了「代幣＝不值錢」的條件。** 呼應章首的伏筆：實體代幣之所以價值微不足道，是因為只能用在很窄的脈絡（一家公車公司、一間洗衣店）；如果你的代幣只能在你自己這個小市場的單一平台上使用，你就複製了同樣的條件。**若使用者必須「把東西換成你的代幣→用掉→再把剩下的換回比較通用的東西」，你創造的其實是公司代用券（company scrip）。**
4. 但書也公平地給出反面：採用代幣同時繼承了整個代幣經濟的市場熱情、早期採用者、技術、創新與流動性——「問題在於好處與熱情是否勝過風險與不確定性」。

書的結論句：

> "Adopt a token because your application cannot work without a token. Adopt it because the token lifts a fundamental market barrier or solves an access problem. Don’t introduce a utility token because it is the only way you can raise money fast and you need to pretend it’s not a public securities offering."
> （譯文：採用代幣，是因為你的應用少了代幣就無法運作；採用它，是因為代幣消除了某個根本性的市場障礙、或解決了某個存取問題。不要因為那是你唯一能快速募資的方式、而且你需要假裝那不是公開的證券發行，才去引進一個 utility token。）
> —— Ch.10 "Utility Tokens: Who Needs Them?"（PDF p.433–434）

### 5. 代幣活在合約層，協定根本不知道它存在

這是理解後面所有 ERC20 怪癖的**唯一前提**：

> "Tokens are different from ether because the Ethereum protocol does not know anything about them. Sending ether is an intrinsic action of the Ethereum platform, but sending or even owning tokens is not. The ether balance of Ethereum accounts is handled at the protocol level, whereas the token balance of Ethereum accounts is handled at the smart contract level."
> （譯文：代幣不同於 ether，因為以太坊協定對它們一無所知。發送 ether 是以太坊平台的內建行為，但發送、甚至擁有代幣則不是。以太坊帳戶的 ether 餘額在協定層被處理，而代幣餘額則是在智能合約層被處理。）
> —— Ch.10 "Tokens on Ethereum"（PDF p.435）

所以**在以太坊上建立新代幣＝部署一份新的智能合約**；部署後由該合約處理一切，包含所有權、移轉與存取權。你可以隨心所欲地寫，但書說「照既有標準走大概是最明智的」。

### 6. ERC20：實際的介面定義

**來歷**（"The ERC20 Token Standard"，p.436）：2015 年 11 月由 **Fabian Vogelsteller** 以 Ethereum Request for Comments 形式提出，被自動指派為 GitHub issue 編號 **20**，因而得名「ERC20 token」；後來成為 **EIP-20**，但大家仍多以原名稱呼。**ERC20 是同質化代幣的標準**，意思是同一種 ERC20 代幣的不同單位可互換、且沒有獨特屬性。

> "The ERC20 standard defines a common interface for contracts implementing a token, such that any compatible token can be accessed and used in the same way."
> （譯文：ERC20 標準為實作代幣的合約定義了一套共通介面，使得任何相容的代幣都能以相同方式被存取與使用。）
> —— Ch.10 "The ERC20 Token Standard"（PDF p.436）

**必要 function 與 event**（"ERC20 required functions and events"，p.436–437）——「一份符合 ERC20 的代幣合約至少必須提供下列 function 與 event」：

| 名稱 | 書中定義（譯文） |
|---|---|
| `totalSupply` | 回傳目前存在的此代幣總單位數。ERC20 代幣可以是固定供給，也可以是可變供給 |
| `balanceOf` | 給定一個地址，回傳該地址的代幣餘額 |
| `transfer` | 給定地址與數量，從執行此次轉帳的地址餘額中，把該數量的代幣轉給該地址 |
| `transferFrom` | 給定 sender、recipient 與數量，把代幣從一個帳戶轉到另一個帳戶。**與 `approve` 搭配使用** |
| `approve` | 給定接收方地址與數量，授權該地址從發出授權的帳戶中，執行**多次**、總額不超過該數量的轉帳 |
| `allowance` | 給定 owner 地址與 spender 地址，回傳 spender 仍被核准可從 owner 提取的剩餘數量 |
| `Transfer`（event） | 成功轉帳（呼叫 `transfer` 或 `transferFrom`）時觸發的事件，**即使是零金額的轉帳也會觸發** |
| `Approval`（event） | 成功呼叫 `approve` 後記錄的事件 |

**選用 function**（p.437）：`name`（人類可讀名稱，如 "US Dollars"）、`symbol`（人類可讀代號，如 "USD"）、`decimals`（代幣數量要除以幾位小數；若 `decimals` 為 2，代幣數量要除以 100 才是使用者看到的表示）。

**書中給的 Solidity 介面原文**（p.437–438）：

```solidity
contract ERC20 {
   function totalSupply() constant returns (uint theTotalSupply);
   function balanceOf(address _owner) constant returns (uint balance);
   function transfer(address _to, uint _value) returns (bool success);
   function transferFrom(address _from, address _to, uint _value) returns
      (bool success);
   function approve(address _spender, uint _value) returns (bool success);
   function allowance(address _owner, address _spender) constant returns
      (uint remaining);

   event Transfer(address indexed _from, address indexed _to, uint _value);
   event Approval(address indexed _owner, address indexed _spender, uint _value);
}
```

**內部資料結構就兩張表**（"ERC20 data structures"，p.438）：

```solidity
mapping(address => uint256) balances;                          // 誰有多少
mapping (address => mapping (address => uint256)) public allowed;  // 誰授權誰可花多少
```

每一次轉帳就是「從一個餘額扣掉、加到另一個餘額」。

**兩種工作流程**（"ERC20 workflows"，p.438–440）：

1. **`transfer`：單筆交易。** 錢包對錢包送代幣用的就是這條，**絕大多數代幣交易都走這條**。Alice 想送 10 顆給 Bob，她的錢包對代幣合約地址送一筆交易、呼叫 `transfer(Bob, 10)`；合約調整 Alice 餘額（−10）與 Bob 餘額（+10），並發出 `Transfer` 事件。
2. **`approve` + `transferFrom`：兩筆交易。** 讓代幣擁有者把控制權**委派**給另一個地址，最常見的用途是委派給一份合約來分發代幣，交易所也可以用。書的 ICO 範例：Alice 先部署 AliceCoin（全部發給自己）與 AliceICO 合約，再對 AliceCoin 呼叫 `approve(AliceICO 地址, totalSupply 的 50%)`（觸發 `Approval` 事件）；此後 AliceICO 收到 Bob 的 ether，就按合約內的匯率呼叫 `AliceCoin.transferFrom(Alice, Bob, 數量)`。**只要不超過 Alice 設定的核准上限，AliceICO 可以無限次呼叫 `transferFrom`**，並用 `allowance` 查自己還能賣多少。

**實作要用現成的**（"ERC20 implementations"，p.440–441）：雖然 30 行左右的 Solidity 就能寫出相容的 ERC20，但實際實作都更複雜，因為要處理潛在的安全漏洞。EIP-20 標準提到兩份實作：**Consensys EIP20**（簡單易讀）與 **OpenZeppelin StandardToken**（相容 ERC20 並加上額外安全防護，是 OpenZeppelin 一系列含募資上限、拍賣、歸屬時程等複雜代幣的基礎）。書自己的 METoken 範例就是 `contract METoken is StandardToken`，整份合約只有幾行，功能全部繼承自 OpenZeppelin。

### 7. 書對 ERC20 的評價：已知問題（"Issues with ERC20 Tokens"）

書的態度是「採用爆炸性成長，但有一些潛在的坑」。以下**全部是書中實際寫到的**：

**(1) 把代幣送到不支援代幣的合約地址＝永久卡死。** 書故意示範了這個災難：把 1,000 MET 送進前面章節的 `Faucet` 合約，然後問「怎麼領回來？」答案是：

> "If you’re wondering what to do next, don’t. There is no solution to this problem. The MET sent to Faucet is stuck, forever. Only the Faucet contract can transfer it, and the Faucet contract doesn’t have code to call the transfer function of an ERC20 token contract."
> （譯文：如果你正在想接下來該怎麼辦——別想了。這個問題沒有解。送進 Faucet 的那些 MET 永遠卡住了。只有 Faucet 合約能轉走它們，而 Faucet 合約裡並沒有呼叫 ERC20 代幣合約 `transfer` 函式的程式碼。）
> —— Ch.10 "Sending ERC20 tokens to contract addresses"（PDF p.451）

規模：書引述「據某些估計，寫作當時價值超過約 250 萬美元的代幣就這樣『卡住』並永遠遺失」。**最常見的踩坑方式**是使用者想把代幣送到交易所或其他服務——他們從交易所網站複製一個以太坊地址，以為直接送過去就好，但**許多交易所公布的收款地址其實是合約**，那些合約只設計來收 ether（通常會把收到的資金掃進冷錢包或另一個中心化錢包）。儘管到處寫著「請勿發送代幣到此地址」的警告，還是有大量代幣這樣消失。

**(2) 代幣移轉根本沒有交易送到收款人。** 這是書認為「比較不明顯」的問題：

> "In a token transfer, no transaction is actually sent to the recipient of the token. Instead, the recipient’s address is added to a map within the token contract itself. A transaction sending ether to an address changes the state of an address. A transaction transferring a token to an address only changes the state of the token contract, not the state of the recipient address."
> （譯文：在一次代幣移轉中，實際上沒有任何交易被送到代幣的收款人。取而代之的是，收款人的地址被加進代幣合約內部的一張對映表裡。送 ether 到某個地址的交易會改變該地址的狀態；而把代幣轉到某個地址的交易，只會改變代幣合約的狀態，不會改變收款地址的狀態。）
> —— Ch.10 "Issues with ERC20 Tokens"（PDF p.455）

後果：即使錢包支援 ERC20，**除非使用者明確把某個代幣合約加進「watch」清單，否則錢包不會知道有這個餘額**。有些錢包會盯著最熱門的代幣合約，但那只涵蓋現存 ERC20 合約的極小部分。

**(3) 垃圾代幣（junk token）。** 反過來說，使用者也不會想追蹤所有可能的 ERC20 合約——「許多 ERC20 代幣比較像 email 垃圾信而不是可用的代幣」，它們會**自動替有 ether 活動的帳戶建立餘額**來吸引使用者。歷史悠久的地址（尤其是預售時期建立的）會「裝滿」憑空冒出來的垃圾代幣；當然地址本身沒有真的裝著代幣，是那些代幣合約裡有你的地址。

**(4) 送代幣需要 ether，收代幣不需要——幻覺就這樣破了。**

> "To send ether or use any Ethereum contract you need ether to pay for gas. To send tokens, you also need ether. You cannot pay for a transaction’s gas with a token and the token contract can’t pay for the gas for you."
> （譯文：要發送 ether 或使用任何以太坊合約，你都需要 ether 來支付 gas。要發送代幣，你同樣需要 ether。你無法用代幣支付一筆交易的 gas，代幣合約也不能替你支付 gas。）
> —— Ch.10 "Issues with ERC20 Tokens"（PDF p.456）

書描述的使用者經驗：你在交易所或 ShapeShift 把比特幣換成某代幣，錢包顯示餘額、看起來跟其他加密貨幣沒兩樣；一按送出，錢包告訴你需要 ether。你可能根本不知道它是以太坊上的 ERC20，還以為它有自己的區塊鏈。**「幻覺就這樣破了。」**

**(5) 代幣的行為跟 ether 不一樣。** ether 用 `send` 發送，可被合約中任何 `payable` function 或任何 EOA 接受；代幣則透過只存在於 ERC20 合約內的 `transfer` 或 `approve` + `transferFrom` 發送，且（至少在 ERC20 中）**不會觸發收款合約裡的任何 `payable` function**。

**(6) 責任被推給使用者介面。** 書在 METFaucet 範例做完後直接下結論：只要正確使用，ERC20 代幣可以被 EOA 與其他合約使用，「**然而，正確管理 ERC20 代幣的負擔被推給了使用者介面**」——如果使用者誤把代幣轉到一個沒有能力接收 ERC20 的合約地址，代幣就沒了。

書自己對這批問題的分類：有些是 ERC20 特有的；有些是以太坊內部抽象與介面邊界的普遍問題（EOA 與合約的區別、交易與訊息的區別）；有些可以靠改代幣介面解決，有些需要改以太坊的基礎結構，有些可能根本「無解」，只能靠 UI 設計把細節藏起來。

### 8. 兩個提案中的改良標準

書把它們放在「proposed」層級，並明說爭論仍在繼續。

**ERC223**（p.457–458）：靠**偵測目的地是不是合約**來解決誤轉問題。它要求「設計來接受代幣的合約必須實作一個名為 `tokenFallback` 的 function」；如果轉帳目的地是合約而該合約沒有實作 `tokenFallback`，轉帳就失敗。偵測手法是一小段 inline assembly：

```solidity
function isContract(address _addr) private view returns (bool is_contract) {
  uint length;
    assembly {
       // retrieve the size of the code on target address; this needs assembly
       length := extcodesize(_addr)
    }
    return (length>0);
}
```

書的評價：**ERC223 並未被廣泛實作**，ERC 討論串中對於「向後相容性」以及「該在合約介面層還是使用者介面層做改動」的取捨仍有爭論。

**ERC777**（p.459–461）：目標包含——提供 ERC20 相容介面；用 `send` function 移轉代幣（類似 ether 的轉帳）；相容 ERC820 的代幣合約註冊；透過發送前呼叫的 `tokensToSend` 讓合約與地址控制自己送出哪些代幣；透過在收款方呼叫 `tokensReceived` 讓合約與地址得知代幣到帳，**並藉由「要求合約必須提供 `tokensReceived`」來降低代幣被鎖死在合約裡的機率**；允許既有合約用 proxy 合約來實作這兩個 hook；不論送給合約或 EOA 行為一致；為鑄造（minting）與銷毀（burning）提供專屬事件；讓 operator（受信任第三方，設想為經過驗證的合約）代表持有者移轉代幣；在 `userData` 與 `operatorData` 欄位提供轉帳的中繼資料。

限制與爭議：每個地址**只能註冊一個** token sender 與一個 token recipient hook（可用 message sender＝代幣合約地址來分辨是哪種代幣）；收款合約若沒註冊實作該介面的地址，代幣轉帳就會失敗。ERC777 依賴平行提案 ERC820 的註冊合約，因此部分爭論集中在「**一次採用兩個大改動**（新的代幣標準＋註冊標準）的複雜度」。

### 9. ERC721：非同質化代幣（deed）與 ERC20 的差別

書用的詞是 **deed（地契／權狀）**，並引牛津字典的定義：「一份經簽署與交付的法律文件，特別是關於財產所有權或法定權利者」。書坦承這些東西**在任何司法管轄區都還不被承認為「法律文件」**——「但很可能在未來的某個時點，基於區塊鏈平台上數位簽章的合法所有權會被法律認可」。

ERC721 追蹤**一個獨特事物的所有權**：可以是遊戲道具、數位收藏品，也可以是所有權由代幣追蹤的實體物（房子、車子、藝術品）；**deed 甚至可以代表負值的東西**，例如貸款（債務）、留置權、地役權。標準對「被追蹤所有權的那個東西是什麼」不設限制也不設期待，只要求它**能被唯一識別，而在此標準中是用一個 256-bit 的識別碼達成**。

**跟 ERC20 的差別，書說只要看一行資料結構就夠了**（p.463）：

```solidity
// Mapping from deed ID to owner
mapping (uint256 => address) private deedOwner;
```

> "Whereas ERC20 tracks the balances that belong to each owner, with the owner being the primary key of the mapping, ERC721 tracks each deed ID and who owns it, with the deed ID being the primary key of the mapping. From this basic difference flow all the properties of a non-fungible token."
> （譯文：ERC20 追蹤的是屬於每個擁有者的餘額，對映表的主鍵是擁有者；而 ERC721 追蹤的是每一個 deed ID 以及誰擁有它，對映表的主鍵是 deed ID。非同質化代幣的所有性質，都由這個基本差異衍生而來。）
> —— Ch.10 "ERC721: Non-fungible Token (Deed) Standard"（PDF p.463）

另外書明說：**ERC20 只追蹤每個帳戶的最終餘額，並不（明確地）追蹤任何代幣的來源歷史（provenance）**——這正好呼應第 2 節「可追蹤 provenance 就不完全同質」的說法。

**書中列出的 ERC721 介面原文**（p.463）：

```solidity
interface ERC721 /* is ERC165 */ {
    event Transfer(address indexed _from, address indexed _to, uint256 _deedId);
    event Approval(address indexed _owner, address indexed _approved,
                   uint256 _deedId);
    event ApprovalForAll(address indexed _owner, address indexed _operator,
                         bool _approved);

    function balanceOf(address _owner) external view returns (uint256 _balance);
    function ownerOf(uint256 _deedId) external view returns (address _owner);
    function transfer(address _to, uint256 _deedId) external payable;
    function transferFrom(address _from, address _to, uint256 _deedId)
        external payable;
    function approve(address _approved, uint256 _deedId) external payable;
    function setApprovalForAll(address _operateor, boolean _approved) payable;
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
```

對照 ERC20 可以看出：同名的 `balanceOf`／`transfer`／`transferFrom`／`approve` 都在，但**參數從「數量」換成了「deed ID」**；並多出 `ownerOf`（問某個 deed 屬於誰）與 `setApprovalForAll`（一次授權 operator 管理全部）。

ERC721 另外支援兩個**選用介面**：**metadata**（`name`、`symbol`、`deedUri`）與 **enumeration**（`totalSupply`、`deedByIndex`、`countOfOwners`、`ownerByIndex`、`deedOfOwnerByIndex`）。

### 10. 該不該用標準、用哪一份實作、要不要擴充

**標準是什麼**（"What Are Token Standards? What Is Their Purpose?"，p.466）：**標準是實作的最低規格**——要符合 ERC20，你至少要實作它指定的 function 與行為；你也可以自由加上標準之外的功能。

> "The primary purpose of these standards is to encourage interoperability between contracts."
> （譯文：這些標準的主要目的，是促進合約之間的互通性。）
> —— Ch.10 "What Are Token Standards? What Is Their Purpose?"（PDF p.466）

具體好處：所有錢包、交易所、使用者介面與其他基礎設施元件，都能以**可預期的方式**與任何遵循該規格的合約互動——你部署一份符合 ERC20 的合約，所有既有錢包的使用者就能無縫開始交易你的代幣，不需要升級錢包，你也不必額外做什麼。另一個關鍵性質：**標準是描述性的（descriptive）而非規定性的（prescriptive）**，怎麼實作那些 function 由你決定，合約內部運作與標準無關；標準只有少數規範特定情況下行為的功能性要求（書舉的例子：`transfer` 在 value 為零時的行為）。

**該不該用**（p.467）：這是兩難。標準必然限制你創新的能力，替你挖了一條必須遵循的窄溝；但基本標準是從數百個應用的經驗中浮現的，通常很貼合絕大多數使用情境。更大的議題是**互通性與廣泛採用的價值**——選既有標準，你就獲得所有為該標準設計的系統帶來的價值；選擇偏離，你得考慮自己從頭打造全部支援基礎設施、或說服別人支援你的新標準的成本。書點名這種「凡事自己來、無視既有標準」的傾向叫 **"Not Invented Here" 症候群，與開源文化背道而馳**；但也補上一句：進步與創新有時就是得偏離傳統。

**Security by maturity**（p.468）：選完標準還要選實作，而這個選擇有嚴重的安全意涵。

> "Existing implementations are “battle-tested.” While it is impossible to prove that they are secure, many of them underpin millions of dollars’ worth of tokens. They have been attacked, repeatedly and vigorously. So far, no significant vulnerabilities have been discovered."
> （譯文：既有實作是「經過實戰檢驗」的。雖然無法證明它們安全，但其中許多支撐著價值數百萬美元的代幣，並且反覆而猛烈地被攻擊過。到目前為止，尚未發現重大漏洞。）
> —— Ch.10 "Security by Maturity"（PDF p.468）

書的建議：自己寫不容易，合約被攻破的微妙途徑很多，**用經過充分測試、被廣泛使用的實作安全得多**；書的範例用的就是 OpenZeppelin 的 ERC20 實作，因為它從根基上就以安全為導向。要擴充也要小心——

> "Complexity is the enemy of security. Every single line of code you add expands the attack surface of your contract and could represent a vulnerability lying in wait."
> （譯文：複雜性是安全的敵人。你加的每一行程式碼都在擴大合約的攻擊面，都可能是一個潛伏等待的漏洞。）
> —— Ch.10 "Security by Maturity"（PDF p.468）

**常見的擴充功能**（"Extensions to Token Interface Standards"，p.469–470）：**Owner control**（給特定地址或多簽群組特殊能力：黑名單、白名單、鑄造、回收等）、**Burning**（把代幣送到不可花用的地址或直接抹掉餘額並減少供給）、**Minting**（以可預期的速率或依創建者「意志」增加總供給）、**Crowdfunding**（透過拍賣、市場銷售、反向拍賣等出售代幣）、**Caps**（為總供給設定預先定義且不可變的上限，與 minting 相反）、**Recovery backdoors**（由指定地址啟動的資金回收、反向轉帳或拆除代幣的函式）、**Whitelisting**（把轉帳等動作限制在特定地址，最常見於各法域審核後只提供給「合格投資人」）、**Blacklisting**（禁止特定地址轉帳）。書提醒：這些功能**目前沒有被廣泛接受的介面標準**，而是否擴充標準本身，就是「創新／風險」與「互通性／安全」之間的取捨。

### 11. DApp 架構與「什麼該上鏈」

**這部分見 [[工具-去中心化儲存與命名]]**（同書 Ch.12）：DApp 的定義與五個可去中心化的面向（後端邏輯、前端、資料儲存、訊息通訊、名稱解析）、大檔案為什麼不能上鏈（IPFS／Swarm）、使用者怎麼不用記 0x 地址（ENS）、以及要不要留特權帳號的治理取捨，全部在那張卡。

本卡只留一句銜接：**代幣合約是 DApp「鏈上那一半」的典型形態**——Ch.10 結尾也預告，Ch.12 會用一個非同質化代幣當作拍賣 DApp 的基礎。

## 🧪 我實際套用的紀錄
- 2026-07-15：（待填）

## ⚠️ 注意 / 什麼時候不適用

- **書對當時代幣市場的評價非常不客氣**（"Tokens and ICOs"，p.471）：代幣標準與平台長期影響可能巨大，但**不該和對當前代幣發行的背書混為一談**——「如同任何早期技術，第一波產品與公司幾乎都會失敗，有些會敗得很慘。今天以太坊上提供的許多代幣，不過是勉強偽裝的騙局、金字塔騙局與撈錢手法。」書在 ICO 的 NOTE 也特別聲明：**書中對 ICO 的說明與範例不構成對這種募資方式的背書。**
- **這是 2018 年的快照。** 書自己把 ERC223、ERC777、ERC820 都標為「proposed／討論仍在繼續」，ERC721 引用的也是**當時的提案版本**（介面裡是 `transfer`、`deedUri`、`countOfOwners`，用詞是 deed）。要動手實作前必須查現行規格，不要照書抄介面。
- **標準只是最低規格**，符合 ERC20 不代表安全；安全的整體設計見 [[工具-智能合約安全反模式]]（書自己在 "Security by Maturity" 的 TIP 就指向 Chapter 9）。
- **代幣一定要有 ether 才轉得動**，這個限制連帶決定了很多產品的入金流程設計；gas 那一層見 [[工具-Gas與EVM]]。
- **`decimals` 是純顯示約定**：書的 METoken 用 `decimals = 2`，所以「轉 1,000 MET」在合約裡要寫 `100000`。這種單位換算錯誤在介面層很容易發生。

### 刻意不寫的東西

本書出版於 2018 年，以下都不在本章內，**本卡一律不寫**：

- **`approve` 的競態（race condition）／先跑（front-running）問題**——這是 ERC20 有名的坑，但**本章完全沒有提到**（`race`、`front-run` 在 Ch.10 全章 grep 為 0 命中）。書列出的 ERC20 問題只有上面第 7 節那六項。**不代書補**。（Ch.9 有講交易排序／搶跑，但那是合約安全的一般議題，見 [[工具-智能合約安全反模式]]，不是本章對 ERC20 的評價。）
- **ERC-1155（多代幣標準）**——本章沒有，全章 grep 0 命中。**原卡片提到的 ERC-1155 已移除。**
- **ERC-4626（金庫標準）、現代 NFT 生態**（NFT 市集、版稅、鏈下 metadata 慣例、`tokenURI`／`safeTransferFrom` 這些最終定案的 ERC-721 命名）——書中一律沒有。
- **DeFi、AMM、流動性池、穩定幣機制**——本章談代幣的用途時只列到第 1 節那 10 種，沒有 DeFi 這個概念。
- **EIP-1559 之後的 gas 機制**——本章談到代幣轉帳需要 gas 時，用的是「你需要 ether 來付 gas、代幣不能付 gas」的說法，沒有 base fee／priority fee。相關的 gas 卡也維持書中的單一 `gasPrice` 模型。

## 🔗 相關工具
- [[ERC-20 代幣標準]] —— **規格層**：EIP-20 原文的逐條語義（哪些 MUST、哪些 SHOULD、`approve` 的已知競態）。本卡是 2018 年書本視角的概念與決策，真要實作或串接時看那張。
- [[工具-去中心化儲存與命名]] —— 同書 Ch.12：DApp 的定義、前端／儲存／命名怎麼去中心化（本卡的第 11 節直接指向那裡）。
- [[工具-智能合約]] —— 代幣＝一份智能合約；那張講合約本身的性質與不可變性。
- [[工具-智能合約安全反模式]] —— 同書 Ch.9："Security by Maturity" 明白指向那一章；代幣合約管的是真實價值，權限與升級設計的坑都在那裡。
- [[工具-Gas與EVM]] —— 同書 Ch.13：為什麼送代幣一定要有 ether，以及 `transfer` 那筆交易的成本從哪來。
- [[工具-以太坊帳戶與交易]] —— 同書 Ch.6：代幣移轉「只改代幣合約狀態、不改收款地址狀態」，要先懂交易與帳戶模型才看得懂這句。
- [[工具-針對介面編程]] —— 標準介面＝針對介面編程；書自己的說法是「標準是描述性而非規定性的」。
- [[精通以太坊]] —— 來源書卡
