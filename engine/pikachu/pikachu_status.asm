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
	ld b, $6
.loop
	dec b
	jr z, .isPlayerPikachu
	ld a, [de]
	inc de
	cp [hl]
	inc hl
	jr z, .loop
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

CheckPikachuFaintedOrStatused::
; function to test if Pikachu is alive?
	xor a
	ld [wWhichPokemon], a
	ld hl, wPartyCount
.loop
	inc hl
	ld a, [hl]
	cp $ff
	jr z, .dead_or_not_in_party
	push hl
	call IsThisPartymonStarterPikachu_Party
	pop hl
	jr nc, .next
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1HP
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a, [hli]
	or [hl]
	ld d, a
	inc hl
	inc hl
	ld a, [hl] ; status
	and a
	jr nz, .alive
	jr .dead_or_not_in_party

.next
	ld a, [wWhichPokemon]
	inc a
	ld [wWhichPokemon], a
	jr .loop

.alive
	scf
	ret

.dead_or_not_in_party
	and a
	ret

IsSurfingPikachuInThePlayersParty::
	ld hl, wPartySpecies
	ld de, wPartyMon1Moves
	ld bc, wPartyMonOT
	push hl
.loop
	pop hl
	ld a, [hli]
	push hl
	inc a
	jr z, .noSurfingPlayerPikachu
	cp STARTER_PIKACHU + 1
	jr nz, .curMonNotSurfingPlayerPikachu
	ld h, d
	ld l, e
	push hl
	push bc
	ld b, NUM_MOVES
.moveSearchLoop
	ld a, [hli]
	cp SURF
	jr z, .foundSurfingPikachu
	dec b
	jr nz, .moveSearchLoop
	pop bc
	pop hl
	jr .curMonNotSurfingPlayerPikachu

.foundSurfingPikachu
	pop bc
	pop hl
	inc hl
	inc hl
	inc hl
	inc hl
	ld a, [wPlayerID]
	cp [hl]
	jr nz, .curMonNotSurfingPlayerPikachu
	inc hl
	ld a, [wPlayerID+1]
	cp [hl]
	jr nz, .curMonNotSurfingPlayerPikachu
	push de
	push bc
	ld hl, wPlayerName
	ld d, $6
.nameCompareLoop
	dec d
	jr z, .foundSurfingPlayerPikachu
	ld a, [bc]
	inc bc
	cp [hl]
	inc hl
	jr z, .nameCompareLoop
	pop bc
	pop de
.curMonNotSurfingPlayerPikachu
	ld hl, wPartyMon2 - wPartyMon1
	add hl, de
	ld d, h
	ld e, l
	ld hl, NAME_LENGTH
	add hl, bc
	ld b, h
	ld c, l
	jr .loop

.foundSurfingPlayerPikachu
	pop bc
	pop de
	pop hl
	scf
	ret

.noSurfingPlayerPikachu
	pop hl
	and a
	ret
