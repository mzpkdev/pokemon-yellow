import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class EggFrameworkTests(unittest.TestCase):
    def test_egg_metadata_uses_persistent_box_fields(self) -> None:
        eggs = read("engine/pokemon/eggs.asm")
        constructor = eggs.split("UpdatePartyEggsOnStep::", 1)[0]
        self.assertIn("call AddPartyMon", constructor)
        self.assertNotIn("predef _AddPartyMon", constructor)
        self.assertIn("; Input: c = species that will hatch, de = incubation steps", constructor)
        self.assertIn("ld hl, wPartyMon1CatchRate", constructor)
        self.assertIn("ld bc, MON_EXP - MON_CATCH_RATE", constructor)
        self.assertIn("ld hl, wPartyMon1HP", constructor)
        self.assertIn("ld hl, wPartyMon1MaxHP", constructor)
        self.assertGreaterEqual(len(re.findall(r"xor a\s+ld \[hli\], a\s+ld \[hl\], a", constructor)), 2)

    def test_incubation_is_party_only_and_ignores_scripted_steps(self) -> None:
        overworld = read("home/overworld.asm")
        step_hook = overworld.split("StepCountCheck::", 1)[1].split(
            "AllPokemonFainted::", 1
        )[0]
        self.assertLess(
            step_hook.index("BIT_SCRIPTED_MOVEMENT_STATE"),
            step_hook.index("UpdatePartyEggsOnStep"),
        )

        incubation = read("engine/pokemon/eggs.asm").split(
            "UpdatePartyEggsOnStep::", 1
        )[1].split("HatchPartyEgg::", 1)[0]
        self.assertIn("wPartyMon1", incubation)
        self.assertNotIn("wBoxMon", incubation)
        self.assertRegex(
            incubation,
            re.compile(
                r"; Big-endian 24-bit decrement\."
                r".*?sub 1.*?sbc 0.*?sbc 0",
                re.DOTALL,
            ),
        )

    def test_pending_hatch_runs_after_a_completed_step(self) -> None:
        overworld = read("home/overworld.asm")
        completed_step = overworld.split("; walking animation finished", 1)[1]
        self.assertLess(
            completed_step.index("call StepCountCheck"),
            completed_step.index("call HandlePendingEggHatch"),
        )
        self.assertLess(
            completed_step.index("call HandlePendingEggHatch"),
            completed_step.index("SafariZoneCheckSteps"),
        )

        handler = overworld.split("HandlePendingEggHatch:", 1)[1].split(
            "AllPokemonFainted::", 1
        )[0]
        for guard in (
            "wEggHatchPending",
            "BIT_SCRIPTED_MOVEMENT_STATE",
            "wIsInBattle",
            "wLinkState",
        ):
            with self.subTest(guard=guard):
                self.assertIn(guard, handler)
        self.assertIn("farcall HatchPartyEgg", handler)
        self.assertLess(
            handler.index("farcall HatchPartyEgg"),
            handler.index("ld hl, EggHatchingText"),
        )
        self.assertLess(
            handler.index("ld hl, EggHatchingText"),
            handler.index("callfar EvolveMon"),
        )
        self.assertLess(
            handler.index("callfar EvolveMon"),
            handler.index("ld hl, EggHatchedText"),
        )
        self.assertIn("ret nc", handler)
        self.assertIn("ld [wEvoOldSpecies], a", handler)
        self.assertIn("ld [wEvoNewSpecies], a", handler)
        self.assertIn("ld [wForceEvolution], a", handler)
        self.assertIn("call SaveScreenTilesToBuffer2", handler)
        self.assertIn("call TextBoxBorder", handler)
        self.assertIn("call CopyScreenTileBufferToVRAM", handler)
        self.assertIn("call LoadFontTilePatterns", handler)
        self.assertIn("call ReloadTilesetTilePatterns", handler)
        self.assertIn("call LoadScreenTilesFromBuffer2DisableBGTransfer", handler)
        self.assertIn("call RunDefaultPaletteCommand", handler)
        self.assertIn("call LoadGBPal", handler)
        self.assertIn("call UpdateSprites", handler)
        self.assertIn("call PlayDefaultMusic", handler)

    def test_hatch_event_announces_the_result_name(self) -> None:
        text = read("data/text/text_3.asm")
        hatching_text = text.split("_EggHatchingText::", 1)[1].split(
            "_EggHatchedText::", 1
        )[0]
        self.assertIn('text "Huh? The EGG is"', hatching_text)
        self.assertIn('line "hatching!"', hatching_text)
        self.assertIn("prompt", hatching_text)

        hatch_text = text.split("_EggHatchedText::", 1)[1].split(
            "_Colosseum3MonsText::", 1
        )[0]
        self.assertIn('text "Huh? "', hatch_text)
        self.assertIn("text_ram wNameBuffer", hatch_text)
        self.assertIn('line "from the EGG!"', hatch_text)
        self.assertIn("prompt", hatch_text)

    def test_hatching_reinitializes_runtime_data_and_registers_target(self) -> None:
        hatch = read("engine/pokemon/eggs.asm").split("HatchPartyEgg::", 1)[1]
        for token in (
            "wMonHType1",
            "wMonHType2",
            "wMonHCatchRate",
            "wMonHMoves",
            "wPartySpecies",
            "WriteMonMoves",
            "CalcExperience",
            "AddPartyMon_WriteMovePP",
            "CalcStats",
            "wPokedexOwned",
            "wPokedexSeen",
        ):
            with self.subTest(token=token):
                self.assertIn(token, hatch)

    def test_box_withdrawal_restores_move_type_after_egg_check(self) -> None:
        move_mon = read("engine/pokemon/add_mon.asm").split("_MoveMon::", 1)[1]
        egg_check = move_mon.split("cp EGG", 1)[1].split("call LoadMonData", 1)[0]
        self.assertIn("ld a, [wMoveMonType]", egg_check)
        self.assertLess(
            egg_check.index("ld a, [wMoveMonType]"),
            egg_check.index("srl a"),
        )

    def test_transient_pending_state_is_cleared(self) -> None:
        for path in (
            "engine/overworld/clear_variables.asm",
            "engine/movie/oak_speech/init_player_data.asm",
        ):
            with self.subTest(path=path):
                self.assertIn("ld [wEggHatchPending], a", read(path))

    def test_pending_state_does_not_expand_wram_layout(self) -> None:
        wram = read("ram/wram.asm")
        self.assertRegex(
            wram,
            re.compile(
                r"wEggHatchPending:: db\s*"
                r"wEggHatchPartyIndex:: db\s*"
                r"\s*ds 1\s*"
                r"wDexMinSeenMon::",
                re.MULTILINE,
            ),
        )

    def test_debug_start_exercises_egg_and_added_species(self) -> None:
        debug_party = read("engine/debug/debug_party.asm")
        debug_menu = read("engine/debug/debug_menu.asm")
        eggs = read("engine/pokemon/eggs.asm")
        added_species = (
            "SMOOCHUM",
            "ELEKID",
            "MAGBY",
            "POLITOED",
            "SLOWKING",
            "STEELIX",
            "KINGDRA",
            "SCIZOR",
            "PORYGON2",
            "PICHU",
            "CLEFFA",
            "IGGLYBUFF",
            "CROBAT",
            "BLISSEY",
        )
        box_table = eggs.split("DebugNewGameBoxMons:", 1)[1].split("ENDC", 1)[0]

        self.assertIn("db STARTER_PIKACHU, 5", debug_party)
        self.assertIn("ld c, PICHU", debug_party)
        self.assertIn("ld de, 16", debug_party)
        self.assertIn("farcall CreatePartyEgg", debug_party)
        self.assertEqual(debug_party.count("SetDebugNewGameBox"), 1)
        self.assertLess(
            debug_party.index("farcall SetDebugNewGameBox"),
            debug_party.index("call SetDebugNewGameParty"),
        )
        self.assertIn("ld a, 15", eggs)
        self.assertIn("ld a, PARTY_TO_BOX", eggs)
        self.assertNotIn("\tdb EGG", box_table)
        for species in added_species:
            with self.subTest(species=species):
                self.assertEqual(box_table.count(f"\tdb {species}\n"), 1)

        self.assertRegex(
            debug_menu,
            re.compile(
                r"set BIT_DEBUG_MODE, \[hl\]\s+"
                r"ld a, PEWTER_CITY\s+"
                r"ld \[wDefaultMap\], a"
            ),
        )


if __name__ == "__main__":
    unittest.main()
