#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.trae/skills"

mkdir -p "$DEST"

for d in "$REPO/skills"/*/; do
  name="$(basename "$d")"
  mkdir -p "$DEST/$name"
  cp -r "$d." "$DEST/$name/"
done

rm -rf "$DEST/humanize-shared"
mkdir -p "$DEST/humanize-shared"
cp -r "$REPO/shared/." "$DEST/humanize-shared/"

cat <<EOM
✅ 全局 Humanize Skill 已安装至 $DEST
   - skills: $(ls "$REPO/skills" | tr '\n' ' ')
   - shared: $DEST/humanize-shared

启用监控（写入 ~/.zshrc 或 ~/.bashrc）：
  source $DEST/humanize-shared/scripts/humanize.sh
EOM
