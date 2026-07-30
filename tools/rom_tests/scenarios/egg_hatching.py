"""Reusable automation for the short-incubation debug Egg."""

from pyboy.utils import WindowEvent

from tools.rom_tests.emulator import Emulator


PICHU = 0xC8
EGG = 0xCD
PEWTER_CITY = 0x02
DEBUG_INCUBATION_STEPS = 16


def start_debug_game_with_egg(emulator: Emulator) -> None:
    """Open the hidden debug menu and enter its prepared Pewter City game."""
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


def walk_one_overworld_step(
    emulator: Emulator, preferred_button: str | None
) -> str:
    """Take one player-controlled step and return the preferred reverse step."""
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


def walk_debug_egg_until_hatch(emulator: Emulator) -> tuple[str, int]:
    """Walk the real debug Egg to zero and stop at its hatch announcement."""
    countdown = emulator.symbols["wPartyMon2Exp"]
    next_button = "up"
    counted_steps = 0
    for attempt in range(DEBUG_INCUBATION_STEPS + 8):
        before = int.from_bytes(
            bytes(emulator.pyboy.memory[countdown + i] for i in range(3)),
            "big",
        )
        try:
            next_button = walk_one_overworld_step(emulator, next_button)
        except AssertionError as error:
            raise AssertionError(f"Failed on debug Egg movement {attempt + 1}") from error

        if emulator.read("wPartyMon2") == PICHU:
            if before != 1:
                raise AssertionError(
                    f"Debug Egg hatched with {before} counted steps remaining"
                )
            counted_steps += 1
            return next_button, counted_steps

        after = int.from_bytes(
            bytes(emulator.pyboy.memory[countdown + i] for i in range(3)),
            "big",
        )
        if after not in (before, before - 1):
            raise AssertionError(f"Egg countdown jumped from {before} to {after}")
        if after == before - 1:
            counted_steps += 1

    raise AssertionError("The real debug Egg did not hatch")
