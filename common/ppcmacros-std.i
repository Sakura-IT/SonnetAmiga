# Copyright (c) 2015-2017 Dennis van der Boon
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

.macro	illegal
		.long	0
.endm

.macro clearreg register
		lis \register, 0
		mr \register,\register
.endm

.macro loadreg register, value
	.if 	(\value >= -0x8000) && (\value <= 0x7fff)
        	li      \register, \value
	.else
		lis     \register, \value@h
		ori     \register, \register, \value@l
	.endif
.endm

.macro setpcireg pcivalue
		ori r23,r22,\pcivalue
.endm

.macro LIBCALLPOWERPC ppcfunction
		lwz	r3,PowerPCBase(r0)
		lwz     r0,_LVO\ppcfunction+2(r3)
		mtlr    r0
		blrl
.endm

.macro BUILDSTACKPPC
		stw	r2,20(r1)
		mflr	r0
		stw	r0,8(r1)
		mfcr	r0
		stw	r0,4(r1)
		stw	r13,-4(r1)
		subi	r13,r1,4
		stwu	r1,-284(r1)
.endm

.macro prolog stacksize, data
	.if	\data = "TOC"
		stw	r2,20(r1)
	.endif
		mflr	r0
		stw	r0,8(r1)
		mfcr	r0
		stw	r0,4(r1)
		stw	r13,-4(r1)
		subi	r13,r1,4
	.if	\stacksize = ""
		stwu	r1,-1024(r1)
	.else
		stwu	r1,-(\stacksize+60)(r1)
	.endif
.endm

.macro DSTRYSTACKPPC
		lwz	r1,0(r1)
		lwz	r13,-4(r1)
		lwz	r0,8(r1)
		mtlr	r0
		lwz	r0,4(r1)
		mtcr	r0
		lwz	r2,20(r1)
.endm

.macro	epilog data
		lwz     r1,0(r1)
		lwz     r13,-4(r1)
		lwz     r0,8(r1)
		mtlr    r0
		lwz     r0,4(r1)
		mtcr    r0
	.if     (\data = "TOC")
		lwz     r2,20(r1)
		blr
	.endif
.endm

.macro	excepilog data
		lwz     r1,0(r1)
		lwz     r13,-4(r1)
		lwz     r0,8(r1)
		mtlr    r0
		lwz     r0,4(r1)
		mtcr    r0
	.if     (\data = "TOC")
		lwz     r2,20(r1)
	.endif
.endm

.macro RUN68K base, function
		subi    r13,r13,PP_SIZE				#RUN68K_XL (Parts of it)
		stw     r4,PP_REGS+1*4(r13)
		stw     r22,PP_REGS+2*4(r13)

		lwz	r3,\base-_LinkerDB(r2)
		stw     r3,PP_CODE(r13)
		stw     r3,PP_REGS+14*4(r13)
		li      r3,_LVO\function
		stw     r3,PP_OFFSET(r13)
		li	r3,0
		stw     r3,PP_FLAGS(r13)
		stw     r3,PP_STACKPTR(r13)
		stw     r3,PP_STACKSIZE(r13)
		mr	r4,r13

		lwz	r3,_PowerPCBase-_LinkerDB(r2)
		lwz     r0,_LVORun68K+2(r3)
		mtlr    r0
		blrl
.endm

.macro	CALLPOWERPC ppcfunction
		lwz	r3,_PowerPCBase-_LinkerDB(r2)
		lwz     r0,_LVO\ppcfunction+2(r3)
		mtlr    r0
		blrl
.endm

.macro CALLWOS function, register
		.ifnb \register
			mr r3,\register
		.endif
		lwz r0,_LVO\function+2(r3)
		mtlr r0
		blrl
.endm
