# Leal Transcription

Fast local audio transcription CLI for Windows, backed by
[faster-whisper](https://github.com/SYSTRAN/faster-whisper) with CUDA acceleration
(falls back to CPU automatically if no compatible GPU is found).

## Install

Run in PowerShell:

```powershell
irm https://raw.githubusercontent.com/Swellshinider/LealTranscription/main/install.ps1 | iex
```

This installs [uv](https://astral.sh/uv) if needed, then installs the `lt` command
via `uv tool install`. Open a **new** terminal afterwards so PATH picks it up.
Re-running the command later updates `lt` to the latest version.

## Usage

```powershell
lt "audio.wav" --copy
```

The first run downloads the selected model (`large-v3-turbo` by default, ~1.6 GB)
into the HuggingFace cache; later runs reuse it.

| Flag | Description |
| --- | --- |
| `-q, --quality {fast,balanced,best}` | Preset model size (default: `best`) |
| `-m, --model NAME` | Raw Whisper model name, overrides `--quality` |
| `-l, --language CODE` | Language code (e.g. `en`, `pt`), skips autodetect |
| `-c, --copy` | Copy transcript to clipboard |
| `-o, --output FILE` | Write transcript to a file instead of stdout |
| `--device {cuda,cpu,auto}` | Force a device (default: `auto`) |
| `--quiet` | Suppress the timing line on stderr |

## Uninstall

```powershell
irm https://raw.githubusercontent.com/Swellshinider/LealTranscription/main/uninstall.ps1 | iex
```

Removes the `lt` command and keeps downloaded models. To also delete all
faster-whisper models in the shared HuggingFace cache (including models used by
other applications), explicitly pass `-RemoveModels`:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Swellshinider/LealTranscription/main/uninstall.ps1))) -RemoveModels
```

`-KeepModels` remains supported and overrides `-RemoveModels`.
Cleanup honors `HF_HUB_CACHE`, `HUGGINGFACE_HUB_CACHE`, `HF_HOME`, and
`XDG_CACHE_HOME`, in that order, before using the default cache.

`uv` itself is left installed, since it's a general-purpose tool manager you may use
for other projects.
