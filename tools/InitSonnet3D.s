;	Small programme which initializes the sonnet.library and patches
;	the AllocMem function to redirect memory allocations to sonnet memory
;	when the (CLI) name ends with 2005. It does this also for programs tagged
;	by the sonnet.library (by using the Open() function of the library).
;
;	NOTE: Now the memory attributes are the same as the ones of the pcidma memory
;	installed by the Mediator, this code could be actually integrated into sonnet.library.
;********************************************************************************************

		include 68kdefines.i
		include	exec/exec_lib.i
		include	sonnet_lib.i
		include exec/execbase.i
		include dos/dosextens.i

;********************************************************************************************

		SECTION MainProg,CODE

;********************************************************************************************

		movem.l d0-a6,-(a7)
		move.l 4.w,a6
		lea Sonnet(pc),a1
		moveq.l #0,d0
		jsr _LVOOpenLibrary(a6)				;Open the sonnet.library
		tst.l d0
		beq.s NoPatch

		move.l #Sonnet-NewAlloc,d0
		move.l #$10001,d1
		jsr _LVOAllocVec(a6)
		tst.l d0					;Get memory for our patch
		beq.s NoPatch

		lea NewAlloc(pc),a1
		move.l d0,a2
		moveq.l #(Sonnet-NewAlloc)/4-1,d1
Cp		move.l (a1)+,(a2)+
		dbf d1,Cp					;Copy the patch routine to this memory
	
		move.l d0,a1		
		lea NoFast-NewAlloc+2(a1),a2
		move.l _LVOAllocMem+2(a6),(a2)
		move.l a1,_LVOAllocMem+2(a6)			;Patch the AllocMem() function

		jsr _LVOCacheClearU(a6)				;Clear all caches

		lea ramlib(pc),a1
		jsr _LVOFindTask(a6)
		tst.l d0
		beq.s NoPatch
		
		move.l d0,a1
		move.l a1,-(a7)
		or.b #TF_PPC,TC_FLAGS(a1)

		lea Warp3D(pc),a1				;Pre-load the Warp3D libraries
		moveq.l #0,d0					;and force them into PPC memory
		jsr _LVOOpenLibrary(a6)
	
		move.l (a7)+,a1
		eor.b #TF_PPC,TC_FLAGS(a1)
	
NoPatch		movem.l (a7)+,d0-a6
		rts						;Exit
		
;********************************************************************************************

NewAlloc:	tst.w d1					;Patch code - Test for attribute $0000 (Any)
		beq.s Best
		btst #2,d1					;If FAST requested, redirect
		bne.s Best					
		btst #0,d1					;If not PUBLIC requested, exit
		beq.s NoFast
		btst #1,d1					;If CHIP requested, exit
		bne.s NoFast
		nop						;Let everything else through..?		
		
Best		move.l d7,-(a7)
		move.l a3,-(a7)
		move.l a2,-(a7)
		move.l ThisTask(a6),a3
		move.b TC_FLAGS(a3),d7
		btst #2,d7					;Check if task was tagged by sonnet.library
		bne.s DoBit					;If yes, then redirect to PPC memory
		
		move.l pr_CLI(a3),d7				;Was this task started by CLI?
		bne.s IsHell					;If yes, go there
		
		move.l LN_NAME(a3),d7				;Has the task a name?
		beq.s NoBit					;If no then exit
		move.l d7,a2

FindEnd		move.b (a2)+,d7
		bne.s FindEnd
		move.l -5(a2),d7
		cmp.l #"2005",d7				;Task has name with 2005 at end?
		beq.s DoBit					;if yes, then redirect to PPC memory
		bra.s NoBit

IsHell		lsl.l #2,d7
		move.l d7,a3
		move.l cli_CommandName(a3),d7			;Get name of task started by CLI
		beq.s NoBit
		lsl.l #2,d7
		move.l d7,a3
		clr.l d7
		move.b (a3),d7
		subq.l #4,d7
		bmi.s NoBit
		move.l 1(a3,d7.l),d7
		cmp.l #"2005",d7				;Check if CLI or Shell CommandName ends with 2005
		beq.s DoBit					;If yes, then redirect to PPC memory
		bra.s NoBit	

DoBit		bset #13,d1					;Set attribute $2000
		bset #18,d1					;MEMF_REVERSE
NoBit		move.l (a7)+,a2
		move.l (a7)+,a3
		move.l (a7)+,d7	
NoFast		dc.w $4ef9,0,0					;Jump to pathed AllocMem routine

;********************************************************************************************	

Sonnet		dc.b "sonnet.library",0
Warp3D		dc.b "Warp3DPPC.library",0
ramlib		dc.b "ramlib",0

		cnop 0,2

;********************************************************************************************