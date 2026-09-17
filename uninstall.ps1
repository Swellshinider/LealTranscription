#Requires -Version 5.1
# Removes the `lt` CLI and, unless -KeepModels is passed, its downloaded
# faster-whisper models from the HuggingFace cache.
# Usage: irm https://raw.githubusercontent.com/Swellshinider/LealTranscription/main/uninstall.ps1 | iex
# With -KeepModels: & ([scriptblock]::Create((irm <url>))) -KeepModels
param([switch]$KeepModels)
$ErrorActionPreference = 'Stop'

uv tool uninstall leal-transcription

if (-not $KeepModels) {
    $hfHome = if ($env:HF_HOME) { $env:HF_HOME } else { "$env:USERPROFILE\.cache\huggingface" }
    $hub = Join-Path $hfHome 'hub'
    Get-ChildItem $hub -Directory -Filter 'models--*faster-whisper*' -ErrorAction SilentlyContinue |
        ForEach-Object { Write-Host "Removing $($_.FullName)"; Remove-Item $_.FullName -Recurse -Force }
}

Write-Host 'Done.'
