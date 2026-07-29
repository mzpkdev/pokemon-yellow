; Checks the next entry in the ordered gift queue. This is called only by
; IsPlayerTalkingToPikachu, so scripted Pikachu reactions cannot give gifts.
; Each entry contains an eligibility function, an item, and a quantity.
; The eligibility function returns carry when its requirements are met.
; Return carry when a gift interaction was handled.
TryPikachuGift::
	ld a, [wPikachuGiftCooldown]
	and a
	jp nz, .noGift
	ld a, [wPikachuNextGift]
	ld c, a
	ld b, 0
	ld hl, PikachuGiftTable
.findGift
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	or e
	jp z, .noGift
	ld a, c
	and a
	jr z, .checkEligibility
	inc hl
	inc hl
	inc hl
	inc hl
	dec c
	jr .findGift

.checkEligibility
	push hl
	push de
	ld h, d
	ld l, e
	call JumpToAddress
	pop de
	pop hl
	jr nc, .noGift

	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld b, [hl]
	inc hl
	ld c, [hl]
	push de
	push bc
	ld c, SMILE_BUBBLE
	callfar ShowPikachuEmoteBubbleFromC
	ldpikacry e, PikachuCry35
	callfar PlayPikachuSoundClip
	pop bc
	pop de
	push bc
	ld a, d
	or e
	jr z, .genericFoundText
	ld h, d
	ld l, e
	jr .printFoundText
.genericFoundText
	ld hl, PikachuFoundGiftText
.printFoundText
	push hl
	farcall DisplayTextIDInit
	pop hl
	rst _PrintText
	pop bc
	call GiveItem
	jr nc, .bagFull

	ld hl, wPikachuNextGift
	inc [hl]
	xor a
	ld [wPikachuGiftAlerted], a
	ld a, [wPikachuCompanionQueuedReaction]
	cp PIKACOMPANION_REACTION_GIFT_READY
	jr nz, .keepQueuedReaction
	xor a
	ld [wPikachuCompanionQueuedReaction], a
.keepQueuedReaction
	ld a, PIKACHU_GIFT_COOLDOWN_STEPS
	ld [wPikachuGiftCooldown], a
	ld a, [wItemQuantity]
	cp 1
	ld hl, PikachuReceivedMultipleGiftsText
	jr nz, .printReceivedText
	ld hl, PikachuReceivedGiftText
.printReceivedText
	rst _PrintText
	call CloseTextDisplay
	scf
	ret

.bagFull
	ld hl, PikachuGiftBagFullText
	rst _PrintText
	call CloseTextDisplay
	scf
	ret

.noGift
	and a
	ret

; Queue a one-time exclamation reaction when the next gift becomes eligible.
; Delivery remains exclusive to player-initiated Pikachu interactions.
QueuePikachuGiftAlert::
	ld a, [wPikachuGiftCooldown]
	and a
	ret nz
	ld a, [wPikachuGiftAlerted]
	and a
	ret nz

	ld a, [wPikachuNextGift]
	ld c, a
	ld hl, PikachuGiftTable
.findGift
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	or e
	ret z
	ld a, c
	and a
	jr z, .checkEligibility
	inc hl
	inc hl
	inc hl
	inc hl
	dec c
	jr .findGift

.checkEligibility
	ld h, d
	ld l, e
	call JumpToAddress
	ret nc
	ld a, [wPikachuCompanionQueuedReaction]
	and a
	jr z, .queueGiftAlert
	cp PIKACOMPANION_REACTION_AMBIENT_FIND
	jr z, .queueGiftAlert
	cp PIKACOMPANION_REACTION_PORTRAIT_READY
	ret nz
.queueGiftAlert
	ld a, PIKACOMPANION_REACTION_GIFT_READY
	ld [wPikachuCompanionQueuedReaction], a
	ret

; Roll for a found item at the configured eligible-step interval, then queue a
; one-time question reaction. A ready milestone gift always takes priority.
UpdatePikachuAmbientFind::
	call IsNextPikachuGiftReady
	ret c
	ld a, [wPikachuAmbientItem]
	and a
	jr nz, .tryQueueAlert
	ld a, [wPikachuCompanionStepCounter]
	and PIKACHU_AMBIENT_FIND_STEP_MASK
	ret nz
	call Random
	and PIKACHU_AMBIENT_FIND_CHANCE_MASK
	ret nz

	ld hl, PikachuAmbientFindsLow
	ld a, [wPikachuHappiness]
	cp 100
	jr c, .chooseItem
	ld hl, PikachuAmbientFindsMid
	cp 200
	jr c, .chooseItem
	ld hl, PikachuAmbientFindsHigh
.chooseItem
	call Random
	and 7
	ld e, a
	ld d, 0
	add hl, de
	ld a, [hl]
	ld [wPikachuAmbientItem], a
	xor a
	ld [wPikachuAmbientAlerted], a

.tryQueueAlert
	ld a, [wPikachuAmbientAlerted]
	and a
	ret nz
	ld a, [wPikachuCompanionQueuedReaction]
	and a
	ret nz
	ld a, PIKACOMPANION_REACTION_AMBIENT_FIND
	ld [wPikachuCompanionQueuedReaction], a
	ret

; Return carry when the next ordered milestone gift is currently available.
IsNextPikachuGiftReady:
	ld a, [wPikachuGiftCooldown]
	and a
	ret nz
	ld a, [wPikachuNextGift]
	ld c, a
	ld hl, PikachuGiftTable
.findGift
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	or e
	ret z
	ld a, c
	and a
	jr z, .checkEligibility
	inc hl
	inc hl
	inc hl
	inc hl
	dec c
	jr .findGift
.checkEligibility
	ld h, d
	ld l, e
	jp JumpToAddress

; Deliver Pikachu's held ambient find during a player-initiated interaction.
TryPikachuAmbientFind::
	ld a, [wPikachuAmbientItem]
	and a
	ret z
	ld b, a
	ld c, 1
	push bc
	ld c, QUESTION_BUBBLE
	callfar ShowPikachuEmoteBubbleFromC
	ldpikacry e, PikachuCry35
	callfar PlayPikachuSoundClip
	ld hl, PikachuAmbientFoundText
	push hl
	farcall DisplayTextIDInit
	pop hl
	rst _PrintText
	pop bc
	call GiveItem
	jr nc, .bagFull

	xor a
	ld [wPikachuAmbientItem], a
	ld [wPikachuAmbientAlerted], a
	ld a, [wPikachuCompanionQueuedReaction]
	cp PIKACOMPANION_REACTION_AMBIENT_FIND
	jr nz, .keepQueuedReaction
	xor a
	ld [wPikachuCompanionQueuedReaction], a
.keepQueuedReaction
	ld hl, PikachuReceivedGiftText
	rst _PrintText
	call CloseTextDisplay
	scf
	ret

.bagFull
	ld hl, PikachuGiftBagFullText
	rst _PrintText
	call CloseTextDisplay
	scf
	ret

PikachuAmbientFindsLow:
	db POTION, POKE_BALL, ANTIDOTE, PARLYZ_HEAL
	db AWAKENING, POTION, POKE_BALL, ANTIDOTE

PikachuAmbientFindsMid:
	db POTION, POKE_BALL, ANTIDOTE, AWAKENING
	db REPEL, SUPER_POTION, GREAT_BALL, PARLYZ_HEAL

PikachuAmbientFindsHigh:
	db SUPER_POTION, GREAT_BALL, REPEL, FULL_HEAL
	db POTION, POKE_BALL, ESCAPE_ROPE, ANTIDOTE

; Ordered gift queue. Add entries with:
;   dw EligibilityFunction
;   dw CustomMessage ; use 0 for PikachuFoundGiftText
;   db ITEM, quantity
; Only the next entry is checked, and it advances after GiveItem succeeds.
PikachuGiftTable:
	dw PikachuGiftAfterBrockEligible
	dw PikachuGiftAfterBrockText
	db ESCAPE_ROPE, 1

	dw PikachuGiftAfterSurgeEligible
	dw PikachuGiftAfterSurgeText
	db SUPER_REPEL, 3

	dw PikachuGiftAfterPokemonTowerEligible
	dw PikachuGiftAfterPokemonTowerText
	db HYPER_POTION, 2

	dw PikachuGiftBeforePokemonLeagueEligible
	dw PikachuGiftBeforePokemonLeagueText
	db ELIXER, 1

	dw 0

PikachuGiftAfterBrockEligible:
	CheckEvent EVENT_BEAT_BROCK
	jr z, .notEligible
	ld a, [wPikachuHappiness]
	cp 80
	jr c, .notEligible
	scf
	ret
.notEligible
	and a
	ret

PikachuGiftAfterSurgeEligible:
	CheckEvent EVENT_BEAT_LT_SURGE
	jr z, .notEligible
	ld a, [wPikachuHappiness]
	cp 130
	jr c, .notEligible
	scf
	ret
.notEligible
	and a
	ret

PikachuGiftAfterPokemonTowerEligible:
	CheckEvent EVENT_RESCUED_MR_FUJI
	jr z, .notEligible
	ld a, [wPikachuHappiness]
	cp 180
	jr c, .notEligible
	scf
	ret
.notEligible
	and a
	ret

PikachuGiftBeforePokemonLeagueEligible:
	ld a, [wObtainedBadges]
	cp $ff
	jr nz, .notEligible
	ld a, [wPikachuHappiness]
	cp 220
	jr c, .notEligible
	scf
	ret
.notEligible
	and a
	ret

PikachuGiftAfterBrockText:
	text_far _PikachuGiftAfterBrockText
	text_end

PikachuGiftAfterSurgeText:
	text_far _PikachuGiftAfterSurgeText
	text_end

PikachuGiftAfterPokemonTowerText:
	text_far _PikachuGiftAfterPokemonTowerText
	text_end

PikachuGiftBeforePokemonLeagueText:
	text_far _PikachuGiftBeforePokemonLeagueText
	text_end

PikachuFoundGiftText:
	text_far _PikachuFoundGiftText
	text_end

PikachuAmbientFoundText:
	text_far _PikachuAmbientFoundText
	text_end

PikachuReceivedGiftText:
	text_far _PikachuReceivedGiftText
	sound_get_item_1
	text_end

PikachuReceivedMultipleGiftsText:
	text_far _PikachuReceivedMultipleGiftsText
	sound_get_item_1
	text_end

PikachuGiftBagFullText:
	text_far _PikachuGiftBagFullText
	text_end
