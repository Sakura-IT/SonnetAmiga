	mc68040

	section	newRunPPC,code

	xref	_oldRunPPC


	xdef	_newRunPPC
_newRunPPC:
; a0 = PPCArgs
; a6 = PowerPCBase
	move.l	a0,-(sp)
	or.b	#4,11(a0)	; PP_Flags |= PPF_THROW
	jsr	([_oldRunPPC.l])
	move.l	(sp)+,a0
	and.b	#$fb,11(a0)
	rts
