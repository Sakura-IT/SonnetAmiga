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

.global		@_PPC_Code,_SysBase,_DOSBase,_PowerPCBase,_LinkerDB

.set		HID1, 1009
.set		HID1_PI0_BIT,1<<(31-14)
.set		HID1_PS_BIT,1<<(31-15)
.set		HID1_PR1_BIT,1<<(31-29)
.set		PLL1shift,31-28
.set		PLL0shift,31-20
.set		PLL0shifte,31-4

#************************************************************************************************

.section "ppccode","acrx"

#************************************************************************************************

@_PPC_Code:

.long		PPC_Code

PPC_Code:	stw	r2,20(r1)
		mflr	r0
		stw	r0,8(r1)
		mfcr	r0
		stw	r0,4(r1)
		stw	r13,-4(r1)
		subi	r13,r1,4
		stwu	r1,-1024(r1)

		CALLPOWERPC Super

		mfspr	r31,HID1		#r31=HID1
		mr	r4,r3			#SuperKey to r4

		CALLPOWERPC User

		mr	r3,r31
		li	r4,PLL1shift		#PLL1 shift value as default
		andis.	r3,r3,HID1_PS_BIT@h
		bne	.foundshift

		mr	r3,r31
		andis.	r3,r3,HID1_PI0_BIT@h
		beq	.externconfig

		li	r4,PLL0shift		#PLL0 internal shift
		b	.foundshift

.externconfig:	li	r4,PLL0shifte		#PLL0 external shift

.foundshift:	sraw	r3,r31,r4		#shift answer down
		andi.	r3,r3,0x1f		#mask to lowest 5 bits
		mulli	r3,r3,50		#in multiples of 50Hz

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

