# Copyright (c) 2015-2019 Dennis van der Boon
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

.include ppcdefines.i
.include sonnet_libppc.i
.include ppcmacros-std.i

.global PPCCode,PPCLen,ThisPPCProc,LIST_WAITINGTASKS,Init,ViolationAddress
.global MCPort,SysBase,PowerPCBase,DOSBase,sonnet_DebugLevel,sonnet_PosSize,PageTableSize
.global UtilityBase

.set	PPCLen,(PPCEnd-PPCCode)
.set	base_Comm,0
.set	base_MemStart,4
.set	base_MemLen,8
.set	base_RTGBase,12
.set	base_RTGLen,16
.set	base_RTGType,20
.set	base_RTGConfig,24
.set	base_Options,28
.set	base_XMPI,40
.set	base_StartBAT,44
.set	base_SizeBAT,48

.set	rtgtype_ati,0x1002
.set	rtgtype_voodoo3,0x121a
.set	rtgtype_voodoo45,0x121b

#********************************************************************************************

.section "PPCSetup","acrx"

PPCCode:	bl	.SkipCom			#0x3000	System initialization

.long		0					#Used for initial communication
.long		0					#MemStart
.long		0					#MemLen
.long		0					#RTGBase
.long		0					#RTGLen
.long		0					#RTGType
.long		0					#RTGConfig
.long		0					#Options1
.long		0					#Options2
.long		0					#Options3
.long		0					#XMPI Address
.long		0					#StartBAT
.long		0					#SizeBAT

.SkipCom:	mflr	r29				#For initial communication with 68k
		lis	r22,CMD_BASE@h			#Used in setpcireg macro
		
		mfpvr	r25		
		rlwinm	r25,r25,16,16,31
		cmplwi	r25,0x8000
		bne	.NoEIDIS
				
		mfspr	r25,MSSCR0
		oris	r25,r25,MSSCR0_EIDIS@h
		mtspr	MSSCR0,r25

.NoEIDIS:	loadreg	r0,'Init'
		stw	r0,base_Comm(r29)

		bl	Reset

		lwz	r25,base_XMPI(r29)
		mr.	r25,r25
		bne	.GoToClear

		mfpvr	r25
		rlwinm	r25,r25,16,16,31
		cmplwi	r25,ID_MPC834X
		beq	.GoToClear

		b	.SonnetStart

.GoToClear:	li	r3,0
		li	r4,63
		mtctr	r4
		li	r0,0
.ClearH:	stwu	r0,4(r3)
		bdnz+	.ClearH

		cmplwi	r25,ID_MPC834X
		beq	.KillerStart

		stw	r25,XMPIBase(r0)
		
		la	r14,base_Options(r29)
		li	r8,0x13
		stb	r8,option_VersionNB(r14)

		lwz	r0,base_MemLen(r29)
		stw	r0,MemSize(r0)
		
		bl	.SetupHarFIFOs
		bl	Mpic
		bl	InstallExceptions
		lwz	r27,base_MemStart(r29)
		stw	r27,SonnetBase(r0)
		lwz	r8,base_MemLen(r29)

		bl	mmuSetup

		loadreg	r0,'Boon'
		stw	r0,0(r0)
		
		b	.SonSkip

#*********************************************************

.KillerStart:	lwz	r0,base_MemLen(r29)
		stw	r0,MemSize(r0)
		
		bl	.SetupKillerFIFOs
		bl	Ipic
		bl	InstallExceptions

		lwz	r27,base_MemStart(r29)
		stw	r27,SonnetBase(r0)
		lwz	r8,base_MemLen(r29)

		bl	mmuSetup

		loadreg	r0,'Boon'
		stw	r0,0(r0)

		b	.SonSkip

#*********************************************************

.SonnetStart:	setpcireg PICR1				#Setup various PCI registers of the Sonnet
		loadreg r25,VAL_PICR1
		bl	ConfigWrite32

		setpcireg PICR2
		loadreg r25,VAL_PICR2
		bl	ConfigWrite32

		setpcireg PMCR1
		loadreg r25,VAL_PMCR1
		bl	ConfigWrite16

		setpcireg EUMBBAR
		lis	r25,EUMB@h
		bl	ConfigWrite32
		
		la	r14,base_Options(r29)
		lbz	r8,option_VersionNB(r14)
		cmpwi	r8,0x13
		bne	.NoForce
		bl	.DoForceMem
		b	.DoForce

.NoForce:	bl	ConfigMem			#Result = Sonnet Mem Len in r8
.DoForce:	bl	InstallExceptions		#Put exceptions in place

		mr.	r8,r8
		beq	.ErrorRam
		
		lis	r4,0x1000
		cmplw	r8,r4
		ble	.NoMaxRam2
	
		mr	r8,r4				#Limitations of Mediator without bank-switching
		
.NoMaxRam2:	li	r7,0
		
		bl	DirtyMemCheck

		mr	r28,r6

		li	r7,0

		bl	DirtyMemCheck

		cmplw	r28,r6
		beq	.PassedTest1

.MemUnstable:	loadreg	r0,'Err3'
		b	.Unstable

.PassedTest1:	mr	r7,r8
		loadreg	r6,0x100000
		sub	r7,r7,r6
		mr	r31,r7
		
		bl	DirtyMemCheck
		
		mr	r28,r6		
		mr	r7,r31
		
		bl	DirtyMemCheck
		
		cmplw	r28,r6
		beq	.GotRam
		
		b	.MemUnstable

.ErrorRam:	loadreg	r0,'Err2'
.Unstable:	stw	r0,base_Comm(r29)
		b	.ErrorRam

.GotRam:	mr	r28,r8
		lhz	r3,base_RTGType(r29)		#RTGType
		cmpwi	r3,rtgtype_ati			#Check for ATI Gfx Card
		beq	.MaxRam
		cmpwi	r3,rtgtype_voodoo45		#Check for VooDoo4/5
		bne	.NoMaxRam	

.MaxRam:	lis	r4,0x800			#Max 128MB RAM on Sonnet when ATI present
		cmplw	r8,r4
		ble	.NoMaxRam

		mr	r8,r4	

.NoMaxRam:	lis	r27,0x8000			#Upper boundary PCI Memory Mediator
		lwz	r26,base_RTGBase(r29)		#Get gfx mem (RTGBase)
		cmplw	r26,r27
		blt	.CheckJumper			#Is Zorro3
		mr	r8,r28				#Restore full memory range
		lis	r27,0x9000			#Zorro2 plus 256MB ATI
		cmplw	r26,r27
		beq	.GotUpperLimit
		lis	r27,0x9800			#Zorro2 plus 128MB (or less) ATI
		b	.GotUpperLimit
		
.CheckJumper:	rlwinm	r26,r26,4,28,31
		cmpwi	r26,4		
		bne	.NextCheck1
		lis	r27,0x6000			#Config jumper closed
		b	.GotUpperLimit

.NextCheck1:	cmpwi	r26,5
		bne	.NextCheck2
		lis 	r27,0x5000
		b	.GotUpperLimit

.NextCheck2:	cmpwi	r26,3
		bne	.NextCheck3
		lis	r27,0x3000
		mr	r8,r28		
		b	.GotUpperLimit

.NextCheck3:	cmpwi	r26,7
		bne	.GotUpperLimit
		lis	r27,0x7000

.GotUpperLimit:	mr	r26,r8

		li	r28,17
		mtctr	r28
		li	r28,1
		li	r25,29

Loop1:		slw.	r26,r26,r28
		blt	Fndbit
		addi	r25,r25,-1
		bdnz	Loop1
		b	Start				#Error

Fndbit:		slw.	r26,r26,r28
		beq	SetLen
		addi	r25,r25,1

SetLen:		mr	r30,r28
		slw	r30,r30,r25
		slw	r30,r30,r28
		subf	r27,r30,r27

		rlwinm.	r0,r27,1,31,31
		beq	.UpperPCI

		lis	r27,0x1000

.UpperPCI:	lis	r26,EUMB@h
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

		stw	r8,MemSize(r0)		
		stw	r27,base_MemStart(r29)		#MemStart
		stw	r8,base_MemLen(r29)		#MemLen

		bl	mmuSetup			#Setup the Memory Management Unit
		bl	Epic				#Setup the EPIC controller
.SonSkip:	bl	End

#*********************************************************

Start:							#Dummy task at absolute (see ppcdefines)
		nop
		nop
		b	Start

#*********************************************************

End:		mflr	r4

		li	r14,0				#Reset
		mtspr	285,r14				#Time Base Upper,
		mtspr	284,r14				#Time Base Lower and
		loadreg r28,0x7fffffff
		mtdec	r28				#Decrementer.

		lwz	r28,0(r0)			#Get magic word
		stw	r28,base_Comm(r29)		#Signal 68k that PPC is initialized

		loadreg r6,'INIT'
.WInit:		lwz	r28,Init(r0)
		cmplw	r28,r6
		bne	.WInit
		isync					#Wait for 68k to set up library

		loadreg	r3,IdleTask			#Start hardcoded at 0x8000
		lwz	r31,SonnetBase(r0)
		add	r3,r3,r31

		loadreg	r1,SysStack-0x20		#System stack in unused mem (See sonnet.s)
		add	r1,r1,r31
		mr	r31,r3
		
		addi	r5,r4,End-Start
		subf	r5,r4,r5
		li	r6,0
		bl	copy_and_flush			#Put program in PPC Card Mem instead of PCI Mem

		stw	r13,-4(r1)
		subi	r13,r1,4
		stwu	r1,-288(r1)		
				
		lwz	r3,PowerPCBase(r0)

		la	r4,LIST_READYTASKS(r3)		#Set up various used lists
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
		stb	r6,sonnet_AltivecOn(r3)

		li	r6,24
		stb	r6,BusyCounter(r3)

		li	r6,6000
		stw	r6,LowActivityPrio(r3)		#Not used

		lwz	r6,SysBase(r0)
		stw	r6,sonnet_SysBase(r3)

		lwz	r6,DOSBase(r0)
		stw	r6,sonnet_DosBase(r3)
		
		lwz	r6,UtilityBase(r0)
		stw	r6,sonnet_UtilityBase(r3)

		la	r14,base_Options(r29)
		lbz	r6,option_EnDebug(r14)
		stb	r6,sonnet_DebugLevel(r3)

		lbz	r6,option_EnAlignExc(r14)
		stb	r6,sonnet_EnAlignExc(r3)

		lbz	r6,option_EnDAccessExc(r14)
		stb	r6,sonnet_EnDAccessExc(r3)

		lbz	r6,option_DisL2Flush(r14)
		stb	r6,DoDFlushAll(r3)
	
		mfpvr	r4
		rlwinm	r6,r4,16,16,31
		cmplwi	r6,ID_MPC834X
		bne	.NoKillerClock
	
		loadreg	r0,KillerQuantum
		loadreg	r4,KillerBusClock
		
		lis	r14,IMMR_ADDR_DEFAULT
		addi	r14,r14,IMMR_RCWLR
		lwz	r6,0(r14)
		rlwinm.	r6,r6,2,30,31
		beq	.PutClocks

		rlwinm	r0,r0,31,1,31
		rlwinm	r4,r4,31,1,31
		b	.PutClocks
		
.NoKillerClock:	lbz	r6,option_VersionNB(r14)
		loadreg	r0,SonnetQuantum
		loadreg	r4,SonnetBusClock
		cmpwi	r6,0x13
		bne	.PutClocks
		loadreg	r0,RaptureQuantum
		loadreg	r4,RaptureBusClock

.PutClocks:	stw	r0,Quantum(r0)
		stw	r0,sonnet_Quantum(r3)
		stw	r4,sonnet_BusClock(r3)
		mr	r14,r3
		la	r6,SemMemory(r14)
		la	r3,TaskListSem(r14)
		
		mr	r30,r3
		mr	r4,r3
		stw	r4,sonnet_TaskListSem(r14)
		bl	.InitSem

		addi	r4,r30,SSPPC_SIZE
		stw	r4,sonnet_SemListSem(r14)
		addi	r6,r6,32
		bl	.InitSem

		addi	r4,r30,SSPPC_SIZE*2
		stw	r4,sonnet_PortListSem(r14)
		addi	r6,r6,32
		bl	.InitSem
	
		addi	r4,r30,SSPPC_SIZE*3
		stw	r4,sonnet_SnoopSem(r14)
		addi	r6,r6,32
		bl	.InitSem
	
		addi	r4,r30,SSPPC_SIZE*4
		stw	r4,sonnet_MemSem(r14)
		addi	r6,r6,32
		bl	.InitSem
		
		addi	r4,r30,SSPPC_SIZE*5
		stw	r4,sonnet_WaitListSem(r14)
		addi	r6,r6,32
		bl	.InitSem

		mfpvr	r4
		stw	r4,sonnet_CPUInfo(r14)
		
		lwz	r4,MemSize(r0)
		stw	r4,sonnet_MemSize(r14)
		
		lwz	r4,MCPort(r0)
		stw	r4,sonnet_MCPort(r14)
		
		lwz	r4,SonnetBase(r0)
		stw	r4,sonnet_SonnetBase(r14)
			
		mfpvr	r4
		rlwinm	r4,r4,16,16,31
		cmplwi	r4,ID_MPC834X
		beq	.DidFIFOs
				
		lwz	r4,XMPIBase(r0)
		mr.	r4,r4
		bne	.DidFIFOs

		bl	.SetupMsgFIFOs

.DidFIFOs:	lwz	r14,PowerPCBase(r0)				
		lwz	r4,_LVOSetCache+2(r14)

		addi	r6,r4,ViolationOS		
		stw	r6,ViolationAddress(r0)

		addi	r6,r4,TaskStart
		stw	r6,RunPPCStart(r0)

		addi	r6,r4,ListStart
		stw	r6,AdListStart(r0)

		addi	r6,r4,ListEnd
		stw	r6,AdListEnd(r0)

		addi	r6,r4,TaskExit
		stw	r6,sonnet_TaskExitCode(r14)
		
		addi	r6,r4,NiceTable
		stw	r6,Table_NICE(r14)		#NICE values are not used (yet).

		bl	Caches				#Setup the L1 and L2 cache

		mfpvr	r3
		rlwinm	r3,r3,16,16,31
		cmplwi	r3,0x8000
		bne	.AutoDec
		
		mfspr	r3,HID0
		oris	r3,r3,HID0_TBEN@h		#Enable TimeBase and Decrementer
		mtspr	HID0,r3

.AutoDec:	li	r3,0
		loadreg	r0,'REDY'
		stw	r0,Init(r0)
		dcbf	r0,r3
		sync
		
		lwz	r3,PowerPCBase(r0)
		
		mtsrr0	r31

		loadreg	r0,MACHINESTATE_DEFAULT
		mtsrr1	r0				#load up user MSR. Also clears PSL_IP
		
		lwz	r0,Quantum(r0)			#Load time slice
		mtdec	r0

		rfi					#To user code
		
#********************************************************************************************		

.MakeList:	stw	r4,8(r4)			#NewList()
		lis	r0,0	
		stwu	r0,4(r4)
		stw	r4,-4(r4)

		blr

.InitSem:	addi	r5,r4,SS_WAITQUEUE		#InitSemaphore()
		stw	r5,8(r5)
		li	r0,0
		stwu	r0,4(r5)
		stwu	r5,-4(r5)
		li	r0,0
		stw	r0,SS_OWNER(r4)
		sth	r0,SS_NESTCOUNT(r4)
		li	r0,-1
		sth	r0,SS_QUEUECOUNT(r4)
		stw	r6,SSPPC_RESERVE(r4)
		
		blr

#********************************************************************************************		

.SetupMsgFIFOs:	lis	r14,EUMB@h
		
		li	r4,MUCR_CQS_FIFO4K		#4K entries (16k x 4 FIFOs)
		li	r5,MUCR
		stwbrx	r4,r5,r14
		sync

		lwz	r6,SonnetBase(r0)
		lis	r4,0x10
		li	r5,QBAR
		stwbrx	r4,r5,r14
		sync
		
		subi	r4,r4,4
		lis	r5,0x20
		add	r5,r5,r6
		
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

		lis	r14,EUMB@h
		
		li	r5,IFTPR
		li	r4,4096*0+4
		stwbrx	r4,r5,r14
		sync
		
		li	r5,IFHPR
		li	r4,4096*0
		stwbrx	r4,r5,r14
		sync
		
		li	r5,IPTPR
		loadreg	r4,4096*4
		stwbrx	r4,r5,r14
		sync
		
		li	r5,IPHPR
		loadreg	r4,4096*4
		stwbrx	r4,r5,r14
		sync
		
		li	r5,OPTPR
		loadreg	r4,4096*8
		stwbrx	r4,r5,r14
		sync
		
		li	r5,OPHPR
		loadreg	r4,4096*8
		stwbrx	r4,r5,r14
		sync
		
		li	r5,OFTPR
		loadreg	r4,4096*12+4
		stwbrx	r4,r5,r14
		sync
		
		li	r5,OFHPR
		loadreg	r4,4096*12
		stwbrx	r4,r5,r14
		sync

		li	r4,MUCR_CQS_FIFO4K|MUCR_CQE_ENABLE
		li	r5,MUCR
		stwbrx	r4,r5,r14		
		sync

		blr

#********************************************************************************************

.SetupHarFIFOs:	
		lis	r14,PPC_XCSR_BASE@h			#Load Base XCSR
		lwz	r6,base_MemStart(r29)
		lis	r4,0x10
		stw	r4,XCSR_MIQB(r14)			#MIQB on 0x100000
		
		subi	r4,r4,4
		lis	r5,0x20
		add	r5,r5,r6		
		li	r6,4096
		loadreg	r20,(0x180000-4)
		mtctr	r6
		loadreg	r21,(0x140000-4)
		addis	r7,r5,0xc
		loadreg	r22,(0x1c0000-4)
		li	r23,0
		
.FillFIFO:	stwu	r5,4(r4)
		stwu	r7,4(r20)
		stwu	r23,4(r21)
		stwu	r23,4(r22)
		addi	r5,r5,192				#Message Frame Length
		addi	r7,r7,192
		bdnz	.FillFIFO
		
		li	r4,4
		stw	r4,XCSR_MIIFT(r14)

		li	r4,0
		stw	r4,XCSR_MIIFH(r14)
		
		lis	r4,4
		stw	r4,XCSR_MIIPT(r14)
		
		lis	r4,4
		stw	r4,XCSR_MIIPH(r14)

		loadreg	r4,0x80004				#Each FIFO (MIIF, MIIP, MIOF, MIOP) sits on a 256k boundary
		stw	r4,XCSR_MIOFT(r14)
		
		lis	r4,8
		stw	r4,XCSR_MIOFH(r14)
		
		lis	r4,12
		stw	r4,XCSR_MIOPT(r14)
		
		lis	r4,12
		stw	r4,XCSR_MIOPH(r14)

		lis	r4,(XCSR_MICT_ENA|XCSR_MICT_QSZ_16K)@h
		stw	r4,XCSR_MICT(r14)			#enable 4k entries x 4 bytes address = 16k per FIFO

		sync						#Is it safer to clear the empty FIFOs?
		
		blr
#********************************************************************************************

.SetupKillerFIFOs:

		lwz	r6,base_MemStart(r29)
		lis	r4,0x38		
		subi	r4,r4,4
		lis	r5,0x20
		add	r5,r5,r6				#Sonnetbase + 200000: Messages

		li	r6,4096
		loadreg	r20,(0x3a0000-4)
		mtctr	r6
		loadreg	r21,(0x390000-4)
		addis	r7,r5,0xc
		loadreg	r22,(0x3b0000-4)
		li	r23,0
		
.FillKillFIFO:	stwu	r5,4(r4)
		stwu	r7,4(r20)
		stwu	r23,4(r21)
		stwu	r23,4(r22)
		addi	r5,r5,192				#Message Frame Length
		addi	r7,r7,192
		bdnz	.FillKillFIFO

		lwz	r6,base_MemStart(r29)
		addis	r6,r6,0x38

		lis	r23,FIFO_BASE

		addi	r4,r6,4
		stw	r4,FIFO_MIIFT(r23)

		mr	r4,r6
		stw	r4,FIFO_MIIFH(r23)

		addis	r4,r6,1
		stw	r4,FIFO_MIIPT(r23)
		stw	r4,FIFO_MIIPH(r23)

		addis	r4,r6,2		
		stw	r4,FIFO_MIOFH(r23)
		addi	r4,r4,4
		stw	r4,FIFO_MIOFT(r23)

		addis	r4,r6,3
		stw	r4,FIFO_MIOPT(r23)
		stw	r4,FIFO_MIOPH(r23)

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
		
		loadreg	r3,PSL_FP			#Set MPU/MSR to a known state. Turn on FP
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
		
		mfpvr	r4
		rlwinm	r3,r4,16,16,31
		cmplwi	r3,0x8083
		beq	.ExtraBats
		
		rlwinm	r3,r4,8,24,31
		cmpwi	r3,0x70
		bne	.SkipExtraBats

.ExtraBats:	mtspr	ibat4u,r1
		mtspr	ibat5u,r1
		mtspr	ibat6u,r1
		mtspr	ibat7u,r1
		mtspr	ibat4l,r1
		mtspr	ibat5l,r1
		mtspr	ibat6l,r1
		mtspr	ibat7l,r1
		mtspr	dbat4u,r1
		mtspr	dbat5u,r1
		mtspr	dbat6u,r1
		mtspr	dbat7u,r1
		mtspr	dbat4l,r1
		mtspr	dbat5l,r1
		mtspr	dbat6l,r1
		mtspr	dbat7l,r1
		
.SkipExtraBats:	isync
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

Epic:		lis	r26,EUMB@h
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
		sync

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
		lis	r26,EUMBEPICPROC@h

ClearInts:	lwz	r27,0xa0(r26)			#IACKR
		eieio
		clearreg r27
		sync
		stw	r27,0xb0(r26)			#EOI
		bdnz	ClearInts

		blr

#********************************************************************************************

Mpic:		lwz	r26,base_XMPI(r29)
		lwz	r27,XMPI_GLBC(r26)
		oris	r27,r27,XMPI_GLBC_RESET@h
		stw	r27,XMPI_GLBC(r26)		#Reset MPIC

.ResLoopH:	lwz	r27,XMPI_GLBC(r26)
		andis.	r27,r27,XMPI_GLBC_RESET@h
		bne	.ResLoopH			#Wait for reset

		oris	r27,r27,XMPI_GLBC_M@h		#M bit
		stw	r27,XMPI_GLBC(r26)		#Set Mixed Mode

		loadreg r27,XMPI_IFEVP
		loadreg	r28,0x00050042			#80050042
		stwx	r28,r26,r27			#Set Internal Interrupt

		addi	r27,r27,XMPI_IFEDE-XMPI_IFEVP
		li	r28,XMPI_IFEDE_P0		#Destination processor of interrupt
		stwx	r28,r26,r27		

		loadreg	r27,XMPI_P0CTP
		li	r28,0
		stwx	r28,r26,r27			#P0CTP Set Pri (Task) = 0

		lwz	r27,XMPI_FREP(r26)
		rlwinm	r28,r27,16,20,31		#Get FREP(NIRQ)

		mtctr	r28				#Doc says clear all possible ints
		
ClearIntsH:	loadreg	r27,XMPI_P0IAC			#Processor 0 Interrupt Ack
		lwzx	r28,r26,r27	
		loadreg	r27,XMPI_P0EOI			#EOI for processor 0
		li	r28,0
		stwx	r28,r26,r27
		bdnz	ClearIntsH

		lis	r27,PPC_XCSR_BASE@h		#XCSR
		lis	r28,(XCSR_FEEN_MIP|XCSR_FEEN_MIM0)@h
		stw	r28,XCSR_FEEN(r27)		#Turn on FIFO and MSG interrupt
		lis	r28,XCSR_FEMA_MIPM0@h
		stw	r28,XCSR_FEMA(r27)		#Turn off FIFO and MSG interrupt mask

		lis	r28,XCSR_MCSR_OPI@h
		stw	r28,XCSR_MCSR(r27)		#Enable OpenPIC (Must be before clearing ints?)
		
		sync

		blr

#********************************************************************************************

Ipic:		blr

#********************************************************************************************

Caches:				
		mfspr	r4,HID0
		ori	r4,r4,HID0_ICE|HID0_DCE|HID0_SGE|HID0_BTIC|HID0_BHTE
		sync
		mtspr	HID0,r4
		sync

		la	r11,base_Options(r29)

		mfpvr	r4
		rlwinm	r0,r4,16,16,31
		cmplwi	r0,ID_MPC834X			#MPC8343
		li	r30,0
		beq	.ClearOpt

		lbz	r5,option_DisL2Cache(r11)		
		mr.	r5,r5
		li	r30,0
		bne	.ClearOpt

		mfpvr	r4
		rlwinm	r0,r4,8,24,31
		cmpwi	r0,0x70
		beq	.OnDieL2
		rlwinm	r0,r4,16,16,31
		cmplwi	r0,0x8000			#Vger 0x8000
		bne	.NoPPCFX
		
		li	r30,L2_SIZE_QM
		li	r4,0
		b	.DoFX

.OnDieL2:	li	r30,L2_SIZE_HM
#		loadreg r4,L2CR_L2SIZ_HM|L2CR_L2CLK_3|L2CR_L2RAM_BURST
		li	r4,0
		b	.DoFX

.NoPPCFX:	loadreg r4,L2CR_L2SIZ_1M|L2CR_L2CLK_3|L2CR_L2RAM_BURST|L2CR_TS

.DoFX:		mtl2cr	r4				# Set up on chip L2 cache controller.
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

		mr.	r30,r30
		bne	.NoClearOpt

		li	r0,0				#Determine size of L2 Cache
		mr	r5,r0
		mr	r30,r0
		lis	r4,0

		lwz	r6,MemSize(r0)			#Address to start writing
		subis	r6,r6,0x40			#Substract 4 MB
		lwz	r5,SonnetBase(r0)		
		add	r6,r6,r5
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

#		lis	r7,L2CR_L2SIZ_2M@h
#		cmpwi	r30,L2_SIZE_2M
#		beq	.L2SizeDone

		lis	r7,L2CR_L2SIZ_1M@h
		cmpwi	r30,L2_SIZE_1M
		beq	.L2SizeDone
		
		lis	r7,L2CR_L2SIZ_HM@h
		cmpwi	r30,L2_SIZE_HM
		beq	.L2SizeDone
		
		lis	r7,L2CR_L2SIZ_QM@h
		cmpwi	r30,L2_SIZE_QM
		beq	.L2SizeDone
		
		lis	r7,0
		
.L2SizeDone:	mfl2cr	r4
		oris	r4,r4,L2CR_TS@h
		xoris	r4,r4,L2CR_TS@h
		mtl2cr	r4				#Disable Test Support
		sync
		isync
		b	.NoClearOpt
		
.ClearOpt:	stw	r30,option_SetCMemDiv(r11)

.NoClearOpt:	li	r4,8
		slw	r30,r30,r4
		lwz	r4,PowerPCBase(r0)
		stw	r30,sonnet_L2Size(r4)
		stw	r30,sonnet_CurrentL2Size(r4)

		mfpvr	r6
		rlwinm	r10,r6,8,24,31
		cmpwi	r10,0x70
		mfspr	r9,HID1
		beq	.DoFX2

		rlwinm	r10,r6,16,16,31
		cmplwi	r10,0x8000
		bne	.NoFX

		rlwinm	r9,r9,20,27,31
		mflr	r10
		bl	.END_CFG_VGER

		.long	0,0						#For the Modders
.PLL_CFG_VGER:	.long	0b11010,600000000,0b01010,650000000
		.long	0b00100,700000000,0b00010,750000000
		.long	0b11000,800000000,0b01100,850000000
		.long	0b01111,900000000

.END_CFG_VGER:	
		mflr	r6
		li	r8,(.END_CFG_VGER-.PLL_CFG_VGER)/8
		mtctr	r8
		b	.NextPLL

.DoFX2:		rlwinm	r9,r9,5,27,31
		mflr	r10
		bl	.END_CFG_FX

		.long	0,0						#For the Modders
.PLL_CFG_FX:	.long	0b01110,700000000,0b01111,750000000
		.long	0b10000,800000000,0b10001,850000000
		.long	0b10010,900000000,0b10011,950000000
		.long	0b10100,1000000000

.END_CFG_FX:	
		mflr	r6
		li	r8,(.END_CFG_FX-.PLL_CFG_FX)/8
		mtctr	r8
		b	.NextPLL

.KillerStats:	rlwinm	r9,r9,7,25,31
		mflr	r10
		bl	.END_CFG_KILL

		.long	0,0						#For the Modders
.PLL_CFG_KILL:	.long	0b0100011,400000000,0b0100101,333333333

.END_CFG_KILL:	
		mflr	r6
		li	r8,(.END_CFG_KILL-.PLL_CFG_KILL)/8
		mtctr	r8
		b	.NextPLL

.NoFX:		cmplwi	r10,ID_MPC834X
		beq	.KillerStats

		rlwinm	r9,r9,4,28,31
		mflr	r10

		la	r14,base_Options(r29)
		lbz	r6,option_VersionNB(r14)
		cmpwi	r6,0x13
		bne	.Bus66MHz
		bl	.END_CFG_100

		.long	0,0						#For the Modders
.PLL_CFG_100:	.long	0b1110,350000000,0b1010,400000000
		.long	0b0111,450000000,0b1011,500000000
		.long	0b1001,550000000,0b1101,600000000
		.long	0b0101,650000000,0b0010,700000000
		.long	0b0001,750000000,0b1100,800000000
		.long	0b0000,900000000

.END_CFG_100:
		mflr	r6
		li	r8,(.END_CFG_100-.PLL_CFG_100)/8
		mtctr	r8
		b	.NextPLL

.Bus66MHz:	bl	.END_CFG_66
		
		.long	0,0						#For the Modders
.PLL_CFG_66:	.long	0b1101,400000000,0b0001,500000000
		.long	0b0101,433333333,0b0010,466666666
		.long	0b1100,533333333

.END_CFG_66:
		mflr	r6
		li	r8,(.END_CFG_66-.PLL_CFG_66)/8
		mtctr	r8
		
.NextPLL:	lwzu	r8,8(r6)
		cmpw	r9,r8
		beq	.GotMHz
		bdnz	.NextPLL
		li	r9,0				#Unknown speed
		b	.StoreSpeed
		
.GotMHz:	lwz	r9,4(r6)
.StoreSpeed:	stw	r9,sonnet_CPUSpeed(r4)
		lbz	r8,option_SetCMemDiv(r11)
		mr.	r8,r8
		beq	.DoDefSpeed

		cmpwi	r8,5
		beq	.DefL2Speed
		
		cmpwi	r8,4
		lis	r12,L2CR_L2CLK_2_5@h
		beq	.DoSpeed2
		
		cmpwi	r8,3
		lis	r12,L2CR_L2CLK_2@h
		beq	.DoSpeed2
		
		cmpwi	r8,2
		lis	r12,L2CR_L2CLK_1_5@h
		beq	.DoSpeed2

		lis	r12,L2CR_L2CLK_1@h
		cmpwi	r8,1
		beq	.DoSpeed2
		
.DoDefSpeed:	lis	r12,L2CR_L2CLK_2@h
		loadreg	r8,400000000
		cmpw	r8,r9
		bne	.DefL2Speed
		
		lis	r8,L2CR_L2SIZ_1M@h		#check for 400/1MB (= 200MHz cache)
		cmpw	r8,r7
		bne	.DefL2Speed
		
.DoSpeed2:	mfl2cr	r4
		xoris	r4,r4,L2CR_L2CLK_3@h
		or	r4,r4,r12
		b	.DoRestL2

.DefL2Speed:	mfpvr	r4
		rlwinm	r0,r4,16,16,31
		cmplwi	r0,0x8000
		beq	.NoSetSize
		cmplwi	r0,ID_MPC834X
		beq	.NoSetSize

		mfl2cr	r4
.DoRestL2:	xoris	r4,r4,L2CR_L2SIZ_1M@h
		or	r4,r4,r7
		mtl2cr	r4				#Set correct size, switch Test off and enable
		
.NoSetSize:	sync
		isync
		
		mtlr	r10
		
		blr

#********************************************************************************************
	
mmuSetup:	
		mflr	r30
		
		lwz	r6,MemSize(r0)
		cntlzw	r4,r6
		li	r3,24
		sub	r5,r3,r4
		li	r4,1
		rlwnm	r6,r4,r5,0,31				#r6 = Amount of memory to virtualize
		stw	r6,PageTableSize(r0)

		bl	.SetupPT

		mfpvr	r4
		rlwinm	r4,r4,16,16,31
		cmplwi	r4,ID_MPC834X
		lis	r3,IMMR_ADDR_DEFAULT
		beq	.mmuDo

		lwz	r3,base_XMPI(r29)
		mr.	r3,r3
		beq	.mmuMPC107
		
		addis	r4,r3,0x40
		mr	r5,r3
		loadreg	r6,PTE_CACHE_INHIBITED|PTE_GUARDED
		li	r7,PP_SUPERVISOR_RW

		bl	.DoTBLs

 		lis	r3,PPC_XCSR_BASE@h
		b	.mmuDo

.mmuMPC107:	lis	r3,EUMB@h				#PCI memory (EUMB) start effective address
.mmuDo:		addis	r4,r3,0x10				#end effective address
		mr	r5,r3					#start physical address
		loadreg	r6,PTE_CACHE_INHIBITED|PTE_GUARDED	#WIMG
		li	r7,PP_USER_RW				#pp = 2 - Read/Write Access (0 = No Access)

		bl	.DoTBLs

		lis	r3,0xfff0				#Fake ROM (128k)
		lis	r4,0xfff2
		mr	r5,r3
		loadreg	r6,PTE_CACHE_INHIBITED
		li	r7,PP_USER_RW

		bl	.DoTBLs

		lhz	r3,base_RTGType(r29)
		cmpwi	r3,rtgtype_ati
		bne	.DoInhibit

		lwz	r24,base_RTGBase(r29)
		b	.No3DFX

.DoInhibit:	loadreg	r6,PTE_CACHE_INHIBITED|PTE_GUARDED		
		cmpwi	r3,rtgtype_voodoo45		#Config (Avenger)
		lwz	r3,base_RTGBase(r29)
		addis	r4,r3,0x200
		bne	.Voodoo3
		addis	r4,r4,0x600
.Voodoo3:	mr	r24,r4
		addis	r5,r3,0x6000
		li	r7,PP_USER_RW

		bl	.DoTBLs

		lhz	r3,base_RTGType(r29)
		cmpwi	r3,rtgtype_voodoo3
		beq	.Is3DFX
		cmpwi	r3,rtgtype_voodoo45
		bne	.No3DFX

		lwz	r3,base_RTGBase(r29)		#32MB Video RAM (Napalm)
		addis	r3,r3,0x800
		addis	r4,r3,0x200
		addis	r5,r3,0x6000

		li	r17,BAT_READ_WRITE
		li	r18,BAT_BL_32M | BAT_VALID_SUPERVISOR | BAT_VALID_USER
		li	r19,BAT_WRITE_THROUGH | BAT_READ_WRITE
		li	r20,BAT_BL_32M | BAT_VALID_SUPERVISOR | BAT_VALID_USER

		or	r17,r17,r5
		or	r18,r18,r3
		or	r19,r19,r5
		or	r20,r20,r3

		mtspr	ibat1l,r17
		mtspr	ibat1u,r18
		mtspr	dbat1l,r19
		mtspr	dbat1u,r20

		sync
		isync

		b	.No3DFX
		
.Is3DFX:	lwz	r3,base_RTGBase(r29)		#32MB Video RAM (Avenger)
		addis	r3,r3,0x200
		addis	r4,r3,0x200
		addis	r5,r3,0x6000
		
		li	r17,BAT_READ_WRITE
		li	r18,BAT_BL_32M | BAT_VALID_SUPERVISOR | BAT_VALID_USER
		li	r19,BAT_WRITE_THROUGH | BAT_READ_WRITE
		li	r20,BAT_BL_32M | BAT_VALID_SUPERVISOR | BAT_VALID_USER
		
		or	r17,r17,r5
		or	r18,r18,r3
		or	r19,r19,r5
		or	r20,r20,r3
		
		mtspr	ibat1l,r17
		mtspr	ibat1u,r18
		mtspr	dbat1l,r19
		mtspr	dbat1u,r20

		sync
		isync

.No3DFX:	lhz	r3,base_RTGType(r29)
		cmpwi	r3,rtgtype_ati
		bne	.NoATI

		lwz	r3,base_RTGConfig(r29)
		addis	r5,r3,0x6000
		addis	r4,r3,0x1			#64k config RAM (ATI) -> NO LONGER WORKING
		loadreg	r6,PTE_CACHE_INHIBITED|PTE_GUARDED
		li	r7,PP_USER_RW

		bl	.DoTBLs

		lwz	r3,base_RTGBase(r29)
		rlwinm.	r0,r3,5,31,31			#Test for split memory
		bne	.Split128

		lwz	r3,base_RTGConfig(r29)
		rlwinm.	r0,r3,5,31,31			#Test for split memory
		bne	.Split128

		li	r17,BAT_READ_WRITE
		li	r18,BAT_BL_256M | BAT_VALID_SUPERVISOR | BAT_VALID_USER
		li	r19,BAT_WRITE_THROUGH | BAT_READ_WRITE
		li	r20,BAT_BL_256M | BAT_VALID_SUPERVISOR | BAT_VALID_USER

.ReUseSetup:	mr	r3,r24				#256MB (or 2x128MB) Video RAM (ATI)
		addis	r5,r3,0x6000

		or	r17,r17,r5
		or	r18,r18,r3
		or	r19,r19,r5
		or	r20,r20,r3

		mtspr	ibat1l,r17
		mtspr	ibat1u,r18
		mtspr	dbat1l,r19
		mtspr	dbat1u,r20

		sync
		isync

		b	.NoATI

.Split128:	li	r17,BAT_READ_WRITE
		li	r18,BAT_BL_128M | BAT_VALID_SUPERVISOR | BAT_VALID_USER
		li	r19,BAT_WRITE_THROUGH | BAT_READ_WRITE
		li	r20,BAT_BL_128M | BAT_VALID_SUPERVISOR | BAT_VALID_USER

		b	.ReUseSetup			#NEED TO SETUP 2nd 128MB STILL WHEN APPLICABLE

.NoATI:		li	r3,0				#First 2MB cached - user protected - Directs to CHIP
		mr	r5,r3

		li	r17,BAT_READ_WRITE
		li	r18,BAT_BL_2M | BAT_VALID_SUPERVISOR

		or	r17,r17,r5
		or	r18,r18,r3

		mtspr	ibat0l,r17
		mtspr	ibat0u,r18
		mtspr	dbat0l,r17
		mtspr	dbat0u,r18

		sync
		isync
		
		lis	r3,0x20				#Messages (2MB no data cache)
		mr	r5,r3
		add	r3,r3,r27

		li	r17,BAT_READ_WRITE
		li	r18,BAT_BL_2M | BAT_VALID_SUPERVISOR | BAT_VALID_USER
		li	r19,BAT_CACHE_INHIBITED | BAT_READ_WRITE
		li	r20,BAT_BL_2M | BAT_VALID_SUPERVISOR | BAT_VALID_USER

		or	r17,r17,r5
		or	r18,r18,r3
		or	r19,r19,r5
		or	r20,r20,r3

		mtspr	ibat2l,r17
		mtspr	ibat2u,r18
		mtspr	dbat2l,r19
		mtspr	dbat2u,r20

		sync
		isync
		
		lwz	r19,base_SizeBAT(r29)
		mr.	r19,r19
		beq	.DoneVGAMem
		
		lhz	r3,base_RTGType(r29)
		cmpwi	r3,rtgtype_ati
		beq	.DoneVGAMem			#If ATI primary card, then skip

		lwz	r3,base_StartBAT(r29)
		addis	r5,r3,0x6000
		li	r17,BAT_CACHE_INHIBITED | BAT_READ_WRITE
		li	r18,BAT_BL_64M | BAT_VALID_SUPERVISOR | BAT_VALID_USER
		subi	r19,r19,1
		mr.	r19,r19
		beq	.DoVGAMem

		li	r18,BAT_BL_128M | BAT_VALID_SUPERVISOR | BAT_VALID_USER
		subi	r19,r19,1
		mr.	r19,r19
		beq	.DoVGAMem

		li	r18,BAT_BL_256M | BAT_VALID_SUPERVISOR | BAT_VALID_USER

.DoVGAMem:	or	r17,r17,r5
		or	r18,r18,r3
		or	r20,r20,r5
		
		mtspr	ibat3l,r17
		mtspr	ibat3u,r18
		mtspr	dbat3l,r17
		mtspr	dbat3u,r18

		sync
		isync

.DoneVGAMem:	lis	r3,0x40				#PPC card memory (Rest cached)
		lwz	r4,MemSize(r0)
		mr	r5,r3
		add	r3,r3,r27
		add	r4,r4,r27

		li	r6,PTE_COPYBACK
		li	r7,PP_USER_RW

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

.SetupPT:	mr	r23,r8				#Save ppc card memory size
		rlwinm.	r8,r6,20,12,31			#is pt_size >= 64 KB
		bne	.Cont
		lis	r6,0x10
		
.Cont:		mr	r3,r23				#Size of ppc card memory

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
		mtsdr1	r15				#set SDR1	
		isync

		rlwinm	r6,r6,30,0,31			#r6 = pt_size, r7 = pt_loc
		mtctr	r6
		xor	r8,r8,r8
		subi	r7,r7,4
		
.zero_out:	stwu	r8,4(r7)
		bdnz	.zero_out

		li	r6,16				#set up SR registers
		mtctr	r6
		li	r5,0
		lis	r4,0x2000			#set ks and kp (0x6000 = 11; 0x4000 = 10 etc.)
.srx_set:	mtsrin	r4,r5
		addi	r4,r4,1
		addis	r5,r5,0x1000
		bdnz	.srx_set
		blr
		
#********************************************************************************************		
		
.DoTBLs:	mr	r17,r3				#SHOULD IMPLEMENT TURBO MODE (THROUGH BATS)
		mr	r18,r4
		mr	r19,r5
		mr	r20,r6
		mr	r21,r7
		mflr	r22
		
.load_PTEs:	cmplw	r3,r4
		bge	.ExitTBL
		
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
		
		mfsdr1	r15				#Calculate PTEG address
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
		stw	r0,base_Comm(r29)
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

DirtyMemCheck:
		li	r6,0
		loadreg r21,0x40000
		mtctr	r21

		lwz	r20,0(r7)
.SimpleAdd:	add	r6,r6,r20
		lwzu	r20,4(r7)
		bdnz	.SimpleAdd
		blr

#********************************************************************************************	

.DoForceMem:	mflr	r15

		setpcireg MCCR4
#		loadreg	r25,0x35323239		#from examples on internet
		loadreg	r25,0x35303232
		bl	ConfigWrite32

		setpcireg MCCR3
		lis	r25,0x7840
		bl	ConfigWrite32

		setpcireg MCCR2
#		loadreg	r25,0x044004cc		#33MHz
		loadreg	r25,0x04400700		#Fastest & stable?
#		loadreg r25,0x0440150c		#100MHz
		bl	ConfigWrite32

		lis	r26,0x7588
		loadreg	r28,0xaaaa		#13x4
		li	r30,0x5555		#13x2/12x2
		li	r31,0x0000		#12x4/11x4

		b	.EndForce

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
		la	r3,base_Options(r29)
		lbz	r4,option_EnEDOMem(r3)
		mr.	r4,r4
		beq	.DoFPMMem
		lis	r3,1
		or	r25,r25,r3		#Enable EDO
		
.DoFPMMem:	bl	ConfigWrite32		#set MCCR2 to 0xE0001040
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
						
		lis	r26,0xffea
		loadreg	r28,0xffff		#13
		loadreg	r30,0xaaaa		#11
		li	r31,0x5555		#11

						
.EndForce:	bl	.DetectMemSize

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

		setpcireg PGMAX				#A3
		li	r25,0x32
		bl	ConfigWrite8

		setpcireg MBEN				#A0
		mr	r25,r14
		bl	ConfigWrite8

		lis	r7,1
		mtctr	r7
		
.MPC107Wait200us:
		bdnz	.MPC107Wait200us

		setpcireg MCCR1				#F0		
		mr	r25,r13
		bl	ConfigWrite32

		loadreg	r7,0x2ffff
		mtctr	r7
.MPC107Wait8Ref:
		bdnz	.MPC107Wait8Ref

		mtlr	r15
		
		blr

#********************************************************************************************

.DetectMemSize:	mflr	r27

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
		loadreg	r25,0xffffffff
		bl	ConfigWrite32		#set MEAR1 to ffffffff

		setpcireg MEEAR1
		clearreg r25
		bl	ConfigWrite32		#clear EMEAR1

		setpcireg MEAR2
		loadreg	r25,0xffffffff
		bl	ConfigWrite32		#set MEAR2 to ffffffff

		setpcireg MEEAR2
		clearreg r25
		bl	ConfigWrite32		#clear EMEAR2

		setpcireg MCCR1
		mr	r25,r26
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
		mr	r13,r26
		li	r14,0
		li	r16,0
		li	r17,0
		li	r18,0
		li	r19,0

loc_3BD8:	setpcireg MBEN			#Memory Bank Enable Register
		mr	r25,r5
		bl	ConfigWrite8		#enable Bank as given in r5

		stw	r4,0(r3)		#try to store "Boon" at address 0x0
		eieio
	
		stw	r3,4(r3)		#try to store 0x0 at 0x4
		eieio
		lwz	r7,0(r3)		#read from 0x0
		cmplw	r4,r7			#is it "Boon", long compare
		bne	loc_4184
	
		or	r14,r14,r5		#continue if found
	
		setpcireg MCCR1			#0x800000f0
		or	r25,r26,r28
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
		lis	r6,0x1000
		cmpwi	r7,0
		beq	loc_3E24
		b	loc_4184		#goto loc_4184

#********************************************************************************************
loc_3CBC:					#CODE XREF: findSetMem+1D0
		or	r25,r26,r30
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
		or	r25,r26,r31
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

#********************************************************************************************
loc_4184:	
		slwi	r5,r5,1
		cmplwi	r5,0x100
		bne	loc_3BD8
		
		mtlr	r27
		
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
		b	.VMXUnav			#34
		b	.ITLBMiss			#38
		b	.DLoadTLBMiss			#3c
		b	.DStoreTLBMiss			#40

		mtsprg0	r0				#44

		mfsrr0	r0
		stw	r0,Exc_srr0(r0)
		mfsrr1	r0
		stw	r0,Exc_srr1(r0)

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0				#Reenable MMU
		isync					#Also reenable FPU
		sync

		mfsprg0	r0

		stwu	r1,-1088(r1)
		stw	r4,40(r1)
		stw	r3,44(r1)
		stw	r0,48(r1)
		mfcr	r0
		stw	r0,52(r1)
		mfxer	r0
		stw	r0,64(r1)

		mfpvr	r4
		rlwinm	r0,r4,16,16,31
		cmplwi	r0,ID_MPC834X
		beq	.HandleKiller

		lwz	r3,XMPIBase(r0)
		mr.	r3,r3
		beq	.HandleSonnI

		lis	r3,PPC_XCSR_BASE@h
		lwz	r4,XCSR_FEST(r3)
		andis.	r0,r4,XCSR_FEST_MIM0@h		#From CausePPCInterrupt on Harrier
		b	.DoneIMH

.HandleKiller:	lis	r3,IMMR_ADDR_DEFAULT
		ori	r3,r3,IMMR_IMISR
		lwbrx	r4,r0,r3		
		andi.	r4,r4,IMMR_IMISR_IDI		#From CausePPInterrupt on MPC8343E
		b	.DoneIMH

.HandleSonnI:	lis	r3,EUMB@h
		li	r4,IMISR
		lwbrx	r3,r3,r4
		andi.	r0,r3,IMISR_IM0I		#From CausePPCInterrupt MPC107
.DoneIMH:	lwz	r3,PowerPCBase(r0)
		beq	.NoEHandler

.EHandler:	li	r0,0
		stb	r0,sonnet_ExternalInt(r3)
		li	r0,EXCF_INTERRUPT
		stw	r0,60(r1)
		la	r4,LIST_EXCINTERRUPT(r3)
		b	.CommonHandler

.NoEHandler:	li	r0,-1
		stb	r0,sonnet_ExceptionMode(r3)
		stw	r5,36(r1)
		stw	r6,32(r1)

#***********************************************		

.DoEInt:	lwz	r3,44(r1)
		lwz	r4,40(r1)
		lwz	r5,36(r1)
		lwz	r6,32(r1)
		lwz	r0,52(r1)
		mtcr	r0
		lwz	r0,64(r1)
		mtxer	r0
		lwz	r0,48(r1)
		lwz	r1,0(r1)
		
#***********************************************

		mtsprg0	r0

		stwu	r1,-288(r1)

		prolog	228,'TOC'
		
		mfxer	r0
		stwu	r0,-4(r13)
		
		bl	.TaskStats

		stwu	r3,-4(r13)
		stwu	r4,-4(r13)
		stwu 	r5,-4(r13)
		stwu	r6,-4(r13)
		stwu	r7,-4(r13)
		stwu	r8,-4(r13)
		stwu	r9,-4(r13)
		stwu	r10,-4(r13)

		loadreg	r3,'EXEX'
		stw	r3,0xf4(r0)

		li	r5,-1
		lwz	r10,PowerPCBase(r0)
		stb	r5,sonnet_ExceptionMode(r10)
		
		mfpvr	r3
		rlwinm	r5,r3,16,16,31
		cmplwi	r5,ID_MPC834X
		beq	.KillerAck
		
		lwz	r3,XMPIBase(r0)
		mr.	r3,r3
		beq	.SonnAck

		loadreg	r4,XMPI_P0IAC
		lwzx	r5,r3,r4		
		b	.HarrAck

.SonnAck:	lis	r3,EUMBEPICPROC@h
		lwz	r5,EPIC_IACK(r3)		#Read IACKR to acknowledge interrupt

		rlwinm	r5,r5,8,0,31
		cmpwi	r5,0x00ff			#Spurious Vector. Should not do EOI acc Docs.
		beq	.SlowReturn
		
		lis	r3,EUMB@h
		li	r4,IMISR
		lwbrx	r5,r4,r3
		andi.	r9,r5,IMISR_IM0I
		beq	.CheckQueue

		mr	r9,r5
		li	r5,IMISR_IM0I|IMISR_IM1I
		stwbrx	r5,r4,r3			#Clear IM0/IM1 bit to clear interrupt
		sync					#IMR0 is used by CausePPCInterrupt
		mr	r5,r9	
	
.CheckQueue:	andi.	r9,r5,IMISR_IPQI
		beq	.EndQueue

		li	r4,IPHPR			
		lwbrx	r9,r4,r3
		li	r4,IPTPR			#Get message from Inbound FIFO
		lwbrx	r5,r4,r3		
		cmpw	r5,r9				#Check if interrupt was triggered
		beq	.EndQueue			#during previous interrupt

.QNotEmpty:	addi	r9,r5,4				#Increase FIFO pointer
		li	r4,0x4000
		or	r9,r9,r4
		loadreg r4,0xffff7fff
		and	r9,r9,r4			#Keep it 4000-7FFE		
		sync
		lwz	r5,0(r5)

		la	r4,LIST_MSGQUEUE(r10)
		addi	r4,r4,4				#PutMsg r5 to queue
		lwz	r3,4(r4)			#AddTailPPC
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
		
		lis	r3,EUMB@h			#Check if header (IPHPR) is equal to
		li	r4,IPHPR			#tail (IPTPR). If so, queue is empty
		lwbrx	r5,r4,r3
		cmpw	r5,r9

		beq	.QEmpty
		
		mr	r5,r9
		b	.QNotEmpty

.QEmpty:	li	r4,IPTPR
		stwbrx	r9,r4,r3
		sync
		
.EndQueue:	lis	r3,EUMB@h
		li	r4,IMISR
		li	r5,IMISR_IPQI			#Clear IPQI bit to clear interrupt
		stwbrx	r5,r4,r3		
		sync

		clearreg r5
		lis	r3,EUMBEPICPROC@h
		stw	r5,EPIC_EOI(r3)			#Write 0 to EOI to End Interrupt
		sync
		b	.StartQ

#**********************************************************

.KillerAck:	lis	r9,IMMR_ADDR_DEFAULT
		ori	r3,r9,IMMR_IMISR
		lwbrx	r4,r0,r3		
		andi.	r4,r4,IMMR_IMISR_IDI	
		beq	.NoDoorBell

		li	r4,1
		ori	r3,r9,IMMR_IDR
		stwbrx	r4,r0,r3			#Acknowledge Doorbell

.NoDoorBell:	lwz	r3,SonnetBase(r0)
		addis	r3,r3,FIFO_BASE
		lwz	r9,FIFO_MIIPH(r3)
		lwz	r5,FIFO_MIIPT(r3)
		cmpw	r5,r9
		beq	.EndQueueK
		
.QNotEmptyK:	addi	r9,r5,4				#Increase FIFO pointer
		loadreg	r4,0xffff3fff
		and	r9,r9,r4			#Keep it below 0x4000
		lwz	r5,0(r5)

		la	r4,LIST_MSGQUEUE(r10)
		addi	r4,r4,4				#PutMsg r5 to queue
		lwz	r3,4(r4)			#AddTailPPC
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)

		lwz	r3,SonnetBase(r0)
		addis	r3,r3,FIFO_BASE
		lwz	r5,FIFO_MIIPH(r3)		#Check if header is equal to tail. If so, queue is empty
		cmpw	r5,r9
		beq	.QEmptyK
		
		mr	r5,r9
		b	.QNotEmptyK

.QEmptyK:	stw	r9,FIFO_MIIPT(r3)
		lis	r3,IMMR_ADDR_DEFAULT
		ori	r3,r3,IMMR_IMISR
		li	r5,IMMR_IMISR_IM0I
		stwbrx	r5,r0,r3			#Acknowledge message

.EndQueueK:	b	.StartQ

#**********************************************************

.HarrAck:	cmpwi	r5,0x00ff			#Spurious Vector. Should not do EOI acc Docs.
		beq	.SlowReturn

		lis	r3,PPC_XCSR_BASE@h
		lwz	r4,XCSR_FEST(r3)
		andis.	r0,r4,XCSR_FEST_MIM0@h		#From CausePPCInterrupt on Harrier
		beq	.NoMsgClearIH

		lis	r9,XCSR_FECL_MIM0@h
		stw	r9,XCSR_FECL(r3)		#Clear CausePPCInterrupt on Harrier

.NoMsgClearIH:	andis.	r0,r4,XCSR_FEST_MIP@h
		beq	.EndQueueH

		lwz	r9,XCSR_MIIPH(r3)
		lwz	r5,XCSR_MIIPT(r3)
		cmpw	r5,r9
		beq	.EndQueueH			#FIFO Empty? Shouldn't be on Harrier.

.QNotEmptyH:	addi	r9,r5,4				#Increase FIFO pointer
		loadreg	r4,0xffff3fff
		and	r9,r9,r4			#Keep it below 0x4000
		lwz	r5,0(r5)

		la	r4,LIST_MSGQUEUE(r10)
		addi	r4,r4,4				#PutMsg r5 to queue
		lwz	r3,4(r4)			#AddTailPPC
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
				
		lis	r3,PPC_XCSR_BASE@h
		lwz	r5,XCSR_MIIPH(r3)		#Check if header is equal to tail. If so, queue is empty
		cmpw	r5,r9
		beq	.QEmptyH
		
		mr	r5,r9
		b	.QNotEmptyH

.QEmptyH:	stw	r9,XCSR_MIIPT(r3)
		
.EndQueueH:	lwz	r3,XMPIBase(r0)
		clearreg r5
		loadreg	r4,XMPI_P0EOI			#Write 0 to EOI to End Interrupt
		stwx	r5,r3,r4

#**********************************************************

.StartQ:	lwz	r10,PowerPCBase(r0)

		lwz	r4,sonnet_Atomic(r10)		#If atomic is set, return to current task
		mr.	r4,r4
		bne-	.QuickReturn
		isync

		lwz	r9,Exc_srr0(r0)
		lwz	r4,AdListStart(r0)
		cmpw	r9,r4
		blt	.SkipListChk
		
		lwz	r4,AdListEnd(r0)
		cmpw	r9,r4
		blt	.QuickReturn

.SkipListChk:	la	r4,LIST_MSGQUEUE(r10)
		lwz	r5,0(r4)
.NxtInQ:	lwz	r9,0(r5)			#get next message
		mr.	r9,r9
		beq-	.EndMsgQueue

		loadreg	r4,'TPPC'
		lwz	r6,MN_IDENTIFIER(r5)
		cmpw	r4,r6				#A RunPPC request
		beq	.MsgTPPC
	
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

		loadreg	r4,'LLPP'			#Cross-signaling
		cmpw	r4,r6
		beq	.XSignal

		b	.RelFrame
		
#**********************************************************

.XSignal:	lwz	r3,MN_ARG1(r5)			#68K mirror task
		lwz	r4,ThisPPCProc(r10)		#Check for it in the running task
		lwz	r8,TASKPPC_MIRROR68K(r4)
		cmpw	r8,r3
		bne	.ChkWait
		
		li	r3,TS_RUN
		stb	r3,TC_STATE(r4)			#To negate a potential TS_CHANGING
	
.ReUseLoop:	lwz	r3,MN_ARG0(r5)			#Signals received by the 68K task
		lwz	r8,TC_SIGRECVD(r4)		#Copy to PPC task
		or	r8,r8,r3
		stw	r8,TC_SIGRECVD(r4)
		b	.RelFrame
		
.ChkWait:	la	r4,LIST_WAITINGTASKS(r10)	#Check for it in the waiting tasks
		lwz	r4,0(r4)
.ChkNextSig:	lwz	r7,0(r4)
		mr.	r7,r7				#Check for the end of the list
		beq	.ChkRdy		
		lwz	r8,TASKPPC_MIRROR68K(r4)
		cmpw	r8,r3
		beq	.SetReady
		mr	r4,r7
		b	.ChkNextSig
		
.SetReady:	li	r3,TS_READY
		stb	r3,TC_STATE(r4)
		b	.ReUseLoop	
		
.ChkRdy:	la	r4,LIST_READYTASKS(r10)		#Check for it in the ready tasks
		lwz	r4,0(r4)
.ChkRdySig:	lwz	r7,0(r4)
		mr.	r7,r7				#Check for the end of the list
		beq	.RelFrame
		lwz	r8,TASKPPC_MIRROR68K(r4)
		cmpw	r8,r3
		beq	.ReUseLoop
		mr	r4,r7
		b	.ChkRdySig

#**********************************************************	

.RelFrame:	mr	r4,r5
		lwz	r3,0(r4)			#RemovePPC
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)
	
		loadreg	r3,'FREE'
		stw	r3,MN_IDENTIFIER(r5)
	
		mfpvr	r4
		rlwinm	r4,r4,16,16,31
		cmplwi	r4,ID_MPC834X
		bne	.RelFrameH

		lwz	r3,SonnetBase(r0)
		addis	r3,r3,FIFO_BASE
		lwz	r6,FIFO_MIIFH(r3)
		stw	r5,0(r6)
		addi	r8,r6,4
		loadreg	r4,0xffff3fff
		and	r8,r8,r4
		stw	r8,FIFO_MIIFH(r3)
		b	.RelledH
	
.RelFrameH:	lwz	r4,XMPIBase(r0)
		mr.	r4,r4
		beq	.RelFrameS
	
		lis	r3,PPC_XCSR_BASE@h
		lwz	r6,XCSR_MIIFH(r3)
		stw	r5,0(r6)
		addi	r8,r6,4
		andi.	r8,r8,0x3fff
		stw	r8,XCSR_MIIFH(r3)
		b	.RelledH
	
.RelFrameS:	lis	r3,EUMB@h			#Free the message
		li	r4,IFHPR
		lwbrx	r6,r4,r3		
		stw	r5,0(r6)		
		addi	r8,r6,4
		li	r7,0x3fff
		and	r8,r8,r7			#Keep it 0000-3FFE
		stwbrx	r8,r4,r3
.RelledH:	sync

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
		addi	r8,r8,1
		extsh.	r0,r8
		bne	.Oopsie

		lhz	r6,MN_ARG1(r5)
		lwz	r7,MN_ARG2(r5)
		rlwinm	r8,r6,27,5,31			#Determine number of cachelines
		mfctr	r6
		mtctr	r8
				
.InvRXMsg:	dcbi	r0,r7				#invalidate the cachelines
		addi	r7,r7,L1_CACHE_LINE_SIZE
		bdnz+	.InvRXMsg
	
		mtctr	r6
			
		lwz	r7,MN_ARG2(r5)
		
		mr	r4,r5
		lwz	r3,0(r4)			#RemovePPC
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)

		loadreg	r3,'FREE'
		stw	r3,MN_IDENTIFIER(r5)

		mfpvr	r4
		rlwinm	r4,r4,16,16,31
		cmplwi	r4,ID_MPC834X
		bne	.RelRxMsgH

		lwz	r3,SonnetBase(r0)
		addis	r3,r3,FIFO_BASE
		lwz	r6,FIFO_MIIFH(r3)
		stw	r5,0(r6)
		addi	r8,r6,4
		loadreg	r4,0xffff3fff
		and	r8,r8,r4
		stw	r8,FIFO_MIIFH(r3)
		b	.ContRXMsg

.RelRxMsgH:	lwz	r4,XMPIBase(r0)
		mr.	r4,r4
		beq	.RelRxMsgS
	
		lis	r3,PPC_XCSR_BASE@h
		lwz	r6,XCSR_MIIFH(r3)
		stw	r5,0(r6)
		addi	r8,r6,4
		andi.	r8,r8,0x3fff
		stw	r8,XCSR_MIIFH(r3)
		b	.ContRXMsg

.RelRxMsgS:	lis	r3,EUMB@h			#Free the message
		li	r4,IFHPR
		lwbrx	r6,r4,r3		
		stw	r5,0(r6)		
		addi	r8,r6,4
		li	r6,0x3fff
		and	r8,r8,r6			#Keep it 0000-3FFE
		stwbrx	r8,r4,r3
		
.ContRXMsg:	sync	
		lwz	r4,MN_REPLYPORT(r7)
		mr	r5,r7
		lwz	r3,MP_SIGTASK(r4)
		mr.	r3,r3
		beq	.Oopsie

		lwz	r6,ThisPPCProc(r10)
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
		addi	r8,r8,1
		extsh.	r0,r8
		bne	.Oopsie

		lwz	r3,MP_SIGTASK(r4)
		mr.	r3,r3
		beq	.RelFrame

		mtlr	r4
		mr	r4,r5
		lwz	r3,0(r4)			#RemovePPC
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)

		lhz	r6,MN_ARG1(r5)			#Length of message
		lwz	r7,MN_ARG2(r5)			#Address of message

		rlwinm	r8,r6,27,5,31			#Determine number of cachelines
		mfctr	r6
		mtctr	r8

.InvXMsg:	dcbi	r0,r7				#invalidate the cachelines
		addi	r7,r7,L1_CACHE_LINE_SIZE
		bdnz+	.InvXMsg

		mtctr	r6

		lwz	r7,MN_ARG2(r5)
		loadreg	r3,'FREE'
		stw	r3,MN_IDENTIFIER(r5)

		mfpvr	r4
		rlwinm	r4,r4,16,16,31
		cmplwi	r4,ID_MPC834X
		bne	.RelInvXMsgH

		lwz	r3,SonnetBase(r0)
		addis	r3,r3,FIFO_BASE
		lwz	r6,FIFO_MIIFH(r3)
		stw	r5,0(r6)
		addi	r8,r6,4
		loadreg	r4,0xffff3fff
		and	r8,r8,r4
		stw	r8,FIFO_MIIFH(r3)
		b	.ContInvXMsg

.RelInvXMsgH:	lwz	r4,XMPIBase(r0)
		mr.	r4,r4
		beq	.RelInvXMsgS
	
		lis	r3,PPC_XCSR_BASE@h
		lwz	r6,XCSR_MIIFH(r3)
		stw	r5,0(r6)
		addi	r8,r6,4
		andi.	r8,r8,0x3fff
		stw	r8,XCSR_MIIFH(r3)
		b	.ContInvXMsg

.RelInvXMsgS:	lis	r3,EUMB@h			#Free the message
		li	r4,IFHPR
		lwbrx	r6,r4,r3		
		stw	r5,0(r6)		
		addi	r8,r6,4
		li	r6,0x3fff
		and	r8,r8,r6			#Keep it 0000-3FFE
		stwbrx	r8,r4,r3
		
.ContInvXMsg:	sync
		mr	r5,r7
		mflr	r4
		lwz	r3,MP_SIGTASK(r4)

		b	.PutMsgIt			#Go to signalling code

#**********************************************************
		
.Done68:	lwz	r4,MN_PPC(r5)			#Handles the reply on a Run68K
		lwz	r6,TASKPPC_MSGPORT(r4)
		addi	r6,r6,MP_PPC_SEM
		lha	r8,SS_QUEUECOUNT(r6)
		addi	r8,r8,1
		extsh.	r0,r8
		bne	.Oopsie

		mr	r6,r4
		mr	r4,r5
		lwz	r3,0(r4)			#RemovePPC
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)

		mr	r4,r6
		lwz	r6,ThisPPCProc(r10)
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

		la	r6,LIST_NEWTASKS(r10)		#Handles a RunPPC

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
		
.EndMsgQueue:	lwz	r9,ThisPPCProc(r10)
		mr.	r9,r9
		beq	.NoAtomicTask

		lbz	r5,TC_STATE(r9)
		cmpwi	r5,TS_ATOMIC
		beq	.SlowReturn			##Needs fix/implementation

.NoAtomicTask:	lwz	r5,sonnet_TaskExcept(r10)	##Needs implementation
		mr.	r5,r5
		bne	.TaskException

.RTaskExc:	lbz	r5,FLAG_WAIT(r10)
		mr.	r5,r5
		bne	.NoWaitTime
		
		la	r4,LIST_WAITTIME(r10)
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
		lwz	r9,ThisPPCProc(r10)
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
		la	r4,LIST_WAITINGTASKS(r10)
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
		la	r4,LIST_READYTASKS(r10)
		
		addi	r4,r4,4				#AddTailPPC
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)

		mr	r4,r7

		b	.NextOnList

.EndOfWaitList:	lwz	r9,ThisPPCProc(r10)

		b	.TrySwitch
		
.Dispatch:	lwz	r8,MN_ARG0(r9)
		lwz	r4,IdDefTasks(r10)
		addi	r4,r4,1
		stw	r4,IdDefTasks(r10)
		stw	r4,TASKPPC_ID(r8)
		stw	r10,TASKPPC_POWERPCBASE(r8)		
		li	r4,TS_RUN
		stb	r4,TC_STATE(r8)
		li	r4,NT_PPCTASK
		stb	r4,LN_TYPE(r8)
		la	r4,TASKPPC_CTMEM(r8)
		stw	r4,TASKPPC_CONTEXTMEM(r8)
		la	r4,TASKPPC_BATSTORE(r8)
		stw	r4,TASKPPC_BATSTORAGE(r8)
		stw	r8,TASKLINK_TASK(r8)
		li	r31,0xfff
		stw	r31,TASKLINK_SIG(r8)
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

 		lwz	r0,MN_STARTALLOC(r9)
		stw	r0,TC_SIGALLOC(r8)
		stw	r0,MN_ARG1(r9)

		la	r6,TASKPPC_PORT(r8)
		bl	.IntCrMsgPort

		stw	r6,TASKPPC_MSGPORT(r8)
		stw	r8,ThisPPCProc(r10)

		la	r5,TASKPPC_ALLTASK(r8)
		stw	r8,TASKPTR_TASK(r5)		
		stw	r5,TASKPPC_TASKPTR(r8)
		lwz	r3,LN_NAME(r8)			#Copy Name pointer 
		stw	r3,LN_NAME(r5)

		addi	r4,r10,LIST_ALLTASKS

		addi	r4,r4,4				#AddTailPPC
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)

		li	r0,0				#Tasks +1
		la	r4,NumAllTasks(r10)
		lwz	r3,0(r4)
		addi	r3,r3,1
		stw	r3,0(r4)
		stb	r0,PortInUse(r10)
		stb	r0,sonnet_ExceptionMode(r10)
		dcbst	r0,r4

		lwz	r3,PowerPCBase(r0)

		lwz	r0,Quantum(r0)
		mtdec	r0

		loadreg	r0,MACHINESTATE_DEFAULT
		mtsrr1	r0

		lwz	r0,RunPPCStart(r0)
		mtsrr0	r0

		mr	r30,r9

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
		
.QuickReturn:	li	r0,0x1000
		mtdec	r0
		b	.ExitToUser
		
.SlowReturn:	lwz	r0,Quantum(r0)
		mtdec	r0
		
.ExitToUser:	lwz	r9,0xf0(r0)				#Debug counter to check
		addi	r9,r9,1					#Whether exception is still
		stw	r9,0xf0(r0)				#running
		li	r0,0
		stb	r0,PortInUse(r10)
		stb	r0,sonnet_ExceptionMode(r10)

		lwz	r10,0(r13)
		lwzu	r9,4(r13)
		lwzu	r8,4(r13)
		lwzu	r7,4(r13)
		lwzu	r6,4(r13)
		lwzu	r5,4(r13)
		lwzu	r4,4(r13)
		lwzu	r3,4(r13)
		lwzu	r0,4(r13)
		mtxer	r0
		addi	r13,r13,4
	
		excepilog 'TOC'

		lwz	r1,0(r1)				#Restore user stack

		loadreg	r0,'USER'
		stw	r0,0xf4(r0)
		
		mtsprg1	r30
		mfspr	r0,HID0
		mr	r30,r0
		ori	r0,r0,HID0_ICFI
		mtspr	HID0,r0
		mtspr	HID0,r30
		sync
		
		mfsprg1	r30

		lwz	r0,Exc_srr0(r0)
		mtsrr0	r0
		
		lwz	r0,Exc_srr1(r0)
		mtsrr1	r0

		mfsprg0	r0

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
		lwzx	r31,r7,r31
		rlwinm	r31,r31,24,8,31
		rlwinm	r7,r29,16,0,15
		divwu	r0,r7,r31
		stw	r0,TASKPPC_DESIRED(r4)
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


.TaskException:	lwz	r3,sonnet_TaskExcept(r10)
		cmpw	r3,r9
		li	r0,0
		stw	r0,sonnet_TaskExcept(r10)		
		bne	.RTaskExc
		
		lwz	r4,TC_EXCEPTDATA(r3)
		mr.	r4,r4
		beq-	.RTaskExc

		lwz	r5,TC_SIGRECVD(r3)
		lwz	r0,TC_SIGEXCEPT(r3)
		and.	r6,r5,r0
		beq-	.RTaskExc

		andc.	r4,r5,r6
		stw	r4,TC_SIGRECVD(r3)
		andc.	r4,r0,r6
		stw	r4,TC_SIGEXCEPT(r3)

		stw	r2,-80(r1)
		stw	r10,-76(r1)
		stw	r11,-72(r1)
		stw	r12,-68(r1)
		stw	r13,-64(r1)
		
		subi	r1,r1,140
		lwz	r2,TC_EXCEPTDATA(r3)
		lwz	r0,TC_EXCEPTCODE(r3)
		mr	r3,r6
		mtlr	r0
		blrl
			
		addi	r1,r1,140
		lwz	r2,-80(r1)
		lwz	r10,-76(r1)
		lwz	r11,-72(r1)
		lwz	r12,-68(r1)
		lwz	r13,-64(r1)
		
		lwz	r5,TC_SIGEXCEPT(r4)
		or	r5,r5,r3
		stw	r5,TC_SIGEXCEPT(r4)
		b	.RTaskExc
		
#********************************************************************************************

.TrySwitch:	mr.	r9,r9
		bne	.CheckWait

		la	r4,LIST_NEWTASKS(r10)

		lwz	r5,0(r4)			#RemHeadPPC
		lwz	r3,0(r5)
		mr.	r3,r3
		beq-	.NoNode6
		stw	r3,0(r4)
		stw	r4,4(r3)
		mr	r3,r5
.NoNode6:	mr.	r9,r3		
		
		bne	.Dispatch

		la	r4,LIST_READYTASKS(r10)
		
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
		stw	r9,ThisPPCProc(r10)		
		b	.LoadContext

.CheckWait:	li	r4,TS_REMOVED
		lbz	r3,TC_STATE(r9)
		cmpw	r3,r4
		
		bne	.NotDeleted

		mr	r5,r9
		la	r4,LIST_REMOVEDTASKS(r10)	#Deleted task list at base
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
		stw	r9,ThisPPCProc(r10)
		b	.TrySwitch

.NotDeleted:	li	r4,TS_CHANGING
		lbz	r3,TC_STATE(r9)
		cmpw	r3,r4
		
		beq	.GoToWait

		la	r4,LIST_NEWTASKS(r10)
		
		lwz	r5,0(r4)			#RemHeadPPC
		lwz	r3,0(r5)
		mr.	r3,r3
		beq-	.NoNode1
		stw	r3,0(r4)
		stw	r4,4(r3)
		mr	r3,r5
	
.NoNode1:	mr.	r9,r3
		bne	.SwitchNew			#Dispatch fixed bug

		la	r4,LIST_READYTASKS(r10)
	
		lwz	r5,0(r4)			#RemHeadPPC
		lwz	r3,0(r5)
		mr.	r3,r3
		beq-	.NoNode2
		stw	r3,0(r4)
		stw	r4,4(r3)
		mr	r3,r5
	
.NoNode2:	mr.	r9,r3	
		bne	.SwitchOld
		
		b	.SlowReturn
	
.SwitchOld:	la	r4,LIST_READYTASKS(r10)		#Old = Context, New = PPStruct
		lwz	r5,ThisPPCProc(r10)
		stw	r9,ThisPPCProc(r10)								
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
	
.SwitchNew:	la	r4,LIST_READYTASKS(r10)		
		lwz	r5,ThisPPCProc(r10)
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
		lwz	r3,Exc_srr0(r0)
		stw	r3,0(r6)
		lwz	r3,Exc_srr1(r0)
		stw	r3,4(r6)
		lwz	r3,0(r1)			#User stack
		lwz	r0,8(r3)			#lr
		stw	r0,8(r6)
		lwz	r0,4(r3)			#cr
		stw	r0,12(r6)
		mfctr	r0
		stw	r0,16(r6)
		lwz	r0,32(r13)
		stw	r0,20(r6)			#xer
		mfsprg0	r0
		stw	r0,24(r6)			#r0
		lwz	r0,0(r3)
		stw	r0,28(r6)			#r1
		stw	r2,32(r6)
		lwz	r0,28(r13)
		stw	r0,36(r6)
		lwz	r0,24(r13)
		stw	r0,40(r6)
		lwz	r0,20(r13)
		stw	r0,44(r6)
		lwz	r0,16(r13)
		stw	r0,48(r6)
		lwz	r0,12(r13)
		stw	r0,52(r6)
		lwz	r0,8(r13)
		stw	r0,56(r6)
		lwz	r0,4(r13)
		stw	r0,60(r6)
		lwz	r0,0(r13)
		stw	r0,64(r6)
		stw	r11,68(r6)
		stw	r12,72(r6)
		lwz	r3,-4(r3)
		stw	r3,76(r6)
		stw	r14,80(r6)
		stw	r15,84(r6)
		stw	r16,88(r6)
		stw	r17,92(r6)
		stw	r18,96(r6)
		stw	r19,100(r6)
		stw	r20,104(r6)
		stw	r21,108(r6)
		stw	r22,112(r6)
		stw	r23,116(r6)
		stw	r24,120(r6)
		stw	r25,124(r6)
		stw	r26,128(r6)
		stw	r27,132(r6)
		stw	r28,136(r6)
		stw	r29,140(r6)
		stw	r30,144(r6)
		stw	r31,148(r6)

		stfd	f0,160(r6)			#NO Pad to make align on 8
		mffs	f0
		stfd	f0,152(r6)
		stfd	f1,168(r6)
		stfd	f2,176(r6)
		stfd	f3,184(r6)
		stfd	f4,192(r6)
		stfd	f5,200(r6)
		stfd	f6,208(r6)
		stfd	f7,216(r6)
		stfd	f8,224(r6)
		stfd	f9,232(r6)
		stfd	f10,240(r6)
		stfd	f11,248(r6)
		stfd	f12,256(r6)
		stfd	f13,264(r6)
		stfd	f14,272(r6)
		stfd	f15,280(r6)		
		stfd	f16,288(r6)
		stfd	f17,296(r6)
		stfd	f18,304(r6)
		stfd	f19,312(r6)
		stfd	f20,320(r6)
		stfd	f21,328(r6)
		stfd	f22,336(r6)
		stfd	f23,344(r6)
		stfd	f24,352(r6)
		stfd	f25,360(r6)
		stfd	f26,368(r6)
		stfd	f27,376(r6)
		stfd	f28,384(r6)
		stfd	f29,392(r6)
		stfd	f30,400(r6)
		stfd	f31,408(r6)
		
		lwz	r3,4(r6)
		andis.	r3,r3,PSL_VEC@h
		beq	.NoStoreVMX
		
		li	r3,544+16
		stvx	v0,r6,r3
		
		li	r3,544
		mfvscr	v0
		stvx	v0,r6,r3
		addi	r3,r3,32
		stvx	v1,r6,r3
		addi	r3,r3,16
		stvx	v2,r6,r3
		addi	r3,r3,16
		stvx	v3,r6,r3
		addi	r3,r3,16
		stvx	v4,r6,r3
		addi	r3,r3,16
		stvx	v5,r6,r3
		addi	r3,r3,16
		stvx	v6,r6,r3
		addi	r3,r3,16
		stvx	v7,r6,r3
		addi	r3,r3,16
		stvx	v8,r6,r3
		addi	r3,r3,16
		stvx	v9,r6,r3
		addi	r3,r3,16
		stvx	v10,r6,r3
		addi	r3,r3,16
		stvx	v11,r6,r3
		addi	r3,r3,16
		stvx	v12,r6,r3
		addi	r3,r3,16
		stvx	v13,r6,r3
		addi	r3,r3,16
		stvx	v14,r6,r3
		addi	r3,r3,16
		stvx	v15,r6,r3
		addi	r3,r3,16
		stvx	v16,r6,r3
		addi	r3,r3,16
		stvx	v17,r6,r3
		addi	r3,r3,16
		stvx	v18,r6,r3
		addi	r3,r3,16
		stvx	v19,r6,r3
		addi	r3,r3,16
		stvx	v20,r6,r3
		addi	r3,r3,16
		stvx	v21,r6,r3
		addi	r3,r3,16
		stvx	v22,r6,r3
		addi	r3,r3,16
		stvx	v23,r6,r3
		addi	r3,r3,16
		stvx	v24,r6,r3
		addi	r3,r3,16
		stvx	v25,r6,r3
		addi	r3,r3,16
		stvx	v26,r6,r3
		addi	r3,r3,16
		stvx	v27,r6,r3
		addi	r3,r3,16
		stvx	v28,r6,r3
		addi	r3,r3,16
		stvx	v29,r6,r3
		addi	r3,r3,16
		stvx	v30,r6,r3
		addi	r3,r3,16
		stvx	v31,r6,r3
		
		mfspr	r3,VRSAVE
		stw	r3,1072(r6)
		
.NoStoreVMX:	blr

#********************************************************************************************			

.LoadContext:	lwz	r9,TASKPPC_CONTEXTMEM(r9)
		li	r0,0
		stb	r0,PortInUse(r10)
		stb	r0,sonnet_ExceptionMode(r10)
			
		lwz	r10,4(r9)
		andis.	r10,r10,PSL_VEC@h
		beq	.NoLoadVMX

		li	r10,544
		lvx	v0,r9,r10
		mtvscr	v0
		addi	r10,r10,16
		lvx	v0,r9,r10
		addi	r10,r10,16
		lvx	v1,r9,r10
		addi	r10,r10,16
		lvx	v2,r9,r10
		addi	r10,r10,16
		lvx	v3,r9,r10
		addi	r10,r10,16
		lvx	v4,r9,r10
		addi	r10,r10,16
		lvx	v5,r9,r10
		addi	r10,r10,16
		lvx	v6,r9,r10
		addi	r10,r10,16
		lvx	v7,r9,r10
		addi	r10,r10,16
		lvx	v8,r9,r10
		addi	r10,r10,16
		lvx	v9,r9,r10
		addi	r10,r10,16
		lvx	v10,r9,r10
		addi	r10,r10,16
		lvx	v11,r9,r10
		addi	r10,r10,16
		lvx	v12,r9,r10
		addi	r10,r10,16
		lvx	v13,r9,r10
		addi	r10,r10,16
		lvx	v14,r9,r10
		addi	r10,r10,16
		lvx	v15,r9,r10
		addi	r10,r10,16
		lvx	v16,r9,r10
		addi	r10,r10,16
		lvx	v17,r9,r10
		addi	r10,r10,16
		lvx	v18,r9,r10
		addi	r10,r10,16
		lvx	v19,r9,r10
		addi	r10,r10,16
		lvx	v20,r9,r10
		addi	r10,r10,16
		lvx	v21,r9,r10
		addi	r10,r10,16
		lvx	v22,r9,r10
		addi	r10,r10,16
		lvx	v23,r9,r10
		addi	r10,r10,16
		lvx	v24,r9,r10
		addi	r10,r10,16
		lvx	v25,r9,r10
		addi	r10,r10,16
		lvx	v26,r9,r10
		addi	r10,r10,16
		lvx	v27,r9,r10
		addi	r10,r10,16
		lvx	v28,r9,r10
		addi	r10,r10,16
		lvx	v29,r9,r10
		addi	r10,r10,16
		lvx	v30,r9,r10
		addi	r10,r10,16
		lvx	v31,r9,r10

		lwz	r10,1072(r9)			#544+33*16
		mtspr	VRSAVE,r10
		
.NoLoadVMX:	lwz	r0,0(r9)
		stw	r0,Exc_srr0(r0)
		lwz	r0,4(r9)
		stw	r0,Exc_srr1(r0)
		lwz	r0,8(r9)
		mtlr	r0
		lwz	r0,12(r9)
		mtcr	r0
		lwz	r0,16(r9)
		mtctr	r0
		lwz	r0,20(r9)
		mtxer	r0
		lwz	r0,24(r9)
		lwz	r1,28(r9)
		lwz	r2,32(r9)
		lwz	r3,36(r9)
		lwz	r4,40(r9)
		lwz	r5,44(r9)
		lwz	r6,48(r9)
		lwz	r7,52(r9)
		lwz	r8,56(r9)
		lwz	r10,60(r9)
		mtsprg3	r10
		lwz	r10,64(r9)
		lwz	r11,68(r9)
		lwz	r12,72(r9)
		lwz	r13,76(r9)
		lwz	r14,80(r9)
		lwz	r15,84(r9)
		lwz	r16,88(r9)
		lwz	r17,92(r9)
		lwz	r18,96(r9)
		lwz	r19,100(r9)
		lwz	r20,104(r9)
		lwz	r21,108(r9)
		lwz	r22,112(r9)
		lwz	r23,116(r9)
		lwz	r24,120(r9)
		lwz	r25,124(r9)
		lwz	r26,128(r9)
		lwz	r27,132(r9)
		lwz	r28,136(r9)
		lwz	r29,140(r9)
		lwz	r30,144(r9)
		lwz	r31,148(r9)
		lfd	f0,152(r9)			#Must be 8 aligned
		mtfsf	0xff,f0
		lfd	f0,160(r9)
		lfd	f1,168(r9)
		lfd	f2,176(r9)
		lfd	f3,184(r9)
		lfd	f4,192(r9)
		lfd	f5,200(r9)
		lfd	f6,208(r9)
		lfd	f7,216(r9)
		lfd	f8,224(r9)
		lfd	f9,232(r9)
		lfd	f10,240(r9)
		lfd	f11,248(r9)
		lfd	f12,256(r9)
		lfd	f13,264(r9)
		lfd	f14,272(r9)
		lfd	f15,280(r9)
		lfd	f16,288(r9)
		lfd	f17,296(r9)
		lfd	f18,304(r9)
		lfd	f19,312(r9)
		lfd	f20,320(r9)
		lfd	f21,328(r9)
		lfd	f22,336(r9)
		lfd	f23,344(r9)
		lfd	f24,352(r9)
		lfd	f25,360(r9)
		lfd	f26,368(r9)
		lfd	f27,376(r9)
		lfd	f28,384(r9)
		lfd	f29,392(r9)
		lfd	f30,400(r9)
		lfd	f31,408(r9)

		loadreg	r9,'USER'
		stw	r9,0xf4(r0)
		
		mtsprg1	r30
		mfspr	r9,HID0
		mr	r30,r9
		ori	r9,r9,HID0_ICFI
		mtspr	HID0,r9
		mtspr	HID0,r30
		sync
		
		mfsprg1	r30

		lwz	r9,0xf0(r0)			#Debug counter to check
		addi	r9,r9,1				#Whether exception is still running
		stw	r9,0xf0(r0)

		lwz	r9,Quantum(r0)
		mtdec	r9
		
		lwz	r9,Exc_srr0(r0)
		mtsrr0	r9
		
		lwz	r9,Exc_srr1(r0)
		mtsrr1	r9
		
		mfsprg3	r9

		rfi
		
#********************************************************************************************

.GoToWait:	li	r4,TS_WAIT
		stb	r4,TC_STATE(r9)
		la	r4,LIST_WAITINGTASKS(r10)
		mr	r5,r9
		
		bl	.StoreContext
		
		addi	r4,r4,4				#AddTailPPC
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
		
		li	r9,0
		stw	r9,ThisPPCProc(r10)
		
		b	.TrySwitch

#********************************************************************************************		
		
.DoIdle:	loadreg	r0,IdleTask			#Switch to idle task
		lwz	r1,SonnetBase(r0)
		or	r0,r1,r0
		stw	r0,Exc_srr0(r0)

		loadreg	r1,SysStack-0x20		#System stack in unused mem
		lwz	r9,SonnetBase(r0)
		add	r1,r1,r9

		lwz	r9,0xf0(r0)			#Debug counter to check
		addi	r9,r9,1				#Whether exception is still running
		li	r0,0
		stw	r9,0xf0(r0)
		stb	r0,PortInUse(r10)
		stb	r0,sonnet_ExceptionMode(r10)

		stw	r13,-4(r1)
		subi	r13,r1,4
		stwu	r1,-288(r1)

		mtsprg1	r30
		mfspr	r0,HID0
		mr	r30,r0
		ori	r0,r0,HID0_ICFI
		mtspr	HID0,r0
		mtspr	HID0,r30
		sync
		
		mfsprg1	r30

		lwz	r0,Quantum(r0)
		mtdec	r0
		
		loadreg	r0,'IDLE'
		stw	r0,0xf4(r0)

		lwz	r0,Exc_srr0(r0)
		mtsrr0	r0

		loadreg	r0,MACHINESTATE_DEFAULT
		mtsrr1	r0

		rfi

#********************************************************************************************

.DecInt:	mtsprg0	r0

		mfsrr0	r0
		stw	r0,Exc_srr0(r0)
		mfsrr1	r0
		stw	r0,Exc_srr1(r0)

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0				#Reenable MMU
		isync					#Also reenable FPU
		sync

		mfsprg0	r0

		stwu	r1,-1088(r1)
		stw	r4,40(r1)
		stw	r3,44(r1)
		stw	r0,48(r1)
		mfcr	r0
		stw	r0,52(r1)
		mfxer	r0
		stw	r0,64(r1)

		lwz	r3,PowerPCBase(r0)
		lbz	r4,sonnet_ExternalInt(r3)	#From CauseInterrupt
		mr.	r4,r4
		bne	.EHandler

		li	r0,EXCF_DECREMENTER
		stw	r0,60(r1)
		la	r4,LIST_EXCDECREMENTER(r3)
		b	.CommonHandler

#***********************************************		

.DoDInt:	lwz	r3,44(r1)
		lwz	r4,40(r1)
		lwz	r5,36(r1)
		lwz	r6,32(r1)
		lwz	r0,52(r1)
		mtcr	r0
		lwz	r0,64(r1)
		mtxer	r0
		lwz	r0,48(r1)
		lwz	r1,0(r1)

#***********************************************	

		mtsprg0	r0
		
		stwu	r1,-288(r1)

		prolog	228,'TOC'

		mfxer	r0
		stwu	r0,-4(r13)

		bl	.TaskStats

		stwu	r3,-4(r13)
		stwu	r4,-4(r13)
		stwu 	r5,-4(r13)
		stwu	r6,-4(r13)
		stwu	r7,-4(r13)
		stwu	r8,-4(r13)
		stwu	r9,-4(r13)
		stwu	r10,-4(r13)
			
		loadreg r0,'DECI'
		stw	r0,0xf4(r0)

		li	r5,-1
		lwz	r9,PowerPCBase(r0)
		stb	r5,sonnet_ExceptionMode(r9)
		
.ListLoop:	la	r4,LIST_READYEXC(r9)

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
		
.NoExcHandlers:	la	r4,LIST_REMOVEDEXC(r9)
		
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

.BreakPoint:						#Breakpoint Exception
		mtsprg0	r0

		mfsrr0	r0
		stw	r0,Exc_srr0(r0)
		mfsrr1	r0
		stw	r0,Exc_srr1(r0)

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)	#Reenable FPU & MMU
		mtmsr	r0
		sync
		isync
		
		mfsprg0	r0

		stwu	r1,-1088(r1)
		stw	r4,40(r1)
		stw	r3,44(r1)
		stw	r0,48(r1)
		mfcr	r0
		stw	r0,52(r1)
		mfxer	r0
		stw	r0,64(r1)

		lwz	r3,PowerPCBase(r0)		
		lis	r0,EXCF_IABR@h
		stw	r0,60(r1)
		la	r4,LIST_EXCIABR(r3)
		b	.CommonHandler

#********************************************************************************************

.MachCheck:						#Machine Check Exception
		mtsprg0	r0

		mfsrr0	r0
		stw	r0,Exc_srr0(r0)
		mfsrr1	r0
		stw	r0,Exc_srr1(r0)

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)	#Reenable FPU & MMU
		mtmsr	r0
		sync
		isync
		
		mfsprg0	r0

		stwu	r1,-1088(r1)
		stw	r4,40(r1)
		stw	r3,44(r1)
		stw	r0,48(r1)
		mfcr	r0
		stw	r0,52(r1)
		mfxer	r0
		stw	r0,64(r1)

		lwz	r3,PowerPCBase(r0)		
		li	r0,EXCF_MCHECK
		stw	r0,60(r1)
		la	r4,LIST_EXCMCHECK(r3)
		b	.CommonHandler

#********************************************************************************************

.SysMan:						#System Management Exception
		mtsprg0	r0
		
		mfsrr0	r0
		stw	r0,Exc_srr0(r0)
		mfsrr1	r0
		stw	r0,Exc_srr1(r0)

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)	#Reenable FPU & MMU
		mtmsr	r0
		sync
		isync
		
		mfsprg0	r0

		stwu	r1,-1088(r1)
		stw	r4,40(r1)
		stw	r3,44(r1)
		stw	r0,48(r1)
		mfcr	r0
		stw	r0,52(r1)
		mfxer	r0
		stw	r0,64(r1)

		lwz	r3,PowerPCBase(r0)		
		lis	r0,EXCF_SYSMAN@h
		stw	r0,60(r1)
		la	r4,LIST_EXCSYSMAN(r3)
		b	.CommonHandler

#********************************************************************************************

.TherMan:						#Thermal Management Exception
		mtsprg0	r0

		mfsrr0	r0
		stw	r0,Exc_srr0(r0)
		mfsrr1	r0
		stw	r0,Exc_srr1(r0)

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)	#Reenable FPU & MMU
		mtmsr	r0
		sync
		isync
		
		mfsprg0	r0

		stwu	r1,-1088(r1)
		stw	r4,40(r1)
		stw	r3,44(r1)
		stw	r0,48(r1)
		mfcr	r0
		stw	r0,52(r1)
		mfxer	r0
		stw	r0,64(r1)

		lwz	r3,PowerPCBase(r0)
		lis	r0,EXCF_THERMAN@h
		stw	r0,60(r1)
		la	r4,LIST_EXCTHERMAN(r3)
		b	.CommonHandler

#********************************************************************************************

.SysCall:						#System Call Exception
		mtsprg0	r0

		mfsrr0	r0
		stw	r0,Exc_srr0(r0)
		mfsrr1	r0
		stw	r0,Exc_srr1(r0)

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)	#Reenable FPU & MMU
		mtmsr	r0
		sync
		isync
		
		mfsprg0	r0

		stwu	r1,-1088(r1)
		stw	r4,40(r1)
		stw	r3,44(r1)
		stw	r0,48(r1)
		mfcr	r0
		stw	r0,52(r1)
		mfxer	r0
		stw	r0,64(r1)

		lwz	r3,PowerPCBase(r0)
		li	r0,EXCF_SYSTEMCALL
		stw	r0,60(r1)
		la	r4,LIST_EXCSYSTEMCALL(r3)
		b	.CommonHandler

#********************************************************************************************

.Trace:							#Trace Exception
		mtsprg0	r0

		mfsrr0	r0
		stw	r0,Exc_srr0(r0)
		mfsrr1	r0
		stw	r0,Exc_srr1(r0)

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)	#Reenable FPU & MMU
		mtmsr	r0
		sync
		isync
		
		mfsprg0	r0

		stwu	r1,-1088(r1)
		stw	r4,40(r1)
		stw	r3,44(r1)
		stw	r0,48(r1)
		mfcr	r0
		stw	r0,52(r1)
		mfxer	r0
		stw	r0,64(r1)

		lwz	r3,PowerPCBase(r0)		
		li	r0,EXCF_TRACE
		stw	r0,60(r1)
		la	r4,LIST_EXCTRACE(r3)
		b	.CommonHandler
		
#********************************************************************************************

.FPUnav:						#FPU Unavailable Exception
		mtsprg0	r0

		mfsrr0	r0
		stw	r0,Exc_srr0(r0)
		mfsrr1	r0
		stw	r0,Exc_srr1(r0)

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)	#Reenable FPU & MMU
		mtmsr	r0
		sync
		isync
		
		mfsprg0	r0

		stwu	r1,-1088(r1)
		stw	r4,40(r1)
		stw	r3,44(r1)
		stw	r0,48(r1)
		mfcr	r0
		stw	r0,52(r1)
		mfxer	r0
		stw	r0,64(r1)

		lwz	r3,PowerPCBase(r0)
		li	r0,EXCF_FPUN
		stw	r0,60(r1)
		la	r4,LIST_EXCFPUN(r3)
		b	.CommonHandler

#********************************************************************************************

.Alignment:						#Alignment Error Exception
		mtsprg0	r0

		mfsrr0	r0
		stw	r0,Exc_srr0(r0)
		mfsrr1	r0
		stw	r0,Exc_srr1(r0)

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)	#Reenable FPU & MMU
		mtmsr	r0
		sync
		isync
		
		mfsprg0	r0
		
		stwu	r1,-1088(r1)
		stw	r4,40(r1)
		stw	r3,44(r1)
		stw	r0,48(r1)
		mfcr	r0
		stw	r0,52(r1)
		mfxer	r0
		stw	r0,64(r1)

		lwz	r3,PowerPCBase(r0)		
		li	r0,EXCF_ALIGN
		stw	r0,60(r1)
		lbz	r4,sonnet_EnAlignExc(r3)
		mr.	r4,r4	
		beq	.AlignWOS

		la	r4,LIST_EXCALIGN(r3)
		b	.CommonHandler

#****************************************************

.AlignWOS:	stw	r5,36(r1)
		stw	r6,32(r1)
		
		lwz	r0,48(r1)			#r0
		stw	r0,104(r1)
		lwz	r0,0(r1)			#r1
		stw	r0,108(r1)
		stw	r2,112(r1)
		lwz	r0,44(r1)			#r3
		stw	r0,116(r1)
		lwz	r0,40(r1)			#r4
		stw	r0,120(r1)
		stfd	f0,244(r1)
		lwz	r0,36(r1)			#r5
		stw	r0,124(r1)
		stfd	f1,252(r1)
		lwz	r0,32(r1)			#r6
		stw	r0,128(r1)
		stfd	f2,260(r1)
		stw	r7,132(r1)
		stfd	f3,268(r1)
		stw	r8,136(r1)
		stfd	f4,276(r1)
		stw	r9,140(r1)
		stfd	f5,284(r1)
		stw	r10,144(r1)
		stfd	f6,292(r1)
		stw	r11,148(r1)
		stfd	f7,300(r1)
		stw	r12,152(r1)
		stfd	f8,308(r1)
		stw	r13,156(r1)
		stfd	f9,316(r1)
		stw	r14,160(r1)
		stfd	f10,324(r1)
		stw	r15,164(r1)
		stfd	f11,332(r1)
		stw	r16,168(r1)
		stfd	f12,340(r1)
		stw	r17,172(r1)
		stfd	f13,348(r1)
		stw	r18,176(r1)
		stfd	f14,356(r1)
		stw	r19,180(r1)
		stfd	f15,364(r1)
		stw	r20,184(r1)
		stfd	f16,372(r1)
		stw	r21,188(r1)
		stfd	f17,380(r1)
		stw	r22,192(r1)
		stfd	f18,388(r1)
		stw	r23,196(r1)
		stfd	f19,396(r1)
		stw	r24,200(r1)
		stfd	f20,404(r1)
		stw	r25,204(r1)
		stfd	f21,412(r1)
		stw	r26,208(r1)
		stfd	f22,420(r1)
		stw	r27,212(r1)
		stfd	f23,428(r1)
		stw	r28,216(r1)
		stfd	f24,436(r1)
		li	r0,0
		stfd	f25,444(r1)
		stw	r29,220(r1)
		stfd	f26,452(r1)
		stw	r30,224(r1)
		stfd	f27,460(r1)
		stw	r31,228(r1)
		stfd	f28,468(r1)
		stw	r0,232(r1)			#Align1	(32x4)
		stfd	f29,476(r1)
		stw	r0,236(r1)			#Align2 (33x4)
		stfd	f30,484(r1)
		stw	r0,240(r1)			#For when rA = 0
		stfd	f31,492(r1)
		
		la	r30,104(r1)			#Start of regtable in r30		
		la	r31,244(r1)			#Start of fregtable in r31

		lwz	r5,PowerPCBase(r0)		#For GetHALInfo
		lwz	r6,AlignmentExcLow(r5)		#Counts number of aligment issues
		addic	r6,r6,1				#For debugging and optimization purposes
		stw	r6,AlignmentExcLow(r5)
		lwz	r6,AlignmentExcHigh(r5)
		addze	r6,r6
		stw	r6,AlignmentExcHigh(r5)

		lwz	r5,Exc_srr0(r0)
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
		stfs	f1,32*4(r30)			#store it on correct aligned spot
		lwz	r6,32*4(r30)			#Get the correct 32 bit value
		stwx	r6,r10,r8			#Store correct value
		b	.AligExit

.lfd:		lwzx	r9,r10,r8
		stw	r9,32*4(r30)
		addi	r8,r8,4
		lwzx	r9,r10,r8
		stw	r9,33*4(r30)
		lfd	f1,32*4(r30)
		stfdx	f1,r31,r6
		b	.AligExit

.lfsu:		add	r5,r10,r8			#Add displacement
		stwx	r5,r30,r7	

.lfs:		lwzx	r9,r10,r8			#Get 32 bit value
		stw	r9,32*4(r30)			#Store it on aligned spot
		lfs	f1,32*4(r30)			#Get it and convert it to 64 bit
		stfdx	f1,r31,r6			#Store the 64 bit value
		b	.AligExit
		
.lstfsx:	rlwinm.	r0,r5,25,31,31			#0 = s; 1 = d
		bne	.HaltAlign
		rlwinm.	r0,r5,26,31,31			#0 = x; 1 = ux
		bne	.HaltAlign

		rlwinm	r8,r5,23,25,29			#get index register
		lwzx	r8,r30,r8			#get index register value
		rlwinm.	r0,r5,24,31,31
		bne	.stfs
		b	.lfs

#***********************************************

.HaltAlign:	li	r0,0
		mtsprg0	r0
		b	.CommonAlign

.AligExit:	loadreg	r0,'USER'			#Return to user
		stw	r0,0xf4(r0)
		li	r0,-1
		mtsprg0	r0
		
.CommonAlign:	lwz	r0,104(r1)		
		stw	r0,48(r1)			#r0
		lwz	r0,108(r1)
		stw	r0,0(r1)			#r1
		lwz	r2,112(r1)
		lwz	r3,116(r1)
		stw	r3,44(r1)
		lwz	r4,120(r1)
		lfd	f0,244(r1)
		stw	r4,40(r1)
		lwz	r5,124(r1)
		lfd	f1,252(r1)
		stw	r5,36(r1)
		lwz	r6,128(r1)
		lfd	f2,260(r1)
		stw	r6,32(r1)
		lwz	r7,132(r1)
		lfd	f3,268(r1)
		lwz	r8,136(r1)
		lfd	f4,276(r1)
		lwz	r9,140(r1)
		lfd	f5,284(r1)
		lwz	r10,144(r1)
		lfd	f6,292(r1)
		lwz	r11,148(r1)
		lfd	f7,300(r1)
		lwz	r12,152(r1)
		lfd	f8,308(r1)
		lwz	r13,156(r1)
		lfd	f9,316(r1)
		lwz	r14,160(r1)
		lfd	f10,324(r1)
		lwz	r15,164(r1)
		lfd	f11,332(r1)
		lwz	r16,168(r1)
		lfd	f12,340(r1)
		lwz	r17,172(r1)
		lfd	f13,348(r1)
		lwz	r18,176(r1)
		lfd	f14,356(r1)
		lwz	r19,180(r1)
		lfd	f15,364(r1)
		lwz	r20,184(r1)
		lfd	f16,372(r1)
		lwz	r21,188(r1)
		lfd	f17,380(r1)
		lwz	r22,192(r1)
		lfd	f18,388(r1)
		lwz	r23,196(r1)
		lfd	f19,396(r1)
		lwz	r24,200(r1)
		lfd	f20,404(r1)
		lwz	r25,204(r1)
		lfd	f21,412(r1)
		lwz	r26,208(r1)
		lfd	f22,420(r1)
		lwz	r27,212(r1)
		lfd	f23,428(r1)
		lwz	r28,216(r1)
		lfd	f24,436(r1)
		lfd	f25,444(r1)
		lwz	r29,220(r1)
		lfd	f26,452(r1)
		lwz	r30,224(r1)
		lfd	f27,460(r1)
		lwz	r31,228(r1)
		lfd	f28,468(r1)
		lfd	f29,476(r1)
		lfd	f30,484(r1)
		lfd	f31,492(r1)

		mfsprg0	r0
		mr.	r0,r0
		beq	.HaltAlign2

		lwz	r3,Exc_srr0(r0)
		addi	r3,r3,4				#Exit beyond offending instruction
		stw	r3,Exc_srr0(r0)

		lwz	r3,PowerPCBase(r0)
		li	r0,0
		stb	r0,sonnet_ExceptionMode(r3)
		lwz	r3,44(r1)
		lwz	r0,52(r1)
		mtcr	r0
		lwz	r0,64(r1)
		mtxer	r0
		lwz	r0,48(r1)
		lwz	r1,0(r1)
		
		mtsprg0	r0
		
		lwz	r0,Exc_srr0(r0)
		mtsrr0	r0
		
		lwz	r0,Exc_srr1(r0)
		mtsrr1	r0
		
		mfsprg0	r0

		rfi
	
#***********************************************	

.HaltAlign2:	lwz	r3,PowerPCBase(r0)
		la	r4,LIST_EXCALIGN(r3)
		b	.CommonHandler

#********************************************************************************************

.ITLBMiss:
		mfspr	r2,HASH1				#get first pointer
		li	r1,8					#load 8 for counter
		mfctr	r0					#save counter
		mfspr	r3,ICMP					#get first compare value
		addi	r2,r2,-8				#pre dec the pointer
im0:		
		mtctr	r1					#load counter
im1:		
		lwzu	r1,8(r2)				#get next pte
		cmpw	r1,r3 					#see if found pte
		bdnzf	eq,im1					#dec count br if cmp ne and if count not zero
		bne	instrSecHash     			#if not found set up second hash or exit
		lwz	r1,4(r2)				#load tlb entry lower-word
		andi.	r3,r1,PTE_GUARDED<<3			#check G bit
		bne	doISIp					#if guarded, take an ISI
		mtctr	r0 					#restore counter
		mfspr	r0,IMISS 				#get the miss address for the tlbl
		mfsrr1	r3     					#get the saved cr0 bits
		mtcrf	0x80,r3   				#restore CR0
		mtspr	RPA,r1    				#set the pte
		ori	r1,r1,PTE_REFERENCED    		#set reference bit
		srwi	r1,r1,8    				#get byte 7 of pte
		tlbli	r0    					#load the itlb
		stb	r1,6(r2) 				#update page table
		rfi     					#return to executing program

instrSecHash:
		andi.	r1,r3,PTE_HASHID  			#see if we have done second hash
		bne	doISI        				#if so, go to ISI interrupt
		mfspr	r2,HASH2         			#get the second pointer
		ori	r3,r3,PTE_HASHID      			#change the compare value
		li	r1,8    				#load 8 for counter
		addi	r2,r2,-8   				#pre dec for update on load
		b 	im0    					#try second hash

doISIp:
		mfsrr1	r3   					#get srr1
		andi.	r2,r3,0xffff 				#clean upper srr1
		addis	r2,r2,DSISR_PROTECT@h  			#or in srr<4> = 1 to flag prot violation
		b 	isi1
doISI:
 		mfsrr1	r3    					#get srr1		
 		andi.	r2,r3,0xffff				#clean srr1
		addis	r2,r2,DSISR_NOTFOUND@h			#or in srr1<1> = 1 to flag not found
isi1:
		mtctr	r0 					#restore counter
		mtsrr1	r2 					#set srr1
		mfmsr	r0   					#get msr
		xoris	r0,r0,PSL_TGPR@h  			#flip the msr<tgpr> bit
		mtcrf	0x80,r3      				#restore CR0
		mtmsr	r0      				#flip back to the native gprs
		b	.ISI       				#go to instr. access interrupt

#********************************************************************************************

.DLoadTLBMiss:
		mfspr	r2,HASH1				#get first pointer
		li	r1,8   					#load 8 for counter
		mfctr	r0   					#save counter
		mfspr	r3,DCMP   				#get first compare value
		addi	r2,r2,-8  				#pre dec the pointer
dm0:
		mtctr	r1  					#load counter
dm1:
		lwzu	r1,8(r2)				#get next pte
		cmpw	r1,r3 					#see if found pte
		bdnzf	eq,dm1 					#dec count br if cmp ne and if count not zero
		bne	dataSecHash 				#if not found set up second hash or exit
		lwz	r1,4(r2) 				#load tlb entry lower-word
		mtctr	r0   					#restore counter
		mfspr	r0,DMISS  				#get the miss address for the tlbld
		mfsrr1	r3   					#get the saved cr0 bits
		mtcrf	0x80,r3 				#restore CR0
		mtspr	RPA,r1  				#set the pte
		ori	r1,r1,PTE_REFERENCED   			#set reference bit
		srwi	r1,r1,8  				#get byte 7 of pte
		tlbld	r0    					#load the dtlb
		stb	r1,6(r2) 				#update page table
		rfi      					#return to executing program

dataSecHash:
 		andi.	r1,r3,PTE_HASHID 			#see if we have done second hash
		bne	doDSI       				#if so, go to DSI interrupt
		mfspr	r2,HASH2   				#get the second pointer
		ori	r3,r3,PTE_HASHID 			#change the compare value
		li	r1,8   					#load 8 for counter
		addi	r2,r2,-8  				#pre dec for update on load
		b	dm0  					#try second hash

#********************************************************************************************

.DStoreTLBMiss:	
		mfspr	r2,HASH1				#get first pointer
		li	r1,8 					#load 8 for counter
		mfctr	r0   					#save counter
		mfspr	r3,DCMP 				#get first compare value
		addi	r2,r2,-8				#pre dec the pointer
ceq0:
		mtctr	r1					#load counter
ceq1:
		lwzu	r1,8(r2)				#get next pte
		cmpw	r1,r3    				#see if found pte
		bdnzf	eq,ceq1 				#dec count br if cmp ne and if count not zero
		bne	cEq0SecHash 				#if not found set up second hash or exit
		lwz	r1,4(r2)   				#load tlb entry lower-word
		andi.	r3,r1,PTE_CHANGED 			#check the C-bit
		beq	cEq0ChkProt 				#if (C==0) go check protection modes
ceq2:
		mtctr	r0       				#restore counter
		mfspr	r0,DMISS 				#get the miss address for the tlbld
		mfsrr1	r3      				#get the saved cr0 bits
		mtcrf	0x80,r3   				#restore CR0
		mtspr	RPA,r1  				#set the pte
		tlbld	r0     					#load the dtlb
		rfi     					#return to executing program

cEq0SecHash:
		andi.	r1,r3,PTE_HASHID			#see if we have done second hash
		bne	doDSI    				#if so, go to DSI interrupt
		mfspr	r2,HASH2 				#get the second pointer
		ori	r3,r3,PTE_HASHID  			#change the compare value
		li	r1,8					#load 8 for counter
		addi	r2,r2,-8				#pre dec for update on load
		b	ceq0  					#try second hash

cEq0ChkProt:
		rlwinm.	r3,r1,30,0,1 				#test PP
    		bge-	chk0    				#if (PP == 00 or PP == 01) goto chk0:
		andi.	r3,r1,1 				#test PP[0]
		beq+	chk2   					#return if PP[0] == 0
		b	doDSIp 					#else DSIp

chk0:
  		mfsrr1	r3      				#get old msr
		andis.	r3,r3,SRR1_KEY@h 			#test the KEY bit (SRR1-bit 12)
		beq	chk2      				#if (KEY==0) goto chk2:
		b	doDSIp   				#else DSIp
chk2:
   		ori	r1,r1,(PTE_REFERENCED|PTE_CHANGED)	#set reference and change bit
		sth	r1,6(r2)				#update page table
		b	ceq2  					#and back we go

doDSI:
 		mfsrr1	r3         				#get srr1
		rlwinm	r1,r3,9,6,6  				#get srr1<flag> to bit 6
		addis	r1,r1,DSISR_NOTFOUND@h  		#or in dsisr<1> = 1 to flag not found
		b	dsi1
doDSIp:
    		mfsrr1	r3             				#get srr1
		rlwinm	r1,r3,9,6,6     			#get srr1<flag> to bit 6
		addis	r1,r1,DSISR_PROTECT@h    		#or in dsisr<4> = 1 to flag prot violation
dsi1:
  		mtctr	r0           				#restore counter
		andi.	r2,r3,0xffff     			#clear upper bits of srr1
		mtsrr1	r2              			#set srr1
		mtdsisr	r1         				#load the dsisr
		mfspr	r1,DMISS     				#get miss address
		rlwinm.	r2,r2,0,31,31 				#test LE bit
		beq	dsi2     				#if little endian then:
		xori	r1,r1,0x07   				#de-mung the data address
dsi2:
  		mtdar	r1       				#put in dar
		mfmsr	r0               			#get msr
		xoris	r0,r0,PSL_TGPR@h    			#flip the msr<tgpr> bit
		mtcrf	0x80,r3     				#restore CR0
		mtmsr	r0    					#flip back to the native gprs
		isync
		sync
		sync
		b	.DSI  					#branch to DSI interrupt

#********************************************************************************************

.ISI:							#Instruction Storage Exception
		mtsprg0	r0

		mfsrr0	r0
		stw	r0,Exc_srr0(r0)
		mfsrr1	r0
		stw	r0,Exc_srr1(r0)

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)	#Reenable FPU & MMU
		mtmsr	r0
		sync
		isync
		
		mfsprg0	r0

		stwu	r1,-1088(r1)
		stw	r4,40(r1)
		stw	r3,44(r1)
		stw	r0,48(r1)
		mfcr	r0
		stw	r0,52(r1)
		mfxer	r0
		stw	r0,64(r1)

		lwz	r3,PowerPCBase(r0)		
		li	r0,EXCF_IACCESS
		stw	r0,60(r1)
		la	r4,LIST_EXCIACCESS(r3)
		b	.CommonHandler

#********************************************************************************************

.PerfMon:						#Performance Monitor Exception
		mtsprg0	r0

		mfsrr0	r0
		stw	r0,Exc_srr0(r0)
		mfsrr1	r0
		stw	r0,Exc_srr1(r0)
		
		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)	#Reenable FPU & MMU
		mtmsr	r0
		sync
		isync
		
		mfsprg0	r0

		stwu	r1,-1088(r1)
		stw	r4,40(r1)
		stw	r3,44(r1)
		stw	r0,48(r1)
		mfcr	r0
		stw	r0,52(r1)
		mfxer	r0
		stw	r0,64(r1)

		lwz	r3,PowerPCBase(r0)
		li	r0,-(EXCF_PERFMON)		##There a better way to load 0x8000?
		stw	r0,60(r1)
		la	r4,LIST_EXCPERFMON(r3)
		b	.CommonHandler

#********************************************************************************************

.VMXUnav:					#AltiVec Unavailable Exception
		mtsprg0	r0

		mfsrr0	r0
		stw	r0,Exc_srr0(r0)
		mfsrr1	r0
		stw	r0,Exc_srr1(r0)

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r0
		sync					#Reenable MMU & FPU
		isync
		
		mfsprg0	r0

		stwu	r1,-1088(r1)
		stw	r6,32(r1)
		stw	r5,36(r1)
		stw	r4,40(r1)
		stw	r3,44(r1)
		stw	r0,48(r1)
		mfcr	r0
		stw	r0,52(r1)
		mfxer	r0
		stw	r0,64(r1)

		lwz	r3,PowerPCBase(r0)		#No LIST_ implemented yet.		
		lis	r0,EXCF_VMXUN@h
		stw	r0,60(r1)

		loadreg	r0,'VMXU'
		stw	r0,0xf4(r0)

		li	r0,-1
		stb	r0,sonnet_ExceptionMode(r3)
		lbz	r4,sonnet_AltivecOn(r3)
		mr.	r4,r4
		beq	.ErrorVMX

		lwz	r0,Exc_srr1(r0)
		oris	r0,r0,PSL_VEC@h
		stw	r0,Exc_srr1(r0)
		sync
		isync

		li	r0,0
		stb	r0,sonnet_ExceptionMode(r3)

		loadreg	r0,'USER'
		stw	r0,0xf4(r0)

		lwz	r6,32(r1)
		lwz	r5,36(r1)
		lwz	r4,40(r1)
		lwz	r3,44(r1)
		lwz	r0,52(r1)
		mtcr	r0
		lwz	r0,64(r1)
		mtxer	r0
		lwz	r1,0(r1)

		mtsprg1	r30
		mfspr	r0,HID0
		mr	r30,r0
		ori	r0,r0,HID0_ICFI
		mtspr	HID0,r0
		mtspr	HID0,r30
		sync
		
		mfsprg1	r30

		lwz	r0,Exc_srr0(r0)
		mtsrr0	r0
		
		lwz	r0,Exc_srr1(r0)
		mtsrr1	r0

		mfsprg0	r0
		
		rfi
		
#***********************************************

.ErrorVMX:	lis	r0,EXCF_VMXUN@h
		b	.CommonError

#********************************************************************************************

.DSI:							#Data Storage Exception
		mtsprg0	r0

		mfsrr0	r0
		stw	r0,Exc_srr0(r0)
		mfsrr1	r0
		stw	r0,Exc_srr1(r0)

		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)	#Reenable FPU & MMU
		mtmsr	r0
		sync
		isync
		
		mfsprg0	r0

		stwu	r1,-1088(r1)
		stw	r4,40(r1)
		stw	r3,44(r1)
		stw	r0,48(r1)
		mfcr	r0
		stw	r0,52(r1)
		mfxer	r0
		stw	r0,64(r1)

		lwz	r3,PowerPCBase(r0)		
		li	r0,EXCF_DACCESS
		stw	r0,60(r1)
		lbz	r4,sonnet_EnDAccessExc(r3)
		mr.	r4,r4
		beq	.DoDSI2

		la	r4,LIST_EXCDACCESS(r3)
		b	.CommonHandler

#***********************************************

.DoDSI2:	stw	r5,36(r1)
		stw	r6,32(r1)

.DoDSI:		lwz	r0,48(r1)			#r0
		stw	r0,104(r1)
		lwz	r0,0(r1)			#r1
		stw	r0,108(r1)
		stw	r2,112(r1)
		lwz	r0,44(r1)			#r3
		stw	r0,116(r1)
		lwz	r0,40(r1)			#r4
		stw	r0,120(r1)
		lwz	r0,36(r1)			#r5
		stw	r0,124(r1)
		lwz	r0,32(r1)			#r6
		stw	r0,128(r1)
		stw	r7,132(r1)
		stw	r8,136(r1)
		stw	r9,140(r1)
		stw	r10,144(r1)
		stw	r11,148(r1)
		stw	r12,152(r1)
		stw	r13,156(r1)
		stw	r14,160(r1)
		stw	r15,164(r1)
		stw	r16,168(r1)
		stw	r17,172(r1)
		stw	r18,176(r1)
		stw	r19,180(r1)
		stw	r20,184(r1)
		stw	r21,188(r1)
		stw	r22,192(r1)
		stw	r23,196(r1)
		stw	r24,200(r1)
		stw	r25,204(r1)
		stw	r26,208(r1)
		stw	r27,212(r1)
		stw	r28,216(r1)
		stw	r29,220(r1)
		li	r0,0
		stw	r30,224(r1)
		stw	r31,228(r1)
		stw	r0,232(r1)			#For when rA = 0
		mflr	r0
		stw	r0,236(r1)
		
		la	r30,104(r1)			#Start of reg table in r30
		
		loadreg	r0,'DSI?'
		stw	r0,0xf4(r0)
		
		lwz	r7,Exc_srr0(r0)
####							#Start of check for picture.datatype patch
		mfctr	r0

		bl	.PatchPic
		.long	0x8,0x816100bc,0x800b005c,0x7c1a0040

.PatchPic:	mflr	r6
		lwz	r9,0(r6)
		li	r31,3
		li	r23,0
		mtctr	r31

		sub	r7,r7,r9
.CompPtchLoop:	lwzu	r31,4(r7)
		lwzu	r29,4(r6)
		cmpw	r29,r31
		bne	.DonePatch
		bdnz	.CompPtchLoop

		li	r23,-1
		lwz	r7,0xb0(r0)
		cmpwi	r7,2
		beq	.TryPatch

.TryNew:	li	r6,1
		lwz	r7,PowerPCBase(r0)
		lwz	r7,ThisPPCProc(r7)
		stw	r6,0xb0(r0)
		lwz	r7,TASKPPC_ID(r7)
		stw	r11,0xb8(r0)
		stw	r7,0xb4(r0)

		b	.DonePatch	

.TryPatch:	lwz	r7,PowerPCBase(r0)
		lwz	r31,0xb4(r0)
		lwz	r7,ThisPPCProc(r7)
		lwz	r7,TASKPPC_ID(r7)
		cmpw	r7,r31
		beq	.FurtherTest

		b	.TryNew

.FurtherTest:	lwz	r7,0xb8(r0)
		cmpw	r7,r11
		bne	.TryNew

.DonePatch:	mtctr	r0
		stw	r23,0xc0(r0)
####							#End of check for picture.datatype patch

		lwz	r7,PowerPCBase(r0)		#For GetHALInfo
		lwz	r6,DataExcLow(r7)		#Counts number of Amiga RAM
		addic	r6,r6,1				#accesses by the PPC		
		stw	r6,DataExcLow(r7)		#For debugging/optimization purposes
		lwz	r6,DataExcHigh(r7)
		addze	r6,r6
		stw	r6,DataExcHigh(r7)

		lwz	r31,Exc_srr0(r0)
		cmpwi	r31,0x7f00			#Called from other exception
		blt	.NotSupported			#NOT GOOD!
		
		mfdar	r29
		cmpwi	r29,4				#Accessing Execbase is OK.
		beq	.Execbase
	
		cmpwi	r29,0x100
		blt	.NotSupported			#68K zero page access NOT GOOD!
		
.Execbase:	lwz	r31,0(r31)			#get offending instruction in r31
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

.NotSupported:	li	r0,0
		mtsprg0	r0
		b	.CommonDSI

.GoLoad:

####							#Check for correct setup for picture.datatype patch
		lwz	r23,0xc0(r0)
		mr.	r23,r23
		beq	.DoX
		
		lwz	r23,0xb0(r0)
		cmpwi	r23,2
		bne	.DoX

		lwz	r23,PowerPCBase(r0)
		lwz	r24,0xb4(r0)
		lwz	r23,ThisPPCProc(r23)
		lwz	r23,TASKPPC_ID(r23)
		cmpw	r23,r24
		bne	.DoX
		
		lwz	r11,148(r1)
		lwz	r23,0xb8(r0)
		cmpw	r23,r11
		bne	.DoX

		lwz	r10,0xbc(r0)

		b	.NoX

####							#End of check

.DoX:		loadreg	r9,'GETV'

		bl	.DoSixtyEight			#Returns value in r10

####							#Check for correct setup for picture.datatype patch
		lwz	r23,0xc0(r0)
		mr.	r23,r23
		beq	.NoX

		lwz	r23,0xb0(r0)
		cmpwi	r23,1
		bne	.NoX

		lwz	r23,PowerPCBase(r0)
		lwz	r24,0xb4(r0)
		lwz	r23,ThisPPCProc(r23)
		lwz	r23,TASKPPC_ID(r23)
		cmpw	r23,r24
		bne	.NoX

		lwz	r11,148(r1)
		lwz	r23,0xb8(r0)
		cmpw	r23,r11
		bne	.NoX

		li	r23,2
		stw	r23,0xb0(r0)
		stw	r10,0xbc(r0)

####							#End of check

.NoX:		rlwinm	r9,r31,16,16,31
		andi.	r9,r9,0xa800
		cmplwi	r9,0x8000			#lwz/lwzu 0x8000
		beq	.FixedValue
		rlwinm	r10,r10,16,16,31
		cmplwi	r9,0xa000			#lhz/lhzu 0xa000
		beq	.FixedValue
		extsh	r10,r10
		cmplwi	r9,0xa800			#lha/lhau 0xa800
		beq	.FixedValue
		rlwinm	r10,r10,24,24,31
		cmplwi	r9,0x8800			#lbz/lbzu 0x8800		
		bne	.NotSupported			#Not Supported

.FixedValue:	stwx	r10,r30,r6			#Store gotten value in correct register
		
.DoneDSI:	li	r0,-1
		mtsprg0	r0
		
		loadreg	r0,'USER'			#Return to user
		stw	r0,0xf4(r0)

.CommonDSI:	lwz	r0,104(r1)
		stw	r0,48(r1)			#r0
		lwz	r0,108(r1)
		stw	r0,0(r1)			#r1
		lwz	r2,112(r1)
		lwz	r3,116(r1)
		stw	r3,44(r1)			#r3
		lwz	r4,120(r1)
		stw	r4,40(r1)			#r4
		lwz	r5,124(r1)
		stw	r5,36(r1)			#r5
		lwz	r6,128(r1)
		stw	r6,32(r1)			#r6
		lwz	r7,132(r1)
		lwz	r8,136(r1)
		lwz	r9,140(r1)
		lwz	r10,144(r1)
		lwz	r11,148(r1)
		lwz	r12,152(r1)
		lwz	r13,156(r1)
		lwz	r14,160(r1)
		lwz	r15,164(r1)
		lwz	r16,168(r1)
		lwz	r17,172(r1)
		lwz	r18,176(r1)
		lwz	r19,180(r1)
		lwz	r20,184(r1)
		lwz	r21,188(r1)
		lwz	r22,192(r1)
		lwz	r23,196(r1)
		lwz	r24,200(r1)
		lwz	r25,204(r1)
		lwz	r26,208(r1)
		lwz	r27,212(r1)
		lwz	r28,216(r1)
		lwz	r29,220(r1)
		lwz	r30,224(r1)
		lwz	r31,228(r1)
		lwz	r0,236(r1)			#lr
		mtlr	r0

		mfsprg0	r0
		mr.	r0,r0
		beq	.HaltDSI

		lwz	r3,Exc_srr0(r0)			#Skip offending instruction
		addi	r3,r3,4
		stw	r3,Exc_srr0(r0)

		lwz	r3,PowerPCBase(r0)
		li	r0,0
		stb	r0,sonnet_ExceptionMode(r3)
		lwz	r3,44(r1)
		lwz	r0,52(r1)
		mtcr	r0
		lwz	r0,64(r1)
		mtxer	r0
		lwz	r0,48(r1)
		lwz	r1,0(r1)
		
		mtsprg0	r0
		
		lwz	r0,Exc_srr0(r0)
		mtsrr0	r0
		
		lwz	r0,Exc_srr1(r0)
		mtsrr1	r0
		
		mfsprg0	r0

		rfi
	
#***********************************************	

.HaltDSI:	lwz	r3,PowerPCBase(r0)
		lbz	r4,sonnet_EnDAccessExc(r3)
		mr.	r4,r4
		bne	.RealHalt

		la	r4,LIST_EXCDACCESS(r3)
		b	.CommonHandler

.RealHalt:	li	r0,EXCF_DACCESS
		b	.CommonError

#*************************************************

.DoSixtyEight:	mfpvr	r25
		rlwinm	r23,r25,16,16,31
		cmplwi	r23,ID_MPC834X
		bne	.DoH68

		lwz	r28,SonnetBase(r0)
		addis	r28,r28,FIFO_BASE
		lwz	r25,FIFO_MIOFT(r28)
		addi	r23,r25,4
		loadreg	r20,0xffff3fff
		and	r23,r23,r20
		stw	r23,FIFO_MIOFT(r28)
		b	.Cont68H

.DoH68:		lwz	r25,XMPIBase(r0)
		mr.	r25,r25
		beq	.DoS68
	
		lis	r28,PPC_XCSR_BASE@h
		lwz	r25,XCSR_MIOFT(r28)
		addi	r23,r25,4
		andi.	r23,r23,0x3fff
		stw	r23,XCSR_MIOFT(r28)
		b	.Cont68H

.DoS68:		lis	r28,EUMB@h
		li	r24,OFTPR
		lwbrx	r25,r24,r28			
		addi	r23,r25,4
		loadreg	r20,0xc000
		or	r23,r23,r20
		loadreg r20,0xffff
		and	r23,r23,r20			#Keep it C000-FFFE		
		stwbrx	r23,r24,r28

.Cont68H:	sync
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

		mfpvr	r24
		rlwinm	r22,r24,16,16,31
		cmplwi	r22,ID_MPC834X
		bne	.DoH68Write

		lwz	r28,SonnetBase(r0)
		addis	r28,r28,FIFO_BASE
		lwz	r22,FIFO_MIOPH(r28)
		stw	r25,0(r22)
		addi	r23,r22,4
		loadreg	r21,0xffff3fff
		and	r23,r23,r21
		stw	r23,FIFO_MIOPH(r28)
		lis	r24,IMMR_ADDR_DEFAULT
		ori	r24,r24,IMMR_OMR0
		stw	r23,0(r24)
		b	.Done68WH

.DoH68Write:	lwz	r24,XMPIBase(r0)
		mr.	r24,r24
		beq	.DoS68Write
	
		lis	r28,PPC_XCSR_BASE@h
		lwz	r22,XCSR_MIOPH(r28)
		stw	r25,0(r22)
		addi	r23,r22,4
		andi.	r23,r23,0x3fff
		stw	r23,XCSR_MIOPH(r28)
		b	.Done68WH

.DoS68Write:	lis	r28,EUMB@h
		li	r24,OPHPR
		lwbrx	r22,r24,r28		
		stw	r25,0(r22)		
		addi	r23,r22,4
		loadreg	r20,0xbfff
		and	r23,r23,r20			#Keep it 8000-BFFE
		stwbrx	r23,r24,r28			#triggers Interrupt

.Done68WH:	sync

		mr.	r7,r7
		bne	.NoWaitSE
		mfctr	r0
		loadreg	r9,'DONE'
		
		lis	r7,0x40
		mtctr	r7

.WaitPFIFO:	lwz	r21,MN_IDENTIFIER(r25)
		sync
		cmpw	r21,r9
		
		beq	.DonePFIFO
		bdnz	.WaitPFIFO
		
		loadreg	r0,'ETIM'
		stw	r0,48(r1)			#Error code to r0
		b	.HaltDSI

.DonePFIFO:	mtctr	r0
		lwz	r10,MN_IDENTIFIER+4(r25)	#Returned value for load in r10
		
.NoWaitSE:	blr

#********************************************************************************************

.PrInt:							#Program Exception
		mtsprg0	r0

		mfsrr0	r0
		stw	r0,Exc_srr0(r0)
		mfsrr1	r0
		stw	r0,Exc_srr1(r0)
		
		mfmsr	r0
		ori	r0,r0,(PSL_IR|PSL_DR|PSL_FP)	#Reenable FPU & MMU
		mtmsr	r0
		sync
		isync
		
		mfsprg0	r0
		
		stwu	r1,-1088(r1)
		stw	r4,40(r1)
		stw	r3,44(r1)
		stw	r0,48(r1)
		mfcr	r0
		stw	r0,52(r1)
		mfxer	r0
		stw	r0,64(r1)

		lwz	r3,PowerPCBase(r0)		
		li	r0,EXCF_PROGRAM
		stw	r0,60(r1)
		la	r4,LIST_EXCPROGRAM(r3)

#****************************************************

.CommonHandler:	stw	r6,32(r1)
		stw	r5,36(r1)
		li	r0,-1
		stb	r0,sonnet_ExceptionMode(r3)
		lwz	r5,Exc_srr0(r0)
		lwz	r0,ViolationAddress(r0)
		cmplw	r0,r5
		beq	.DoWOSHandler

.NextExcOnList:	lwz	r4,0(r4)
		lwz	r0,0(r4)
		mr.	r0,r0
		beq	.DoWOSHandler

		lwz	r0,EXCDATA_TASK(r4)
		mr.	r0,r0
		beq 	.DoCustomExc

		lwz	r5,ThisPPCProc(r3)
		cmpw	r0,r5
		beq	.DoCustomExc

		b	.NextExcOnList
		
.DoCustomExc:	mflr	r6
		mtsprg0	r4
		lwz	r0,EXCDATA_CODE(r4)
		
		mtlr	r0		
		lwz	r0,EXCDATA_FLAGS(r4)
		rlwinm.	r0,r0,(32-EXC_LARGECONTEXT),31,31
		lwz	r0,60(r1)
		bne-	.LargeContext
		
		mtsprg3	r2
		lwz	r2,EXCDATA_DATA(r4)
		mtsprg1	r6
		lwz	r3,0(r1)
		mtsprg2	r3			#store original r1 and pass it on in SPRG2
		
		la	r6,104(r1)
		lwz	r3,44(r1)
		stw	r3,4(r6)
		stw	r0,0(r6)
		mr	r3,r6
		
		lwz	r0,52(r1)
		mtcr	r0
		lwz	r0,64(r1)
		mtxer	r0
		lwz	r0,48(r1)
		lwz	r4,40(r1)
		lwz	r5,36(r1)
		lwz	r6,32(r1)
		
		blrl
		
		stw	r0,48(r1)
		mfsprg1	r0
		mtlr	r0
		mfsprg3	r2
		mfsprg2	r0
		stw	r0,0(r1)
		mfcr	r0
		stw	r0,52(r1)
		stw	r4,40(r1)
		stw	r5,36(r1)
		stw	r6,32(r1)
		mfxer	r0
		stw	r0,64(r1)

		cmpwi	r3,EXCRETURN_ABORT
		lwz	r3,108(r1)
		stw	r3,44(r1)
		mfsprg0	r4
		beq	.ExitException

		lwz	r3,PowerPCBase(r0)
		b	.NextExcOnList
	
.LargeContext:	stw	r0,104(r1)
		lwz	r0,Exc_srr0(r0)
		stw	r0,108(r1)
		lwz	r0,Exc_srr1(r0)
		stw	r0,112(r1)
		mfdar	r0
		stw	r0,116(r1)
		mfdsisr	r0
		stw	r0,120(r1)
		lwz	r0,52(r1)		#cr
		stw	r0,124(r1)
		mfctr	r0
		stw	r0,128(r1)
		stw	r6,132(r1)		#lr
		lwz	r0,64(r1)
		stw	r0,136(r1)		#xer
		stfd	f0,272(r1)
		mffs	f0
		stfd	f0,152(r1)
		lwz	r0,156(r1)
		stw	r0,140(r1)
		lwz	r0,48(r1)		#r0
		stw	r0,144(r1)
		lwz	r0,0(r1)
		stw	r0,148(r1)		#r1
		stw	r2,152(r1)
		lwz	r0,44(r1)		#r3
		stw	r0,156(r1)
		lwz	r0,40(r1)		#r4
		stw	r0,160(r1)
		lwz	r0,36(r1)
		stw	r0,164(r1)		#r5
		lwz	r0,32(r1)
		stw	r0,168(r1)		#r6
		stw	r7,172(r1)
		stw	r8,176(r1)
		stw	r9,180(r1)
		stw	r10,184(r1)
		stw	r11,188(r1)
		stw	r12,192(r1)
		stw	r13,196(r1)
		stw	r14,200(r1)
		stw	r15,204(r1)
		stw	r16,208(r1)
		stw	r17,212(r1)
		stw	r18,216(r1)
		stw	r19,220(r1)
		stw	r20,224(r1)
		stw	r21,228(r1)
		stw	r22,232(r1)
		stw	r23,236(r1)
		stw	r24,240(r1)
		stw	r25,244(r1)
		stw	r26,248(r1)
		stw	r27,252(r1)
		stw	r28,256(r1)
		stw	r29,260(r1)
		stw	r30,264(r1)
		stw	r31,268(r1)

		stfd	f1,280(r1)
		stfd	f2,288(r1)
		stfd	f3,296(r1)
		stfd	f4,304(r1)
		stfd	f5,312(r1)
		stfd	f6,320(r1)
		stfd	f7,328(r1)
		stfd	f8,336(r1)
		stfd	f9,344(r1)
		stfd	f10,352(r1)
		stfd	f11,360(r1)
		stfd	f12,368(r1)
		stfd	f13,376(r1)
		stfd	f14,384(r1)
		stfd	f15,392(r1)		
		stfd	f16,400(r1)
		stfd	f17,408(r1)
		stfd	f18,416(r1)
		stfd	f19,424(r1)
		stfd	f20,432(r1)
		stfd	f21,440(r1)
		stfd	f22,448(r1)
		stfd	f23,456(r1)
		stfd	f24,464(r1)
		stfd	f25,472(r1)
		stfd	f26,480(r1)
		stfd	f27,488(r1)
		stfd	f28,496(r1)
		stfd	f29,504(r1)
		stfd	f30,512(r1)
		stfd	f31,520(r1)
		
		lwz	r3,112(r1)
		andis.	r3,r3,PSL_VEC@h
		beq	.NoContextVMX
		
		li	r3,528+16
		stvx	v0,r1,r3
		
		li	r3,528
		mfvscr	v0
		stvx	v0,r1,r3
		addi	r3,r3,32
		stvx	v1,r1,r3
		addi	r3,r3,16
		stvx	v2,r1,r3
		addi	r3,r3,16
		stvx	v3,r1,r3
		addi	r3,r3,16
		stvx	v4,r1,r3
		addi	r3,r3,16
		stvx	v5,r1,r3
		addi	r3,r3,16
		stvx	v6,r1,r3
		addi	r3,r3,16
		stvx	v7,r1,r3
		addi	r3,r3,16
		stvx	v8,r1,r3
		addi	r3,r3,16
		stvx	v9,r1,r3
		addi	r3,r3,16
		stvx	v10,r1,r3
		addi	r3,r3,16
		stvx	v11,r1,r3
		addi	r3,r3,16
		stvx	v12,r1,r3
		addi	r3,r3,16
		stvx	v13,r1,r3
		addi	r3,r3,16
		stvx	v14,r1,r3
		addi	r3,r3,16
		stvx	v15,r1,r3
		addi	r3,r3,16
		stvx	v16,r1,r3
		addi	r3,r3,16
		stvx	v17,r1,r3
		addi	r3,r3,16
		stvx	v18,r1,r3
		addi	r3,r3,16
		stvx	v19,r1,r3
		addi	r3,r3,16
		stvx	v20,r1,r3
		addi	r3,r3,16
		stvx	v21,r1,r3
		addi	r3,r3,16
		stvx	v22,r1,r3
		addi	r3,r3,16
		stvx	v23,r1,r3
		addi	r3,r3,16
		stvx	v24,r1,r3
		addi	r3,r3,16
		stvx	v25,r1,r3
		addi	r3,r3,16
		stvx	v26,r1,r3
		addi	r3,r3,16
		stvx	v27,r1,r3
		addi	r3,r3,16
		stvx	v28,r1,r3
		addi	r3,r3,16
		stvx	v29,r1,r3
		addi	r3,r3,16
		stvx	v30,r1,r3
		addi	r3,r3,16
		stvx	v31,r1,r3
		
		mfspr	r3,VRSAVE
		stw	r3,1056(r1)

.NoContextVMX:	lwz	r2,EXCDATA_DATA(r4)
		la	r3,104(r1)

		blrl

		lwz	r0,108(r1)		#Skips Exc type
		stw	r0,Exc_srr0(r0)
		lwz	r0,112(r1)
		stw	r0,Exc_srr1(r0)
		lwz	r0,116(r1)
		mtdar	r0
		lwz	r0,120(r1)
		mtdsisr	r0		
		lwz	r0,124(r1)
		mtcr	r0
		lwz	r0,128(r1)
		mtctr	r0
		lwz	r0,132(r1)
		mtlr	r0
		lwz	r0,136(r1)
		mtxer	r0
		stw	r0,64(r1)
		lfd	f0,136(r1)
		mtfsf	0xff,f0
		lwz	r0,144(r1)
		lwz	r2,148(r1)
		mtsprg2	r2			#(New) User stack pointer
		lwz	r2,152(r1)
		lwz	r4,160(r1)
		lwz	r5,164(r1)
		lwz	r6,168(r1)
		lwz	r7,172(r1)
		lwz	r8,176(r1)
		lwz	r9,180(r1)
		lwz	r10,184(r1)
		lwz	r11,188(r1)
		lwz	r12,192(r1)
		lwz	r13,196(r1)
		lwz	r14,200(r1)
		lwz	r15,204(r1)
		lwz	r16,208(r1)
		lwz	r17,212(r1)
		lwz	r18,216(r1)
		lwz	r19,220(r1)
		lwz	r20,224(r1)
		lwz	r21,228(r1)
		lwz	r22,232(r1)
		lwz	r23,236(r1)
		lwz	r24,240(r1)
		lwz	r25,244(r1)
		lwz	r26,248(r1)
		lwz	r27,252(r1)
		lwz	r28,256(r1)
		lwz	r29,260(r1)
		lwz	r30,264(r1)
		lwz	r31,268(r1)
		
		lfd	f0,272(r1)
		lfd	f1,280(r1)
		lfd	f2,288(r1)
		lfd	f3,296(r1)
		lfd	f4,304(r1)
		lfd	f5,312(r1)
		lfd	f6,320(r1)
		lfd	f7,328(r1)
		lfd	f8,336(r1)
		lfd	f9,344(r1)
		lfd	f10,352(r1)
		lfd	f11,360(r1)
		lfd	f12,368(r1)
		lfd	f13,376(r1)
		lfd	f14,384(r1)
		lfd	f15,392(r1)
		lfd	f16,400(r1)
		lfd	f17,408(r1)
		lfd	f18,416(r1)
		lfd	f19,424(r1)
		lfd	f20,432(r1)
		lfd	f21,440(r1)
		lfd	f22,448(r1)
		lfd	f23,456(r1)
		lfd	f24,464(r1)
		lfd	f25,472(r1)
		lfd	f26,480(r1)
		lfd	f27,488(r1)
		lfd	f28,496(r1)
		lfd	f29,504(r1)
		lfd	f30,512(r1)
		lfd	f31,520(r1)

		stw	r6,32(r1)
		stw	r5,36(r1)
		stw	r4,40(r1)

		stw	r0,48(r1)
		mfcr	r0
		stw	r0,52(r1)

		mfsprg2	r4
		stw	r4,0(r1)			#Change User Stack
		mfsprg0	r4
		cmpwi	r3,EXCRETURN_ABORT

		lwz	r3,156(r1)
		stw	r3,44(r1)	
		beq	.ExitException
		
		lwz	r3,PowerPCBase(r0)
		b	.NextExcOnList

#****************************************************

.DoWOSHandler:	lwz	r5,60(r1)
		cmpwi	r5,EXCF_PROGRAM
		beq	.Private			#Needs jump table
		cmpwi	r5,EXCF_DACCESS
		beq	.DoDSI3
		cmpwi	r5,EXCF_INTERRUPT
		beq	.DoEInt
		cmpwi	r5,EXCF_DECREMENTER
		beq	.DoDInt
		mr	r0,r5
		b	.CommonError

.DoDSI3:	lwz	r3,PowerPCBase(r0)
		lbz	r4,sonnet_EnDAccessExc(r3)
		mr.	r4,r4
		bne	.DoDSI2
		mr	r0,r5
		b	.CommonError
		
#****************************************************

.Private:	lwz	r5,Exc_srr0(r0)
		lwz	r0,ViolationAddress(r0)
		cmplw	r0,r5
		li	r0,EXCF_PROGRAM
		bne	.CommonError

		addi	r5,r5,4				#Next instruction
		stw	r5,Exc_srr0(r0)
		lwz	r5,Exc_srr1(r0)

		ori	r5,r5,PSL_PR			#Set to Super
		xori	r5,r5,PSL_PR
		stw	r5,Exc_srr1(r0)

		li	r0,0				#SuperKey
		stw	r0,48(r1)

#****************************************************

.ExitException:	li	r0,0
		lwz	r3,PowerPCBase(r0)
		stb	r0,sonnet_ExceptionMode(r3)

		mfspr	r0,HID0
		mr	r3,r0
		ori	r0,r0,HID0_ICFI
		mtspr	HID0,r0
		mtspr	HID0,r3
		sync

		lwz	r0,52(r1)
		mtcr	r0
		lwz	r0,64(r1)
		mtxer	r0
		lwz	r0,48(r1)
		lwz	r3,44(r1)
		lwz	r4,40(r1)
		lwz	r5,36(r1)
		lwz	r6,32(r1)
		lwz	r1,0(r1)			#User stack restored

		mtsprg0	r0
		
		lwz	r0,Exc_srr0(r0)
		mtsrr0	r0
		
		lwz	r0,Exc_srr1(r0)
		mtsrr1	r0
		
		mfsprg0	r0

		rfi
		
#****************************************************		

.CommonError:	rlwinm	r4,r0,16,16,31

		cmpwi	r0,-(EXCF_PERFMON)		##There a better way to check for 0x8000?
		li	r3,.EMonitor-.EMonitor		
		beq	.CEContinue

		cmpwi	r4,EXCF_VMXUN@h
		li	r3,.VMXUnavble-.EMonitor		
		beq	.CEContinue

		cmpwi	r0,EXCF_SYSTEMCALL
		li	r3,.ESC-.EMonitor		
		beq	.CEContinue

		cmpwi	r0,EXCF_MCHECK
		li	r3,.EMachCheck-.EMonitor		
		beq	.CEContinue

		cmpwi	r0,EXCF_PROGRAM
		li	r3,.EProgram-.EMonitor		
		beq	.CEContinue

		cmpwi	r0,EXCF_DACCESS
		li	r3,.EDSI-.EMonitor		
		beq	.CEContinue

		cmpwi	r0,EXCF_IACCESS
		li	r3,.EISI-.EMonitor		
		beq	.CEContinue

		cmpwi	r0,EXCF_ALIGN
		li	r3,.EAlign-.EMonitor		
		beq	.CEContinue

		cmpwi	r0,EXCF_FPUN
		li	r3,.EFP-.EMonitor		
		beq	.CEContinue

		cmpwi	r0,EXCF_TRACE
		li	r3,.ETrace-.EMonitor		
		beq	.CEContinue

		cmpwi	r4,EXCF_SYSMAN@h
		li	r3,.ESM-.EMonitor		
		beq	.CEContinue

		cmpwi	r4,EXCF_THERMAN@h
		li	r3,.ETM-.EMonitor		
		beq	.CEContinue

		li	r3,.EUnknown-.EMonitor

.CEContinue:	mtsprg1	r3
		lwz	r0,52(r1)
		mtcr	r0
		lwz	r0,64(r1)
		mtxer	r0
		lwz	r0,48(r1)
		lwz	r3,44(r1)
		lwz	r4,40(r1)
		lwz	r5,36(r1)
		lwz	r6,32(r1)
		lwz	r1,0(r1)

		mtsprg2	r30
		mflr	r30
		bl .GotStrings

.EMonitor:	.string	"Perfomance Monitor"
.VMXUnavble:	.string "AltiVec Unavailable"
.ESC:		.string	"System Call"
.EMachCheck:	.string	"Machine Check"
.EProgram:	.string	"Program"
.EDSI:		.string	"Data Storage"
.EISI:		.string	"Instruction Storage"
.EAlign:	.string "Alignment"
.EFP:		.string	"FPU Unavailable"
.ETrace:	.string "Trace"
.ESM:		.string "System Management"
.ETM:		.string "Thermal Management"
.EUnknown:	.string "Unknown"

		.align	2

.GotStrings:	mtsprg3	r31
		lwz	r31,SonnetBase(r0)
		addis	r31,r31,FIFO_BASE
		addi	r31,r31,0x100
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
		lwz	r31,SonnetBase(r0)
		addis	r31,r31,FIFO_BASE
		addi	r31,r31,0x100		

		lwz	r3,PowerPCBase(r0)
		lwz	r4,ThisPPCProc(r3)
		stw	r4,4(r31)
		lwz	r5,LN_NAME(r4)

		lwz	r3,Exc_srr0(r0)
		lis	r4,0xf000
		and.	r3,r3,r4
		bne	.NotKernel

		li	r5,0
.NotKernel:	stw	r5,0(r31)
		
		addi	r31,r31,4
		lwz	r3,SonnetBase(r0)
		mflr	r4
		or	r4,r4,r3
		mfsprg1	r5
		add	r4,r4,r5
		stwu	r4,4(r31)

		lwz	r0,Exc_srr0(r0)
		stwu	r0,4(r31)
		lwz	r0,Exc_srr1(r0)
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
		mfsdr1	r0
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

		mfpvr	r4
		rlwinm	r6,r4,16,16,31
		cmplwi	r6,ID_MPC834X
		bne	.DoCrashH

		lwz	r6,SonnetBase(r0)
		addis	r6,r6,FIFO_BASE
		lwz	r5,FIFO_MIOFT(r6)
		addi	r3,r5,4
		loadreg	r7,0xffff3fff
		and	r3,r3,r7
		stw	r3,FIFO_MIOFT(r6)
		b	.ContCrasH

.DoCrashH:	lwz	r4,XMPIBase(r0)
		mr.	r4,r4
		beq	.DoCrashS
	
		lis	r6,PPC_XCSR_BASE@h
		lwz	r5,XCSR_MIOFT(r6)
		addi	r3,r5,4
		andi.	r3,r3,0x3fff
		stw	r3,XCSR_MIOFT(r6)
		b	.ContCrasH

.DoCrashS:	lis	r6,EUMB@h
		li	r4,OFTPR
		lwbrx	r5,r4,r6
		addi	r3,r5,4
		loadreg	r7,0xc000
		or	r3,r3,r20
		loadreg r7,0xffff
		and	r3,r3,r7			#Keep it C000-FFFE		
		stwbrx	r3,r4,r6

.ContCrasH:	sync
		lwz	r5,0(r5)
		loadreg	r7,'CRSH'
		stw	r7,MN_IDENTIFIER(r5)
		lwz	r7,MCPort(r0)
		stw	r7,MN_MCPORT(r5)
		li	r7,NT_MESSAGE
		stb	r7,LN_TYPE(r5)
		li	r7,192
		sth	r7,MN_LENGTH(r5)

		sync

		mfpvr	r4
		rlwinm	r6,r4,16,16,31
		cmplwi	r6,ID_MPC834X
		bne	.FinishCrashH

		lwz	r6,SonnetBase(r0)
		addis	r6,r6,FIFO_BASE
		lwz	r7,FIFO_MIOPH(r6)
		stw	r5,0(r7)
		addi	r3,r7,4
		loadreg	r10,0xffff3fff
		and	r3,r3,r10
		stw	r3,FIFO_MIOPH(r6)
		lis	r9,IMMR_ADDR_DEFAULT
		ori	r9,r9,IMMR_OMR0
		stw	r3,0(r9)
		b	.FinishCrasH

.FinishCrashH:	lwz	r4,XMPIBase(r0)
		mr.	r4,r4
		beq	.FinishCrashS
		
		lis	r6,PPC_XCSR_BASE@h
		lwz	r7,XCSR_MIOPH(r6)
		stw	r5,0(r7)
		addi	r3,r7,4
		andi.	r3,r3,0x3fff
		stw	r3,XCSR_MIOPH(r6)
		b	.FinishCrasH

.FinishCrashS:	lis	r6,EUMB@h
		li	r4,OPHPR
		lwbrx	r7,r4,r6
		stw	r5,0(r7)		
		addi	r3,r7,4
		loadreg	r7,0xbfff
		and	r3,r3,r7			#Keep it 8000-BFFE
		stwbrx	r3,r4,r6			#triggers Interrupt
		
.FinishCrasH:	sync
		lwz	r10,PowerPCBase(r0)
		lwz	r9,ThisPPCProc(r10)
		li	r0,TS_REMOVED
		stb	r0,TC_STATE(r9)

		b	.TrySwitch			#Try to salvage the system

#********************************************************************************************
	
EIntEnd:
		mflr	r4				#Setup a small jumptable for exceptions

		loadreg r5,0x48002b44
		stw	r5,0x500(r0)			#External Interrupt
		loadreg	r5,0x48001e40
		stw	r5,0x1200(r0)			#Data TLB miss on store (G2/e300/option on MPC7450)
		loadreg	r5,0x48001f3c
		stw	r5,0x1100(r0)			#Data TLB miss on load (G2/e300)
		loadreg	r5,0x48002038
		stw	r5,0x1000(r0)			#Instruction TLB Miss (G2/e300)
		loadreg r5,0x48002114
		stw	r5,0xf20(r0)			#AltiVec Unavailable
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
