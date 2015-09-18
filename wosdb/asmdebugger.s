## $VER: asmdebugger.s V0.1 (01.05.99)
##
## This file is part of the WarpOS debugger 'wosdb'
## Copyright (c) 1999-2001  Frank Wille
##
##
## v0.1  (01.05.99) phx
##       First usable version.
## v0.0  (24.04.99) phx
##       File created.
##

	.include "warpos_lvo.i"


	.text

	.extern _PowerPCBase


.if	0	# temporary breakpoints are currently
		# not realized by using IABR
	.align	3
	.globl	_wosdb_tempbreakpoint
_wosdb_tempbreakpoint:
# sets a temporary breakpoint by writing to the IABR register
# r2 = TOC
# r3 = breakpoint-addr
	mflr	r0
	stw	r0,8(r1)
	stwu	r1,-32(r1)
	stw	r30,24(r1)
	stw	r31,28(r1)
	ori	r30,r3,2	# set breakpoint enable flag
	lwz	r31,_PowerPCBase(r2)
	CALLWOS	Super,r31
	mfmsr	r4
	andi.	r4,r4,0x20	# check IR (instruction translation)
	beq	.tbp1
	ori	r30,r30,1	# set translation enable for breakpoint
.tbp1:
	mtspr	1010,r30	# enable IABR
	mr	r4,r3
	CALLWOS	User,r31
	lwz	r30,24(r1)
	lwz	r31,28(r1)
	addi	r1,r1,32
	lwz	r0,8(r1)
	mtlr	r0
	blr
.endif


	.align	3
	.globl	_clearIABR
_clearIABR:
# disables IABR register
# r2 = TOC
	mflr	r0
	stw	r0,8(r1)
	stwu	r1,-32(r1)
	stw	r31,28(r1)
	lwz	r31,_PowerPCBase(r2)
	CALLWOS	Super,r31
	li	r0,0
	mtspr	1010,r0
	mr	r4,r3
	CALLWOS	User,r31
	lwz	r31,28(r1)
	addi	r1,r1,32
	lwz	r0,8(r1)
	mtlr	r0
	blr


	.align	3
	.globl	_readIABR
_readIABR:
# returns IABR register
# r2 = TOC
	mflr	r0
	stw	r0,8(r1)
	stwu	r1,-32(r1)
	stw	r31,28(r1)
	lwz	r31,_PowerPCBase(r2)
	CALLWOS	Super,r31
	mr	r4,r3
	mr	r3,r31
	mfspr	r31,1010
	CALLWOS	User,r3
	mr	r3,r31
	lwz	r31,28(r1)
	addi	r1,r1,32
	lwz	r0,8(r1)
	mtlr	r0
	blr
