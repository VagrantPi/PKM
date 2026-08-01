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
# 只更新這幾個來源資料夾，保留 content/index.md 等站台自訂檔
for d in books articles tools moc reference; do
  rm -rf "content/$d"
  mkdir -p "content/$d"
  # 遞迴同步（保留子資料夾結構，例如 books/軟體工程/clean-code/），只複製 .md
  rsync -a --prune-empty-dirs --include='*/' --include='*.md' --include='*.canvas' --exclude='*' "$VAULT/$d/" "content/$d/"
done
echo "  已同步 $(find content -name '*.md' | wc -l | tr -d ' ') 篇筆記"

# tag 頁 stub：讓 tag 連結不 404，同時不讓 tag 節點跑進 Graph View。
#
# tag-page 外掛遇到已存在的 content/tags/<tag>.md 就不再產生虛擬頁，改用真實檔；
# 真實檔標 unlisted: true 後，contentIndex/search/explorer 都會略過它，但 HTML 照樣
# 產出。全域圖譜的節點來源正是 contentIndex（depth: -1 會把每個 key 都變節點），
# 所以這樣才能兩者兼得。詳見 CLAUDE.md。
echo "▶ 重新產生 tag 頁 stub ..."
rm -rf content/tags
python3 - << 'PY'
import os, re
tags = set()
for root, _, files in os.walk("content"):
    for f in files:
        if not f.endswith(".md"):
            continue
        text = open(os.path.join(root, f), encoding="utf-8").read()
        m = re.search(r"^tags:\s*\[(.*)\]\s*$", text, re.M)
        if not m:
            continue
        for raw in m.group(1).split(","):
            tag = raw.strip().strip("\"'")
            if not tag:
                continue
            segs = tag.split("/")               # 巢狀 tag 的每層前綴都要有頁面
            for i in range(1, len(segs) + 1):
                tags.add("/".join(segs[:i]))
tags.add("index")                              # tag 總覽頁
for tag in sorted(tags):
    path = f"content/tags/{tag}.md"
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "w", encoding="utf-8").write(f'---\ntitle: "{tag}"\nunlisted: true\n---\n')
print(f"  已產生 {len(tags)} 個 tag stub")
PY

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
