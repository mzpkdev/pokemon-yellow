"""Static contracts for the data-driven wild sighting framework."""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]


def _source(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class WildSightingFrameworkTests(unittest.TestCase):
    def test_every_map_has_an_ordered_zone_and_profile_record(self) -> None:
        map_constants = _source("constants/map_constants.asm")
        sighting_maps = _source("data/wild/sighting_maps.asm")

        maps = re.findall(r"^\s*map_const\s+([A-Z0-9_]+),", map_constants, re.MULTILINE)
        records = re.findall(
            r"^\s*sighting_map\s+([A-Z0-9_]+),\s+([A-Z0-9_]+)\s*;\s*([A-Z0-9_]+)",
            sighting_maps,
            re.MULTILINE,
        )

        self.assertEqual(len(records), len(maps))
        self.assertEqual([record[2] for record in records], maps)
        self.assertIn("assert_table_length NUM_MAPS", sighting_maps)

    def test_only_maps_with_normal_wild_data_receive_profiles(self) -> None:
        wild_pointers = _source("data/wild/grass_water.asm")
        sighting_maps = _source("data/wild/sighting_maps.asm")

        wild_rows = re.findall(
            r"^\s*dw\s+([A-Za-z0-9_]+)",
            wild_pointers,
            re.MULTILINE,
        )
        sighting_rows = re.findall(
            r"^\s*sighting_map\s+([A-Z0-9_]+),\s+([A-Z0-9_]+)\s*;\s*([A-Z0-9_]+)",
            sighting_maps,
            re.MULTILINE,
        )

        self.assertEqual(len(wild_rows), len(sighting_rows))
        for wild_data, (zone, profile, _) in zip(
            wild_rows, sighting_rows, strict=True
        ):
            if wild_data == "NothingWildMons":
                self.assertEqual(zone, "SIGHTING_ZONE_NONE")
                self.assertEqual(profile, "SIGHTING_PROFILE_NONE")
            else:
                self.assertNotEqual(zone, "SIGHTING_ZONE_NONE")
                self.assertNotEqual(profile, "SIGHTING_PROFILE_NONE")

    def test_production_species_tables_are_empty_placeholders(self) -> None:
        sightings = _source("engine/events/wild_sightings.asm")
        production_sightings = re.sub(
            r"(?ms)^IF DEF\(_DEBUG\)\r?\n.*?^ENDC\r?\n",
            "",
            sightings,
        )
        table_names = re.findall(
            r"^\s*sighting_profile\s+[^,]+,\s*([A-Za-z0-9_]+)",
            sightings,
            re.MULTILINE,
        )

        self.assertGreater(len(table_names), 1)
        for table_name in table_names:
            self.assertRegex(
                production_sightings,
                rf"(?m)^{re.escape(table_name)}:\r?\n\s*db 0\s*$",
            )

    def test_encounter_hook_runs_after_repel_and_preserves_level(self) -> None:
        encounters = _source("engine/battle/wild_encounters.asm")
        sightings = _source("engine/events/wild_sightings.asm")

        repel_check = encounters.index("cp b\n\tjr c, .CantEncounter2")
        hook = encounters.index("callfar TryReplaceWithWildSighting")
        self.assertGreater(hook, repel_check)

        selector_start = sightings.index("TryReplaceWithWildSighting::")
        selector_end = sightings.index("\nClearWildSighting::", selector_start)
        selector = sightings[selector_start:selector_end]
        self.assertNotIn("wCurEnemyLevel", selector)
        self.assertIn("ld [wCurPartySpecies], a", selector)
        self.assertIn("ld [wEnemyMonSpecies2], a", selector)
        self.assertLess(selector.index("call ClearWildSighting"), selector.index("ret", selector.index(".gotSpecies")))

    def test_world_step_update_is_independent_from_companion_update(self) -> None:
        overworld = _source("home/overworld.asm")
        sighting_call = overworld.index("farcall UpdateWildSightingOnStep")
        companion_call = overworld.index("farcall UpdatePikachuCompanionOnStep")
        self.assertLess(sighting_call, companion_call)


if __name__ == "__main__":
    unittest.main()
