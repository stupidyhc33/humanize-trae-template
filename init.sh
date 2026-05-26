#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-.}"
PRESET="${2:-generic}"
SHARED_DIR="$HOME/.trae/skills/humanize-shared"
TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -d "$SHARED_DIR" ]]; then
  echo "⚠️  全局共享资产缺失，正在自动安装…"
  bash "$TEMPLATE_DIR/install-global.sh"
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
mkdir -p "$PROJECT_DIR/.humanize/ideas"
mkdir -p "$PROJECT_DIR/.humanize/rlcr"
mkdir -p "$PROJECT_DIR/docs"

if [[ -f "$SHARED_DIR/templates/plan.md" ]]; then
  cp "$SHARED_DIR/templates/plan.md" "$PROJECT_DIR/docs/plan.template.md"
fi

if [[ -d "$TEMPLATE_DIR/presets/$PRESET" ]]; then
  cp -r "$TEMPLATE_DIR/presets/$PRESET/." "$PROJECT_DIR/" 2>/dev/null || true
fi

cat > "$PROJECT_DIR/.humanize/config.json" <<JSON
{
  "preset": "$PRESET",
  "review_model": "gpt-5.5",
  "alternative_plan_language": "zh-CN",
  "max_rounds": 5
}
JSON

cat > "$PROJECT_DIR/.humanize/README.md" <<MD
# Humanize 工作流已就位

预设：$PRESET

下一步在 Trae 对话中调用：
- humanize-gen-idea "你的想法"
- humanize-gen-plan --input .humanize/ideas/xxx.md --output docs/plan.md
- humanize-refine-plan --input docs/plan.md
- humanize-rlcr-implement docs/plan.md

监控（外部终端）：
  source $SHARED_DIR/scripts/humanize.sh
  humanize monitor rlcr
MD

echo "✅ Humanize 工作流已初始化于 $PROJECT_DIR（preset=$PRESET）"
