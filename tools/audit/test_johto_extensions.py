import re
import struct
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]

NEW_SPECIES = (
    "SMOOCHUM",
    "ELEKID",
    "MAGBY",
    "POLITOED",
    "SLOWKING",
    "STEELIX",
    "KINGDRA",
    "SCIZOR",
    "PORYGON2",
)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def evolution_rows(species: str) -> list[str]:
    data = read("data/pokemon/evos_moves.asm")
    match = re.search(
        rf"(?m)^{species.title().replace('_', '')}EvosMoves:\s*$"
        rf"(?P<body>.*?)(?=^\s*db\s+0(?:\s*;.*)?$)",
        data,
        re.DOTALL | re.MULTILINE,
    )
    if match is None:
        raise AssertionError(f"missing evolution data for {species}")
    return re.findall(r"(?m)^\s*db\s+([^;\r\n]+)", match.group("body"))


class JohtoExtensionTests(unittest.TestCase):
    def test_new_dex_entries_are_appended_in_order(self) -> None:
        constants = re.findall(
            r"(?m)^\s*const\s+(DEX_[A-Z0-9_]+)\b",
            read("constants/pokedex_constants.asm"),
        )
        self.assertEqual(160, len(constants))
        self.assertEqual(
            ["DEX_MEW", *(f"DEX_{species}" for species in NEW_SPECIES)],
            constants[150:],
        )

    def test_babies_use_their_gen2_level_evolutions(self) -> None:
        expected = {
            "SMOOCHUM": "EVOLVE_LEVEL, 30, JYNX",
            "ELEKID": "EVOLVE_LEVEL, 30, ELECTABUZZ",
            "MAGBY": "EVOLVE_LEVEL, 30, MAGMAR",
        }
        for species, row in expected.items():
            with self.subTest(species=species):
                self.assertEqual([row], evolution_rows(species))

    def test_trade_evolutions_are_first_and_branches_are_preserved(self) -> None:
        expected = {
            "POLIWHIRL": [
                "EVOLVE_TRADE, 1, POLITOED",
                "EVOLVE_ITEM, WATER_STONE, 1, POLIWRATH",
            ],
            "SLOWPOKE": [
                "EVOLVE_TRADE, 1, SLOWKING",
                "EVOLVE_LEVEL, 37, SLOWBRO",
            ],
            "ONIX": ["EVOLVE_TRADE, 1, STEELIX"],
            "SEADRA": ["EVOLVE_TRADE, 1, KINGDRA"],
            "SCYTHER": ["EVOLVE_TRADE, 1, SCIZOR"],
            "PORYGON": ["EVOLVE_TRADE, 1, PORYGON2"],
        }
        for species, rows in expected.items():
            with self.subTest(species=species):
                self.assertEqual(rows, evolution_rows(species))

    def test_new_sprites_are_48_pixels_square(self) -> None:
        paths = [
            ROOT / "gfx/pokemon" / facing / f"{species.lower()}{suffix}.png"
            for species in NEW_SPECIES
            for facing, suffix in (("front", ""), ("back", "b"))
        ]
        self.assertEqual(18, len(paths))
        for path in paths:
            with self.subTest(sprite=path.relative_to(ROOT).as_posix()):
                header = path.read_bytes()[:24]
                self.assertEqual(b"\x89PNG\r\n\x1a\n", header[:8])
                self.assertEqual(b"IHDR", header[12:16])
                self.assertEqual((48, 48), struct.unpack(">II", header[16:24]))

    def test_expanded_dex_flags_use_the_reserved_save_space(self) -> None:
        wram = read("ram/wram.asm")
        self.assertRegex(
            wram,
            r"(?s)wPokedexOwned::\s+flag_array\s+NUM_POKEMON\s+"
            r"wPokedexOwnedEnd::\s+"
            r"wPokedexSeen::\s+flag_array\s+NUM_POKEMON\s+"
            r"wPokedexSeenEnd::.*?\n\s*ds\s+18\b",
        )

    def test_babies_are_not_placed_in_the_world(self) -> None:
        source_roots = (
            "data/wild",
            "data/events",
            "data/trainers",
            "maps",
        )
        sources = "\n".join(
            path.read_text(encoding="utf-8")
            for source_root in source_roots
            for path in (ROOT / source_root).rglob("*.asm")
        )
        for species in ("SMOOCHUM", "ELEKID", "MAGBY"):
            with self.subTest(species=species):
                self.assertNotRegex(sources, rf"\b{species}\b")


if __name__ == "__main__":
    unittest.main()
