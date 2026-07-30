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
        self.assertIn("ld hl, wPartyMon1CatchRate", constructor)
        self.assertIn("ld de, MON_EXP - MON_CATCH_RATE", constructor)
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

    def test_hatching_reinitializes_runtime_data_and_registers_target(self) -> None:
        hatch = read("engine/pokemon/eggs.asm").split("HatchPartyEgg::", 1)[1]
        for token in (
            "wMonHType1",
            "wMonHType2",
            "wMonHCatchRate",
            "wMonHMoves",
            "CalcExperience",
            "AddPartyMon_WriteMovePP",
            "CalcStats",
            "wPokedexOwned",
            "wPokedexSeen",
        ):
            with self.subTest(token=token):
                self.assertIn(token, hatch)

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


if __name__ == "__main__":
    unittest.main()
