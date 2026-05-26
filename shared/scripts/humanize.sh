#!/usr/bin/env bash
# Humanize 监控小工具：在外部终端 source 后使用 `humanize monitor rlcr`
# 用法：source ~/.trae/skills/humanize-shared/scripts/humanize.sh

humanize() {
  local cmd="${1:-help}"
  shift || true
  case "$cmd" in
    monitor)
      local target="${1:-rlcr}"
      local dir=".humanize/$target"
      if [[ ! -d "$dir" ]]; then
        echo "❌ $dir 不存在，先在该项目根目录运行 humanize-rlcr-implement 或 init.sh"
        return 1
      fi
      echo "👀 监控 $dir/round-*/{summary,review}.md  (Ctrl-C 退出)"
      while true; do
        clear
        for f in $(ls -t "$dir"/round-*/*.md 2>/dev/null | head -4); do
          echo "═══ $f ═══"
          tail -n 20 "$f"
          echo
        done
        sleep 3
      done
      ;;
    status)
      if [[ -f .humanize/config.json ]]; then
        cat .humanize/config.json
      else
        echo "未在 humanize 项目下"
      fi
      ;;
    help|*)
      cat <<USAGE
humanize <command>

  monitor rlcr   实时跟踪 .humanize/rlcr/round-*/ 下的 summary/review
  status         查看本项目 humanize 配置
  help           本帮助
USAGE
      ;;
  esac
}
