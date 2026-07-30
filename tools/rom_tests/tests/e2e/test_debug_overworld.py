"""Visual smoke coverage for the debug full-color overworld spawn."""

from pathlib import Path

from tools.rom_tests.emulator import Emulator
from tools.rom_tests.scenarios.debug_overworld import (
    enter_viridian_pokecenter,
    exercise_viridian_scrolling,
    start_debug_game_in_viridian,
)

SNAPSHOTS = Path(__file__).resolve().parents[2] / "snapshots"


def test_debug_full_color_overworld_scrolling(emulator: Emulator) -> None:
    start_debug_game_in_viridian(emulator)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-viridian-spawn.png",
        name="debug-viridian-spawn",
    )

    exercise_viridian_scrolling(emulator)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-viridian-scrolled.png",
        name="debug-viridian-scrolled",
    )


def test_debug_full_color_pokecenter(emulator: Emulator) -> None:
    start_debug_game_in_viridian(emulator)
    enter_viridian_pokecenter(emulator)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-viridian-pokecenter.png",
        name="debug-viridian-pokecenter",
    )
