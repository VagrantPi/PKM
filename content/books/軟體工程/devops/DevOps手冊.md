---
type: book-map
title: "DevOps 手冊 The DevOps Handbook"
author: Gene Kim、Jez Humble、Patrick Debois、John Willis
status: done
tags: [software, devops, cicd, continuous-delivery, culture]
finished: 2026-07-15
rating: 4.6
---

## 📌 30 秒摘要（Layer 3）
> [[鳳凰專案]] 用小說講「為什麼」，這本用手冊講「怎麼做」。沿著**三步工作法**把 DevOps 落地成具體實踐：第一步（流動）→ 建**部署管線**、持續整合/交付、小批量發布；第二步（回饋）→ 建**遙測與監控**、讓問題快速浮現；第三步（持續學習）→ **無指責事後檢討**、把改善與安全（左移）變成日常。

## 🗺 心智圖（Canvas）
![[DevOps手冊.canvas]]

## 🧰 這本書給我的工具
- [[工具-價值流圖]] — 想改善但講不出到底卡在哪一段時
- [[工具-部署管線與持續交付]] — 想讓發布變頻繁、可靠、無痛時
- [[工具-低風險發布模式]] — 上線只能挑半夜、不敢頻繁發布時
- [[工具-遙測與監控]] — 想快速發現問題、用數據決策時
- [[工具-無指責事後檢討]] — 出事後想從失敗學習而非追究人時
- [[工具-注入故障與韌性演練]] — 復原程序從來沒有真的演練過時
- [[工具-資安與合規左移]] — 資安永遠最後一刻擋上線、稽核證據準備不完時

## 📖 完整型錄：43 條 DevOps 實踐（詳解在 reference/）

**🚀 從哪開始**
- [[價值流圖|價值流圖 Value Stream Mapping]]、[[專責轉型團隊|專責轉型團隊 Dedicated Transformation Team]]、[[保留20%產能給非功能需求|保留 20% 產能給非功能需求 Reserve 20% for Non-Functional Requirements]]

**🏗 組織與架構**
- [[自助服務平台|自助服務平台 Self-Service Platform]]、[[康威定律作為設計工具|康威定律作為設計工具 Conway's Law]]、[[兩個披薩團隊|兩個披薩團隊 Two-Pizza Team]]、[[演進式架構|演進式架構 Evolutionary Architecture]]

**⚡ 第一步・流動：技術實踐**
- [[隨選環境與基礎設施即程式碼|隨選環境與基礎設施即程式碼 On-Demand Environments & Infrastructure as Code]]、[[版本控管一切|版本控管一切 Version Control Everything]]、[[不可變基礎設施|不可變基礎設施 Immutable Infrastructure]]、[[修改完成的定義|修改完成的定義 Modify the Definition of Done]]、[[測試金字塔|測試金字塔 The Testing Pyramid]]、[[只自動化可信的測試|只自動化可信的測試 Automate Only Trustworthy Tests]]、[[虛擬安燈繩|虛擬安燈繩 Virtual Andon Cord]]、[[主幹開發|主幹開發 Trunk-Based Development]]、[[自動化自助部署|自動化自助部署 Automated Self-Service Deployment]]

**🎛 第一步・流動：低風險發布**
- [[解耦部署與發布|解耦部署與發布 Decouple Deployments from Releases]]、[[藍綠部署|藍綠部署 Blue-Green Deployment]]、[[金絲雀發布|金絲雀發布 Canary Release]]、[[功能開關|功能開關 Feature Toggles]]、[[黑啟動|黑啟動 Dark Launching]]

**📡 第二步・回饋：遙測與告警**
- [[五層遙測覆蓋|五層遙測覆蓋 Five-Layer Telemetry]]、[[日誌分級|日誌分級 Logging Levels]]、[[均值與標準差告警|均值與標準差告警 Standard Deviation Alerting]]、[[非高斯資料的異常偵測|非高斯資料的異常偵測 Anomaly Detection for Non-Gaussian Data]]、[[從事故回推告警|從事故回推告警 Alert Reset from Incidents]]、[[開發者共同輪值|開發者共同輪值 Dev Shares Pager Rotation]]

**🔬 第二步・回饋：實驗與審查**
- [[A-B測試與假設驅動開發|A/B 測試與假設驅動開發 A/B Testing & Hypothesis-Driven Development]]、[[同儕審查取代變更審批|同儕審查取代變更審批 Peer Review over Change Approval]]、[[程式碼審查準則|程式碼審查準則 Code Review Guidelines]]、[[結對程式設計|結對程式設計 Pair Programming]]、[[大膽砍掉官僚流程|大膽砍掉官僚流程 Cut Bureaucratic Processes]]

**🔁 第三步・持續學習**
- [[廣泛公開事後檢討|廣泛公開事後檢討 Publish Post-Mortems Widely]]、[[注入生產故障|注入生產故障 Inject Production Failures]]、[[遊戲日|遊戲日 Game Day]]、[[改善閃電戰|改善閃電戰 Improvement Blitz]]、[[技術選型收斂|技術選型收斂 Technology Standardization]]、[[單一共用原始碼儲存庫|單一共用原始碼儲存庫 Single Shared Source Code Repository]]

**🔐 資安與合規左移**
- [[預先核可的資安函式庫|預先核可的資安函式庫 Preventive Security Controls]]、[[四類應用資安自動測試|四類應用資安自動測試 Four Categories of Application Security Testing]]、[[保護部署管線|保護部署管線 Protect the Deployment Pipeline]]、[[資安遙測|資安遙測 Security Telemetry]]、[[把變更重歸類為標準變更|把變更重歸類為標準變更 Re-categorize as Standard Changes]]

## ✨ 關鍵重點（Layer 1–2）
- **這是三步工作法的實作大全**（總綱見 [[工具-三步工作法]]）：[[鳳凰專案]] 講「為什麼」，這本逐項講「怎麼做」。
- **先量再改**：價值流圖第一輪只畫 **5–15 個 process block**，每塊標 lead time／process time／%C/A；理想化的未來圖訂 **3–12 個月**為期限。技術債固定吃掉**至少 20%** 的 Dev 與 Ops 產能。
- **第一步・流動**：版本控管一切（2014 State of DevOps 發現 **Ops 是否用版控比 Dev 更能預測績效**）、主幹開發（每人每天至少 check in 一次）、測試金字塔（涵蓋率低於 **80%** 就讓套件失敗、build 守住**十分鐘**）、把部署與發布解耦後用藍綠／金絲雀／功能開關／黑啟動控制風險。
- **第二步・回饋**：五層遙測（business／application／infrastructure／client／pipeline）、**3σ 告警只讓 0.3% 的資料點觸發**、開發者一起輪值 on-call、用同儕審查取代 CAB 逐案審批（**ITIL 從未規定 CAB 要手動評估每個變更**）。
- **第三步・持續學習**：無指責事後檢討開完才准結案、Game Day 與 Chaos Monkey 在**上班時間**製造故障、改善閃電戰期間**不允許做功能工作**。
- **資安左移**：Dev : Ops : Infosec 的人力比例是 **100 : 10 : 1**——資安只能靠自動化與預先核可的函式庫存活；Twitter 把 Brakeman 接進 build 後**漏洞發現率降 60%**。

## 💬 金句原文（Layer 0）
- 「比日常工作更重要的，是改善日常工作。」——Mike Orzen，《Lean IT》作者
  > "Even more important than daily work is the improvement of daily work."
- 「規模 1 倍時管用的東西，很少在 10 倍或 100 倍時還管用。」——Randy Shoup（前 eBay／Google）
  > "What works at scale 1x rarely works at scale 10x or 100x."
- 「一個服務，要到你在生產環境把它弄壞為止，才算真的測過。」——Jesse Robbins，Amazon 的「災難大師」
  > "a service is not really tested until we break it in production."

## 🔗 相關
- 故事版：[[鳳凰專案]]（IT 管理視角）、[[獨角獸專案]]（開發者視角）
- 主題總覽：[[moc/DevOps|DevOps 主題地圖]]
