.include ppcdefines.i
.include sonnet_libppc.i
.include ppcmacros-std.i

.set FunctionsLen,(EndFunctions-SetCache)
.set ViolationOS,(Violation-SetCache)
.set TaskExit,(EndTaskPPC-SetCache)
.set TaskStart,(StartCode-SetCache)
.set ListStart,(InsertPPC-SetCache)
.set ListEnd,(FindNamePPC-SetCache)

.global FunctionsLen
.global ViolationOS
.global LibFunctions
.global TaskExit
.global sonnet_CPUInfo
.global TaskStart
.global	ListStart
.global	ListEnd

.global SetExcMMU,ClearExcMMU,ConfirmInterrupt,InsertPPC,AddHeadPPC,AddTailPPC
.global RemovePPC,RemHeadPPC,RemTailPPC,EnqueuePPC,FindNamePPC,ResetPPC,NewListPPC
.global	AddTimePPC,SubTimePPC,CmpTimePPC,AllocVecPPC,FreeVecPPC,GetInfo,GetSysTimePPC
.global NextTagItemPPC,GetTagDataPPC,FindTagItemPPC,FreeSignalPPC
.global	AllocXMsgPPC,FreeXMsgPPC,CreateMsgPortPPC,DeleteMsgPortPPC,AllocSignalPPC
.global SetSignalPPC,LockTaskList,UnLockTaskList
.global	InitSemaphorePPC,FreeSemaphorePPC,ObtainSemaphorePPC,AttemptSemaphorePPC
.global	ReleaseSemaphorePPC,AddSemaphorePPC,RemSemaphorePPC,FindSemaphorePPC
.global AddPortPPC,RemPortPPC,FindPortPPC,WaitPortPPC,Super,User
.global PutXMsgPPC,WaitFor68K,Run68K,Signal68K,CopyMemPPC,SetReplyPortPPC
.global	TrySemaphorePPC,CreatePoolPPC

.global SPrintF,Run68KLowLevel,CreateTaskPPC,DeleteTaskPPC,FindTaskPPC,SignalPPC
.global WaitPPC,SetTaskPriPPC,SetCache,SetExcHandler,RemExcHandler,SetHardware
.global ModifyFPExc,WaitTime,ChangeStack,ChangeMMU,PutMsgPPC,GetMsgPPC,ReplyMsgPPC
.global FreeAllMem,SnoopTask,EndSnoopTask,GetHALInfo,SetScheduling,FindTaskByID
.global SetNiceValue,AllocPrivateMem,FreePrivateMem,SetExceptPPC,ObtainSemaphoreSharedPPC
.global AttemptSemaphoreSharedPPC,ProcurePPC,VacatePPC,CauseInterrupt,DeletePoolPPC
.global AllocPooledPPC,FreePooledPPC,RawDoFmtPPC,PutPublicMsgPPC,AddUniquePortPPC
.global AddUniqueSemaphorePPC,IsExceptionMode,CreateMsgFramePPC,SendMsgFramePPC,FreeMsgFramePPC

.global	WarpIllegal

.section "LibBody","acrx"

#********************************************************************************************
#
#	Void SetCache(PowerPCBase, cacheflags, start, length) // r3,r4,r5,r6
#
#********************************************************************************************	

LibFunctions:		
SetCache:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		
		li	r31,FSetCache-FRun68K
		bl	DebugStartFunction
		
		mfctr	r28
		mr	r30,r3

		cmplwi	r4,CACHE_DCACHEFLUSH
		beq-	.DCACHEFLUSH
		cmplwi	r4,CACHE_ICACHEINV
		beq-	.ICACHEINV
		cmplwi	r4,CACHE_ICACHEOFF
		beq-	.ICACHEOFF
		cmplwi	r4,CACHE_ICACHEON
		beq-	.ICACHEON
		cmplwi	r4,CACHE_ICACHEUNLOCK
		beq-	.ICACHEUNLOCK
		cmplwi	r4,CACHE_DCACHEON
		beq-	.DCACHEON
		cmplwi	r4,CACHE_DCACHEUNLOCK
		beq-	.DCACHEUNLOCK
		cmplwi	r4,CACHE_ICACHELOCK
		beq-	.ICACHELOCK
		cmplwi	r4,CACHE_DCACHEOFF
		beq-	.DCACHEOFF
		cmplwi	r4,CACHE_DCACHELOCK
		beq-	.DCACHELOCK
		cmplwi	r4,CACHE_DCACHEINV
		beq-	.DCACHEINV
		cmplwi	r4,CACHE_L2CACHEON
		beq-	.L2ENABLE
		cmplwi	r4,CACHE_L2CACHEOFF
		beq-	.L2DISABLE
		cmplwi	r4,CACHE_L2WTON
		beq-	.L2WTENABLE
		cmplwi	r4,CACHE_L2WTOFF
		beq-	.L2WTDISABLE
		cmplwi	r4,CACHE_TOGGLEDFLUSH
		beq-	.TOGGLEDFLUSH
		b	.DoneCache
		
.L2WTENABLE:	bl Super

		mfl2cr	r4
		oris	r4,r4,L2CR_L2WT@h
		mtl2cr	r4
		sync
		
		mr	r4,r3
		
		bl User
		
		b	.DoneCache
		
.L2WTDISABLE:	bl Super

		mfl2cr	r4
		oris	r4,r4,L2CR_L2WT@h
		xoris	r4,r4,L2CR_L2WT@h
		mtl2cr	r4
		sync
		
		mr	r4,r3
		
		bl User
		
		b	.DoneCache


.L2ENABLE:	bl Super

		mfl2cr	r4
		oris	r4,r4,L2CR_L2E@h
		mtl2cr	r4
		sync
		
		lwz	r4,sonnet_L2Size(r30)
		stw	r4,sonnet_CurrentL2Size(r30)
		mr	r4,r3

		bl User
		
		b	.DoneCache


.L2DISABLE:	mr	r3,r30

		bl FlushDCache

		bl Super

		mfl2cr	r4
		oris	r4,r4,L2CR_L2E@h
		xoris	r4,r4,L2CR_L2E@h
		mtl2cr	r4
		sync
		
		li	r4,0
		stw	r4,sonnet_CurrentL2Size(r30)		
		mr	r4,r3
		
		bl User
		
		b	.DoneCache

.DCACHEINV: 	mr.	r5,r5
		beq-	.DoneCache
		mr.	r6,r6
		beq-	.DoneCache
		mr	r4,r5
		mr	r5,r6

		bl Super

		add	r5,r5,r4
		loadreg	r0,0xffffffe0
		and	r4,r4,r0
		addi	r5,r5,31
		and	r5,r5,r0
		sub	r5,r5,r4
		rlwinm	r5,r5,27,5,31
		mtctr	r5
.DInvalidate:	dcbi	r0,r4
		addi	r4,r4,L1_CACHE_LINE_SIZE
		bdnz+	.DInvalidate
		sync
		
		mr	r4,r3
		
		bl User
		
		b	.DoneCache

.DCACHELOCK:	mr.	r5,r5				#ExceptionMode should be Neg?
		beq-	.DoneCache
		mr.	r6,r6
		beq-	.DoneCache

		lbz	r29,DLockState(r30)
		mr.	r29,r29
		bne	.DoneCache

		mr	r3,r30
		mr	r29,r5
		mr	r31,r6
		
		bl FlushDCache
		
		mr	r4,r29
		mr	r5,r31
		
		add	r5,r5,r4
		loadreg r0,0xffffffe0
		and	r4,r4,r0
		addi	r5,r5,31
		and	r5,r5,r0
		sub	r5,r5,r4
		rlwinm	r5,r5,27,5,31
		mtctr	r5
.FillLoop:	lwz	r0,0(r4)
		addi	r4,r4,L1_CACHE_LINE_SIZE
		bdnz+	.FillLoop
		
		bl Super
		
		mfspr	r0,HID0
		ori	r0,r0,HID0_DLOCK
		sync	
		mtspr	HID0,r0
		sync	
		isync		

		mr	r4,r3

		bl User
		
		li	r0,-1
		stb	r0,DLockState(r30)

		b	.DoneCache
				
.DCACHEOFF:	lbz	r29,DState(r30)			#ExceptionMode should be Neg?
		mr.	r29,r29
		bne	.DoneCache
		
		mr	r3,r30

		bl FlushDCache
		
		bl Super
		
		mfspr	r0,HID0
		ori	r0,r0,HID0_DCE
		xori	r0,r0,HID0_DCE
		sync	
		mtspr	HID0,r0
		sync
		
		mr	r4,r3
		
		li	r0,-1
		stb	r0,DState(r30)
		
		bl User

		b	.DoneCache

.ICACHELOCK:	bl Super

		mfspr	r0,HID0
		ori	r0,r0,HID0_ILOCK
		isync	
		mtspr	HID0,r0

		mr	r4,r3

		bl User

		b	.DoneCache

.DCACHEUNLOCK:	li	r0,0
		stb	r0,DLockState(r30)
		
		bl Super

		mfspr	r0,HID0
		ori	r0,r0,HID0_DLOCK
		xori	r0,r0,HID0_DLOCK
		mtspr	HID0,r0
		sync	
		isync		

		mr	r4,r3

		bl User
		
		b	.DoneCache

.DCACHEON:	li	r0,0
		stb	r0,DState(r30)		
		
		bl Super

		mfspr	r0,HID0
		ori	r0,r0,HID0_DCE
		mtspr	HID0,r0
		isync
		
		mr	r4,r3
		
		bl User
		
		b	.DoneCache

.ICACHEUNLOCK:	bl Super

		mfspr	r0,HID0
		ori	r0,r0,HID0_ILOCK
		xori	r0,r0,HID0_ILOCK
		mtspr	HID0,r0
		isync
		
		mr	r4,r3
		
		bl User

		b	.DoneCache

.ICACHEON:	bl Super

		mfspr	r0,HID0
		ori	r0,r0,HID0_ICE
		mtspr	HID0,r0
		isync

		mr	r4,r3

		bl User
		
		b	.DoneCache

.ICACHEOFF:	bl Super
		
		mfspr	r0,HID0
		ori	r0,r0,HID0_ICE
		xori	r0,r0,HID0_ICE
		isync	
		mtspr	HID0,r0

		mr	r4,r3

		bl User

		b	.DoneCache

.ICACHEINV:	mr.	r5,r5		
		beq-	.ICACHEINVALL
		mr.	r6,r6
		beq-	.ICACHEINVALL
		mr	r4,r5
		mr	r5,r6
		
		add	r5,r5,r4
		loadreg	r0,0xffffffe0
		and	r4,r4,r0
		addi	r5,r5,31
		and	r5,r5,r0
		sub	r5,r5,r4
		rlwinm	r5,r5,27,5,31
		mtctr	r5
.Invalidate:	icbi	r0,r4
		addi	r4,r4,L1_CACHE_LINE_SIZE
		bdnz+	.Invalidate
		isync	
		b	.DoneCache

.ICACHEINVALL:  bl Super

		b	.Mojo1					#Some L1 mojo

.Mojo2:		mfspr	r0,HID0
		ori	r0,r0,HID0_ICFI
		mtspr	HID0,r0
		xori	r0,r0,HID0_ICFI
		mtspr	HID0,r0
		isync	
		b 	.Mojo3

.Mojo1:		b 	.Mojo2
		
.Mojo3:		mr	r4,r3

		bl User

		b	.DoneCache

.DCACHEFLUSH:	mr.	r5,r5
		beq-	.DCACHEFLUSHALL
		mr.	r6,r6
		beq-	.DCACHEFLUSHALL
		
		lbz	r29,DState(r30)
		mr.	r29,r29
		bne	.DoneCache

		lbz	r29,DLockState(r30)
		mr.	r29,r29
		bne	.DoneCache

		mr	r4,r5
		mr	r5,r6

		add	r5,r5,r4
		loadreg	r0,0xffffffe0
		and	r4,r4,r0
		addi	r5,r5,31
		and	r5,r5,r0
		sub	r5,r5,r4
		rlwinm	r5,r5,27,5,31		
		mtctr	r5
		
.Flush:		dcbf	r0,r4
		addi	r4,r4,L1_CACHE_LINE_SIZE
		bdnz+	.Flush
		sync
			
		b	.DoneCache

.TOGGLEDFLUSH:	lbz	r29,DoDFlushAll(r30)
		extsb	r29,r29
		not	r29,r29
		stb	r29,DoDFlushAll(r30)
		b	.DoneCache

.DCACHEFLUSHALL:
		lbz	r29,DState(r30)
		mr.	r29,r29
		bne	.DoneCache

		lbz	r29,DLockState(r30)
		mr.	r29,r29
		bne	.DoneCache

		mr	r3,r30

		bl FlushDCache

.DoneCache:	mtctr	r28

		lwz	r28,0(r13)
		lwz	r29,4(r13)
		lwz	r30,8(r13)
		lwz	r31,12(r13)
		addi	r13,r13,16
		
		epilog 'TOC'

#********************************************************************************************
#
#	void SetExcMMU(void) // Only from within Exception Handler (STUB)
#
#********************************************************************************************

SetExcMMU:
		prolog 228,'TOC'			#DUMMY pending better MMU support

		stwu	r31,-4(r13)

		li	r31,FSetExcMMU-FRun68K
		bl	DebugStartFunction

		lwz	r31,0(r13)
		addi	r13,r13,4

		epilog	'TOC'

#********************************************************************************************
#
#	void ClearExcMMU(void) // Only from within Exception Handler (STUB)
#
#********************************************************************************************

ClearExcMMU:	
		prolog 228,'TOC'			#DUMMY pending better MMU support

		stwu	r31,-4(r13)

		li	r31,FClearExcMMU-FRun68K
		bl	DebugStartFunction

		lwz	r31,0(r13)
		addi	r13,r13,4

		epilog	'TOC'

#********************************************************************************************
#
#	void ConfirmInterrupt(void)
#
#********************************************************************************************

ConfirmInterrupt:
		blr
		stw	r3,-12(r1)
		stw	r4,-8(r1)
		lis	r3,EUMBEPICPROC@h
		lwz	r4,0xa0(r3)			#Read IACKR to acknowledge it
		eieio
	
		lis	r3,EUMB@h
		lis	r4,0x100			#Clear IM0 bit to clear interrupt
		stw	r4,0x100(r3)
		eieio

		li	r4,0
		lis	r3,EUMBEPICPROC@h
		stw	r4,0xb0(r3)			#Write 0 to EOI to End Interrupt

		lwz	r4,-8(r1)
		lwz	r3,-12(r1)
		blr

#********************************************************************************************
#
#	void InsertPPC(list, node, nodepredecessor) // r4,r5,r6
#
#********************************************************************************************

InsertPPC:	mr.	r6,r6
		beq-	.NoPred
		lwz	r3,0(r6)
		mr.	r3,r3
		beq-	.Just1
		stw	r3,0(r5)
		stw	r6,4(r5)
		stw	r5,4(r3)
		stw	r5,0(r6)
		b	.E1
.Just1:		stw	r6,0(r5)
		lwz	r3,4(r6)
		stw	r3,4(r5)
		stw	r5,4(r6)
		stw	r5,0(r3)
		b	.E1
.NoPred:	lwz	r3,0(r4)			#Same as AddHeadPPC
		stw	r5,0(r4)
		stw	r3,0(r5)
		stw	r4,4(r5)
		stw	r5,4(r3)
.E1:		blr	

#********************************************************************************************
#
#	void AddHeadPPC(list, node) // r4,r5
#
#********************************************************************************************

AddHeadPPC:	lwz	r3,0(r4)
		stw	r5,0(r4)
		stw	r3,0(r5)
		stw	r4,4(r5)
		stw	r5,4(r3)
		blr	

#********************************************************************************************
#
#	void AddTailPPC(list, node) // r4,r5
#
#********************************************************************************************

AddTailPPC:	addi	r4,r4,4
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
		blr	

#********************************************************************************************
#
#	void RemovePPC(node) // r4
#
#********************************************************************************************

RemovePPC:	lwz	r3,0(r4)
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)
		blr	

#********************************************************************************************
#
#	node = RemHeadPPC(list) // r3=r4
#
#********************************************************************************************

RemHeadPPC:	lwz	r5,0(r4)
		lwz	r3,0(r5)
		mr.	r3,r3
		beq-	.HeadListEmpty
		stw	r3,0(r4)
		stw	r4,4(r3)
		mr	r3,r5
.HeadListEmpty:	blr	

#********************************************************************************************
#
#	node = RemTailPPC(list) // r3=r4
#
#********************************************************************************************

RemTailPPC:	lwz	r3,8(r4)
		lwz	r5,4(r3)
		mr.	r5,r5
		beq-	.TailListEmpty
		stw	r5,8(r4)
		addi	r4,r4,4
		stw	r4,0(r5)
.TailListEmpty:	blr	

#********************************************************************************************
#
#	void EnqueuePPC(list, node) // r4,r5
#
#********************************************************************************************

EnqueuePPC:	lbz	r3,LN_PRI(r5)
		extsb	r3,r3
		lwz	r6,0(r4)
.Loop1:		mr	r4,r6
		lwz	r6,0(r4)
		mr.	r6,r6
		beq-	.Link1
		lbz	r7,LN_PRI(r4)
		extsb	r7,r7
		cmpw	r3,r7
		ble+	.Loop1
.Link1:		lwz	r3,4(r4)
		stw	r5,4(r4)		
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
		blr

#********************************************************************************************
#
#	Support: void InsertOnPri(List, Task) // r4,r5
#
#********************************************************************************************

InsertOnPri:	
		prolog	228,'TOC'

		stwu	r8,-4(r13)
		stwu	r7,-4(r13)
		stwu	r6,-4(r13)
		stwu	r5,-4(r13)
		stwu	r4,-4(r13)
		stwu	r3,-4(r13)

		lwz	r8,TASKPPC_POWERPCBASE(r5)
		lwz	r3,TASKPPC_PRIORITY(r5)
		lwz	r6,TASKPPC_PRIOFFSET(r5)
		add	r3,r3,r6
		lwz	r7,LowActivityPrio(r8)
		lwz	r6,LowActivityPrioOffset(r8)
		add	r6,r6,r7
		cmpw	r3,r6
		blt-	.LowerPri
		
		mr	r3,r6
		lwz	r0,TASKPPC_PRIORITY(r5)
		sub	r0,r3,r0
		stw	r0,TASKPPC_PRIOFFSET(r5)
.LowerPri:	lwz	r6,0(r4)
.CompareNode:	mr	r4,r6
		lwz	r6,0(r4)
		mr.	r6,r6
		beq-	.GoExit
		
		lwz	r0,TASKPPC_FLAGS(r4)
		rlwinm.	r0,r0,(32-TASKPPC_EMULATOR),31,31
		beq-	.NoEmul
		mr	r4,r6
		b	.GoExit
		
.NoEmul:	lwz	r7,TASKPPC_PRIORITY(r4)
		lwz	r0,TASKPPC_PRIOFFSET(r4)
		add	r7,r7,r0
		cmpw	r3,r7
		ble+	.CompareNode
		
.GoExit:	lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)

		lwz	r3,0(r13)
		lwz	r4,4(r13)
		lwz	r5,8(r13)
		lwz	r6,12(r13)
		lwz	r7,16(r13)
		lwz	r8,20(r13)
		addi	r13,r13,24
		
		epilog	'TOC'

#********************************************************************************************
#
#	node = FindNamePPC(list, name) // r3=r4,r5
#
#********************************************************************************************

FindNamePPC:			
		lwz	r3,0(r4)				#Think this is bugged in WarpOS
		lwz	r3,0(r3)
		mr.	r3,r3
		beq-	.ExitFindName
		subi	r8,r5,1
		lwz	r3,0(r4)
.Loop2:		mr	r6,r3
		lwz	r3,0(r6)
		mr.	r3,r3
		beq-	.ExitFindName
		lwz	r4,LN_NAME(r6)
		mr	r5,r8
		subi	r4,r4,1
.Loop3:		lbzu	r0,1(r4)
		lbzu	r7,1(r5)
		cmplw	r0,r7
		bne+	.Loop2
		lbz	r0,0(r4)
		mr.	r0,r0
		bne+	.Loop3
		mr	r3,r6
.ExitFindName:	blr	

#********************************************************************************************
#
#	void ResetPPC(void)	// Dummy (as in powerpc.library)
#
#********************************************************************************************

ResetPPC:
		blr
		

#********************************************************************************************
#
#	void NewListPPC(List)	// r4
#
#********************************************************************************************

NewListPPC:		
		stw	r4,8(r4)
		lis	r0,0
		nop	
		stwu	r0,4(r4)
		stw	r4,-4(r4)
		blr	

#********************************************************************************************
#
#	void AddTimePPC(Dest, Source)	// r4,r5
#
#********************************************************************************************

AddTimePPC:
		lwz	r6,TV_MICRO(r4)
		lwz	r7,TV_MICRO(r5)
		add	r6,r6,r7
		loadreg	r0,1000000
		li	r3,0
		cmplw	r6,r0
		blt-	.Link2
		sub	r6,r6,r0
		li	r3,1
.Link2:		lwz	r8,TV_SECS(r4)
		lwz	r9,TV_SECS(r5)
		add	r8,r8,r9
		add	r8,r8,r3
		stw	r6,TV_MICRO(r4)
		stw	r8,TV_SECS(r4)
		blr	

#********************************************************************************************
#
#	void SubTimePPC(Dest, Source)	// r4,r5
#
#********************************************************************************************

SubTimePPC:
		lwz	r6,TV_MICRO(r4)
		lwz	r7,TV_MICRO(r5)
		sub	r6,r6,r7
		li	r3,0
		mr.	r6,r6
		bge-	.Link3
		loadreg	r0,1000000
		add	r6,r6,r0
		li	r3,1
.Link3:		lwz	r8,TV_SECS(r4)
		lwz	r9,TV_SECS(r5)
		sub	r8,r8,r9
		sub	r8,r8,r3
		stw	r6,TV_MICRO(r4)
		stw	r8,TV_SECS(r4)
		blr	


#********************************************************************************************
#
#	Result = CmpTimePPC(Dest, Source)	// r3=r4,r5
#
#********************************************************************************************

CmpTimePPC:
		lwz	r6,TV_SECS(r4)
		lwz	r7,TV_SECS(r5)
		cmplw	r6,r7
		blt-	.Link5
		bgt-	.Link4
		lwz	r8,TV_MICRO(r4)
		lwz	r9,TV_MICRO(r5)
		cmplw	r8,r9
		blt-	.Link5
		bgt-	.Link4
		li	r3,CMP_EQUAL
		b	.E5
.Link4:		li	r3,CMP_DESTGREATER
		b	.E5
.Link5:		li	r3,CMP_DESTLESS
.E5:		blr

#********************************************************************************************
#
#	MemBlock = AllocVecPPC(PowerPCBase, Length, Null, Alignment)	// r3=r3,r4,r6 (r5 is ignored for now)
#
#********************************************************************************************

AllocVecPPC:	prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)
		
		li	r31,FAllocVecPPC-FRun68K
		bl	DebugStartFunction
				
		mr	r31,r6
		mr	r30,r5
		mr	r29,r4
		mr	r26,r3

		lwz	r3,ThisPPCProc(r26)
		la	r4,TASKPPC_TASKPOOLS(r3)

		lwz	r5,MLH_HEAD(r4)
.NxtPool:	lwz	r6,LN_SUCC(r5)
		subi	r27,r5,36
		mr.	r6,r6
		bne	.AListNotEmpty
		
		
		loadreg	r4,MEMF_PUBLIC|MEMF_PPC|MEMF_REVERSE
#		or	r4,r4,r30
		lis	r5,0x8						#512kb
		lis	r6,0x1						#64kb
		mr	r3,r26
		
		bl CreatePoolPPC
		
		mr.	r27,r3
		beq	.PAllocErr
		
		b	.GotPool
		
.AListNotEmpty:	lis	r4,0x1
		lwz	r5,POOL_TRESHSIZE(r27)
		cmpw	r4,r5
		beq	.GotPool
		
		mr	r5,r6
		b	.NxtPool

.GotPool:	mr.	r31,r31
		beq	.Make32

		andi.	r6,r31,0x1f
		beq	.AtLeast32
		
.Make32:	li	r6,32
		b	.DoneAlign

.AtLeast32:	subi	r7,r31,1
		cntlzw	r6,r7
		subfic	r5,r6,32
		li	r6,1
		rlwnm	r6,r6,r5,0,31					#Round down (alignment)

.DoneAlign:	mr	r4,r27						#Pool to r4
		add	r5,r6,r29					#Room for size & pool
		addi	r5,r5,32
		mr	r29,r5
		mr	r28,r6
		mr	r3,r26
		
		bl AllocPooledPPC

		mr.	r4,r3
		beq	.PAllocErr

		addi	r5,r28,31
		add	r3,r4,r5
		neg	r6,r28
		and	r3,r3,r6

		lis	r28,MEMF_CLEAR@h
		and.	r30,r30,r28
		beq	.DoNotClear

		mfctr	r31
		mtctr	r29
		li	r0,0
		subi	r28,r4,1
		
.ClearBlock:	stbu	r0,1(r28)
		bdnz	.ClearBlock
		
		mtctr	r31

.DoNotClear:	stw	r29,-4(r3)					#Remember size
		stw	r27,-8(r3)					#Remember pool
		stw	r4,-12(r3)					#Remember block
		
.PAllocErr:	mr	r30,r26
		li	r31,FAllocVecPPC-FRun68K
		bl	DebugEndFunction

		lwz	r26,0(r13)
		lwz	r27,4(r13)
		lwz	r28,8(r13)
		lwz	r29,12(r13)
		lwz	r30,16(r13)
		lwz	r31,20(r13)
		addi	r13,r13,24
		
		epilog	'TOC'
		
#********************************************************************************************
#
#	Result = FreeVecPPC(PowerPCBase, MemBlock)	// r3=r3,r4
#
#********************************************************************************************

FreeVecPPC:	prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		
		li	r31,FFreeVecPPC-FRun68K
		bl	DebugStartFunction
		
		mr	r30,r3
		mr.	r31,r4
		beq	.PFreeError

		lwz	r5,-12(r31)				#Original MemBlock
		lwz	r4,-8(r31)				#Pool
		lwz	r6,-4(r31)				#Size
		
		bl FreePooledPPC

.PFreeError:	li	r31,FFreeVecPPC-FRun68K
		bl	DebugEndFunction

		lwz	r30,0(r13)		
		lwz	r31,4(r13)
		addi	r13,r13,8

		epilog	'TOC'


#********************************************************************************************
#
#	Support: MemBlock = AllocVec68K(PowerPCBase, Length)	// r3=r3,r4
#
#********************************************************************************************

AllocVec68K:	prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r9,-4(r13)
		stwu	r8,-4(r13)

		mr	r29,r3
		mr.	r3,r4
		beq	.AllocErr

		mr	r31,r4

		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC|MEMF_REVERSE	#Fixed for now
		
		addi	r8,r4,0x38					#d0
		mr	r9,r5						#d1
		lwz	r4,sonnet_SysBase(r29)
		li	r5,_LVOAllocVec
		mr	r3,r29
			
		bl Run68KLowLevel
										
		mr.	r4,r3
		beq	.AllocErr

		addi	r3,r3,0x27
		loadreg	r5,-32
		and.	r3,r3,r5
		
		stw	r4,-4(r3)
		
		li	r4,CACHE_DCACHEINV
		mr	r5,r3
		mr	r30,r3
		mr	r6,r31
		mr	r3,r29
		
		bl SetCache
		
		mr	r3,r30
		
.AllocErr:	lwz	r8,0(r13)
		lwz	r9,4(r13)
		lwz	r29,8(r13)
		lwz	r30,12(r13)
		lwz	r31,16(r13)
		addi	r13,r13,20
		
		epilog 'TOC'

#********************************************************************************************
#
#	Support: Result = FreeVec68K(PowerPCBase, MemBlock)	// r3=r3,r4	#This call is asynchronous
#
#********************************************************************************************		

FreeVec68K:	prolog 228,'TOC'

		stwu	r7,-4(r13)

		lwz	r7,-4(r4)					#a1
		lwz	r4,sonnet_SysBase(r3)
		li	r5,_LVOFreeVec

		bl Run68KLowLevel

		li	r3,MEMERR_SUCCESS

		lwz	r7,0(r13)
		addi	r13,r13,4
		
		epilog 'TOC'

#********************************************************************************************
#
#	void  GetInfo(PowerPCBase, PPCInfoTagList)	// r3,r4
#
#********************************************************************************************

GetInfo:	
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		mfctr	r31
		stwu	r31,-4(r13)
		stwu	r4,-4(r13)
		
		li	r31,FGetInfo-FRun68K
		bl	DebugStartFunction
		
		mr	r30,r3

		bl Super

		mr	r4,r3

		mfspr	r3,HID0
		stw	r3,sonnet_CPUHID0(r30)
		mfspr	r3,SDR1
		stw	r3,sonnet_CPUSDR1(r30)
		mfl2cr	r3
		stw	r3,sonnet_L2STATE(r30)
		
		bl User	

.NextInList:	mr	r4,r13
		
		bl NextTagItemPPC

		mr.	r4,r3
		beq	.NoTags
		lwz	r3,0(r4)		
		rlwinm	r7,r3,0,0,19
		loadreg	r8,0x80102000
		cmpw	r7,r8		
		beq+	.UserTag
		b	.NextInList
		
.NoTags:	li	r31,FGetInfo-FRun68K
		bl	DebugEndFunction

		lwzu	r31,4(r13)
		mtctr	r31
		lwzu	r30,4(r13)
		lwzu	r31,4(r13)
		addi	r13,r13,4
		
		epilog 'TOC'
		
#********************************************************************************************

.UserTag:	li	r6,1
		rlwinm.	r7,r3,0,27,31
		beq	.INFO_CPU		
		subf.	r7,r6,r7
		beq	.INFO_PVR
		subf.	r7,r6,r7
		beq	.INFO_ICACHE
		subf.	r7,r6,r7
		beq	.INFO_DCACHE
		subf.	r7,r6,r7
		beq	.INFO_PAGETABLE
		subf.	r7,r6,r7
		beq	.INFO_TABLESIZE
		subf.	r7,r6,r7
		beq	.INFO_BUSCLOCK
		subf.	r7,r6,r7
		beq	.INFO_CPUCLOCK
		subf.	r7,r6,r7
		beq	.INFO_CPULOAD
		subf.	r7,r6,r7
		beq	.INFO_SYSTEMLOAD
		subf.	r7,r6,r7
		beq	.INFO_L2CACHE
		subf.	r7,r6,r7
		beq	.INFO_L2WT
		subf.	r7,r6,r7
		beq	.INFO_L2SIZE
		b	.NextInList
		
.INFO_CPULOAD:	lwz	r7,CPULoad(r30)
		stw	r7,4(r4)
		b	.NextInList	

.INFO_SYSTEMLOAD:
		lwz	r7,SystemLoad(r30)
		stw	r7,4(r4)
		b	.NextInList

.INFO_CPU:	lwz	r7,sonnet_CPUInfo(r30)
		rlwinm	r7,r7,16,28,31
		andi.	r7,r7,4
		beq+	.G3
		loadreg r7,CPUF_G4
		b	.GotCPU		
.G3:		loadreg	r7,CPUF_G3
		b	.GotCPU
		
.INFO_PVR:	lwz	r7,sonnet_CPUInfo(r30)
.GotCPU:	stw	r7,4(r4)
		b	.NextInList
		
.INFO_ICACHE:	lwz	r8,sonnet_CPUHID0(r30)
		rlwinm	r8,r8,19,29,31
.ReUse:		andi.	r8,r8,5
		li	r7,1
		cmpwi	r8,4
		beq	.StoreTag
		addi	r7,r7,1
		cmpwi	r8,5
		beq	.StoreTag
		addi	r7,r7,2
		cmpwi	r8,0
		beq	.StoreTag
		addi	r7,r7,4
		b	.StoreTag

.INFO_DCACHE:	lwz	r8,sonnet_CPUHID0(r30)
		rlwinm	r8,r8,20,29,31
		b	.ReUse
		
.INFO_PAGETABLE:
		lwz	r7,sonnet_CPUSDR1(r30)
		rlwinm	r7,r7,0,0,15
		b 	.StoreTag
		
.INFO_TABLESIZE:
		lwz	r8,sonnet_CPUSDR1(r30)
		li	r7,0
		rlwinm.	r8,r8,0,23,31
		beq	.NoShift
.CntShift:	add	r7,r7,r6
		srw.	r8,r8,r6
		bne	.CntShift
.NoShift:	addi	r7,r7,6
		mr	r8,r7
		li	r7,1
		rlwnm	r7,r7,r8,0,31		
		b	.StoreTag
		
.INFO_BUSCLOCK:	loadreg	r7,SonnetBusClock
.StoreTag:	stw	r7,4(r4)
		b	.NextInList
		
.INFO_CPUCLOCK:	lwz	r7,sonnet_CPUSpeed(r30)
		b	.StoreTag

.INFO_L2CACHE:	lwz	r7,sonnet_L2STATE(r30)
		rlwinm	r7,r7,1,31,31
		b	.StoreTag
		
.INFO_L2WT:	lwz	r7,sonnet_L2STATE(r30)
		rlwinm	r7,r7,13,31,31
		b	.StoreTag
		
.INFO_L2SIZE:	lwz	r7,sonnet_CurrentL2Size(r30)
		b	.StoreTag

#********************************************************************************************
#
#	void  GetSysTimePPC(TimeVal)	// r4
#
#********************************************************************************************

GetSysTimePPC:	
		prolog 228,'TOC'
		
		stwu	r7,-4(r13)
		stwu	r6,-4(r13)
		stwu	r31,-4(r13)
		
		li	r31,FGetSysTimePPC-FRun68K
		bl	DebugStartFunction
		
		mr	r6,r4
		loadreg	r5,SonnetBusClock
		rlwinm	r5,r5,30,2,31
.Loop5:		mftbu	r3
		mftbl	r4
		mftbu	r7
		cmplw	r7,r3
		bne+	.Loop5
		bl	.Link17
		stw	r3,TV_SECS(r6)
		mullw	r7,r5,r3
		sub	r7,r4,r7
		loadreg	r0,1000000
		mullw	r4,r0,r7
		mulhw	r3,r0,r7
		bl	.Link17
		stw	r3,TV_MICRO(r6)
		
		lwz	r31,0(r13)
		lwzu	r6,4(r13)
		lwzu	r7,4(r13)
		addi	r13,r13,4
		
		epilog 'TOC'
		
#********************************************************************************************

.Link17:	mfctr	r0
		stwu	r0,-4(r13)
		stwu	r6,-4(r13)
		stwu	r5,-4(r13)
		stwu	r4,-4(r13)
		li	r0,32
		mtctr	r0
		li	r6,0
.Loop4:		mr.	r3,r3
		bge-	.Link18

		addc	r4,r4,r4
		adde	r3,r3,r3
		add	r6,r6,r6
		b	.Link19

.Link18:	addc	r4,r4,r4
		adde	r3,r3,r3
		add	r6,r6,r6
		cmplw	r5,r3
		bgt-	.Link20

.Link19:	sub.	r3,r3,r5
		addi	r6,r6,1
.Link20:	bdnz+	.Loop4

		mr	r3,r6
		lwz	r4,0(r13)
		lwz	r5,4(r13)
		lwz	r6,8(r13)
		addi	r13,r13,12
		lwz	r0,0(r13)
		addi	r13,r13,4
		mtctr	r0		
		blr

#********************************************************************************************
#
#	tag = NextTagItemPPC(tagItemPtr) // r3=r4
#
#********************************************************************************************

NextTagItemPPC:
		lwz	r3,0(r4)
		mr.	r3,r3
		beq-	.EndTag
.NextTag:	lwz	r5,0(r3)
		mr.	r5,r5
		blt-	.GotTag
		beq-	.NoTag
		cmplwi	r5,3
		bgt-	.GotTag
		cmplwi	r5,2
		blt-	.IgnoreTag
		beq-	.ChainTag

		lwz	r5,4(r3)			#Skip tags
		rlwinm	r5,r5,3,0,28
		addi	r5,r5,8
		add	r3,r3,r5
		b	.NextTag

.ChainTag:	lwz	r3,4(r3)
		mr.	r3,r3
		bne+	.NextTag
		stw	r3,0(r4)
		b	.EndTag

.IgnoreTag:	addi	r3,r3,8
		b	.NextTag
			
.GotTag:	addi	r5,r3,8
		stw	r5,0(r4)
		b	.EndTag
			
.NoTag:		li	r3,0
		stw	r3,0(r4)
.EndTag:	blr	

#********************************************************************************************
#
#	value = GetTagDataPPC(tagValue, defaultVal, taglist) // r3=r4,r5,r6
#
#********************************************************************************************		
		
GetTagDataPPC:	
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		
		mr	r31,r5
		mr	r5,r6
		
		bl FindTagItemPPC
		
		mr.	r3,r3
		beq-	.NoTagFound
		lwz	r3,4(r3)
		b	.Done
		
.NoTagFound:	mr	r3,r31
.Done:		lwz	r31,0(r13)
		addi	r13,r13,4

		epilog 'TOC'


#********************************************************************************************
#
#	value = FindTagItemPPC(tagValue, taglist) // r3=r4,r5
#
#********************************************************************************************		

FindTagItemPPC:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		mr	r31,r4
		stwu	r5,-4(r13)
.TagLoop2:	mr	r4,r13
		
		bl NextTagItemPPC
	
		mr.	r3,r3
		beq-	.Done2
		lwz	r4,0(r3)
		cmplw	r4,r31
		bne+	.TagLoop2
		
.Done2:		addi	r13,r13,4
		lwz	r31,0(r13)
		addi	r13,r13,4
		
		epilog 'TOC'

#********************************************************************************************
#
#	Support: void FlushDCache(PowerPCBase) // r3
#
#********************************************************************************************

FlushDCache:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)
		
		mfctr	r28
		mr	r30,r3

.WLFlush:	la	r4,sonnet_Atomic(r30)
		bl 	AtomicTest
		
		mr.	r3,r3
		beq+	.WLFlush
		
		bl Super
		
		bl DisableIntPPC
		
		mfdec	r26
		lis	r29,0xf00
		mtdec	r29
		
		li	r29,0x400			#L1 Cache size/Cache line size
		lwz	r27,sonnet_CurrentL2Size(r30)
		
		lbz	r4,DoDFlushAll(r30)
		mr.	r4,r4
		beq	.CompleteFlush
		li	r27,0		
		
.CompleteFlush:	li	r4,5
		srw	r27,r27,r4
		add	r29,r29,r27			#Add with the L2 Cache size/Cache line size
		mr	r27,r29
		
		mtctr	r29
		
		lwz	r29,sonnet_MemSize(r30)
		subis	r29,r29,0x40
		lwz	r4,sonnet_SonnetBase(r30)		
		add	r4,r4,r29
		mr	r31,r4
	
.FillCache:	lwz	r29,0(r4)
		addi	r4,r4,L1_CACHE_LINE_SIZE
		bdnz+	.FillCache
	
		mr	r4,r31
		mtctr	r27
		
.FlushCache:	dcbf	r0,r4
		addi	r4,r4,L1_CACHE_LINE_SIZE
		bdnz+	.FlushCache
		
		sync
		
		mtdec	r26

		bl EnableIntPPC

		mr	r4,r3
		
		bl User

		mtctr	r28		
		la	r4,sonnet_Atomic(r30)
		
		bl AtomicDone
		
		lwz	r26,0(r13)
		lwz	r27,4(r13)
		lwz	r28,8(r13)
		lwz	r29,12(r13)
		lwz	r30,16(r13)
		lwz	r31,20(r13)
		addi	r13,r13,24
		
		epilog 'TOC'

#********************************************************************************************
#
#	message = AllocXMsgPPC(PowerPCBase, bodysize, replyport) // r3=r3,r4,r5
#
#********************************************************************************************

AllocXMsgPPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

		li	r31,FAllocXMsgPPC-FRun68K
		bl	DebugStartFunction

		mr	r29,r3

		addi	r31,r4,MN_SIZE+31
		loadreg	r30,-32
		and	r4,r31,r30
		mr	r30,r5
		mr	r31,r4
		
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,32

		bl AllocVecPPC

		mr.	r3,r3
		beq-	.NoMaam
		stw	r30,MN_REPLYPORT(r3)
		sth	r31,MN_LENGTH(r3)

.NoMaam:	mr	r30,r29
		li	r31,FAllocXMsgPPC-FRun68K
		bl	DebugEndFunction

		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12

		epilog 'TOC'

#********************************************************************************************
#
#	void FreeXMsgPPC(message) // r4
#
#********************************************************************************************		

FreeXMsgPPC:
		prolog 228,'TOC'
		
		bl FreeVecPPC
		
		epilog 'TOC'		

#********************************************************************************************
#
#	MsgPortPPC = CreateMsgPortPPC(PowerPCBase) // r3=r3
#
#********************************************************************************************

CreateMsgPortPPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		
		li	r31,FCreateMsgPortPPC-FRun68K
		bl	DebugStartFunction
		
		mr	r31,r3
		li	r4,100
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,32
		
		bl AllocVec68K
	
		mr.	r3,r3
		beq-	.NoMsgMem
		mr	r30,r3
		addi	r4,r30,MP_PPC_INTMSG
		stw	r4,LH_TAILPRED(r4)
		li	r0,0
		stwu	r0,LH_TAIL(r4)
		stwu	r4,LH_HEAD-4(r4)
		addi	r4,r30,MP_MSGLIST
		stw	r4,LH_TAILPRED(r4)
		li	r0,0
		stwu	r0,LH_TAIL(r4)
		stwu	r4,LH_HEAD-4(r4)
		li	r4,-1
		mr	r3,r31
		
		bl AllocSignalPPC
	
		cmpwi	r3,-1
		beq-	.NoSigFree
		stb	r3,MP_SIGBIT(r30)
		addi	r4,r30,MP_PPC_SEM
		mr	r3,r31
		
		bl InitSemaphorePPC

		cmpwi	r3,SSPPC_SUCCESS
		bne-	.NoSemMem
		lwz	r3,ThisPPCProc(r31)
		stw	r3,MP_SIGTASK(r30)
		li	r0,PA_SIGNAL
		stb	r0,MP_FLAGS(r30)
		li	r0,NT_MSGPORTPPC
		stb	r0,LN_TYPE(r30)
		mr	r4,r30
		b	.HaveAll

.NoSemMem:	lbz	r4,MP_SIGBIT(r30)
		mr	r3,r31

		bl FreeSignalPPC

.NoSigFree:	mr	r4,r30
		mr	r3,r31

		bl FreeVec68K
	
.NoMsgMem:  	li	r4,0
.HaveAll:	mr	r3,r4

		mr	r30,r31
		li	r31,FCreateMsgPortPPC-FRun68K
		bl	DebugEndFunction

		lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		epilog 'TOC'

#********************************************************************************************
#
#	void DeleteMsgPortPPC(PowerPCBase, MsgPortPPC) // r3,r4
#
#********************************************************************************************

DeleteMsgPortPPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		
		li	r31,FDeleteMsgPortPPC-FRun68K
		bl	DebugStartFunction

		mr	r30,r3
		mr.	r31,r4
		beq-	.NoPortDef

		addi	r4,r31,MP_PPC_SEM

		bl FreeSemaphorePPC

		lbz	r4,MP_SIGBIT(r31)
		mr	r3,r30
		
		bl FreeSignalPPC

		mr	r4,r31
		mr	r3,r30
		
		bl FreeVec68K

.NoPortDef:	li	r31,FDeleteMsgPortPPC-FRun68K
		bl	DebugEndFunction

		lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8

		epilog 'TOC'

#********************************************************************************************
#
#	void FreeSignalPPC(PowerPCBase, signalNum) // r3,r4
#
#********************************************************************************************

FreeSignalPPC:
		prolog 228,'TOC'

		extsb	r4,r4
		cmpwi	r4,-1
		beq-	.NoSigDef

		lwz	r5,ThisPPCProc(r3)
		lwz	r3,TC_SIGALLOC(r5)
		li	r6,1
		slw	r6,r6,r4
		andc	r3,r3,r6
		stw	r3,TC_SIGALLOC(r5)
		lwz	r3,TASKLINK_SIG(r5)
		andc	r3,r3,r6
		stw	r3,TASKLINK_SIG(r5)

.NoSigDef:	epilog 'TOC'

#********************************************************************************************
#
#	signalnum = AllocSignalPPC(PowerPCBase, signalNum) // r3=r3,r4
#
#********************************************************************************************

AllocSignalPPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		
		li	r31,FAllocSignalPPC-FRun68K
		bl	DebugStartFunction
		
		mr	r31,r3
		
		extsb	r4,r4

		lwz	r5,ThisPPCProc(r3)
		lwz	r3,TC_SIGALLOC(r5)
		cmpwi	r4,-1
		beq-	.RandomSig

		li	r6,1
		slw	r6,r6,r4
		and.	r0,r6,r3
		bne-	.NoSigHere

		b	.GetSig

.RandomSig:	lis	r6,0x8000
		li	r4,0x1f
.NxtSig:	and.	r7,r3,r6
		beq-	.GetSig
		subi	r4,r4,1
		rlwinm.	r6,r6,31,1,31
		bne+	.NxtSig

.NoSigHere:	li	r3,-1
		b	.EndSig

.GetSig:	or	r3,r3,r6
		stw	r3,TC_SIGALLOC(r5)
		stwu	r4,-4(r13)
		lwz	r3,TASKLINK_SIG(r5)
		or	r3,r3,r6
		stw	r3,TASKLINK_SIG(r5)
		
.WaitingLine:	la	r4,sonnet_Atomic(r31)

		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitingLine

		lwz	r7,TC_SIGRECVD(r5)
		andc	r7,r7,r6
		stw	r7,TC_SIGRECVD(r5)
		lwz	r7,TC_SIGWAIT(r5)
		andc	r7,r7,r6
		stw	r7,TC_SIGWAIT(r5)

		la	r4,sonnet_Atomic(r31)
		
		bl AtomicDone
		
		lwz	r3,0(r13)
		addi	r13,r13,4
		
.EndSig:	lwz	r31,0(r13)
		addi	r13,r13,4

		epilog 'TOC'	

#********************************************************************************************
#
#	Support: result =  AtomicTest(TestLocation) // r3=r4
#
#********************************************************************************************

AtomicTest:	lwzx	r0,r0,r4
		cmpwi	r0,0
		bne-	.AtomicOn
		lwarx	r0,r0,r4
		cmpwi	r0,0
		bne-	.AtomicOn
		li	r0,-1
		stwcx.	r0,r0,r4
		bne-	.AtomicOn
		li	r3,-1
		b	.AtomicOff

.AtomicOn:	li	r3,0

.AtomicOff:	isync
		blr

#********************************************************************************************
#
#	Support: void AtomicDone(TestLocation) // r4
#
#********************************************************************************************

AtomicDone:	
		sync
		li	r0,0
		stw	r0,0(r4)
		blr
		
#********************************************************************************************
#
#	oldSignals = SetSignalPPC(PowerPCBase, newSignals. signalMask) // r3=r3,r4,r5
#
#********************************************************************************************

SetSignalPPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		
		li	r31,FSetSignalPPC-FRun68K
		bl	DebugStartFunction

		lwz	r6,ThisPPCProc(r3)

		mr	r29,r3
		mr	r30,r4
		
.WaitingLine2:	la	r4,sonnet_Atomic(r29)

		bl AtomicTest
		
		mr.	r3,r3
		beq+	.WaitingLine2

		lwz	r31,TC_SIGRECVD(r6)
		and	r30,r30,r5
		andc	r7,r31,r5
		or	r30,r30,r7
		stw	r30,TC_SIGRECVD(r6)
		
		la	r4,sonnet_Atomic(r29)
		
		bl AtomicDone

		mr	r3,r29
		mr	r4,r6
		li	r5,0

		bl CheckExcSignal

		mr	r3,r31

		mr	r30,r29
		li	r31,FSetSignalPPC-FRun68K
		bl	DebugEndFunction
		
		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12
		
		epilog 'TOC'

#********************************************************************************************
#
#	TaskPtr = LockTaskList(PowerPCBase) // r3=r3
#
#********************************************************************************************

LockTaskList:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		
		mr	r31,r3

		lwz	r4,sonnet_TaskListSem(r3)

		bl ObtainSemaphorePPC

		lwz	r3,LIST_ALLTASKS(r31)

		lwz	r31,0(r13)
		addi	r13,r13,4
		
		epilog 'TOC'

#********************************************************************************************
#
#	void UnLockTaskList(PowerPCBase) // r3
#
#********************************************************************************************

UnLockTaskList:
		prolog 228,'TOC'
		
		lwz	r4,sonnet_TaskListSem(r3)

		bl ReleaseSemaphorePPC

		epilog 'TOC'

#********************************************************************************************
#
#	status = InitSemaphorePPC(PowerPCBase, SignalSemaphorePPC) // r3=r3,r4
#
#********************************************************************************************

InitSemaphorePPC:
		prolog 228,'TOC'
				
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		li	r31,FInitSemaphorePPC-FRun68K
		bl	DebugStartFunction

		mr	r31,r4
		mr	r30,r3

		addi	r5,r31,SS_WAITQUEUE
		stw	r5,8(r5)
		li	r0,0
		stwu	r0,4(r5)
		stwu	r5,-4(r5)
		li	r0,0
		stw	r0,SS_OWNER(r31)
		sth	r0,SS_NESTCOUNT(r31)
		li	r0,-1
		sth	r0,SS_QUEUECOUNT(r31)
		li	r4,32
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,32

		bl AllocVec68K		
		
		mr.	r3,r3
		beq-	.SemDone

		stw	r3,SSPPC_RESERVE(r31)
		li	r3,-1

.SemDone:	li	r31,FInitSemaphorePPC-FRun68K
		bl	DebugEndFunction

		lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		epilog 'TOC'

#********************************************************************************************
#
#	void FreeSemaphorePPC(PowerPCBase, SignalSemaphorePPC) // r3,r4
#
#********************************************************************************************

FreeSemaphorePPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)

		li	r31,FFreeSemaphorePPC-FRun68K
		bl	DebugStartFunction

		mr.	r4,r4
		beq-	.NoSemDef

		lwz	r4,SSPPC_RESERVE(r4)

		bl FreeVec68K

.NoSemDef:	lwz	r31,0(r13)
		addi	r13,r13,4
		
		epilog 'TOC'

#********************************************************************************************
#
#	void ObtainSemaphorePPC(PowerPCBase, SignalSemaphorePPC) // r3,r4
#
#********************************************************************************************

ObtainSemaphorePPC:
		prolog 228,'TOC'
				
		mfctr	r0
		stwu	r0,-4(r13)
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r12,-4(r13)
		stwu	r11,-4(r13)
		stwu	r10,-4(r13)
		stwu	r9,-4(r13)
		stwu	r8,-4(r13)
		stwu	r7,-4(r13)
		stwu	r6,-4(r13)
		stwu	r5,-4(r13)
		stwu	r4,-4(r13)
		stwu	r3,-4(r13)
		
		li	r31,FObtainSemaphorePPC-FRun68K
		bl	DebugStartFunction

		mr	r31,r3
		mr	r30,r4

.WaitRes:	la	r4,sonnet_Atomic(r31)

		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitRes
		lha	r5,SS_QUEUECOUNT(r30)
		addi	r5,r5,1
		sth	r5,SS_QUEUECOUNT(r30)
		extsh.	r0,r5
		bne-	.SemQ

		lwz	r3,ThisPPCProc(r31)
		stw	r3,SS_OWNER(r30)
		
		la	r4,sonnet_Atomic(r31)

		bl AtomicDone

		b	.Obtained

.SemQ:		lwz	r3,ThisPPCProc(r31)
		lwz	r4,SS_OWNER(r30)
		cmplw	r3,r4
		bne-	.SemNotFree

		la	r4,sonnet_Atomic(r31)

		bl AtomicDone

		b	.Obtained

.SemNotFree:	stwu	r29,-4(r13)
		mr	r29,r13
		subi	r13,r13,12
		subi	r5,r29,12
		stw	r3,8(r5)
		lwz	r4,TC_SIGRECVD(r3)
		ori	r4,r4,SIGF_SINGLE
		xori	r4,r4,SIGF_SINGLE
		stw	r4,TC_SIGRECVD(r3)
		addi	r4,r30,SS_WAITQUEUE
		
		bl AddTailPPC

		la	r4,sonnet_Atomic(r31)

		bl AtomicDone

		lis	r4,0
		ori	r4,r4,SIGF_SINGLE
		mr	r3,r31
		
		bl WaitPPC				#Gets signaled from other
							#ReleaseSemaphorePPC
		mr	r13,r29
		lwz	r29,0(r13)
		addi	r13,r13,4
		b	.DoneWait

.Obtained:	lha	r5,SS_NESTCOUNT(r30)		#Number of locks from current task
		addi	r5,r5,1
		sth	r5,SS_NESTCOUNT(r30)
		
.DoneWait:	lwz	r3,0(r13)
		lwz	r4,4(r13)
		lwz	r5,8(r13)
		lwz	r6,12(r13)
		lwz	r7,16(r13)
		lwz	r8,20(r13)
		lwz	r9,24(r13)
		lwz	r10,28(r13)
		lwz	r11,32(r13)
		lwz	r12,36(r13)
		lwz	r29,40(r13)
		lwz	r30,44(r13)
		lwz	r31,48(r13)
		addi	r13,r13,52
		lwz	r0,0(r13)
		addi	r13,r13,4
		mtctr	r0
		
		epilog 'TOC'

#********************************************************************************************
#
#	status = AttemptSemaphorePPC(PowerPCBase, SignalSemaphorePPC) // r3,r4
#
#********************************************************************************************

AttemptSemaphorePPC:
		prolog 228,'TOC'
		
		mfctr	r0
		stwu	r0,-4(r13)
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r12,-4(r13)
		stwu	r11,-4(r13)
		stwu	r10,-4(r13)
		stwu	r9,-4(r13)
		stwu	r8,-4(r13)
		stwu	r7,-4(r13)
		stwu	r6,-4(r13)
		stwu	r5,-4(r13)
		stwu	r4,-4(r13)

		li	r31,FAttemptSemaphorePPC-FRun68K
		bl	DebugStartFunction

		mr	r30,r4
		mr	r31,r3

.WaitRes2:	la	r4,sonnet_Atomic(r31)

		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitRes2
		
		lha	r5,SS_QUEUECOUNT(r30)
		addi	r5,r5,1
		lwz	r3,ThisPPCProc(r31)
		mr.	r5,r5
		beq-	.NoQueue
		lwz	r4,SS_OWNER(r30)
		cmplw	r3,r4
		beq-	.AmOwner
		li	r6,ATTEMPT_FAILURE
		b	.Occupied

.NoQueue:	stw	r3,SS_OWNER(r30)
.AmOwner:	sth	r5,SS_QUEUECOUNT(r30)
		lha	r5,SS_NESTCOUNT(r30)
		addi	r5,r5,1
		sth	r5,SS_NESTCOUNT(r30)
		li	r6,ATTEMPT_SUCCESS

.Occupied:	la	r4,sonnet_Atomic(r31)

		bl AtomicDone

		mr	r3,r6
		lwz	r4,0(r13)
		lwz	r5,4(r13)
		lwz	r6,8(r13)
		lwz	r7,12(r13)
		lwz	r8,16(r13)
		lwz	r9,20(r13)
		lwz	r10,24(r13)
		lwz	r11,28(r13)
		lwz	r12,32(r13)
		lwz	r30,36(r13)
		lwz	r31,40(r13)
		addi	r13,r13,44
		lwz	r0,0(r13)
		addi	r13,r13,4
		mtctr	r0
		
		epilog 'TOC'

#********************************************************************************************
#
#	void ReleaseSemaphorePPC(PowerPCBase, SignalSemaphorePPC) // r3,r4
#
#********************************************************************************************

ReleaseSemaphorePPC:
		prolog 228,'TOC'
		
		mfctr	r0
		stwu	r0,-4(r13)
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r12,-4(r13)
		stwu	r11,-4(r13)
		stwu	r10,-4(r13)
		stwu	r9,-4(r13)
		stwu	r8,-4(r13)
		stwu	r7,-4(r13)
		stwu	r6,-4(r13)
		stwu	r5,-4(r13)
		stwu	r4,-4(r13)
		stwu	r3,-4(r13)

		li	r31,FReleaseSemaphorePPC-FRun68K
		bl	DebugStartFunction

		mr	r28,r3
		mr	r31,r4

.WaitRes3:	la	r4,sonnet_Atomic(r28)

		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitRes3

		lha	r5,SS_NESTCOUNT(r31)
		subi	r5,r5,1
		sth	r5,SS_NESTCOUNT(r31)
		mr.	r5,r5
		beq-	.LastInLine

		blt-	.Error68k				#Error done by 68k

		lha	r5,SS_QUEUECOUNT(r31)
		subi	r5,r5,1
		sth	r5,SS_QUEUECOUNT(r31)

		la	r4,sonnet_Atomic(r28)

		bl AtomicDone

		b	.Released				#Actually not released
								#As current task has more locks
.LastInLine:	lis	r0,0
		nop			
		stw	r0,SS_OWNER(r31)
		lha	r5,SS_QUEUECOUNT(r31)
		subi	r5,r5,1
		sth	r5,SS_QUEUECOUNT(r31)
		mr.	r5,r5
		bge-	.NotLast

		la	r4,sonnet_Atomic(r28)

		bl AtomicDone

		b	.Released

.NotLast:	li	r0,1
		sth	r0,SSPPC_LOCK(r31)
		
		la	r4,sonnet_Atomic(r28)

		bl AtomicDone

		addi	r4,r31,SS_WAITQUEUE
		
		bl RemHeadPPC

		mr.	r3,r3
		beq-	.NoneFurther
		mr	r30,r3
		lwz	r4,8(r30)				#r4 = task
		andi.	r0,r4,1					#Shared = 1, Non-shared = 0
		ori	r4,r4,1
		xori	r4,r4,1
		bne-	.SharedSem
		mr.	r4,r4
		beq-	.NoOwner				#0 = Procure / ObtainSemShared
		stw	r4,SS_OWNER(r31)
.UpNestCount:	lha	r3,SS_NESTCOUNT(r31)
		addi	r3,r3,1
		sth	r3,SS_NESTCOUNT(r31)
		lis	r5,0
		ori	r5,r5,SIGF_SINGLE
		mr	r3,r28

		bl SignalPPC

		b	.NoneFurther
		
.NoOwner:	lwz	r5,20(r30)				#Semaphore on task's stack
		stw	r5,SS_OWNER(r31)
		lwz	r29,SS_WAITQUEUE(r31)
.link29:	stw	r31,20(r30)				#Swap with this Semaphore
		lha	r5,SS_NESTCOUNT(r31)
		addi	r5,r5,1
		sth	r5,SS_NESTCOUNT(r31)
		mr	r4,r30
		mr	r3,r28

		bl ReplyMsgPPC					#To signal back ProcurePPC

		lwz	r3,SS_OWNER(r31)
.link27:	lwz	r4,0(r29)
		mr.	r4,r4
		beq-	.Released
		
		mr	r30,r29
		mr	r29,r4
		lwz	r4,8(r30)
		mr.	r4,r4
		beq-	.link26
		
		cmplw	r4,r3
		bne+	.link27
		
		lwz	r5,4(r30)
		stw	r29,0(r5)
		stw	r5,4(r29)
		mr	r4,r3
		b	.UpNestCount
		
.link26:	lwz	r3,20(r30)
		mr.	r3,r3
		bne+	.link27
		
		lwz	r5,4(r30)
		stw	r29,0(r5)
		stw	r5,4(r29)
		lha	r5,SS_NESTCOUNT(r31)
		addi	r5,r5,1
		sth	r5,SS_NESTCOUNT(r31)
		b	.link29
		
.SharedSem:	lwz	r29,SS_WAITQUEUE(r31)
.link32:	lha	r5,SS_NESTCOUNT(r31)
		addi	r5,r5,1
		sth	r5,SS_NESTCOUNT(r31)
		mr.	r4,r4
		beq-	.link30
		lis	r5,0
		ori	r5,r5,SIGF_SINGLE
		mr	r3,r28

		bl SignalPPC

		b	.link31
		
.link30:	stw	r31,20(r30)
		stw	r4,8(r30)
		mr	r4,r30
		mr	r3,r28

		bl ReplyMsgPPC					#To signal back ProcurePPC

.link31:	lwz	r3,0(r29)
		mr.	r3,r3
		beq-	.NoneFurther
		
		mr	r30,r29
		mr	r29,r3
		lwz	r3,8(r30)
		andi.	r0,r3,1
		ori	r3,r3,1
		xori	r3,r3,1
		beq+	.link31
		
		lwz	r5,4(r30)
		stw	r29,0(r5)
		stw	r5,4(r29)
		mr	r4,r3
		b	.link32

.NoneFurther:	li	r0,0
		sth	r0,SSPPC_LOCK(r31)

.Released:	lwz	r3,0(r13)
		lwz	r4,4(r13)
		lwz	r5,8(r13)
		lwz	r6,12(r13)
		lwz	r7,16(r13)
		lwz	r8,20(r13)
		lwz	r9,24(r13)
		lwz	r10,28(r13)
		lwz	r11,32(r13)
		lwz	r12,36(r13)
		lwz	r28,40(r13)
		lwz	r29,44(r13)
		lwz	r30,48(r13)
		lwz	r31,52(r13)
		addi	r13,r13,56
		lwz	r0,0(r13)
		addi	r13,r13,4
		mtctr	r0
		
		epilog 'TOC'

#********************************************************************************************	

.Error68k:	la	r4,sonnet_Atomic(r28)

		bl AtomicDone

		loadreg	r0,'DBUG'
		
		illegal					#Not Yet Implemented

.DeadEnd:	b 	.DeadEnd

#********************************************************************************************
#
#	status =  AddSemaphorePPC(PowerPCBase, SignalSemaphorePPC) // r3=r3,r4
#
#********************************************************************************************

AddSemaphorePPC:
		prolog 228,'TOC'
				
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		li	r31,FAddSemaphorePPC-FRun68K
		bl	DebugStartFunction

		mr	r31,r3
		mr	r30,r4
		
		bl InitSemaphorePPC

		mr.	r3,r3
		beq-	.NoInitSem

		lwz	r4,sonnet_SemListSem(r31)
		mr	r3,r31
		
		bl ObtainSemaphorePPC

		addi	r4,r31,LIST_SEMAPHORES
		mr	r5,r30
		
		bl EnqueuePPC
		
		lwz	r4,sonnet_SemListSem(r31)
		mr	r3,r31
		
		bl ReleaseSemaphorePPC

		li	r3,SSPPC_SUCCESS

.NoInitSem:	lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		epilog 'TOC'

#********************************************************************************************
#
#	void RemSemaphorePPC(PowerPCBase, SignalSemaphorePPC) // r3,r4
#
#********************************************************************************************

RemSemaphorePPC:
		prolog 228,'TOC'
				
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		li	r31,FRemSemaphorePPC-FRun68K
		bl	DebugStartFunction

		mr	r30,r3
		mr	r31,r4

		bl FreeSemaphorePPC

		lwz	r4,sonnet_SemListSem(r30)
		mr	r3,r30
		
		bl ObtainSemaphorePPC

		mr	r4,r31

		bl RemovePPC

		lwz	r4,sonnet_SemListSem(r30)
		mr	r3,r30

		bl ReleaseSemaphorePPC

		lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		epilog 'TOC'

#********************************************************************************************
#
#	SignalsemaphorePPC = FindSemaphorePPC(PowerPCBase, SemaphoreName) // r3=r3,r4
#
#********************************************************************************************

FindSemaphorePPC:
		prolog 228,'TOC'
				
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		li	r31,FFindSemaphorePPC-FRun68K
		bl	DebugStartFunction

		mr	r31,r3
		mr	r30,r4

		lwz	r4,sonnet_SemListSem(r3)

		bl ObtainSemaphorePPC

		addi	r4,r31,LIST_SEMAPHORES
		mr	r5,r30

		bl FindNamePPC

		mr	r30,r3

		lwz	r4,sonnet_SemListSem(r31)
		mr	r3,r31
		
		bl ReleaseSemaphorePPC

		mr	r3,r30
		lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		epilog 'TOC'

#********************************************************************************************
#
#	void AddPortPPC(MsgPortPPC) // r4
#
#********************************************************************************************

AddPortPPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		li	r31,FAddPortPPC-FRun68K
		bl	DebugStartFunction

		mr	r31,r3
		mr	r30,r4
		
		addi	r3,r30,MP_MSGLIST
		stw	r3,8(r3)
		li	r0,0
		stwu	r0,4(r3)
		stwu	r3,-4(r3)

		lwz	r4,sonnet_PortListSem(r31)
		mr	r3,r31

		bl ObtainSemaphorePPC

		addi	r4,r31,LIST_PORTS
		mr	r5,r30

		bl EnqueuePPC

		lwz	r4,sonnet_PortListSem(r31)
		mr	r3,r31
		
		bl ReleaseSemaphorePPC

		mr	r30,r31
		li	r31,FAddPortPPC-FRun68K
		bl	DebugEndFunction

		lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		epilog 'TOC'

#********************************************************************************************
#
#	void RemPortPPC(PowerPCBase, MsgPortPPC) // r3,r4
#
#********************************************************************************************

RemPortPPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		
		li	r31,FRemPortPPC-FRun68K
		bl	DebugStartFunction

		mr	r30,r3
		mr	r31,r4

		lwz	r4,sonnet_PortListSem(r3)

		bl ObtainSemaphorePPC

		mr	r4,r31
		
		bl RemovePPC

		lwz	r4,sonnet_PortListSem(r30)
		mr	r3,r30
		
		bl ReleaseSemaphorePPC

		li	r31,FRemPortPPC-FRun68K
		bl	DebugEndFunction

		lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		epilog 'TOC'	

#********************************************************************************************
#
#	MsgPortPPC = FindPortPPC(PowerPCBase, name) // r3=r3,r4
#
#********************************************************************************************

FindPortPPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		li	r31,FFindPortPPC-FRun68K
		bl	DebugStartFunction
		
		mr	r31,r3
		mr	r5,r4

		lwz	r4,sonnet_PortListSem(r3)

		bl ObtainSemaphorePPC

		la	r4,LIST_PORTS(r31)
		mr	r3,r31

		bl FindNamePPC

		mr	r30,r3
		lwz	r4,sonnet_PortListSem(r31)
		mr	r3,r31

		bl ReleaseSemaphorePPC

		mr	r3,r30

		mr	r30,r31
		li	r31,FFindPortPPC-FRun68K
		bl	DebugEndFunction

		lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		epilog 'TOC'

#********************************************************************************************
#
#	message = WaitPortPPC(PowerPCBase, MsgPortPPC) // r3=r3,r4
#
#********************************************************************************************

WaitPortPPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)

		li	r31,FWaitPortPPC-FRun68K
		bl	DebugStartFunction

		mr	r28,r3
		mr	r31,r4

		addi	r4,r31,MP_PPC_SEM

		bl ObtainSemaphorePPC

		addi	r5,r31,MP_PPC_INTMSG
		lwz	r4,MP_PPC_INTMSG+LH_TAILPRED(r31)
		cmplw	r4,r5
		beq-	.IntListEmpty4

.WaitInLine:	la	r4,sonnet_Atomic(r28)

		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitInLine
		
		lbz	r3,PortInUse(r28)
		mr.	r3,r3
		beq-	.PortGood

		la	r4,sonnet_Atomic(r28)

		bl AtomicDone

.PortUseWait:	lbz	r3,PortInUse(r28)
		mr.	r3,r3
		bne+	.PortUseWait
		b	.WaitInLine
		
.PortGood:	stw	r31,CurrentPort(r28)
		li	r0,-1
		stb	r0,PortInUse(r28)

		la	r4,sonnet_Atomic(r28)

		bl AtomicDone

		mr	r3,r28
		
		bl CauseInterrupt

.PortUseWait2:	lbz	r3,PortInUse(r28)
		mr.	r3,r3
		bne+	.PortUseWait2

.IntListEmpty4:	lwz	r3,MP_MSGLIST(r31)
		lwz	r4,LH_HEAD(r3)
		mr.	r4,r4
		bne-	.GotMessage

		lbz	r5,MP_SIGBIT(r31)
		addi	r30,r31,MP_MSGLIST
		li	r4,1
		slw	r29,r4,r5
.NoMessage:	addi	r4,r31,MP_PPC_SEM
		mr	r3,r28

		bl ReleaseSemaphorePPC

		mr	r4,r29
		mr	r3,r28

		bl WaitPPC

		mr	r27,r3
		addi	r4,r31,MP_PPC_SEM
		mr	r3,r28

		bl ObtainSemaphorePPC

		addi	r5,r31,MP_PPC_INTMSG
		lwz	r4,MP_PPC_INTMSG+LH_TAILPRED(r31)
		cmplw	r4,r5
		beq-	.IntListEmpty5

.WaitInLine2:	la	r4,sonnet_Atomic(r28)

		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitInLine2
		
		lbz	r3,PortInUse(r28)
		mr.	r3,r3
		beq-	.PortGood2

		la	r4,sonnet_Atomic(r28)

		bl AtomicDone

.PortUseWait3:	lbz	r3,PortInUse(r28)
		mr.	r3,r3
		bne+	.PortUseWait3
		
		b	.WaitInLine2

.PortGood2:	stw	r31,CurrentPort(r28)
		li	r0,-1
		stb	r0,PortInUse(r28)

		la	r4,sonnet_Atomic(r28)

		bl AtomicDone
		
		mr	r3,r28

		bl CauseInterrupt

.PortUseWait4:	lbz	r3,PortInUse(r28)
		mr.	r3,r3
		bne+	.PortUseWait4
		
.IntListEmpty5:	mr	r3,r27
		lwz	r5,MP_MSGLIST(r31)
		lwz	r4,LH_HEAD(r5)
						
		mr.	r4,r4
		beq+	.NoMessage
		mr	r3,r5
.GotMessage:	mr	r5,r3
		addi	r4,r31,MP_PPC_SEM
		mr	r3,r28

		bl ReleaseSemaphorePPC

		mr	r3,r5

		mr	r30,r28
		li	r31,FWaitPortPPC-FRun68K
		bl	DebugEndFunction
		
		lwz	r27,0(r13)
		lwz	r28,4(r13)
		lwz	r29,8(r13)
		lwz	r30,12(r13)
		lwz	r31,16(r13)
		addi	r13,r13,20
		
		epilog 'TOC'

#********************************************************************************************
#
#	SuperKey = Super(void) // r3 (0 on first switch, -1 on the rest)
#
#********************************************************************************************

Super:
		prolog 228,'TOC'

		li	r0,-1			#READ PVR (warp funcion -130)
Violation:	mfpvr	r3			#IF user then exception; r0/r3=0
		mr	r3,r0			#IF super then r0/r3=-1

		epilog 'TOC'			#See Program Exception ($700)	

#********************************************************************************************
#
#	void User(SuperKey) // r4
#
#********************************************************************************************

User:
		prolog 228,'TOC'

		mr.	r4,r4
		bne-	.WrongKey

		mfmsr	r0
		ori	r0,r0,PSL_PR		#SET Bit 17 (PR) To User
		mtmsr	r0
		isync
		sync

.WrongKey:	epilog 'TOC'

#********************************************************************************************
#
#	Support: void DisableIntPPC(void)
#
#********************************************************************************************

DisableIntPPC:	
		stwu	r28,-4(r13)
		mfmsr	r28
		ori	r28,r28,PSL_EE
		xori	r28,r28,PSL_EE			#Disable()
		mtmsr	r28
		isync
		sync
		lwz	r28,0(r13)
		addi	r13,r13,4
		blr

#********************************************************************************************
#
#	Support: void EnableIntPPC(void)
#
#********************************************************************************************

EnableIntPPC:
		stwu	r28,-4(r13)
		mfmsr	r28
		ori	r28,r28,PSL_EE			#Enable()
		mtmsr	r28
		isync
		sync
		lwz	r28,0(r13)
		addi	r13,r13,4
		blr

#********************************************************************************************
#
#	Support: MsgFrame = CreateMsgFramePPC(void) // r3
#
#********************************************************************************************

CreateMsgFramePPC:
		prolog 228,'TOC'
		
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)
		stwu	r4,-4(r13)

		bl Super

		mr	r26,r3

		bl DisableIntPPC

		lis	r3,EUMB@h
		li	r27,OFTPR
		lwbrx	r30,r27,r3			
		addi	r28,r30,4
		loadreg	r29,0xc000
		or	r28,r28,r29
		loadreg r29,0xffff
		and	r28,r28,r29			#Keep it C000-FFFE		
		stwbrx	r28,r27,r3
		sync
		lwz	r30,0(r30)			

		bl EnableIntPPC

		mr	r4,r26

		bl User

		mr	r3,r30

		lwz	r4,0(r13)
		lwz	r26,4(r13)
		lwz	r27,8(r13)
		lwz	r28,12(r13)
		lwz	r29,16(r13)
		lwz	r30,20(r13)
		addi	r13,r13,24

		epilog 'TOC'
		
#********************************************************************************************
#
#	Support: void SendMsgFramePPC(MsgFrame) // r4
#
#********************************************************************************************

SendMsgFramePPC:
		prolog 228,'TOC'
		
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)

		mr	r30,r4

		bl Super

		mr	r26,r3

		bl DisableIntPPC

		lis	r3,EUMB@h
		li	r27,OPHPR
		lwbrx	r28,r27,r3		
		stw	r30,0(r28)		
		addi	r29,r28,4
		loadreg	r4,0xbfff
		and	r29,r29,r4			#Keep it 8000-BFFE
		stwbrx	r29,r27,r3			#triggers Interrupt
		sync
		
		bl EnableIntPPC

		mr	r4,r26

		bl User

		lwz	r26,0(r13)
		lwz	r27,4(r13)
		lwz	r28,8(r13)
		lwz	r29,12(r13)
		lwz	r30,16(r13)
		addi	r13,r13,20

		epilog	'TOC'
		
#********************************************************************************************
#
#	Support: void FreeMsgFramePPC(MsgFrame) // r4
#
#********************************************************************************************

FreeMsgFramePPC:
		prolog 228,'TOC'
		
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)

		mr	r30,r4

		bl Super

		mr	r26,r3

		bl DisableIntPPC

		lis	r3,EUMB@h			#Free the message
		li	r27,IFHPR
		lwbrx	r29,r27,r3		
		stw	r30,0(r29)		
		addi	r28,r29,4
		li	r29,0x3fff
		and	r28,r28,r29			#Keep it 0000-3FFE
		stwbrx	r28,r27,r3
		sync

		bl EnableIntPPC

		mr	r4,r26

		bl User

		lwz	r26,0(r13)
		lwz	r27,4(r13)
		lwz	r28,8(r13)
		lwz	r29,12(r13)
		lwz	r30,16(r13)
		addi	r13,r13,20
		
		epilog	'TOC'

#********************************************************************************************
#
#	void PutXMsgPPC(PowerPCBase, MsgPort, message) // r3,r4,r5
#
#********************************************************************************************

PutXMsgPPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)

		li	r31,FPutXMsgPPC-FRun68K
		bl	DebugStartFunction

		li	r31,NT_XMSGPPC
		stb	r31,LN_TYPE(r5)	
		
		mr	r31,r5
		mr	r28,r4
		lhz	r29,MN_LENGTH(r31)
		mr	r26,r3
		
		li	r4,CACHE_DCACHEFLUSH
		mr	r6,r29
		
		bl SetCache
			
		bl CreateMsgFramePPC
		
		mr	r30,r3

		lwz	r27,sonnet_MCPort(r26)
		stw	r27,MN_MCPORT(r30)
		sth	r29,MN_ARG1(r30)
		stw	r31,MN_ARG2(r30)
		loadreg	r27,'XMSG'
		stw	r27,MN_IDENTIFIER(r30)
		li	r27,NT_MESSAGE
		stb	r27,LN_TYPE(r30)
		stw	r28,MN_PPC(r30)
		mr	r4,r30
		
		bl SendMsgFramePPC

		lwz	r26,0(r13)
		lwz	r27,4(r13)
		lwz	r28,8(r13)
		lwz	r29,12(r13)
		lwz	r30,16(r13)
		lwz	r31,20(r13)
		addi	r13,r13,24
		
		epilog 'TOC'

#********************************************************************************************
#
#	status = WaitFor68K(PowerPCBase, PPStruct) // r3=r3,r4
#
#********************************************************************************************

WaitFor68K:	
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)
		stwu	r25,-4(r13)

		li	r31,FWaitFor68K-FRun68K
		bl	DebugStartFunction

		mr	r25,r3
		mr	r31,r4

.WasNoMsg:	lwz	r27,ThisPPCProc(r25)
		lwz	r4,TC_SIGALLOC(r27)
		loadreg	r28,0xfffff100
		and.	r4,r4,r28
		mr	r3,r25

		bl WaitPPC

		mr	r5,r3
		li	r28,SIGF_DOS				#Standard msg port wait bit
		andc.	r5,r5,r28
		beq	.NextMsg

		lwz	r4,TASKPPC_MIRRORPORT(r27)
		lwz	r4,MP_SIGTASK(r4)
		mr	r3,r25
		
		bl Signal68K		
		
.NextMsg:	lwz	r4,TASKPPC_MSGPORT(r27)
		mr	r3,r25

		bl GetMsgPPC

		mr.	r30,r3
		beq	.WasNoMsg
		
		lwz	r29,MN_IDENTIFIER(r30)
		loadreg	r4,'DNLL'
		cmpw	r4,r29
		beq	.WasLL
		loadreg	r4,'END!'
		cmpw	r4,r29
		beq	.KillRunPPC
		loadreg	r4,'TPPC'
		cmpw	r4,r29
		beq	.RunPPC
		loadreg	r4,'DONE'
		cmpw	r4,r29
		beq	.WasDone
		
		illegal					##FIFO list corruption?
		b	.NextMsg			##Needs error message
		
.WasDone:	lwz	r4,ThisPPCProc(r25)
		lwz	r26,TASKPPC_MIRRORPORT(r4)
		mr.	r26,r26
		bne	.GotMirror

		lwz	r26,MN_MIRROR(r30)
		stw	r26,TASKPPC_MIRRORPORT(r4)
		lwz	r26,MN_ARG2(r30)
		stw	r26,TASKPPC_MIRROR68K(r4)
		
.GotMirror:	mfctr	r26
		subi	r4,r31,4
		addi	r29,r30,MN_PPSTRUCT-4		#r30 = new msg
		li	r6,PP_SIZE/4
		mtctr	r6
.CopyPPB:	lwzu	r7,4(r29)
		stwu	r7,4(r4)
		bdnz+	.CopyPPB
		
		mtctr	r26

.WasLL:		lwz	r28,MN_PPSTRUCT+6*4(r30)	#return d0 for Run68KLowLevel
		lwz	r29,MN_PPSTRUCT+5*4(r30)
		mr	r4,r30
		
		bl FreeMsgFramePPC

		mr	r4,r28
		mr	r5,r29

.ASync:		li	r3,0				#Needs proper status still

		lwz	r25,0(r13)
		lwz	r26,4(r13)
		lwz	r27,8(r13)
		lwz	r28,12(r13)
		lwz	r29,16(r13)
		lwz	r30,20(r13)
		lwz	r31,24(r13)
		addi	r13,r13,28
		
		epilog 'TOC'

.RunPPC:	mr	r3,r25

		bl	.StartRunPPC
		
		b	.NextMsg

#********************************************************************************************
#
#	status = Run68K(PowerPCBase, PPStruct) // r3=r3,r4
#
#********************************************************************************************

Run68K:		
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r25,-4(r13)
		stwu	r24,-4(r13)
		stwu	r23,-4(r13)

		li	r31,FRun68K-FRun68K
		bl	DebugStartFunction

		mr	r28,r3
		mr	r31,r4		
		mfctr	r25

		bl CreateMsgFramePPC
		
		mr	r30,r3			
		subi	r5,r30,4		
		li	r6,48
		li	r7,0
		mtctr	r6
.ClearMsg:	stwu	r7,4(r5)
		bdnz	.ClearMsg
				
		subi	r4,r31,4			#r29 = PPStruct -4
		addi	r29,r30,MN_PPSTRUCT-4		#r30 = msg		
		li	r6,PP_SIZE/4
		mtctr	r6
.CopyPP:	lwzu	r7,4(r4)
		stwu	r7,4(r29)
		bdnz+	.CopyPP
		
		loadreg	r5,'T68K'
		stw	r5,MN_IDENTIFIER(r30)
		lwz	r5,ThisPPCProc(r28)
		stw	r5,MN_PPC(r30)
		lwz	r4,TASKPPC_MIRRORPORT(r5)
		stw	r4,MN_MIRROR(r30)
		lwz	r4,LN_NAME(r5)
		stw	r4,MN_ARG0(r30)
		lwz	r4,TC_SIGALLOC(r5)
		stw	r4,MN_ARG1(r30)
		lwz	r4,TC_SIGRECVD(r5)
		stw	r4,MN_ARG2(r30)
		
		
		lwz	r4,PP_CODE(r30)
		mr.	r4,r4
		li	r4,PPERR_MISCERR
		beq	.GiveResult
		lwz	r4,PP_FLAGS(r30)
		mr.	r4,r4
		bne	.GivErr
		lwz	r4,PP_STACKPTR(r30)
		mr.	r4,r4
		beq	.FromRunPPC
		lwz	r4,PP_STACKSIZE(r30)
		mr.	r4,r4
		beq	.FromRunPPC
		
.GivErr:	loadreg	r0,'DBUG'

		illegal					#DEBUG Not yet implemented (Stack transfer)
		
.FromRunPPC:	lwz	r4,sonnet_MCPort(r28)
		stw	r4,MN_MCPORT(r30)
		li	r5,NT_MESSAGE
		stb	r5,LN_TYPE(r30)
		li	r5,192
		sth	r5,MN_LENGTH(r30)

		lwz	r4,sonnet_SysBase(r28)
		lwz	r5,PP_CODE(r30)
		cmpw	r4,r5
		bne	.NotAllocMem
		
		loadreg	r4,_LVOAllocMem
		lwz	r5,PP_OFFSET(r30)
		cmpw	r4,r5
		beq	.DoingMem
		
		loadreg	r4,_LVOAllocVec
		cmpw	r4,r5
		bne	.NotAllocMem
		
.DoingMem:	lwz	r4,PP_REGS+4(r30)
		loadreg	r5,MEMF_CHIP
		and.	r5,r4,r5
		bne	.NotAllocMem
		ori	r4,r4,MEMF_PPC
		stw	r4,PP_REGS+4(r30)			

.NotAllocMem:	mr	r4,r30

		bl SendMsgFramePPC

		mr	r4,r31
		mr	r3,r28

		bl WaitFor68K

		mr	r3,r5

		mr	r30,r28
		li	r31,FRun68K-FRun68K
		bl	DebugEndFunction
		
		mtctr	r25
		li	r4,PPERR_SUCCESS
.GiveResult:	mr	r3,r4
		
		lwz	r23,0(r13)
		lwzu	r24,4(r13)
		lwzu	r25,4(r13)
		lwzu	r28,4(r13)
		lwzu	r29,4(r13)
		lwzu	r30,4(r13)
		lwzu	r31,4(r13)
		addi	r13,r13,4

		epilog 'TOC'

#********************************************************************************************
#
#	void Signal68K(Task, Signal) // r4,r5
#
#********************************************************************************************

Signal68K:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		
		li	r31,FSignal68K-FRun68K
		bl	DebugStartFunction
		
		mr	r31,r4
		mr	r30,r5
		
		bl CreateMsgFramePPC
		
		mr	r4,r3
		loadreg	r5,'SIG!'
		stw	r5,MN_IDENTIFIER(r4)
		stw	r31,MN_PPSTRUCT(r4)
		stw	r30,MN_PPSTRUCT+4(r4)
		
		bl SendMsgFramePPC
		
		lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		epilog 'TOC'	

#********************************************************************************************
#
#	void CopyMemPPC(source, dest, size) // r4,r5,r6
#
#********************************************************************************************

CopyMemPPC:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		
		li	r31,FCopyMemPPC-FRun68K
		bl	DebugStartFunction
		
		mfctr	r31

		andi.	r3,r4,7
		bne-	.NoSAlign8

		andi.	r7,r5,7
		beq-	.Align8

.NoSAlign8:	andi.	r3,r4,3
		bne-	.NoSAlign4

		andi.	r7,r5,3
		beq-	.Align4

.NoSAlign4:	andi.	r3,r4,1
		bne-	.NoSAlign2

		andi.	r7,r5,1
		beq-	.Align2

.NoSAlign2:	mr.	r6,r6
		beq-	.ExitCopy

		mtctr	r6
		subi	r4,r4,1
		subi	r5,r5,1
.LoopAl1:	lbzu	r0,1(r4)
		stbu	r0,1(r5)
		bdnz+	.LoopAl1

		b	.ExitCopy
		
.Align2:	rlwinm	r7,r6,31,1,31
		mtctr	r7
		subi	r4,r4,2
		subi	r5,r5,2
		mr.	r7,r7
		beq-	.ExitAl2

.LoopAl2:	lhzu	r0,2(r4)
		sthu	r0,2(r5)
		bdnz+	.LoopAl2

.ExitAl2:	andi.	r6,r6,1
		beq-	.ExitCopy

		lbzu	r0,2(r4)
		stbu	r0,2(r5)
		b	.ExitCopy

.Align4:	rlwinm	r7,r6,30,2,31
		mtctr	r7
		subi	r4,r4,4
		subi	r5,r5,4
		mr.	r7,r7
		beq-	.SmallSize4

.LoopAl4:	lwzu	r0,4(r4)
		stwu	r0,4(r5)
		bdnz+	.LoopAl4

.SmallSize4:	andi.	r6,r6,3
		beq-	.ExitCopy

		mtctr	r6
		addi	r4,r4,3
		addi	r5,r5,3
.SmallLoop4:	lbzu	r0,1(r4)
		stbu	r0,1(r5)
		bdnz+	.SmallLoop4

		b	.ExitCopy

.Align8:	rlwinm	r7,r6,29,3,31		
		mtctr	r7
		subi	r4,r4,8
		subi	r5,r5,8
		mr.	r7,r7
		beq-	.SmallSize8

.LoopAl8:	lfdu	f0,8(r4)
		stfdu	f0,8(r5)
		bdnz+	.LoopAl8

.SmallSize8:	andi.	r6,r6,7
		beq-	.ExitCopy

		mtctr	r6
		addi	r4,r4,7
		addi	r5,r5,7
.SmallLoop8:	lbzu	r0,1(r4)
		stbu	r0,1(r5)
		bdnz+	.SmallLoop8

.ExitCopy:	mtctr	r31
		lwz	r31,0(r13)
		addi	r13,r13,4

		epilog 'TOC'

#********************************************************************************************
#
#	oldport = SetReplyPortPPC(Message, MsgPortPPC) // r3=r4,r5
#
#********************************************************************************************
			
SetReplyPortPPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		
		li	r31,FSetReplyPortPPC-FRun68K
		bl	DebugStartFunction
		
		lwz	r3,MN_REPLYPORT(r4)
		stw	r5,MN_REPLYPORT(r4)
		
		lwz	r31,0(r13)
		addi	r13,r13,4
		
		epilog 'TOC'

#********************************************************************************************
#
#	status = TrySemaphorePPC(PowerPCBase, SignalSemaphorePPC, Timeout) // r3=r3,r4,r5
#
#********************************************************************************************

TrySemaphorePPC:
		prolog 228,'TOC'

		mfctr	r0
		stwu	r0,-4(r13)
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)
		stwu	r12,-4(r13)
		stwu	r11,-4(r13)
		stwu	r10,-4(r13)
		stwu	r9,-4(r13)
		stwu	r8,-4(r13)
		stwu	r7,-4(r13)
		stwu	r6,-4(r13)
		stwu	r5,-4(r13)
		stwu	r4,-4(r13)
	
		li	r31,FTrySemaphorePPC-FRun68K
		bl	DebugStartFunction
	
		mr	r26,r3
		mr	r30,r4
		mr	r28,r5
		
.WaitAt1:	la	r4,sonnet_Atomic(r26)

		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitAt1
		
		lwz	r4,SSPPC_RESERVE(r30)

.WaitAt2:	bl AtomicTest

		mr.	r3,r3
		beq+	.WaitAt2
		
		lha	r5,SS_QUEUECOUNT(r30)
		addi	r5,r5,1
		sth	r5,SS_QUEUECOUNT(r30)
		extsh.	r0,r5
		bne-	.CheckOwner

		lwz	r3,ThisPPCProc(r26)
		stw	r3,SS_OWNER(r30)		
		lwz	r4,SSPPC_RESERVE(r30)

		bl AtomicDone

		la	r4,sonnet_Atomic(r26)

		bl AtomicDone

		b	.Jump1
		
.CheckOwner:	lwz	r3,ThisPPCProc(r26)
		lwz	r4,SS_OWNER(r30)
		cmplw	r3,r4
		bne-	.Diff1
		
		lwz	r4,SSPPC_RESERVE(r30)

		bl AtomicDone

		la	r4,sonnet_Atomic(r26)

		bl AtomicDone

		b	.Jump1
		
.Diff1:		stwu	r29,-4(r13)
		mr	r29,r13
		subi	r13,r13,12
		subi	r5,r29,12
		stw	r3,8(r5)
		lwz	r4,TC_SIGRECVD(r3)
		ori	r4,r4,SIGF_SINGLE
		xori	r4,r4,SIGF_SINGLE
		stw	r4,TC_SIGRECVD(r3)
		addi	r4,r30,SS_WAITQUEUE
		addi	r4,r4,4					#AddTailPPC
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)		
		lwz	r4,SSPPC_RESERVE(r30)

		bl AtomicDone

		la	r4,sonnet_Atomic(r26)

		bl AtomicDone

		li	r4,SIGF_SINGLE
		mr	r5,r28
		mr	r3,r26
		
		bl WaitTime
		
		mr	r28,r3
.WeirdWait:	lhz	r3,SSPPC_LOCK(r30)
		mr.	r3,r3
		bne+	.WeirdWait
		
.WaitAt3:	la	r4,sonnet_Atomic(r26)

		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitAt3

		lhz	r3,SSPPC_LOCK(r30)
		mr.	r3,r3
		beq-	.Jump3

		la	r4,sonnet_Atomic(r26)

		bl AtomicDone

		b	.WeirdWait
		
.Jump3:		lwz	r3,ThisPPCProc(r26)
		lwz	r4,TC_SIGRECVD(r3)
		or	r4,r28,r4
		mr	r27,r4
		ori	r4,r4,SIGF_SINGLE
		xori	r4,r4,SIGF_SINGLE
		stw	r4,TC_SIGRECVD(r3)
		subi	r4,r29,12
		rlwinm.	r0,r28,28,31,31
		bne-	.Jump2
		
		lwz	r3,0(r4)				#RemovePPC
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)
		
.Jump2:		la	r4,sonnet_Atomic(r26)

		bl AtomicDone

		mr	r13,r29
		lwz	r29,0(r13)
		addi	r13,r13,4
		rlwinm.	r0,r28,28,31,31
		beq-	.Exit1

		lha	r5,SS_NESTCOUNT(r30)
		subi	r5,r5,1
		sth	r5,SS_NESTCOUNT(r30)
.Jump1:		li	r3,ATTEMPT_SUCCESS
		b	.Exit2
		
.Exit1:		li	r3,ATTEMPT_FAILURE
.Exit2:		lha	r5,SS_NESTCOUNT(r30)
		addi	r5,r5,1
		sth	r5,SS_NESTCOUNT(r30)
		lwz	r4,0(r13)
		lwz	r5,4(r13)
		lwz	r6,8(r13)
		lwz	r7,12(r13)
		lwz	r8,16(r13)
		lwz	r9,20(r13)
		lwz	r10,24(r13)
		lwz	r11,28(r13)
		lwz	r12,32(r13)
		lwz	r26,36(r13)
		lwz	r27,40(r13)
		lwz	r28,44(r13)
		lwz	r29,48(r13)
		lwz	r30,52(r13)
		lwz	r31,56(r13)
		addi	r13,r13,60
		lwz	r0,0(r13)
		addi	r13,r13,4
		mtctr	r0

		epilog 'TOC'

#********************************************************************************************
#
#	Void ModifyFPExc(FPflags) // r4
#
#********************************************************************************************

ModifyFPExc:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)

		li	r31,FModifyFPExc-FRun68K
		bl	DebugStartFunction

		mr	r5,r4
		andi.	r0,r5,1
		beq-	.NoEnOverflow

		li	r4,1					#FPF_EN_OVERFLOW
		bl	.FP_EN

.NoEnOverflow:	rlwinm.	r0,r5,(32-FPF_DIS_OVERFLOW),31,31
		beq-	.NoDisOverflow

		li	r4,1
		bl	.FP_DIS

.NoDisOverflow:	rlwinm.	r0,r5,(32-FPF_EN_UNDERFLOW),31,31
		beq-	.NoEnUnder

		li	r4,2
		bl	.FP_EN

.NoEnUnder:	rlwinm.	r0,r5,(32-FPF_DIS_UNDERFLOW),31,31
		beq-	.NoDisUnder

		li	r4,2
		bl	.FP_DIS

.NoDisUnder:	rlwinm.	r0,r5,(32-FPF_EN_ZERODIVIDE),31,31
		beq-	.NoEnZeroDiv

		li	r4,4
		bl	.FP_EN

.NoEnZeroDiv:	rlwinm.	r0,r5,(32-FPF_DIS_ZERODIVIDE),31,31
		beq-	.NoDisZeroDiv

		li	r4,4
		bl	.FP_DIS

.NoDisZeroDiv:	rlwinm.	r0,r5,(32-FPF_EN_INEXACT),31,31
		beq-	.NoEnInexact

		li	r4,8
		bl	.FP_EN

.NoEnInexact:	rlwinm.	r0,r5,(32-FPF_DIS_INEXACT),31,31
		beq-	.NoDisInexact

		li	r4,8
		bl	.FP_DIS

.NoDisInexact:	rlwinm.	r0,r5,(32-FPF_EN_INVALID),31,31
		beq-	.NoEnInvalid

		li	r4,16
		bl	.FP_EN

.NoEnInvalid:	rlwinm.	r0,r5,(32-FPF_DIS_INVALID),31,31
		beq-	.NoDisInvalid

		li	r4,16
		bl	.FP_DIS

.NoDisInvalid:	lwz	r31,0(r13)
		addi	r13,r13,4
		
		epilog 'TOC'

#********************************************************************************************
		
.FP_EN:		stw	r2,20(r1)
		mflr	r0
		stw	r0,8(r1)
		mfcr	r0
		stw	r0,4(r1)
		stw	r13,-4(r1)
		subi	r13,r1,4
		stwu	r1,-60(r1)
		stwu	r3,-4(r13)

		andi.	r0,r4,1
		bnel-	.Bit0
		rlwinm.	r0,r4,31,31,31
		bnel-	.Bit1
		rlwinm.	r0,r4,30,31,31
		bnel-	.Bit2
		rlwinm.	r0,r4,29,31,31
		bnel-	.Bit3
		rlwinm.	r0,r4,28,31,31
		bnel-	.Bit4
		b	.ExitFP_EN

.Bit0:		mtfsb0	3
		mtfsb1	25
		blr	

.Bit1:		mtfsb0	4
		mtfsb1	26
		blr	

.Bit2:		mtfsb0	5
		mtfsb1	27
		blr	

.Bit3:		mtfsb0	6
		mtfsb1	28
		blr	

.Bit4:		mtfsb0	7
		mtfsb0	8
		mtfsb0	9
		mtfsb0	10
		mtfsb0	11
		mtfsb0	12
		mtfsb0	21
		mtfsb0	22
		mtfsb0	23
		mtfsb1	24
		blr	

.ExitFP_EN:	lwz	r3,0(r13)
		addi	r13,r13,4
		lwz	r1,0(r1)
		lwz	r13,-4(r1)
		lwz	r0,8(r1)
		mtlr	r0
		lwz	r0,4(r1)
		mtcr	r0
		lwz	r2,20(r1)
		blr
		
.FP_DIS:	stw	r2,20(r1)
		mflr	r0
		stw	r0,8(r1)
		mfcr	r0
		stw	r0,4(r1)
		stw	r13,-4(r1)
		subi	r13,r1,4
		stwu	r1,-60(r1)
		stwu	r3,-4(r13)

		andi.	r0,r4,1
		bnel-	.Bit_0
		rlwinm.	r0,r4,31,31,31
		bnel-	.Bit_1
		rlwinm.	r0,r4,30,31,31
		bnel-	.Bit_2
		rlwinm.	r0,r4,29,31,31
		bnel-	.Bit_3
		rlwinm.	r0,r4,28,31,31
		bnel-	.Bit_4
		b	.ExitFP_DIS

.Bit_0:		mtfsb0	25
		blr	

.Bit_1:		mtfsb0	26
		blr	

.Bit_2:		mtfsb0	27
		blr	

.Bit_3:		mtfsb0	28
		blr	

.Bit_4:		mtfsb0	24
		blr	

.ExitFP_DIS:	lwz	r3,0(r13)
		addi	r13,r13,4
		lwz	r1,0(r1)
		lwz	r13,-4(r1)
		lwz	r0,8(r1)
		mtlr	r0
		lwz	r0,4(r1)
		mtcr	r0
		lwz	r2,20(r1)
		blr	
		
#********************************************************************************************
#
#	status = AddUniquePortPPC(PowerPCBase, MsgPortPPC) // r3=r3,r4. r4 has an initialized LN_NAME
#
#********************************************************************************************

AddUniquePortPPC:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

		li	r31,FAddUniquePortPPC-FRun68K
		bl	DebugStartFunction

		mr	r31,r3
		mr	r30,r4
		li	r29,UNIPORT_SUCCESS

		lwz	r4,sonnet_PortListSem(r3)
		mr	r3,r31

		bl ObtainSemaphorePPC

		lwz	r4,LN_NAME(r30)
		mr	r3,r31

		bl FindPortPPC

		mr.	r3,r3
		bne-	.Duplicate
		
		mr	r4,r30
		mr	r3,r31

		bl AddPortPPC

		b	.SkipDup

.Duplicate:	li	r29,UNIPORT_NOTUNIQUE
.SkipDup:	lwz	r4,sonnet_PortListSem(r31)
		mr	r3,r31

		bl ReleaseSemaphorePPC

		mr	r3,r29

		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12
		
		epilog 'TOC'

#********************************************************************************************
#
#	status =  AddUniqueSemaphorePPC(PowerPCBase, SignalSemaphorePPC) // r3=r3,r4. r4 has an initialized LN_NAME
#
#********************************************************************************************

AddUniqueSemaphorePPC:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

		li	r31,FAddUniqueSemaphorePPC-FRun68K
		bl	DebugStartFunction

		mr	r31,r3
		mr	r30,r4
		li	r29,UNISEM_SUCCESS

		lwz	r4,sonnet_SemListSem(r3)
		
		bl ObtainSemaphorePPC

		lwz	r4,LN_NAME(r30)
		mr	r3,r31

		bl FindSemaphorePPC

		mr.	r3,r3
		bne-	.Duplicate2

		mr	r4,r30
		mr	r3,r31

		bl AddSemaphorePPC
		
		b	.SkipDup2

.Duplicate2:	li	r29,UNISEM_NOTUNIQUE
.SkipDup2:	lwz	r4,sonnet_SemListSem(r31)
		mr	r3,r31

		bl ReleaseSemaphorePPC

		mr	r3,r29

		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12

		epilog 'TOC'

#********************************************************************************************
#
#	status =  PutPublicMsgPPC(PowerPCBase, Portname, message) // r3=r3,r4,r5
#
#********************************************************************************************	
	
PutPublicMsgPPC:
		prolog 228,'TOC'		

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)

		li	r31,FPutPublicMsgPPC-FRun68K
		bl	DebugStartFunction

		mr	r28,r3
		mr	r31,r4
		mr	r30,r5
		li	r29,PUBMSG_SUCCESS

		lwz	r4,sonnet_PortListSem(r3)

		bl ObtainSemaphorePPC

		mr	r4,r31
		mr	r3,r28

		bl FindPortPPC

		mr.	r3,r3
		beq-	.PortNotFound

		mr	r4,r3
		mr	r5,r30
		mr	r3,r28

		bl PutMsgPPC

		b	.SkipStatus

.PortNotFound:	li	r29,PUBMSG_NOPORT
.SkipStatus:	lwz	r4,sonnet_PortListSem(r28)
		mr	r3,r28

		bl ReleaseSemaphorePPC

		mr	r3,r29
		
		lwz	r28,0(r13)
		lwz	r29,4(r13)
		lwz	r30,8(r13)
		lwz	r31,12(r13)
		addi	r13,r13,16

		epilog 'TOC'

#********************************************************************************************
#
#	void AllocPrivateMem(void)	// Dummy (as in powerpc.library)
#
#********************************************************************************************

AllocPrivateMem:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12

		epilog 'TOC'	

#********************************************************************************************
#
#	void FreePrivateMem(void)	// Dummy (as in powerpc.library)
#
#********************************************************************************************

FreePrivateMem:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12

		epilog 'TOC'

#********************************************************************************************
#
#	TaskPPC = FindTaskByID(PowerPCBase, taskID) // r3=r3,r4
#
#********************************************************************************************

FindTaskByID:		
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)

		li	r31,FFindTaskByID-FRun68K
		bl	DebugStartFunction

		mr	r28,r3
		li	r29,0
		mr	r31,r4

		bl LockTaskList

		mr	r30,r3
.NextNode:	lwz	r4,0(r3)
		mr.	r4,r4
		beq-	.EndSearch

		lwz	r3,TASKPTR_TASK(r3)			#Link from mini list to big list
		lwz	r5,TASKPPC_ID(r3)
		cmpw	r5,r31
		bne-	.IncorrectID

		mr	r29,r3
		b	.EndSearch

.IncorrectID:	mr	r3,r4
		b	.NextNode

.EndSearch:	mr	r4,r30
		mr	r3,r28

		bl UnLockTaskList

		mr	r3,r29

		lwz	r28,0(r13)
		lwz	r29,4(r13)
		lwz	r30,8(r13)
		lwz	r31,12(r13)
		addi	r13,r13,16
		
		epilog 'TOC'

#********************************************************************************************
#
#	OldNice = SetNiceValue(PowerPCBase, TaskPPC, Nice) // r3=r3,r4,r5
#
#********************************************************************************************
	
SetNiceValue:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)

		li	r31,FSetNiceValue-FRun68K
		bl	DebugStartFunction
		
		mr	r28,r3
		mr	r31,r4
		
		cmpwi	r5,-20
		bge-	.SetMin
		li	r5,-20
.SetMin:	cmpwi	r5,20
		ble-	.SetMax
		li	r5,20
.SetMax:	mr	r30,r5

		bl LockTaskList

		lwz	r29,TASKPPC_NICE(r31)
		stw	r30,TASKPPC_NICE(r31)
		mr	r4,r3
		mr	r3,r28

		bl UnLockTaskList

		mr	r3,r29

		lwz	r28,0(r13)
		lwz	r29,4(r13)
		lwz	r30,8(r13)
		lwz	r31,12(r13)
		addi	r13,r13,16
		
		epilog 'TOC'

#********************************************************************************************
#
#	Support: StrLen = GetLen(String) // r3=r3
#
#********************************************************************************************

GetLen:	
		li	r4,0
		subi	r3,r3,1
.NextChar:	lbzu	r0,1(r3)
		mr.	r0,r0
		beq-	.EndReached
		addi	r4,r4,1
		b	.NextChar
.EndReached:	mr	r3,r4
		blr
		
#********************************************************************************************
#
#	Support: EndOfDestStr = CopyStr(Source, Destination) // r3=r3,r4
#
#********************************************************************************************

CopyStr:	
		subi	r3,r3,1
		subi	r4,r4,1
.CopyNext:	lbzu	r0,1(r3)
		stbu	r0,1(r4)
		mr.	r0,r0
		bne+	.CopyNext
		addi	r3,r4,1
		blr

#********************************************************************************************
#
#	TaskPPC = CreateTaskPPC(PowerPCBase, TagItems) // r3=r3,r4
#
#********************************************************************************************

CreateTaskPPC:	
		prolog 228,'TOC'	
 
		stwu	r31,-4(r13) 
		stwu	r30,-4(r13) 
		stwu	r29,-4(r13) 
		stwu	r28,-4(r13) 
		stwu	r27,-4(r13) 
		stwu	r26,-4(r13) 
		stwu	r25,-4(r13) 
		stwu	r24,-4(r13) 
		stwu	r23,-4(r13) 
		stwu	r22,-4(r13) 
		stwu	r21,-4(r13) 
		stwu	r20,-4(r13) 
		stwu	r19,-4(r13) 
		stwu	r18,-4(r13) 
		stwu	r17,-4(r13) 
		stwu	r16,-4(r13) 

		li	r31,FCreateTaskPPC-FRun68K
		bl	DebugStartFunction

		mr	r17,r2 
		mr	r30,r4
		mr	r23,r3

		lwz	r3,ThisPPCProc(r23)
		lwz	r4,TASKPPC_FLAGS(r3)
		ori	r4,r4,1<<TASKPPC_CHOWN 
		stw	r4,TASKPPC_FLAGS(r3) 
 		
		loadreg	r4,TASKATTR_CODE
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
	 
		mr.	r3,r3 
		beq-	.Error01			#Error NoCode 
 
		mr	r25,r3 
		li	r4,TASKPPC_LENGTH		#Original 246 bytes
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,0				#default alignment
		mr	r3,r23
 
 		bl AllocVec68K
 
		mr.	r3,r3 
		beq-	.Error01			#Error NoMem 
 
		mr	r31,r3 
		stw	r31,TASKLINK_TASK(r31)
		li	r0,0xfff
		stw	r0,TASKLINK_SIG(r31)
		addi	r3,r31,TC_MEMENTRY
		stw	r3,LH_TAILPRED(r3)
		li	r0,0 
		stwu	r0,LH_TAIL(r3)
		stwu	r3,LH_HEAD-4(r3)
		li	r0,NT_PPCTASK 
		stb	r0,LN_TYPE(r31) 
		li	r0,T_PROCTIME 
		stb	r0,TC_FLAGS(r31) 
		stw	r23,TASKPPC_POWERPCBASE(r31)
 
		li	r4,84
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,0
		mr	r3,r23
 
 		bl AllocVec68K
 
		mr.	r3,r3 
		beq-	.Error02			#Error NoMem 
 
		mr	r20,r3 
		stw	r3,TASKPPC_BATSTORAGE(r31)
 
		li	r4,24 
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,0
		mr	r3,r23
 
 		bl AllocVec68K
 
		mr.	r3,r3	 
		beq-	.Error03			#Error NoMem 
 
		mr	r19,r3 
		li	r0,1 
		sth	r0,ML_NUMENTRIES(r3) 
		stw	r20,ML_SIZE+ME_ADDR(r3)		#Value of memory of BATSTORAGE 
		lis	r0,0 
		ori	r0,r0,84 
		stw	r0,ML_SIZE+ME_LENGTH(r3)	#Length 
		mr	r5,r3 
		addi	r4,r31,TC_MEMENTRY		#Link into TC_MEMENRY

		bl AddHeadPPC

		loadreg	r4,TASKATTR_NAME 
		li	r5,0				#defaultVal 
		mr	r6,r30				#TagList 
 
		bl GetTagDataPPC
 
		mr.	r3,r3 
		beq-	.Error04			#Error NoName 
 
		mr	r29,r3

		bl GetLen
 
		addi	r3,r3,1 
		mr	r4,r3 
		mr	r28,r3
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,0
		mr	r3,r23
 
 		bl AllocVec68K
 
		mr.	r3,r3 
		beq-	.Error04			#Error NoMem 
 
		mr	r22,r3 
		li	r4,24
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,0
		mr	r3,r23 
 
 		bl AllocVec68K
 
		mr.	r3,r3 
		beq-	.Error05			#Error NoMem 
 
		mr	r21,r3				#Link name mem into  
		li	r0,1				#TC_MEMENTRY 
		sth	r0,ML_NUMENTRIES(r3) 
		stw	r22,ML_SIZE+ME_ADDR(r3) 
		stw	r28,ML_SIZE+ME_LENGTH(r3) 
		mr	r5,r3 
		addi	r4,r31,TC_MEMENTRY

		bl AddHeadPPC

		mr	r3,r29
		mr	r4,r22
		stw	r4,LN_NAME(r31)
 
		bl CopyStr
 
 		loadreg r4,TASKATTR_SYSTEM
		li	r5,0 
		mr	r6,r30 
 
		bl GetTagDataPPC
 
		mr.	r3,r3 
		beq-	.NotSystemTask
 
		lis	r3,0 
		ori	r3,r3,1<<TASKPPC_SYSTEM 
		stw	r3,TASKPPC_FLAGS(r31)
 
.NotSystemTask:	loadreg	r4,TASKATTR_ATOMIC
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		mr.	r3,r3 
		beq-	.NotAtomicTask
 
		lis	r3,0 
		ori	r3,r3,1<<TASKPPC_ATOMIC
		lwz	r6,TASKPPC_FLAGS(r31) 
		or	r6,r6,r3 
		stw	r6,TASKPPC_FLAGS(r31)
.NotAtomicTask:	addi	r3,r31,TASKPPC_TASKPOOLS
		stw	r3,LH_TAILPRED(r3)
		li	r0,0 
		stwu	r0,LH_TAIL(r3)
		stwu	r3,LH_HEAD-4(r3)
 
 		loadreg	r4,TASKATTR_PRI
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		stb	r3,LN_PRI(r31)
 
 		loadreg	r4,TASKATTR_NICE
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		cmpwi	r3,-20				#Min/Max check -20 - 20 
		bge-	.AboveMin 
		li	r3,-20 
.AboveMin:	cmpwi	r3,20 
		ble-	.BelowMax 
		li	r3,20 
 
.BelowMax:	stw	r3,TASKPPC_NICE(r31)
 		loadreg	r4,TASKATTR_MOTHERPRI
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		mr.	r3,r3 
		beq-	.NoMotherPri

 		lwz	r3,ThisPPCProc(r23)		#Mother task
		lbz	r0,LN_PRI(r3) 
		extsb	r0,r0 
		stb	r0,LN_PRI(r31) 
		lwz	r3,TASKPPC_NICE(r3) 
		stw	r3,TASKPPC_NICE(r31)		#Copy PRI and NICE 
 
.NoMotherPri:	loadreg	r4,TASKATTR_STACKSIZE
		li	r5,0x4000
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		addi	r4,r3,0x1000			#Default = 0x4000 or asked+0x1000 
		stw	r4,TASKPPC_STACKSIZE(r31)
		mr	r29,r4 
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,0
		mr	r3,r23
 
 		bl AllocVec68K
 
		mr.	r3,r3 
		beq-	.Error06			#Error NoMem 
 
		mr	r28,r3 
		stw	r3,TC_SPLOWER(r31)
		add	r4,r3,r29 
		stw	r4,TC_SPUPPER(r31)
 
		subi	r4,r4,56			#Align SP on 32 
		loadreg r0,0xfffffff0
		and	r4,r4,r0 
		stw	r4,TC_SPREG(r31)
 
		li	r4,24 
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,0
		mr	r3,r23 
 
 		bl AllocVec68K
 
		mr.	r3,r3 
		beq-	.Error07			#Error NoMem 
 
		mr	r27,r3 
		stw	r3,TASKPPC_STACKMEM(r31)
 
		li	r0,1				#Link into TC_MEMENTRY 
		sth	r0,ML_NUMENTRIES(r3) 
		stw	r28,ML_SIZE+ME_ADDR(r3) 
		stw	r29,ML_SIZE+ME_LENGTH(r3) 
		mr	r5,r3 
		addi	r4,r31,TC_MEMENTRY

		bl AddHeadPPC
 
		li	r4,CONTEXT_LENGTH
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,0
		mr	r3,r23
 
 		bl AllocVec68K
 
		mr.	r3,r3 
		beq-	.Error08			#Error NoMem 
 
		stw	r3,TASKPPC_CONTEXTMEM(r31)
		mr	r26,r3
		lwz	r0,TC_SPREG(r31)
		stw	r0,CONTEXT_STACK(r26)		#r1 in context
 
		li	r4,24
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,0
		mr	r3,r23
 
 		bl AllocVec68K
 
		mr.	r3,r3 
		beq-	.Error09			#Error NoMem 
 
		mr	r24,r3				#Link into TC_MEMENTRY 
		li	r0,1 
		sth	r0,ML_NUMENTRIES(r3) 
		stw	r26,ML_SIZE+ME_ADDR(r3) 
		lis	r0,0 
		ori	r0,r0,CONTEXT_LENGTH 
		stw	r0,ML_SIZE+ME_LENGTH(r3) 
		mr	r5,r3 
		addi	r4,r31,TC_MEMENTRY

		bl AddHeadPPC

		loadreg	r0,MACHINESTATE_DEFAULT
		stw	r0,CONTEXT_SRR1(r26)		#f070 to srr1
		stw	r25,CONTEXT_CODE(r26)		#Code to srr0
		stw	r2,CONTEXT_TOC(r26)		#Mother r2 to TOC 
 
 		loadreg	r4,TASKATTR_BAT
		lis	r5,0 
		ori	r5,r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		addi	r4,r26,CONTEXT_BATS 
		li	r0,16 
		mtctr	r0 
 
		mr.	r3,r3 
		beq-	.NoBATs				#NoBATs 
 
		addi	r5,r23,BASE_STOREBAT0-4		#Default BATS in PowerPCBase
		lis	r3,0 
		ori	r3,r3,1<<TASKPPC_BAT
		lwz	r6,TASKPPC_FLAGS(r31) 
		or	r6,r6,r3 
		stw	r6,TASKPPC_FLAGS(r31) 
		b	.GetBATs 
 
.NoBATs:	addi	r5,r23,BASE_INVALBATS-4		#Invalid BATS in PowerPCBase
.GetBATs:	lwzu	r0,4(r5)			#PowerPCBase 
		stwu	r0,4(r4)			#ContextMem 416-476 104-119 
		bdnz+	.GetBATs 
 
		addi	r5,r23,BASE_INVALBATS-4		#Copy to TASKPPC_BATSTORAGE 
		subi	r4,r20,4 
		li	r0,16 
		mtctr	r0 
.ToStorage:	lwzu	r0,4(r5) 
		stwu	r0,4(r4) 
		bdnz+	.ToStorage 
  
		addi	r4,r26,CONTEXT_SEGMENTS		#480 in ContextMem (Segment Regs)
 
 		bl Super
 
 		mr	r6,r3
 
		li	r0,16
		mtctr	r0
		li	r3,0
		subi	r4,r4,4
.SegCpLoop:	mfsrin	r0,r3
		stwu	r0,4(r4)
		addis	r3,r3,4096
		bdnz+	.SegCpLoop
 
 		mr	r4,r6
 
 		bl User
 
 		loadreg	r4,TASKATTR_EXITCODE
		lwz	r5,sonnet_TaskExitCode(r23)
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		stw	r3,CONTEXT_LR(r26)		#Exit code. Default=0 
 
 		loadreg r4,TASKATTR_PRIVATE
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		mr.	r3,r3 
		beq-	.NotPrivate			#Not Private 
 
		ori	r3,r3,1 
		b	.DoPrivate 
 
.NotPrivate:	li	r4,0
		mr	r3,r23

		bl FindTaskPPC
 
.DoPrivate:	stw	r3,76(r26)			#Store MotherTask or 1 (prv) 
 
 		loadreg	r4,TASKATTR_INHERITR2
		li	r5,0 
		mr	r6,r30 
 
		bl GetTagDataPPC
 
		mr.	r3,r3 
		beq-	.NoInherit			#No Inherit 
 
		stw	r17,CONTEXT_TOC(r26)		#Mother r2 is originally 156
		b	.DoInherit 
 
.NoInherit:	loadreg	r4,TASKATTR_R2
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		stw	r3,CONTEXT_TOC(r26)		#r2 is originally 156
 
.DoInherit:	loadreg	r4,TASKATTR_R3
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		stw	r3,CONTEXT_R3(r26)		#r3 to ContextMem 44 orig 
 
 		loadreg	r4,TASKATTR_R4
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		stw	r3,CONTEXT_R4(r26)		#r4 to ContextMem 48 orig
 		
 		loadreg	r4,TASKATTR_R5
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		stw	r3,CONTEXT_R5(r26)		#r5 to ContextMem 52 orig
  
  		loadreg	r4,TASKATTR_R6
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		stw	r3,CONTEXT_R6(r26)		#r6 to ContextMem 56 orig
 
 		loadreg	r4,TASKATTR_R7
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		stw	r3,CONTEXT_R7(r26)		#r7 to ContextMem 60 orig
 
 		loadreg	r4,TASKATTR_R8
		li	r5,0 
		mr	r6,r30 
		
		bl GetTagDataPPC
 
		stw	r3,CONTEXT_R8(r26)		#r8 to ContextMem 64 orig
 
 		loadreg	r4,TASKATTR_R9
		li	r5,0 
		mr	r6,r30 
 
		bl GetTagDataPPC
	 
		stw	r3,CONTEXT_R9(r26)		#r9 to ContextMem 68 orig
 
 		loadreg	r4,TASKATTR_R10
		li	r5,0 
		mr	r6,r30 
 
		bl GetTagDataPPC 
 
		stw	r3,CONTEXT_R10(r26)		#r10 to ContextMem 72 orig
 
		li	r4,100
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,32
		mr	r3,r23
 
 		bl AllocVec68K
 
		mr.	r3,r3 
		beq-	.Error10			#Error NoMem 
 
		mr	r18,r3				#Setup a Semaphore & MsgPort 
		addi	r4,r18,MP_PPC_INTMSG
		stw	r4,LH_TAILPRED(r4) 
		li	r0,0 
		stwu	r0,LH_TAIL(r4) 
		stwu	r4,LH_HEAD-4(r4) 
 
		addi	r4,r18,MP_MSGLIST
		stw	r4,LH_TAILPRED(r4) 
		li	r0,0 
		stwu	r0,LH_TAIL(r4) 
		stwu	r4,LH_HEAD-4(r4) 
 
 		loadreg	r0,SYS_SIGALLOC
		stw	r0,TC_SIGALLOC(r31)
 
		li	r0,SIGB_DOS 			#SIGBIT = DOS
		stb	r0,MP_SIGBIT(r18)			 
		addi	r4,r18,MP_PPC_SEM
		mr	r3,r23
 
 		bl InitSemaphorePPC
	 
		cmpwi	r3,-1				#Error 
		bne-	.Error11 
 
		stw	r31,MP_SIGTASK(r18)
		li	r0,PA_SIGNAL 
		stb	r0,MP_FLAGS(r18)
		li	r0,NT_MSGPORTPPC 
		stb	r0,LN_TYPE(r18)
		stw	r18,TASKPPC_MSGPORT(r31)
 
		loadreg	r4,TASKATTR_NOTIFYMSG		#V16+ Never implemented in powerpc.lib
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
	 
		stw	r3,TASKPPC_POOLMEM(r31)

		li	r4,928
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,0
		mr	r3,r23
 
 		bl AllocVec68K
 
		mr.	r3,r3 
		beq-	.Error12			#Error NoMem 
 
		stw	r3,TASKPPC_MESSAGERIP(r31)
 
		mr	r16,r3 
 
		li	r4,18				#Dummy MirrorTask?
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,0
		mr	r3,r23
 
 		bl AllocVec68K
 
		mr.	r3,r3 
		beq-	.Error13			#Error NoMem 
 
		mr	r5,r3 
		stw	r31,TASKPTR_TASK(r5)		#Store Taskpointer 
		stw	r5,TASKPPC_TASKPTR(r31)
		lwz	r3,LN_NAME(r31)			#Copy Name pointer 
		stw	r3,LN_NAME(r5) 
 
		lwz	r4,sonnet_TaskListSem(r23)
		mr	r3,r23
 
 		bl ObtainSemaphorePPC
	 
	 	la	r4,LIST_ALLTASKS(r23)

	 	bl AddTailPPC				#Insert dummy task in list

		la	r4,NumAllTasks(r23)
		lwz	r3,0(r4)
		addi	r3,r3,1				#Set number of tasks
		stw	r3,0(r4) 
		dcbst	r0,r4				#Cache

 		lwz	r4,sonnet_TaskListSem(r23)
 		mr	r3,r23

		bl ReleaseSemaphorePPC

 		bl Super

		b	.Mojo4
.Mojo5:		mfspr	r0,HID0				#Invalidate ICache
		ori	r0,r0,HID0_ICFI			#Make sure code is in L1 Cache
		mtspr	HID0,r0
		xori	r0,r0,HID0_ICFI
		mtspr	HID0,r0
		isync
		b 	.Mojo6

.Mojo4:		b 	.Mojo5

.Mojo6:		mr	r4,r3

		bl User

.WaitAtomic01:	la	r4,sonnet_Atomic(r23)

		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitAtomic01			#Wait for Atomic

		lwz	r3,TASKPPC_FLAGS(r31)
		andi.	r0,r3,1<<TASKPPC_SYSTEM
		bne-	.SystemTask			#Yes -> Skip next

		lwz	r5,IdDefTasks(r23)		#Normal Tasks +1
		addi	r5,r5,1
		stw	r5,IdDefTasks(r23)
		b	.SkipSystem

.SystemTask:	lwz	r5,IdSysTasks(r23)		#System Tasks +1
		addi	r5,r5,1
		stw	r5,IdSysTasks(r23)

.SkipSystem:	stw	r5,TASKPPC_ID(r31)
		li	r0,TS_READY
		stb	r0,TC_STATE(r31)
		la	r4,LIST_READYTASKS(r23)
		mr	r5,r31				#Task
		loadreg	r0,Quantum
		stw	r0,TASKPPC_QUANTUM(r31)
#		lwz	r7,TASKPPC_NICE(r31)		
#		addi	r8,r7,20
#		rlwinm	r8,r8,2,0,29
#		lwz	r7,Table_NICE(r23)		#Getting DESIRED from a table
#		lwzx	r8,r7,r8
#		rlwinm	r8,r8,24,8,31
#		lis	r7,2000
#		ori	r7,r7,0
#		divwu	r0,r7,r8
#		stw	r0,TASKPPC_DESIRED(r31)

		bl InsertOnPri

		li	r0,-1 
		stb	r0,RescheduleFlag(r23)		#Reschedule flag 
 		la	r4,sonnet_Atomic(r23)

 		bl AtomicDone
 		
 		mr	r3,r23

		bl CauseInterrupt

		mr	r3,r31
		b	.SkipToEnd			#All good, go to exit
							#Error handling:
.Error13:	mr	r4,r16
		mr	r3,r23

		bl FreeVec68K

.Error12:	addi	r4,r18,MP_PPC_SEM
		lwz	r4,SSPPC_RESERVE(r4)
		mr	r3,r23

		bl FreeVec68K

.Error11:	mr	r4,r18
		mr	r3,r23

		bl FreeVec68K
 
.Error10:	mr	r4,r24
		mr	r3,r23

		bl FreeVec68K
 
.Error09:	mr	r4,r26
		mr	r3,r23

		bl FreeVec68K
 
.Error08:	mr	r4,r27
		mr	r3,r23

		bl FreeVec68K
 
.Error07:	mr	r4,r28
		mr	r3,r23

		bl FreeVec68K
 
.Error06:	mr	r4,r21
		mr	r3,r23

		bl FreeVec68K 
 
.Error05:	mr	r4,r22
		mr	r3,r23

		bl FreeVec68K
 
.Error04:	mr	r4,r19
		mr	r3,r23

		bl FreeVec68K
 
.Error03:	mr	r4,r20
		mr	r3,r23

		bl FreeVec68K
 
.Error02:	mr	r4,r31
		mr	r3,r23

		bl FreeVec68K

.Error01:	li	r3,0				#Error flag in r3 

.SkipToEnd:	mr	r5,r3
		lwz	r3,ThisPPCProc(r23)
		lwz	r4,TASKPPC_FLAGS(r3)
		ori	r4,r4,1<<TASKPPC_CHOWN 
		xori	r4,r4,1<<TASKPPC_CHOWN
		stw	r4,TASKPPC_FLAGS(r3) 

		mr	r3,r5				#Exit with task in r3 (or not)

		mr	r30,r23
		li	r31,FCreateTaskPPC-FRun68K
		bl	DebugEndFunction

		lwz	r16,0(r13) 
		lwz	r17,4(r13) 
		lwz	r18,8(r13) 
		lwz	r19,12(r13) 
		lwz	r20,16(r13) 
		lwz	r21,20(r13) 
		lwz	r22,24(r13) 
		lwz	r23,28(r13) 
		lwz	r24,32(r13) 
		lwz	r25,36(r13) 
		lwz	r26,40(r13) 
		lwz	r27,44(r13) 
		lwz	r28,48(r13) 
		lwz	r29,52(r13) 
		lwz	r30,56(r13) 
		lwz	r31,60(r13) 
		addi	r13,r13,64 

		epilog 'TOC'

#********************************************************************************************
#
#	Status = ChangeStack(PowerPCBase, NewStackSize) // r3=r3,r4
#
#********************************************************************************************

ChangeStack:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)

		li	r31,FChangeStack-FRun68K
		bl	DebugStartFunction

		mr	r26,r3
		mr	r29,r4	

		lwz	r28,ThisPPCProc(r26)
		lwz	r5,TASKPPC_STACKSIZE(r28)
		cmplw	r4,r5
		blt-	.SomeError

		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,0
		mr	r3,r26

		bl AllocVec68K

		mr.	r3,r3
		beq-	.SomeError

		mr	r30,r3

		li	r4,24
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,0
		mr	r3,r26
		
		bl AllocVec68K
		
		mr.	r3,r3
		beq-	.SomeError2

		stw	r3,TASKPPC_STACKMEM(r28)
		li	r0,1
		sth	r0,ML_NUMENTRIES(r3)
		stw	r30,ML_SIZE+ME_ADDR(r3)
		stw	r29,ML_SIZE+ME_LENGTH(r3)
		mr	r5,r3
		addi	r4,r28,TC_MEMENTRY

		bl AddHeadPPC

		lwz	r3,TC_SPLOWER(r28)
		lwz	r4,TC_SPUPPER(r28)
		mr	r27,r4
		add	r5,r30,r29
.StackLoop:	cmplw	r4,r3
		ble-	.DoneLoop

		lwzu	r0,-4(r4)
		stwu	r0,-4(r5)
		b	.StackLoop

.DoneLoop:	sub	r3,r27,r1
		stw	r30,TC_SPLOWER(r28)
		add	r6,r30,r29
		stw	r6,TC_SPUPPER(r28)
		stw	r29,TASKPPC_STACKSIZE(r28)
		sub	r1,r6,r3
		sub	r6,r6,r27
		mr	r4,r1
.StackLoop2:	lwz	r3,0(r4)
		mr.	r3,r3
		beq-	.DoneChange

		add	r3,r3,r6
		stw	r3,0(r4)
		mr	r4,r3
		b	.StackLoop2

.DoneChange:	li	r3,-1
		b	.ExitChange

.SomeError2:	mr	r4,r30
		mr	r3,r26

		bl FreeVec68K

.SomeError:	li	r3,0

.ExitChange:	lwz	r26,0(r13)
		lwz	r27,4(r13)
		lwz	r28,8(r13)
		lwz	r29,12(r13)
		lwz	r30,16(r13)
		lwz	r31,20(r13)
		addi	r13,r13,24
		
		epilog 'TOC'

#********************************************************************************************
#
#	TaskPPC = FindTaskPPC(PowerPCBase, Name) // r3=r3,r4
#
#********************************************************************************************

FindTaskPPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		li	r31,FFindTaskPPC-FRun68K
		bl	DebugStartFunction
		
		mr	r30,r3

		mr.	r4,r4
		bne-	.NotOwnTask

		lwz	r3,ThisPPCProc(r30)
		b	.ExitFind

.NotOwnTask:	mr	r31,r3
		mr	r5,r4

		lwz	r4,sonnet_TaskListSem(r30)
		mr	r3,r30

		bl ObtainSemaphorePPC

		addi	r4,r30,LIST_ALLTASKS
		mr	r3,r30
		
		bl FindNamePPC

		mr.	r3,r3
		beq-	.NameNotFound

		lwz	r3,TASKPTR_TASK(r3)		#Pointer to PPCTask in AllTasks list
.NameNotFound:	mr	r31,r3

		lwz	r4,sonnet_TaskListSem(r30)
		mr	r3,r30
		
		bl ReleaseSemaphorePPC

		mr	r3,r31

.ExitFind:	li	r31,FFindTaskPPC-FRun68K
		bl	DebugEndFunction

		lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8

		epilog 'TOC'

#********************************************************************************************
#
#	ExceptionMode = IsExceptionMode(PowerPCBase) // r3
#
#********************************************************************************************

IsExceptionMode:
		lbz	r3,sonnet_ExceptionMode(r3)
		blr
		
#********************************************************************************************
#
#	void ProcurePPC(PowerPCBase, SignalSemaphorePPC, SemaphoreMessage) // r3,r4,r5
#
#********************************************************************************************

ProcurePPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)

		li	r31,FProcurePPC-FRun68K
		bl	DebugStartFunction

		mr	r31,r3
		mr	r30,r4
		mr	r29,r5

		lwz	r28,ThisPPCProc(r3)
		stw	r28,SSM_SEMAPHORE(r29)
		lwz	r4,LN_NAME(r29)				#0 = Exclusive 1 = Shared
		stw	r4,LN_TYPE(r29)
		mr.	r4,r4
		beq-	.ExcLock
		li	r28,0

.ExcLock:	la	r4,sonnet_Atomic(r31)

		bl AtomicTest

		mr.	r3,r3
		beq+	.ExcLock

		lha	r5,SS_QUEUECOUNT(r30)
		addi	r5,r5,1
		sth	r5,SS_QUEUECOUNT(r30)
		extsh.	r0,r5
		bne-	.Queue
		stw	r28,SS_OWNER(r30)
.IsExclusive:	stw	r30,SSM_SEMAPHORE(r29)
		li	r0,0
		stw	r0,LN_TYPE(r29)
		lha	r5,SS_NESTCOUNT(r30)
		addi	r5,r5,1
		sth	r5,SS_NESTCOUNT(r30)

		la	r4,sonnet_Atomic(r31)
		
		bl AtomicDone

		mr	r4,r29
		mr	r3,r31
		
		bl ReplyMsgPPC

		b	.ProcureExit

.Queue:		lwz	r4,SS_OWNER(r30)
		cmplw	r4,r28
		beq+	.IsExclusive

		addi	r4,r30,SS_WAITQUEUE
		mr	r5,r29

		bl AddTailPPC

		la	r4,sonnet_Atomic(r31)

		bl AtomicDone

.ProcureExit:	lwz	r28,0(r13)
		lwz	r29,4(r13)
		lwz	r30,8(r13)
		lwz	r31,12(r13)
		addi	r13,r13,16

		epilog 'TOC'

#********************************************************************************************
#
#	void VacatePPC(PowerPCBase, SignalSemaphorePPC, SemaphoreMessage) // r3,r4,r5
#
#********************************************************************************************

VacatePPC:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

		li	r31,FVacatePPC-FRun68K
		bl	DebugStartFunction

		mr	r31,r3
		mr	r30,r4
		mr	r29,r5
		
		li	r0,0
		stw	r0,SSM_SEMAPHORE(r29)
		stw	r0,LN_TYPE(r29)

.AtomicVacate:	la	r4,sonnet_Atomic(r31)

		bl AtomicTest

		mr.	r3,r3
		beq+	.AtomicVacate

		mr	r4,r29
		lwz	r3,SS_WAITQUEUE(r30)
.NextSSM:	cmplw	r3,r4
		beq-	.OwnSSM

		mr	r29,r3
		lwz	r3,LN_SUCC(r29)
		mr.	r3,r3
		bne+	.NextSSM

		la	r4,sonnet_Atomic(r31)
		
		bl AtomicDone

		mr	r4,r30
		mr	r3,r31
		
		bl ReleaseSemaphorePPC

		b	.VacateExit

.OwnSSM:	lha	r5,SS_QUEUECOUNT(r30)
		subi	r5,r5,1
		sth	r5,SS_QUEUECOUNT(r30)
		mr	r5,r4
		
		bl RemovePPC

		la	r4,sonnet_Atomic(r31)
		
		bl AtomicDone

		mr	r4,r5
		mr	r3,r31

		bl ReplyMsgPPC

.VacateExit:	lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12

		epilog 'TOC'

#********************************************************************************************
#
#	SnoopID = SnoopTask(PowerPCBase, SnoopTags) // r3=r3,r4
#
#********************************************************************************************

SnoopTask:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

		li	r31,FSnoopTask-FRun68K
		bl	DebugStartFunction

		mr	r29,r3
		li	r31,0
		mr	r30,r4

		li	r4,26
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC
		li	r6,0

		bl AllocVec68K

		mr.	r3,r3
		beq-	.NoSnoop

		mr	r31,r3
		loadreg r4,SNOOP_CODE
		li	r5,0
		mr	r6,r30

		bl GetTagDataPPC

		mr.	r3,r3
		beq-	.NoSnoop

		stw	r3,14(r31)

		loadreg	r4,SNOOP_DATA
		li	r5,0
		mr	r6,r30
		
		bl GetTagDataPPC

		stw	r3,18(r31)

		loadreg r4,SNOOP_TYPE
		li	r5,0
		mr	r6,r30

		bl GetTagDataPPC

		mr.	r3,r3
		beq-	.NoSnoop

		cmplwi	r3,SNOOP_START
		beq-	.SnoopStart

		cmplwi	r3,SNOOP_EXIT
		bne-	.NoSnoop

.SnoopStart:	stw	r3,22(r31)

		lwz	r4,sonnet_SnoopSem(r29)
		mr	r3,r29
		
		bl ObtainSemaphorePPC

		addi	r4,r29,LIST_SNOOP
		mr	r5,r31

		bl AddHeadPPC

		lwz	r4,sonnet_SnoopSem(r29)
		mr	r3,r29
		
		bl ReleaseSemaphorePPC

		mr	r30,r31
		b	.Snooping

.NoSnoop:	li	r30,0
		mr.	r31,r31
		beq-	.Snooping
		
		mr	r4,r31
		mr	r3,r29
		
		bl FreeVec68K

.Snooping:	mr	r3,r30
		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12

		epilog 'TOC'

#********************************************************************************************
#
#	void EndSnoopTask(PowerPCBase, SnoopID) // r3,r4
#
#********************************************************************************************
		
EndSnoopTask:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		li	r31,FEndSnoopTask-FRun68K
		bl	DebugStartFunction

		mr	r30,r3
		mr	r31,r4

		mr.	r31,r31
		beq-	.NoEndSnoop

		lwz	r4,sonnet_SnoopSem(r3)
		
		bl ObtainSemaphorePPC

		mr	r4,r31
		
		bl RemovePPC

		lwz	r4,sonnet_SnoopSem(r30)
		mr	r3,r30
		
		bl ReleaseSemaphorePPC

		mr	r4,r31
		mr	r3,r30
		
		bl FreeVec68K

.NoEndSnoop:	lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		epilog 'TOC'

#********************************************************************************************
#
#	void ObtainSemaphoreSharedPPC(PowerPCBase, SignalSemaphorPPC) // r3,r4
#
#********************************************************************************************

ObtainSemaphoreSharedPPC:
		
		prolog 228,'TOC'

		mfctr	r0
		stwu	r0,-4(r13)
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r12,-4(r13)
		stwu	r11,-4(r13)
		stwu	r10,-4(r13)
		stwu	r9,-4(r13)
		stwu	r8,-4(r13)
		stwu	r7,-4(r13)
		stwu	r6,-4(r13)
		stwu	r5,-4(r13)
		stwu	r4,-4(r13)
		stwu	r3,-4(r13)

		li	r31,FObtainSemaphoreSharedPPC-FRun68K
		bl	DebugStartFunction

		mr	r28,r3
		lwz	r31,ThisPPCProc(r3)
		mr	r30,r4
		
.SharedAtomic:	la	r4,sonnet_Atomic(r28)
		
		bl AtomicTest

		mr.	r3,r3
		beq+	.SharedAtomic

		lha	r5,SS_QUEUECOUNT(r30)
		addi	r5,r5,1
		sth	r5,SS_QUEUECOUNT(r30)
		extsh.	r0,r5
		bne-	.SharedQ

		la	r4,sonnet_Atomic(r28)
		
		bl AtomicDone

		b	.ExitShared

.SharedQ:	mr	r3,r31
		lwz	r4,SS_OWNER(r30)
		mr.	r4,r4
		bne-	.HasOwner

		la	r4,sonnet_Atomic(r28)

		bl AtomicDone

		b	.ExitShared

.HasOwner:	cmplw	r3,r4
		bne-	.NotOwner

		la	r4,sonnet_Atomic(r28)
		
		bl AtomicDone

		b	.ExitShared

.NotOwner:	stwu	r29,-4(r13)
		mr	r29,r13
		subi	r13,r13,12
		subi	r5,r29,12
		addi	r3,r3,1				#Mark it shared!
		stw	r3,8(r5)
		lwz	r4,TC_SIGRECVD(r3)
		ori	r4,r4,16
		xori	r4,r4,16
		stw	r4,TC_SIGRECVD(r3)		
		addi	r4,r30,SS_WAITQUEUE

		bl AddTailPPC

		la	r4,sonnet_Atomic(r28)
		
		bl AtomicDone

		lis	r4,0
		ori	r4,r4,SIGF_SINGLE
		mr	r3,r28
		
		bl WaitPPC

		mr	r13,r29
		lwz	r29,0(r13)
		addi	r13,r13,4
		b	.DoneShared

.ExitShared:	lha	r5,SS_NESTCOUNT(r30)
		addi	r5,r5,1
		sth	r5,SS_NESTCOUNT(r30)

.DoneShared:	lwz	r3,0(r13)
		lwz	r4,4(r13)
		lwz	r5,8(r13)
		lwz	r6,12(r13)
		lwz	r7,16(r13)
		lwz	r8,20(r13)
		lwz	r9,24(r13)
		lwz	r10,28(r13)
		lwz	r11,32(r13)
		lwz	r12,36(r13)
		lwz	r28,40(r13)
		lwz	r29,44(r13)
		lwz	r30,48(r13)
		lwz	r31,52(r13)
		addi	r13,r13,56
		lwz	r0,0(r13)
		addi	r13,r13,4
		mtctr	r0

		epilog 'TOC'

#********************************************************************************************
#
#	status = AttemptSemaphoreSharedPPC(PowerPCBase, SignalSemaphorPPC) // r3,r4
#
#********************************************************************************************

AttemptSemaphoreSharedPPC:

		prolog 228,'TOC'

		mfctr	r0
		stwu	r0,-4(r13)
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r12,-4(r13)
		stwu	r11,-4(r13)
		stwu	r10,-4(r13)
		stwu	r9,-4(r13)
		stwu	r8,-4(r13)
		stwu	r7,-4(r13)
		stwu	r6,-4(r13)
		stwu	r5,-4(r13)
		stwu	r4,-4(r13)

		li	r31,FAttemptSemaphoreSharedPPC-FRun68K
		bl	DebugStartFunction

		mr	r29,r3
		lwz	r31,ThisPPCProc(r3)
		mr	r30,r4

.SharedAttempt:	la	r4,sonnet_Atomic(r29)

		bl AtomicTest

		mr.	r3,r3
		beq+	.SharedAttempt

		lha	r5,SS_QUEUECOUNT(r30)
		addi	r5,r5,1
		mr	r3,r31
		mr.	r5,r5
		beq-	.NoQ

		lwz	r4,SS_OWNER(r30)
		mr.	r4,r4
		beq-	.NoQ

		cmplw	r3,r4
		beq-	.NoQ

		li	r6,ATTEMPT_FAILURE
		b	.ItFailed

.NoQ:		sth	r5,SS_QUEUECOUNT(r30)
		lha	r5,SS_NESTCOUNT(r30)
		addi	r5,r5,1
		sth	r5,SS_NESTCOUNT(r30)
		li	r6,ATTEMPT_SUCCESS

.ItFailed:	la	r4,sonnet_Atomic(r29)

		bl AtomicDone

		mr	r3,r6
		lwz	r4,0(r13)
		lwz	r5,4(r13)
		lwz	r6,8(r13)
		lwz	r7,12(r13)
		lwz	r8,16(r13)
		lwz	r9,20(r13)
		lwz	r10,24(r13)
		lwz	r11,28(r13)
		lwz	r12,32(r13)
		lwz	r29,36(r13)
		lwz	r30,40(r13)
		lwz	r31,44(r13)
		addi	r13,r13,48
		lwz	r0,0(r13)
		addi	r13,r13,4
		mtctr	r0

		epilog 'TOC'

#********************************************************************************************
#
#	Support: void CauseInterrupt(PowerPCBase) // causing the system call interrupt
#
#********************************************************************************************

CauseInterrupt:

		prolog 228,'TOC'

		stwu	r31,-4(r13)

		lbz	r0,sonnet_ExceptionMode(r3)
		mr.	r0,r0
		bne	.AlreadyInExc

		bl Super

		mr	r4,r3
		li	r3,10
		mtdec	r3

		bl User

.AlreadyInExc:	lwz	r31,0(r13)
		addi	r13,r13,4

		epilog 'TOC'

#********************************************************************************************
#
#	Support: oldSignals = CheckExcSignal(PowerPCBase, Task, Signal) // r3=r3,r4,r5
#
#********************************************************************************************		
		
CheckExcSignal:		
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		
		mr	r31,r3
		mr	r7,r4
		mr	r8,r5

.DoAtomic:	la	r4,sonnet_Atomic(r31)

		bl AtomicTest

		mr.	r3,r3
		beq+	.DoAtomic

		lwz	r5,TC_SIGRECVD(r7)
		or	r9,r5,r8
		lwz	r6,TC_SIGEXCEPT(r7)
		and.	r4,r9,r6
		beq-	.NonePending

		andc	r8,r8,r4
		or	r5,r5,r4
		stw	r5,TC_SIGRECVD(r7)
		
		stw	r7,sonnet_TaskExcept(r31)
		
		mr	r3,r31

		bl CauseInterrupt

.IntWait2:	lwz	r0,sonnet_TaskExcept(r31)
		mr.	r0,r0
		bne+	.IntWait2

.NonePending:	la	r4,sonnet_Atomic(r31)

		bl AtomicDone
	
		mr	r3,r8
		
		lwz	r31,0(r13)
		addi	r13,r13,4
		
		epilog 'TOC'

#********************************************************************************************
#
#	oldSignals = SetExceptPPC(PowerPCBase, newSignals, signalMask, flag) // r3=r3,r4,r5,r6
#
#********************************************************************************************

SetExceptPPC:	
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)

		li	r31,FSetExceptPPC-FRun68K
		bl	DebugStartFunction

		mr	r27,r3
		mr	r29,r6
		mr	r28,r2

		lwz	r6,ThisPPCProc(r3)
		mr	r30,r4

.DoAtomic2:	la	r4,sonnet_Atomic(r27)

		bl AtomicTest

		mr.	r3,r3
		beq+	.DoAtomic2

		lwz	r31,TC_SIGEXCEPT(r6)
		and	r30,r30,r5
		andc	r7,r31,r5
		or	r30,r30,r7
		stw	r30,TC_SIGEXCEPT(r6)
		mr.	r29,r29
		beq-	.NoPassR2

		stw	r28,TC_EXCEPTDATA(r6)

.NoPassR2:	la	r4,sonnet_Atomic(r27)

		bl AtomicDone

		mr	r3,r27
		mr	r4,r6
		li	r5,0
		
		bl CheckExcSignal

		mr	r3,r31

		lwz	r27,0(r13)
		lwz	r28,4(r13)
		lwz	r29,8(r13)
		lwz	r30,12(r13)
		lwz	r31,16(r13)
		addi	r13,r13,20

		epilog 'TOC'
		
#********************************************************************************************
#
#	support: void EndTaskPPC(void)
#
#********************************************************************************************

EndTaskPPC:
		bl Super
		
		lwz	r31,PowerPCBase(r0)		#zero page will be soon privileged
		mr	r3,r4
		
		bl User
		
		mr	r3,r31
		li	r4,0
		
		b DeleteTaskPPC


#********************************************************************************************
#
#	void DeleteTaskPPC(PowerPCBase, PPCTask) // r3,r4
#
#********************************************************************************************

DeleteTaskPPC:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)
		
		li	r31,FDeleteTaskPPC-FRun68K
		bl	DebugStartFunction
		
		mr	r30,r3

		lwz	r5,ThisPPCProc(r30)		#ThisTask
		li	r29,0
		cmpw	r4,r5				#To be deleted?
		beq-	.DelOwnTask			#Yes: then r29=-1
		mr.	r4,r4
		bne-	.DelOtherTask			#Other task then r29=0
.DelOwnTask:	li	r29,-1				#0 then r29=0 (owntask)
		mr	r4,r5
.DelOtherTask:	mr	r31,r4				#task to r31

		lwz	r4,sonnet_SnoopSem(r30)
		mr	r3,r30
		
		bl ObtainSemaphorePPC

		lwz	r28,LIST_SNOOP(r30)
.Loop100:	lwz	r27,0(r28)
		mr.	r27,r27
		beq-	.EmptySnoopLst

		lwz	r4,22(r28)			#Snoop type (START or EXIT)
		cmplwi	r4,SNOOP_EXIT
		bne-	.Link100
		lwz	r3,14(r28)			#SNOOP_CODE
		mtlr	r3
		mr	r26,r2
		lwz	r2,18(r28)			#SNOOP_DATA
		mr	r3,r31
		blrl					#Jump to snoop exit code

		mr	r2,r26
.Link100:	mr	r28,r27
		b	.Loop100

.EmptySnoopLst:	lwz	r4,sonnet_SnoopSem(r30)
		mr	r3,r30
		
		bl ReleaseSemaphorePPC

		lwz	r4,TASKPPC_MSGPORT(r31)
		mr.	r27,r4
		beq-	.NoMsgPort

		addi	r4,r27,MP_PPC_SEM
		lwz	r4,SSPPC_RESERVE(r4)
		mr	r3,r30

		bl FreeVec68K

		mr	r4,r27
		mr	r3,r30
		
		bl FreeVec68K

.NoMsgPort:	lwz	r4,sonnet_TaskListSem(r30)
		mr	r3,r30
		
		bl ObtainSemaphorePPC

		lwz	r4,TASKPPC_TASKPTR(r31)

		mr.	r4,r4
		beq	.NoTaskPtr

		bl RemovePPC		

.NoTaskPtr:	la	r4,NumAllTasks(r30)		#Tasks -1
		lwz	r3,0(r4)
		subi	r3,r3,1
		stw	r3,0(r4)
		dcbst	r0,r4

		lwz	r4,sonnet_TaskListSem(r30)
		mr	r3,r30
		
		bl ReleaseSemaphorePPC

		lwz	r3,ThisPPCProc(r30)
		lwz	r26,TASKPPC_MIRRORPORT(r3)		
		mr.	r26,r26
		beq	.NoMirror

		bl CreateMsgFramePPC
		
		mr	r4,r3
		stw	r26,MN_MIRROR(r4)
		loadreg	r26,'END!'
		stw	r26,MN_IDENTIFIER(r4)
		
		bl SendMsgFramePPC			#Send kill signal to mirror 68K task

.NoMirror:	mr.	r29,r29				#This task?
		beq-	.NotOwnTask2			#no? Skip next
		li	r0,TS_REMOVED
		stb	r0,TC_STATE(r31)
		li	r0,-1
		stb	r0,RescheduleFlag(r30)		#Reschedule
		
		mr	r3,r30
		
		bl CauseInterrupt

.EndTask:	b	.EndTask			#Halt this Task

.NotOwnTask2:	la	r4,sonnet_Atomic(r30)

		bl AtomicTest

		mr.	r3,r3			
		beq+	.NotOwnTask2			#Wait Atomic

		mr	r4,r31
		
		bl RemovePPC

		mr	r5,r31		
		la	r4,LIST_REMOVEDTASKS(r30)	#Deleted task list at base
		
		bl AddTailPPC				#In WarpOS a seperate task takes care of all freemems (TC_MEMENTRY)

		li	r0,TS_REMOVED
		stb	r0,TC_STATE(r31)

		la	r4,sonnet_Atomic(r30)
		
		bl AtomicDone

		li	r31,FDeleteTaskPPC-FRun68K
		bl	DebugEndFunction

		lwz	r26,0(r13)
		lwz	r27,4(r13)
		lwz	r28,8(r13)
		lwz	r29,12(r13)
		lwz	r30,16(r13)
		lwz	r31,20(r13)
		addi	r13,r13,24

		epilog 'TOC'

#********************************************************************************************
#
#	Status = SetHardware(PowerPCBase, hardwareflags, parameter) // r3=r3,r4,r5
#
#********************************************************************************************

SetHardware:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		
		li	r31,FSetHardware-FRun68K
		bl	DebugStartFunction
		
		cmplwi	r4,HW_TRACEON
		beq-	.TraceOn
		cmplwi	r4,HW_TRACEOFF
		beq-	.TraceOff
		cmplwi	r4,HW_BRANCHTRACEON
		beq-	.BranchOn
		cmplwi	r4,HW_BRANCHTRACEOFF
		beq-	.BranchOff
		cmplwi	r4,HW_FPEXCON
		beq-	.FPExcOn
		cmplwi	r4,HW_FPEXCOFF
		beq-	.FPExcOff
		cmplwi	r4,HW_SETIBREAK
		beq-	.SetIBreak
		cmplwi	r4,HW_CLEARIBREAK
		beq-	.ClearIBreak
		cmplwi	r4,HW_SETDBREAK
		beq-	.SetDBreak
		cmplwi	r4,HW_CLEARDBREAK
		beq-	.ClearDBreak
		cmplwi	r4,HW_CPUTYPE
		beq-	.CPUType
		cmplwi	r4,HW_SETDEBUGMODE
		beq-	.SetDebugMode
		cmplwi	r4,HW_PPCSTATE
		beq-	.PPCState
		b	.HWEnd

.TraceOn:	bl Super

		mfmsr	r0
		ori	r0,r0,PSL_SE
		mtmsr	r0
		isync	
		sync
		mr	r4,r3
		
		bl User

		b	.HWEnd
		
.TraceOff:	bl Super

		mfmsr	r0
		ori	r0,r0,PSL_SE
		xori	r0,r0,PSL_SE
		mtmsr	r0
		isync	
		sync	
		mr	r4,r3
		
		bl User

		b	.HWEnd

.BranchOn:	bl Super

		mfmsr	r0
		ori	r0,r0,PSL_BE
		mtmsr	r0
		isync	
		sync	
		mr	r4,r3
		
		bl User

		b	.HWEnd

.BranchOff:	bl Super

		mfmsr	r0
		ori	r0,r0,PSL_BE
		xori	r0,r0,PSL_BE
		mtmsr	r0
		isync	
		sync	
		mr	r4,r3
		
		bl User

		b	.HWEnd

.FPExcOn:	bl Super

		mtfsfi	1,0
		mtfsfi	2,0
		mtfsb0	3
		mtfsb0	12
		mtfsb0	21
		mtfsb0	22
		mtfsb0	23
		mfmsr	r0
		ori	r0,r0,PSL_FE0|PSL_FE1
		mtmsr	r0
		isync	
		sync	
		mr	r4,r3
		
		bl User

		b	.HWEnd

.FPExcOff:	bl Super

		mfmsr	r0
		ori	r0,r0,PSL_FE0|PSL_FE1
		xori	r0,r0,PSL_FE0|PSL_FE1
		mtmsr	r0
		isync	
		sync	
		mr	r4,r3

		bl User

		b	.HWEnd
		
.SetIBreak:	bl Super
		
		mr	r4,r5
		loadreg	r0,0xfffffffc
		and	r4,r4,r0
		ori	r4,r4,3
		mtspr	IABR,r4
		mr	r4,r3

		bl User

		b	.HWEnd

.ClearIBreak:	bl Super

		li	r0,0
		mtspr	IABR,r0
		mr	r4,r3
		
		bl User

		b	.HWEnd

.SetDBreak:	bl Super
		
		mr	r4,r5
		loadreg	r0,0xfffffff8
		and	r4,r4,r0		
		ori	r4,r4,7
		mtspr	DABR,r4
		mr	r4,r3
		
		bl User
		
		b	.HWEnd

.ClearDBreak:	bl Super

		li	r0,0
		mtspr	DABR,r0
		mr	r4,r3
		
		bl User
		
		b	.HWEnd
		
.CPUType:	lwz	r3,sonnet_CPUInfo(r3)

		b	.PrivateEnd
		
.SetDebugMode:	stb	r5,sonnet_DebugLevel(r3)

		b	.HWEnd
		
.PPCState:	mr	r31,r3
		lwz	r5,LIST_WAITINGTASKS(r3)
		li	r3,PPCSTATEF_POWERSAVE
		lwz	r5,0(r5)
		mr.	r5,r5
		beq	.NoWaiting
		
		li	r3,PPCSTATEF_APPACTIVE
.NoWaiting:	lwz	r5,ThisPPCProc(r31)
		mr.	r5,r5
		beq	.PrivateEnd
		
		li	r3,PPCSTATEF_APPRUNNING
		b	.PrivateEnd
		
.HWEnd:		li	r4,HW_AVAILABLE
		mr	r3,r4

.PrivateEnd:	lwz	r31,0(r13)
		addi	r13,r13,4

		epilog 'TOC'

#********************************************************************************************
#
#	Poolheader = CreatePoolPPC(PowerPCBase, attr, puddlesize, treshsize) // r3=r3,r4,r5,r6 r4 is ignored
#
#********************************************************************************************		

CreatePoolPPC:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)

		li	r31,FCreatePoolPPC-FRun68K
		bl	DebugStartFunction
			
		mr	r27,r3	
		li	r31,0
		
		cmplw	r5,r6
		blt	.NoCreatePool
	
		addi	r30,r5,31
		loadreg r29,0xffffffe0
		and	r30,r30,r29
		
		mr	r29,r4
		mr	r28,r6
		
		li	r4,POOL_SIZE				#struct Pool
		mr	r5,r29
		li	r6,32
		
		bl AllocVec68K
		
		mr.	r31,r3
		beq-	.NoCreatePool
		
		la	r4,POOL_PUDDLELIST(r31)
		
		bl NewListPPC
		
		la	r4,POOL_BLOCKLIST(r31)
		
		bl NewListPPC
		
		stw	r29,POOL_REQUIREMENTS(r31)
		stw	r30,POOL_PUDDLESIZE(r31)
		stw	r28,POOL_TRESHSIZE(r31)
		
		addi	r5,r31,36				#r5 = node
		lwz	r4,ThisPPCProc(r27)
		la 	r4,TASKPPC_TASKPOOLS(r4)
		
		bl AddHeadPPC

.NoCreatePool:	mr	r3,r31
		mr	r30,r27
		li	r31,FCreatePoolPPC-FRun68K
		bl	DebugEndFunction

		lwz	r27,0(r13)
		lwz	r28,4(r13)
		lwz	r29,8(r13)
		lwz	r30,12(r13)
		lwz	r31,16(r13)
		addi	r13,r13,20
		
		epilog 'TOC'

#********************************************************************************************
#
#	void DeletePoolPPC(PowerPCBase, poolheader) // r3,r4
#
#********************************************************************************************

DeletePoolPPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		li	r31,FDeletePoolPPC-FRun68K
		bl	DebugStartFunction

		mr	r30,r3
		mr.	r31,r4
		beq-	.NoHeader
		
		lwz	r4,sonnet_MemSem(r3)
		
		bl ObtainSemaphorePPC
		
		addi	r4,r31,36

		bl RemovePPC
		
.NextPuddle:	la	r4,POOL_PUDDLELIST(r31)
		
		bl RemHeadPPC
		
		mr.	r4,r3
		beq	.NextBlock
		
		mr	r3,r30
		
		bl FreeVec68K
		
		b	.NextPuddle
	
.NextBlock:	la	r4,POOL_BLOCKLIST(r31)

		bl RemHeadPPC
		
		mr.	r4,r3
		beq	.AllFreed
		
		mr	r3,r30
		
		bl FreeVec68K
		
		b	.NextBlock
		
.AllFreed:	mr	r4,r31
		mr	r3,r30
		
		bl FreeVec68K
		
		lwz	r4,sonnet_MemSem(r30)
		mr	r3,r30
		
		bl ReleaseSemaphorePPC
		
.NoHeader:	lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		epilog 'TOC'

#********************************************************************************************
#
#	memory = AllocPooledPPC(PowerPCBase, poolheader, size) // r3=r3,r4,r5
#
#********************************************************************************************

AllocPooledPPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)
		stwu	r25,-4(r13)

		li	r31,FAllocPooledPPC-FRun68K
		bl	DebugStartFunction

		mr	r25,r3
		mr	r31,r4
		mr	r30,r5
		
		lwz	r4,sonnet_MemSem(r3)
		
		bl ObtainSemaphorePPC
		
		lwz	r29,POOL_TRESHSIZE(r31)
		
		cmplw	r29,r30
		bge	.DoPuddle
		
		addi	r4,r30,32			#Make room for Node, 32 aligned
		lwz	r5,POOL_REQUIREMENTS(r31)
		li	r6,32
		mr	r3,r25
		
		bl AllocVec68K
		
		mr.	r28,r3
		beq-	.ExitPooledMem

		mr	r5,r3				
		li	r0,0
		stw	r0,0(r5)
		stw	r0,4(r5)		
		mr	r29,r5		
		la	r4,POOL_BLOCKLIST(r31)
				
		bl AddHeadPPC
		
		li	r3,NT_MEMORY
		stb	r3,LN_TYPE(r28)
		
		addi	r3,r28,32			#Return memory
		addi	r5,r30,32
		stw	r5,-4(r3)

		b	.ExitPooledMem
		
.DoPuddle:	la	r4,POOL_PUDDLELIST(r31)

		bl	RemHeadPPC
		
		mr.	r4,r3
		beq	.MakeHeader
		
.LoopBack:	mr	r27,r4
		addi	r5,r30,32
		
		bl AllocatePPC				#mh, size
		
		mr.	r26,r3
		beq	.MakeHeader2		

		lwz	r5,POOL_PUDDLESIZE(r31)
		rlwinm	r5,r5,24,8,31			#Establish granularity
		lwz	r4,MH_FREE(r27)
		divwu	r4,r4,r5			
		addi	r4,r4,0x80			#Establish priority based on free space
		stb	r4,LN_PRI(r27)
		
		la	r4,POOL_PUDDLELIST(r31)
		mr	r5,r27
		
		bl 	EnqueuePPC
				
		addi	r30,r30,32
		addi	r3,r26,32
		stw	r30,-4(r3)

		b	.ExitPooledMem

.MakeHeader2:	la	r4,POOL_PUDDLELIST(r31)
		mr	r5,r27
		
		bl	AddHeadPPC

.MakeHeader:	lwz	r4,POOL_PUDDLESIZE(r31)	
		addi	r4,r4,MH_SIZE
		lwz	r5,POOL_REQUIREMENTS(r31)
		li	r6,32
		mr	r3,r25
		
		bl AllocVec68K
		
		mr.	r5,r3
		
		beq-	.ExitPooledMem
		
		addi	r4,r5,MH_SIZE
		stw	r4,MH_FIRST(r5)
		stw	r4,MH_LOWER(r5)
		li	r3,NT_MEMORY
		stb	r3,LN_TYPE(r5)
		lwz	r3,POOL_REQUIREMENTS(r31)
		sth	r3,MH_ATTRIBUTES(r5)
		li	r3,0
		stw	r3,MC_NEXT(r4)
		lwz	r3,POOL_PUDDLESIZE(r31)
		stw	r3,MC_BYTES(r4)
		stw	r3,MH_FREE(r5)
		add	r4,r4,r3
		stw	r4,MH_UPPER(r5)		
		la	r4,POOL_PUDDLELIST(r31)
		mr	r4,r5

		b	.LoopBack
		
.ExitPooledMem:	mr	r30,r3
		lwz	r4,sonnet_MemSem(r25)
		mr	r3,r25
		
		bl ReleaseSemaphorePPC
		
		mr	r3,r30
		mr	r30,r25
		li	r31,FAllocPooledPPC-FRun68K
		bl	DebugEndFunction

		lwz	r25,0(r13)
		lwz	r26,4(r13)
		lwz	r27,8(r13)
		lwz	r28,12(r13)
		lwz	r29,16(r13)
		lwz	r30,20(r13)
		lwz	r31,24(r13)
		addi	r13,r13,28
		
		epilog 'TOC'

#********************************************************************************************
#
#	support: memory = AllocatePPC(Memheader, byteSize) // r3=r4,r5
#
#********************************************************************************************

AllocatePPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)		
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)

		mr.	r3,r5
		beq-	.ExitAlloc
		
		mr	r31,r5
		mr	r30,r4
		addi	r31,r31,31			#Check: Original was 7
		loadreg	r29,0xffffffe0
		and	r31,r31,r29			
		
		lwz	r29,MH_FREE(r30)
		cmplw	r31,29
		ble	.EnoughRoom
		
		li	r3,0
		
		b	.ExitAlloc
		
.EnoughRoom:	la	r4,MH_FIRST(r30)
				
.NextChunk:	lwz	r5,MC_NEXT(r4)
		mr.	r3,r5
		
		beq-	.ExitAlloc
		
		lwz	r29,MC_BYTES(r5)
		cmplw	r31,r29
		bgt	.TooBeaucoup
		bne	.NotPerfect				

		lwz	r29,MC_NEXT(r5)
		stw	r29,MC_NEXT(r4)		
		mr	r3,r5
		
		b	.SetFree

.NotPerfect:	add	r28,r5,r31
		lwz	r29,MC_NEXT(r5)
		stw	r29,MC_NEXT(r28)
		lwz	r29,MC_BYTES(r5)
		sub	r29,r29,r31
		stw	r29,MC_BYTES(r28)
		stw	r28,MC_NEXT(r4)
		mr	r3,r5
		
		b	.SetFree
		
.TooBeaucoup:	lwz	r4,MC_NEXT(r4)
		mr.	r4,r4
		
		bne	.NextChunk
		
		li	r3,0
		
		b	.ExitAlloc

.SetFree:	lwz	r29,MH_FREE(r30)
		sub	r29,r29,r31
		stw	r29,MH_FREE(r30)
		
		subi	r28,r3,1
		mfctr	r29
		mtctr	r31
		li	r30,0
.ClearAlloc:	stbu	r30,1(r28)
		bdnz	.ClearAlloc
		mtctr	r29

.ExitAlloc:	lwz	r28,0(r13)
		lwz	r29,4(r13)
		lwz	r30,8(r13)
		lwz	r31,12(r13)
		addi	r13,r13,16
		
		epilog 'TOC'

#********************************************************************************************
#
#	support: void DeallocatePPC(Memheader, memoryBlock, byteSize) // r4,r5,r6(a0,a1,d0)
#
#********************************************************************************************

DeallocatePPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)

		mr.	r31,r6		
		beq 	.ExitDealloc
		
		mr	r29,r4
		loadreg	r28,-32
		and	r30,r5,r28
		sub	r5,r5,r30
		add	r6,r5,r31
		addi	r6,r6,31
		and.	r6,r6,r28
		
		beq	.ExitDealloc
		
		la	r28,MH_FIRST(r29)
		lwz	r27,MC_NEXT(r28)
		mr.	r27,r27
		
		beq	.LinkNewMC
		
.NextMemChunk:	cmplw	r27,r30

		bgt	.CorrectMC
		beq	.GuruTime
		
		mr	r28,r27
		lwz	r27,MC_NEXT(r28)
		mr.	r27,r27
		
		bne	.NextMemChunk
		
.CorrectMC:	la	r26,MH_FIRST(r29)
		cmplw	r28,r26
		
		beq	.LinkNewMC
		
		lwz	r27,MC_BYTES(r28)
		add	r27,r27,r28
		cmplw	r30,r27

		beq	.JoinThem
		blt	.GuruTime
		
.LinkNewMC:	lwz	r27,MC_NEXT(r28)
		stw	r27,MC_NEXT(r30)
		stw	r30,MC_NEXT(r28)		
		stw	r6,MC_BYTES(r30)
		
		b	.DoNextMC
		
.JoinThem:	lwz	r27,MC_BYTES(r28)
		add	r27,r27,r6
		stw	r27,MC_BYTES(r28)
		mr	r30,r28
				
.DoNextMC:	lwz	r26,MC_NEXT(r30)
		mr.	r26,r26
		
		beq	.UpdateFree
		
		lwz	r27,MC_BYTES(r30)
		add	r27,r27,r30
		cmplw	r26,r27
		
		blt	.GuruTime
		bne	.UpdateFree
		
		mr	r28,r26
		lwz	r27,MC_NEXT(r28)
		stw	r27,MC_NEXT(r30)
		lwz	r27,MC_BYTES(r28)
		lwz	r26,MC_BYTES(r30)
		add	r27,r27,r26
		stw	r27,MC_BYTES(r30)
						
.UpdateFree:	lwz	r27,MH_FREE(r29)
		add	r27,r27,r6
		stw	r27,MH_FREE(r29)		
		
.ExitDealloc:	lwz	r26,0(r13)
		lwz	r27,4(r13)
		lwz	r28,8(r13)
		lwz	r29,12(r13)
		lwz	r30,16(r13)
		lwz	r31,20(r13)
		addi	r13,r13,24
		
		epilog 'TOC'
		
#********************************************************************************************

.GuruTime:	loadreg	r0,'MEM!'
		
		illegal

.GTHalt:	b	.GTHalt			#STUB

#********************************************************************************************
#
#	void FreePooledPPC(PowerPCBase, poolheader, memory, size) // r3,r4,r5,r6
#
#********************************************************************************************

FreePooledPPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)

		li	r31,FFreePooledPPC-FRun68K
		bl	DebugStartFunction

		mr	r27,r3
		mr	r31,r4
		mr.	r30,r5		
		beq	.ExitPoolZero

		mr.	r28,r6
		bne	.NoAmnesia

		lwz	r28,-4(r30)
		subi	r28,r28,32
		
.NoAmnesia:	lwz	r4,sonnet_MemSem(r3)
		
		bl ObtainSemaphorePPC

		lwz	r29,POOL_TRESHSIZE(r31)
		
		cmplw	r29,r28
		
		bge	.DoFrPuddle
		
		subi	r4,r30,32
		
		bl RemovePPC

		subi	r4,r30,32
		mr	r3,r27
		
		bl FreeVec68K

		b	.ExitFreePool
		
.DoFrPuddle:	subi	r30,r30,32
		la	r29,POOL_PUDDLELIST(r31)
		lwz	r29,MLH_HEAD(r29)
		
.NextMHNode:	lwz	r4,LN_SUCC(r29)
		mr.	r4,r4
		beq	.ExitFreePool			#Needs an error message (GURU?)

		lwz	r4,MH_LOWER(r29)
		cmplw	r4,r30

		bgt	.OutOfBounds
		
		lwz	r4,MH_UPPER(r29)
		cmplw	r4,r30

		ble	.OutOfBounds
		
		b	.CorrectMHFnd
		
.OutOfBounds:	lwz	r29,LN_SUCC(r29)

		b	.NextMHNode
		
.CorrectMHFnd:	mr	r4,r29				#MH
		mr	r5,r30				#Block
		addi	r6,r28,32			#Size
			
		bl DeallocatePPC
		
		lwz	r4,MH_FREE(r29)
		lwz	r5,POOL_PUDDLESIZE(r31)
		cmpw	r4,r5
		
		beq	.RemovePuddle
		
		mr	r4,r29
		
		bl RemovePPC
		
		lwz	r5,POOL_PUDDLESIZE(r31)
		rlwinm	r5,r5,24,8,31			#Establish granularity
		lwz	r4,MH_FREE(r29)
		divwu	r4,r4,r5			
		addi	r4,r4,0x80			#Establish priority based on free space
		stb	r4,LN_PRI(r29)
		
		la	r4,POOL_PUDDLELIST(r31)
		mr	r5,r29
		
		bl EnqueuePPC
		
		b	.ExitFreePool
		
.RemovePuddle:	mr	r4,r29
		
		bl RemovePPC
		
		mr	r4,r29
		mr	r3,r27
		
		bl FreeVec68K		
		
.ExitFreePool:	lwz	r4,sonnet_MemSem(r27)
		mr	r3,r27
		
		bl ReleaseSemaphorePPC

.ExitPoolZero:	mr	r30,r27
		li	r31,FFreePooledPPC-FRun68K
		bl	DebugEndFunction

		lwz	r27,0(r13)
		lwz	r28,4(r13)
		lwz	r29,8(r13)
		lwz	r30,12(r13)
		lwz	r31,16(r13)
		addi	r13,r13,20
		
		epilog 'TOC'

#********************************************************************************************
#
#	signals = WaitPPC(PowerPCBase, signalSet) // r3=r3,r4
#
#********************************************************************************************

WaitPPC:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)

		li	r31,FWaitPPC-FRun68K
		bl	DebugStartFunction

		mr	r30,r3
		lwz	r31,ThisPPCProc(r3)
		mr	r28,r4

.WaitPPCAtom:	la	r4,sonnet_Atomic(r30)

		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitPPCAtom

		stw	r28,TC_SIGWAIT(r31)
.RecheckSig:	lwz	r6,TC_SIGRECVD(r31)
		and	r5,r28,r6
		mr.	r5,r5
		bne-	.GotSignals

		la	r4,sonnet_Atomic(r30)
		
		bl AtomicDone

		li	r0,TS_CHANGING
		stb	r0,TC_STATE(r31)
		
		mr	r3,r30
		
		bl CauseInterrupt

.WaitForRun:	lbz	r0,TC_STATE(r31)
		cmplwi	r0,TS_RUN
		bne+	.WaitForRun
		
.WaitPPCAtom2:	la	r4,sonnet_Atomic(r30)

		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitPPCAtom2
		
		lwz	r28,TC_SIGWAIT(r31)
		
		b	.RecheckSig

.GotSignals:	xor	r6,r5,r6
		stw	r6,TC_SIGRECVD(r31)
				
		la	r4,sonnet_Atomic(r30)
		
		bl AtomicDone

		mr	r3,r5

		lwz	r28,0(r13)
		lwz	r29,4(r13)
		lwz	r30,8(r13)
		lwz	r31,12(r13)
		addi	r13,r13,16
		
		epilog 'TOC'

#********************************************************************************************
#
#	oldpriority = SetTaskPriPPC(PowerPCBase, taskPPC, priority) // r3=r3,r4,r5
#
#********************************************************************************************

SetTaskPriPPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

		li	r31,FSetTaskPriPPC-FRun68K
		bl	DebugStartFunction

		mr	r31,r3
		mr	r30,r4

.PriAtomic:	la	r4,sonnet_Atomic(r31)

		bl AtomicTest

		mr.	r3,r3
		beq+	.PriAtomic

		lbz	r29,LN_PRI(r30)
		extsb	r29,r29
		stb	r5,LN_PRI(r30)
		lwz	r3,ThisPPCProc(r31)

		cmpw	r3,r30
		beq-	.NoSelf

		lbz	r0,TC_STATE(r30)
		cmplwi	r0,TS_REMOVED
		beq-	.DonePriChange

		cmplwi	r0,TS_WAIT
		bne-	.DonePriChange

		mr	r4,r30

		bl RemovePPC

		mr	r5,r30
		li	r0,TS_READY
		stb	r0,TC_STATE(r30)
		la	r4,LIST_READYTASKS(r30)		#Insert in Readytasks list on Pri
		bl	InsertOnPri

		lwz	r4,LIST_READYTASKS(r30)		#Check if we are top
		cmplw	r4,r30
		bne-	.DonePriChange

.NoSelf:	la	r4,sonnet_Atomic(r31)
		
		bl AtomicDone
		
		mr	r3,r31

		bl CauseInterrupt

		b	.ExitPri

.DonePriChange:	la	r4,sonnet_Atomic(r31)

		bl AtomicDone

.ExitPri:	mr	r3,r29
		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12

		epilog 'TOC'

#********************************************************************************************
#
#	d0 = Run68KLowLevel(PowerPCBase, Code, Offset, a0, a1, d0, d1) // r3=r3,r4,r5,r6,r7,r8,r9
#
#********************************************************************************************

Run68KLowLevel:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)
		stwu	r25,-4(r13)
		stwu	r24,-4(r13)
		stwu	r23,-4(r13)
		stwu	r22,-4(r13)
		
		mr	r31,r4
		mr	r29,r5
		mr	r28,r6
		mr	r27,r7
		mr	r26,r8
		mr	r25,r9
		mr	r24,r3
		mfctr	r22

		bl CreateMsgFramePPC

		mr	r30,r3
		subi	r5,r30,4				
		li	r6,48
		li	r7,0
		mtctr	r6
.ClearLLMsg:	stwu	r7,4(r5)
		bdnz	.ClearLLMsg
		
		stw	r31,MN_PPSTRUCT+0*4(r30)		# Code	/ 	Base
		stw	r29,MN_PPSTRUCT+1*4(r30)		# 0	/	Offset
		stw	r28,MN_PPSTRUCT+2*4(r30)		# a0
		stw	r27,MN_PPSTRUCT+3*4(r30)		# a1
		stw	r26,MN_PPSTRUCT+4*4(r30)		# d0
		stw	r25,MN_PPSTRUCT+5*4(r30)		# d1
		loadreg	r5,'LL68'
		stw	r5,MN_IDENTIFIER(r30)
		li	r5,192
		sth	r5,MN_LENGTH(r30)		
		li	r5,NT_MESSAGE
		stb	r5,LN_TYPE(r30)		
		lwz	r4,sonnet_MCPort(r24)
		stw	r4,MN_MCPORT(r30)
		lwz	r5,ThisPPCProc(r24)
		stw	r5,MN_PPC(r30)				
		mr	r4,r30

		bl SendMsgFramePPC

		subi	r4,r30,MN_PPSTRUCT
		mr	r3,r24

		bl WaitFor68K

		mr	r3,r4					# return d0 - See WaitFor68K

		mtctr	r22

		lwz	r22,0(r13)
		lwz	r23,4(r13)
		lwz	r24,8(r13)
		lwz	r25,12(r13)
		lwz	r26,16(r13)
		lwz	r27,20(r13)
		lwz	r28,24(r13)
		lwz	r29,28(r13)
		lwz	r30,32(r13)
		lwz	r31,36(r13)
		addi	r13,r13,40
		
		epilog 'TOC'

#********************************************************************************************
#
#	void SignalPPC(PowerPCBase, taskPPC, signals) // r3,r4,r5
#
#********************************************************************************************

SignalPPC:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)

		li	r31,FSignalPPC-FRun68K
		bl	DebugStartFunction

		mr	r31,r4
		mr	r30,r5
		mr	r29,r3

		lbz	r0,LN_TYPE(r4)
		cmpwi	r0,NT_PPCTASK
		beq-	.PPCTask
		cmpwi	r0,NT_TASK
		beq	.LegacyTask
		cmpwi	r0,NT_PROCESS
		bne	.SigExit

.LegacyTask:	mr	r8,r30						#d0
		mr	r7,r31						#a1
		lwz	r4,sonnet_SysBase(r3)
		li	r5,_LVOSignal
		
		bl Run68KLowLevel
		
		b	.SigExit

.PPCTask:	mr	r3,r29
		mr	r4,r31
		mr	r5,r30
		mr	r30,r31
		
		bl CheckExcSignal

		mr	r5,r3
		
.SigAtom:	la	r4,sonnet_Atomic(r29)

		bl AtomicTest

		mr.	r3,r3
		beq+	.SigAtom
		
		lbz	r0,TC_STATE(r30)
		cmplwi	r0,TS_WAIT
		beq-	.ItsWaiting

		cmplwi	r0,TS_CHANGING
		bne-	.NotChanging

		li	r0,TS_RUN
		stb	r0,TC_STATE(r30)
.NotChanging:	lwz	r0,TC_SIGRECVD(r30)
		or	r0,r0,r5
		stw	r0,TC_SIGRECVD(r30)
		
		la	r4,sonnet_Atomic(r29)

		bl AtomicDone

		b	.SigExit

.ItsWaiting:	lwz	r0,TC_SIGRECVD(r30)
		or	r0,r0,r5
		stw	r0,TC_SIGRECVD(r30)
		lwz	r0,TC_SIGWAIT(r30)
		and.	r0,r0,r5
		bne-	.GotSignal

		la	r4,sonnet_Atomic(r29)

		bl AtomicDone

		b	.SigExit

.GotSignal:	mr	r4,r30

		bl RemovePPC

		li	r0,TS_READY
		stb	r0,TC_STATE(r30)

		la	r4,LIST_READYTASKS(r29)
		mr	r5,r30
		
		bl InsertOnPri				#Prio recalculation
							#r4 = ReadyTasksList r5 = Task
		la	r4,sonnet_Atomic(r29)

		bl AtomicDone

		lwz	r4,LIST_READYTASKS(r29)
		cmplw	r4,r30				#Check if we are top
		bne-	.SigExit
		
		li	r0,-1
		stb	r0,RescheduleFlag(r29)
		
		mr	r3,r29

		bl CauseInterrupt

.SigExit:	mr	r30,r29
		li	r31,FSignalPPC-FRun68K
		bl	DebugEndFunction

		lwz	r28,0(r13)
		lwz	r29,4(r13)
		lwz	r30,8(r13)
		lwz	r31,12(r13)
		addi	r13,r13,16
		
		epilog 'TOC'

#********************************************************************************************
#
#	message = GetMsgPPC(PowerPCBase, MsgPortPPC) // r3=r3,r4
#
#********************************************************************************************

GetMsgPPC:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

		li	r31,FGetMsgPPC-FRun68K
		bl	DebugStartFunction

		mr	r29,r3
		mr	r31,r4

		addi	r4,r31,MP_PPC_SEM
		
		bl ObtainSemaphorePPC

		addi	r5,r31,MP_PPC_INTMSG			#Private WarpOS stuff
		lwz	r4,LH_TAILPRED+MP_PPC_INTMSG(r31)	#Needs to be checked for purpose
		cmplw	r4,r5					#See also other functions
		beq-	.IntListEmpty				#probably system msging & port

.GetMsgAtom:	la	r4,sonnet_Atomic(r29)

		bl AtomicTest

		mr.	r3,r3
		beq+	.GetMsgAtom

		lbz	r3,PortInUse(r29)
		mr.	r3,r3
		beq-	.PortIsFree

		la	r4,sonnet_Atomic(r29)

		bl AtomicDone

.PortWait:	lbz	r3,PortInUse(r29)
		mr.	r3,r3
		bne+	.PortWait

		b	.GetMsgAtom

.PortIsFree:	stw	r31,CurrentPort(r29)
		li	r0,-1
		stb	r0,PortInUse(r29)

		la	r4,sonnet_Atomic(r29)

		bl AtomicDone
		
		mr	r3,r29

		bl CauseInterrupt

.PortWait2:	lbz	r3,PortInUse(r29)
		mr.	r3,r3
		bne+	.PortWait2

.IntListEmpty:	addi	r4,r31,MP_MSGLIST

		bl RemHeadPPC

		mr	r5,r3		
		addi	r4,r31,MP_PPC_SEM
		mr	r3,r29

		bl ReleaseSemaphorePPC

		mr	r3,r5
		
		mr	r30,r29
		li	r31,FGetMsgPPC-FRun68K
		bl	DebugEndFunction
		
		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12

		epilog 'TOC'

#********************************************************************************************
#
#	void ReplyMsgPPC(PowerPCBase, message) // r3,r4
#
#********************************************************************************************

ReplyMsgPPC:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)

		li	r31,FReplyMsgPPC-FRun68K
		bl	DebugStartFunction

		mr	r29,r3
		mr	r30,r4

		lwz	r31,MN_REPLYPORT(r30)
		mr.	r31,r31
		bne-	.GotReplyPort

		li	r0,NT_FREEMSG
		stb	r0,LN_TYPE(r30)
		b	.ExitReply

.GotReplyPort:	lbz	r28,LN_TYPE(r30)
		li	r0,NT_REPLYMSG
		stb	r0,LN_TYPE(r30)
		addi	r4,r31,MP_PPC_INTMSG

		cmpwi	r28,NT_XMSG68K
		bne-	.DoSem

		bl CreateMsgFramePPC
		
		stw	r30,MN_ARG2(r3)
		lhz	r6,MN_LENGTH(r30)
		sth	r6,MN_ARG1(r3)		
		rlwinm	r6,r6,27,5,31				#determine number of cachelines
		loadreg	r5,'RX68'
		stw	r5,MN_IDENTIFIER(r3)	
		mr	r4,r3
		mfctr	r5
		mtctr	r6

.FlushMsg:	dcbf	r0,r30
		addi	r30,r30,L1_CACHE_LINE_SIZE
		bdnz+	.FlushMsg

		mtctr	r5

		bl SendMsgFramePPC

		b	.ExitReply

.DoSem:		addi	r4,r31,MP_PPC_SEM
		mr	r3,r29
		
		bl ObtainSemaphorePPC

		addi	r5,r31,MP_PPC_INTMSG
		lwz	r4,LH_TAILPRED+MP_PPC_INTMSG(r31)
		cmplw	r4,r5
		beq-	.IntListEmpty2

.ReplyAtom:	la	r4,sonnet_Atomic(r29)

		bl AtomicTest

		mr.	r3,r3
		beq+	.ReplyAtom

		lbz	r3,PortInUse(r29)
		mr.	r3,r3
		beq-	.PortIzFree

		la	r4,sonnet_Atomic(r29)
		
		bl AtomicDone

.WaitForPort:	lbz	r3,PortInUse(r29)
		mr.	r3,r3
		bne+	.WaitForPort

		b	.ReplyAtom

.PortIzFree:	stw	r31,CurrentPort(r29)
		li	r0,-1
		stb	r0,PortInUse(r29)

		la	r4,sonnet_Atomic(r29)
		
		bl AtomicDone
		
		mr	r3,r29
		
		bl CauseInterrupt

.WaitForPort2:	lbz	r3,PortInUse(r29)
		mr.	r3,r3
		bne+	.WaitForPort2

.IntListEmpty2:	addi	r4,r31,MP_MSGLIST
		mr	r5,r30

		bl AddTailPPC

		lwz	r4,MP_SIGTASK(r31)
		mr.	r4,r4
		beq-	.NoSig

		lbz	r3,MP_FLAGS(r31)
		andi.	r3,r3,PF_ACTION
		bne-	.NoSig

		lbz	r3,MP_SIGBIT(r31)
		li	r5,1
		slw	r5,r5,r3
		mr	r3,r29

		bl SignalPPC

.NoSig:		addi	r4,r31,MP_PPC_SEM
		mr	r3,r29
		
		bl ReleaseSemaphorePPC

.ExitReply:	lwz	r28,0(r13)
		lwz	r29,4(r13)
		lwz	r30,8(r13)
		lwz	r31,12(r13)
		addi	r13,r13,16
		
		epilog 'TOC'

#********************************************************************************************
#
#	void PutMsgPPC(PowerPCBase, MsgPortPPC, message) // r3,r4,r5
#
#********************************************************************************************

PutMsgPPC:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)

		li	r31,FPutMsgPPC-FRun68K
		bl	DebugStartFunction

		mr	r29,r3
		mr	r31,r4
		mr	r30,r5

		addi	r4,r31,MP_PPC_SEM

		bl ObtainSemaphorePPC

		addi	r5,r31,MP_PPC_INTMSG
		lwz	r4,LH_TAILPRED+MP_PPC_INTMSG(r31)
		cmplw	r4,r5
		beq-	.IntListEmpty3

.PutAtom:	la	r4,sonnet_Atomic(r29)

		bl AtomicTest

		mr.	r3,r3
		beq+	.PutAtom

		lbz	r3,PortInUse(r29)
		mr.	r3,r3
		beq-	.CheckedPort

		la	r4,sonnet_Atomic(r29)
		
		bl AtomicDone

.W8ForPort:	lbz	r3,PortInUse(r29)
		mr.	r3,r3
		bne+	.W8ForPort

		b	.PutAtom

.CheckedPort:	stw	r31,CurrentPort(r29)
		li	r0,-1
		stb	r0,PortInUse(r29)

		la	r4,sonnet_Atomic(r29)

		bl AtomicDone
		
		mr	r3,r29

		bl CauseInterrupt

.W8ForPort2:	lbz	r3,PortInUse(r29)
		mr.	r3,r3
		bne+	.W8ForPort2

.IntListEmpty3:	addi	r4,r31,MP_MSGLIST
		li	r0,NT_MESSAGE
		stb	r0,LN_TYPE(r30)
		mr	r5,r30

		bl AddTailPPC

		lwz	r4,MP_SIGTASK(r31)
		mr.	r4,r4
		beq-	.NoPutSig

		lbz	r3,MP_FLAGS(r31)
		andi.	r3,r3,PF_ACTION
		bne-	.NoPutSig

		lbz	r3,MP_SIGBIT(r31)
		li	r5,1
		slw	r5,r5,r3
		mr	r3,r29

		bl SignalPPC

.NoPutSig:	addi	r4,r31,MP_PPC_SEM
		mr	r3,r29
		
		bl ReleaseSemaphorePPC

		lwz	r28,0(r13)
		lwz	r29,4(r13)
		lwz	r30,8(r13)
		lwz	r31,12(r13)
		addi	r13,r13,16

		epilog 'TOC'

#********************************************************************************************
#
#	void SetScheduling(PowerPCBase, SchedTagList) // r3,r4 - Not working with current scheduler
#
#********************************************************************************************

SetScheduling:
		prolog 228,'TOC'
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		li	r31,FSetScheduling-FRun68K
		bl	DebugStartFunction

		mr	r30,r3
		mr	r31,r4

		loadreg	r4,SCHED_REACTION
		mr	r5,r31

		bl FindTagItemPPC

		mr.	r3,r3
		beq-	.SchedNotFound

		lwz	r4,4(r3)
		cmpwi	r4,1
		bge-	.InRange1

		li	r4,1
.InRange1:	cmpwi	r4,20
		ble-	.InRange2

		li	r4,20
.InRange2:	mulli	r4,r4,1000
		stw	r4,LowActivityPrio(r30)

.SchedNotFound:	lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		epilog 'TOC'

#********************************************************************************************
#
#	void SPrintF(PowerPCBase, Formatstring, values) // r3,r4,r5
#
#********************************************************************************************

SPrintF:
		prolog 228,'TOC'

		stwu	r7,-4(r13)
		stwu	r6,-4(r13)		
		stwu	r5,-4(r13)
		stwu	r4,-4(r13)
		stwu	r3,-4(r13)

		mr	r6,r4						#a0
		mr	r7,r5						#a1
		mr	r4,r3
		li	r5,_LVOSPrintF68K

		bl 	Run68KLowLevel

		lwz	r3,0(r13)
		lwz	r4,4(r13)
		lwz	r5,8(r13)
		lwz	r6,12(r13)
		lwz	r7,16(r13)
		addi	r13,r13,20

		epilog 'TOC'

#********************************************************************************************
#
#	void GetHALInfo(PowerPCBase, HALInfoTagList) // r3,r4
#
#********************************************************************************************

GetHALInfo:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		li	r31,FGetHALInfo-FRun68K
		bl	DebugStartFunction

		mr	r31,r4
		mr	r30,r3

		loadreg	r4,HINFO_ALEXC_HIGH
		mr	r5,r31

		bl FindTagItemPPC

		mr.	r3,r3
		beq-	.NoHALTag1

		lwz	r4,AlignmentExcHigh(r30)
		stw	r4,4(r3)
		
.NoHALTag1:	loadreg	r4,HINFO_ALEXC_LOW
		mr	r5,r31

		bl FindTagItemPPC

		mr.	r3,r3
		beq-	.NoHALTag2

		lwz	r4,AlignmentExcLow(r30)
		stw	r4,4(r3)
		
.NoHALTag2:	loadreg	r4,HINFO_DSEXC_HIGH
		mr	r5,r31
		
		bl FindTagItemPPC
		
		mr.	r3,r3
		beq	.NoHALTag3
		
		lwz	r4,DataExcHigh(r30)
		stw	r4,4(r3)
		
.NoHALTag3:	loadreg	r4,HINFO_DSEXC_LOW
		mr	r5,r31
		
		bl FindTagItemPPC
		
		mr.	r3,r3
		beq	.NoHALTag4		
		
		lwz	r4,DataExcLow(r30)
		stw	r4,4(r3)

.NoHALTag4:	lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8

		epilog 'TOC'

#********************************************************************************************
#
#	void ChangeMMU(PowerPCBase, MMUMode) // r3,r4			#STUB
#
#********************************************************************************************

ChangeMMU:	prolog 228,'TOC'

		stwu	r31,-4(r13)
		
		li	r31,FChangeMMU-FRun68K
		bl	DebugStartFunction

		lwz	r31,0(r13)
		addi	r13,r13,4
		
		epilog	'TOC'
		
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		
		li	r31,FChangeMMU-FRun68K
		bl	DebugStartFunction
		
		mr	r31,r3
		lwz	r3,ThisPPCProc(r31)

		cmplwi	r4,CHMMU_STANDARD
		beq-	.ChangeToTable

		cmplwi	r4,CHMMU_BAT
		bne-	.ExitChMMU

		lwz	r5,TASKPPC_FLAGS(r3)
		ori	r5,r5,1<<TASKPPC_BAT
		stw	r5,TASKPPC_FLAGS(r3)

		bl	GetBATs

		b	.ExitChMMU

.ChangeToTable:	lwz	r5,TASKPPC_FLAGS(r3)
		ori	r5,r5,1<<TASKPPC_BAT
		xori	r5,r5,1<<TASKPPC_BAT
		stw	r5,TASKPPC_FLAGS(r3)

		bl	StoreBATs

.ExitChMMU:	lwz	r31,0(r13)
		addi	r13,r13,4

		epilog 'TOC'

#********************************************************************************************

GetBATs:							#r31 = PowerPCBase
		mflr	r0
		stwu	r0,-4(r13)
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

		lwz	r4,ThisPPCProc(r31)
		lwz	r30,TASKPPC_BATSTORAGE(r4)
		
		bl Super
		
		mr	r29,r3
		
		addi	r5,r30,TASKPPC_BAT0
		li	r4,CHMMU_BAT0

		bl MoveFromBAT

		addi	r5,r30,TASKPPC_BAT1
		li	r4,CHMMU_BAT1

		bl MoveFromBAT

		addi	r5,r30,TASKPPC_BAT2
		li	r4,CHMMU_BAT2

		bl MoveFromBAT

		addi	r5,r30,TASKPPC_BAT3
		li	r4,CHMMU_BAT3

		bl MoveFromBAT

		addi	r5,r31,BASE_STOREBAT0
		li	r4,CHMMU_BAT0

		bl MoveToBAT

		addi	r5,r31,BASE_STOREBAT1
		li	r4,CHMMU_BAT1

		bl MoveToBAT

		addi	r5,r31,BASE_STOREBAT2
		li	r4,CHMMU_BAT2

		bl MoveToBAT

		addi	r5,r31,BASE_STOREBAT3
		li	r4,CHMMU_BAT3

		bl MoveToBAT

		mr	r4,r29

		bl User

		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		lwz	r0,12(r13)
		addi	r13,r13,16
		mtlr	r0

		blr
		
#********************************************************************************************

StoreBATs:							#r31 = PowerPCBase
		mflr	r0
		stwu	r0,-4(r13)
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

		lwz	r4,ThisPPCProc(r31)
		lwz	r30,TASKPPC_BATSTORAGE(r4)
		
		bl Super
		
		mr	r29,r3
		
		addi	r5,r30,TASKPPC_BAT0
		li	r4,CHMMU_BAT0

		bl MoveToBAT

		addi	r5,r30,TASKPPC_BAT1
		li	r4,CHMMU_BAT1

		bl MoveToBAT

		addi	r5,r30,TASKPPC_BAT2
		li	r4,CHMMU_BAT2

		bl MoveToBAT

		addi	r5,r30,TASKPPC_BAT3
		li	r4,CHMMU_BAT3

		bl MoveToBAT

		mr	r4,r29

		bl User

		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		lwz	r0,12(r13)
		addi	r13,r13,16
		mtlr	r0

		blr
		
#********************************************************************************************
#
#	Support: void MoveToBAT(BAT#, BATArray) // r4,r5 / Must be in Supervisor Mode
#
#********************************************************************************************

MoveToBAT:
		mflr	r0
		stwu	r0,-4(r13)
		mfmsr	r9
		ori	r0,r9,(PSL_IR|PSL_DR)
		xori	r0,r0,(PSL_IR|PSL_DR)
		mtmsr	r0
		sync	
		isync	
		
		lwz	r3,0(r5)
		lwz	r6,4(r5)
		lwz	r7,8(r5)
		lwz	r8,12(r5)
		
		cmplwi	r4,CHMMU_BAT0
		beq-	.MoveBat0
		
		cmplwi	r4,CHMMU_BAT1
		beq-	.MoveBat1
		
		cmplwi	r4,CHMMU_BAT2
		beq-	.MoveBat2
		
		cmplwi	r4,CHMMU_BAT3
		beq-	.MoveBat3
		
		b	.EndMoveBat
		
.MoveBat0:	mtibatu	0,r3
		mtibatl	0,r6
		mtdbatu	0,r7
		mtdbatl	0,r8
		b 	.EndMoveBat
		
.MoveBat1:	mtibatu	1,r3
		mtibatl	1,r6
		mtdbatu	1,r7
		mtdbatl	1,r8
		b	.EndMoveBat
		
.MoveBat2:	mtibatu	2,r3
		mtibatl	2,r6
		mtdbatu	2,r7
		mtdbatl	2,r8
		b	.EndMoveBat
		
.MoveBat3:	mtibatu	3,r3
		mtibatl	3,r6
		mtdbatu	3,r7
		mtdbatl	3,r8
		
.EndMoveBat:	mtmsr	r9
		sync	
		isync	
		lwz	r0,0(r13)
		addi	r13,r13,4
		mtlr	r0
		
		blr	

#********************************************************************************************
#
#	Support: void MoveFromBAT(BAT#, BATArray) // r4,r5 / Must be in Supervisor Mode
#
#********************************************************************************************

MoveFromBAT:
		mflr	r0
		stwu	r0,-4(r13)
		cmplwi	r4,CHMMU_BAT0
		beq-	.MoveFBat0
		
		cmplwi	r4,CHMMU_BAT1
		beq-	.MoveFBat1
		
		cmplwi	r4,CHMMU_BAT2
		beq-	.MoveFBat2
		
		cmplwi	r4,CHMMU_BAT3
		beq-	.MoveFBat3
		
		b	.EndMoveFBat
		
.MoveFBat0:	mfibatu	r0,0
		stw	r0,0(r5)
		mfibatl	r0,0
		stw	r0,4(r5)
		mfdbatu	r0,0
		stw	r0,8(r5)
		mfdbatl	r0,0
		stw	r0,12(r5)
		b	.EndMoveFBat
		
.MoveFBat1:	mfibatu	r0,1
		stw	r0,0(r5)
		mfibatl	r0,1
		stw	r0,4(r5)
		mfdbatu	r0,1
		stw	r0,8(r5)
		mfdbatl	r0,1
		stw	r0,12(r5)
		b	.EndMoveFBat
		
.MoveFBat2:	mfibatu	r0,2
		stw	r0,0(r5)
		mfibatl	r0,2
		stw	r0,4(r5)
		mfdbatu	r0,2
		stw	r0,8(r5)
		mfdbatl	r0,2
		stw	r0,12(r5)
		b	.EndMoveFBat
		
.MoveFBat3:	mfibatu	r0,3
		stw	r0,0(r5)
		mfibatl	r0,3
		stw	r0,4(r5)
		mfdbatu	r0,3
		stw	r0,8(r5)
		mfdbatl	r0,3
		stw	r0,12(r5)
		
.EndMoveFBat:	lwz	r0,0(r13)
		addi	r13,r13,4
		mtlr	r0
		
		blr
		
#********************************************************************************************
#
#	void FreeAllMem(PowerPCBase) // r3
#
#********************************************************************************************

FreeAllMem:	blr

		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		
		li	r31,FFreeAllMem-FRun68K
		bl	DebugStartFunction

		mr	r31,r3

		lwz	r4,ThisPPCProc(r3)
		la	r4,TASKPPC_TASKPOOLS(r4)
		lwz	r5,MLH_HEAD(r4)
.NextFPool:	mr	r30,r5
		lwz	r29,LN_SUCC(r5)
		mr.	r29,r29
		beq	.AreNoPools

		subi	r4,r5,36

		bl DeletePoolPPC

		mr	r5,r29
		b	.NextFPool
		
.AreNoPools:	mr	r30,r31
		li	r31,FFreeAllMem-FRun68K
		bl	DebugEndFunction

		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12

		epilog 'TOC'

#********************************************************************************************
#
#	void RemExcHandler(PowerPCBase, XLock) // r3,r4		*NEEDS FUNCTIONALITY IN INTERRUPT
#
#********************************************************************************************

RemExcHandler:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		li	r31,FRemExcHandler-FRun68K
		bl	DebugStartFunction

		mr.	r4,r4
		beq-	.NoXLock

		mr	r31,r3
		mr	r30,r4

.RemExcAtom:	la	r4,sonnet_Atomic(r31)

		bl AtomicTest

		mr.	r3,r3
		
		beq+	.RemExcAtom

		addi	r4,r31,LIST_REMOVEDEXC			#In lib base
		mr	r5,r30

		bl AddHeadPPC

		la	r4,sonnet_Atomic(r31)

		bl AtomicDone
		
		mr	r3,r31

		bl CauseInterrupt

		lwz	r3,EXCDATA_LASTEXC(r30)
.WaitActive:	lwz	r4,EXCDATA_FLAGS(r3)
		rlwinm.	r0,r4,(32-EXC_ACTIVE),31,31
		bne+	.WaitActive				#Done in interrupt

		mr	r4,r30
		mr	r3,r31
		
		bl	.FreeAllExcMem

		mr	r4,r30
		mr	r3,r31
		
		bl FreeVec68K

.NoXLock:	lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8

		epilog 'TOC'

#********************************************************************************************

.FreeAllExcMem:	
		mflr	r0
		stwu	r0,-4(r13)
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		
		mr	r31,r4
		mr	r30,r3
		
		lwz	r4,EXCDATA_MCHECK(r31)
		mr.	r4,r4
		beq-	.NoMemMCheck
		
		mr	r3,r30

		bl FreeVec68K

.NoMemMCheck:	lwz	r4,EXCDATA_DACCESS(r31)
		mr.	r4,r4
		beq-	.NoMemDAccess
		
		mr	r3,r30

		bl FreeVec68K

.NoMemDAccess:	lwz	r4,EXCDATA_IACCESS(r31)
		mr.	r4,r4
		beq-	.NoMemIAccess
		
		mr	r3,r30

		bl FreeVec68K

.NoMemIAccess:	lwz	r4,EXCDATA_INTERRUPT(r31)
		mr.	r4,r4
		beq-	.NoMemInt
		
		mr	r3,r30

		bl FreeVec68K

.NoMemInt:	lwz	r4,EXCDATA_ALIGN(r31)
		mr.	r4,r4
		beq-	.NoMemAlign
		
		mr	r3,r30

		bl FreeVec68K
		
		mr	r3,r30

.NoMemAlign:	lwz	r4,EXCDATA_PROGRAM(r31)
		mr.	r4,r4
		beq-	.NoMemProgram
		
		mr	r3,r30

		bl FreeVec68K

.NoMemProgram:	lwz	r4,EXCDATA_FPUN(r31)
		mr.	r4,r4
		beq-	.NoMemFPUn
		
		mr	r3,r30

		bl FreeVec68K

.NoMemFPUn:	lwz	r4,EXCDATA_DECREMENTER(r31)
		mr.	r4,r4
		beq-	.NoMemDec
		
		mr	r3,r30

		bl FreeVec68K

.NoMemDec:	lwz	r4,EXCDATA_SYSTEMCALL(r31)
		mr.	r4,r4
		beq-	.NoMemSC
		
		mr	r3,r30

		bl FreeVec68K

.NoMemSC:	lwz	r4,EXCDATA_TRACE(r31)
		mr.	r4,r4
		beq-	.NoMemTrace
		
		mr	r3,r30

		bl FreeVec68K

.NoMemTrace:	lwz	r4,EXCDATA_PERFMON(r31)
		mr.	r4,r4
		beq-	.NoMemPerfMon
		
		mr	r3,r30

		bl FreeVec68K

.NoMemPerfMon:	lwz	r4,EXCDATA_IABR(r31)
		mr.	r4,r4
		beq-	.NoMemIABR
		
		mr	r3,r30

		bl FreeVec68K

.NoMemIABR:	lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		lwz	r0,0(r13)
		addi	r13,r13,4
		mtlr	r0
		blr
		
#********************************************************************************************
#
#	XLock = SetExcHandler(PowerPCBase, ExcTags) // r3=r3,r4	*NEEDS FUNCTIONALITY IN INTERRUPT
#
#********************************************************************************************		

SetExcHandler:	
		prolog 228,'TOC'	

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)

		li	r31,FSetExcHandler-FRun68K
		bl	DebugStartFunction

		li	r26,0
		mr	r27,r3
		mr	r31,r4

		li	r4,98
		loadreg	r5,0x10001			#NEEDS PROPER ATTRIBUTES
		li	r6,0
		li	r7,0
		
		bl AllocVec68K

		mr.	r3,r3
		beq-	.NoMemAvail

		mr	r30,r3

		loadreg	r4,EXCATTR_CODE
		li	r5,0
		mr	r6,r31
		
		bl GetTagDataPPC

		mr.	r3,r3
		beq-	.NoExcCode

		stw	r3,EXCDATA_CODE(r30)

		loadreg	r4,EXCATTR_DATA
		li	r5,0
		mr	r6,r31
		
		bl GetTagDataPPC

		stw	r3,EXCDATA_DATA(r30)

		loadreg	r4,EXCATTR_NAME
		li	r5,0
		mr	r6,r31
		
		bl GetTagDataPPC

		stw	r3,EXCDATA_NAME(r30)

		loadreg	r4,EXCATTR_PRI
		li	r5,0
		mr	r6,r31
		
		bl GetTagDataPPC

		extsb	r3,r3
		stb	r3,EXCDATA_PRI(r30)
		li	r0,NT_INTERRUPT
		stb	r0,EXCDATA_TYPE(r30)

		loadreg	r4,EXCATTR_FLAGS
		li	r5,0
		mr	r6,r31
		
		bl GetTagDataPPC

		stw	r3,EXCDATA_FLAGS(r30)
		rlwinm.	r0,r3,(32-EXC_SMALLCONTEXT),31,31
		bne-	.HasContext

		rlwinm.	r0,r3,(32-EXC_LARGECONTEXT),31,31
		bne-	.HasContext

		b	.NoExcCode

.HasContext:	mr	r28,r3

		loadreg	r4,EXCATTR_TASK
		li	r5,0
		mr	r6,r31
		
		bl GetTagDataPPC

		andi.	r0,r28,(1<<EXC_GLOBAL)
		bne-	.ExcIsGlobal

		rlwinm.	r0,r28,(32-EXC_LOCAL),31,31
		bne-	.ExcIsLocal

		b	.NoExcCode

.ExcIsLocal:	mr.	r3,r3
		bne-	.ExcIsGlobal

		lwz	r3,ThisPPCProc(r27)
.ExcIsGlobal:	stw	r3,EXCDATA_TASK(r30)

		loadreg	r4,0x80101007				#Unknown Tag
		li	r5,0
		mr	r6,r31
		
		bl GetTagDataPPC

		mr.	r3,r3
		beq-	.NoUnknownTag

		stw	r3,EXCDATA_UNKNOWN1(r30)
		li	r0,0
		stw	r0,EXCDATA_UNKNOWN2(r30)
		stw	r0,EXCDATA_UNKNOWN3(r30)

.NoUnknownTag:	loadreg	r4,EXCATTR_EXCID
		li	r5,0
		mr	r6,r31
		
		bl GetTagDataPPC

		stw	r3,EXCDATA_EXCID(r30)
		mr	r29,r3
		rlwinm.	r0,r29,(32-EXC_MCHECK),31,31
		beq-	.NoMachineChk

		li	r4,46
		loadreg	r5,0x10001
		li	r6,0
		li	r7,0
		mr	r3,r27
		
		bl AllocVec68K

		mr.	r3,r3
		beq-	.NoMemAvail2

		stw	r3,EXCDATA_MCHECK(r30)
		mr	r26,r3
.NoMachineChk:	rlwinm.	r0,r29,(32-EXC_DACCESS),31,31
		beq-	.NoDataAccess

		li	r4,46
		loadreg	r5,0x10001
		li	r6,0
		li	r7,0
		mr	r3,r27
		
		bl AllocVec68K

		mr.	r3,r3
		beq-	.NoMemAvail2

		stw	r3,EXCDATA_DACCESS(r30)
		mr	r26,r3
.NoDataAccess:	rlwinm.	r0,r29,(32-EXC_IACCESS),31,31
		beq-	.NoInstAccess

		li	r4,46
		loadreg	r5,0x10001
		li	r6,0
		li	r7,0
		mr	r3,r27
		
		bl AllocVec68K

		mr.	r3,r3
		beq-	.NoMemAvail2

		stw	r3,EXCDATA_IACCESS(r30)
		mr	r26,r3
.NoInstAccess:	rlwinm.	r0,r29,(32-EXC_INTERRUPT),31,31
		beq-	.NoExtInt

		li	r4,46
		loadreg	r5,0x10001
		li	r6,0
		li	r7,0
		mr	r3,r27
		
		bl AllocVec68K

		mr.	r3,r3
		beq-	.NoMemAvail2

		stw	r3,EXCDATA_INTERRUPT(r30)
		mr	r26,r3
.NoExtInt:	rlwinm.	r0,r29,(32-EXC_ALIGN),31,31
		beq-	.NoAlignment

		li	r4,46
		loadreg	r5,0x10001
		li	r6,0
		li	r7,0
		mr	r3,r27
		
		bl AllocVec68K

		mr.	r3,r3
		beq-	.NoMemAvail2

		stw	r3,EXCDATA_ALIGN(r30)
		mr	r26,r3
.NoAlignment:	rlwinm.	r0,r29,(32-EXC_PROGRAM),31,31
		beq-	.NoProgram

		li	r4,46
		loadreg	r5,0x10001
		li	r6,0
		li	r7,0
		mr	r3,r27
		
		bl AllocVec68K

		mr.	r3,r3
		beq-	.NoMemAvail2

		stw	r3,EXCDATA_PROGRAM(r30)
		mr	r26,r3
.NoProgram:	rlwinm.	r0,r29,(32-EXC_FPUN),31,31
		beq-	.NoFPUnavail

		li	r4,46
		loadreg	r5,0x10001
		li	r6,0
		li	r7,0
		mr	r3,r27
		
		bl AllocVec68K

		mr.	r3,r3
		beq-	.NoMemAvail2

		stw	r3,EXCDATA_FPUN(r30)
		mr	r26,r3
.NoFPUnavail:	rlwinm.	r0,r29,(32-EXC_DECREMENTER),31,31
		beq-	.NoDecrementer

		li	r4,46
		loadreg	r5,0x10001
		li	r6,0
		li	r7,0
		mr	r3,r27
		
		bl AllocVec68K

		mr.	r3,r3
		beq-	.NoMemAvail2

		stw	r3,EXCDATA_DECREMENTER(r30)
		mr	r26,r3
.NoDecrementer:	rlwinm.	r0,r29,(32-EXC_SYSTEMCALL),31,31
		beq-	.NoSC

		li	r4,46
		loadreg	r5,0x10001
		li	r6,0
		li	r7,0
		mr	r3,r27
		
		bl AllocVec68K

		mr.	r3,r3
		beq-	.NoMemAvail2

		stw	r3,EXCDATA_SYSTEMCALL(r30)
		mr	r26,r3
.NoSC:		rlwinm.	r0,r29,(32-EXC_TRACE),31,31
		beq-	.NoTrace

		li	r4,46
		loadreg	r5,0x10001
		li	r6,0
		li	r7,0
		mr	r3,r27
		
		bl AllocVec68K

		mr.	r3,r3
		beq-	.NoMemAvail2

		stw	r3,EXCDATA_TRACE(r30)
		mr	r26,r3
.NoTrace:	rlwinm.	r0,r29,(32-EXC_PERFMON),31,31
		beq-	.NoPerfMon

		li	r4,46
		loadreg	r5,0x10001
		li	r6,0
		li	r7,0
		mr	r3,r27
		
		bl AllocVec68K

		mr.	r3,r3
		beq-	.NoMemAvail2

		stw	r3,EXCDATA_PERFMON(r30)
		mr	r26,r3
.NoPerfMon:	rlwinm.	r0,r29,(32-EXC_IABR),31,31
		beq-	.NoIABR

		li	r4,46
		loadreg	r5,0x10001
		li	r6,0
		li	r7,0
		mr	r3,r27
		
		bl AllocVec68K

		mr.	r3,r3
		beq-	.NoMemAvail2

		stw	r3,EXCDATA_IABR(r30)
		mr	r26,r3
.NoIABR:	stw	r26,EXCDATA_LASTEXC(r30)

.SetExcAtom:	la	r4,sonnet_Atomic(r27)
		
		bl AtomicTest

		mr.	r3,r3
		beq+	.SetExcAtom

		mr	r4,r30
		mr	r3,r27
		
		bl	.MakeLists

		la	r4,sonnet_Atomic(r27)
		
		bl AtomicDone
		
		mr	r3,r27

		bl CauseInterrupt

		mr.	r26,r26
		beq-	.NoExcDefined

.ExcLoop:	lwz	r3,EXCDATA_FLAGS(r26)
		rlwinm.	r0,r3,(32-EXC_ACTIVE),31,31
		beq+	.ExcLoop

.NoExcDefined:	mr	r4,r30
		b	.DoResult

.NoMemAvail2:	mr	r4,r30
		mr	r3,r27

		bl	.FreeAllExcMem

.NoExcCode:	mr	r4,r30
		mr	r3,r27

		bl FreeVec68K

.NoMemAvail:	li	r4,0

.DoResult:	mr	r3,r4

		lwz	r26,0(r13)
		lwz	r27,4(r13)
		lwz	r28,8(r13)
		lwz	r29,12(r13)
		lwz	r30,16(r13)
		lwz	r31,20(r13)
		addi	r13,r13,24
		
		epilog 'TOC'

#*******************************************************************************************		

.MakeLists:		
		mflr	r0
		stwu	r0,-4(r13)
		mr	r6,r4
		addi	r4,r3,LIST_READYEXC
		lwz	r5,EXCDATA_MCHECK(r6)
		mr.	r5,r5
		beq-	.NoVMCheck

		loadreg	r3,(1<<EXC_MCHECK)

		bl	.CopyIt

		bl AddHeadPPC		

.NoVMCheck:	lwz	r5,EXCDATA_DACCESS(r6)
		mr.	r5,r5
		beq-	.NoVDAccess

		loadreg	r3,(1<<EXC_DACCESS)

		bl	.CopyIt

		bl AddHeadPPC

.NoVDAccess:	lwz	r5,EXCDATA_IACCESS(r6)
		mr.	r5,r5
		beq-	.NoVIAccess
		
		loadreg	r3,(1<<EXC_IACCESS)
		
		bl	.CopyIt

		bl AddHeadPPC

.NoVIAccess:	lwz	r5,EXCDATA_INTERRUPT(r6)
		mr.	r5,r5
		beq-	.NoVInterrupt
		
		loadreg	r3,(1<<EXC_INTERRUPT)
		
		bl	.CopyIt

		bl AddHeadPPC		

.NoVInterrupt:	lwz	r5,EXCDATA_ALIGN(r6)
		mr.	r5,r5
		beq-	.NoVAlign
		
		loadreg	r3,(1<<EXC_ALIGN)
		
		bl	.CopyIt

		bl AddHeadPPC

.NoVAlign:	lwz	r5,EXCDATA_PROGRAM(r6)
		mr.	r5,r5
		beq-	.NoVProgram
		
		loadreg	r3,(1<<EXC_PROGRAM)
		
		bl	.CopyIt

		bl AddHeadPPC		

.NoVProgram:	lwz	r5,EXCDATA_FPUN(r6)
		mr.	r5,r5
		beq-	.NoVFPUn

		loadreg	r3,(1<<EXC_FPUN)

		bl	.CopyIt

		bl AddHeadPPC

.NoVFPUn:	lwz	r5,EXCDATA_DECREMENTER(r6)
		mr.	r5,r5
		beq-	.NoVDec

		loadreg	r3,(1<<EXC_DECREMENTER)

		bl	.CopyIt

		bl AddHeadPPC

.NoVDec:	lwz	r5,EXCDATA_SYSTEMCALL(r6)
		mr.	r5,r5
		beq-	.NoVSC

		loadreg	r3,(1<<EXC_SYSTEMCALL)

		bl	.CopyIt

		bl AddHeadPPC

.NoVSC:		lwz	r5,EXCDATA_TRACE(r6)
		mr.	r5,r5
		beq-	.NoVTrace

		loadreg	r3,(1<<EXC_TRACE)

		bl	.CopyIt

		bl AddHeadPPC

.NoVTrace:	lwz	r5,EXCDATA_PERFMON(r6)
		mr.	r5,r5
		beq-	.NoVPerfMon

		loadreg	r3,(1<<EXC_PERFMON)

		bl	.CopyIt

		bl AddHeadPPC

.NoVPerfMon:	lwz	r5,EXCDATA_IABR(r6)
		mr.	r5,r5
		beq-	.NoVIABR

		loadreg	r3,(1<<EXC_IABR)

		bl	.CopyIt

		bl AddHeadPPC

.NoVIABR:	lwz	r0,0(r13)
		addi	r13,r13,4
		mtlr	r0
		blr
		
#*******************************************************************************************

.CopyIt:
		mflr	r0
		stwu	r0,-4(r13)
		lbz	r0,EXCDATA_PRI(r6)
		stb	r0,EXCDATA_PRI(r5)
		lwz	r0,EXCDATA_NAME(r6)
		stw	r0,EXCDATA_NAME(r5)
		lwz	r0,EXCDATA_CODE(r6)
		stw	r0,EXCDATA_CODE(r5)
		lwz	r0,EXCDATA_DATA(r6)
		stw	r0,EXCDATA_DATA(r5)
		lwz	r0,EXCDATA_TASK(r6)
		stw	r0,EXCDATA_TASK(r5)
		lwz	r0,EXCDATA_FLAGS(r6)
		stw	r0,EXCDATA_FLAGS(r5)
		lwz	r0,EXCDATA_UNKNOWN1(r6)
		stw	r0,EXCDATA_UNKNOWN1(r5)
		lwz	r0,EXCDATA_UNKNOWN2(r6)
		stw	r0,EXCDATA_UNKNOWN2(r5)
		lwz	r0,EXCDATA_UNKNOWN3(r6)
		stw	r0,EXCDATA_UNKNOWN3(r5)
		stw	r3,EXCDATA_EXCID(r5)
		lwz	r0,0(r13)
		addi	r13,r13,4
		mtlr	r0
		blr
		
#********************************************************************************************
#
#	signals = WaitTime(PowerPCBase, signalSet, Time) // r3=r3,r4,r5
#
#********************************************************************************************

WaitTime:
		prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)
		stwu	r25,-4(r13)
		
		mfctr	r25

		li	r31,FWaitTime-FRun68K
		bl	DebugStartFunction

		mr	r29,r3
		mr	r30,r4
		lwz	r26,ThisPPCProc(r3)
		lwz	r4,sonnet_WaitListSem(r3)
		
		bl ObtainSemaphorePPC

		li	r0,-1
		stb	r0,FLAG_WAIT(r29)
		
		stwu	r31,-4(r13)
		mr	r31,r13
		subi	r13,r13,26
		subi	r31,r31,26

		loadreg	r4,60000000
		mr	r28,r5
		
		bl	.CalculateTime

		loadreg	r8,60000000
		divwu	r27,r28,r8
		mullw	r6,r27,r8
		sub	r4,r28,r6
		mr	r28,r3
		
		bl	.CalculateTime

.TimeLoop:	mftbu	r4
		mftbl	r5
		mftbu	r0
		cmplw	r0,r4
		bne+	.TimeLoop

		mtctr	r27
		mr.	r27,r27
		beq-	.TimeCalced

.CalcLoop:	addc	r5,r5,r28
		addze	r4,r4
		bdnz+	.CalcLoop

.TimeCalced:	addc	r5,r5,r3
		addze	r4,r4
		li	r9,0

		stw	r4,WAITTIME_TIME1(r31)
		stw	r5,WAITTIME_TIME2(r31)
		stw	r26,WAITTIME_TASK(r31)
		li	r0,0
		stb	r0,LN_PRI(r31)
		li	r0,0
		stb	r0,LN_TYPE(r31)
		lwz	r0,LN_NAME(r26)
		stw	r0,LN_NAME(r31)
		addi	r4,r29,LIST_WAITTIME
		mr	r5,r31

		bl AddHeadPPC		

		li	r0,0		
		stb	r0,FLAG_WAIT(r29)

		lwz	r4,sonnet_WaitListSem(r29)
		mr	r3,r29
		
		bl ReleaseSemaphorePPC

		mr	r4,r30
		ori	r4,r4,SIGF_WAIT
		mr	r27,r4
		mr	r3,r29

		bl WaitPPC

		mr	r6,r3
		li	r0,-1
		stb	r0,FLAG_WAIT(r29)

.WaitTimeAtom:	la	r4,sonnet_Atomic(r29)
		
		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitTimeAtom

		lwz	r26,ThisPPCProc(r29)
		lwz	r4,TC_SIGRECVD(r26)
		or	r5,r6,r4
		rlwinm.	r0,r5,22,31,31		
		bne-	.TimeOut

		mr	r4,r31

		bl RemovePPC		

		b	.SigBeforeTime

.TimeOut:	ori	r4,r4,SIGF_WAIT
		xori	r4,r4,SIGF_WAIT
		stw	r4,TC_SIGRECVD(r26)

.SigBeforeTime:	la	r4,sonnet_Atomic(r29)

		bl AtomicDone

		li	r0,0
		stb	r0,FLAG_WAIT(r29)
		mr	r30,r6
		ori	r30,r30,SIGF_WAIT
		xori	r30,r30,SIGF_WAIT
		addi	r31,r31,26
		mr	r13,r31
		lwz	r31,0(r13)
		addi	r13,r13,4

		mr	r3,r30

		mr	r30,r29
		li	r31,FWaitTime-FRun68K
		bl	DebugEndFunction

		mtctr	r25

		lwz	r25,0(r13)
		lwz	r26,4(r13)
		lwz	r27,8(r13)
		lwz	r28,12(r13)
		lwz	r29,16(r13)
		lwz	r30,20(r13)
		lwz	r31,24(r13)
		addi	r13,r13,28

		epilog 'TOC'

#********************************************************************************************		

.CalculateTime:		
		stw	r2,20(r1)
		mflr	r0
		stw	r0,8(r1)
		mfcr	r0
		stw	r0,4(r1)

		stw	r13,-4(r1)
		subi	r13,r1,4
		stwu	r1,-44(r1)
		
		loadreg	r5,SonnetBusClock
		
		mr	r6,r4
		mulhw	r3,r5,r6
		mullw	r4,r5,r6

		loadreg	r5,4000000

		bl	.Calculator
		
		lwz	r1,0(r1)
		lwz	r13,-4(r1)
		lwz	r0,8(r1)
		mtlr	r0
		lwz	r0,4(r1)
		mtcr	r0
		lwz	r2,20(r1)
		
		blr

.Calculator:	li	r0,32
		mtctr	r0
		li	r6,0
		mr.	r3,r3
		
.DoCalcLoop:	bge-	.XNotNeg

		addc	r4,r4,r4
		adde	r3,r3,r3
		add	r6,r6,r6
		b	.XWasNeg
		
.XNotNeg:	addc	r4,r4,r4
		adde	r3,r3,r3
		add	r6,r6,r6
		cmplw	r5,r3
		bgt-	.SkipNext
		
.XWasNeg:	sub.	r3,r3,r5
		addi	r6,r6,1
.SkipNext:	bdnz+	.DoCalcLoop

		mr	r3,r6
		
		blr

#********************************************************************************************
#
#	NextData = RawDoFmtPPC(FormatString, DataStream, PutChProc, PutChData) // r3=r4,r5,r6,r7
#
#********************************************************************************************

RawDoFmtPPC:	prolog 228,'TOC'

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)
		stwu	r25,-4(r13)
		stwu	r24,-4(r13)
		stwu	r23,-4(r13)
		stwu	r22,-4(r13)
		stwu	r21,-4(r13)
		stwu	r20,-4(r13)
		stwu	r19,-4(r13)
		stwu	r18,-4(r13)

		li	r31,FRawDoFmtPPC-FRun68K
		bl	DebugStartFunction

		cmplwi	r6,1
		beq-	.DoNoFmt

		mr	r28,r4
		mr	r29,r5
		mr	r30,r6
		mr	r18,r7
		stwu	r26,-4(r13)
		mr	r26,r13
		subi	r13,r13,16
		stwu	r29,-4(r13)
		mr	r25,r28
		b	.DoFmt

.NextFmtChar:	mr.	r30,r30
		bne-	.DoPutChProc

		stb	r3,0(r18)
		addi	r18,r18,1
		b	.NoPutChProc

.DoPutChProc:	mtlr	r30
		mr	r4,r3
		mr	r3,r18
		blrl	
		mr	r18,r3

.NoPutChProc:	lwz	r3,0(r13)
		addi	r13,r13,4
		mr	r13,r26
		lwz	r26,0(r13)
		addi	r13,r13,4
		
.DoNoFmt:	lwz	r18,0(r13)
		lwz	r19,4(r13)
		lwz	r20,8(r13)
		lwz	r21,12(r13)
		lwz	r22,16(r13)
		lwz	r23,20(r13)
		lwz	r24,24(r13)
		lwz	r25,28(r13)
		lwz	r26,32(r13)
		lwz	r27,36(r13)
		lwz	r28,40(r13)
		lwz	r29,44(r13)
		lwz	r30,48(r13)
		lwz	r31,52(r13)
		addi	r13,r13,56
		
		epilog 'TOC'
		
#********************************************************************************************	

.NormalChar:	mr.	r30,r30
		bne-	.PutChProc

		stb	r3,0(r18)
		addi	r18,r18,1
		b	.DoFmt

.PutChProc:	mtlr	r30
		mr	r4,r3
		mr	r3,r18
		blrl	
		mr	r18,r3

.DoFmt:		lbz	r3,0(r25)
		addi	r25,r25,1
		mr.	r3,r3
		beq+	.NextFmtChar

		cmplwi	r3,"%"
		bne+	.NormalChar

		subi	r24,r26,16
		xor	r20,r20,r20
		lbz	r3,0(r25)
		cmplwi	r3,"-"
		bne-	.NoJustif

		ori	r20,r20,1
		addi	r25,r25,1
.NoJustif:	lbz	r3,0(r25)
		cmplwi	r3,"0"
		bne-	.NoZeroPadding

		ori	r20,r20,2
.NoZeroPadding:	bl	.GetNum

		mr	r23,r3
		xor	r22,r22,r22
		lbz	r3,0(r25)
		cmplwi	r3,"."
		bne-	.NoTruncate

		addi	r25,r25,1
		bl	.GetNum

		mr	r22,r3
.NoTruncate:	lbz	r3,0(r25)
		cmplwi	r3,"l"
		bne-	.NoLong

		ori	r20,r20,4
		addi	r25,r25,1
.NoLong:	lbz	r3,0(r25)
		addi	r25,r25,1
		cmplwi	r3,"d"
		beq-	.IsDecimal

		cmplwi	r3,"D"
		bne-	.NotDecimal

.IsDecimal:	bl	.GetParameter

		bl	.MakeDecimal

		b	.FmtOutput

.NotDecimal:	cmplwi	r3,"x"
		beq-	.IsHex

		cmplwi	r3,"X"
		bne-	.IsNotHex

.IsHex:		bl	.GetParameter

		bl	.MakeHex

		b	.FmtOutput

.IsNotHex:	cmplwi	r3,"s"
		bne-	.NotString

		bl	.GetIntParam

		mr.	r21,r21
		beq+	.DoFmt

		mr	r24,r21
		b	.StrOutput

.NotString:	cmplwi	r3,"b"
		bne-	.NoBSTR

		bl	.GetIntParam

		mr.	r21,r21
		beq+	.DoFmt

		rlwinm	r21,r21,2,0,29
		mr	r24,r21
		lbz	r19,0(r24)
		addi	r24,r24,1
		mr.	r19,r19
		beq+	.DoFmt

		subi	r19,r19,1
		lbzx	r0,r24,r19
		mr.	r0,r0
		beq-	.BSTROutput

		addi	r19,r19,1
		b	.BSTROutput

.NoBSTR:	cmplwi	r3,"u"
		beq-	.UnsignedDec

		cmplwi	r3,"U"
		bne-	.NoUnsignedDec

.UnsignedDec:	bl	.GetParameter

		bl	.OutputNum

		b	.FmtOutput

.NoUnsignedDec:	cmplwi	r3,"c"
		bne+	.NormalChar

		bl	.GetParameter

		stb	r21,0(r24)
		addi	r24,r24,1
.FmtOutput:	xor	r0,r0,r0
		stb	r0,0(r24)
		subi	r24,r26,16
.StrOutput:	mr	r28,r24
		li	r19,-1
.FmtLoop:	lbz	r0,0(r28)
		addi	r28,r28,1
		mr.	r0,r0
		beq-	.FmtZero

		subi	r19,r19,1
		b	.FmtLoop

.FmtZero:	not	r19,r19
.BSTROutput:	mr.	r22,r22
		beq-	.GetR19

		cmplw	r19,r22
		bgt-	.GetR22

.GetR19:	mr	r22,r19
.GetR22:	sub.	r23,r23,r22
		bge-	.FmtPos

		xor	r23,r23,r23
.FmtPos:	andi.	r0,r20,1
		bne-	.HasJust

		bl	.PerformPad

.HasJust:	mr.	r22,r22
		beq-	.ZeroParam

		mtctr	r22
.NextOne:	lbz	r3,0(r24)
		addi	r24,r24,1
		mr.	r30,r30
		bne-	.DoPutChProc4

		stb	r3,0(r18)
		addi	r18,r18,1
		b	.SkipToNext3

.DoPutChProc4:	mtlr	r30
		mr	r4,r3
		mr	r3,r18
		blrl	

		mr	r18,r3
.SkipToNext3:	bdnz+	.NextOne

.ZeroParam:	andi.	r0,r20,1
		beq+	.DoFmt

		bl	.PerformPad

		b	.DoFmt

#********************************************************************************************

.PerformPad:	mflr	r0
		stwu	r0,-4(r13)
		li	r19," "
		andi.	r0,r20,2
		beq-	.NoZeroPad

		lbz	r3,0(r24)
		cmplwi	r3,"-"
		bne-	.DoPadding

		addi	r24,r24,1
		subi	r22,r22,1
		mr.	r30,r30
		bne-	.DoPutChProc2

		stb	r3,0(r18)
		addi	r18,r18,1
		b	.DoPadding

.DoPutChProc2:	mtlr	r30
		mr	r4,r3
		mr	r3,r18
		blrl	
		mr	r18,r3
.DoPadding:	li	r19,"0"
.NoZeroPad:	mr.	r23,r23
		beq-	.PadExit

		mtctr	r23
.PadNext:	mr	r3,r19
		mr.	r30,r30
		bne-	.DoPutChProc3

		stb	r3,0(r18)
		addi	r18,r18,1
		b	.SkipToNext2

.DoPutChProc3:	mtlr	r30
		mr	r4,r3
		mr	r3,r18
		blrl	
		mr	r18,r3
.SkipToNext2:	bdnz+	.PadNext

.PadExit:	lwz	r0,0(r13)
		addi	r13,r13,4
		mtlr	r0
		blr	

#********************************************************************************************

.GetParameter:	andi.	r0,r20,4
		bne-	.GetIntParam
		lwz	r29,0(r13)
		lha	r21,0(r29)
		addi	r29,r29,2
		stw	r29,0(r13)
		blr	

.GetIntParam:	lwz	r29,0(r13)
		lwz	r21,0(r29)
		addi	r29,r29,4
		stw	r29,0(r13)
		blr
		
#*******************************************************************************************

.GetNum:	xor	r3,r3,r3
.NextNum:	lbz	r19,0(r25)
		addi	r25,r25,1
		cmplwi	r19,"0"
		blt-	.NoValidNum

		cmplwi	r19,"9"
		bgt-	.NoValidNum

		mulli	r3,r3,10
		subi	r19,r19,48
		add	r3,r3,r19
		b	.NextNum

.NoValidNum:	subi	r25,r25,1
		blr	

#********************************************************************************************

.MakeDecimal:	mr.	r21,r21
		bge-	.OutputNum

		li	r0,"-"
		stb	r0,0(r24)
		addi	r24,r24,1
		neg	r21,r21
		
.OutputNum:	mflr	r3
		bl	.GetTable

.long		0x3b9aca00,0x05f5e100,0x00989680,0x000f4240,0x000186a0
.long		0x00002710,0x000003e8,0x00000064,0x0000000a,0x00000000

.GetTable:	mflr	r28
		mtlr	r3
		li	r3,"0"
.NumLoop:	lwz	r27,0(r28)
		addi	r28,r28,4
		mr.	r27,r27
		beq-	.NormalNum
		li	r19,47
.SmallNLoop:	addi	r19,r19,1
		cmplw	r21,r27
		sub	r21,r21,r27
		bge+	.SmallNLoop
		add	r21,r21,r27
		cmplw	r3,r19
		beq+	.NumLoop
		li	r3,0
		stb	r19,0(r24)
		addi	r24,r24,1
		b	.NumLoop

.NormalNum:	li	r3,"0"

		add	r21,r21,r3
		stb	r21,0(r24)
		addi	r24,r24,1
		blr

#********************************************************************************************

.MakeHex:	mr.	r21,r21
		beq+	.NormalNum

		xor	r27,r27,r27
		andi.	r0,r20,4
		bne-	.IsNotLongH

		li	r19,4
		mtctr	r19
		rlwinm	r21,r21,16,0,31
		b	.NextHex

.IsNotLongH:	li	r19,8
		mtctr	r19
.NextHex:	rlwinm	r21,r21,4,0,31
		andi.	r3,r21,15
		bne-	.MakeComp

		mr.	r27,r27
		beq-	.SkipToNext

.MakeComp:	eqv	r27,r27,r27
		cmplwi	r3,9
		bgt-	.IsLetter

		addi	r3,r3,48
		b	.OutputHex

.IsLetter:	addi	r3,r3,55
.OutputHex:	stb	r3,0(r24)
		addi	r24,r24,1
.SkipToNext:	bdnz+	.NextHex

		blr

#********************************************************************************************
#
#	void DebugStartFunction(PowerPCBase, FunctionString, r4, r5, r6, r7) // r3,r31
#
#********************************************************************************************

DebugStartFunction:
		lbz	r0,sonnet_DebugLevel(r3)
		mr.	r0,r0
		beq	.NoDebug

		prolog 228,'TOC'
		
		stwu	r3,-4(r13)
		stwu	r4,-4(r13)
		stwu	r5,-4(r13)
		stwu	r27,-4(r13)
		stwu	r28,-4(r13)
		stwu	r29,-4(r13)
		stwu	r30,-4(r13)		

		mr	r27,r3
		mr	r30,r4
		mr	r29,r5
		mr.	r31,r31
		bne	.NoRun

		lwz	r29,PP_OFFSET-MN_PPSTRUCT(r4)
		lwz	r30,PP_CODE-MN_PPSTRUCT(r4)
		
.NoRun:		bl CreateMsgFramePPC

		mr	r28,r3
		mr	r4,r30
		mr	r5,r29

		bl	.GetTextOffSet
		
.FText:		nop

.GetTextOffSet:	mflr	r4
		addi	r5,r4,FRun68K-.FText
		add	r31,r5,r31
		stw	r31,MN_PPSTRUCT+4(r28)
		lwz	r5,ThisPPCProc(r27)
		lwz	r31,LN_NAME(r5)
		stw	r31,MN_PPSTRUCT(r28)
		stw	r5,MN_PPC(r28)
		loadreg	r31,'DBG!'
		stw	r31,MN_IDENTIFIER(r28)
		stw	r30,MN_PPSTRUCT+8(r28)
		stw	r29,MN_PPSTRUCT+12(r28)
		stw	r6,MN_PPSTRUCT+16(r28)
		
		mr	r4,r7					##Used for timing speed
		mftbl	r7					##of functions
		stw	r7,MN_PPSTRUCT+20(r28)
		mr	r7,r4					##Restore r7
		
		lwz	r4,sonnet_MCPort(r27)
		stw	r4,MN_MCPORT(r28)
		mr	r4,r28

		bl SendMsgFramePPC

		lwz	r30,0(r13)
		lwz	r29,4(r13)
		lwz	r28,8(r13)
		lwz	r27,12(r13)
		lwz	r5,16(r13)
		lwz	r4,20(r13)
		lwz	r3,24(r13)
		addi	r13,r13,28

		epilog 'TOC'
		
.NoDebug:	blr
		
#********************************************************************************************
#
#	void DebugEndFunction(PowerPCBase, FunctionString, r3) // r30, r31
#
#********************************************************************************************

DebugEndFunction:
		lbz	r0,sonnet_DebugLevel(r30)
		mr.	r0,r0
		beq	.NoDebug

		prolog 228,'TOC'
		
		stwu	r3,-4(r13)
		stwu	r4,-4(r13)
		stwu	r5,-4(r13)
		stwu	r28,-4(r13)
		stwu	r29,-4(r13)
		stwu	r30,-4(r13)

		mr	r29,r3

		bl CreateMsgFramePPC
		
		mr	r28,r3

		bl	.GetTxtOffSet2
		
.FText2:	nop

.GetTxtOffSet2:	mflr	r4
		addi	r5,r4,FRun68K-.FText2
		add	r31,r5,r31
		stw	r31,MN_PPSTRUCT+4(r28)
		lwz	r5,ThisPPCProc(r30)		
		lwz	r31,LN_NAME(r5)
		stw	r31,MN_PPSTRUCT(r28)
		stw	r5,MN_PPC(r28)
		loadreg	r31,'DBG2'
		stw	r31,MN_IDENTIFIER(r28)
		stw	r29,MN_PPSTRUCT+8(r28)
		lwz	r4,sonnet_MCPort(r30)
		stw	r4,MN_MCPORT(r28)

		mr	r4,r28
					
		bl SendMsgFramePPC

		lwz	r30,0(r13)
		lwz	r29,4(r13)
		lwz	r28,8(r13)
		lwz	r5,12(r13)
		lwz	r4,16(r13)
		lwz	r3,20(r13)
		addi	r13,r13,24

		epilog 'TOC'
		
#********************************************************************************************
#
#	Start/Exit code for RunPPC Tasks
#
#********************************************************************************************		

StartCode:	bl	.StartRunPPC

		mr	r25,r3

.WasNoEMsg:	lwz	r31,ThisPPCProc(r25)
		lwz	r4,TC_SIGALLOC(r31)
		loadreg	r28,0xfffff100
		and.	r4,r4,r28
		mr	r3,r25

		bl WaitPPC

		mr	r5,r3
		li	r28,SIGF_DOS				#Standard msg port wait bit
		andc.	r5,r5,r28
		beq	.NextEMsg

		lwz	r4,TASKPPC_MIRRORPORT(r31)
		lwz	r4,MP_SIGTASK(r4)
		mr	r3,r25
		
		bl Signal68K		
		
.NextEMsg:	lwz	r4,TASKPPC_MSGPORT(r31)
		mr	r3,r25

		bl GetMsgPPC

		mr.	r30,r3
		beq	.WasNoEMsg
		
		lwz	r29,MN_IDENTIFIER(r30)
		loadreg	r4,'END!'
		cmpw	r4,r29
		beq	.KillRunPPC
		loadreg r4,'TPPC'
		cmpw	r4,r29
		bne	.NextEMsg

		mr	r3,r25

		bl	.StartRunPPC
		
		b	.NextEMsg
		
#********************************************************************************************

.StartRunPPC:		
		mflr	r0	
		stwu	r0,-4(r1)
		stwu	r2,-4(r1)
		stwu	r3,-4(r1)
		stwu	r4,-4(r1)
		stwu	r5,-4(r1)
		stwu	r6,-4(r1)
		stwu	r7,-4(r1)
		stwu	r8,-4(r1)
		stwu	r9,-4(r1)
		stwu	r10,-4(r1)
		stwu	r11,-4(r1)
		stwu	r12,-4(r1)
		stwu	r13,-4(r1)
		stwu	r14,-4(r1)
		stwu	r15,-4(r1)
		stwu	r16,-4(r1)
		stwu	r17,-4(r1)
		stwu	r18,-4(r1)
		stwu	r19,-4(r1)
		stwu	r20,-4(r1)
		stwu	r21,-4(r1)
		stwu	r22,-4(r1)
		stwu	r23,-4(r1)
		stwu	r24,-4(r1)
		stwu	r25,-4(r1)
		stwu	r26,-4(r1)
		stwu	r27,-4(r1)
		stwu	r28,-4(r1)
		stwu	r29,-4(r1)
		stwu	r30,-4(r1)
		stwu	r31,-4(r1)
		
		stfdu	f0,-8(r1)
		stfdu	f1,-8(r1)
		stfdu	f2,-8(r1)
		stfdu	f3,-8(r1)
		stfdu	f4,-8(r1)
		stfdu	f5,-8(r1)
		stfdu	f6,-8(r1)
		stfdu	f7,-8(r1)
		stfdu	f8,-8(r1)
		stfdu	f9,-8(r1)
		stfdu	f10,-8(r1)
		stfdu	f11,-8(r1)
		stfdu	f12,-8(r1)
		stfdu	f13,-8(r1)
		stfdu	f14,-8(r1)
		stfdu	f15,-8(r1)
		stfdu	f16,-8(r1)
		stfdu	f17,-8(r1)
		stfdu	f18,-8(r1)
		stfdu	f19,-8(r1)
		stfdu	f20,-8(r1)
		stfdu	f21,-8(r1)
		stfdu	f22,-8(r1)
		stfdu	f23,-8(r1)
		stfdu	f24,-8(r1)
		stfdu	f25,-8(r1)
		stfdu	f26,-8(r1)
		stfdu	f27,-8(r1)
		stfdu	f28,-8(r1)
		stfdu	f29,-8(r1)
		stfdu	f30,-8(r1)
		stfdu	f31,-8(r1)

		mr	r9,r30
		mr	r8,r9
		
		lwz	r2,ThisPPCProc(r3)
		stw	r9,TASKPPC_STARTMSG(r2)
		lwz	r3,MN_ARG1(r8)
		stw	r3,TC_SIGALLOC(r2)
		lwz	r2,PP_REGS+12*4(r8)
		lwz	r3,PP_REGS+0*4(r8)
		lwz	r4,PP_REGS+1*4(r8)
		lwz	r5,PP_REGS+8*4(r8)
		lwz	r6,PP_REGS+9*4(r8)
		lwz	r22,PP_REGS+2*4(r8)
		lwz	r23,PP_REGS+3*4(r8)
		lwz	r24,PP_REGS+4*4(r8)
		lwz	r25,PP_REGS+5*4(r8)
		lwz	r26,PP_REGS+6*4(r8)
		lwz	r27,PP_REGS+7*4(r8)
		lwz	r28,PP_REGS+10*4(r8)
		lwz	r29,PP_REGS+11*4(r8)
		lwz	r30,PP_REGS+13*4(r8)
		lwz	r31,PP_REGS+14*4(r8)
		lfd	f1,PP_FREGS+0*8(r8)
		lfd	f2,PP_FREGS+1*8(r8)
		lfd	f3,PP_FREGS+2*8(r8)
		lfd	f4,PP_FREGS+3*8(r8)
		lfd	f5,PP_FREGS+4*8(r8)
		lfd	f6,PP_FREGS+5*8(r8)
		lfd	f7,PP_FREGS+6*8(r8)
		lfd	f8,PP_FREGS+7*8(r8)
		lwz	r9,PP_OFFSET(r8)
		
		mr	r17,r8
		lwz	r8,PP_CODE(r8)		
		add	r8,r8,r9
		mr.	r9,r9					#Check if it is a PPC library
		beq	.NoLibCall				#call from M68K code
		
		lwz	r8,2(r8)				#If so, get offset
		
.NoLibCall:	mtlr	r8
				
		li	r0,0
		mr	r7,r0
		mr	r8,r0
		mr	r9,r0
		mr	r10,r0
		mr 	r11,r0
		mr	r12,r0
		mr	r20,r0
		mr	r21,r0
		
		lwz	r16,PP_STACKPTR(r17)
		mr.	r16,r16
		beq 	.NoStack
		lwz	r15,PP_STACKSIZE(r17)
		mr.	r15,r15
		beq	.NoStack

		mtctr	r15
		mr	r14,r1
		sub	r1,r1,r15
		mr	r19,r1
		lwz	r16,MN_STACKFRAME(r17)
		la	r16,MN_PPSTRUCT(r16)
		subi	r19,r19,1
		subi	r16,r16,1

.CpPPCStck:	lbzu	r18,1(r16)
		stbu	r18,1(r19)
		bdnz	.CpPPCStck
		
		subi	r1,r1,24
		stw	r14,0(r1)
		b	.DoneStack

.NoStack:	stwu	r1,-60(r1)
.DoneStack:	lwz	r16,PP_FLAGS(r17)
		rlwinm.	r16,r16,(32-PPB_LINEAR),31,31
		beq	.NotLinear

		mr	r5,r22
		mr	r6,r23
		mr	r7,r24
		mr	r8,r25
		mr	r9,r26
		mr	r10,r27

.NotLinear:	loadreg	r0,'WARP'
		
		lwz	r16,PP_FLAGS(r17)
		li	r19,0
		mr	r18,r19
		mr	r17,r19
		mr	r15,r19
		mr	r14,r19
		rlwinm.	r16,r16,(32-PPB_THROW),31,31
		mr	r16,r19
		beq	.NoThrow

		trap						#For PP_THROW
	
.NoThrow:	blrl

ExitCode:	lwz	r14,0(r1)
		lwz	r14,368(r14)				#PowerPCBase
		lwz	r17,ThisPPCProc(r14)
		lwz	r17,TASKPPC_STARTMSG(r17)
		lwz	r17,PP_FLAGS(r17)
		rlwinm.	r17,r17,(32-PPB_LINEAR),31,31
		beq	.NotLinear2

		mr	r22,r5
		mr	r23,r6
		mr	r24,r7
		mr	r25,r8
		mr	r26,r9
		mr	r27,r10

.NotLinear2:	mr	r12,r3

		bl CreateMsgFramePPC

		mr	r9,r3
		mr	r3,r12

		subi	r10,r9,4		
		li	r11,48
		li	r7,0
		mtctr	r11
.ClearEndMsg:	stwu	r7,4(r10)
		bdnz	.ClearEndMsg

		loadreg r7,'FPPC'
		stw	r7,MN_IDENTIFIER(r9)
		li	r7,192
		sth	r7,MN_LENGTH(r9)
		li	r7,NT_MESSAGE
		stb	r7,LN_TYPE(r9)

		lwz	r7,ThisPPCProc(r14)
		lwz	r8,TC_SIGALLOC(r7)
		stw	r8,MN_ARG1(r9)		
		lwz	r7,TASKPPC_STARTMSG(r7)						
		lwz	r7,MN_REPLYPORT(r7)		
		stw	r7,MN_REPLYPORT(r9)
		stw	r2,PP_REGS+12*4(r9)
		stw	r3,PP_REGS+0*4(r9)
		stw	r4,PP_REGS+1*4(r9)
		stw	r5,PP_REGS+8*4(r9)
		stw	r6,PP_REGS+9*4(r9)
		stw	r22,PP_REGS+2*4(r9)
		stw	r23,PP_REGS+3*4(r9)
		stw	r24,PP_REGS+4*4(r9)
		stw	r25,PP_REGS+5*4(r9)
		stw	r26,PP_REGS+6*4(r9)
		stw	r27,PP_REGS+7*4(r9)
		stw	r28,PP_REGS+10*4(r9)
		stw	r29,PP_REGS+11*4(r9)
		stw	r30,PP_REGS+13*4(r9)
		stw	r31,PP_REGS+14*4(r9)		
		stfd	f1,PP_FREGS+0*8(r9)
		stfd	f2,PP_FREGS+1*8(r9)
		stfd	f3,PP_FREGS+2*8(r9)
		stfd	f4,PP_FREGS+3*8(r9)
		stfd	f5,PP_FREGS+4*8(r9)
		stfd	f6,PP_FREGS+5*8(r9)
		stfd	f7,PP_FREGS+6*8(r9)
		stfd	f8,PP_FREGS+7*8(r9)
		lwz	r8,sonnet_MCPort(r14)
		lwz	r7,MN_STACKFRAME(r9)			#StackFrame
		stw	r8,MN_MCPORT(r9)

		lwz	r4,ThisPPCProc(r14)
		stw	r4,MN_PPC(r9)

		lwz	r4,TASKPPC_STARTMSG(r4)			#Free original 68K -> PPC message

		bl FreeMsgFramePPC
		
		lwz	r4,PP_STACKPTR(r9)
		mr.	r4,r4
		beq	.NoStck
		
		lwz	r4,PP_STACKSIZE(r9)
		mr.	r4,r4
		beq	.NoStck
		
		mr	r4,r7
		
		bl FreeMsgFramePPC				#Free up StackFrame
		
.NoStck:	mr	r4,r9
		
		bl SendMsgFramePPC
		
		lwz	r1,0(r1)
		lfd	f31,0(r1)
		lfdu	f30,8(r1)
		lfdu	f29,8(r1)
		lfdu	f28,8(r1)
		lfdu	f27,8(r1)
		lfdu	f26,8(r1)
		lfdu	f25,8(r1)
		lfdu	f24,8(r1)
		lfdu	f23,8(r1)
		lfdu	f22,8(r1)
		lfdu	f21,8(r1)
		lfdu	f20,8(r1)
		lfdu	f19,8(r1)
		lfdu	f18,8(r1)
		lfdu	f17,8(r1)
		lfdu	f16,8(r1)
		lfdu	f15,8(r1)
		lfdu	f14,8(r1)
		lfdu	f13,8(r1)
		lfdu	f12,8(r1)
		lfdu	f11,8(r1)
		lfdu	f10,8(r1)
		lfdu	f9,8(r1)
		lfdu	f8,8(r1)
		lfdu	f7,8(r1)
		lfdu	f6,8(r1)
		lfdu	f5,8(r1)
		lfdu	f4,8(r1)
		lfdu	f3,8(r1)
		lfdu	f2,8(r1)
		lfdu	f1,8(r1)
		lfdu	f0,8(r1)
		
		lwzu	r31,8(r1)
		lwzu	r30,4(r1)
		lwzu	r29,4(r1)
		lwzu	r28,4(r1)
		lwzu	r27,4(r1)
		lwzu	r26,4(r1)
		lwzu	r25,4(r1)
		lwzu	r24,4(r1)
		lwzu	r23,4(r1)
		lwzu	r22,4(r1)
		lwzu	r21,4(r1)
		lwzu	r20,4(r1)
		lwzu	r19,4(r1)
		lwzu	r18,4(r1)
		lwzu	r17,4(r1)
		lwzu	r16,4(r1)
		lwzu	r15,4(r1)
		lwzu	r14,4(r1)
		lwzu	r13,4(r1)
		lwzu	r12,4(r1)
		lwzu	r11,4(r1)
		lwzu	r10,4(r1)
		lwzu	r9,4(r1)
		lwzu	r8,4(r1)
		lwzu	r7,4(r1)
		lwzu	r6,4(r1)
		lwzu	r5,4(r1)
		lwzu	r4,4(r1)
		lwzu	r3,4(r1)
		lwzu	r2,4(r1)
		lwzu	r0,4(r1)
		mtlr	r0
		
		addi	r1,r1,4
		
		blr
		
#********************************************************************************************		

.KillRunPPC:	lwz	r31,ThisPPCProc(r25)			#r25 = PowerPCBase
		mr	r4,r30

		bl FreeMsgFramePPC

		la	r4,NumAllTasks(r25)			#Tasks -1
		lwz	r3,0(r4)
		subi	r3,r3,1
		stw	r3,0(r4)
		dcbst	r0,r4

		li	r7,TS_REMOVED
		stb	r7,TC_STATE(r31)
		
		mr	r3,r25

		bl CauseInterrupt
		
Pause:		nop
		nop
		b	Pause
		
#********************************************************************************************		

WarpIllegal:	illegal					#Fake warp.library functions
		b	WarpIllegal			#intended to debug iFusion
		
#********************************************************************************************
#********************************************************************************************

FRun68K:		.byte	"Run68K",0
FWaitFor68K:		.byte	"WaitFor68K",0
FSPrintF:		.byte	"SPrintF",0
FRun68KLowLevel:	.byte	"Run68KLowLevel",0
FAllocVecPPC:		.byte	"AllocVecPPC",0
FFreeVecPPC:		.byte	"FreeVecPPC",0
FCreateTaskPPC:		.byte	"CreateTaskPPC",0
FDeleteTaskPPC:		.byte	"DeleteTaskPPC",0
FFindTaskPPC:		.byte	"FindTaskPPC",0
FInitSemaphorePPC:	.byte	"InitSemaphorePPC",0
FFreeSemaphorePPC:	.byte	"FreeSemaphorePPC",0
FAddSemaphorePPC:	.byte	"AddSemaphorePPC",0
FRemSemaphorePPC:	.byte	"RemSemaphorePPC",0
FObtainSemaphorePPC:	.byte	"ObtainSemaphorePPC",0
FAttemptSemaphorePPC:	.byte	"AttemptSemaphorePPC",0
FReleaseSemaphorePPC:	.byte	"ReleaseSemaphorePPC",0
FFindSemaphorePPC:	.byte	"FindSemaphorePPC",0
FInsertPPC:		.byte	"InsertPPC",0
FAddHeadPPC:		.byte	"AddHeadPPC",0
FAddTailPPC:		.byte	"AddtailPPC",0
FRemovePPC:		.byte	"RemovePPC",0
FRemHeadPPC:		.byte	"RemHeadPPC",0
FRemTailPPC:		.byte	"RemTailPPC",0
FEnqueuePPC:		.byte	"EnqueuePPC",0
FFindNamePPC:		.byte	"FindNamePPC",0
FFindTagItemPPC:	.byte	"FindTagItemPPC",0
FGetTagDataPPC:		.byte	"GetTagItemPPC",0
FNextTagItemPPC:	.byte	"NextTagItemPPC",0
FAllocSignalPPC:	.byte	"AllocSignalPPC",0
FFreeSignalPPC:		.byte	"FreeSignalPPC",0
FSetSignalPPC:		.byte	"SetSignalPPC",0
FSignalPPC:		.byte	"SignalPPC",0
FWaitPPC:		.byte	"WaitPPC",0
FSetTaskPriPPC:		.byte	"SetTaskPriPPC",0
FSignal68K:		.byte	"Signal68K",0
FSetCache:		.byte	"SetCache",0
FSetExcHandler:		.byte	"SetExcHandler",0
FRemExcHandler:		.byte	"RemExcHandler",0
FSuper:			.byte	"Super",0
FUser:			.byte	"User",0
FSetHardware:		.byte	"SetHardware",0
FModifyFPExc:		.byte	"ModifyFPExc",0
FWaitTime:		.byte	"WaitTime",0
FChangeStack:		.byte	"ChangeStack",0
FLockTaskList:		.byte	"LockTaskList",0
FUnLockTaskList:	.byte	"UnlockTaskList",0
FSetExcMMU:		.byte	"SetExcMMU",0
FClearExcMMU:		.byte	"ClearExcMMU",0
FChangeMMU:		.byte	"ChangeMMU",0
FGetInfo:		.byte	"GetInfo",0
FCreateMsgPortPPC:	.byte	"CreateMsgPortPPC",0
FDeleteMsgPortPPC:	.byte	"DeleteMsgPortPPC",0
FAddPortPPC:		.byte	"AddPortPPC",0
FRemPortPPC:		.byte	"RemPortPPC",0
FFindPortPPC:		.byte	"FindPortPPC",0
FWaitPortPPC:		.byte	"WaitPortPPC",0
FPutMsgPPC:		.byte	"PutMsgPPC",0
FGetMsgPPC:		.byte	"GetMsgPPC",0
FReplyMsgPPC:		.byte	"ReplyMsgPPC",0
FFreeAllMem:		.byte	"FreeAllMem",0
FCopyMemPPC:		.byte	"CopyMemPPC",0
FAllocXMsgPPC:		.byte	"AllocXMsgPPC",0
FFreeXMsgPPC:		.byte	"FreeXMsgPPC",0
FPutXMsgPPC:		.byte	"PutXMsgPPC",0
FGetSysTimePPC:		.byte	"GetSysTimePPC",0
FAddTimePPC:		.byte	"AddTimePPC",0
FSubTimePPC:		.byte	"SubTimePPC",0
FCmpTimePPC:		.byte	"CmpTimePPC",0
FSetReplyPortPPC:	.byte	"SetReplyPortPPC",0
FSnoopTask:		.byte	"SnoopTask",0
FEndSnoopTask:		.byte	"EndSnoopTask",0
FGetHALInfo:		.byte	"GetHALInfo",0
FSetScheduling:		.byte	"SetScheduling",0
FFindTaskByID:		.byte	"FindTaskByID",0
FSetNiceValue:		.byte	"SetNiceValue",0
FTrySemaphorePPC:	.byte	"TrySemaphorePPC",0
FAllocPrivateMem:	.byte	"AllocPrivateMem",0
FFreePrivateMem:	.byte	"FreePrivateMem",0
FResetPPC:		.byte	"ResetPPC",0
FNewListPPC:		.byte	"NewListPPC",0
FSetExceptPPC:			.byte	"SetExceptPPC",0
FObtainSemaphoreSharedPPC:	.byte	"ObtainSemaphoreSharedPPC",0
FAttemptSemaphoreSharedPPC:	.byte	"AttemptSempahoreSharedPPC",0
FProcurePPC:		.byte	"ProcurePPC",0
FVacatePPC:		.byte	"VacatePPC",0
FCauseInterrupt:	.byte	"CauseInterrupt",0
FCreatePoolPPC:		.byte	"CreatePoolPPC",0
FDeletePoolPPC:		.byte	"DeletePoolPPC",0
FAllocPooledPPC:	.byte	"AllocPooledPPC",0
FFreePooledPPC:		.byte	"FreePooledPPC",0
FRawDoFmtPPC:		.byte	"RawDoFmtPPC",0
FPutPublicMsgPPC:	.byte	"PutPublicMsgPPC",0
FAddUniquePortPPC:	.byte	"AddUniquePortPPC",0
FAddUniqueSemaphorePPC:	.byte	"AddUniqueSemaphorePPC",0
FIsExceptionMode:	.byte	"IsExceptionMode",0
FAllocatePPC:		.byte	"AllocatePPC",0
FDeallocatePPC:		.byte	"DeallocatePPC",0

			.balign	4

#********************************************************************************************
EndFunctions:
