#!/usr/bin/env bash
# Put the kit back to the starting state. Deletes all runs and app changes.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf app tasks runs
mkdir -p tasks/done runs/transcripts
cp -R starter/app app
cp -R starter/tasks tasks/inbox
cp starter/board.md runs/board.md
echo "Reset done: 3 tasks in tasks/inbox, empty board."
