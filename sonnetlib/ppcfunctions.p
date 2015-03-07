.include ppcdefines.i
.include sonnet_libppc.i

.set MH_FIRST,16
.set MH_FREE,28
.set MC_BYTES,4
.set MC_NEXT,0
.set TC_SIGALLOC,18
.set TC_SIGWAIT,22
.set TC_SIGRECVD,26
.set TASKPPC_TASKPTR,104
.set SS_NESTCOUNT,14
.set SS_WAITQUEUE,16
.set SS_OWNER,40
.set SS_QUEUECOUNT,44
.set SSPPC_RESERVE,46
.set SSPPC_LOCK,50
.set MP_SIGTASK,16
.set MP_MSGLIST,20
.set pr_MsgPort,92

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
.global PutXMsgPPC,WaitFor68K,Run68K,Signal68K

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

		clearreg r4
		lis	r3,EUMBEPICPROC
		sync
		stw	r4,0xb0(r3)			#Write 0 to EOI to End Interrupt

		lwz	r4,-8(r1)
		lwz	r3,-12(r1)
		blr

#********************************************************************************************
#
#	void InsertPPC(list, node, nodepredecessor) // r4,r5,r6 Node must be in Sonnet mem to work
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
#	void AddHeadPPC(list, node) // r4,r5 List/Node must be in Sonnet mem to work
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
#	void AddTailPPC(list, node) // r4,r5 List/Node must be in Sonnet mem to work
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
#	void RemovePPC(node) // r4 Node must be in sonnet mem to work
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
#	void RemHeadPPC(list) // r4 List must be in Sonnet mem to work
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
#	void RemTailPPC(list) // r4 List must be in Sonnet mem to work (this msg won't be repeated from now on
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
#	void ResetPPC(void)	// Dummy (as in powerpc.library
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
		lis	r0,15
		ori	r0,r0,16960
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
		lis	r0,15
		ori	r0,r0,16960
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
#	MemBlock = AllocVecPPC(Length)	// r3=r4 (r5 and r6 are ignored) Should be 4 byte aligned
#
#********************************************************************************************

AllocVecPPC:
		BUILDSTACKPPC			#Should be 32 aligned instead of 4?

		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r23,-4(r13)
		stwu	r22,-4(r13)
		stwu	r21,-4(r13)
		stwu	r20,-4(r13)
		stwu	r7,-4(r13)
		stwu	r6,-4(r13)

		andi.	r3,r0,0
		addi	r29,r0,4
		addco.	r4,r4,r29
.Align:		andi.	r29,r4,3
		beq+	.Aligned
		addi	r4,r4,1
		b	.Align
		
.Aligned:	li 	r20,SonnetBase
		lwz	r20,PPCMemHeader(r20)
		lwz	r5,MH_FREE(r20)
		subfco	r31,r5,r4
		cmpw	r5,r4
		bge+	.Link6
		b	.error
.Link6:
		lwz	r21,MH_FIRST(r20)
		addi	r23,r20,MH_FIRST
.MemLoop:	lwz	r5,MC_BYTES(r21)
		subfco	r31,r5,r4
		cmpw	r5,r4
		blt	.Link7
		b	.FoundMem
.Link7:
		lwz	r30,MC_NEXT(r21)
		cmpwi	r30,0
		bne+	.Link8
		b	.error
.Link8:
		mr	r23,r21
		lwz	r21,MC_NEXT(r21)
		b	.MemLoop
		
.FoundMem:	mr	r22,r21
		addco.	r22,r22,r4
		mr	r3,r21
		addi	r29,r0,4
		addco.	r3,r3,r29
		lwz	r5,MC_BYTES(r21)
		subfco	r31,r5,r4
		cmpw	r5,r4
		beq-	.Yep
		b	.MaybePerfect
		
.Yep:		lwz	r22,MC_NEXT(r21)
		b	.JmpPerfect

.MaybePerfect:	addi	r29,r0,4
		addco.	r4,r4,r29
		subfco	r31,r5,r4
		cmpw	r5,r4
		bne	.Link9
		b	.Yep
.Link9:
		addi	r29,r0,4
		addco.	r4,r4,r29
		subfco	r31,r5,r4
		cmpw	r5,r4
		bne	.Link10
		b	.Yep
.Link10:
		addi	r29,r0,8
		subfco	r28,r4,r29
		subf.	r4,r29,r4
		lwz	r29,MC_NEXT(r21)
		stw	r29,0(r22)
		lwz	r29,MC_BYTES(r21)
		stw	r29,4(r22)
		lwz	r30,MC_BYTES(r22)
		subfco	r28,r30,r4
		subf.	r30,r4,r30
		stw	r30,MC_BYTES(r22)
.JmpPerfect:	lwz	r30,MH_FREE(r20)
		subfco	r28,r30,r4
		subf.	r30,r4,r30
		stw	r30,MH_FREE(r20)
		stw	r22,MC_NEXT(r23)
		stw	r4,MC_NEXT(r21)
		addi	r29,r0,5
		subfco	r28,r4,r29
		subf.	r4,r29,r4
		addi	r29,r0,4
		addco.	r21,r21,r29
.ClrMem:	andi.	r30,r30,0
		stb	r30,0(r21)
		addi	r21,r21,1
		extsh	r29,r4
		cmpi	2,0,r29,0
		beq-	cr2,.Link11
		subi	r29,r29,1
		rlwimi	r4,r29,0,16,31
		b	.ClrMem
.Link11:
		subi	r29,r29,1
		rlwimi	r4,r29,0,16,31

.error:		lwz	r6,0(r13)
		lwzu	r7,4(r13)
		lwzu	r20,4(r13)
		lwzu	r21,4(r13)
		lwzu	r22,4(r13)
		lwzu	r23,4(r13)
		lwzu	r28,4(r13)
		lwzu	r29,4(r13)
		lwzu	r30,4(r13)
		lwzu	r31,4(r13)
		addi	r13,r13,4
		
		DSTRYSTACKPPC
		
		blr
		
#********************************************************************************************
#
#	Result = FreeVecPPC(MemBlock)	// r3=r4 r3 should be MEMERR_SUCCESS on success
#
#********************************************************************************************		
		
FreeVecPPC:	
		BUILDSTACKPPC
				
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r23,-4(r13)
		stwu	r22,-4(r13)
		stwu	r21,-4(r13)
		stwu	r20,-4(r13)
		stwu	r7,-4(r13)
		stwu	r6,-4(r13)
		
		addi	r3,r0,1
		li	r20,SonnetBase
		lwz	r20,PPCMemHeader(r20)
		addi	r23,r20,MH_FIRST
		lwz	r5,0(r23)
		cmpwi	r5,0
		bne+	.Link12
		b	.error2
.Link12:
		mr	r21,r5
.MHLoop:	subfco	r31,r5,r4
		cmpw	r5,r4
		ble	.Link13
		b	.FoundMH
.Link13:
		lwz	r5,MC_NEXT(r21)
		cmpwi	r5,0
		bne+	.Link14
		b	.error2
.Link14:
		addi	r23,r21,MC_NEXT
		b	.MHLoop

.FoundMH:	mr	r21,r4
		lwz	r6,-4(r21)
		cmpwi	r6,0
		bne+	.Link15
		b	.error2
.Link15:
		mr	r7,r6
		addi	r29,r0,4
		subfco	r28,r4,r29
		subf.	r4,r29,r4
		addco.	r6,r6,r4
		subfco	r31,r6,r5
		cmpw	r6,r5
		bne	.Link16
		b	.OnlyChunk
.Link16:
		stw	r5,-4(r21)
		stw	r7,0(r21)
		b	.MoreChunks

.OnlyChunk:	mr	r22,r5
		lwz	r29,MC_NEXT(r22)
		stw	r29,-4(r21)
		lwz	r29,MC_BYTES(r22)
		stw	r29,0(r21)
		lwz	r30,0(r21)
		addco.	r30,r30,r7
		stw	r30,0(r21)

.MoreChunks:	stw	r4,0(r23)
		lwz	r30,MH_FREE(r20)
		addco.	r30,r30,r7
		stw	r30,MH_FREE(r20)
		addi	r29,r0,1
		subfco	r28,r3,r29
		subf.	r3,r29,r3

.error2:	lwz	r6,0(r13)
		lwzu	r7,4(r13)
		lwzu	r20,4(r13)
		lwzu	r21,4(r13)
		lwzu	r22,4(r13)
		lwzu	r23,4(r13)
		lwzu	r28,4(r13)
		lwzu	r29,4(r13)
		lwzu	r30,4(r13)
		lwzu	r31,4(r13)
		addi	r13,r13,4
		
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
		
		LIBCALLPOWERPC WarpSuper
		
		li	r5,SonnetBase
		mfspr	r3,PVR
		stw	r3,CPUInfo(r5)
		mfspr	r3,HID1
		stw	r3,CPUHID1(r5)
		mfspr	r3,HID0
		stw	r3,CPUHID0(r5)
		mfspr	r3,SDR1
		stw	r3,CPUSDR1(r5)
		
		LIBCALLPOWERPC WarpUser		
		
.TagLoop:	mflr	r5
		
		LIBCALLPOWERPC NextTagItemPPC

		mtlr	r5
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
		

.INFO_CPU:	li	r7,SonnetBase
		lwz	r7,CPUInfo(r7)
		rlwinm	r7,r7,16,28,31
		andi.	r7,r7,4
		beq+	.G3
		loadreg r7,CPUF_G4
		b	.GotCPU		
.G3:		loadreg	r7,CPUF_G3
		b	.GotCPU
		
.INFO_PVR:	li	r7,SonnetBase
		lwz	r7,CPUInfo(r7)
.GotCPU:	stw	r7,4(r4)
		b	.NextInList
		
.INFO_ICACHE:	li	r8,SonnetBase
		lwz	r8,CPUHID0(r8)
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

.INFO_DCACHE:	li	r8,SonnetBase
		lwz	r8,CPUHID0(r8)
		rlwinm	r8,r8,20,29,31
		b	.ReUse
		
.INFO_PAGETABLE:	
		li	r7,SonnetBase
		lwz	r7,CPUSDR1(r7)
		rlwinm	r7,r7,0,0,15
		b 	.StoreTag
		
.INFO_TABLESIZE:
		li	r8,SonnetBase
		lwz	r8,CPUSDR1(r8)
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
		
.INFO_CPUCLOCK:	li	r7,SonnetBase
		lwz	r7,CPUHID1(r7)
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
		
		LIBCALLPOWERPC FindTagItemPPC

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

		LIBCALLPOWERPC NextTagItemPPC

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
#	Support: void Flush_L1_DCache(void)
#
#********************************************************************************************

FlushL1DCache:			
		li	r4,0x7000

		li	r6,0x400
		mr	r5,r6
		mtctr	r6
	
.Fl1:		lwz	r6,0(r4)
		addi	r4,r4,L1_CACHE_LINE_SIZE
		bdnz	.Fl1
	
		li	r4,0x7000
		mtctr	r5
		
.Fl2:		dcbf	r0,r4
		addi	r4,r4,L1_CACHE_LINE_SIZE
		bdnz	.Fl2		

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
		
		LIBCALLPOWERPC AllocVecPPC
		
		mr.	r3,r3
		beq-	.NoMaam
		stw	r30,14(r3)
		sth	r31,18(r3)
		
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
		
		LIBCALLPOWERPC FreeVecPPC
		
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
		
		LIBCALLPOWERPC AllocVecPPC
	
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
		
		LIBCALLPOWERPC AllocSignalPPC
	
		cmpwi	r3,-1
		beq-	.NoSigFree
		stb	r3,15(r30)
		addi	r4,r30,48
		
		LIBCALLPOWERPC InitSemaphorePPC

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

		LIBCALLPOWERPC FreeSignalPPC

.NoSigFree:	mr	r4,r30

		LIBCALLPOWERPC FreeVecPPC
	
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

		LIBCALLPOWERPC FreeSemaphorePPC

		lbz	r4,15(r31)
		
		LIBCALLPOWERPC FreeSignalPPC

		mr	r4,r31
		
		LIBCALLPOWERPC FreeVecPPC

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

		li	r5,SonnetBase
		lwz	r5,RunningTask(r5)		

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

		li	r5,SonnetBase
		lwz	r5,RunningTask(r5)

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
		stw	r3,TC_SIGALLOC(r5)		#Task structure not in place yet
		stwu	r4,-4(r13)
		
.WaitingLine:	LIBCALLPOWERPC AtomicTest		#Reentrant

		mr.	r3,r3
		beq+	.WaitingLine

		lwz	r7,TC_SIGRECVD(r5)
		andc	r7,r7,r6
		stw	r7,TC_SIGRECVD(r5)
		lwz	r7,TC_SIGWAIT(r5)
		andc	r7,r7,r6
		stw	r7,TC_SIGWAIT(r5)

		LIBCALLPOWERPC AtomicDone
		
		lwz	r4,0(r13)
		addi	r13,r13,4

.EndSig:	mr	r4,r3
		mr	r3,r4
		
		DSTRYSTACKPPC
		
		blr	
		
#********************************************************************************************
#
#	Support: result =  AtomicTest(void) // r3 - r4 is trashed
#
#********************************************************************************************

AtomicTest:
		li	r4,SonnetBase
		la	r4,Atomic(r4)
		
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
#	Support: void AtomicDone(void) // r4 is trashed
#
#********************************************************************************************

AtomicDone:		
		sync
		li	r4,SonnetBase
		li	r0,0
		stw	r0,Atomic(r4)
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

		li	r6,SonnetBase
		lwz	r6,RunningTask(r6)

		mr	r30,r4
		
.WaitingLine2:	LIBCALLPOWERPC AtomicTest
		
		mr.	r3,r3
		beq+	.WaitingLine2

		lwz	r31,TC_SIGRECVD(r6)
		and	r30,r30,r5
		andc	r7,r31,r5
		or	r30,r30,r7
		stw	r30,TC_SIGRECVD(r6)
		
		LIBCALLPOWERPC AtomicDone

		mr	r4,r31				#Reschedule?
		mr	r3,r4
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

		li	r31,SonnetBase
		lwz	r31,RunningTask(r31)

		li	r4,SonnetBase
		lwz	r4,TaskListSem(r4)

		LIBCALLPOWERPC ObtainSemaphorePPC

		lwz	r3,TASKPPC_TASKPTR(r31)
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
		
		li	r4,SonnetBase
		lwz	r4,TaskListSem(r4)

		LIBCALLPOWERPC ReleaseSemaphorePPC

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

		LIBCALLPOWERPC AllocVecPPC

		mr.	r3,r3
		beq-	.SemDone
		stw	r3,SSPPC_RESERVE(r31)
		li	r3,-1
		b	.SemDone

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

		LIBCALLPOWERPC FreeVecPPC

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

		li	r31,SonnetBase
		mr	r30,r4

.WaitRes:	LIBCALLPOWERPC AtomicTest

		mr.	r3,r3
		beq+	.WaitRes
		lha	r5,SS_QUEUECOUNT(r30)
		addi	r5,r5,1
		sth	r5,SS_QUEUECOUNT(r30)
		extsh.	r0,r5
		bne-	.link21

		lwz	r3,RunningTask(r31)
		stw	r3,SS_OWNER(r30)
		
		LIBCALLPOWERPC AtomicDone

		b	.Obtained

.link21:	lwz	r3,RunningTask(r31)
		lwz	r4,SS_OWNER(r30)
		cmplw	r3,r4
		bne-	.SemNotFree


		LIBCALLPOWERPC AtomicDone

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

		LIBCALLPOWERPC AtomicDone

		lis	r4,0
		ori	r4,r4,16
		
		LIBCALLPOWERPC WaitPPC

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

		li	r31,SonnetBase
		mr	r30,r4

.WaitRes2:	LIBCALLPOWERPC AtomicTest

		mr.	r3,r3
		beq+	.WaitRes2
		
		lha	r5,SS_QUEUECOUNT(r30)
		addi	r5,r5,1
		lwz	r3,RunningTask(r31)
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

.Occupied:	LIBCALLPOWERPC AtomicDone

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

.WaitRes3:	LIBCALLPOWERPC AtomicTest

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

		LIBCALLPOWERPC AtomicDone

		b	.Released

.LastInLine:	lis	r0,0
		nop	
		stw	r0,SS_OWNER(r31)
		lha	r5,SS_QUEUECOUNT(r31)
		subi	r5,r5,1
		sth	r5,SS_QUEUECOUNT(r31)
		mr.	r5,r5
		bge-	.NotLast

		LIBCALLPOWERPC AtomicDone

		b	.Released

.NotLast:	li	r0,1
		sth	r0,SSPPC_LOCK(r31)
		
		LIBCALLPOWERPC AtomicDone

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

		LIBCALLPOWERPC SignalPPC

		b	.link23
		
.link25:	lwz	r5,20(r30)
		stw	r5,SS_OWNER(r31)
		lwz	r29,SS_WAITQUEUE(r31)
.link29:	stw	r31,20(r30)
		lha	r5,SS_NESTCOUNT(r31)
		addi	r5,r5,1
		sth	r5,SS_NESTCOUNT(r31)
		mr	r4,r30

		LIBCALLPOWERPC ReplyMsgPPC

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

		LIBCALLPOWERPC SignalPPC

		b	.link31
		
.link30:	stw	r31,20(r30)
		stw	r4,8(r30)
		mr	r4,r30

		LIBCALLPOWERPC ReplyMsgPPC

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

.Error68k:	LIBCALLPOWERPC AtomicDone
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
		
		LIBCALLPOWERPC InitSemaphorePPC

		mr.	r3,r3
		beq-	.NoInitSem

		li	r4,SonnetBase
		lwz	r4,SemListSem(r4)
		
		LIBCALLPOWERPC ObtainSemaphorePPC
		
		li	r4,SonnetBase
		lwz	r4,Semaphores(r4)
		mr	r5,r30
		
		LIBCALLPOWERPC EnqueuePPC
		
		li	r4,SonnetBase
		lwz	r4,SemListSem(r4)
		
		LIBCALLPOWERPC ReleaseSemaphorePPC

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

		LIBCALLPOWERPC FreeSemaphorePPC

		li	r4,SonnetBase
		lwz	r4,SemListSem(r4)
		
		LIBCALLPOWERPC ObtainSemaphorePPC

		mr	r4,r31

		LIBCALLPOWERPC RemovePPC

		li	r4,SonnetBase
		lwz	r4,SemListSem(r4)

		LIBCALLPOWERPC ReleaseSemaphorePPC

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

		li	r4,SonnetBase
		lwz	r4,SemListSem(r4)

		LIBCALLPOWERPC ObtainSemaphorePPC

		li	r4,SonnetBase
		lwz	r4,Semaphores(r4)
		mr	r5,r30

		LIBCALLPOWERPC FindNamePPC

		mr	r30,r3

		li	r4,SonnetBase
		lwz	r4,SemListSem(r4)
		
		LIBCALLPOWERPC ReleaseSemaphorePPC

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

		li	r4,SonnetBase
		lwz	r4,PortListSem(r4)

		LIBCALLPOWERPC ObtainSemaphorePPC

		li	r4,SonnetBase
		lwz	r4,Ports(r4)
		mr	r5,r30

		LIBCALLPOWERPC EnqueuePPC

		li	r4,SonnetBase
		lwz	r4,PortListSem(r4)
		
		LIBCALLPOWERPC ReleaseSemaphorePPC

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

		li	r4,SonnetBase
		lwz	r4,PortListSem(r4)

		LIBCALLPOWERPC ObtainSemaphorePPC

		mr	r4,r31
		lwz	r3,0(r4)
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)
		
		li	r4,SonnetBase
		lwz	r4,PortListSem(r4)
		
		LIBCALLPOWERPC ReleaseSemaphorePPC

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

		li	r4,SonnetBase
		lwz	r4,PortListSem(r4)

		LIBCALLPOWERPC ObtainSemaphorePPC

		li	r4,SonnetBase
		lwz	r4,Ports(r4)		

		LIBCALLPOWERPC FindNamePPC

		mr	r31,r3
		li	r4,SonnetBase
		lwz	r4,PortListSem(r4)

		LIBCALLPOWERPC ReleaseSemaphorePPC

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
		mr	r28,r3				#UNKNOWN AS OF YET (switch?)
		mr	r31,r4

		addi	r4,r31,48

		LIBCALLPOWERPC ObtainSemaphorePPC

		addi	r5,r31,34
		lwz	r4,42(r31)
		cmplw	r4,r5
		beq-	.Link33

.WaitInLine:	LIBCALLPOWERPC AtomicTest

		mr.	r3,r3
		beq+	.WaitInLine
		
		lbz	r3,628(r28)
		mr.	r3,r3
		beq-	.Link34

		LIBCALLPOWERPC AtomicDone

.Link35:	lbz	r3,628(r28)
		mr.	r3,r3
		bne+	.Link35
		b	.WaitInLine
		
.Link34:	stw	r31,610(r28)
		li	r0,-1
		stb	r0,628(r28)

		LIBCALLPOWERPC AtomicDone

		li	r4,0				#UNKNOWN AS OF YET
		lwz	r3,17652(r2)
		lwz	r0,-166(r3)
		mtlr	r0
		blrl	

.Link36:	lbz	r3,628(r28)
		mr.	r3,r3
		bne+	.Link36

.Link33:	lwz	r3,20(r31)
		lwz	r4,0(r3)
		mr.	r4,r4
		bne-	.Link37

		lbz	r5,15(r31)
		addi	r30,r31,20
		li	r4,1
		slw	r29,r4,r5
.Link42:	addi	r4,r31,48

		LIBCALLPOWERPC ReleaseSemaphorePPC

		mr	r4,r29

		LIBCALLPOWERPC WaitPPC

		mr	r27,r3
		addi	r4,r31,48

		LIBCALLPOWERPC ObtainSemaphorePPC

		addi	r5,r31,34
		lwz	r4,42(r31)
		cmplw	r4,r5
		beq-	.Link38

.WaitInLine2:	LIBCALLPOWERPC AtomicTest

		mr.	r3,r3
		beq+	.WaitInLine2
		
		lbz	r3,628(r28)
		mr.	r3,r3
		beq-	.Link39

		LIBCALLPOWERPC AtomicDone

.Link40:	lbz	r3,628(r28)
		mr.	r3,r3
		bne+	.Link40
		b	.WaitInLine2

.Link39:	stw	r31,610(r28)
		li	r0,-1
		stb	r0,628(r28)

		LIBCALLPOWERPC AtomicDone

		li	r4,0				#UNKNOWN AS OF YET
		lwz	r3,17652(r2)
		lwz	r0,-166(r3)
		mtlr	r0
		blrl	

.Link41:	lbz	r3,628(r28)
		mr.	r3,r3
		bne+	.Link41
		
.Link38:	mr	r3,r27
		lwz	r5,20(r31)
		lwz	r4,0(r5)
		mr.	r4,r4
		beq+	.Link42
		mr	r3,r5
.Link37:	mr	r5,r3
		addi	r4,r31,48

		LIBCALLPOWERPC ReleaseSemaphorePPC

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
		
		LIBCALLPOWERPC WarpSuper
		
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

		LIBCALLPOWERPC WarpUser

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
#	void User(SuperKey) // r4
#
#********************************************************************************************

WarpUser:
		mfmsr	r0			
		ori	r0,r0,0x4000		#SET Bit 17 (PR) To User
		mtmsr	r0
		isync	
		blr

#********************************************************************************************
#
#	void PutXMsgPPC(MsgPort, message) // r4,r5 (UNDER DEVELOPMENT)
#
#********************************************************************************************

PutXMsgPPC:
		BUILDSTACKPPC
		
		stwu	r31,-4(r13)
		mr	r31,r4
		la	r4,MP_MSGLIST(r4)

		LIBCALLPOWERPC AddTailPPC
		
		mr 	r4,r31
		
		lwz	r4,MP_SIGTASK(r4)	#Port flags to be implemented (PA_SIGNAL etc)
		mr.	r4,r4
		beq-	.NoSigTask
		li	r5,0x100
		
		LIBCALLPOWERPC Signal68K

.NoSigTask:	lwz	r31,0(r13)
		addi	r13,r13,4
		
		DSTRYSTACKPPC
		
		blr

#********************************************************************************************
#
#	status = WaitFor68K(PStruct) // r3=r4 (HACKED FUNCTION - UNDER DEVELOPMENT)
#
#********************************************************************************************

WaitFor68K:	
		BUILDSTACKPPC

		li	r3,SonnetBase		#Just for PoC
		loadreg r5,"DONE"
.FakeWait:	lwz	r6,Init(r3)
		cmpw	r6,r5
		bne+ 	.FakeWait

		stw	r3,Init(r3)

		DSTRYSTACKPPC
				
		blr
		
#********************************************************************************************
#
#	status = Run68K(PPStruct) // r3=r4 (UNDER DEVELOPMENT)
#
#********************************************************************************************

Run68K:		
		BUILDSTACKPPC
		
		mr	r5,r4
		li	r6,SonnetBase
		lwz	r6,MCTask(r6)
		lwz	r4,pr_MsgPort(r6)
		
		LIBCALLPOWERPC PutXMsgPPC
		
		LIBCALLPOWERPC WaitFor68K

		DSTRYSTACKPPC
		
		blr
		
#********************************************************************************************
#
#	void Signal68K(task, signals) // r4,r5
#
#********************************************************************************************

Signal68K:	
		BUILDSTACKPPC
		
		lis	r3,EUMB
		stw	r4,0x58(r3)
		stw	r5,0x5c(r3)		#Need to disable OMR1 interrupts?

		DSTRYSTACKPPC
		
		blr	
	
#********************************************************************************************
EndFunctions:
