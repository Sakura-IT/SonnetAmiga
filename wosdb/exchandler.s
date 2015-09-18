## $VER: exchandler.s V0.4c (17.02.01)
##
## This file is part of the WarpOS debugger 'wosdb'
## Copyright (c) 1999-2001  Frank Wille
##
##
## v0.4c (17.02.01) phx
##       Data-access to ExecBase at address 4 has to be emulated by
##       WarpUp kernel. Currently this has the effect that the following
##       instruction can't be traced.
## v0.3  (04.05.99) phx
##       ProgramExit() replaces the task-finished notification mechanism
##       in the 68k function newRunPPC(). It also saves the return code.
## v0.1  (01.05.99) phx
##       First usable version.
## v0.0  (19.04.99) phx
##       File created.
##

	.include "warpos_lvo.i"


	.text

	.extern _PowerPCBase
	.extern	@__ec		# global EXCContext
	.extern @__spr		# SpecRegs structure
	.extern _thisTask	# debugger task
	.extern _dbTask		# debugged task
	.extern _sigExcept	# exception signal
	.extern _sigRun		# wake up signal for debugged task
	.extern _sigFinish	# task-finished signal
	.extern	_sTrace		# single step trace mode
	.extern	_bTrace		# branch trace mode
	.extern	_initialLR	# initial LR of debugged task
	.extern	___getr2	# vc.lib
	.extern _result		# for storing the result code



	.align	3
	.globl	_ExceptionCatch
_ExceptionCatch:
# The debugged task ran into an exception. Save its context
# and put it into a user-mode waiting-loop.
# r2 = TOC
# r3 = struct EXCContext *
	lwz	r12,0(r3)	# ec_ExcID
	cmpwi	r12,(1<<3)	# == EXCF_DACCESS ?
	bne+	.ec_saveregs
	lwz	r12,12(r3)	# ec_DAR
	cmpwi	r12,4		# == 4 (ExecBase access) ?
	bne+	.ec_saveregs
	li	r3,0		# EXCRETURN_NORMAL
	blr			# run WarpOS handler to access ExecBase
.ec_saveregs:
	mr	r11,r1
	lwz	r1,@_excStackBase(r2)
	li	r12,0
	stwu	r12,-32(r1)
	stw	r11,28(r1)
	mflr	r0
	stw	r0,8(r1)
	stwu	r1,-32(r1)
	stw	r30,24(r1)
	stw	r31,28(r1)

	lwz	r31,_PowerPCBase(r2)
	mr	r30,r3		# r30 struct EXCContext *
	CALLWOS	SetExcMMU,r31	# temporary MMU setup

	mr	r4,r30
	lwz	r5,@__ec(r2)
	li	r6,424		# sizeof(struct EXCContext)
	CALLWOS	CopyMemPPC,r31	# save EXCContext to ec

	lwz	r3,@__spr(r2)	# fill SpecRegs
	mfspr	r0,1008
	stw	r0,0(r3)	# HID0
	mfspr	r0,1009
	stw	r0,4(r3)	# HID1
	mfspr	r0,287
	stw	r0,8(r3)	# PVR
	mfspr	r0,25
	stw	r0,12(r3)	# SDR1
	mfspr	r0,282
	stw	r0,16(r3)	# EAR
	mfspr	r0,22
	stw	r0,20(r3)	# DEC
	mfspr	r0,268
	stw	r0,24(r3)	# TBU
	mfspr	r0,269
	stw	r0,28(r3)	# TBL

	li	r4,0
	CALLWOS	FindTaskPPC,r31	# determine debugged task
	stw	r3,_dbTask(r2)

	lwz	r4,_thisTask(r2)
	li	r5,1
	lwz	r6,_sigExcept(r2)
	slw	r5,r5,r6
	CALLWOS	SignalPPC,r31	# wake up debugger task

	lwz	r3,8(r30)	# r3 MSR
	li	r11,0xfffff9ff
	and	r3,r3,r11	# disable trace mode
	stw	r3,8(r30)
	li	r0,0
	mtspr	1010,r0		# clear IABR breakpoint

	lwz	r0,@_taskWait(r2)
	stw	r0,4(r30)	# set SRR0 (PC) to taskWait()
	stw	r1,40+1*4(r30)	# pass stack-pointer (r1)
	stw	r2,40+2*4(r30)	# pass TOC-pointer (r2)
	stw	r31,40+31*4(r30) # and PowerPCBase (r31)

	CALLWOS	ClearExcMMU,r31

	lwz	r30,24(r1)
	lwz	r31,28(r1)
	li	r3,1		# EXCRETURN_ABORT
	addi	r1,r1,32
	lwz	r0,8(r1)
	mtlr	r0
	lwz	r1,28(r1)
	blr


	.align	3
taskWait:
# The debugged task is waiting here for a signal from the debugger
	lwz	r3,_sigRun(r2)
	li	r4,1
	slw	r4,r4,r3
	CALLWOS	WaitPPC,r31
taskWaitExit:
	trap


	.align	3
	.globl	_ExceptionLeave
_ExceptionLeave:
# The debugged task continues to run. The complete context must be restored.
# r2 = TOC
# r3 = struct EXCContext *
	mr	r11,r1
	lwz	r1,@_excStackBase(r2)
	li	r12,0
	stwu	r12,-32(r1)
	stw	r11,28(r1)
	mflr	r0
	stw	r0,8(r1)
	stwu	r1,-32(r1)
	stw	r30,24(r1)
	stw	r31,28(r1)

	lwz	r31,_PowerPCBase(r2)
	mr	r30,r3		# r30 struct EXCContext *
	CALLWOS	SetExcMMU,r31	# temporary MMU setup

	lwz	r3,4(r30)
	lwz	r4,@_taskWaitExit(r2)
	cmpw	r3,r4		# breakpoint = taskWaitExit?
	beq	.el1
	li	r30,0		# EXCRETURN_NORMAL, call other handler
	b	.el2
.el1:
	lwz	r4,@__ec(r2)
	mr	r5,r30
	li	r6,424		# sizeof(struct EXCContext)
	CALLWOS	CopyMemPPC,r31	# restore EXCContext from ec

	lwz	r0,8(r30)	# MSR = SRR1
	li	r11,0xfffff9ff
	lhz	r3,_sTrace(r2)
	and	r0,r0,r11
	mr.	r3,r3
	lhz	r4,_bTrace(r2)
	beq	.el3
	ori	r0,r0,0x400	# MSR: Single Step Trace Enable
.el3:
	mr.	r4,r4
	beq	.el4
	ori	r0,r0,0x200	# MSR: Branch Trace Enable
.el4:
	stw	r0,8(r30)
	li	r30,1		# EXCRETURN_ABORT

.el2:
	CALLWOS	ClearExcMMU,r31

	mr	r3,r30
	lwz	r30,24(r1)
	lwz	r31,28(r1)
	addi	r1,r1,32
	lwz	r0,8(r1)
	mtlr	r0
	lwz	r1,28(r1)
	blr


	.align	3
	.globl	_ProgramExit
_ProgramExit:
# called when debugged program terminates
# r3 = return code
	stwu	r1,-32(r1)
	stw	r2,24(r1)
	stw	r3,28(r1)
	bl	___getr2	# get debugger's TOC pointer
	lwz	r3,_PowerPCBase(r2)
	lwz	r4,_thisTask(r2)
	li	r5,1
	lwz	r6,_sigFinish(r2)
	slw	r5,r5,r6
	CALLWOS	SignalPPC	# tell debugger about task termination
	lwz	r3,28(r1)
	lwz	r0,_initialLR(r2)
	stw	r3,_result(r2)	# save result code for debugger
	mtlr	r0
	lwz	r2,24(r1)	# restore TOC pointer and return code
	addi	r1,r1,32
	blr			# return to Warp kernel

	.global	_ProgramExitEnd
_ProgramExitEnd:



	.lcomm	excStack,0x1000


	.tocd

@_taskWait:
	.long	taskWait
@_taskWaitExit:
	.long	taskWaitExit
@_excStackBase:
	.long	excStack+0x1000
