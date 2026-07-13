#!/usr/bin/env bash
#
# sync.sh — 把 Obsidian vault 的筆記同步進 Quartz 並發布到 GitHub Pages
#
# 流程：vault(books/articles/tools) --複製--> Quartz content/ --commit+push-->
#       GitHub Actions 自動 build 並部署 https://vagrantpi.github.io/PKM/
#
# 用法：
#   ./sync.sh            只同步 + 推送（正常發布用這個）
#   ./sync.sh --serve    同步後在本機預覽（不推送），http://localhost:8099
#
set -euo pipefail

VAULT="$HOME/WS/kais/Obsidian"          # Obsidian 筆記庫
SITE="$HOME/WS/kais/Obsidian-quartz"    # Quartz 網站專案
NODE_BIN="$HOME/.nvm/versions/node/v22.23.1/bin"
export PATH="$NODE_BIN:$PATH"

cd "$SITE"

echo "▶ 從 vault 同步筆記到 Quartz content/ ..."
# 只更新這三個來源資料夾，保留 content/index.md 等站台自訂檔
for d in books articles tools moc; do
  rm -rf "content/$d"
  mkdir -p "content/$d"
  # 遞迴同步（保留子資料夾結構，例如 books/軟體工程/clean-code/），只複製 .md
  rsync -a --prune-empty-dirs --include='*/' --include='*.md' --exclude='*' "$VAULT/$d/" "content/$d/"
done
echo "  已同步 $(find content -name '*.md' | wc -l | tr -d ' ') 篇筆記"

# --serve：本機預覽，不推送
if [[ "${1:-}" == "--serve" ]]; then
  echo "▶ 本機預覽（Ctrl+C 結束）: http://localhost:8099"
  exec npx quartz build --serve --port 8099
fi

echo "▶ 提交並推送到 GitHub ..."
git add -A
if git diff --cached --quiet; then
  echo "  沒有變更，略過推送。"
  exit 0
fi
git commit -m "sync: 更新筆記 $(date '+%Y-%m-%d %H:%M')"
git push
echo "✔ 已推送。GitHub Actions 正在 build，約 1–2 分鐘後更新："
echo "  https://vagrantpi.github.io/PKM/"
