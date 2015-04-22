.include ppcdefines.i
.include sonnet_libppc.i
.include ppcmacros-std.i

.global PPCCode,PPCLen,RunningTask,WaitingTasks,NewTasks,Init,ViolationAddress
.global MCTask,SysBase,PowerPCBase

.set	PPCLen,(PPCEnd-PPCCode)

#********************************************************************************************

.section "PPCSetup","acrx"

PPCCode:						#0x4000	System initialization
		lis	r22,CMD_BASE
		lis	r29,VEC_BASE			#0xfff00000
		ori	r29,r29,0x6000			#For initial communication

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
		mr	r26,r8				#Oops, hardcoded

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

		bl	mmuSetup			#Setup BATs. Needs to be changed to tables
		bl	Epic				#Setup the EPIC controller
#		bl	Caches				#Setup the L1 and L2 cache

		loadreg	r3,0x8000			#Start hardcoded at 0x8000
		mr	r31,r3

		loadreg	r1,0x7ffe0			#Userstack in unused mem (See sonnet.s)
		BUILDSTACKPPC

		bl	End

Start:		nop					#Dummy entry at absolute 0x8000
.StartX:	nop
		nop
		nop
		b	.StartX
	
ExitCode:	lwz	r9,RunningTask(r0)
		lwz	r21,TC_SPLOWER(r9)
		la	r9,TASKPPC_SIZE(r9)
		loadreg r7,"FPPC"
		stw	r7,MN_IDENTIFIER(r9)
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
		mr	r5,r9

		LIBCALLPOWERPC PutXMsgPPC

		loadreg	r1,0x7ffe0			#Userstack in unused mem (See sonnet.s)
		BUILDSTACKPPC
		
		mr	r4,r21
		lwz	r21,SonnetBase(r0)
		or	r4,r4,r21
		
		LIBCALLPOWERPC FreeVecPPC

		LIBCALLPOWERPC FlushL1DCache
		
		sync
		isync
		
		li	r0,0
		stw	r0,RunningTask(r0)
		
Pause:		nop
		nop
		b	Pause

End:		mflr	r4

		addi	r5,r4,End-Start
		subf	r5,r4,r5
		li	r6,0
		bl	copy_and_flush			#Put program in Sonnet Mem instead of PCI Mem

		lis	r14,0				#Reset
		mtspr	285,r14				#Time Base Upper,
		mtspr	284,r14				#Time Base Lower and
		loadreg r8,0x7fffffff
		mtdec	r28				#Decrementer.

		lwz	r28,0(r14)
		stw	r14,Atomic(r14)
		stw	r28,4(r29)			#Signal 68k that PPC is initialized

		loadreg r6,"INIT"
WInit:		lwz	r28,Init(r14)
		cmplw	r28,r6
		bne	WInit				#Wait for 68k to set up library
		isync

		loadreg	r4,2000000			#BUG! Not sure why this delay is needed
		mtctr	r4
.BugLoop:	bdnz+	.BugLoop

		la	r4,ReadyTasks(r14)
		LIBCALLPOWERPC NewListPPC

		la	r4,WaitingTasks(r14)
		LIBCALLPOWERPC NewListPPC

		la	r4,Semaphores(r14)
		LIBCALLPOWERPC NewListPPC

		la	r4,Ports(r14)
		LIBCALLPOWERPC NewListPPC

		la	r4,AllTasks(r14)
		LIBCALLPOWERPC NewListPPC

		la	r4,SnoopList(r14)
		LIBCALLPOWERPC NewListPPC

		li	r4,SSPPC_SIZE*5			#Memory for 5 Semaphores
		LIBCALLPOWERPC AllocVecPPC
		
		lwz	r4,SonnetBase(r0)
		xor	r3,r3,r4		
		
		mr	r30,r3
		mr	r4,r3
		stw 	r4,TaskListSem(r14)
		LIBCALLPOWERPC InitSemaphorePPC

		addi	r4,r30,SSPPC_SIZE
		stw	r4,SemListSem(r14)
		LIBCALLPOWERPC InitSemaphorePPC

		addi	r4,r30,SSPPC_SIZE*2
		stw	r4,PortListSem(r14)
		LIBCALLPOWERPC InitSemaphorePPC
	
		addi	r4,r30,SSPPC_SIZE*3
		stw	r4,SnoopSem(r14)
		LIBCALLPOWERPC InitSemaphorePPC
	
		addi	r4,r30,SSPPC_SIZE*4
		stw	r4,MemSem(r14)
		LIBCALLPOWERPC InitSemaphorePPC	

		lwz	r14,0(r14)
		la	r4,NewTasks(r14)
		LIBCALLPOWERPC NewListPPC

		LIBCALLPOWERPC FlushL1DCache

		mtsrr0	r31
		mfmsr	r14
		ori	r14,r14,PSL_EE|PSL_PR			#Set privilege mode to User
		mtsrr1	r14

		rfi					#To user code

#********************************************************************************************

							#Clear MSR to diable interrupts and checks
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
		bne	.ResLoop				#Wait for reset

		li	r28,0x20
		stw	r28,0(r27)			#Set Mixed Mode

		loadreg	r28,0x80050042
		loadreg	r27,EPIC_IIVPR3
		add	r27,r26,r27
		stwbrx	r28,0,r27			#Set MU interrupt, Pri = 5, Vector = 0x42

		loadreg r28,Quantum			#Set Slice/Quantum
		loadreg r27,EPIC_GTBCR0
		add	r27,r26,r27
		stwbrx	r28,0,r27
	
		loadreg r28,0x80040043
		loadreg r27,EPIC_GTVPR0
		add	r27,r26,r27
		stwbrx	r28,0,r27

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

		loadreg	r27,EPIC_GTVPR0
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

							#Enable L1 data cache 
Caches:		mfspr	r4,HID0	
		ori	r4,r4,HID0_ICE|HID0_DCE|HID0_SGE|HID0_BTIC|HID0_BHTE@l
		isync
		mtspr	HID0,r4				#Enable D-cache
		isync
		 					# Set up on chip L2 cache controller.
		loadreg r4,L2CR_L2SIZ_1M|L2CR_L2CLK_3|L2CR_L2RAM_BURST|L2CR_L2WT
#		loadreg r4,L2CR_L2SIZ_1M|L2CR_L2CLK_3|L2CR_L2RAM_BURST
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
		
		blr

#********************************************************************************************

mmuSetup:	loadreg	r4,IBAT0L_VAL			#Could be simpler. To be converted to tables
		loadreg	r3,IBAT0U_VAL
		mtspr ibat0l,r4
		mtspr ibat0u,r3
		isync

		loadreg	r4,DBAT0L_VAL
		loadreg	r3,DBAT0U_VAL
		isync
		mtspr dbat0l,r4
		mtspr dbat0u,r3
		isync

		loadreg r4,IBAT1L_VAL
		loadreg	r3,IBAT1U_VAL
		mtspr ibat1l,r4
		mtspr ibat1u,r3
		isync

		loadreg r4,DBAT1L_VAL
		loadreg r3,DBAT1U_VAL
		isync
		mtspr dbat1l,r4
		mtspr dbat1u,r3
		isync

		loadreg r4,IBAT2L_VAL
		loadreg r3,IBAT2U_VAL
		or r3,r3,r27
		mtspr ibat2l,r4
		mtspr ibat2u,r3
		isync

		loadreg r4,DBAT2L_VAL
		loadreg	r3,DBAT2U_VAL
		or r3,r3,r27
		isync
		mtspr dbat2l,r4
		mtspr dbat2u,r3
		isync

		loadreg	r4,IBAT3L_VAL
		loadreg	r3,IBAT3U_VAL
		mtspr ibat3l,r4
		mtspr ibat3u,r3
		isync

		loadreg	r4,DBAT3L_VAL
		loadreg	r3,DBAT3U_VAL
		isync
		mtspr dbat3l,r4
		mtspr dbat3u,r3
		isync
							#BATs are now set up, now invalidate tlb entries
		li	r7,64
		mtctr	r7
		li	r7,0
.tlblp:		tlbie	r7
		addi	r7,r7,0x1000
		bdnz+	.tlblp
		tlbsync
	
		mfmsr	r4
		andi.	r4,r4,~PSL_IP@l			#Exception prefix from 0xfff00000 to 0x0
		ori	r4,r4,(PSL_IR|PSL_DR)		#Translation enable
		mtmsr	r4
		isync
		sync

		blr

#********************************************************************************************
	
ConfigWrite32:	lis	r20,CONFIG_ADDR			#Various PCI command routines
		lis 	r21,CONFIG_DAT
		stwbrx	r23,0,r20
		isync
		stwbrx	r25,0,r21
		blr

ConfigWrite16:	lis	r20,CONFIG_ADDR
		lis 	r21,CONFIG_DAT
		stwbrx	r23,0,r20
		isync
		sthbrx	r25,0,r21
		blr

ConfigWrite8:	lis	r20,CONFIG_ADDR
		stwbrx	r23,0,r20
		isync
		andi.	r19,r23,3
		oris	r21,r19,CONFIG_DAT
		stb	r25,0(r21)
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

		lis	r6, 0x40
		stw	r3, 0(r6)		#set 0x400000 to 0x0
		lis	r6, 0x80
		stw	r3, 0(r6)		#set 0x800000 to 0x0
		lis	r6, 0x100
		stw	r3, 0(r6)		#set 0x1000000 to 0x0
		lis	r6, 0x200
		stw	r3, 0(r6)		#set 0x2000000 to 0x0
		lis	r6, 0x400
		stw	r3, 0(r6)		#set 0x4000000 to 0x0
		lis	r6, 0x800
		stw	r3, 0(r6)		#set 0x8000000 to 0x0
		eieio
		stw	r4, 0(r3)		#set 0x0 to "Boon"
		eieio
		lis	r6, 0x40
		lwz	r7, 0(r6)		#read from 0x400000
		cmplw	r4, r7			#is it "Boon"
		beq	loc_3CBC		#if yes goto loc_3CBC
		lis	r6, 0x80
		lwz	r7, 0(r6)		#read form 0x800000
		cmplw	r4, r7			#is it "Boon"
		beq	loc_3E24		#if yes goto loc_3E24
		lis	r6, 0x100
		lwz	r7, 0(r6)		#read from 0x1000000
		cmplw	r4, r7			#is it "Boon"
		beq	loc_3E24		#if yes goto loc_3E24
		lis	r6, 0x200
		lwz	r7, 0(r6)		#read from 0x2000000
		cmplw	r4, r7
		beq	loc_3E24		#if its "Boon" goto loc_3E24
		lis	r6, 0x400
		lwz	r7, 0(r6)		#read from 0x4000000
		cmplw	r4, r7
		beq	loc_3E24		#if its "Boon" goto loc_3E24
		lis	r6, 0x800
		lwz	r7, 0(r6)		#read from 0x8000000
		cmplw	r4, r7
		beq	loc_3E24		#if its "Boon" goto loc_3E24
		b	loc_4184		#goto loc_4184

#********************************************************************************************
loc_3CBC:					#CODE XREF: findSetMem+1D0
		loadreg r25,0xFFEAAAAA		#set row bits to 11 row bits
		bl	ConfigWrite32
		lis	r6, 0x20		#continue tests
		stw	r3, 0(r6)
		lis	r6, 0x40
		stw	r3, 0(r6)
		lis	r6, 0x80
		stw	r3, 0(r6)
		lis	r6, 0x100
		stw	r3, 0(r6)
		lis	r6, 0x200
		stw	r3, 0(r6)
		eieio
		stw	r4, 0(r3)
		eieio
		lis	r6, 0x20
		lwz	r7, 0(r6)
		cmplw	r4, r7
		beq	loc_3D50
		lis	r6, 0x40
		lwz	r7, 0(r6)
		cmplw	r4, r7
		beq	loc_3E24
		lis	r6, 0x80
		lwz	r7, 0(r6)
		cmplw	r4, r7
		beq	loc_3E24
		lis	r6, 0x100
		lwz	r7, 0(r6)
		cmplw	r4, r7
		beq	loc_3E24
		lis	r6, 0x200
		lwz	r7, 0(r6)
		cmplw	r4, r7
		beq	loc_3E24
		b	loc_4184

#********************************************************************************************
loc_3D50:					#CODE XREF: findSetMem+274
		loadreg r25,0xFFEA5555		#set row bits to 10 row bits
		bl	ConfigWrite32
		lis	r6, 0x10		#continue tests
		stw	r3, 0(r6)
		lis	r6, 0x20
		stw	r3, 0(r6)
		lis	r6, 0x40
		stw	r3, 0(r6)
		lis	r6, 0x80
		stw	r3, 0(r6)
		eieio
		stw	r4, 0(r3)
		eieio
		lis	r6, 0x10
		lwz	r7, 0(r6)
		cmplw	r4, r7
		beq	loc_3DCC
		lis	r6, 0x20
		lwz	r7, 0(r6)
		cmplw	r4, r7
		beq	loc_3E24
		lis	r6, 0x40
		lwz	r7, 0(r6)
		cmplw	r4, r7
		beq	loc_3E24
		lis	r6, 0x80
		lwz	r7, 0(r6)
		cmplw	r4, r7
		beq	loc_3E24
		b	loc_4184

#********************************************************************************************
loc_3DCC:					#CODE XREF: findSetMem+300
		lis	r6, 8
		stw	r3, 0(r6)
		lis	r6, 0x10
		stw	r3, 0(r6)
		lis	r6, 0x20
		stw	r3, 0(r6)
		eieio
		stw	r4, 0(r3)
		eieio
		lis	r6, 8
		lwz	r7, 0(r6)
		cmplw	r4, r7
		beq	loc_4184
		lis	r6, 0x10
		lwz	r7, 0(r6)
		cmplw	r4, r7
		beq	loc_3E24
		lis	r6, 0x20
		lwz	r7, 0(r6)
		cmplw	r4, r7
		beq	loc_3E24
		b	loc_4184

#********************************************************************************************
loc_3E24:					#CODE XREF: findSetMem+1E0
						#findSetMem+1F0 ...
		cmplwi	r5, 1
		bne	loc_3E84
		mr	r7, r8
		srwi	r7, r7, 20
		andi.	r7, r7, 0xFF
		or	r9, r9, r7
		mr	r7, r8
		srwi	r7, r7, 28
		andi.	r7, r7, 3
		or	r16, r16, r7
		add	r8, r8, r6
		mr	r7, r8
		addi	r7, r7, 0xFF
		srwi	r7, r7, 20
		andi.	r7, r7, 0xFF
		or	r11, r11, r7
		mr	r7, r8
		addi	r7, r7, 0xFF
		srwi	r7, r7, 28
		andi.	r7, r7, 3
		or	r18, r18, r7
		andi.	r2, r2, 3
		or	r13, r13, r2
		b	loc_4184

#********************************************************************************************
loc_3E84:					#CODE XREF: findSetMem+394
		cmplwi	r5, 2
		bne	loc_3EF4
		mr	r7, r8
		srwi	r7, r7, 20
		andi.	r7, r7, 0xFF
		slwi	r7, r7, 8
		or	r9, r9, r7
		mr	r7, r8
		srwi	r7, r7, 28
		andi.	r7, r7, 3
		slwi	r7, r7, 8
		or	r16, r16, r7
		add	r8, r8, r6
		mr	r7, r8
		addi	r7, r7, -1
		srwi	r7, r7, 20
		andi.	r7, r7, 0xFF
		slwi	r7, r7, 8
		or	r11, r11, r7
		mr	r7, r8
		addi	r7, r7, -1
		srwi	r7, r7, 28
		andi.	r7, r7, 3
		slwi	r7, r7, 8
		or	r18, r18, r7
		andi.	r2, r2, 0xC
		or	r13, r13, r2
		b	loc_4184

#********************************************************************************************
loc_3EF4:					#CODE XREF: findSetMem+3F4
		cmplwi	r5, 4
		bne	loc_3F64
		mr	r7, r8
		srwi	r7, r7, 20
		andi.	r7, r7, 0xFF
		slwi	r7, r7, 16
		or	r9, r9, r7
		mr	r7, r8
		srwi	r7, r7, 28
		andi.	r7, r7, 3
		slwi	r7, r7, 16
		or	r16, r16, r7
		add	r8, r8, r6
		mr	r7, r8
		addi	r7, r7, -1
		srwi	r7, r7, 20
		andi.	r7, r7, 0xFF
		slwi	r7, r7, 16
		or	r11, r11, r7
		mr	r7, r8
		addi	r7, r7, -1
		srwi	r7, r7, 28
		andi.	r7, r7, 3
		slwi	r7, r7, 16
		or	r18, r18, r7
		andi.	r2, r2, 0x30
		or	r13, r13, r2
		b	loc_4184

#********************************************************************************************
loc_3F64:					#CODE XREF: findSetMem+464
		cmplwi	r5, 8
		bne	loc_3FD4
		mr	r7, r8
		srwi	r7, r7, 20
		andi.	r7, r7, 0xFF
		slwi	r7, r7, 24
		or	r9, r9, r7
		mr	r7, r8
		srwi	r7, r7, 28
		andi.	r7, r7, 3
		slwi	r7, r7, 24
		or	r16, r16, r7
		add	r8, r8, r6
		mr	r7, r8
		addi	r7, r7, -1
		srwi	r7, r7, 20
		andi.	r7, r7, 0xFF
		slwi	r7, r7, 24
		or	r11, r11, r7
		mr	r7, r8
		addi	r7, r7, -1
		srwi	r7, r7, 28
		andi.	r7, r7, 3
		slwi	r7, r7, 24
		or	r18, r18, r7
		andi.	r2, r2, 0xC0
		or	r13, r13, r2
		b	loc_4184

#********************************************************************************************
loc_3FD4:					#CODE XREF: findSetMem+4D4
		cmplwi	r5, 0x10
		bne	loc_4034
		mr	r7, r8
		srwi	r7, r7, 20
		andi.	r7, r7, 0xFF
		or	r10, r10, r7
		mr	r7, r8
		srwi	r7, r7, 28
		andi.	r7, r7, 3
		or	r17, r17, r7
		add	r8, r8, r6

loc_4000:
		mr	r7, r8
		addi	r7, r7, -1
		srwi	r7, r7, 20
		andi.	r7, r7, 0xFF
		or	r12, r12, r7
		mr	r7, r8
		addi	r7, r7, -1
		srwi	r7, r7, 28
		andi.	r7, r7, 3
		or	r19, r19, r7
		andi.	r2, r2, 0x300
		or	r13, r13, r2
		b	loc_4184

#********************************************************************************************
loc_4034:
		cmplwi	r5, 0x20

		bne	loc_40A4
		mr	r7, r8
		srwi	r7, r7, 20
		andi.	r7, r7, 0xFF
		slwi	r7, r7, 8
		or	r10, r10, r7
		mr	r7, r8
		srwi	r7, r7, 28
		andi.	r7, r7, 3
		slwi	r7, r7, 8
		or	r17, r17, r7
		add	r8, r8, r6
		mr	r7, r8
		addi	r7, r7, -1
		srwi	r7, r7, 20
		andi.	r7, r7, 0xFF
		slwi	r7, r7, 8
		or	r12, r12, r7
		mr	r7, r8
		addi	r7, r7, -1
		srwi	r7, r7, 28
		andi.	r7, r7, 3
		slwi	r7, r7, 8
		or	r19, r19, r7
		andi.	r2, r2, 0xC00
		or	r13, r13, r2
		b	loc_4184

#********************************************************************************************
loc_40A4:
		cmplwi	r5, 0x40
		bne	loc_4114
		mr	r7, r8
		srwi	r7, r7, 20
		andi.	r7, r7, 0xFF
		slwi	r7, r7, 16
		or	r10, r10, r7
		mr	r7, r8
		srwi	r7, r7, 28
		andi.	r7, r7, 3
		slwi	r7, r7, 16
		or	r17, r17, r7
		add	r8, r8, r6
		mr	r7, r8
		addi	r7, r7, -1
		srwi	r7, r7, 20
		andi.	r7, r7, 0xFF
		slwi	r7, r7, 16
		or	r12, r12, r7
		mr	r7, r8
		addi	r7, r7, -1
		srwi	r7, r7, 28
		andi.	r7, r7, 3
		slwi	r7, r7, 16
		or	r19, r19, r7
		andi.	r2, r2, 0x3000
		or	r13, r13, r2
		b	loc_4184

#********************************************************************************************
loc_4114:
		cmplwi	r5, 0x80
		bne	loc_4184
		mr	r7, r8
		srwi	r7, r7, 20
		andi.	r7, r7, 0xFF
		slwi	r7, r7, 24
		or	r10, r10, r7
		mr	r7, r8
		srwi	r7, r7, 28
		andi.	r7, r7, 3
		slwi	r7, r7, 24
		or	r17, r17, r7
		add	r8, r8, r6
		mr	r7, r8
		addi	r7, r7, -1
		srwi	r7, r7, 20
		andi.	r7, r7, 0xFF
		slwi	r7, r7, 24
		or	r12, r12, r7
		mr	r7, r8
		addi	r7, r7, -1
		srwi	r7, r7, 28
		andi.	r7, r7, 3
		slwi	r7, r7, 24
		or	r19, r19, r7
		andi.	r2, r2, 0xc000
		or	r13, r13, r2
		b	loc_4184

loc_4184:
		slwi	r5, r5, 1
		cmplwi	r5, 0x100
		bne	loc_3BD8

		setpcireg MSAR1				#80
		mr	r25, r9
		bl	ConfigWrite32			#store found values to registers

		setpcireg MSAR2				#84
		mr	r25, r10
		bl	ConfigWrite32

		setpcireg MEAR1				#90
		mr	r25, r11
		bl	ConfigWrite32

		setpcireg MEAR2				#94
		mr	r25, r12
		bl	ConfigWrite32

		setpcireg MCCR1				#F0
		mr	r25, r13
		bl	ConfigWrite32

		setpcireg MBEN				#A0
		mr	r25, r14
		bl	ConfigWrite8

		setpcireg MESAR1			#88
		mr	r25, r16
		bl	ConfigWrite32

		setpcireg MESAR2			#8c
		mr	r25, r17
		bl	ConfigWrite32

		setpcireg MEEAR1			#98
		mr	r25, r18
		bl	ConfigWrite32

		setpcireg MEEAR2			#9C
		mr	r25, r19
		bl	ConfigWrite32

		addi	r16, r7, 4
	
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

InstallExceptions:
		mflr	r15
		bl	GtCode
Halt:		nop
		b	Halt
GtCode:		mflr	r16
		li	r17,0
		li	r18,20
		mtctr	r18
FillEm:		addi	r17,r17,0x100
		lwz	r19,0(r16)
		stw	r19,0(r17)
		lwz	r19,4(r16)
		stw	r19,4(r17)
		bdnz	FillEm
		bl	EIntEnd

#********************************************************************************************

EInt:		b	.DecInt

		mtsprg2	r0
		mfsrr0	r0
		mtsprg0	r0
		mfsrr1	r0
		mtsprg1	r0
		
		BUILDSTACKPPC

		stwu	r3,-4(r13)
		stwu	r4,-4(r13)
		stwu 	r5,-4(r13)
		stwu	r6,-4(r13)
		stwu	r7,-4(r13)
		stwu	r8,-4(r13)
		stwu	r9,-4(r13)

		mfmsr	r5
		ori	r5,r5,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r5				#Reenable MMU (can affect srr0/srr1 acc Docs)
		isync					#Also reenable FPU
		sync

		lis	r3,EUMBEPICPROC
		lwz	r5,0xa0(r3)			#Read IACKR to acknowledge it

		rlwinm	r5,r5,8,0,31
		cmpwi	r5,0x00ff			#Spurious Vector. Should not do EOI acc Docs.
		beq	.ReturnToUser
		
		cmpwi	r5,0x0042
		beq	TestRoutine
		
		cmpwi	r5,0x0043
		
#		beq	Timer

.IntReturn:	lis	r3,EUMB
		lis	r5,0x100			#Clear IM0 bit to clear interrupt
		stw	r5,0x100(r3)
		eieio
		clearreg r5
		lis	r3,EUMBEPICPROC
		stw	r5,0xb0(r3)			#Write 0 to EOI to End Interrupt

.RDecInt:	li	r3,0
		stb	r3,Interrupt(r0)

		lwz	r9,TaskException(r0)
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
		
.GotOneWait:	mr	r6,r4
		
		LIBCALLPOWERPC	RemovePPC
		
		mr	r5,r6
		la	r4,ReadyTasks(r0)
		
		LIBCALLPOWERPC AddTailPPC		

.EndOfWaitList:	lwz	r9,RunningTask(r0)

		b	.TrySwitch

.NewTask:	lwz	r3,SonnetBase(r0)
		la	r4,NewTasks(r3)

		LIBCALLPOWERPC RemHeadPPC
	
		mr.	r9,r3
		beq	.ReturnToUser

.Dispatch:	LIBCALLPOWERPC FlushL1DCache
		
		li	r4,TS_RUN
		stb	r4,TC_STATE(r9)
		stw	r9,RunningTask(r0)
		
		loadreg	r4,500000			#fixed stack len (for now)
		
		LIBCALLPOWERPC AllocVecPPC
		
		mr.	r4,r3
		beq	.ReturnToUser	
		
		loadreg	r6,0x8000
		addi	r6,r6,ExitCode-Start	
		mtlr	r6

		lwz	r8,RunningTask(r0)
		lwz	r6,SonnetBase(r0)
		xor	r4,r4,r6		
		stw	r4,TC_SPLOWER(r8)
		loadreg	r5,500000-32
		add	r4,r4,r5
		stw	r4,TC_SPUPPER(r8)
		stw	r4,TC_SPREG(r8)
		mr	r1,r4
		
		BUILDSTACKPPC		
		
		la	r8,TASKPPC_SIZE(r8)
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
		lwz	r8,PP_CODE(r8)
		add	r8,r8,r9
		
		sync
		isync

		mtsprg0	r8

		li	r8,0
		
		mr	r7,r8
		mr	r9,r8
		mr	r10,r8
		mr 	r11,r8
		mr	r12,r8
		mr	r14,r8
		mr	r15,r8
		mr	r16,r8
		mr	r17,r8
		mr	r18,r8
		mr	r19,r8
		mr	r20,r8
		mr	r21,r8
		
		mfsprg1	r0
		mtsrr1	r0
		mfsprg0	r0
		mtsrr0	r0

		li	r0,0
		
		rfi
		
#********************************************************************************************

.ReturnToUser:
		lwz	r9,0xf0(r0)
		addi	r9,r9,1
		stw	r9,0xf0(r0)
		
		lwz	r9,0(r13)
		lwzu	r8,4(r13)
		lwzu	r7,4(r13)
		lwzu	r6,4(r13)
		lwzu	r5,4(r13)
		lwzu	r4,4(r13)
		lwzu	r3,4(r13)
		addi	r13,r13,4
	
		DSTRYSTACKPPC
	
		mfsprg1 r0
		mtsrr1	r0
		mfsprg0	r0
		mtsrr0	r0
		mfsprg2	r0

		rfi
		
#********************************************************************************************

TestRoutine:	b	.IntReturn

#********************************************************************************************

.TaskException:	li	r9,0				#Will be starting point for TC_EXCEPTCODE
		stw	r9,TaskException(r0)
		b	.ReturnToUser
		
#********************************************************************************************

.TrySwitch:	mr.	r9,r9
		bne	.CheckWait
		
		la	r4,ReadyTasks(r0)
		
		LIBCALLPOWERPC RemHeadPPC
		
		mr.	r9,r3
		
		beq	.NewTask

		li	r6,TS_RUN
		stb	r6,TC_STATE(r9)
		stw	r9,RunningTask(r0)
		
		b	.LoadContext
		

.CheckWait:	li	r4,TS_WAIT
		lbz	r3,TC_STATE(r9)
		cmpw	r3,r4
		beq	.GoToWait

		lwz	r3,0(r3)
		la	r4,NewTasks(r3)
	
		LIBCALLPOWERPC RemHeadPPC
	
		mr.	r9,r3
		bne	.SwitchNew
	
		la	r4,ReadyTasks(r0)
	
		LIBCALLPOWERPC RemHeadPPC
	
		mr.	r9,r3	
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
		
		LIBCALLPOWERPC AddTailPPC
		
		b	.LoadContext
	
.SwitchNew:	la	r4,ReadyTasks(r0)
		lwz	r5,RunningTask(r0)
		stw	r9,RunningTask(r0)
		
		li	r6,TS_READY
		stb	r6,TC_STATE(r5)
		
		bl	.StoreContext
		
		LIBCALLPOWERPC AddTailPPC
	
		b	.Dispatch
		
.StoreContext:	lwz	r6,TASKPPC_CONTEXTMEM(r5)
		mfsprg0	r3
		stw	r3,0(r6)
		mfsprg1 r3
		stwu	r3,4(r6)
		lwz	r3,0(r1)
		lwz	r0,8(r3)			#lr
		stwu	r0,4(r6)
		lwz	r0,4(r3)			#cr
		stwu	r0,4(r6)
		mfctr	r0
		stwu	r0,4(r6)
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
		stfdu	f0,8(r6)			#Pad to make align on 8
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
		lfdu	f0,8(r9)			#Pad to make align on 8
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
		mfsprg3	r9
		rfi

.GoToWait:	la	r4,WaitingTasks(r0)
		mr	r5,r9
		
		bl	.StoreContext
		
		LIBCALLPOWERPC AddTailPPC
		
		li	r4,0
		stw	r4,RunningTask(r0)

		la	r4,ReadyTasks(r0)
	
		LIBCALLPOWERPC RemHeadPPC
	
		mr.	r9,r3
		beq	.DoIdle
		
		li	r0,TS_RUN
		stb	r0,TC_STATE(r9)
		stw	r9,RunningTask(r0)
		
		b	.LoadContext

.DoIdle:	loadreg	r19,0x8000			#Start hardcoded at 0x8000

		loadreg	r1,0x7ffe0			#Userstack in unused mem (See sonnet.s)
		BUILDSTACKPPC
		
		mfsrr1	r18
		ori	r18,r18,PSL_PR|PSL_EE
		mtsrr1 	r18		
		mtsrr0	r19
		rfi

#********************************************************************************************
		
.DecInt:	mtsprg2	r0
		mfsrr0	r0
		mtsprg0	r0
		mfsrr1	r0
		mtsprg1	r0

		BUILDSTACKPPC

		stwu	r3,-4(r13)
		stwu	r4,-4(r13)
		stwu 	r5,-4(r13)
		stwu	r6,-4(r13)
		stwu	r7,-4(r13)
		stwu	r8,-4(r13)
		stwu	r9,-4(r13)

		mfmsr	r5
		ori	r5,r5,(PSL_IR|PSL_DR|PSL_FP)
		mtmsr	r5				#Reenable MMU (can affect srr0/srr1 acc Docs)
		isync					#Also reenable FPU
		sync

		b	.RDecInt

#********************************************************************************************
	
EIntEnd:
		mflr	r4
		loadreg	r5,0x48002b04
		stw	r5,0x500(r0)
		loadreg r5,0x48002700
		stw	r5,0x900(r0)	
	
		li	r3,0x3000			#Jump from Exception (0x500) immediatly to 0x3000
		li	r5,EIntEnd-EInt
		li	r6,0
		bl	copy_and_flush
		bl	PrIntEnd

#********************************************************************************************

PrInt:							#Privilege Exception
		mtsprg	1,r3
		mfspr	r3,HID0
		ori	r3,r3,HID0_ICFI|HID0_DCFI
		xori	r3,r3,HID0_ICFI|HID0_DCFI
		mtspr	HID0,r3
		mfcr	r3
		mtsprg	2,r3
		mtsprg	3,r0
		mfsrr0	r3

		lwz	r0,ViolationAddress(r0)

		cmplw	r0,r3
		bne-	.HaltErr
		addi	r3,r3,4				#Next instruction
		mtsrr0	r3
		mfsrr1	r3
		ori	r3,r3,PSL_PR			#Set to Super
		xori	r3,r3,PSL_PR
		mtsrr1	r3
		mfsprg	r3,2
		mtcr	r3
		mfsprg	r3,1
		li	r0,0				#SuperKey
		rfi
.HaltErr:
		loadreg r3,"HALT"			#DEBUG
		stw	r3,0xf0(r0)
		mfsrr1	r3
		stw	r3,0xf4(r0)
.xxHaltErr2:	b .xxHaltErr2

#********************************************************************************************

PrIntEnd:
		mflr	r4
		li	r3,0x700
		li	r5,PrIntEnd-PrInt
		li	r6,0
		bl	copy_and_flush
	
		mtlr	r15
		blr

#********************************************************************************************
PPCEnd:
