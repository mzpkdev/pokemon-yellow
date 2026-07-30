"""Debug-build automation for quickly exercising overworld rendering."""

from tools.rom_tests.emulator import Emulator
from tools.rom_tests.scenarios.viridian_city import VIRIDIAN_CITY, walk_to_value


FULL_COLOR_OVERWORLD = 1 << 2


def start_debug_game_in_viridian(emulator: Emulator) -> None:
    """Use the hidden title-screen menu and wait for the debug Viridian spawn."""
    emulator.advance_until(
        lambda: (
            emulator.read("wTopMenuItemY") == 7
            and emulator.read("wTopMenuItemX") == 6
            and emulator.read("wMaxMenuItem") == 1
        ),
        button="select",
        max_presses=12,
        description="debug menu",
    )
    emulator.press("down")
    emulator.press("a", wait_frames=0)

    for _ in range(30):
        if (
            emulator.read("wCurMap") == VIRIDIAN_CITY
            and emulator.read("wStatusFlags6") & 1
        ):
            break
        emulator.tick(60)
    else:
        emulator.save_screenshot("timeout-debug-viridian-spawn.png")
        raise AssertionError("Timed out waiting for the debug Viridian spawn")

    emulator.tick(180)
    assert (emulator.read("wYCoord"), emulator.read("wXCoord")) == (26, 23)
    assert emulator.read("wOptions2") & FULL_COLOR_OVERWORLD


def exercise_viridian_scrolling(emulator: Emulator) -> None:
    """Walk a known-valid route that streams rows and columns into the BG map."""
    walk_to_value(emulator, "wYCoord", 29, "down", "south Viridian path")
    walk_to_value(emulator, "wXCoord", 19, "left", "Viridian main path")
    walk_to_value(emulator, "wYCoord", 20, "up", "Viridian Mart row")
    emulator.tick(180)
