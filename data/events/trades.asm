TradeMons:
; entries correspond to TRADE_FOR_* constants
	table_width 3 + NAME_LENGTH, TradeMons
	; give mon, get mon, dialog id, nickname
	; Dialog sets only select the trader's tone; trade evolution is
	; determined separately by the received species.
	db MR_MIME,    HAUNTER,   TRADE_DIALOGSET_CASUAL,    "SPOOKY@@@@@"
	db BUTTERFREE, SCYTHER,   TRADE_DIALOGSET_CASUAL,    "SLASH@@@@@@"
	db VULPIX,     EEVEE,     TRADE_DIALOGSET_HAPPY,     "BUDDY@@@@@@"
	db MUK,        KANGASKHAN, TRADE_DIALOGSET_CASUAL,    "ROO@@@@@@@@"
	db BEEDRILL,   DRATINI,   TRADE_DIALOGSET_HAPPY,     "TWINKLE@@@@"
	db PONYTA,     TAUROS,    TRADE_DIALOGSET_CASUAL,    "BULLSEYE@@@"
	db ABRA,       MR_MIME,   TRADE_DIALOGSET_CASUAL,    "MIMEY@@@@@@"
	db DITTO,      CHANSEY,   TRADE_DIALOGSET_EVOLUTION, "LUCKY@@@@@@"
	db LICKITUNG,  RHYDON,    TRADE_DIALOGSET_HAPPY,     "TANK@@@@@@@"
	db GRAVELER,   ELECTABUZZ, TRADE_DIALOGSET_HAPPY,     "VOLT@@@@@@@"
	db NO_MON,     NO_MON,   TRADE_DIALOGSET_SELF,      "Unseen@@@@@"
	assert_table_length NUM_NPC_TRADES
