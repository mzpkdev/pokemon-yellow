import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class EggGuardTests(unittest.TestCase):
    def test_zero_hp_eggs_reuse_shared_fainted_checks(self) -> None:
        battle = read("engine/battle/core.asm")
        any_alive = battle[
            battle.index("AnyPartyAlive::") : battle.index(
                "; tests if player mon has fainted"
            )
        ]
        has_fainted = battle[
            battle.index("HasMonFainted:") : battle.index("NoWillText:")
        ]
        self.assertNotIn("cp EGG", any_alive)
        self.assertNotIn("cp EGG", has_fainted)
        constructor = read("engine/pokemon/eggs.asm").split(
            "UpdatePartyEggsOnStep::", 1
        )[0]
        self.assertIn("ld hl, wPartyMon1HP", constructor)
        self.assertIn("ld hl, wPartyMon1MaxHP", constructor)

    def test_party_receipt_paths_skip_egg_pokedex_flags(self) -> None:
        add_mon = read("engine/pokemon/add_mon.asm")
        self.assertEqual(2, len(re.findall(r"cp EGG\s+jr z, \.skipPokedex", add_mon)))

        give_mon = read("engine/events/give_pokemon.asm")
        set_owned = give_mon[give_mon.index("SetPokedexOwnedFlag:") :]
        self.assertRegex(set_owned, r"cp EGG\s+jr z, \.skipPokedex")

    def test_self_trade_rejects_eggs_before_trade_setup(self) -> None:
        trades = read("engine/events/in_game_trades.asm")
        selection = trades[
            trades.index("InGameTrade_DoTrade:") : trades.index(
                "InGameTrade_RestoreScreen:"
            )
        ]
        egg_guard = selection.index("cp EGG")
        self.assertLess(egg_guard, selection.index("TradeSelf_PrepareTradeData"))
        self.assertRegex(
            selection,
            r"(?s)cp NO_MON\s+jr nz, \.check_required_mon.*?"
            r"cp EGG\s+ld a, \$2\s+jp z, \.tradeFailed",
        )
        self.assertRegex(
            trades,
            r"(?s)TradeTextPointers4:.*?"
            r"dw InGameEggCannotBeTradedText",
        )

    def test_cable_trade_rejects_eggs_before_serial_exchange(self) -> None:
        cable = read("engine/link/cable_club.asm")
        chose_trade_start = cable.index(".choseTrade\n")
        chose_trade = cable[
            chose_trade_start : cable.index(".statsTrade", chose_trade_start)
        ]
        self.assertRegex(chose_trade, r"cp EGG\s+jr z, \.eggCannotBeTraded")
        self.assertLess(
            chose_trade.index("cp EGG"),
            chose_trade.index("Serial_PrintWaitingTextAndSyncAndExchangeNybble"),
        )
        rejection = chose_trade.index(".eggCannotBeTraded")
        cancel = chose_trade.index("ld a, $f", rejection)
        cancel_sync = chose_trade.index(
            "call Serial_PrintWaitingTextAndSyncAndExchangeNybble", cancel
        )
        message = chose_trade.index("ld hl, LinkEggCannotBeTradedText", cancel_sync)
        self.assertLess(rejection, cancel)
        self.assertLess(cancel, cancel_sync)
        self.assertLess(cancel_sync, message)

    def test_trade_rejection_text_is_shared(self) -> None:
        self.assertIn(
            '_EggCannotBeTradedText::\n\ttext "An EGG can\'t be"',
            read("data/text/text_3.asm"),
        )
        self.assertIn(
            "text_far _EggCannotBeTradedText",
            read("engine/events/in_game_trades.asm"),
        )
        self.assertIn(
            "text_far _EggCannotBeTradedText",
            read("engine/link/cable_club.asm"),
        )


if __name__ == "__main__":
    unittest.main()
