#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"

# 自动探测 Trae skill 根目录：~/.trae-cn/skills（CN 版优先）→ ~/.trae/skills（海外版）
detect_skill_root() {
  if [[ -n "${TRAE_SKILLS_DIR:-}" ]]; then
    echo "$TRAE_SKILLS_DIR"; return
  fi
  if [[ -d "$HOME/.trae-cn/skills" ]]; then
    echo "$HOME/.trae-cn/skills"; return
  fi
  if [[ -d "$HOME/.trae/skills" ]]; then
    echo "$HOME/.trae/skills"; return
  fi
  if [[ -d "$HOME/.trae-cn" ]]; then
    mkdir -p "$HOME/.trae-cn/skills"
    echo "$HOME/.trae-cn/skills"; return
  fi
  mkdir -p "$HOME/.trae/skills"
  echo "$HOME/.trae/skills"
}

DEST="$(detect_skill_root)"
echo "📍 检测到 Trae skill 目录：$DEST"

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

如需指定其它目录：
  TRAE_SKILLS_DIR=/custom/path bash install-global.sh
EOM
