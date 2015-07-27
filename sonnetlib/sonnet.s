
;MMU	EQU	1

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
	include	dos/dostags.i
	include dos/dos_lib.i
	include exec/ports.i
	include dos/dosextens.i
	include	exec/interrupts.i
	include hardware/intbits.i
	include	exec/tasks.i
	include sonnet_lib.i
	
	IFD	MMU
	
	include mmu/mmutags.i
	include mmu/context.i
	include	mmu/mmu_lvo.i

	ENDC

	XREF	FunctionsLen

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

	XREF 	PPCCode,PPCLen,RunningTask,WaitingTasks,MCTask,Init
	XREF	SysBase,PowerPCBase
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
	dc.b	1					;RT_VERSION
	dc.b	NT_LIBRARY				;RT_TYPE
	dc.b	0					;RT_PRI
	dc.l	LibName
	dc.l	IDString
	dc.l	INIT

ENDSKIP:
	ds.w	1

INIT:
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
	move.l #$89e,d0				;ELBOX
	moveq.l #33,d1				;Mediator MKII
	jsr _LVOFindConfigDev(a6)		;Find A3000/A4000 mediator (for now)
	move.l 4.w,a6
	tst.l d0
	beq.s Clean

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
	bra Dirty				;No initialized VGA found

Clean	move.l ROMMem(pc),d0
	beq.s NoROM
	bsr.s FreeROM
NoROM	move.l PCIBase(pc),d0
	beq.s NoPCI
	bsr.s ClsLib
NoPCI	move.l DosBase(pc),d0
	beq.s NoDos
	bsr.s ClsLib
NoDos	move.l ExpBase(pc),d0
	beq.s Exit
	bsr.s ClsLib
Exit	move.l _PowerPCBase(pc),d0
	movem.l (a7)+,d1-a6
	rts

ClsLib  move.l d0,a1
	jmp _LVOCloseLibrary(a6)
FreeROM	move.l d0,a1
	move.l #$10000,d0
	jmp _LVOFreeMem(a6)
	
FndMem	move.l d0,d7

	move.l PCIBase(pc),d0
	beq.s Clean
	move.l d0,a2

	move.l PCI_List(a2),a2
Loop1	move.l LN_SUCC(a2),d6
	beq.s Clean
	move.l PCI_VENDORID(a2),d1
	cmp.l #$10570004,d1
	beq.s Sonnet
	move.l d6,a2
	bra.s Loop1

Sonnet	move.l d7,a0
	move.l MH_UPPER(a0),d1
	sub.l #$10000,d1
	and.w #0,d1
	move.l d1,a1
	move.l #$10000,d0
	jsr _LVOAllocAbs(a6)			;Allocate fake ROM in VGA Mem
	tst.l d0
	beq.s Clean

	move.l d0,ROMMem-Buffer(a4)
	move.l d0,a5
	move.l a5,a1
	lea $100(a5),a5

	move.l PCI_SPACE1(a2),a3		;PCSRBAR Sonnet
	move.l a3,EUMBAddr-Buffer(a4)
	or.b #15,d0				;64kb
	rol.w #8,d0
	swap d0
	rol.w #8,d0
	move.l d0,OTWR(a3)
	move.l #$0000F0FF,OMBAR(a3)		;Processor outbound mem at $FFF00000

	move.l a2,d4
EndDrty	move.l #$48003f00,(a5)
	lea $3f00(a5),a5
	lea PPCCode(pc),a2
	move.l #PPCLen,d6
	lsr.l #2,d6
	subq.l #1,d6

loop2	move.l (a2)+,(a5)+
	dbf d6,loop2

	move.l #$abcdabcd,$6004(a1)		;Code Word
	move.l #$abcdabcd,$6008(a1)		;Sonnet Mem Start (Translated to PCI)
	move.l #$abcdabcd,$600c(a1)		;Sonnet Mem Len

	jsr _LVOCacheClearU(a6)

	tst.l d4
	bne.s NoCmm
	move.l d5,a5
	move.l COMMAND(a5),d5
	bset #26,d5				;Set Bus Master bit
	move.l d5,COMMAND(a5)

NoCmm	move.l #WP_TRIG01,WP_CONTROL(a3)	;Negate HRESET

Wait	move.l $6004(a1),d5
	cmp.l #"Boon",d5
	bne.s Wait

	move.l #StackSize,d7			;Set stack
	move.l $6008(a1),d5
	move.l d5,SonnetBase-Buffer(a4)
	add.l d7,d5
	move.l $600c(a1),d6
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
	sub.l #32,d1
	move.l d1,4(a1)
	move.l a1,MH_LOWER(a0)
	add.l a0,d6
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
NoPCILb	jsr _LVOEnqueue(a6)

	move.l #FunctionsLen,d0
	move.l #MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC,d1
	jsr _LVOAllocVec(a6)
	tst.l d0
	beq Clean
	move.l d0,PPCCodeMem-Buffer(a4)
	move.l d0,a1
	lea EndCP(pc),a0
	move.l #FunctionsLen,d1
	lsr.l #2,d1
	subq.l #1,d1
MoveSon	move.l (a0)+,(a1)+
	dbf d1,MoveSon
	
	bsr MakeLibrary
	
	tst.l d0
	beq.s NoLib

	move.l SonnetBase(pc),a1
	move.l d0,PowerPCBase(a1)
	move.l a5,PPCMemHeader(a1)			;Memheader at $8
	move.l a1,(a1)					;Sonnet relocated mem at $0
	move.l d0,_PowerPCBase-Buffer(a4)
	move.l a6,SysBase(a1)

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
	moveq.l #10,d0
	move.b d0,LN_PRI(a1)
	moveq.l #NT_INTERRUPT,d0
	move.b d0,LN_TYPE(a1)
	moveq.l #INTB_PORTS,d0
	jsr _LVOAddIntServer(a6)

	lea PrcTags(pc),a1
	move.l a1,d1
	move.l DosBase(pc),a6
	jsr _LVOCreateNewProc(a6)
	move.l 4.w,a6

NoLib	jsr _LVOEnable(a6)
	
	IFD	MMU
	bsr FunkyMMU
	ENDC
	
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
NumFunc	cmp.l (a3)+,d0
	dbeq d3,NumFunc
	not.w d3
	lsl #1,d3
	move.l d3,d0
	lsl #1,d3
	add.l d0,d3
	addq.l #3,d3
	andi.w #-4,d3
	moveq.l #124,d0				;PosSize
	move.l d0,d2
	add.w d3,d0
	move.l #MEMF_PUBLIC|MEMF_FAST|MEMF_PPC,d1
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
	
LoopFun	move.l (a1)+,d1
	cmp.l #-1,d1
	beq.s DoneFun
	
	tst.l d2
	bgt.s Fun68K
	
	add.l d6,d1
Fun68K	subq.l #1,d2
	move.l d1,-(a0)
	move.w #$4ef9,-(a0)
	bra.s LoopFun

DoneFun	jsr _LVOCacheClearU(a6)	
	move.l a3,a2
	move.l d5,a1
	moveq.l #0,d0
	jsr _LVOInitStruct(a6)
	move.l a3,d0
NoFun	movem.l (a7)+,d1-a6
	rts
	
;********************************************************************************************	
	
Dirty	move.l MediatorBase(pc),a0		;WARNING!!!! : EUMB register gets redefined
	moveq.l #0,d2				;after pci.library initiation!!!
	moveq.l #$3f,d1				;This affects the INT2 interrupt!!
	move.b #$60,(a0)			;Start address PCI Mem ($60000000)
CpLoop	move.l a0,a5
	add.l #$800000,a5			;Start address PCI config
	move.l d2,d0
	lsl.l #3,d0
	lsl.l #8,d0
	add.l d0,a5
	move.l (a5),d6
	cmp.l #$FFFFFFFF,d6
	beq Clean
	rol.w #8,d6
	swap d6
	rol.w #8,d6
	cmp.l #$00041057,d6
	beq.s MPC107
	cmp.l #$0005121a,d6
	beq VooDoo3
VooDone	addq.l #1,d2
	dbf d1,CpLoop
	bra Clean

MPC107	move.l #$62b00000,a1
	move.l PCIBase(pc),d5
	beq.s HardCr
	nop					;Insert code

	move.l PCSRBAR(a5),d5
	rol.w #8,d5
	swap d5
	rol.w #8,d5
	move.l d5,a3
	bra.s SoftCr

HardCr	move.l #$00300064,d5			;EUMB at $64003000
	move.l d5,PCSRBAR(a5)
	move.l COMMAND(a5),d5
	bset #25,d5				;Set PCI Memory bit
	move.l d5,COMMAND(a5)
	
	move.l #$64003000,a3			;EUMB at $64003000
SoftCr	move.l a3,EUMBAddr-Buffer(a4)

	move.l PCIBase(pc),d5
	beq.s HC2
	move.l d5,a1
	move.l PCI_List(a1),a1
Loop12	move.l LN_SUCC(a1),d5
	beq Clean
	move.l PCI_VENDORID(a1),d1
	cmp.l #$121a0005,d1
	beq.s Voodoo2
	move.l d5,a1
	bra.s Loop12

Voodoo2	move.l PCI_SPACE1(a1),d1
	add.l #$b00000,d1
	move.l d1,a1
	or.l #$f,d1
	rol.w #8,d1
	swap d1
	rol.w #8,d1
	move.l d1,OTWR(a3)
	bra.s SC2

HC2	move.l #$0F00B062,OTWR(a3)		;Host outbound PCI mem at $62B00000, 64kb (Code in GFXMem?)
SC2	move.l #$0000F0FF,OMBAR(a3)		;Processor outbound mem at $FFF00000

	moveq.l #0,d4
	move.l a5,d5
	lea $100(a1),a5
	bra EndDrty

VooDoo3	movem.l d0-a6,-(a7)
	move.l PCIBase(pc),d5
	bne.s V3SC
	moveq.l	#$62,d5				;Set BAR Voodoo at $62000000
	move.l d5,$14(a5)
V3SC	move.l COMMAND(a5),d5
	or.l #$07000000,d5
;	bset #25,d5				;Set PCI Memory bit (Voodoo3)
	move.l d5,COMMAND(a5)
	movem.l (a7)+,d0-a6
	bra VooDone

DosLib	dc.b "dos.library",0
	cnop 	0,2
ExpLib	dc.b "expansion.library",0
	cnop	0,2
pcilib	dc.b "pci.library",0
	cnop	0,2
MemName	dc.b "Sonnet memory",0
	cnop	0,2
PCIMem	dc.b "pcidma memory",0
	cnop	0,2
IntName	dc.b "Gort",0
	cnop	0,4

;********************************************************************************************

MasterControl:
	move.l #"INIT",d6
	move.l SonnetBase(pc),a4
	move.l 4.w,a6
	move.l ThisTask(a6),d0
	move.l d0,MCTask(a4)
	move.l d6,Init(a4)
	lea Buffer(pc),a4	
	jsr _LVOCacheClearU(a6)
	
NextMsg	move.l ThisTask(a6),a0
	lea pr_MsgPort(a0),a0
	move.l a0,d6
	jsr _LVOWaitPort(a6)
GetLoop	move.l d6,a0
	jsr _LVOGetMsg(a6)
	
	move.l d0,d7
	beq.s NextMsg
	move.l d0,a1
	move.l MN_IDENTIFIER(a1),d0
	cmp.l #"T68K",d0
	beq.s MsgT68k
	cmp.l #"FPPC",d0
	beq MsgFPPC
	cmp.l #"F68k",d0
	beq.s MsgF68k
	cmp.l #"LL68",d0
	beq MsgLL68
	bra.s GetLoop

MsgT68k	move.b LN_TYPE(a1),d7
	cmp.b #NT_MESSAGE,d7
	beq.s Sig68k
	cmp.b #NT_REPLYMSG,d7				;signal PPC that 68k is done
	bne.s NextMsg

	move.l MN_ARG2(a1),a2
	move.l #"DONE",MN_IDENTIFIER(a2)
ReUse	move.l a2,d7
	lea PushMsg(pc),a5
	jsr _LVOSupervisor(a6)
	move.l EUMBAddr(pc),a2
	move.l a1,OFQPR(a2)				;Return Message Frame
	move.l d7,IFQPR(a2)				;Message the PPC
	bra.s NextMsg
	
Sig68k	move.l ThisTask(a6),a0
	lea pr_MsgPort(a0),a0
	move.l a0,MN_REPLYPORT(a1)
	move.l MN_MIRROR(a1),a0
	jsr _LVOPutMsg(a6)				;move message to waiting 68k task
	bra NextMsg

MsgF68k	move.l d7,a1
	jsr _LVOReplyMsg(a6)
	bra NextMsg

MsgFPPC	move.l d7,a1
	move.l MN_ARG0(a1),a1
	move.l _PowerPCBase(pc),a6
	jsr _LVOFreeVec32(a6)
	move.l 4.w,a6
	move.l d7,a1
	jsr _LVOReplyMsg(a6)
	bra NextMsg

MsgLL68	move.l MN_PPSTRUCT+0*4(a1),a6
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
	
RtnLL	move.l (a7)+,a1
	move.l EUMBAddr(pc),a2
	move.l IFQPR(a2),a2
	move.l d0,MN_PPSTRUCT+6*4(a2)
	move.l #"DONE",MN_IDENTIFIER(a2)
	bra ReUse
	
PushMsg	moveq.l #11,d4
	move.l a1,a2
PshMsg	cpushl dc,(a2)
	lea L1_CACHE_LINE_SIZE_040(a2),a2		;Cache_Line 040/060 = 16 bytes
	dbf d4,PshMsg
	rte

	cnop 0,4

PrcTags	dc.l NP_Entry,MasterControl,NP_Name,PrcName,NP_Priority,125,0,0
PrcName	dc.b "MasterControl",0

	cnop 0,4

;********************************************************************************************
	IFD MMU

FunkyMMU
	movem.l d1-a6,-(a7)			;Enable caches for PCI memory
	move.l ROMMem(pc),a1
	move.l #$10000,d7
	move.l $6008(a1),d6			;MemStart
	add.l d7,d6
	move.l $600c(a1),d5			;MemLen
	sub.l d7,d5
	moveq.l #0,d0
	lea mmulib(pc),a1
	jsr _LVOOpenLibrary(a6)
	move.l d0,d7
	beq.s NoMMU
	move.l d0,a6
	jsr _LVODefaultContext(a6)
	move.l d0,d4
	beq.s NoMMU2
	move.l d0,a0				;Context
	moveq.l #0,d1
;	move.l #MAPP_COPYBACK,d1		;flags
	moveq.l #-1,d2				;Mask
	move.l d6,a1				;Logical
	move.l d5,d0				;Size
	lea MMUTags(pc),a2
	jsr _LVOSetPropertiesA(a6)
	tst.l d0
	beq.s NoMMU2
	move.l d4,a0
	jsr _LVORebuildTree(a6)
	move.l d7,a1
	move.l 4.w,a6
	jsr _LVOCloseLibrary(a6)
	movem.l (a7)+,d1-a6
	rts	
	
NoMMU2	move.l d7,a1
	move.l 4.w,a6
	jsr _LVOCloseLibrary(a6)
NoMMU	movem.l (a7)+,d1-a6
	rts	

;********************************************************************************************

MMUTags	dc.l TAG_DONE,0

mmulib	dc.b "mmu.library",0
	cnop	0,2
	
	ENDC
	
;********************************************************************************************
	
SonInt:
	movem.l d1-a6,-(a7)
	move.l 4.w,a6
	move.l EUMBAddr(pc),a2
	move.l #$03000000,d2				;OMISR[OM0I|OM1I]
	move.l OMISR(a2),d3
	and.l d2,d3
	beq.s NoSingl
	
	move.l OMR0(a2),a0				;Port
	move.l OMR1(a2),a1				;Message
	
	moveq.l #0,d4
	move.w MN_LENGTH(a1),d4				;PPC should make it 32 byte aligned
	beq.s NoSingl
	lsr.l #4,d4
	subq.l #1,d4
	move.l a1,d3
	bsr.s InvMsg
	move.l d3,a1
	
	jsr _LVOPutMsg(a6)

NoSingl move.l OMISR(a2),d3
	move.l d2,OMISR(a2)

	move.l #$20000000,d4				;OMISR[OPQI]
	and.l d4,d3
	beq.s NoInt
NxtMsg	move.l OFQPR(a2),d3				;Get Message Frame
	bmi.s NoInt
	
	move.l d3,a1	
	moveq.l #11,d4
	bsr.s InvMsg	
	move.l d3,a1
	move.l MN_MCTASK(a1),a0				;MN_MCTASK
	
	jsr _LVOPutMsg(a6)
	
	bra.s NxtMsg
	
NoInt	movem.l (a7)+,d1-a6
	moveq.l #0,d0
	rts

InvMsg	cinvl dc,(a1)
	lea L1_CACHE_LINE_SIZE_040(a1),a1		;Cache_Line 040/060 = 16 bytes
	dbf d4,InvMsg					;12x16 = MsgLen (192 bytes)
	rts

IntData	dc.l 0

;********************************************************************************************

Open:
	move.l a6,d0
	tst.l d0
	beq.s NoA6
	move.l d0,a6
	move.l a1,-(a7)
	lea _PowerPCBase(pc),a1
	move.l a6,(a1)
	move.l (a7)+,a1
	addq.w #1,LIB_OPENCNT(a6)
	bclr #LIBB_DELEXP,LIB_FLAGS(a6)
NoA6	rts

;********************************************************************************************

Close:
	moveq.l #0,d0
	subq.w #1,LIB_OPENCNT(a6)
	bne.s NoExp
	btst #LIBB_DELEXP,LIB_FLAGS(a6)
	bne.s Expunge
NoExp	rts

;********************************************************************************************

Expunge:
	tst.w LIB_OPENCNT(a6)
	beq.s NotOpen
	bset #LIBB_DELEXP,LIB_FLAGS(a6)
	moveq.l #0,d0
	rts
	
NotOpen	movem.l d2/a5/a6,-(a7)
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

DoPPCInterrupt:
	movem.l d1-a6,-(a7)
	jsr _LVOCacheClearU(a6)
	move.l #"HEAR",d5
StrtPPC	lea Buffer(pc),a4
	move.l SonAddr(pc),d0
	beq.s First
	move.l d0,a5
	bra.s NoFirst

First	bsr.s FindSonnet
	move.l a5,SonAddr-Buffer(a4)
NoFirst	addq.l #1,d1
	beq.s Error
	move.l PCSRBAR(a5),d0
	rol.w #8,d0
	swap d0
	rol.w #8,d0
	move.l d0,a5
	move.l d5,IMR0(a5)
Error	movem.l (a7)+,d1-a6
	rts
	
;********************************************************************************************

FindSonnet:
	moveq.l #0,d2
	moveq.l #$3f,d1
CpxLoop	move.l MediatorBase(pc),a5
	add.l #$800000,a5
	move.l d2,d0
	lsl.l #3,d0
	lsl.l #8,d0
	add.l d0,a5
	move.l (a5),d4
	cmp.l #$FFFFFFFF,d4
	beq.s Error2
	cmp.l #$57100400,d4
	beq.s xSonnet
	addq.l #1,d2
	dbf d1,CpxLoop
Error2	move.l d4,d1
xSonnet	rts

;********************************************************************************************
;
;	CPUTyoe = GetCPU(void) // d0
;
;********************************************************************************************

GetCPU:
	movem.l d1-a6,-(a7)	
	move.l SonnetBase(pc),a1
	move.l 12(a1),d0
	and.w #$0,d0
	swap d0
	subq.l #8,d0
	beq.s G3
	subq.l #4,d0
	beq.s G4
	moveq.l #0,d0
	bra.s ExCPU
G3	move.l #CPUF_G3,d0
	bra.s ExCPU
G4	move.l #CPUF_G4,d0
ExCPU	movem.l (a7)+,d1-a6
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

RunPPC:	
	link a5,#-8
	movem.l d1-a6,-(a7)
	moveq.l #0,d0
	move.l d0,Port(a5)
	move.l a0,PStruct(a5)
	move.l 4.w,a6
	move.l ThisTask(a6),a1
	cmp.b #NT_PROCESS,LN_TYPE(a1)
	bne.s xTask
	lea pr_MsgPort(a1),a1
	move.l a1,d0
	bra.s xProces

xTask	move.l LN_NAME(a1),a1
	jsr _LVOFindPort(a6)
	tst.l d0
	bne.s xProces
	
	jsr _LVOCreateMsgPort(a6)
	tst.l d0
	beq Cannot
	move.l ThisTask(a6),a1
	move.l d0,a2
	move.l LN_NAME(a1),LN_NAME(a2)

xProces	move.l d0,Port(a5)
	move.l ThisTask(a6),a1	
	move.l TC_SPUPPER(a1),d0
	move.l TC_SPLOWER(a1),d1
	sub.l d1,d0
	move.l d0,d7
	add.l #1024,d0

	move.l _PowerPCBase(pc),a6
	jsr _LVOAllocVec32(a6)
	
	move.l d0,d6
	beq Stacker

	move.l 4.w,a6
	move.l ThisTask(a6),a1
	move.l d6,a2
	lea TASKPPC_NAME(a2),a2
	
	move.l #1019-TASKPPC_NAME,d0			;Name len limit
	move.l LN_NAME(a1),a1
CpName	move.b (a1)+,(a2)
	tst.b (a2)
	beq.s EndName
	addq.l #1,a2
	dbf d0,CpName

EndName	move.l #"_PPC",(a2)				;Check Alignment?
							;Also push dcache
	move.l EUMBAddr(pc),a2
	move.l IFQPR(a2),a1
	
	moveq.l #47,d0					;MsgLen/4-1
	move.l a1,a2
ClrMsg	clr.l (a2)+
	dbf d0,ClrMsg
	
	move.w #192,MN_LENGTH(a1)
	move.l #"TPPC",MN_IDENTIFIER(a1)
	move.b #NT_MESSAGE,LN_TYPE(a1)
	move.l Port(a5),d1
	move.l d1,MN_REPLYPORT(a1)
	move.l d1,MN_MIRROR(a1)
	move.l d6,MN_ARG0(a1)				;Mem
	move.l d7,MN_ARG1(a1)				;Len
	
	lea MN_PPSTRUCT(a1),a2
	moveq.l #PP_SIZE/4-1,d0
	move.l PStruct(a5),a0
CpMsg2	move.l (a0)+,(a2)+
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
	
	ILLEGAL						;Shouldn't happen
	
FndPort	move.l d0,Port(a5)	
	bra.s Stacker

yProces	lea pr_MsgPort(a1),a1
	move.l a1,Port(a5)

Stacker	move.l Port(a5),a0
	jsr _LVOWaitPort(a6)
GtLoop	move.l Port(a5),a0
	jsr _LVOGetMsg(a6)
	tst.l d0
	beq.s Stacker	
	move.l d0,a0
	move.l MN_IDENTIFIER(a0),d0
	cmp.l #"FPPC",d0
	beq.s DizDone
	cmp.l #"T68K",d0
	beq.s Runk86
	bra.s GtLoop

DizDone	move.l PStruct(a5),a1
	move.l a0,a2
	lea MN_PPSTRUCT(a0),a0
	moveq.l #PP_SIZE/4-1,d0
CpBck	move.l (a0)+,(a1)+
	dbf d0,CpBck
	moveq.l #0,d7	
	move.l EUMBAddr(pc),a1
	move.l a2,OFQPR(a1)				;Return Message Frame
	bra.s Success

Cannot	moveq.l #-1,d7	
Success	move.l 4.w,a6
	move.l ThisTask(a6),a1
	cmp.b #NT_PROCESS,LN_TYPE(a1)
	beq.s EndIt
	move.l Port(a5),d0
	beq.s EndIt
	bsr.s FreePrt
EndIt	move.l d7,d0
	movem.l (a7)+,d1-a6
	unlk a5
	rts

FreePrt	move.l d0,a0
	jmp _LVODeleteMsgPort(a6)

Runk86	
	btst #AFB_FPU40,AttnFlags+1(a6)
	beq.s NoFPU
	fmove.d fp0,-(a7)
	fmove.d fp1,-(a7)
	fmove.d fp2,-(a7)
	fmove.d fp3,-(a7)
	fmove.d fp4,-(a7)
	fmove.d fp5,-(a7)
	fmove.d fp6,-(a7)
	fmove.d fp7,-(a7)
NoFPU	movem.l d0-a6,-(a7)				;68k routines called from PPC
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
NoFPU3	lea PP_REGS(a1),a6				;PP_STACKSIZE & PP_STACKPTR to be done
	movem.l (a6)+,d0-a5
	move.l (a6),a6
	rts

xBack	move.l a6,-(a7)
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
	
NoFPU4	move.l (a7),a1
	move.l EUMBAddr(pc),a2
	move.l IFQPR(a2),a2	
	move.l a2,MN_ARG2(a1)
	moveq.l #47,d1
DoReslt	move.l (a1)+,(a2)+
	dbf d1,DoReslt
	
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
NoFPU2	jsr _LVOReplyMsg(a6)
	bra GtLoop

;********************************************************************************************
;
;	PPCState = GetPCState(void) // d0
;
;********************************************************************************************

GetPPCState:
	move.l a0,-(a7)
	move.l d1,-(a7)
	moveq.l #PPCSTATEF_POWERSAVE,d0			;If no waiting then POWERSAVE
	move.l SonnetBase(pc),a0
	move.l WaitingTasks(a0),d1
	beq.s NoWait
	moveq.l #PPCSTATEF_APPACTIVE,d0
NoWait	move.l RunningTask(a0),d1
	beq.s NoRun
	moveq.l #PPCSTATEF_APPRUNNING,d0
NoRun	move.l (a7)+,d1
	move.l (a7)+,a0
	rts

;********************************************************************************************
;
;	TaskPPC = CreatePPCTask(TagItems) // d0 = a0
;
;********************************************************************************************

CreatePPCTask:
	movem.l d1-a6,-(a7)

	RUNPOWERPC	_PowerPCBase,CreateTaskPPC

	movem.l (a7)+,d1-a6
	rts

;********************************************************************************************
;
;	memblock = AllocVec32(memsize) // d0 = d0 (d1 is ignored)
;
;********************************************************************************************

AllocVec32:
	move.l a6,-(a7)
	add.l #$38,d0
	move.l 4.w,a6
	move.l #MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC,d1	;attributes are FIXED to Sonnet mem
	jsr _LVOAllocVec(a6)
	move.l d0,d1
	add.l #$27,d0
	and.l #$ffffffe0,d0
	move.l d0,a0
	move.l d1,-4(a0)
	move.l (A7)+,a6
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
	movem.l d2-d3,-(a7)
	move.l a0,d2
	add.l #$14,d0
	move.l d0,d3
	jsr _LVOAllocVec32(a6)
	tst.l d0
	beq.s NoAl32
	move.l d0,a0
	move.l d2,MN_REPLYPORT(a0)
	move.w d3,MN_LENGTH(a0)
NoAl32	movem.l (a7)+,d2-d3
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

DCOff	moveq.l #0,d0
	move.l #CACRF_EnableD,d1
	move.l 4.w,a6
	jsr _LVOCacheControl(a6)
	bra.s CacheIt

DCOn	move.l #CACRF_EnableD,d0
	move.l d0,d1
	move.l 4.w,a6
	jsr _LVOCacheControl(a6)
	bra.s CacheIt

ICOff	moveq.l #0,d0
	moveq.l #CACRF_EnableI,d1
	move.l 4.w,a6
	jsr _LVOCacheControl(a6)
	bra.s CacheIt

ICOn	moveq.l #CACRF_EnableI,d0
	move.l d0,d1
	move.l 4.w,a6
	bra.s CacheIt

DCFlush	tst.l a2
	beq.s NoStrtA
	tst.l d3
	beq.s NoStrtA
	move.l a2,a0
	move.l d3,d0
	move.l #CACRF_ClearD,d1
	move.l 4.w,a6
	jsr _LVOCacheClearE(a6)
	bra.s CacheIt

ICInv	tst.l a2
	beq.s NoStrtA
	tst.l d3
	beq.s NoStrtA
	move.l a2,a0
	move.l d3,d0
	moveq.l #CACRF_ClearI,d1
	move.l 4.w,a6
	jsr _LVOCacheClearE(a6)
	bra.s CacheIt

NoStrtA	move.l 4.w,a6
	jsr _LVOCacheClearU(a6)

CacheIt	movem.l (a7)+,d2-d4/a2/a6
	rts
	
;********************************************************************************************
;
;	void PowerDebugMode(debuglevel) // d0 -> NO DEBUGLEVEL IN SONNETLIB
;
;********************************************************************************************

PowerDebugMode:
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
;	void PutXMsg(MsgPortPPC, message) // a0,a1 -> TO BE IMPLEMENTED
;
;********************************************************************************************

PutXMsg:
	movem.l d0-a6,-(a7)			#STUB
	move.l #"DONE",d6
	move.l d6,MN_IDENTIFIER(a1)
	move.l MN_PPC(a1),a1
	moveq.l #TS_READY,d6
	move.b d6,TC_STATE(a1)
	move.l 4.w,a6
	jsr _LVOCacheClearU(a6)
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

DriverID
	dc.b "WarpUp hardware driver for Sonnet Crescendo 7200 PCI",0
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
ComProc		ds.l	1
SonAddr		ds.l	1
EUMBAddr	ds.l	1
MyInterrupt	ds.b	IS_SIZE

	cnop	0,4

DATATABLE:
	INITBYTE	LN_TYPE,NT_LIBRARY
	INITLONG	LN_NAME,LibName
	INITBYTE	LIB_FLAGS,LIBF_SUMMING|LIBF_CHANGED
	INITWORD	LIB_VERSION,1
	INITWORD	LIB_REVISION,0
	INITLONG	LIB_IDSTRING,IDString
	ds.l	1
	
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
	dc.l	Reserved				;49 68K Functions

	dc.l	Run68K					;PPC
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

EndFlag	dc.l	-1
LibName
	dc.b	"sonnet.library",0,0
IDString
	dc.b	"$VER: sonnet.library 1.0 (01-Apr-15)",0
	cnop	0,4
EndCP	end
