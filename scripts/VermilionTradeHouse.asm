VermilionTradeHouse_Script:
	jp EnableAutoTextBoxDrawing

VermilionTradeHouse_TextPointers:
	def_text_pointers
	dw_const VermilionTradeHouseGentlemanText, TEXT_VERMILIONTRADEHOUSE_GENTLEMAN
	dw_const VermilionTradeHouseLittleGirlText, TEXT_VERMILIONTRADEHOUSE_LITTLE_GIRL

VermilionTradeHouseGentlemanText:
	text_far TeachingHMsText
	text_end

VermilionTradeHouseLittleGirlText:
	text_asm
	ld a, TRADE_FOR_TWINKLE
	ld [wWhichTrade], a
	predef DoInGameTradeDialogue
	rst TextScriptEnd
