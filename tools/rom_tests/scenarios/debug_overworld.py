"""Debug-build automation for quickly exercising overworld rendering."""

from tools.rom_tests.emulator import Emulator
from tools.rom_tests.scenarios.viridian_city import VIRIDIAN_CITY, walk_to_value


FULL_COLOR_OVERWORLD = 1 << 2
VIRIDIAN_POKECENTER = 0x29
VIRIDIAN_MART = 0x2A
VIRIDIAN_SCHOOL_HOUSE = 0x2B
ROUTE_22 = 0x21


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


def debug_atlas_enter_map(
    emulator: Emulator, map_id: int, x: int = 1, y: int = 1
) -> None:
    """Ask the debug ROM to reload an arbitrary map through EnterMap."""
    emulator.write("wDebugAtlasMap", map_id)
    emulator.write("wDebugAtlasX", x)
    emulator.write("wDebugAtlasY", y)
    # The request aliases surfing-minigame scratch in debug builds, so use a
    # magic value that ordinary gameplay cannot accidentally interpret.
    emulator.write("wDebugAtlasRequest", 0xA5)
    # EnterMap reuses that scratch byte while loading map objects, so the
    # request value itself is intentionally not a completion flag.
    emulator.tick(240)
    assert emulator.read("wCurMap") == map_id, (
        f"debug atlas requested map {map_id:#x}, "
        f"but map {emulator.read('wCurMap'):#x} loaded"
    )


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


def enter_viridian_mart(emulator: Emulator) -> None:
    """Enter the Mart from the debug spawn without advancing its parcel script."""
    walk_to_value(emulator, "wXCoord", 19, "left", "Viridian main path")
    walk_to_value(emulator, "wYCoord", 20, "up", "Viridian Mart row")
    walk_to_value(emulator, "wXCoord", 29, "right", "Viridian Mart entrance")
    walk_to_value(emulator, "wCurMap", VIRIDIAN_MART, "up", "Viridian Mart")
    emulator.tick(180)


def enter_viridian_school(emulator: Emulator) -> None:
    """Enter a representative small house from the debug spawn."""
    walk_to_value(emulator, "wXCoord", 19, "left", "Viridian main path")
    walk_to_value(emulator, "wYCoord", 16, "up", "Viridian school row")
    walk_to_value(emulator, "wXCoord", 21, "right", "Viridian school column")
    walk_to_value(
        emulator,
        "wCurMap",
        VIRIDIAN_SCHOOL_HOUSE,
        "up",
        "Viridian School",
    )
    emulator.tick(180)


def walk_west_to_route_22(emulator: Emulator) -> None:
    """Cross Viridian's west connected-map boundary into Route 22."""
    walk_to_value(emulator, "wXCoord", 19, "left", "Viridian main path")
    walk_to_value(emulator, "wYCoord", 20, "up", "Viridian west path")
    walk_to_value(emulator, "wXCoord", 7, "left", "Viridian west exit")
    walk_to_value(emulator, "wYCoord", 16, "up", "Route 22 connection row")
    walk_to_value(emulator, "wCurMap", ROUTE_22, "left", "Route 22")
    emulator.tick(180)


def mount_bicycle_with_select(emulator: Emulator) -> None:
    """Use PureRGB's Select shortcut to mount the debug inventory bicycle."""
    assert emulator.read("wWalkBikeSurfState") == 0
    emulator.press("select")
    if emulator.read("wWalkBikeSurfState") != 1:
        emulator.press("b")
    emulator.tick(180)
    assert emulator.read("wWalkBikeSurfState") == 1


def ride_bicycle_in_viridian(emulator: Emulator) -> None:
    """Ride west from the debug spawn far enough to stream the scenery."""
    assert emulator.read("wWalkBikeSurfState") == 1
    walk_to_value(emulator, "wXCoord", 19, "left", "Viridian bicycle path")
    emulator.tick(180)


def dismount_bicycle_with_select(emulator: Emulator) -> None:
    """Use the Select shortcut again and wait until the player is walking."""
    assert emulator.read("wWalkBikeSurfState") == 1
    emulator.press("select")
    emulator.press("b")
    emulator.tick(180)
    assert emulator.read("wWalkBikeSurfState") == 0


def open_viridian_pokecenter_sign(emulator: Emulator) -> None:
    """Open the sign dialogue immediately northeast of the debug spawn."""
    walk_to_value(emulator, "wXCoord", 24, "right", "Pokemon Center sign")
    emulator.press("up", wait_frames=30)
    emulator.press("a", wait_frames=180)
    assert emulator.read("hWY") == 0
