$cmd = ([Console]::In.ReadToEnd() | ConvertFrom-Json).tool_input.command
$bad = @('git\s+push.*([\s:]main(\s|$)|--force|\s-f\b)', 'git\s+branch\s+(?-i:-D)',
  'rm\s+-rf', 'Remove-Item.*-Recurse', 'DROP\s+TABLE', '(^|[^\w.])\.env\b(?!\.)',
  'appsettings\.Production\.json', 'web\.config') -join '|'
if ($cmd -match $bad) {
  [Console]::Error.WriteLine("Blocked by guard: '$($Matches[0])'. Ask a human.")
  exit 2 }
exit 0
