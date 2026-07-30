	db DEX_PORYGON2 ; pokedex id

	db  85,  80,  90,  60, 105
	;   hp  atk  def  spd  spc

	db NORMAL, NORMAL ; type
	db 45 ; catch rate
	db 180 ; base exp

	; Use Porygon's graphics until Porygon2's sprites are integrated.
	INCBIN "gfx/pokemon/front/porygon.pic", 0, 1
	dw PorygonPicFront, PorygonPicBack

	db TACKLE, CONVERSION, NO_MOVE, NO_MOVE
	db GROWTH_MEDIUM_FAST

	tmhm TOXIC, TAKE_DOWN, DOUBLE_EDGE, ICE_BEAM, BLIZZARD, HYPER_BEAM, RAGE, \
	     THUNDERBOLT, THUNDER, PSYCHIC_M, TELEPORT, MIMIC, DOUBLE_TEAM, \
	     REFLECT, BIDE, SWIFT, SKULL_BASH, REST, THUNDER_WAVE, PSYWAVE, \
	     TRI_ATTACK, SUBSTITUTE, FLASH

	db BANK(PorygonPicFront)
