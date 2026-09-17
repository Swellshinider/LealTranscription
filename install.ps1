#Requires -Version 5.1
# Installs the `lt` transcription CLI via uv (https://astral.sh/uv).
# Usage: irm https://raw.githubusercontent.com/Swellshinider/LealTranscription/main/install.ps1 | iex
$ErrorActionPreference = 'Stop'

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing uv...'
    irm https://astral.sh/uv/install.ps1 | iex
    $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
}

uv tool install --force git+https://github.com/Swellshinider/LealTranscription.git
uv tool update-shell

Write-Host 'Done. Open a new terminal, then: lt "audio.wav" --copy'
