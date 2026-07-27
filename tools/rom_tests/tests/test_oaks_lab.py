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
        name="oaks-lab-exit-upper",
        crop=(0, 0, 160, 80),
    )


def test_companion_step_rollover_updates_happiness_and_mood(
    emulator: Emulator,
) -> None:
    complete_oaks_lab_intro(emulator)
    emulator.write("wPikachuHappiness", 30)
    emulator.write("wPikachuMood", 127)
    emulator.write("wPikachuCompanionStepCounter", 0xFF)
    emulator.write("wWalkBikeSurfState", 0)
    emulator.write("wStatusFlags5", emulator.read("wStatusFlags5") & 0x7F)

    start_x = emulator.read("wXCoord")
    emulator.advance_until(
        lambda: emulator.read("wXCoord") < start_x,
        button="left",
        max_presses=3,
        description="companion test step",
    )

    assert emulator.read("wPikachuCompanionStepCounter") == 0
    assert emulator.read("wPikachuHappiness") == 32
    assert emulator.read("wPikachuMood") == 128

    emulator.write("wWalkBikeSurfState", 1)
    emulator.advance_until(
        lambda: emulator.read("wXCoord") == start_x,
        button="right",
        max_presses=3,
        description="companion bicycle test step",
    )

    assert emulator.read("wPikachuCompanionStepCounter") == 0
