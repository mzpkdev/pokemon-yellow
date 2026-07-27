# Yellow Legacy encounter-balance port specification

This document specifies the first implementation pass for porting encounter balance
from `Pokemon_Yellow_Legacy` into Static Yellow (`pokemon-yellow`). It is keyed by
trainer class and 1-based trainer ordinal because those two bytes are the actual
runtime identity of a trainer party.

## Safety rules

- Do not insert, delete, or reorder records inside a trainer class. Map objects,
  scripts, and `SpecialTrainerMoves` all depend on the ordinal.
- Change `data/trainers/parties.asm` and the matching
  `data/trainers/special_moves.asm` records together.
- Validate every special move after changing a party: party slot must exist, move
  slot must be 1 through 4, and the move must still suit the Pokémon in that slot.
- Keep Static's trainer constants and pointer-table order. Legacy has incompatible
  classes (`SMITH`, `CRAIG`, and `WEEBRA`) where Static has a different layout.
- Keep Static-exclusive encounters and systems unless a separate specification
  explicitly replaces them.
- Do not globally copy `move_choices.asm` or `ai_pointers.asm`. Those tables are
  class-wide, so a boss-motivated change can alter every encounter in that class.

Party notation is `LEVEL SPECIES`. “Legacy exact” means use both the Legacy
composition and its per-Pokémon levels. For rematches, use the Legacy composition
and relative ordering but scale it into Static's existing postgame band.

## Initial level policy

- Main story through the Champion: start with Legacy's exact party and levels.
  This gives a faithful balance baseline and avoids mixing two tuning models before
  playtesting.
- Gym rematches: use Legacy species and move design, scaled to levels 74–75. Put
  Legacy's lower-level members at 74 and its aces at 75.
- Elite Four rematches: use Legacy species and move design, scaled to levels
  82–85. Preserve relative ordering; reserve 85 for the ace.
- Champion rematch: use Legacy composition at levels 87–90, with the ace at 90.
- Static-only Janine, Joy, Jenny, Oak, and any other extra battle remain unchanged
  in the first pass. They receive a separate tuning pass after the imported curve
  is playable.

## Gym Leaders

All first battles are selected by the leader's map object. Rematches and
order-dependent variants are assigned directly by the named map script.

| Key and selector | Current Static party | Legacy party | Proposed first pass | Special-move and AI risk |
|---|---|---|---|---|
| `BROCK:1`; `data/maps/objects/PewterGym.asm` | 12 Geodude, 12 Zubat, 15 Onix | 10 Geodude, 12 Onix | Legacy exact | Party shrinks 3→2. Replace the keyed move record; Static's slot 2 is Zubat while Legacy's slot 2 is Onix. Brock's class-wide AI mask must not be changed in this batch. |
| `BROCK:2`; `scripts/PewterGym.asm` rematch | six at 75: Golem, Golbat, Aerodactyl, Ninetales, Omastar, Onix | 64 Omastar, 65 Onix, 64 Kabutops, 64 Golem, 64 Ninetales, 65 Aerodactyl | Legacy species at 74–75 | Six slots remain, but every slot changes. Port/remap the entire keyed move record. |
| `MISTY:1`; `data/maps/objects/CeruleanGym.asm` | 18 Psyduck, 18 Staryu, 22 Starmie | 19 Psyduck, 18 Goldeen, 21 Starmie | Legacy exact | Slot 2 changes species. Replace the complete keyed move record. |
| `MISTY:2`; `scripts/CeruleanGym.asm` rematch | six at 75: Golduck, Gyarados, Starmie, Seadra, Lapras, Blastoise | 64 Seadra, 65 Golduck, 64 Lapras, 64 Blastoise, 64 Vaporeon, 65 Starmie | Legacy species at 74–75 | All six slots reorder/change; move data must be ported as a unit. |
| `LT_SURGE:1`; `data/maps/objects/VermilionGym.asm` | 24 Electabuzz, 25 Magneton, 25 Pikachu, 28 Raichu | 29 Raichu | Legacy exact | Party shrinks 4→1. Static's multi-slot move record is invalid afterward; replace it with Legacy's Raichu record. High playtest priority because this is a large difficulty-philosophy change. |
| `LT_SURGE:2`; `scripts/VermilionGym.asm` rematch | six at 75: Electrode, Porygon, Jolteon, Electabuzz, Pikachu, Raichu | 64 Electrode, 65 Magneton, 64 Jolteon, 64 Porygon, 64 Electabuzz, 65 Raichu | Legacy species at 74–75 | Six slots, heavily reordered. Replace all keyed moves. |
| `ERIKA:1`; base map object | 33 Exeggcute, 34 Victreebel, 34 Tangela, 37 Vileplume | 33 Tangela, 34 Victreebel, 31 Ivysaur, 35 Vileplume | Legacy exact | Four slots remain but 1 and 3 change. Replace keyed moves. |
| `ERIKA:2`; `scripts/CeladonGym.asm` when fought as fifth Gym | 43 Exeggutor, 43 Victreebel, 43 Tangela, 44 Venusaur, 44 Vileplume | 41 Tangela, 42 Victreebel, 42 Venusaur, 43 Vileplume | Legacy exact | Party shrinks 5→4. Replace keyed moves and test the fifth-Gym branch. |
| `ERIKA:3`; script when fought as sixth Gym | 47 Exeggutor, 47 Victreebel, 47 Tangela, 48 Venusaur, 48 Vileplume | 48 Tangela, 49 Victreebel, 48 Venusaur, 49 Exeggutor, 50 Vileplume | Legacy exact | Five slots reorder. Replace keyed moves and test the sixth-Gym branch. |
| `ERIKA:4`; script rematch | six at 75: Venusaur, Tangela, Chansey, Victreebel, Exeggutor, Vileplume | 64 Tangela, 64 Venusaur, 64 Parasect, 64 Exeggutor, 65 Victreebel, 65 Vileplume | Legacy species at 74–75 | Six slots reorder/change; replace all keyed moves. |
| `KOGA:1`; base map object | 43 Golbat, 43 Muk, 43 Weezing, 44 Arbok, 44 Venomoth | 42 Golbat, 42 Muk, 41 Tentacruel, 43 Venomoth | Legacy exact | Party shrinks 5→4 and slot identity changes. Replace keyed moves. |
| `KOGA:2`; `scripts/FuchsiaGym.asm` sixth-Gym branch | 47 Golbat, 48 Muk, 48 Weezing, 48 Arbok, 48 Venomoth | 49 Golbat, 48 Muk, 49 Tentacruel, 48 Weezing, 50 Venomoth | Legacy exact | Five slots remain but slots 3–5 change. Replace keyed moves. |
| `KOGA:3`; script rematch | six at 75: Arbok, Golbat, Weezing, Tentacruel, Muk, Venomoth | 64 Golbat, 64 Muk, 64 Tentacruel, 65 Weezing, 64 Arbok, 65 Venomoth | Legacy species at 74–75 | Complete reorder; replace keyed moves. Preserve Static's separate `JANINE:1` encounter unchanged. |
| `BLAINE:1`; `data/maps/objects/CinnabarGym.asm` | 49 Flareon, 49 Ninetales, 49 Rapidash, 50 Arcanine, 50 Magmar | 52 Rapidash, 51 Charizard, 51 Ninetales, 52 Arcanine, 53 Magmar | Legacy exact | Five slots remain; 1–3 differ. Replace keyed moves. |
| `BLAINE:2`; `scripts/CinnabarGym.asm` rematch | six at 75: Arcanine, Ninetales, Rhydon, Flareon, Charizard, Magmar | 64 Rapidash, 64 Flareon, 64 Charizard, 64 Ninetales, 65 Arcanine, 65 Magmar | Legacy species at 74–75 | Complete reorder; replace keyed moves. |
| `SABRINA:1`; base map object | 47 Slowbro, 47 Mr. Mime, 47 Jynx, 47 Hypno, 48 Alakazam | 50 Abra, 48 Hypno, 49 Mr. Mime, 50 Kadabra, 50 Alakazam | Legacy exact | Five slots remain but four change/reorder. Replace keyed moves. |
| `SABRINA:2`; `scripts/SaffronGym.asm` fifth-Gym branch | 43 Slowbro, 43 Mr. Mime, 43 Jynx, 43 Hypno, 44 Alakazam | 43 Abra, 42 Mr. Mime, 43 Kadabra, 43 Alakazam | Legacy exact | Party shrinks 5→4. Replace keyed moves and test branch selection. |
| `SABRINA:3`; script rematch | six at 75: Gengar, Slowbro, Mr. Mime, Jynx, Hypno, Alakazam | 65 Mr. Mime, 64 Hypno, 64 Slowbro, 64 Jynx, 64 Gengar, 65 Alakazam | Legacy species at 74–75 | Same species, different order. Remap every move by slot rather than retaining Static data. |

## Giovanni

| Key and selector | Current Static party | Legacy party | Proposed first pass | Special-move and AI risk |
|---|---|---|---|---|
| `GIOVANNI:1`; `data/maps/objects/RocketHideoutB4F.asm` | 37 Onix, 37 Rhyhorn, 38 Kangaskhan, 38 Persian | 29 Onix, 31 Kangaskhan, 30 Marowak, 32 Persian | Legacy exact | Four slots remain; middle slots change. Replace keyed moves. Static's `GiovanniAI` pointer should remain initially. |
| `GIOVANNI:2`; `data/maps/objects/SilphCo11F.asm` | 42 Kingler, 40 Kangaskhan, 40 Machamp, 42 Dugtrio, 43 Nidoqueen | 44 Kingler, 44 Kangaskhan, 45 Machoke, 44 Golem, 47 Persian | Legacy exact | Five slots remain but slots 3–5 change. Replace keyed moves; test `GiovanniAI` against the Legacy move set. |
| `GIOVANNI:3`; `data/maps/objects/ViridianGym.asm` | 51 Golem, 52 Persian, 52 Kingler, 52 Nidoqueen, 52 Nidoking, 53 Rhydon | 53 Dugtrio, 54 Nidoqueen, 55 Persian, 54 Nidoking, 55 Rhydon | Legacy exact | Party shrinks 6→5 and reorders. Replace the entire keyed move record. |

## Rival arc

The script arithmetic is part of the contract and should not change:

- Oak's Lab explicitly selects `RIVAL1:1`.
- Route 22 early explicitly selects `RIVAL1:2`.
- Cerulean City explicitly selects `RIVAL1:3`.
- SS Anne explicitly selects `RIVAL2:1`.
- Pokémon Tower uses `wRivalStarter + 1`, selecting `RIVAL2:2..4`.
- Silph Co. uses `wRivalStarter + 4`, selecting `RIVAL2:5..7`.
- Route 22 late uses `wRivalStarter + 7`, selecting `RIVAL2:8..10`.
- Champion selection resolves to `RIVAL3:1..3`; rematch explicitly selects
  `RIVAL3:4`.

| Key and selector | Current Static party | Legacy party | Proposed first pass | Special-move and AI risk |
|---|---|---|---|---|
| `RIVAL1:1`; Oak's Lab | 5 Eevee | 5 Eevee | No party change | Retain Static move data unless comparison proves a deliberate Legacy difference. |
| `RIVAL1:2`; Route 22 early | 9 Spearow, 9 Rattata, 9 Eevee | 9 Spearow, 8 Eevee | Legacy exact | Party shrinks 3→2; replace keyed moves. |
| `RIVAL1:3`; Cerulean City | four at 18: Spearow, Sandshrew, Rattata, Eevee | 18 Spearow, 15 Rattata, 15 Bellsprout, 19 Eevee | Legacy exact | Four slots remain and three differ. Replace keyed moves. |
| `RIVAL2:1`; SS Anne | 24 Spearow, 24 Rattata, 24 Sandshrew, 25 Eevee | 20 Raticate, 22 Weepinbell, 21 Sandshrew, 24 Eevee | Legacy exact | Replace all keyed moves; this is not starter-branched. |
| `RIVAL2:2`; Tower/Jolteon | 31 Fearow, 29 Shellder, 28 Vulpix, 28 Sandslash, 30 Eevee | 34 Fearow, 32 Shellder, 32 Growlithe, 33 Kadabra, 35 Jolteon | Legacy exact | Replace all keyed moves. Confirm branch 2 still corresponds to Jolteon. |
| `RIVAL2:3`; Tower/Flareon | 31 Fearow, 29 Magnemite, 28 Shellder, 28 Sandslash, 30 Eevee | 34 Fearow, 32 Magnemite, 33 Kadabra, 32 Shellder, 35 Flareon | Legacy exact | Replace all keyed moves. |
| `RIVAL2:4`; Tower/Vaporeon | 31 Fearow, 29 Vulpix, 28 Magnemite, 28 Sandslash, 30 Eevee | 34 Fearow, 32 Vulpix, 33 Kadabra, 32 Scyther, 35 Vaporeon | Legacy exact | Replace all keyed moves. |
| `RIVAL2:5`; Silph/Jolteon | 38 Sandslash, 39 Exeggcute, 39 Ninetales, 38 Cloyster, 39 Kadabra, 40 Jolteon | 43 Parasect, 44 Gyarados, 43 Rhydon, 44 Alakazam, 46 Jolteon | Legacy exact | Party shrinks 6→5. Replace keyed moves. |
| `RIVAL2:6`; Silph/Flareon | 38 Sandslash, 39 Exeggcute, 39 Cloyster, 38 Magneton, 39 Kadabra, 40 Flareon | 43 Electabuzz, 44 Cloyster, 43 Dodrio, 44 Alakazam, 46 Flareon | Legacy exact | Party shrinks 6→5. Replace keyed moves. |
| `RIVAL2:7`; Silph/Vaporeon | 38 Sandslash, 39 Exeggcute, 39 Magneton, 38 Ninetales, 39 Kadabra, 40 Vaporeon | 43 Victreebel, 44 Porygon, 43 Primeape, 44 Alakazam, 46 Vaporeon | Legacy exact | Party shrinks 6→5. Replace keyed moves. |
| `RIVAL2:8`; Route 22/Jolteon | 54 Sandslash, 54 Exeggutor, 54 Ninetales, 54 Cloyster, 54 Alakazam, 55 Jolteon | 55 Jolteon, 53 Pidgeot, 52 Exeggutor, 52 Marowak, 54 Arcanine, 54 Alakazam | Legacy exact | Same size, complete reorder. Replace keyed moves. |
| `RIVAL2:9`; Route 22/Flareon | 54 Sandslash, 54 Exeggutor, 54 Cloyster, 54 Magneton, 54 Alakazam, 55 Flareon | 54 Fearow, 52 Magneton, 53 Golduck, 54 Alakazam, 52 Marowak, 55 Flareon | Legacy exact | Replace keyed moves. |
| `RIVAL2:10`; Route 22/Vaporeon | 54 Sandslash, 54 Exeggutor, 54 Magneton, 54 Ninetales, 54 Alakazam, 55 Vaporeon | 53 Pidgeot, 54 Machamp, 54 Alakazam, 52 Ninetales, 52 Scyther, 55 Vaporeon | Legacy exact | Replace keyed moves. |
| `RIVAL3:1`; Champion/Jolteon | 64 Sandslash, 64 Alakazam, 64 Exeggutor, 65 Cloyster, 65 Ninetales, 65 Jolteon | 63 Alakazam, 60 Rhydon, 61 Gyarados, 63 Arcanine, 62 Exeggutor, 65 Jolteon | Legacy exact | Same size, complete reorder. Replace keyed moves; retain Static `Rival3AI` initially. |
| `RIVAL3:2`; Champion/Flareon | 64 Sandslash, 64 Alakazam, 64 Exeggutor, 65 Magneton, 65 Cloyster, 65 Flareon | 62 Magneton, 61 Dodrio, 63 Alakazam, 60 Sandslash, 62 Cloyster, 65 Flareon | Legacy exact | Replace keyed moves. |
| `RIVAL3:3`; Champion/Vaporeon | 64 Sandslash, 64 Alakazam, 64 Exeggutor, 65 Ninetales, 65 Magneton, 65 Vaporeon | 60 Machamp, 61 Pidgeot, 62 Ninetales, 62 Victreebel, 63 Alakazam, 65 Vaporeon | Legacy exact | Replace keyed moves. |
| `RIVAL3:4`; Champion rematch | six at 90: Alakazam, Machamp, Gyarados, Pidgeot, Exeggutor, Arcanine | 77 Alakazam, 76 Machamp, 75 Gyarados, 74 Pidgeot, 75 Exeggutor, 77 Arcanine | Same Legacy/Static species at 87–90 | Species and order already match. Port Legacy move design, then scale levels rather than reducing the fight to the Legacy 74–77 band. |

## Elite Four

The room object selects ordinal 1 for the first clear and ordinal 2 for the rematch.

| Key and selector | Current Static party | Legacy party | Proposed first pass | Special-move and AI risk |
|---|---|---|---|---|
| `LORELEI:1`; `data/maps/objects/LoreleisRoom.asm` | 54 Dewgong, 54 Starmie, 55 Cloyster, 55 Slowbro, 56 Jynx, 56 Lapras | 56 Slowbro, 55 Cloyster, 55 Dewgong, 56 Jynx, 57 Lapras | Legacy exact | Party shrinks 6→5 and reorders. Replace keyed moves; retain Static class AI initially. |
| `LORELEI:2`; room rematch object | six at 85: Wigglytuff, Starmie, Cloyster, Omastar, Exeggutor, Lapras | 70 Wigglytuff, 71 Starmie, 71 Cloyster, 70 Omastar, 70 Exeggutor, 72 Lapras | Legacy species at 82–85 | Species/order match. Port move design and scale levels. |
| `BRUNO:1`; `data/maps/objects/BrunosRoom.asm` | 56 Onix, 56 Golem, 56 Hitmonchan, 56 Hitmonlee, 56 Poliwrath, 58 Machamp | 57 Hitmonchan, 56 Poliwrath, 57 Hitmonlee, 56 Onix, 58 Machamp | Legacy exact | Party shrinks 6→5 and reorders. Replace keyed moves. |
| `BRUNO:2`; room rematch object | six at 85: Clefable, Muk, Slowbro, Hitmonlee, Rhydon, Machamp | 71 Clefable, 71 Muk, 70 Slowbro, 72 Hitmonlee, 72 Rhydon, 73 Machamp | Legacy species at 82–85 | Species/order match. Port moves and scale levels. |
| `AGATHA:1`; `data/maps/objects/AgathasRoom.asm` | 58 Muk, 58 Tentacruel, 58 Venusaur, 58 Hypno, 58 Arbok, 60 Gengar | 57 Gengar, 58 Golbat, 57 Marowak, 58 Arbok, 59 Gengar | Legacy exact | Party shrinks 6→5 and changes identity. Replace keyed moves; test Static `AgathaAI` behavior. |
| `AGATHA:2`; room rematch object | 85 Jynx, then five at 80: Gyarados, Alakazam, Venusaur, Arbok, Gengar | 71 Jynx, 71 Gyarados, 72 Alakazam, 71 Venusaur, 72 Arbok, 73 Gengar | Legacy species at 82–85 | Species/order match, but Static's current ace ordering is anomalous. Use Legacy relative curve and port moves. |
| `LANCE:1`; `data/maps/objects/LancesRoom.asm` | 60 Gyarados, 60 Charizard, 60 Seadra, 60 Electabuzz, 61 Aerodactyl, 62 Dragonite | 61 Dragonite, 60 Gyarados, 60 Charizard, 61 Aerodactyl, 62 Dragonite | Legacy exact | Party shrinks 6→5 and has two Dragonite. Replace keyed moves; test Static `LanceAI`. |
| `LANCE:2`; room rematch object | six at 85: Arcanine, Electabuzz, Snorlax, Charizard, Kangaskhan, Dragonite | 73 Arcanine, 73 Electabuzz, 74 Snorlax, 74 Charizard, 72 Kangaskhan, 75 Dragonite | Legacy species at 82–85 | Species/order match. Port moves and scale levels. |

## Static extras to preserve

These are explicitly outside the first party replacement pass:

- `JANINE:1` in Fuchsia Gym. Static's Janine occupies class ID `$0D`; Legacy's
  Janine is at a different class ID. Never copy the Legacy pointer-table layout.
- `JOY:1` in Fuchsia Pokécenter and `JENNY:1` in Vermilion City.
- Static `CHIEF` and its `EvilTrainerList` membership.
- Static's postgame Professor Oak battle(s), including its existing selector and
  `Rival3AI` behavior. Oak's shadowed slot-5 Thunderbolt override was removed;
  the effective Fire Blast override remains unchanged.
- All Static rematch scripts and unlock conditions. Only their keyed party payloads
  are in scope.
- Static's Blackbelt, Rival, Giovanni, Agatha, Lance, Joy, and Jenny AI routines
  remain in place until a dedicated AI comparison pass.

Legacy-only `SMITH`, `CRAIG`, and `WEEBRA` encounters are content additions, not
balance data. Do not create or substitute them during this port.

## Implementation batches

1. Gyms 1–4: `BROCK`, `MISTY`, `LT_SURGE`, `ERIKA`, including rematches and
   Erika variants.
2. Gyms 5–8 and Rocket boss: `KOGA`, `BLAINE`, `SABRINA`, `GIOVANNI`, preserving
   `JANINE:1`.
3. Early rival: `RIVAL1:1..3` and `RIVAL2:1..4`.
4. Late rival: `RIVAL2:5..10`.
5. First-clear League: `LORELEI:1`, `BRUNO:1`, `AGATHA:1`, `LANCE:1`,
   `RIVAL3:1..3`.
6. Postgame payloads: all leader/E4 ordinal-2-or-later rematches and `RIVAL3:4`,
   while preserving Static unlock scripts and level bands.
7. AI experiment: compare Legacy class masks and routines only after party/move
   behavior is stable. Make each class-level AI change its own reviewable commit.

Because `parties.asm` and `special_moves.asm` are monolithic, parallel agents should
produce keyed patch fragments or encounter manifests. One integrator should apply
them in ordinal order to avoid merge conflicts and accidental record drift.

## Verification checklist

- Build after every implementation batch.
- Assert the record count of every edited class is unchanged.
- Assert every map-object and scripted ordinal resolves to a party.
- Assert each `SpecialTrainerMoves` party slot is within the new party size.
- Exercise every order-dependent Erika, Koga, and Sabrina selector.
- Exercise all three Tower, Silph, Route 22, and Champion rival branches.
- Exercise first-clear and rematch objects in every Elite Four room.
- Compare enemy moves in-game against the keyed specification; a successful build
  does not detect a legal but incorrectly reassigned move.
- Playtest at the intended badge cap without candies, then repeat with Static's
  expected convenience systems enabled before final level tuning.
