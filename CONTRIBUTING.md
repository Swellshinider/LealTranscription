# Contributing

Keep changes focused and follow the existing Python and PowerShell patterns.
For a substantial change, open an issue to discuss the approach first.

## Development setup

Use Windows x64, Git, PowerShell 5.1 or later, and
[uv](https://docs.astral.sh/uv/getting-started/installation/).
Development and CI use Python 3.13, as recorded in `.python-version`.

```powershell
git clone https://github.com/Swellshinider/LealTranscription.git
cd LealTranscription
uv sync --locked
uv run --locked lt --help
```

`uv` installs the project in editable mode, so `uv run lt` uses your source
changes. Installation downloads the runtime dependencies, including NVIDIA
libraries. The automated tests mock transcription and do not require a GPU or
download models.

## Validation

Run these checks before submitting a pull request:

```powershell
uv run --locked pytest -q
powershell -NoProfile -ExecutionPolicy Bypass -File tests/test_scripts.ps1
uv build
```

For changes to transcription, also test with your own non-sensitive audio:

```powershell
uv run --locked lt "sample.wav" --device cpu -q fast
```

Test CUDA behavior on compatible hardware when changing GPU support. Do not
commit recordings, transcripts, model files, credentials, or private logs.
Keep local recordings and transcripts outside the checkout.

## Pull requests

1. Create a focused branch from `main`.
2. Make the smallest complete change and add a regression check for changed logic.
3. Update docs when commands or behavior change.
4. Describe the problem, change, related issue, and checks actually run.

Use `uv` for dependency changes and include the corresponding `uv.lock` update.
CI runs the Python tests, PowerShell checks, and package build on Windows.
Report vulnerabilities privately through [SECURITY.md](SECURITY.md).
