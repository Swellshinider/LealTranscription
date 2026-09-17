# Leal Transcription

Fast local audio transcription CLI for Windows, backed by
[faster-whisper](https://github.com/SYSTRAN/faster-whisper) with CUDA acceleration
(falls back to CPU automatically if no compatible GPU is found).

Transcribe one or more audio/video files, choose a model or quality preset, and
print the result, save it as UTF-8 text, or copy it to the clipboard. Audio is
processed locally; installation and the first use of a model require downloads.

## Requirements

- Windows x64 with PowerShell 5.1 or later and [Git](https://git-scm.com/downloads/win) on PATH.
- Python 3.11 or later (`uv` can download a compatible Python when needed).
- Internet access for package installation and model downloads, plus disk space
  for the Python environment, bundled NVIDIA libraries, and models.
- Optional: an NVIDIA GPU with a CUDA 12-compatible driver. Use `--device cpu`
  to explicitly run on the CPU; the same installation includes NVIDIA libraries.

The installer and CI target Windows. Other operating systems are not currently
validated by this project.

## Install

Run in PowerShell:

```powershell
irm https://raw.githubusercontent.com/Swellshinider/LealTranscription/main/install.ps1 | iex
```

This installs [uv](https://astral.sh/uv) if needed, then installs the `lt` command
via `uv tool install`. Open a **new** terminal afterwards so PATH picks it up.
Re-running the command later updates `lt` to the latest version.

The command downloads and executes [install.ps1](install.ps1) from `main`.
To inspect the source and run the installer from a local checkout instead:

```powershell
git clone https://github.com/Swellshinider/LealTranscription.git
cd LealTranscription
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

The installer still fetches the package from GitHub. To install your local
changes, use the development setup in [CONTRIBUTING.md](CONTRIBUTING.md).

## Usage

```powershell
lt "audio.wav" --copy
lt "meeting.mp4" -l en -o "transcript.txt"
lt "first.wav" "second.wav" --device cpu -q fast
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

Quality presets map to `tiny` (`fast`), `small` (`balanced`), and
`large-v3-turbo` (`best`). Language detection is automatic unless `-l` is set.
Use `lt --help` for the CLI reference.

`-o` replaces the destination file when at least one input transcribes
successfully. When some inputs fail, successful transcripts are still written
and the command exits with status 1. Review generated text for accuracy.

## Troubleshooting

- **Installer URL returns 404:** confirm the repository is public and the URL
  names the correct owner and branch. Private repositories require authenticated
  access; run the installer from an authenticated local clone in that case.
- **`lt` is not found:** open a new terminal after installation. If needed, run
  `uv tool update-shell` and restart the terminal again.
- **CUDA is unavailable:** update your NVIDIA driver or use `--device cpu`.
  With `--device auto`, model loading retries on the CPU if CUDA loading fails.
- **First run is slow:** the model must download before transcription starts.
  Use `-q fast` for a smaller model, or `-m` with a local model directory for
  an already downloaded compatible model.

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

## Contributing and support

- [Contributing](CONTRIBUTING.md): development setup and validation commands.
- [Support](SUPPORT.md): questions, bugs, and feature requests.
- [Security](SECURITY.md): private vulnerability reporting.
- [Code of conduct](CODE_OF_CONDUCT.md): community expectations.

## License

Leal Transcription is licensed under the [MIT License](LICENSE).
Dependencies and downloaded models retain their own licenses.
