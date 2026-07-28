InitPlayerData:
InitPlayerData2:

	call Random
	ldh a, [hRandomSub]
	ld [wPlayerID], a

	call Random
	ldh a, [hRandomAdd]
	ld [wPlayerID + 1], a

	ld a, $ff
	ld [wUnusedPlayerDataByte], a

	ld a, 30 ; initialize happiness to 30
	ld [wPikachuHappiness], a
	xor a
	ld [wPikachuMood], a ; initialize mood
	ld [wPikachuCompanionStepCounter], a
	ld [wPikachuNextGift], a
	ld [wPikachuGiftCooldown], a
	ld [wPikachuGiftAlerted], a
	ld [wPikachuAmbientItem], a
	ld [wPikachuAmbientAlerted], a
	ld [wStarterCompanionDVs], a
	ld [wStarterCompanionDVs + 1], a
	ld [wPikachuCompanionQueuedReaction], a
	ld [wPikachuCompanionIdleCounter], a

	ld hl, wPartyCount
	call InitializeEmptyList
	ld hl, wBoxCount
	call InitializeEmptyList
	ld hl, wNumBagItems
	call InitializeEmptyList
	ld hl, wNumBoxItems
	call InitializeEmptyList

DEF START_MONEY EQU $5000
	ld hl, wPlayerMoney + 1
	ld a, HIGH(START_MONEY)
	ld [hld], a
	xor a ; LOW(START_MONEY)
	ld [hli], a
	inc hl
	ld [hl], a

	ld [wMonDataLocation], a

	ld hl, wObtainedBadges
	ld [hli], a
	assert wObtainedBadges + 1 == wUnusedObtainedBadges
	ld [hl], a

	ld hl, wPlayerCoins
	ld [hli], a
	ld [hl], a

	ld hl, wGameProgressFlags
	ld bc, wGameProgressFlagsEnd - wGameProgressFlags
	call FillMemory ; clear all game progress flags

	jp InitializeMissableObjectsFlags

InitializeEmptyList:
	xor a ; count
	ld [hli], a
	dec a ; terminator
	ld [hl], a
	ret
