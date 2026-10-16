# Guard hook for Windows. NOT RUN ON WINDOWS YET (the .sh version was tested on a Mac).
# Codex runs this before every shell command. It blocks any command that touches .env.
$raw = [Console]::In.ReadToEnd()
try { $cmd = ($raw | ConvertFrom-Json).tool_input.command } catch { $cmd = "" }
if ($cmd -like "*.env*") {
  Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Guard: reading or sending .env is not allowed. The task was blocked."}}'
}
exit 0
