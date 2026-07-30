"""Exhaustive debug-ROM loading and image capture for indoor map headers."""

from pathlib import Path
import re

from tools.rom_tests.emulator import Emulator
from tools.rom_tests.scenarios.debug_overworld import (
    debug_atlas_enter_map,
    start_debug_game_in_viridian,
)


ROOT = Path(__file__).resolve().parents[4]
OUTDOOR_TILESETS = {"OVERWORLD", "FOREST", "PLATEAU"}
TOWN_SPAWNS = (
    ("PALLET_TOWN", 5, 6),
    ("VIRIDIAN_CITY", 23, 26),
    ("PEWTER_CITY", 13, 26),
    ("CERULEAN_CITY", 19, 18),
    ("LAVENDER_TOWN", 3, 6),
    ("VERMILION_CITY", 11, 4),
    ("CELADON_CITY", 41, 10),
    ("FUCHSIA_CITY", 19, 28),
    ("CINNABAR_ISLAND", 11, 12),
    ("SAFFRON_CITY", 9, 30),
    ("INDIGO_PLATEAU", 9, 6),
    ("ROUTE_4", 11, 6),
    ("ROUTE_10", 11, 20),
)


def indoor_maps() -> list[tuple[str, int, str, int]]:
    """Return every non-outdoor map and its expected tileset ID."""
    map_ids: dict[str, int] = {}
    for line in (ROOT / "constants/map_constants.asm").read_text().splitlines():
        match = re.search(r"map_const\s+(\w+).+;\s+\$([0-9A-Fa-f]{2})", line)
        if match:
            map_ids[match.group(1)] = int(match.group(2), 16)

    tileset_ids: dict[str, int] = {}
    next_tileset = 0
    for line in (ROOT / "constants/tileset_constants.asm").read_text().splitlines():
        match = re.match(r"\s*const\s+(\w+)", line)
        if match:
            tileset_ids[match.group(1)] = next_tileset
            next_tileset += 1

    cases: dict[str, tuple[str, int, str, int]] = {}
    for header in sorted((ROOT / "data/maps/headers").glob("*.asm")):
        match = re.search(
            r"map_header\s+\w+,\s*(\w+),\s*(\w+)",
            header.read_text(),
        )
        if not match:
            continue
        map_name, tileset = match.groups()
        if tileset in OUTDOOR_TILESETS:
            continue
        cases[map_name] = (
            map_name,
            map_ids[map_name],
            tileset,
            tileset_ids[tileset],
        )
    return sorted(cases.values(), key=lambda case: case[1])


def map_id_lookup() -> dict[str, int]:
    """Parse map IDs used by the town-spawn image matrix."""
    ids: dict[str, int] = {}
    for line in (ROOT / "constants/map_constants.asm").read_text().splitlines():
        match = re.search(r"map_const\s+(\w+).+;\s+\$([0-9A-Fa-f]{2})", line)
        if match:
            ids[match.group(1)] = int(match.group(2), 16)
    return ids


def test_debug_full_color_indoor_map_atlas(emulator: Emulator) -> None:
    """Load and capture every building/cave floor through the normal map path."""
    cases = indoor_maps()
    assert len(cases) == 184
    assert len({tileset for _, _, tileset, _ in cases}) == 22

    start_debug_game_in_viridian(emulator)
    for map_name, map_id, tileset, tileset_id in cases:
        debug_atlas_enter_map(emulator, map_id)
        assert emulator.read("wCurMapTileset") == tileset_id, (
            f"{map_name} loaded tileset {emulator.read('wCurMapTileset')}, "
            f"expected {tileset} ({tileset_id})"
        )
        emulator.save_screenshot(
            f"atlas-{map_id:02x}-{map_name.lower().replace('_', '-')}.png"
        )


def test_debug_full_color_town_spawn_atlas(emulator: Emulator) -> None:
    """Capture every Fly destination beside its Center or equivalent landmark."""
    map_ids = map_id_lookup()
    start_debug_game_in_viridian(emulator)
    for map_name, x, y in TOWN_SPAWNS:
        map_id = map_ids[map_name]
        debug_atlas_enter_map(emulator, map_id, x=x, y=y)
        assert (emulator.read("wXCoord"), emulator.read("wYCoord")) == (x, y)
        emulator.save_screenshot(
            f"town-{map_id:02x}-{map_name.lower().replace('_', '-')}.png"
        )
