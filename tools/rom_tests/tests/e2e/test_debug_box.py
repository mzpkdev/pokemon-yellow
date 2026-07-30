"""End-to-end coverage for the newly added Pokémon in the debug PC box."""

from pyboy.utils import WindowEvent

from tools.rom_tests.emulator import Emulator


PEWTER_CITY = 0x02
PEWTER_POKECENTER = 0x3A
DEBUG_LEVEL = 15
BOXMON_STRUCT_LENGTH = 33
PARTYMON_STRUCT_LENGTH = 44
MON_HP = 1
MON_BOX_LEVEL = 3
MON_EXP = 14
MON_LEVEL = 33
MON_MAXHP = 34
NEW_SPECIES = (
    0xBF,  # Smoochum
    0xC0,  # Elekid
    0xC1,  # Magby
    0xC2,  # Politoed
    0xC3,  # Slowking
    0xC4,  # Steelix
    0xC5,  # Kingdra
    0xC6,  # Scizor
    0xC7,  # Porygon2
    0xC8,  # Pichu
    0xC9,  # Cleffa
    0xCA,  # Igglybuff
    0xCB,  # Crobat
    0xCC,  # Blissey
)


def _start_debug_game(emulator: Emulator) -> None:
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
    emulator.press("b", wait_frames=20)


def _walk_until(
    emulator: Emulator,
    button: str,
    predicate,
    description: str,
) -> None:
    for _ in range(20):
        if predicate():
            return
        emulator.press(button, wait_frames=40)
    raise AssertionError(f"Timed out walking to {description}")


def _read_bytes(emulator: Emulator, address: int, length: int) -> bytes:
    return bytes(emulator.pyboy.memory[address + index] for index in range(length))


def _read_big_endian_word(emulator: Emulator, address: int) -> int:
    return int.from_bytes(_read_bytes(emulator, address, 2), "big")


def test_debug_box_mons_keep_level_and_valid_hp_when_withdrawn(
    emulator: Emulator,
) -> None:
    _start_debug_game(emulator)

    assert emulator.read("wBoxCount") == len(NEW_SPECIES)
    box_species = emulator.symbols["wBoxSpecies"]
    assert _read_bytes(emulator, box_species, len(NEW_SPECIES)) == bytes(NEW_SPECIES)

    box_mons = emulator.symbols["wBoxMons"]
    boxed_experience = []
    for index, species in enumerate(NEW_SPECIES):
        mon = box_mons + index * BOXMON_STRUCT_LENGTH
        assert emulator.pyboy.memory[mon] == species
        assert emulator.pyboy.memory[mon + MON_BOX_LEVEL] == DEBUG_LEVEL
        experience = _read_bytes(emulator, mon + MON_EXP, 3)
        assert experience != b"\0\0\0"
        boxed_experience.append(experience)

    # Keep the debug Egg from hatching while this test walks to the PC.
    egg_countdown = emulator.symbols["wPartyMon2Exp"]
    emulator.pyboy.memory[egg_countdown : egg_countdown + 3] = bytes((0, 0xFF, 0xFF))

    _walk_until(
        emulator,
        "up",
        lambda: emulator.read("wCurMap") == PEWTER_POKECENTER,
        "the Pewter Pokémon Center",
    )
    _walk_until(
        emulator,
        "right",
        lambda: emulator.read("wXCoord") == 5,
        "the center aisle",
    )
    _walk_until(
        emulator,
        "up",
        lambda: emulator.read("wYCoord") == 4,
        "the PC row",
    )
    _walk_until(
        emulator,
        "right",
        lambda: emulator.read("wXCoord") == 13,
        "the PC",
    )
    emulator.press("up", wait_frames=20)
    emulator.press("a", wait_frames=100)

    # The first option at every prompt leads to Bill's PC, Withdraw, Smoochum,
    # and Withdraw once more.
    for _ in range(10):
        if emulator.read("wPartyCount") == 3:
            break
        emulator.press("a", wait_frames=100)
    assert emulator.read("wPartyCount") == 3
    assert emulator.read("wBoxCount") == len(NEW_SPECIES) - 1

    party_mon = emulator.symbols["wPartyMon1"] + 2 * PARTYMON_STRUCT_LENGTH
    assert emulator.pyboy.memory[party_mon] == NEW_SPECIES[0]
    assert emulator.pyboy.memory[party_mon + MON_LEVEL] == DEBUG_LEVEL
    assert _read_bytes(emulator, party_mon + MON_EXP, 3) == boxed_experience[0]

    hp = _read_big_endian_word(emulator, party_mon + MON_HP)
    max_hp = _read_big_endian_word(emulator, party_mon + MON_MAXHP)
    assert 0 < hp <= max_hp
    assert hp == max_hp
