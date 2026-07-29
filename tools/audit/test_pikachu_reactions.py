"""Static contracts for event-driven Pikachu companion reactions."""

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def _source(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


class PikachuReactionTests(unittest.TestCase):
    def test_walking_does_not_queue_random_mood_reactions(self) -> None:
        happiness = _source("engine/events/pikachu_happiness.asm")
        update_start = happiness.index("UpdatePikachuCompanionOnStep::")
        update_end = happiness.index(
            "\nUpdatePikachuCompanionIdle::",
            update_start,
        )
        update = happiness[update_start:update_end]

        self.assertNotIn(".tryQueueReaction", update)
        self.assertNotIn("PIKACOMPANION_REACTION_SMILE", update)

    def test_catching_a_pokemon_does_not_queue_a_portrait(self) -> None:
        items = _source("engine/items/item_effects.asm")
        caught_start = items.index(".skipShowingPokedexData")
        caught_end = items.index("\n.sendToBox", caught_start)
        caught = items[caught_start:caught_end]

        self.assertNotIn("SetPendingPikachuEmotion", caught)
        self.assertNotIn("PIKACHU_PENDING_CAUGHT_MON", caught)

    def test_happiness_tier_crossings_still_queue_reactions(self) -> None:
        happiness = _source("engine/events/pikachu_happiness.asm")
        tier_start = happiness.index(".queueHappinessTierReaction")
        tier_end = happiness.index("\nHappinessChangeTable:", tier_start)
        tier = happiness[tier_start:tier_end]

        self.assertIn("cp PIKAHAPPY_WALKING\n\tret z", tier)
        self.assertIn("ld b, PIKACOMPANION_REACTION_HEART", tier)
        self.assertIn("ld b, PIKACOMPANION_REACTION_BOLT", tier)


if __name__ == "__main__":
    unittest.main()
