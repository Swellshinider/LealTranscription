from leal_transcription.cli import PRESETS, pick_model


def test_pick_model_uses_preset():
    assert pick_model("fast", None) == PRESETS["fast"]
    assert pick_model("best", None) == "large-v3-turbo"


def test_pick_model_override_wins():
    assert pick_model("best", "tiny.en") == "tiny.en"
