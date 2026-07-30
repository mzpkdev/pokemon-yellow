"""Visual smoke coverage for the debug full-color overworld spawn."""

from tools.rom_tests.emulator import Emulator
from tools.rom_tests.scenarios.debug_overworld import (
    exercise_viridian_scrolling,
    start_debug_game_in_viridian,
)


def test_debug_full_color_overworld_scrolling(emulator: Emulator) -> None:
    start_debug_game_in_viridian(emulator)
    emulator.save_screenshot("debug-viridian-spawn.png")

    exercise_viridian_scrolling(emulator)
    emulator.save_screenshot("debug-viridian-scrolled.png")
