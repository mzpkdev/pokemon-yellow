"""End-to-end coverage for the debug party Egg and automatic hatching."""

from pyboy.utils import WindowEvent

from tools.rom_tests.emulator import Emulator
from tools.rom_tests.scenarios.oaks_lab import complete_oaks_lab_intro


PICHU = 0xC8
EGG = 0xCD
PEWTER_CITY = 0x02
DEBUG_INCUBATION_STEPS = 16
EGG_NICKNAME = bytes((0x84, 0x86, 0x86, 0x50))  # "EGG@"
PARTY_END = 0xFF


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
    emulator.press("a", wait_frames=30)
    emulator.advance_until(
        lambda: (
            emulator.read("wCurMap") == PEWTER_CITY
            and emulator.read("wPartyCount") == 2
            and emulator.read("wStatusFlags6") & 1
        ),
        button="a",
        max_presses=30,
        description="playable debug Pewter City game",
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
        [preferred_button] * 3 + ["down", "left", "right", "up"] * 3
        if preferred_button is not None
        else ["down", "left", "right", "up"] * 3
    )
    for button in buttons:
        coordinate = "wXCoord" if button in ("left", "right") else "wYCoord"
        before = emulator.read(coordinate)
        emulator.press(button, wait_frames=40)
        if emulator.read(coordinate) != before:
            return opposites[button]
    raise AssertionError("Could not take a player-controlled overworld step")


def _complete_hatch_presentation(emulator: Emulator) -> None:
    """Advance the announcement, non-cancellable animation, and result text."""
    assert emulator.read("wForceEvolution") == 0
    saved_tile_animations = emulator.read("hTileAnimations")
    transfer_destination = emulator.symbols["hAutoBGTransferDest"]
    saved_transfer_destination = bytes(
        emulator.pyboy.memory[transfer_destination + offset] for offset in range(2)
    )
    saved_bgp = emulator.pyboy.memory[0xFF47]
    emulator.press("a", wait_frames=10)
    for _ in range(300):
        if emulator.read("wForceEvolution") != 0:
            break
        emulator.tick()
    else:
        raise AssertionError("Egg hatch animation did not begin")

    # Wait past sprite loading, the cry, and the animation's 80-frame lead-in.
    emulator.tick(180)
    tilemap = emulator.symbols["wTileMap"] + 2 * 20 + 7
    visible_bg = 0x9800 + 2 * 32 + 7
    assert all(
        emulator.pyboy.memory[visible_bg + row * 32 + column]
        == emulator.pyboy.memory[tilemap + row * 20 + column]
        for row in range(7)
        for column in range(7)
    )

    # Unlike ordinary evolution, hatching cannot be cancelled with B. Keep
    # pressing through the cry lead-in and the actual cancellation window.
    for _ in range(300):
        if emulator.read("wForceEvolution") == 0:
            break
        emulator.press("b", wait_frames=5)
    else:
        raise AssertionError("Egg hatch animation did not finish")
    assert emulator.read("wEvoCancelled") == 0

    # The result remains on screen until the player acknowledges it.
    before = (emulator.read("wXCoord"), emulator.read("wYCoord"))
    emulator.press("left", wait_frames=30)
    assert (emulator.read("wXCoord"), emulator.read("wYCoord")) == before
    emulator.press("a", wait_frames=120)
    assert emulator.read("hTileAnimations") == saved_tile_animations
    assert bytes(
        emulator.pyboy.memory[transfer_destination + offset] for offset in range(2)
    ) == saved_transfer_destination
    assert emulator.pyboy.memory[0xFF47] == saved_bgp
    assert emulator.read("wUpdateSpritesEnabled") == 1


def test_debug_party_egg_hatches_after_16_counted_steps(emulator: Emulator) -> None:
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

    emulator.press("b", wait_frames=20)
    next_button = "up"
    counted_steps = 0
    for attempt in range(DEBUG_INCUBATION_STEPS + 8):
        before = int.from_bytes(
            bytes(emulator.pyboy.memory[countdown + i] for i in range(3)),
            "big",
        )
        try:
            next_button = _walk_one_step(emulator, next_button)
        except AssertionError as error:
            raise AssertionError(f"Failed on debug Egg movement {attempt + 1}") from error

        if emulator.read("wPartyMon2") == PICHU:
            assert before == 1
            counted_steps += 1
            break

        after = int.from_bytes(
            bytes(emulator.pyboy.memory[countdown + i] for i in range(3)),
            "big",
        )
        assert after in (before, before - 1)
        if after == before - 1:
            counted_steps += 1
    else:
        raise AssertionError("The real debug Egg did not hatch")

    for _ in range(600):
        if emulator.read("wEggHatchPending") == 0:
            break
        emulator.tick()
    assert counted_steps == DEBUG_INCUBATION_STEPS
    assert emulator.read("wPartyMon2") == PICHU
    assert emulator.pyboy.memory[party_species + 1] == PICHU
    assert emulator.read("wEggHatchPending") == 0

    _complete_hatch_presentation(emulator)
    _walk_one_step(emulator, next_button)


def _add_pichu_egg_beside_pikachu(emulator: Emulator) -> None:
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


def test_party_egg_hatches_and_returns_control_to_the_overworld(
    emulator: Emulator,
) -> None:
    complete_oaks_lab_intro(emulator)
    _add_pichu_egg_beside_pikachu(emulator)
    party_species = emulator.symbols["wPartySpecies"]

    next_button = "left"
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

    _complete_hatch_presentation(emulator)
    _walk_one_step(emulator, next_button)
