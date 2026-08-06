"""Debug-ROM automation for representative full-color indoor maps."""

from tools.rom_tests.emulator import Emulator
from tools.rom_tests.scenarios.debug_overworld import (
    FULL_COLOR_OVERWORLD,
    start_debug_game_in_viridian,
)
from tools.rom_tests.scenarios.new_game import reach_bedroom_overworld
from tools.rom_tests.scenarios.oaks_lab import (
    OAKS_LAB,
    REDS_HOUSE_1F,
    SCRIPT_OAKSLAB_PLAYER_DONT_GO_AWAY,
    advance_to_value,
    walk_from_bedroom_to_oak,
)
from tools.rom_tests.scenarios.viridian_city import walk_to_value


ROUTE_4 = 0x0F
MT_MOON_1F = 0x3B


def enable_full_color_in_bedroom(emulator: Emulator) -> None:
    """Start normally, then opt into FULL before the next map load."""
    reach_bedroom_overworld(emulator)
    emulator.write(
        "wOptions2",
        emulator.read("wOptions2") | FULL_COLOR_OVERWORLD,
    )


def enter_reds_house_first_floor(emulator: Emulator) -> None:
    """Load Red's downstairs room through its normal staircase warp."""
    enable_full_color_in_bedroom(emulator)
    advance_to_value(emulator, "wXCoord", 5, "right", "bedroom aisle")
    advance_to_value(emulator, "wYCoord", 1, "up", "bedroom stairs")
    advance_to_value(emulator, "wCurMap", REDS_HOUSE_1F, "right", "first floor")
    emulator.tick(180)


def enter_oaks_lab_before_starter(emulator: Emulator) -> None:
    """Follow Oak into the lab and stop at the stable starter-selection script."""
    enable_full_color_in_bedroom(emulator)
    walk_from_bedroom_to_oak(emulator)
    advance_to_value(emulator, "wCurMap", OAKS_LAB, "a", "Oak's Lab")
    advance_to_value(
        emulator,
        "wOaksLabCurScript",
        SCRIPT_OAKSLAB_PLAYER_DONT_GO_AWAY,
        "a",
        "starter selection",
    )
    emulator.tick(180)


def enter_mt_moon_with_debug_fly(emulator: Emulator) -> None:
    """Fly to Route 4 with the debug party, then enter Mt. Moon normally."""
    start_debug_game_in_viridian(emulator)
    emulator.press("start")
    emulator.press("down")
    emulator.press("a")
    emulator.press("a")
    emulator.press("a")
    emulator.press("down")
    emulator.press("down")
    emulator.press("a")
    emulator.advance_until(
        lambda: emulator.read("wCurMap") == ROUTE_4,
        button="b",
        max_presses=40,
        description="flying to Route 4",
    )
    walk_to_value(emulator, "wXCoord", 18, "right", "Mt. Moon entrance column")
    walk_to_value(emulator, "wCurMap", MT_MOON_1F, "up", "Mt. Moon 1F")
    emulator.tick(180)
