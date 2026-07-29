"""Integration coverage for world sightings and optional Pikachu hints."""

from tools.rom_tests.emulator import Emulator
from tools.rom_tests.scenarios.oaks_lab import (
    PALLET_TOWN,
    complete_oaks_lab_intro,
)
from tools.rom_tests.scenarios.viridian_city import ROUTE_1, walk_to_value, walk_until
from tools.rom_tests.test_support import apply_debug_repel


LIGHT_BALL_GSC = 0xA3
PIKACHU_PENDING_SIGHTING = 6
PIKACHU_PENDING_EMOTION_ALERTED = 0x80
PIKACOMPANION_REACTION_PORTRAIT_READY = 7
SIGHTING_ZONE_PALLET_VIRIDIAN = 1
SIGHTING_PROFILE_EARLY_GRASSLAND = 1
SIGHTING_ACTIVE = 1


def _enter_route_1(emulator: Emulator) -> None:
    if emulator.read("wCurMap") != PALLET_TOWN:
        raise AssertionError("Route 1 sighting test must begin in Pallet Town")
    apply_debug_repel(emulator)
    if emulator.read("wYCoord") > 2:
        walk_to_value(emulator, "wXCoord", 8, "left", "west side of Oak's Lab")
        walk_to_value(emulator, "wYCoord", 2, "up", "north Pallet Town")
    if emulator.read("wXCoord") < 10:
        walk_to_value(emulator, "wXCoord", 10, "right", "Route 1 entrance")
    elif emulator.read("wXCoord") > 10:
        walk_to_value(emulator, "wXCoord", 10, "left", "Route 1 entrance")
    walk_to_value(emulator, "wCurMap", ROUTE_1, "up", "Route 1")
    emulator.tick(30)


def _take_step(emulator: Emulator, button: str) -> None:
    coordinate = "wXCoord" if button in ("left", "right") else "wYCoord"
    start = emulator.read(coordinate)
    emulator.advance_until(
        lambda: emulator.read(coordinate) != start,
        button=button,
        max_presses=3,
        description=f"sighting {button} step",
    )


def test_sighting_world_state_and_optional_companion_hint(
    emulator: Emulator,
) -> None:
    complete_oaks_lab_intro(emulator)
    _enter_route_1(emulator)

    emulator.write("wSightingFlags", 0)
    emulator.write("wSightingCooldown", 0)
    emulator.write("wSightingStepCounter", 127)
    emulator.write("wd49c", 0)
    emulator.write("wPikachuCompanionQueuedReaction", 0)
    _take_step(emulator, "up")

    assert emulator.read("wSightingFlags") & SIGHTING_ACTIVE
    assert emulator.read("wSightingZone") == SIGHTING_ZONE_PALLET_VIRIDIAN
    assert emulator.read("wSightingProfile") == SIGHTING_PROFILE_EARLY_GRASSLAND
    assert (emulator.read("wd49c") & 0x7F) == PIKACHU_PENDING_SIGHTING

    emulator.write("wJoyIgnore", 0)
    emulator.write("wStatusFlags5", 0)
    emulator.tick(3)
    assert (
        emulator.read("wPikachuCompanionQueuedReaction")
        == PIKACOMPANION_REACTION_PORTRAIT_READY
    )
    emulator.write("wPikachuCompanionIdleCounter", 59)
    emulator.tick(180)
    assert emulator.read("wd49c") == (
        PIKACHU_PENDING_EMOTION_ALERTED | PIKACHU_PENDING_SIGHTING
    )

    walk_until(
        emulator,
        lambda: emulator.read("wCurMap") == PALLET_TOWN,
        "down",
        "Pallet Town sighting exit",
    )
    assert not (emulator.read("wSightingFlags") & SIGHTING_ACTIVE)
    assert emulator.read("wSightingZone") == 0
    assert emulator.read("wSightingProfile") == 0
    assert emulator.read("wSightingCooldown") > 0
    assert (emulator.read("wd49c") & 0x7F) == 0

    # Sightings are world events: removing the starter's identity suppresses
    # only the hint, not activation itself.
    emulator.write("wPartyMon1CatchRate", LIGHT_BALL_GSC ^ 0x01)
    emulator.write("wd49c", 0)
    _enter_route_1(emulator)
    emulator.write("wSightingCooldown", 0)
    emulator.write("wSightingStepCounter", 127)
    _take_step(emulator, "up")

    assert emulator.read("wSightingFlags") & SIGHTING_ACTIVE
    assert emulator.read("wd49c") == 0
