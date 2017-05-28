; Copyright (c) 2015-2017 Dennis van der Boon
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

FUNC_CNT	SET	-30		* Skip 4 standard vectors
FUNCDEF		MACRO
_LVO\1		EQU	FUNC_CNT 
FUNC_CNT	SET	FUNC_CNT-6	* Standard offset-6 bytes each
		ENDM   

		include powerpc/powerpc.i

		include powerpc/powerpc_lib.i
		include exec/exec_lib.i
		include dos/dos_lib.i
		
		XREF _SysBase,_DOSBase,_PowerPCBase,_LinkerDB

;************************************************************************************************

		section code

;************************************************************************************************		
		
		movem.l d0-a6,-(a7)			;Need to add WBMsg handling
		lea _LinkerDB,a4
		move.l 4.w,a6
		move.l a6,_SysBase
		moveq.l #37,d0
		lea DosLib(pc),a1
		jsr _LVOOpenLibrary(a6)
		tst.l d0
		beq NoLib
		move.l d0,_DOSBase
		moveq.l #0,d0
		lea PowerPCLib(pc),a1
		jsr _LVOOpenLibrary(a6)
		tst.l d0
		beq NoLib
		move.l d0,_PowerPCBase
		
		RUNPOWERPC PPC_Code
		
		move.l 4.w,a6
NoLib		move.l _PowerPCBase,d0
		beq.s NoPower
		move.l d0,a1
		jsr _LVOCloseLibrary(a6)
NoPower		move.l _DOSBase,d0
		beq.s NoDOS
		move.l d0,a1
		jsr _LVOCloseLibrary(a6)
		
NoDOS		movem.l (a7)+,d0-a6
		rts
		
;************************************************************************************************		

DosLib		dc.b "dos.library",0
PowerPCLib	dc.b "powerpc.library",0		
		
;************************************************************************************************		
