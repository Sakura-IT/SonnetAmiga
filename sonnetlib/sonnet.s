
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
	include exec/ports.i
	include dos/dosextens.i
	include	exec/interrupts.i
	include hardware/intbits.i
	include	exec/tasks.i
	include sonnet_lib.i

	XREF	FunctionsLen,LibFunctions,DebugLevel,CPUInfo

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
	XREF	AddUniqueSemaphorePPC,IsExceptionMode

	XREF 	PPCCode,PPCLen,RunningTask,LIST_WAITINGTASKS,MCPort,Init
	XREF	SysBase,PowerPCBase,DOSBase
	XDEF	_PowerPCBase

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

		lea DosLib(pc),a1
		moveq.l #37,d0
		jsr _LVOOpenLibrary(a6)
		tst.l d0
		beq.s Clean				;Open dos.library
		move.l d0,DosBase-Buffer(a4)

		lea ExpLib(pc),a1
		moveq.l #37,d0
		jsr _LVOOpenLibrary(a6)			;Open expansion.library
		tst.l d0
		beq.s Clean
		move.l d0,ExpBase-Buffer(a4)

		move.l d0,a6
		sub.l a0,a0
		move.l #VENDOR_ELBOX,d0			;ELBOX
		moveq.l #33,d1				;Mediator MKII
		jsr _LVOFindConfigDev(a6)		;Find A3000/A4000 mediator
		tst.l d0
		bne.s FoundMed

		sub.l a0,a0
		move.l #VENDOR_ELBOX,d0			;ELBOX
		moveq.l #60,d1				;Mediator 1200TX
		jsr _LVOFindConfigDev(a6)		;Find 1200TX mediator
		move.l 4.w,a6
		tst.l d0
		beq.s Clean

FoundMed	move.l 4.w,a6
		move.l d0,a1
		move.l cd_BoardAddr(a1),d0		;Start address Configspace Mediator
		move.l d0,MediatorBase-Buffer(a4)

		lea MemList(a6),a0
		lea MemName(pc),a1
		jsr _LVOFindName(a6)
		tst.l d0
		bne.s Clean

		moveq.l #0,d0
		lea pcilib(pc),a1
		jsr _LVOOpenLibrary(a6)
		move.l d0,PCIBase-Buffer(a4)

		lea MemList(a6),a0
		lea PCIMem(pc),a1
		jsr _LVOFindName(a6)
		tst.l d0
		bne.s FndMem

Clean		move.l 4.w,a6
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
		move.l #$10000,d0
		jmp _LVOFreeMem(a6)

FndMem		move.l d0,d7

		jsr _LVODisable(a6)
		move.l d7,a1
		jsr _LVORemove(a6)
		lea MemList(a6),a0
		move.l d7,a1
		jsr _LVOAddTail(a6)			;Move gfx memory to back to prevent
		jsr _LVOEnable(a6)			;mem list corruption

		move.l PCIBase(pc),d0
		beq.s Clean
		move.l d0,a6

		move.w #VENDOR_MOTOROLA,d0
		move.w #DEVICE_MPC107,d1
		moveq.l #0,d2
		jsr _LVOPCIFindCard(a6)
		move.l d0,d6
		beq.s Clean
		
		move.w #VENDOR_3DFX,d0
		move.w d0,d5
		move.w #DEVICE_VOODOO45,d1
		moveq.l #0,d2
		jsr _LVOPCIFindCard(a6)
		tst.l d0		
		beq.s Nxt3DFX
		move.l d0,a2
		move.l PCI_SPACE0(a2),d4
		bra.s FoundGfx
	
Nxt3DFX		move.w #VENDOR_3DFX,d0
		move.w d0,d5
		move.w #DEVICE_VOODOO3,d1
		moveq.l #0,d2
		jsr _LVOPCIFindCard(a6)
		tst.l d0		
		beq.s Not3DFX
		move.l d0,a2
		move.l PCI_SPACE0(a2),d4
		bra.s FoundGfx
			
Not3DFX		move.w #VENDOR_ATI,d0			;Need more pciinfo
		move.w d0,d5
		move.w #DEVICE_RV280PRO,d1
		moveq.l #0,d2
		jsr _LVOPCIFindCard(a6)
		tst.l d0
		beq.s NxtATI
		move.l d0,a2
		move.l PCI_SPACE0(a2),d4
		bra.s FoundGfx
				
NxtATI		move.w #VENDOR_ATI,d0
		move.w d0,d5
		move.w #DEVICE_RV280MOB,d1
		moveq.l #0,d2
		jsr _LVOPCIFindCard(a6)
		tst.l d0
		beq Clean
		move.l d0,a2
		move.l PCI_SPACE0(a2),d4
		
FoundGfx	move.l 4.w,a6
		move.l d4,GfxMem-Buffer(a4)
		move.w d5,GfxType-Buffer(a4)
		move.l d6,a2
		move.l a2,SonAddr-Buffer(a4)
		move.l d7,a0
		move.l MH_UPPER(a0),d1
		sub.l #$10000,d1
		and.w #0,d1
		move.l d1,a1
		move.l #$10000,d0
		jsr _LVOAllocAbs(a6)			;Allocate fake ROM in VGA Mem
		tst.l d0
		beq Clean

		move.l d0,ROMMem-Buffer(a4)
		move.l d0,a5
		move.l a5,a1
		lea $100(a5),a5

		move.l PCI_SPACE1(a2),a3		;PCSRBAR Sonnet
		move.l a3,EUMBAddr-Buffer(a4)
		or.b #15,d0				;64kb ROM
		rol.w #8,d0
		swap d0
		rol.w #8,d0
		move.l d0,OTWR(a3)
		move.l #$0000F0FF,OMBAR(a3)		;Processor outbound mem at $FFF00000

		move.l a2,d4
EndDrty		move.l #$48002f00,(a5)
		lea $2f00(a5),a5
		lea PPCCode(pc),a2
		move.l #PPCLen,d6
		lsr.l #2,d6
		subq.l #1,d6

loop2		move.l (a2)+,(a5)+
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

NoCmm		move.l #WP_TRIG01,WP_CONTROL(a3)	;Negate HRESET

Wait		move.l $3004(a1),d5
		cmp.l #"Boon",d5
		bne.s Wait

		move.l #StackSize,d7			;Set stack
		move.l $3008(a1),d5
		move.l d5,SonnetBase-Buffer(a4)
		add.l d7,d5
		move.l $300c(a1),d6
		sub.l d7,d6
		add.l d6,d7

		moveq.l #16,d0
		move.l #MEMF_PUBLIC|MEMF_CLEAR|MEMF_REVERSE,d1
		jsr _LVOAllocVec(a6)
		tst.l d0
		beq Clean
		move.l d0,a0
		lea MemName(pc),a1
		move.l (a1),(a0)
		move.l 4(a1),4(a0)
		move.l 8(a1),8(a0)
		move.l 12(a1),12(a0)

		move.l a0,a1
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
		sub.l #StackSize,d5
		move.l d5,PCI_SPACE0(a2)
		moveq.l #0,d6
		sub.l d7,d6
		move.l d6,PCI_SPACELEN0(a2)
NoPCILb		jsr _LVOEnqueue(a6)

		move.l #FunctionsLen,d0
		move.l #MEMF_PUBLIC|MEMF_PPC|MEMF_REVERSE|MEMF_CLEAR,d1
		bsr AllocVec32

		tst.l d0
		beq Clean
		move.l d0,PPCCodeMem-Buffer(a4)
		move.l d0,a1
		lea LibFunctions(pc),a0
		move.l #FunctionsLen,d1
		lsr.l #2,d1
		subq.l #1,d1
MoveSon		move.l (a0)+,(a1)+
		dbf d1,MoveSon

		bsr MakeLibrary
		tst.l d0
		beq NoLib

		move.l SonnetBase(pc),a1
		move.l d0,PowerPCBase(a1)
		move.l a5,PPCMemHeader(a1)		;Memheader at $8
		move.l a1,(a1)				;Sonnet relocated mem at $0
		move.l d0,_PowerPCBase-Buffer(a4)
		move.l a6,SysBase(a1)
		move.l DosBase(pc),DOSBase(a1)

		move.l d0,a1
		jsr _LVOAddLibrary(a6)

		lea WARPFUNCTABLE(pc),a0		;Set up a fake warp.library
		lea WARPDATATABLE(pc),a1		;Some programs do a version
		sub.l a2,a2				;check on this
		moveq.l #124,d0
		moveq.l #0,d1
		jsr _LVOMakeLibrary(a6)
		move.l d0,a1
		jsr _LVOAddLibrary(a6)

		move.l SonnetBase(pc),a1
		add.l #$100000,a1
		move.l #$190000,d0
		jsr _LVOAllocAbs(a6)

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
		jsr _LVOCreateNewProc(a6)

		move.l 4.w,a6
NoLib		jsr _LVOEnable(a6)

PPCInit		move.l SonnetBase(pc),a1
		move.l Init(a1),d0
		cmp.l #"REDY",d0
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
		move.l d0,OMBAR(a3)

		jsr _LVOCacheClearU(a6)
		bra Clean

;********************************************************************************************

MakeLibrary
		movem.l d1-a6,-(a7)
		sub.l a0,a1
		move.l a1,d6
		lea FUNCTABLE(pc),a0
		lea DATATABLE(pc),a1
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
		addq.l #3,d3
		andi.w #-4,d3
		move.l #1024,d0				;PosSize
		move.l d0,d2
		add.w d3,d0
		move.l #MEMF_PUBLIC|MEMF_FAST|MEMF_PPC|MEMF_REVERSE,d1
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

DosLib		dc.b "dos.library",0
		cnop 	0,2
ExpLib		dc.b "expansion.library",0
		cnop	0,2
pcilib		dc.b "pci.library",0
		cnop	0,2
MemName		dc.b "Sonnet memory",0
		cnop	0,2
PCIMem		dc.b "pcidma memory",0
		cnop	0,2
IntName		dc.b "Gort",0
		cnop	0,4

;********************************************************************************************
;********************************************************************************************

MasterControl:
		move.l #"INIT",d6
		move.l SonnetBase(pc),a4
		move.l 4.w,a6
		jsr _LVOCreateMsgPort(a6)
		tst.l d0
		beq.s MasterControl
		move.l d0,MCPort(a4)
		move.l d6,Init(a4)
		move.l d0,d6
		jsr _LVOCacheClearU(a6)

NextMsg		move.l d6,a0
		jsr _LVOWaitPort(a6)
		
GetLoop		move.l d6,a0
		jsr _LVOGetMsg(a6)

		move.l d0,d7
		beq.s NextMsg
				
		move.l d0,a1
		move.l MN_IDENTIFIER(a1),d0
		cmp.l #"T68K",d0
		beq MsgMir68
		cmp.l #"LL68",d0
		beq.s MsgLL68
		cmp.l #"FREE",d0
		beq.s MsgFree
		bra.s GetLoop
		
;********************************************************************************************

MsgLL68		move.l MN_PPSTRUCT+0*4(a1),a6
		move.l MN_PPSTRUCT+1*4(a1),a0
		add.l a6,a0
		move.l a1,-(a7)
		pea RtnLL(pc)
		move.l a0,-(a7)	
		move.l MN_PPSTRUCT+2*4(a1),a0
		move.l MN_PPSTRUCT+4*4(a1),d0
		move.l MN_PPSTRUCT+5*4(a1),d1
		move.l MN_PPSTRUCT+3*4(a1),a1
		rts

RtnLL		move.l (a7)+,a1
		move.l EUMBAddr(pc),a2
		move.l IFQPR(a2),a2
		move.l d0,MN_PPSTRUCT+6*4(a2)
		move.l #"DNLL",MN_IDENTIFIER(a2)
		move.l MN_PPC(a1),MN_PPC(a2)
		
		move.l MN_PPSTRUCT+0*4(a1),MN_PPSTRUCT+0*4(a2)
		move.l MN_PPSTRUCT+1*4(a1),MN_PPSTRUCT+1*4(a2)

		move.l 4.w,a6
		move.l a2,d7
		move.l a1,d5
		lea PushMsg(pc),a5
		jsr _LVOSupervisor(a6)
		move.l 4.w,a6
		move.l EUMBAddr(pc),a2
		move.l d7,IFQPR(a2)			;Message the PPC
		move.l d5,OFQPR(a2)			;Return Message Frame
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

RtnFree		move.l (a7)+,a1
		move.l EUMBAddr(pc),a2
		move.l a1,OFQPR(a2)			;Return Message Frame
		move.l 4.w,a6
		bra GetLoop
		
;********************************************************************************************

PushMsg		moveq.l #11,d4
		move.l a1,a2
PshMsg		cpushl dc,(a2)				;040+
		lea L1_CACHE_LINE_SIZE_040(a2),a2	;Cache_Line 040/060 = 16 bytes
		dbf d4,PshMsg
		rte
		
;********************************************************************************************

MsgMir68	move.l a1,-(a7)
		move.l MN_ARG0(a1),a0
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
		move.l #"_68K",(a2)+
		clr.b (a2)
		move.l d1,d2
		
		move.l DosBase(pc),a6
		lea Prc2Tags(pc),a1
		move.l a7,12(a1)
		move.l a1,d1
		jsr _LVOCreateNewProc(a6)
		
		add.l d2,a7
		move.l (a7)+,a1
		move.l 4.w,a6
		tst.l d0
		beq.s MsgMir68
		move.l d0,a0
		lea pr_MsgPort(a0),a0
		jsr _LVOPutMsg(a6)
		bra GetLoop
		
;********************************************************************************************		
;********************************************************************************************

MirrorTask	move.l 4.w,a6				;Mirror task for PPC task
		move.l ThisTask(a6),a0
		or.b #TF_PPC,TC_FLAGS(a0)
		lea pr_MsgPort(a0),a0
		move.l a0,d6
		jsr _LVOWaitPort(a6)

Error		jsr _LVOCreateMsgPort(a6)
		tst.l d0
		beq.s Error
		move.l d0,-(a7)
		
CleanUp		move.l d6,a0
		jsr _LVOGetMsg(a6)
		tst.l d0
		beq.s GoWaitPort
		
		move.l d0,a1
		move.l (a7),a0
		jsr _LVOPutMsg(a6)
		bra.s CleanUp

GoWaitPort	move.l (a7),a0
		move.l ThisTask(a6),a1
		move.l TC_SIGALLOC(a1),d0
		move.b MP_SIGBIT(a0),d1
		moveq.l #0,d2
		bset d1,d2
		or.l d2,d0		
		jsr _LVOWait(a6)
		
		move.l (a7),a0		
		move.b MP_SIGBIT(a0),d1
		moveq.l #0,d2
		bset d1,d2
		not.l d2
		move.l d0,d1
		and.l d2,d1
		beq.s GtLoop2

		move.l a0,a3
		bsr CrossSignals
		
GtLoop2		move.l (a7),a0
		jsr _LVOGetMsg(a6)
		move.l d0,d7
		beq.s GoWaitPort
				
		move.l d0,a0
		move.l MN_IDENTIFIER(a0),d0
		cmp.l #"T68K",d0
		beq.s DoRunk86
		cmp.l #"END!",d0
		bne.s GtLoop2
		
		move.l EUMBAddr(pc),a2
		move.l a0,OFQPR(a2)			;Return Message to free state
		move.l (a7)+,d0
		rts					;End task
		
DoRunk86	move.l (a7),MN_MIRROR(a0)	
		bsr Runk86
		bra.s GoWaitPort
		
;********************************************************************************************

		cnop 0,4

PrcTags		dc.l NP_Entry,MasterControl,NP_Name,PrcName,NP_Priority,4,NP_StackSize,$20000,0,0
PrcName		dc.b "MasterControl",0

		cnop 0,4
		
Prc2Tags	dc.l NP_Entry,MirrorTask,NP_Name,Prc2Name,NP_Priority,3,NP_StackSize,$20000,0,0
Prc2Name	dc.b "Joshua",0

		cnop 0,4
				
;********************************************************************************************
;********************************************************************************************

SonInt:		movem.l d0-a6,-(a7)
		move.l 4.w,a6
		move.l EUMBAddr(pc),a2
		move.l #$03000000,d2			;OMISR[OM0I|OM1I]
		move.l OMISR(a2),d3
		and.l d2,d3
		beq.s NoSingl

		move.l OMR0(a2),a0			;Port
		move.l OMR1(a2),a1			;Message
		move.l #$ffffffff,OMR0(a2)		;Destroy value
		cmp.l #$ffffffff,a0
		beq.s ClearInt

DoPMsg		moveq.l #0,d4
		move.w MN_LENGTH(a1),d4			;PPC should make it 32 byte aligned
		beq.s NoSingl
		lsr.l #4,d4
		subq.l #1,d4
		move.l a1,d3
		bsr InvMsg				;PCI memory is cache inhibited for 68k
		move.l d3,a1
;		jsr _LVOPutMsg(a6)		
ClearInt	move.l d2,OMISR(a2)

NoSingl	 	move.l OMISR(a2),d3		
		move.l #$20000000,d4			;OMISR[OPQI]
		and.l d4,d3
		beq.s DidInt

NxtMsg		move.l EUMBAddr(pc),a2
		move.l OFQPR(a2),d3			;Get Message Frame
		cmp.l #-1,d3
		beq.s DidInt

		move.l d3,a1
		moveq.l #11,d4
		bsr.s InvMsg				;PCI memory is cache inhibited for 68k
		move.l d3,a1
		move.b LN_TYPE(a1),d0
		cmp.b #NT_REPLYMSG,d0
		bne.s NoXReply
	
		move.l -32+MN_IDENTIFIER(a1),d0
		cmp.l #"XMSG",d0
		beq MsgRXMSG
		
NoXReply	move.l MN_IDENTIFIER(a1),d0
		cmp.l #"T68K",d0
		beq MsgT68k
		cmp.l #"END!",d0
		beq MsgT68k
		cmp.l #"FPPC",d0
		beq MsgFPPC
		cmp.l #"XMSG",d0
		beq MsgXMSG
		cmp.l #"GETV",d0
		beq.s LoadD
		and.l #$ffffff00,d0
		cmp.l #$50555400,d0
		beq.s StoreD		
		
CommandMaster	move.l d3,a1
		move.l MN_MCPORT(a1),a0
DoPutMsg	jsr _LVOPutMsg(a6)
		bra.s NxtMsg

DidInt		moveq.l #0,d7
		movem.l (a7)+,d0-a6
		rts

InvMsg		cinvl dc,(a1)				;040+
		lea L1_CACHE_LINE_SIZE_040(a1),a1	;Cache_Line 040/060 = 16 bytes
		dbf d4,InvMsg				;12x16 = MsgLen (192 bytes)
		rts

IntData		dc.l 0

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
		move.l EUMBAddr(pc),a2
		move.l a1,OFQPR(a2)			;Return Message Frame
		bra NxtMsg

PutB		move.b d0,(a0)
		bra.s Putted

PutH		move.w d0,(a0)
		bra.s Putted

LoadD		move.l #"DONE",d0
		move.l MN_IDENTIFIER+8(a1),a3

		move.l (a3),MN_IDENTIFIER+4(a1)
		move.l d0,MN_IDENTIFIER(a1)
		move.l EUMBAddr(pc),a2
		move.l a1,OFQPR(a2)			;Return Message Frame
		bra NxtMsg
		
;********************************************************************************************		
		
MsgT68k		move.l MN_MIRROR(a1),a0			;Handles messages to 68K (mirror)tasks
		move.l a0,d0
		beq CommandMaster		
		bra DoPutMsg

;********************************************************************************************

MsgFPPC		jsr _LVOReplyMsg(a6)			;Ends the RunPPC function
		bra NxtMsg
		
;********************************************************************************************		

MsgXMSG		
		move.l MN_MIRROR(a1),a0
		lea 32(a1),a1
		bra DoPutMsg
		
;********************************************************************************************		

MsgRXMSG	lea -32(a1),a1
		move.b #NT_REPLYMSG,LN_TYPE(a1)
		move.l EUMBAddr(pc),a2
		move.l MN_REPLYPORT(a1),d0
		beq.s FreeRXMsg

		move.l IFQPR(a2),a2
		move.l a1,a3
		move.l a2,d7
		moveq.l #192/4-1,d0
CopyRXMsg	move.l (a3)+,(a2)+
		dbf d0,CopyRXMsg
		
		move.l EUMBAddr(pc),a2
		move.l d7,IFQPR(a2)			;Message the PPC
FreeRXMsg	move.l a1,OFQPR(a2)			;Return Message Frame
		bra NxtMsg

;********************************************************************************************
;********************************************************************************************

WarpOpen:
		move.l a6,d0				;Dummy Open() for warp.library
		tst.l d0
		beq.s NoA6
		move.l 4.w,a6
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
		move.l a6,d0
		tst.l d0
		beq.s NoA6
		move.l 4.w,a6
		move.l ThisTask(a6),a6
		or.b #TF_PPC,TC_FLAGS(a6)
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
		beq.s NotOpen
		bset #LIBB_DELEXP,LIB_FLAGS(a6)
		moveq.l #0,d0
		rts

NotOpen		movem.l d2/a5/a6,-(a7)
		move.l a6,a5
		move.l 4.w,a6
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
		movem.l d1-a6,-(a7)
		move.l SonnetBase(pc),a1
		move.l CPUInfo(a1),d0
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
;	status = RunPPC(PPStruct) // d0=a0
;
;********************************************************************************************

MN_IDENTIFIER	EQU MN_SIZE
MN_MIRROR	EQU MN_IDENTIFIER+4
MN_PPC		EQU MN_MIRROR+4
MN_PPSTRUCT	EQU MN_PPC+4


PStruct	EQU -4
Port	EQU -8

RunPPC:		link a5,#-8
		movem.l d1-a6,-(a7)
		moveq.l #0,d0
		move.l d0,Port(a5)
		move.l a0,PStruct(a5)
		move.l 4.w,a6
		move.l ThisTask(a6),a1
		cmp.b #NT_PROCESS,LN_TYPE(a1)
xTask		bne.s xTask

		jsr _LVOCreateMsgPort(a6)
		tst.l d0
		bne.s xProces
		
		moveq.l #PPERR_ASYNCERR,d7
		bra EndIt

xProces		move.l d0,Port(a5)
		move.l ThisTask(a6),a1
		move.l TC_SPUPPER(a1),d0
		move.l TC_SPLOWER(a1),d1
		sub.l d1,d0
		or.l #$10000,d0				;Set stack at least at 64k
		move.l d0,d7
		add.l #1024,d0

		move.l _PowerPCBase(pc),a6
		move.l #MEMF_PUBLIC|MEMF_PPC|MEMF_REVERSE,d1
		jsr _LVOAllocVec32(a6)
		move.l d0,d6
		beq Stacker

		move.l 4.w,a6
		move.l ThisTask(a6),a1
		move.l d6,a2
		move.l #255,d0
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

DoNameCp	moveq.l #1019-TASKPPC_NAME,d0		;Name len limit		
CpName		move.b (a1)+,(a2)
		tst.b (a2)
		beq.s EndName
		addq.l #1,a2
		dbf d0,CpName

EndName		move.l #"_PPC",(a2)			;Check Alignment?
							;Also push dcache
		move.l EUMBAddr(pc),a2
		move.l IFQPR(a2),a1

		moveq.l #47,d0				;MsgLen/4-1
		move.l a1,a2
ClrMsg		clr.l (a2)+
		dbf d0,ClrMsg

		move.w #192,MN_LENGTH(a1)
		move.l #"TPPC",MN_IDENTIFIER(a1)
		move.b #NT_MESSAGE,LN_TYPE(a1)
		move.l Port(a5),d1
		move.l d1,MN_REPLYPORT(a1)
		move.l d1,MN_MIRROR(a1)
		move.l d6,MN_ARG0(a1)			;Mem
		move.l d7,MN_ARG1(a1)			;Len

		lea MN_PPSTRUCT(a1),a2
		moveq.l #PP_SIZE/4-1,d0
		move.l PStruct(a5),a0
		
		tst.l PP_STACKPTR(a0)			;Unsupported, but not yet encountered
		beq.s CpMsg2
		
		ILLEGAL
		
CpMsg2		move.l (a0)+,(a2)+
		dbf d0,CpMsg2

		move.l EUMBAddr(pc),a2
		move.l a1,IFQPR(a2)
		bra.s Stacker

;********************************************************************************************
;
;	status = WaitForPPC(PPStruct) // d0=a0
;
;********************************************************************************************

WaitForPPC:
		ILLEGAL

		link a5,#-8
		movem.l d1-a6,-(a7)
		moveq.l #0,d0
		move.l d0,Port(a5)
		move.l a0,PStruct(a5)
		move.l 4.w,a6
		cmp.b #NT_PROCESS,LN_TYPE(a1)
		beq.s yProces

		move.l ThisTask(a6),a1
		move.l LN_NAME(a1),a1
		jsr _LVOFindPort(a6)
		tst.l d0
		bne.s FndPort

		moveq.l #PPERR_WAITERR,d7
		bra EndIt

FndPort		move.l d0,Port(a5)
		bra.s Stacker

yProces		lea pr_MsgPort(a1),a1
		move.l a1,Port(a5)

Stacker		move.l ThisTask(a6),a1
		move.l TC_SIGALLOC(a1),d0
;		and.l #$fffff000,d0
		move.l Port(a5),a0		
		move.b MP_SIGBIT(a0),d1
		moveq.l #0,d2
		bset d1,d2
		or.l d2,d0		
		jsr _LVOWait(a6)

		move.l Port(a5),a0		
		move.b MP_SIGBIT(a0),d1
		moveq.l #0,d2
		bset d1,d2
		not.l d2
		move.l d0,d1
		and.l d2,d1
		beq.s GtLoop
		
		move.l Port(a5),a3
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
		bsr.s Runk86
		bra.s GtLoop

DizDone		move.l a0,-(a7)
		move.l MN_ARG0(a0),a1			;Releases memory from RunPPC created
		move.l _PowerPCBase(pc),a6		;PPC task
		jsr _LVOFreeVec32(a6)
		move.l 4.w,a6
		move.l PStruct(a5),a1
		lea PP_REGS(a1),a1
		move.l (a7)+,a0
		move.l a0,a2
		lea MN_PPSTRUCT+PP_REGS(a0),a0
		moveq.l #(PP_SIZE-PP_REGS)/4-1,d0
CpBck		move.l (a0)+,(a1)+
		dbf d0,CpBck
		moveq.l #PPERR_SUCCESS,d7
		move.l EUMBAddr(pc),a1
		move.l a2,OFQPR(a1)			;Return Message Frame
		bra.s Success

Cannot		moveq.l #-1,d7
Success		move.l 4.w,a6
		move.l Port(a5),d0
		beq.s EndIt
		bsr.s FreePrt
EndIt		move.l d7,d0
		movem.l (a7)+,d1-a6
		unlk a5
		rts

FreePrt		move.l d0,a0
		jmp _LVODeleteMsgPort(a6)

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
		pea xBack(pc)
		move.l PP_CODE(a1),a0
		add.l PP_OFFSET(a1),a0
		move.l a0,-(a7)
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
NoFPU3		lea PP_REGS(a1),a6			;PP_STACKSIZE & PP_STACKPTR to be done
		movem.l (a6)+,d0-a5
		move.l (a6),a6
		rts

xBack		move.l a6,-(a7)
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
		move.l 4.w,a6
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

NoFPU4		move.l (a7),a1
		move.l EUMBAddr(pc),a2
		move.l IFQPR(a2),-(a7)
		move.l (a7),a2
		moveq.l #47,d1
DoReslt		move.l (a1)+,(a2)+
		dbf d1,DoReslt
		
		move.l (a7)+,a2
		move.l #"DONE",MN_IDENTIFIER(a2)
		move.l a2,d7
		move.l (a7),a1
		lea PushMsg(pc),a5
		move.l 4.w,a6
		jsr _LVOSupervisor(a6)
		move.l EUMBAddr(pc),a2
		move.l d7,IFQPR(a2)			;Message the PPC
		move.l (a7),OFQPR(a2)			;Return Message Frame

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

CrossSignals	move.l EUMBAddr(pc),a2			;Get Frame
		move.l IFQPR(a2),a1

		moveq.l #47,d1				;MsgLen/4-1
		move.l a1,a2
ClearMsg	clr.l (a2)+
		dbf d1,ClearMsg

		move.l #"LLPP",MN_IDENTIFIER(a1)
		move.l d0,MN_ARG0(a1)
		move.l a3,MN_ARG1(a1)		
		move.l EUMBAddr(pc),a2
		move.l a1,IFQPR(a2)			;Signal PPC with Frame

		rts

;********************************************************************************************
;
;	PPCState = GetPCState(void) // d0
;
;********************************************************************************************

GetPPCState:
		move.l a0,-(a7)
		move.l d1,-(a7)
		moveq.l #PPCSTATEF_POWERSAVE,d0		;If no waiting then POWERSAVE
		move.l SonnetBase(pc),a0
		move.l LIST_WAITINGTASKS(a0),d1		;PPC Cache?
		beq.s NoWait
		moveq.l #PPCSTATEF_APPACTIVE,d0
NoWait		move.l RunningTask(a0),d1
		beq.s NoRun
		moveq.l #PPCSTATEF_APPRUNNING,d0
NoRun		move.l (a7)+,d1
		move.l (a7)+,a0
		rts

;********************************************************************************************
;
;	TaskPPC = CreatePPCTask(TagItems) // d0 = a0
;
;********************************************************************************************

CreatePPCTask:	movem.l d1-a6,-(a7)

		ILLEGAL

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
		move.l 4.w,a6
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
		move.l -4(a1),a1
		move.l 4.w,a6
		jsr _LVOFreeVec(a6)
		move.l (a7)+,a6
		rts

;********************************************************************************************
;
;	message = AllocXMsg(bodysize, replyport) // d0=d0,a0
;
;********************************************************************************************

AllocXMsg:
		movem.l d1-a6,-(a7)
		cmp.l #192-MN_PPSTRUCT,d0
		ble.s RightSize
		
		ILLEGAL						;Sizes above 172 unsupported
		
RightSize	move.l d0,d3
		move.l #MEMF_PUBLIC|MEMF_REVERSE|MEMF_CLEAR,d1
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
;	void SetCache68k(cacheflags, start, length) // d0,a0,d1
;
;********************************************************************************************

SetCache68K:
		movem.l d2-d4/a2/a6,-(a7)
		move.l d0,d2
		move.l a0,a2
		move.l d1,d3
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
		cmp.l #CACHE_DCACHEINV,d2
		beq.s DCFlush
		bra.s CacheIt

DCOff		moveq.l #0,d0
		move.l #CACRF_EnableD,d1
		move.l 4.w,a6
		jsr _LVOCacheControl(a6)
		bra.s CacheIt

DCOn		move.l #CACRF_EnableD,d0
		move.l d0,d1
		move.l 4.w,a6
		jsr _LVOCacheControl(a6)
		bra.s CacheIt

ICOff		moveq.l #0,d0
		moveq.l #CACRF_EnableI,d1
		move.l 4.w,a6
		jsr _LVOCacheControl(a6)
		bra.s CacheIt

ICOn		moveq.l #CACRF_EnableI,d0
		move.l d0,d1
		move.l 4.w,a6
		bra.s CacheIt

DCFlush		tst.l a2
		beq.s NoStrtA
		tst.l d3
		beq.s NoStrtA
		move.l a2,a0
		move.l d3,d0
		move.l #CACRF_ClearD,d1
		move.l 4.w,a6
		jsr _LVOCacheClearE(a6)
		bra.s CacheIt

ICInv		tst.l a2
		beq.s NoStrtA
		tst.l d3
		beq.s NoStrtA
		move.l a2,a0
		move.l d3,d0
		moveq.l #CACRF_ClearI,d1
		move.l 4.w,a6
		jsr _LVOCacheClearE(a6)
		bra.s CacheIt

NoStrtA		move.l 4.w,a6
		jsr _LVOCacheClearU(a6)

CacheIt		movem.l (a7)+,d2-d4/a2/a6
		rts

;********************************************************************************************
;
;	void PowerDebugMode(debuglevel) // d0
;
;********************************************************************************************

PowerDebugMode:
		cmp.b #0,d0
		blt.s ExitDebug
		cmp.b #4,d0
		bge.s ExitDebug
		move.l a0,-(a7)
		move.l SonnetBase(pc),a0
		move.b d0,DebugLevel(a0)
		move.l (a7)+,a0
ExitDebug	rts

;********************************************************************************************
;
;	void SPrintF68K(Formatstring, values) // a0,a1
;
;********************************************************************************************

SPrintF68K:
		movem.l a2,-(a7)
		lea PutChProc(pc),a2
		move.l a6,-(a7)
		move.l 4.w,a6
		jsr _LVORawDoFmt(a6)
		move.l (a7)+,a6
		move.l (a7)+,a2
		rts

PutChProc:
		move.l a6,-(a7)
		move.l 4.w,a6
		jsr _LVORawPutChar(a6)
		move.l (a7)+,a6
		rts

;********************************************************************************************
;
;	void PutXMsg(MsgPortPPC, message) // a0,a1
;
;********************************************************************************************

PutXMsg:
		movem.l d0-a6,-(a7)
		move.b #NT_XMSG68K,LN_TYPE(a1)
		move.l a1,a3
		move.l EUMBAddr(pc),a2
		move.l IFQPR(a2),a1			;Get message frame

		moveq.l #47,d0				;MsgLen/4-1
		move.l a1,a2
ClrXMsg		clr.l (a2)+
		dbf d0,ClrXMsg

		move.w #192,MN_LENGTH(a1)
		move.l #"XPPC",MN_IDENTIFIER(a1)
		move.b #NT_MESSAGE,LN_TYPE(a1)
		move.l a0,MN_PPC(a1)

		lea MN_PPSTRUCT(a1),a2
		moveq.l #PP_SIZE/4-1,d0
CpXMsg		move.l (a3)+,(a2)+
		dbf d0,CpXMsg

		move.l EUMBAddr(pc),a2
		move.l a1,IFQPR(a2)			;Free send message to PPC
		movem.l (a7)+,d0-a6
		rts

;********************************************************************************************
;
;	void CausePPCInterrupt(void) // -> TO BE IMPLEMENTED
;
;********************************************************************************************

CausePPCInterrupt:
		rts

;********************************************************************************************

		cnop	0,4

Buffer
SegList		ds.l	1
PPCCodeMem	ds.l	1
_PowerPCBase	ds.l	1
SonnetBase	ds.l	1
MediatorBase	ds.l	1
DosBase		ds.l	1
ExpBase		ds.l	1
PCIBase		ds.l	1
ROMMem		ds.l	1
GfxMem		ds.l	1
GfxType		ds.l	1
ComProc		ds.l	1
SonAddr		ds.l	1
EUMBAddr	ds.l	1
MyInterrupt	ds.b	IS_SIZE

	cnop	0,4

DATATABLE:
	INITBYTE	LN_TYPE,NT_LIBRARY
	INITLONG	LN_NAME,LibName
	INITBYTE	LIB_FLAGS,LIBF_SUMMING|LIBF_CHANGED
	INITWORD	LIB_VERSION,17
	INITWORD	LIB_REVISION,0
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

WARPFUNCTABLE:
	dc.l	WarpOpen
	dc.l	WarpClose
	dc.l	Reserved
	dc.l	Reserved
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

EndFlag		dc.l	-1
LibName		dc.b	"sonnet.library",0
		cnop	 0,4
IDString	dc.b	"$VER: sonnet.library 17.0 (01-Apr-16)",0
		cnop 	0,4
WarpName	dc.b	"warp.library",0
		cnop	0,4
WarpIDString	dc.b	"$VER: fake warp.library 5.0 (01-Apr-16)",0
		cnop	0,4
EndCP		end
