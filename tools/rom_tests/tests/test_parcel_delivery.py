"""Integration coverage for Oak's Parcel and Pokédex sequence."""

from pathlib import Path

from tools.rom_tests.emulator import Emulator
from tools.rom_tests.scenarios.oaks_lab import PALLET_TOWN
from tools.rom_tests.scenarios.parcel_delivery import (
    OAKS_PARCEL,
    SCRIPT_OAKSLAB_NOOP,
    complete_parcel_delivery,
)


SNAPSHOTS = Path(__file__).resolve().parents[1] / "snapshots"


def test_deliver_oaks_parcel_and_leave_lab(emulator: Emulator) -> None:
    complete_parcel_delivery(emulator)

    assert not emulator.bag_contains(OAKS_PARCEL)
    assert emulator.read("wOaksLabCurScript") == SCRIPT_OAKSLAB_NOOP
    assert emulator.read("wCurMap") == PALLET_TOWN
    assert (emulator.read("wYCoord"), emulator.read("wXCoord")) == (12, 12)
    emulator.assert_screen_matches(
        SNAPSHOTS / "parcel-delivered-lab-exit.png",
        name="parcel-delivered-lab-exit",
        # NPC position and the player's idle animation depend on elapsed frames.
        ignored_regions=((0, 80, 160, 112), (48, 120, 72, 144)),
    )
