"""Integration coverage for the complete opening Oak's Lab sequence."""

from pathlib import Path

from tools.rom_tests.emulator import Emulator
from tools.rom_tests.scenarios.oaks_lab import (
    OAKS_LAB,
    PALLET_TOWN,
    PIKACHU,
    SCRIPT_OAKSLAB_NOOP,
    complete_oaks_lab_intro,
)


SNAPSHOTS = Path(__file__).resolve().parents[1] / "snapshots"


def test_receive_pikachu_battle_rival_and_leave_lab(emulator: Emulator) -> None:
    complete_oaks_lab_intro(emulator)

    assert emulator.read("wPartyCount") == 1
    assert emulator.read("wPartySpecies") == PIKACHU
    assert emulator.read("wOaksLabCurScript") == SCRIPT_OAKSLAB_NOOP
    assert not emulator.is_in_battle()
    assert emulator.read("wCurMap") == PALLET_TOWN
    assert emulator.read("wCurMap") != OAKS_LAB
    assert (emulator.read("wYCoord"), emulator.read("wXCoord")) == (12, 12)
    emulator.assert_screen_matches(
        SNAPSHOTS / "oaks-lab-exit.png",
        name="oaks-lab-exit",
        # NPC position and the player's idle animation depend on elapsed frames.
        ignored_regions=(
            (0, 80, 160, 112),
            (48, 120, 72, 144),
            (24, 128, 104, 144),
        ),
    )
