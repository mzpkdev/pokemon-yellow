DEF SHINY_ATK_MASK EQU %0010
DEF SHINY_DEF_DV EQU 10
DEF SHINY_SPD_DV EQU 10
DEF SHINY_SPC_DV EQU 10

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
