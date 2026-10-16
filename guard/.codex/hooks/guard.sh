#!/usr/bin/env bash
# PreToolUse guard (Mac/Linux): blocks secret reads and destructive commands. Exit 2 = block.
cmd=$(jq -r '.tool_input.command // ""')
bad='git[[:space:]]+push.*([[:space:]](main|master)\b|--force|[[:space:]]-f\b)|rm[[:space:]]+-(rf|fr)|Remove-Item.*-Recurse|DROP[[:space:]]+TABLE|(^|[^A-Za-z0-9_.])\.env($|[[:space:]"'"'"'/;|&<>)])|appsettings\.Production\.json|web\.config'
if printf '%s' "$cmd" | grep -Eiq "$bad" || printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+branch[[:space:]]+-D'; then
  echo "Blocked by guard: this command can leak secrets or destroy work. Ask a human." >&2
  exit 2
fi
exit 0
