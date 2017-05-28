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
;
;	Small programme which initializes the sonnet library
;	It is needed as 2005 hunks cannot be loaded without the library already in memory
;
;********************************************************************************************

		include 68kdefines.i
		include	exec/exec_lib.i

;********************************************************************************************

		SECTION MainProg,CODE

;********************************************************************************************

		movem.l d0-a6,-(a7)
		move.l 4.w,a6
		lea PowerPC(pc),a1
		moveq.l #0,d0
		jsr _LVOOpenLibrary(a6)				;Open the powerpc.library

NoPatch		movem.l (a7)+,d0-a6
		rts						;Exit

;********************************************************************************************

PowerPC		dc.b "powerpc.library",0

		cnop 0,2

;********************************************************************************************
