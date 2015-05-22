.include ppcdefines.i
.include sonnet_libppc.i
.include ppcmacros-std.i

.set FunctionsLen,(EndFunctions-SetExcMMU)

.global FunctionsLen

.global SetExcMMU,ClearExcMMU,ConfirmInterrupt,InsertPPC,AddHeadPPC,AddTailPPC
.global RemovePPC,RemHeadPPC,RemTailPPC,EnqueuePPC,FindNamePPC,ResetPPC,NewListPPC
.global	AddTimePPC,SubTimePPC,CmpTimePPC,AllocVecPPC,FreeVecPPC,GetInfo,GetSysTimePPC
.global NextTagItemPPC,GetTagDataPPC,FindTagItemPPC,FlushL1DCache,FreeSignalPPC
.global	AllocXMsgPPC,FreeXMsgPPC,CreateMsgPortPPC,DeleteMsgPortPPC,AllocSignalPPC
.global AtomicTest,AtomicDone,SetSignalPPC,LockTaskList,UnLockTaskList
.global	InitSemaphorePPC,FreeSemaphorePPC,ObtainSemaphorePPC,AttemptSemaphorePPC
.global	ReleaseSemaphorePPC,AddSemaphorePPC,RemSemaphorePPC,FindSemaphorePPC
.global AddPortPPC,RemPortPPC,FindPortPPC,WaitPortPPC,Super,User,WarpSuper,WarpUser
.global PutXMsgPPC,WaitFor68K,Run68K,Signal68K,CopyMemPPC,SetReplyPortPPC
.global	TrySemaphorePPC,CreatePoolPPC

.global SPrintF,Run68KLowLevel,CreateTaskPPC,DeleteTaskPPC,FindTaskPPC,SignalPPC
.global WaitPPC,SetTaskPriPPC,SetCache,SetExcHandler,RemExcHandler,SetHardware
.global ModifyFPExc,WaitTime,ChangeStack,ChangeMMU,PutMsgPPC,GetMsgPPC,ReplyMsgPPC
.global FreeAllMem,SnoopTask,EndSnoopTask,GetHALInfo,SetScheduling,FindTaskByID
.global SetNiceValue,AllocPrivateMem,FreePrivateMem,SetExceptPPC,ObtainSemaphoreSharedPPC
.global AttemptSemaphoreSharedPPC,ProcurePPC,VacatePPC,CauseInterrupt,DeletePoolPPC
.global AllocPooledPPC,FreePooledPPC,RawDoFmtPPC,PutPublicMsgPPC,AddUniquePortPPC
.global AddUniqueSemaphorePPC,IsExceptionMode

.section "LibBody","acrx"

#********************************************************************************************
#
#	void SetExcMMU(void) // Only from within Exception Handler
#
#********************************************************************************************

SetExcMMU:
		stw	r4,-8(r1)
		mfmsr	r4
		ori	r4,r4,(PSL_IR|PSL_DR)
		mtmsr	r4				#Reenable MMU
		isync
		lwz	r4,-8(r1)
		blr
	
#********************************************************************************************
#
#	void ClearExcMMU(void) // Only from within Exception Handler
#
#********************************************************************************************

ClearExcMMU:
		stw	r4,-8(r1)
		mfmsr	r4
		andi.	r4,r4,~(PSL_IR|PSL_DR)@l
		mtmsr	r4				#Disable MMU
		isync
		lwz	r4,-8(r1)
		blr	
	
#********************************************************************************************
#
#	void ConfirmInterrupt(void)
#
#********************************************************************************************

ConfirmInterrupt:
		stw	r3,-12(r1)
		stw	r4,-8(r1)
		lis	r3,EUMBEPICPROC
		lwz	r4,0xa0(r3)			#Read IACKR to acknowledge it
		eieio
	
		lis	r3,EUMB
		lis	r4,0x100			#Clear IM0 bit to clear interrupt
		stw	r4,0x100(r3)
		eieio

		li	r4,0
		lis	r3,EUMBEPICPROC
		stw	r4,0xb0(r3)			#Write 0 to EOI to End Interrupt

		lwz	r4,-8(r1)
		lwz	r3,-12(r1)
		blr

#********************************************************************************************
#
#	void InsertPPC(list, node, nodepredecessor) // r4,r5,r6
#
#********************************************************************************************

InsertPPC:	
		mr.	r6,r6
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

AddHeadPPC:
		lwz	r3,0(r4)
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

AddTailPPC:
		addi	r4,r4,4
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

RemovePPC:
		lwz	r3,0(r4)
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)
		blr	


#********************************************************************************************
#
#	node = RemHeadPPC(list) // r3=r4
#
#********************************************************************************************

RemHeadPPC:
		lwz	r5,0(r4)
		lwz	r3,0(r5)
		mr.	r3,r3
		beq-	.E2
		stw	r3,0(r4)
		stw	r4,4(r3)
		mr	r3,r5
.E2:		blr	

#********************************************************************************************
#
#	node = RemTailPPC(list) // r3=r4
#
#********************************************************************************************

RemTailPPC:
		lwz	r3,8(r4)
		lwz	r5,4(r3)
		mr.	r5,r5
		beq-	.E3
		stw	r5,8(r4)
		addi	r4,r4,4
		stw	r4,0(r5)
.E3:		blr	

#********************************************************************************************
#
#	void EnqueuePPC(list, node) // r4,r5
#
#********************************************************************************************

EnqueuePPC:
		lbz	r3,9(r5)
		extsb	r3,r3
		lwz	r6,0(r4)
.Loop1:		mr	r4,r6
		lwz	r6,0(r4)
		mr.	r6,r6
		beq-	.Link1
		lbz	r7,9(r4)
		extsb	r7,r7
		cmpw	r3,r7
		ble+	.Loop1
		lwz	r3,4(r4)
.Link1:		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
		blr	

#********************************************************************************************
#
#	node = FindNamePPC(list, name) // r3=r4,r5
#
#********************************************************************************************

FindNamePPC:
		lwz	r3,0(r4)
		mr.	r3,r3
		beq-	.E4
		subi	r8,r5,1
.Loop2:		mr	r6,r3
		lwz	r3,0(r6)
		mr.	r3,r3
		beq-	.E4
		lwz	r4,10(r6)
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
.E4:		blr	

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
		lwz	r6,4(r4)
		lwz	r7,4(r5)
		add	r6,r6,r7
		lis	r0,0xf
		ori	r0,r0,0x4240
		li	r3,0
		cmplw	r6,r0
		blt-	.Link2
		sub	r6,r6,r0
		li	r3,1
.Link2:		lwz	r8,0(r4)
		lwz	r9,0(r5)
		add	r8,r8,r9
		add	r8,r8,r3
		stw	r6,4(r4)
		stw	r8,0(r4)
		blr	

#********************************************************************************************
#
#	void SubTimePPC(Dest, Source)	// r4,r5
#
#********************************************************************************************

SubTimePPC:
		lwz	r6,4(r4)
		lwz	r7,4(r5)
		sub	r6,r6,r7
		li	r3,0
		mr.	r6,r6
		bge-	.Link3
		lis	r0,0xf
		ori	r0,r0,0x4240
		add	r6,r6,r0
		li	r3,1
.Link3:		lwz	r8,0(r4)
		lwz	r9,0(r5)
		sub	r8,r8,r9
		sub	r8,r8,r3
		stw	r6,4(r4)
		stw	r8,0(r4)
		blr	


#********************************************************************************************
#
#	Result = CmpTimePPC(Dest, Source)	// r3=r4,r5
#
#********************************************************************************************

CmpTimePPC:
		lwz	r6,0(r4)
		lwz	r7,0(r5)
		cmplw	r6,r7
		blt-	.Link5
		bgt-	.Link4
		lwz	r8,4(r4)
		lwz	r9,4(r5)
		cmplw	r8,r9
		blt-	.Link5
		bgt-	.Link4
		li	r3,0
		b	.E5
.Link4:		li	r3,-1
		b	.E5
.Link5:		li	r3,1
.E5:		blr

#********************************************************************************************
#
#	MemBlock = AllocVecPPC(Length)	// r3=r4 (r5 and r6 are ignored for now
#
#********************************************************************************************

AllocVecPPC:	BUILDSTACKPPC

		stwu	r31,-4(r13)
		stwu	r9,-4(r13)
		stwu	r8,-4(r13)

		mr.	r3,r4
		beq	.AllocErr
		loadreg	r5,MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC		#Fixed for now
		
		addi	r8,r4,0x38					#d0
		mr	r31,r8
		mr	r9,r5						#d1
		lwz	r4,SysBase(r0)
		li	r5,_LVOAllocMem
			
		bl 	Run68KLowLevel
		
		mr.	r4,r3
		beq	.AllocErr
		
		addi	r3,r3,0x27
		loadreg	r5,-32
		and.	r3,r3,r5
		
		stw	r4,-4(r3)
		stw	r31,-8(r3)
		
.AllocErr:	lwz	r8,0(r13)
		lwz	r9,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12
		
		DSTRYSTACKPPC
		
		blr
	
#********************************************************************************************
#
#	Result = FreeVecPPC(MemBlock)	// r3=r4 r3 should be MEMERR_SUCCESS on success
#
#********************************************************************************************		

FreeVecPPC:
		BUILDSTACKPPC
		
		stwu	r8,-4(r13)
		stwu	r7,-4(r13)
		
		lwz	r7,-4(r4)					#a1
		lwz	r8,-8(r4)					#d0
		lwz	r4,SysBase(r0)
		li	r5,_LVOFreeMem

		bl 	Run68KLowLevel
		
		lwz	r7,0(r13)
		lwz	r8,4(r13)
		addi	r13,r13,8
		
		DSTRYSTACKPPC
		
		blr		

#********************************************************************************************
#
#	void  GetInfo(PPCInfoTagList)	// r4
#
#********************************************************************************************		

GetInfo:	
		BUILDSTACKPPC

		stwu	r8,-4(r13)
		stwu	r7,-4(r13)
		stwu	r6,-4(r13)
		stwu	r5,-4(r13)
		stwu	r4,-4(r13)
		li	r6,1
		
		bl WarpSuper
		
		mfspr	r3,PVR
		stw	r3,CPUInfo(r0)
		mfspr	r3,HID1
		stw	r3,CPUHID1(r0)
		mfspr	r3,HID0
		stw	r3,CPUHID0(r0)
		mfspr	r3,SDR1
		stw	r3,CPUSDR1(r0)
		
		bl WarpUser	
		
.TagLoop:	bl NextTagItemPPC

		mr.	r3,r3
		beq	.NoTags		
		rlwinm	r7,r3,0,0,19
		loadreg	r8,0x80102000
		cmpw	r7,r8		
		beq+	.UserTag
.NextInList:	addi	r4,r4,8
		b	.TagLoop
		
.NoTags:	lwz	r4,0(r13)
		lwzu	r5,4(r13)
		lwzu	r6,4(r13)
		lwzu	r7,4(r13)
		lwzu	r8,4(r13)
		addi	r13,r13,4
		
		DSTRYSTACKPPC
		
		blr

.UserTag:	rlwinm.	r7,r3,0,27,31
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
		b	.NextInList
		

.INFO_CPU:	lwz	r7,CPUInfo(r0)
		rlwinm	r7,r7,16,28,31
		andi.	r7,r7,4
		beq+	.G3
		loadreg r7,CPUF_G4
		b	.GotCPU		
.G3:		loadreg	r7,CPUF_G3
		b	.GotCPU
		
.INFO_PVR:	lwz	r7,CPUInfo(r0)
.GotCPU:	stw	r7,4(r4)
		b	.NextInList
		
.INFO_ICACHE:	lwz	r8,CPUHID0(r0)
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

.INFO_DCACHE:	lwz	r8,CPUHID0(r0)
		rlwinm	r8,r8,20,29,31
		b	.ReUse
		
.INFO_PAGETABLE:
		lwz	r7,CPUSDR1(r0)
		rlwinm	r7,r7,0,0,15
		b 	.StoreTag
		
.INFO_TABLESIZE:
		lwz	r8,CPUSDR1(r0)
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
		
.INFO_CPUCLOCK:	lwz	r7,CPUHID1(r0)
		rlwinm	r7,r7,4,28,31
		cmpwi	r7,1
		beq	.MHz500
		cmpwi	r7,13
		beq	.MHz400
		li	r7,0
		b 	.StoreTag
.MHz500:	loadreg	r7,500000000
		b	.StoreTag
.MHz400:	loadreg r7,400000000
		b	.StoreTag		

#********************************************************************************************
#
#	void  GetSysTimePPC(TimeVal)	// r4
#
#********************************************************************************************

GetSysTimePPC:	
		BUILDSTACKPPC
		
		stwu	r7,-4(r13)
		stwu	r6,-4(r13)

		mr	r6,r4
		loadreg	r5,SonnetBusClock
		rlwinm	r5,r5,30,2,31
.Loop5:		mftbu	r3
		mftbl	r4
		mftbu	r7
		cmplw	r7,r3
		bne+	.Loop5
		bl	.Link17
		stw	r3,0(r6)
		mullw	r7,r5,r3
		sub	r7,r4,r7
		lis	r0,15
		ori	r0,r0,16960
		mullw	r4,r0,r7
		mulhw	r3,r0,r7
		bl	.Link17
		stw	r3,4(r6)
		lwz	r6,0(r13)
		lwzu	r7,4(r13)
		addi	r13,r13,4
		
		DSTRYSTACKPPC
		
		blr

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
		stwu	r8,-4(r13)
		stwu	r7,-4(r13)
		stwu	r6,-4(r13)
		stwu	r5,-4(r13)		
		li	r6,1
.NextTag:	lwz	r5,0(r4)
		mr.	r5,r5
		beq	.EndTag
		subf.	r7,r6,r5
		beq-	.IgnoreTag
		subf.	r7,r6,r7
		beq-	.ChainTag
		subf.	r7,r6,r7
		beq-	.SkipTags
.EndTag:	mr	r3,r5
		lwz	r5,0(r13)
		lwzu	r6,4(r13)
		lwzu	r7,4(r13)
		lwzu	r8,4(r13)
		addi	r13,r13,4

		blr

.IgnoreTag:	addi	r4,r4,8
		b	.NextTag		
.ChainTag:	lwz	r4,4(r4)
		b	.NextTag
.SkipTags:	lwz	r7,4(r4)
		li	r8,3
		slw	r7,r7,r8
		add 	r4,r4,r7
		b	.NextTag
			
#********************************************************************************************
#
#	value = GetTagDataPPC(tagValue, defaultVal, taglist) // r3=r4,r5,r6
#
#********************************************************************************************		
		
GetTagDataPPC:	
		stwu	r8,-4(r13)
		stwu	r7,-4(r13)
		stwu	r6,-4(r13)
		stwu	r5,-4(r13)
		stwu	r4,-4(r13)
		mr	r8,r5
		mr	r5,r6
		li	r6,1
		
		mflr	r7
		
		bl FindTagItemPPC

		mtlr	r7
		mr.	r3,r3
		bne	.Done
		mr	r3,r8
		b	.Done2
		
.Done:		lwz	r3,4(r3)		
.Done2:		lwz	r4,0(r13)
		lwzu	r5,4(r13)
		lwzu	r6,4(r13)
		lwzu	r7,4(r13)
		lwzu	r8,4(r13)
		addi	r13,r13,4

		blr

#********************************************************************************************
#
#	value = FindTagItemPPC(tagValue, taglist) // r3=r4,r5
#
#********************************************************************************************		

FindTagItemPPC:	
		stwu	r8,-4(r13)
		stwu	r7,-4(r13)
		stwu	r6,-4(r13)
		stwu	r5,-4(r13)
		stwu	r4,-4(r13)
		mr	r8,r4
		mr	r4,r5
		li	r6,1
		
.TagLoop2:	mflr	r7

		bl NextTagItemPPC

		mtlr	r7
		mr.	r3,r3
		beq	.Done2
		
		cmpw	r8,r3
		beq	.Done3
		addi	r4,r4,8
		b	.TagLoop2
		
.Done3:		mr	r3,r4
		b	.Done2

#********************************************************************************************
#
#	Support: void FlushL1DCache(void)
#
#********************************************************************************************

FlushL1DCache:
		BUILDSTACKPPC
		
		li	r4,0x7000

		li	r6,0x400
		mr	r5,r6
		mtctr	r6
	
.Fl1:		lwz	r6,0(r4)
		addi	r4,r4,L1_CACHE_LINE_SIZE
		bdnz+	.Fl1
	
		li	r4,0x7000
		mtctr	r5
		
.Fl2:		dcbf	r0,r4
		addi	r4,r4,L1_CACHE_LINE_SIZE
		bdnz+	.Fl2

		DSTRYSTACKPPC

		blr
				
#********************************************************************************************
#
#	message = AllocXMsgPPC(bodysize, replyport) // r3=r4,r5
#
#********************************************************************************************


AllocXMsgPPC:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		addi	r31,r4,20
		mr	r30,r5
		mr	r4,r31
		
		bl AllocVecPPC
		
		mr.	r3,r3
		beq-	.NoMaam
		stw	r30,MN_REPLYPORT(r3)
		sth	r31,MN_LENGTH(r3)
		
.NoMaam:	lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		DSTRYSTACKPPC
				
		blr		
		
#********************************************************************************************
#
#	void FreeXMsgPPC(message) // r4
#
#********************************************************************************************		

FreeXMsgPPC:
		BUILDSTACKPPC
		
		bl FreeVecPPC
		
		DSTRYSTACKPPC
		
		blr		

#********************************************************************************************
#
#	MsgPortPPC = CreateMsgPortPPC(void) // r3
#
#********************************************************************************************

CreateMsgPortPPC:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		li	r4,100
		lis	r5,1
		ori	r5,r5,1
		li	r6,32
		
		bl AllocVecPPC
	
		mr.	r3,r3
		beq-	.NoMsgMem
		mr	r30,r3
		addi	r4,r30,34
		stw	r4,8(r4)
		li	r0,0
		stwu	r0,4(r4)
		stwu	r4,-4(r4)
		addi	r4,r30,20
		stw	r4,8(r4)
		li	r0,0
		stwu	r0,4(r4)
		stwu	r4,-4(r4)
		li	r4,-1
		
		bl AllocSignalPPC
	
		cmpwi	r3,-1
		beq-	.NoSigFree
		stb	r3,15(r30)
		addi	r4,r30,48
		
		bl InitSemaphorePPC

		cmpwi	r3,-1
		bne-	.NoSemMem
		lwz	r3,88(r31)
		stw	r3,16(r30)
		li	r0,0
		stb	r0,14(r30)
		li	r0,101
		stb	r0,8(r30)
		mr	r4,r30
		b	.HaveAll

.NoSemMem:	lbz	r4,15(r30)

		bl FreeSignalPPC

.NoSigFree:	mr	r4,r30

		bl FreeVecPPC
	
.NoMsgMem:  	li	r4,0
.HaveAll:	mr	r3,r4
		lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		DSTRYSTACKPPC

		blr
		
#********************************************************************************************
#
#	void DeleteMsgPortPPC(MsgPortPPC) // r4
#
#********************************************************************************************

DeleteMsgPortPPC:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		mr.	r31,r4
		beq-	.NoPortDef

		addi	r4,r31,48

		bl FreeSemaphorePPC

		lbz	r4,15(r31)
		
		bl FreeSignalPPC

		mr	r4,r31
		
		bl FreeVecPPC

.NoPortDef:	lwz	r31,0(r13)
		addi	r13,r13,4

		DSTRYSTACKPPC
				
		blr

#********************************************************************************************
#
#	void FreeSignalPPC(signalNum) // r4
#
#********************************************************************************************

FreeSignalPPC:
		BUILDSTACKPPC

		extsb	r4,r4
		cmpwi	r4,-1
		beq-	.NoSigDef

		lwz	r5,RunningTask(r0)		

		lwz	r3,TC_SIGALLOC(r5)
		li	r6,1
		slw	r6,r6,r4
		andc	r3,r3,r6
		stw	r3,TC_SIGALLOC(r5)

.NoSigDef:	
		DSTRYSTACKPPC
		
		blr

#********************************************************************************************
#
#	signalnum = AllocSignalPPC(signalNum) // r4
#
#********************************************************************************************

AllocSignalPPC:
		BUILDSTACKPPC
		
		extsb	r4,r4

		lwz	r5,RunningTask(r0)

		lwz	r3,TC_SIGALLOC(r5)
		cmpwi	r4,-1
		beq-	.RandomSig

		li	r6,1
		slw	r6,r6,r4
		and.	r0,r6,r3
		bne-	.NoSigHere
		b	.GetSig

.RandomSig:	lis	r6,-32768
		li	r4,31
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
		
.WaitingLine:	li	r4,Atomic
		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitingLine

		lwz	r7,TC_SIGRECVD(r5)
		andc	r7,r7,r6
		stw	r7,TC_SIGRECVD(r5)
		lwz	r7,TC_SIGWAIT(r5)
		andc	r7,r7,r6
		stw	r7,TC_SIGWAIT(r5)

		li	r4,Atomic
		bl AtomicDone
		
		lwz	r4,0(r13)
		addi	r13,r13,4

.EndSig:	mr	r4,r3
		mr	r3,r4
		
		DSTRYSTACKPPC
		
		blr	
		
#********************************************************************************************
#
#	Support: result =  AtomicTest(TestLocation) // r3=r4
#
#********************************************************************************************

AtomicTest:		
		lwarx	r0,0,r4
		cmpwi	r0,0
		bne-	.AtomicOn
		li	r0,-1
		stwcx.	r0,0,r4
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
#	oldSignals = SetSignalPPC(newSignals. signalMask) // r3=r4,r5
#
#********************************************************************************************

SetSignalPPC:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		lwz	r6,RunningTask(r0)

		mr	r30,r4
		
.WaitingLine2:	li	r4,Atomic
		bl AtomicTest
		
		mr.	r3,r3
		beq+	.WaitingLine2

		lwz	r31,TC_SIGRECVD(r6)
		and	r30,r30,r5
		andc	r7,r31,r5
		or	r30,r30,r7
		stw	r30,TC_SIGRECVD(r6)
		
		li	r4,Atomic
		bl AtomicDone

		mr	r3,r6
		li	r4,0
		bl	CheckExcSignal

		mr	r3,r31
		lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		DSTRYSTACKPPC
		
		blr

#********************************************************************************************
#
#	TaskPtr = LockTaskList(void) // r3
#
#********************************************************************************************

LockTaskList:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)

		lwz	r4,TaskListSem(r0)

		bl ObtainSemaphorePPC

		li	r3,AllTasks
		
		lwz	r31,0(r13)
		addi	r13,r13,4
		
		DSTRYSTACKPPC
		
		blr	

#********************************************************************************************
#
#	void UnLockTaskList(void)
#
#********************************************************************************************

UnLockTaskList:
		BUILDSTACKPPC
		
		lwz	r4,TaskListSem(r0)

		bl ReleaseSemaphorePPC

		DSTRYSTACKPPC
		
		blr

#********************************************************************************************
#
#	status = InitSemaphorePPC(SignalSemaphorePPC) // r3=r4
#
#********************************************************************************************

InitSemaphorePPC:
		BUILDSTACKPPC
				
		stwu	r31,-4(r13)
		mr	r31,r4

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
		lis	r5,1
		ori	r5,r5,1
		li	r6,32

		bl AllocVecPPC

		mr.	r3,r3
		beq-	.SemDone
		stw	r3,SSPPC_RESERVE(r31)
		li	r3,-1

.SemDone:	lwz	r31,0(r13)
		addi	r13,r13,4
		
		DSTRYSTACKPPC
		
		blr	

#********************************************************************************************
#
#	void FreeSemaphorePPC(SignalSemaphorePPC) // r4
#
#********************************************************************************************

FreeSemaphorePPC:
		BUILDSTACKPPC
				
		mr.	r4,r4
		beq-	.NoSemDef

		lwz	r4,SSPPC_RESERVE(r4)

		bl FreeVecPPC

.NoSemDef:	
		DSTRYSTACKPPC

		blr

#********************************************************************************************
#
#	void ObtainSemaphorePPC(SignalSemaphorePPC) // r4
#
#********************************************************************************************

ObtainSemaphorePPC:
		BUILDSTACKPPC
				
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

		mr	r30,r4

.WaitRes:	li	r4,Atomic
		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitRes
		lha	r5,SS_QUEUECOUNT(r30)
		addi	r5,r5,1
		sth	r5,SS_QUEUECOUNT(r30)
		extsh.	r0,r5
		bne-	.link21

		lwz	r3,RunningTask(r0)
		stw	r3,SS_OWNER(r30)
		
		li	r4,Atomic
		bl AtomicDone

		b	.Obtained

.link21:	lwz	r3,RunningTask(r0)
		lwz	r4,SS_OWNER(r30)
		cmplw	r3,r4
		bne-	.SemNotFree

		li	r4,Atomic
		bl AtomicDone

		b	.Obtained

.SemNotFree:	stwu	r29,-4(r13)
		mr	r29,r13
		subi	r13,r13,12
		subi	r5,r29,12
		stw	r3,8(r5)
		lwz	r4,TC_SIGRECVD(r3)
		ori	r4,r4,16
		xori	r4,r4,16
		stw	r4,TC_SIGRECVD(r3)
		addi	r4,r30,SS_WAITQUEUE
		addi	r4,r4,4
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)

		li	r4,Atomic
		bl AtomicDone

		lis	r4,0
		ori	r4,r4,16
		
		bl WaitPPC

		mr	r13,r29
		lwz	r29,0(r13)
		addi	r13,r13,4
		b	.DoneWait

.Obtained:	lha	r5,14(r30)
		addi	r5,r5,1
		sth	r5,14(r30)
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
		
		DSTRYSTACKPPC

		blr

#********************************************************************************************
#
#	status = AttemptSemaphorePPC(SignalSemaphorePPC) // r4
#
#********************************************************************************************

AttemptSemaphorePPC:
		BUILDSTACKPPC
		
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

		mr	r30,r4

.WaitRes2:	li	r4,Atomic
		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitRes2
		
		lha	r5,SS_QUEUECOUNT(r30)
		addi	r5,r5,1
		lwz	r3,RunningTask(r0)
		mr.	r5,r5
		beq-	.NoQueue
		lwz	r4,SS_OWNER(r30)
		cmplw	r3,r4
		beq-	.AmOwner
		li	r6,0
		b	.Occupied

.NoQueue:	stw	r3,SS_OWNER(r30)
.AmOwner:	sth	r5,SS_QUEUECOUNT(r30)
		lha	r5,SS_NESTCOUNT(r30)
		addi	r5,r5,1
		sth	r5,SS_NESTCOUNT(r30)
		li	r6,-1

.Occupied:	li	r4,Atomic
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
		
		DSTRYSTACKPPC

		blr

#********************************************************************************************
#
#	void ReleaseSemaphorePPC(SignalSemaphorePPC) // r4
#
#********************************************************************************************

ReleaseSemaphorePPC:
		BUILDSTACKPPC
		
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

		mr	r31,r4

.WaitRes3:	li	r4,Atomic
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

		li	r4,Atomic
		bl AtomicDone

		b	.Released

.LastInLine:	lis	r0,0
		nop	
		stw	r0,SS_OWNER(r31)
		lha	r5,SS_QUEUECOUNT(r31)
		subi	r5,r5,1
		sth	r5,SS_QUEUECOUNT(r31)
		mr.	r5,r5
		bge-	.NotLast

		li	r4,Atomic
		bl AtomicDone

		b	.Released

.NotLast:	li	r0,1
		sth	r0,SSPPC_LOCK(r31)
		
		li	r4,Atomic
		bl AtomicDone

		addi	r4,r31,SS_WAITQUEUE
		lwz	r5,0(r4)
		lwz	r3,0(r5)
		mr.	r3,r3
		beq-	.link22
		stw	r3,0(r4)
		stw	r4,4(r3)
		mr	r3,r5
.link22:	mr.	r3,r3
		beq-	.link23
		mr	r30,r3
		lwz	r4,8(r30)
		andi.	r0,r4,1
		ori	r4,r4,1
		xori	r4,r4,1
		bne-	.link24
		mr.	r4,r4
		beq-	.link25
		stw	r4,SS_OWNER(r31)
.link28:	lha	r3,SS_NESTCOUNT(r31)
		addi	r3,r3,1
		sth	r3,SS_NESTCOUNT(r31)
		lis	r5,0
		ori	r5,r5,16

		bl SignalPPC

		b	.link23
		
.link25:	lwz	r5,20(r30)
		stw	r5,SS_OWNER(r31)
		lwz	r29,SS_WAITQUEUE(r31)
.link29:	stw	r31,20(r30)
		lha	r5,SS_NESTCOUNT(r31)
		addi	r5,r5,1
		sth	r5,SS_NESTCOUNT(r31)
		mr	r4,r30

		bl ReplyMsgPPC

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
		b	.link28
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
.link24:	lwz	r29,SS_WAITQUEUE(r31)
.link32:	lha	r5,SS_NESTCOUNT(r31)
		addi	r5,r5,1
		sth	r5,SS_NESTCOUNT(r31)
		mr.	r4,r4
		beq-	.link30
		lis	r5,0
		ori	r5,r5,16

		bl SignalPPC

		b	.link31
		
.link30:	stw	r31,20(r30)
		stw	r4,8(r30)
		mr	r4,r30

		bl ReplyMsgPPC

.link31:	lwz	r3,0(r29)
		mr.	r3,r3
		beq-	.link23
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

.link23:	li	r0,0
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
		lwz	r29,40(r13)
		lwz	r30,44(r13)
		lwz	r31,48(r13)
		addi	r13,r13,52
		lwz	r0,0(r13)
		addi	r13,r13,4
		mtctr	r0
		
		DSTRYSTACKPPC

		blr	

.Error68k:	li	r4,Atomic
		bl AtomicDone
.DeadEnd:	nop					#Not Yet Implemented
		b .DeadEnd

#********************************************************************************************
#
#	status =  AddSemaphorePPC(SignalSemaphorePPC) // r4
#
#********************************************************************************************

AddSemaphorePPC:
		BUILDSTACKPPC
				
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		mr	r30,r4
		
		bl InitSemaphorePPC

		mr.	r3,r3
		beq-	.NoInitSem

		lwz	r4,SemListSem(r0)
		
		bl ObtainSemaphorePPC
		
		lwz	r4,Semaphores(r0)
		mr	r5,r30
		
		bl EnqueuePPC
		
		lwz	r4,SemListSem(r0)
		
		bl ReleaseSemaphorePPC

		li	r3,-1

.NoInitSem:	lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		DSTRYSTACKPPC
		
		blr	

#********************************************************************************************
#
#	void RemSemaphorePPC(SignalSemaphorePPC) // r4
#
#********************************************************************************************

RemSemaphorePPC:
		BUILDSTACKPPC
				
		stwu	r31,-4(r13)

		mr	r31,r4

		bl FreeSemaphorePPC

		lwz	r4,SemListSem(r0)
		
		bl ObtainSemaphorePPC

		mr	r4,r31

		bl RemovePPC

		lwz	r4,SemListSem(r0)

		bl ReleaseSemaphorePPC

		lwz	r31,0(r13)
		addi	r13,r13,4
		
		DSTRYSTACKPPC

		blr

#********************************************************************************************
#
#	SignalsemaphorePPC = FindSemaphorePPC(SemaphoreName) // r3=r4
#
#********************************************************************************************

FindSemaphorePPC:
		BUILDSTACKPPC
				
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		mr	r30,r4

		lwz	r4,SemListSem(r0)

		bl ObtainSemaphorePPC

		lwz	r4,Semaphores(r0)
		mr	r5,r30

		bl FindNamePPC

		mr	r30,r3

		lwz	r4,SemListSem(r0)
		
		bl ReleaseSemaphorePPC

		mr	r3,r30
		lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		DSTRYSTACKPPC

		blr

#********************************************************************************************
#
#	void AddPortPPC(MsgPortPPC) // r4
#
#********************************************************************************************

AddPortPPC:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		mr	r30,r4
		addi	r3,r30,20
		stw	r3,8(r3)
		li	r0,0
		stwu	r0,4(r3)
		stwu	r3,-4(r3)

		lwz	r4,PortListSem(r0)

		bl ObtainSemaphorePPC

		lwz	r4,Ports(r0)
		mr	r5,r30

		bl EnqueuePPC

		lwz	r4,PortListSem(r0)
		
		bl ReleaseSemaphorePPC

		lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		DSTRYSTACKPPC
		
		blr	

#********************************************************************************************
#
#	void RemPortPPC(MsgPortPPC) // r4
#
#********************************************************************************************

RemPortPPC:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		mr	r31,r4

		lwz	r4,PortListSem(r0)

		bl ObtainSemaphorePPC

		mr	r4,r31
		lwz	r3,0(r4)
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)
		
		lwz	r4,PortListSem(r0)
		
		bl ReleaseSemaphorePPC

		lwz	r31,0(r13)
		addi	r13,r13,4
		
		DSTRYSTACKPPC

		blr	

#********************************************************************************************
#
#	void FIndPortPPC(name) // r4
#
#********************************************************************************************

FindPortPPC:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		mr	r31,r3
		mr	r5,r4

		lwz	r4,PortListSem(r0)

		bl ObtainSemaphorePPC

		lwz	r4,Ports(r0)		

		bl FindNamePPC

		mr	r31,r3
		lwz	r4,PortListSem(r0)

		bl ReleaseSemaphorePPC

		mr	r3,r31
		lwz	r31,0(r13)
		addi	r13,r13,4
		
		DSTRYSTACKPPC
		
		blr	

#********************************************************************************************
#
#	message = WaitPortPPC(MsgPortPPC) // r4 (UNDER DEVELOPMENT)
#
#********************************************************************************************

WaitPortPPC:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		
		li	r28,SonnetBase
		mr	r31,r4

		addi	r4,r31,MP_PPC_SEM

		bl ObtainSemaphorePPC

		addi	r5,r31,MP_PPC_INTMSG
		lwz	r4,MP_PPC_INTMSG+LH_TAILPRED(r31)
		cmplw	r4,r5
		beq-	.Link33

.WaitInLine:	li	r4,Atomic
		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitInLine
		
		lbz	r3,628(r28)
		mr.	r3,r3
		beq-	.Link34

		li	r4,Atomic
		bl AtomicDone

.Link35:	lbz	r3,628(r28)
		mr.	r3,r3
		bne+	.Link35
		b	.WaitInLine
		
.Link34:	stw	r31,CurrentPort(r28)
		li	r0,-1
		stb	r0,628(r28)

		li	r4,Atomic
		bl AtomicDone

		bl CauseInterrupt

.Link36:	lbz	r3,628(r28)
		mr.	r3,r3
		bne+	.Link36

.Link33:	lwz	r3,MP_MSGLIST(r31)
		lwz	r4,LH_HEAD(r3)
		mr.	r4,r4
		bne-	.Link37

		lbz	r5,MP_SIGBIT(r31)
		addi	r30,r31,MP_MSGLIST
		li	r4,1
		slw	r29,r4,r5
.Link42:	addi	r4,r31,MP_PPC_SEM

		bl ReleaseSemaphorePPC

		mr	r4,r29

		bl WaitPPC

		mr	r27,r3
		addi	r4,r31,MP_PPC_SEM

		bl ObtainSemaphorePPC

		addi	r5,r31,MP_PPC_INTMSG
		lwz	r4,MP_PPC_INTMSG+LH_TAILPRED(r31)
		cmplw	r4,r5
		beq-	.Link38

.WaitInLine2:	li	r4,Atomic
		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitInLine2
		
		lbz	r3,628(r28)
		mr.	r3,r3
		beq-	.Link39

		li	r4,Atomic
		bl AtomicDone

.Link40:	lbz	r3,628(r28)
		mr.	r3,r3
		bne+	.Link40
		b	.WaitInLine2

.Link39:	stw	r31,CurrentPort(r28)
		li	r0,-1
		stb	r0,628(r28)

		li	r4,Atomic
		bl AtomicDone

		bl CauseInterrupt

.Link41:	lbz	r3,628(r28)
		mr.	r3,r3
		bne+	.Link41
		
.Link38:	mr	r3,r27
		lwz	r5,MP_MSGLIST(r31)
		lwz	r4,LH_HEAD(r5)
		mr.	r4,r4
		beq+	.Link42
		mr	r3,r5
.Link37:	mr	r5,r3
		addi	r4,r31,MP_PPC_SEM

		bl ReleaseSemaphorePPC

		mr	r3,r5
		lwz	r27,0(r13)
		lwz	r28,4(r13)
		lwz	r29,8(r13)
		lwz	r30,12(r13)
		lwz	r31,16(r13)
		addi	r13,r13,20
		
		DSTRYSTACKPPC
		
		blr
		
#********************************************************************************************
#
#	SuperKey = Super(void) // r3 (0 on first switch, -1 on the rest)
#
#********************************************************************************************

Super:
		BUILDSTACKPPC
		
		bl WarpSuper
		
		DSTRYSTACKPPC

		blr	

#********************************************************************************************
#
#	void User(SuperKey) // r4
#
#********************************************************************************************

User:
		BUILDSTACKPPC

		mr.	r4,r4
		bne-	.WrongKey

		bl WarpUser

.WrongKey:	
		DSTRYSTACKPPC
		
		blr

#********************************************************************************************
#
#	Support: SuperKey = WarpSuper(void) // r3
#
#********************************************************************************************

WarpSuper:
		li	r0,-1			#READ PVR (warp funcion -130)
.Violation:	mfspr	r3,PVR			#IF user then exception; r0/r3=0
		mr	r3,r0			#IF super then r0/r3=-1
		blr				#See Program Exception ($700)

#********************************************************************************************
#
#	void WarpUser(void)
#
#********************************************************************************************

WarpUser:
		lbz	r0,ExceptionMode(r0)
		mr.	r0,r0
		bne	.InException

		mfmsr	r0			
		ori	r0,r0,PSL_PR		#SET Bit 17 (PR) To User
		mtmsr	r0
.InException:	isync	
		blr

#********************************************************************************************
#
#	void PutXMsgPPC(MsgPort, message) // r4,r5 (UNDER DEVELOPMENT)
#
#********************************************************************************************

PutXMsgPPC:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		li	r31,NT_MESSAGE
		stb	r31,LN_TYPE(r5)
				
		mr	r31,r4
		mr	r30,r5
		
		bl	FlushL1DCache
				
		mr 	r4,r31
		mr	r5,r30
		
		bl Signal68K

.NoSigTask:	lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		DSTRYSTACKPPC
		
		blr

#********************************************************************************************
#
#	status = WaitFor68K(PPStruct) // r3=r4 (HACKED FUNCTION - UNDER DEVELOPMENT)
#
#********************************************************************************************

WaitFor68K:	
		BUILDSTACKPPC

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

		mr	r31,r4
		
.Check68K:
		bl 	WarpSuper
		
		la	r6,MN_IDENTIFIER(r31)
		dcbi	r0,r6

		bl 	WarpUser

		loadreg r30,"DONE"
		lwz	r6,MN_IDENTIFIER(r31)
		cmpw	r6,r30
		beq- 	.Done68K
		isync
		
		lwz	r3,RunningTask(r0)
		li	r4,TS_WAIT
		stb	r4,TC_STATE(r3)		
		
		bl 	CauseInterrupt
		
		b	.Check68K				

.Done68K:	bl	WarpSuper
		
		li	r30,6
		mtctr	r30
.PPInvalid:	dcbi	r0,r31
		addi	r31,r31,4
		bdnz	.PPInvalid
		
		bl	WarpUser

		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12
		
		DSTRYSTACKPPC
				
		blr
		
#********************************************************************************************
#
#	status = Run68K(PPStruct) // r3=r4
#
#********************************************************************************************

Run68K:		
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r24,-4(r13)
		stwu	r23,-4(r13)
		
		mr	r31,r4
					
		lis	r3,EUMB
		li	r24,OFTPR
		lwbrx	r30,r24,r3			
		addi	r23,r30,4
		loadreg	r4,0xc000
		or	r23,r23,r4
		loadreg r4,0xffff
		and	r23,r23,r4			#Keep it C000-FFFE		
		stwbrx	r23,r24,r3
		lwz	r30,0(r30)			
			
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
		
		loadreg	r5,"T68K"
		stw	r5,MN_IDENTIFIER(r30)
		lwz	r5,RunningTask(r0)
		stw	r5,MN_PPC(r30)
		la	r5,TASKPPC_SIZE(r5)
		lwz	r5,MN_MIRROR(r5)
		stw	r5,MN_MIRROR(r30)
		lwz	r4,MCTask(r0)
		la	r4,pr_MsgPort(r4)
		stw	r4,188(r30)			#MN_MCTASK
		li	r5,NT_MESSAGE
		stb	r5,LN_TYPE(r30)
		li	r5,192
		sth	r5,MN_LENGTH(r30)
		
		sync
				
		bl FlushL1DCache
		
		lis	r3,EUMB
		li	r24,OPHPR
		lwbrx	r31,r24,r3		
		stw	r30,0(r31)		
		addi	r23,r31,4
		loadreg	r4,0xbfff
		and	r23,r23,r4			#Keep it 8000-BFFE
		stwbrx	r23,r24,r3			#triggers Interrupt
		
		mr	r4,r30
		
		bl WaitFor68K
		
		subi	r4,r31,4
		addi	r29,r30,MN_PPSTRUCT-4		
		li	r6,PP_SIZE/4
		mtctr	r6
.CopyPPB:	lwzu	r7,4(r29)
		stwu	r7,4(r4)
		bdnz+	.CopyPPB
		
		li	r3,0
		
		lwz	r23,0(r13)
		lwzu	r24,4(r13)
		lwzu	r29,4(r13)
		lwzu	r30,4(r13)
		lwzu	r31,4(r13)
		addi	r13,r13,4

		DSTRYSTACKPPC
		
		blr
		
#********************************************************************************************
#
#	void Signal68K(Port, Message) // r4,r5
#
#********************************************************************************************

Signal68K:	
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		
		lis	r3,EUMB
		
		stw	r5,0x5c(r3)
		sync
		stw	r4,0x58(r3)
		sync
		
		lwz	r31,0(r13)
		addi	r13,r13,4
		
		DSTRYSTACKPPC
		
		blr	
	
#********************************************************************************************
#
#	void CopyMemPPC(source, dest, size) // r4,r5,r6
#
#********************************************************************************************

CopyMemPPC:
		BUILDSTACKPPC

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

.ExitCopy:	DSTRYSTACKPPC

		blr
		
#********************************************************************************************
#
#	oldport = SetReplyPortPPC(Message, MsgPortPPC) // r3=r4,r5
#
#********************************************************************************************
			
SetReplyPortPPC:
		BUILDSTACKPPC
		
		lwz	r3,14(r4)
		stw	r5,14(r4)
		
		DSTRYSTACKPPC
		
		blr

#********************************************************************************************
#
#	status = TrySemaphorePPC(SignalSemaphorePPC, Timeout) // r3=r4,r5
#
#********************************************************************************************

TrySemaphorePPC:
		BUILDSTACKPPC

		mfctr	r0
		stwu	r0,-4(r13)
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r12,-4(r13)
		stwu	r11,-4(r13)
		stwu	r10,-4(r13)
		stwu	r9,-4(r13)
		stwu	r8,-4(r13)
		stwu	r7,-4(r13)
		stwu	r6,-4(r13)
		stwu	r5,-4(r13)
		stwu	r4,-4(r13)
	
		mr	r30,r4
		mr	r28,r5
		
.WaitAt1:	li	r4,Atomic
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
		bne-	.NoTimer
		lwz	r3,RunningTask(r0)
		stw	r3,SS_OWNER(r30)
		
		lwz	r4,SSPPC_RESERVE(r30)		
		bl AtomicDone
		
		li	r4,Atomic
		bl AtomicDone

		b	.Jump1
		
.NoTimer:	lwz	r3,RunningTask(r0)
		lwz	r4,SS_OWNER(r30)
		cmplw	r3,r4
		bne-	.Diff1
		
		lwz	r4,SSPPC_RESERVE(r30)		
		bl AtomicDone
		
		li	r4,Atomic
		bl AtomicDone

		b	.Jump1
		
.Diff1:		stwu	r29,-4(r13)
		mr	r29,r13
		subi	r13,r13,12
		subi	r5,r29,12
		stw	r3,8(r5)
		lwz	r4,26(r3)
		ori	r4,r4,16
		xori	r4,r4,16
		stw	r4,26(r3)
		addi	r4,r30,16
		addi	r4,r4,4
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
		
		lwz	r4,SSPPC_RESERVE(r30)		
		bl AtomicDone

		li	r4,Atomic
		bl AtomicDone
		
		lis	r4,0
		ori	r4,r4,16
		mr	r5,r28
		
		bl WaitTime
		
		mr	r28,r3
.WeirdWait:	lhz	r3,SSPPC_LOCK(r30)
		mr.	r3,r3
		bne+	.WeirdWait
		
.WaitAt3:	li	r4,Atomic
		bl AtomicTest
		mr.	r3,r3
		beq+	.WaitAt3
		lhz	r3,SSPPC_LOCK(r30)
		mr.	r3,r3
		beq-	.Jump3
		
		li	r4,Atomic
		bl AtomicDone

		b	.WeirdWait
		
.Jump3:		lwz	r3,RunningTask(r0)
		lwz	r4,TC_SIGRECVD(r3)
		or	r4,r28,r4
		mr	r27,r4
		ori	r4,r4,16
		xori	r4,r4,16
		stw	r4,TC_SIGRECVD(r3)
		subi	r4,r29,12
		rlwinm.	r0,r28,28,31,31
		bne-	.Jump2
		lwz	r3,0(r4)
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)
		
.Jump2:		li	r4,Atomic
		bl AtomicDone

		mr	r13,r29
		lwz	r29,0(r13)
		addi	r13,r13,4
		rlwinm.	r0,r28,28,31,31
		beq-	.Exit1
		lha	r5,SS_NESTCOUNT(r30)
		subi	r5,r5,1
		sth	r5,SS_NESTCOUNT(r30)
.Jump1:		li	r3,-1
		b	.Exit2
		
.Exit1:		li	r3,0
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
		lwz	r27,36(r13)
		lwz	r28,40(r13)
		lwz	r29,44(r13)
		lwz	r30,48(r13)
		lwz	r31,52(r13)
		addi	r13,r13,56
		lwz	r0,0(r13)
		addi	r13,r13,4
		mtctr	r0

		DSTRYSTACKPPC

		blr
		
#********************************************************************************************
#
#	Void SetCache(cacheflags, start, length) // r4,r5,r6
#
#********************************************************************************************	
		
SetCache:
		BUILDSTACKPPC

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

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
		b	.DoneCache

.DCACHEINV: 	mr.	r5,r5
		beq-	.DoneCache
		mr.	r6,r6
		beq-	.DoneCache
		mr	r4,r5
		mr	r5,r6

		bl WarpSuper

		add	r5,r5,r4
		lis	r0,-1
		ori	r0,r0,65504
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
		
		bl WarpUser
		
		b	.DoneCache

.DCACHELOCK:	mr.	r5,r5				#ExceptionMode should be Neg?
		beq-	.DoneCache
		mr.	r6,r6
		beq-	.DoneCache

		lbz	r29,DLockState(r0)
		mr.	r29,r29
		bne	.DoneCache

		mr	r29,r5
		mr	r31,r6
		
		bl FlushL1DCache
		
		mr	r4,r29
		mr	r5,r31
		
		add	r5,r5,r4
		lis	r0,-1
		ori	r0,r0,65504
		and	r4,r4,r0
		addi	r5,r5,31
		and	r5,r5,r0
		sub	r5,r5,r4
		rlwinm	r5,r5,27,5,31
		mtctr	r5
.FillLoop:	lwz	r0,0(r4)
		addi	r4,r4,32
		bdnz+	.FillLoop
		
		bl WarpSuper
		
		mfspr	r0,HID0
		ori	r0,r0,HID0_DLOCK
		sync	
		mtspr	HID0,r0
		sync	
		isync		

		bl WarpUser
		
		li	r0,-1
		stb	r0,DLockState(r0)

		b	.DoneCache
				
.DCACHEOFF:	lbz	r29,DState(r0)			#ExceptionMode should be Neg?
		mr.	r29,r29
		bne	.DoneCache
		
		bl FlushL1DCache
		bl WarpSuper
		
		mfspr	r0,HID0
		ori	r0,r0,HID0_DCE
		xori	r0,r0,HID0_DCE
		sync	
		mtspr	HID0,r0
		
		bl WarpUser
		
		li	r0,-1
		stb	r0,DState(r0)
		
		b	.DoneCache

.ICACHELOCK:	bl WarpSuper

		mfspr	r0,HID0
		ori	r0,r0,HID0_ILOCK
		isync	
		mtspr	HID0,r0

		bl WarpUser

		b	.DoneCache

.DCACHEUNLOCK:	li	r0,0
		stb	r0,DLockState(r0)
		
		bl WarpSuper

		mfspr	r0,HID0
		ori	r0,r0,HID0_DLOCK
		xori	r0,r0,HID0_DLOCK
		mtspr	HID0,r0
		sync	
		isync		

		bl WarpUser
		
		b	.DoneCache

.DCACHEON:	li	r0,0
		stb	r0,DState(r0)		
		
		bl WarpSuper

		mfspr	r0,HID0
		ori	r0,r0,HID0_DCE
		mtspr	HID0,r0
		isync
		
		bl WarpUser
		
		b	.DoneCache

.ICACHEUNLOCK:	bl WarpSuper

		mfspr	r0,HID0
		ori	r0,r0,HID0_ILOCK
		xori	r0,r0,HID0_ILOCK
		mtspr	HID0,r0
		isync
		
		bl WarpUser

		b	.DoneCache

.ICACHEON:	bl WarpSuper

		mfspr	r0,HID0
		ori	r0,r0,HID0_ICE
		mtspr	HID0,r0
		isync

		bl WarpUser
		
		b	.DoneCache

.ICACHEOFF:	bl WarpSuper
		
		mfspr	r0,HID0
		ori	r0,r0,HID0_ICE
		xori	r0,r0,HID0_ICE
		isync	
		mtspr	HID0,r0

		bl WarpUser

		b	.DoneCache

.ICACHEINV:	mr.	r5,r5		
		beq-	.ICACHEINVALL
		mr.	r6,r6
		beq-	.ICACHEINVALL
		mr	r4,r5
		mr	r5,r6
		
		add	r5,r5,r4
		lis	r0,-1
		ori	r0,r0,65504
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

.ICACHEINVALL:  
		bl WarpSuper
		
		b	.Mojo1
.Mojo2:		mfspr	r0,HID0
		ori	r0,r0,HID0_ICFI
		mtspr	HID0,r0
		xori	r0,r0,HID0_ICFI
		mtspr	HID0,r0
		isync	
		b 	.Mojo3
.Mojo1:		b 	.Mojo2
		
.Mojo3:		bl WarpUser
		
		b	.DoneCache

.DCACHEFLUSH:	mr.	r5,r5
		beq-	.DCACHEFLUSHALL
		mr.	r6,r6
		beq-	.DCACHEFLUSHALL
		lbz	r29,DState(r0)
		mr.	r29,r29
		bne	.DoneCache
		lbz	r29,DLockState(r0)
		mr.	r29,r29
		bne	.DoneCache
		
		mr	r4,r5
		mr	r5,r6
		
		add	r5,r5,r4
		lis	r0,-1
		ori	r0,r0,65504
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

.DCACHEFLUSHALL:
		lbz	r29,DState(r0)
		mr.	r29,r29
		bne	.DoneCache
		lbz	r29,DLockState(r0)
		mr.	r29,r29
		bne	.DoneCache

		bl FlushL1DCache

.DoneCache:	lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12
		
		DSTRYSTACKPPC
		
		blr

#********************************************************************************************
#
#	Void ModifyFPExc(FPflags) // r4
#
#********************************************************************************************

ModifyFPExc:
		BUILDSTACKPPC

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

.NoDisInvalid:	DSTRYSTACKPPC

		blr
		
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
#	status = AddUniquePortPPC(MsgPortPPC) // r3=r4. r4 has an initialized LN_NAME
#
#********************************************************************************************

AddUniquePortPPC:
		BUILDSTACKPPC

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

		mr	r30,r4
		li	r29,-1

		lwz	r4,PortListSem(r0)
		bl ObtainSemaphorePPC

		lwz	r4,10(r30)
		bl FindPortPPC

		mr.	r3,r3
		bne-	.Duplicate
		
		mr	r4,r30
		bl AddPortPPC
		b	.SkipDup

.Duplicate:	li	r29,0
.SkipDup:	lwz	r4,PortListSem(r0)
		bl ReleaseSemaphorePPC

		mr	r3,r29

		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12
		
		DSTRYSTACKPPC

		blr
		
#********************************************************************************************
#
#	status =  AddUniqueSemaphorePPC(SignalSemaphorePPC) // r3=r4. r4 has an initialized LN_NAME
#
#********************************************************************************************

AddUniqueSemaphorePPC:
		BUILDSTACKPPC

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

		mr	r30,r4
		li	r29,-1

		lwz	r4,SemListSem(r0)
		bl ObtainSemaphorePPC

		lwz	r4,10(r30)
		bl FindSemaphorePPC

		mr.	r3,r3
		bne-	.Duplicate2

		mr	r4,r30
		bl AddSemaphorePPC
		
		b	.SkipDup2

.Duplicate2:	li	r29,0
.SkipDup2:	lwz	r4,SemListSem(r0)

		bl ReleaseSemaphorePPC

		mr	r3,r29

		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12

		DSTRYSTACKPPC

		blr
		
#********************************************************************************************
#
#	status =  PutPublicMsgPPC(Portname, message) // r3=r4,r5
#
#********************************************************************************************	
	
PutPublicMsgPPC:
		BUILDSTACKPPC		

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

		mr	r31,r4
		mr	r30,r5
		li	r29,-1

		lwz	r4,PortListSem(r0)
		bl ObtainSemaphorePPC

		mr	r4,r31
		bl FindPortPPC

		mr.	r3,r3
		beq-	.PortNotFound

		mr	r4,r3
		mr	r5,r30
		bl PutMsgPPC

		b	.SkipStatus

.PortNotFound:	li	r29,0
.SkipStatus:	lwz	r4,PortListSem(r0)
		bl ReleaseSemaphorePPC

		mr	r3,r29
		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12

		DSTRYSTACKPPC

		blr
#********************************************************************************************
#
#	void AllocPrivateMem(void)	// Dummy (as in powerpc.library)
#
#********************************************************************************************

AllocPrivateMem:
		BUILDSTACKPPC

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12

		DSTRYSTACKPPC
		
		blr	

#********************************************************************************************
#
#	void FreePrivateMem(void)	// Dummy (as in powerpc.library)
#
#********************************************************************************************

FreePrivateMem:
		BUILDSTACKPPC

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12

		DSTRYSTACKPPC
		
		blr
		
#********************************************************************************************
#
#	TaskPPC = FindTaskByID(taskID) // r3=r4
#
#********************************************************************************************

FindTaskByID:		
		BUILDSTACKPPC

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

		li	r29,0
		mr	r31,r4

		bl LockTaskList

		mr	r30,r3
.NextNode:	lwz	r4,0(r3)
		mr.	r4,r4
		beq-	.EndSearch

		lwz	r3,14(r3)			#Link from mini list to big list
		lwz	r5,TASKPPC_ID(r3)
		cmpw	r5,r31
		bne-	.IncorrectID

		mr	r29,r3
		b	.EndSearch

.IncorrectID:	mr	r3,r4
		b	.NextNode

.EndSearch:	mr	r4,r30

		bl UnLockTaskList

		mr	r3,r29

		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12
		
		DSTRYSTACKPPC

		blr
		
#********************************************************************************************
#
#	OldNice = SetNiceValue(TaskPPC, Nice) // r3=r4,r5
#
#********************************************************************************************
	
SetNiceValue:
		stw	r2,20(r1)
		mflr	r0
		stw	r0,8(r1)
		mfcr	r0
		stw	r0,4(r1)
		stw	r13,-4(r1)
		subi	r13,r1,4
		stwu	r1,-284(r1)

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

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

		bl UnLockTaskList

		mr	r3,r29

		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12
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
#	StrLen = GetLen(String) // r3=r3 (Support)
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
#	EndOfDestStr = CopyStr(Source, Destination) // r3=r3,r4 (Support)
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
#	void InsertOnPri(??, Task) // r4,r5 (Support)
#
#********************************************************************************************

InsertOnPri:	
		mflr	r0
		stw	r0,8(r1)
		mfcr	r0
		stw	r0,4(r1)
		stw	r13,-4(r1)
		subi	r13,r1,4
		stwu	r1,-60(r1)

		stwu	r7,-4(r13)
		stwu	r6,-4(r13)
		stwu	r5,-4(r13)
		stwu	r4,-4(r13)
		stwu	r3,-4(r13)

		lwz	r3,TASKPPC_PRIORITY(r5)
		lwz	r6,TASKPPC_PRIOFFSET(r5)
		add	r3,r3,r6
		lwz	r6,TASKPPC_POWERPCBASE(r5)
		lwz	r7,658(r6)				#
		lwz	r6,670(r6)				#
		add	r6,r6,r7
		cmpw	r3,r6
		blt-	.LowerPri
		mr	r3,r6
		lwz	r0,TASKPPC_PRIORITY(r5)
		sub	r0,r3,r0
		stw	r0,TASKPPC_PRIOFFSET(r5)
.LowerPri:	lwz	r6,0(r4)
.Huh:		mr	r4,r6
		lwz	r6,0(r4)
		mr.	r6,r6
		beq-	.GoExit
		lwz	r0,TASKPPC_FLAGS(r4)
		rlwinm.	r0,r0,(31-TASKPPC_EMULATOR),31,31
		beq-	.NoEmul
		mr	r4,r6
		b	.GoExit
.NoEmul:	lwz	r7,TASKPPC_PRIORITY(r4)
		lwz	r0,TASKPPC_PRIOFFSET(r4)
		add	r7,r7,r0
		cmpw	r3,r7
		ble+	.Huh
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
		addi	r13,r13,20
		
		lwz	r1,0(r1)
		lwz	r13,-4(r1)
		lwz	r0,8(r1)
		mtlr	r0
		lwz	r0,4(r1)
		mtcr	r0
		
		blr

#********************************************************************************************
#
#	TaskPPC = CreateTaskPPC(TagItems) // r3=r4
#
#********************************************************************************************

CreateTaskPPC:	
		BUILDSTACKPPC	
 
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
 
		mr	r17,r2 
		mr	r30,r4 
		
		lwz	r3,RunningTask(r0)
		lwz	r23,PowerPCBase(r0)
		lwz	r4,TASKPPC_FLAGS(r3)
		ori	r4,r4,TASKPPC_CHOWN 
		stw	r4,TASKPPC_FLAGS(r3) 
 		
		loadreg	r4,TASKATTR_CODE
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
	 
		mr.	r3,r3 
		beq-	.Error01			#Error NoCode 
 
		mr	r25,r3 
		li	r4,246				#246 bytes
		loadreg	r5,0x10001			#attr = $10001
		li	r6,0				#default alignment 
 
 		bl AllocVecPPC
 
		mr.	r3,r3 
		beq-	.Error01			#Error NoMem 
 
		mr	r31,r3 
		stw	r31,TASKLINK_TASK(r31)
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
		loadreg	r5,0x10001
		li	r6,0 
 
 		bl AllocVecPPC
 
		mr.	r3,r3 
		beq-	.Error02			#Error NoMem 
 
		mr	r20,r3 
		stw	r3,TASKPPC_BATSTORAGE(r31)
 
		li	r4,24 
		loadreg	r5,0x10001
		li	r6,0 
 
 		bl AllocVecPPC
 
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
		lwz	r3,LH_HEAD(r4) 
		stw	r5,LH_HEAD(r4) 
		stw	r3,LH_HEAD(r5) 
		stw	r4,LH_TAIL(r5) 
		stw	r5,LH_TAIL(r3)
		
		loadreg	r4,TASKATTR_NAME 
		li	r5,0				#defaultVal 
		mr	r6,r30				#TagList 
 
		bl GetTagDataPPC
 
		mr.	r3,r3 
		beq-	.Error04			#Error NoName 
 
		mr	r29,r3
		bl	GetLen
 
		addi	r3,r3,1 
		mr	r4,r3 
		mr	r28,r3
		loadreg	r5,0x10001
		li	r6,0 
 
 		bl AllocVecPPC
 
		mr.	r3,r3 
		beq-	.Error04			#Error NoMem 
 
		mr	r22,r3 
		li	r4,24
		loadreg	r5,0x10001
		li	r6,0 
 
 		bl AllocVecPPC
 
		mr.	r3,r3 
		beq-	.Error05			#Error NoMem 
 
		mr	r21,r3				#Link name mem into  
		li	r0,1				#TC_MEMENTRY 
		sth	r0,ML_NUMENTRIES(r3) 
		stw	r22,ML_SIZE+ME_ADDR(r3) 
		stw	r28,ML_SIZE+ME_LENGTH(r3) 
		mr	r5,r3 
		addi	r4,r31,TC_MEMENTRY 
		lwz	r3,LH_HEAD(r4) 
		stw	r5,LH_HEAD(r4) 
		stw	r3,LH_HEAD(r5) 
		stw	r4,LH_TAIL(r5) 
		stw	r5,LH_TAIL(r3) 
		mr	r3,r29 
		mr	r4,r22 
		stw	r4,LN_NAME(r31)
 
		bl	CopyStr
 
 		loadreg r4,TASKATTR_SYSTEM
		li	r5,0 
		mr	r6,r30 
 
		bl GetTagDataPPC
 
		mr.	r3,r3 
		beq-	.NotSystemTask
 
		lis	r3,0 
		ori	r3,r3,TASKPPC_SYSTEM 
		stw	r3,TASKPPC_FLAGS(r31)
 
.NotSystemTask:	loadreg	r4,TASKATTR_ATOMIC
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		mr.	r3,r3 
		beq-	.NotAtomicTask
 
		lis	r3,0 
		ori	r3,r3,TASKPPC_ATOMIC
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
 
 		lwz	r3,RunningTask(r0)		#Mother task
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
		lis	r5,1 
		ori	r5,r5,1 
		li	r6,0 
 
 		bl AllocVecPPC
 
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
		loadreg	r5,0x10001
		li	r6,0 
 
 		bl AllocVecPPC
 
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
		lwz	r3,LH_HEAD(r4) 
		stw	r5,LH_HEAD(r4) 
		stw	r3,LH_HEAD(r5) 
		stw	r4,LH_TAIL(r5) 
		stw	r5,LH_TAIL(r3) 
 
		li	r4,544
		loadreg r5,0x10001 
		li	r6,0 
 
 		bl AllocVecPPC
 
		mr.	r3,r3 
		beq-	.Error08			#Error NoMem 
 
		stw	r3,TASKPPC_CONTEXTMEM(r31)
		mr	r26,r3
		lwz	r0,TC_SPREG(r31)
		stw	r0,36(r26)			#To location 9?? 
 
		li	r4,24
		loadreg r5,0x10001
		li	r6,0 
 
 		bl AllocVecPPC
 
		mr.	r3,r3 
		beq-	.Error09			#Error NoMem 
 
		mr	r24,r3				#Link into TC_MEMENTRY 
		li	r0,1 
		sth	r0,ML_NUMENTRIES(r3) 
		stw	r26,ML_SIZE+ME_ADDR(r3) 
		lis	r0,0 
		ori	r0,r0,544 
		stw	r0,ML_SIZE+ME_LENGTH(r3) 
		mr	r5,r3 
		addi	r4,r31,TC_MEMENTRY
		lwz	r3,LH_HEAD(r4) 
		stw	r5,LH_HEAD(r4) 
		stw	r3,LH_HEAD(r5) 
		stw	r4,LH_TAIL(r5) 
		stw	r5,LH_TAIL(r3) 
 
		lis	r0,0 
		ori	r0,r0,61552
		loadreg	r0,0xf070
		stw	r0,4(r26)			#f070 to location 1?? 
		stw	r25,148(r26)			#Code to location 37 
		stw	r2,40(r26)			#TOC to location 10 
		lwz	r3,8000(r2) 
		stw	r3,0(r26)			#8000(TOC) to location 0?? 
 
 		loadreg	r4,TASKATTR_BAT
		lis	r5,0 
		ori	r5,r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		addi	r4,r26,412 
		li	r0,16 
		mtctr	r0 
 
		mr.	r3,r3 
		beq-	.NoBATs				#NoBATs 
 
		addi	r5,r23,478			#Default BATS in PowerPCBase? 
		lis	r3,0 
		ori	r3,r3,TASKPPC_BAT
		lwz	r6,TASKPPC_FLAGS(r31) 
		or	r6,r6,r3 
		stw	r6,TASKPPC_FLAGS(r31) 
		b	.GetBATs 
 
.NoBATs:	addi	r5,r23,542			#Invalid BATS in PowerPCBase? 
.GetBATs:	lwzu	r0,4(r5)			#PowerPCBase 
		stwu	r0,4(r4)			#ContextMem 416-476 104-119 
		bdnz+	.GetBATs 
 
		addi	r5,r23,542			#Copy to TASKPPC_BATSTORAGE 
		subi	r4,r20,4 
		li	r0,16 
		mtctr	r0 
.ToStorage:	lwzu	r0,4(r5) 
		stwu	r0,4(r4) 
		bdnz+	.ToStorage 
 
		lwz	r3,18720(r2)			#? 
		stw	r3,64(r20)			#4 bytes at end of BATSTORAGE? 
		addi	r4,r26,480			#480 in ContextMem 
 
		lwz	r3,17652(r2)			#WARP! 
		lwz	r0,-346(r3) 
		mtlr	r0 
		blrl	 
 
 		loadreg	r4,TASKATTR_EXITCODE
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		stw	r3,152(r26)			#152 in ContextMem; Default=0 
 
 		loadreg r4,TASKATTR_PRIVATE
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		mr.	r3,r3 
		beq-	.NotPrivate			#Not Private 
 
		ori	r3,r3,1 
		b	.DoPrivate 
 
.NotPrivate:	li	r4,0 

		bl FindTaskPPC
 
.DoPrivate:	stw	r3,76(r26)			#Store MotherTask or 1 (prv) 
 
 		loadreg	r4,TASKATTR_INHERITR2
		li	r5,0 
		mr	r6,r30 
 
		bl GetTagDataPPC
 
		mr.	r3,r3 
		beq-	.NoInherit			#No Inherit 
 
		stw	r17,156(r26)			#Mother r2 to ContextMem 156 
		b	.DoInherit 
 
.NoInherit:	loadreg	r4,TASKATTR_R2
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		stw	r3,156(r26)			#r2 to ContextMem 156 
 
.DoInherit:	loadreg	r4,TASKATTR_R3
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		stw	r3,44(r26)			#r3 to ContextMem 44 
 
 		loadreg	r4,TASKATTR_R4
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		stw	r3,48(r26)			#r4 to ContextMem 48 
 		
 		loadreg	r4,TASKATTR_R5
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		stw	r3,52(r26)			#r5 to ContextMem 52 
  
  		loadreg	r4,TASKATTR_R6
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		stw	r3,56(r26)			#r6 to ContextMem 56 
 
 		loadreg	r4,TASKATTR_R7
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
 
		stw	r3,60(r26)			#r7 to ContextMem 60 
 
 		loadreg	r4,TASKATTR_R8
		li	r5,0 
		mr	r6,r30 
		
		bl GetTagDataPPC
 
		stw	r3,64(r26)			#r8 to ContextMem 64 
 
 		loadreg	r4,TASKATTR_R9
		li	r5,0 
		mr	r6,r30 
 
		bl GetTagDataPPC
	 
		stw	r3,68(r26)			#r9 to ContextMem 68 
 
 		loadreg	r4,TASKATTR_R10
		li	r5,0 
		mr	r6,r30 
 
		bl GetTagDataPPC 
 
		stw	r3,72(r26)			#r10 to ContextMem 72 
 
		li	r4,100
		loadreg	r5,0x10001
		li	r6,32 
 
 		bl AllocVecPPC
 
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
 
		li	r0,8 				#Unknown SIGBIT
		stb	r0,MP_SIGBIT(r18)			 
		addi	r4,r18,MP_PPC_SEM
 
 		bl InitSemaphorePPC
	 
		cmpwi	r3,-1				#Error 
		bne-	.Error11 
 
		stw	r31,MP_SIGTASK(r18)
		li	r0,PA_SIGNAL 
		stb	r0,MP_FLAGS(r18)
		li	r0,NT_PPCMSGPORT 
		stb	r0,LN_TYPE(r18)
		stw	r18,TASKPPC_MSGPORT(r31)
 
		loadreg	r4,TASKATTR_NOTIFYMSG
		li	r5,0 
		mr	r6,r30 
 
 		bl GetTagDataPPC
	 
		stw	r3,238(r31)			#Undocumented in docs?? 
							#Stops at 234?? 
		li	r4,928 
		lis	r5,1 
		ori	r5,r5,1 
		li	r6,0 
 
 		bl AllocVecPPC
 
		mr.	r3,r3 
		beq-	.Error12			#Error NoMem 
 
		stw	r3,242(r31)			#Undocumented in docs?? 
 
		mr	r16,r3 
 
		li	r4,18				#Dummy MirrorTask?
		loadreg	r5,0x10001
		li	r6,0 
 
 		bl AllocVecPPC
 
		mr.	r3,r3 
		beq-	.Error13			#Error NoMem 
 
		mr	r5,r3 
		stw	r31,14(r5)			#Store Taskpointer 
		stw	r5,TASKPPC_TASKPTR(r31)
		lwz	r3,LN_NAME(r31)			#Copy Name pointer 
		stw	r3,LN_NAME(r5) 
 
		lwz	r4,TaskListSem(r0)
 
 		bl ObtainSemaphorePPC
	 
		li	r4,AllTasks
		addi	r4,r4,4
		lwz	r3,4(r4) 
		stw	r5,4(r4)			#Insert dummy task in list 
		stw	r4,0(r5) 
		stw	r3,4(r5) 
		stw	r5,0(r3) 
 
 		la	r4,NumAllTasks(r0)
		lwz	r3,0(r4) 
		addi	r3,r3,1				#Set number of tasks
		stw	r3,0(r4) 
 
		dcbst	r0,r4				#Cache 
 
 		lwz	r4,TaskListSem(r0)
		
		bl ReleaseSemaphorePPC
 
		lwz	r3,17652(r2)			#WARP! ICACHEINVALL 
		lwz	r0,-100(r3) 
		mtlr	r0 
		blrl	 
 
		lwz	r3,17652(r2)			#WARP! 
		lwz	r0,-52(r3) 
		mtlr	r0 
		blrl	 
 
.WaitAtomic01:	li	r4,Atomic
		
		bl AtomicTest
 
		mr.	r3,r3 
		beq+	.WaitAtomic01			#Wait for Atomic 
 
		lwz	r3,TASKPPC_FLAGS(r31)
		andi.	r0,r3,TASKPPC_SYSTEM
		bne-	.SystemTask			#Yes -> c684 
 
		lwz	r5,IdDefTasks(r0)		#Normal Tasks +1
		addi	r5,r5,1 
		stw	r5,IdDefTasks(r0) 
		b	.SkipSystem 
 
.SystemTask:	lwz	r5,IdSysTasks(r0)		#System Tasks +1
		addi	r5,r5,1
		stw	r5,IdSysTasks(r0)
 
.SkipSystem:	stw	r5,TASKPPC_ID(r31)
		li	r0,TS_READY
		stb	r0,TC_STATE(r31)		 
		addi	r4,r23,102			#PowerPCBase +102 
		mr	r5,r31				#Task
		loadreg	r0,0x000186a0
		stw	r0,TASKPPC_QUANTUM(r31)
		lwz	r7,TASKPPC_NICE(r31)
		addi	r8,r7,20 
		rlwinm	r8,r8,2,0,29 
		lwz	r7,654(r23) 
		lwzx	r8,r7,r8 
		rlwinm	r8,r8,24,8,31 
		lis	r7,2000 
		ori	r7,r7,0 
		divwu	r0,r7,r8 
		stw	r0,TASKPPC_DESIRED(r31)
		
		bl	InsertOnPri
		
		li	r0,-1 
		stb	r0,626(r23)			#Some flag? (reschedule flag?)
 
 		li	r4,Atomic
 		
 		bl AtomicDone
 
		bl CauseInterrupt
 
		mr	r3,r31 
		b	.SkipToEnd			#All good, go to exit 
							#Error handling: 
.Error13:	mr	r4,r16

		bl FreeVecPPC
 
.Error12:	addi	r4,r18,48

		bl FreeSemaphorePPC
 
.Error11:	mr	r4,r18

		bl FreeVecPPC
 
.Error10:	mr	r4,r24

		bl FreeVecPPC
 
.Error09:	mr	r4,r26

		bl FreeVecPPC
 
.Error08:	mr	r4,r27

		bl FreeVecPPC
 
.Error07:	mr	r4,r28

		bl FreeVecPPC
 
.Error06:	mr	r4,r21

		bl FreeVecPPC 
 
.Error05:	mr	r4,r22

		bl FreeVecPPC
 
.Error04:	mr	r4,r19

		bl FreeVecPPC
 
.Error03:	mr	r4,r20

		bl FreeVecPPC
 
.Error02:	mr	r4,r31

		bl FreeVecPPC
 
.Error01:	mr	r0,r3 
		lbz	r3,18737(r2) 
		cmpwi	r3,1				#Check some flag? DebugMode?
		mr	r3,r0 
		blt-	.SetTask0 
 
		stwu	r3,-4(r13) 
		subi	r13,r13,4 
		li	r3,0 
		stwu	r3,-4(r13) 
		addi	r3,r2,6154 
		stwu	r3,-4(r13)
		bl	0x14058				#??
		
		addi	r13,r13,12 
		lwz	r3,0(r13) 
		addi	r13,r13,4 
.SetTask0:	li	r3,0				#Error flag in r3 
 
.SkipToEnd:	mr	r5,r3
		lwz	r3,RunningTask(r0)
 
		lwz	r4,TASKPPC_FLAGS(r3)
		ori	r4,r4,TASKPPC_CHOWN 
		xori	r4,r4,TASKPPC_CHOWN
		stw	r4,TASKPPC_FLAGS(r3) 
 
		mr	r3,r5				#Exit with task in r3 (or not) 
 
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
		
		DSTRYSTACKPPC

		blr
		 
#********************************************************************************************
#
#	Void SetDecInterrupt(Delay) // r4
#
#********************************************************************************************

SetDecInterrupt:
		BUILDSTACKPPC
		
		loadreg	r5,Quantum
		mr	r6,r4
		mulhw	r3,r5,r6
		mullw	r4,r5,r6
		loadreg	r5,0x3d0900
		bl	.GetDelay

		mr.	r3,r3
		bne-	.NotZ
		li	r3,10
.NotZ:		stwu	r31,-4(r13)
		mr	r31,r3

		bl WarpSuper
		
		mr	r3,r31
		mtdec	r3
		
		bl WarpUser

		lwz	r31,0(r13)
		addi	r13,r13,4
		
		DSTRYSTACKPPC

		blr	

.GetDelay:	li	r0,32
		mtctr	r0
		li	r6,0
		mr.	r3,r3
.NextCtr:	bge-	.IsPos
		addc	r4,r4,r4
		adde	r3,r3,r3
		add	r6,r6,r6
		b	.WasNeg

.IsPos:		addc	r4,r4,r4
		adde	r3,r3,r3
		add	r6,r6,r6
		cmplw	r5,r3
		bgt-	.NoSubAdd
.WasNeg:	sub.	r3,r3,r5
		addi	r6,r6,1
.NoSubAdd:	bdnz+	.NextCtr
		mr	r3,r6
		blr
		
#********************************************************************************************
#
#	Status = ChangeStack(NewStackSize) // r3=r4
#
#********************************************************************************************

ChangeStack:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)

		mr	r29,r4	

		lwz	r3,RunningTask(r0)		
		mr	r28,r3
		lwz	r5,TASKPPC_STACKSIZE(r3)
		cmplw	r4,r5
		blt-	.SomeError

		loadreg	r5,0x10001
		li	r6,0

		bl AllocVecPPC

		mr.	r3,r3
		beq-	.SomeError

		mr	r30,r3

		li	r4,24
		loadreg	r5,0x10001
		li	r6,0
		
		bl AllocVecPPC
		
		mr.	r3,r3
		beq-	.SomeError2

		stw	r3,TASKPPC_STACKMEM(r28)
		li	r0,1
		sth	r0,14(r3)
		stw	r30,16(r3)
		stw	r29,20(r3)
		mr	r5,r3
		addi	r4,r28,TC_MEMENTRY
		lwz	r3,LH_HEAD(r4)
		stw	r5,LH_HEAD(r4)
		stw	r3,LH_HEAD(r5)
		stw	r4,LH_TAIL(r5)
		stw	r5,LH_TAIL(r3)
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

		bl FreeVecPPC

.SomeError:	li	r3,0

.ExitChange:	lwz	r27,0(r13)
		lwz	r28,4(r13)
		lwz	r29,8(r13)
		lwz	r30,12(r13)
		lwz	r31,16(r13)
		addi	r13,r13,20
		
		DSTRYSTACKPPC
		
		blr	

#********************************************************************************************
#
#	TaskPPC = FindTaskPPC(Name) // r3=r4
#
#********************************************************************************************

FindTaskPPC:
		BUILDSTACKPPC

		mr.	r4,r4
		bne-	.NotOwnTask

		lwz	r3,RunningTask(r0)
		b	.ExitFind

.NotOwnTask:	stwu	r31,-4(r13)
		mr	r31,r3
		mr	r5,r4

		lwz	r4,TaskListSem(r0)

		bl ObtainSemaphorePPC

		li	r4,AllTasks
		
		bl FindNamePPC

		mr.	r3,r3
		beq-	.NameNotFound

		lwz	r3,14(r3)			#Pointer to PPCTask in AllTasks list
.NameNotFound:	mr	r31,r3

		lwz	r4,TaskListSem(r0)
		
		bl ReleaseSemaphorePPC

		mr	r3,r31

		lwz	r31,0(r13)
		addi	r13,r13,4

.ExitFind:	DSTRYSTACKPPC

		blr
#********************************************************************************************
#
#	ExceptionMode = IsExceptionMode(void) // r3
#
#********************************************************************************************

IsExceptionMode:
		lbz	r3,ExceptionMode(r0)
		blr
		
#********************************************************************************************
#
#	void ProcurePPC(SignalSemaphorePPC, SemaphoreMessage) // r4,r5
#
#********************************************************************************************

ProcurePPC:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)

		lwz	r3,RunningTask(r0)

		mr	r31,r3
		mr	r30,r4
		mr	r29,r5
		mr	r28,r31
		
		stw	r28,SSM_SEMAPHORE(r29)
		lwz	r4,LN_NAME(r29)
		stw	r4,LN_TYPE(r29)
		mr.	r4,r4
		beq-	.ExcLock
		li	r28,0

.ExcLock:	li	r4,Atomic

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

		li	r4,Atomic
		
		bl AtomicDone

		mr	r4,r29
		
		bl ReplyMsgPPC

		b	.ProcureExit

.Queue:		lwz	r4,SS_OWNER(r30)
		cmplw	r4,r28
		beq+	.IsExclusive

		addi	r4,r30,SS_WAITQUEUE
		mr	r5,r29
		addi	r4,r4,4
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)

		li	r4,Atomic

		bl AtomicDone

.ProcureExit:	lwz	r28,0(r13)
		lwz	r29,4(r13)
		lwz	r30,8(r13)
		lwz	r31,12(r13)
		addi	r13,r13,16

		DSTRYSTACKPPC

		blr

#********************************************************************************************
#
#	void VacatePPC(SignalSemaphorePPC, SemaphoreMessage) // r4,r5
#
#********************************************************************************************

VacatePPC:
		BUILDSTACKPPC

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

		mr	r31,r3
		mr	r30,r4
		mr	r29,r5
		
		li	r0,0
		stw	r0,SSM_SEMAPHORE(r29)
		stw	r0,LN_TYPE(r29)

.AtomicVacate:	li	r4,Atomic

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

		li	r4,Atomic
		
		bl AtomicDone

		mr	r4,r30
		
		bl ReleaseSemaphorePPC

		b	.VacateExit

.OwnSSM:	lha	r5,SS_QUEUECOUNT(r30)
		subi	r5,r5,1
		sth	r5,SS_QUEUECOUNT(r30)
		mr	r5,r4
		lwz	r3,0(r4)
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)

		li	r4,Atomic
		
		bl AtomicDone

		mr	r4,r5

		bl ReplyMsgPPC

.VacateExit:	lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12

		DSTRYSTACKPPC
		
		blr

#********************************************************************************************
#
#	SnoopID = SnoopTask(SnoopTags) // r3=r4
#
#********************************************************************************************

SnoopTask:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

		mr	r29,r3
		li	r31,0
		mr	r30,r4

		li	r4,26
		loadreg	r5,0x10001
		li	r6,0

		bl AllocVecPPC

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

		lwz	r4,SnoopSem(r0)
		
		bl ObtainSemaphorePPC

		lwz	r4,SnoopList(r0)
		mr	r5,r31

		bl AddHeadPPC

		lwz	r4,SnoopSem(r0)
		
		bl ReleaseSemaphorePPC

		mr	r30,r31
		b	.Snooping

.NoSnoop:	li	r30,0
		mr.	r31,r31
		beq-	.Snooping
		
		mr	r4,r31
		
		bl FreeVecPPC

.Snooping:	mr	r3,r30
		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12

		DSTRYSTACKPPC

		blr
		
#********************************************************************************************
#
#	void EndSnoopTask(SnoopID) // r4
#
#********************************************************************************************
		
EndSnoopTask:
		BUILDSTACKPPC

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)

		mr	r31,r4

		mr.	r31,r31
		beq-	.NoEndSnoop

		lwz	r4,SnoopSem(r0)
		
		bl ObtainSemaphorePPC

		mr	r4,r31
		
		bl RemovePPC

		lwz	r4,SnoopSem(r0)
		
		bl ReleaseSemaphorePPC

		mr	r4,r31
		
		bl FreeVecPPC

.NoEndSnoop:	lwz	r30,0(r13)
		lwz	r31,4(r13)
		addi	r13,r13,8
		
		DSTRYSTACKPPC

		blr
		
#********************************************************************************************
#
#	void ObtainSemaphoreSharedPPC(SignalSemaphorPPC) // r4
#
#********************************************************************************************

ObtainSemaphoreSharedPPC:
		
		BUILDSTACKPPC

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

		lwz	r31,RunningTask(r0)
		mr	r30,r4
		
.SharedAtomic:	li	r4,Atomic
		
		bl AtomicTest

		mr.	r3,r3
		beq+	.SharedAtomic

		lha	r5,SS_QUEUECOUNT(r30)
		addi	r5,r5,1
		sth	r5,SS_QUEUECOUNT(r30)
		extsh.	r0,r5
		bne-	.SharedQ

		li	r4,Atomic
		
		bl AtomicDone

		b	.ExitShared

.SharedQ:	mr	r3,r31
		lwz	r4,SS_OWNER(r30)
		mr.	r4,r4
		bne-	.HasOwner

		bl AtomicDone

		b	.ExitShared

.HasOwner:	cmplw	r3,r4
		bne-	.NotOwner

		li	r4,Atomic
		
		bl AtomicDone

		b	.ExitShared

.NotOwner:	stwu	r29,-4(r13)
		mr	r29,r13
		subi	r13,r13,12
		subi	r5,r29,12
#		addi	r3,r3,1				#??
		stw	r3,8(r5)
		lwz	r4,TC_SIGRECVD(r3)
		ori	r4,r4,16
		xori	r4,r4,16
		stw	r4,TC_SIGRECVD(r3)
		
		addi	r4,r30,SS_WAITQUEUE
		addi	r4,r4,4
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)

		li	r4,Atomic
		
		bl AtomicDone

		lis	r4,0
		ori	r4,r4,16
		
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
		lwz	r29,40(r13)
		lwz	r30,44(r13)
		lwz	r31,48(r13)
		addi	r13,r13,52
		lwz	r0,0(r13)
		addi	r13,r13,4
		mtctr	r0

		DSTRYSTACKPPC

		blr
		
#********************************************************************************************
#
#	status = AttemptSemaphoreSharedPPC(SignalSemaphorPPC) // r4
#
#********************************************************************************************

AttemptSemaphoreSharedPPC:

		BUILDSTACKPPC

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

		lwz	r31,RunningTask(r0)
		mr	r30,r4

.SharedAttempt:	li	r4,Atomic

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

.ItFailed:	li	r4,Atomic

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

		DSTRYSTACKPPC

		blr
		
#********************************************************************************************
#
#	void CauseInterrupt(void) // Interrupt using the Decrementer Exception (Support)
#
#********************************************************************************************
	
CauseInterrupt:

		BUILDSTACKPPC

		stwu	r31,-4(r13)

#		li	r0,-1
#		stb	r0,Interrupt(r0)

		li	r4,0
		
		bl SetDecInterrupt

#.IntWait:	lbz	r0,Interrupt(r0)
#		mr.	r0,r0
#		bne+	.IntWait
		isync

		lwz	r31,0(r13)
		addi	r13,r13,4

		DSTRYSTACKPPC

		blr
		
#********************************************************************************************
#
#	oldSignals = CheckExcSignal(Task, Signal) // r3=r3,r4 (Support)
#
#********************************************************************************************		
		
CheckExcSignal:		
		BUILDSTACKPPC

		mr	r7,r3
		mr	r8,r4

.DoAtomic:	li	r4,Atomic

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
		
		stw	r7,TaskException(r0)

		bl CauseInterrupt

.IntWait2:	lwz	r0,TaskException(r0)
		mr.	r0,r0
		bne+	.IntWait2

.NonePending:	li	r4,Atomic

		bl AtomicDone
	
		mr	r3,r8
		
		DSTRYSTACKPPC
		
		blr
		
#********************************************************************************************
#
#	oldSignals = SetExceptPPC(newSignals, signalMask, flag) // r3=r4,r5,r6
#
#********************************************************************************************

SetExceptPPC:	
		BUILDSTACKPPC

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)

		mr	r29,r6
		mr	r28,r2

		lwz	r6,RunningTask(r0)
		mr	r30,r4

.DoAtomic2:	li	r4,Atomic

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

.NoPassR2:	li	r4,Atomic

		bl AtomicDone

		mr	r3,r6
		li	r4,0
		bl	CheckExcSignal

		mr	r3,r31

		lwz	r28,0(r13)
		lwz	r29,4(r13)
		lwz	r30,8(r13)
		lwz	r31,12(r13)
		addi	r13,r13,16

		DSTRYSTACKPPC

		blr

#********************************************************************************************
#
#	void DeleteTaskPPC(PPCTask) // r4
#
#********************************************************************************************

DeleteTaskPPC:
		BUILDSTACKPPC

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)

		lwz	r5,RunningTask(r0)		#ThisTask
		li	r29,0
		cmpw	r4,r5				#To be deleted?
		beq-	.DelOwnTask			#Yes: then r29=-1
		mr.	r4,r4
		bne-	.DelOtherTask			#Other task then r29=0
.DelOwnTask:	li	r29,-1				#0 then r29=0 (owntask)
		mr	r4,r5
.DelOtherTask:	mr	r31,r4				#task to r31

		lwz	r4,SnoopSem(r0)
		
		bl ObtainSemaphorePPC

		la	r28,SnoopList(r0)
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

.EmptySnoopLst:	lwz	r4,SnoopSem(r0)
		
		bl ReleaseSemaphorePPC

		mr	r3,r31
		bl	0x13354				#?

		mr.	r3,r3
		beq-	.NotTwo

		mr	r27,r3
		lbz	r4,54(r27)
		cmplwi	r4,2
		bne-	.NotTwo

		lwz	r28,14(r27)
		lis	r0,0
		nop	
		stw	r0,0(r28)

		li	r4,CACHE_DCACHEFLUSH
		li	r5,0
		li	r6,0

		bl SetCache

		lwz	r4,22(r27)			#Task
		lwz	r5,26(r27)			#Signals

		bl Signal68K

		addi	r4,r2,18202			#?
		
		bl ObtainSemaphorePPC

		mr	r4,r27
		lwz	r3,0(r4)
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)

		addi	r4,r2,18202
		
		bl ReleaseSemaphorePPC

.NotTwo:	lwz	r4,TASKPPC_MSGPORT(r31)
		mr.	r27,r4
		beq-	.NoMsgPort

		addi	r4,r27,MP_PPC_SEM
		
		bl FreeSemaphorePPC

		mr	r4,r27
		
		bl FreeVecPPC

.NoMsgPort:	lwz	r4,TaskListSem(r0)
		
		bl ObtainSemaphorePPC

		lwz	r4,TASKPPC_TASKPTR(r31)
		lwz	r3,0(r4)
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)
		la	r4,NumAllTasks(r0)		#Tasks -1
		lwz	r3,0(r4)
		subi	r3,r3,1
		stw	r3,0(r4)
		dcbst	r0,r4

		lwz	r4,TaskListSem(r0)
		
		bl ReleaseSemaphorePPC
	
		lwz	r4,17740(r2)			#Task	(Voyager or Babylon 5?)
		lwz	r5,17736(r2)			#Signal
		
		bl SignalPPC

		mr.	r29,r29				#This task?
		beq-	.NotOwnTask2			#no? Skip next
		li	r0,TS_REMOVED
		stb	r0,TC_STATE(r31)
		li	r0,-1
		stb	r0,626(r0)			#Some Flag?
		
		bl CauseInterrupt
		
.EndTask:	b	.EndTask			#Halt this Task

.NotOwnTask2:	li	r4,Atomic

		bl AtomicTest

		mr.	r3,r3			
		beq+	.NotOwnTask2			#Wait Atomic

		mr	r4,r31
		lwz	r3,0(r4)			#task list
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)
		mr	r5,r31
		
		la	r4,130(r0)			#??
		addi	r4,r4,4
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)

		li	r0,TS_REMOVED
		stb	r0,TC_STATE(r31)

		li	r4,Atomic
		
		bl AtomicDone

		lwz	r26,0(r13)
		lwz	r27,4(r13)
		lwz	r28,8(r13)
		lwz	r29,12(r13)
		lwz	r30,16(r13)
		lwz	r31,20(r13)
		addi	r13,r13,24

		DSTRYSTACKPPC

		blr
		
#********************************************************************************************
#
#	Status = SetHardware(hardwareflags, parameter) // r3=r4,r5
#
#********************************************************************************************

SetHardware:
		BUILDSTACKPPC
		
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
		b	.HWEnd

.TraceOn:	bl WarpSuper

		mfmsr	r0
		ori	r0,r0,PSL_SE
		mtmsr	r0
		isync	
		sync
		
		bl WarpUser

		b	.HWEnd
		
.TraceOff:	bl WarpSuper

		mfmsr	r0
		ori	r0,r0,PSL_SE
		xori	r0,r0,PSL_SE
		mtmsr	r0
		isync	
		sync	
		
		bl WarpUser

		b	.HWEnd

.BranchOn:	bl WarpSuper

		mfmsr	r0
		ori	r0,r0,PSL_BE
		mtmsr	r0
		isync	
		sync	
		
		bl WarpUser

		b	.HWEnd

.BranchOff:	bl WarpSuper

		mfmsr	r0
		ori	r0,r0,PSL_BE
		xori	r0,r0,PSL_BE
		mtmsr	r0
		isync	
		sync	
		
		bl WarpUser

		b	.HWEnd

.FPExcOn:	bl WarpSuper

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
		
		bl WarpUser

		b	.HWEnd

.FPExcOff:	bl WarpSuper

		mfmsr	r0
		ori	r0,r0,PSL_FE0|PSL_FE1
		xori	r0,r0,PSL_FE0|PSL_FE1
		mtmsr	r0
		isync	
		sync	

		bl WarpUser

		b	.HWEnd
		
.SetIBreak:	bl WarpSuper
		
		mr	r4,r5
		loadreg	r0,0xfffffffc
		and	r4,r4,r0
		ori	r4,r4,3
		mtspr	IABR,r4

		bl WarpUser

		b	.HWEnd

.ClearIBreak:	bl WarpSuper

		li	r0,0
		mtspr	IABR,r0
		
		bl WarpUser

		b	.HWEnd

.SetDBreak:	bl WarpSuper
		
		mr	r4,r5
		loadreg	r0,0xfffffff8
		and	r4,r4,r0		
		ori	r4,r4,7
		mtspr	DABR,r4
		
		bl WarpUser
		
		b	.HWEnd

.ClearDBreak:	bl WarpSuper

		li	r0,0
		mtspr	DABR,r0
		
		bl WarpUser
		
.HWEnd:		li	r4,HW_AVAILABLE

		mr	r3,r4

		DSTRYSTACKPPC

		blr
		
#********************************************************************************************
#
#	Poolheader = CreatePoolPPC(attr, puddlesize, treshsize) // r3=r4,r5,r6 r4 is ignored
#
#********************************************************************************************		

CreatePoolPPC:
		BUILDSTACKPPC

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		
		li	r31,0
		
		cmpw	r5,r6
		blt	.TooSmall
		
		addi	r30,r5,31
		loadreg r29,0xffffffe0
		and	r30,r30,r29
		
		mr	r29,r4
		mr	r28,r6
		
		li	r4,POOL_SIZE			#struct Pool
		mr	r5,r29
		li	r6,32
		
		bl AllocVecPPC
		
		mr.	r31,r3
		beq-	.TooSmall
		
		la	r4,POOL_PUDDLELIST(r31)
		
		bl NewListPPC
		
		la	r4,POOL_BLOCKLIST(r31)
		
		bl NewListPPC
		
		stw	r29,POOL_REQUIREMENTS(r31)
		stw	r30,POOL_PUDDLESIZE(r31)
		stw	r28,POOL_TRESHSIZE(r31)
		
.TooSmall:	mr	r3,r31
		
		lwz	r28,0(r13)
		lwz	r29,4(r13)
		lwz	r30,8(r13)
		lwz	r31,12(r13)
		addi	r13,r13,16		
		
		DSTRYSTACKPPC

		blr
		
#********************************************************************************************
#
#	void DeletePoolPPC(poolheader) // r4
#
#********************************************************************************************

DeletePoolPPC:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)

		mr.	r31,r4
		beq-	.NoHeader
		
.NextPuddle:	la	r4,POOL_PUDDLELIST(r31)
		
		bl RemHeadPPC
		
		mr.	r4,r3
		beq	.NextBlock	
		
		bl FreeVecPPC
		
		b	.NextPuddle
	
.NextBlock:	la	r4,POOL_BLOCKLIST(r31)

		bl RemHeadPPC
		
		mr.	r4,r3
		beq	.AllFreed		
		
		bl FreeVecPPC
		
.AllFreed:	mr	r4,r31
		
		bl FreeVecPPC
		
.NoHeader:	lwz	r31,0(r13)
		addi	r13,r13,4
		
		DSTRYSTACKPPC
				
		blr
		
#********************************************************************************************
#
#	memory = AllocPooledPPC(poolheader, size) // r3=r4,r5
#
#********************************************************************************************

AllocPooledPPC:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		
		mr	r31,r4
		mr	r30,r5
		
		lwz	r4,MemSem(r0)
		
		bl ObtainSemaphorePPC
		
		
		lwz	r29,POOL_TRESHSIZE(r31)
		
		cmpw	r29,r30
		ble	.DoPuddle
		
		addi	r4,r30,8			#Make room for MLN
		lwz	r5,POOL_REQUIREMENTS(r31)
		li	r6,32
		
		bl AllocVecPPC
		
		mr.	r5,r3
		
		beq-	.NoPooledMem
				
		li	r0,0
		stw	r0,0(r5)
		stw	r0,4(r5)		
		mr	r29,r5		
		la	r4,POOL_BLOCKLIST(r31)
		
		
		bl AddHeadPPC
		
		
		la	r3,8(r29)			#Point beyond Minimal List Node
		
		
		b	.NoPooledMem
		
.DoPuddle:	addi	r4,r30,8			#STUB (same as block at the moment)
		lwz	r5,POOL_REQUIREMENTS(r31)
		li	r6,32
		
		bl AllocVecPPC
		
		mr.	r5,r3
		beq-	.NoPooledMem
		li	r0,0
		stw	r0,0(r5)
		stw	r0,4(r5)
		mr	r29,r5
		la	r4,POOL_PUDDLELIST(r31)
		
		bl AddHeadPPC
		
		la	r3,8(r29)
		
.NoPooledMem:	lwz	r4,MemSem(r0)
		
		bl ReleaseSemaphorePPC
		
		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12
		
		DSTRYSTACKPPC
		
		blr
		
#********************************************************************************************
#
#	void FreePooledPPC(poolheader, memory) // r4,r5
#
#********************************************************************************************

FreePooledPPC:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		
		mr	r31,r4
		mr	r30,r5
		
		lwz	r4,MemSem(r0)
		
		bl ObtainSemaphorePPC

		lwz	r29,POOL_TRESHSIZE(r31)
		
		cmpw	r29,r30
		ble	.DoFrPuddle
		
		subi	r4,r30,8
		
		bl RemovePPC

		b	.FrPooledMem
		
.DoFrPuddle:	subi	r4,r30,8			#STUB (same as block at the moment)

		bl RemovePPC				
		
.FrPooledMem:	lwz	r4,MemSem(r0)
		
		bl ReleaseSemaphorePPC
		
		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12
		
		DSTRYSTACKPPC
		
		blr
		
#********************************************************************************************
#
#	signals = WaitPPC(signalSet) // r3=r4
#
#********************************************************************************************

WaitPPC:
		BUILDSTACKPPC

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)

		lwz	r3,52(r3)
		lwz	r2,46(r3)

		lwz	r31,RunningTask(r0)

		mr	r28,r4
		
.WaitPPCAtom:	li	r4,Atomic

		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitPPCAtom

		stw	r28,TC_SIGWAIT(r31)
.RecheckSig:	lwz	r6,TC_SIGRECVD(r31)
		and	r5,r28,r6
		mr.	r5,r5
		bne-	.GotSignals

		li	r0,TS_CHANGING
		stb	r0,TC_STATE(r31)

		li	r4,Atomic
		
		bl AtomicDone
		
		bl CauseInterrupt

.WaitForRun:	lbz	r0,TC_STATE(r31)
		cmplwi	r0,TS_RUN
		bne+	.WaitForRun

.WaitPPCAtom2:	li	r4,Atomic

		bl AtomicTest

		mr.	r3,r3
		beq+	.WaitPPCAtom2
		
		lwz	r28,TC_SIGWAIT(r31)
		b	.RecheckSig

.GotSignals:	xor	r6,r5,r6
		stw	r6,TC_SIGRECVD(r31)

		li	r4,Atomic
		
		bl AtomicDone

		mr	r3,r5

		lwz	r28,0(r13)
		lwz	r29,4(r13)
		lwz	r30,8(r13)
		lwz	r31,12(r13)
		addi	r13,r13,16
		
		DSTRYSTACKPPC

		blr
		
#********************************************************************************************
#
#	oldpriority = SetTaskPriPPC(taskPPC, priority) // r3=r4,r5
#
#********************************************************************************************

SetTaskPriPPC:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)

		mr	r30,r4

.PriAtomic:	li	r4,Atomic

		bl AtomicTest

		mr.	r3,r3
		beq+	.PriAtomic

		lbz	r29,LN_PRI(r30)
		extsb	r29,r29
		stb	r5,LN_PRI(r30)
		lwz	r3,RunningTask(r0)
		
#		lwz	r3,88(r0)			#??

		cmpw	r3,r30
		beq-	.NoSelf

		lbz	r0,TC_STATE(r30)
		cmplwi	r0,TS_REMOVED
		beq-	.DonePriChange

		cmplwi	r0,TS_WAIT
		bne-	.DonePriChange

		lwz	r4,TASKPPC_TIMESTAMP2(r30)
		mftbl	r5
		sub	r4,r5,r4
		lwz	r6,TASKPPC_ELAPSED2(r30)
		add	r4,r4,r6
		stw	r4,TASKPPC_ELAPSED2(r30)

		mr	r4,r30				#RemovePPC
		lwz	r3,LN_SUCC(r4)
		lwz	r4,LN_PRED(r4)
		stw	r4,LN_PRED(r3)
		stw	r3,LN_SUCC(r4)
		mr	r5,r30
		li	r0,TS_READY
		stb	r0,TC_STATE(r30)

		la	r4,102(r0)			#sonnetbase +102 (some tasklist)
		bl	InsertOnPri

		lwz	r4,102(r0)			#??
		cmplw	r4,r30
		bne-	.DonePriChange

.NoSelf:	li	r4,Atomic
		
		bl AtomicDone

		bl CauseInterrupt

		b	.ExitPri

.DonePriChange:	li	r4,Atomic

		bl AtomicDone

.ExitPri:	mr	r3,r29
		lwz	r29,0(r13)
		lwz	r30,4(r13)
		lwz	r31,8(r13)
		addi	r13,r13,12

		DSTRYSTACKPPC

		blr
		
#********************************************************************************************
#
#	d0 = Run68KLowLevel(Code, Offset, a0, a1, d0, d1) // r3=r4,r5,r6,r7,r8,r9
#
#********************************************************************************************

Run68KLowLevel:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r26,-4(r13)
		stwu	r25,-4(r13)
		stwu	r24,-4(r13)
		stwu	r23,-4(r13)
		
		mr	r31,r4
		mr	r29,r5
		mr	r28,r6
		mr	r27,r7
		mr	r26,r8
		mr	r25,r9

		lis	r3,EUMB
		li	r24,OFTPR
		lwbrx	r30,r24,r3			
		addi	r23,r30,4		
		loadreg	r4,0xc000
		or	r23,r23,r4
		loadreg r4,0xffff
		and	r23,r23,r4				#Keep it C000-FFFE		
		stwbrx	r23,r24,r3
		lwz	r30,0(r30)

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
		loadreg	r5,"LL68"
		stw	r5,MN_IDENTIFIER(r30)
		li	r5,192
		sth	r5,MN_LENGTH(r30)		
		li	r5,NT_MESSAGE
		stb	r5,LN_TYPE(r30)		
		lwz	r4,MCTask(r0)
		la	r4,pr_MsgPort(r4)
		stw	r4,188(r30)				#MN_MCTASK
				
		sync
		
		bl	FlushL1DCache
		
		lis	r3,EUMB
		li	r24,OPHPR
		lwbrx	r31,r24,r3		
		stw	r30,0(r31)		
		addi	r23,r31,4
		loadreg	r4,0xbfff
		and	r23,r23,r4				#Keep it 8000-BFFE
		stwbrx	r23,r24,r3				#triggers Interrupt
		
		mr	r31,r30		

		bl 	WarpSuper

.Wait68KLow:
		la	r6,MN_IDENTIFIER(r31)
		dcbi	r0,r6
		
		loadreg r30,"DONE"
		lwz	r6,MN_IDENTIFIER(r31)
		cmpw	r6,r30
		bne 	.Wait68KLow

		isync

		la	r3,MN_PPSTRUCT+6*4(r31)
		dcbi	r0,r3
		
		bl	WarpUser
		
		lwz	r3,MN_PPSTRUCT+6*4(r31)			# return d0
		
		lwz	r23,0(r13)
		lwz	r24,4(r13)
		lwz	r25,8(r13)
		lwz	r26,12(r13)
		lwz	r27,16(r13)
		lwz	r28,20(r13)
		lwz	r29,24(r13)
		lwz	r30,28(r13)
		lwz	r31,32(r13)
		addi	r13,r13,36
		
		DSTRYSTACKPPC
		
		blr

#********************************************************************************************

SPrintF:			blr
SignalPPC:			blr
SetExcHandler:			li	r3,0
				blr
RemExcHandler:			blr
WaitTime:			li	r3,0
				blr
ChangeMMU:			blr
PutMsgPPC:			blr
GetMsgPPC:			li	r3,0
				blr
ReplyMsgPPC:			blr
FreeAllMem:			blr
GetHALInfo:			blr
SetScheduling:			blr
RawDoFmtPPC:			li	r3,0
				blr

#********************************************************************************************
EndFunctions:
