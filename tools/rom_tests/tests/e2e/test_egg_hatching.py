"""End-to-end coverage for the debug party Egg and automatic hatching."""

from pyboy.utils import WindowEvent

from tools.rom_tests.emulator import Emulator


PICHU = 0xC8
EGG = 0xCD
PEWTER_CITY = 0x02
DEBUG_INCUBATION_STEPS = 16
EGG_NICKNAME = bytes((0x84, 0x86, 0x86, 0x50))  # "EGG@"


def _start_debug_game(emulator: Emulator) -> None:
    """Open the hidden debug menu and choose its prepared Pewter City game."""
    emulator.tick(600)
    emulator.pyboy.send_input(WindowEvent.PRESS_BUTTON_SELECT)
    for _ in range(2400):
        emulator.tick()
        if (
            emulator.read("wTopMenuItemY") == 7
            and emulator.read("wTopMenuItemX") == 6
            and emulator.read("wMaxMenuItem") == 1
        ):
            break
    else:
        raise AssertionError("Timed out waiting for the debug menu")

    emulator.pyboy.send_input(WindowEvent.RELEASE_BUTTON_SELECT)
    emulator.tick(5)
    emulator.press("down", wait_frames=5)
    emulator.press("a")
    emulator.advance_until(
        lambda: (
            emulator.read("wCurMap") == PEWTER_CITY
            and emulator.read("wPartyCount") == 2
        ),
        button="a",
        max_presses=10,
        description="debug Pewter City game",
    )
    emulator.tick(300)


def _walk_one_step(emulator: Emulator, preferred_button: str | None) -> str:
    opposites = {
        "left": "right",
        "right": "left",
        "up": "down",
        "down": "up",
    }
    buttons = (
        [preferred_button]
        if preferred_button is not None
        else ["down", "left", "right", "up"]
    )
    for button in buttons:
        coordinate = "wXCoord" if button in ("left", "right") else "wYCoord"
        before = emulator.read(coordinate)
        emulator.pyboy.button(button, delay=2)
        for _ in range(120):
            emulator.tick()
            if emulator.read(coordinate) != before:
                return opposites[button]
    raise AssertionError("Could not take a player-controlled overworld step")


def test_debug_party_egg_hatches_and_returns_control_to_the_overworld(
    emulator: Emulator,
) -> None:
    _start_debug_game(emulator)

    party_species = emulator.symbols["wPartySpecies"]
    assert emulator.pyboy.memory[party_species + 1] == EGG
    assert emulator.read("wPartyMon2") == EGG
    assert emulator.read("wPartyMon2CatchRate") == PICHU

    countdown = emulator.symbols["wPartyMon2Exp"]
    assert bytes(emulator.pyboy.memory[countdown + i] for i in range(3)) == bytes(
        (0, 0, DEBUG_INCUBATION_STEPS)
    )
    nickname = emulator.symbols["wPartyMonNicks"] + 11
    assert bytes(emulator.pyboy.memory[nickname + i] for i in range(4)) == EGG_NICKNAME

    next_button = None
    for step in range(DEBUG_INCUBATION_STEPS):
        next_button = _walk_one_step(emulator, next_button)
        if step < DEBUG_INCUBATION_STEPS - 1:
            assert emulator.read("wPartyMon2") == EGG

    for _ in range(600):
        if emulator.read("wEggHatchPending") == 0:
            break
        emulator.tick()
    assert emulator.read("wPartyMon2") == PICHU
    assert emulator.pyboy.memory[party_species + 1] == PICHU
    assert emulator.read("wEggHatchPending") == 0

    emulator.press("a")
    _walk_one_step(emulator, next_button)
