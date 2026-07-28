import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def matching_lines(path: str, pattern: str) -> list[str]:
    regex = re.compile(pattern)
    return [
        line
        for line in (ROOT / path).read_text(encoding="utf-8").splitlines()
        if regex.match(line)
    ]


class MoveTableTests(unittest.TestCase):
    def test_parallel_move_tables_stay_aligned(self) -> None:
        move_rows = matching_lines("data/moves/moves.asm", r"^\s*move\s+")
        expected = len(move_rows)
        tables = {
            "names": matching_lines("data/moves/names.asm", r'^\s*li\s+"'),
            "descriptions": matching_lines(
                "data/moves/descriptions.asm", r"^\s*dw\s+\w+Description$"
            ),
            "movedex entries": matching_lines(
                "data/moves/movedex_entries.asm", r"^\s*dw\s+\w+DexEntry$"
            ),
            "movedex order": matching_lines(
                "data/moves/movedex_order.asm", r"^\s*db\s+[A-Z][A-Z0-9_]*\s*$"
            ),
        }
        for label, rows in tables.items():
            with self.subTest(table=label):
                self.assertEqual(expected, len(rows))

    def test_struggle_remains_the_last_move(self) -> None:
        move_rows = matching_lines("data/moves/moves.asm", r"^\s*move\s+")
        self.assertRegex(move_rows[-1], r"^\s*move\s+STRUGGLE,")

    def test_movedex_order_contains_each_move_once(self) -> None:
        rows = matching_lines(
            "data/moves/movedex_order.asm", r"^\s*db\s+[A-Z][A-Z0-9_]*\s*$"
        )
        moves = [re.search(r"\bdb\s+([A-Z][A-Z0-9_]*)", row).group(1) for row in rows]
        self.assertEqual(len(moves), len(set(moves)))

    def test_replaced_tms_have_curated_compatibility(self) -> None:
        compatibility = (
            ROOT / "data/moves/curated_tm_compatibility.asm"
        ).read_text(encoding="utf-8")
        replaced_tms = {
            "X_SCISSOR",
            "ROOST",
            "WATER_PULSE",
            "DRAGONBREATH",
            "ROCK_TOMB",
            "BULLET_SEED",
            "SHADOW_BALL",
            "DRILL_RUN",
            "SUPERPOWER",
        }
        curated_moves = set(
            re.findall(r"^\s*db\s+([A-Z][A-Z0-9_]*)\s*$", compatibility, re.MULTILINE)
        )
        self.assertTrue(replaced_tms <= curated_moves)

    def test_advanced_move_metadata_is_registered(self) -> None:
        priority = (ROOT / "data/battle/priority_moves.asm").read_text(encoding="utf-8")
        critical = (
            ROOT / "data/battle/critical_hit_moves.asm"
        ).read_text(encoding="utf-8")
        for move in ("MACH_PUNCH", "AQUA_JET", "EXTREMESPEED"):
            with self.subTest(priority_move=move):
                self.assertRegex(priority, rf"\b{move}\b")
        for move in ("DRILL_RUN", "AIR_CUTTER"):
            with self.subTest(high_critical_move=move):
                self.assertRegex(critical, rf"\b{move}\b")


if __name__ == "__main__":
    unittest.main()
