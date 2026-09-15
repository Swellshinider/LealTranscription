from types import SimpleNamespace
from unittest.mock import Mock

import pytest

from leal_transcription import cli
from leal_transcription.cli import PRESETS, pick_model


def test_pick_model_uses_preset():
    assert pick_model("fast", None) == PRESETS["fast"]
    assert pick_model("best", None) == "large-v3-turbo"


def test_pick_model_override_wins():
    assert pick_model("best", "tiny.en") == "tiny.en"


@pytest.mark.parametrize("failure", ["missing", "decode"])
def test_failed_inputs_preserve_output(tmp_path, monkeypatch, failure):
    source = tmp_path / "audio.wav"
    if failure == "decode":
        source.touch()
    output = tmp_path / "transcript.txt"
    output.write_text("existing transcript", encoding="utf-8")
    model = Mock()
    model.transcribe.side_effect = RuntimeError("invalid audio")
    monkeypatch.setattr(cli, "load_model", lambda *args: model)
    monkeypatch.setattr("sys.argv", ["transcribe", str(source), "-o", str(output)])

    with pytest.raises(SystemExit) as exc:
        cli.main()

    assert exc.value.code == 1
    assert output.read_text(encoding="utf-8") == "existing transcript"


@pytest.mark.parametrize("to_file", [False, True])
def test_transcript_output_destination(tmp_path, monkeypatch, capsys, to_file):
    source = tmp_path / "audio.wav"
    source.touch()
    output = tmp_path / "transcript.txt"
    model = Mock()
    model.transcribe.return_value = (
        iter([SimpleNamespace(text=" hello ")]), SimpleNamespace(duration=10)
    )
    monkeypatch.setattr(cli, "load_model", lambda *args: model)
    argv = ["transcribe", str(source), "--quiet"]
    if to_file:
        argv.extend(["-o", str(output)])
    monkeypatch.setattr("sys.argv", argv)

    with pytest.raises(SystemExit) as exc:
        cli.main()

    assert exc.value.code == 0
    assert capsys.readouterr().out == ("" if to_file else "hello\n")
    if to_file:
        assert output.read_text(encoding="utf-8") == "hello"


def test_timing_includes_transcribe_call(tmp_path, monkeypatch, capsys):
    clock = [0]

    def transcribe(*args, **kwargs):
        clock[0] += 9

        def segments():
            clock[0] += 1
            yield SimpleNamespace(text="hello")

        return segments(), SimpleNamespace(duration=10)

    monkeypatch.setattr(cli.time, "monotonic", lambda: clock[0])
    model = SimpleNamespace(transcribe=transcribe)
    assert cli.transcribe_file(model, tmp_path / "audio.wav", None, False) == "hello"
    assert "10.0s audio in 10.0s (1.0x realtime)" in capsys.readouterr().err
