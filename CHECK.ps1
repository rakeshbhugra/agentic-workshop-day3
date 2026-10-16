# Day 3 pre-flight check. Run from C:\workshop\day3 with:  .\CHECK.ps1
$allOk = $true
function Show($ok, $name, $msg, $optional = $false) {
    if ($ok) { Write-Host ("OK    {0,-8} {1}" -f $name, $msg) -ForegroundColor Green }
    elseif ($optional) { Write-Host ("SKIP  {0,-8} optional. To add it: {1}" -f $name, $msg) -ForegroundColor Yellow }
    else { Write-Host ("FIX   {0,-8} {1}" -f $name, $msg) -ForegroundColor Red; $script:allOk = $false }
}
function Version($cmd, $arg = '--version') {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { return $null }
    try { return ((& $cmd $arg 2>&1) | Select-Object -First 1).ToString().Trim() } catch { return $null }
}

$v = Version codex
Show ($null -ne $v) 'codex' $(if ($v) { $v } else { 'npm install -g @openai/codex   then: codex login' })

$v = Version git
Show ($null -ne $v) 'git' $(if ($v) { $v } else { 'winget install --id Git.Git -e' })

$sdks = if (Get-Command dotnet -ErrorAction SilentlyContinue) { dotnet --list-sdks 2>$null } else { @() }
$has8 = @($sdks | Where-Object { $_ -match '^([89]|\d\d)\.' }).Count -gt 0
Show $has8 'dotnet' $(if ($has8) { 'SDK ' + (($sdks | Select-Object -Last 1) -split ' ')[0] } else { 'winget install --id Microsoft.DotNet.SDK.8 -e' })

$v = Version node
Show ($null -ne $v) 'node' $(if ($v) { $v } else { 'winget install --id OpenJS.NodeJS.LTS -e' })

$v = Version docker
Show ($null -ne $v) 'docker' $(if ($v) { $v } else { 'winget install --id Docker.DockerDesktop -e' }) $true

$here = $PSScriptRoot
Show ($here -eq 'C:\workshop\day3') 'folder' $(if ($here -eq 'C:\workshop\day3') { $here } else { "kit is in $here. Unzip it to C:\workshop\day3 instead." })

Write-Host ''
if ($allOk) { Write-Host 'ALL OK. You are ready for Day 3.' -ForegroundColor Green }
else { Write-Host 'Fix the red lines. Open a NEW PowerShell window after any install. Then run .\CHECK.ps1 again.' -ForegroundColor Red }
