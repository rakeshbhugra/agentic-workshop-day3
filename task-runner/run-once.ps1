# One pass: pick up todo tasks, run them with Codex, save the transcript.
# NOT RUN ON WINDOWS YET. Written to match run-once.sh, which was tested on a Mac.
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
New-Item -ItemType Directory -Force runs\transcripts | Out-Null

# Nothing to do? Stop before spending any tokens.
if (-not (Select-String -Path tasks\inbox\*.md -Pattern '^status: todo' -Quiet)) {
  Write-Host "$(Get-Date -Format HH:mm:ss) no todo tasks"; exit 0
}

# Only one run at a time. Creating the lock folder fails if it is already there.
# A lock older than 30 min is left over from a killed run, so clear it.
if ((Test-Path runs\.lock) -and ((Get-Item runs\.lock).CreationTime -lt (Get-Date).AddMinutes(-30))) {
  Remove-Item runs\.lock -Force
}
try { New-Item -ItemType Directory runs\.lock -ErrorAction Stop | Out-Null }
catch { Write-Host "$(Get-Date -Format HH:mm:ss) another run is still going, skipping"; exit 0 }

try {
  $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  Write-Host "$stamp starting run"
  Get-Content orchestrator-prompt.md -Raw |
    codex exec -s workspace-write `
      -c model_reasoning_effort=low `
      -c skills.include_instructions=false -c skills.bundled.enabled=false `
      -c features.apps=false -c features.plugins=false -c features.memories=false `
      --json -o runs\last.md - |
    Out-File -Encoding utf8 "runs\transcripts\$stamp.jsonl"

  # The helpers' own transcripts live in Codex's session folder. Copy them next to this run's.
  $first = Get-Content "runs\transcripts\$stamp.jsonl" -TotalCount 1
  if ($first -match '"thread_id":"([^"]+)"') {
    $thread = $Matches[1]
    $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { "$env:USERPROFILE\.codex" }
    $dest = New-Item -ItemType Directory -Force "runs\transcripts\$stamp-helpers"
    $started = (Get-Item runs\.lock).CreationTime
    Get-ChildItem -Recurse -Filter *.jsonl "$codexHome\sessions" |
      Where-Object { $_.LastWriteTime -gt $started } |
      Select-String -SimpleMatch -List ('"parent_thread_id":"' + $thread + '"') |
      ForEach-Object { Copy-Item $_.Path $dest }
  }
  Write-Host "$(Get-Date -Format HH:mm:ss) finished. Transcripts: runs\transcripts\$stamp.jsonl and $stamp-helpers\"
}
finally { Remove-Item runs\.lock -Force }
