; Project name	:	XTIDE Universal BIOS
; Description	:	Displays Boot Menu.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Displays Boot Menu and returns Drive or Function number.
;
; BootMenu_DisplayAndReturnSelection
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		DX:		Untranslated drive number to be used for booting
;	Corrupts registers:
;		All General Purpose Registers
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_DisplayAndReturnSelection:
	call	DriveXlate_Reset
	call	BootMenuPrint_TheBottomOfScreen
	call	BootMenu_Enter			; Get selected menuitem index to CX
	call	BootMenuPrint_ClearScreen
	cmp		cx, BYTE NO_ITEM_SELECTED
	je		SHORT BootMenu_DisplayAndReturnSelection	; Clear screen and display menu
	; Fall to BootMenu_GetDriveToDXforMenuitemInCX

;--------------------------------------------------------------------
; BootMenu_GetDriveToDXforMenuitemInCX
;	Parameters:
;		CX:		Index of menuitem selected from Boot Menu
;		DS:		RAMVARS segment
;	Returns:
;		DX:		Drive number to be used for booting
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_GetDriveToDXforMenuitemInCX:
	mov		dx, cx					; Copy menuitem index to DX
	call	FloppyDrive_GetCountToCX
	cmp		dx, cx					; Floppy drive?
	jb		SHORT .ReturnFloppyDriveInDX
	sub		dx, cx					; Remove floppy drives from index
	or		dl, 80h
.ReturnFloppyDriveInDX:
	ret


;--------------------------------------------------------------------
; Enters Boot Menu or submenu.
;
; BootMenu_Enter
;	Parameters:
;		Nothing
;	Returns:
;		CX:		Index of selected item or NO_ITEM_SELECTED
;	Corrupts registers:
;		AX, BX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_Enter:
	mov		bx, BootMenuEvent_Handler
	CALL_MENU_LIBRARY DisplayWithHandlerInBXandUserDataInDXAX
	xchg	cx, ax
	ret


;--------------------------------------------------------------------
; Returns number of menuitems in Boot Menu.
;
; BootMenu_GetMenuitemCountToAX
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		AX:		Number of boot menu items
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_GetMenuitemCountToAX:
	call	RamVars_GetHardDiskCountFromBDAtoCX
	xchg	ax, cx
	call	FloppyDrive_GetCountToCX
	add		ax, cx
	ret


;--------------------------------------------------------------------
; BootMenu_GetHeightToAHwithItemCountInAL
;	Parameters:
;		AL:		Number of menuitems
;	Returns:
;		AH:		Boot menu height
;	Corrupts registers:
;		AL, CX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_GetHeightToAHwithItemCountInAL:
	add		al, BOOT_MENU_HEIGHT_WITHOUT_ITEMS
	xchg	cx, ax
	CALL_DISPLAY_LIBRARY GetColumnsToALandRowsToAH
	sub		ah, MENU_SCREEN_BOTTOM_LINES*2	; Leave space for bottom info
	MIN_U	ah, cl
	ret


;--------------------------------------------------------------------
; BootMenu_GetMenuitemToAXforAsciiHotkeyInAL
;	Parameters:
;		AL:		ASCII hotkey
;	Returns:
;		AX:		Menuitem index
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_GetMenuitemToAXforAsciiHotkeyInAL:
	call	Char_ALtoUpperCaseLetter
	call	BootMenu_GetLetterForFirstHardDiskToCL
	xor		ah, ah
	cmp		al, cl						; Letter is for Hard Disk?
	jae		SHORT .StartFromHardDiskLetter
	sub		al, 'A'						; Letter to Floppy Drive menuitem
	ret
ALIGN JUMP_ALIGN
.StartFromHardDiskLetter:
	sub		al, cl						; Hard Disk index
	call	FloppyDrive_GetCountToCX
	add		ax, cx						; Menuitem index
	ret


;--------------------------------------------------------------------
; Returns letter for first hard disk. Usually it will be 'c' but it
; can be higher if more than two floppy drives are found.
;
; BootMenu_GetLetterForFirstHardDiskToCL
;	Parameters:
;		Nothing
;	Returns:
;		CL:		Upper case letter for first hard disk
;	Corrupts registers:
;		CH
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_GetLetterForFirstHardDiskToCL:
	call	FloppyDrive_GetCountToCX
	add		cl, 'A'
	MAX_U	cl, 'C'
	ret


;--------------------------------------------------------------------
; BootMenu_GetMenuitemToDXforDriveInDL
;	Parameters:
;		DL:		Drive number
;	Returns:
;		DX:		Menuitem index (assuming drive is available)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_GetMenuitemToDXforDriveInDL:
	xor		dh, dh						; Drive number now in DX
	test	dl, dl
	jns		SHORT .ReturnItemIndexInDX	; Return if floppy drive (HD bit not set)
	call	FloppyDrive_GetCountToCX
	and		dl, ~80h					; Clear HD bit
	add		dx, cx
.ReturnItemIndexInDX:
	ret


;--------------------------------------------------------------------
; Checks is drive number valid for this system.
;
; BootMenu_IsDriveInSystem
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		CF:		Set if drive number is valid
;				Clear if drive is not present in system
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_IsDriveInSystem:
	test	dl, dl								; Floppy drive?
	jns		SHORT .IsFloppyDriveInSystem
	call	RamVars_GetHardDiskCountFromBDAtoCX	; Hard Disk count to CX
	or		cl, 80h								; Set Hard Disk bit to CX
	jmp		SHORT .CompareDriveNumberToDriveCount
.IsFloppyDriveInSystem:
	call	FloppyDrive_GetCountToCX
.CompareDriveNumberToDriveCount:
	cmp		dl, cl								; Set CF when DL is smaller
	ret