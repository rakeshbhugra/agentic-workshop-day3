#!/usr/bin/env bash
# Re-copies ../task-runner into this repo as task-runner/, in its reset state.
# The live ../task-runner folder is not touched: reset.sh runs on a temp copy.
set -euo pipefail
KIT=$(cd "$(dirname "$0")" && pwd)
SRC="$KIT/../task-runner"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
rsync -a --exclude .git --exclude runs --exclude .DS_Store "$SRC/" "$STAGE/"
bash "$STAGE/reset.sh"
rm -rf "$STAGE/runs/transcripts"
rsync -a --delete "$STAGE/" "$KIT/task-runner/"
echo "task-runner synced. Check with: git status task-runner"
