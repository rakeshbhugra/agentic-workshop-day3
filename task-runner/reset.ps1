# Put the kit back to the starting state. Deletes all runs and app changes.
# NOT RUN ON WINDOWS YET. Written to match reset.sh, which was tested on a Mac.
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
Remove-Item -Recurse -Force app, tasks, runs -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force tasks\done, runs\transcripts | Out-Null
Copy-Item -Recurse starter\app app
Copy-Item -Recurse starter\tasks tasks\inbox
Copy-Item starter\board.md runs\board.md
Write-Host "Reset done: 3 tasks in tasks/inbox, empty board."
