IsStarterPikachuInOurParty::
	ld a, [wWhichPokemon]
	push af
	xor a
	ld [wWhichPokemon], a
.loop
	ld a, [wWhichPokemon]
	ld hl, wPartyCount
	cp [hl]
	jr nc, .notFound
	call IsThisPartymonStarterPikachu_Party
	jr c, .found
	ld hl, wWhichPokemon
	inc [hl]
	jr .loop

.found
	pop af
	ld [wWhichPokemon], a
	scf
	ret

.notFound
	pop af
	ld [wWhichPokemon], a
	and a
	ret

IsThisPartymonStarterPikachu_Box::
	ld a, STARTER_PIKACHU
	ld hl, wBoxMon1
	ld bc, wBoxMon2 - wBoxMon1
	ld de, wBoxMonOT
	jr CheckThisPartymonStarterCompanion

IsThisPartymonStarterPikachu_Party::
IsThisPartymonStarterPikachu::
	ld a, STARTER_PIKACHU
	jr CheckThisPartymonStarterCompanion_Party

IsThisPartymonStarterCompanion_Box::
	ld a, $ff
	ld hl, wBoxMon1
	ld bc, wBoxMon2 - wBoxMon1
	ld de, wBoxMonOT
	jr CheckThisPartymonStarterCompanion

IsThisPartymonStarterCompanion_Party::
	ld a, $ff
CheckThisPartymonStarterCompanion_Party:
	ld hl, wPartyMon1
	ld bc, wPartyMon2 - wPartyMon1
	ld de, wPartyMonOT
CheckThisPartymonStarterCompanion:
	push af
	push de
	ld a, [wWhichPokemon]
	call AddNTimes
	pop de
	pop af
	ld b, a
	ld a, [hl]
	ld c, a
	ld a, b
	cp $ff
	ld a, c
	jr z, .checkCompanionSpecies
	cp STARTER_PIKACHU
	jr nz, .notPlayerPikachu
.checkFingerprint
	push de
	ld bc, MON_CATCH_RATE
	add hl, bc
	ld a, [hl]
	cp LIGHT_BALL_GSC
	jr nz, .fingerprintMismatch
	ld bc, MON_OTID - MON_CATCH_RATE
	add hl, bc
	ld a, [wPlayerID]
	cp [hl]
	jr nz, .fingerprintMismatch
	inc hl
	ld a, [wPlayerID+1]
	cp [hl]
	jr nz, .fingerprintMismatch
	ld bc, MON_DVS - (MON_OTID + 1)
	add hl, bc
	ld a, [wStarterCompanionDVs]
	cp [hl]
	jr nz, .fingerprintMismatch
	inc hl
	ld a, [wStarterCompanionDVs + 1]
	cp [hl]
	jr nz, .fingerprintMismatch
	pop hl
	ld a, [wWhichPokemon]
	ld bc, NAME_LENGTH
	call AddNTimes
	ld de, wPlayerName
	ld b, NAME_LENGTH
.loop
	ld a, [de]
	cp [hl]
	jr nz, .notPlayerPikachu
	cp "@"
	jr z, .isPlayerPikachu
	inc de
	inc hl
	dec b
	jr nz, .loop
.notPlayerPikachu
	and a
	ret

.checkCompanionSpecies
	cp STARTER_PIKACHU
	jr z, .checkFingerprint
	cp RAICHU
	jr z, .checkFingerprint
	jr .notPlayerPikachu

.fingerprintMismatch
	pop de
	jr .notPlayerPikachu

.isPlayerPikachu
	scf
	ret

CanStarterCompanionFollow::
	call IsThisPartymonStarterCompanion_Party
	ret nc
	ld a, [wWhichPokemon]
	ld hl, wPartySpecies
	ld b, 0
	ld c, a
	add hl, bc
	ld a, [hl]
	cp STARTER_PIKACHU
	jr z, .supported
	and a
	ret
.supported
	scf
	ret

CanStarterCompanionInPartyFollow::
	ld a, [wWhichPokemon]
	push af
	xor a
	ld [wWhichPokemon], a
.loop
	ld a, [wWhichPokemon]
	ld hl, wPartyCount
	cp [hl]
	jr nc, .notFound
	call CanStarterCompanionFollow
	jr c, .found
	ld hl, wWhichPokemon
	inc [hl]
	jr .loop

.found
	pop af
	ld [wWhichPokemon], a
	scf
	ret

.notFound
	pop af
	ld [wWhichPokemon], a
	and a
	ret

RecordStarterPikachuSurgeLoss::
	ld a, [wBattleResult]
	and a
	ret z
	ld a, [wSurrenderedFromTrainerBattle]
	and a
	ret nz
	ld a, [wCurOpponent]
	cp OPP_LT_SURGE
	ret nz
	CheckEvent EVENT_BEAT_LT_SURGE
	ret nz
	ld a, [wWhichPokemon]
	push af
	xor a
	ld [wWhichPokemon], a
.findStarter
	ld a, [wWhichPokemon]
	ld hl, wPartyCount
	cp [hl]
	jr nc, .notParticipated
	call IsThisPartymonStarterPikachu_Party
	jr c, .checkParticipation
	ld hl, wWhichPokemon
	inc [hl]
	jr .findStarter

.checkParticipation
	ld a, [wWhichPokemon]
	ld c, a
	ld b, FLAG_TEST
	ld hl, wPartyGainExpFlags
	predef FlagActionPredef
	ld a, c
	and a
	jr z, .notParticipated
	SetEvent EVENT_LOST_TO_LT_SURGE_WITH_STARTER_PIKACHU
.notParticipated
	pop af
	ld [wWhichPokemon], a
	ret

CanStarterPikachuAcceptEvolution::
	ld a, [wPikachuHappiness]
	cp PIKACHU_EVOLUTION_HAPPINESS
	jr c, .notEligible
	CheckEvent EVENT_LOST_TO_LT_SURGE_WITH_STARTER_PIKACHU
	jr z, .checkFuji
	ld a, PIKACHU_EVOLUTION_ROUTE_SURGE
	scf
	ret

.checkFuji
	CheckEvent EVENT_RESCUED_MR_FUJI
	jr z, .notEligible
	ld a, PIKACHU_EVOLUTION_ROUTE_FUJI
	scf
	ret

.notEligible
	ld a, PIKACHU_EVOLUTION_ROUTE_NONE
	and a
	ret
