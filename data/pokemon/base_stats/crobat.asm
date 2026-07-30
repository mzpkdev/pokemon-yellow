	db DEX_CROBAT ; pokedex id

	db  85,  90,  80, 130,  80
	;   hp  atk  def  spd  spc

	db POISON, FLYING ; type
	db 90 ; catch rate
	db 204 ; base exp

	INCBIN "gfx/pokemon/front/golbat.pic", 0, 1
	dw GolbatPicFront, GolbatPicBack

	db LEECH_LIFE, SCREECH, BITE, WING_ATTACK
	db GROWTH_MEDIUM_FAST

	tmhm RAZOR_WIND, TOXIC, TAKE_DOWN, DOUBLE_EDGE, HYPER_BEAM, RAGE, \
	     MEGA_DRAIN, MIMIC, DOUBLE_TEAM, BIDE, SWIFT, REST, SUBSTITUTE, FLY

	db BANK(GolbatPicFront)
