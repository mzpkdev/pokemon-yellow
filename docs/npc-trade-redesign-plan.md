# NPC Trade Redesign Plan

## Goal

Replace the ten conventional NPC trades with a progression-aware roster that:

- uses only the NPCs that are already traders in the current code;
- offers several different fantasies rather than ten simple power upgrades;
- preserves special acquisition moments such as fossils, Lapras, Porygon, the
  Fighting Dojo choice, Snorlax, starters, legendaries, and Dragonite's level-55
  payoff;
- uses different kinds of payment: attachment, catching difficulty, local
  hunting, training, a trade chain, and late collection checks;
- keeps the Fuchsia self-trade feature unchanged;
- does not add progression flags or enforce a strict order for the Eevee trade.

Save compatibility with old trade completion flags is not a requirement, but
this design deliberately keeps the existing trade indices and flag count because
no expansion is needed.

## Locked trade roster

The species pairs and locations below are the design decisions reached during
the trade review.

| Existing trader | Player gives | NPC sends | Actual result | Intended experience |
|---|---|---|---|---|
| Route 2 Trade House Game Boy Kid | Butterfree | Scyther | Scyther | Give up a replaceable early partner for an advanced blade Bug. |
| Cerulean Melanie's House gambler | Abra | Mr. Mime | Mr. Mime | Catching challenge and the first half of a secret trade chain. |
| Route 11 Gate 2F Youngster | Mr. Mime | Haunter | Gengar | The chain payoff: Haunter unexpectedly evolves during the trade. |
| Underground Path Route 5 little girl | Graveler | Electabuzz | Electabuzz | Train a fresh Rock Tunnel Geodude four or five levels for an early Electric powerhouse. |
| Vermilion Trade House little girl | Beedrill | Dratini | Dratini | Trade an early partner for a low-level dragon project; a trained Beedrill naturally yields a more developed Dratini. |
| Route 16 Gate 2F gambler | Vulpix | Eevee | Eevee | A fox-companion exchange that normally occurs after the Celadon Mansion gift and enables a second Eeveelution. |
| Route 18 Gate 2F cook | Ponyta | Tauros | Tauros | A Cycling Road hunt exchanged for an anime-associated Safari battler. |
| Cinnabar Lab Fossil Room scientist | Muk | Kangaskhan | Kangaskhan | Turn a locally obtainable level 38-42 Mansion Pokemon into an immediately usable Safari prize. |
| Cinnabar Lab Trade Room Gramps | Ditto | Chansey | Chansey | A rare Mansion catch exchanged for the most frustrating Safari capture. |
| Cinnabar Lab Trade Room Beauty | Lickitung | Rhydon | Rhydon | Reward an earlier collection find with a powerful pre-Victory-Road armored monster. |

The special trade in Fuchsia Bill's Grandpa's house remains:

| Existing trader | Behavior |
|---|---|
| Fuchsia Bill's Grandpa's house trader | `TRADE_WITH_SELF`; returns the selected Pokemon to enable trade evolution. |

## Recommended nicknames

Nicknames were discussed as flavor but were not individually approved as firmly
as the species pairs. Treat these as the recommended implementation set and the
one remaining creative review point:

| Received Pokemon | Recommended nickname |
|---|---|
| Scyther | `SLASH` |
| Mr. Mime | `MIMEY` |
| Haunter / Gengar | `SPOOKY` |
| Electabuzz | `VOLT` |
| Dratini | `TWINKLE` |
| Eevee | `BUDDY` |
| Tauros | `BULLSEYE` |
| Kangaskhan | `ROO` |
| Chansey | `LUCKY` |
| Rhydon | `TANK` |

Pad every nickname to `NAME_LENGTH` with `@`, following the current table
format.

## Why the roster works

### Early attachment trades

- Butterfree -> Scyther asks for a Pokemon that may have carried the early game,
  but Caterpie can be replaced and evolved quickly.
- Beedrill -> Dratini uses level inheritance as natural difficulty scaling.
  A freshly prepared Beedrill is normally about level 10, producing a low-level
  Dratini. A player who gives up a trained partner receives a correspondingly
  higher-level Dratini.

### Secret chain

The chain is entirely species-driven and needs no special flag:

1. Catch Abra on Routes 24/25.
2. Trade Abra for Mr. Mime in Cerulean.
3. Trade Mr. Mime for Haunter at Route 11.
4. The existing in-game trade evolution check evolves Haunter into Gengar.

At the Route 11 stage, the Cerulean trade is the convenient source of Mr. Mime.
Players may deliberately keep Mr. Mime instead. The chain can be bypassed later
with the expensive Game Corner Mr. Mime or the later wild/Safari sources. That
is intentional.

### Training project

Geodude evolves into Graveler at level 25. Rock Tunnel provides:

- level 20 Geodude on 1F in a 10-percent slot;
- level 21 Geodude on B1F in a 10-percent slot.

The intended cost is therefore four or five levels, not raising a level-10
Mt. Moon Geodude by fifteen levels. A level-25 Electabuzz arrives with
Thundershock, Thunder Wave, and Screech, with Thunderpunch at level 31.

### Eevee timing

Do not add an Eevee gift flag or gate the trade. Route 16 naturally points the
player toward this trade after visiting Celadon, but sequence breaks are allowed.
Vulpix is available at level 20 in a 20-percent Route 7 slot, so no Persian-style
thirteen-level grind is required. The trade gives access to a second Eeveelution
during the main story; additional level-10 Eevee remain a one-percent Route 23
encounter near the end.

### Safari-related late trades

- Ponyta -> Tauros: Ponyta has about 14 percent combined availability on Route
  17. Tauros is strong, anime-recognizable, and still subject to Safari capture
  frustration when acquired normally.
- Muk -> Kangaskhan: keep Muk rather than Marowak as payment. Wild/local Muk
  produces a level 40-42 Kangaskhan that is immediately useful. Marowak would
  make a more thematic pairing but usually produces an underleveled level 28-32
  Kangaskhan at Cinnabar.
- Ditto -> Chansey: Ditto occupies the final two Mansion B1F slots for about
  five percent combined availability. Chansey is only about one to four percent
  across Safari tables and is difficult to catch after appearing.
- Lickitung -> Rhydon is not a direct Safari replacement. Normal Rhydon requires
  raising Safari Rhyhorn to level 42 or waiting for Victory Road.

Three direct Safari rewards are the upper acceptable limit. They remain because
they cover different fantasies: battler (Tauros), parent/kaiju (Kangaskhan), and
rare healer/collector prize (Chansey). Chansey is the least immediately exciting
combat reward, but it has the strongest capture-relief justification.

## Code map

### Central definitions

- `constants/script_constants.asm`
  - Defines the `TRADE_FOR_*` indices.
  - Preserve the current order and keep `TRADE_WITH_SELF` last.
  - Rename the old nickname-derived constants so scripts describe the new rows.

- `data/events/trades.asm`
  - Contains the 14-byte trade records:
    `give species, receive species, dialog set, nickname`.
  - Replace the first ten rows in place.
  - Leave the `NO_MON, NO_MON, TRADE_DIALOGSET_SELF` row unchanged.
  - Keep `assert_table_length NUM_NPC_TRADES`.

- `engine/events/in_game_trades.asm`
  - No feature change is expected.
  - Received Pokemon inherit the selected payment Pokemon's level.
  - `InGameTrade_CheckForTradeEvo` already recognizes `HAUNTER` and will run
    the Gengar evolution after the trade.
  - Completion is tracked by the existing index in
    `wCompletedInGameTradeFlags`.

- `ram/wram.asm`
  - `wCompletedInGameTradeFlags` is already two bytes.
  - No WRAM or save-layout change is needed for ten normal trades plus self-trade.

### Stable row/index mapping

Keep the rows in their existing order so every NPC retains its current completion
bit:

| Index | Current constant/script owner | New recommended constant | New table row |
|---:|---|---|---|
| 0 | `TRADE_FOR_GURIO`; Route 11 Gate 2F | `TRADE_FOR_SPOOKY` | `MR_MIME, HAUNTER, ..., "SPOOKY"` |
| 1 | `TRADE_FOR_MILES`; Route 2 Trade House | `TRADE_FOR_SLASH` | `BUTTERFREE, SCYTHER, ..., "SLASH"` |
| 2 | `TRADE_FOR_STINGER`; Route 16 Gate 2F | `TRADE_FOR_BUDDY` | `VULPIX, EEVEE, ..., "BUDDY"` |
| 3 | `TRADE_FOR_STICKY`; Cinnabar Fossil Room | `TRADE_FOR_ROO` | `MUK, KANGASKHAN, ..., "ROO"` |
| 4 | `TRADE_FOR_DUX`; Vermilion Trade House | `TRADE_FOR_TWINKLE` | `BEEDRILL, DRATINI, ..., "TWINKLE"` |
| 5 | `TRADE_FOR_SPIKE`; Route 18 Gate 2F | `TRADE_FOR_BULLSEYE` | `PONYTA, TAUROS, ..., "BULLSEYE"` |
| 6 | `TRADE_FOR_LOLA`; Cerulean Melanie's House | `TRADE_FOR_MIMEY` | `ABRA, MR_MIME, ..., "MIMEY"` |
| 7 | `TRADE_FOR_BUFFY`; Cinnabar Trade Room Gramps | `TRADE_FOR_LUCKY` | `DITTO, CHANSEY, ..., "LUCKY"` |
| 8 | `TRADE_FOR_CEZANNE`; Cinnabar Trade Room Beauty | `TRADE_FOR_TANK` | `LICKITUNG, RHYDON, ..., "TANK"` |
| 9 | `TRADE_FOR_RICKY`; Underground Path Route 5 | `TRADE_FOR_VOLT` | `GRAVELER, ELECTABUZZ, ..., "VOLT"` |
| 10 | `TRADE_WITH_SELF`; Fuchsia | unchanged | unchanged self-trade row |

The dialog-set field changes tone only; it does not cause evolution. Review the
four generic dialog sets in `engine/events/in_game_trades.asm` and choose the
best tone per NPC. The Haunter evolution is species-driven, not dialog-driven.
Keeping each row's existing dialog set is the safest initial implementation if
no new tone decision is made.

### NPC script references to rename

Update only the loaded constants; the existing `wWhichTrade` and predef calls
remain unchanged:

- `scripts/Route11Gate2F.asm`
- `scripts/Route2TradeHouse.asm`
- `scripts/Route16Gate2F.asm`
- `scripts/CinnabarLabFossilRoom.asm`
- `scripts/VermilionTradeHouse.asm`
- `scripts/Route18Gate2F.asm`
- `scripts/CeruleanMelaniesHouse.asm`
- `scripts/CinnabarLabTradeRoom.asm` (two constants)
- `scripts/UndergroundPathRoute5.asm`

Do not change:

- map objects;
- NPC positions or sprites;
- text-pointer tables;
- generic in-game trade dialogue;
- `scripts/FuchsiaBillsGrandpasHouse.asm`;
- the self-trade row or self-trade engine path.

## Implementation sequence

1. Rename the ten conventional `TRADE_FOR_*` constants in place without
   reordering them.
2. Update the ten NPC script references to the renamed constants.
3. Replace the ten central trade rows with the locked species pairs.
4. Apply the approved nicknames, or confirm/adjust the recommended nickname list
   before implementation.
5. Review dialog-set tone; initially retain the existing per-index dialog sets
   unless one produces obviously unsuitable wording.
6. Build normal and debug ROMs.
7. Run static searches and table assertions.
8. Exercise the trade-specific runtime cases below.

## Verification checklist

### Static verification

- `NUM_NPC_TRADES` and `assert_table_length` still pass.
- No old constants (`TRADE_FOR_GURIO`, `MILES`, `STINGER`, `STICKY`, `DUX`,
  `SPIKE`, `LOLA`, `BUFFY`, `CEZANNE`, `RICKY`) remain referenced.
- Every new constant has exactly one intended conventional NPC owner.
- Nickname literals are exactly `NAME_LENGTH`.
- The self-trade constant, row, and script are byte-for-byte behaviorally
  unchanged.
- No map object or text-pointer count changes.

### Generic runtime cases

For at least one ordinary trade, verify:

- declining the offer;
- selecting the wrong species;
- cancelling the party menu;
- completing the trade;
- talking to the NPC again after completion;
- nickname, OT, level, moves, Pokedex credit, and traded EXP behavior.

### Design-specific runtime cases

- Butterfree -> Scyther preserves the payment Pokemon's level.
- A freshly evolved level-10 Beedrill produces level-10 Dratini.
- A trained Beedrill produces a correspondingly trained Dratini.
- Abra -> Mr. Mime completes, and that exact Mr. Mime is accepted at Route 11.
- A separately acquired Mr. Mime is also accepted at Route 11; this is intended.
- Mr. Mime -> Haunter triggers the trade animation, then evolution to Gengar.
- Gengar retains the received nickname and correct traded ownership data.
- A level-20/21 Rock Tunnel Geodude can evolve at 25 and produce level-25
  Electabuzz.
- Vulpix -> Eevee works whether or not the Celadon Mansion Eevee was collected.
- All three late Safari-relief trades work at their expected source levels.
- Each completion bit blocks only its own NPC trade.
- Fuchsia self-trade still triggers trade evolution and remains repeatable as
  designed.

## Explicit non-goals

- No new trader NPCs.
- No new maps, objects, or custom dialogue.
- No exact-identity check for the chained Mr. Mime; species matching is enough.
- No independent received-level field.
- No Eevee progression flag.
- No repeatable conventional trades.
- No fossil, legendary, starter, Lapras, Porygon, Snorlax, Hitmonlee, Hitmonchan,
  Aerodactyl, Kabutops, Omastar, or direct Dragonite rewards.
