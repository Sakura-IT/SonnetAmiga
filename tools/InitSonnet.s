;	Small programme which initializes the sonnet.library
;	It is needed as 2005 hunks cannot be loaded without the library already in memory
;
;********************************************************************************************

		include	exec/exec_lib.i

;********************************************************************************************

		SECTION MainProg,CODE

;********************************************************************************************

		movem.l d0-a6,-(a7)
		move.l 4.w,a6
		lea Sonnet(pc),a1
		moveq.l #0,d0
		jsr _LVOOpenLibrary(a6)				;Open the sonnet.library

NoPatch		movem.l (a7)+,d0-a6
		rts						;Exit
		
;********************************************************************************************
	
Sonnet		dc.b "sonnet.library",0

		cnop 0,2

;********************************************************************************************