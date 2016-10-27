.include ppcdefines.i
.include sonnet_libppc.i
.include ppcmacros-std.i

.global PPCCode,PPCLen,RunningTask,LIST_WAITINGTASKS,Init,ViolationAddress
.global MCPort,SysBase,PowerPCBase,DOSBase,DebugLevel

.set	PPCLen,(PPCEnd-PPCCode)

#********************************************************************************************

.section "PPCSetup","acrx"

PPCCode:	b	.SkipCom			#0x3000	System initialization

.long		0					#Used for initial communication
.long		0					#MemStart
.long		0					#MemLen
.long		0					#RTGBase
.long		0					#RTGType

.SkipCom:	
		lis	r22,CMD_BASE			#Used in setpcireg macro
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

		mr.	r8,r8
		bne	.GotRam

.ErrorRam:	loadreg	r0,'Err2'
		stw	r0,4(r29)
		b	.ErrorRam

.GotRam:	lhz	r3,20(r29)
		cmpwi	r3,0x1002			#Check for ATI Gfx Card
		beq	.MaxRam
		cmpwi	r3,0x121b			#Check for VooDoo4/5
		bne	.NoMaxRam	

.MaxRam:	lis	r4,0x800			#Max 128MB RAM on Sonnet when ATI present
		cmplw	r8,r4
		ble	.NoMaxRam

		mr	r8,r4	

.NoMaxRam:	lis	r27,0x8000			#Upper boundary PCI Memory Mediator
		lwz	r26,16(r29)			#Get gfx mem
		cmplw	r26,r27
		blt	.ZorroX				#Is Zorro3
		lis	r27,0x9000			#Zorro2 plus 256MB ATI
		cmplw	r26,r27
		beq	.ZorroX
		lis	r27,0x9800			#Zorro2 plus 128MB (or less) ATI
		
.ZorroX:	mr	r26,r8

		li	r28,17
		mtctr	r28
		li	r28,1
		li	r25,29

Loop1:		slw.	r26,r26,r28
		blt	Fndbit
		addi	r25,r25,-1
		bdnz	Loop1
		b	.IdleLoop

Fndbit:		slw.	r26,r26,r28
		beq	SetLen
		addi	r25,r25,1

SetLen:		mr	r30,r28
		slw	r30,r30,r25
		slw	r30,r30,r28
		subf	r27,r30,r27
		lis	r26,EUMB
		ori	r26,r26,ITWR
		stwbrx	r25,0,r26			#Set size of Inbound Translate Window
		sync

		setpcireg LMBAR
		mr	r25,r27
		ori	r25,r25,8			#Set LMBAR to Base of memory plus size
		bl	ConfigWrite32

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

		stw	r27,8(r29)			#MemStart
		stw	r8,12(r29)			#MemLen

		bl	mmuSetup			#Setup the Memory Management Unit
		bl	Epic				#Setup the EPIC controller
		bl	End

Start:		loadreg	r0,'REDY'			#Dummy entry at absolute 0x8400
		stw	r0,Init(r0)
.IdleLoop:	nop					#IdleTask
		nop
		nop
		b	.IdleLoop

End:		mflr	r4
		
		li	r14,0				#Reset
		mtspr	285,r14				#Time Base Upper,
		mtspr	284,r14				#Time Base Lower and
		loadreg r28,0x7fffffff
		mtdec	r28				#Decrementer.

		lwz	r28,0(r14)
		stw	r14,Atomic(r0)
		stw	r28,4(r29)			#Signal 68k that PPC is initialized

		loadreg r6,'INIT'
.WInit:		lwz	r28,Init(r0)
		cmplw	r28,r6
		bne	.WInit
		
		isync					#Wait for 68k to set up library

		loadreg	r3,IdleTask			#Start hardcoded at 0x8400
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
				
		lwz	r3,PowerPCBase(r0)
		
		la	r4,LIST_WAITINGTASKS-4(r3)
		li	r5,600/4
		li	r6,0
		mtctr	r5
		
.ClearBase:	stwu	r6,4(r4)
		bdnz	.ClearBase
		
		la	r4,LIST_READYTASKS(r3)
		bl	.MakeList
		
		la	r4,LIST_WAITINGTASKS(r3)
		bl	.MakeList
		
		la	r4,LIST_NEWTASKS(r3)
		bl	.MakeList

		la	r4,LIST_SEMAPHORES(r3)
		bl	.MakeList

		la	r4,LIST_PORTS(r3)
		bl	.MakeList

		la	r4,LIST_SNOOP(r3)
		bl	.MakeList

		la	r4,LIST_ALLTASKS(r3)
		bl	.MakeList

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

		la	r4,LIST_EXCSYSMAN(r3)
		bl	.MakeList

		la	r4,LIST_EXCTHERMAN(r3)
		bl	.MakeList
		
		la	r4,LIST_EXCINTERRUPT(r3)
		bl	.MakeList
		
		la	r4,LIST_WAITTIME(r3)
		bl	.MakeList
		
		la	r4,LIST_MSGQUEUE(r3)
		bl	.MakeList

		li	r6,100				#Insert default values here
		stw	r6,IdDefTasks(r3)
		li	r6,24
		stb	r6,BusyCounter(r3)
		li	r6,6000
		stw	r6,LowActivityPrio(r3)

		loadreg	r3,0x8000			#Put Semaphores at 0x8000
		addi	r6,r3,0x200			#Put Semaphores memory at 0x8200
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
		
		loadreg	r0,MACHINESTATE_DEFAULT
		mtsrr1	r0				#load up user MSR. Also clears PSL_IP
		
		lwz	r4,PowerPCBase(r0)
		lwz	r4,_LVOSetCache+2(r4)
		addi	r6,r4,ViolationOS		
		stw	r6,ViolationAddress(r0)
		addi	r6,r4,TaskExit
		stw	r6,TaskExitCode(r0)
		addi	r6,r4,TaskStart
		stw	r6,RunPPCStart(r0)

		bl	Caches				#Setup the L1 and L2 cache

		loadreg	r4,QuickQuantum
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

Caches:		mfspr	r4,HID0				#Invalidatem then enable L1 caches
		ori	r4,r4,HID0_ICFI|HID0_DCFI
		mtspr	HID0,r4
		sync
		
#		blr					#REMOVE ME FOR L1 CACHE

		mfspr	r4,HID0
		ori	r4,r4,HID0_ICE|HID0_DCE|HID0_SGE|HID0_BTIC|HID0_BHTE
		sync
		mtspr	HID0,r4
		sync
		 	
#		blr					#REMOVE ME FOR L2 CACHE		

		loadreg r4,L2CR_L2SIZ_1M|L2CR_L2CLK_3|L2CR_L2RAM_BURST|L2CR_TS|L2CR_DO
		mtl2cr	r4				# Set up on chip L2 cache controller.
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
		
		lis	r3,EUMB					#PCI memory (EUMB) start effective address
		addis	r4,r3,0x10				#end effective address
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
		
		lhz	r3,RTGType(r0)
		cmpwi	r3,0x1002
		bne	.DoInhibit
		loadreg	r6,PTE_WRITE_THROUGH
		b	.DoWT

.DoInhibit:	loadreg	r6,PTE_CACHE_INHIBITED		
.DoWT:		cmpwi	r3,0x121b
		lwz	r3,RTGBase(r0)			#32MB Video RAM (ATi) or Config (Avenger)
		addis	r4,r3,0x200
		bne	.Voodoo3
		addis	r4,r4,0x600
.Voodoo3:	mr	r24,r4
		addis	r5,r3,0x4000
		li	r7,2
		
		bl	.DoTBLs
		
		lhz	r3,RTGType(r0)
		cmpwi	r3,0x121a
		beq	.Is3DFX
		cmpwi	r3,0x121b
		bne	.No3DFX
		
		lwz	r3,RTGBase(r0)			#32MB Video RAM (Napalm)
		addis	r3,r3,0x800
		addis	r4,r3,0x200
		addis	r5,r3,0x4000
		loadreg	r6,PTE_WRITE_THROUGH
		li	r7,2
		
		bl	.DoTBLs
		
		b	.No3DFX
		
.Is3DFX:	lwz	r3,RTGBase(r0)			#32MB Video RAM (Avenger)
		addis	r3,r3,0x200
		addis	r4,r3,0x200
		addis	r5,r3,0x4000
		loadreg	r6,PTE_WRITE_THROUGH
		li	r7,2
		
		bl	.DoTBLs
		
.No3DFX:	lhz	r3,RTGType(r0)
		cmpwi	r3,0x1002
		bne	.NoATI
		mr	r3,r24
		addis	r5,r3,0x4000
		mr	r4,r3
		addis	r4,r4,0xf00			#256-32MB max Video RAM (ATI)
		li	r6,0
		li	r7,2
		
		bl	.DoTBLs		
		
.NoATI:		li	r3,0				#Zeropage (4K no cache)
		li	r4,0x1000
		mr	r5,r3
		loadreg	r6,PTE_CACHE_INHIBITED
		li	r7,2				#pp = 2 - Read/Write Access
		
		bl	.DoTBLs						
		
		li	r3,0x1000			#Exception code (16K cached)
		loadreg	r4,0x8000
		mr	r5,r3
		li	r6,r0
		li	r7,0				#pp = 0 - Supervisor access only.
							#Otherwise DSI/ISI (e.g. CHIP access)
		bl	.DoTBLs
		
		loadreg	r3,0x100000			#Message FIFOs (64k no cache)
		loadreg	r4,0x110000
		mr	r5,r3
		li	r6,PTE_CACHE_INHIBITED
		li	r7,0				#pp = 0 - Supervisor access only.
							#Otherwise DSI/ISI (e.g. CHIP access)
		bl	.DoTBLs
		
		loadreg	r3,0x110000			#Message (1.5MB no cache)
		loadreg	r4,0x290000
		mr	r5,r3
		or	r3,r3,r27
		or	r4,r4,r27
		li	r6,PTE_CACHE_INHIBITED
		li	r7,2
		
		bl	.DoTBLs

		
		loadreg	r3,0x8000			#First free block (~1MB cached)
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

		lis	r8,0x2000			#set ks and kp (0x6000 = 11; 0x4000 = 10 etc.)
.srx_set:	or	r5,r3,r8

		rlwinm	r13,r3,28,0,4
		mtsrin	r5,r13

		addi	r3,r3,1
		cmplw	r3,r4
		ble	.srx_set

		mr	r3,r17
		mr	r4,r18
		
.load_PTEs:	cmplw	r3,r4
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

.ExitTBLErr:	loadreg	r0,'Err1'
		stw	r0,4(r29)
		loadreg	r0,'TBL!'
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
		loadreg	r25,0x0002a29c		#0x2A29C  0101 010 001 010 011 100,	
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
		loadreg	r25,0xe0001040	
		bl	ConfigWrite32		#set MCCR2 to 0xE0001040
						#MCCR2 Memory Control Config Reg   = 0xe0001040
						#    Read Modify Write parity      = 0x0 Disabled
						#    RSV_PG Reserve one open page  = 0x0 Four open page mode
						#    Refresh Interval              = 0x0208 = 520 decimal (is actually 0x410...)
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
		loadreg r4,'Boon'		#0x426F6F6E -> "Boon"
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
		mr	r25,r5
		bl	ConfigWrite8		#enable Bank 0

		stw	r4,0(r3)		#try to store "Boon" at address 0x0
		eieio
	
		stw	r3,4(r3)		#try to store 0x0 at 0x4
		eieio
		lwz	r7,0(r3)		#read from 0x0
		cmplw	r4,r7			#is it "Boon", long compare
		bne	loc_4184
	
		or	r14,r14,r5		#continue if found
	
		setpcireg MCCR1			#0x800000f0
		loadreg r25,0xffeaffff
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
		b	.PerfMon			#28
		b	.SysMan				#2c
		b	.TherMan			#30

		mtsprg2	r0				#34
		
		mfsrr1	r0
		mtsprg1	r0
		mfsrr0	r0
		mtsprg0	r0

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0				#Reenable MMU (can affect srr0/srr1 acc Docs)
		isync					#Also reenable FPU
		sync

		li	r0,-1
		stb	r0,ExceptionMode(r0)

		mtsprg3	r1				
		lwz	r0,SonnetBase(r0)		#Store user stack pointer
		loadreg	r1,SysStack-0x20		#System stack in unused mem (See sonnet.s)
		or	r1,r1,r0
		mfsprg3 r0
		stwu	r0,-4(r1)
		
		mfxer	r0
		mtsprg3	r0

		prolog	228,'TOC'
		
		bl	.TaskStats

		stwu	r3,-4(r13)
		stwu	r4,-4(r13)
		stwu 	r5,-4(r13)
		stwu	r6,-4(r13)
		stwu	r7,-4(r13)
		stwu	r8,-4(r13)
		stwu	r9,-4(r13)

		loadreg	r3,'EXEX'
		stw	r3,0xf4(r0)

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
		sync		
		mr	r5,r9
	
.CheckQueue:	andi.	r9,r5,IMISR_IPQI
		beq	.EndQueue
		
		li	r5,IMISR_IPQI			#Clear IPQI bit to clear interrupt
		stwbrx	r5,r4,r3		
		sync

		li	r4,IPHPR			
		lwbrx	r9,r4,r3
		li	r4,IPTPR			#Get message from Inbound FIFO
		lwbrx	r5,r4,r3		
		cmpw	r5,r9				#Check if interrupt was triggered

		beq	.QEmpty				#during previous interrupt

.QNotEmpty:	addi	r9,r5,4				#Increase FIFO pointer
		loadreg	r4,0x4000
		or	r9,r9,r4
		loadreg r4,0xffff7fff
		and	r9,r9,r4			#Keep it 4000-7FFE		
		sync
		lwz	r5,0(r5)

		lwz	r3,PowerPCBase(r0)
		la	r4,LIST_MSGQUEUE(r3)
		addi	r4,r4,4				#PutMsg r5 to queue
		lwz	r3,4(r4)			#AddTailPPC
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
		
		lis	r3,EUMB				#Check if header (IPHPR) is equal to
		li	r4,IPHPR			#tail (IPTPR). If so, queue is empty
		lwbrx	r5,r4,r3
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

#**********************************************************


.StartQ:	lwz	r3,PowerPCBase(r0)
		la	r4,LIST_MSGQUEUE(r3)
		lwz	r5,0(r4)
.NxtInQ:	lwz	r9,0(r5)			#get next message
		mr.	r9,r9
		beq-	.EndMsgQueue

		loadreg	r4,'TPPC'
		lwz	r6,MN_IDENTIFIER(r5)
		cmpw	r4,r6				#A RunPPC request
		beq	.MsgTPPC
		
		loadreg	r4,'LLPP'			#Cross-signaling
		cmpw	r4,r6
		beq	.XSignal
	
		loadreg	r4,'XMSG'			#Reply (7) from XMSG from 68K
		cmpw	r4,r6
		beq 	.ReturnXMsg

		loadreg	r4,'XPPC'			#Message (5) from 68K
		cmpw	r4,r6
		beq	.XMsgPPC
		
		loadreg	r4,'DONE'			#Reply from Run68K
		cmpw	r4,r6
		beq	.Done68
		
		loadreg	r4,'END!'
		cmpw	r4,r6
		beq	.Done68
		
		loadreg	r4,'DNLL'			#Reply from Run68KLowLevel
		cmpw	r4,r6
		beq	.Done68
		
		loadreg	r4,'STCK'
		cmpw	r4,r6
		beq	.RemNode			#Leave it to be released by PPC task

		b	.RelFrame
		
#**********************************************************

.XSignal:	lwz	r3,KrytenTask(r0)
		lwz	r4,TASKPPC_MSGPORT(r3)
		addi	r6,r4,MP_PPC_SEM
		lha	r8,SS_QUEUECOUNT(r6)
		extsh.	r0,r8
		beq	.Oopsie

		lwz	r6,RunningTask(r0)
		cmpw	r6,r3
		li	r7,TS_RUN
		beq	.IsXRunning

		li	r7,TS_READY
.IsXRunning:	stb	r7,TC_STATE(r3)

		lbz	r6,MP_SIGBIT(r4)
		li	r8,1
		slw	r8,r8,r6		
		addi	r6,r4,MP_MSGLIST
		lwz	r0,TC_SIGRECVD(r3)
		or	r0,r0,r8
		stw	r0,TC_SIGRECVD(r3)
		mr	r4,r5

		lwz	r3,0(r4)			#RemovePPC
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)

		addi	r4,r6,4				#PutMsg r5 to Kryten
		lwz	r3,4(r4)			#AddTailPPC
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)

		mr	r5,r9
		b	.NxtInQ

#**********************************************************	

.RelFrame:	mr	r4,r5
		lwz	r3,0(r4)			#RemovePPC
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)
	
		lis	r3,EUMB				#Free the message
		li	r4,IFHPR
		lwbrx	r6,r4,r3		
		stw	r5,0(r6)		
		addi	r8,r6,4
		loadreg	r7,0x3fff
		and	r8,r8,r7			#Keep it 0000-3FFE
		stwbrx	r8,r4,r3

.Oopsie:	mr	r5,r9
		b	.NxtInQ
		
#**********************************************************

.RemNode:	mr	r4,r5
		lwz	r3,0(r4)			#RemovePPC
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)
		
		mr	r5,r9
		b	.NxtInQ
		
#**********************************************************		
		
.ReturnXMsg:	lwz	r4,MN_REPLYPORT(r5)		#Handles the reply from an XMSG
		addi	r6,r4,MP_PPC_SEM
		lha	r8,SS_QUEUECOUNT(r6)
		extsh.	r0,r8
		beq	.Oopsie

		addi	r7,r5,32			#(or a cross message from PPC to 68K)
		stw	r4,MN_REPLYPORT(r7)
		lwz	r8,MN_PPC(r5)		
		li	r4,NT_REPLYMSG
		stb	r4,LN_TYPE(r7)
		lhz	r4,MN_LENGTH(r7)
		mfctr	r3
		mtctr	r4
		
		subi	r8,r8,1
		subi	r7,r7,1
.CopyXBack:	lbzu	r6,1(r7)
		stbu	r6,1(r8)
		bdnz	.CopyXBack
		mtctr	r3
				
		lwz	r7,MN_PPC(r5)

		mr	r4,r5
		lwz	r3,0(r4)			#RemovePPC
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)

		lis	r3,EUMB				#Free the message
		li	r4,IFHPR
		lwbrx	r6,r4,r3		
		stw	r5,0(r6)		
		addi	r8,r6,4
		loadreg	r6,0x3fff			#ffff3fff?
		and	r8,r8,r6			#Keep it 0000-3FFE
		stwbrx	r8,r4,r3
		sync
		
		mr	r5,r7
		lwz	r4,MN_REPLYPORT(r5)
		lwz	r3,MP_SIGTASK(r4)
		mr.	r3,r3
		beq	.Oopsie
		
		lwz	r6,RunningTask(r0)
		cmpw	r6,r3
		li	r6,TS_READY
		bne	.MakeReady		
		li	r6,TS_RUN
.MakeReady:	stb	r6,TC_STATE(r3)		
		b	.PutMsgIt

#**********************************************************
		
.XMsgPPC:	lwz	r4,MN_PPC(r5)			#Handles a cross message from 68K to PPC)
		addi	r6,r4,MP_PPC_SEM
		lha	r8,SS_QUEUECOUNT(r6)
		extsh.	r0,r8
		beq	.Oopsie

		lwz	r3,MP_SIGTASK(r4)
		mr.	r3,r3
		beq	.RelFrame
		mr	r7,r3

		mr	r6,r4
		mr	r4,r5
		lwz	r3,0(r4)			#RemovePPC
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)

		mr	r3,r7
		mr	r4,r6
		la	r5,MN_PPSTRUCT(r5)		#PutMsg it to correct PPC task
		b	.PutMsgIt			#Go to signalling code

#**********************************************************
		
.Done68:	lwz	r4,MN_PPC(r5)			#Handles the reply on a Run68K
		lwz	r6,TASKPPC_MSGPORT(r4)
		addi	r6,r6,MP_PPC_SEM
		lha	r8,SS_QUEUECOUNT(r6)
		extsh.	r0,r8
		beq	.Oopsie

		mr	r6,r4
		mr	r4,r5
		lwz	r3,0(r4)			#RemovePPC
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)

		mr	r4,r6
		lwz	r6,RunningTask(r0)
		cmpw	r6,r4
		li	r3,TS_RUN
		beq	.IsRunning
		
		li	r3,TS_READY
.IsRunning:	stb	r3,TC_STATE(r4)		
		mr	r3,r4				
		lwz	r4,TASKPPC_MSGPORT(r3)
		
.PutMsgIt:	lbz	r6,MP_SIGBIT(r4)
		li	r8,1
		slw	r8,r8,r6		
		addi	r4,r4,MP_MSGLIST						
		lwz	r0,TC_SIGRECVD(r3)
		or	r0,r0,r8
		stw	r0,TC_SIGRECVD(r3)
		
		lwz	r0,MN_IDENTIFIER(r5)
		loadreg	r6,'DONE'
		cmpw	r6,r0
		bne	.NoSigUpdate
		
		lwz	r8,MN_ARG1(r5)
		stw	r8,TC_SIGALLOC(r3)
				
.NoSigUpdate:	addi	r4,r4,4				#PutMsg r5 to currenttask
		lwz	r3,4(r4)			#AddTailPPC
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
			
		mr	r5,r9						
		b	.NxtInQ

#**********************************************************
		
.MsgTPPC:	lwz	r4,MN_PPC(r5)
		mr.	r4,r4
		bne	.Done68
		
		lwz	r4,PowerPCBase(r0)		#Handles a RunPPC
		la	r6,LIST_NEWTASKS(r4)

		mr	r4,r5
		lwz	r3,0(r4)			#RemovePPC
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)
		
		addi	r4,r6,4				#AddTailPPC
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
		
		mr	r5,r9
		b	.NxtInQ

#**********************************************************

.EndMsgQueue:	lwz	r9,Atomic(r0)
		cmpwi	r9,-1
		beq	.ReturnToUser

		lwz	r9,RunningTask(r0)
		mr.	r9,r9
		beq	.NoAtomicTask
		lbz	r9,TC_STATE(r9)
		cmpwi	r9,TS_ATOMIC
		beq	.ReturnToUser

.NoAtomicTask:	lwz	r9,TaskException(r0)
		mr.	r9,r9
		bne	.TaskException

		lwz	r4,PowerPCBase(r0)		
		lbz	r5,FLAG_WAIT(r4)
		mr.	r5,r5
		bne	.NoWaitTime
		
		la	r4,LIST_WAITTIME(r4)
		lwz	r4,MLH_HEAD(r4)
.NextWaitList:	lwz	r5,LN_SUCC(r4)

		mr.	r5,r5
		beq	.NoWaitTime

		mftbu	r9
		lwz	r6,WAITTIME_TIME1(r4)
		cmplw	r6,r9		
		bgt	.NotDoneYet
		blt	.DoneWaiting
		
		mftbl	r9
		lwz	r6,WAITTIME_TIME2(r4)
		cmplw	r6,r9		
		bgt	.NotDoneYet
								
.DoneWaiting:	lwz	r6,WAITTIME_TASK(r4)		
		lwz	r9,RunningTask(r0)
		cmpw	r6,r9
		li	r9,TS_RUN
		beq	.SetSig

		li	r9,TS_READY
.SetSig:	stb	r9,TC_STATE(r6)	
		lwz	r9,TC_SIGRECVD(r6)
		ori	r9,r9,SIGF_WAIT
		stw	r9,TC_SIGRECVD(r6)
		
		lwz	r3,0(r4)			#RemovePPC
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)
	
.NotDoneYet:	mr	r4,r5

		b	.NextWaitList

.NoWaitTime:	li	r9,TS_READY
		lwz	r4,PowerPCBase(r0)
		la	r4,LIST_WAITINGTASKS(r4)
		lwz	r4,MLH_HEAD(r4)
.NextOnList:	lwz	r5,LN_SUCC(r4)
		mr.	r5,r5
		beq	.EndOfWaitList

		lbz	r6,TC_STATE(r4)
		cmpw	r9,r6
		beq	.GotOneWait

		lwz	r6,TC_SIGWAIT(r4)
		lwz	r7,TC_SIGRECVD(r4)
		and.	r0,r7,r6
		beq	.NoSigsRecvd

		stb	r9,TC_STATE(r4)
		b	.GotOneWait

.NoSigsRecvd:	mr	r4,r5		
		b	.NextOnList

.GotOneWait:	mr	r6,r4
		mr	r7,r5
		
		lwz	r3,0(r4)			#RemovePPC
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)
				
		mr	r5,r6
		lwz	r4,PowerPCBase(r0)
		la	r4,LIST_READYTASKS(r4)
		
		addi	r4,r4,4				#AddTailPPC
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)

		mr	r4,r7

		b	.NextOnList

.EndOfWaitList:	lwz	r9,RunningTask(r0)

		b	.TrySwitch
		
.Dispatch:	lwz	r8,MN_ARG0(r9)
		lwz	r31,PowerPCBase(r0)
		lwz	r4,IdDefTasks(r31)
		addi	r4,r4,1
		stw	r4,IdDefTasks(r31)
		stw	r4,TASKPPC_ID(r8)
		stw	r31,TASKPPC_POWERPCBASE(r8)		
		li	r4,TS_RUN
		stb	r4,TC_STATE(r8)
		li	r4,NT_PPCTASK
		stb	r4,LN_TYPE(r8)
		la	r4,TASKPPC_CTMEM(r8)
		stw	r4,TASKPPC_CONTEXTMEM(r8)
		lwz	r31,MN_ARG2(r9)
		stw	r31,TASKPPC_MIRROR68K(r8)
		lwz	r31,MN_MIRROR(r9)
		stw	r31,TASKPPC_MIRRORPORT(r8)		
		la	r31,TASKPPC_NAME(r8)
		stw	r31,LN_NAME(r8)
		lwz	r31,MN_ARG1(r9)
		stw	r31,TASKPPC_STACKSIZE(r8)
		addi	r4,r8,2048		
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
		stwu	r1,-1024(r1)		
		
		lwz	r6,RunPPCStart(r0)
		mtsprg0	r6

 		lwz	r0,MN_STARTALLOC(r9)
		stw	r0,TC_SIGALLOC(r8)
		stw	r0,MN_ARG1(r9)

		la	r6,TASKPPC_PORT(r8)
		bl	.IntCrMsgPort

		stw	r6,TASKPPC_MSGPORT(r8)
		stw	r8,RunningTask(r0)

		la	r5,TASKPPC_ALLTASK(r8)
		stw	r8,TASKPTR_TASK(r5)		
		stw	r5,TASKPPC_TASKPTR(r8)
		lwz	r3,LN_NAME(r8)			#Copy Name pointer 
		stw	r3,LN_NAME(r5)
		
		lwz	r4,PowerPCBase(r0)
		addi	r4,r4,LIST_ALLTASKS

		addi	r4,r4,4				#AddTailPPC
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)

		lwz	r30,PowerPCBase(r0)		#Tasks +1
		li	r0,0
		la	r4,NumAllTasks(r30)
		lwz	r3,0(r4)
		addi	r3,r3,1
		stw	r3,0(r4)
		stb	r0,PortInUse(r30)
		dcbst	r0,r4

		loadreg	r0,MACHINESTATE_DEFAULT
		mtsrr1	r0		
		mfsprg0	r0
		mtsrr0	r0

		mfspr	r0,HID0
		ori	r0,r0,HID0_ICFI
		isync
		mtspr	HID0,r0
		isync

		li	r0,0
		stb	r0,ExceptionMode(r0)

		mr	r30,r9

		loadreg	r0,Quantum
		mtdec	r0
		
		nop
		
		rfi
		
#********************************************************************************************	

.IntCrMsgPort:		
		addi	r4,r6,MP_PPC_INTMSG		#Setup a Semaphore & MsgPort
		stw	r4,LH_TAILPRED(r4) 
		li	r0,0 
		stwu	r0,LH_TAIL(r4) 
		stwu	r4,LH_HEAD-4(r4) 

		addi	r4,r6,MP_MSGLIST
		stw	r4,LH_TAILPRED(r4) 
		li	r0,0 
		stwu	r0,LH_TAIL(r4) 
		stwu	r4,LH_HEAD-4(r4) 

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

		blr

#********************************************************************************************
		
.ReturnToUser:		
		lwz	r9,0xf0(r0)				#Debug counter to check
		addi	r9,r9,1					#Whether exception is still
		stw	r9,0xf0(r0)				#running
		li	r0,0
		lwz	r9,PowerPCBase(r0)
		stb	r0,PortInUse(r9)

		lwz	r9,0(r13)
		lwzu	r8,4(r13)
		lwzu	r7,4(r13)
		lwzu	r6,4(r13)
		lwzu	r5,4(r13)
		lwzu	r4,4(r13)
		lwzu	r3,4(r13)
		addi	r13,r13,4
	
		excepilog 'TOC'

		lwz	r1,0(r1)				#Restore user stack

		mfsprg3	r0
		mtxer	r0
		mfsprg1 r0
		mtsrr1	r0
		mfsprg0	r0
		mtsrr0	r0

		li	r0,0
		stb	r0,ExceptionMode(r0)

		loadreg	r0,'USER'
		stw	r0,0xf4(r0)
		
		mfspr	r0,HID0
		ori	r0,r0,HID0_ICFI
		isync
		mtspr	HID0,r0
		isync

		loadreg	r0,Quantum
		mtdec	r0
		
		mfsprg2	r0

		rfi
	
#********************************************************************************************

.TaskStats:		
		stwu	r2,-4(r13)
		stwu	r3,-4(r13)
		stwu	r4,-4(r13)
		stwu	r5,-4(r13)
		stwu	r6,-4(r13)
		stwu	r7,-4(r13)
		stwu	r8,-4(r13)
		stwu	r9,-4(r13)
		stwu	r10,-4(r13)
		stwu	r11,-4(r13)
		stwu	r12,-4(r13)
		stwu	r14,-4(r13)
		stwu	r28,-4(r13)
		stwu	r29,-4(r13)
		stwu	r31,-4(r13)		

		loadreg	r3,'STAT'
		stw	r3,0xf4(r0)

		mftbl	r3
		lwz	r2,PowerPCBase(r0)		
		lwz	r5,CurrentTBL(r2)
		stw	r3,CurrentTBL(r2)

		mr.	r5,r5
		beq	.ExitStats
		sub	r5,r3,r5
		mr	r14,r5
		
		li	r8,0
		li	r9,0
		la	r4,LIST_ALLTASKS(r2)
		lwz	r4,MLH_HEAD(r4)

		lwz	r7,LowActivityPrioOffset(r2)
		neg.	r0,r7
		lwz	r28,LowActivityPrio(r2)
		sub.	r28,r0,r28
		bge-	.SkipResetR28
		li	r28,0

.SkipResetR28:	mr	r10,r4
.LoopLTasks:	lwz	r6,LN_SUCC(r4)
		mr.	r6,r6
		beq-	.TaskLReady
		
		mr	r5,r14
		lwz	r4,TASKPTR_TASK(r4)
		lwz	r7,TASKPPC_TOTALELAPSED(r4)
		add	r7,r7,r5
		stw	r7,TASKPPC_TOTALELAPSED(r4)
				
		lbz	r11,TC_STATE(r4)
		cmpwi	r11,TS_RUN
		beq-	.StatRunning
		cmpwi	r11,TS_CHANGING
		bne-	.StatRdyWait

.StatRunning:	lwz	r7,TASKPPC_ELAPSED(r4)
		add	r7,r7,r5
		stw	r7,TASKPPC_ELAPSED(r4)
		b	.CheckCount

.StatRdyWait:	cmpwi	r11,TS_WAIT
		bne-	.CheckCount

		lwz	r0,TASKPPC_ELAPSED2(r4)
		add	r11,r5,r0
		stw	r11,TASKPPC_ELAPSED2(r4)
		b	.CheckCount
	
.CheckCount:	lbz	r12,BusyCounter(r2)
		mr.	r12,r12
		bne	.NoCounting

.DoStats:	lwz	r11,TASKPPC_ELAPSED2(r4)
		lwz	r7,TASKPPC_ELAPSED(r4)
		lwz	r5,TASKPPC_TOTALELAPSED(r4)
		mr	r3,r7
		add	r0,r11,r7
		srawi	r31,r7,10
		srawi	r0,r0,10		
		mulli	r31,r31,10000
		mr.	r0,r0
		beq-	.NoDivZero1

		divwu	r0,r31,r0
.NoDivZero1:	mr	r29,r0
		stw	r29,TASKPPC_ACTIVITY(r4)
		addi	r29,r29,2000
		lwz	r7,TASKPPC_NICE(r4)
		addi	r31,r7,20
		rlwinm	r31,r31,2,0,29
		lwz	r7,Table_NICE(r2)
#		lwzx	r31,r7,r31
#		rlwinm	r31,r31,24,8,31
		rlwinm	r7,r29,16,0,15
#		divwu	r0,r7,r31
#		stw	r0,TASKPPC_DESIRED(r4)
		srawi	r0,r5,10
		srawi	r11,r11,10
		sub.	r11,r0,r11
		bgt-	.NoResetR11

		li	r11,0
.NoResetR11:	mulli	r11,r11,10000
		divwu	r11,r11,r0
		stw	r11,TASKPPC_BUSY(r4)
		add	r9,r9,r11
		
		srawi	r11,r5,10
		srawi	r0,r3,10
		
		mulli	r0,r0,10000
		li	r7,0
		mr.	r11,r11
		beq-	.NoDivZero2

		divwu	r7,r0,r11
.NoDivZero2:	cmpwi	r7,10000
		blt-	.NoResetR7

		li	r7,10000
.NoResetR7:	stw	r7,TASKPPC_CPUUSAGE(r4)
		add	r8,r8,r7
			
		li	r0,0
		stw	r0,TASKPPC_TOTALELAPSED(r4)
		stw	r0,TASKPPC_ELAPSED2(r4)
		stw	r0,TASKPPC_ELAPSED(r4)
		
.NoCounting:	mr	r4,r6
		b	.LoopLTasks

.TaskLReady:	lbz	r11,BusyCounter(r2)
		mr.	r11,r11
		bne	.NoResetCtr
		
		stw	r8,CPULoad(r2)
		stw	r9,SystemLoad(r2)
		li	r11,25
.NoResetCtr:	subi	r11,r11,1		
		stb	r11,BusyCounter(r2)

.ExitStats:	lwz	r31,0(r13)
		lwzu	r29,4(r13)
		lwzu	r28,4(r13)
		lwzu	r14,4(r13)
		lwzu	r12,4(r13)
		lwzu	r11,4(r13)
		lwzu	r10,4(r13)
		lwzu	r9,4(r13)
		lwzu	r8,4(r13)
		lwzu	r7,4(r13)
		lwzu	r6,4(r13)
		lwzu	r5,4(r13)
		lwzu	r4,4(r13)
		lwzu	r3,4(r13)
		lwzu	r2,4(r13)
		addi	r13,r13,4

		blr

#********************************************************************************************


.TaskException:	li	r9,0				#Will be starting point for TC_EXCEPTCODE
		stw	r9,TaskException(r0)
		b	.ReturnToUser
		
#********************************************************************************************

.TrySwitch:	mr.	r9,r9
		bne	.CheckWait

		lwz	r4,PowerPCBase(r0)
		la	r4,LIST_NEWTASKS(r4)

		lwz	r5,0(r4)			#RemHeadPPC
		lwz	r3,0(r5)
		mr.	r3,r3
		beq-	.NoNode6
		stw	r3,0(r4)
		stw	r4,4(r3)
		mr	r3,r5
.NoNode6:	mr.	r9,r3		
		
		bne	.Dispatch

		lwz	r4,PowerPCBase(r0)
		la	r4,LIST_READYTASKS(r4)
		
		lwz	r5,0(r4)			#RemHeadPPC
		lwz	r3,0(r5)
		mr.	r3,r3
		beq-	.NoNode3
		stw	r3,0(r4)
		stw	r4,4(r3)
		mr	r3,r5		
.NoNode3:	mr.	r9,r3
		
		bne	.DoReady
		
		b	.DoIdle

.DoReady:	li	r6,TS_RUN
		stb	r6,TC_STATE(r9)
		stw	r9,RunningTask(r0)		
		b	.LoadContext

.CheckWait:	li	r4,TS_REMOVED
		lbz	r3,TC_STATE(r9)
		cmpw	r3,r4
		
		bne	.NotDeleted

		mr	r5,r9
		lwz	r3,PowerPCBase(r0)
		la	r4,LIST_REMOVEDTASKS(r3)	#Deleted task list at base
		addi	r4,r4,4				#AddTailPPC
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)

		lwz	r4,TASKPPC_TASKPTR(r9)		
		lwz	r3,0(r4)			#RemovePPC
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)

		li	r9,0
		stw	r9,RunningTask(r0)
		b	.TrySwitch

.NotDeleted:	li	r4,TS_CHANGING
		lbz	r3,TC_STATE(r9)
		cmpw	r3,r4
		
		beq	.GoToWait

		lwz	r4,PowerPCBase(r0)
		la	r4,LIST_NEWTASKS(r4)
		
		lwz	r5,0(r4)			#RemHeadPPC
		lwz	r3,0(r5)
		mr.	r3,r3
		beq-	.NoNode1
		stw	r3,0(r4)
		stw	r4,4(r3)
		mr	r3,r5
	
.NoNode1:	mr.	r9,r3
		bne	.SwitchNew			#Dispatch fixed bug

		lwz	r4,PowerPCBase(r0)
		la	r4,LIST_READYTASKS(r4)
	
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
	
.SwitchOld:	lwz	r4,PowerPCBase(r0)
		la	r4,LIST_READYTASKS(r4)		#Old = Context, New = PPStruct
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
	
.SwitchNew:	lwz	r4,PowerPCBase(r0)
		la	r4,LIST_READYTASKS(r4)		
		lwz	r5,RunningTask(r0)
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
		lwz	r3,0(r1)			#User stack
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
		lwz	r0,0(r3)
		stwu	r0,4(r6)			#r1
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
		li	r0,0
		lwz	r3,PowerPCBase(r0)
		stb	r0,PortInUse(r3)
		lwz	r0,0(r9)
		mtsrr0	r0
		lwzu	r0,4(r9)
		mtsrr1	r0
		lwzu	r0,4(r9)
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
		
		loadreg	r9,'USER'
		stw	r9,0xf4(r0)
		
		mfspr	r9,HID0
		ori	r9,r9,HID0_ICFI
		isync
		mtspr	HID0,r9
		isync

		lwz	r9,0xf0(r0)				#Debug counter to check
		addi	r9,r9,1					#Whether exception is still
		stw	r9,0xf0(r0)

		loadreg	r9,Quantum
		mtdec	r9
		
		mfsprg3	r9
		rfi
		
#********************************************************************************************

.GoToWait:	li	r4,TS_WAIT
		stb	r4,TC_STATE(r9)
		lwz	r4,PowerPCBase(r0)
		la	r4,LIST_WAITINGTASKS(r4)
		mr	r5,r9
		
		bl	.StoreContext
		
		addi	r4,r4,4				#AddTailPPC
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
		
		li	r9,0
		stw	r9,RunningTask(r0)
		
		b	.TrySwitch

#********************************************************************************************		
		
.DoIdle:	loadreg	r0,IdleTask+(.IdleLoop-Start)	#Switch to idle task
		lwz	r1,SonnetBase(r0)
		or	r0,r1,r0
		mtsrr0	r0

		loadreg	r1,SysStack-0x20		#System stack in unused mem
		lwz	r0,SonnetBase(r0)
		or	r1,r1,r0

		lwz	r9,0xf0(r0)				#Debug counter to check
		addi	r9,r9,1					#Whether exception is still
		li	r0,0
		stw	r9,0xf0(r0)
		lwz	r9,PowerPCBase(r0)
		stb	r0,PortInUse(r9)

		stw	r13,-4(r1)
		subi	r13,r1,4
		stwu	r1,-284(r1)
		
		loadreg	r0,MACHINESTATE_DEFAULT
		mtsrr1	r0

		mfspr	r0,HID0
		ori	r0,r0,HID0_ICFI
		isync
		mtspr	HID0,r0
		isync

		loadreg	r0,Quantum
		mtdec	r0
		
		loadreg	r0,'IDLE'
		stw	r0,0xf4(r0)
		
		li	r0,0
		stb	r0,ExceptionMode(r0)
		
		rfi

#********************************************************************************************
		
.DecInt:	mtsprg2	r0

		mfsrr1	r0
		mtsprg1	r0
		mfsrr0	r0
		mtsprg0	r0
		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0				#Reenable MMU (can affect srr0/srr1 acc Docs)
		isync					#Also reenable FPU
		sync

		li	r0,-1
		stb	r0,ExceptionMode(r0)

		mtsprg3	r1				#Store user stack pointer
		lwz	r0,SonnetBase(r0)
		loadreg	r1,SysStack-0x20		#System stack in unused mem (See sonnet.s)
		or	r1,r1,r0
		mfsprg3	r0
		stwu	r0,-4(r1)
		
		mfxer	r0
		mtsprg3	r0
		
		prolog	228,'TOC'
		
		bl	.TaskStats

		stwu	r3,-4(r13)
		stwu	r4,-4(r13)
		stwu 	r5,-4(r13)
		stwu	r6,-4(r13)
		stwu	r7,-4(r13)
		stwu	r8,-4(r13)
		stwu	r9,-4(r13)
			
		loadreg r0,'DECI'
		stw	r0,0xf4(r0)
		
		lwz	r9,Atomic(r0)
		cmpwi	r9,-1
		beq	.ReturnToUser

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
		
.NoRemExc:	b	.StartQ
		
#********************************************************************************************

.BreakPoint:	mtsprg0	r0				#Breakpoint Exception

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0
		sync					#Reenable MMU & FPU
		isync

		li	r0,-1
		stb	r0,ExceptionMode(r0)

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
		stwu	r26,-4(r13)			#Make place on stack (36) for Exc Type
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

		loadreg	r29,'IABR'
		stw	r29,0xf4(r0)
				
		lwz	r31,PowerPCBase(r0)
		la	r31,LIST_EXCIABR(r31)
		loadreg	r0,EXCF_IABR
		stw	r0,36(r13)			#NOT VERY NICE!!

		b	.ExcReUse

#********************************************************************************************

.MachCheck:	mtsprg0	r0				#Machine Check Exception

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0
		sync					#Reenable MMU & FPU
		isync

		li	r0,-1
		stb	r0,ExceptionMode(r0)

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
		stwu	r26,-4(r13)			#Make place on stack (36) for Exc Type
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

		loadreg	r29,'CHCK'
		stw	r29,0xf4(r0)
				
		lwz	r31,PowerPCBase(r0)
		la	r31,LIST_EXCMCHECK(r31)
		li	r0,EXCF_MCHECK
		stw	r0,36(r13)			#NOT VERY NICE!!

		li	r0,.EMachCheck-.EMonitor
		mtsprg1	r0

		b	.ExcReUse

#********************************************************************************************

.SysMan:	mtsprg0	r0				#System Management Exception
		
		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)	#Reenable MMU & FPU
		sync
		mtmsr	r0
		sync
		isync

		li	r0,-1
		stb	r0,ExceptionMode(r0)

		loadreg	r0,'SYSM'
		stw	r0,0xf4(r0)

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
		stwu	r26,-4(r13)			#Make place on stack (36) for Exc Type
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

		lwz	r31,PowerPCBase(r0)
		la	r31,LIST_EXCSYSMAN(r31)
		lis	r0,EXCF_SYSMAN@h
		stw	r0,36(r13)			#NOT VERY NICE!!

		li	r0,.ESM-.EMonitor
		mtsprg1	r0

		b	.NoHandler
		
#********************************************************************************************

.TherMan:	mtsprg0	r0				#Thermal Management Exception
		
		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)	#Reenable MMU & FPU
		sync
		mtmsr	r0
		sync
		isync

		li	r0,-1
		stb	r0,ExceptionMode(r0)

		loadreg	r0,'THRM'
		stw	r0,0xf4(r0)

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
		stwu	r26,-4(r13)			#Make place on stack (36) for Exc Type
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

		lwz	r31,PowerPCBase(r0)
		la	r31,LIST_EXCTHERMAN(r31)
		lis	r0,EXCF_THERMAN@h
		stw	r0,36(r13)			#NOT VERY NICE!!

		li	r0,.ETM-.EMonitor
		mtsprg1	r0

		b	.NoHandler

#********************************************************************************************


.SysCall:	mtsprg0	r0				#System Call Exception

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0
		sync					#Reenable MMU & FPU
		isync

		li	r0,-1
		stb	r0,ExceptionMode(r0)

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
		stwu	r26,-4(r13)			#Make place on stack (36) for Exc Type
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

		loadreg	r29,'SYSC'
		stw	r29,0xf4(r0)
				
		lwz	r31,PowerPCBase(r0)
		la	r31,LIST_EXCSYSTEMCALL(r31)
		li	r0,EXCF_SYSTEMCALL
		stw	r0,36(r13)			#NOT VERY NICE!!
		
		li	r0,.ESC-.EMonitor
		mtsprg1	r0

		b	.ExcReUse

#********************************************************************************************

.Trace:		mtsprg0	r0				#Trace Exception

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0
		sync					#Reenable MMU & FPU
		isync

		li	r0,-1
		stb	r0,ExceptionMode(r0)

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
		stwu	r26,-4(r13)			#Make place on stack (36) for Exc Type
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

		loadreg	r29,'TRCE'
		stw	r29,0xf4(r0)
				
		lwz	r31,PowerPCBase(r0)
		la	r31,LIST_EXCTRACE(r31)
		li	r0,EXCF_TRACE
		stw	r0,36(r13)			#NOT VERY NICE!!
		
		li	r0,.ETrace-.EMonitor
		mtsprg1	r0
		
.ExcReUse:	lwz	r31,0(r31)
		lwz	r0,0(r31)
		mr. 	r0,r0
		beq	.NoHandler
		b	.FirstHandler			#Are there handlers in place?
		
.NextTExc:	lwz	r31,0(r31)
		lwz	r0,0(r31)
		mr.	r0,r0
		beq	.LastTrHandler
		
.FirstHandler:	mr	r30,r31												
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
		lwz	r0,36(r13)			#NOT VERY NICE!!
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
		addi	r13,r13,40			#Skipping one spot (was for Exc Type)

		lwz	r1,0(r1)
		lwz	r13,-4(r1)
		lwz	r1,0(r1)			#User stack restored
		
		li	r0,0
		stb	r0,ExceptionMode(r0)

		loadreg	r0,'USER'
		stw	r0,0xf4(r0)
		
		mfspr	r0,HID0
		ori	r0,r0,HID0_ICFI
		isync
		mtspr	HID0,r0
		isync

		mfsprg0	r0
		
		rfi
		
.NoHandler:	lwz	r0,0(r13)
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
		addi	r13,r13,40			#Skipping one spot (was for Exc Type)

		lwz	r1,0(r1)
		lwz	r13,-4(r1)
		lwz	r1,0(r1)

		b	.CrashReport
		
#********************************************************************************************

.FPUnav:	mtsprg0	r0				#FPU Unavailable Exception

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0
		sync					#Reenable MMU & FPU
		isync

		li	r0,-1
		stb	r0,ExceptionMode(r0)

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
		stwu	r26,-4(r13)			#Make place on stack (36) for Exc Type
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

		loadreg	r29,'NOFP'
		stw	r29,0xf4(r0)
				
		lwz	r31,PowerPCBase(r0)
		la	r31,LIST_EXCFPUN(r31)
		li	r0,EXCF_FPUN
		stw	r0,36(r13)			#NOT VERY NICE!!

		li	r0,.EFP-.EMonitor
		mtsprg1	r0

		b	.ExcReUse

#********************************************************************************************

.Alignment:	mtsprg0	r0				#FPU Alignment Exception
		mtsprg1	r1
		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0				#Reenable MMU & FPU
		sync
		isync

		lwz	r0,SonnetBase(r0)
		loadreg	r1,SysStack-0x20		#System stack in unused mem
		or	r1,r1,r0
		
		loadreg	r0,'ALIG'
		stw	r0,0xf4(r0)
		
		mfcr	r0
		stwu	r0,-4(r1)
		li	r0,0
		stwu	r0,-4(r1)			#For when rA = 0

		stwu	r31,-4(r1)
		stwu	r30,-4(r1)
		stwu	r29,-4(r1)
		stwu	r28,-4(r1)
		stwu	r27,-4(r1)
		stwu	r26,-4(r1)
		stwu	r25,-4(r1)
		stwu	r24,-4(r1)
		stwu	r23,-4(r1)
		stwu	r22,-4(r1)
		stwu	r21,-4(r1)
		stwu	r20,-4(r1)
		stwu	r19,-4(r1)
		stwu	r18,-4(r1)
		stwu	r17,-4(r1)
		stwu	r16,-4(r1)
		stwu	r15,-4(r1)
		stwu	r14,-4(r1)
		stwu	r13,-4(r1)
		stwu	r12,-4(r1)
		stwu	r11,-4(r1)
		stwu	r10,-4(r1)
		stwu	r9,-4(r1)
		stwu	r8,-4(r1)
		stwu	r7,-4(r1)
		stwu	r6,-4(r1)
		stwu	r5,-4(r1)
		stwu	r4,-4(r1)
		stwu	r3,-4(r1)
		stwu	r2,-4(r1)
		mfsprg1	r30
		stwu	r30,-4(r1)
		mfsprg0	r30
		stwu	r30,-4(r1)
		mr	r30,r1				#Start of regtable in r30
		
		stfdu	f31,-8(r1)
		stfdu	f30,-8(r1)
		stfdu	f29,-8(r1)
		stfdu	f28,-8(r1)
		stfdu	f27,-8(r1)
		stfdu	f26,-8(r1)
		stfdu	f25,-8(r1)
		stfdu	f24,-8(r1)
		stfdu	f23,-8(r1)
		stfdu	f22,-8(r1)
		stfdu	f21,-8(r1)
		stfdu	f20,-8(r1)
		stfdu	f19,-8(r1)
		stfdu	f18,-8(r1)
		stfdu	f17,-8(r1)
		stfdu	f16,-8(r1)
		stfdu	f15,-8(r1)
		stfdu	f14,-8(r1)
		stfdu	f13,-8(r1)
		stfdu	f12,-8(r1)
		stfdu	f11,-8(r1)
		stfdu	f10,-8(r1)
		stfdu	f9,-8(r1)
		stfdu	f8,-8(r1)
		stfdu	f7,-8(r1)
		stfdu	f6,-8(r1)
		stfdu	f5,-8(r1)
		stfdu	f4,-8(r1)
		stfdu	f3,-8(r1)
		stfdu	f2,-8(r1)
		stfdu	f1,-8(r1)
		stfdu	f0,-8(r1)
		
		mr	r31,r1				#Start of fp regtable in r31

		lwz	r5,PowerPCBase(r0)		#For GetHALInfo
		lwz	r6,AlignmentExcLow(r5)		#Counts number of FPU aligment issues
		addic	r6,r6,1				#For debugging and optimization purposes
		stw	r6,AlignmentExcLow(r5)
		lwz	r6,AlignmentExcHigh(r5)
		addze	r6,r6
		stw	r6,AlignmentExcHigh(r5)

		mfsrr0	r5
		lwz	r5,0(r5)

		rlwinm	r6,r5,14,24,28			#get floating point register offset
		rlwinm	r7,r5,18,25,29			#get destination register offset
		mr.	r10,r7
		beq	.ItsR0
		lwzx	r10,r30,r7			#get address from destination register
.ItsR0:		rlwinm	r8,r5,0,16,31			#get displacement

		rlwinm	r0,r5,6,26,31		
		cmpwi	r0,0x34				#test for stfs
		beq	.stfs
		cmpwi	r0,0x35
		beq	.stfsu
		cmpwi	r0,0x30
		beq	.lfs
		cmpwi	r0,0x31
		beq	.lfsu
		cmpwi	r0,0x1f
		beq	.lstfsx
		cmpwi	r0,0x32
		beq	.lfd
		cmpwi	r0,0x36
		beq	.stfd
		b	.HaltAlign

.stfd:		lwzx	r9,r31,r6
		stwx	r9,r10,r8
		addi	r6,r6,4
		addi	r8,r8,4
		lwzx	r9,r31,r6
		stwx	r9,r10,r8
		b	.AligExit

.stfsu:		add	r9,r10,r8
		stwx	r9,r30,r7

.stfs:		lfdx	f1,r31,r6			#get value from fp register
		stfs	f1,AlignStore(r0)		#store it on correct aligned spot
		lwz	r6,AlignStore(r0)		#Get the correct 32 bit value
		stwx	r6,r10,r8			#Store correct value
		b	.AligExit

.lfd:		lwzx	r9,r10,r8
		stw	r9,AlignStore(r0)
		addi	r8,r8,4
		lwzx	r9,r10,r8
		stw	r9,AlignStore2(r0)
		lfd	f1,AlignStore(r0)
		stfdx	f1,r31,r6
		b	.AligExit

.lfsu:		add	r5,r10,r8			#Add displacement
		stwx	r5,r30,r7	

.lfs:		lwzx	r9,r10,r8			#Get 32 bit value
		stw	r9,AlignStore(r0)		#Store it on aligned spot
		lfs	f1,AlignStore(r0)		#Get it and convert it to 64 bit
		stfdx	f1,r31,r6			#Store the 64 bit value
		b	.AligExit
		
.lstfsx:	rlwinm	r8,r5,23,25,29			#get index register
		lwzx	r8,r30,r8			#get index register value
		rlwinm.	r0,r5,24,31,31
		bne	.stfs
		b	.lfs
				
#***********************************************
						
.AligExit:	loadreg	r7,'USER'			#Return to user
		stw	r7,0xf4(r0)

		lfdu	f0,0(r1)
		lfdu	f1,8(r1)
		lfdu	f2,8(r1)
		lfdu	f3,8(r1)
		lfdu	f4,8(r1)
		lfdu	f5,8(r1)
		lfdu	f6,8(r1)
		lfdu	f7,8(r1)
		lfdu	f8,8(r1)
		lfdu	f9,8(r1)
		lfdu	f10,8(r1)
		lfdu	f11,8(r1)
		lfdu	f12,8(r1)
		lfdu	f13,8(r1)
		lfdu	f14,8(r1)
		lfdu	f15,8(r1)
		lfdu	f16,8(r1)
		lfdu	f17,8(r1)
		lfdu	f18,8(r1)
		lfdu	f19,8(r1)
		lfdu	f20,8(r1)
		lfdu	f21,8(r1)
		lfdu	f22,8(r1)
		lfdu	f23,8(r1)
		lfdu	f24,8(r1)
		lfdu	f25,8(r1)
		lfdu	f26,8(r1)
		lfdu	f27,8(r1)
		lfdu	f28,8(r1)
		lfdu	f29,8(r1)
		lfdu	f30,8(r1)
		lfdu	f31,8(r1)
		
		lwzu	r31,8(r1)			#Load registers with correct values
		mtsprg0	r31
		lwzu	r31,4(r1)
		mtsprg1	r31
		lwzu	r2,4(r1)
		lwzu	r3,4(r1)
		lwzu	r4,4(r1)
		lwzu	r5,4(r1)
		lwzu	r6,4(r1)
		lwzu	r7,4(r1)
		lwzu	r8,4(r1)
		lwzu	r9,4(r1)
		lwzu	r10,4(r1)
		lwzu	r11,4(r1)
		lwzu	r12,4(r1)
		lwzu	r13,4(r1)
		lwzu	r14,4(r1)
		lwzu	r15,4(r1)
		lwzu	r16,4(r1)
		lwzu	r17,4(r1)
		lwzu	r18,4(r1)
		lwzu	r19,4(r1)
		lwzu	r20,4(r1)
		lwzu	r21,4(r1)
		lwzu	r22,4(r1)
		lwzu	r23,4(r1)
		lwzu	r24,4(r1)
		lwzu	r25,4(r1)
		lwzu	r26,4(r1)
		lwzu	r27,4(r1)
		lwzu	r28,4(r1)
		lwzu	r29,4(r1)
		lwzu	r30,4(r1)
		lwzu	r31,4(r1)
		lwzu	r0,8(r1)
		mtcr	r0
		
		mfsrr0	r1
		addi	r1,r1,4				#Exit beyond offending instruction
		mtsrr0	r1
		mfsprg1	r1
		mfsprg0	r0

		rfi
	
#***********************************************	
		
.HaltAlign:	
		lfdu	f0,0(r1)
		lfdu	f1,8(r1)
		lfdu	f2,8(r1)
		lfdu	f3,8(r1)
		lfdu	f4,8(r1)
		lfdu	f5,8(r1)
		lfdu	f6,8(r1)
		lfdu	f7,8(r1)
		lfdu	f8,8(r1)
		lfdu	f9,8(r1)
		lfdu	f10,8(r1)
		lfdu	f11,8(r1)
		lfdu	f12,8(r1)
		lfdu	f13,8(r1)
		lfdu	f14,8(r1)
		lfdu	f15,8(r1)
		lfdu	f16,8(r1)
		lfdu	f17,8(r1)
		lfdu	f18,8(r1)
		lfdu	f19,8(r1)
		lfdu	f20,8(r1)
		lfdu	f21,8(r1)
		lfdu	f22,8(r1)
		lfdu	f23,8(r1)
		lfdu	f24,8(r1)
		lfdu	f25,8(r1)
		lfdu	f26,8(r1)
		lfdu	f27,8(r1)
		lfdu	f28,8(r1)
		lfdu	f29,8(r1)
		lfdu	f30,8(r1)
		lfdu	f31,8(r1)
		
		lwzu	r31,8(r1)			#Load registers with correct values
		mtsprg0	r31
		lwzu	r31,4(r1)
		mtsprg1	r31
		lwzu	r2,4(r1)
		lwzu	r3,4(r1)
		lwzu	r4,4(r1)
		lwzu	r5,4(r1)
		lwzu	r6,4(r1)
		lwzu	r7,4(r1)
		lwzu	r8,4(r1)
		lwzu	r9,4(r1)
		lwzu	r10,4(r1)
		lwzu	r11,4(r1)
		lwzu	r12,4(r1)
		lwzu	r13,4(r1)
		lwzu	r14,4(r1)
		lwzu	r15,4(r1)
		lwzu	r16,4(r1)
		lwzu	r17,4(r1)
		lwzu	r18,4(r1)
		lwzu	r19,4(r1)
		lwzu	r20,4(r1)
		lwzu	r21,4(r1)
		lwzu	r22,4(r1)
		lwzu	r23,4(r1)
		lwzu	r24,4(r1)
		lwzu	r25,4(r1)
		lwzu	r26,4(r1)
		lwzu	r27,4(r1)
		lwzu	r28,4(r1)
		lwzu	r29,4(r1)
		lwzu	r30,4(r1)
		lwzu	r31,4(r1)
		lwzu	r0,8(r1)
		mtcr	r0

		mfsprg1	r1

		li	r0,.EAlign-.EMonitor
		mtsprg1	r0
		
		mfsprg0	r0
		
		b	.CrashReport

#********************************************************************************************

.ISI:		mtsprg0	r0				#Instruction Storage Exception

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0
		sync					#Reenable MMU & FPU
		isync

		li	r0,-1
		stb	r0,ExceptionMode(r0)

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
		stwu	r26,-4(r13)			#Make place on stack (36) for Exc Type
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

		loadreg	r29,'ISI!'
		stw	r29,0xf4(r0)
				
		lwz	r31,PowerPCBase(r0)
		la	r31,LIST_EXCIACCESS(r31)
		li	r0,EXCF_IACCESS
		stw	r0,36(r13)			#NOT VERY NICE!!
		
		li	r0,.EISI-.EMonitor
		mtsprg1	r0

		b	.ExcReUse

#********************************************************************************************

.PerfMon:	mtsprg0	r0				#Performance Monitor Exception

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0
		sync					#Reenable MMU & FPU
		isync

		li	r0,-1
		stb	r0,ExceptionMode(r0)

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
		stwu	r26,-4(r13)			#Make place on stack (36) for Exc Type
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
				
		loadreg	r29,'PRFM'
		stw	r29,0xf4(r0)
				
		lwz	r31,PowerPCBase(r0)
		la	r31,LIST_EXCPERFMON(r31)
		loadreg	r0,EXCF_PERFMON
		stw	r0,36(r13)			#NOT VERY NICE!!

		li	r0,.EMonitor-.EMonitor
		mtsprg1	r0

		b	.ExcReUse
	
#********************************************************************************************

.DSI:		mtsprg0	r0
		mtsprg1	r1				#Data Storage Exception
		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0				#Reenable MMU & FPU
		sync
		isync
		
		lwz	r0,SonnetBase(r0)
		loadreg	r1,SysStack-0x20		#System stack in unused mem
		or	r1,r1,r0

		mflr	r0
		stwu	r0,-4(r1)
		mfcr	r0
		stwu	r0,-4(r1)
		li	r0,0
		stwu	r0,-4(r1)			#For when rA = 0
		stwu	r31,-4(r1)
		stwu	r30,-4(r1)
		stwu	r29,-4(r1)
		stwu	r28,-4(r1)
		stwu	r27,-4(r1)
		stwu	r26,-4(r1)
		stwu	r25,-4(r1)
		stwu	r24,-4(r1)
		stwu	r23,-4(r1)
		stwu	r22,-4(r1)
		stwu	r21,-4(r1)
		stwu	r20,-4(r1)
		stwu	r19,-4(r1)
		stwu	r18,-4(r1)
		stwu	r17,-4(r1)
		stwu	r16,-4(r1)
		stwu	r15,-4(r1)
		stwu	r14,-4(r1)
		stwu	r13,-4(r1)
		stwu	r12,-4(r1)
		stwu	r11,-4(r1)
		stwu	r10,-4(r1)
		stwu	r9,-4(r1)
		stwu	r8,-4(r1)
		stwu	r7,-4(r1)
		stwu	r6,-4(r1)
		stwu	r5,-4(r1)
		stwu	r4,-4(r1)
		stwu	r3,-4(r1)
		stwu	r2,-4(r1)
		mfsprg1	r31
		stwu	r31,-4(r1)
		mfsprg0	r31
		stwu	r31,-4(r1)
		mr	r30,r1				#Start of reg table in r30
		
		loadreg	r7,'DSI?'
		stw	r7,0xf4(r0)

		lwz	r7,PowerPCBase(r0)		#For GetHALInfo
		lwz	r6,DataExcLow(r7)		#Counts number of Amiga RAM
		addic	r6,r6,1				#accesses by the PPC
		stw	r6,DataExcLow(r7)		#For debugging/optimization purposes
		lwz	r6,DataExcHigh(r7)
		addze	r6,r6
		stw	r6,DataExcHigh(r7)

		mfsrr0	r31
		
		cmpwi	r31,0x7f00			#Called from other exception
		blt	.NotSupported			#NOT GOOD!
		
		lwz	r31,0(r31)			#get offending instruction in r31
		
		li	r29,0
		lis	r0,0xc000			#check for load or store instruction
		and.	r0,r31,r0
		lis	r6,0x8000
		cmpw	r6,r0				
		beq	.LoadStore

		rlwinm	r6,r31,0,25,5
		loadreg	r8,0x7c00002e			#check for stbx/sthx/stwx/lbzx/lhzx/lwzx
		cmpw	r6,r8
		bne	.NotSupported
		nop
		
		li	r29,1
		rlwinm	r6,r31,13,25,29			#Source reg
		rlwinm	r8,r31,18,25,29			#Dest 1
		rlwinm	r4,r31,23,25,29			#Dest 2
		lwzx	r4,r30,r4			#Displacement (word)
		li	r5,0				#Update bit
		li	r9,1				#Mark as Store instruction
		
		b	.GoStore
		
.LoadStore:	rlwinm	r6,r31,13,25,29			#Get Destination Reg (l) or Source (s)
		rlwinm	r8,r31,18,25,29			#Get Source Reg (l) or Destination (s)
		rlwinm	r9,r31,4,31,31			#Check load or store
		rlwinm	r5,r31,6,31,31			#Check for update bit
		rlwinm	r4,r31,0,16,31			#Displacement (halfword)
		extsh	r4,r4				#Extend sign of displacement		
		
.GoStore:	mr.	r5,r5
		bne	.NoZero				#When update r0 = r0 and not 0
		mr.	r8,r8
		bne	.NoZero
		li	r8,128				#Point to 0 in reg table
		
.NoZero:	lwzx	r3,r30,r8			#Get Destination Address			
		add	r3,r3,r4			#Add displacement
		mr.	r5,r5
		beq	.NoUpdate
		stwx	r3,r30,r8			#Update Destination Reg
.NoUpdate:	lwzx	r2,r30,r6			#Get value to store
		
		li	r7,0
		mr.	r9,r9
		beq	.GoLoad				#Load or store?
		
		mr.	r29,r29				#Normal store or with index?
		beq	.NoStxx
	
		rlwinm	r0,r31,25,29,31			#Indexed store
		cmpwi	r0,6
		beq	.StoreHalf
		cmpwi	r0,3
		beq	.StoreByte
		cmpwi	r0,2
		beq	.StoreWord
		mr.	r0,r0
		beq	.GoLoadx			#Lwzx
		cmpwi	r0,1
		beq	.GoLoadx			#lbzx
		cmpwi	r0,4
		beq	.GoLoadx			#lhzx
		cmpwi	r0,5
		beq	.GoLoadx			#lhax
		b	.NotSupported			#Not Supported
		
.NoStxx:	rlwinm.	r0,r31,3,31,31			#Normal store
		bne	.StoreHalf
		rlwinm. r0,r31,5,31,31
		bne	.StoreByte
.StoreWord:	loadreg	r9,'PUTW'
		b	.DoStore
.StoreHalf:	loadreg	r9,'PUTH'
		b	.DoStore
.StoreByte:	loadreg	r9,'PUTB'

.DoStore:	li	r7,-1
		bl	.DoSixtyEight			#Send message to 68K
		
		b	.DoneDSI			#We're done

.GoLoadx:	mr	r19,r0
		loadreg	r9,'GETV'
		
		bl	.DoSixtyEight
		
		mr.	r19,r19
		beq	.FixedValue			#Word
		rlwinm	r10,r10,16,16,31
		cmpwi	r19,4
		beq	.FixedValue			#halfword
		extsh	r10,r10
		cmpwi	r19,5				#halfword algebraic
		beq	.FixedValue
		rlwinm	r10,r10,24,24,31
		b	.FixedValue			#byte

.GoLoad:	loadreg	r9,'GETV'

		bl	.DoSixtyEight			#Returns value in r10
		
		rlwinm	r9,r31,16,16,31
		andi.	r9,r9,0xa800
		oris	r9,r9,0xffff
		cmpwi	r9,-32768			#lwz/lwzu 0x8000
		beq	.FixedValue
		rlwinm	r10,r10,16,16,31
		cmpwi	r9,-24576			#lhz/lhzu 0xa000
		beq	.FixedValue
		extsh	r10,r10
		cmpwi	r9,-22528			#lha/lhau 0xa800
		beq	.FixedValue
		rlwinm	r10,r10,24,24,31
		cmpwi	r9,-30720			#lbz/lbzu
		bne	.NotSupported			#Not Supported

.FixedValue:	stwx	r10,r30,r6			#Store gotten value in correct register
		
.DoneDSI:	mfsrr0	r7				#Skip offending instruction
		addi	r7,r7,4
		mtsrr0	r7
		isync		
		
.DSINoStep:	loadreg	r7,'USER'			#Return to user
		stw	r7,0xf4(r0)

		lwz	r31,0(r1)			#Load registers with correct values
		mtsprg0	r31
		lwz	r31,4(r1)
		mtsprg1	r31
		lwz	r2,8(r1)
		lwz	r3,12(r1)
		lwz	r4,16(r1)
		lwz	r5,20(r1)
		lwz	r6,24(r1)
		lwz	r7,28(r1)
		lwz	r8,32(r1)
		lwz	r9,36(r1)
		lwz	r10,40(r1)
		lwz	r11,44(r1)
		lwz	r12,48(r1)
		lwz	r13,52(r1)
		lwz	r14,56(r1)
		lwz	r15,60(r1)
		lwz	r16,64(r1)
		lwz	r17,68(r1)
		lwz	r18,72(r1)
		lwz	r19,76(r1)
		lwz	r20,80(r1)
		lwz	r21,84(r1)
		lwz	r22,88(r1)
		lwz	r23,92(r1)
		lwz	r24,96(r1)
		lwz	r25,100(r1)
		lwz	r26,104(r1)
		lwz	r27,108(r1)
		lwz	r28,112(r1)
		lwz	r29,116(r1)
		lwz	r30,120(r1)
		lwz	r31,124(r1)
		lwz	r0,132(r1)
		mtcr	r0
		lwz	r0,136(r1)
		mtlr	r0
		mfsprg1	r1
		mfsprg0	r0
		rfi

.NotSupported:	nop
.HaltDSI:	loadreg	r7,'DSI!'
		stw	r7,0xf4(r0)
				
		lwz	r31,0(r1)			#Load registers with correct values
		mtsprg0	r31
		lwz	r31,4(r1)
		mtsprg1	r31
		lwz	r2,8(r1)
		lwz	r3,12(r1)
		lwz	r4,16(r1)
		lwz	r5,20(r1)
		lwz	r6,24(r1)
		lwz	r7,28(r1)
		lwz	r8,32(r1)
		lwz	r9,36(r1)
		lwz	r10,40(r1)
		lwz	r11,44(r1)
		lwz	r12,48(r1)
		lwz	r13,52(r1)
		lwz	r14,56(r1)
		lwz	r15,60(r1)
		lwz	r16,64(r1)
		lwz	r17,68(r1)
		lwz	r18,72(r1)
		lwz	r19,76(r1)
		lwz	r20,80(r1)
		lwz	r21,84(r1)
		lwz	r22,88(r1)
		lwz	r23,92(r1)
		lwz	r24,96(r1)
		lwz	r25,100(r1)
		lwz	r26,104(r1)
		lwz	r27,108(r1)
		lwz	r28,112(r1)
		lwz	r29,116(r1)
		lwz	r30,120(r1)
		lwz	r31,124(r1)
		lwz	r0,132(r1)
		mtcr	r0
		lwz	r0,136(r1)
		mtlr	r0
		mfsprg1	r1
				
		li	r0,.EDSI-.EMonitor
		mtsprg1	r0
		
		mfsprg0	r0
		
		b	.CrashReport

#*************************************************

.DoSixtyEight:	lis	r28,EUMB
		li	r24,OFTPR
		lwbrx	r25,r24,r28			
		addi	r23,r25,4
		loadreg	r20,0xc000
		or	r23,r23,r20
		loadreg r20,0xffff
		and	r23,r23,r20			#Keep it C000-FFFE		
		stwbrx	r23,r24,r28
		lwz	r25,0(r25)

.Loading:	stw	r9,MN_IDENTIFIER(r25)
		stw	r2,MN_IDENTIFIER+4(r25)		#AmigaValue
		stw	r3,MN_IDENTIFIER+8(r25)		#AmigaAddress
		
		lwz	r20,MCPort(r0)
		stw	r20,MN_MCPORT(r25)
		li	r20,NT_MESSAGE
		stb	r20,LN_TYPE(r25)
		li	r20,192
		sth	r20,MN_LENGTH(r25)

		sync

		lis	r28,EUMB
		li	r24,OPHPR
		lwbrx	r22,r24,r28		
		stw	r25,0(r22)		
		addi	r23,r22,4
		loadreg	r20,0xbfff
		and	r23,r23,r20			#Keep it 8000-BFFE
		stwbrx	r23,r24,r28			#triggers Interrupt

		mr.	r7,r7
		bne	.NoWaitSE
		loadreg	r9,'DONE'
.WaitPFIFO:	lwz	r21,MN_IDENTIFIER(r25)
		cmpw	r21,r9
		bne	.WaitPFIFO
		
		lwz	r10,MN_IDENTIFIER+4(r25)	#Returned value for load in r10
		
.NoWaitSE:	blr

#********************************************************************************************

.PrInt:		
		mtsprg0	r0				#Program Exception		

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0				#Reenable MMU & FPU
		sync
		isync

		li	r0,-1
		stb	r0,ExceptionMode(r0)

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

		loadreg	r29,'TRAP'
		stw	r29,0xf4(r0)

		mfsrr0	r31
		lwz	r0,ViolationAddress(r0)
		cmplw	r0,r31
		beq	.Privvy

#		lis	r31,SRR1_TRAP-12
#		mfsrr1	r0
		
#		and.	r0,r0,r31
#		beq	.HaltErr			#skip ILLEGAL and PRIVILEGED

		lwz	r31,PowerPCBase(r0)
		la	r31,LIST_EXCPROGRAM(r31)
		lwz	r31,0(r31)
		lwz	r0,0(r31)
		mr.	r0,r0
		beq	.HaltErr
		b	.FirstEHandler		
	
.NextPExc:	lwz	r31,0(r31)			#Are there handlers in place?

		lwz	r0,0(r31)
		mr.	r0,r0
		beq	.LastPrHandler
		
.FirstEHandler:	mr	r30,r31
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

		loadreg	r0,'USER'
		stw	r0,0xf4(r0)
		
		mfspr	r0,HID0
		ori	r0,r0,HID0_ICFI
		mtspr	HID0,r0
		isync
		
		mfsprg0	r0
		
		rfi
		
.HaltErr:	loadreg r3,'HALT'			#DEBUG
		stw	r3,0xf4(r0)			#Error
		
		li	r0,.EProgram-.EMonitor
		mtsprg1	r0
		
		lwz	r0,0(r13)
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
		lwz	r1,0(r1)

.CrashReport:	mtsprg2	r30
		mflr	r30
		bl .GotStrings

.EMonitor:	.string	"Perfomance Monitor"
.ESC:		.string	"System Call"
.EMachCheck:	.string	"Machine Check"
.EProgram:	.string	"Program"
.EDSI:		.string	"Data Storage"
.EISI:		.string	"Instruction Storage"
.EAlign:	.string "FPU Alignment"
.EFP:		.string	"FPU Unavailable"
.ETrace:	.string "Trace"
.ESM:		.string "System Management"
.ETM:		.string "Thermal Management"

		.align	2
				
.GotStrings:	mtsprg3	r31
		li	r31,0x2100
		addi	r31,r31,18*4
		stwu	r0,4(r31)
		stwu	r1,4(r31)
		stwu	r2,4(r31)
		stwu	r3,4(r31)
		mfibatu	r0,0
		stwu	r0,4(r31)
		mfibatl	r0,0
		stwu	r0,4(r31)		
		stwu	r4,4(r31)
		stwu	r5,4(r31)
		stwu	r6,4(r31)
		stwu	r7,4(r31)
		mfibatu	r0,1
		stwu	r0,4(r31)
		mfibatl	r0,1
		stwu	r0,4(r31)
		stwu	r8,4(r31)
		stwu	r9,4(r31)
		stwu	r10,4(r31)
		stwu	r11,4(r31)
		mfibatu	r0,2
		stwu	r0,4(r31)
		mfibatl	r0,2
		stwu	r0,4(r31)
		stwu	r12,4(r31)
		stwu	r13,4(r31)
		stwu	r14,4(r31)
		stwu	r15,4(r31)
		mfibatu	r0,3
		stwu	r0,4(r31)
		mfibatl	r0,3
		stwu	r0,4(r31)
		stwu	r16,4(r31)
		stwu	r17,4(r31)
		stwu	r18,4(r31)
		stwu	r19,4(r31)
		mfdbatu	r0,0
		stwu	r0,4(r31)
		mfdbatl	r0,0
		stwu	r0,4(r31)
		stwu	r20,4(r31)
		stwu	r21,4(r31)
		stwu	r22,4(r31)
		stwu	r23,4(r31)
		mfdbatu	r0,1
		stwu	r0,4(r31)
		mfdbatl	r0,1
		stwu	r0,4(r31)
		stwu	r24,4(r31)
		stwu	r25,4(r31)
		stwu	r26,4(r31)
		stwu	r27,4(r31)
		mfdbatu	r0,2
		stwu	r0,4(r31)
		mfdbatl	r0,2
		stwu	r0,4(r31)
		stwu	r28,4(r31)
		stwu	r29,4(r31)
		mfsprg2	r0
		stwu	r0,4(r31)
		mfsprg3	r0
		stwu	r0,4(r31)
		mfdbatu	r0,3
		stwu	r0,4(r31)
		mfdbatl	r0,3
		stwu	r0,4(r31)
		li	r31,0x2100
		lwz	r29,RunningTask(r0)
		stw	r29,4(r31)
		lwz	r29,LN_NAME(r29)
		stw	r29,0(r31)
		addi	r31,r31,4
		lwz	r29,SonnetBase(r0)
		mflr	r28
		or	r28,r28,r29
		mfsprg1	r29
		add	r28,r28,r29
		stwu	r28,4(r31)
		mfsrr0	r0
		stwu	r0,4(r31)
		mfsrr1	r0
		stwu	r0,4(r31)
		mfmsr	r0
		stwu	r0,4(r31)
		mfspr	r0,HID0
		stwu	r0,4(r31)
		mfpvr	r0
		stwu	r0,4(r31)
		mfdar	r0
		stwu	r0,4(r31)
		mfdsisr	r0
		stwu	r0,4(r31)
		mfspr	r0,SDR1
		stwu	r0,4(r31)
		mfdec	r0
		stwu	r0,4(r31)
		mftbu	r0
		stwu	r0,4(r31)
		mftbl	r0
		stwu	r0,4(r31)
		mfxer	r0
		stwu	r0,4(r31)
		mfcr	r0
		mffs	f0
		stfdu	f0,4(r31)
		stw	r0,0(r31)
		addi	r31,r31,4		
		stwu	r30,4(r31)
		mfctr	r0
		stwu	r0,4(r31)
		
		lis	r28,EUMB
		li	r24,OFTPR
		lwbrx	r25,r24,r28			
		addi	r23,r25,4
		loadreg	r20,0xc000
		or	r23,r23,r20
		loadreg r20,0xffff
		and	r23,r23,r20			#Keep it C000-FFFE		
		stwbrx	r23,r24,r28
		lwz	r25,0(r25)

		loadreg	r9,'CRSH'

		stw	r9,MN_IDENTIFIER(r25)
		
		lwz	r20,MCPort(r0)
		stw	r20,MN_MCPORT(r25)
		li	r20,NT_MESSAGE
		stb	r20,LN_TYPE(r25)
		li	r20,192
		sth	r20,MN_LENGTH(r25)

		sync

		lis	r28,EUMB
		li	r24,OPHPR
		lwbrx	r22,r24,r28		
		stw	r25,0(r22)		
		addi	r23,r22,4
		loadreg	r20,0xbfff
		and	r23,r23,r20			#Keep it 8000-BFFE
		stwbrx	r23,r24,r28			#triggers Interrupt
		
.RealHalt:	b	.RealHalt
		
		
#********************************************************************************************
	
EIntEnd:
		mflr	r4				#Setup a small jumptable for exceptions			
		loadreg r5,0x48002b34
		stw	r5,0x500(r0)			#External Interrupt
		loadreg	r5,0x48001930			
		stw	r5,0x1700(r0)			#Thermal Management
		loadreg	r5,0x48001c2c
		stw	r5,0x1400(r0)			#System Management
		loadreg	r5,0x48002128
		stw	r5,0xf00(r0)			#Performance Monitor
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
