#!/usr/bin/env bash
# PreToolUse hook: blocks reading .env files and force-deleting git branches.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
if printf '%s' "$cmd" | grep -Eq '(^|[^A-Za-z0-9_.])\.env($|[[:space:]"'"'"'/;|&<>)])'; then
  echo "Blocked by hook: reading .env files is not allowed." >&2
  exit 2
fi
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+branch[[:space:]]+(-D|--delete[[:space:]]+--force)'; then
  echo "Blocked by hook: git branch -D is not allowed. Use git branch -d." >&2
  exit 2
fi
exit 0
