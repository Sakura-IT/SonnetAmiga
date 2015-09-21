.macro clearreg # reg
		lis \1, 0
		mr \1,\1
.endm

.macro loadreg # reg, value
	.if (\2 >= -0x8000) && (\2 <= 0x7fff)
        li      \1, \2
    .else
        lis     \1, \2@h
        ori     \1, \1, \2@l
    .endif
.endm

.macro setpcireg # value
		ori r23,r22,\1
.endm

.macro LIBCALLPOWERPC # function
	lwz	r3,PowerPCBase(r0)
	lwz     r0,_LVO\1+2(r3)
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

.macro prolog
	.if (\2 = "TOC")
	stw	r2,20(r1)
	.endif
	mflr	r0
	stw	r0,8(r1)
	mfcr	r0
	stw	r0,4(r1)
	stw	r13,-4(r1)
	subi	r13,r1,4
	.if (\1 = "")
	stw	r1,-1080(r1)
	.else
	stw	r1,-\1(r1)
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

.macro	epilog
	lwz     r1,0(r1)
	lwz     r13,-4(r1)
	lwz     r0,8(r1)
	mtlr    r0
	lwz     r0,4(r1)
	mtcr    r0
	.if     (\1 = "TOC")
	lwz     r2,20(r1)
.endif
	blr
.endm

.macro RUN68K # code, offset
	subi    r13,r13,PP_SIZE				#RUN68K_XL (Parts of it)
	stw     r4,PP_REGS+1*4(r13)
	stw     r22,PP_REGS+2*4(r13)
                
	lwz	r3,\1-_LinkerDB(r2)
	stw     r3,PP_CODE(r13)
	stw     r3,PP_REGS+14*4(r13)
	li      r3,_LVO\2
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

.macro	CALLPOWERPC
	lwz	r3,_PowerPCBase-_LinkerDB(r2)
	lwz     r0,_LVO\1+2(r3)	
	mtlr    r0
	blrl
.endm