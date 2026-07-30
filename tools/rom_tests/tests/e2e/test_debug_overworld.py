"""Visual smoke coverage for the debug full-color overworld spawn."""

from pathlib import Path

from tools.rom_tests.emulator import Emulator
from tools.rom_tests.scenarios.debug_overworld import (
    dismount_bicycle_with_select,
    enter_viridian_pokecenter,
    exercise_viridian_scrolling,
    mount_bicycle_with_select,
    open_viridian_pokecenter_sign,
    ride_bicycle_in_viridian,
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
    emulator.press("start")
    emulator.tick(180)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-viridian-after-start-menu.png",
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
        SNAPSHOTS / "debug-viridian-bicycle-mounted.png",
        name="debug-viridian-bicycle-mounted",
    )

    ride_bicycle_in_viridian(emulator)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-viridian-bicycle-ridden.png",
        name="debug-viridian-bicycle-ridden",
    )

    dismount_bicycle_with_select(emulator)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-viridian-bicycle-dismounted.png",
        name="debug-viridian-bicycle-dismounted",
    )


def test_debug_full_color_bicycle_survives_start_menu(emulator: Emulator) -> None:
    start_debug_game_in_viridian(emulator)
    mount_bicycle_with_select(emulator)
    ride_bicycle_in_viridian(emulator)

    emulator.press("start")
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-viridian-bicycle-start-menu.png",
        name="debug-viridian-bicycle-start-menu",
    )
    emulator.press("start")
    emulator.tick(180)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-viridian-bicycle-after-start-menu.png",
        name="debug-viridian-bicycle-after-start-menu",
    )


def test_debug_full_color_pokemon_menus_use_menu_palettes(
    emulator: Emulator,
) -> None:
    start_debug_game_in_viridian(emulator)
    emulator.press("start")
    emulator.press("down")
    emulator.press("a")
    emulator.tick(180)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-full-color-party-menu.png",
        name="debug-full-color-party-menu",
    )

    emulator.press("a")
    stats_item = emulator.read("wMaxMenuItem") - 2
    for _ in range(stats_item):
        emulator.press("down")
    emulator.press("a")
    emulator.tick(240)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-full-color-status-screen.png",
        name="debug-full-color-status-screen",
    )

    emulator.press("b")
    emulator.tick(180)
    emulator.press("b")
    emulator.tick(180)
    emulator.press("start")
    emulator.tick(180)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-full-color-after-pokemon-menus.png",
        name="debug-full-color-after-pokemon-menus",
    )


def test_debug_full_color_survives_dialogue_window(emulator: Emulator) -> None:
    start_debug_game_in_viridian(emulator)
    open_viridian_pokecenter_sign(emulator)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-full-color-dialogue-open.png",
        name="debug-full-color-dialogue-open",
    )

    emulator.press("b")
    emulator.tick(180)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-full-color-after-dialogue.png",
        name="debug-full-color-after-dialogue",
    )
