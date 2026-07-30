	db DEX_PICHU ; pokedex id

	db  20,  40,  15,  60,  35
	;   hp  atk  def  spd  spc

	db ELECTRIC, ELECTRIC ; type
	db 190 ; catch rate
	db 42 ; base exp

	INCBIN "gfx/pokemon/front/pikachu.pic", 0, 1
	dw PikachuPicFront, PikachuPicBack

	db THUNDERSHOCK, CHARM, NO_MOVE, NO_MOVE
	db GROWTH_MEDIUM_FAST

	tmhm MEGA_PUNCH, MEGA_KICK, TOXIC, BODY_SLAM, TAKE_DOWN, DOUBLE_EDGE, \
	     PAY_DAY, SUBMISSION, SEISMIC_TOSS, RAGE, THUNDERBOLT, THUNDER, \
	     MIMIC, DOUBLE_TEAM, REFLECT, BIDE, SWIFT, SKULL_BASH, REST, \
	     THUNDER_WAVE, SUBSTITUTE, CUT, FLY, SURF, STRENGTH, FLASH

	db BANK(PikachuPicFront)
