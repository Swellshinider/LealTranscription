# Run with: powershell -NoProfile -ExecutionPolicy Bypass -File tests/test_scripts.ps1
$ErrorActionPreference = 'Stop'
$uninstall = [scriptblock]::Create((Get-Content -Raw "$PSScriptRoot/../uninstall.ps1"))
$script:scans = 0
function uv { $global:LASTEXITCODE = 0 }
function Get-ChildItem { $script:scans++ }
function Remove-Item { throw 'Tests must never delete files' }
& $uninstall
if ($script:scans -ne 0) { throw 'Default uninstall must preserve shared models' }
& $uninstall -RemoveModels
if ($script:scans -ne 1) { throw 'Explicit cleanup must scan the cache' }
& $uninstall -RemoveModels -KeepModels
if ($script:scans -ne 1) { throw 'KeepModels must override cleanup' }
Write-Host 'Script checks passed.'
