; Optional daytime per-tile colors for CGB overworld maps.
; This intentionally does not participate in battle or menu palette systems.

DEF FULL_COLOR_TILESET_SIZE EQU $60

LoadFullColorTileAttributes::
	ldh a, [hGBC]
	and a
	ret z
	ld a, [wOptions2]
	bit BIT_FULL_COLOR_OVERWORLD, a
	jr nz, .enabled
	ld a, 2
	ldh [rSVBK], a
	xor a
	ld [wFullColorOverworldActive], a
	ldh [rSVBK], a
	ret

.enabled
	ld a, 2
	ldh [rSVBK], a
	xor a
	ld [wFullColorOverworldActive], a
	ldh [rSVBK], a
	ld a, [wCurMapTileset]
	cp NUM_TILESETS
	ret nc
	ld c, a
	ld b, 0
	ld hl, FullColorTileAttributePointers
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld e, a
	ld d, [hl]

	ld a, 2
	ldh [rSVBK], a
	ld hl, wFullColorTileAttributes
	ld bc, $100
	ld a, 7
	call FillMemory
	ld h, d
	ld l, e
	ld de, wFullColorTileAttributes
	ld bc, FULL_COLOR_TILESET_SIZE
	rst _CopyData
	ld a, 1
	ld [wFullColorOverworldActive], a
	xor a
	ldh [rSVBK], a
	ret

ApplyFullColorOverworldPalettes::
	ldh a, [hGBC]
	and a
	ret z
	ld a, [wDefaultPaletteCommand]
	cp SET_PAL_OVERWORLD
	jr z, .checkEnabled
	ld a, 2
	ldh [rSVBK], a
	xor a
	ld [wFullColorOverworldActive], a
	ldh [rSVBK], a
	ret

.checkEnabled
	ld a, [wOptions2]
	bit BIT_FULL_COLOR_OVERWORLD, a
	ret z
	ld a, [wCurMapTileset]
	ld hl, FullColorIndoorPalettes
	cp OVERWORLD
	jr z, .outdoor
	cp FOREST
	jr z, .outdoor
	cp PLATEAU
	jr nz, .load
.outdoor
	ld hl, FullColorOutdoorPalettes
.load
	ld a, $80
	ldh [rBGPI], a
	ld c, 8 * PALETTE_SIZE
.loop
	ldh a, [rSTAT]
	and %10
	jr nz, .loop
	ld a, [hli]
	ldh [rBGPD], a
	dec c
	jr nz, .loop
	ret

FullColorTileAttributePointers:
	table_width 2, FullColorTileAttributePointers
	dw FullColorOutdoorAttributes ; OVERWORLD
	dw FullColorIndoorAttributes  ; REDS_HOUSE_1
	dw FullColorIndoorAttributes  ; MART
	dw FullColorForestAttributes  ; FOREST
	dw FullColorIndoorAttributes  ; REDS_HOUSE_2
	dw FullColorIndoorAttributes  ; DOJO
	dw FullColorIndoorAttributes  ; POKECENTER
	dw FullColorIndoorAttributes  ; GYM
	dw FullColorIndoorAttributes  ; HOUSE
	dw FullColorIndoorAttributes  ; FOREST_GATE
	dw FullColorIndoorAttributes  ; MUSEUM
	dw FullColorIndoorAttributes  ; UNDERGROUND
	dw FullColorIndoorAttributes  ; GATE
	dw FullColorIndoorAttributes  ; SHIP
	dw FullColorIndoorAttributes  ; SHIP_PORT
	dw FullColorIndoorAttributes  ; CEMETERY
	dw FullColorIndoorAttributes  ; INTERIOR
	dw FullColorCaveAttributes    ; CAVERN
	dw FullColorIndoorAttributes  ; LOBBY
	dw FullColorIndoorAttributes  ; MANSION
	dw FullColorIndoorAttributes  ; LAB
	dw FullColorIndoorAttributes  ; CLUB
	dw FullColorIndoorAttributes  ; FACILITY
	dw FullColorOutdoorAttributes ; PLATEAU
	dw FullColorIndoorAttributes  ; BEACH_HOUSE (not Celebrations Safari)
	assert_table_length NUM_TILESETS

; Palette numbers: gray, red, green, water, yellow, brown, accent, text.
FullColorOutdoorAttributes:
	db 0,5,5,1,5,6,6,6, 6,6,4,4,4,0,5,0
	db 0,5,6,5,3,6,6,6, 6,6,0,5,5,2,5,0
	db 0,0,0,0,5,6,6,5, 6,6,0,0,2,2,2,0
	db 5,0,5,5,5,5,5,5, 6,0,0,0,5,2,2,0
	db 2,2,0,0,0,0,0,0, 5,5,0,5,6,6,0,0
	db 2,2,2,6,5,5,0,0, 5,5,6,5,6,6,7,7

FullColorForestAttributes:
	db 0,5,5,1,5,6,6,6, 6,6,4,4,4,0,5,0
	db 0,5,6,5,3,6,6,6, 6,6,0,5,5,2,5,0
	db 0,0,0,0,5,6,6,5, 6,6,0,0,2,2,2,0
	db 5,0,5,5,5,5,5,5, 6,0,0,0,5,2,2,0
	db 2,2,0,0,0,0,0,0, 5,5,0,5,6,6,0,0
	db 2,2,2,6,5,5,0,0, 5,5,6,5,6,6,7,7

FullColorIndoorAttributes:
	db 0,1,1,0,0,5,5,5, 5,5,5,5,5,5,5,0
	db 5,5,5,1,1,5,5,0, 0,0,0,5,5,5,5,0
	db 0,5,5,1,1,0,2,0, 0,0,0,5,5,0,0,0
	db 0,1,1,1,0,0,2,0, 1,1,0,5,5,5,5,5
	db 5,1,1,1,1,0,1,1, 5,5,5,5,5,5,5,5
	db 0,5,5,1,1,1,1,0, 5,0,0,5,5,5,7,7

FullColorCaveAttributes:
	db 0,5,5,0,0,5,5,5, 5,5,5,5,5,5,5,0
	db 0,0,5,5,0,0,0,0, 5,5,0,0,3,3,0,0
	db 0,5,5,5,5,0,0,0, 0,0,0,5,5,5,5,0
	db 5,5,0,0,0,0,5,5, 0,0,0,0,5,5,5,5
	db 0,0,0,5,5,5,0,0, 5,5,5,5,0,0,0,0
	db 5,5,5,0,0,0,5,5, 5,5,0,0,0,0,7,7

FullColorOutdoorPalettes:
	RGB 27,31,27, 21,21,21, 13,13,13, 7,7,7
	RGB 27,31,27, 31,19,24, 30,10,6, 7,7,7
	RGB 22,31,10, 12,25,1, 5,14,0, 7,7,7
	RGB 23,23,31, 18,19,31, 13,12,31, 7,7,7
	RGB 27,31,27, 31,31,7, 31,16,1, 7,7,7
	RGB 27,31,27, 24,18,7, 20,15,3, 7,7,7
	RGB 27,31,27, 20,31,14, 11,23,5, 7,7,7
	RGB 31,31,31, 31,31,31, 31,31,31, 0,0,0

FullColorIndoorPalettes:
	RGB 30,28,26, 19,19,19, 13,13,13, 7,7,7
	RGB 30,28,26, 31,19,24, 30,10,6, 7,7,7
	RGB 30,28,26, 15,20,1, 9,13,0, 7,7,7
	RGB 30,28,26, 15,16,31, 9,9,31, 7,7,7
	RGB 30,28,26, 31,31,7, 31,16,1, 7,7,7
	RGB 30,28,26, 21,17,7, 16,13,3, 7,7,7
	RGB 30,28,26, 17,19,31, 14,16,31, 7,7,7
	RGB 31,31,31, 31,31,31, 31,31,31, 0,0,0
