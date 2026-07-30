; Create a party Egg.
; Input: a = species that will hatch, bc = incubation steps (1-65535).
; Output: carry set on success, clear if the party is full.
; Clobbers: af, bc, de, hl.
CreatePartyEgg::
	push bc
	push af
	ld a, [wMonDataLocation]
	push af
	ld a, EGG
	ld [wCurPartySpecies], a
	ld a, 1
	ld [wCurEnemyLevel], a
	; A nonzero high nybble suppresses naming while still selecting player data.
	ld a, $10
	ld [wMonDataLocation], a
	call _AddPartyMon
	jr nc, .partyFull
	pop af
	ld [wMonDataLocation], a
	pop de ; d = target species
	pop bc

	ld a, [wPartyCount]
	dec a
	push bc
	push de
	push af
	ld hl, wPartyMon1HP
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	xor a
	ld [hli], a
	ld [hl], a
	ld hl, wPartyMon1MaxHP
	pop af
	push af
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	xor a
	ld [hli], a
	ld [hl], a

	pop af
	ld hl, wPartyMon1CatchRate
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	pop de
	ld [hl], d
	pop bc
	ld de, MON_EXP - MON_CATCH_RATE
	add hl, de
	xor a
	ld [hli], a
	ld [hl], b
	inc hl
	ld [hl], c

	; AddPartyMon already supplied the default species name, but it was written
	; before naming was suppressed only in older call paths. Set it explicitly.
	ld a, EGG
	ld [wNamedObjectIndex], a
	call GetMonName
	push de
	ld hl, wPartyMonNicks
	ld a, [wPartyCount]
	dec a
	call .AddNameOffset
	ld d, h
	ld e, l
	pop hl
	ld bc, NAME_LENGTH
	rst _CopyData

.success
	scf
	ret

.partyFull
	pop af
	ld [wMonDataLocation], a
	pop de
	pop bc
	and a
	ret

.AddNameOffset
	and a
	ret z
.nameLoop
	ld bc, NAME_LENGTH
	add hl, bc
	dec a
	jr nz, .nameLoop
	ret

; Cancel an attempted Cable Club Egg trade without leaving the peer waiting for
; the selection exchange, then explain why the Egg stayed with its Trainer.
HandleCableEggTradeRejection::
	ld a, $f
	ld [wSerialExchangeNybbleSendData], a
	farcall Serial_PrintWaitingTextAndSyncAndExchangeNybble
	ld hl, .Text
	rst _PrintText
	ret

.Text:
	text_far _EggCannotBeTradedText
	text_end

; Decrement every Egg in the party by one step. Boxed Eggs are not scanned.
; The first Egg that reaches zero becomes pending; other ready Eggs remain at
; zero and can be discovered after the pending Egg is hatched.
UpdatePartyEggsOnStep::
	ld a, [wPartyCount]
	and a
	ret z
	ld b, a
	ld c, 0
	ld hl, wPartyMon1
.loop
	ld a, [hl]
	cp EGG
	jr nz, .next
	push hl
	ld de, MON_EXP
	add hl, de
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
	ld a, [hl]
	or d
	or e
	jr z, .markReady ; already ready and no other Egg may be pending

	; Big-endian 24-bit decrement.
	ld a, [hl]
	sub 1
	ld [hld], a
	ld a, [hl]
	sbc 0
	ld [hld], a
	ld a, [hl]
	sbc 0
	ld [hl], a
	or [hl]
	inc hl
	or [hl]
	inc hl
	or [hl]
	jr nz, .restore
.markReady
	ld a, [wEggHatchPending]
	and a
	jr nz, .restore
	ld a, 1
	ld [wEggHatchPending], a
	ld a, c
	ld [wEggHatchPartyIndex], a
.restore
	pop hl
.next
	ld de, wPartyMon2 - wPartyMon1
	add hl, de
	inc c
	dec b
	jr nz, .loop
	ret

; Hatch the pending party Egg.
; Output: carry set on success, clear if no valid ready Egg is pending.
; The hatch target is read from MON_CATCH_RATE. OT ID, DVs, and stat experience
; are retained; species data, moves, PP, level, experience, stats, and HP are
; initialized for EGG_HATCH_LEVEL.
HatchPartyEgg::
	ld a, [wEggHatchPending]
	and a
	ret z
	ld a, [wEggHatchPartyIndex]
	ld c, a
	ld a, [wPartyCount]
	cp c
	jr z, .invalid
	jr c, .invalid
	ld a, c
	ld hl, wPartyMon1
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a, [hl]
	cp EGG
	jr nz, .invalid
	push hl
	ld de, MON_EXP
	add hl, de
	ld a, [hli]
	or [hl]
	inc hl
	or [hl]
	pop hl
	jr nz, .invalid

	push hl
	ld de, MON_CATCH_RATE
	add hl, de
	ld a, [hl]
	and a
	jr z, .invalidPop
	cp EGG
	jr z, .invalidPop
	ld [wCurSpecies], a
	ld [wCurPartySpecies], a
	ld [wPokedexNum], a
	call GetMonHeader
	pop hl
	ld a, [wCurSpecies]
	ld [hl], a

	push hl
	ld de, MON_BOX_LEVEL
	add hl, de
	xor a
	ld [hli], a
	ld [hli], a ; status
	ld a, [wMonHType1]
	ld [hli], a
	ld a, [wMonHType2]
	ld [hli], a
	ld a, [wMonHCatchRate]
	ld [hli], a
	ld de, wMonHMoves
	ld b, NUM_MOVES
.copyMoves
	ld a, [de]
	inc de
	ld [hli], a
	dec b
	jr nz, .copyMoves
	ld de, MON_EXP - (MON_MOVES + NUM_MOVES)
	add hl, de
	push hl
	ld d, EGG_HATCH_LEVEL
	callfar CalcExperience
	pop hl
	ldh a, [hExperience]
	ld [hli], a
	ldh a, [hExperience + 1]
	ld [hli], a
	ldh a, [hExperience + 2]
	ld [hl], a
	pop hl

	; Generate PP from the newly copied moves.
	push hl
	ld de, MON_MOVES
	add hl, de
	push hl
	ld de, MON_PP - MON_MOVES - 1
	add hl, de
	ld d, h
	ld e, l
	pop hl
	call AddPartyMon_WriteMovePP
	pop hl

	push hl
	ld de, MON_LEVEL
	add hl, de
	ld a, EGG_HATCH_LEVEL
	ld [hl], a
	ld [wCurEnemyLevel], a
	pop hl

	; Calculate stats using the retained stat experience and DVs.
	push hl
	push hl
	ld bc, MON_HP_EXP - 1
	add hl, bc
	pop de
	push hl
	ld hl, MON_STATS
	add hl, de
	ld d, h
	ld e, l
	pop hl
	ld b, 1
	call CalcStats
	pop hl
	push hl
	ld de, MON_MAXHP
	add hl, de
	ld a, [hli]
	ld d, a
	ld e, [hl]
	pop hl
	inc hl
	ld [hl], d
	inc hl
	ld [hl], e

	; Use the species name as the hatchling's default nickname.
	ld a, [wCurSpecies]
	ld [wNamedObjectIndex], a
	call GetMonName
	push de
	ld hl, wPartyMonNicks
	ld a, [wEggHatchPartyIndex]
	call CreatePartyEgg.AddNameOffset
	ld d, h
	ld e, l
	pop hl
	ld bc, NAME_LENGTH
	rst _CopyData

	; Register the hatchling, not Egg, as seen and owned.
	ld a, [wCurSpecies]
	ld [wPokedexNum], a
	predef IndexToPokedex
	ld a, [wPokedexNum]
	dec a
	ld c, a
	ld b, FLAG_SET
	push bc
	ld hl, wPokedexOwned
	call FlagAction
	pop bc
	ld hl, wPokedexSeen
	call FlagAction

	xor a
	ld [wEggHatchPending], a
	ld a, $ff
	ld [wEggHatchPartyIndex], a
	scf
	ret

.invalidPop
	pop hl
.invalid
	xor a
	ld [wEggHatchPending], a
	ld a, $ff
	ld [wEggHatchPartyIndex], a
	and a
	ret
