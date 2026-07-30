"""End-to-end coverage for the debug party Egg and automatic hatching."""

from tools.rom_tests.emulator import Emulator, screen_difference
from tools.rom_tests.scenarios.egg_hatching import (
    DEBUG_INCUBATION_STEPS,
    EGG,
    PICHU,
    start_debug_game_with_egg,
    walk_debug_egg_until_hatch,
    walk_one_overworld_step,
)
from tools.rom_tests.scenarios.oaks_lab import complete_oaks_lab_intro


EGG_NICKNAME = bytes((0x84, 0x86, 0x86, 0x50))  # "EGG@"
PARTY_END = 0xFF


def _complete_hatch_presentation(emulator: Emulator) -> None:
    """Advance the announcement, non-cancellable animation, and result text."""
    assert emulator.read("wForceEvolution") == 0
    map_before = emulator.pyboy.screen.image.convert("RGB")
    map_before.save(emulator.results / "hatch-map-before.png")
    for frame in range(0, 121, 30):
        if frame:
            emulator.tick(30)
        emulator.save_screenshot(f"hatch-announcement-{frame:03d}f.png")
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
    emulator.tick(3)
    emulator.save_screenshot("hatch-01-animation-00s.png")

    # Wait past sprite loading, the cry, and the animation's 80-frame lead-in.
    emulator.tick(177)
    emulator.save_screenshot("hatch-02-animation-03s.png")
    tilemap = emulator.symbols["wTileMap"] + 2 * 20 + 7
    visible_bg = 0x9C00 + 2 * 32 + 7
    assert all(
        emulator.pyboy.memory[visible_bg + row * 32 + column]
        == emulator.pyboy.memory[tilemap + row * 20 + column]
        for row in range(7)
        for column in range(7)
    )

    # Unlike ordinary evolution, hatching cannot be cancelled with B. Keep
    # pressing through the cry lead-in and the actual cancellation window.
    for press_index in range(300):
        if emulator.read("wForceEvolution") == 0:
            break
        emulator.press("b", wait_frames=5)
        if (press_index + 1) % 15 == 0:
            elapsed_seconds = 3 + (press_index + 1) // 15 * 2
            emulator.save_screenshot(
                f"hatch-animation-{elapsed_seconds:02d}s.png"
            )
    else:
        raise AssertionError("Egg hatch animation did not finish")
    assert emulator.read("wEvoCancelled") == 0
    emulator.save_screenshot("hatch-result.png")

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
    map_after = emulator.pyboy.screen.image.convert("RGB")
    map_after.save(emulator.results / "hatch-map-after.png")

    # The pre-hatch image contains the dialogue box, player, and companion.
    # Mask only those dynamic regions; all surrounding map pixels and colors
    # must return exactly to their pre-movie appearance.
    difference = screen_difference(
        map_before,
        map_after,
        ignored_regions=((0, 96, 160, 144), (48, 32, 112, 96)),
    )
    difference.save(emulator.results / "hatch-map-after-diff.png")
    assert difference.getbbox() is None


def test_debug_party_egg_hatches_after_16_counted_steps(emulator: Emulator) -> None:
    start_debug_game_with_egg(emulator)

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
    next_button, counted_steps = walk_debug_egg_until_hatch(emulator)

    for _ in range(600):
        if emulator.read("wEggHatchPending") == 0:
            break
        emulator.tick()
    assert counted_steps == DEBUG_INCUBATION_STEPS
    assert emulator.read("wPartyMon2") == PICHU
    assert emulator.pyboy.memory[party_species + 1] == PICHU
    assert emulator.read("wEggHatchPending") == 0

    _complete_hatch_presentation(emulator)
    walk_one_overworld_step(emulator, next_button)


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
        next_button = walk_one_overworld_step(emulator, next_button)
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
    walk_one_overworld_step(emulator, next_button)
