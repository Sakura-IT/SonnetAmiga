.include ppcdefines.i
.include sonnet_libppc.i
.set MH_FIRST,16
.set MH_FREE,28
.set MC_BYTES,4
.set MC_NEXT,0
.set FunctionsLen,(EndFunctions-SetExcMMU)

.global FunctionsLen

.global SetExcMMU,ClearExcMMU,ConfirmInterrupt,InsertPPC,AddHeadPPC,AddTailPPC
.global RemovePPC,RemHeadPPC,RemTailPPC,EnqueuePPC,FindNamePPC,ResetPPC,NewListPPC
.global	AddTimePPC,SubTimePPC,CmpTimePPC,AllocVecPPC,FreeVecPPC,GetInfo,GetSysTimePPC
.global NextTagItemPPC,GetTagDataPPC,FindTagItemPPC

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
		stwu	r31,-4(r1)
		stwu	r30,-4(r1)
		stwu	r29,-4(r1)
		stwu	r28,-4(r1)
		stwu	r23,-4(r1)
		stwu	r22,-4(r1)
		stwu	r21,-4(r1)
		stwu	r20,-4(r1)
		stwu	r7,-4(r1)
		stwu	r6,-4(r1)

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
		cmp	0,0,r5,r4
		bge+	.Link6
		b	.error
.Link6:
		lwz	r21,MH_FIRST(r20)
		addi	r23,r20,MH_FIRST
.MemLoop:	lwz	r5,MC_BYTES(r21)
		subfco	r31,r5,r4
		cmp	0,0,r5,r4
		blt	.Link7
		b	.FoundMem
.Link7:
		lwz	r30,MC_NEXT(r21)
		cmpi	0,0,r30,0
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
		cmp	0,0,r5,r4
		beq-	.Yep
		b	.MaybePerfect
		
.Yep:		lwz	r22,MC_NEXT(r21)
		b	.JmpPerfect

.MaybePerfect:	addi	r29,r0,4
		addco.	r4,r4,r29
		subfco	r31,r5,r4
		cmp	0,0,r5,r4
		bne	.Link9
		b	.Yep
.Link9:
		addi	r29,r0,4
		addco.	r4,r4,r29
		subfco	r31,r5,r4
		cmp	0,0,r5,r4
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

.error:		lwz	r6,0(r1)
		lwzu	r7,4(r1)
		lwzu	r20,4(r1)
		lwzu	r21,4(r1)
		lwzu	r22,4(r1)
		lwzu	r23,4(r1)
		lwzu	r28,4(r1)
		lwzu	r29,4(r1)
		lwzu	r30,4(r1)
		lwzu	r31,4(r1)
		addi	r1,r1,4
		sync
		blr
		
#********************************************************************************************
#
#	Result = FreeVecPPC(MemBlock)	// r3=r4 r3 should be MEMERR_SUCCESS on success
#
#********************************************************************************************		
		
FreeVecPPC:		
		stwu	r31,-4(r1)
		stwu	r30,-4(r1)
		stwu	r29,-4(r1)
		stwu	r28,-4(r1)
		stwu	r23,-4(r1)
		stwu	r22,-4(r1)
		stwu	r21,-4(r1)
		stwu	r20,-4(r1)
		stwu	r7,-4(r1)
		stwu	r6,-4(r1)
		
		addi	r3,r0,1
		li	r20,SonnetBase
		lwz	r20,PPCMemHeader(r20)
		addi	r23,r20,MH_FIRST
		lwz	r5,0(r23)
		cmpi	0,0,r5,0
		bne+	.Link12
		b	.error2
.Link12:
		mr	r21,r5
.MHLoop:	subfco	r31,r5,r4
		cmp	0,0,r5,r4
		ble	.Link13
		b	.FoundMH
.Link13:
		lwz	r5,MC_NEXT(r21)
		cmpi	0,0,r5,0
		bne+	.Link14
		b	.error2
.Link14:
		addi	r23,r21,MC_NEXT
		b	.MHLoop

.FoundMH:	mr	r21,r4
		lwz	r6,-4(r21)
		cmpi	0,0,r6,0
		bne+	.Link15
		b	.error2
.Link15:
		mr	r7,r6
		addi	r29,r0,4
		subfco	r28,r4,r29
		subf.	r4,r29,r4
		addco.	r6,r6,r4
		subfco	r31,r6,r5
		cmp	0,0,r6,r5
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
		stw	r30,0(r7)

.MoreChunks:	stw	r4,0(r23)
		lwz	r30,MH_FREE(r20)
		addco.	r30,r30,r7
		stw	r30,MH_FREE(r20)
		addi	r29,r0,1
		subfco	r28,r3,r29
		subf.	r3,r29,r3

.error2:	lwz	r6,0(r1)
		lwzu	r7,4(r1)
		lwzu	r20,4(r1)
		lwzu	r21,4(r1)
		lwzu	r22,4(r1)
		lwzu	r23,4(r1)
		lwzu	r28,4(r1)
		lwzu	r29,4(r1)
		lwzu	r30,4(r1)
		lwzu	r31,4(r1)
		addi	r1,r1,4
		sync
		blr	

#********************************************************************************************
#
#	void  GetInfo(PPCInfoTagList)	// r4
#
#********************************************************************************************		

GetInfo:
		stwu	r8,-4(r1)
		stwu	r7,-4(r1)
		stwu	r6,-4(r1)
		stwu	r5,-4(r1)
		stwu	r4,-4(r1)
		li	r6,1
		
.TagLoop:	mflr	r5
		li	r3,SonnetBase
		lwz	r3,PowerPCBase(r3)
		lwz	r0,_LVONextTagItemPPC+2(r3)
		mtlr	r0
		blrl
		mtlr	r5
		mr.	r3,r3
		beq	.NoTags		
		rlwinm	r7,r3,0,0,19
		loadreg	r8,0x80102000
		cmpw	r7,r8		
		beq+	.UserTag
.NextInList:	addi	r4,r4,8
		b	.TagLoop
		
.NoTags:	lwz	r4,0(r1)
		lwzu	r5,4(r1)
		lwzu	r6,4(r1)
		lwzu	r7,4(r1)
		lwzu	r8,4(r1)
		sync
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
		li	r7,0
		cmpwi	r8,4
		beq	.StoreTag
		addi	r7,r7,1
		cmpwi	r8,5
		beq	.StoreTag
		addi	r7,r7,1
		cmpwi	r8,0
		beq	.StoreTag
		addi	r7,r7,1
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
		stw	r2,20(r1)
		mflr	r0
		stw	r0,8(r1)
		mfcr	r0
		stw	r0,4(r1)
		stw	r13,-4(r1)
		subi	r13,r1,4
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
		lwz	r13,-4(r1)
		lwz	r0,8(r1)
		mtlr	r0
		lwz	r0,4(r1)
		mtcr	r0
		lwz	r2,20(r1)
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
		stwu	r8,-4(r1)
		stwu	r7,-4(r1)
		stwu	r6,-4(r1)
		stwu	r5,-4(r1)		
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
		lwz	r5,0(r1)
		lwzu	r6,4(r1)
		lwzu	r7,4(r1)
		lwzu	r8,4(r1)
		addi	r1,r1,4
		sync
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
		stwu	r8,-4(r1)
		stwu	r7,-4(r1)
		stwu	r6,-4(r1)
		stwu	r5,-4(r1)
		stwu	r4,-4(r1)
		mr	r8,r5
		mr	r5,r6
		li	r6,1
		
		mflr	r7
		li	r3,SonnetBase
		lwz	r3,PowerPCBase(r3)
		lwz	r0,_LVOFindTagItemPPC+2(r3)
		mtlr	r0
		blrl
		mtlr	r7
		mr.	r3,r3
		bne	.Done
		mr	r3,r8
		b	.Done2
		
.Done:		lwz	r3,4(r3)		
.Done2:		lwz	r4,0(r1)
		lwzu	r5,4(r1)
		lwzu	r6,4(r1)
		lwzu	r7,4(r1)
		lwzu	r8,4(r1)
		addi	r1,r1,4
		sync
		blr

#********************************************************************************************
#
#	value = FindTagItemPPC(tagValue, taglist) // r3=r4,r5
#
#********************************************************************************************		

FindTagItemPPC:	
		stwu	r8,-4(r1)
		stwu	r7,-4(r1)
		stwu	r6,-4(r1)
		stwu	r5,-4(r1)
		stwu	r4,-4(r1)
		mr	r8,r4
		mr	r4,r5
		li	r6,1
		
.TagLoop2:	mflr	r7
		li	r3,SonnetBase
		lwz	r3,PowerPCBase(r3)
		lwz	r0,_LVONextTagItemPPC+2(r3)
		mtlr	r0
		blrl
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
EndFunctions:
