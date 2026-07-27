# Encounter Balance Progression Specification

## Purpose

This document defines the player-progression contract for the full encounter-balance
sweep. The target is to import Yellow Legacy's encounter philosophy into Static
Yellow without removing Static Yellow's content, quality-of-life features, or
single-cartridge completion support.

This is not a request to copy Yellow Legacy's progression files wholesale. Trainer
teams should be designed against the resources documented here, and progression
changes should be targeted, reviewed by checkpoint, and merged into Static
Yellow's existing maps and systems.

## Fixed design rules

1. Every major fight must have at least two practical counterplay routes available
   without trading or excessive grinding.
2. A "practical" answer is obtainable before the fight, is no more than five
   levels below the current hard-mode cap when obtained or reasonably trained, and
   has its required move available at that point.
3. Counters should not all depend on one finite TM. Reusable TMs reduce this risk,
   but TM access must still be checked.
4. Optional gifts and rare encounters may be strong answers, but at least one
   answer should be commonly obtainable.
5. Preserve route-order freedom after Celadon. The badge-count cap system means
   Erika, Koga, Sabrina, and Blaine cannot assume one strict order unless the map
   scripts enforce it.
6. Wild tables are ported by intent: species, timing, encounter rate, and useful
   catch level. Static-exclusive maps and encounters are merged, not overwritten.
7. Normal mode remains uncapped. Hard mode uses the existing badge-count caps.

## Hard-mode checkpoints

The cap table is defined in `engine/battle/experience.asm` and is indexed by number
of badges, not leader identity.

| State | Current cap | Next benchmark | Availability/counterplay contract |
|---|---:|---|---|
| 0 badges | 15 | Brock | Common Water/Grass/Fighting pressure or reliable status must exist before Pewter. Early catches must not require grinding from single-digit levels to be useful. |
| 1 badge | 22 | Misty | Electric, Grass, status, and neutral special offense should be available. At least one non-Pikachu route is required. |
| 2 badges | 28 | Lt. Surge | Ground immunity/resistance counterplay must be available before Vermilion, with a second route through special bulk, status, or strong neutral damage. |
| 3 badges | 37 | nominally Erika | Fire, Flying, Bug, Ice, or Psychic pressure should be available. The Charmander gift must be usable near the curve rather than arrive as a grinding project. |
| 4 badges | 44 | nominally Koga | Psychic/Ground offense and status mitigation must be available. Because the fourth badge is order-flexible, encounters must also support Sabrina-first or Koga-first play. |
| 5 badges | 48 | nominally Sabrina | Physical pressure, Bug/Ghost interaction, status, and special bulk should offer multiple plans. Do not assume the player owns a unique gift or one shop TM. |
| 6 badges | 50 | nominally Blaine | Water, Ground, Rock, and special bulk must be available at useful levels. Surf access is allowed as a progression assumption. |
| 7 badges | 53 | Giovanni | Water/Grass/Ice and safe Ground answers must be available. Victory Road catches are not valid pre-Giovanni answers. |
| 8 badges | 65 | Elite Four/Champion | A complete six-Pokémon team with broad coverage must be feasible without grinding far beyond Victory Road levels. Late gifts should join close enough to the curve to compete. |
| Postgame | 100 | rematches | Static's high-level rematches remain a separate tuning tier. Main-story availability changes must not trivialize them accidentally. |

The labels "nominally" describe the intended curve, not a hard map-order
guarantee. Encounter implementers must record which badge-count variant a boss
script selects.

## Intended counter families by major fight

These are design requirements, not mandatory species lists. The availability
audit should name the actual species and moves that satisfy each row.

| Fight | Primary answers to support | Secondary answers to support | Avoid |
|---|---|---|---|
| Brock | Water/Grass/Fighting damage | Sleep, accuracy control, or special neutral damage | Making Pikachu grinding or one rare catch the only realistic path |
| Misty | Electric and Grass damage | Sleep/paralysis, special bulk, strong neutral damage | Requiring Pikachu specifically |
| Lt. Surge | Ground damage or Electric immunity | Bulky Grass, status, neutral physical pressure | A single Diglett encounter as the entire answer set |
| Erika | Fire/Flying/Bug/Ice/Psychic pressure | Poison resistance, status recovery, fast neutral attackers | Balancing solely around the optional Charmander |
| Koga | Psychic/Ground offense | Poison-resistant walls, paralysis/sleep control | Assuming one exact midgame badge order |
| Sabrina | Fast physical attackers and Bug/Ghost pressure where mechanically valid | Special bulk, paralysis, sleep, strong neutral physical moves | Requiring a finite or late TM for all viable plans |
| Blaine | Water/Ground/Rock offense | Special bulk and paralysis | Assuming the player caught a legendary |
| Giovanni | Water/Grass/Ice offense | Flying immunity to Ground, status, mixed coverage | Depending on Victory Road availability |
| Lorelei | Electric/Grass/Fighting coverage | Special bulk, status, mixed attackers | One-dimensional teams that demand a single species |
| Bruno | Water/Grass/Psychic/Flying coverage | Strong special neutral attacks | Letting one Psychic Pokémon invalidate the full team |
| Agatha | Ground/Psychic and strong physical pressure | Status control, Normal pivots, paralysis | Requiring Ghost damage alone |
| Lance | Ice/Rock/Electric coverage | Status and bulky Water types | Requiring a legendary or Game Corner grind |
| Champion | A balanced six-slot roster and route-dependent coverage | Status, speed control, defensive pivots | Countering only one rival evolution branch |

## Wild encounter audit and port decisions

Yellow Legacy and Static Yellow differ across 62 files under `data/wild`. Treat
this as an authored balance port, not a mechanical directory copy.

### Batch A: early game

Scope:

- Routes 1 through 25
- Viridian Forest
- Mt. Moon
- Diglett's Cave
- Rock Tunnel

For each table, record encounter rate, slot probability, species, level range,
first intended boss use, and whether the species needs a TM to perform that role.
Port Legacy timing when it improves counter diversity. Retain Static species when
they are required for 151 completion or exclusive content, replacing a redundant
slot rather than deleting the species.

Acceptance checks:

- Two practical plans for Brock, Misty, and Surge.
- Charmander is not the only credible Erika answer.
- No required counter appears only in a very low-probability slot.
- Catch levels track the current cap closely enough to avoid mandatory grinding.

### Batch B: midgame, late game, and fishing

Scope:

- Pokémon Tower, including Static's exclusive 8F
- Safari Zone
- Power Plant
- Pokémon Mansion
- Seafoam Islands
- Victory Road
- Cerulean Cave
- Old Rod, Good Rod, and Super Rod tables

Port Legacy's progression-aware species and levels where compatible. Preserve
Static's Pokémon Tower 8F table and merge it explicitly. Fishing is part of boss
counter availability and must be audited alongside grass/cave tables rather than
treated as post-processing.

Acceptance checks:

- Order-flexible answers exist for Erika/Koga/Sabrina.
- Surf-era Water encounters do not arrive so underleveled that they are unusable
  for Blaine or Giovanni.
- Victory Road supports final-team completion before the Elite Four.
- All 151 remain obtainable in one save.

## Gifts, trades, static encounters, and evolution

### Approved targeted gift changes

Subject to build and playtest verification, align these Static gifts with Legacy:

| Gift | Static level | Target level | Reason |
|---|---:|---:|---|
| Charmander, Route 24 | 10 | 13 | Keeps it usable on the post-Misty curve and as an Erika option |
| Squirtle, Vermilion | 10 | 15 | Reduces catch-up grinding while remaining below the Surge cap |
| Lapras, Silph Co. 7F | 15 | 35 | Makes a late gift a viable team member before the final gyms |
| Magikarp, Mt. Moon Center | 5 | 5 | Retain; its low level is an explicit investment choice |

Do not copy gift scripts wholesale; Static uses newer WRAM names and has unrelated
script changes.

### Trades

Preserve Static's trade table and trade framework, including its extra self-trade
sentinel and its changed species trades. Do not replace it with Legacy's table.
Audit each trade for:

- earliest access,
- requested species availability,
- received level behavior,
- whether the result is an intended boss counter,
- and whether it is still renameable as advertised.

Trades may provide bonus counterplay but cannot be the only practical answer.

### Static encounters

Preserve Static-exclusive static encounters. The legendary birds remain level 50
and Mewtwo remains level 70 in both projects. Static places level 70 Mew in
Cerulean Cave, while Legacy places it in Pokémon Mansion; retain Static's location
unless a separate narrative decision changes it. The S.S. Anne Snorlax interaction
only displays its Pokédex entry and exists in both projects; it is not a
Static-exclusive encounter.

Legendary and postgame static encounters are not valid assumptions for main-story
boss tuning unless their access is unambiguously before that boss.

### Evolution access

Preserve Static's tradeback support and dual trade/level fallback evolutions for
Kadabra, Graveler, Machoke, and Haunter. Do not copy Legacy's evolution entries
wholesale.

The acquisition-level forks are resolved:

- Graveler and Machoke use level 38 fallbacks.
- Kadabra and Haunter use level 42 fallbacks.
- Poliwag evolves into Poliwhirl at level 18.

Continue to audit stone availability before each intended boss use. The earlier
trade-evolution fallbacks are deliberate support for the flexible Koga/Sabrina
segment.

Celadon must continue to sell Fire, Thunder, Water, Leaf, and Moon Stones. Stone
access is a deliberate team-building feature and should be included when
evaluating counter availability.

## TM and item economy

Preserve:

- reusable TMs,
- TM51 Flamethrower,
- the move relearner,
- Static's post-Elite-Four all-TM shop,
- current bag/TM naming behavior,
- and Static-exclusive item systems.

Do not import Legacy's mart lists wholesale. Legacy sells many powerful TMs in
Celadon, Cinnabar, and Indigo Plateau; combined with reusable TMs, those shops
would increase player power much more than they do in Legacy.

Default policy:

1. Retain Static's current pre-Elite-Four TM placement and shop gating.
2. For each boss, audit the moves required by the counter families above.
3. Move or add a TM only if intended counterplay is otherwise unavailable.
4. Prefer natural learnsets or multiple species over making one shop TM mandatory.
5. Keep the all-TM shop postgame.

The economy audit must also check status-healing availability before status-heavy
bosses. Hard mode bans bag items during trainer battles, so in-battle consumable
access is not a substitute for team or move counterplay.

## EXP and anti-grind systems

Preserve Static's:

- toggleable key-item EXP All,
- existing hard-mode level-cap routine,
- capped-EXP messaging,
- and normal-mode uncapped progression.

Do not port Legacy's experience engine. Static's cap values are part of the
encounter contract in this document.

The README says Cheat Candy is given at the start, but the normal Oak grant is
currently commented out; it appears only in debug-party data. Treat Cheat Candy
as unavailable in a normal playthrough unless implementation changes. If it is
re-enabled later, it must remain an optional anti-grind tool and must not bypass
hard-mode caps.

## Counter availability matrix deliverable

Before encounter data is considered complete, add a working matrix (in this file
or a linked generated report) with one row per major fight and these fields:

The working matrix and playtest checklist are maintained in
[`encounter-balance-validation-report.md`](encounter-balance-validation-report.md).
Its 10 percent "common encounter" threshold is provisional pending user
confirmation.

| Field | Required content |
|---|---|
| Fight and badge-count state | Exact script variant and effective cap |
| Common answer 1 | Species, location, encounter probability, catch level, required move |
| Common answer 2 | Different species/family and acquisition details |
| Optional answer | Gift, trade, stone evolution, or rare encounter |
| Move access | Natural level, TM/HM location, or relearner |
| Resource caveat | Stone, money, detour, prior badge, or version-specific requirement |
| Validation | Build verified, data verified, and playtest result |

No row passes on type matchups alone; acquisition timing and move access must both
be demonstrated.

## Parallel implementation ownership

The following batches can be implemented independently after trainer boss rosters
and movesets are frozen:

1. Early wild tables.
2. Mid/late wild and rod tables.
3. Gifts, trades, static encounters, and evolution review.
4. TM/item economy, EXP verification, and counter matrix.

Batches 1 and 2 may edit only their assigned `data/wild` files. Batch 3 owns
targeted map scripts/objects, `data/events/trades.asm`, and reviewed evolution
entries. Batch 4 owns marts/TM placement proposals and documentation; experience
code changes require a separately approved defect or design change.

All batches must preserve unrelated Static changes and report conflicts rather
than resolving them through whole-file replacement.

## Resolved implementation forks

The approved selections `1A`, `2B`, `3B`, `4B`, `5A`, `6B`, and `7B` are
resolved in the implemented trainer baseline, authored wild/fishing merge,
targeted gift levels, evolution fallbacks, and preservation of Static-exclusive
completion content. The validation consequences are recorded in
[`encounter-balance-validation-report.md`](encounter-balance-validation-report.md).

The 10 percent definition of a common encounter remains provisional and is not
part of these resolved selections.

## Unresolved tuning questions

These require an explicit design decision or playtest evidence:

1. Are Legacy boss levels copied exactly, or are compositions/moves ported while
   levels remain aligned to Static's existing caps?
2. Should perfect trainer DVs remain for the entire story, only hard mode, only
   bosses, or only rematches?
3. Should reusable TMs remain available in hard mode, or is their power accounted
   for entirely through boss design?
4. Should Legacy's unchosen-fossil gift be restored in Fuchsia, or does Static's
   existing 151-completion path make it redundant?
5. Should Mew remain postgame in Cerulean Cave, or return to Legacy's Mansion
   placement?
6. Which badge-count variants are guaranteed for Erika, Koga, Sabrina, and Blaine
   when leaders are challenged out of the nominal order?
7. What encounter probability qualifies as "common" for a required counter:
   20 percent, 10 percent, or another threshold?
8. What is the acceptable catch-up distance for a newly obtained Pokémon:
    five levels below cap, one ordinary route of training, or another measure?
9. Are the level-75 gym rematches and level-85/90 League rematches retained
    unchanged, or redesigned after the main-story sweep?
10. Should the early gift-level changes be adopted directly or tuned after the
    final trainer level curve is selected?

## Completion criteria

The progression portion of the sweep is complete when:

- every major-fight matrix row has two demonstrated practical answers;
- all 151 Pokémon remain obtainable;
- Static-exclusive maps, gifts, trades, and static encounters are preserved;
- hard-mode caps and normal-mode EXP behavior pass build/runtime checks;
- no intended counter depends solely on a legendary, rare slot, trade, or unique
  finite resource;
- wild catch levels and gift levels have been checked against the actual boss
  curve;
- and all unresolved questions above are either decided or explicitly deferred
  with an owner.
