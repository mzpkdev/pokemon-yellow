ModifyPikachuHappiness::
	ld a, d
	cp PIKAHAPPY_GYMLEADER
	jr z, .checkanywhereinparty
	cp PIKAHAPPY_WALKING
	jr z, .checkanywhereinparty
	push de
	callfar IsThisPartymonStarterPikachu_Party
	pop de
	ret nc
	jr .proceed

.checkanywhereinparty
	push de
	callfar IsStarterPikachuInOurParty
	pop de
	ret nc

.proceed
	push de
	; Divide [wPikachuHappiness] by 100.  Hold the integer part in e.
	ld e, $0
	ld a, [wPikachuHappiness]
	cp 100
	jr c, .wPikachuHappiness_div_100
	inc e
	cp 200
	jr c, .wPikachuHappiness_div_100
	inc e
.wPikachuHappiness_div_100
	; Get the (d, e) entry from HappinessChangeTable.
	ld c, d
	dec c
	ld b, $0
	ld hl, HappinessChangeTable
	add hl, bc
	add hl, bc
	add hl, bc
	ld d, $0
	add hl, de
	ld a, [hl]
	; If [hl] is positive, take min(0xff, [hl] + [wPikachuHappiness]).
	; If [hl] is negative, take max(0x00, [hl] + [wPikachuHappiness]).
	; Inexplicably, we're using 100 as the threshold for comparison.
	cp 100
	ld a, [wPikachuHappiness]
	jr nc, .negative
	add [hl]
	jr nc, .okay
	ld a, -1
	jr .okay

.negative
	add [hl]
	jr c, .okay
	xor a
.okay
	ld [wPikachuHappiness], a

	; Restore d and apply the corresponding additive mood change.
	pop de
	ld a, d
	cp PIKAHAPPY_DEPOSITED
	jr z, .deposited
	cp PIKAHAPPY_TRADE
	jr z, .traded
	dec d
	ld hl, PikachuMoodChanges
	ld e, d
	ld d, $0
	add hl, de
	ld b, [hl]
	ld a, b
	and a
	ret z
	bit 7, b
	jr nz, .decreaseMood
	ld a, [wPikachuMood]
	add b
	jr nc, .storeMood
	ld a, $ff
	jr .storeMood

.decreaseMood
	ld a, [wPikachuMood]
	add b
	jr c, .storeMood
	xor a
.storeMood
	ld [wPikachuMood], a
	ret

.deposited
	ld a, [wPikachuMood]
	cp 33
	ret c
	ld a, 32
	ld [wPikachuMood], a
	ret

.traded
	xor a
	ld [wPikachuMood], a
	ret

HappinessChangeTable:
	; Increase
	db   5, 3, 2 ; Gained a level
	db   5, 3, 2 ; HP restore
	db   1, 1, 0 ; Used X item
	db   3, 2, 1 ; Challenged Gym Leader
	db   1, 1, 0 ; Teach TM/HM
	db   2, 1, 1 ; Walking around
	; Decrease
	db  -3, -3, -5 ; Deposited
	db  -1, -1, -1 ; Fainted in battle
	db  -5, -5, -10 ; Fainted due to Poison outside of battle
	db  -5, -5, -10 ; Fainted to opponent at least 30 levels higher
	db -10, -10, -20 ; Traded away

PikachuMoodChanges:
	db  12 ; Gained a level
	db   4 ; HP restore
	db   0 ; Used X item
	db  20 ; Challenged Gym Leader
	db   8 ; Teach TM/HM
	db   0 ; Walking around (handled separately)
	db   0 ; Deposited (handled separately)
	db  -6 ; Fainted in battle
	db -20 ; Fainted due to poison outside of battle
	db -16 ; Fainted to an opponent at least 30 levels higher
	db   0 ; Traded away (handled separately)
