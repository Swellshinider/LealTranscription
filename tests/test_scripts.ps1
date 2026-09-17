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
function uv { $global:LASTEXITCODE = 0 }
function Get-ChildItem { param($LiteralPath) $script:cachePath = $LiteralPath }
$cacheVariables = @('HF_HUB_CACHE', 'HUGGINGFACE_HUB_CACHE', 'HF_HOME', 'XDG_CACHE_HOME')
$saved = @{}
foreach ($name in $cacheVariables) {
    $saved[$name] = [Environment]::GetEnvironmentVariable($name)
    [Environment]::SetEnvironmentVariable($name, $null)
}
try {
    & $uninstall -RemoveModels
    if ($script:cachePath -ne "$env:USERPROFILE\.cache\huggingface\hub") { throw 'Wrong default cache' }
    foreach ($case in @(
        @('XDG_CACHE_HOME', 'C:\test-cache', 'C:\test-cache\huggingface\hub'),
        @('HF_HOME', 'C:\test-hf', 'C:\test-hf\hub'),
        @('HUGGINGFACE_HUB_CACHE', 'C:\test-legacy', 'C:\test-legacy'),
        @('HF_HUB_CACHE', 'C:\test-hub', 'C:\test-hub'),
        @('HF_HUB_CACHE', '~\test-hub', "$env:USERPROFILE\test-hub"),
        @('HF_HUB_CACHE', '%USERPROFILE%\test-hub', "$env:USERPROFILE\test-hub"),
        @('HF_HUB_CACHE', '${USERPROFILE}\test-hub', "$env:USERPROFILE\test-hub")
    )) {
        [Environment]::SetEnvironmentVariable($case[0], $case[1])
        & $uninstall -RemoveModels
        if ($script:cachePath -ne $case[2]) { throw "Wrong cache precedence or expansion: $($case[0])" }
    }
} finally {
    foreach ($name in $cacheVariables) { [Environment]::SetEnvironmentVariable($name, $saved[$name]) }
}
Write-Host 'Script checks passed.'
