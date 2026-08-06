; Optional daytime per-tile colors for CGB overworld maps.
; This intentionally does not participate in battle or menu palette systems.

DEF FULL_COLOR_TILESET_SIZE EQU $60

DEF PAL_BG_GRAY   EQU 0
DEF PAL_BG_RED    EQU 1
DEF PAL_BG_GREEN  EQU 2
DEF PAL_BG_WATER  EQU 3
DEF PAL_BG_YELLOW EQU 4
DEF PAL_BG_BROWN  EQU 5
DEF PAL_BG_ROOF   EQU 6
DEF PAL_BG_TEXT   EQU 7

MACRO tilepal
	REPT _NARG +- 1
		db PAL_BG_\2
		SHIFT
	ENDR
ENDM

CopyFullColorMapViewAttributes::
	ldh a, [hGBC]
	and a
	ret z
	ld a, [wOptions2]
	and %1100
	cp 1 << BIT_FULL_COLOR_OVERWORLD
	ret nz
	call GetFullColorAttributeTableHigh
	ld a, 1
	ldh [rVBK], a
	ld hl, wTileMap
	ld a, SCREEN_HEIGHT
.row
	push af
	push de
	ld c, SCREEN_WIDTH
.column
	ld a, [hli]
	cp FULL_COLOR_TILESET_SIZE
	jr c, .assigned
	ld a, 7
	jr .write
.assigned
	push bc
	ld c, a
	ld a, [bc]
	and $7
	pop bc
.write
	call WaitForFullColorVRAM
	ld [de], a
	push bc
	ld a, e
	inc a
	and $1f
	ld c, a
	ld a, e
	and $e0
	or c
	ld e, a
	pop bc
	dec c
	jr nz, .column
	pop de
	ld a, BG_MAP_WIDTH
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
	ld a, d
	and $3
	or $98
	ld d, a
	pop af
	dec a
	jr nz, .row
	xor a
	ldh [rVBK], a
	ret

CopyFullColorDialogueAttributes::
	ldh a, [hGBC]
	and a
	ret z
	ld a, [wOptions2]
	and %1100
	cp 1 << BIT_FULL_COLOR_OVERWORLD
	ret nz
	ld a, [wLastPaletteCommand]
	cp SET_PAL_OVERWORLD
	ret nz
	ld a, [wIsInBattle]
	and a
	ret nz

	ld a, 1
	ldh [rVBK], a
	ld a, [wMapViewVRAMPointer]
	ld l, a
	ld a, [wMapViewVRAMPointer + 1]
	ld h, a
	ld de, vBGMap1
	ld a, SCREEN_HEIGHT - 6
.terrainRow
	push af
	push hl
	ld c, SCREEN_WIDTH
.terrainColumn
	call WaitForFullColorVRAM
	ld a, [hl]
	call WaitForFullColorVRAM
	ld [de], a
	inc de
	ld a, l
	inc a
	and $1f
	ld b, a
	ld a, l
	and $e0
	or b
	ld l, a
	dec c
	jr nz, .terrainColumn
	pop hl
	ld a, BG_MAP_WIDTH
	add l
	ld l, a
	jr nc, .sourceRowReady
	inc h
.sourceRowReady
	ld a, h
	and $3
	or $98
	ld h, a
	ld a, BG_MAP_WIDTH - SCREEN_WIDTH
	add e
	ld e, a
	jr nc, .terrainRowReady
	inc d
.terrainRowReady
	pop af
	dec a
	jr nz, .terrainRow

	ld a, 6
.textRow
	push af
	ld c, SCREEN_WIDTH
.textColumn
	ld a, 7
	call WaitForFullColorVRAM
	ld [de], a
	inc de
	dec c
	jr nz, .textColumn
	ld a, BG_MAP_WIDTH - SCREEN_WIDTH
	add e
	ld e, a
	jr nc, .textRowReady
	inc d
.textRowReady
	pop af
	dec a
	jr nz, .textRow

	xor a
	ldh [rVBK], a
	ret

ApplyFullColorOverworldPalettes::
	ldh a, [hGBC]
	and a
	ret z
	ld a, [wLastPaletteCommand]
	cp SET_PAL_OVERWORLD
	ret nz
	ld a, [wIsInBattle]
	and a
	ret nz

	ld a, [wOptions2]
	and %1100
	cp 1 << BIT_FULL_COLOR_OVERWORLD
	ret nz
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

DrawFullColorRowOrColumn::
	push af
	ldh a, [hGBC]
	and a
	jp z, .done
	ld a, [wOptions2]
	and %1100
	cp 1 << BIT_FULL_COLOR_OVERWORLD
	jp nz, .done
	ld a, [wLastPaletteCommand]
	cp SET_PAL_OVERWORLD
	jp nz, .done
	ld a, [wIsInBattle]
	and a
	jp nz, .done
	call GetFullColorAttributeTableHigh
	ld a, 1
	ldh [rVBK], a
	ld a, c
	dec a
	jr nz, .row

.column
	ld hl, wRedrawRowOrColumnSrcTiles
	ldh a, [hRedrawRowOrColumnDest]
	ld e, a
	ldh a, [hRedrawRowOrColumnDest + 1]
	ld d, a
	ld a, SCREEN_HEIGHT
.columnLoop
	push af
	REPT 2
		ld a, [hli]
		cp FULL_COLOR_TILESET_SIZE
		jr c, .columnAssigned\@
		ld a, 7
		jr .columnWrite\@
.columnAssigned\@
		ld c, a
		ld a, [bc]
		and $7
.columnWrite\@
		call WaitForFullColorVRAM
		ld [de], a
		inc de
	ENDR
	ld a, BG_MAP_WIDTH - 2
	add e
	ld e, a
	jr nc, .columnNoCarry
	inc d
.columnNoCarry
	ld a, d
	and $3
	or $98
	ld d, a
	pop af
	dec a
	jr nz, .columnLoop
	jr .restoreVRAMBank

.row
	ld hl, wRedrawRowOrColumnSrcTiles
	ldh a, [hRedrawRowOrColumnDest]
	ld e, a
	ldh a, [hRedrawRowOrColumnDest + 1]
	ld d, a
	push de
	call .drawRowHalf
	pop de
	ld a, BG_MAP_WIDTH
	add e
	ld e, a
	call .drawRowHalf
	jr .restoreVRAMBank
.drawRowHalf
	ld a, SCREEN_WIDTH
.rowLoop
	push af
	ld a, [hli]
	cp FULL_COLOR_TILESET_SIZE
	jr c, .rowAssigned
	ld a, 7
	jr .rowWrite
.rowAssigned
	ld c, a
	ld a, [bc]
	and $7
.rowWrite
	call WaitForFullColorVRAM
	ld [de], a
	ld a, e
	inc a
	and $1f
	ld c, a
	ld a, e
	and $e0
	or c
	ld e, a
	pop af
	dec a
	jr nz, .rowLoop
	ret

.restoreVRAMBank
	xor a
	ldh [rVBK], a
.done
	pop af
	ret

WaitForFullColorVRAM:
	push af
.wait
	ldh a, [rSTAT]
	and %10
	jr nz, .wait
	pop af
	ret

GetFullColorAttributeTableHigh:
	ld a, [wCurMapTileset]
	cp NUM_TILESETS
	jr c, .known
	ld a, BEACH_HOUSE
.known
	ld hl, FullColorAttributeTableHighs
	add l
	ld l, a
	jr nc, .noCarry
	inc h
.noCarry
	ld b, [hl]
	ret

FullColorAttributeTableHighs:
	db HIGH(FullColorOutdoorAttributes)  ; OVERWORLD
	db HIGH(FullColorRedsHouseAttributes)
	db HIGH(FullColorPokecenterAttributesExact)
	db HIGH(FullColorForestAttributes)
	db HIGH(FullColorRedsHouseAttributes)
	db HIGH(FullColorGymAttributes)
	db HIGH(FullColorPokecenterAttributesExact)
	db HIGH(FullColorGymAttributes)
	db HIGH(FullColorHouseAttributes)
	db HIGH(FullColorGateAttributes)
	db HIGH(FullColorGateAttributes)
	db HIGH(FullColorUndergroundAttributes)
	db HIGH(FullColorGateAttributes)
	db HIGH(FullColorShipAttributes)
	db HIGH(FullColorShipPortAttributes)
	db HIGH(FullColorCemeteryAttributes)
	db HIGH(FullColorInteriorAttributes)
	db HIGH(FullColorCaveAttributes)
	db HIGH(FullColorLobbyAttributes)
	db HIGH(FullColorMansionAttributes)
	db HIGH(FullColorLabAttributes)
	db HIGH(FullColorClubAttributes)
	db HIGH(FullColorFacilityAttributes)
	db HIGH(FullColorPlateauAttributes)
	db HIGH(FullColorIndoorAttributes) ; BEACH_HOUSE safe fallback

; Palette numbers: gray, red, green, water, yellow, brown, accent, text.
ALIGN 8
FullColorOutdoorAttributes:
	db 0,5,5,1,5,6,6,6, 6,6,4,4,4,0,5,0
	db 0,5,6,5,3,6,6,6, 6,6,0,5,5,2,5,0
	db 0,0,0,0,5,6,6,5, 6,6,0,0,2,2,2,0
	db 5,0,5,5,5,5,5,5, 6,0,0,0,5,2,2,0
	db 2,2,0,0,0,0,0,0, 5,5,0,5,6,6,0,0
	db 2,2,2,6,5,5,0,0, 5,5,6,5,6,6,7,7
	ds $100 - FULL_COLOR_TILESET_SIZE

FullColorForestAttributes:
	db 2,4,5,5,6,6,6,6, 5,5,5,5,5,2,5,5
	db 0,0,5,5,3,6,6,6, 5,5,5,5,5,5,5,5
	db 2,5,5,6,6,6,6,6, 5,5,5,5,5,5,5,5
	db 2,5,5,0,2,5,5,1, 5,2,5,5,5,5,5,5
	db 5,5,5,5,0,0,0,0, 5,5,5,5,5,5,5,2
	db 2,2,2,2,2,2,2,2, 2,2,2,2,2,2,7,7
	ds $100 - FULL_COLOR_TILESET_SIZE

FullColorIndoorAttributes:
	db 0,1,1,0,0,5,5,5, 5,5,5,5,5,5,5,0
	db 5,5,5,1,1,5,5,0, 0,0,0,5,5,5,5,0
	db 0,5,5,1,1,0,2,0, 0,0,0,5,5,0,0,0
	db 0,1,1,1,0,0,2,0, 1,1,0,5,5,5,5,5
	db 5,1,1,1,1,0,1,1, 5,5,5,5,5,5,5,5
	db 0,5,5,1,1,1,1,0, 5,0,0,5,5,5,7,7
	ds $100 - FULL_COLOR_TILESET_SIZE

FullColorPokecenterAttributes:
	db 0,0,1,1,3,3,0,0, 0,0,0,0,1,0,0,0
	db 0,0,1,1,3,3,0,1, 3,3,0,0,1,1,0,0
	db 2,2,5,5,1,4,1,1, 3,0,1,1,6,6,6,6
	db 2,2,5,5,1,4,0,1, 0,0,0,0,0,0,6,6
	db 0,0,0,0,0,0,0,0, 0,0,0,0,6,6,4,4
	db 0,0,0,0,0,0,0,0, 0,3,0,0,0,0,7,7
	ds $100 - FULL_COLOR_TILESET_SIZE

FullColorCaveAttributes:
	INCLUDE "engine/gfx/full_color_tilesets/cavern.asm"
	ds $100 - (@ - FullColorCaveAttributes)

MACRO full_color_attribute_table
	ALIGN 8
\1:
	INCLUDE \2
	ds $100 - (@ - \1)
ENDM

	full_color_attribute_table FullColorRedsHouseAttributes, "engine/gfx/full_color_tilesets/reds_house.asm"
	full_color_attribute_table FullColorPokecenterAttributesExact, "engine/gfx/full_color_tilesets/pokecenter.asm"
	full_color_attribute_table FullColorGymAttributes, "engine/gfx/full_color_tilesets/gym.asm"
	full_color_attribute_table FullColorHouseAttributes, "engine/gfx/full_color_tilesets/house.asm"
	full_color_attribute_table FullColorGateAttributes, "engine/gfx/full_color_tilesets/gate.asm"
	full_color_attribute_table FullColorUndergroundAttributes, "engine/gfx/full_color_tilesets/underground.asm"
	full_color_attribute_table FullColorShipAttributes, "engine/gfx/full_color_tilesets/ship.asm"
	full_color_attribute_table FullColorShipPortAttributes, "engine/gfx/full_color_tilesets/ship_port.asm"
	full_color_attribute_table FullColorCemeteryAttributes, "engine/gfx/full_color_tilesets/cemetery.asm"
	full_color_attribute_table FullColorInteriorAttributes, "engine/gfx/full_color_tilesets/interior.asm"
	full_color_attribute_table FullColorLobbyAttributes, "engine/gfx/full_color_tilesets/lobby.asm"
	full_color_attribute_table FullColorMansionAttributes, "engine/gfx/full_color_tilesets/mansion.asm"
	full_color_attribute_table FullColorLabAttributes, "engine/gfx/full_color_tilesets/lab.asm"
	full_color_attribute_table FullColorClubAttributes, "engine/gfx/full_color_tilesets/club.asm"
	full_color_attribute_table FullColorFacilityAttributes, "engine/gfx/full_color_tilesets/facility.asm"
	full_color_attribute_table FullColorPlateauAttributes, "engine/gfx/full_color_tilesets/plateau.asm"

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
