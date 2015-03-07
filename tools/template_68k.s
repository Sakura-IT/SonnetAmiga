FUNC_CNT	EQU	-30		* Skip 4 standard vectors
FUNCDEF		MACRO
_LVO\1		EQU	FUNC_CNT 
FUNC_CNT	SET	FUNC_CNT-6	* Standard offset-6 bytes each
		ENDM   

		include powerpc/powerpc.i

		include powerpc/powerpc_lib.i
		include exec/exec_lib.i
		include dos/dos_lib.i
		
		XDEF _SysBase,_DOSBase,_PowerPCBase

;************************************************************************************************

		section code

;************************************************************************************************		
		
		movem.l d0-a6,-(a7)			;Need to add WBMsg handling
		lea Data,a4
		move.l 4.w,a6
		move.l a6,_SysBase-Data(a4)
		moveq.l #37,d0
		lea DosLib(pc),a1
		jsr _LVOOpenLibrary(a6)
		tst.l d0
		beq NoLib
		move.l d0,_DOSBase-Data(a4)
		moveq.l #0,d0
		lea PowerPCLib(pc),a1
		jsr _LVOOpenLibrary(a6)
		tst.l d0
		beq NoLib
		move.l d0,_PowerPCBase-Data(a4)
		
		RUNPOWERPC PPC_Code
		
		move.l 4.w,a6
NoLib		move.l _PowerPCBase-Data(a4),d0
		beq.s NoPower
		move.l d0,a1
		jsr _LVOCloseLibrary(a6)
NoPower		move.l _DOSBase-Data(a4),d0
		beq.s NoDOS
		move.l d0,a1
		jsr _LVOCloseLibrary(a6)
		
NoDOS		movem.l (a7)+,d0-a6
		rts
		
		
DosLib		dc.b "dos.library",0
PowerPCLib	dc.b "sonnet.library",0		
		
;************************************************************************************************

		section ppcdata,data,$1005	;MUST be in Sonnet memory!
		
;************************************************************************************************

Data		ds.l	1
_SysBase	ds.l 	1
_DOSBase	ds.l	1
_PowerPCBase	ds.l	1

		
