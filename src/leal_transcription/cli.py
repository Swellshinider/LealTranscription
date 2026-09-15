"""Fast local audio transcription CLI, backed by faster-whisper + CUDA."""

import argparse
import importlib.util
import os
import sys
import time
from pathlib import Path

# ponytail: pip-installed nvidia-*-cu12 wheels put their DLLs under
# site-packages/nvidia/*/bin, which Windows never searches automatically —
# unlike Linux, where the wheels' RPATH makes them loadable as-is. ctranslate2's
# CUDA loader on Windows only honors PATH (os.add_dll_directory is not enough),
# so prepend those dirs to PATH before it needs them. Ceiling: only covers
# wheels named nvidia-*-cu12; a system-wide CUDA/cuDNN install needs no fix.
if sys.platform == "win32":
    _nvidia_spec = importlib.util.find_spec("nvidia")
    if _nvidia_spec and _nvidia_spec.submodule_search_locations:
        _bin_dirs = [
            str(p)
            for base in _nvidia_spec.submodule_search_locations
            for p in Path(base).glob("*/bin")
        ]
        os.environ["PATH"] = os.pathsep.join(_bin_dirs + [os.environ.get("PATH", "")])

from faster_whisper import WhisperModel

PRESETS = {"fast": "tiny", "balanced": "small", "best": "large-v3-turbo"}


def pick_model(quality: str, model_override: str | None) -> str:
    """Resolve the Whisper model name from --model (wins) or --quality preset."""
    if model_override:
        return model_override
    return PRESETS[quality]


def load_model(name: str, device: str) -> WhisperModel:
    """Load the model, falling back to CPU/int8 if CUDA is unavailable."""
    if device == "auto":
        try:
            return WhisperModel(name, device="cuda", compute_type="float16")
        except Exception as exc:
            print(
                f"warning: CUDA unavailable ({exc}); falling back to CPU (will be slower)",
                file=sys.stderr,
            )
            return WhisperModel(name, device="cpu", compute_type="int8")
    if device == "cuda":
        return WhisperModel(name, device="cuda", compute_type="float16")
    return WhisperModel(name, device="cpu", compute_type="int8")


def transcribe_file(model: WhisperModel, path: Path, language: str | None, quiet: bool) -> str:
    """Stream segments to stdout as they decode, return the full transcript."""
    segments, info = model.transcribe(str(path), language=language, vad_filter=True)
    lines: list[str] = []
    start = time.monotonic()
    for segment in segments:
        text = segment.text.strip()
        print(text)
        lines.append(text)
    elapsed = time.monotonic() - start
    if not lines:
        if not quiet:
            print(f"warning: empty transcript for {path}", file=sys.stderr)
    elif elapsed > 0 and not quiet:
        factor = info.duration / elapsed
        print(
            f"{info.duration:.1f}s audio in {elapsed:.1f}s ({factor:.1f}x realtime)",
            file=sys.stderr,
        )
    return " ".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(prog="transcribe", description=__doc__)
    parser.add_argument("files", nargs="+", metavar="FILE", help="audio/video file(s) to transcribe")
    parser.add_argument("-q", "--quality", choices=PRESETS, default="best")
    parser.add_argument("-m", "--model", help="raw Whisper model name, overrides --quality")
    parser.add_argument("-l", "--language", help="language code, e.g. en, pt (skips autodetect)")
    parser.add_argument("-c", "--copy", action="store_true", help="copy transcript to clipboard")
    parser.add_argument("-o", "--output", metavar="FILE", help="write transcript to file instead of stdout")
    parser.add_argument("--device", choices=["cuda", "cpu", "auto"], default="auto")
    parser.add_argument("--quiet", action="store_true", help="suppress the timing line on stderr")
    args = parser.parse_args()

    model_name = pick_model(args.quality, args.model)
    model = load_model(model_name, args.device)

    transcripts: list[str] = []
    had_error = False
    for file_arg in args.files:
        path = Path(file_arg)
        if not path.is_file():
            print(f"error: file not found: {path}", file=sys.stderr)
            had_error = True
            continue
        try:
            transcripts.append(transcribe_file(model, path, args.language, args.quiet))
        except Exception as exc:
            print(f"error: failed to transcribe {path}: {exc}", file=sys.stderr)
            had_error = True

    full_text = "\n".join(t for t in transcripts if t)

    if args.output:
        Path(args.output).write_text(full_text, encoding="utf-8")

    if args.copy and full_text:
        import pyperclip

        pyperclip.copy(full_text)

    sys.exit(1 if had_error else 0)


if __name__ == "__main__":
    main()
