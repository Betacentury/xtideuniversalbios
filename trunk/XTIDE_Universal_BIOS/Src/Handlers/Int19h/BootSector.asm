; Project name	:	XTIDE Universal BIOS
; Description	:	Reading and jumping to boot sector.

;
; XTIDE Universal BIOS and Associated Tools 
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2012 by XTIDE Universal BIOS Team.
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; Visit http://www.gnu.org/licenses/old-licenses/gpl-2.0.html				
;		

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; BootSector_TryToLoadFromDriveDL
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;		DS:		RAMVARS segment
;	Returns:
;		ES:BX:	Ptr to boot sector (if successful)
;		CF:		Set if boot sector loaded successfully
;				Cleared if failed to load boot sector
;	Corrupts registers:
;		AX, CX, DH, SI, DI, (DL if failed to read boot sector)
;--------------------------------------------------------------------
BootSector_TryToLoadFromDriveDL:
	call	DetectPrint_TryToBootFromDL
	call	LoadFirstSectorFromDriveDL
	jc		SHORT .FailedToLoadFirstSector

	test	dl, dl
	jns		SHORT .AlwaysBootFromFloppyDriveForBooterGames
	cmp		WORD [es:bx+510], 0AA55h		; Valid boot sector?
	jne		SHORT .FirstHardDiskSectorNotBootable
.AlwaysBootFromFloppyDriveForBooterGames:
	stc
	ret
.FailedToLoadFirstSector:
	call	DetectPrint_FailedToLoadFirstSector
	clc
	ret
.FirstHardDiskSectorNotBootable:
	mov		si, g_szBootSectorNotFound
	call	DetectPrint_NullTerminatedStringFromCSSIandSetCF
	clc
	ret

;--------------------------------------------------------------------
; LoadFirstSectorFromDriveDL
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;	Returns:
;		AH:		INT 13h error code
;		ES:BX:	Ptr to boot sector (if successful)
;		CF:		Cleared if read successful
;				Set if any error
;	Corrupts registers:
;		AL, CX, DH, DI
;--------------------------------------------------------------------
LoadFirstSectorFromDriveDL:
	LOAD_BDA_SEGMENT_TO	es, bx				; ES:BX now points to...
	mov		bx, BOOTVARS.rgbBootSect		; ...boot sector location
	mov		di, BOOT_READ_RETRY_TIMES		; Initialize retry counter

.ReadRetryLoop:
	call	.ResetBootDriveFromDL
	call	.LoadFirstSectorFromDLtoESBX
	jnc		SHORT .Return
	dec		di								; Decrement retry counter
	jnz		SHORT .ReadRetryLoop			; Loop while retries left
.Return:
	ret

;--------------------------------------------------------------------
; .ResetBootDriveFromDL
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;	Returns:
;		AH:		INT 13h error code
;		CF:		Cleared if read successful
;				Set if any error
;	Corrupts registers:
;		AL
;--------------------------------------------------------------------
.ResetBootDriveFromDL:
	xor		ax, ax							; AH=0h, Disk Controller Reset
	test	dl, dl							; Floppy drive?
	jns		SHORT .SkipAltReset
	mov		ah, 0Dh							; AH=Dh, Reset Hard Disk (Alternate reset)
.SkipAltReset:
	int		BIOS_DISK_INTERRUPT_13h
	ret

;--------------------------------------------------------------------
; .LoadFirstSectorFromDLtoESBX
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;		ES:BX:	Destination buffer for boot sector
;	Returns:
;		AH:		INT 13h error code
;		ES:BX:	Ptr to boot sector
;		CF:		Cleared if read successful
;				Set if any error
;	Corrupts registers:
;		AL, CX, DH
;--------------------------------------------------------------------
.LoadFirstSectorFromDLtoESBX:
	mov		ax, 0201h						; Read 1 sector
	mov		cx, 1							; Cylinder 0, Sector 1
	xor		dh, dh							; Head 0
	int		BIOS_DISK_INTERRUPT_13h
	ret