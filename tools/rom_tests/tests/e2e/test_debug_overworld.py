"""Visual smoke coverage for the debug full-color overworld spawn."""

from pathlib import Path

from tools.rom_tests.emulator import Emulator
from tools.rom_tests.scenarios.debug_overworld import (
    dismount_bicycle_with_select,
    enter_viridian_mart,
    enter_viridian_pokecenter,
    enter_viridian_school,
    exercise_viridian_scrolling,
    mount_bicycle_with_select,
    open_viridian_pokecenter_sign,
    ride_bicycle_in_viridian,
    start_debug_game_in_viridian,
    walk_west_to_route_22,
)
from tools.rom_tests.scenarios.debug_indoor_maps import (
    enter_mt_moon_with_debug_fly,
    enter_oaks_lab_before_starter,
    enter_reds_house_first_floor,
)

SNAPSHOTS = Path(__file__).resolve().parents[2] / "snapshots"
ROOT = Path(__file__).resolve().parents[4]


def assert_visible_outdoor_attributes(emulator: Emulator) -> None:
    """Match the visible BG attributes to the outdoor tile assignment table."""
    source = (ROOT / "engine/gfx/full_color_overworld.asm").read_text()
    table_source = source.split("FullColorOutdoorAttributes:", 1)[1].split(
        "FullColorForestAttributes:", 1
    )[0]
    attributes = [
        int(value)
        for line in table_source.splitlines()
        if line.strip().startswith("db ")
        for value in line.split("db ", 1)[1].replace(" ", "").split(",")
    ]
    assert len(attributes) == 0x60

    screen_x = emulator.pyboy.memory[0xFF43] // 8
    screen_y = emulator.pyboy.memory[0xFF42] // 8
    mismatches = []
    for y in range(18):
        for x in range(20):
            offset = ((screen_y + y) & 31) * 32 + ((screen_x + x) & 31)
            emulator.pyboy.memory[0xFF4F] = 0
            tile = emulator.pyboy.memory[0x9800 + offset]
            expected = attributes[tile] if tile < len(attributes) else 7
            emulator.pyboy.memory[0xFF4F] = 1
            try:
                actual = emulator.pyboy.memory[0x9800 + offset] & 7
            finally:
                emulator.pyboy.memory[0xFF4F] = 0
            if actual != expected:
                mismatches.append((x, y, tile, actual, expected))
    assert not mismatches, f"visible attribute mismatches: {mismatches}"


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


def test_debug_full_color_viridian_mart(emulator: Emulator) -> None:
    start_debug_game_in_viridian(emulator)
    enter_viridian_mart(emulator)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-viridian-mart.png",
        name="debug-viridian-mart",
    )


def test_debug_full_color_generic_house(emulator: Emulator) -> None:
    start_debug_game_in_viridian(emulator)
    enter_viridian_school(emulator)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-viridian-school.png",
        name="debug-viridian-school",
    )


def test_debug_full_color_reds_house(emulator: Emulator) -> None:
    enter_reds_house_first_floor(emulator)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-reds-house-1f.png",
        name="debug-reds-house-1f",
    )


def test_debug_full_color_oaks_lab(emulator: Emulator) -> None:
    enter_oaks_lab_before_starter(emulator)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-oaks-lab.png",
        name="debug-oaks-lab",
        ignored_regions=((48, 48, 72, 88),),
    )


def test_debug_full_color_mt_moon(emulator: Emulator) -> None:
    enter_mt_moon_with_debug_fly(emulator)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-mt-moon-1f.png",
        name="debug-mt-moon-1f",
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
    assert_visible_outdoor_attributes(emulator)
    emulator.tick(180)
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
        ignored_regions=(
            (0, 0, 88, 16),
            (0, 80, 88, 112),
            (64, 56, 88, 88),
            (112, 0, 160, 16),
            (40, 32, 88, 48),
        ),
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
        ignored_regions=(
            (0, 0, 16, 16),
            (32, 0, 56, 16),
            (120, 0, 160, 64),
            (136, 80, 160, 104),
        ),
    )

    emulator.press("b")
    emulator.tick(180)
    emulator.assert_screen_matches(
        SNAPSHOTS / "debug-full-color-after-dialogue.png",
        name="debug-full-color-after-dialogue",
    )
