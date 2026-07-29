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
	ld a, [wPikachuHappiness]
	push af
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
	pop bc
	push de
	call .queueHappinessTierReaction
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

.queueHappinessTierReaction
	; Walking changes are deliberately quiet, and a traded Pikachu cannot alert us.
	ld a, d
	cp PIKAHAPPY_WALKING
	ret z
	cp PIKAHAPPY_TRADE
	ret z
	; b contains the old happiness value.
	ld a, b
	call .getHappinessTier
	ld c, a
	ld a, [wPikachuHappiness]
	call .getHappinessTier
	cp c
	ret z
	ld b, PIKACOMPANION_REACTION_HEART
	jr nc, .tryQueueTierReaction
	ld b, PIKACOMPANION_REACTION_BOLT
.tryQueueTierReaction
	ld a, [wPikachuCompanionQueuedReaction]
	cp PIKACOMPANION_REACTION_GYM_VICTORY
	ret z
	cp PIKACOMPANION_REACTION_GIFT_READY
	ret z
	cp PIKACOMPANION_REACTION_PORTRAIT_READY
	ret z
	ld a, b
	ld [wPikachuCompanionQueuedReaction], a
	ret

.getHappinessTier
	ld b, 0
	cp 51
	jr c, .gotTier
	inc b
	cp 101
	jr c, .gotTier
	inc b
	cp 131
	jr c, .gotTier
	inc b
	cp 161
	jr c, .gotTier
	inc b
	cp 201
	jr c, .gotTier
	inc b
	cp 251
	jr c, .gotTier
	inc b
.gotTier
	ld a, b
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

UpdatePikachuCompanionOnStep::
	ld a, [wWalkBikeSurfState]
	cp BIKING
	ret z
	callfar IsStarterPikachuInOurParty
	ret nc

	ld hl, wPikachuGiftCooldown
	ld a, [hl]
	and a
	jr z, .giftCooldownDone
	dec [hl]
.giftCooldownDone

	callfar QueuePikachuGiftAlert

	ld hl, wPikachuCompanionStepCounter
	inc [hl]
	callfar UpdatePikachuAmbientFind
	ld hl, wPikachuCompanionStepCounter
	ld a, [hl]
	and $7
	call z, .driftMoodTowardNeutral
	ld a, [wPikachuCompanionStepCounter]
	and $7f
	call z, .tryQueueReaction

	ld a, [wPikachuCompanionStepCounter]
	and a
	ret nz
	ld d, PIKAHAPPY_WALKING
	jp ModifyPikachuHappiness

.driftMoodTowardNeutral
	ld hl, wPikachuMood
	ld a, [hl]
	cp 128
	ret z
	jr c, .increaseMood
	dec [hl]
	ret

.increaseMood
	inc [hl]
	ret

.tryQueueReaction
	ld a, [wPikachuCompanionQueuedReaction]
	and a
	ret nz
	call Random
	and $7
	ret nz

	ld a, [wPikachuHappiness]
	cp 70
	ld b, PIKACOMPANION_REACTION_BOLT
	jr c, .queueReaction
	cp 160
	ret c
	cp 250
	ld b, PIKACOMPANION_REACTION_SMILE
	jr c, .queueReaction
	ld b, PIKACOMPANION_REACTION_HEART
.queueReaction
	ld a, b
	ld [wPikachuCompanionQueuedReaction], a
	ret

UpdatePikachuCompanionIdle::
	call .queuePendingPortraitAlert
	ldh a, [hJoyHeld]
	ld b, a
	ldh a, [hJoyPressed]
	or b
	jp nz, .resetIdle
	ld a, [wPikachuCompanionQueuedReaction]
	and a
	jp z, .resetIdle

	ld hl, wPikachuCompanionIdleCounter
	inc [hl]
	ld a, [hl]
	cp 60
	ret c
	ld [hl], 60

	ld a, [wIsInBattle]
	and a
	jp nz, .resetIdle
	ld a, [wCurOpponent]
	and a
	jp nz, .resetIdle
	ld a, [wJoyIgnore]
	and a
	jp nz, .resetIdle
	ld a, [wStatusFlags5]
	and (1 << BIT_SCRIPTED_MOVEMENT_STATE) | (1 << BIT_DISABLE_JOYPAD) | (1 << BIT_SCRIPTED_NPC_MOVEMENT)
	jp nz, .resetIdle
	ld a, [wStatusFlags3]
	bit BIT_WARP_FROM_CUR_SCRIPT, a
	jp nz, .resetIdle
	ld a, [wStatusFlags6]
	and (1 << BIT_FLY_WARP) | (1 << BIT_DUNGEON_WARP)
	jp nz, .resetIdle
	call CheckPikachuFollowingPlayer
	jp nz, .resetIdle
	ld a, [wPikachuOverworldStateFlags]
	bit 3, a
	jp nz, .resetIdle
	ld a, [wSpritePikachuStateData1ImageIndex]
	cp $ff
	jp z, .resetIdle
	callfar IsStarterPikachuInOurParty
	jp nc, .resetIdle

	ld a, [wPikachuCompanionQueuedReaction]
	ld b, a
	xor a
	ld [wPikachuCompanionQueuedReaction], a
	ld [wPikachuCompanionIdleCounter], a
	ld a, b
	cp PIKACOMPANION_REACTION_BOLT
	jr z, .bolt
	cp PIKACOMPANION_REACTION_SMILE
	jr z, .smile
	cp PIKACOMPANION_REACTION_GYM_VICTORY
	jr z, .gymVictory
	cp PIKACOMPANION_REACTION_GIFT_READY
	jr z, .giftReady
	cp PIKACOMPANION_REACTION_AMBIENT_FIND
	jr z, .ambientFind
	cp PIKACOMPANION_REACTION_PORTRAIT_READY
	jr z, .portraitReady
	cp PIKACOMPANION_REACTION_HEART
	ret nz
	ld b, HEART_BUBBLE
	jr .facePlayer
.smile
	ld b, SMILE_BUBBLE
.facePlayer
	ld a, [wSpritePlayerStateData1FacingDirection]
	ld [wSpritePikachuStateData1FacingDirection], a
	jr .showBubble
.bolt
	callfar StarterPikachuEmotionCommand_turnawayfromplayer
	ld b, BOLT_BUBBLE
.showBubble
	push bc
	call UpdateSprites
	pop bc
	ld c, b
	jpfar ShowPikachuEmoteBubbleFromC
.gymVictory
	ldpikaemotion e, PikachuEmotion34
	jpfar PlaySpecificPikachuEmotion
.giftReady
	ld a, 1
	ld [wPikachuGiftAlerted], a
	ld b, EXCLAMATION_BUBBLE
	jr .facePlayer
.ambientFind
	ld a, 1
	ld [wPikachuAmbientAlerted], a
	ld b, QUESTION_BUBBLE
	jr .facePlayer

.portraitReady
	ld hl, wd49c
	set PIKACHU_PENDING_EMOTION_ALERTED_F, [hl]
	ld a, [hl]
	and PIKACHU_PENDING_EMOTION_MASK
	cp PIKACHU_PENDING_CAUGHT_MON
	jr z, .portraitSmile
	cp PIKACHU_PENDING_FISHING
	jr z, .portraitFish
	cp PIKACHU_PENDING_EVOLUTION_REFUSAL
	jr z, .portraitRefusal
	cp PIKACHU_PENDING_ELECTRIC_MOVE
	jr z, .portraitElectric
	cp PIKACHU_PENDING_SIGHTING
	jr z, .portraitSighting
	ld b, EXCLAMATION_BUBBLE
	jr .facePlayer
.portraitSmile
	ld b, SMILE_BUBBLE
	jr .facePlayer
.portraitFish
	ld b, FISH_BUBBLE
	jr .facePlayer
.portraitRefusal
	callfar StarterPikachuEmotionCommand_turnawayfromplayer
	ld b, EXCLAMATION_BUBBLE
	jr .showBubble
.portraitElectric
	ld b, BOLT_BUBBLE
	jr .facePlayer
.portraitSighting
	ld b, EXCLAMATION_BUBBLE
	jr .facePlayer

.queuePendingPortraitAlert
	ld a, [wd49c]
	bit PIKACHU_PENDING_EMOTION_ALERTED_F, a
	ret nz
	and PIKACHU_PENDING_EMOTION_MASK
	ret z
	ld a, [wPikachuCompanionQueuedReaction]
	cp PIKACOMPANION_REACTION_GYM_VICTORY
	ret z
	cp PIKACOMPANION_REACTION_GIFT_READY
	ret z
	ld a, PIKACOMPANION_REACTION_PORTRAIT_READY
	ld [wPikachuCompanionQueuedReaction], a
	ret

.resetIdle
	xor a
	ld [wPikachuCompanionIdleCounter], a
	ret
