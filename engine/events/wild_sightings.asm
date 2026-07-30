UpdateWildSightingOnStep::
	ld a, [wSightingFlags]
	bit SIGHTING_ACTIVE_F, a
	ret nz

	call GetCurrentWildSightingZoneAndProfile
	ld a, c
	and a
	ret z
	push bc
	call GetCurrentWildSightingStepMethod
	ld d, a
	pop bc
	and a
	ret z
	ld a, c
	push bc
	push de
	call GetWildSightingProfile
	ld b, a
	pop de
	ld a, d
	and b
	jr z, .ineligibleProfile
	ld a, d
	call GetWildSightingTable
	ld a, [hl]
	and a
	pop bc
	ret z
	jr .eligibleProfile

.ineligibleProfile
	pop bc
	ret

.eligibleProfile

	ld hl, wSightingCooldown
	ld a, [hl]
	and a
	jr z, .cooldownDone
	dec [hl]
	ret

.cooldownDone
	ld hl, wSightingStepCounter
	inc [hl]
	ld a, [hl]
	and SIGHTING_STEP_INTERVAL - 1
	ret nz

	IF !DEF(_DEBUG)
		push bc
		call Random
		cp SIGHTING_TRIGGER_CHANCE
		pop bc
		ret nc
	ENDC

	ld a, b
	ld [wSightingZone], a
	ld a, c
	ld [wSightingProfile], a
	ld hl, wSightingFlags
	set SIGHTING_ACTIVE_F, [hl]
	call QueueWildSightingPikachuHint
	ret

; Match the terrain classification used by TryDoWildEncounter without rolling
; an encounter. Outdoor maps require grass or water; encounter-enabled indoor
; maps allow land encounters anywhere except forest-style maps.
GetCurrentWildSightingStepMethod:
	callfar IsPlayerStandingOnDoorTileOrWarpTile
	jr c, .ineligible
	callfar IsPlayerJustOutsideMap
	jr z, .ineligible
	hlcoord 8, 9
	ld e, [hl]
	ld a, [wGrassTile]
	cp e
	ld a, SIGHTING_METHOD_LAND
	ret z
	ld a, e
	cp $14
	ld a, SIGHTING_METHOD_WATER
	ret z
	ld a, [wCurMap]
	cp FIRST_INDOOR_MAP
	jr c, .ineligible
	ld a, [wCurMapTileset]
	cp FOREST
	jr z, .ineligible
	ld a, SIGHTING_METHOD_LAND
	ret

.ineligible
	xor a
	ret

ValidateWildSightingZone::
	ld a, [wSightingFlags]
	bit SIGHTING_ACTIVE_F, a
	ret z
	call GetCurrentWildSightingZoneAndProfile
	ld a, [wSightingZone]
	cp b
	jr nz, ClearWildSighting
	ld a, c
	ld [wSightingProfile], a
	ret

; Replace an otherwise valid land/water encounter with a weighted species from
; the active profile. The caller's normal encounter level is deliberately kept.
; Input: a = SIGHTING_METHOD_* bit. The sighting is consumed only on replacement.
TryReplaceWithWildSighting::
	push af
	ld a, [wSightingFlags]
	bit SIGHTING_ACTIVE_F, a
	jr z, .noReplacementPop

	call GetCurrentWildSightingZoneAndProfile
	ld a, [wSightingZone]
	cp b
	jr nz, .noReplacementPop
	ld a, [wSightingProfile]
	cp c
	jr nz, .noReplacementPop

	pop de ; d = requested encounter-method bit
	ld a, [wSightingProfile]
	push de
	call GetWildSightingProfile
	pop de
	and d
	ret z
	ld a, d
	call GetWildSightingTable
	ld a, [hl]
	and a
	ret z

	IF !DEF(_DEBUG)
		call Random
		cp SIGHTING_ENCOUNTER_CHANCE
		ret nc
	ENDC
	call Random
	ld b, a
.chooseSpecies
	ld a, [hli]
	and a
	ret z
	cp b
	jr nc, .gotSpecies
	inc hl
	jr .chooseSpecies

.gotSpecies
	ld b, [hl]
	push bc
	call ClearWildSighting
	pop bc
	ld hl, wSightingFlags
	set SIGHTING_BATTLE_F, [hl]
	ld a, b
	ld [wCurPartySpecies], a
	ld [wEnemyMonSpecies2], a
	ret

.noReplacementPop
	pop af
	ret

ClearWildSighting::
	xor a
	ld [wSightingZone], a
	ld [wSightingProfile], a
	ld [wSightingFlags], a
	ld [wSightingStepCounter], a
	ld a, SIGHTING_COOLDOWN_STEPS
	ld [wSightingCooldown], a
	call ClearWildSightingPikachuHint
	ret

QueueWildSightingPikachuHint:
	callfar IsStarterPikachuInOurParty
	ret nc
	ld a, [wd49c]
	and PIKACHU_PENDING_EMOTION_MASK
	ret nz
	ld e, PIKACHU_PENDING_SIGHTING
	callfar SetPendingPikachuEmotion
	ld a, [wPikachuCompanionQueuedReaction]
	cp PIKACOMPANION_REACTION_GIFT_READY
	ret z
	ld a, PIKACOMPANION_REACTION_PORTRAIT_READY
	ld [wPikachuCompanionQueuedReaction], a
	ret

ClearWildSightingPikachuHint:
	ld a, [wd49c]
	and PIKACHU_PENDING_EMOTION_MASK
	cp PIKACHU_PENDING_SIGHTING
	ret nz
	xor a
	ld [wd49c], a
	ld a, [wPikachuCompanionQueuedReaction]
	cp PIKACOMPANION_REACTION_PORTRAIT_READY
	ret nz
	xor a
	ld [wPikachuCompanionQueuedReaction], a
	ld [wPikachuCompanionIdleCounter], a
	ret

; Return the current map's explicit zone in b and shared profile in c.
GetCurrentWildSightingZoneAndProfile:
	ld a, [wCurMap]
	ld l, a
	ld h, 0
	add hl, hl
	ld de, WildSightingMapData
	add hl, de
	ld b, [hl]
	inc hl
	ld c, [hl]
	ret

; Return a profile's encounter-method flags in a and table pointers in hl.
GetWildSightingProfile:
	ld e, a
	ld d, 0
	ld hl, WildSightingProfiles
	add hl, de
	add hl, de
	add hl, de
	add hl, de
	add hl, de
	ld a, [hli]
	ret

; Return the land or water species table selected by a.
; Input: a = SIGHTING_METHOD_* bit, hl = profile table pointers.
GetWildSightingTable:
	cp SIGHTING_METHOD_WATER
	jr nz, .loadPointer
	inc hl
	inc hl

.loadPointer
	push af
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld h, d
	ld l, e
	pop af
	ret

INCLUDE "data/wild/sighting_maps.asm"

; Each profile contains supported encounter-method flags followed by land and
; water species-table pointers. Unsupported methods use NoWildSightings.
WildSightingProfiles:
	table_width 5, WildSightingProfiles
	sighting_profile 0, NoWildSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, PalletGrasslandSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, PalletWoodlandSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, ViridianForestSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, PewterRockyRouteSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, PewterGrasslandSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, MtMoonSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, CentralOutskirtsLandSightings, CentralOutskirtsWaterSightings
	sighting_profile SIGHTING_METHOD_LAND, EastRockyRouteSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, EastCoastSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, SouthWetlandLandSightings, SouthWetlandWaterSightings
	sighting_profile SIGHTING_METHOD_LAND, CyclingRoadSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, CoastalLandSightings, CoastalWaterSightings
	sighting_profile SIGHTING_METHOD_WATER, NoWildSightings, OpenOceanSightings
	sighting_profile SIGHTING_METHOD_LAND, IndigoSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, RockTunnelSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, PowerPlantSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, VictoryRoadSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, PokemonTowerSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, SeafoamLandSightings, SeafoamWaterSightings
	sighting_profile SIGHTING_METHOD_LAND, PokemonMansionSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, DiglettsCaveSightings, NoWildSightings
	assert_table_length NUM_SIGHTING_PROFILES

NoWildSightings:
	db 0
PalletGrasslandSightings:
	sighting_mon $32, CATERPIE
	sighting_mon $65, WEEDLE
	sighting_mon $98, MEOWTH
	sighting_mon $be, SANDSHREW
	sighting_mon $d8, ODDISH
	sighting_mon $f2, BELLSPROUT
	sighting_mon $ff, PIDGEOTTO
	db 0
PalletWoodlandSightings:
	sighting_mon $32, PARAS
	sighting_mon $65, VENONAT
	sighting_mon $8c, CATERPIE
	sighting_mon $b2, WEEDLE
	sighting_mon $cc, MEOWTH
	sighting_mon $e5, BELLSPROUT
	sighting_mon $f2, BUTTERFREE
	sighting_mon $ff, BEEDRILL
	db 0
ViridianForestSightings:
	sighting_mon $3f, PARAS
	sighting_mon $72, VENONAT
	sighting_mon $99, BELLSPROUT
	sighting_mon $bf, MEOWTH
	sighting_mon $d9, BUTTERFREE
	sighting_mon $f2, BEEDRILL
	sighting_mon $ff, PINSIR
	db 0
PewterRockyRouteSightings:
	sighting_mon $3f, GEODUDE
	sighting_mon $72, VULPIX
	sighting_mon $a5, GROWLITHE
	sighting_mon $cb, CUBONE
	sighting_mon $e5, ONIX
	sighting_mon $f2, PONYTA
	sighting_mon $ff, MACHOKE
	db 0
PewterGrasslandSightings:
	sighting_mon $32, CATERPIE
	sighting_mon $65, WEEDLE
	sighting_mon $8c, MEOWTH
	sighting_mon $b2, VULPIX
	sighting_mon $cc, GROWLITHE
	sighting_mon $e5, PARAS
	sighting_mon $f2, BUTTERFREE
	sighting_mon $ff, BEEDRILL
	db 0
MtMoonSightings:
	sighting_mon $3f, ONIX
	sighting_mon $72, CUBONE
	sighting_mon $99, MACHOP
	sighting_mon $bf, GOLBAT
	sighting_mon $d9, GRAVELER
	sighting_mon $f2, PARASECT
	sighting_mon $ff, CLEFABLE
	db 0
CentralOutskirtsLandSightings:
	sighting_mon $32, ODDISH
	sighting_mon $65, BELLSPROUT
	sighting_mon $8c, DROWZEE
	sighting_mon $b2, EXEGGCUTE
	sighting_mon $cc, CUBONE
	sighting_mon $e5, PERSIAN
	sighting_mon $f2, ARCANINE
	sighting_mon $ff, NINETALES
	db 0
CentralOutskirtsWaterSightings:
	sighting_mon $3f, POLIWAG
	sighting_mon $72, SLOWPOKE
	sighting_mon $99, GOLDEEN
	sighting_mon $bf, KRABBY
	sighting_mon $d9, SHELLDER
	sighting_mon $f2, STARYU
	sighting_mon $ff, POLIWHIRL
	db 0
EastRockyRouteSightings:
	sighting_mon $32, GEODUDE
	sighting_mon $59, VULPIX
	sighting_mon $7f, GROWLITHE
	sighting_mon $99, CUBONE
	sighting_mon $b2, ONIX
	sighting_mon $cc, PONYTA
	sighting_mon $e5, GRAVELER
	sighting_mon $f2, MACHOKE
	sighting_mon $ff, MAGNETON
	db 0
EastCoastSightings:
	sighting_mon $3f, DODUO
	sighting_mon $72, FARFETCHD
	sighting_mon $99, GROWLITHE
	sighting_mon $bf, VULPIX
	sighting_mon $d9, CUBONE
	sighting_mon $f2, PONYTA
	sighting_mon $ff, DODRIO
	db 0
SouthWetlandLandSightings:
	sighting_mon $32, PARAS
	sighting_mon $65, EXEGGCUTE
	sighting_mon $8c, LICKITUNG
	sighting_mon $b2, DITTO
	sighting_mon $cc, PARASECT
	sighting_mon $e5, EXEGGUTOR
	sighting_mon $f2, VILEPLUME
	sighting_mon $ff, VICTREEBEL
	db 0
SouthWetlandWaterSightings:
	sighting_mon $32, POLIWAG
	sighting_mon $65, PSYDUCK
	sighting_mon $8c, GOLDEEN
	sighting_mon $b2, KRABBY
	sighting_mon $cc, HORSEA
	sighting_mon $e5, POLIWHIRL
	sighting_mon $f2, GOLDUCK
	sighting_mon $ff, GYARADOS
	db 0
CyclingRoadSightings:
	sighting_mon $3f, KOFFING
	sighting_mon $72, MACHOP
	sighting_mon $99, MAGNEMITE
	sighting_mon $bf, VOLTORB
	sighting_mon $d9, CUBONE
	sighting_mon $f2, WEEZING
	sighting_mon $ff, MACHOKE
	db 0
CoastalLandSightings:
	sighting_mon $3f, DODUO
	sighting_mon $72, FARFETCHD
	sighting_mon $99, EXEGGCUTE
	sighting_mon $bf, GROWLITHE
	sighting_mon $d9, VULPIX
	sighting_mon $f2, PONYTA
	sighting_mon $ff, DODRIO
	db 0
CoastalWaterSightings:
	sighting_mon $32, KRABBY
	sighting_mon $65, SEEL
	sighting_mon $8c, PSYDUCK
	sighting_mon $b2, GOLDUCK
	sighting_mon $cc, SEADRA
	sighting_mon $e5, KINGLER
	sighting_mon $f2, STARMIE
	sighting_mon $ff, LAPRAS
	db 0
OpenOceanSightings:
	sighting_mon $32, KRABBY
	sighting_mon $59, SEEL
	sighting_mon $7f, PSYDUCK
	sighting_mon $99, SEADRA
	sighting_mon $b2, KINGLER
	sighting_mon $cc, GOLDUCK
	sighting_mon $e5, DEWGONG
	sighting_mon $f2, DRATINI
	sighting_mon $ff, LAPRAS
	db 0
IndigoSightings:
	sighting_mon $25, ARCANINE
	sighting_mon $4c, NINETALES
	sighting_mon $72, RAPIDASH
	sighting_mon $98, MAROWAK
	sighting_mon $b2, PARASECT
	sighting_mon $cb, PERSIAN
	sighting_mon $d8, VICTREEBEL
	sighting_mon $e5, VILEPLUME
	sighting_mon $f2, WEEZING
	sighting_mon $ff, SNORLAX
	db 0
RockTunnelSightings:
	sighting_mon $32, SANDSHREW
	sighting_mon $65, RHYHORN
	sighting_mon $8c, GRAVELER
	sighting_mon $b2, GOLBAT
	sighting_mon $cc, MAROWAK
	sighting_mon $e5, MACHOKE
	sighting_mon $f2, CLEFABLE
	sighting_mon $ff, GOLEM
	db 0
PowerPlantSightings:
	sighting_mon $4c, KOFFING
	sighting_mon $8c, WEEZING
	sighting_mon $bf, DITTO
	sighting_mon $e5, MACHOP
	sighting_mon $f2, MACHOKE
	sighting_mon $ff, PORYGON
	db 0
VictoryRoadSightings:
	sighting_mon $32, CUBONE
	sighting_mon $65, MAROWAK
	sighting_mon $8c, CLEFAIRY
	sighting_mon $b2, ARBOK
	sighting_mon $cc, PARASECT
	sighting_mon $e5, NIDOQUEEN
	sighting_mon $f2, NIDOKING
	sighting_mon $ff, KANGASKHAN
	db 0
PokemonTowerSightings:
	sighting_mon $32, DROWZEE
	sighting_mon $65, ABRA
	sighting_mon $8c, DITTO
	sighting_mon $b2, CLEFAIRY
	sighting_mon $cc, HYPNO
	sighting_mon $e5, KADABRA
	sighting_mon $f2, CLEFABLE
	sighting_mon $ff, ALAKAZAM
	db 0
SeafoamLandSightings:
	sighting_mon $32, MACHOP
	sighting_mon $65, CUBONE
	sighting_mon $8c, CLEFAIRY
	sighting_mon $b2, GEODUDE
	sighting_mon $cc, ONIX
	sighting_mon $e5, DITTO
	sighting_mon $f2, MACHOKE
	sighting_mon $ff, CLEFABLE
	db 0
SeafoamWaterSightings:
	sighting_mon $32, PSYDUCK
	sighting_mon $65, POLIWAG
	sighting_mon $8c, TENTACOOL
	sighting_mon $b2, GYARADOS
	sighting_mon $cc, TENTACRUEL
	sighting_mon $e5, DRATINI
	sighting_mon $f2, DRAGONAIR
	sighting_mon $ff, LAPRAS
	db 0
PokemonMansionSightings:
	sighting_mon $32, VULPIX
	sighting_mon $65, KOFFING
	sighting_mon $8c, WEEZING
	sighting_mon $b2, NINETALES
	sighting_mon $cc, ARCANINE
	sighting_mon $e5, RAPIDASH
	sighting_mon $f2, GOLEM
	sighting_mon $ff, NIDOKING
	db 0
DiglettsCaveSightings:
	sighting_mon $3f, SANDSHREW
	sighting_mon $72, GEODUDE
	sighting_mon $99, ZUBAT
	sighting_mon $bf, ONIX
	sighting_mon $d9, CUBONE
	sighting_mon $f2, MACHOP
	sighting_mon $ff, RHYHORN
	db 0
