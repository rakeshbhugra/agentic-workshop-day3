# Codex PreToolUse hook (Windows). Blocks reading .env files and git branch -D.
$raw = [Console]::In.ReadToEnd()
$cmd = ($raw | ConvertFrom-Json).tool_input.command
if ($cmd -match '(^|[^\w.])\.env($|[\s"''/\;|&<>)])') {
  [Console]::Error.WriteLine('Blocked by hook: reading .env files is not allowed.')
  exit 2
}
if ($cmd -match 'git\s+branch\s+(-D|--delete\s+--force)') {
  [Console]::Error.WriteLine('Blocked by hook: git branch -D is not allowed. Use git branch -d.')
  exit 2
}
exit 0
