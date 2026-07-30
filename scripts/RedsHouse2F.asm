RedsHouse2F_Script:
	call EnableAutoTextBoxDrawing
	ld hl, RedsHouse2F_ScriptPointers
	ld a, 0
	call CallFunctionInTable
	ret

RedsHouse2F_ScriptPointers:
	def_script_pointers
	dw_const DoRet,                      SCRIPT_REDSHOUSE2F_DEFAULT
	dw_const DoRet,                      SCRIPT_REDSHOUSE2F_NOOP    

RedsHouse2FDefaultScript:
	CheckEvent EVENT_INFORMED_ABOUT_OPTIONS
	ret nz
; if we have not been told already, check if we are near the stairs
	ld hl, CoordsData_NearStairs
	call ArePlayerCoordsInArray ; sets carry if the coordinates are in the array, clears carry if not
	ret nc
; we are near the stairs
	ld a, TEXT_REDSHOUSE2F_OPTIONS
	ldh [hTextID], a
	call DisplayTextID
; boring technical stuff
	SetEvent EVENT_INFORMED_ABOUT_OPTIONS
	ret

CoordsData_NearStairs:
	dbmapcoord  6,  1
	dbmapcoord  7,  2
	db -1 ; end

RedsHouse2F_TextPointers:
	def_text_pointers
	dw_const RedsHouse2FOptionsText, TEXT_REDSHOUSE2F_OPTIONS


RedsHouse2FOptionsText:
	text_far _RedsHouse2FOptionsText
	text_end
