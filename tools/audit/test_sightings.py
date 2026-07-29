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

    def test_species_tables_are_weighted_and_end_at_full_probability(self) -> None:
        sightings = _source("engine/events/wild_sightings.asm")
        table_names = {
            table_name
            for profile in re.findall(
                r"^\s*sighting_profile\s+(.+)$",
                sightings,
                re.MULTILINE,
            )
            for table_name in re.findall(r"([A-Za-z0-9_]+)", profile)[-2:]
        }
        table_names.remove("NoWildSightings")

        self.assertGreater(len(table_names), 1)
        for table_name in table_names:
            table = re.search(
                rf"(?ms)^{re.escape(table_name)}:\r?\n(.*?)(?=^[A-Za-z]\w*:\r?$|\Z)",
                sightings,
            )
            self.assertIsNotNone(table, table_name)
            entries = re.findall(
                r"^\s*sighting_mon\s+\$([0-9a-f]{2}),\s+([A-Z0-9_]+)",
                table.group(1),
                re.MULTILINE,
            )
            thresholds = [int(threshold, 16) for threshold, _ in entries]
            bucket_sizes = [
                current - previous
                for previous, current in zip(
                    [-1, *thresholds[:-1]],
                    thresholds,
                )
            ]
            self.assertGreater(len(entries), 1, table_name)
            self.assertEqual(thresholds[-1], 0xFF, table_name)
            self.assertEqual(thresholds, sorted(set(thresholds)), table_name)
            # Five percent of 256 rolls alternates between 12- and 13-byte
            # buckets when cumulative percentage boundaries are rounded.
            self.assertGreaterEqual(min(bucket_sizes), 12, table_name)
            self.assertRegex(table.group(1), r"(?m)^\s*db 0\s*$")

    def test_profile_method_flags_match_populated_table_pointers(self) -> None:
        sightings = _source("engine/events/wild_sightings.asm")
        profiles = re.findall(
            r"^\s*sighting_profile\s+(.+?),\s*([A-Za-z0-9_]+),\s*([A-Za-z0-9_]+)",
            sightings,
            re.MULTILINE,
        )

        for flags, land_table, water_table in profiles:
            with self.subTest(flags=flags):
                self.assertEqual(
                    land_table != "NoWildSightings",
                    "SIGHTING_METHOD_LAND" in flags,
                )
                self.assertEqual(
                    water_table != "NoWildSightings",
                    "SIGHTING_METHOD_WATER" in flags,
                )

    def test_sighting_species_do_not_overlap_their_profiles_normal_species(
        self,
    ) -> None:
        sightings = _source("engine/events/wild_sightings.asm")
        sighting_maps = _source("data/wild/sighting_maps.asm")
        wild_pointers = _source("data/wild/grass_water.asm")

        profiles = re.findall(
            r"^\s*sighting_profile\s+[^,]+,\s*([A-Za-z0-9_]+),\s*([A-Za-z0-9_]+)",
            sightings,
            re.MULTILINE,
        )
        profile_names = re.findall(
            r"^\s*const\s+(SIGHTING_PROFILE_[A-Z0-9_]+)",
            _source("constants/sighting_constants.asm"),
            re.MULTILINE,
        )
        profile_tables = dict(zip(profile_names, profiles, strict=True))
        map_profiles = re.findall(
            r"^\s*sighting_map\s+[^,]+,\s+([A-Z0-9_]+)",
            sighting_maps,
            re.MULTILINE,
        )
        map_wild_data = re.findall(
            r"^\s*dw\s+([A-Za-z0-9_]+)",
            wild_pointers[: wild_pointers.index("assert_table_length NUM_MAPS")],
            re.MULTILINE,
        )

        wild_sources = "\n".join(
            path.read_text(encoding="utf-8")
            for path in (ROOT / "data/wild/maps").glob("*.asm")
        )
        normal_species: dict[str, set[str]] = {
            profile: set() for profile in profile_tables
        }
        for profile, wild_label in zip(
            map_profiles,
            map_wild_data,
            strict=True,
        ):
            if profile == "SIGHTING_PROFILE_NONE":
                continue
            wild_table = re.search(
                rf"(?ms)^{re.escape(wild_label)}:\r?\n(.*?)(?=^[A-Za-z]\w*:\r?$|\Z)",
                wild_sources,
            )
            self.assertIsNotNone(wild_table, wild_label)
            normal_species[profile].update(
                re.findall(
                    r"^\s*db\s+\d+,\s*([A-Z0-9_]+)",
                    wild_table.group(1),
                    re.MULTILINE,
                )
            )

        overlaps = []
        for profile, tables in profile_tables.items():
            for table_name in set(tables) - {"NoWildSightings"}:
                table = re.search(
                    rf"(?ms)^{re.escape(table_name)}:\r?\n(.*?)(?=^[A-Za-z]\w*:\r?$|\Z)",
                    sightings,
                )
                self.assertIsNotNone(table, table_name)
                species = set(
                    re.findall(
                        r"^\s*sighting_mon\s+\$[0-9a-f]{2},\s+([A-Z0-9_]+)",
                        table.group(1),
                        re.MULTILINE,
                    )
                )
                shared_species = species & normal_species[profile]
                if shared_species:
                    overlaps.append(
                        f"{table_name}: {sorted(shared_species)}"
                    )
        self.assertFalse(
            overlaps,
            "Sighting tables overlap normal encounters: " + "; ".join(overlaps),
        )

    def test_sightings_exclude_starters_fossils_and_legendaries(self) -> None:
        sightings = _source("engine/events/wild_sightings.asm")
        species = set(
            re.findall(
                r"^\s*sighting_mon\s+\$[0-9a-f]{2},\s+([A-Z0-9_]+)",
                sightings,
                re.MULTILINE,
            )
        )
        excluded = {
            "PIKACHU", "RAICHU",
            "EEVEE", "VAPOREON", "JOLTEON", "FLAREON",
            "BULBASAUR", "IVYSAUR", "VENUSAUR",
            "CHARMANDER", "CHARMELEON", "CHARIZARD",
            "SQUIRTLE", "WARTORTLE", "BLASTOISE",
            "OMANYTE", "OMASTAR", "KABUTO", "KABUTOPS", "AERODACTYL",
            "ARTICUNO", "ZAPDOS", "MOLTRES", "MEWTWO", "MEW",
        }
        self.assertFalse(species & excluded)

    def test_land_and_water_tables_use_disjoint_species(self) -> None:
        sightings = _source("engine/events/wild_sightings.asm")
        profiles = re.findall(
            r"^\s*sighting_profile\s+[^,]+,\s*([A-Za-z0-9_]+),\s*([A-Za-z0-9_]+)",
            sightings,
            re.MULTILINE,
        )

        def table_species(table_name: str) -> set[str]:
            table = re.search(
                rf"(?ms)^{re.escape(table_name)}:\r?\n(.*?)(?=^[A-Za-z]\w*:\r?$|\Z)",
                sightings,
            )
            self.assertIsNotNone(table, table_name)
            return set(
                re.findall(
                    r"^\s*sighting_mon\s+\$[0-9a-f]{2},\s+([A-Z0-9_]+)",
                    table.group(1),
                    re.MULTILINE,
                )
            )

        for land_table, water_table in profiles:
            if "NoWildSightings" in (land_table, water_table):
                continue
            shared_species = (
                table_species(land_table) & table_species(water_table)
            )
            self.assertFalse(
                shared_species,
                f"{land_table} and {water_table} share "
                f"{sorted(shared_species)}",
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

    def test_encounter_method_selects_a_dedicated_species_table(self) -> None:
        sightings = _source("engine/events/wild_sightings.asm")
        constants = _source("constants/sighting_constants.asm")
        selector_start = sightings.index("TryReplaceWithWildSighting::")
        selector_end = sightings.index("\nClearWildSighting::", selector_start)
        selector = sightings[selector_start:selector_end]
        table_selector_start = sightings.index("GetWildSightingTable:")
        table_selector_end = sightings.index(
            '\nINCLUDE "data/wild/sighting_maps.asm"',
            table_selector_start,
        )
        table_selector = sightings[table_selector_start:table_selector_end]

        self.assertIn("call GetWildSightingTable", selector)
        self.assertIn("cp SIGHTING_METHOD_WATER", table_selector)
        self.assertIn("inc hl\n\tinc hl", table_selector)
        self.assertIn("dw \\3", constants)
        self.assertIn("table_width 5, WildSightingProfiles", sightings)

    def test_sighting_capture_penalty_uses_the_effective_rate(self) -> None:
        item_effects = _source("engine/items/item_effects.asm")
        ball_start = item_effects.index("ItemUseBall:")
        ball_end = item_effects.index("\nItemUseBallText00:", ball_start)
        ball = item_effects[ball_start:ball_end]
        helper_start = ball.index("GetEffectiveEnemyCatchRate:")
        helper = ball[helper_start:]

        self.assertEqual(ball.count("call GetEffectiveEnemyCatchRate"), 2)
        self.assertIn("bit SIGHTING_BATTLE_F, a", helper)
        self.assertIn("ld a, [wEnemyMonActualCatchRate]", helper)
        self.assertIn("push bc", helper)
        self.assertIn("srl a\n\tsrl a", helper)
        self.assertIn("sub c", helper)
        self.assertIn("pop bc", helper)
        master_ball = ball.index("cp MASTER_BALL")
        first_penalty = ball.index("call GetEffectiveEnemyCatchRate")
        self.assertLess(master_ball, first_penalty)

    def test_world_step_update_is_independent_from_companion_update(self) -> None:
        overworld = _source("home/overworld.asm")
        sighting_call = overworld.index("farcall UpdateWildSightingOnStep")
        companion_call = overworld.index("farcall UpdatePikachuCompanionOnStep")
        self.assertLess(sighting_call, companion_call)

    def test_pikachu_sighting_hint_uses_question_bubble(self) -> None:
        happiness = _source("engine/events/pikachu_happiness.asm")
        portrait_start = happiness.index(".portraitReady")
        portrait_end = happiness.index("\n.queuePendingPortraitAlert", portrait_start)
        portrait = happiness[portrait_start:portrait_end]

        sighting_branch = (
            "cp PIKACHU_PENDING_SIGHTING\n"
            "\tjr z, .portraitSighting"
        )
        sighting_handler = (
            ".portraitSighting\n"
            "\tld b, QUESTION_BUBBLE\n"
            "\tjr .facePlayer"
        )
        self.assertIn(sighting_branch, portrait)
        self.assertIn(sighting_handler, portrait)

    def test_pikachu_sighting_interaction_uses_emotion_27(self) -> None:
        emotions = _source("engine/pikachu/pikachu_emotions.asm")
        table_start = emotions.index(".Emotions:")
        table_end = emotions.index("\n\nIsPlayerPikachuAsleepInParty:", table_start)
        pending_emotions = [
            line.strip()
            for line in emotions[table_start:table_end].splitlines()[1:]
            if line.strip()
        ]

        self.assertEqual(len(pending_emotions), 6)
        self.assertEqual(
            pending_emotions[-1],
            "dpikaemotion PikachuEmotion27",
        )

    def test_only_eligible_steps_advance_the_interval_and_rng_preserves_zone(self) -> None:
        sightings = _source("engine/events/wild_sightings.asm")
        update_start = sightings.index("UpdateWildSightingOnStep::")
        update_end = sightings.index("\nValidateWildSightingZone::", update_start)
        update = sightings[update_start:update_end]

        eligibility = update.index("call GetCurrentWildSightingZoneAndProfile")
        terrain = update.index("call GetCurrentWildSightingStepMethod")
        counter = update.index("inc [hl]")
        self.assertLess(eligibility, counter)
        self.assertLess(terrain, counter)
        terrain_start = sightings.index("GetCurrentWildSightingStepMethod:")
        terrain_end = sightings.index("\nValidateWildSightingZone::", terrain_start)
        terrain_source = sightings[terrain_start:terrain_end]
        self.assertIn("callfar IsPlayerStandingOnDoorTileOrWarpTile", terrain_source)
        self.assertIn("callfar IsPlayerJustOutsideMap", terrain_source)
        self.assertIn(
            "push bc\n\t\tcall Random\n\t\tcp SIGHTING_TRIGGER_CHANCE\n\t\tpop bc",
            update,
        )

    def test_warp_and_connected_map_entries_validate_the_active_zone(self) -> None:
        overworld = _source("home/overworld.asm")
        clear_variables = _source("engine/overworld/clear_variables.asm")
        self.assertIn("callfar ValidateWildSightingZone", clear_variables)
        self.assertIn(
            "call LoadMapHeader\n\tfarcall ValidateWildSightingZone",
            overworld,
        )


if __name__ == "__main__":
    unittest.main()
