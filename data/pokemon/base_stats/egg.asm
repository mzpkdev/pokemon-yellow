	db DEX_EGG ; pokedex id

	db  10,  10,  10,  10,  10
	;   hp  atk  def  spd  spc

	db NORMAL, NORMAL ; type
	db 0 ; catch rate
	db 0 ; base exp

	INCBIN "gfx/pokemon/front/egg.pic", 0, 1 ; sprite dimensions
	dw EggPicFront, EggPicBack

	db NO_MOVE, NO_MOVE, NO_MOVE, NO_MOVE ; level 1 learnset
	db GROWTH_MEDIUM_FAST ; growth rate

	; tm/hm learnset
	tmhm
	; end

	db BANK(EggPicFront)
