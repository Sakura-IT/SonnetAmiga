;	Small programme which initializes the sonnet.library and patches
;	the AllocMem function to redirect memory allocations to sonnet memory
;	when the CLI name ends with 1005 or (so)nnet. This for debugging purposes.
;	Only works when the ppc programme is started from Shell/CLI.


	incdir include:
	include system/system.gs		;DevPac system global symbols
	include	lvo/sonnet_lib.i
	include exec/execbase.i
	include dos/dosextens.i


	movem.l d0-a6,-(a7)
	move.l 4.w,a6
	lea Sonnet(pc),a1
	moveq.l #0,d0
	jsr _LVOOpenLibrary(a6)
	tst.l d0
	beq.s NoPatch

	move.l #Sonnet-NewAlloc,d0
	move.l #$10001,d1
	jsr _LVOAllocVec(a6)
	tst.l d0
	beq.s NoPatch
	
	lea NewAlloc(pc),a1
	move.l d0,a2
	moveq.l #(Sonnet-NewAlloc)/4-1,d1
Cp	move.l (a1)+,(a2)+
	dbf d1,Cp
	
	move.l d0,a1		
	lea NoFast-NewAlloc+2(a1),a2
	move.l _LVOAllocMem+2(a6),(a2)
	move.l a1,_LVOAllocMem+2(a6)
	
	jsr _LVOCacheClearU(a6)	
	
NoPatch	movem.l (a7)+,d0-a6
	rts
	
NewAlloc:
	tst.w d1
	beq.s Best
	btst #0,d1
	beq.s NoFast
	btst #1,d1
	bne.s NoFast
Best	move.l d7,-(a7)
	move.l a3,-(a7)
	move.l a2,-(a7)
	move.l ThisTask(a6),a3
	move.b TC_FLAGS(a3),d7
	btst #2,d7
	bne.s DoBit
	move.l LN_NAME(a3),d7
	beq.s NoBit
	move.l d7,a2
	move.l (a2),d7
	cmp.l #"Shel",d7
	beq.s IsHell
	cmp.l #"Back",d7
FindEnd	move.b (a2)+,d7
	bne.s FindEnd
	move.l -5(a2),d7
	cmp.l #"2005",d7
	beq.s DoBit
	bra.s NoBit
	
IsHell	move.l pr_CLI(a3),d7
	beq.s NoBit
	lsl.l #2,d7
	move.l d7,a3
	move.l cli_CommandName(a3),d7
	beq.s NoBit
	lsl.l #2,d7
	move.l d7,a3
	clr.l d7
	move.b (a3),d7
	subq.l #4,d7
	bmi.s NoBit
	move.l 1(a3,d7.l),d7
	cmp.l #"2005",d7
	beq.s DoBit
	bra.s NoBit	
	
DoBit	bset #13,d1
NoBit	move.l (a7)+,a2
	move.l (a7)+,a3
	move.l (a7)+,d7	
NoFast	dc.w $4ef9,0,0
	
Sonnet	dc.b "sonnet.library",0

	cnop 0,2