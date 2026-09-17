#Requires -Version 5.1
# Removes the `lt` CLI, keeping shared HuggingFace models by default.
# Usage: irm https://raw.githubusercontent.com/Swellshinider/LealTranscription/main/uninstall.ps1 | iex
# With -RemoveModels: & ([scriptblock]::Create((irm <url>))) -RemoveModels
param([switch]$RemoveModels, [switch]$KeepModels)
$ErrorActionPreference = 'Stop'

uv tool uninstall leal-transcription
if ($LASTEXITCODE -ne 0) { throw 'uv tool uninstall failed.' }

if ($RemoveModels -and -not $KeepModels) {
    $cacheRoot = if ($env:XDG_CACHE_HOME) { $env:XDG_CACHE_HOME } else { "$env:USERPROFILE\.cache" }
    $hfHome = if ($env:HF_HOME) { $env:HF_HOME } else { Join-Path $cacheRoot 'huggingface' }
    $hub = if ($env:HF_HUB_CACHE) { $env:HF_HUB_CACHE }
        elseif ($env:HUGGINGFACE_HUB_CACHE) { $env:HUGGINGFACE_HUB_CACHE }
        else { Join-Path $hfHome 'hub' }
    if ($hub -match '^~([\\/]|$)') { $hub = $env:USERPROFILE + $hub.Substring(1) }
    $hub = [Environment]::ExpandEnvironmentVariables($hub)
    $hub = [regex]::Replace($hub, '\$(?:\{(?<name>\w+)\}|(?<name>\w+))', {
        param($match)
        $value = [Environment]::GetEnvironmentVariable($match.Groups['name'].Value)
        if ($null -eq $value) { $match.Value } else { $value }
    })
    $hub = [IO.Path]::GetFullPath($hub)
    Get-ChildItem -LiteralPath $hub -Directory -Filter 'models--*faster-whisper*' -ErrorAction SilentlyContinue |
        ForEach-Object {
            if ($_.Parent.FullName.TrimEnd('\') -ne $hub.TrimEnd('\')) { throw 'Model is outside the cache.' }
            Write-Host "Removing $($_.FullName)"
            Remove-Item -LiteralPath $_.FullName -Recurse -Force
        }
}

Write-Host 'Done.'
