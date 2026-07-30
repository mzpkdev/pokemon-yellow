"""Visual smoke coverage for the debug full-color overworld spawn."""

from pathlib import Path

from tools.rom_tests.emulator import Emulator
from tools.rom_tests.scenarios.debug_overworld import (
    enter_viridian_pokecenter,
    exercise_viridian_scrolling,
    mount_bicycle_with_select,
    start_debug_game_in_viridian,
    walk_west_to_route_22,
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


def test_debug_full_color_survives_start_menu(emulator: Emulator) -> None:
    start_debug_game_in_viridian(emulator)
    emulator.press("start")
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-viridian-start-menu.png",
        name="debug-viridian-start-menu",
    )
    emulator.press("b")
    emulator.tick(180)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-viridian-spawn.png",
        name="debug-viridian-after-menu",
    )


def test_debug_full_color_connected_route(emulator: Emulator) -> None:
    start_debug_game_in_viridian(emulator)
    walk_west_to_route_22(emulator)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-route-22.png",
        name="debug-route-22",
    )


def test_debug_full_color_bicycle_shortcut(emulator: Emulator) -> None:
    start_debug_game_in_viridian(emulator)
    mount_bicycle_with_select(emulator)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-viridian-bicycle.png",
        name="debug-viridian-bicycle",
    )
