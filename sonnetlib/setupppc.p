.include ppcdefines.i
.include sonnet_libppc.i
.include ppcmacros-std.i

.global PPCCode,PPCLen,RunningTask,WaitingTasks,Init,ViolationAddress
.global MCTask,SysBase,PowerPCBase,DOSBase

.set	PPCLen,(PPCEnd-PPCCode)

#********************************************************************************************

.section "PPCSetup","acrx"

PPCCode:	b	.SkipCom			#0x3000	System initialization

.long		0					#Used for initial communication
.long		0					#MemStart
.long		0					#MemLen
.long		0					#RTGBase
.long		0					#RTGType

.SkipCom:	lis	r22,CMD_BASE
		lis	r29,VEC_BASE			#0xfff00000
		ori	r29,r29,0x3000			#For initial communication

		bl	Reset

		setpcireg PICR1				#Setup various PCI registers of the Sonnet
		loadreg r25,VAL_PICR1
		bl	ConfigWrite32
		setpcireg PICR2
		loadreg r25,VAL_PICR2
		bl	ConfigWrite32
		setpcireg PMCR1
		loadreg r25,VAL_PMCR1
		bl	ConfigWrite16
		setpcireg EUMBBAR
		lis	r25,EUMB
		bl	ConfigWrite32

		bl	ConfigMem			#Result = Sonnet Mem Len in r8
		bl	InstallExceptions		#Put exceptions in place

		lis	r27,0x8000			#Upper boundary PCI Memory Mediator
		mr	r26,r8				#This is hardcoded at the moment

		li	r28,17
		mtctr	r28
		li	r28,1
		li	r25,29

Loop1:		slw.	r26,r26,r28
		blt	Fndbit
		addi	r25,r25,-1
		bdnz	Loop1
		b	Pause

Fndbit:		slw.	r26,r26,r28
		beq	SetLen
		addi	r25,r25,1

SetLen:		mr	r30,r28
		slw	r30,r30,r25
		slw	r30,r30,r28
		subf	r27,r30,r27
		lis	r26,EUMB
		ori	r26,r26,ITWR
		stwbrx	r25,0,r26			#debug = 0x19 (=48MB, Development system)
		sync

		setpcireg LMBAR
		mr	r25,r27
		ori	r25,r25,8			#debug = 0x7c000008
		bl	ConfigWrite32

		stw	r27,8(r29)			#MemStart
		stw	r8,12(r29)			#MemLen

		li	r3,0
		li	r4,63
		mtctr	r4
		li	r0,0
.Clear0:	stwu	r0,4(r3)
		bdnz+	.Clear0				#Clear first part of zero page

		lwz	r3,16(r29)
		stw	r3,RTGBase(r0)
		lhz	r3,20(r29)
		sth	r3,RTGType(r0)
		stw	r8,MemSize(r0)		

		bl	mmuSetup			#Setup the Memory Management Unit
		bl	Epic				#Setup the EPIC controller

		bl	End

Start:		loadreg	r0,"REDY"			#Dummy entry at absolute 0x7400
		stw	r0,Init(r0)
.IdleLoop:	nop					#IdleTask
		nop
		nop
		b	.IdleLoop
	
		trap					#For PP_THROW
	
ExitCode:	blrl
		li	r7,TS_REMOVED
		lwz	r9,RunningTask(r0)
		stb	r7,TC_STATE(r9)
		
		lis	r7,EUMB					#Get Msg Frame for 
		li	r8,OFTPR				#communication with 68K
		lwbrx	r9,r8,r7			
		addi	r10,r9,4		
		loadreg	r11,0xc000
		or	r10,r10,r11
		loadreg r11,0xffff
		and	r10,r10,r11				#Keep it C000-FFFE		
		stwbrx	r10,r8,r7
		sync
		lwz	r9,0(r9)
				
		subi	r10,r9,4		
		li	r11,48
		li	r7,0
		mtctr	r11
.ClearLLMsg:	stwu	r7,4(r10)
		bdnz	.ClearLLMsg		
		
		loadreg r7,"FPPC"
		stw	r7,MN_IDENTIFIER(r9)
		li	r7,192
		sth	r7,MN_LENGTH(r9)
		li	r7,NT_MESSAGE
		stb	r7,LN_TYPE(r9)
		
		lwz	r7,RunningTask(r0)		
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
		stfd	f0,PP_FREGS+0*8(r9)
		stfd	f1,PP_FREGS+1*8(r9)
		stfd	f2,PP_FREGS+2*8(r9)
		stfd	f3,PP_FREGS+3*8(r9)
		stfd	f4,PP_FREGS+4*8(r9)
		stfd	f5,PP_FREGS+5*8(r9)
		stfd	f6,PP_FREGS+6*8(r9)
		stfd	f7,PP_FREGS+7*8(r9)
		lwz	r8,MCTask(r0)
		la	r4,pr_MsgPort(r8)		
		stw	r4,MN_MCTASK(r9)
		
		lwz	r4,RunningTask(r0)
		lwz	r4,TC_SPLOWER(r4)
		subi	r4,r4,1024
		stw	r4,MN_ARG0(r9)
		
		mr	r24,r9		
		lis	r3,EUMB					#Send Msg to 68K
		li	r24,OPHPR
		lwbrx	r31,r24,r3		
		stw	r9,0(r31)		
		addi	r23,r31,4
		loadreg	r4,0xbfff
		and	r23,r23,r4				#Keep it 8000-BFFE
		stwbrx	r23,r24,r3				#triggers Interrupt
		sync

		loadreg	r1,SysStack-0x20			#System stack in unused mem
		lwz	r13,SonnetBase(r0)
		or	r1,r1,r13
		subi	r13,r1,4
		stwu	r1,-284(r1)

		lwz	r9,RunningTask(r0)			#Free original 68K -> PPC
		lwz	r9,TASKPPC_STARTMSG(r9)			#message
		lis	r3,EUMB
		li	r24,IFHPR
		lwbrx	r31,r24,r3		
		stw	r9,0(r31)		
		addi	r23,r31,4
		loadreg	r4,0x3fff
		and	r23,r23,r4				#Keep it 0000-3FFE
		stwbrx	r23,r24,r3
		sync
		li	r0,0
		stw	r0,RunningTask(r0)

Pause:		nop
		nop
		b	Pause

End:		mflr	r4
		
		li	r14,0				#Reset
		mtspr	285,r14				#Time Base Upper,
		mtspr	284,r14				#Time Base Lower and
		loadreg r28,0x7fffffff
		mtdec	r28				#Decrementer.

		lwz	r28,0(r14)
		stw	r14,Atomic(r0)
		stw	r28,4(r29)			#Signal 68k that PPC is initialized

		loadreg r6,"INIT"
.WInit:		lwz	r28,Init(r0)
		cmplw	r28,r6
		bne	.WInit
		
		isync					#Wait for 68k to set up library

		li	r3,IdleTask			#Start hardcoded at 0x7400
		lwz	r31,SonnetBase(r0)
		or	r3,r3,r31

		loadreg	r1,SysStack-0x20		#System stack in unused mem (See sonnet.s)
		or	r1,r1,r31
		mr	r31,r3
		
		addi	r5,r4,End-Start
		subf	r5,r4,r5
		li	r6,0
		bl	copy_and_flush			#Put program in Sonnet Mem instead of PCI Mem
		
		stw	r13,-4(r1)
		subi	r13,r1,4
		stwu	r1,-284(r1)		

		la	r4,ReadyTasks(r0)
		bl	.MakeList

		la	r4,WaitingTasks(r0)
		bl	.MakeList

		la	r4,Semaphores(r0)
		bl	.MakeList

		la	r4,Ports(r0)
		bl	.MakeList

		la	r4,AllTasks(r0)
		bl	.MakeList

		la	r4,SnoopList(r0)
		bl	.MakeList
		
		la	r4,NewTasks(r0)
		bl	.MakeList
		
		lwz	r3,PowerPCBase(r0)
		
		la	r4,LIST_REMOVEDTASKS(r3)
		bl	.MakeList
		
		la	r4,LIST_REMOVEDEXC(r3)
		bl	.MakeList
		
		la	r4,LIST_READYEXC(r3)
		bl	.MakeList
		
		la	r4,LIST_INSTALLEDEXC(r3)
		bl	.MakeList
		
		la	r4,LIST_EXCMCHECK(r3)
		bl	.MakeList
		
		la	r4,LIST_EXCDACCESS(r3)
		bl	.MakeList
		
		la	r4,LIST_EXCIACCESS(r3)
		bl	.MakeList
		
		la	r4,LIST_EXCALIGN(r3)
		bl	.MakeList
		
		la	r4,LIST_EXCPROGRAM(r3)
		bl	.MakeList
		
		la	r4,LIST_EXCFPUN(r3)
		bl	.MakeList
		
		la	r4,LIST_EXCDECREMENTER(r3)
		bl	.MakeList
		
		la	r4,LIST_EXCSYSTEMCALL(r3)
		bl	.MakeList
		
		la	r4,LIST_EXCTRACE(r3)
		bl	.MakeList
		
		la	r4,LIST_EXCPERFMON(r3)
		bl	.MakeList
		
		la	r4,LIST_EXCIABR(r3)
		bl	.MakeList
		
		la	r4,LIST_EXCINTERRUPT(r3)
		bl	.MakeList
		
		li	r3,0x7000			#Put Semaphores at 0x7000
		li	r6,0x7200			#Put Semaphores memory at 0x7200
		lwz	r30,SonnetBase(r0)
		or	r3,r3,r30
		or	r6,r6,r30
		
		mr	r30,r3
		mr	r29,r31
		mr	r4,r3
		stw 	r4,TaskListSem(r14)
		bl	.InitSem

		addi	r4,r30,SSPPC_SIZE
		stw	r4,SemListSem(r14)
		addi	r6,r6,32
		bl	.InitSem

		addi	r4,r30,SSPPC_SIZE*2
		stw	r4,PortListSem(r14)
		addi	r6,r6,32
		bl	.InitSem
	
		addi	r4,r30,SSPPC_SIZE*3
		stw	r4,SnoopSem(r14)
		addi	r6,r6,32
		bl	.InitSem
	
		addi	r4,r30,SSPPC_SIZE*4
		stw	r4,MemSem(r14)
		addi	r6,r6,32
		bl	.InitSem
		
		addi	r4,r30,SSPPC_SIZE*5
		stw	r4,WaitListSem(r14)
		addi	r6,r6,32
		bl	.InitSem
				
		bl	.SetupMsgFIFOs

		mfpvr	r4
		stw	r4,CPUInfo(r0)

		mfspr	r4,HID0
		ori	r4,r4,HID0_DCFI|HID0_ICFI
		mtspr	HID0,r4
		sync

		mtsrr0	r29
		
		loadreg	r0,PSL_IR|PSL_DR|PSL_FP|PSL_PR|PSL_EE
		mtsrr1	r0				#load up user MSR. Also clears PSL_IP
		
		lwz	r4,PowerPCBase(r0)
		lwz	r4,_LVOSetCache+2(r4)
		addi	r4,r4,ViolationOS		
		stw	r4,ViolationAddress(r0)

		bl	Caches				#Setup the L1 and L2 cache

		loadreg	r4,Quantum
		mtdec	r4

		rfi					#To user code
		
#********************************************************************************************		

.MakeList:	stw	r4,8(r4)
		lis	r0,0
		nop	
		stwu	r0,4(r4)
		stw	r4,-4(r4)

		blr

.InitSem:	mr	r31,r4
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
		stw	r6,SSPPC_RESERVE(r31)
		
		blr

#********************************************************************************************		

.SetupMsgFIFOs:	lis	r14,EUMB
		
		li	r4,MUCR_CQS_FIFO4K		#4K entries (16k x 4 FIFOs)
		li	r5,MUCR
		stwbrx	r4,r5,r14

		lwz	r6,SonnetBase(r0)
		loadreg	r4,0x100000
		li	r5,QBAR
		stwbrx	r4,r5,r14
		
		mr	r5,r4
		subi	r4,r4,4
		
		loadreg	r14,0x10000
		or	r5,r5,r6
		add	r5,r5,r14
		
		li	r6,4096
		mr	r7,r6
		mtctr	r6
.FillIBFL:	stwu	r5,4(r4)
		addi	r5,r5,192			#Message Frame Length
		bdnz	.FillIBFL

		loadreg	r4,(0x100000-4)+12*4096
		mtctr	r7
.FillOBFL:	stwu	r5,4(r4)
		addi	r5,r5,192
		bdnz	.FillOBFL

		lis	r14,EUMB
		
		li	r5,IFTPR
		li	r4,4096*0
		
		li	r5,IFHPR
		li	r4,4096*4-4
		stwbrx	r4,r5,r14
		
		li	r5,IPTPR
		loadreg	r4,4096*4
		stwbrx	r4,r5,r14
		
		li	r5,IPHPR
		loadreg	r4,4096*4
		stwbrx	r4,r5,r14
		
		li	r5,OPTPR
		loadreg	r4,4096*8
		stwbrx	r4,r5,r14
		
		li	r5,OPHPR
		loadreg	r4,4096*8
		stwbrx	r4,r5,r14
		
		li	r5,OFTPR
		loadreg	r4,4096*12
		stwbrx	r4,r5,r14
		
		li	r5,OFHPR
		loadreg	r4,4096*16-4
		stwbrx	r4,r5,r14

		li	r4,MUCR_CQS_FIFO4K|MUCR_CQE_ENABLE
		li	r5,MUCR
		stwbrx	r4,r5,r14
		
		sync

		blr

#********************************************************************************************

Reset:		mflr	r15

		mfmsr	r1
		andi.	r1,r1,PSL_IP
		mtmsr	r1				#Clear MSR, keep Interrupt Prefix for now 
		isync
							#Zero-out registers
		li	r0,0
		mtsprg0	r0
		mtsprg1 r0
		mtsprg2	r0
		mtsprg3	r0
			
		loadreg	r3,HID0_NHR			#Set HID0 to known state 
		mfspr	r4,HID0
		and	r3,r4, r3			#Clear other bits
		mtspr	HID0,r3
		sync
		
		loadreg	r3,PSL_FP					#Set MPU/MSR to a known state. Turn on FP
		or	r3,r1,r3
		mtmsr 	r3
		isync
							#Init the floating point control/status register 
	 	mtfsfi  7,0
		mtfsfi  6,0
		mtfsfi  5,0
		mtfsfi  4,0
		mtfsfi  3,0
		mtfsfi  2,0
		mtfsfi  1,0
		mtfsfi  0,0
		isync
							#Initialize floating point data regs to known state 
		bl	ifpdr_value
.long		0x3f800000				#Value of 1.0
ifpdr_value:	mflr	r3
		lfs	f0,0(r3)
		lfs	f1,0(r3)
		lfs	f2,0(r3)
		lfs	f3,0(r3)
		lfs	f4,0(r3)
		lfs	f5,0(r3)
		lfs	f6,0(r3)
		lfs	f7,0(r3)
		lfs	f8,0(r3)
		lfs	f9,0(r3)
		lfs	f10,0(r3)
		lfs	f11,0(r3)
		lfs	f12,0(r3)
		lfs	f13,0(r3)
		lfs	f14,0(r3)
		lfs	f15,0(r3)
		lfs	f16,0(r3)
		lfs	f17,0(r3)
		lfs	f18,0(r3)
		lfs	f19,0(r3)
		lfs	f20,0(r3)
		lfs	f21,0(r3)
		lfs	f22,0(r3)
		lfs	f23,0(r3)
		lfs	f24,0(r3)
		lfs	f25,0(r3)
		lfs	f26,0(r3)
		lfs	f27,0(r3)
		lfs	f28,0(r3)
		lfs	f29,0(r3)
		lfs	f30,0(r3)
		lfs	f31,0(r3)
		sync
							#Clear BAT and Segment mapping registers 
		li	r1,0
		mtspr	ibat0u,r1
		mtspr	ibat1u,r1
		mtspr	ibat2u,r1
		mtspr	ibat3u,r1
		mtspr	ibat0l,r1
		mtspr	ibat1l,r1
		mtspr	ibat2l,r1
		mtspr	ibat3l,r1
		mtspr	dbat0u,r1
		mtspr	dbat1u,r1
		mtspr	dbat2u,r1
		mtspr	dbat3u,r1
		mtspr	dbat0l,r1
		mtspr	dbat1l,r1
		mtspr	dbat2l,r1
		mtspr	dbat3l,r1
		isync
		sync
		sync
	
		mtsr	0,r1
		mtsr	1,r1
		mtsr	2,r1
		mtsr	3,r1
		mtsr	4,r1
		mtsr	5,r1
		mtsr	6,r1
		mtsr	7,r1
		mtsr	8,r1
		mtsr	9,r1
		mtsr	10,r1
		mtsr	11,r1
		mtsr	12,r1
		mtsr	13,r1
		mtsr	14,r1
		mtsr	15,r1
		isync
		sync
		sync

		mtlr	r15
		blr

#********************************************************************************************

Epic:		lis	r26,EUMB
		loadreg	r27,EPIC_GCR
		add	r27,r26,r27
		li	r28,0xa0
		stw	r28,0(r27)			#Reset EPIC

.ResLoop:	lwz	r28,0(r27)
		andi.	r28,r28,0x80
		bne	.ResLoop			#Wait for reset

		li	r28,0x20
		stw	r28,0(r27)			#Set Mixed Mode

		loadreg	r28,0x80050042
		loadreg	r27,EPIC_IIVPR3
		add	r27,r26,r27
		stwbrx	r28,0,r27			#Set MU interrupt, Pri = 5, Vector = 0x42

		loadreg	r27,EPIC_EICR
		add	r27,r26,r27
		lwz	r28,0(r27)
		rlwinm	r28,r28,0,21,19			#Doc says Set SIE = 0
		stw	r28,0(r27)

		loadreg	r27,EPIC_IIVPR3
		add 	r27,r26,r27
		lwz	r28,0(r27)
		rlwinm	r28,r28,0,25,23			#Doc says Mask M bit now. Can maybe already at
		stw	r28,0(r27)			#while setting the interrupt above?

		loadreg	r27,EPIC_PCTPR
		add	r27,r26,r27
		lis	r28,0
		stw	r28,0(r27)			#Doc says Set Pri (Task) = 0

		loadreg	r27,EPIC_FRR
		add	r27,r26,r27

		lwbrx	r28,0,r27
		rlwinm	r28,r28,16,21,31		#Get FRR[NIRQ]

		mtctr	r28				#Doc says clear all possible ints
		lis	r26,EUMBEPICPROC

ClearInts:	lwz	r27,0xa0(r26)			#IACKR
		eieio
		clearreg r27
		sync
		stw	r27,0xb0(r26)			#EOI
		bdnz	ClearInts

		blr

#********************************************************************************************

							#Invalidatem then enable L1 caches
Caches:		mfspr	r4,HID0
		ori	r4,r4,HID0_ICFI|HID0_DCFI
		mtspr	HID0,r4
		sync
		
#		blr					#REMOVE ME FOR L1 CACHE
							#L1 cache off for now
							#to fix coherancy problems
		mfspr	r4,HID0
#		ori	r4,r4,HID0_DCE|HID0_SGE|HID0_BTIC|HID0_BHTE
		ori	r4,r4,HID0_ICE|HID0_DCE|HID0_SGE|HID0_BTIC|HID0_BHTE
		sync
		mtspr	HID0,r4
		sync
		 	
#		blr					#REMOVE ME FOR L2 CACHE		
		 					# Set up on chip L2 cache controller.
#		loadreg r4,L2CR_L2SIZ_1M|L2CR_L2CLK_3|L2CR_L2RAM_BURST|L2CR_TS|L2CR_L2WT
		loadreg r4,L2CR_L2SIZ_1M|L2CR_L2CLK_3|L2CR_L2RAM_BURST|L2CR_TS|L2CR_DO
		mtl2cr	r4
		sync
		
		mfl2cr	r5
		oris	r5,r5,L2CR_L2I@h
		mtl2cr	r5
		sync

Wait2:		mfl2cr	r3
		andi.	r3,r3,L2CR_L2IP@l
		cmpwi	r3,L2CR_L2IP@l
		beq	Wait2				#Wait for invalidate done 

		oris	r4,r4,L2CR_L2E@h
		mtl2cr	r4				#Enable L2 cache
		sync
		isync
		
		li	r0,0				#Determine size of L2 Cache
		mr	r5,r0
		mr	r30,r0
		lis	r4,0

		lwz	r6,MemSize(r0)			#Address to start writing
		loadreg	r5,0x400000			#Substract 4 MB
		sub	r6,r6,r5
		lwz	r5,SonnetBase(r0)
		or	r6,r6,r5

		lis	r5,L2_SIZE_1M_U			#Size of memory to write to
		
.L2SzWriteLoop:	dcbz	r4,r6
		stwx	r4,r4,r6
		dcbf	r4,r6
		addi	r4,r4,L2_ADR_INCR
		cmpw	r4,r5
		blt	.L2SzWriteLoop
		
		lis	r4,0
		
.L2SzReadLoop:	lwzx	r7,r4,r6
		cmpw	r4,r7
		bne	.L2SkipCount
		addi	r30,r30,1			#Count cache lines
		
.L2SkipCount:	dcbi	r4,r6
		addi	r4,r4,L2_ADR_INCR
		cmpw	r4,r5
		blt	.L2SzReadLoop
		
		lis	r7,L2CR_SIZE_1MB
		cmpwi	r30,L2_SIZE_1M
		beq	.L2SizeDone
		
		lis	r7,L2CR_SIZE_512KB
		cmpwi	r30,L2_SIZE_HM
		beq	.L2SizeDone
		
		lis	r7,L2CR_SIZE_256KB
		cmpwi	r30,L2_SIZE_QM
		beq	.L2SizeDone
		
		lis	r7,0
		
.L2SizeDone:	li	r4,8
		slw	r30,r30,r4
		stw	r30,L2Size(r0)
		
		mfl2cr	r4		
		xoris	r4,r4,L2CR_SIZE_1MB|L2CR_TS_OFF
		or	r4,r4,r7		
		mtl2cr	r4				#Set correct size and switch Test off
		sync
		isync
		
		blr

#********************************************************************************************

mmuSetup:	
		mflr	r30

		loadreg	r6,0x8000000			#Amount of memory to virtualize (128MB)

		bl	.SetupPT
		
		loadreg	r3,0x80000000				#PCI memory (EUMB) start effective address
		loadreg	r4,0x80100000				#end effective address
		mr	r5,r3					#start physical address
		loadreg	r6,PTE_CACHE_INHIBITED|PTE_GUARDED	#WIMG
		li	r7,2					#pp = 2 - Read/Write Access (0 = No Access)
		
		bl	.DoTBLs
						
		loadreg	r3,0xfff00000			#Fake ROM (64k)
		loadreg	r4,0xfff10000
		mr	r5,r3
		loadreg	r6,PTE_CACHE_INHIBITED
		li	r7,2
		
		bl	.DoTBLs
		
		lwz	r3,RTGBase(r0)			#8MB Video RAM
		addis	r4,r3,0x80
		addis	r5,r3,0x4000
		loadreg	r6,PTE_CACHE_INHIBITED
		lhz	r7,RTGType(r0)
		cmpwi	r7,0x1002
		beq	.ATI
		li	r6,0
.ATI:		li	r7,2
		
		bl	.DoTBLs
		
		li	r3,0				#Zeropage (12K no cache)
		li	r4,0x3000
		mr	r5,r3
		loadreg	r6,PTE_CACHE_INHIBITED
		li	r7,2				#pp = 2 - Read/Write Access
		
		bl	.DoTBLs						
		
		
		li	r3,0x3000			#Exception code (16K cached)
		li	r4,0x7000
		mr	r5,r3
		li	r6,r0
		li	r7,2
		
		bl	.DoTBLs
		
		
		loadreg	r3,0x100000			#Message FIFOs (64k no cache)
		loadreg	r4,0x110000
		mr	r5,r3
		li	r6,PTE_CACHE_INHIBITED
		li	r7,2
		
		bl	.DoTBLs
		
		loadreg	r3,0x110000			#Message (1.5MB no cache)
		loadreg	r4,0x290000
		mr	r5,r3
		or	r3,r3,r27
		or	r4,r4,r27
		li	r6,PTE_CACHE_INHIBITED
		li	r7,2
		
		bl	.DoTBLs

		
		loadreg	r3,0x7000			#First free block (~1MB cached)
		loadreg	r4,0x100000
		mr	r5,r3
		or	r3,r3,r27
		or	r4,r4,r27
		li	r6,0
		li	r7,2
		
		bl	.DoTBLs
		
		loadreg	r3,0x290000			#Sonnet memory (Rest cached)
		lwz	r4,MemSize(r0)
		mr	r5,r3
		or	r3,r3,r27
		add	r4,r4,r27
		li	r6,0
		li	r7,2
		
		bl	.DoTBLs
		
		li	r7,64				#Now invalidate tlb entries
		mtctr	r7
		li	r7,0
.tlblp:		tlbie	r7
		addi	r7,r7,0x1000
		bdnz+	.tlblp
		tlbsync

		loadreg	r0,PSL_IR|PSL_DR|PSL_FP		#Turn on MMU
		sync
		mtmsr	r0		
		sync

		mtlr	r30

		blr

#********************************************************************************************	

.SetupPT:	mflr	r22
		mr	r23,r8				#Save sonnet memory size
		srwi	r6,r6,7				#Get pt_size
		rlwinm.	r8,r6,20,12,31			#is pt_size >= 64 KB
		bne	.Cont
		lis	r6,0x10
		
.Cont:		mr	r3,r23				#Size of sonnet memory

		sub	r3,r3,r6			#Set pt_loc
		mr	r7,r3
		xor	r9,r9,r9
		ori	r9,r9,0xffff			#set up SDR1
		
		rlwinm	r8,r9,16,0,15			#set HTABORG
		and	r15,r3,r8
		
.htabmask:	rlwinm	r8,r9,16,0,15			#set HTABMASK
		and.	r8,r8,r15
		beq	.Exithtab
		cmpwi	r9,0
		ble	.Exithtab
		srwi	r9,r9,1
		b	.htabmask
		
.Exithtab:	or	r15,r15,r9
		sync
		mtspr	SDR1,r15			#set SDR1
		isync

		rlwinm	r6,r6,30,0,31			#r6 = pt_size, r7 = pt_loc
		mtctr	r6
		xor	r8,r8,r8
		subi	r7,r7,4
		
.zero_out:	stwu	r8,4(r7)
		bdnz	.zero_out
		
		mtlr	r22
		blr
		
#********************************************************************************************		
		
.DoTBLs:	mr	r17,r3
		mr	r18,r4
		mr	r19,r5
		mr	r20,r6
		mr	r21,r7
		mflr	r22

		mr	r8,r17
		mr	r9,r18

		rlwinm	r3,r8,4,28,31			#get 4 MSBs
		rlwinm	r4,r9,4,28,31

		lis	r8,0x6000			#set ks and kp
.srx_set:	or	r5,r3,r8

		rlwinm	r13,r3,28,0,4
		mtsrin	r5,r13

		addi	r3,r3,1
		cmpw	r3,r4
		ble	.srx_set

		mr	r3,r17
		mr	r4,r18
		
.load_PTEs:	cmpw	r3,r4
		bge	.ExitTBL
		
		rlwinm	r8,r3,4,28,31
		mfsrin	r13,r3

		mr	r5,r20				#set WIMG
		
		rlwinm	r11,r13,7,1,24			#Upper PTE (with effective address)
		rlwimi	r11,r3,10,26,31
		oris	r11,r11,0x8000			#set valid bit
		
		rlwinm	r12,r19,0,0,19			#Lower PTE (with physical address)
		rlwimi	r12,r5,3,25,28
		ori	r12,r12,0x180			#R=C=1, 
		or	r12,r12,r21			#Set PP (00 with ks/kp=1 = no access)

		rlwinm	r14,r3,20,16,31
		rlwinm	r15,r13,0,13,31
		xor	r14,r14,r15			#Calculate Hash1
		
		mfspr	r15,SDR1			#Calculate PTEG address
.calc_PTEG:	rlwinm	r16,r14,22,23,31
		and	r16,r16,r15
		rlwinm	r8,r15,16,23,31
		or	r16,r16,r8
		
		xor	r9,r9,r9			#clear PTE
		rlwimi	r9,r15,0,0,6
		rlwimi	r9,r16,16,7,15
		rlwimi	r9,r14,6,16,25
		
		subi	r9,r9,8				#Look for empty PTE location
		li	r10,8
		mtctr	r10
		
.next:		lwzu	r8,8(r9)
		rlwinm.	r8,r8,1,31,31			#Check for valid bit
		beq	.store_PTE			#If not valid then PTE is empty
		bdnz	.next

		rlwinm.	r16,r11,26,31,31
		bne	.ExitTBLErr			#Should not happen (no room for Hash2)
		
		xoris	r14,r14,0xffff
		xori	r14,r14,0xffff
		ori	r11,r11,0x40
		b	.calc_PTEG			#Try Hash2

.store_PTE:	stw	r11,0(r9)			#Put PTEs in empty place
		stw	r12,4(r9)
		
		addi	r3,r3,0x1000			#Next page of 4096 bytes
		addi	r19,r19,0x1000
		b	.load_PTEs
		
.ExitTBL:	mtlr	r22
		blr

.ExitTBLErr:	loadreg	r0,"TBL!"
		stw	r0,0xf4(r0)
		b	.ExitTBLErr

#********************************************************************************************

ConfigWrite32:	lis	r20,CONFIG_ADDR			#Various PCI command routines
		lis 	r21,CONFIG_DAT
		stwbrx	r23,0,r20
		sync
		stwbrx	r25,0,r21
		sync
		blr

ConfigWrite16:	lis	r20,CONFIG_ADDR
		lis 	r21,CONFIG_DAT
		stwbrx	r23,0,r20
		sync
		sthbrx	r25,0,r21
		sync
		blr

ConfigWrite8:	lis	r20,CONFIG_ADDR
		stwbrx	r23,0,r20
		sync
		andi.	r23,r23,3
		oris	r21,r23,CONFIG_DAT
		stb	r25,0(r21)
		sync
		blr

#********************************************************************************************
	
ConfigMem:	mflr	r15			#Code lifted from the Sonnet Driver
		setpcireg MCCR4			#by Mastatabs from A1k fame

		lis	r25,0x0010	
		mr	r25,r25			#nop ?
		bl	ConfigWrite32		#set MCCR4 to 0x100000 BUFTYPE[1] = 

		setpcireg MCCR3	
		lis	r25,0x2
		ori	r25,r25,0xa29c		#0x2A29C  0101 010 001 010 011 100,
						#RP1  RAS Precharge = 4 3b100
						#(4 clocks are 110 per pdf, seems docu is wrong)
						#RCD2 RAS to CAS delay = 3
						#CAS3 CAS assertion = 2
						#CP4  CAS precharge = 1
						#CAS5 CAS assertion = 2																	
						#CBR  RAS assertion = 5
						#CAS write timing modifier DRAM = 0	
						#31-19 = 0
		bl	ConfigWrite32		#set MCCR3 to 0x2A29C
	
		setpcireg MCCR2	
		lis	r25,0xe000
		ori	r25,r25,0x1040
		bl	ConfigWrite32		#set MCCR2 to 0xE0001040
						#MCCR2 Memory Control Config Reg   = 0xe0001040
						#    Read Modify Write parity      = 0x0 Disabled
						#    RSV_PG Reserve one open page  = 0x0 Four open page mode
						#    Refresh Interval              = 0x0208 = 520 decimal
						#    EDO Enable                    = 0x0 standard DRAM
						#    ECC enable                    = 0x0 Disabled
						#    Inline Read Parity enable     = 0x0 Disabled
						#    Inline Report Parity enable   = 0x0 Disabled
						#    Inline Parity not ECC         = 0x0 Disabled
						#    ASFALL timing                 = 0x0 clocks
						#    ASRISE timing for Port X      = 0x0 clocks
						#    TS Wait Timer                 = 0x7 8 clocks min disable time

		setpcireg MCCR1
		lis	r25,0xffe2
		mr	r25,r25
		bl	ConfigWrite32		#Set MCCR1 to FFE20000	RAM_TYPE = 1 -> DRAM/EDO, 
						#SREN = 0 disable selfref, MEMGO = 0, 
						#BURST = 0, all banks 9 row bits

		setpcireg MSAR1
		clearreg r25
		bl	ConfigWrite32		#clear MSAR1

		setpcireg MESAR1
		clearreg r25
		bl	ConfigWrite32		#clear EMASR1

		setpcireg MSAR2
		clearreg r25
		bl	ConfigWrite32		#clear MASR2

		setpcireg MESAR2
		clearreg r25
		bl	ConfigWrite32		#clear EMASR2

		setpcireg MEAR1
		loadreg r25,0x7F7F7F7F
		bl	ConfigWrite32		#set MEAR1 to 7f7f7f7f

		setpcireg MEEAR1
		clearreg r25
		bl	ConfigWrite32		#clear EMEAR1

		setpcireg MEAR2
		loadreg r25,0x7F7F7F7F
		bl	ConfigWrite32		#set MEAR2 to 7f7f7f7f

		setpcireg MEEAR2
		clearreg r25
		bl	ConfigWrite32		#clear EMEAR2

		setpcireg MCCR1
		lis	r25,0xffea
		mr	r25,r25
		bl	ConfigWrite32		#set MCCR1 to ffea0000  set MEMGO!

		li	r3,0
		loadreg r4,"Boon"		#0x426F6F6E -> "Boon"
		li	r5,1
		li	r8,0
		li	r9,0
		li	r10,0
		li	r11,0
		li	r12,0
		lis	r13,0xffea		#ffea0000
		li	r14,0
		li	r16,0
		li	r17,0
		li	r18,0
		li	r19,0

loc_3BD8:	setpcireg MBEN			#Memory Bank Enable Register
		mr	r25, r5
		bl	ConfigWrite8		#enable Bank 0

		stw	r4, 0(r3)		#try to store "Boon" at address 0x0
		eieio
	
		stw	r3, 4(r3)		#try to store 0x0 at 0x4
		eieio
		lwz	r7, 0(r3)		#read from 0x0
		cmplw	r4, r7			#is it "Boon", long compare
		bne	loc_4184
	
		or	r14, r14, r5		#continue if found
	
		setpcireg MCCR1			#0x800000f0
		loadreg r25,0xffeaffff		#-22,65535
		bl	ConfigWrite32		#set all banks to 12 or 13 row bits

		lis	r6,0x40
		stw	r3,0(r6)		#set 0x400000 to 0x0
		lis	r6,0x80
		stw	r3,0(r6)		#set 0x800000 to 0x0
		lis	r6,0x100
		stw	r3,0(r6)		#set 0x1000000 to 0x0
		lis	r6,0x200
		stw	r3,0(r6)		#set 0x2000000 to 0x0
		lis	r6,0x400
		stw	r3,0(r6)		#set 0x4000000 to 0x0
		lis	r6,0x800
		stw	r3,0(r6)		#set 0x8000000 to 0x0
		eieio
		stw	r4,0(r3)		#set 0x0 to "Boon"
		eieio		
		lis	r6,0x40
		lwz	r7,0(r6)		#read from 0x400000
		cmplw	r4,r7			#is it "Boon"
		beq	loc_3CBC		#if yes goto loc_3CBC
		lis	r6,0x80
		lwz	r7,0(r6)		#read form 0x800000
		cmplw	r4,r7			#is it "Boon"
		beq	loc_3E24		#if yes goto loc_3E24
		lis	r6,0x100
		lwz	r7,0(r6)		#read from 0x1000000
		cmplw	r4,r7			#is it "Boon"
		beq	loc_3E24		#if yes goto loc_3E24
		lis	r6,0x200
		lwz	r7,0(r6)		#read from 0x2000000
		cmplw	r4,r7
		beq	loc_3E24		#if its "Boon" goto loc_3E24
		lis	r6,0x400
		lwz	r7,0(r6)		#read from 0x4000000
		cmplw	r4,r7
		beq	loc_3E24		#if its "Boon" goto loc_3E24
		lis	r6,0x800
		lwz	r7,0(r6)		#read from 0x8000000
		cmplw	r4,r7
		beq	loc_3E24		#if its "Boon" goto loc_3E24
		b	loc_4184		#goto loc_4184

#********************************************************************************************
loc_3CBC:					#CODE XREF: findSetMem+1D0
		loadreg r25,0xFFEAAAAA		#set row bits to 11 row bits
		bl	ConfigWrite32
		lis	r6,0x20			#continue tests
		stw	r3,0(r6)
		lis	r6,0x40
		stw	r3,0(r6)
		lis	r6,0x80
		stw	r3,0(r6)
		lis	r6,0x100
		stw	r3,0(r6)
		lis	r6,0x200
		stw	r3,0(r6)
		eieio
		stw	r4,0(r3)
		eieio
		lis	r6,0x20
		lwz	r7,0(r6)
		cmplw	r4,r7
		beq	loc_3D50
		lis	r6,0x40
		lwz	r7,0(r6)
		cmplw	r4,r7
		beq	loc_3E24
		lis	r6,0x80
		lwz	r7,0(r6)
		cmplw	r4,r7
		beq	loc_3E24
		lis	r6,0x100
		lwz	r7,0(r6)
		cmplw	r4,r7
		beq	loc_3E24
		lis	r6,0x200
		lwz	r7,0(r6)
		cmplw	r4,r7
		beq	loc_3E24
		b	loc_4184

#********************************************************************************************
loc_3D50:					#CODE XREF: findSetMem+274
		loadreg r25,0xFFEA5555		#set row bits to 10 row bits
		bl	ConfigWrite32
		lis	r6,0x10			#continue tests
		stw	r3,0(r6)
		lis	r6,0x20
		stw	r3,0(r6)
		lis	r6,0x40
		stw	r3,0(r6)
		lis	r6,0x80
		stw	r3,0(r6)
		eieio
		stw	r4,0(r3)
		eieio
		lis	r6,0x10
		lwz	r7,0(r6)
		cmplw	r4,r7
		beq	loc_3DCC
		lis	r6,0x20
		lwz	r7,0(r6)
		cmplw	r4,r7
		beq	loc_3E24
		lis	r6,0x40
		lwz	r7,0(r6)
		cmplw	r4,r7
		beq	loc_3E24
		lis	r6,0x80
		lwz	r7,0(r6)
		cmplw	r4,r7
		beq	loc_3E24
		b	loc_4184

#********************************************************************************************
loc_3DCC:					#CODE XREF: findSetMem+300
		lis	r6,8
		stw	r3,0(r6)
		lis	r6,0x10
		stw	r3,0(r6)
		lis	r6,0x20
		stw	r3,0(r6)
		eieio
		stw	r4,0(r3)
		eieio
		lis	r6,8
		lwz	r7,0(r6)
		cmplw	r4,r7
		beq	loc_4184
		lis	r6,0x10
		lwz	r7,0(r6)
		cmplw	r4,r7
		beq	loc_3E24
		lis	r6,0x20
		lwz	r7,0(r6)
		cmplw	r4,r7
		beq	loc_3E24
		b	loc_4184

#********************************************************************************************
loc_3E24:					#CODE XREF: findSetMem+1E0
						#findSetMem+1F0 ...
		cmplwi	r5,1
		bne	loc_3E84
		mr	r7,r8
		srwi	r7,r7,20
		andi.	r7,r7,0xFF
		or	r9,r9,r7
		mr	r7,r8
		srwi	r7,r7,28
		andi.	r7,r7,3
		or	r16,r16,r7
		add	r8,r8,r6
		mr	r7,r8
		addi	r7,r7,-1
		srwi	r7,r7,20
		andi.	r7,r7,0xFF
		or	r11,r11,r7
		mr	r7,r8
		addi	r7,r7,0xFF
		srwi	r7,r7,28
		andi.	r7,r7,3
		or	r18,r18,r7
		andi.	r25,r25,3
		or	r13,r13,r25
		b	loc_4184

#********************************************************************************************
loc_3E84:					#CODE XREF: findSetMem+394
		cmplwi	r5,2
		bne	loc_3EF4
		mr	r7,r8
		srwi	r7,r7,20
		andi.	r7,r7,0xFF
		slwi	r7,r7,8
		or	r9,r9,r7
		mr	r7,r8
		srwi	r7,r7,28
		andi.	r7,r7,3
		slwi	r7,r7,8
		or	r16,r16,r7
		add	r8,r8,r6
		mr	r7,r8
		addi	r7,r7,-1
		srwi	r7,r7,20
		andi.	r7,r7,0xFF
		slwi	r7,r7,8
		or	r11,r11,r7
		mr	r7,r8
		addi	r7,r7,-1
		srwi	r7,r7,28
		andi.	r7,r7,3
		slwi	r7,r7,8
		or	r18,r18,r7
		andi.	r25,r25,0xC
		or	r13,r13,r25
		b	loc_4184

#********************************************************************************************
loc_3EF4:					#CODE XREF: findSetMem+3F4
		cmplwi	r5,4
		bne	loc_3F64
		mr	r7,r8
		srwi	r7,r7,20
		andi.	r7,r7,0xFF
		slwi	r7,r7,16
		or	r9,r9,r7
		mr	r7,r8
		srwi	r7,r7,28
		andi.	r7,r7,3
		slwi	r7,r7,16
		or	r16,r16,r7
		add	r8,r8,r6
		mr	r7,r8
		addi	r7,r7,-1
		srwi	r7,r7,20
		andi.	r7,r7,0xFF
		slwi	r7,r7,16
		or	r11,r11,r7
		mr	r7,r8
		addi	r7,r7,-1
		srwi	r7,r7,28
		andi.	r7,r7,3
		slwi	r7,r7,16
		or	r18,r18,r7
		andi.	r25,r25,0x30
		or	r13,r13,r25
		b	loc_4184

#********************************************************************************************
loc_3F64:					#CODE XREF: findSetMem+464
		cmplwi	r5,8
		bne	loc_3FD4
		mr	r7,r8
		srwi	r7,r7,20
		andi.	r7,r7,0xFF
		slwi	r7,r7,24
		or	r9,r9,r7
		mr	r7,r8
		srwi	r7,r7,28
		andi.	r7,r7,3
		slwi	r7,r7,24
		or	r16,r16,r7
		add	r8,r8,r6
		mr	r7,r8
		addi	r7,r7,-1
		srwi	r7,r7,20
		andi.	r7,r7,0xFF
		slwi	r7,r7,24
		or	r11,r11,r7
		mr	r7,r8
		addi	r7,r7,-1
		srwi	r7,r7,28
		andi.	r7,r7,3
		slwi	r7,r7,24
		or	r18,r18,r7
		andi.	r25,r25,0xC0
		or	r13,r13,r25
		b	loc_4184

#********************************************************************************************
loc_3FD4:					#CODE XREF: findSetMem+4D4
		cmplwi	r5,0x10
		bne	loc_4034
		mr	r7,r8
		srwi	r7,r7,20
		andi.	r7,r7,0xFF
		or	r10,r10,r7
		mr	r7,r8
		srwi	r7,r7,28
		andi.	r7,r7,3
		or	r17,r17,r7
		add	r8,r8,r6

loc_4000:
		mr	r7,r8
		addi	r7,r7,-1
		srwi	r7,r7,20
		andi.	r7,r7,0xFF
		or	r12,r12,r7
		mr	r7,r8
		addi	r7,r7,-1
		srwi	r7,r7,28
		andi.	r7,r7,3
		or	r19,r19,r7
		andi.	r25,r25,0x300
		or	r13,r13,r25
		b	loc_4184

#********************************************************************************************
loc_4034:
		cmplwi	r5,0x20

		bne	loc_40A4
		mr	r7,r8
		srwi	r7,r7,20
		andi.	r7,r7,0xFF
		slwi	r7,r7,8
		or	r10,r10,r7
		mr	r7,r8
		srwi	r7,r7,28
		andi.	r7,r7,3
		slwi	r7,r7,8
		or	r17,r17,r7
		add	r8,r8,r6
		mr	r7,r8
		addi	r7,r7,-1
		srwi	r7,r7,20
		andi.	r7,r7,0xFF
		slwi	r7,r7,8
		or	r12,r12,r7
		mr	r7,r8
		addi	r7,r7,-1
		srwi	r7,r7,28
		andi.	r7,r7,3
		slwi	r7,r7,8
		or	r19,r19,r7
		andi.	r25,r25,0xC00
		or	r13,r13,r25
		b	loc_4184

#********************************************************************************************
loc_40A4:
		cmplwi	r5,0x40
		bne	loc_4114
		mr	r7,r8
		srwi	r7,r7,20
		andi.	r7,r7,0xFF
		slwi	r7,r7,16
		or	r10,r10,r7
		mr	r7,r8
		srwi	r7,r7,28
		andi.	r7,r7,3
		slwi	r7,r7,16
		or	r17,r17,r7
		add	r8,r8,r6
		mr	r7,r8
		addi	r7,r7,-1
		srwi	r7,r7,20
		andi.	r7,r7,0xFF
		slwi	r7,r7,16
		or	r12,r12,r7
		mr	r7,r8
		addi	r7,r7,-1
		srwi	r7,r7,28
		andi.	r7,r7,3
		slwi	r7,r7,16
		or	r19,r19,r7
		andi.	r25,r25,0x3000
		or	r13,r13,r25
		b	loc_4184

#********************************************************************************************
loc_4114:
		cmplwi	r5,0x80
		bne	loc_4184
		mr	r7,r8
		srwi	r7,r7,20
		andi.	r7,r7,0xFF
		slwi	r7,r7,24
		or	r10,r10,r7
		mr	r7,r8
		srwi	r7,r7,28
		andi.	r7,r7,3
		slwi	r7,r7,24
		or	r17,r17,r7
		add	r8,r8,r6
		mr	r7,r8
		addi	r7,r7,-1
		srwi	r7,r7,20
		andi.	r7,r7,0xFF
		slwi	r7,r7,24
		or	r12,r12,r7
		mr	r7,r8
		addi	r7,r7,-1
		srwi	r7,r7,28
		andi.	r7,r7,3
		slwi	r7,r7,24
		or	r19,r19,r7
		andi.	r25,r25,0xc000
		or	r13,r13,r25
		b	loc_4184

loc_4184:
		slwi	r5,r5,1
		cmplwi	r5,0x100
		bne	loc_3BD8
		
		

		setpcireg MSAR1				#80
		mr	r25,r9		
		bl	ConfigWrite32			#store found values to registers

		setpcireg MSAR2				#84
		mr	r25,r10
		bl	ConfigWrite32

		setpcireg MEAR1				#90		
		mr	r25,r11		
		bl	ConfigWrite32

		setpcireg MEAR2				#94
		mr	r25,r12
		bl	ConfigWrite32

		setpcireg MCCR1				#F0		
		mr	r25,r13
		bl	ConfigWrite32

		setpcireg MESAR1			#88		
		mr	r25,r16
		bl	ConfigWrite32

		setpcireg MESAR2			#8c
		mr	r25,r17
		bl	ConfigWrite32

		setpcireg MEEAR1			#98
		mr	r25,r18
		bl	ConfigWrite32

		setpcireg MEEAR2			#9C
		mr	r25,r19
		bl	ConfigWrite32

		setpcireg MBEN				#A0
		mr	r25,r14
		bl	ConfigWrite8
	
		mtlr	r15
		
		blr

#********************************************************************************************
#Copy routine used to copy the kernel to start at physical address 0
#and flush and invalidate the caches as needed.
#r3 = dest addr, r4 = source addr, r5 = copy limit, r6 = start offset
#on exit, r3, r4, r5 are unchanged, r6 is updated to be >= r5.

copy_and_flush:	addi	r5,r5,-4
		addi	r6,r6,-4
cachel:		li	r0,L1_CACHE_LINE_SIZE/4
		mtctr	r0
cachel1:	addi	r6,r6,4				#copy a cache line
		lwzx	r0,r6,r4
		stwx	r0,r6,r3
		bdnz	cachel1
		dcbst	r6,r3				#write it to memory
		sync
		icbi	r6,r3				#flush the icache line
		cmplw	0,r6,r5
		blt	cachel
		sync					#additional sync needed on g4
		isync
		addi	r5,r5,4
		addi	r6,r6,4
		blr

#********************************************************************************************

InstallExceptions:					#Installs a loop on every exception
		mflr	r15				#to make sure unsupported exceptions
		bl	GtCode				#will not run into never-neverland
		
Halt:		nop					#These 2 instructions are the loop
		b	Halt
		
GtCode:		mflr	r16
		li	r17,0
		li	r18,20				#0x100-0x1400
		mtctr	r18
FillEm:		addi	r17,r17,0x100
		lwz	r19,0(r16)
		stw	r19,0(r17)
		lwz	r19,4(r16)
		stw	r19,4(r17)
		bdnz	FillEm
		bl	EIntEnd

#********************************************************************************************

EInt:		b	.FPUnav				#0
		b	.Alignment			#4
		b	.ISI				#8
		b	.DSI				#c
		b	.Trace				#10
		b	.BreakPoint			#14
		b	.DecInt				#18
		b	.PrInt				#1c
		b	.MachCheck			#20
		b	.SysCall			#24

		mtsprg2	r0				#28
		
		li	r0,-1
		stb	r0,ExceptionMode(r0)
		
		mfsrr1	r0
		mtsprg1	r0
		mfsrr0	r0
		mtsprg0	r0

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0				#Reenable MMU (can affect srr0/srr1 acc Docs)
		isync					#Also reenable FPU
		sync

		mtsprg3	r1				
		lwz	r0,SonnetBase(r0)		#Store user stack pointer
		loadreg	r1,SysStack-0x20		#System stack in unused mem (See sonnet.s)
		or	r1,r1,r0
		mfsprg3 r0
		stwu	r0,-4(r1)
		
		mfxer	r0
		mtsprg3	r0

		prolog	228,"TOC"

		stwu	r3,-4(r13)
		stwu	r4,-4(r13)
		stwu 	r5,-4(r13)
		stwu	r6,-4(r13)
		stwu	r7,-4(r13)
		stwu	r8,-4(r13)
		stwu	r9,-4(r13)

		loadreg	r3,"EXEX"
		stw	r3,0xf4(r0)

#.RDecInt:	
		lis	r3,EUMBEPICPROC
		lwz	r5,EPIC_IACK(r3)		#Read IACKR to acknowledge interrupt

		rlwinm	r5,r5,8,0,31
		cmpwi	r5,0x00ff			#Spurious Vector. Should not do EOI acc Docs.
		beq	.ReturnToUser
		
.IntReturn:	lis	r3,EUMB
		li	r4,IMISR
		lwbrx	r5,r4,r3
		andi.	r9,r5,IMISR_IM0I
		beq	.CheckQueue

		mr	r9,r5
		li	r5,IMISR_IM0I|IMISR_IM1I
		stwbrx	r5,r4,r3			#Clear IM0/IM1 bit to clear interrupt
		eieio		
		mr	r5,r9
	
.CheckQueue:	andi.	r9,r5,IMISR_IPQI
		beq	.EndQueue
		
		li	r5,IMISR_IPQI			#Clear IPQI bit to clear interrupt
		stwbrx	r5,r4,r3		
		eieio

		li	r4,IPTPR			#Get message from Inbound FIFO
		lwbrx	r5,r4,r3
.QNotEmpty:	addi	r9,r5,4				#Increase FIFO pointer
		loadreg	r4,0x4000
		or	r9,r9,r4
		loadreg r4,0x7fff
		and	r9,r9,r4			#Keep it 4000-7FFE		
		sync
		
		lwz	r5,0(r5)				
		loadreg	r4,"TPPC"
		lwz	r6,MN_IDENTIFIER(r5)
		cmpw	r4,r6				#The one we want?
		beq	.MsgTPPC
		
		loadreg	r4,"DONE"
		cmpw	r4,r6
		bne	.NxtInQ
		
		lwz	r4,MN_PPC(r5)
		
		li	r3,TS_READY
		stb	r3,TC_STATE(r4)
		
		mr	r3,r4
				
		lwz	r4,TASKPPC_MSGPORT(r3)				
		lbz	r6,MP_SIGBIT(r4)
		li	r8,1
		slw	r8,r8,r6		
		addi	r4,r4,MP_MSGLIST						
		lwz	r0,TC_SIGRECVD(r3)
		or	r0,r0,r8
		stw	r0,TC_SIGRECVD(r3)
				
		addi	r4,r4,4				#PutMsg r5 to currenttask
		lwz	r3,4(r4)			#AddTailPPC
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
									
		b	.NxtInQ
		
.MsgTPPC:	la	r4,NewTasks(r0)
		
		addi	r4,r4,4				#AddTailPPC
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
		
.NxtInQ:	lis	r3,EUMB
		li	r4,IPHPR
		lwbrx	r5,r4,r3
		loadreg	r4,0xffff
		and	r5,r5,r4
		cmpw	r5,r9

		beq	.QEmpty
		
		mr	r5,r9
		b	.QNotEmpty
		
.QEmpty:	li	r4,IPTPR
		stwbrx	r9,r4,r3
		sync
		
.EndQueue:	clearreg r5
		lis	r3,EUMBEPICPROC
		stw	r5,EPIC_EOI(r3)			#Write 0 to EOI to End Interrupt
		
.RDecInt:	
		lhz	r9,RTGType(r0)
		cmpwi	r9,0x1002
		beq	.ATI2
		lwz	r9,RTGBase(r0)
		addis	r4,r9,0x80
.flushgfx:	dcbf	r0,r9
		addi	r9,r9,32
		cmpw	r9,r4
		bne	.flushgfx
		
.ATI2:		lwz	r9,TaskException(r0)
		mr.	r9,r9
		bne	.TaskException

		li	r9,TS_READY
		la	r4,WaitingTasks(r0)
		lwz	r4,MLH_HEAD(r4)
.NextOnList:	lwz	r5,LN_SUCC(r4)
		mr.	r5,r5
		beq	.EndOfWaitList
		lbz	r6,TC_STATE(r4)
		cmpw	r9,r6
		beq	.GotOneWait
		
		mr	r4,r5		
		b	.NextOnList

.GotOneWait:			
		mr	r6,r4
		
		lwz	r3,0(r4)			#RemovePPC
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)
		
		mr	r5,r6
		la	r4,ReadyTasks(r0)
		
		addi	r4,r4,4				#AddTailPPC
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)

.EndOfWaitList:	
		lwz	r9,RunningTask(r0)

		b	.TrySwitch

.NewTask:	la	r4,NewTasks(r0)
		mr	r6,r4

		lwz	r5,0(r4)			#RemHeadPPC
		lwz	r3,0(r5)
		mr.	r3,r3
		beq-	.NoNode5
		stw	r3,0(r4)
		stw	r4,4(r3)
		mr	r3,r5
	
.NoNode5:	mr.	r9,r3
		beq	.ReturnToUser

		mr	r3,r9
		
.Dispatch:	lwz	r8,MN_ARG0(r9)		

		li	r4,TS_RUN
		stb	r4,TC_STATE(r8)
		li	r4,NT_PPCTASK
		stb	r4,LN_TYPE(r8)
		la	r4,TASKPPC_CTMEM(r8)
		stw	r4,TASKPPC_CONTEXTMEM(r8)
		stw	r9,TASKPPC_STARTMSG(r8)
		la	r31,TASKPPC_NAME(r8)
		stw	r31,LN_NAME(r8)
		lwz	r31,MN_ARG1(r9)
		stw	r31,TASKPPC_STACKSIZE(r8)
		addi	r4,r8,1024		
		stw	r4,TC_SPLOWER(r8)
		add	r4,r4,r31
		stw	r4,TC_SPUPPER(r8)
		subi	r4,r4,32
		stw	r4,TC_SPREG(r8)
		mr	r1,r4
		
		addi	r4,r8,TC_MEMENTRY
		stw	r4,8(r4)
		li	r0,0
		stwu	r0,4(r4)
		stw	r4,-4(r4)
		
		stw	r13,-4(r1)
		subi	r13,r1,4
		stwu	r1,-284(r1)		
		
		loadreg	r6,IdleTask+(ExitCode-Start)
		lwz	r4,SonnetBase(r0)
		or	r6,r6,r4
		mtsprg0	r6

		la	r6,TASKPPC_PORT(r8)		#Setup a Semaphore & MsgPort
		addi	r4,r6,MP_PPC_INTMSG
		stw	r4,LH_TAILPRED(r4) 
		li	r0,0 
		stwu	r0,LH_TAIL(r4) 
		stwu	r4,LH_HEAD-4(r4) 
 
		addi	r4,r6,MP_MSGLIST
		stw	r4,LH_TAILPRED(r4) 
		li	r0,0 
		stwu	r0,LH_TAIL(r4) 
		stwu	r4,LH_HEAD-4(r4) 
 
 		loadreg	r0,SYS_SIGALLOC
		stw	r0,TC_SIGALLOC(r8)
 
		li	r0,SIGB_DOS 			#SIGBIT = DOS
		stb	r0,MP_SIGBIT(r6)			 
		addi	r4,r6,MP_PPC_SEM

		addi	r5,r4,SS_WAITQUEUE
		stw	r5,8(r5)
		li	r0,0
		stwu	r0,4(r5)
		stwu	r5,-4(r5)
		li	r0,0
		stw	r0,SS_OWNER(r4)
		sth	r0,SS_NESTCOUNT(r4)
		li	r0,-1
		sth	r0,SS_QUEUECOUNT(r4)	 
 
 		la	r3,TASKPPC_SSPPC_RESERVE(r8)
 		stw	r3,SSPPC_RESERVE(r4)
 
		stw	r8,MP_SIGTASK(r6)
		li	r0,PA_SIGNAL 
		stb	r0,MP_FLAGS(r6)
		li	r0,NT_MSGPORTPPC 
		stb	r0,LN_TYPE(r6)
		stw	r6,TASKPPC_MSGPORT(r8)

		stw	r8,RunningTask(r0)

		mr	r8,r9
		
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
		lfd	f0,PP_FREGS+0*8(r8)
		lfd	f1,PP_FREGS+1*8(r8)
		lfd	f2,PP_FREGS+2*8(r8)
		lfd	f3,PP_FREGS+3*8(r8)
		lfd	f4,PP_FREGS+4*8(r8)
		lfd	f5,PP_FREGS+5*8(r8)
		lfd	f6,PP_FREGS+6*8(r8)
		lfd	f7,PP_FREGS+7*8(r8)
		lwz	r9,PP_OFFSET(r8)
		mr	r7,r8
		lwz	r8,PP_CODE(r8)
		add	r8,r8,r9
		
		mtlr	r8
		
		lwz	r11,Break(r0)
		mr.	r11,r11
		beq	.NoBreak				#Should be beq
		
		mr	r11,r8
		ori	r11,r11,3
		mtspr	IABR,r11				#Set breakpoint
		isync
		
.NoBreak:	li	r0,0
		mr	r8,r0
		mr	r9,r0
		mr	r10,r0
		mr 	r11,r0
		mr	r12,r0
		mr	r14,r0
		mr	r15,r0
		mr	r16,r0
		mr	r17,r0
		mr	r18,r0
		mr	r19,r0
		mr	r20,r0
		mr	r21,r0
		
		loadreg	r0,PSL_IR|PSL_DR|PSL_FP|PSL_PR|PSL_EE
		mtsrr1	r0		
		mfsprg0	r0
		mtsrr0	r0

		mfspr	r0,HID0
		ori	r0,r0,HID0_ICFI
		mtspr	HID0,r0
		isync

		li	r0,0
		
		lwz	r7,PP_FLAGS(r7)
		rlwinm.	r7,r7,(32-PPB_THROW),31,31
		beq	.NoThrow
		
		mfsrr0	r7
		subi	r7,r7,4					#Set start on a TRAP instruction
		mtsrr0	r7

.NoThrow:	mr	r7,r0
		stb	r0,ExceptionMode(r0)

		loadreg	r0,Quantum
		mtdec	r0

		loadreg	r0,"WARP"
		
		rfi
		
#********************************************************************************************
		
.ReturnToUser:		
		lwz	r9,0xf0(r0)				#Debug counter to check
		addi	r9,r9,1					#Whether exception is still
		stw	r9,0xf0(r0)				#running
		
		lwz	r9,0(r13)
		lwzu	r8,4(r13)
		lwzu	r7,4(r13)
		lwzu	r6,4(r13)
		lwzu	r5,4(r13)
		lwzu	r4,4(r13)
		lwzu	r3,4(r13)
		addi	r13,r13,4
	
		excepilog "TOC"

		lwz	r1,0(r1)				#Restore user stack

		mfsprg3	r0
		mtxer	r0
		mfsprg1 r0
		mtsrr1	r0
		mfsprg0	r0
		mtsrr0	r0
		
		li	r0,0
		stb	r0,ExceptionMode(r0)
		
		loadreg	r0,"USER"
		stw	r0,0xf4(r0)
		
		mfspr	r0,HID0
		ori	r0,r0,HID0_ICFI
		mtspr	HID0,r0
		isync

		loadreg	r0,Quantum
		mtdec	r0
		
		mfsprg2	r0

		rfi
		
#********************************************************************************************

.TaskException:	li	r9,0				#Will be starting point for TC_EXCEPTCODE
		stw	r9,TaskException(r0)
		b	.ReturnToUser
		
#********************************************************************************************

.TrySwitch:	mr.	r9,r9
		bne	.CheckWait
		
		la	r4,ReadyTasks(r0)
		
		lwz	r5,0(r4)			#RemHeadPPC
		lwz	r3,0(r5)
		mr.	r3,r3
		beq-	.NoNode3
		stw	r3,0(r4)
		stw	r4,4(r3)
		mr	r3,r5
		
.NoNode3:	mr.	r9,r3
		
		beq	.NewTask

		li	r6,TS_RUN
		stb	r6,TC_STATE(r9)
		stw	r9,RunningTask(r0)		
		b	.LoadContext

.CheckWait:	
		li	r4,TS_REMOVED
		lbz	r3,TC_STATE(r9)
		cmpw	r3,r4
		
		beq	.ReturnToUser

		li	r4,TS_CHANGING
		lbz	r3,TC_STATE(r9)
		cmpw	r3,r4
		
		beq	.GoToWait
		
		la	r4,NewTasks(r0)
		mr	r6,r4
		
		lwz	r5,0(r4)			#RemHeadPPC
		lwz	r3,0(r5)
		mr.	r3,r3
		beq-	.NoNode1
		stw	r3,0(r4)
		stw	r4,4(r3)
		mr	r3,r5
	
.NoNode1:	mr.	r9,r3
		bne	.SwitchNew			#Dispatch fixed bug

		la	r4,ReadyTasks(r0)
	
		lwz	r5,0(r4)			#RemHeadPPC
		lwz	r3,0(r5)
		mr.	r3,r3
		beq-	.NoNode2
		stw	r3,0(r4)
		stw	r4,4(r3)
		mr	r3,r5
	
.NoNode2:	mr.	r9,r3	
		bne	.SwitchOld
		
		b	.ReturnToUser
	
.SwitchOld:	la	r4,ReadyTasks(r0)		#Old = Context, New = PPStruct		
		lwz	r5,RunningTask(r0)
		stw	r9,RunningTask(r0)
		
		li	r6,TS_READY
		stb	r6,TC_STATE(r5)
		li	r6,TS_RUN
		stb	r6,TC_STATE(r9)
		
		bl	.StoreContext
		
		addi	r4,r4,4				#AddTailPPC
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
		
		b	.LoadContext
	
.SwitchNew:	
		la	r4,ReadyTasks(r0)
		lwz	r5,RunningTask(r0)
		stw	r9,RunningTask(r0)
		
		li	r6,TS_READY
		stb	r6,TC_STATE(r5)
		
		bl	.StoreContext
		
		addi	r4,r4,4				#AddTailPPC
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)

		b	.Dispatch
		
.StoreContext:	lwz	r6,TASKPPC_CONTEXTMEM(r5)
		mfsprg0	r3
		stw	r3,0(r6)
		mfsprg1 r3
		stwu	r3,4(r6)
		lwz	r3,0(r1)
		lwz	r3,0(r3)			#User stack
		lwz	r0,8(r3)			#lr
		stwu	r0,4(r6)
		lwz	r0,4(r3)			#cr
		stwu	r0,4(r6)
		mfctr	r0
		stwu	r0,4(r6)
		mfsprg3	r0
		stwu	r0,4(r6)			#xer
		mfsprg2	r0
		stwu	r0,4(r6)
		stwu	r3,4(r6)
		stwu	r2,4(r6)
		lwz	r0,24(r13)
		stwu	r0,4(r6)
		lwz	r0,20(r13)
		stwu	r0,4(r6)
		lwz	r0,16(r13)
		stwu	r0,4(r6)
		lwz	r0,12(r13)
		stwu	r0,4(r6)
		lwz	r0,8(r13)
		stwu	r0,4(r6)
		lwz	r0,4(r13)
		stwu	r0,4(r6)
		lwz	r0,0(r13)
		stwu	r0,4(r6)
		stwu	r10,4(r6)
		stwu	r11,4(r6)
		stwu	r12,4(r6)
		lwz	r3,-4(r3)
		stwu	r3,4(r6)
		stwu	r14,4(r6)
		stwu	r15,4(r6)
		stwu	r16,4(r6)
		stwu	r17,4(r6)
		stwu	r18,4(r6)
		stwu	r19,4(r6)
		stwu	r20,4(r6)
		stwu	r21,4(r6)
		stwu	r22,4(r6)
		stwu	r23,4(r6)
		stwu	r24,4(r6)
		stwu	r25,4(r6)
		stwu	r26,4(r6)
		stwu	r27,4(r6)
		stwu	r28,4(r6)
		stwu	r29,4(r6)
		stwu	r30,4(r6)
		stwu	r31,4(r6)
		stfdu	f0,4(r6)			#NO Pad to make align on 8
		stfdu	f1,8(r6)
		stfdu	f2,8(r6)
		stfdu	f3,8(r6)
		stfdu	f4,8(r6)
		stfdu	f5,8(r6)
		stfdu	f6,8(r6)
		stfdu	f7,8(r6)
		stfdu	f8,8(r6)
		stfdu	f9,8(r6)
		stfdu	f10,8(r6)
		stfdu	f11,8(r6)
		stfdu	f12,8(r6)
		stfdu	f13,8(r6)
		stfdu	f14,8(r6)
		stfdu	f15,8(r6)		
		stfdu	f16,8(r6)
		stfdu	f17,8(r6)
		stfdu	f18,8(r6)
		stfdu	f19,8(r6)
		stfdu	f20,8(r6)
		stfdu	f21,8(r6)
		stfdu	f22,8(r6)
		stfdu	f23,8(r6)
		stfdu	f24,8(r6)
		stfdu	f25,8(r6)
		stfdu	f26,8(r6)
		stfdu	f27,8(r6)
		stfdu	f28,8(r6)
		stfdu	f29,8(r6)
		stfdu	f30,8(r6)
		stfdu	f31,8(r6)
		blr
			
.LoadContext:	lwz	r9,TASKPPC_CONTEXTMEM(r9)
		lwz	r0,0(r9)
		stw	r9,0x180(r0)
		mtsrr0	r0
		lwzu	r0,4(r9)
		mtsrr1	r0
		lwzu	r0,4(r9)
		stw	r0,0x184(r0)
		mtlr	r0
		lwzu	r0,4(r9)
		mtcr	r0
		lwzu	r0,4(r9)
		mtctr	r0
		lwzu	r0,4(r9)
		mtxer	r0
		lwzu	r0,4(r9)
		lwzu	r1,4(r9)
		lwzu	r2,4(r9)
		lwzu	r3,4(r9)
		lwzu	r4,4(r9)
		lwzu	r5,4(r9)
		lwzu	r6,4(r9)
		lwzu	r7,4(r9)
		lwzu	r8,4(r9)
		lwzu	r10,4(r9)
		mtsprg3	r10
		lwzu	r10,4(r9)
		lwzu	r11,4(r9)
		lwzu	r12,4(r9)
		lwzu	r13,4(r9)
		lwzu	r14,4(r9)
		lwzu	r15,4(r9)
		lwzu	r16,4(r9)
		lwzu	r17,4(r9)
		lwzu	r18,4(r9)
		lwzu	r19,4(r9)
		lwzu	r20,4(r9)
		lwzu	r21,4(r9)
		lwzu	r22,4(r9)
		lwzu	r23,4(r9)
		lwzu	r24,4(r9)
		lwzu	r25,4(r9)
		lwzu	r26,4(r9)
		lwzu	r27,4(r9)
		lwzu	r28,4(r9)
		lwzu	r29,4(r9)
		lwzu	r30,4(r9)
		lwzu	r31,4(r9)
		lfdu	f0,4(r9)			#NO Pad to make align on 8
		lfdu	f1,8(r9)
		lfdu	f2,8(r9)
		lfdu	f3,8(r9)
		lfdu	f4,8(r9)
		lfdu	f5,8(r9)
		lfdu	f6,8(r9)
		lfdu	f7,8(r9)
		lfdu	f8,8(r9)
		lfdu	f9,8(r9)
		lfdu	f10,8(r9)
		lfdu	f11,8(r9)
		lfdu	f12,8(r9)
		lfdu	f13,8(r9)
		lfdu	f14,8(r9)
		lfdu	f15,8(r9)
		lfdu	f16,8(r9)
		lfdu	f17,8(r9)
		lfdu	f18,8(r9)
		lfdu	f19,8(r9)
		lfdu	f20,8(r9)
		lfdu	f21,8(r9)
		lfdu	f22,8(r9)
		lfdu	f23,8(r9)
		lfdu	f24,8(r9)
		lfdu	f25,8(r9)
		lfdu	f26,8(r9)
		lfdu	f27,8(r9)
		lfdu	f28,8(r9)
		lfdu	f29,8(r9)
		lfdu	f30,8(r9)
		lfdu	f31,8(r9)
		
		li	r9,0
		stb	r9,ExceptionMode(r0)
		
		mfspr	r9,HID0
		ori	r9,r9,HID0_ICFI
		mtspr	HID0,r9
		isync

		loadreg	r9,Quantum
		mtdec	r9
		
		mfsprg3	r9
		rfi
		
#********************************************************************************************

.GoToWait:	li	r4,TS_WAIT
		stb	r4,TC_STATE(r9)
		la	r4,WaitingTasks(r0)
		mr	r5,r9
		
		bl	.StoreContext
		
		addi	r4,r4,4				#AddTailPPC
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
		
		li	r4,0
		stw	r4,RunningTask(r0)

		la	r4,ReadyTasks(r0)

		lwz	r5,0(r4)			#RemHeadPPC
		lwz	r3,0(r5)
		mr.	r3,r3
		beq-	.NoNode4
		stw	r3,0(r4)
		stw	r4,4(r3)
		mr	r3,r5

.NoNode4:	mr.	r9,r3
		beq	.DoIdle
		
		li	r0,TS_RUN
		stb	r0,TC_STATE(r9)
		stw	r9,RunningTask(r0)
		
		b	.LoadContext

.DoIdle:	loadreg	r0,IdleTask+(.IdleLoop-Start)	#Switch to idle task
		lwz	r1,SonnetBase(r0)
		or	r0,r1,r0
		mtsrr0	r0

		loadreg	r1,SysStack-0x20		#System stack in unused mem
		lwz	r0,SonnetBase(r0)
		or	r1,r1,r0
		
		stw	r13,-4(r1)
		subi	r13,r1,4
		stwu	r1,-284(r1)
		
		loadreg	r0,PSL_IR|PSL_DR|PSL_FP|PSL_PR|PSL_EE
		mtsrr1	r0
		
		mfspr	r0,HID0
		ori	r0,r0,HID0_ICFI
		mtspr	HID0,r0
		isync

		loadreg	r0,Quantum
		mtdec	r0
		
		li	r0,0
		stb	r0,ExceptionMode(r0)
		
		rfi

#********************************************************************************************
		
.DecInt:	mtsprg2	r0

		li	r0,-1
		stb	r0,ExceptionMode(r0)

		mfsrr1	r0
		mtsprg1	r0
		mfsrr0	r0
		mtsprg0	r0
		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0				#Reenable MMU (can affect srr0/srr1 acc Docs)
		isync					#Also reenable FPU
		sync

		mtsprg3	r1				#Store user stack pointer
		lwz	r0,SonnetBase(r0)
		loadreg	r1,SysStack-0x20		#System stack in unused mem (See sonnet.s)
		or	r1,r1,r0
		mfsprg3	r0
		stwu	r0,-4(r1)
		
		mfxer	r0
		mtsprg3	r0
		
		prolog	228,"TOC"

		stwu	r3,-4(r13)
		stwu	r4,-4(r13)
		stwu 	r5,-4(r13)
		stwu	r6,-4(r13)
		stwu	r7,-4(r13)
		stwu	r8,-4(r13)
		stwu	r9,-4(r13)

		loadreg r5,"DECI"
		stw	r5,0xf4(r0)
		
.ListLoop:	lwz	r9,PowerPCBase(r0)
		la	r4,LIST_READYEXC(r9)

		lwz	r5,0(r4)			#RemHeadPPC
		lwz	r3,0(r5)
		mr.	r3,r3
		beq-	.NoExcHandlers
		stw	r3,0(r4)
		stw	r4,4(r3)
			
		lwz	r8,EXCDATA_EXCID(r5)
		
		rlwinm.	r0,r8,(32-EXC_MCHECK),31,31
		beq	.NoMCheck
		
		la	r4,LIST_EXCMCHECK(r9)
		b	.InsertOnPri
		
.NoMCheck:	rlwinm.	r0,r8,(32-EXC_DACCESS),31,31
		beq	.NoDAccess
		
		la	r4,LIST_EXCDACCESS(r9)
		b	.InsertOnPri
		
.NoDAccess:	rlwinm.	r0,r8,(32-EXC_IACCESS),31,31
		beq	.NoIAccess
		
		la	r4,LIST_EXCIACCESS(r9)
		b	.InsertOnPri
		
.NoIAccess:	rlwinm.	r0,r8,(32-EXC_INTERRUPT),31,31
		beq	.NoInterrupt
		
		la	r4,LIST_EXCINTERRUPT(r9)
		b	.InsertOnPri
		
.NoInterrupt:	rlwinm.	r0,r8,(32-EXC_ALIGN),31,31
		beq	.NoAlign
		
		la	r4,LIST_EXCALIGN(r9)
		b	.InsertOnPri
		
.NoAlign:	rlwinm.	r0,r8,(32-EXC_PROGRAM),31,31
		beq	.NoProgram
		
		la	r4,LIST_EXCPROGRAM(r9)
		b	.InsertOnPri
		
.NoProgram:	rlwinm.	r0,r8,(32-EXC_FPUN),31,31
		beq	.NoFPUn
		
		la	r4,LIST_EXCFPUN(r9)
		b	.InsertOnPri
				
.NoFPUn:	rlwinm.	r0,r8,(32-EXC_DECREMENTER),31,31
		beq	.NoDecrementer
		
		la	r4,LIST_EXCDECREMENTER(r9)
		b	.InsertOnPri
		
.NoDecrementer:	rlwinm.	r0,r8,(32-EXC_SYSTEMCALL),31,31
		beq	.NoSystemCall
		
		la	r4,LIST_EXCSYSTEMCALL(r9)
		b	.InsertOnPri		
		
.NoSystemCall:	rlwinm.	r0,r8,(32-EXC_TRACE),31,31
		beq	.NoTrace
		
		la	r4,LIST_EXCTRACE(r9)
		b	.InsertOnPri		

.NoTrace:	rlwinm.	r0,r8,(32-EXC_PERFMON),31,31
		beq	.NoPerfMon
		
		la	r4,LIST_EXCPERFMON(r9)
		b	.InsertOnPri

.NoPerfMon:	rlwinm.	r0,r8,(32-EXC_IABR),31,31
		beq	.NoIABR
		
		la	r4,LIST_EXCIABR(r9)
		b	.InsertOnPri
		
.NoIABR:	lwz	r6,EXCDATA_FLAGS(r5)
		ori	r6,r6,(1<<EXC_ACTIVE)
		stw	r6,EXCDATA_FLAGS(r5)
				
		b	.ListLoop
		
.InsertOnPri:	lbz	r3,LN_PRI(r5)			#EnqueuePPC
		extsb	r3,r3
		lwz	r6,0(r4)
.InsertLoop1:	mr	r4,r6
		lwz	r6,0(r4)
		mr.	r6,r6
		beq-	.InsertLink1
		lbz	r7,LN_PRI(r4)
		extsb	r7,r7
		cmpw	r3,r7
		ble+	.InsertLoop1
.InsertLink1:	lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
		b	.NoIABR
		
.NoExcHandlers:	lwz	r3,PowerPCBase(r0)
		la	r4,LIST_REMOVEDEXC(r3)
		
		lwz	r5,0(r4)			#RemHeadPPC
		lwz	r3,0(r5)
		mr.	r3,r3
		beq-	.NoRemExc
		stw	r3,0(r4)
		stw	r4,4(r3)
		mr	r7,r5
		
		mfctr	r0
		li	r5,12
		mtctr	r5
		la	r6,EXCDATA_LASTEXC(r7)
		
.NextExc:	lwzu	r4,4(r6)
		mr.	r4,r4
		beq	.NotInstalled
		
		lwz	r3,0(r4)			#RemovePPC
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)
		
.NotInstalled:	bdnz+	.NextExc
		
		mtctr	r0
		lwz	r6,EXCDATA_LASTEXC(r7)
		lwz	r7,EXCDATA_FLAGS(r6)
		ori	r7,r7,(1<<EXC_ACTIVE)
		xori	r7,r7,(1<<EXC_ACTIVE)
		stw	r7,EXCDATA_FLAGS(r6)
		
		b	.NoExcHandlers
		
.NoRemExc:	b	.RDecInt
		
#********************************************************************************************

.BreakPoint:	mfspr	r0,HID0
		ori	r0,r0,HID0_DCE
		xori	r0,r0,HID0_DCE
		sync	
		mtspr	HID0,r0
		isync
		
		loadreg	r3,"IABR"
		stw	r3,0xf4(r0)
		mfsrr0	r3
		stw	r3,0xf8(r0)
		mfsrr1	r3
		stw	r3,0xfc(r0)
.HaltIABR:	b	.HaltIABR

#********************************************************************************************

.MachCheck:	mfspr	r0,HID0
		ori	r0,r0,HID0_DCE
		xori	r0,r0,HID0_DCE
		sync	
		mtspr	HID0,r0
		isync
		
		loadreg	r3,"CHCK"
		stw	r3,0xf4(r0)
		mfsrr0	r3
		stw	r3,0xf8(r0)
		mfsrr1	r3
		stw	r3,0xfc(r0)
.HaltMCheck:	b	.HaltMCheck

#********************************************************************************************

.SysCall:	mfspr	r0,HID0
		ori	r0,r0,HID0_DCE
		xori	r0,r0,HID0_DCE
		sync	
		mtspr	HID0,r0
		isync
		
		loadreg	r3,"SYSC"
		stw	r3,0xf4(r0)
		mfsrr0	r3
		stw	r3,0xf8(r0)
		mfsrr1	r3
		stw	r3,0xfc(r0)
.HaltSysCall:	b	.HaltSysCall

#********************************************************************************************

.Trace:		mtsprg0	r0				#Program Exception
		
		li	r0,-1
		stb	r0,ExceptionMode(r0)

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0
		sync				#Reenable MMU & FPU
		isync

		mtsprg3	r1
		lwz	r0,SonnetBase(r0)
		loadreg	r1,SysStack-0x20		#System stack in unused mem (See sonnet.s)
		or	r1,r1,r0
		mfsprg3	r0
		stwu	r0,-4(r1)			#Store user stack
		
		mfsprg0	r0

		stw	r13,-4(r1)
		subi	r13,r1,4
		stwu	r1,-1080(r1)				
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r3,-4(r13)
		stwu	r2,-4(r13)
		stwu	r0,-4(r13)		
		mfcr	r0
		stwu	r0,-4(r13)

		loadreg	r29,"TRCE"
		stw	r29,0xf4(r0)
				
		lwz	r31,PowerPCBase(r0)
		la	r31,LIST_EXCTRACE(r31)
.NextTExc:	lwz	r31,0(r31)			#Are there handlers in place?

		lwz	r0,0(r31)
		mr.	r0,r0
		beq	.LastTrHandler
		
		mr	r30,r31
												
		lwz	r0,EXCDATA_TASK(r30)
		mr.	r0,r0
		beq 	.DoTExc
		
		lwz	r28,RunningTask(r0)
		cmpw	r0,r28
		beq	.DoTExc
		
		b	.NextTExc
		
.DoTExc:	mflr	r29
		mtsprg0	r31
		lwz	r0,EXCDATA_CODE(r30)
		mtlr	r0		
		lwz	r0,EXCDATA_FLAGS(r30)
		rlwinm.	r0,r0,(32-EXC_LARGECONTEXT),31,31
		li	r0,EXCF_TRACE
		bne-	.LargeTContext
		
		mtsprg3	r2
		lwz	r2,EXCDATA_DATA(r30)
		mtsprg1	r29		
		subi	r13,r13,XCO_SIZE
		stw	r3,4(r13)
		stw	r0,0(r13)
		mr	r3,r13
		mtsprg2	r1				
		
		lwz	r0,4+XCO_SIZE(r13)
		lwz	r27,16+XCO_SIZE(r13)
		lwz	r28,20+XCO_SIZE(r13)
		lwz	r29,24+XCO_SIZE(r13)
		lwz	r30,28+XCO_SIZE(r13)
		lwz	r31,32+XCO_SIZE(r13)
		
		blrl					#DO NOT TRASH R13 IN HANDLER!

		addi	r13,r13,XCO_SIZE
		
		stw	r0,4(r13)
		stw	r27,16(r13)
		stw	r28,20(r13)
		stw	r29,24(r13)
		stw	r30,28(r13)
		stw	r31,32(r13)
		
		mfsprg1	r31
		mtlr	r31
		mfsprg2	r1
		mfsprg3	r2
		mfsprg0	r31
			
		stw	r2,8(r13)								
		cmpwi	r3,EXCRETURN_ABORT
		beq	.LastTrHandler
				
		b	.NextTExc
		
.LargeTContext:	mr	r31,r13
		subi	r13,r13,EC_SIZE
		mr	r3,r13

		stw	r0,0(r3)
		mfsrr0	r0
		stwu	r0,4(r3)
		mfsrr1	r0		
		stwu	r0,4(r3)
		mfdar	r0
		stwu	r0,4(r3)
		mfdsisr	r0
		stwu	r0,4(r3)
		lwz	r0,0(r31)		#cr
		stwu	r0,4(r3)
		mfctr	r0
		stwu	r0,4(r3)
		stwu	r29,4(r3)		#lr
		mfxer	r0
		stwu	r0,4(r3)
		stfd	f0,16(r3)
		mffs	f0
		stfd	f0,4(r3)
		lfd	f0,16(r3)
		lwz	r0,8(r3)
		stwu	r0,4(r3)
		lwz	r0,4(r31)		#r0
		stwu	r0,4(r3)
		lwz	r29,0(r1)
		lwz	r0,0(r29)
		stwu	r0,4(r3)		#r1
		stwu	r2,4(r3)
		lwz	r0,12(r31)		#r3
		stwu	r0,4(r3)
		stwu	r4,4(r3)
		stwu	r5,4(r3)
		stwu	r6,4(r3)
		stwu	r7,4(r3)
		stwu	r8,4(r3)
		stwu	r9,4(r3)
		stwu	r10,4(r3)
		stwu	r11,4(r3)
		stwu	r12,4(r3)
		lwz	r2,0(r1)
		lwz	r0,-4(r2)		
		stwu	r0,4(r3)		#r13
		stwu	r14,4(r3)
		stwu	r15,4(r3)
		stwu	r16,4(r3)
		stwu	r17,4(r3)
		stwu	r18,4(r3)
		stwu	r19,4(r3)
		stwu	r20,4(r3)
		stwu	r21,4(r3)
		stwu	r22,4(r3)
		stwu	r23,4(r3)
		stwu	r24,4(r3)
		stwu	r25,4(r3)
		stwu	r26,4(r3)
		lwz	r0,16(r31)
		stwu	r0,4(r3)		#r27
		lwz	r0,20(r31)
		stwu	r0,4(r3)		#r28
		lwz	r0,24(r31)
		stwu	r0,4(r3)		#r29
		lwz	r0,28(r31)
		stwu	r0,4(r3)		#r30
		lwz	r0,32(r31)
		stwu	r0,4(r3)		#r31
		stfdu	f0,4(r3)
		stfdu	f1,8(r3)
		stfdu	f2,8(r3)
		stfdu	f3,8(r3)
		stfdu	f4,8(r3)
		stfdu	f5,8(r3)
		stfdu	f6,8(r3)
		stfdu	f7,8(r3)
		stfdu	f8,8(r3)
		stfdu	f9,8(r3)
		stfdu	f10,8(r3)
		stfdu	f11,8(r3)
		stfdu	f12,8(r3)
		stfdu	f13,8(r3)
		stfdu	f14,8(r3)
		stfdu	f15,8(r3)		
		stfdu	f16,8(r3)
		stfdu	f17,8(r3)
		stfdu	f18,8(r3)
		stfdu	f19,8(r3)
		stfdu	f20,8(r3)
		stfdu	f21,8(r3)
		stfdu	f22,8(r3)
		stfdu	f23,8(r3)
		stfdu	f24,8(r3)
		stfdu	f25,8(r3)
		stfdu	f26,8(r3)
		stfdu	f27,8(r3)
		stfdu	f28,8(r3)
		stfdu	f29,8(r3)
		stfdu	f30,8(r3)
		stfdu	f31,8(r3)

		mr	r3,r13
		mtsprg3	r3

		lwz	r2,EXCDATA_DATA(r30)

		blrl

		mfsprg3	r31

		lwzu	r0,4(r31)		#Skips Exc type
		mtsrr0	r0
		lwzu	r0,4(r31)
		mtsrr1	r0
		lwzu	r0,4(r31)
		mtdar	r0
		lwzu	r0,4(r31)
		mtdsisr	r0		
		lwzu	r0,4(r31)
		mtcr	r0
		lwzu	r0,4(r31)
		mtctr	r0
		lwzu	r0,4(r31)
		mtlr	r0
		lwzu	r0,4(r31)
		mtxer	r0
		lfd	f0,0(r31)
		mtfsf	0xff,f0
		lwzu	r0,8(r31)
		lwzu	r2,4(r31)
		mtsprg1	r2			#(New) User stack pointer
		lwzu	r2,4(r31)
		mtsprg2	r3
		lwzu	r3,4(r31)
		lwzu	r4,4(r31)
		lwzu	r5,4(r31)
		lwzu	r6,4(r31)
		lwzu	r7,4(r31)
		lwzu	r8,4(r31)
		lwzu	r9,4(r31)
		lwzu	r10,4(r31)
		lwzu	r11,4(r31)
		lwzu	r12,4(r31)
		lwzu	r13,4(r31)
		lwzu	r14,4(r31)
		lwzu	r15,4(r31)
		lwzu	r16,4(r31)
		lwzu	r17,4(r31)
		lwzu	r18,4(r31)
		lwzu	r19,4(r31)
		lwzu	r20,4(r31)
		lwzu	r21,4(r31)
		lwzu	r22,4(r31)
		lwzu	r23,4(r31)
		lwzu	r24,4(r31)
		lwzu	r25,4(r31)
		lwzu	r26,4(r31)
		lwzu	r27,4(r31)
		lwzu	r28,4(r31)
		lwzu	r29,4(r31)
		lwz	r30,8(r31)
		mtsprg3	r30
		lwzu	r30,4(r31)
		lfdu	f0,8(r31)		#skips r31 (is in sprg3)
		lfdu	f1,8(r31)
		lfdu	f2,8(r31)
		lfdu	f3,8(r31)
		lfdu	f4,8(r31)
		lfdu	f5,8(r31)
		lfdu	f6,8(r31)
		lfdu	f7,8(r31)
		lfdu	f8,8(r31)
		lfdu	f9,8(r31)
		lfdu	f10,8(r31)
		lfdu	f11,8(r31)
		lfdu	f12,8(r31)
		lfdu	f13,8(r31)
		lfdu	f14,8(r31)
		lfdu	f15,8(r31)
		lfdu	f16,8(r31)
		lfdu	f17,8(r31)
		lfdu	f18,8(r31)
		lfdu	f19,8(r31)
		lfdu	f20,8(r31)
		lfdu	f21,8(r31)
		lfdu	f22,8(r31)
		lfdu	f23,8(r31)
		lfdu	f24,8(r31)
		lfdu	f25,8(r31)
		lfdu	f26,8(r31)
		lfdu	f27,8(r31)
		lfdu	f28,8(r31)
		lfdu	f29,8(r31)
		lfdu	f30,8(r31)
		lfdu	f31,8(r31)
		
		mfsprg3	r31
		
		stw	r13,-4(r1)
		subi	r13,r1,4				
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r3,-4(r13)
		stwu	r2,-4(r13)
		stwu	r0,-4(r13)		
		mfcr	r0
		stwu	r0,-4(r13)

		mfsprg1	r3
		lwz	r31,0(r1)
		stw	r3,0(r31)		#Change User Stack

		mfsprg2	r3
		mfsprg0	r31

		cmpwi	r3,EXCRETURN_ABORT
		beq	.LastTrHandler		
		
		b	.NextTExc
		
.LastTrHandler:	lwz	r0,0(r13)
		mtcr	r0
		lwz	r0,4(r13)
		mtsprg0	r0
		lwz	r2,8(r13)
		lwz	r3,12(r13)
		lwz	r27,16(r13)
		lwz	r28,20(r13)
		lwz	r29,24(r13)
		lwz	r30,28(r13)
		lwz	r31,32(r13)
		addi	r13,r13,36

		lwz	r1,0(r1)
		lwz	r13,-4(r1)
		lwz	r1,0(r1)			#User stack restored
		
		li	r0,0
		stb	r0,ExceptionMode(r0)

		loadreg	r0,"USER"
		stw	r0,0xf4(r0)
		
		mfspr	r0,HID0
		ori	r0,r0,HID0_ICFI
		mtspr	HID0,r0
		isync

		mfsprg0	r0
		
		rfi
		
#********************************************************************************************

.FPUnav:	mfspr	r0,HID0
		ori	r0,r0,HID0_DCE
		xori	r0,r0,HID0_DCE
		sync	
		mtspr	HID0,r0
		isync
		
		loadreg	r3,"NOFP"
		stw	r3,0xf4(r0)
		mfsrr0	r3
		stw	r3,0xf8(r0)
		mfsrr1	r3
		stw	r3,0xfc(r0)
.HaltFP:	b	.HaltFP

#********************************************************************************************

.Alignment:	mfspr	r0,HID0
		ori	r0,r0,HID0_DCE
		xori	r0,r0,HID0_DCE
		sync	
		mtspr	HID0,r0
		isync
		
		loadreg	r3,"ALIG"
		stw	r3,0xf4(r0)
		mfsrr0	r3
		stw	r3,0xf8(r0)
.HaltAlign:	b	.HaltAlign

#********************************************************************************************

.ISI:		mfspr	r0,HID0
		ori	r0,r0,HID0_DCE
		xori	r0,r0,HID0_DCE
		sync	
		mtspr	HID0,r0
		isync
		
		loadreg	r3,"ISI!"
		stw	r3,0xf4(r0)
		mfsrr0	r3
		stw	r3,0xf8(r0)
		mflr	r3
		stw	r3,0xfc(r0)
.HaltISI:	b	.HaltISI

#********************************************************************************************

.DSI:		mtsprg0	r0
		mtsprg1	r6
		mtsprg2	r7
		mtsprg3	r8

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0				#Reenable MMU & FPU
		sync
		isync

		loadreg	r7,"DSI!"
		stw	r7,0xf4(r0)

		mfsrr0	r7
		stw	r7,0xf8(r0)		
		lwz	r7,0(r7)		
		
.wosdb:		lwz	r6,SysBase(r0)			#Special wosdb patch
		cmpw	r6,r10
		bne	.Nowosdb

		loadreg	r0,0x80ca0142			#MemList(sysbase)->r6
		lwz	r6,PPCMemHeader(r0)		#dummy
		mtsprg1	r6

		cmpw	r0,r7
		beq	.Clutch

.Nowosdb:	lis	r0,0xc000			#check for load or store instruction
		and.	r0,r7,r0
		lis	r6,0x8000
		cmpw	r6,r0				
		bne	.NoLoadStore

.DoInst:	rlwinm	r6,r7,11,27,31			#Get Destination Reg (l) or Source (s)
		rlwinm	r8,r7,16,27,31			#Get Source Reg (l) or Destination (s)
		rlwinm.	r0,r7,4,31,31			#Check load or store
		rlwinm	r0,r7,6,31,31			#Check for update bit
		rlwinm	r7,r7,0,16,31			#Displacement (halfword)
		extsh	r7,r7				#Extend sign of displacement

		beq	.GetAddr

		cmpwi	r6,0
		bne	.NotSDr0
		mfsprg0	r8
		b	.GetAddr
		
.NotSDr0:	cmpwi	r6,1
		bne	.NotSDr1
		mr	r8,r1
		b	.GetAddr
		
.NotSDr1:	cmpwi	r6,2
		bne	.NotSDr2
		mr	r8,r2
		b	.GetAddr
		
.NotSDr2:	cmpwi	r6,3
		bne	.NotSDr3
		mr	r8,r3
		b	.GetAddr
		
.NotSDr3:	cmpwi	r6,4
		bne	.NotSDr4
		mr	r8,r4
		b	.GetAddr		

.NotSDr4:	cmpwi	r6,5
		bne	.NotSDr5
		mr	r8,r5
		b	.GetAddr
		
.NotSDr5:	cmpwi	r6,6
		bne	.NotSDr6
		mfsprg1	r8
		b	.GetAddr
		
.NotSDr6:	cmpwi	r6,7
		bne	.NotSDr7
		mfsprg2	r8
		b	.GetAddr
		
.NotSDr7:	cmpwi	r6,8
		bne	.NotSDr8
		mfsprg3	r8
		b	.GetAddr
		
.NotSDr8:	cmpwi	r6,9
		bne	.NotSDr9
		mr	r8,r9
		b	.GetAddr
		
.NotSDr9:	cmpwi	r6,10
		bne	.NotSDr10
		mr	r8,r10
		b	.GetAddr
		
.NotSDr10:	cmpwi	r6,11
		bne	.NotSDr11
		mr	r8,r11
		b	.GetAddr
		
.NotSDr11:	cmpwi	r6,12
		bne	.NotSDr12
		mr	r8,r12
		b	.GetAddr		

.NotSDr12:	cmpwi	r6,13
		bne	.NotSDr13
		mr	r8,r13
		b	.GetAddr
		
.NotSDr13:	cmpwi	r6,14
		bne	.NotSDr14
		mr	r8,r14
		b	.GetAddr
		
.NotSDr14:	cmpwi	r6,15
		bne	.NotSDr15
		mr	r8,r15
		b	.GetAddr
		
.NotSDr15:	cmpwi	r6,16
		bne	.NotSDr16
		mr	r8,r16
		b	.GetAddr		

.NotSDr16:	cmpwi	r6,17
		bne	.NotSDr17
		mr	r8,r17
		b	.GetAddr
		
.NotSDr17:	cmpwi	r6,18
		bne	.NotSDr18
		mr	r8,r18
		b	.GetAddr
		
.NotSDr18:	cmpwi	r6,19
		bne	.NotSDr19
		mr	r8,r19
		b	.GetAddr
		
.NotSDr19:	cmpwi	r6,20
		bne	.NotSDr20
		mr	r8,r20
		b	.GetAddr		

.NotSDr20:	cmpwi	r6,21
		bne	.NotSDr21
		mr	r8,r21
		b	.GetAddr
		
.NotSDr21:	cmpwi	r6,22
		bne	.NotSDr22
		mr	r8,r22
		b	.GetAddr
		
.NotSDr22:	cmpwi	r6,23
		bne	.NotSDr23
		mr	r8,r23
		b	.GetAddr
		
.NotSDr23:	cmpwi	r6,24
		bne	.NotSDr24
		mr	r8,r24
		b	.GetAddr
		
.NotSDr24:	cmpwi	r6,25
		bne	.NotSDr25
		mr	r8,r25
		b	.GetAddr
		
.NotSDr25:	cmpwi	r6,26
		bne	.NotSDr26
		mr	r8,r26
		b	.GetAddr
		
.NotSDr26:	cmpwi	r6,27
		bne	.NotSDr27
		mr	r8,r27
		b	.GetAddr
		
.NotSDr27:	cmpwi	r6,28
		bne	.NotSDr28
		mr	r8,r28
		b	.GetAddr		

.NotSDr28:	cmpwi	r6,29
		bne	.NotSDr29
		mr	r8,r29
		b	.GetAddr
		
.NotSDr29:	cmpwi	r6,30
		bne	.NotSDr30
		mr	r8,r30
		b	.GetAddr
		
.NotSDr30:	cmpwi	r6,31
		bne	.HaltDSI			#Should not happen
		mr	r8,r31

.GetAddr:	mr	r6,r0
		mr	r0,r8
		
		mfsrr0	r8
		lwz	r8,0(r8)
		rlwinm	r8,r8,16,27,31			#Get Source Reg (l) or Destination (s)
		
		cmpwi	r8,0
		bne	.Notr0
		mfsprg0 r8
		add	r7,r8,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mtsprg0	r7
		b	.GotAmigaMemAd
		
.Notr0:		cmpwi	r8,1
		bne	.Notr1
		add	r7,r1,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r1,r7
		b	.GotAmigaMemAd
		
.Notr1:		cmpwi	r8,2
		bne	.Notr2
		add	r7,r2,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r2,r7
		b	.GotAmigaMemAd
		
.Notr2:		cmpwi	r8,3
		bne	.Notr3
		add	r7,r3,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r3,r7
		b	.GotAmigaMemAd
		
.Notr3:		cmpwi	r8,4
		bne	.Notr4
		add	r7,r4,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r4,r7
		b	.GotAmigaMemAd
		
.Notr4:		cmpwi	r8,5
		bne	.Notr5
		add	r7,r5,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r5,r7
		b	.GotAmigaMemAd
		
.Notr5:		cmpwi	r8,6
		bne	.Notr6
		mfsprg1	r8
		add	r7,r8,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mtsprg1	r7
		b	.GotAmigaMemAd
		
.Notr6:		cmpwi	r8,7
		bne	.Notr7
		mfsprg2	r8
		add	r7,r8,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mtsprg2	r7
		b	.GotAmigaMemAd
		
.Notr7:		cmpwi	r8,8
		bne	.Notr8
		mfsprg3 r8
		add	r7,r8,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mtsprg3	r7
		b	.GotAmigaMemAd
		
.Notr8:		cmpwi	r8,9
		bne	.Notr9
		add	r7,r9,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r9,r7
		b	.GotAmigaMemAd
		
.Notr9:		cmpwi	r8,10
		bne	.Notr10
		add	r7,r10,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r10,r7
		b	.GotAmigaMemAd
		
.Notr10:	cmpwi	r8,11
		bne	.Notr11
		add	r7,r11,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r11,r7
		b	.GotAmigaMemAd
		
.Notr11:	cmpwi	r8,12
		bne	.Notr12
		add	r7,r12,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r12,r7
		b	.GotAmigaMemAd
		
.Notr12:	cmpwi	r8,13
		bne	.Notr13
		add	r7,r13,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r13,r7
		b	.GotAmigaMemAd
		
.Notr13:	cmpwi	r8,14
		bne	.Notr14
		add	r7,r14,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r14,r7
		b	.GotAmigaMemAd
		
.Notr14:	cmpwi	r8,15
		bne	.Notr15
		add	r7,r15,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r15,r7
		b	.GotAmigaMemAd
		
.Notr15:	cmpwi	r8,16
		bne	.Notr16
		add	r7,r16,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r16,r7
		b	.GotAmigaMemAd
		
.Notr16:	cmpwi	r8,17
		bne	.Notr17
		add	r7,r17,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r17,r7
		b	.GotAmigaMemAd
		
.Notr17:	cmpwi	r8,18
		bne	.Notr18
		add	r7,r18,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r18,r7
		b	.GotAmigaMemAd
		
.Notr18:	cmpwi	r8,19
		bne	.Notr19
		add	r7,r19,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r19,r7
		b	.GotAmigaMemAd
		
.Notr19:	cmpwi	r8,20
		bne	.Notr20
		add	r7,r20,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r20,r7
		b	.GotAmigaMemAd
		
.Notr20:	cmpwi	r8,21
		bne	.Notr21
		add	r7,r21,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r21,r7
		b	.GotAmigaMemAd
		
.Notr21:	cmpwi	r8,22
		bne	.Notr22
		add	r7,r22,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r22,r7
		b	.GotAmigaMemAd
		
.Notr22:	cmpwi	r8,23
		bne	.Notr23
		add	r7,r23,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r23,r7
		b	.GotAmigaMemAd
		
.Notr23:	cmpwi	r8,24
		bne	.Notr24
		add	r7,r24,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r24,r7
		b	.GotAmigaMemAd
		
.Notr24:	cmpwi	r8,25
		bne	.Notr25
		add	r7,r25,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r25,r7
		b	.GotAmigaMemAd
		
.Notr25:	cmpwi	r8,26
		bne	.Notr26
		add	r7,r26,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r26,r7
		b	.GotAmigaMemAd
		
.Notr26:	cmpwi	r8,27
		bne	.Notr27
		add	r7,r27,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r27,r7
		b	.GotAmigaMemAd
		
.Notr27:	cmpwi	r8,28
		bne	.Notr28
		add	r7,r28,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r28,r7
		b	.GotAmigaMemAd
		
.Notr28:	cmpwi	r8,29
		bne	.Notr29
		add	r7,r29,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r29,r7
		b	.GotAmigaMemAd
		
.Notr29:	cmpwi	r8,30
		bne	.Notr30
		add	r7,r30,r7
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r30,r7
		b	.GotAmigaMemAd
		
.Notr30:	cmpwi	r8,31
		bne	.HaltDSI
		add	r7,r31,r7				#Should not happen
		mr.	r6,r6
		beq	.GotAmigaMemAd
		mr	r31,r7

.GotAmigaMemAd:	mfsrr0	r8
		lwz	r8,0(r8)
		mr	r6,r0
		rlwinm.	r0,r8,4,31,31				#Check load or store		
		beq	.LoadInstr
	
		rlwinm.	r0,r8,3,31,31
		bne	.StoreHalf
		rlwinm. r0,r8,5,31,31
		bne	.StoreByte
		loadreg	r8,"PUTW"
		b	.DoStore
.StoreHalf:	loadreg	r8,"PUTH"
		b	.DoStore
.StoreByte:	loadreg	r8,"PUTB"
		
.DoStore:	mr	r0,r6
		mr	r6,r1				#r13?
		stwu	r3,-4(r6)
		stwu	r4,-4(r6)
		stwu	r23,-4(r6)
		stwu	r24,-4(r6)
		stwu	r30,-4(r6)
		stwu	r31,-4(r6)
								
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

		stw	r8,MN_IDENTIFIER(r30)
		stw	r0,MN_IDENTIFIER+4(r30)		#AmigaValue
		stw	r7,MN_IDENTIFIER+8(r30)		#AmigaAddress
		
		lwz	r4,MCTask(r0)
		la	r4,pr_MsgPort(r4)
		stw	r4,MN_MCTASK(r30)
		li	r4,NT_MESSAGE
		stb	r4,LN_TYPE(r30)
		li	r4,192
		sth	r4,MN_LENGTH(r30)

		sync

		lis	r3,EUMB
		li	r24,OPHPR
		lwbrx	r31,r24,r3		
		stw	r30,0(r31)		
		addi	r23,r31,4
		loadreg	r4,0xbfff
		and	r23,r23,r4			#Keep it 8000-BFFE
		stwbrx	r23,r24,r3			#triggers Interrupt

		loadreg	r8,"DONE"
.WaitPFIFO:	lwz	r7,MN_IDENTIFIER(r30)
		cmpw	r7,r8
		bne	.WaitPFIFO

		lwz	r31,0(r6)
		lwz	r30,4(r6)
		lwz	r24,8(r6)
		lwz	r23,12(r6)
		lwz	r4,16(r6)
		lwz	r3,20(r6)

		b	.GotAmigaValue
								
.LoadInstr:	mfsrr0	r8
		lwz	r8,0(r8)
		rlwinm	r0,r8,11,27,31			#Get Destination Reg (l) or Source (s)
		loadreg	r8,"GETV"
		mr	r6,r1
		stwu	r3,-4(r6)
		stwu	r4,-4(r6)
		stwu	r23,-4(r6)
		stwu	r24,-4(r6)
		stwu	r30,-4(r6)
		stwu	r31,-4(r6)
								
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

		stw	r8,MN_IDENTIFIER(r30)
		stw	r7,MN_IDENTIFIER+8(r30)		#AmigaAddress

		lwz	r4,MCTask(r0)
		la	r4,pr_MsgPort(r4)
		stw	r4,MN_MCTASK(r30)
		li	r4,NT_MESSAGE
		stb	r4,LN_TYPE(r30)
		li	r4,192
		sth	r4,MN_LENGTH(r30)

		sync

		lis	r3,EUMB
		li	r24,OPHPR
		lwbrx	r31,r24,r3		
		stw	r30,0(r31)		
		addi	r23,r31,4
		loadreg	r4,0xbfff
		and	r23,r23,r4			#Keep it 8000-BFFE
		stwbrx	r23,r24,r3			#triggers Interrupt
		
		loadreg	r8,"DONE"		
.WaitGFIFO:	lwz	r7,MN_IDENTIFIER(r30)
		cmpw	r7,r8
		bne	.WaitGFIFO
		
		lwz	r8,MN_IDENTIFIER+4(r30)
		
		lwz	r31,0(r6)
		lwz	r30,4(r6)
		lwz	r24,8(r6)
		lwz	r23,12(r6)
		lwz	r4,16(r6)
		lwz	r3,20(r6)		
		
		mfsrr0	r6
		lwz	r6,0(r6)
		rlwinm	r6,r6,16,16,31
		andi.	r6,r6,0xa800
		oris	r6,r6,0xffff
		cmpwi	r6,-32768				#lwz/lwzu 0x8000
		beq	.FixedValue
		rlwinm	r8,r8,16,16,31
		cmpwi	r6,-24576				#lhz/lhzu 0xa000
		beq	.FixedValue
		extsh	r8,r8
		cmpwi	r6,-22528				#lha/lhau 0xa800
		beq	.FixedValue
		rlwinm	r8,r8,24,24,31
		cmpwi	r6,-30720				#lbz/lbzu
		bne	.HaltDSI				#Should not happen
		
.FixedValue:	mr	r6,r0

		cmpwi	r6,0
		bne	.NotDr0
		mtsprg0	r8
		b	.GotAmigaValue
		
.NotDr0:	cmpwi	r6,1
		bne	.NotDr1
		mr	r1,r8
		b	.GotAmigaValue
		
.NotDr1:	cmpwi	r6,2
		bne	.NotDr2
		mr	r2,r8
		b	.GotAmigaValue
		
.NotDr2:	cmpwi	r6,3
		bne	.NotDr3
		mr	r3,r8
		b	.GotAmigaValue
		
.NotDr3:	cmpwi	r6,4
		bne	.NotDr4
		mr	r4,r8
		b	.GotAmigaValue		

.NotDr4:	cmpwi	r6,5
		bne	.NotDr5
		mr	r5,r8
		b	.GotAmigaValue
		
.NotDr5:	cmpwi	r6,6
		bne	.NotDr6
		mtsprg1	r8
		b	.GotAmigaValue
		
.NotDr6:	cmpwi	r6,7
		bne	.NotDr7
		mtsprg2	r8
		b	.GotAmigaValue
		
.NotDr7:	cmpwi	r6,8
		bne	.NotDr8
		mtsprg3	r8
		b	.GotAmigaValue
		
.NotDr8:	cmpwi	r6,9
		bne	.NotDr9
		mr	r9,r8
		b	.GotAmigaValue
		
.NotDr9:	cmpwi	r6,10
		bne	.NotDr10
		mr	r10,r8
		b	.GotAmigaValue
		
.NotDr10:	cmpwi	r6,11
		bne	.NotDr11
		mr	r11,r8
		b	.GotAmigaValue
		
.NotDr11:	cmpwi	r6,12
		bne	.NotDr12
		mr	r12,r8
		b	.GotAmigaValue		

.NotDr12:	cmpwi	r6,13
		bne	.NotDr13
		mr	r13,r8
		b	.GotAmigaValue
		
.NotDr13:	cmpwi	r6,14
		bne	.NotDr14
		mr	r14,r8
		b	.GotAmigaValue
		
.NotDr14:	cmpwi	r6,15
		bne	.NotDr15
		mr	r15,r8
		b	.GotAmigaValue
		
.NotDr15:	cmpwi	r6,16
		bne	.NotDr16
		mr	r16,r8
		b	.GotAmigaValue		

.NotDr16:	cmpwi	r6,17
		bne	.NotDr17
		mr	r17,r8
		b	.GotAmigaValue
		
.NotDr17:	cmpwi	r6,18
		bne	.NotDr18
		mr	r18,r8
		b	.GotAmigaValue
		
.NotDr18:	cmpwi	r6,19
		bne	.NotDr19
		mr	r19,r8
		b	.GotAmigaValue
		
.NotDr19:	cmpwi	r6,20
		bne	.NotDr20
		mr	r20,r8
		b	.GotAmigaValue		

.NotDr20:	cmpwi	r6,21
		bne	.NotDr21
		mr	r21,r8
		b	.GotAmigaValue
		
.NotDr21:	cmpwi	r6,22
		bne	.NotDr22
		mr	r22,r8
		b	.GotAmigaValue
		
.NotDr22:	cmpwi	r6,23
		bne	.NotDr23
		mr	r23,r8
		b	.GotAmigaValue
		
.NotDr23:	cmpwi	r6,24
		bne	.NotDr24
		mr	r24,r8
		b	.GotAmigaValue
		
.NotDr24:	cmpwi	r6,25
		bne	.NotDr25
		mr	r25,r8
		b	.GotAmigaValue
		
.NotDr25:	cmpwi	r6,26
		bne	.NotDr26
		mr	r26,r8
		b	.GotAmigaValue
		
.NotDr26:	cmpwi	r6,27
		bne	.NotDr27
		mr	r26,r7
		b	.GotAmigaValue
		
.NotDr27:	cmpwi	r6,28
		bne	.NotDr28
		mr	r28,r8
		b	.GotAmigaValue		

.NotDr28:	cmpwi	r6,29
		bne	.NotDr29
		mr	r29,r8
		b	.GotAmigaValue
		
.NotDr29:	cmpwi	r6,30
		bne	.NotDr30
		mr	r30,r8
		b	.GotAmigaValue
		
.NotDr30:	cmpwi	r6,31
		bne	.HaltDSI			#Should not happen
		mr	r31,r8

.GotAmigaValue:	b	.Clutch
			
							
.NoLoadStore:	nop
		b	.NoClutch
		
.Clutch:	mfsrr0	r7
		addi	r7,r7,4
		mtsrr0	r7
		
.ClutchNoStep:	mfspr	r7,HID0
		ori	r7,r7,HID0_ICFI
		mtspr	HID0,r7
		isync		
		
		loadreg	r7,"USER"
		stw	r7,0xf4(r0)
		
		mfsprg0	r0
		mfsprg1 r6
		mfsprg2	r7
		mfsprg3	r8
		
		rfi

.NoClutch:	mfspr	r0,HID0
		ori	r0,r0,HID0_DCE
		xori	r0,r0,HID0_DCE
		sync	
		mtspr	HID0,r0
		isync
		
.HaltDSI:	b	.HaltDSI

#********************************************************************************************

.PrInt:		
		mtsprg0	r0				#Program Exception
		
		li	r0,-1
		stb	r0,ExceptionMode(r0)		
		
		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0				#Reenable MMU & FPU
		sync
		isync

		mtsprg3	r1
		lwz	r0,SonnetBase(r0)
		loadreg	r1,SysStack-0x20		#System stack in unused mem (See sonnet.s)
		or	r1,r1,r0
		mfsprg3	r0
		stwu	r0,-4(r1)			#Store user stack
		
		mfsprg0	r0
		
		stw	r13,-4(r1)
		subi	r13,r1,4
		stwu	r1,-1080(r1)				
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r3,-4(r13)
		stwu	r2,-4(r13)
		stwu	r0,-4(r13)		
		mfcr	r0
		stwu	r0,-4(r13)

		loadreg	r29,"TRAP"
		stw	r29,0xf4(r0)

		mfsrr0	r31
		stw	r31,0xf8(r0)
		lwz	r0,ViolationAddress(r0)
		cmplw	r0,r31
		beq	.Privvy

		lis	r31,SRR1_TRAP-12
		mfsrr1	r0
		
		and.	r0,r0,r31
		beq	.HaltErr			#skip ILLEGAL and PRIVILEGED

		lwz	r31,PowerPCBase(r0)
		la	r31,LIST_EXCPROGRAM(r31)
.NextPExc:	lwz	r31,0(r31)			#Are there handlers in place?

		lwz	r0,0(r31)
		mr.	r0,r0
		beq	.LastPrHandler
		
		mr	r30,r31

		lwz	r0,EXCDATA_TASK(r30)
		mr.	r0,r0
		beq 	.DoExc
		
		lwz	r28,RunningTask(r0)
		cmpw	r0,r28
		beq	.DoExc
		
		b	.NextPExc
		
.DoExc:		mflr	r29
		mtsprg0	r31
		lwz	r0,EXCDATA_CODE(r30)
		mtlr	r0		
		lwz	r0,EXCDATA_FLAGS(r30)
		rlwinm.	r0,r0,(32-EXC_LARGECONTEXT),31,31
		li	r0,EXCF_PROGRAM
		bne-	.LargeContext
		
		mtsprg3	r2
		lwz	r2,EXCDATA_DATA(r30)
		mtsprg1	r29		
		subi	r13,r13,XCO_SIZE
		stw	r3,4(r13)
		stw	r0,0(r13)
		mr	r3,r13
		mtsprg2	r1				
		
		lwz	r0,4+XCO_SIZE(r13)
		lwz	r27,16+XCO_SIZE(r13)
		lwz	r28,20+XCO_SIZE(r13)
		lwz	r29,24+XCO_SIZE(r13)
		lwz	r30,28+XCO_SIZE(r13)
		lwz	r31,32+XCO_SIZE(r13)
		
		blrl					#DO NOT TRASH R13 IN HANDLER!

		addi	r13,r13,XCO_SIZE
		
		stw	r0,4(r13)
		stw	r27,16(r13)
		stw	r28,20(r13)
		stw	r29,24(r13)
		stw	r30,28(r13)
		stw	r31,32(r13)
		
		mfsprg1	r31
		mtlr	r31
		mfsprg2	r1
		mfsprg3	r2
		mfsprg0	r31
			
		stw	r2,8(r13)								
		cmpwi	r3,EXCRETURN_ABORT
		beq	.LastPrHandler
				
		b	.NextPExc
		
.LargeContext:	mr	r31,r13
		subi	r13,r13,EC_SIZE
		mr	r3,r13

		stw	r0,0(r3)
		mfsrr0	r0
		stwu	r0,4(r3)
		mfsrr1	r0		
		stwu	r0,4(r3)
		mfdar	r0
		stwu	r0,4(r3)
		mfdsisr	r0
		stwu	r0,4(r3)
		lwz	r0,0(r31)		#cr
		stwu	r0,4(r3)
		mfctr	r0
		stwu	r0,4(r3)
		stwu	r29,4(r3)		#lr
		mfxer	r0
		stwu	r0,4(r3)
		stfd	f0,16(r3)
		mffs	f0
		stfd	f0,4(r3)
		lfd	f0,16(r3)
		lwz	r0,8(r3)
		stwu	r0,4(r3)
		lwz	r0,4(r31)		#r0
		stwu	r0,4(r3)
		lwz	r29,0(r1)
		lwz	r0,0(r29)
		stwu	r0,4(r3)		#r1
		stwu	r2,4(r3)
		lwz	r0,12(r31)		#r3
		stwu	r0,4(r3)
		stwu	r4,4(r3)
		stwu	r5,4(r3)
		stwu	r6,4(r3)
		stwu	r7,4(r3)
		stwu	r8,4(r3)
		stwu	r9,4(r3)
		stwu	r10,4(r3)
		stwu	r11,4(r3)
		stwu	r12,4(r3)
		lwz	r2,0(r1)
		lwz	r0,-4(r2)		
		stwu	r0,4(r3)		#r13
		stwu	r14,4(r3)
		stwu	r15,4(r3)
		stwu	r16,4(r3)
		stwu	r17,4(r3)
		stwu	r18,4(r3)
		stwu	r19,4(r3)
		stwu	r20,4(r3)
		stwu	r21,4(r3)
		stwu	r22,4(r3)
		stwu	r23,4(r3)
		stwu	r24,4(r3)
		stwu	r25,4(r3)
		stwu	r26,4(r3)
		lwz	r0,16(r31)
		stwu	r0,4(r3)		#r27
		lwz	r0,20(r31)
		stwu	r0,4(r3)		#r28
		lwz	r0,24(r31)
		stwu	r0,4(r3)		#r29
		lwz	r0,28(r31)
		stwu	r0,4(r3)		#r30
		lwz	r0,32(r31)
		stwu	r0,4(r3)		#r31
		stfdu	f0,4(r3)
		stfdu	f1,8(r3)
		stfdu	f2,8(r3)
		stfdu	f3,8(r3)
		stfdu	f4,8(r3)
		stfdu	f5,8(r3)
		stfdu	f6,8(r3)
		stfdu	f7,8(r3)
		stfdu	f8,8(r3)
		stfdu	f9,8(r3)
		stfdu	f10,8(r3)
		stfdu	f11,8(r3)
		stfdu	f12,8(r3)
		stfdu	f13,8(r3)
		stfdu	f14,8(r3)
		stfdu	f15,8(r3)		
		stfdu	f16,8(r3)
		stfdu	f17,8(r3)
		stfdu	f18,8(r3)
		stfdu	f19,8(r3)
		stfdu	f20,8(r3)
		stfdu	f21,8(r3)
		stfdu	f22,8(r3)
		stfdu	f23,8(r3)
		stfdu	f24,8(r3)
		stfdu	f25,8(r3)
		stfdu	f26,8(r3)
		stfdu	f27,8(r3)
		stfdu	f28,8(r3)
		stfdu	f29,8(r3)
		stfdu	f30,8(r3)
		stfdu	f31,8(r3)

		mr	r3,r13
		mtsprg3	r3

		lwz	r2,EXCDATA_DATA(r30)

		blrl

		mfsprg3	r31

		lwzu	r0,4(r31)		#Skips Exc type
		mtsrr0	r0
		lwzu	r0,4(r31)
		mtsrr1	r0
		lwzu	r0,4(r31)
		mtdar	r0
		lwzu	r0,4(r31)
		mtdsisr	r0		
		lwzu	r0,4(r31)
		mtcr	r0
		lwzu	r0,4(r31)
		mtctr	r0
		lwzu	r0,4(r31)
		mtlr	r0
		lwzu	r0,4(r31)
		mtxer	r0
		lfd	f0,0(r31)
		mtfsf	0xff,f0
		lwzu	r0,8(r31)
		lwzu	r2,4(r31)
		mtsprg1	r2			#(New) User stack pointer
		lwzu	r2,4(r31)
		mtsprg2	r3
		lwzu	r3,4(r31)
		lwzu	r4,4(r31)
		lwzu	r5,4(r31)
		lwzu	r6,4(r31)
		lwzu	r7,4(r31)
		lwzu	r8,4(r31)
		lwzu	r9,4(r31)
		lwzu	r10,4(r31)
		lwzu	r11,4(r31)
		lwzu	r12,4(r31)
		lwzu	r13,4(r31)
		lwzu	r14,4(r31)
		lwzu	r15,4(r31)
		lwzu	r16,4(r31)
		lwzu	r17,4(r31)
		lwzu	r18,4(r31)
		lwzu	r19,4(r31)
		lwzu	r20,4(r31)
		lwzu	r21,4(r31)
		lwzu	r22,4(r31)
		lwzu	r23,4(r31)
		lwzu	r24,4(r31)
		lwzu	r25,4(r31)
		lwzu	r26,4(r31)
		lwzu	r27,4(r31)
		lwzu	r28,4(r31)
		lwzu	r29,4(r31)
		lwz	r30,8(r31)
		mtsprg3	r30
		lwzu	r30,4(r31)
		lfdu	f0,8(r31)		#skips r31 (is in sprg3)
		lfdu	f1,8(r31)
		lfdu	f2,8(r31)
		lfdu	f3,8(r31)
		lfdu	f4,8(r31)
		lfdu	f5,8(r31)
		lfdu	f6,8(r31)
		lfdu	f7,8(r31)
		lfdu	f8,8(r31)
		lfdu	f9,8(r31)
		lfdu	f10,8(r31)
		lfdu	f11,8(r31)
		lfdu	f12,8(r31)
		lfdu	f13,8(r31)
		lfdu	f14,8(r31)
		lfdu	f15,8(r31)
		lfdu	f16,8(r31)
		lfdu	f17,8(r31)
		lfdu	f18,8(r31)
		lfdu	f19,8(r31)
		lfdu	f20,8(r31)
		lfdu	f21,8(r31)
		lfdu	f22,8(r31)
		lfdu	f23,8(r31)
		lfdu	f24,8(r31)
		lfdu	f25,8(r31)
		lfdu	f26,8(r31)
		lfdu	f27,8(r31)
		lfdu	f28,8(r31)
		lfdu	f29,8(r31)
		lfdu	f30,8(r31)
		lfdu	f31,8(r31)
		
		mfsprg3	r31
		
		stw	r13,-4(r1)
		subi	r13,r1,4				
		stwu	r31,-4(r13)
		stwu	r30,-4(r13)
		stwu	r29,-4(r13)
		stwu	r28,-4(r13)
		stwu	r27,-4(r13)
		stwu	r3,-4(r13)
		stwu	r2,-4(r13)
		stwu	r0,-4(r13)
		mfcr	r0
		stwu	r0,-4(r13)

		mfsprg1	r3
		lwz	r31,0(r1)
		stw	r3,0(r31)		#Change User Stack

		mfsprg2	r3
		mfsprg0	r31

		cmpwi	r3,EXCRETURN_ABORT
		beq	.LastPrHandler		
		
		b	.NextPExc
		
.LastPrHandler:	lwz	r0,4(r13)
		mtsprg0	r0
		b	.WasTrap

.Privvy:	addi	r31,r31,4			#Next instruction
		mtsrr0	r31
		mfsrr1	r31
		
		ori	r31,r31,PSL_PR			#Set to Super
		xori	r31,r31,PSL_PR
		mtsrr1	r31

		li	r0,0				#SuperKey
		mtsprg0	r0

.WasTrap:	lwz	r0,0(r13)
		mtcr	r0
		lwz	r0,4(r13)
		lwz	r2,8(r13)
		lwz	r3,12(r13)
		lwz	r27,16(r13)
		lwz	r28,20(r13)
		lwz	r29,24(r13)
		lwz	r30,28(r13)
		lwz	r31,32(r13)
		addi	r13,r13,36

		lwz	r1,0(r1)
		lwz	r13,-4(r1)
		lwz	r1,0(r1)			#User stack restored
		
		li	r0,0
		stb	r0,ExceptionMode(r0)

		loadreg	r0,"USER"
		stw	r0,0xf4(r0)
		
		mfspr	r0,HID0
		ori	r0,r0,HID0_ICFI
		mtspr	HID0,r0
		isync
		
		mfsprg0	r0
		
		rfi
		
.HaltErr:	loadreg r3,"HALT"			#DEBUG
		stw	r3,0xf4(r0)			#Error
		mfsrr0	r3
		stw	r3,0xf8(r0)			#Current PC
		mflr	r3
		stw	r3,0xfc(r0)			#Original calling function

.xxHaltErr2:	b .xxHaltErr2
		
#********************************************************************************************
	
EIntEnd:
		mflr	r4				#Setup a small jumptable for exceptions
		loadreg r5,0x48002b28
		stw	r5,0x500(r0)			#External Interrupt
		loadreg	r5,0x48002424
		stw	r5,0xc00(r0)			#System Call
		loadreg	r5,0x48002e20
		stw	r5,0x200(r0)			#Machine Check
		loadreg	r5,0x4800291c
		stw	r5,0x700(r0)			#Program/Trap/Illegal
		loadreg r5,0x48002718
		stw	r5,0x900(r0)			#Decrementer
		loadreg	r5,0x48001d14
		stw	r5,0x1300(r0)			#Instruction Address Breakpoint
		loadreg	r5,0x48002310
		stw	r5,0xd00(r0)			#Trace
		loadreg	r5,0x48002d0c
		stw	r5,0x300(r0)			#DSI
		loadreg	r5,0x48002c08
		stw	r5,0x400(r0)			#ISI
		loadreg	r5,0x48002a04
		stw	r5,0x600(r0)			#Alignment
		loadreg	r5,0x48002800
		stw	r5,0x800(r0)			#FP Unavailable
	
		li	r3,0x3000			#Jump from Exception immediatly to 0x3000
		li	r5,EIntEnd-EInt
		li	r6,0
		bl	copy_and_flush
		mtlr	r15
		blr

#********************************************************************************************
PPCEnd:
