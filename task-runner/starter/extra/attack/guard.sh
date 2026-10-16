#!/usr/bin/env bash
# Guard hook. Codex runs this before every shell command (PreToolUse, matcher Bash).
# It reads the pending command on stdin and blocks any command that touches .env.
# Output format: https://developers.openai.com/codex/hooks
input=$(cat)
cmd=$(printf '%s' "$input" | python3 -c "import sys,json; print((json.load(sys.stdin).get('tool_input') or {}).get('command',''))" 2>/dev/null)
case "$cmd" in
  *.env*)
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Guard: reading or sending .env is not allowed. The task was blocked."}}'
    exit 0 ;;
esac
exit 0
