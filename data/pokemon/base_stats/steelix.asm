	db DEX_STEELIX ; pokedex id

	db  75,  85, 200,  30,  55
	;   hp  atk  def  spd  spc

	db GROUND, ROCK ; adapted type
	db 25 ; catch rate
	db 196 ; base exp

	; Use Onix's graphics until Steelix's sprites are integrated.
	INCBIN "gfx/pokemon/front/onix.pic", 0, 1
	dw OnixPicFront, OnixPicBack

	db TACKLE, SCREECH, NO_MOVE, NO_MOVE
	db GROWTH_MEDIUM_FAST

	tmhm TOXIC, BODY_SLAM, TAKE_DOWN, DOUBLE_EDGE, HYPER_BEAM, RAGE, \
	     EARTHQUAKE, FISSURE, DIG, MIMIC, DOUBLE_TEAM, BIDE, SELFDESTRUCT, \
	     SKULL_BASH, REST, EXPLOSION, ROCK_SLIDE, SUBSTITUTE, STRENGTH

	db BANK(OnixPicFront)
