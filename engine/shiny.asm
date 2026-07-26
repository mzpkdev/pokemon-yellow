DEF SHINY_ATK_MASK EQU %0010
DEF SHINY_DEF_DV EQU 10
DEF SHINY_SPD_DV EQU 10
DEF SHINY_SPC_DV EQU 10

SECTION "Shiny Engine", ROMX

GeneratePerfectShinyDVs:
; Generate DVs with a 1 / 2 chance of being shiny for testing.
; Return Attack/Defense in d and Speed/Special in e.
; The far-call trampoline preserves de but clobbers af and bc on return.
;
; Roll shininess separately from the DVs so the eight DV combinations that
; are naturally shiny do not increase the configured rate.

	call Random
	and 1
	jr z, .shiny

.not_shiny
	call Random
	ld d, a
	call Random
	ld e, a

	; Attack can be 2, 3, 6, 7, 10, 11, 14, or 15.
	cp (SHINY_SPD_DV << 4) | SHINY_SPC_DV
	jr nz, .done
	ld a, d
	and $f
	cp SHINY_DEF_DV
	jr nz, .done
	ld a, d
	and SHINY_ATK_MASK << 4
	jr nz, .not_shiny

.done
	ret

.shiny
	ld d, (SHINY_DEF_DV << 4) | SHINY_DEF_DV
	ld e, (SHINY_SPD_DV << 4) | SHINY_SPC_DV
	ret

IsMonShiny:
; Check whether the DVs at de satisfy the Generation II shiny condition.
; Return nz if shiny and z if not shiny.

	ld h, d
	ld l, e

; Attack
	ld a, [hl]
	and SHINY_ATK_MASK << 4
	jr z, .not_shiny

; Defense
	ld a, [hli]
	and $f
	cp SHINY_DEF_DV
	jr nz, .not_shiny

; Speed and Special
	ld a, [hl]
	cp (SHINY_SPD_DV << 4) | SHINY_SPC_DV
	jr nz, .not_shiny
	and a
	ret

.not_shiny
	xor a
	ret

SetShinyPaletteFlag:
; Set palette-selection bit 0 according to the DVs at de.
	ld hl, wShinyMonFlag
	res 0, [hl]
	call IsMonShiny
	ret z
	ld hl, wShinyMonFlag
	set 0, [hl]
	ret

SetShinyPaletteFlagFromBoolean:
; Set palette-selection bit 0 according to a (zero = normal).
	ld hl, wShinyMonFlag
	res 0, [hl]
	and a
	ret z
	set 0, [hl]
	ret

PlayEnemyShinySparkle:
	ld de, wEnemyMonDVs
	call IsMonShiny
	ret z
	ld hl, wShinyMonFlag
	set 1, [hl]
	jr PlayShinySparkleAnimation

PlayPlayerShinySparkle:
	ld de, wBattleMonDVs
	call IsMonShiny
	ret z
	ld hl, wShinyMonFlag
	res 1, [hl]

PlayShinySparkleAnimation:
	ldh a, [rBGP]
	push af
	ld a, %00011011
	ldh [rBGP], a
	ld c, 4
	rst _DelayFrames
	pop af
	ldh [rBGP], a

	ld b, 12
.frame_loop
	dec b
	jr z, .finish
	ld c, (ShinySparkleCoordsEnd - ShinySparkleCoords) / 3 + 1
	ld a, [wShinyMonFlag]
	bit 1, a
	ld de, ShinySparkleCoords
	jr z, .got_coords
	ld de, EnemyShinySparkleCoords
.got_coords
	ld hl, wShadowOAM
.sparkle_loop
	dec c
	jr z, .delay
	ld a, [de]
	cp b
	jr c, .inactive
	sub b
	cp 4
	jr nc, .inactive
	push bc
	ld b, a
	inc de
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hli], a
	inc de
	ld a, $c9 + 3
	sub b
	ld [hli], a
	xor a
	ld [hli], a
	pop bc
	jr .sparkle_loop

.inactive
	inc de
	inc de
	inc de
	xor a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	jr .sparkle_loop

.delay
	push bc
	ld c, 2
	rst _DelayFrames
	ld a, SFX_PRESS_AB
	rst _PlaySound
	pop bc
	jr .frame_loop

.finish
	xor a
	ld hl, wShadowOAM
	ld bc, 4 * ((ShinySparkleCoordsEnd - ShinySparkleCoords) / 3)
	jp FillMemory

ShinySparkleCoords:
	db $0b, 70, 48
	db $0a, 75, 60
	db $09, 86, 64
	db $08, 99, 60
	db $07, 103, 48
	db $06, 99, 36
	db $05, 86, 30
	db $04, 75, 36
ShinySparkleCoordsEnd:

EnemyShinySparkleCoords:
	db $0b, 70 - 48, 48 + 80
	db $0a, 75 - 48, 60 + 80
	db $09, 86 - 48, 64 + 80
	db $08, 99 - 48, 60 + 80
	db $07, 103 - 48, 48 + 80
	db $06, 99 - 48, 36 + 80
	db $05, 86 - 48, 30 + 80
	db $04, 75 - 48, 36 + 80
EnemyShinySparkleCoordsEnd:
