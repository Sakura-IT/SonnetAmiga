# Copyright (c) 2018 Matthew Arends
# Portions of this code are taken from template.s or template.p which is
# Copyright (c) 2015-2018 Dennis van der Boon
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

.include	sonnet_libppc.i
.include	ppcmacros-std.i
.include	ppcdefines.i

.global	@_PPC_Gettemp,_SysBase,_DOSBase,_PowerPCBase,_LinkerDB

.set		PVR,287
.set		PVR_750FX,0x7000		#hi 2 bytes only
.set		DELAY,500000			#at least 200 usecs
.set		THRM1,1020
.set		THRM2,1021
.set		THRM3,1022
.set		N,127				#start temp in search
.set		INTERVAL,0x3fff			#14 bits of 1
.set		TIV,0x4000			#TIV bit
.set		TIN,0x8000			#TIN bit

#************************************************************************************************

.section "ppccode","acrx"

#************************************************************************************************

@_PPC_Gettemp:

.long		PPC_Gettemp

#on entry r4=speed

PPC_Gettemp:	stw	r2,20(r1)
		mflr	r0
		stw	r0,8(r1)
		mfcr	r0
		stw	r0,4(r1)
		stw	r13,-4(r1)
		subi	r13,r1,4
		stwu	r1,-1024(r1)

		CALLPOWERPC Super		#Super mode before we play

		mr	r27,r3

		mfspr	r0,PVR			#check for 750FX
		rlwinm	r0,r0,16,16,31		#shift upper word to lower
		cmpwi	r0,PVR_750FX
		beq	found750FX		#beq if all good

		li	r31,-2
		b	exit			#exit with error code


found750FX:	mfmsr	r28			#turn off interrupts
		ori	r28,r28,PSL_EE
		xori	r28,r28,PSL_EE		#Disable()
		mtmsr	r28
		isync
		sync

		li	r31,N			#start point for search

search:		mr	r17,r3			#copy current temp
		rlwinm	r17,r17,23,2,8		#shift temp to bits 2 to 8
		ori	r17,r17,1		#set V bit
		mtspr	THRM1,r17		#apply threshold, TID=TIE=0,V=1 
		addi	r17,0,0
		mtspr	THRM2,r17		#V=0
		addis	r17,0,INTERVAL@h
		ori	r17,r17,INTERVAL@l	#set interval and E=1
		mtspr	THRM3,r17		#start temp sampling

		lis	r4,DELAY@h
		ori	r4,r4,DELAY@l		#reset counter
.l1:		mfspr	r17,THRM1
		andis.	r17,r17,TIV
		bne	valid			#bne if valid sample

		subi	r4,r4,1			#-1
		cmpwi	r4,0			#=0?
		bne	.l1			#bne loop
						#timer has run out - abort

		li	r31,-1			#error flag
		b	exit

valid:		mfspr	r17,THRM1		#get reading again
		andis.	r17,r17,TIN
		bne	exit			#bne if crossed threshold

		subi	r31,r31,1		#-1
		cmpwi	r31,0			#=0?
		bne	search			#bne search

						#no threshold ever found - abort

		li	r31,-1			#error flag

exit:		mfmsr	r28			#turn interrupts back on
		ori	r28,r28,PSL_EE		#Enable()
		mtmsr	r28
		isync
		sync

		mr	r4,r27

		CALLPOWERPC User		#restore user mode sanity - uncommenting causes a crash, not clear why!

		mr	r3,r31

		lwz	r1,0(r1)
		lwz	r13,-4(r1)
		lwz	r0,8(r1)
		mtlr	r0
		lwz	r0,4(r1)
		mtcr	r0
		lwz	r2,20(r1)

		blr

#************************************************************************************************

.section "ppcdata","adrw"

#************************************************************************************************

_LinkerDB:
.long		0
_SysBase:
.long		0
_DOSBase:
.long		0
_PowerPCBase:
.long		0

