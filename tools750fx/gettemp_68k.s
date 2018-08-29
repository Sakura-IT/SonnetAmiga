; Copyright (c) 2018 Matthew Arends
; Portions of this code are taken from template.s or template.p which is
; Copyright (c) 2015-2018 Dennis van der Boon
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
FUNCDEF	MACRO
_LVO\1	EQU	FUNC_CNT 
FUNC_CNT	SET	FUNC_CNT-6	* Standard offset-6 bytes each
		ENDM 

		include powerpc/powerpc.i

		include powerpc/powerpc_lib.i
		include exec/exec_lib.i
		include dos/dos_lib.i

		XREF _SysBase,_DOSBase,_PowerPCBase,_LinkerDB

lowhz		equ	300
hihz		equ	1200

;************************************************************************************************

		section code

;************************************************************************************************

		movem.l d0-a6,-(a7)		;Need to add WBMsg handling
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

		RUNPOWERPC PPC_Gettemp

		tst.l d0			;r3=positive temp,-1=error,-2=no 750FX
		bmi.s Errorfnd

		move.l _DOSBase,a6
		lea infotext,a1
		move.l a1,d1
		lea args,a1
		move.l d0,(a1)			;store result from r3
		move.l a1,d2
		moveq #0,d0
		jsr _LVOVPrintf(a6)
		bra.s NoLib

Errorfnd	move.l _DOSBase,a6
		cmp.l #-1,d0
		bne.s No750FX

		lea errortext,a1
prntmsg		move.l a1,d1
		moveq #0,d2
		moveq #0,d0
		jsr _LVOVPrintf(a6)

		bra.s NoLib

No750FX		lea No750,a1
		bra.s prntmsg

NoLib		move.l 4.w,a6			;close open libs
		move.l _PowerPCBase,d0
		beq.s NoPower

		move.l d0,a1
		jsr _LVOCloseLibrary(a6)

NoPower		move.l _DOSBase,d0
		beq.s NoDOS
		move.l d0,a1
		jsr _LVOCloseLibrary(a6)

NoDOS		movem.l (a7)+,d0-a6
		rts

DosLib		dc.b "dos.library",0
		cnop	0,2
PowerPCLib	dc.b "powerpc.library",0

;************************************************************************************************

		section ppcdata,data

;************************************************************************************************


		cnop 0,4
infotext	dc.b "Temperature: %ldC",10
		dc.b 0
		cnop 0,4
errortext	dc.b "Error reading temperature",10,0
		cnop 0,4
No750		dc.b "PowerPC 750FX not found",10,0

		cnop 0,4

args		dc.l 0



