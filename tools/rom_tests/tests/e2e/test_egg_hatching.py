"""End-to-end coverage for walking a party Egg through hatching."""

from tools.rom_tests.emulator import Emulator
from tools.rom_tests.scenarios.oaks_lab import complete_oaks_lab_intro


PICHU = 0xC8
EGG = 0xCD
PARTY_END = 0xFF
DEBUG_INCUBATION_STEPS = 16


def _spawn_pichu_egg(emulator: Emulator) -> None:
    """Add the framework's short-incubation Pichu Egg beside Pikachu."""
    emulator.write("wPartyCount", 2)
    party_species = emulator.symbols["wPartySpecies"]
    emulator.pyboy.memory[party_species + 1] = EGG
    emulator.pyboy.memory[party_species + 2] = PARTY_END

    emulator.write("wPartyMon2", EGG)
    emulator.write("wPartyMon2CatchRate", PICHU)

    countdown = emulator.symbols["wPartyMon2Exp"]
    emulator.pyboy.memory[countdown] = 0
    emulator.pyboy.memory[countdown + 1] = 0
    emulator.pyboy.memory[countdown + 2] = DEBUG_INCUBATION_STEPS


def _walk_one_step(emulator: Emulator, button: str, coordinate: str) -> None:
    before = emulator.read(coordinate)
    for _ in range(3):
        emulator.pyboy.button(button, delay=2)
        for _ in range(120):
            emulator.tick()
            after = emulator.read(coordinate)
            if after != before:
                assert abs(after - before) == 1
                return
    raise AssertionError(f"Timed out waiting for one {button} step")


def test_party_egg_hatches_and_returns_control_to_the_overworld(
    emulator: Emulator,
) -> None:
    complete_oaks_lab_intro(emulator)
    _spawn_pichu_egg(emulator)

    # The open Pallet Town path lets the test count real, completed player steps
    # without encounters, warps, or scripted movement.
    for step in range(DEBUG_INCUBATION_STEPS):
        button = "left" if step % 2 == 0 else "right"
        _walk_one_step(emulator, button, "wXCoord")

        if step < DEBUG_INCUBATION_STEPS - 1:
            assert emulator.read("wPartyMon2") == EGG

    assert emulator.read("wPartyMon2") == PICHU
    assert emulator.pyboy.memory[emulator.symbols["wPartySpecies"] + 1] == PICHU
    for _ in range(600):
        if emulator.read("wEggHatchPending") == 0:
            break
        emulator.tick()
    assert emulator.read("wEggHatchPending") == 0

    # Dismiss the completion message and prove the event returned to normal
    # player control instead of hanging at the end of the hatch.
    emulator.press("a")
    _walk_one_step(emulator, "left", "wXCoord")
