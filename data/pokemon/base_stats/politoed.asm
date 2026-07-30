	db DEX_POLITOED ; pokedex id

	db  90,  75,  75,  70,  90
	;   hp  atk  def  spd  spc

	db WATER, WATER ; type
	db 45 ; catch rate
	db 185 ; base exp

	INCBIN "gfx/pokemon/front/politoed.pic", 0, 1
	dw PolitoedPicFront, PolitoedPicBack

	db WATER_GUN, HYPNOSIS, DOUBLESLAP, NO_MOVE
	db GROWTH_MEDIUM_SLOW

	tmhm MEGA_PUNCH, MEGA_KICK, TOXIC, BODY_SLAM, TAKE_DOWN, DOUBLE_EDGE, \
	     BUBBLEBEAM, WATER_GUN, ICE_BEAM, BLIZZARD, HYPER_BEAM, COUNTER, \
	     SEISMIC_TOSS, RAGE, PSYCHIC_M, MIMIC, DOUBLE_TEAM, BIDE, \
	     METRONOME, SKULL_BASH, REST, PSYWAVE, SUBSTITUTE, SURF, STRENGTH

	db BANK(PolitoedPicFront)
