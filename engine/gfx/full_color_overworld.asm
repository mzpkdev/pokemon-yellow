; Optional daytime per-tile colors for CGB overworld maps.
; This intentionally does not participate in battle or menu palette systems.

DEF FULL_COLOR_TILESET_SIZE EQU $60

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
	ld [de], a
	inc e
	dec c
	jr nz, .column
	ld a, BG_MAP_WIDTH - SCREEN_WIDTH
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
	pop af
	dec a
	jr nz, .row
	xor a
	ldh [rVBK], a
	ret

ApplyFullColorOverworldPalettes::
	ldh a, [hGBC]
	and a
	ret z
	ld a, [wDefaultPaletteCommand]
	cp SET_PAL_OVERWORLD
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
	ld a, [wDefaultPaletteCommand]
	cp SET_PAL_OVERWORLD
	jp nz, .done
	ld a, [wIsInBattle]
	and a
	jp nz, .done
	call GetFullColorAttributeTableHigh
	ld a, 1
	ldh [rVBK], a
	ldh a, [hRedrawRowOrColumnMode]
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

GetFullColorAttributeTableHigh:
	ld a, [wCurMapTileset]
	ld b, HIGH(FullColorIndoorAttributes)
	cp CAVERN
	jr nz, .notCave
	ld b, HIGH(FullColorCaveAttributes)
	ret
.notCave
	ld b, HIGH(FullColorOutdoorAttributes)
	cp OVERWORLD
	ret z
	ld b, HIGH(FullColorForestAttributes)
	cp FOREST
	ret z
	ld b, HIGH(FullColorOutdoorAttributes)
	cp PLATEAU
	ret z
	ld b, HIGH(FullColorIndoorAttributes)
	ret

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
	db 0,5,5,1,5,6,6,6, 6,6,4,4,4,0,5,0
	db 0,5,6,5,3,6,6,6, 6,6,0,5,5,2,5,0
	db 0,0,0,0,5,6,6,5, 6,6,0,0,2,2,2,0
	db 5,0,5,5,5,5,5,5, 6,0,0,0,5,2,2,0
	db 2,2,0,0,0,0,0,0, 5,5,0,5,6,6,0,0
	db 2,2,2,6,5,5,0,0, 5,5,6,5,6,6,7,7
	ds $100 - FULL_COLOR_TILESET_SIZE

FullColorIndoorAttributes:
	db 0,1,1,0,0,5,5,5, 5,5,5,5,5,5,5,0
	db 5,5,5,1,1,5,5,0, 0,0,0,5,5,5,5,0
	db 0,5,5,1,1,0,2,0, 0,0,0,5,5,0,0,0
	db 0,1,1,1,0,0,2,0, 1,1,0,5,5,5,5,5
	db 5,1,1,1,1,0,1,1, 5,5,5,5,5,5,5,5
	db 0,5,5,1,1,1,1,0, 5,0,0,5,5,5,7,7
	ds $100 - FULL_COLOR_TILESET_SIZE

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
