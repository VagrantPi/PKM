---
type: reference
name: "Floyd-Warshall 全對最短路 Floyd-Warshall"
source: "[[演算法導論]]"
source_type: book
tags: [algorithm, clrs, graph]
triggers: [要所有點對之間的最短路, 圖小而稠密, 要傳遞閉包]
---

## 🎯 什麼情境該想到我
當你「要一次算出**所有點對**之間的最短路徑、且圖不大時」的時候。

## ⚙️ 怎麼用（步驟 / 公式）
- **思路**：DP，逐一把每個節點當中繼點 k，更新所有 (i,j)。
- **複雜度**：時間 O(V³)、空間 O(V²)。
- dist[i][j] = min(dist[i][j], dist[i][k]+dist[k][j])。

## 🧪 我實際套用的紀錄
- （待填）

## ⚠️ 注意 / 什麼時候不適用
- V 很大時 O(V³) 太慢；稀疏圖多源可跑多次 Dijkstra。
- 可處理負權邊（無負環）。

## 🔗 相關工具
- [[Bellman-Ford 最短路徑]]
- [[Dijkstra 最短路徑]]
- [[動態規劃]]
- [[演算法導論]]
