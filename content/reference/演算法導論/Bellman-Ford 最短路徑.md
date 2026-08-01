---
type: reference
name: "Bellman-Ford 最短路徑 Bellman-Ford"
source: "[[演算法導論]]"
source_type: book
tags: [algorithm, clrs, graph]
triggers: [圖有負權邊, 要偵測負權環, 單源最短路但 Dijkstra 不適用]
---

## 🎯 什麼情境該想到我
當你「要單源最短路、但圖有**負權邊**，或要偵測負權環時」的時候。

## ⚙️ 怎麼用（步驟 / 公式）
- **思路**：對所有邊做 V-1 輪鬆弛。
- **偵測負環**：第 V 輪仍能鬆弛代表有負權環。
- **複雜度**：O(VE)。

## 🧪 我實際套用的紀錄
- （待填）

## ⚠️ 注意 / 什麼時候不適用
- 比 Dijkstra 慢；沒有負權時優先用 Dijkstra。

## 🔗 相關工具
- [[Dijkstra 最短路徑]]
- [[Floyd-Warshall 全對最短路]]
- [[演算法導論]]
