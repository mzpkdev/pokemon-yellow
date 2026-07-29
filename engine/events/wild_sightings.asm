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

	; Let the player acknowledge Pikachu's hint before the encounter consumes
	; the sighting and clears its pending portrait.
	ld a, [wd49c]
	and PIKACHU_PENDING_EMOTION_MASK
	cp PIKACHU_PENDING_SIGHTING
	jr z, .noReplacementPop

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
	sighting_profile SIGHTING_METHOD_LAND, EarlyGrasslandSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, ForestSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, RockyRouteSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, MountainCaveSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, UrbanOutskirtsLandSightings, UrbanOutskirtsWaterSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, WetlandLandSightings, WetlandWaterSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, CoastalLandSightings, CoastalWaterSightings
	sighting_profile SIGHTING_METHOD_WATER, NoWildSightings, OpenOceanSightings
	sighting_profile SIGHTING_METHOD_LAND, HauntedSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, IndustrialSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, VolcanicSightings, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, IceCaveLandSightings, IceCaveWaterSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, SafariLandSightings, SafariWaterSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, EndgameLandSightings, EndgameWaterSightings
	assert_table_length NUM_SIGHTING_PROFILES

NoWildSightings:
	db 0
EarlyGrasslandSightings:
	sighting_mon $32, CATERPIE
	sighting_mon $65, WEEDLE
	sighting_mon $98, MEOWTH
	sighting_mon $be, VULPIX
	sighting_mon $e5, SANDSHREW
	sighting_mon $ff, PARAS
	db 0
ForestSightings:
	sighting_mon $32, PARAS
	sighting_mon $58, VENONAT
	sighting_mon $7f, BELLSPROUT
	sighting_mon $98, MEOWTH
	sighting_mon $b2, CLEFAIRY
	sighting_mon $cb, BUTTERFREE
	sighting_mon $e5, BEEDRILL
	sighting_mon $f2, SCYTHER
	sighting_mon $ff, PINSIR
	db 0
RockyRouteSightings:
	sighting_mon $32, GEODUDE
	sighting_mon $58, VULPIX
	sighting_mon $7f, GROWLITHE
	sighting_mon $a5, CUBONE
	sighting_mon $be, ONIX
	sighting_mon $d8, PONYTA
	sighting_mon $e5, MACHOKE
	sighting_mon $f2, MAGNETON
	sighting_mon $ff, WIGGLYTUFF
	db 0
MountainCaveSightings:
	sighting_mon $25, NIDORAN_F
	sighting_mon $4c, NIDORAN_M
	sighting_mon $72, EKANS
	sighting_mon $98, DROWZEE
	sighting_mon $b2, GOLBAT
	sighting_mon $cb, GRAVELER
	sighting_mon $d8, PARASECT
	sighting_mon $e5, MAROWAK
	sighting_mon $f2, CLEFABLE
	sighting_mon $ff, MACHOKE
	db 0
UrbanOutskirtsLandSightings:
	sighting_mon $25, ODDISH
	sighting_mon $4c, BELLSPROUT
	sighting_mon $72, DROWZEE
	sighting_mon $98, EXEGGCUTE
	sighting_mon $b2, PERSIAN
	sighting_mon $cb, CUBONE
	sighting_mon $d8, ARCANINE
	sighting_mon $e5, NINETALES
	sighting_mon $f2, ALAKAZAM
	sighting_mon $ff, EXEGGUTOR
	db 0
UrbanOutskirtsWaterSightings:
	sighting_mon $32, POLIWAG
	sighting_mon $65, SLOWPOKE
	sighting_mon $8b, GOLDEEN
	sighting_mon $b2, KRABBY
	sighting_mon $cb, SHELLDER
	sighting_mon $d8, STARYU
	sighting_mon $e5, POLIWHIRL
	sighting_mon $f2, STARMIE
	sighting_mon $ff, POLIWRATH
	db 0
WetlandLandSightings:
	sighting_mon $32, PARAS
	sighting_mon $65, EXEGGCUTE
	sighting_mon $8b, LICKITUNG
	sighting_mon $a5, CUBONE
	sighting_mon $be, DITTO
	sighting_mon $cb, PARASECT
	sighting_mon $d8, EXEGGUTOR
	sighting_mon $e5, VILEPLUME
	sighting_mon $f2, VICTREEBEL
	sighting_mon $ff, PINSIR
	db 0
WetlandWaterSightings:
	sighting_mon $32, POLIWAG
	sighting_mon $65, PSYDUCK
	sighting_mon $8b, GOLDEEN
	sighting_mon $b2, KRABBY
	sighting_mon $cb, HORSEA
	sighting_mon $d8, POLIWHIRL
	sighting_mon $e5, GOLDUCK
	sighting_mon $f2, POLIWRATH
	sighting_mon $ff, GYARADOS
	db 0
CoastalLandSightings:
	sighting_mon $32, DODUO
	sighting_mon $58, FARFETCHD
	sighting_mon $7f, EXEGGCUTE
	sighting_mon $a5, PONYTA
	sighting_mon $be, CUBONE
	sighting_mon $d8, PARAS
	sighting_mon $e5, DODRIO
	sighting_mon $f2, EXEGGUTOR
	sighting_mon $ff, LICKITUNG
	db 0
CoastalWaterSightings:
	sighting_mon $32, SHELLDER
	sighting_mon $65, STARYU
	sighting_mon $8b, KRABBY
	sighting_mon $b2, SEEL
	sighting_mon $cb, PSYDUCK
	sighting_mon $d8, CLOYSTER
	sighting_mon $e5, STARMIE
	sighting_mon $f2, KINGLER
	sighting_mon $ff, LAPRAS
	db 0
OpenOceanSightings:
	sighting_mon $32, KRABBY
	sighting_mon $65, SEEL
	sighting_mon $8b, LAPRAS
	sighting_mon $b2, DRATINI
	sighting_mon $cb, TENTACRUEL
	sighting_mon $e5, KINGLER
	sighting_mon $f2, DEWGONG
	sighting_mon $ff, DRAGONAIR
	db 0
HauntedSightings:
	sighting_mon $32, DROWZEE
	sighting_mon $65, ABRA
	sighting_mon $8b, DITTO
	sighting_mon $b2, CLEFAIRY
	sighting_mon $cb, HYPNO
	sighting_mon $d8, KADABRA
	sighting_mon $e5, CLEFABLE
	sighting_mon $f2, ALAKAZAM
	sighting_mon $ff, WIGGLYTUFF
	db 0
IndustrialSightings:
	sighting_mon $32, KOFFING
	sighting_mon $65, MACHOP
	sighting_mon $8b, DITTO
	sighting_mon $a5, WEEZING
	sighting_mon $be, MACHOKE
	sighting_mon $d8, PORYGON
	sighting_mon $e5, GOLEM
	sighting_mon $f2, ALAKAZAM
	sighting_mon $ff, MACHAMP
	db 0
VolcanicSightings:
	sighting_mon $32, VULPIX
	sighting_mon $65, KOFFING
	sighting_mon $8b, WEEZING
	sighting_mon $a5, NINETALES
	sighting_mon $be, ARCANINE
	sighting_mon $d8, RAPIDASH
	sighting_mon $e5, RHYDON
	sighting_mon $f2, GOLEM
	sighting_mon $ff, NIDOKING
	db 0
IceCaveLandSightings:
	sighting_mon $25, MACHOP
	sighting_mon $4c, CUBONE
	sighting_mon $72, CLEFAIRY
	sighting_mon $8b, GEODUDE
	sighting_mon $a5, ONIX
	sighting_mon $be, DITTO
	sighting_mon $cb, MACHOKE
	sighting_mon $d8, MAROWAK
	sighting_mon $e5, CLEFABLE
	sighting_mon $f2, RHYHORN
	sighting_mon $ff, GOLEM
	db 0
IceCaveWaterSightings:
	sighting_mon $25, PSYDUCK
	sighting_mon $4c, POLIWAG
	sighting_mon $72, TENTACOOL
	sighting_mon $98, LAPRAS
	sighting_mon $b2, DRATINI
	sighting_mon $cb, GYARADOS
	sighting_mon $e5, TENTACRUEL
	sighting_mon $f2, DRAGONAIR
	sighting_mon $ff, DRAGONITE
	db 0
SafariLandSightings:
	sighting_mon $25, NIDORAN_F
	sighting_mon $4c, NIDORAN_M
	sighting_mon $72, DODUO
	sighting_mon $98, PONYTA
	sighting_mon $b2, VULPIX
	sighting_mon $cb, DITTO
	sighting_mon $d8, PORYGON
	sighting_mon $e5, PERSIAN
	sighting_mon $f2, RAPIDASH
	sighting_mon $ff, ARCANINE
	db 0
SafariWaterSightings:
	sighting_mon $32, DRATINI
	sighting_mon $58, PSYDUCK
	sighting_mon $7f, POLIWAG
	sighting_mon $a5, SLOWPOKE
	sighting_mon $be, HORSEA
	sighting_mon $d8, LAPRAS
	sighting_mon $e5, DRAGONAIR
	sighting_mon $f2, GOLDUCK
	sighting_mon $ff, GYARADOS
	db 0
EndgameLandSightings:
	sighting_mon $25, ARCANINE
	sighting_mon $4c, NINETALES
	sighting_mon $65, RAPIDASH
	sighting_mon $7f, MAROWAK
	sighting_mon $98, SNORLAX
	sighting_mon $b2, PARASECT
	sighting_mon $be, PERSIAN
	sighting_mon $cb, VICTREEBEL
	sighting_mon $d8, VILEPLUME
	sighting_mon $e5, WEEZING
	sighting_mon $f2, NIDOKING
	sighting_mon $ff, NIDOQUEEN
	db 0
EndgameWaterSightings:
	sighting_mon $25, STARMIE
	sighting_mon $4c, CLOYSTER
	sighting_mon $72, LAPRAS
	sighting_mon $8b, KINGLER
	sighting_mon $a5, SEADRA
	sighting_mon $be, GOLDUCK
	sighting_mon $d8, TENTACRUEL
	sighting_mon $f2, DEWGONG
	sighting_mon $ff, SEAKING
	db 0
