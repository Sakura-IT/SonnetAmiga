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

.global	@_PPC_Setspeed,_SysBase,_DOSBase,_PowerPCBase,_LinkerDB


.set		HID1, 1009
.set		HID1_PI0_BIT,1<<(31-14)
.set		HID1_PS_BIT,1<<(31-15)
.set		HID1_PR1_BIT,1<<(31-29)
.set		PVR,287
.set		PVR_750FX,0x7000		#hi 2 bytes only
.set		DELAY,500000	#at least 200 usecs
.set		LOWSPEED,600	#low range below 600MHz

#************************************************************************************************

.section "ppccode","acrx"

#************************************************************************************************

@_PPC_Setspeed:

.long		PPC_Setspeed

#on entry r4=speed

PPC_Setspeed:	stw	r2,20(r1)
		mflr	r0
		stw	r0,8(r1)
		mfcr	r0
		stw	r0,4(r1)
		stw	r13,-4(r1)
		subi	r13,r1,4
		stwu	r1,-1024(r1)

		mr	r29,r4

		CALLPOWERPC Super		#Super mode before we play

		mr	r30,r3			#Safe superkey
		mfspr	r0,PVR			#check for 750FX
		rlwinm	r0,r0,16,16,31		#shift upper word to lower
		cmpwi	r0,PVR_750FX
		beq	found750FX		#beq if all good

		li	r31,-1
		b exit				#exit with error code

found750FX:	mfmsr	r28			#turn off interrupts
		ori	r28,r28,PSL_EE
		xori	r28,r28,PSL_EE		#Disable()
		mtmsr	r28
		isync
		sync

		mr	r4,r29
						#set PLL0 external clocking
		mfspr	r0,HID1			#r0=HID1
		mr	r3,r0
		andis.	r3,r3,HID1_PS_BIT@h
		beq	.PLL0			#beq

		mr	r3,r0
		andis.	r3,r3,HID1_PI0_BIT@h
		beq	.SelPLL0		#beq .SelPLL0 if extern

		lis	r22,~(HID1_PI0_BIT)@h
		ori	r22,r22,~(HID1_PI0_BIT)@l
		and	r0,r0,r22		#flip bit
		mtspr	HID1,r0


		lis	r22,DELAY@h		#delay 200 microseconds
		ori	r22,r22,DELAY@l
		mtctr	r22			#set counter
.l1:		bdnz	.l1			#bdnz

.SelPLL0:	lis	r22,~(HID1_PS_BIT)@h
		ori	r22,r22,~(HID1_PS_BIT)@l
		and	r0,r0,r22		#select PLL0
		mtspr	HID1,r0

						#now set new clockspeed
.PLL0:
		mfspr	r0,HID1			# r0=HID1
		lis	r22,0xfffe
		ori	r22,r22,0xff01
		and	r0,r0,r22		#&0xfffeff01
		cmplwi	r4,LOWSPEED
		bge	.speedok		#bge

		ori	r0,r0,HID1_PR1_BIT@l	#if speed<600, r0|=HID1_PR1

.speedok:
		li	r3,50
		divwu	r4,r4,r3		#/50
		rlwinm	r4,r4,3,24,28		#<<3 and &$f8
		or 	r0,r4,r0		#hid1|speed
		mtspr	HID1,r0			#set new speed

		lis	r22,DELAY@h		#delay 200 microseconds
		ori	r22,r22,DELAY@l
		mtctr	r22			#set counter
.l2:		bdnz	.l2			#bdnz

		oris	r0,r0,HID1_PS_BIT@h
		mtspr	HID1,r0

		mfmsr	r28			#turn interrupts back on
		ori	r28,r28,PSL_EE		#Enable()
		mtmsr	r28
		isync
		sync
		
		li	r31,0			#signal no error

exit:		mr	r4,r30

		CALLPOWERPC User		#restore user mode sanity - uncommenting causes a crash for some reason

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
