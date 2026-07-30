	db DEX_KINGDRA ; pokedex id

	db  75,  95,  95,  85,  95
	;   hp  atk  def  spd  spc

	db WATER, DRAGON ; type
	db 45 ; catch rate
	db 207 ; base exp

	INCBIN "gfx/pokemon/front/kingdra.pic", 0, 1
	dw KingdraPicFront, KingdraPicBack

	db BUBBLE, SMOKESCREEN, LEER, WATER_GUN
	db GROWTH_MEDIUM_FAST

	tmhm TOXIC, TAKE_DOWN, DOUBLE_EDGE, BUBBLEBEAM, WATER_GUN, ICE_BEAM, \
	     BLIZZARD, HYPER_BEAM, RAGE, MIMIC, DOUBLE_TEAM, BIDE, SWIFT, \
	     SKULL_BASH, REST, SUBSTITUTE, SURF

	db BANK(KingdraPicFront)
