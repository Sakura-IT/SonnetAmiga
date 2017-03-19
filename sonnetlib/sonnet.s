
	include 68kdefines.i
	include	exec/exec_lib.i
	include exec/initializers.i
	include	exec/nodes.i
	include exec/libraries.i
	include exec/resident.i
	include	exec/memory.i
	include pci.i
	include	libraries/expansion_lib.i
	include	libraries/configvars.i
	include	exec/execbase.i
	include powerpc/powerpc.i
	include powerpc/tasksPPC.i
	include	dos/dostags.i
	include dos/dos_lib.i
	include intuition/intuition_lib.i
	include exec/ports.i
	include dos/dosextens.i
	include	exec/interrupts.i
	include hardware/intbits.i
	include	exec/tasks.i
	include sonnet_lib.i

	XREF	SetExcMMU,ClearExcMMU,InsertPPC,AddHeadPPC,AddTailPPC
	XREF	RemovePPC,RemHeadPPC,RemTailPPC,EnqueuePPC,FindNamePPC,ResetPPC,NewListPPC
	XREF	AddTimePPC,SubTimePPC,CmpTimePPC,AllocVecPPC,FreeVecPPC,GetInfo,GetSysTimePPC
	XREF	NextTagItemPPC,GetTagDataPPC,FindTagItemPPC,FreeSignalPPC
	XREF	AllocXMsgPPC,FreeXMsgPPC,CreateMsgPortPPC,DeleteMsgPortPPC,AllocSignalPPC
	XREF	SetSignalPPC,LockTaskList,UnLockTaskList
	XREF	InitSemaphorePPC,FreeSemaphorePPC,ObtainSemaphorePPC,AttemptSemaphorePPC
	XREF	ReleaseSemaphorePPC,AddSemaphorePPC,RemSemaphorePPC,FindSemaphorePPC
	XREF	AddPortPPC,RemPortPPC,FindPortPPC,WaitPortPPC,Super,User
	XREF	PutXMsgPPC,WaitFor68K,Run68K,Signal68K,CopyMemPPC,SetReplyPortPPC
	XREF	TrySemaphorePPC,CreatePoolPPC

	XREF	SPrintF,Run68KLowLevel,CreateTaskPPC,DeleteTaskPPC,FindTaskPPC,SignalPPC
	XREF	WaitPPC,SetTaskPriPPC,SetCache,SetExcHandler,RemExcHandler,SetHardware
	XREF	ModifyFPExc,WaitTime,ChangeStack,ChangeMMU,PutMsgPPC,GetMsgPPC,ReplyMsgPPC
	XREF	FreeAllMem,SnoopTask,EndSnoopTask,GetHALInfo,SetScheduling,FindTaskByID
	XREF	SetNiceValue,AllocPrivateMem,FreePrivateMem,SetExceptPPC,ObtainSemaphoreSharedPPC
	XREF	AttemptSemaphoreSharedPPC,ProcurePPC,VacatePPC,CauseInterrupt,DeletePoolPPC
	XREF	AllocPooledPPC,FreePooledPPC,RawDoFmtPPC,PutPublicMsgPPC,AddUniquePortPPC
	XREF	AddUniqueSemaphorePPC,IsExceptionMode,CreateMsgFramePPC,SendMsgFramePPC
	XREF	FreeMsgFramePPC
	
	IFD	_IFUSION_
	
	XREF	WarpIllegal
	
	ENDC

	XREF 	PPCCode,PPCLen,MCPort,Init,SysBase,PowerPCBase,DOSBase,sonnet_PosSize
	XDEF	_PowerPCBase,FunctionsLen,LibFunctions

;********************************************************************************************

	SECTION LibBody,CODE

;********************************************************************************************


		moveq.l #-1,d0
		rts

ROMTAG:
		dc.w	RTC_MATCHWORD
		dc.l	ROMTAG
		dc.l	ENDSKIP
		dc.b	0					;WAS RTF_AUTOINIT
		dc.b	17					;RT_VERSION
		dc.b	NT_LIBRARY				;RT_TYPE
		dc.b	0					;RT_PRI
		dc.l	LibName
		dc.l	IDString
		dc.l	LIBINIT

ENDSKIP:
		ds.w	1

LIBINIT:
		movem.l d1-a6,-(a7)
		move.l 4.w,a6
		lea Buffer(pc),a4
		move.l a0,(a4)				;SegList
		move.l a6,LExecBase-Buffer(a4)

		lea LibList(a6),a0
		lea PowerName(pc),a1			;Check for WarpOS
		jsr _LVOFindName(a6)
		tst.l d0
		beq.s NoWOS

		lea PowerPCError(pc),a2
		bra PrintError

NoWOS		lea DosLib(pc),a1
		moveq.l #37,d0
		jsr _LVOOpenLibrary(a6)
		tst.l d0
		bne GotDOS				;Open dos.library
		
		lea LDOSError(pc),a2
		bra PrintError
		
GotDOS		move.l d0,DosBase-Buffer(a4)
		lea ExpLib(pc),a1
		moveq.l #37,d0
		jsr _LVOOpenLibrary(a6)			;Open expansion.library
		tst.l d0
		bne.s GotExp

		lea LExpError(pc),a2
		bra PrintError		
	
GotExp		move.l d0,ExpBase-Buffer(a4)
		move.l d0,a6
		sub.l a0,a0
		move.l #VENDOR_ELBOX,d0			;ELBOX
		moveq.l #MEDIATOR_MKII,d1		;Mediator MKII
		jsr _LVOFindConfigDev(a6)		;Find A3000/A4000 mediator
		tst.l d0
		bne.s FoundMed
		
WeirdMed	lea MedError(pc),a2
		bra PrintError

FoundMed	sub.l a0,a0
		move.l #VENDOR_ELBOX,d0			;ELBOX
		move.l #MEDIATOR_LOGIC,d1		;Mediator Logic board for A3/4000
		jsr _LVOFindConfigDev(a6)
		tst.l d0
		beq.s WeirdMed

		move.l d0,a1
		move.l LExecBase(pc),a6
		move.l cd_BoardSize(a1),d0		;Start address Configspace Mediator
		cmp.l #$20000000,d0
		beq CorrectWindowJ			;WindowSize 512MB?

		lea MedWindowJ(pc),a2
		bra PrintError

CorrectWindowJ	move.l cd_BoardAddr(a1),d0
		cmp.l #$60000000,d0
		beq CorrectConfigJ			;MemorySpace at default position?

		lea MedConfigJ(pc),a2
		bra PrintError

CorrectConfigJ	lea MemList(a6),a0
		lea MemName(pc),a1
		jsr _LVOFindName(a6)			;Check for sonnet memory
		tst.l d0
		bne.s Clean

		moveq.l #PCI_VERSION,d0			;Minimal version of pci.library
		lea pcilib(pc),a1
		jsr _LVOOpenLibrary(a6)
		move.l d0,PCIBase-Buffer(a4)

		lea MemList(a6),a0
		lea PCIMem(pc),a1			;Check for PCI DMA (GFX) memory
		jsr _LVOFindName(a6)
		tst.l d0
		bne.s FndMem

		lea MemMedError(pc),a2
		bra PrintError

Clean		move.l LExecBase(pc),a6
		move.l ROMMem(pc),d0
		beq.s NoROM
		bsr.s FreeROM
NoROM		move.l PCIBase(pc),d0
		beq.s NoPCI
		bsr.s ClsLib
NoPCI		move.l DosBase(pc),d0
		beq.s NoDos
		bsr.s ClsLib
NoDos		move.l ExpBase(pc),d0
		beq.s Exit
		bsr.s ClsLib
Exit		move.l _PowerPCBase(pc),d0
		movem.l (a7)+,d1-a6
		rts

ClsLib  	move.l d0,a1
		jmp _LVOCloseLibrary(a6)

FreeROM		move.l d0,a1
		jmp _LVOFreeVec(a6)

FndMem		move.l d0,d7

		jsr _LVODisable(a6)
		move.l d7,a1
		jsr _LVORemove(a6)
		lea MemList(a6),a0
		move.l d7,a1
		jsr _LVOAddTail(a6)			;Move gfx memory to back to prevent
		jsr _LVOEnable(a6)			;mem list corruption if LE

		move.l PCIBase(pc),d0
		bne.s GotPCI

		lea LPCIError(pc),a2
		bra PrintError
		
CheckATI	move.w #VENDOR_ATI,d0
		move.w d0,d5
		moveq.l #0,d2
		jmp _LVOPCIFindCard(a6)			;Check for ATI 92xx	

GotPCI		move.l d0,a6
		move.w #VENDOR_MOTOROLA,d0
		move.w #DEVICE_MPC107,d1
		moveq.l #0,d2
		jsr _LVOPCIFindCard(a6)			;Check for Sonnet card
		move.l d0,d6
		bne.s GotSonnetCard
	
		lea SonnetError(pc),a2
		bra PrintError		
		
GotSonnetCard	move.w #VENDOR_3DFX,d0
		move.w d0,d5
		move.w #DEVICE_VOODOO45,d1
		moveq.l #0,d2
		jsr _LVOPCIFindCard(a6)			;Check for Voodoo4/5
		tst.l d0		
		beq.s Nxt3DFX
		move.l d0,a2
		addq.l #1,d5
		move.l PCI_SPACE0(a2),d4
		bra.s FoundGfx
	
Nxt3DFX		move.w #VENDOR_3DFX,d0
		move.w d0,d5
		move.w #DEVICE_VOODOO3,d1		;Check for Voodoo3
		moveq.l #0,d2
		jsr _LVOPCIFindCard(a6)
		tst.l d0		
		beq.s Not3DFX
		move.l d0,a2
		move.l PCI_SPACE0(a2),d4
		bra.s FoundGfx
			
Not3DFX		lea ATIs(pc),a3
NextATI		move.l (a3)+,d1
		beq.s NoATI
		
		bsr CheckATI
		tst.l d0
		bne.s GotATI
		bra.s NextATI
		
NoATI		lea VGAError(pc),a2
		bra PrintError

ATIs		dc.l	DEVICE_RV280PRO,DEVICE_RV280MOB,DEVICE_RV280SE,0		

GotATI		move.l d0,a2
		move.l PCI_SPACE0(a2),d4

FoundGfx	move.l LExecBase(pc),a6
		move.l d4,GfxMem-Buffer(a4)
		move.w d5,GfxType-Buffer(a4)
		move.l d6,a2
		move.l a2,SonAddr-Buffer(a4)
		
		move.l #$20000,d0
		move.l #MEMF_PUBLIC|MEMF_PPC,d1
		jsr _LVOAllocVec(a6)
		tst.l d0				;Allocate fake ROM in VGA Mem
		bne.s GotVGAMem

		lea MemVGAError(pc),a2
		bra PrintError

GotVGAMem	move.l d0,ROMMem-Buffer(a4)
		add.l #$10000,d0
		and.w #0,d0				;Align ROM on $10000
		move.l d0,a5
		move.l a5,a1
		lea $100(a5),a5				;Pointer to system reset exception

		move.l PCI_SPACE1(a2),a3		;PCSRBAR Sonnet
		move.l a3,EUMBAddr-Buffer(a4)
		or.b #15,d0				;64kb ROM
		rol.w #8,d0
		swap d0
		rol.w #8,d0
		move.l d0,OTWR(a3)			;Make ROM visible and place it at
		move.l #$0000F0FF,OMBAR(a3)		;Processor outbound mem at $FFF00000

		move.l a2,d4
EndDrty		move.l #$48002f00,(a5)			;PPC branch to code outside exception space (0x3000)
		lea $2f00(a5),a5
		lea PPCCode(pc),a2
		move.l #PPCLen,d6
		lsr.l #2,d6
		subq.l #1,d6

loop2		move.l (a2)+,(a5)+			;Copy code to 0x3000
		dbf d6,loop2

		move.l #$abcdabcd,$3004(a1)		;Code Word
		move.l #$abcdabcd,$3008(a1)		;Sonnet Mem Start (Translated to PCI)
		move.l #$abcdabcd,$300c(a1)		;Sonnet Mem Len
		move.l GfxMem(pc),$3010(a1)
		move.l GfxType(pc),$3014(a1)

		jsr _LVOCacheClearU(a6)

		tst.l d4
		bne.s NoCmm
		move.l d5,a5
		move.l COMMAND(a5),d5
		bset #26,d5				;Set Bus Master bit
		move.l d5,COMMAND(a5)

NoCmm		move.l #WP_TRIG01,WP_CONTROL(a3)	;Negate HRESET. Now code gets executed
							;at 0xfff00100 which jumps to 0xfff03000							
		move.l	#$EC0000,d7			;Simple Time-out timer
		
Wait		subq.l #1,d7
		beq.s TimeOut
		move.l $3004(a1),d5
		cmp.l #"Boon",d5			;This is returned when PPC is set up
		beq.s PPCReady
		cmp.l #"Err3",d5
		beq.s UnstableRam
		cmp.l #"Err2",d5			;When no memory found on the Sonnet
		beq.s NoSonRam
		cmp.l #"Err1",d5			;When the MMU was not set up correctly
		bne.s Wait
		
		lea PPCMMUError(pc),a2
		bra PrintError
		
TimeOut		cmp.l #"Init",d5
		beq.s PPCCrashed
		
		cmp.l #"Boon",d5
		bne.s PPCError

PPCCrashed	lea PPCCrash(pc),a2
		bra PrintError
		
PPCError	lea NoPPCFound(pc),a2
		bra PrintError		
		
UnstableRam	lea SonnetUnstable(pc),a2
		bra PrintError

NoSonRam	lea SonnetMemError(pc),a2
		bra PrintError

PPCReady	move.l #NoMemAccess,d7			;Part of memory not accessible
		move.l $3008(a1),d5
		move.l d5,SonnetBase-Buffer(a4)
		add.l d7,d5
		move.l $300c(a1),d6
		sub.l d7,d6
		add.l d6,d7

		moveq.l #16,d0
		move.l #MEMF_PUBLIC|MEMF_CLEAR|MEMF_REVERSE,d1
		jsr _LVOAllocVec(a6)			;Reserve space for sonnet mem name
		tst.l d0
		bne.s GotMemName			
		
		lea GenMemError(pc),a2
		bra PrintError

GotMemName	move.l d0,a0
		lea MemName(pc),a1
		move.l (a1),(a0)
		move.l 4(a1),4(a0)
		move.l 8(a1),8(a0)
		move.l 12(a1),12(a0)

		move.l a0,a1				;Set up sonnet memory on 68k side:
		move.l d5,a0
		move.w #$0a01,LN_TYPE(a0)		;TYPE and PRI
		move.l a1,LN_NAME(a0)
		move.w #MEMF_PUBLIC|MEMF_FAST|MEMF_PPC,14(a0)
		lea MH_SIZE(a0),a1
		move.l a1,MH_FIRST(a0)
		clr.l (a1)

		move.l d6,d1
		sub.l #PageTableSize+32,d1		;for pagetable
		move.l d1,MC_BYTES(a1)
		move.l a1,MH_LOWER(a0)
		add.l a0,d6
		sub.l #PageTableSize,d6			;for pagetable
		move.l d6,MH_UPPER(a0)
		move.l d1,MH_FREE(a0)
		move.l a0,a1
		move.l a0,a5

		jsr _LVODisable(a6)
		lea MemList(a6),a0
		tst.l d4
		beq.s NoPCILb

		move.l d4,a2
		sub.l #NoMemAccess,d5
		move.l d5,PCI_SPACE0(a2)
		moveq.l #0,d6
		sub.l d7,d6
		move.l d6,PCI_SPACELEN0(a2)		;Correct MemSpace0 in the PCI database
NoPCILb		jsr _LVOEnqueue(a6)			;Add the memory node

		lea DATATABLE(pc),a2
		bsr MakeLibrary
		tst.l d0
		bne.s GotLibMade

NotLibMade	jsr _LVOEnable(a6)
		lea LSetupError(pc),a2
		bra PrintError

GotLibMade	move.l SonnetBase(pc),a1
		move.l d0,PowerPCBase(a1)
		move.l a5,PPCMemHeader(a1)		;Memheader at $8
		move.l a1,(a1)				;Sonnet relocated mem at $0
		move.l d0,_PowerPCBase-Buffer(a4)
		move.l a6,SysBase(a1)
		move.l DosBase(pc),DOSBase(a1)

		move.l d0,a1
		addq.w #1,LIB_OPENCNT(a1)		;Prevent closure and all kinds of problems
		jsr _LVOAddLibrary(a6)

		lea POWERDATATABLE(pc),a2
		bsr MakeLibrary
		tst.l d0
		beq NotLibMade
		
		move.l d0,a1
		addq.w #1,LIB_OPENCNT(a1)		;Prevent closure and all kinds of problems
;		jsr _LVOAddLibrary(a6)			;DEBUG: DISABLED FOR NOW

		lea WARPFUNCTABLE(pc),a0		;Set up a fake warp.library
		lea WARPDATATABLE(pc),a1		;Some programs do a version
		sub.l a2,a2				;check on this
		moveq.l #124,d0
		moveq.l #0,d1
		jsr _LVOMakeLibrary(a6)
		move.l d0,a1
		jsr _LVOAddLibrary(a6)

		lea MyInterrupt(pc),a1
		lea SonInt(pc),a2
		move.l a2,IS_CODE(a1)
		lea IntData(pc),a2
		move.l a2,IS_DATA(a1)
		lea IntName(pc),a2
		move.l a2,LN_NAME(a1)
		moveq.l #100,d0
		move.b d0,LN_PRI(a1)
		moveq.l #NT_INTERRUPT,d0
		move.b d0,LN_TYPE(a1)

		move.l PCIBase(pc),a6
		move.l SonAddr(pc),a0
		jsr _LVOPCIAddIntServer(a6)		;Attach Sonnet card to PCI Interrupt Chain

		move.l SonAddr(pc),a0
		jsr _LVOPCIEnableInterupt(a6)		;Enable interrupt

		lea PrcTags(pc),a1
		move.l a1,d1
		move.l DosBase(pc),a6
		jsr _LVOCreateNewProc(a6)		;Start up Master Control
							;It will start phase 2 of PPC setup
		move.l LExecBase(pc),a6
		jsr _LVOEnable(a6)

PPCInit		move.l SonnetBase(pc),a1
		move.l Init(a1),d0
		cmp.l #"REDY",d0			;Phase 2 of PPC setup completed?
		bne.s PPCInit

		move.l GfxMem(pc),d0			;Amiga PCI Memory
		move.l SonAddr(pc),a2
		move.l PCI_SPACE1(a2),a3		;PCSRBAR Sonnet
		or.b #27,d0				;256MB
		rol.w #8,d0
		swap d0
		rol.w #8,d0
		move.l d0,OTWR(a3)
		add.b #$40,d0				;Translated to PPC PCI Memory
		move.l d0,OMBAR(a3)			;Is probably 0x60000000-0x80000000
		
		jsr _LVODisable(a6)
		
		moveq.l #MEMF_PUBLIC,d1
		move.l #$4000,d2
		moveq.l #0,d3
		
		bsr ChangeStack68K			;Enlarge RamLib stack
		
		move.l #_LVOLoadSeg,a0			;Set system patches
		lea NewOldLoadSeg(pc),a3
		move.l a3,d0
		move.l DosBase(pc),a1
		jsr _LVOSetFunction(a6)			;LoadSeg to correctly scatter-load sonnet exes
		lea LoadSegAddress(pc),a3
		move.l d0,(a3)
		
		move.l #_LVONewLoadSeg,a0
		lea NewNewLoadSeg(pc),a3
		move.l a3,d0
		move.l DosBase(pc),a1
		jsr _LVOSetFunction(a6)			;NewLoadSeg to correctly scatter-load sonnet exes
		lea NewLoadSegAddress(pc),a3
		move.l d0,(a3)
	
		move.l #_LVOAddTask,a0
		lea StartCode(pc),a3
		move.l a3,d0
		move.l a6,a1
		jsr _LVOSetFunction(a6)			;AddTask to track PPC mirror tasks
		lea AddTaskAddress(pc),a3
		move.l d0,(a3)
		
		move.l #_LVORemTask,a0			;Counterpart to AddTask
		lea ExitCode(pc),a3
		move.l a3,d0
		move.l a6,a1
		jsr _LVOSetFunction(a6)
		lea RemTaskAddress(pc),a3
		move.l d0,(a3)
				
		move.l #_LVOOpenLibrary,a0
		lea OpenCode(pc),a3
		move.l a3,d0
		move.l a6,a1
		jsr _LVOSetFunction(a6)			;To force certain lib bases to MEMF_PPC
		lea OpenLibAddress(pc),a3
		move.l d0,(a3)
		
		move.l #_LVOAllocMem,a0
		lea NewAlloc(pc),a3
		move.l a3,d0
		move.l a6,a1
		jsr _LVOSetFunction(a6)			;To force memory allocations to MEMF_PPC
		lea AllocMemAddress(pc),a3
		move.l d0,(a3)

		jsr _LVOCacheClearU(a6)

		lea MirrorList(pc),a3			;Make a list for PPC Mirror Tasks
		move.l a3,LH_TAILPRED(a3)
		addq.l #4,a3
		clr.l (a3)
		move.l a3,-(a3)

		jsr _LVOEnable(a6)
		
		move.l LExecBase(pc),a6
		moveq.l #0,d0
		lea ppclib(pc),a1
		jsr _LVOOpenLibrary(a6)			;Open ppc.library for LoadSeg() patch
		
		bra Clean

;********************************************************************************************

PrintError	move.l LExecBase(pc),a6			;Put up a requester and give out
		lea IntuitionLib(pc),a1			;an error message
		moveq.l #33,d0
		jsr _LVOOpenLibrary(a6)
		tst.l d0
		beq Clean
		move.l d0,a6
		lea LibName(pc),a0
		lea Requester(pc),a1
		move.l a0,8(a1)
		move.l a2,12(a1)
		lea RContinue(pc),a0
		move.l a0,16(a1)
		sub.l a0,a0
		move.l a0,a2
		move.l a0,a3
		jsr _LVOEasyRequestArgs(a6)
		move.l a6,a1
		move.l LExecBase(pc),a6
		jsr _LVOCloseLibrary(a6)
		bra Clean
		
;********************************************************************************************

MakeLibrary
		movem.l d1-a6,-(a7)			;Sets up library base and function table		
		move.l #FunctionsLen,d0
		move.l #MEMF_PUBLIC|MEMF_PPC|MEMF_REVERSE|MEMF_CLEAR,d1
		bsr AllocVec32				;Reserve space for the function table
		tst.l d0				;to be copied to PPC memory
		beq NoFun
		
		move.l PPCCodeMem(pc),d1
		beq.s FirstMem

		move.l d0,PPCCodeMem2-Buffer(a4)
		bra.s SecondMem

FirstMem	move.l d0,PPCCodeMem-Buffer(a4)
SecondMem	move.l d0,a1
		lea LibFunctions(pc),a0
		move.l #FunctionsLen,d1
		lsr.l #2,d1
		subq.l #1,d1
MoveSon		move.l (a0)+,(a1)+
		dbf d1,MoveSon				;Do the copy to PPC/Sonnet memory		
		
		sub.l a0,a1
		move.l a1,d6
		lea FUNCTABLE(pc),a0
		move.l a2,a1
		move.l a0,d4
		move.l a1,d5
		moveq.l #-1,d3
		move.l d3,d0
		move.l a0,a3
NumFunc		cmp.l (a3)+,d0
		dbeq d3,NumFunc
		not.w d3
		lsl #1,d3
		move.l d3,d0
		lsl #1,d3
		add.l d0,d3
		add.l #31,d3
		andi.w #-32,d3				;End up with a base 32 aligned. This messes up programs like Scout
		move.l #sonnet_PosSize,d0		;PosSize
		move.l d0,d2
		add.w d3,d0
		move.l #MEMF_PPC|MEMF_REVERSE|MEMF_CLEAR,d1
		jsr _LVOAllocMem(a6)
		tst.l d0
		beq.s NoFun
		move.l d0,a3				;Base
		add.w d3,a3
		move.w d3,LIB_NEGSIZE(a3)
		move.w d2,LIB_POSSIZE(a3)
		move.l a3,a0
		move.l d4,a1
		moveq.l #0,d0
		move.l d0,d1
		moveq.l #49,d2				;Number of 68K functions

LoopFun		move.l (a1)+,d1
		cmp.l #-1,d1
		beq.s DoneFun

		tst.l d2
		bgt.s Fun68K

		add.l d6,d1
Fun68K		subq.l #1,d2
		move.l d1,-(a0)
		move.w #$4ef9,-(a0)
		bra.s LoopFun

DoneFun		jsr _LVOCacheClearU(a6)
		move.l a3,a2
		move.l d5,a1
		moveq.l #0,d0
		jsr _LVOInitStruct(a6)
		move.l a3,d0
NoFun		movem.l (a7)+,d1-a6
		rts

;********************************************************************************************

IntuitionLib	dc.b "intuition.library",0
DosLib		dc.b "dos.library",0
ExpLib		dc.b "expansion.library",0
pcilib		dc.b "pci.library",0
ppclib		dc.b "ppc.library",0
MemName		dc.b "Sonnet memory",0
PCIMem		dc.b "pcidma memory",0
IntName		dc.b "Gort",0
		cnop	0,4

;********************************************************************************************
;********************************************************************************************

MasterControl:
		move.l #"INIT",d6
		move.l SonnetBase(pc),a4
		move.l LExecBase(pc),a6
		jsr _LVOCreateMsgPort(a6)
		tst.l d0
		beq.s MasterControl
		move.l d0,MCPort(a4)
		move.l d6,Init(a4)			;Start phase 2 of PPC setup
		move.l d0,d6				;which moves it from fff00000 to 00000000
		jsr _LVOCacheClearU(a6)			;and sets up all the exception handlers

NextMsg		move.l d6,a0

		jsr _LVOWaitPort(a6)			;we wait for messages from our 68k interrupt
		
GetLoop		move.l d6,a0
		jsr _LVOGetMsg(a6)

		move.l d0,d7
		bne.s CheckMsg
		
		move.l d6,a0
		clr.l MP_MSGLIST+MLH_TAIL(a0)				;SoftCinema bug/quirk?
		bra.s NextMsg
							
CheckMsg	move.l d0,a1	
		move.b LN_TYPE(a1),d0
		cmp.b #NT_REPLYMSG,d0
		bne.s NoXReply
	
		move.l LN_NAME(a1),d0
		bne.s MsgRXMSG
		
		ILLEGAL
		
NoXReply	move.l MN_IDENTIFIER(a1),d0
		cmp.l #"T68K",d0			;Message to 68K
		beq MsgMir68
		cmp.l #"LL68",d0			;Low level message to 68K
		beq.s MsgLL68
		cmp.l #"FREE",d0			;Async FreeMem/FreeVec() call. Not implemented in ppcfunctions.p
		beq MsgFree
		cmp.l #"DBG!",d0			;Print debug info
		beq PrintDebug
		cmp.l #"DBG2",d0			;Print debug info
		beq PrintDebug2
		cmp.l #"CRSH",d0			;Print WarpOS like crash window
		beq Crashed
		bra.s GetLoop

		move.l a1,a0
		moveq.l #0,d1
		move.w MN_LENGTH(a2),d1
		moveq.l #CACHE_DCACHEFLUSH,d0
		bsr SetCache68K

;********************************************************************************************		

MsgRXMSG	move.l a1,a2
		move.l a1,a0
		moveq.l #0,d1
		move.w MN_LENGTH(a2),d1
		moveq.l #CACHE_DCACHEFLUSH,d0
		bsr SetCache68K

		bsr CreateMsgFrame			;To set up reply to XMSG =(RXMSG)
		move.l #"XMSG",MN_IDENTIFIER(a0)
		move.l a2,MN_ARG2(a0)
		move.w MN_LENGTH(a2),MN_ARG1(a0)
		move.l LN_NAME(a2),MN_REPLYPORT(a0)
		move.l LN_NAME(a2),MN_REPLYPORT(a2)

		bsr SendMsgFrame			;Send response from XMSG back to PPC
		bra GetLoop

;********************************************************************************************

MsgLL68		move.l MN_PPSTRUCT+0*4(a1),a6
		move.l MN_PPSTRUCT+1*4(a1),a0
		add.l a6,a0
		move.l a1,-(a7)
		pea RtnLL(pc)				;Execute 68K code
		move.l a0,-(a7)	
		move.l MN_PPSTRUCT+2*4(a1),a0
		move.l MN_PPSTRUCT+4*4(a1),d0
		move.l MN_PPSTRUCT+5*4(a1),d1
		move.l MN_PPSTRUCT+3*4(a1),a1
		rts

RtnLL		move.l LExecBase(pc),a6
		move.l (a7)+,a1
		move.l a1,d5
		bsr CreateMsgFrame			;Get message for reply
		
		move.l a0,d7
		move.l d0,MN_PPSTRUCT+6*4(a0)
		move.l #"DNLL",MN_IDENTIFIER(a0)
		move.l MN_PPC(a1),MN_PPC(a0)
		clr.l MN_ARG1(a0)		
		move.l MN_PPSTRUCT+0*4(a1),MN_PPSTRUCT+0*4(a0)
		move.l MN_PPSTRUCT+1*4(a1),MN_PPSTRUCT+1*4(a0)

		move.l d7,a1
		lea PushMsg(pc),a5			;Push to 68K data cache (needed?)
		jsr _LVOSupervisor(a6)

		move.l d7,a0
		bsr SendMsgFrame			;Send it to PPC

		move.l d5,a0
		bsr FreeMsgFrame			;Free original LL68 message

		bra GetLoop

;********************************************************************************************

MsgFree		move.l MN_PPSTRUCT+0*4(a1),a6		;Asynchronous FreeMem call from the PPC.
		move.l MN_PPSTRUCT+1*4(a1),a0
		add.l a6,a0
		move.l a1,-(a7)
		pea RtnFree(pc)
		move.l a0,-(a7)	
		move.l MN_PPSTRUCT+4*4(a1),d0
		move.l MN_PPSTRUCT+3*4(a1),a1
		rts

RtnFree		move.l LExecBase(pc),a6
		move.l (a7)+,a0
		bsr FreeMsgFrame
		bra GetLoop
		
;********************************************************************************************

PushMsg		moveq.l #11,d4				;Flush message from data cache
		move.l a1,a2
PshMsg		cpushl dc,(a2)				;040+
		lea L1_CACHE_LINE_SIZE_040(a2),a2	;Cache_Line 040/060 = 16 bytes
		dbf d4,PshMsg
		rte
		
;********************************************************************************************

MsgMir68	move.l a1,-(a7)				;Sets up a mirror task for an
		move.l MN_ARG0(a1),a0			;original PPC task 
		moveq.l #-1,d1
GetPPCName	addq.l #1,d1
		tst.b (a0)+
		bne.s GetPPCName
		
		move.l d1,d2
		subq.l #1,d2
		addq.l #5,d1
		sub.l d1,a7
		move.l a7,a2
		move.l MN_ARG0(a1),a0
CopyPPCName	move.b (a0)+,(a2)+
		dbf d2,CopyPPCName
		move.l #"_68K",(a2)+			;add _68K to PPC mirror task name
		clr.b (a2)
		move.l d1,d2
		
		move.l DosBase(pc),a6
		lea Prc2Tags(pc),a1
		move.l a7,12(a1)
		move.l a1,d1
		jsr _LVOCreateNewProc(a6)		;start the process
		
		add.l d2,a7
		move.l (a7)+,a1
		move.l LExecBase(pc),a6
		tst.l d0
		beq.s MsgMir68
		move.l d0,a0
		
		jsr _LVODisable(a6)
		move.l MN_ARG1(a1),TC_SIGALLOC(a0)	;set up the allocated signals
		jsr _LVOEnable(a6)
		
		lea pr_MsgPort(a0),a0
		jsr _LVOPutMsg(a6)
		bra GetLoop

;********************************************************************************************

PrintDebug2	lea DebugString2(pc),a0			;Print debug information send
		bra.s DebugEnd				;from PPC tasks
		
PrintDebug	lea DebugString(pc),a0
DebugEnd	move.l a1,a3
		lea MN_PPSTRUCT(a1),a1
		move.l _PowerPCBase(pc),a6
		bsr SPrintF68K
		move.l a3,a0
		bsr FreeMsgFrame
		move.l LExecBase(pc),a6
		bra GetLoop
		
;********************************************************************************************		
;********************************************************************************************

MirrorTask	move.l LExecBase(pc),a6			;Mirror task for PPC task
		move.l ThisTask(a6),a0			;set up by MsgMir68
		
		or.b #TF_PPC,TC_FLAGS(a0)
		lea pr_MsgPort(a0),a0
		move.l a0,d6
		jsr _LVOWaitPort(a6)

Error		jsr _LVOCreateMsgPort(a6)		;Make a seperate msgport to prevent
		tst.l d0				;DOS packet gurus
		beq.s Error
		move.l d0,-(a7)
		
CleanUp		move.l d6,a0
		jsr _LVOGetMsg(a6)			;Make sure the original msgport is empty
		tst.l d0
		beq.s GoWaitPort
		
		move.l d0,a1
		move.l (a7),a0
		jsr _LVOPutMsg(a6)
		bra.s CleanUp

GoWaitPort	move.l (a7),a0
		move.l ThisTask(a6),a1
		
		move.l TC_SIGALLOC(a1),d0		
		and.l #$fffff000,d0			;Do not act on system signals except the CTRL ones
		
		jsr _LVOWait(a6)
		
		move.l (a7),a0		
		move.b MP_SIGBIT(a0),d1
		moveq.l #0,d2
		bset d1,d2
		not.l d2
		move.l d0,d1
		and.l d2,d1
		beq.s GtLoop2

		bsr CrossSignals			;If other signals are detected than the
							;the one for the msgport, send it to ppc.
GtLoop2		move.l (a7),a0
		jsr _LVOGetMsg(a6)
		move.l d0,d7
		beq.s GoWaitPort

		move.l d7,a0
		move.l MN_IDENTIFIER(a0),d0
		cmp.l #"T68K",d0			;Mother PPC task has send a Run68K request
		beq.s DoRunk86
		cmp.l #"END!",d0			;Mother PPC task is shutting down
		bne.s GtLoop2

		bsr FreeMsgFrame

		move.l (a7)+,d0
		rts					;End task
		
DoRunk86	move.l (a7),MN_MIRROR(a0)

		bsr Runk86
		bra.s GtLoop2
		
;********************************************************************************************

		cnop 0,4

PrcTags		dc.l NP_Entry,MasterControl,NP_Name,PrcName,NP_Priority,4,NP_StackSize,$20000,TAG_END
PrcName		dc.b "MasterControl",0

		cnop 0,4
		
Prc2Tags	dc.l NP_Entry,MirrorTask,NP_Name,Prc2Name,NP_Priority,3,NP_StackSize,$20000,TAG_END
Prc2Name	dc.b "Joshua",0

		cnop 0,4

;********************************************************************************************
;********************************************************************************************


Crashed		movem.l d0-a6,-(a7)			;Prints message when PPC has crashed
		move.l a1,a0
		bsr FreeMsgFrame
		move.l DosBase(pc),a6
		lea ConWindow(pc),a0
		move.l a0,d1
		move.l #MODE_NEWFILE,d2
		jsr _LVOOpen(a6)
		move.l d0,d1
		beq.s VeryBad
		
		lea CrashMessage(pc),a0
		move.l a0,d2		
		move.l SonnetBase(pc),a0
		move.l a0,d3
		add.l #$2100,d3
		jsr _LVOVFPrintf(a6)
		
VeryBad		movem.l (a7)+,d0-a6
		bra NextMsg

;********************************************************************************************

SonInt:		movem.l d1-a6,-(a7)			;68K interrupt which distributes
		move.l LExecBase(pc),a6			;messages send by the PPC
		move.l EUMBAddr(pc),a2
		move.l OMISR(a2),d3
		move.l #$20000000,d4			;OMISR[OPQI]
		and.l d4,d3
		beq DidNotInt

		bsr GetMsgFrame
		move.l a1,d3
		cmp.l #-1,d3
		beq DidNotInt

IntMsgLoop	moveq.l #11,d4
;		bsr.s InvMsg				;PCI memory is cache inhibited for 68k
		move.l d3,a1
		
		move.l MN_IDENTIFIER(a1),d0
		cmp.l #"T68K",d0
		beq MsgT68k
		cmp.l #"END!",d0
		beq MsgT68k
		cmp.l #"FPPC",d0
		beq MsgFPPC
		cmp.l #"XMSG",d0
		beq MsgXMSG
		cmp.l #"SIG!",d0
		beq MsgSignal68k
		cmp.l #"RX68",d0
		beq MsgRetX
		cmp.l #"GETV",d0
		beq LoadD
		and.l #$ffffff00,d0
		cmp.l #$50555400,d0
		beq.s StoreD		
		
CommandMaster	move.l d3,a1
		move.l MN_MCPORT(a1),a0
DoPutMsg	jsr _LVOPutMsg(a6)

NxtMsg		bsr GetMsgFrame
		move.l a1,d3
		cmp.l #-1,d3
		beq.s DidInt
		bra.s IntMsgLoop

DidInt		movem.l (a7)+,d1-a6
		moveq.l #-1,d0				;Clear Z flag if server handled interrupt
		rts

InvMsg		cinvl dc,(a1)				;040+
		lea L1_CACHE_LINE_SIZE_040(a1),a1	;Cache_Line 040/060 = 16 bytes
		dbf d4,InvMsg				;12x16 = MsgLen (192 bytes)
		rts

IntData		dc.l 0

DidNotInt	movem.l (a7)+,d1-a6
		moveq.l #0,d0				;Set Z flag if we did not handle interrupt
		rts

;********************************************************************************************

StoreD		move.l MN_IDENTIFIER(a1),d7		;Handles indirect access from PPC
		move.l MN_IDENTIFIER+4(a1),d0		;to Amiga Memory
		move.l MN_IDENTIFIER+8(a1),a0

		cmp.l #"PUTB",d7
		beq.s PutB
		cmp.l #"PUTH",d7
		beq.s PutH
		cmp.l #"PUTW",d7
		bne NxtMsg
		move.l d0,(a0)
Putted		move.l #"DONE",d7
		move.l d7,MN_IDENTIFIER(a1)
		move.l a1,a0
		bsr FreeMsgFrame

		bra NxtMsg

PutB		move.b d0,(a0)
		bra.s Putted

PutH		move.w d0,(a0)
		bra.s Putted

LoadD		move.l #"DONE",d0
		move.l MN_IDENTIFIER+8(a1),a3

		move.l (a3),MN_IDENTIFIER+4(a1)
		move.l d0,MN_IDENTIFIER(a1)
		move.l a1,a0
		bsr FreeMsgFrame

		bra NxtMsg

;********************************************************************************************		
		
MsgT68k		move.l MN_MIRROR(a1),a0			;Handles messages to 68K (mirror)tasks
		move.l a0,d1
		beq CommandMaster
		cmp.l #"END!",d0
		beq DoPutMsg

		move.l d1,a2
		move.l MP_SIGTASK(a2),a2
		move.l MN_ARG1(a1),TC_SIGALLOC(a2)
		move.l MN_ARG2(a1),d0
		or.l d0,TC_SIGRECVD(a2)				
		bra DoPutMsg

;********************************************************************************************

MsgFPPC		move.l MN_ARG1(a1),d0
		move.l MN_REPLYPORT(a1),a2
		move.l MP_SIGTASK(a2),a2
		move.l d0,TC_SIGALLOC(a2)
		jsr _LVOReplyMsg(a6)			;Ends the RunPPC function
		bra NxtMsg
		
;********************************************************************************************		

MsgXMSG		move.l a1,a2				;Cross message from PPC to 68k
		move.l MN_ARG2(a2),a0
		moveq.l #0,d1
		move.w MN_ARG1(a2),d1
		moveq.l #CACHE_DCACHEINV,d0
		bsr SetCache68K

		move.l MN_PPC(a2),d7			
		move.l a2,a0
		move.l MN_ARG2(a2),a1
		move.l MN_REPLYPORT(a1),LN_NAME(a1)
		move.l MN_MCPORT(a2),MN_REPLYPORT(a1)	;Set MasterControl as replyport
		bsr FreeMsgFrame
		
		move.l d7,a0
		bra DoPutMsg
		
;********************************************************************************************

MsgRetX		move.l a1,a2
		move.l MN_ARG2(a2),a0			;Reply on cross message to PPC
		moveq.l #0,d1
		move.w MN_ARG1(a2),d1		
		moveq.l #CACHE_DCACHEINV,d0
		bsr SetCache68K

		move.l MN_ARG2(a2),a1
		move.l a2,a0
		move.l MN_REPLYPORT(a1),d7
		bsr FreeMsgFrame
		
		move.l d7,a0
		bra DoPutMsg

;********************************************************************************************		

MsgSignal68k	move.l MN_PPSTRUCT+4(a1),d0		;Signal from a PPC task to 68K task
		move.l a1,d7
		move.l MN_PPSTRUCT(a1),a1
		jsr _LVOSignal(a6)
		move.l d7,a0
		bsr FreeMsgFrame
		bra NxtMsg
		
;********************************************************************************************
;********************************************************************************************

WarpOpen:
		move.l a6,d0				;Dummy Open() for warp.library
		tst.l d0
		beq.s NoA6
		move.l LExecBase(pc),a6
		move.l ThisTask(a6),a6
		or.b #TF_PPC,TC_FLAGS(a6)
		move.l d0,a6
		addq.w #1,LIB_OPENCNT(a6)
		bclr #LIBB_DELEXP,LIB_FLAGS(a6)
		rts

;********************************************************************************************

WarpClose:
		moveq.l #0,d0				;Dummy Close() for warp.library
		subq.w #1,LIB_OPENCNT(a6)
		bra.s NoExp

;********************************************************************************************
;********************************************************************************************

Open:
		move.l a6,d0				;Standard LibOpen() routine
		tst.l d0
		beq.s NoA6
		move.l LExecBase(pc),a6
		move.l ThisTask(a6),a6
		or.b #TF_PPC,TC_FLAGS(a6)
		
;		movem.l d0-a6,-(a7)
;		move.l LN_NAME(a6),a1
;		cmp.l #"raml",(a1)
;		beq.s DontDoRamLib
;		move.l LExecBase(pc),a6
;		jsr _LVODisable(a6)
;		move.l #MEMF_PUBLIC|MEMF_PPC|MEMF_REVERSE,d1
;		moveq.l #0,d2
;		moveq.l #1,d3
;		bsr ChangeStack68K
;		jsr _LVOEnable(a6)
;DontDoRamLib	movem.l (a7)+,d0-a6

		move.l d0,a6
		move.l a1,-(a7)
		lea _PowerPCBase(pc),a1
		move.l a6,(a1)
		move.l (a7)+,a1
		addq.w #1,LIB_OPENCNT(a6)
		bclr #LIBB_DELEXP,LIB_FLAGS(a6)
NoA6		rts

;********************************************************************************************

Close:
		moveq.l #0,d0
		subq.w #1,LIB_OPENCNT(a6)
		bne.s NoExp
		btst #LIBB_DELEXP,LIB_FLAGS(a6)
		bne.s Expunge
NoExp		rts

;********************************************************************************************

Expunge:
		tst.w LIB_OPENCNT(a6)
;		beq.s NotOpen
		nop					;DEBUG Library should not be expunged due to fake powerpc stuff
		bset #LIBB_DELEXP,LIB_FLAGS(a6)
		moveq.l #0,d0
		rts

NotOpen		movem.l d2/a5/a6,-(a7)
		move.l a6,a5
		move.l LExecBase(pc),a6
		move.l a5,a1
		jsr _LVORemove(a6)
		moveq.l #0,d0
		move.l a5,a1
		move.w LIB_NEGSIZE(a5),d0
		sub.l d0,a1
		add.w LIB_POSSIZE(a5),d0
		jsr _LVOFreeMem(a6)
		move.l PPCCodeMem(pc),a1
		jsr _LVOFreeVec(a6)
		move.l SegList(pc),d0
		movem.l (a7)+,d2/a5/a6
		rts

;********************************************************************************************

Reserved:
		moveq.l #0,d0
		rts

;********************************************************************************************
;
;	CPUType = GetCPU(void) // d0
;
;********************************************************************************************

GetCPU:
		movem.l d1-a6,-(a7)			;As we only have G3 and G4 on a sonnet
		
		moveq.l #HW_CPUTYPE,d1			;only those are returned (no 603/604 etc)			
		
		RUNPOWERPC	_PowerPCBase,SetHardware
		
		and.w #$0,d0
		swap d0
		subq.l #8,d0
		beq.s G3
		subq.l #4,d0
		beq.s G4
		moveq.l #0,d0
		bra.s ExCPU
G3		move.l #CPUF_G3,d0
		bra.s ExCPU
G4		move.l #CPUF_G4,d0
ExCPU		movem.l (a7)+,d1-a6
		rts

;********************************************************************************************
;
;	MessageFrame = CreateMsgFrame(void) // a0
;
;********************************************************************************************

CreateMsgFrame:						;Fetch a free 192 bytes long message
		movem.l a1/a2,-(a7)
TooFast4U	move.l EUMBAddr(pc),a2
		move.l IFQPR(a2),a0
		lea Previous(pc),a2
		move.l (a2),a1
		cmp.l a1,a0
		beq.s TooFast4U				;To prevent duplicates (Is there a better way?)
		move.l a0,(a2)
		movem.l (a7)+,a1/a2
		rts

;********************************************************************************************
;
;	void SendMsgFrame(MessageFrame)) // a0
;
;********************************************************************************************

SendMsgFrame:
		move.l a2,-(a7)				;Send the message to the PPC
		move.l EUMBAddr(pc),a2
		move.l a0,IFQPR(a2)		
		move.l (a7)+,a2
		rts

;********************************************************************************************
;
;	void FreeMsgFrame(MessageFrame) // a0
;
;********************************************************************************************
		
FreeMsgFrame:
		move.l a2,-(a7)				;Return a PPC message to the free
		move.l EUMBAddr(pc),a2			;messages pool
		move.l a0,OFQPR(a2)		
		move.l (a7)+,a2
		rts
		
;********************************************************************************************
;
;	MessageFrame = GetMsgFrame(void) // a1
;
;********************************************************************************************

GetMsgFrame:
		move.l a2,-(a7)				;Get next message send from the PPC
		move.l EUMBAddr(pc),a2			;if available
		move.l OFQPR(a2),a1		
		move.l (a7)+,a2
		rts

;********************************************************************************************
;
;		System Patches
;
;********************************************************************************************
;********************************************************************************************
;
;		RemTask() Patch
;
;********************************************************************************************

ExitCode	movem.l d0-a6,-(a7)			;called when an 68K task is removed
		move.l LExecBase(pc),a6
		bsr.s CommonCode
		movem.l (a7)+,d0-a6
		move.l RemTaskAddress(pc),-(a7)
		rts

ExitCode2	movem.l d0-a6,-(a7)
		move.l LExecBase(pc),a6
		bsr.s Common2
		movem.l (a7)+,d0-a6
		move.l RemSysTask(pc),-(a7)
		rts

CommonCode	move.l a1,d1
		bne.s NotSelf

Common2		move.l ThisTask(a6),d1
		move.l d1,a1
NotSelf		cmp.b #NT_PROCESS,LN_TYPE(a1)
		bne.s DoneMList
		
CorrectType	lea MirrorList(pc),a2
		move.l MLH_HEAD(a2),a2
NextMList	tst.l LN_SUCC(a2)
		beq.s DoneMList
		cmp.l MT_TASK(a2),d1
		beq.s KillPPC
		move.l LN_SUCC(a2),a2
		bra.s NextMList

KillPPC		bsr CreateMsgFrame
		move.l #"END!",MN_IDENTIFIER(a0)
		move.l MT_MIRROR(a2),MN_PPC(a0)
		bsr SendMsgFrame			;kill off the PPC mirror task

		jsr _LVODisable(a6)

		move.l a2,a1
		jsr _LVORemove(a6)

		jsr _LVOEnable(a6)

		move.l MT_PORT(a2),a0
		jsr _LVODeleteMsgPort(a6)		;Free the 68K task msg port

		move.l a2,a1
		jsr _LVOFreeVec(a6)			;Free the original task structure

DoneMList	rts
		
;********************************************************************************************
;
;		Addtask() Patch
;
;********************************************************************************************

StartCode	movem.l d0/a1,-(a7)			;Change exit code of 68K task to point
		cmp.b #NT_PROCESS,LN_TYPE(a1)		;to our own exit code
		bne.s ExitTrue
		move.l a3,d0
		beq.s DoPatch		
		and.l #$ff000000,d0
		bne.s ExitTrue
		lea RemSysTask(pc),a1
		move.l a3,(a1)
		lea ExitCode2(pc),a3
		bra.s ExitTrue

DoPatch		lea ExitCode(pc),a3
ExitTrue	movem.l (a7)+,d0/a1
		move.l AddTaskAddress(pc),-(a7)
		rts
		
;********************************************************************************************
;
;		OpenLibrary() Patch
;
;********************************************************************************************

OpenCode	lea -8(a7),a7				;check a list of libraries
		movem.l d0-a6,-(a7)			;to see where to put the lib base
		move.l a1,d3				;either in normal or MEMF_PPC memory
		lea ramlib(pc),a1
		jsr _LVOFindTask(a6)
		move.l d3,a1
		move.l d0,d3
		beq.s NoRamLib1
		move.l d0,64(a7)
		move.l d0,a4
		move.b TC_FLAGS(a4),d3
NoRamLib1	move.l d3,60(a7)
		moveq.l #0,d4
		move.l d4,d1
		move.l d4,d2
		lea WhiteList(pc),a2
		or.b #TF_PPC,d3
NextBWList	move.b (a2)+,d1
NextWhite	move.b (a2)+,d2
		move.l a2,a3
		add.l d2,a3
		move.l (a2),d5
		cmp.l (a1),d5
		bne.s DoNextW
		move.l 4(a2),d5
		cmp.l 4(a1),d5
		beq.s SetFlag
		
DoNextW		move.l a3,a2
		dbf d1,NextWhite
		tst.l d4
		beq.s DoBlack
		bra.s NoChange

SetFlag		move.l a4,d0
		beq.s NoChange
		move.b d3,TC_FLAGS(a4)
NoChange	movem.l (a7)+,d0-a6
		pea OpenLibReturn(pc)
		move.l OpenLibAddress(pc),-(a7)
		rts
		
DoBlack		move.l d4,d1
		move.l d4,d2
		moveq.l #-1,d4
		lea BlackList(pc),a2
		and.b #~TF_PPC,d3
		bra.s NextBWList

OpenLibReturn	movem.l d1/a4,-(a7)
		move.l 12(a7),d1
		beq.s NoRamLib2
		move.l d1,a4
		move.l 8(a7),d1
		move.b d1,TC_FLAGS(a4)
NoRamLib2	movem.l (a7)+,d1/a4
		lea 8(a7),a7
		rts

;********************************************************************************************
;
;		AllocMem() Patch
;
;********************************************************************************************

NewAlloc	cmp.l #$f4248,d0				;HARDCODED FreeSpace PATCH!!
		beq NoFast

		tst.w d1					;Patch code - Test for attribute $0000 (Any)
		beq.s Best
		btst #2,d1					;If FAST requested, redirect
		bne.s Best					
		btst #0,d1					;If not PUBLIC requested, exit
		beq NoFast
		btst #1,d1					;If CHIP requested, exit
		bne NoFast
		nop						;Let everything else through..?		
		
Best		move.l d7,-(a7)
		move.l a3,-(a7)
		move.l a2,-(a7)
		move.l ThisTask(a6),a3
		move.b TC_FLAGS(a3),d7
		btst #2,d7					;Check if task was tagged by sonnet.library
		bne.s DoBit					;If yes, then redirect to PPC memory
		cmp.b #NT_PROCESS,LN_TYPE(a3)			;Is it a DOS process?
		bne.s IsTask
		move.l pr_CLI(a3),d7				;Was this task started by CLI?
		bne.s IsHell					;If yes, go there
		
IsTask		move.l LN_NAME(a3),d7				;Has the task a name?
		beq.s NoBit					;If no then exit
		move.l d7,a2
		cmp.l #"ahi.",(a2)
		beq DoBit

FindEnd		move.b (a2)+,d7
		bne.s FindEnd
		move.l -5(a2),d7
		cmp.l #"2005",d7				;Task has name with 2005 at end?
		beq.s DoBit					;if yes, then redirect to PPC memory
		cmp.l #"_68K",d7
		beq.s DoBit
		cmp.l #"_PPC",d7
		beq.s DoBit
		cmp.l #"sk_0",d7
		beq.s DoBit
		cmp.l #"sk_1",d7
		beq.s DoBit
		cmp.l #"trol",d7
		beq.s DoBit
		bra.s NoBit

IsHell		lsl.l #2,d7
		move.l d7,a3
		move.l cli_CommandName(a3),d7			;Get name of task started by CLI
		beq.s NoBit
		lsl.l #2,d7
		move.l d7,a3
		clr.l d7
		move.b (a3),d7
		subq.l #4,d7
		bmi.s NoBit
		move.l 1(a3,d7.l),d7
		cmp.l #"2005",d7				;Check if CLI or Shell CommandName ends with 2005
		beq.s DoBit					;If yes, then redirect to PPC memory
		bra.s NoBit	

DoBit		bset #13,d1					;Set attribute MEMF_PPC
		bset #18,d1					;MEMF_REVERSE
NoBit		move.l (a7)+,a2
		move.l (a7)+,a3
		move.l (a7)+,d7
NoFast		move.l AllocMemAddress(pc),-(a7)
		rts
		
;********************************************************************************************
;
;		LoadSeg() Patch
;
;********************************************************************************************

NewOldLoadSeg	move.l LoadSegAddress(pc),-(a7)
		rts

;********************************************************************************************
;
;		NewLoadSeg() Patch
;
;********************************************************************************************

NewNewLoadSeg	move.l NewLoadSegAddress(pc),-(a7)
		rts
;*********************************************************************************************
;
;	status = RunPPC(PPStruct) // d0=a0
;
;********************************************************************************************

MN_STARTALLOC	EQU LN_NAME
MN_IDENTIFIER	EQU MN_SIZE
MN_MIRROR	EQU MN_IDENTIFIER+4
MN_PPC		EQU MN_MIRROR+4
MN_PPSTRUCT	EQU MN_PPC+4
MT_TASK		EQU MLN_SIZE
MT_MIRROR	EQU MT_TASK+4
MT_PORT		EQU MT_MIRROR+4
MT_FLAGS	EQU MT_PORT+4
MT_SIZE		EQU MT_FLAGS+4


PStruct		EQU -4
Port		EQU -8
MirrorNode	EQU -12

RunPPC:		link a5,#-12
		movem.l d1-a6,-(a7)
		moveq.l #0,d0		
		move.l d0,Port(a5)
		move.l a0,PStruct(a5)
		move.l LExecBase(pc),a6
		move.l ThisTask(a6),a1
		cmp.b #NT_PROCESS,LN_TYPE(a1)
		beq.s IsProc

		moveq.l #PPERR_MISCERR,d7		;Only DOS processes supported
		bra EndIt

IsProc		move.l ThisTask(a6),d6			;See if we already have a PPC mirrortask
		lea MirrorList(pc),a2
		move.l MLH_HEAD(a2),a2
NextMirList	tst.l LN_SUCC(a2)
		beq.s DoneMirList
		move.l MT_MIRROR(a2),d5
		move.l MT_PORT(a2),Port(a5)
		move.l a2,MirrorNode(a5)
		cmp.l MT_TASK(a2),d6
		beq PPCRunning				
		move.l LN_SUCC(a2),a2
		bra.s NextMirList

PPCRunning	tst.l MT_FLAGS(a2)
		beq NoASyncErr
		bra.s GiveASyncErr

DoneMirList	jsr _LVOCreateMsgPort(a6)
		tst.l d0
		bne.s GotMsgPort
		
GiveASyncErr	moveq.l #PPERR_MISCERR,d7
		bra EndIt

GotMsgPort	move.l d0,Port(a5)
		move.l #MEMF_PUBLIC|MEMF_REVERSE|MEMF_CLEAR,d1
		moveq.l #MT_SIZE,d0
		jsr _LVOAllocVec(a6)
		tst.l d0
		beq GtLoop
		move.l d0,a1
		move.l ThisTask(a6),MT_TASK(a1)
		move.l Port(a5),MT_PORT(a1)
		moveq.l #0,d5
		move.l d5,MT_FLAGS(a1)
		
		jsr _LVODisable(a6)
		
		move.l a1,MirrorNode(a5)
		lea MirrorList(pc),a0
		jsr _LVOAddHead(a6)

		jsr _LVOEnable(a6)

		move.l ThisTask(a6),a1
		move.l TC_SPUPPER(a1),d0
		move.l TC_SPLOWER(a1),d1
		sub.l d1,d0
		lsl.l #1,d0				;Double the 68K stack
		or.l #$80000,d0				;Set stack at least at 512k
		move.l d0,d7
		add.l #2048,d0

		move.l _PowerPCBase(pc),a6
		move.l #MEMF_PUBLIC|MEMF_PPC|MEMF_REVERSE,d1
		jsr _LVOAllocVec32(a6)
		move.l d0,d6
		beq Stacker

		move.l LExecBase(pc),a6
		move.l ThisTask(a6),a1
		move.l d6,a2
		move.l #511,d0
ClearTaskMem	clr.l (a2)+
		dbf d0,ClearTaskMem
		
		move.l d6,a2
		lea TASKPPC_TASKPOOLS(a2),a2
		move.l a2,d0
		move.l d0,8(a2)
		addq.l #4,d0
		move.l d0,(a2)
		moveq.l #0,d0
		move.l d0,4(a2)		
		move.l d6,a2
		lea TASKPPC_NAME(a2),a2	
		cmp.b #NT_PROCESS,LN_TYPE(a1)
		beq.s CheckCLI
		
NoCLI		move.l LN_NAME(a1),a1
		bra.s DoNameCp
		
CheckCLI	move.l pr_CLI(a1),d0
		beq.s NoCLI
		lsl.l #2,d0
		move.l d0,a1
		move.l cli_CommandName(a1),d0
		bne.s GetCLIName
		move.l ThisTask(a6),a1
		bra.s NoCLI
		
GetCLIName	lsl.l #2,d0
		addq.l #1,d0
		move.l d0,a1
		moveq.l #0,d0
		move.b -1(a1),d0
		bra.s CpName

DoNameCp	move.l #(2043-TASKPPC_NAME),d0		;Name len limit		
CpName		move.b (a1)+,(a2)
		tst.b (a2)
		beq.s EndName
		addq.l #1,a2
		dbf d0,CpName

EndName		move.l #"_PPC",(a2)			;Check Alignment?
		move.b #0,4(a2)
							;Also push dcache
NoASyncErr	bsr CreateMsgFrame

		moveq.l #MSG_LEN/4-1,d0
		move.l a0,a2
ClrMsg		clr.l (a2)+
		dbf d0,ClrMsg

		move.w #192,MN_LENGTH(a0)
		move.l #"TPPC",MN_IDENTIFIER(a0)
		move.b #NT_MESSAGE,LN_TYPE(a0)
		move.l Port(a5),d1
		move.l d1,MN_REPLYPORT(a0)
		move.l d1,MN_MIRROR(a0)
		move.l d6,MN_ARG0(a0)			;Mem
		move.l d5,MN_PPC(a0)
		move.l ThisTask(a6),a2
		
		move.l TC_SIGALLOC(a2),d0
		tst.l d5
		bne OldPPCTask
		
		move.l d0,MN_STARTALLOC(a0)
		bra SetSigAlloc
		
OldPPCTask	move.l d0,d7
SetSigAlloc	move.l d7,MN_ARG1(a0)
		move.l a2,MN_ARG2(a0)		
		move.l PStruct(a5),a1

		move.l a1,a3
		tst.l PP_STACKPTR(a1)
		beq.s SetupCp

		move.l PP_STACKSIZE(a1),d0
		bne DoStack
		
		moveq.l #0,d0
		move.l d0,PP_STACKPTR(a1)
		bra SetupCp

DoStack		move.l PP_FLAGS(a1),d2			;Passing stack through a message frame
		btst #PPB_ASYNC,d2			;Docs say don't do it while async
		bne StackErr

		move.l a0,a4
		move.l #MEMF_PUBLIC|MEMF_PPC|MEMF_REVERSE,d1
		move.l _PowerPCBase(pc),a6
		jsr _LVOAllocVec32(a6)
		
		tst.l d0
		beq StackErr
		
		move.l PP_STACKPTR(a3),a0
		move.l d0,a1
		move.l d0,PP_STACKPTR(a3)
		move.l PP_STACKSIZE(a3),d0
		move.l LExecBase(pc),a6
		jsr _LVOCopyMem(a6)
		
		move.l #CACHE_DCACHEFLUSH,d0
		move.l PP_STACKPTR(a3),a0
		move.l PP_STACKSIZE(a3),d1
		bsr SetCache68K

		move.l a4,a0
		bra SetupCp
		
StackErr	lea StackRunError(pc),a2
		bra PrintError

SetupCp		move.l a3,a1
		lea MN_PPSTRUCT(a0),a2
		moveq.l #PP_SIZE/4-1,d0

CpMsg2		move.l (a3)+,(a2)+
		dbf d0,CpMsg2

		bsr SendMsgFrame
		
		move.l PP_FLAGS(a1),d1			;Asynchronous RunPPC Call
		btst.l #PPB_ASYNC,d1
		beq Stacker
		
		move.l MirrorNode(a5),a3
		move.l d1,MT_FLAGS(a3)
		moveq.l #PPERR_SUCCESS,d7
		bra EndIt

;********************************************************************************************
;
;	status = WaitForPPC(PPStruct) // d0=a0
;
;********************************************************************************************

WaitForPPC:	link a5,#-12
		movem.l d1-a6,-(a7)
		move.l a0,PStruct(a5)

		move.l LExecBase(pc),a6
		move.l ThisTask(a6),d6
		lea MirrorList(pc),a2
		move.l MLH_HEAD(a2),a2
NextMirList2	tst.l LN_SUCC(a2)
		beq.s WaitForPPCErr
		move.l MT_MIRROR(a2),d5
		move.l MT_PORT(a2),Port(a5)
		move.l a2,MirrorNode(a5)
		cmp.l MT_TASK(a2),d6
		beq NowCheckFlag
		move.l LN_SUCC(a2),a2
		bra.s NextMirList2

NowCheckFlag	tst.l MT_FLAGS(a2)
		bne.s DidAsync
		
WaitForPPCErr	moveq.l #PPERR_WAITERR,d7
		bra EndIt

DidAsync	moveq.l #0,d0
		move.l d0,MT_FLAGS(a2)

Stacker		move.l ThisTask(a6),a1

		move.l TC_SIGALLOC(a1),d0		
		and.l #$fffff000,d0
		
		jsr _LVOWait(a6)

		move.l Port(a5),a0		
		move.b MP_SIGBIT(a0),d1
		moveq.l #0,d2
		bset d1,d2
		not.l d2
		move.l d0,d1
		and.l d2,d1
		beq.s GtLoop

		bsr CrossSignals

GtLoop		move.l Port(a5),a0
		jsr _LVOGetMsg(a6)
		
		tst.l d0
		beq.s Stacker

		move.l d0,a0
		move.l MN_IDENTIFIER(a0),d0
		cmp.l #"FPPC",d0
		beq.s DizDone
		cmp.l #"T68K",d0
		bne.s GtLoop
		bsr.s Runk862
		bra.s GtLoop

DizDone		move.l a0,a2
		move.l MirrorNode(a5),a1
		move.l MN_PPC(a2),MT_MIRROR(a1)		
		move.l PStruct(a5),a1
		move.l PP_STACKPTR(a1),d0
		beq NoFrStackPtr

		move.l a1,-(a7)
		move.l d0,a1
		bsr FreeVec32
		move.l (a7)+,a1

NoFrStackPtr	lea PP_REGS(a1),a1
		lea MN_PPSTRUCT+PP_REGS(a2),a2
		moveq.l #(PP_SIZE-PP_REGS)/4-1,d0
CpBck		move.l (a2)+,(a1)+
		dbf d0,CpBck
		moveq.l #PPERR_SUCCESS,d7
		bsr FreeMsgFrame

		bra.s Success

Cannot		moveq.l #-1,d7
Success		move.l LExecBase(pc),a6
EndIt		move.l d7,d0
		movem.l (a7)+,d1-a6
		unlk a5
		rts

Runk862		move.l MirrorNode(a5),a1
		move.l MN_PPC(a0),MT_MIRROR(a1)
Runk86		btst #AFB_FPU40,AttnFlags+1(a6)
		beq.s NoFPU
		fmove.d fp0,-(a7)
		fmove.d fp1,-(a7)
		fmove.d fp2,-(a7)
		fmove.d fp3,-(a7)
		fmove.d fp4,-(a7)
		fmove.d fp5,-(a7)
		fmove.d fp6,-(a7)
		fmove.d fp7,-(a7)
		
NoFPU		movem.l d0-a6,-(a7)			;68k routines called from PPC
		move.l a0,-(a7)
		lea MN_PPSTRUCT(a0),a1
		btst #AFB_FPU40,AttnFlags+1(a6)
		beq.s NoFPU3
		lea PP_FREGS(a1),a6
		fmove.d (a6)+,fp0
		fmove.d (a6)+,fp1
		fmove.d (a6)+,fp2
		fmove.d (a6)+,fp3
		fmove.d (a6)+,fp4
		fmove.d (a6)+,fp5
		fmove.d (a6)+,fp6
		fmove.d (a6)+,fp7
NoFPU3		move.l a1,a5
		move.l PP_STACKPTR(a1),d0
		beq NoStckPtr

		move.l d0,a0
		move.l PP_STACKSIZE(a1),d1
		beq NoStckPtr

		moveq.l #CACHE_DCACHEINV,d0
		bsr SetCache68K

		move.l PP_STACKPTR(a5),a0
		move.l PP_STACKSIZE(a5),d0
		move.l a7,a1
;		sub.l d0,a1

		cmp.l #512,d0				;DEBUG
		ble StackLimit				;DEBUG
		ILLEGAL					;DEBUG

StackLimit	lea -512(a1),a1				;Stack overflow?
		move.l a1,a7
		move.l LExecBase(pc),a6
		jsr _LVOCopyMem(a6)
		pea xBack2(pc)
		bra StckPtr

NoStckPtr	pea xBack(pc)
StckPtr		move.l PP_CODE(a5),a0
		add.l PP_OFFSET(a5),a0
		move.l a0,-(a7)
		lea PP_REGS(a5),a6
		movem.l (a6)+,d0-a5
		move.l (a6),a6
		rts
		
xBack2		lea 512(a7),a7
xBack		move.l a6,-(a7)				;Restore correct stack?
		move.l 4(a7),a6
		lea MN_PPSTRUCT+PP_REGS(a6),a6
		move.l d0,(a6)+
		move.l d1,(a6)+
		move.l d2,(a6)+
		move.l d3,(a6)+
		move.l d4,(a6)+
		move.l d5,(a6)+
		move.l d6,(a6)+
		move.l d7,(a6)+
		move.l a0,(a6)+
		move.l a1,(a6)+
		move.l a2,(a6)+
		move.l a3,(a6)+
		move.l a4,(a6)+
		move.l a5,(a6)+
		move.l a6,a0
		move.l (a7)+,a6
		move.l a6,(a0)
		move.l LExecBase(pc),a6
		btst #AFB_FPU40,AttnFlags+1(a6)
		beq.s NoFPU4
		move.l (a7),a6
		lea MN_PPSTRUCT+PP_FREGS(a6),a6
		fmove.d fp0,(a6)+
		fmove.d fp1,(a6)+
		fmove.d fp2,(a6)+
		fmove.d fp3,(a6)+
		fmove.d fp4,(a6)+
		fmove.d fp5,(a6)+
		fmove.d fp6,(a6)+
		fmove.d fp7,(a6)+

NoFPU4		move.l LExecBase(pc),a6
		move.l (a7),a1
		bsr CreateMsgFrame
		
		move.l a0,a3
		moveq.l #MSG_LEN/4-1,d1
DoReslt		move.l (a1)+,(a3)+
		dbf d1,DoReslt
		
		move.l #"DONE",MN_IDENTIFIER(a0)
		move.l ThisTask(a6),a1
		move.l a1,MN_ARG2(a0)
		move.l TC_SIGALLOC(a1),MN_ARG1(a0)
		move.l a0,d7
		move.l a0,a1
		lea PushMsg(pc),a5
		jsr _LVOSupervisor(a6)
		
		move.l d7,a0
		bsr SendMsgFrame
		
		move.l (a7),a0
		bsr FreeMsgFrame

		move.l (a7)+,a6
		movem.l (a7)+,d0-a5
		move.l a6,a1
		move.l (a7)+,a6
		btst #AFB_FPU40,AttnFlags+1(a6)
		beq.s NoFPU2
		fmove.d (a7)+,fp7
		fmove.d (a7)+,fp6
		fmove.d (a7)+,fp5
		fmove.d (a7)+,fp4
		fmove.d (a7)+,fp3
		fmove.d (a7)+,fp2
		fmove.d (a7)+,fp1
		fmove.d (a7)+,fp0
NoFPU2		rts

CrossSignals	bsr CreateMsgFrame

		moveq.l #MSG_LEN/4-1,d1
		move.l a0,a2
ClearMsg	clr.l (a2)+
		dbf d1,ClearMsg

		move.l #"LLPP",MN_IDENTIFIER(a0)
		move.l d0,MN_ARG0(a0)
		move.l ThisTask(a6),a3
		move.l a3,MN_ARG1(a0)
		
		bsr SendMsgFrame
		
		rts

;********************************************************************************************
;
;	PPCState = GetPCState(void) // d0		THIS NEEDS AN OVERHAUL!!
;
;********************************************************************************************

GetPPCState:	movem.l d1-a6,-(a7)

		moveq.l #HW_PPCSTATE,d1

		RUNPOWERPC	_PowerPCBase,SetHardware

		movem.l (a7)+,d1-a6
		rts

;********************************************************************************************
;
;	TaskPPC = CreatePPCTask(TagItems) // d0 = a0
;
;********************************************************************************************

CreatePPCTask:	movem.l d1-a6,-(a7)

		move.l a0,d1						;d1 = r4

		RUNPOWERPC	_PowerPCBase,CreateTaskPPC

		movem.l (a7)+,d1-a6
		rts

;********************************************************************************************
;
;	memblock = AllocVec32(memsize) // d0 = d0 (d1 is fixed)
;
;********************************************************************************************

AllocVec32:
		move.l a6,-(a7)
		add.l #$38,d0
		move.l LExecBase(pc),a6
		and.l #MEMF_CLEAR,d1
		or.l #MEMF_PUBLIC|MEMF_PPC|MEMF_REVERSE,d1		;attributes are FIXED to Sonnet mem
		jsr _LVOAllocVec(a6)
		move.l d0,d1
		beq.s MemErr
		add.l #$27,d0
		and.l #$ffffffe0,d0
		move.l d0,a0
		move.l d1,-4(a0)
MemErr		move.l (a7)+,a6
		rts

;********************************************************************************************
;
;	void FreeVec32(memblock) // a1
;
;********************************************************************************************

FreeVec32:
		move.l a6,-(a7)
		move.l a1,d0
		beq NoMemAddr
		move.l -4(a1),a1
		move.l LExecBase(pc),a6
		jsr _LVOFreeVec(a6)
NoMemAddr	move.l (a7)+,a6
		rts

;********************************************************************************************
;
;	message = AllocXMsg(bodysize, replyport) // d0=d0,a0
;
;********************************************************************************************

AllocXMsg:			
		movem.l d1-a6,-(a7)
		add.l #MN_SIZE+31,d0
		and.l #-32,d0
		move.l d0,d3
		move.l a0,d2
		move.l #MEMF_PUBLIC|MEMF_PPC|MEMF_CLEAR,d1
		jsr _LVOAllocVec32(a6)
		tst.l d0
		beq.s NoRoom
		move.l d0,a0
		move.l d2,MN_REPLYPORT(a0)
		move.w d3,MN_LENGTH(a0)
NoRoom		movem.l (a7)+,d1-a6
		rts

;********************************************************************************************
;
;	void FreeXMsg(message) // a0
;
;********************************************************************************************

FreeXMsg:
		move.l a0,a1
		jsr _LVOFreeVec32(a6)
		rts

;********************************************************************************************
;
;	void SetCache68K(cacheflags, start, length) // d0,a0,d1
;
;********************************************************************************************

SetCache68K:
		movem.l d2-d4/a2/a6,-(a7)
		move.l d0,d2
		move.l a0,a2
		move.l d1,d3
		move.l LExecBase(pc),a6
		cmp.l #CACHE_DCACHEOFF,d2
		beq.s DCOff
		cmp.l #CACHE_DCACHEON,d2
		beq.s DCOn
		cmp.l #CACHE_ICACHEOFF,d2
		beq.s ICOff
		cmp.l #CACHE_ICACHEON,d2
		beq.s ICOn
		cmp.l #CACHE_DCACHEFLUSH,d2
		beq.s DCFlush
		cmp.l #CACHE_ICACHEINV,d2
		beq.s ICInv
		cmp.l #CACHE_DCACHEINV,d2		;only works if flushed before 
		beq.s DCFlush				;as this is not a real invalidate
		bra.s CacheIt				;but a flush/invalidate

DCOff		moveq.l #0,d0
		move.l #CACRF_EnableD,d1
		jsr _LVOCacheControl(a6)
		bra.s CacheIt

DCOn		move.l #CACRF_EnableD,d0
		move.l d0,d1
		jsr _LVOCacheControl(a6)
		bra.s CacheIt

ICOff		moveq.l #0,d0
		moveq.l #CACRF_EnableI,d1
		jsr _LVOCacheControl(a6)
		bra.s CacheIt

ICOn		moveq.l #CACRF_EnableI,d0
		move.l d0,d1
		jsr _LVOCacheControl(a6)
		bra.s CacheIt

DCFlush		tst.l a2
		beq.s NoStrtA
		tst.l d3
		beq.s NoStrtA
		move.l a2,a0
		move.l d3,d0
		move.l #CACRF_ClearD,d1
		jsr _LVOCacheClearE(a6)
		bra.s CacheIt

ICInv		tst.l a2
		beq.s NoStrtA
		tst.l d3
		beq.s NoStrtA
		move.l a2,a0
		move.l d3,d0
		moveq.l #CACRF_ClearI,d1
		jsr _LVOCacheClearE(a6)
		bra.s CacheIt		

NoStrtA		jsr _LVOCacheClearU(a6)

CacheIt		movem.l (a7)+,d2-d4/a2/a6
		rts

;********************************************************************************************
;
;	void PowerDebugMode(debuglevel) // d0
;
;********************************************************************************************

PowerDebugMode:
		movem.l d1-a6,-(a7)
		cmp.b #0,d0
		blt.s ExitDebug
		cmp.b #4,d0
		bge.s ExitDebug
		
		moveq.l #HW_SETDEBUGMODE,d1
		move.l d0,a0
		
		RUNPOWERPC	_PowerPCBase,SetHardware
		
ExitDebug	movem.l (a7)+,d1-a6

		rts

;********************************************************************************************
;
;	void SPrintF68K(Formatstring, values) // a0,a1
;
;********************************************************************************************

SPrintF68K:
		movem.l a2,-(a7)
		lea PutChProc(pc),a2
		move.l a6,-(a7)
		move.l LExecBase(pc),a6
		jsr _LVORawDoFmt(a6)
		move.l (a7)+,a6
		move.l (a7)+,a2
		rts

PutChProc:
		move.l a6,-(a7)
		move.l LExecBase(pc),a6
		jsr _LVORawPutChar(a6)
		move.l (a7)+,a6
		rts

;********************************************************************************************
;
;	void PutXMsg(MsgPortPPC, message) // a0,a1
;
;********************************************************************************************

PutXMsg:	movem.l d0-a6,-(a7)
		move.l a0,d7
		move.b #NT_XMSG68K,LN_TYPE(a1)
		bsr CreateMsgFrame		

		moveq.l #MSG_LEN/4-1,d0
		move.l a0,a2
ClrXMsg		clr.l (a2)+
		dbf d0,ClrXMsg

		move.l a0,a2
		move.w #192,MN_LENGTH(a0)
		move.l #"XPPC",MN_IDENTIFIER(a0)
		move.b #NT_MESSAGE,LN_TYPE(a0)
		move.l d7,MN_PPC(a0)
		move.l a1,MN_ARG2(a0)
		move.w MN_LENGTH(a1),MN_ARG1(a0)	;length for PPC to invalidate cache

		moveq.l #0,d1
		move.w MN_LENGTH(a1),d1
		move.l a1,a0
		move.l #CACHE_DCACHEFLUSH,d0

		bsr SetCache68K

		move.l a2,a0
		bsr SendMsgFrame
		movem.l (a7)+,d0-a6
		rts

;********************************************************************************************
;
;	void CausePPCInterrupt(void) //
;
;********************************************************************************************

CausePPCInterrupt:
		movem.l d1-a6,-(a7)

		RUNPOWERPC	_PowerPCBase,CauseInterrupt

		movem.l (a7)+,d1-a6
		rts

;********************************************************************************************
;
;	void ChangeStack68K(mem_attributes, size, flags) // d1, d2, d3	If d2=0 then keep old size
;
;********************************************************************************************

ChangeStack68K:						;moves stack. Does not release old stack!!
		move.l d1,d5
		move.l d2,d6
		sub.l a1,a1
		jsr _LVOFindTask(a6)
		tst.l d0
		beq PatchError

		move.l d0,a3
		move.l TC_SPUPPER(a3),d0
		move.l TC_SPLOWER(a3),d1
		tst.l d3
		beq.s NoPPCCheck
	
		move.l d1,d3
		rol.l #8,d3
		and.b #$F0,d3
		cmp.b #$70,d3
		beq.s PatchError
		
NoPPCCheck	sub.l d1,d0
		cmp.l d6,d0				;don't make stack smaller!
		blt.s DoStackMagic
		tst.l d6
		bne.s PatchError
		move.l d0,d6
		
DoStackMagic	move.l d6,d0
		move.l d5,d1
		jsr _LVOAllocVec(a6)
		tst.l d0
		beq.s PatchError
		
		move.l d0,-(a7)
		add.l d6,d0
		move.l d0,-(a7)
		move.l TC_SPUPPER(a3),d1
		move.l TC_SPREG(a3),d2
		move.l d2,a0
		sub.l d2,d1
		sub.l d1,d0
		move.l d0,a1
		move.l a1,-(a7)
		move.l d1,d0
		
		jsr _LVOCopyMem(a6)			;Copy stack to new spot
		
		move.l (a7)+,TC_SPREG(a3)
		move.l (a7)+,d0
		move.l TC_SPUPPER(a3),d2
		move.l d0,TC_SPUPPER(a3)
		move.l (a7)+,TC_SPLOWER(a3)
		move.l a7,d1
		move.l d0,d3
		sub.l d1,d2
		sub.l d2,d3
		cmp.b #NT_PROCESS,LN_TYPE(a3)
		bne.s NotAProc

		lsr.l #2,d0
		move.l d0,pr_StackBase(a3)
		move.l d6,pr_StackSize(a3)
NotAProc	move.l d3,a7				;Set new stack pointer
;		jsr _LVOCacheClearU(a6)
PatchError	rts

;********************************************************************************************

		cnop	0,4

Buffer
SegList			ds.l	1
PPCCodeMem		ds.l	1
PPCCodeMem2		ds.l	1
_PowerPCBase		ds.l	1
SonnetBase		ds.l	1
DosBase			ds.l	1
ExpBase			ds.l	1
PCIBase			ds.l	1
LExecBase		ds.l	1
ROMMem			ds.l	1
GfxMem			ds.l	1
GfxType			ds.l	1
ComProc			ds.l	1
SonAddr			ds.l	1
EUMBAddr		ds.l	1
AddTaskAddress		ds.l	1
RemTaskAddress		ds.l	1
OpenLibAddress		ds.l	1
AllocMemAddress		ds.l	1
LoadSegAddress		ds.l	1
NewLoadSegAddress	ds.l	1
MirrorList		ds.l	3
RemSysTask		ds.l	1
Previous		ds.l	1
MyInterrupt		ds.b	IS_SIZE

	cnop	0,4

DATATABLE:
	INITBYTE	LN_TYPE,NT_LIBRARY
	INITLONG	LN_NAME,LibName
	INITBYTE	LIB_FLAGS,LIBF_SUMMING|LIBF_CHANGED
	INITWORD	LIB_VERSION,17
	INITWORD	LIB_REVISION,5
	INITLONG	LIB_IDSTRING,IDString
	ds.l	1
	
WARPDATATABLE:
	INITBYTE	LN_TYPE,NT_LIBRARY
	INITLONG	LN_NAME,WarpName
	INITBYTE	LIB_FLAGS,LIBF_SUMMING|LIBF_CHANGED
	INITWORD	LIB_VERSION,5
	INITWORD	LIB_REVISION,0
	INITLONG	LIB_IDSTRING,WarpIDString
	ds.l	1

POWERDATATABLE:
	INITBYTE	LN_TYPE,NT_LIBRARY
	INITLONG	LN_NAME,PowerName
	INITBYTE	LIB_FLAGS,LIBF_SUMMING|LIBF_CHANGED
	INITWORD	LIB_VERSION,17
	INITWORD	LIB_REVISION,5
	INITLONG	LIB_IDSTRING,PowerIDString
	ds.l	1

WARPFUNCTABLE:
	dc.l	WarpOpen				;for WarpDT
	dc.l	WarpClose
	dc.l	Reserved
	dc.l	Reserved
	
	IFD	_IFUSION_	
	
	dc.l	WarpIllegal				;Debug for iFusion
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	dc.l	WarpIllegal
	
	ENDC	
	
	dc.l	-1

FUNCTABLE:
	dc.l	Open					;68K
	dc.l	Close
	dc.l	Expunge
	dc.l	Reserved
	dc.l	RunPPC
	dc.l	WaitForPPC
	dc.l	GetCPU
	dc.l	PowerDebugMode
	dc.l	AllocVec32
	dc.l	FreeVec32
	dc.l	SPrintF68K
	dc.l	AllocXMsg
	dc.l	FreeXMsg
	dc.l	PutXMsg
	dc.l	GetPPCState
	dc.l	SetCache68K
	dc.l	CreatePPCTask
	dc.l	CausePPCInterrupt

	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved
	dc.l	Reserved			;49 68K Functions

	dc.l	Run68K				;PPC
	dc.l	WaitFor68K
	dc.l	SPrintF
	dc.l	Run68KLowLevel
	dc.l	AllocVecPPC
	dc.l	FreeVecPPC
	dc.l	CreateTaskPPC
	dc.l	DeleteTaskPPC
	dc.l	FindTaskPPC
	dc.l	InitSemaphorePPC
	dc.l	FreeSemaphorePPC
	dc.l	AddSemaphorePPC
	dc.l	RemSemaphorePPC
	dc.l	ObtainSemaphorePPC
	dc.l	AttemptSemaphorePPC
	dc.l	ReleaseSemaphorePPC
	dc.l	FindSemaphorePPC
	dc.l	InsertPPC
	dc.l	AddHeadPPC
	dc.l	AddTailPPC
	dc.l	RemovePPC
	dc.l	RemHeadPPC
	dc.l	RemTailPPC
	dc.l	EnqueuePPC
	dc.l	FindNamePPC
	dc.l	FindTagItemPPC
	dc.l	GetTagDataPPC
	dc.l	NextTagItemPPC
	dc.l	AllocSignalPPC
	dc.l	FreeSignalPPC
	dc.l	SetSignalPPC
	dc.l	SignalPPC
	dc.l	WaitPPC
	dc.l	SetTaskPriPPC
	dc.l	Signal68K
	dc.l	SetCache
	dc.l	SetExcHandler
	dc.l	RemExcHandler
	dc.l	Super
	dc.l	User
	dc.l	SetHardware
	dc.l	ModifyFPExc
	dc.l	WaitTime
	dc.l	ChangeStack
	dc.l	LockTaskList
	dc.l	UnLockTaskList
	dc.l	SetExcMMU
	dc.l	ClearExcMMU
	dc.l	ChangeMMU
	dc.l	GetInfo
	dc.l	CreateMsgPortPPC
	dc.l	DeleteMsgPortPPC
	dc.l	AddPortPPC
	dc.l	RemPortPPC
	dc.l	FindPortPPC
	dc.l	WaitPortPPC
	dc.l	PutMsgPPC
	dc.l	GetMsgPPC
	dc.l	ReplyMsgPPC
	dc.l	FreeAllMem
	dc.l	CopyMemPPC
	dc.l	AllocXMsgPPC
	dc.l	FreeXMsgPPC
	dc.l	PutXMsgPPC
	dc.l	GetSysTimePPC
	dc.l	AddTimePPC
	dc.l	SubTimePPC
	dc.l	CmpTimePPC
	dc.l	SetReplyPortPPC
	dc.l	SnoopTask
	dc.l	EndSnoopTask
	dc.l	GetHALInfo
	dc.l	SetScheduling
	dc.l	FindTaskByID
	dc.l	SetNiceValue
	dc.l	TrySemaphorePPC
	dc.l	AllocPrivateMem
	dc.l	FreePrivateMem
	dc.l	ResetPPC
	dc.l	NewListPPC
	dc.l	SetExceptPPC
	dc.l	ObtainSemaphoreSharedPPC
	dc.l	AttemptSemaphoreSharedPPC
	dc.l	ProcurePPC
	dc.l	VacatePPC
	dc.l	CauseInterrupt
	dc.l	CreatePoolPPC
	dc.l	DeletePoolPPC
	dc.l	AllocPooledPPC
	dc.l	FreePooledPPC
	dc.l	RawDoFmtPPC
	dc.l	PutPublicMsgPPC
	dc.l	AddUniquePortPPC
	dc.l	AddUniqueSemaphorePPC
	dc.l	IsExceptionMode
	dc.l	CreateMsgFramePPC
	dc.l	SendMsgFramePPC
	dc.l	FreeMsgFramePPC

EndFlag		dc.l	-1
LibName		dc.b	"sonnet.library",0
IDString	dc.b	"$VER: sonnet.library 17.5 (11-Mar-17)",0
WarpName	dc.b	"warp.library",0
WarpIDString	dc.b	"$VER: fake warp.library 5.0 (01-Apr-16)",0
PowerName	dc.b	"powerpc.library",0
PowerIDString	dc.b	"$VER: fake powerpc.library 17.5 (11-Mar-17)",0

DebugString	dc.b	"Process: %s Function: %s r4,r5,r6,r7 = %08lx,%08lx,%08lx,%08lx",10,0
DebugString2	dc.b	"Process: %s Function: %s r3 = %08lx",10,0
		
PowerPCError	dc.b	"Powerpc.library (WarpOS) already active",0
LDOSError	dc.b	"Could not open dos.library V37+",0
LExpError	dc.b	"Could not open expansion.library V37+",0
LPCIError	dc.b	"Could not open pci.library V11+",0
MedError	dc.b	"Could not find a supported Mediator board",0
MemMedError	dc.b	"No system VGA memory detected (pcidma)",0
SonnetError	dc.b	"No Sonnet card detected",0
VGAError	dc.b	"No supported VGA card detected",0
MemVGAError	dc.b	"Could not allocate VGA memory",0
PPCMMUError	dc.b	"Error during MMU setup of PPC",0
GenMemError	dc.b	"General memory allocation error",0
LSetupError	dc.b	"Error during library function setup",0
SonnetMemError	dc.b	"No memory detected on the Sonnet card",0
SonnetUnstable	dc.b	"Memory corruption detected during setup",0
PPCCrash	dc.b	"PowerPC CPU possibly crashed during setup",0
NoPPCFound	dc.b	"PowerPC CPU not responding",0
StackRunError	dc.b	"RunPPC Stack transfer error",0
MedConfigJ	dc.b	"Mediator ConfigSwap jumper incorrectly configured",0
MedWindowJ	dc.b	"Mediator WindowSize jumper incorrectly configured",0

ramlib		dc.b "ramlib",0

WhiteList	dc.b 12,w1-WhiteList-2,"mpega.library",0
w1		dc.b w2-w1-1,"Warp3DPPC.library",0
w2		dc.b w3-w2-1,"agleppc.library",0
w3		dc.b w4-w3-1,"aglppc.library",0
w4		dc.b w5-w4-1,"aglsmapppc.library",0
w5		dc.b w6-w5-1,"agluppc.library",0
w6		dc.b w7-w6-1,"aglutppc.library",0
w7		dc.b w8-w7-1,"warpsdl.library",0
w8		dc.b w9-w8-1,"fsoundPPC.library",0
w9		dc.b w10-w9-1,"chunkyppc.library",0
w10		dc.b w11-w10-1,"ppc.library",0
w11		dc.b w12-w11-1,"asyncio.library",0
w12		dc.b w13-w12-1,"jpeg.library",0
w13		dc.b -1
		
BlackList	dc.b 1,b1-BlackList-2,"hyperionvideo.library",0
b1		dc.b b2-b1-1,"Picasso96API.library",0
b2		dc.b -1

ConWindow	dc.b	"CON:0/20/680/250/Sonnet - PowerPC Exception/AUTO/CLOSE/WAIT/"
		dc.b	"INACTIVE",0		

		cnop	0,4
		
CrashMessage	dc.b	"Task name: '%s'  Task address: %08lx  Exception: %s",10
		dc.b	"SRR0: %08lx    SRR1:  %08lx     MSR:   %08lx    HID0: %08lx",10
		dc.b	"PVR:  %08lx    DAR:   %08lx     DSISR: %08lx    SDR1: %08lx",10
		dc.b	"DEC:  %08lx    TBU:   %08lx     TBL:   %08lx    XER:  %08lx",10
		dc.b	"CR:   %08lx    FPSCR: %08lx     LR:    %08lx    CTR:  %08lx",10
		dc.b	"R0-R3:   %08lx %08lx %08lx %08lx   IBAT0: %08lx %08lx",10
		dc.b	"R4-R7:   %08lx %08lx %08lx %08lx   IBAT1: %08lx %08lx",10
		dc.b	"R8-R11:  %08lx %08lx %08lx %08lx   IBAT2: %08lx %08lx",10
		dc.b	"R12-R15: %08lx %08lx %08lx %08lx   IBAT3: %08lx %08lx",10
		dc.b	"R16-R19: %08lx %08lx %08lx %08lx   DBAT0: %08lx %08lx",10
		dc.b	"R20-R23: %08lx %08lx %08lx %08lx   DBAT1: %08lx %08lx",10
		dc.b	"R24-R27: %08lx %08lx %08lx %08lx   DBAT2: %08lx %08lx",10
		dc.b	"R28-R31: %08lx %08lx %08lx %08lx   DBAT3: %08lx %08lx",10,10,0

		dc.b	"F0-F3:    %s   %s   %s   %s",10		;Unused at the moment
		dc.b	"F4-F7:    %s   %s   %s   %s",10
		dc.b	"F8-F11:   %s   %s   %s   %s",10
		dc.b	"F12-F15:  %s   %s   %s   %s",10
		dc.b	"F16-F19:  %s   %s   %s   %s",10
		dc.b	"F20-F23:  %s   %s   %s   %s",10
		dc.b	"F24-F27:  %s   %s   %s   %s",10
		dc.b	"F28-F31:  %s   %s   %s   %s",10,0
				
RContinue	dc.b	"Continue",0

		cnop	0,4

Requester	dc.l	$14
		ds.l	4
		
EndCP		end
