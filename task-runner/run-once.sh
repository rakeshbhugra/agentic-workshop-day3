#!/usr/bin/env bash
# One pass: pick up todo tasks, run them with Codex, save the transcript.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p runs/transcripts

# Nothing to do? Stop before spending any tokens.
if ! grep -qs '^status: todo' tasks/inbox/*.md; then
  echo "$(date '+%H:%M:%S') no todo tasks"; exit 0
fi

# Only one run at a time. mkdir fails if the lock is already there.
# A lock older than 30 min is left over from a killed run, so clear it.
find runs/.lock -maxdepth 0 -mmin +30 -exec rmdir {} \; 2>/dev/null || true
if ! mkdir runs/.lock 2>/dev/null; then
  echo "$(date '+%H:%M:%S') another run is still going, skipping"; exit 0
fi
trap 'rmdir runs/.lock' EXIT

stamp=$(date '+%Y%m%d-%H%M%S')
echo "$stamp starting run"
# Low reasoning and trimmed prompt. The task runner needs the shell and multi-agent
# tools only, so we switch off the skills, apps, plugins and memory instruction blocks.
# That shaves about 2,500 tokens off every model call.
codex exec -s workspace-write \
  -c model_reasoning_effort=low \
  -c skills.include_instructions=false -c skills.bundled.enabled=false \
  -c features.apps=false -c features.plugins=false -c features.memories=false \
  --json -o runs/last.md - \
  < orchestrator-prompt.md > "runs/transcripts/$stamp.jsonl"

# The helpers' own transcripts live in Codex's session folder. Copy them next to this run's.
thread=$(head -1 "runs/transcripts/$stamp.jsonl" | sed -n 's/.*"thread_id":"\([^"]*\)".*/\1/p')
if [ -n "$thread" ]; then
  mkdir -p "runs/transcripts/$stamp-helpers"
  find "${CODEX_HOME:-$HOME/.codex}/sessions" -name '*.jsonl' -newer runs/.lock \
    -exec grep -l "\"parent_thread_id\":\"$thread\"" {} + \
    | xargs -I{} cp {} "runs/transcripts/$stamp-helpers/" || true
fi
echo "$(date '+%H:%M:%S') finished. Transcripts: runs/transcripts/$stamp.jsonl and $stamp-helpers/"
