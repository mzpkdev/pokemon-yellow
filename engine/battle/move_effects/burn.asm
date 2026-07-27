BurnEffect_:
	ld hl, wEnemyMonStatus
	ld de, wEnemyMonType
	ldh a, [hWhoseTurn]
	and a
	jr z, .checkTarget
	ld hl, wBattleMonStatus
	ld de, wBattleMonType
.checkTarget
	ld a, [hl]
	and a
	jr nz, .didntAffect
	ld a, [de]
	cp FIRE
	jr z, .didntAffect
	inc de
	ld a, [de]
	cp FIRE
	jr z, .didntAffect
	push hl
	callfar MoveHitTest
	pop hl
	ld a, [wMoveMissed]
	and a
	jr nz, .didntAffect
	call .applyBurn
	ld c, 30
	rst _DelayFrames
	callfar PlayCurrentMoveAnimation
	jr .printBurned
.didntAffect
	ld c, 50
	rst _DelayFrames
	jpfar PrintDidntAffectText

BurnSideEffect_:
	call BattleRandom
	cp 10 percent
	ret nc
	ld hl, wEnemyMonHP
	ld de, wEnemyMonStatus
	ld bc, wEnemyMonType
	ldh a, [hWhoseTurn]
	and a
	jr z, .checkTarget
	ld hl, wBattleMonHP
	ld de, wBattleMonStatus
	ld bc, wBattleMonType
.checkTarget
	ld a, [hli]
	or [hl]
	ret z
	ld a, [de]
	and a
	ret nz
	ld a, [bc]
	cp FIRE
	ret z
	inc bc
	ld a, [bc]
	cp FIRE
	ret z
	ld h, d
	ld l, e
	call BurnEffect_.applyBurn
.printBurned
	ld hl, BurnedText2
	jpfar PrintText

BurnEffect_.applyBurn:
	set BRN, [hl]
	callfar HalveAttackDueToBurn
	ret

BurnedText2:
	text_far _BurnedText
	text_end
