UpdateWildSightingOnStep::
	ld hl, wSightingCooldown
	ld a, [hl]
	and a
	jr z, .cooldownDone
	dec [hl]
	ret

.cooldownDone
	ld a, [wSightingFlags]
	bit SIGHTING_ACTIVE_F, a
	ret nz

	ld hl, wSightingStepCounter
	inc [hl]
	ld a, [hl]
	and SIGHTING_STEP_INTERVAL - 1
	ret nz

	call GetCurrentWildSightingZoneAndProfile
	ld a, c
	and a
	ret z
	push bc
	call GetWildSightingProfile
	ld e, a
	ld a, [hl]
	and a
	pop bc
	ret z
	ld a, e
	and SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER
	ret z

	IF !DEF(_DEBUG)
		call Random
		cp SIGHTING_TRIGGER_CHANCE
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

; Return a profile's encounter-method flags in a and species-table pointer in hl.
GetWildSightingProfile:
	ld e, a
	ld d, 0
	ld hl, WildSightingProfiles
	add hl, de
	add hl, de
	add hl, de
	ld a, [hli]
	push af
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld h, d
	ld l, e
	pop af
	ret

INCLUDE "data/wild/sighting_maps.asm"

; Each profile contains supported encounter-method flags and a pointer to a
; weighted species table. Species tables are intentionally empty until their
; contents are balanced separately from the engine framework.
WildSightingProfiles:
	table_width 3, WildSightingProfiles
	sighting_profile 0, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, EarlyGrasslandSightings
	sighting_profile SIGHTING_METHOD_LAND, ForestSightings
	sighting_profile SIGHTING_METHOD_LAND, RockyRouteSightings
	sighting_profile SIGHTING_METHOD_LAND, MountainCaveSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, UrbanOutskirtsSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, WetlandSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, CoastalSightings
	sighting_profile SIGHTING_METHOD_WATER, OpenOceanSightings
	sighting_profile SIGHTING_METHOD_LAND, HauntedSightings
	sighting_profile SIGHTING_METHOD_LAND, IndustrialSightings
	sighting_profile SIGHTING_METHOD_LAND, VolcanicSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, IceCaveSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, SafariSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, EndgameSightings
	assert_table_length NUM_SIGHTING_PROFILES

NoWildSightings:
	db 0
EarlyGrasslandSightings:
IF DEF(_DEBUG)
	sighting_mon $ff, CATERPIE
ENDC
	db 0
ForestSightings:
	db 0
RockyRouteSightings:
	db 0
MountainCaveSightings:
	db 0
UrbanOutskirtsSightings:
	db 0
WetlandSightings:
	db 0
CoastalSightings:
	db 0
OpenOceanSightings:
	db 0
HauntedSightings:
	db 0
IndustrialSightings:
	db 0
VolcanicSightings:
	db 0
IceCaveSightings:
	db 0
SafariSightings:
	db 0
EndgameSightings:
	db 0
