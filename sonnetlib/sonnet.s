
COMMAND		EQU $4	
IMR0		EQU $50
LMBAR		EQU $10
PCSRBAR		EQU $14
OMBAR		EQU $300
OTWR		EQU $308
WP_CONTROL	EQU $F48		
WP_TRIG01	EQU $c0000000
MEMF_PPC	EQU $1000
StackSize	EQU $80000
blr		MACRO
		dc.l $4E800020
		ENDM
	
	incdir	include:
	include	lvo/exec_lib.i
	include exec/initializers.i
	include	exec/nodes.i
	include exec/libraries.i
	include exec/resident.i
	include	exec/memory.i
	include pci.i
	include	lvo/expansion_lib.i
	include	libraries/configvars.i
	include	exec/execbase.i
	include powerpc/powerpc.i
	include	dos/dostags.i
	include lvo/dos_lib.i
	include exec/ports.i
	include dos/dosextens.i
	
	XREF	FunctionsLen
	
	XREF	SetExcMMU,ClearExcMMU,ConfirmInterrupt,InsertPPC,AddHeadPPC,AddTailPPC
	XREF	RemovePPC,RemHeadPPC,RemTailPPC,EnqueuePPC,FindNamePPC,ResetPPC,NewListPPC
	XREF	AddTimePPC,SubTimePPC,CmpTimePPC,AllocVecPPC,FreeVecPPC,GetInfo,GetSysTimePPC
	XREF	NextTagItemPPC,GetTagDataPPC,FindTagItemPPC
	
	XREF 	PPCCode,PPCLen
	XDEF	PowerPCBase

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

INIT	movem.l d1-a6,-(a7)
	move.l 4.w,a6
	lea Buffer(pc),a4
	
	lea MemList(a6),a0
	lea MemName(pc),a1
	jsr _LVOFindName(a6)
	tst.l d0
	bne.s Exit
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
Exit	move.l PowerPCBase(pc),d0
	movem.l (a7)+,d1-a6
	rts
	
ClsLib  move.l d0,a1
	jmp _LVOCloseLibrary(a6)
FreeROM	move.l d0,a1
	move.l #$10000,d0
	jmp _LVOFreeMem(a6)
	
FndMem	move.l d0,d7
	moveq.l #0,d0
	lea pcilib(pc),a1
	jsr _LVOOpenLibrary(a6)
	tst.l d0
	beq.s Exit
	move.l d0,PCIBase-Buffer(a4)
	
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
	beq Clean

	move.l d0,a1
	move.l cd_BoardAddr(a1),d0		;Start address Configspace Mediator
	move.l d0,MediatorBase-Buffer(a4)
	
	move.l PCIBase(pc),a2
	move.l PCI_List(a2),a2
Loop1	move.l LN_SUCC(a2),d6
	beq Clean
	move.l PCI_VENDORID(a2),d1
	cmp.l #$10570004,d1
	beq.s Sonnet
Loop2	move.l d6,a2
	bra.s Loop1	
	
Sonnet	move.l d7,a0
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
	jsr _LVOCacheClearU(a6)
	
	move.l #$abcdabcd,$6004(a1)		;Code Word
	move.l #$abcdabcd,$6008(a1)		;Sonnet Mem Start (Translated to PCI)
	move.l #$abcdabcd,$600c(a1)		;Sonnet Mem Len
	
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
	move.w #$0a32,LN_TYPE(a0)
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

	move.l #(EndCP-MasterControl)+FunctionsLen,d0
	move.l #MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC,d1
	jsr _LVOAllocVec(a6)
	tst.l d0
	beq Clean
	move.l d0,a1
	lea PrcName-MasterControl(a1),a2
	lea MasterControl(pc),a0
	move.l a2,PrcTags+12-MasterControl(a0)
	move.l a1,PrcTags+4-MasterControl(a0)
	move.l #(EndCP-MasterControl)+FunctionsLen,d1
	lsr.l #2,d1
	subq.l #1,d1
MoveSon	move.l (a0)+,(a1)+
	dbf d1,MoveSon
	
	sub.l a0,a1
	move.l a1,d2
	move.l d0,a1
	add.l #DATATABLE-MasterControl,a1
	move.l a1,a0
	add.l #FUNCTABLE-DATATABLE,a0
	move.l a0,a2

	add.l d2,(X1-FUNCTABLE)-4(a2)
	add.l d2,(X2-FUNCTABLE)-4(a2)
	move.l #(EndFlag-FUNCTABLE)/4-1,d0
RLoc	add.l d2,(a2)+
	dbf d0,RLoc
	
	sub.l	a2,a2
	moveq.l #124,d0
	moveq.l #0,d1
	jsr _LVOMakeLibrary(a6)	
	tst.l d0
	beq.s NoLib
	
	move.l SonnetBase(pc),a1
	move.l d0,4(a1)					;PowerPCBase at $4
	move.l a5,8(a1)					;Memheader at $8
	move.l a1,(a1)					;Sonnet relocated mem at $0
	move.l d0,PowerPCBase-Buffer(a4)

	move.l d0,a1
	jsr _LVOAddLibrary(a6)
	lea PrcTags(pc),a1
	move.l a1,d1
	move.l DosBase(pc),a6
	jsr _LVOCreateNewProc(a6)
	move.l 4.w,a6
	
NoLib	move.l a5,a1
	jsr _LVORemove(a6)
	move.w #$0a01,8(a5)
	move.l a5,a1
	lea MemList(a6),a0
	jsr _LVOEnqueue(a6)
	jsr _LVOEnable(a6)		

	bra Clean

;********************************************************************************************

Dirty	move.l MediatorBase(pc),a0
	moveq.l #0,d2
	moveq.l #$3f,d1
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

MPC107	move.l #$62B00000,a5
	move.l a5,a1
	lea $100(a5),a5
	
	move.l #$00300064,d5			;EUMB at $64003000
	move.l d5,PCSRBAR(a5)
	move.l COMMAND(a5),d5
	bset #25,d5				;Set PCI Memory bit
	move.l d5,COMMAND(a5)
	
	move.l #$64003000,a3			;EUMB at $64003000
	move.l #$0F00B062,OTWR(a3)		;Host outbound PCI mem at $62B00000, 64kb (Code in GFXMem?)
	move.l #$0000F0FF,OMBAR(a3)		;Processor outbound mem at $FFF00000

	move.l OTWR(a3),d5
	moveq.l #0,d4
	move.l a5,d5
	lea $100(a1),a5
	bra EndDrty


VooDoo3	movem.l d0-a6,-(a7)
	move.l	#$62,d5				;Set BAR Voodoo at $62000000
	move.l d5,$14(a5)
	move.l COMMAND(a5),d5
	bset #25,d5				;Set PCI Memory bit (Voodoo3)
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
	cnop	0,4
	
;********************************************************************************************

MasterControl
	movem.l d0-a6,-(a7)
	lea Buffer(pc),a4
	move.l 4.w,a6
	moveq.l #17,d0					;Start 68k
	jsr _LVOAllocSignal(a6)
	tst.l d0
	bmi.s SigErr
	moveq.l #18,d0					;Start PPC
	jsr _LVOAllocSignal(a6)
	tst.l d0
	bmi.s SigErr
	moveq.l #19,d0					;End 68k
	jsr _LVOAllocSignal(a6)
	tst.l d0
	bmi.s SigErr
	moveq.l #20,d0					;End PPC
	jsr _LVOAllocSignal(a6)
	tst.l d0
	bmi.s SigErr
	
NextMsg	move.l #$60000,d0
	jsr _LVOWait(a6)
	btst #17,d0
	bne.s Msg68k
Don68k	btst #18,d0
	bne.s MsgPPC	
	bra.s NextMsg
	
SigErr	movem.l (a7)+,d0-a6
	rts

Msg68k	move.l #$7c000000,a1
	move.l #"68k!",64(a1)
	bra.s Don68k

MsgPPC	move.l ThisTask(a6),a0
	lea pr_MsgPort(a0),a0
	jsr _LVOGetMsg(a6)
	tst.l d0
	beq.s NextMsg
	move.l d0,a1					;MOVE THIS TO TASKLIST PPC
	jsr _LVOReplyMsg(a6)				;THEN CREATE PPC TASK WITH THESE VALUES
	move.l #$7c000000,a1				;EXIT CODE OF PPC TASK SIGNALS THIS
	move.l #"PPC!",64(a1)				;TASK WITH END PPC SIGNAL
	bra.s NextMsg

	cnop 0,4
	
PrcTags	dc.l NP_Entry,0,NP_Name,0,NP_Priority,125,0,0
PrcName	dc.b "MasterControl",0,0,0

Open	move.l	a6,d0
	tst.l	d0
	beq.s	NoA6
	move.l	d0,a6
	addq.w	#1,LIB_OPENCNT(a6)
	bclr	#3,Buffer
NoA6	rts

Close	moveq.l #0,d0
	subq.w	#1,LIB_OPENCNT(a6)
	bne.s	NoExp
	btst	#3,Buffer
	bne.s	Expunge
NoExp	rts

Expunge	moveq.l #0,d0
	rts
	
Reserved:
	moveq.l #0,d0
	rts
	
GetDriverID:
	move.l #DriverID,d0
	rts

SupportedProtocol:
	moveq.l #1,d0
	rts

InitBootArea:
	movem.l d1-a6,-(a7)
	bsr.s FindSonnet
	addq.l #1,d1
	beq.s Error
	move.l LMBAR(a5),d0
	rol.w #8,d0	
	swap d0
	rol.w #8,d0
	and.b #$f0,d0
	bra.s Error

BootPowerPC:
	movem.l d1-a6,-(a7)
	move.l #"STRT",d5
	bra.s StrtPPC
	
CauseInterruptHW:
	movem.l d1-a6,-(a7)
	move.l #"HEAR",d5
StrtPPC	bsr.s FindSonnet
	addq.l #1,d1
	beq.s Error
	move.l PCSRBAR(a5),d0
	rol.w #8,d0
	swap d0
	rol.w #8,d0
	move.l d0,a0
	move.l d5,IMR0(a0)
Error	nop
	movem.l (a7)+,d1-a6
	nop
	rts

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
	beq Error2
	cmp.l #$57100400,d4
	beq.s xSonnet
	addq.l #1,d2	
	dbf d1,CpxLoop
Error2	move.l d4,d1	
xSonnet	rts

GetCPU	movem.l d1-a6,-(a7)
	move.l SonnetBase(pc),a1
	move.l 12(a1),d0
	and.w #$0,d0
	swap d0
	subq.l #8,d0
	beq.s G3
	subq.l #4,d0
	beq.s G4
	move.l #0,d0
	bra.s ExCPU
G3	move.l #CPUF_G3,d0
	bra.s ExCPU
G4	move.l #CPUF_G4,d0
ExCPU	movem.l (a7)+,d1-a6
	rts

RunPPC	movem.l d1-a6,-(a7)
	lea Buffer(pc),a4
	move.l a0,PStruct-Buffer(a4)
	move.l 4.w,a6
	jsr _LVOCreateMsgPort(a6)
	tst.l d0
	beq Cannot
	move.l d0,Port-Buffer(a4)
	move.l #MN_SIZE+PP_SIZE+64,d0
	move.l #MEMF_PUBLIC|MEMF_CLEAR|MEMF_PPC,d1
	jsr _LVOAllocVec(a6)
	tst.l d0
	beq Cannot
	move.l d0,Msg-Buffer(a4)
	move.l Port(pc),d1
	move.l d0,a1
	move.w #MN_SIZE+PP_SIZE+64,MN_LENGTH(a1)
	move.l d1,MN_REPLYPORT(a1)
	lea MN_LENGTH+2(a1),a2
	move.l #PP_SIZE/4-1,d0
	move.l PStruct(pc),a0
CpMsg	move.l (a0)+,(a2)+
	dbf d0,CpMsg
	move.b #NT_MESSAGE,LN_TYPE(a1)
	move.l ThisTask(a6),a1
	moveq.l #15,d0
	move.l LN_NAME(a1),a1
CpName	move.l (a1)+,(a2)+
	dbf d0,CpName	
	lea PrcName(pc),a1	
	jsr _LVOFindTask(a6)
	move.l d0,d7
	beq.s Cannot
	move.l d0,a0
	lea pr_MsgPort(a0),a0
	move.l Msg(pc),a1
	jsr _LVOPutMsg(a6)
	move.l d7,a1
	move.l #$40000,d0				;Bit 18
	jsr _LVOSignal(a6)	
	move.l Port(pc),a0
	jsr _LVOWaitPort(a6)
	move.l PStruct(pc),a1
	move.l Msg(pc),a0
	lea MN_LENGTH+2(a0),a0
	move.l #PP_SIZE/4-1,d0
CpBck	move.l (a0)+,(a1)+
	dbf d0,CpBck
	moveq.l #0,d7
	bra.s Success

Cannot	moveq.l #-1,d7	
Success	move.l Msg(pc),d0
	beq.s NoMsg
	bsr.s FreeIt
NoMsg	move.l Port(pc),d0
	beq.s EndIt
	bsr.s FreePrt
EndIt	move.l d7,d0
	movem.l (a7)+,d1-a6
	rts
	
FreeIt	move.l d0,a1
	jmp _LVOFreeVec(a6)
FreePrt	move.l d0,a0
	jmp _LVODeleteMsgPort(a6)


WaitForPPC			rts
;;;;;;GetCPU			rts
PowerDebugMode			rts
AllocVec32			rts
FreeVec32			rts
SPrintF68K			rts
AllocXMsg			rts
FreeXMsg			rts
PutXMsg				rts
GetPPCState			rts
SetCache68K			rts
CreatePPCTask			rts
CausePPCInterrupt		rts

Run68K				blr
WaitFor68K			blr
SPrintF				blr
Run68KLowLevel			blr
;;;;;;AllocVecPPC		blr
;;;;;;FreeVecPPC		blr
CreateTaskPPC			blr
DeleteTaskPPC			blr
FindTaskPPC			blr
InitSemaphorePPC		blr
FreeSemaphorePPC		blr
AddSemaphorePPC			blr
RemSemaphorePPC			blr
ObtainSemaphorePPC		blr
AttemptSemaphorePPC		blr
ReleaseSemaphorePPC		blr
FindSemaphorePPC		blr
;;;;;;InsertPPC			blr
;;;;;;AddHeadPPC		blr
;;;;;;AddTailPPC		blr
;;;;;;RemovePPC			blr
;;;;;;RemHeadPPC		blr
;;;;;;RemTailPPC		blr
;;;;;;EnqueuePPC		blr
;;;;;;FindNamePPC		blr
;;;;;;FindTagItemPPC		blr
;;;;;;GetTagDataPPC		blr
;;;;;;NextTagItemPPC		blr
AllocSignalPPC			blr
FreeSignalPPC			blr
SetSignalPPC			blr
SignalPPC			blr
WaitPPC				blr
SetTaskPriPPC			blr
Signal68K			blr
SetCache			blr
SetExcHandler			blr
RemExcHandler			blr
Super				blr
User				blr
SetHardware			blr
ModifyFPExc			blr
WaitTime			blr
ChangeStack			blr
LockTaskList			blr
UnLockTaskList			blr
;;;;;;SetExcMMU			blr
;;;;;;ClearExcMMU		blr	
ChangeMMU			blr
;;;;;;GetInfo			blr
CreateMsgPortPPC		blr
DeleteMsgPortPPC		blr
AddPortPPC			blr
RemPortPPC			blr
FindPortPPC			blr
WaitPortPPC			blr
PutMsgPPC			blr
GetMsgPPC			blr
ReplyMsgPPC			blr
FreeAllMem			blr
CopyMemPPC			blr
AllocXMsgPPC			blr
FreeXMsgPPC			blr
PutXMsgPPC			blr
;;;;;;GetSysTimePPC		blr
;;;;;;AddTimePPC		blr
;;;;;;SubTimePPC		blr
;;;;;;CmpTimePPC		blr
SetReplyPortPPC			blr
SnoopTask			blr
EndSnoopTask			blr
GetHALInfo			blr
SetScheduling			blr
FindTaskByID			blr
SetNiceValue			blr
TrySemaphorePPC			blr
AllocPrivateMem			blr
FreePrivateMem			blr
;;;;;;ResetPPC			blr
;;;;;;NewListPPC		blr
SetExceptPPC			blr
ObtainSemaphoreSharedPPC	blr
AttemptSemaphoreSharedPPC	blr
ProcurePPC			blr
VacatePPC			blr
CauseInterrupt			blr
CreatePoolPPC			blr
DeletePoolPPC			blr
AllocPooledPP			blr
FreePooledPPC			blr
RawDoFmtPPC			blr
PutPublicMsgPPC			blr
AddUniquePortPPC		blr
AddUniqueSemaphorePPC		blr
IsExceptionMode			blr



DriverID
	dc.b "WarpUp hardware driver for Sonnet Crescendo 7200 PCI",0
	cnop	0,2

Buffer		ds.l	1
PowerPCBase	ds.l	1
SonnetBase	ds.l	1
MediatorBase	ds.l	1
DosBase		ds.l	1
ExpBase		ds.l	1
PCIBase		ds.l	1
Port		ds.l 	1
Msg		ds.l 	1
PStruct		ds.l 	1
ROMMem		ds.l	1

DATATABLE:
	INITBYTE	LN_TYPE,NT_LIBRARY
	INITLONG	LN_NAME,LibName
X1	INITBYTE	LIB_FLAGS,LIBF_SUMMING|LIBF_CHANGED
	INITWORD	LIB_VERSION,1
	INITWORD	LIB_REVISION,0
	INITLONG	LIB_IDSTRING,IDString
X2	ds.l	1
	
FUNCTABLE:
	dc.l	Open
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
	
	dc.l	GetDriverID
	dc.l	SupportedProtocol
	dc.l	InitBootArea
	dc.l	BootPowerPC
	dc.l	CauseInterruptHW
	dc.l	ConfirmInterrupt
	
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

	dc.l	Run68K
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
	dc.l	AllocPooledPP
	dc.l	FreePooledPPC
	dc.l	RawDoFmtPPC
	dc.l	PutPublicMsgPPC
	dc.l	AddUniquePortPPC
	dc.l	AddUniqueSemaphorePPC
	dc.l	IsExceptionMode


EndFlag	dc.l	$ffffffff
LibName
	dc.b	"sonnet.library",0,0
IDString
	DC.B	"$VER: sonnet.library 1.0 (19-Feb-15)",0
	cnop	0,4
EndCP	end
	
