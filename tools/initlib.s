	incdir include:
	include lvo/exec_lib.i
	include	lvo/sonnet_lib.i


	movem.l d0-a6,-(a7)
	move.l 4.w,a6
	lea Sonnet(pc),a1
	moveq.l #0,d0
	jsr _LVOOpenLibrary(a6)
	tst.l d0
	movem.l (a7)+,d0-a6
	rts
	
Sonnet	dc.b "sonnet.library",0