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
$install = [scriptblock]::Create((Get-Content -Raw "$PSScriptRoot/../install.ps1"))
foreach ($failure in @('install', 'update-shell', 'uninstall')) {
    $script:calls = @()
    function uv {
        $script:calls += $args[1]
        $global:LASTEXITCODE = if ($args[1] -eq $failure) { 1 } else { 0 }
    }
    $caught = $false
    try {
        if ($failure -eq 'uninstall') { & $uninstall -RemoveModels }
        else { & $install }
    } catch {
        if ($_.Exception.Message -ne "uv tool $failure failed.") { throw }
        $caught = $true
    }
    if (-not $caught) { throw "Failure was ignored: $failure" }
    if ($failure -eq 'install' -and $script:calls.Count -ne 1) { throw 'Install continued after failure' }
    if ($script:scans -ne 1) { throw 'Failed uninstall must not clean models' }
}
Write-Host 'Script checks passed.'
