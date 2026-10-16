# Windows. NOT RUN ON WINDOWS YET (written carefully, tested only the Mac version).
# Usage:
#   .\schedule.ps1 install            every 15 min for the next 8 hours
#   .\schedule.ps1 install -Minutes 10
#   .\schedule.ps1 install -At 02:00  once a day at 2 am
#   .\schedule.ps1 remove             stop and delete the scheduled task
#   .\schedule.ps1 watch              for class: run now, then every 2 min (Ctrl+C stops)
#   .\schedule.ps1 board              show runs\board.md, refreshed every 5 s
param(
  [Parameter(Position = 0)][ValidateSet("install", "remove", "watch", "board")][string]$Command = "install",
  [int]$Minutes = 15,
  [string]$At = ""
)
$ErrorActionPreference = "Stop"
$name = "Codex task runner"

switch ($Command) {
  "install" {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" `
      -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\run-once.ps1`"" `
      -WorkingDirectory $PSScriptRoot
    if ($At) {
      $trigger = New-ScheduledTaskTrigger -Daily -At $At
    } else {
      $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
        -RepetitionInterval (New-TimeSpan -Minutes $Minutes) `
        -RepetitionDuration (New-TimeSpan -Hours 8)
    }
    # Kill a run that takes longer than 20 minutes. Never start a second copy.
    $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 20) `
      -MultipleInstances IgnoreNew -StartWhenAvailable
    Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
    Write-Host "Installed '$name'. Check: Get-ScheduledTask -TaskName '$name'"
  }
  "remove" {
    Stop-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $name -Confirm:$false
    Write-Host "Removed '$name'."
  }
  "watch" {
    while ($true) { & "$PSScriptRoot\run-once.ps1"; Start-Sleep -Seconds 120 }
  }
  "board" {
    while ($true) { Clear-Host; Get-Content "$PSScriptRoot\runs\board.md"; Start-Sleep -Seconds 5 }
  }
}
