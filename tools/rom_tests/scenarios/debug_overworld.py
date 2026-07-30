"""Debug-build automation for quickly exercising overworld rendering."""

from tools.rom_tests.emulator import Emulator
from tools.rom_tests.scenarios.viridian_city import VIRIDIAN_CITY, walk_to_value


FULL_COLOR_OVERWORLD = 1 << 2
VIRIDIAN_POKECENTER = 0x29


def start_debug_game_in_viridian(emulator: Emulator) -> None:
    """Use the hidden title-screen menu and wait for the debug Viridian spawn."""
    emulator.tick(2400)
    emulator.save_screenshot("debug-title.png")
    emulator.press("select")
    emulator.save_screenshot("debug-menu.png")
    assert emulator.read("wTopMenuItemY") == 7
    assert emulator.read("wTopMenuItemX") == 6
    assert emulator.read("wMaxMenuItem") == 1
    emulator.press("down")
    emulator.press("a", wait_frames=0)

    for _ in range(40):
        if (
            emulator.read("wCurMap") == VIRIDIAN_CITY
            and emulator.read("wStatusFlags6") & 1
        ):
            break
        emulator.press("b", wait_frames=30)
    else:
        emulator.save_screenshot("timeout-debug-viridian-spawn.png")
        raise AssertionError(
            "Timed out waiting for the debug Viridian spawn "
            f"(map={emulator.read('wCurMap'):#x}, "
            f"flags={emulator.read('wStatusFlags6'):#x}, "
            f"yx={(emulator.read('wYCoord'), emulator.read('wXCoord'))})"
        )

    emulator.tick(180)
    assert (emulator.read("wYCoord"), emulator.read("wXCoord")) == (26, 23)
    assert emulator.read("wOptions2") & FULL_COLOR_OVERWORLD


def exercise_viridian_scrolling(emulator: Emulator) -> None:
    """Walk a known-valid route that streams rows and columns into the BG map."""
    walk_to_value(emulator, "wXCoord", 19, "left", "Viridian main path")
    walk_to_value(emulator, "wYCoord", 29, "down", "south Viridian path")
    walk_to_value(emulator, "wYCoord", 20, "up", "Viridian Mart row")
    emulator.tick(180)


def enter_viridian_pokecenter(emulator: Emulator) -> None:
    """Enter the building immediately north of the debug spawn."""
    walk_to_value(
        emulator,
        "wCurMap",
        VIRIDIAN_POKECENTER,
        "up",
        "Viridian Pokemon Center",
    )
    emulator.tick(180)


def leave_viridian_pokecenter(emulator: Emulator) -> None:
    """Return to Viridian City through the center's exit."""
    walk_to_value(
        emulator,
        "wCurMap",
        VIRIDIAN_CITY,
        "down",
        "Viridian City return",
    )
    emulator.tick(180)
