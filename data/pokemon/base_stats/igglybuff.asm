	db DEX_IGGLYBUFF ; pokedex id

	db  90,  30,  15,  15,  20
	;   hp  atk  def  spd  spc

	db NORMAL, NORMAL ; adapted type
	db 150 ; catch rate
	db 39 ; base exp

	INCBIN "gfx/pokemon/front/igglybuff.pic", 0, 1
	dw IgglybuffPicFront, IgglybuffPicBack

	db SING, CHARM, NO_MOVE, NO_MOVE
	db GROWTH_FAST

	tmhm MEGA_PUNCH, MEGA_KICK, TOXIC, BODY_SLAM, TAKE_DOWN, REST, \
	     DOUBLE_EDGE, BUBBLEBEAM, WATER_GUN, ICE_BEAM, BLIZZARD, SUBMISSION, \
	     COUNTER, SEISMIC_TOSS, RAGE, SOLARBEAM, THUNDERBOLT, THUNDER, \
	     PSYCHIC_M, TELEPORT, MIMIC, DOUBLE_TEAM, REFLECT, BIDE, FIRE_BLAST, \
	     SKULL_BASH, THUNDER_WAVE, PSYWAVE, TRI_ATTACK, SUBSTITUTE, STRENGTH, \
	     FLASH

	db BANK(IgglybuffPicFront)
