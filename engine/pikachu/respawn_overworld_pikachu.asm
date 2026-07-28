RespawnOverworldPikachu:
	callfar CanStarterCompanionFollow
	ret nc
	ld a, $3
	ld [wPikachuSpawnState], a
	ret

RefreshStarterCompanionAfterEvolution:
	callfar IsThisPartymonStarterCompanion_Party
	ret nc
	callfar CanStarterCompanionFollow
	jr c, RespawnOverworldPikachu
	call DisablePikachuFollowingPlayer
	call DisablePikachuOverworldSpriteDrawing
	xor a
	ld [wPikachuSpawnState], a
	ld [wPikachuCompanionQueuedReaction], a
	ld [wPikachuCompanionIdleCounter], a
	farcall ClearPikachuFollowCommandBuffer
	ld a, [wEvolutionOccurred]
	and a
	ret z
	ld hl, StarterRaichuReturnedText
	rst _PrintText
	ret

StarterRaichuReturnedText:
	text_far _StarterRaichuReturnedText
	text_end
