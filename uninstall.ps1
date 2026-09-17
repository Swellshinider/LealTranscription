#Requires -Version 5.1
# Removes the `lt` CLI, keeping shared HuggingFace models by default.
# Usage: irm https://raw.githubusercontent.com/Swellshinider/LealTranscription/main/uninstall.ps1 | iex
# With -RemoveModels: & ([scriptblock]::Create((irm <url>))) -RemoveModels
param([switch]$RemoveModels, [switch]$KeepModels)
$ErrorActionPreference = 'Stop'

uv tool uninstall leal-transcription
if ($LASTEXITCODE -ne 0) { throw 'uv tool uninstall failed.' }

if ($RemoveModels -and -not $KeepModels) {
    $hfHome = if ($env:HF_HOME) { $env:HF_HOME } else { "$env:USERPROFILE\.cache\huggingface" }
    $hub = Join-Path $hfHome 'hub'
    Get-ChildItem $hub -Directory -Filter 'models--*faster-whisper*' -ErrorAction SilentlyContinue |
        ForEach-Object { Write-Host "Removing $($_.FullName)"; Remove-Item $_.FullName -Recurse -Force }
}

Write-Host 'Done.'
