"""Compatibility entry point; implementation belongs to xplayer_player."""
from pathlib import Path
import runpy

runpy.run_path(str(Path(__file__).resolve().parent.parent / "packages/xplayer_player/tool/generate_playback_fixtures.py"), run_name="__main__")
