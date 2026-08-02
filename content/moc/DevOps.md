---
type: moc
title: "DevOps"
tags: [moc, software, devops, delivery]
---

> 主題索引（MOC）：把「想法 → 上線 → 學到教訓」整條交付流程的工具收在一起。
> 四本來源書分工是：[[鳳凰專案]] 講**為什麼**（IT 管理視角）、[[獨角獸專案]] 講**開發者體驗與文化**、[[DevOps手冊]] 講**怎麼做**（實作大全）、[[高效程式設計師的45個習慣]] 講**團隊日常習慣**。

## 🧭 總綱
- [[工具-三步工作法]]（[[鳳凰專案]]）—— 流動／回饋／持續學習三個方向的上位地圖，底下每一區都掛在它下面

## 🚀 從哪開始（先量再改）
- [[工具-價值流圖]]、[[工具-找出並管理約束點]] —— 前者告訴你哪裡慢，後者告訴你先修哪一個
- [[工具-四種工作類型]]、[[工具-降低在製品WIP]]、[[工具-等待時間與閒置產能]]（[[鳳凰專案]]）—— 讓工作可見、限流、解釋「為什麼大家都很忙卻交付不出來」

## ⚡ 第一步・流動
- [[工具-部署管線與持續交付]] —— 版本控管一切、CI、一鍵部署、小批量
- [[工具-低風險發布模式]] —— 把部署與發布拆開後，用藍綠／金絲雀／功能開關／黑啟動控制風險

## 📡 第二步・回饋
- [[工具-遙測與監控]] —— 指標／日誌／追蹤與告警設計
- [[工具-心理安全感]]（[[獨角獸專案]]）—— 回饋要能往上游走，前提是人敢說真話

## 🔁 第三步・持續學習
- [[工具-無指責事後檢討]] —— 出事後追系統不追人
- [[工具-注入故障與韌性演練]] —— 主動製造故障，別等它自己來
- [[工具-技術債功能凍結]]（[[獨角獸專案]]）—— 債多到動不了時，怎麼喊停、停多久
- [[工具-對事不對人的協作]]、[[工具-投資自己持續學習]]（[[高效程式設計師的45個習慣]]）—— 把「檢討不變成人身攻擊」與「持續學習」落到個人的日常習慣

## 🔐 資安與合規
- [[工具-資安與合規左移]] —— 資安測試進管線、稽核證據自動化、把低風險變更降級為標準變更

## 👔 管理與投資決策
- [[工具-把業務目標接到IT風險]]（[[鳳凰專案]]）—— 把技術工作翻譯成業務語言
- [[工具-五大理想]]（[[獨角獸專案]]）—— 診斷開發者體驗與工程文化的五個面向
- [[工具-核心與語境盤點]]、[[工具-三地平線與創新賭注治理]]（[[獨角獸專案]]）—— 什麼自己做、資源投到哪個時間軸
- [[工具-資料民主化]]（[[獨角獸專案]]）—— 解除資料團隊的瓶頸

## 📖 完整型錄：43 條 DevOps 實踐（[[DevOps手冊]]，詳解在 reference/）
  - **🚀 從哪開始**：[[價值流圖|價值流圖 Value Stream Mapping]]、[[專責轉型團隊|專責轉型團隊 Dedicated Transformation Team]]、[[保留20%產能給非功能需求|保留 20% 產能給非功能需求 Reserve 20% for Non-Functional Requirements]]
  - **🏗 組織與架構**：[[自助服務平台|自助服務平台 Self-Service Platform]]、[[康威定律作為設計工具|康威定律作為設計工具 Conway's Law]]、[[兩個披薩團隊|兩個披薩團隊 Two-Pizza Team]]、[[演進式架構|演進式架構 Evolutionary Architecture]]
  - **⚡ 第一步・流動：技術實踐**：[[隨選環境與基礎設施即程式碼|隨選環境與基礎設施即程式碼 On-Demand Environments & Infrastructure as Code]]、[[版本控管一切|版本控管一切 Version Control Everything]]、[[不可變基礎設施|不可變基礎設施 Immutable Infrastructure]]、[[修改完成的定義|修改完成的定義 Modify the Definition of Done]]、[[測試金字塔|測試金字塔 The Testing Pyramid]]、[[只自動化可信的測試|只自動化可信的測試 Automate Only Trustworthy Tests]]、[[虛擬安燈繩|虛擬安燈繩 Virtual Andon Cord]]、[[主幹開發|主幹開發 Trunk-Based Development]]、[[自動化自助部署|自動化自助部署 Automated Self-Service Deployment]]
  - **🎛 第一步・流動：低風險發布**：[[解耦部署與發布|解耦部署與發布 Decouple Deployments from Releases]]、[[藍綠部署|藍綠部署 Blue-Green Deployment]]、[[金絲雀發布|金絲雀發布 Canary Release]]、[[功能開關|功能開關 Feature Toggles]]、[[黑啟動|黑啟動 Dark Launching]]
  - **📡 第二步・回饋：遙測與告警**：[[五層遙測覆蓋|五層遙測覆蓋 Five-Layer Telemetry]]、[[日誌分級|日誌分級 Logging Levels]]、[[均值與標準差告警|均值與標準差告警 Standard Deviation Alerting]]、[[非高斯資料的異常偵測|非高斯資料的異常偵測 Anomaly Detection for Non-Gaussian Data]]、[[從事故回推告警|從事故回推告警 Alert Reset from Incidents]]、[[開發者共同輪值|開發者共同輪值 Dev Shares Pager Rotation]]
  - **🔬 第二步・回饋：實驗與審查**：[[A-B測試與假設驅動開發|A/B 測試與假設驅動開發 A/B Testing & Hypothesis-Driven Development]]、[[同儕審查取代變更審批|同儕審查取代變更審批 Peer Review over Change Approval]]、[[程式碼審查準則|程式碼審查準則 Code Review Guidelines]]、[[結對程式設計|結對程式設計 Pair Programming]]、[[大膽砍掉官僚流程|大膽砍掉官僚流程 Cut Bureaucratic Processes]]
  - **🔁 第三步・持續學習**：[[廣泛公開事後檢討|廣泛公開事後檢討 Publish Post-Mortems Widely]]、[[注入生產故障|注入生產故障 Inject Production Failures]]、[[遊戲日|遊戲日 Game Day]]、[[改善閃電戰|改善閃電戰 Improvement Blitz]]、[[技術選型收斂|技術選型收斂 Technology Standardization]]、[[單一共用原始碼儲存庫|單一共用原始碼儲存庫 Single Shared Source Code Repository]]
  - **🔐 資安與合規左移**：[[預先核可的資安函式庫|預先核可的資安函式庫 Preventive Security Controls]]、[[四類應用資安自動測試|四類應用資安自動測試 Four Categories of Application Security Testing]]、[[保護部署管線|保護部署管線 Protect the Deployment Pipeline]]、[[資安遙測|資安遙測 Security Telemetry]]、[[把變更重歸類為標準變更|把變更重歸類為標準變更 Re-categorize as Standard Changes]]

## 📚 來源書
[[鳳凰專案]]、[[DevOps手冊]]、[[獨角獸專案]]、[[高效程式設計師的45個習慣]]
