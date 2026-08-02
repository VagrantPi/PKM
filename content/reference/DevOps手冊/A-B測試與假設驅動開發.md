---
type: reference
name: "A/B 測試與假設驅動開發 A/B Testing & Hypothesis-Driven Development"
source: "[[DevOps手冊]]"
source_type: book
tags: [devops, feedback, experimentation, product]
triggers: [功能做完了卻不知道有沒有用, 老闆說了算但沒人有證據, 想改按鈕文案又怕影響營收, 旺季不敢動任何東西只好凍結]
---

## 🎯 什麼情境該想到我
當你「靠直覺與老闆的一票決定要做哪個功能，卻拿不出證據證明它真的有用」的時候。

## ⚙️ 怎麼用（步驟 / 公式）
意圖：把每一個功能都當成一個**假設**，用真實使用者的生產環境實驗來證實或推翻它。

A/B 測試怎麼做：
- 網站訪客被**隨機**分配看到兩個版本之一：**control（「A」）** 或 **treatment（「B」）**。
- 對兩群使用者後續行為做**統計分析**，證明兩者結果是否有顯著差異，藉此在 treatment（例如功能、設計元素、背景色的改動）與 outcome（例如轉換率、平均訂單金額）之間**建立因果連結**。
- 例子：改「buy」按鈕的文字或顏色是否提高營收；**刻意注入延遲**拖慢網站回應時間是否降低營收——後者讓你能把效能改善**換算成金額**。
- 別名：online controlled experiments、split tests；一次跑多個變數則叫 **multivariate testing**。

怎麼在發布層面實作：
- 快速迭代的 A/B 測試靠的是**隨需（on demand）的生產部署能力**，用 **feature toggles**、必要時同時交付多個版本給不同客群，並且**各層都要有可用的生產遙測**。
- **勾進 feature toggles，就能控制多少百分比的使用者看到 treatment 版本**。書中例子：一半客戶是 treatment 組，看到「購物車中無庫存品項的相似商品連結」，跟 control 組（不給這個提案）比較該 session 的購買次數。
- Etsy 開源了他們的實驗框架 **Feature API**（前身 Etsy A/B API），它不只支援 A/B 測試，也支援 **online ramp-ups**（節流控制實驗曝光）。其他產品包括 Optimizely、Google Analytics。

**關鍵數字（Ronny Kohavi，Microsoft）**：在評估那些**精心設計並執行、目的就是要改善某個關鍵指標**的實驗後發現，**只有大約三分之一真的改善了那個關鍵指標**。換句話說，**三分之二的功能不是影響微乎其微，就是把事情弄得更糟**——而這些功能當初都被認為是合理的好點子。含意：若不做使用者研究，你正在建造的功能有三分之二會交付零或負價值，同時讓程式庫更複雜、維護成本更高、更難改。Jez Humble 的玩笑：極端來說，**與其做這些不創造價值的功能，不如給整個團隊放假**，組織與客戶都會過得更好。

假設驅動開發的三段式模板（Barry O'Reilly，《Lean Enterprise》共同作者）：

> **We Believe** that increasing the size of hotel images on the booking page
>
> **Will Result in** improved customer engagement and conversion
>
> **We Will Have Confidence To Proceed When** we see a 5% increase in customers who review hotel images who then proceed to book in forty-eight hours.

也就是：量化門檻是**看過飯店照片後、在四十八小時內完成訂房的客戶增加 5%**。採用實驗式的產品開發，要求我們不只把工作拆成小單位（stories 或 requirements），還要**驗證每個工作單位是否交付了預期成果**；沒有的話，就改用其他路徑修正 road map。

案例一：Intuit TurboTax
- Scott Cook（Intuit 創辦人）主張的不是「看老闆那一票」，而是**讓真人在真實驗中真的做出行為，再據此決策**。
- Dan Maurer 接手消費者事業群（負責 TurboTax 網站）時，**一年大約做 7 個實驗**。
- 導入「rampant innovation culture」（2010）後，**在美國報稅季的三個月內做了 165 個實驗**，**網站轉換率提升 50%**。
- 最令人意外的一點：TurboTax **刻意在流量尖峰季做生產環境實驗**。零售業幾十年來的做法是十月中到一月中**凍結變更**；但把部署與發布做到又快又安全之後，尖峰期的線上實驗就變成低風險活動。書中的論點是：**實驗價值最高的時候，正是流量尖峰季**——若等到報稅截止日隔天（4/16）才改，早就把潛在客戶（甚至既有客戶）輸給對手了。

案例二：Yahoo! Answers（2010）
- 從**六週一次發布**改為**每週多次發布**。當時 Answers 約有 1.4 億月訪客、超過兩千萬活躍使用者、二十多種語言，但使用者成長與營收已經停滯、互動分數在下滑。
- Jim Stoneham 的觀察：Twitter、Facebook、Zynga 這些對手**至少每週做兩次實驗**，回饋迴圈比他們快 **10 倍**；而他當時最快只能四週發一次。他也指出：產品負責人與開發者再怎麼把「metrics-driven」掛嘴上，**只要實驗不是高頻（每日或每週）進行，日常工作的焦點就只會停在自己手上的功能，而不是客戶成果**。
- 改為每週乃至每週多次部署後的**十二個月**成果：**月訪問量增加 72%、使用者互動增為三倍、營收翻倍**。
- 後續聚焦的核心指標：Time to first answer、Time to best answer、Upvotes per answer、Answers／week／person、Second search rate（越低越好）。
- Stoneham 的結論：這改變的不只是功能速度，「我們從一群員工變成一群 owner」。

> 原文：「experiments that were designed to improve a key metric, only about one-third」（L9197，接 L9198「were successful at improving the key metric!」）

> 原文：「 We Will Have Confidence To Proceed When we see a 5% increase in」（L9263，接 L9264「 customers who review hotel images who then proceed to book in forty-eight」）

> 原文：「do 165 experiments in the three months of the [US] tax season. Business result?」（L9110，接 L9111「[The] conversion rate of the website is up 50 percent….」）

> 原文：「72%, increased user engagement of threefold, and the team」（L9326，接 L9327「doubled their revenue.」）

## 🧪 我實際套用的紀錄
- （待填）

## ⚠️ 注意 / 什麼時候不適用
- **沒有 feature toggles 與各層生產遙測就做不了這件事**——先把發布能力與遙測補上，否則實驗只是換個名字的猜測。
- 一次跑多個實驗時要小心互相干擾（書中在變更協調那節就把「simultaneous A/B tests」列為需要協調的風險）。
- 三分之二的功能沒有正面效果是**實驗結果**，不是允許亂做的理由——重點是要有機制**及早知道**哪三分之二。
- 「假設模板」若沒有量化門檻與時窗（例：48 小時內 +5%），就退化成願望清單，無法判定成敗。
- 尖峰期做實驗的前提是**部署與發布已經足夠快且安全**；能力沒到位就照做，只是把 Knight Capital 式的風險放到最貴的時段。

## 🔗 相關工具
- [[功能開關]]（控制多少比例的使用者看到 treatment，是 A/B 測試的實作基礎）
- [[解耦部署與發布]]（先能安全部署，才有辦法在尖峰季做實驗）
- [[工具-部署管線與持續交付]]（高頻實驗的前提是高頻且安全的發布）
- [[五層遙測覆蓋]]（Business level 明列 A/B testing results 為必備遙測）
- [[同儕審查取代變更審批]]（同時跑多個實驗時的變更協調問題）
- [[工具-三步工作法]]（假設驅動開發是第三步「持續實驗與學習」的具體形式）
- [[DevOps手冊]]
