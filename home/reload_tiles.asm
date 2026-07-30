; reloads text box tile patterns, current map view, and tileset tile patterns
ReloadMapData::
	ldh a, [hLoadedROMBank]
	push af
	ld a, [wCurMap]
	call SwitchToMapRomBank
	call DisableLCD
	call LoadTextBoxTilePatterns
	call LoadCurrentMapView
	call LoadTilesetTilePatternData
	call EnableLCD
	ldh a, [hGBC]
	and a
	jr z, .palettesDone
	ld a, [wOptions2]
	and %1100
	cp 1 << BIT_FULL_COLOR_OVERWORLD
	jr nz, .palettesDone
	ld b, SET_PAL_OVERWORLD
	call RunPaletteCommand
	ld de, vBGMap0
	farcall CopyFullColorMapViewAttributes
.palettesDone
	pop af
	call BankswitchCommon
	ret

; reloads tileset tile patterns
ReloadTilesetTilePatterns::
	ldh a, [hLoadedROMBank]
	push af
	ld a, [wCurMap]
	call SwitchToMapRomBank
	call DisableLCD
	call LoadTilesetTilePatternData
	call EnableLCD
	pop af
	call BankswitchCommon
	ret

; shows the town map and lets the player choose a destination to fly to
ChooseFlyDestination::
	ld hl, wStatusFlags4
	res BIT_NO_BATTLES, [hl]
	farjp LoadTownMap_Fly
