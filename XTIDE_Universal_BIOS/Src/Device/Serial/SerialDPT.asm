; Project name	:	XTIDE Universal BIOS
; Description	:	Sets Serial Device specific parameters to DPT.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; SerialDPT_Finalize
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
SerialDPT_Finalize:
		or		byte [di+DPT.bFlagsHigh], FLGH_DPT_SERIAL_DEVICE
		mov		ax, [es:si+ATA6.wVendor]
		mov		[di+DPT_SERIAL.wSerialPortAndBaud], ax
		ret
