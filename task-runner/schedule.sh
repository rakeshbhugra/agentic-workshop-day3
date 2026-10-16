#!/usr/bin/env bash
# Mac / Linux. Usage:
#   ./schedule.sh install [minutes]   add a cron job (default every 15 min)
#   ./schedule.sh remove              remove that cron job
#   ./schedule.sh watch               for class: run now, then every 2 min (Ctrl+C stops)
#   ./schedule.sh board               show runs/board.md, refreshed every 5 s
set -euo pipefail
dir="$(cd "$(dirname "$0")" && pwd)"
tag="# codex-task-runner $dir"

case "${1:-}" in
  install)
    mins="${2:-15}"
    # cron has a tiny PATH, so pass ours in. Output goes to runs/cron.log.
    line="*/$mins * * * * PATH=\"$PATH\" \"$dir/run-once.sh\" >> \"$dir/runs/cron.log\" 2>&1 $tag"
    ( crontab -l 2>/dev/null | grep -vF "$tag" || true; echo "$line" ) | crontab -
    echo "Installed. Runs every $mins min. Check: crontab -l" ;;
  remove)
    ( crontab -l 2>/dev/null | grep -vF "$tag" || true ) | crontab -
    echo "Removed." ;;
  watch)
    while true; do "$dir/run-once.sh"; sleep 120; done ;;
  board)
    while true; do clear; cat "$dir/runs/board.md"; sleep 5; done ;;
  *) sed -n '2,6p' "$0"; exit 1 ;;
esac
