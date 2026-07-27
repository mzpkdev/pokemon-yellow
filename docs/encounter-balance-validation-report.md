# Encounter Balance Validation Report

## Status and interpretation

This report validates encounter availability against the implemented authored wild,
fishing, gift, and evolution changes. It is a data review, not a completed
playtest. Trainer builds and structural audits may pass while a matchup still
needs tuning in play.

For this first report, **10 percent is the provisional threshold for a "common"
wild answer**. This threshold is pending user confirmation. Generation I's ten
wild slots are treated as `20 / 20 / 15 / 10 / 10 / 10 / 5 / 5 / 4 / 1`
percent; repeated species are summed within one table. Static encounters and
gifts are guaranteed when their event requirements are met, but gifts remain
optional answers.

Hard-mode caps are badge-count based: `15 / 22 / 28 / 37 / 44 / 48 / 50 /
53 / 65`. Midgame leader rows must be rechecked for every script-selected
badge-count variant.

## Build evidence

The fishing-phase baseline passed GitHub Actions CI in run `30275919497`.
These values are run-specific; documentation is not assembled into the ROM, but
future gameplay commits will change them.

| Artifact | Size | SHA-256 |
|---|---:|---|
| Normal ROM | 2,097,152 bytes | `F72C2175EEFEB1CF3DBFB654F00EF19850D7FF35F6ADBC1428B8A19F04720924` |
| Debug ROM | 2,097,152 bytes | `9CBCEEDB652842F93402A5FF673BDBDD90503C7772CC2BB11437091A792847C5` |

The parsed linker maps contained 75 `TOTAL EMPTY` sections. Aggregate empty
space was 151,545 bytes in the normal build and 147,923 bytes in the debug build.
This establishes build and structural headroom only; it is not battle-balance
evidence.

## Implemented acquisition baseline

- Charmander is given on Route 24 at level 13.
- Squirtle is given in Vermilion at level 15 after the Thunder Badge.
- Lapras is given in Silph Co. 7F at level 35.
- Poliwag evolves into Poliwhirl at level 18.
- Graveler and Machoke have level 38 trade-evolution fallbacks.
- Kadabra and Haunter have level 42 trade-evolution fallbacks.
- Trading and Static's tradeback support remain available.
- Static's completion-oriented Safari, Seafoam, Cerulean Cave, Route 23,
  Pokémon Tower 8F, and special fishing content is retained.

Natural-move levels below come from `data/pokemon/evos_moves.asm`. A caught
Pokémon is assumed to receive the applicable current moves for its level; its
exact four-move catch set still needs ROM verification.

## Source-level 151-species audit

The completed source-level acquisition audit resolves **all 151 Pokédex species**.
The audit began with wild tables, fishing rows, gifts, trades, fossils, and static
encounters, then repeatedly applied every reachable level, stone, and trade
evolution until no new species were added. The resulting closure contains all 151
species with no unresolved species IDs.

Important closure findings:

- Kadabra, Graveler, Machoke, and Haunter remain trade evolutions, retain
  tradeback support, and also resolve without another cartridge through the
  implemented level 42/38/38/42 fallbacks.
- Fire, Thunder, Water, Leaf, and Moon Stones remain sold in Celadon, so their
  evolution branches are source-reachable without a finite-stone dead end.
- Both fossil families resolve through Static's retained fossil revival and
  completion encounters. Route 23 fishing retains Omanyte and Kabuto, while
  Cerulean Cave retains their evolved forms.
- Static's other completion encounters retain otherwise awkward gift, trade,
  stone, and evolved species, including Porygon and the Dragon line.
- Mewtwo remains the level 70 Cerulean Cave static encounter.
- Mew remains Static's level 70 Cerulean Cave encounter rather than Legacy's
  Pokémon Mansion placement.

This is a source-graph result: it proves that acquisition definitions and
evolution edges exist. Runtime event flags, map access, catch success, and
save-state completion still need campaign verification.

## Rationale for unchanged authored tables

These tables were intentionally preserved rather than mechanically replaced with
Legacy data:

| Preserved area | Completion and progression role |
|---|---|
| Safari Zone Center/East/North/West | Keeps Static's broad single-cartridge land roster, including both Nidoran evolutions, Exeggcute/Exeggutor, Paras/Parasect, Rhyhorn, Cubone/Marowak, Mr. Mime, Tauros, Kangaskhan, Chansey, Scyther, Pinsir, Tangela, Lickitung, Butterfree, Beedrill, and Weepinbell. The level 30–38 band also makes catches plausible midgame additions instead of collection-only trophies. |
| Seafoam Islands 1F–B4F | Preserves diverse Water/Ice acquisition across Krabby/Kingler, Goldeen, Staryu/Starmie, Slowpoke/Slowbro, Seel/Dewgong, Shellder/Cloyster, Horsea/Seadra, and Jynx. Legacy's more repetitive Zubat, Golbat, Tentacool, and Staryu tables would reduce completion coverage and remove several practical Blaine, Giovanni, and Lance candidates. |
| Cerulean Cave 1F/2F/B1F | Retains Static's postgame catch-up roster: fossil families, trade evolutions, Porygon, Dragonair/Dragonite, stone evolutions, and other difficult evolved species at the postgame curve. Legacy's repeated Ditto/Raichu-oriented roster would weaken the one-save 151 path. |
| Pokémon Tower 8F | Keeps Static's exclusive floor and its Gastly, Haunter, Cubone, and Marowak progression. Legacy has no corresponding 8F table, so directory replacement would silently delete authored content. |
| Old Rod | Keeps level 5 Magikarp and Poliwag as distinct early investment choices. Magikarp preserves the traditional early Gyarados path; Poliwag now evolves at level 18 and provides an alternate early Water family. Replacing Magikarp with Legacy's Goldeen would narrow that progression identity. |

The same preservation principle applies to authored rows inside merged Super Rod
data, especially Route 23 fossils, Safari dragons, Seafoam B4 diversity, and
Cerulean Cave fossil evolutions.

## Major-fight counter matrix

### Brock — 0 badges, cap 15

| Answer | Acquisition and probability | Move access | Caveat |
|---|---|---|---|
| Oddish | Viridian Forest, levels 5–6, 15% total | Absorb 13; PoisonPowder 5; Leech Seed 8 | Common, but needs seven or eight levels for Grass damage |
| Mankey | Route 22, levels 4–5, 25% total | Low Kick 9 | Common; requires early training |
| Nidoran family | Route 22, levels 3–4; each sex at least 25% total | Double Kick 12 | Common and does not require a Moon Stone |

Data verdict: three independent families exist, but the low catch levels make
Brock a priority anti-grind playtest.

### Misty — 1 badge, cap 22

| Answer | Acquisition and probability | Move access | Caveat |
|---|---|---|---|
| Oddish | Route 24, levels 12–14, 30% total | Absorb 13; Stun Spore 16 | Common, immediate non-Pikachu answer |
| Magnemite | Route 6, levels 16–19, 10% total | Thundershock 6; Sonicboom 16; Thunder Wave 21 | Exactly provisional-common; Route 6 access before Misty needs script verification |
| Pikachu | Starter, guaranteed | Early Thundershock | Guaranteed but must not be the only demonstrated route |
| Bulbasaur | Cerulean gift, level 10 | Grass/status learnset | Optional and happiness-gated |

Data verdict: passes if Route 6 is reachable before Misty; otherwise the second
common non-Pikachu route needs confirmation.

### Lt. Surge — 2 badges, cap 28

| Answer | Acquisition and probability | Move access | Caveat |
|---|---|---|---|
| Diglett/Dugtrio | Diglett's Cave, levels 18–24 / 28–29, 100% | Dig 19 | Guaranteed wild family and Electric immunity |
| Sandshrew | Route 11, level 18, 15% | Dig 14; evolves 22; Slash 22 | Common independent Ground route |
| Nidoran family | Routes 2/22, early levels | Nidorino learns Dig 24; Double Kick 12 | Evolution and Moon Stone sequencing must be documented |
| Oddish/Gloom | Forest/Route 24 | Stun Spore 16 and Electric resistance | Secondary plan, not immunity |

Data verdict: passes the two-route requirement without depending exclusively on
Diglett.

### Erika — nominally 3 badges, cap 37

| Answer | Acquisition and probability | Move access | Caveat |
|---|---|---|---|
| Growlithe | Route 8, level 20, 20% | Ember 18; Flamethrower 35 | Common Fire route |
| Pidgeotto | Routes 7/8, level 24, 10% per table | Wing Attack inherited by 19 | Common Flying route |
| Fearow | Route 9, level 20, 5% | Drill Peck 24 | Strong but below provisional-common |
| Kadabra | Route 8, levels 24/28, 5% total | Psybeam 27; Psychic 38 | Rare optional Psychic route |
| Charmander | Route 24 gift, level 13 | Fire line; train toward the current cap | Optional; substantial catch-up remains |

Data verdict: common Fire and Flying routes exist without requiring Charmander.

### Koga — order-flexible, caps 44/48/50

| Answer | Acquisition and probability | Move access | Caveat |
|---|---|---|---|
| Drowzee/Hypno | Route 11, levels 17–20, 25% total | Confusion 17; evolves 26; Psychic 32 | Common non-trade Psychic route |
| Sandshrew/Sandslash | Route 11, level 18, 15% | Dig 14; Sandslash Earthquake 30 | Common Ground route |
| Abra/Kadabra/Alakazam | Route 8, levels 17–28; Kadabra 5% | Psybeam 27; Psychic 38; fallback evolution 42 | Abra catch/training or rare evolved catch |
| Exeggcute/Exeggutor | Safari, levels 33–37 | Confusion 19; Mega Drain 20; status 32; Psychic 45 | Depends on Safari access for the selected variant |

Data verdict: Route 11 alone supplies two common families. Badge-order and level-cap
behavior still require variant playtests.

### Sabrina — order-flexible, caps 44/48/50

| Answer | Acquisition and probability | Move access | Caveat |
|---|---|---|---|
| Snorlax | Static Route 12 or 16, level 30, guaranteed battle | Headbutt 29; Body Slam 43 | Catch is not guaranteed; either route is available only after Poké Flute |
| Doduo/Dodrio | Route 17; Doduo levels 26–28 at 40% total, Dodrio 31 at 1% | Drill Peck 30; Tri Attack 39 | Common family, but evolved catch is rare |
| Scyther | Route 14, level 28, 10% | Wing Attack 30; Slash 36; Twineedle 42 | Exactly provisional-common; Bug STAB arrives late |
| Pinsir | Route 9, levels 21/23, 5% total | Seismic Toss 25; Twineedle 30; Slash 42 | Rare; requires training |
| Tangela | Routes 12/13, level 29, 5% per table | Stun Spore 23; Sleep Powder 25 | Status support, not a primary damage answer |

Data verdict: physical routes exist, but Sabrina's Bug plan and the lower-cap
variant need focused testing under Generation I mechanics.

### Blaine — nominally 6 badges, cap 50

| Answer | Acquisition and probability | Move access | Caveat |
|---|---|---|---|
| Staryu/Starmie | Seafoam 1F level 33 at 10%; deeper water levels 30–40 | Water Gun 7; Bubblebeam 24; Surf HM | Common on 1F; Water Stone for Starmie |
| Slowpoke/Slowbro | Seafoam 1F levels 33 at 20% total; deeper levels 31–38 | Water Gun 5; Waterfall 28; evolves 37 | Common and immediately useful |
| Seel/Dewgong | Seafoam B4 levels 28/32 at 20% total; evolved catches deeper | Water Gun 13; Bubblebeam 25; Ice Beam 40 | Common family |
| Squirtle line | Vermilion gift, level 15 | Bubblebeam 21; Surf HM | Optional and needs long-term training |

Data verdict: multiple common Water families arrive near enough to the curve.

### Giovanni — 7 badges, cap 53

| Answer | Acquisition and probability | Move access | Caveat |
|---|---|---|---|
| Staryu/Slowpoke/Seel families | Seafoam, levels 28–40 | Natural Water moves and Surf | Multiple common Water routes |
| Tangela | Routes 12/13, level 29, 5% each; Safari level 35 at 4% in Center | Vine Whip 19; Mega Drain 32; status | No single table meets provisional-common |
| Jynx | Seafoam 1F level 36 at 1%; deeper level 40 at 5–10% | Ice Punch 31; Psychic 39; Ice Beam 43 | Strong but generally rare |
| Lapras | Silph Co. gift, level 35 | Waterfall 34; Ice Beam 38 | Guaranteed optional gift after reaching Silph 7F |

Data verdict: Water routes pass; Grass/Ice diversity is available but less common.
Victory Road encounters are deliberately excluded.

### Lorelei — 8 badges, cap 65

| Answer | Acquisition and probability | Move access | Caveat |
|---|---|---|---|
| Magneton | Power Plant, levels 33/35, 35% total | Thunderbolt 33; Reflect 27 | Common Electric route |
| Electabuzz | Power Plant, levels 38/39, 9% total | Thunderpunch 31; Thunderbolt 43 | Just below provisional-common |
| Machop line | Route 10 levels 18–20 at 10% total; Victory Road Machamp 46–47 | Submission 28; trade or fallback 38 | Common early family, large training requirement |
| Exeggcute/Exeggutor | Safari levels 33–37 | Mega Drain 20; status; Psychic 45 | Safari probabilities vary; stone optional |

### Bruno — 8 badges, cap 65

| Answer | Acquisition and probability | Move access | Caveat |
|---|---|---|---|
| Slowpoke/Slowbro | Seafoam common family, levels 31–38 | Confusion 10; Psybeam 25; Waterfall 28 | Covers Fighting and Rock/Ground roles |
| Staryu/Starmie | Seafoam, levels 30–40 | Water moves; Psychic 40 before stone evolution | Water Stone sequencing |
| Abra line | Route 8, levels 17–28 | Psychic 38; fallback Alakazam 42 | Training/catch difficulty |
| Doduo/Dodrio | Route 17 common family; Victory Road support | Drill Peck 30 | Physical Flying route |

### Agatha — 8 badges, cap 65

| Answer | Acquisition and probability | Move access | Caveat |
|---|---|---|---|
| Sandshrew/Sandslash | Route 11, 15% at level 18 | Earthquake 30 as Sandslash | Common Ground family |
| Drowzee/Hypno | Route 11, 25% total | Psychic 32 | Common Psychic family |
| Snorlax | Route 12/16 static level 30 | Headbutt/Body Slam and Normal immunity | Catch outcome is player-dependent |
| Abra line | Route 8 | Psychic 38 | Faster but frailer optional route |

### Lance — 8 badges, cap 65

| Answer | Acquisition and probability | Move access | Caveat |
|---|---|---|---|
| Seel/Dewgong | Seafoam common family, levels 28–40 | Ice Beam 40 | Common Ice route |
| Shellder/Cloyster | Seafoam B3/B4 and fishing, levels 30–40 | Aurora Beam 20; Ice Beam 35 | Water Stone sequencing |
| Jynx | Seafoam, levels 36–40 | Ice Punch 31; Ice Beam 43 | Strong but uncommon |
| Lapras | Silph gift, level 35 | Ice Beam 38 | Guaranteed optional gift |
| Magneton | Power Plant, 35% total | Thunderbolt 33 | Common Gyarados answer |

### Champion — 8 badges, cap 65

The Champion must be tested separately for `RIVAL3:1` Jolteon, `RIVAL3:2`
Flareon, and `RIVAL3:3` Vaporeon. A non-legendary final roster can combine:

- a common Seafoam Ice/Water family (Dewgong, Cloyster, Slowbro, or Starmie);
- common Power Plant Magneton;
- Route 11 Hypno or Sandslash;
- Route 17 Dodrio;
- Victory Road Machamp/Golem/Hitmon or Eeveelution catches at levels 42–48;
- an optional gift such as Lapras.

Data verdict: broad coverage is obtainable without a legendary or Game Corner
purchase. Branch-specific turns, survivability, and move-slot quality remain
playtest questions.

## Acquisition and move caveats

1. Confirm Route 6 is reachable before Misty in an ordinary campaign.
2. Confirm newly caught Pokémon receive the assumed natural moves and record the
   exact four-move result for every matrix answer.
3. Confirm hard-mode behavior when a catch level exceeds the current badge cap.
4. Record the exact badge-count selector used for every Erika, Koga, Sabrina,
   and Blaine variant.
5. Verify TM/HM compatibility and acquisition before crediting Surf, Psychic,
   Ice Beam, Dig, Rock Slide, or other taught coverage. Reusable TMs remove
   depletion risk, not access gating.
6. Record Water/Fire/Leaf/Moon Stone timing and the level at which each stone
   evolution should occur so useful natural moves are not skipped.
7. The 10% common threshold is provisional. Reclassify the matrix if the user
   chooses another threshold.
8. Static encounters require a successful catch and therefore are not equivalent
   to gifts.

## Three-profile playtest checklist

For every major fight, record difficulty mode, badge count, party levels, moves,
items held, attempts, turns, faints, remaining HP, and whether a listed counter
was actually used.

### Profile 1: minimal-catch

- Keep Pikachu and catch only what is required to maintain a functional team.
- Do not use optional gifts except where the campaign forces one.
- Avoid deliberate rare-slot hunting and avoid detours solely for one matchup.
- Verify that each fight has a workable plan without one specific rare species.

### Profile 2: typical diverse

- Build a rotating team from common route encounters and accepted gifts.
- Use stones, reusable TMs, and the EXP All as an ordinary player likely would.
- Challenge flexible midgame leaders in at least two different orders.
- Record catch-up time when adding Charmander, Squirtle, Lapras, or a late catch.

### Profile 3: optimized reusable-TM

- Use the strongest legal reusable-TM coverage and deliberate encounter choices.
- Stay within hard-mode caps; do not use in-battle bag items where prohibited.
- Check whether any boss is trivialized by repeated TM access or perfect planning.
- Test all three Champion branches and the retained high-level rematches.

## Deferred AI findings

AI changes are deferred until full-campaign playtesting. Static's current AI and
perfect hard-mode trainer DVs remain the baseline. In particular:

- do not wholesale-copy Legacy's `move_choices.asm`, `ai_pointers.asm`, or trainer
  DV policy;
- observe setup, recovery, status, recoil, trapping, self-damage, and coverage
  choices under Static's enabled AI layers;
- retest Agatha, Giovanni, Rival3, and every party whose imported moves include
  situational or setup-heavy options;
- change class-wide AI only if the result benefits every party in that class;
- keep rematch AI tuning separate from the main-story first pass.

No AI finding is considered resolved from data inspection alone.
