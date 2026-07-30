	db DEX_SCIZOR ; pokedex id

	db  70, 130, 100,  65,  55
	;   hp  atk  def  spd  spc

	db BUG, BUG ; adapted type
	db 25 ; catch rate
	db 200 ; base exp

	; Use Scyther's graphics until Scizor's sprites are integrated.
	INCBIN "gfx/pokemon/front/scyther.pic", 0, 1
	dw ScytherPicFront, ScytherPicBack

	db QUICK_ATTACK, LEER, NO_MOVE, NO_MOVE
	db GROWTH_MEDIUM_FAST

	tmhm SWORDS_DANCE, TOXIC, TAKE_DOWN, DOUBLE_EDGE, HYPER_BEAM, RAGE, \
	     MIMIC, DOUBLE_TEAM, BIDE, SWIFT, SKULL_BASH, REST, SUBSTITUTE, CUT

	db BANK(ScytherPicFront)
