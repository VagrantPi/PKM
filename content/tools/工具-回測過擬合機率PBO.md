---
type: tool
name: "回測過擬合機率 PBO（CSCV）"
source: "[[回測過擬合的機率（PBO）]]"
source_type: article
tags: [finance, quant, backtest, overfitting, cross-validation]
triggers: [回測績效好得不像話, 掃了很多組參數挑最好的, 策略上線後表現大不如回測, 不知道回測結果能不能信]
---

## 🎯 什麼情境該想到我
當你「**掃了一堆參數組合，挑出回測最好的那組，正要決定要不要上線**」的時候。
★ 它不評估某一個策略好不好，而是評估「**你挑策略的流程**」有沒有在挑雜訊。

## ⚙️ 怎麼用

### 1. 準備矩陣
- 把試過的 **N 組參數**，每期損益排成 T×N 矩陣 M（每列同一時間點）。
- **所有試過的組合都要放**，包括失敗的。藏掉失敗的組合，PBO 會被低估。
- 用最佳化演算法引導搜尋時，放每次搜尋收斂後的結果，不放中間步驟。

### 2. 跑 CSCV
1. 依時間切 S 段（預設 S=16）。
2. 窮舉 C(S, S/2) 種「哪一半當樣本內」的組合。
3. 每種組合：在樣本內挑冠軍，看它在樣本外的相對排名 ω = rank/(N+1)，算 λ = ln(ω/(1−ω))。
4. **PBO ＝ λ ≤ 0 的比例。**

Node 實作（2026-10-25 自己寫並驗證過）。關鍵技巧是 **Sharpe 只需要每段的 sum、sum of squares、count**，任意段組合可以直接加總，不用重掃資料。880 個策略 × 12,870 種組合，約 1 秒跑完：

```js
function pbo(M, S = 16) {
  const T = M.length, N = M[0].length, L = Math.floor(T / S);
  const blk = Array.from({ length: S }, (_, s) => {        // 每段每策略的 sum、sumsq
    const sum = new Float64Array(N), sq = new Float64Array(N);
    for (let t = s * L; t < (s + 1) * L; t++)
      for (let n = 0; n < N; n++) { sum[n] += M[t][n]; sq[n] += M[t][n] ** 2; }
    return { sum, sq };
  });
  const sharpe = (blocks) => {                              // 合併多段算 Sharpe（只比排名，不必年化）
    const out = new Float64Array(N), cnt = blocks.length * L;
    for (let n = 0; n < N; n++) {
      let a = 0, b = 0;
      for (const s of blocks) { a += blk[s].sum[n]; b += blk[s].sq[n]; }
      const mu = a / cnt;
      out[n] = mu / Math.sqrt(Math.max(b / cnt - mu * mu, 1e-18));
    }
    return out;
  };
  const logits = [];
  const comb = (start, pick) => {                           // 窮舉 C(S, S/2)
    if (pick.length === S / 2) {
      const oos = [...Array(S).keys()].filter((s) => !pick.includes(s));
      const R = sharpe(pick), Rb = sharpe(oos);
      let best = 0;
      for (let n = 1; n < N; n++) if (R[n] > R[best]) best = n;
      let rank = 1;                                         // 1 = 樣本外最差，N = 最好
      for (let n = 0; n < N; n++) if (Rb[n] < Rb[best]) rank++;
      const w = rank / (N + 1);
      logits.push(Math.log(w / (1 - w)));
      return;
    }
    for (let s = start; s < S; s++) comb(s + 1, [...pick, s]);
  };
  comb(0, []);
  return logits.filter((l) => l <= 0).length / logits.length;  // PBO
}
```

### 3. 判讀
| 結果 | 意思 | 動作 |
|---|---|---|
| PBO > 0.05 | 挑選流程很可能在挑雜訊 | 不要上線；減少參數維度或拉長資料 |
| PBO 低，但樣本外虧損機率高 | 沒過擬合，但策略本身就不賺錢 | 不是調參問題，回頭檢查策略邏輯 |
| PBO 低，且樣本外冠軍隨機支配整體 | 挑選流程確實有效 | 可以進下一關（模擬盤、小資金） |

順便看**績效衰退**：把每種組合的（樣本內冠軍 Sharpe，樣本外 Sharpe）畫成散點。斜率是負的，代表越去追樣本內最高分，樣本外越差。

### 參數怎麼選（可自行驗算）
- **S**：組合數是 C(S, S/2)，S=16 時是 **12,870**，論文誤印為 12,780。PBO 是比例估計，標準差最大是 √(1/(4·12870)) ≈ 0.0044，夠精確。
  - 4 年日資料切 16 段，每段約一季，能保住日、週、月的序列結構。
  - 要研究季效應就改用 S=12（924 種），或把資料長度加倍。
- **N**：要遠大於 10。N 太小時 ω 只有幾個離散值，PBO 的解析度不夠。
- **T**：取「實際用來挑策略的資料長度」的兩倍，因為 CSCV 每次只用一半資料挑。

## 🧪 我實際套用的紀錄
- 2026-10-25：用上面的程式碼重現論文第 6 節。月度季節策略，進場日 × 持有天數 × 多空，共 880 組，1,000 個交易日，每種各 3 個隨機種子：
  - 純隨機漫步：PBO 0.56／0.60／0.84（論文 55%）
  - 每月前 5 天埋入 +0.25σ 效應：PBO 0.00／0.16／0.05（論文 13%）
  - **觀察**：我的每一次 PBO 都剛好等於樣本外虧損機率。原因是參數格點裡做多、做空成對出現，每個策略都有一個鏡像，樣本外中位數 Sharpe 恰好是 0，「低於中位數」就等於「虧錢」。格點不對稱時，兩者就不會相等。

## ⚠️ 注意 / 什麼時候不適用
- **不檢查回測本身對不對**：手續費、滑價設錯，或用到當時拿不到的未來資料，PBO 一樣會給出漂亮的數字。這些要另外檢查。
- **不能拿 PBO 當挑策略的目標**，例如「挑 PBO 最低的那組參數」。這樣就是在對 PBO 過擬合（Goodhart 定律）。它只用來評估挑選流程。
- **只涵蓋資料期間內的市場狀態**：資料期間外換了行情，它無能為力。
- **PBO 高不代表策略全爛**：N 個策略都很好又彼此差不多時，PBO 也會高。
- **對稱切分不一定最適合**：績效序列自我相關很強時，切段可能破壞時間結構。對績效分布有更多了解時，針對模型設計的方法會更準。

## 🔗 相關工具
- [[工具-試越多次冠軍越不可信]] —— 這個工具背後的通用道理：為什麼「挑最好的」本身就會灌水
