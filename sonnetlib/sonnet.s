; IRA V2.08 (26.12.14) (c)1993-95 Tim Ruehsen, (c)2009-2014 Frank Wille

	incdir	include:
	include	lvo/exec_lib.i
	
IMR0		EQU $50
LMBAR		EQU $10
PCSRBAR		EQU $14
OTWR		EQU $308
	
	XREF	ConfirmInterrupt

;********************************************************************************************

	SECTION S_0,CODE

;********************************************************************************************


	MOVEQ	#-1,D0
	RTS
ROMTAG:
	DC.W	$4afc
	DC.L	ROMTAG
	DC.L	ENDSKIP
	DC.L	$80010900
	DC.L	WARPHWLIBNAME
	DC.L	IDSTRING
	DC.L	INIT
INIT:
	DC.L	$00000022
	DC.L	FUNCTABLE
	DC.L	DATATABLE
	DC.L	INITFUNCTION
DATATABLE:
	DC.L	$a0080900
	DC.W	$800a
	DC.L	WARPHWLIBNAME
	DC.L	$a00e0600,$90140001,$90160000
	DC.W	$8018
	DC.L	IDSTRING
	DS.L	1
ENDSKIP:
	DS.W	1
INITFUNCTION:
	MOVE.L	A6,-(A7)
	MOVE.L	A6,D1
	MOVEA.L	D0,A6
	MOVE.L	D1,SECSTRT_2
	MOVE.L	A0,LAB_0029
	CLR.L	LAB_002B
	MOVE.L	A6,-(A7)
	MOVE.L	A7,LAB_002C
	JSR	LAB_0015(PC)
	EXG	D0,D0
	TST.L	LAB_002B
	BNE.W	LAB_0006
	ADDQ.L	#4,A7
	MOVE.L	A6,D0
	MOVEA.L	(A7)+,A6
	RTS
LAB_0006:
	MOVEA.L	(A7),A6
	JSR	LAB_0019(PC)
	EXG	D0,D0
	MOVEQ	#0,D0
	MOVEA.L	A6,A1
	MOVE.W	16(A6),D0
	SUBA.L	D0,A1
	ADD.W	18(A6),D0
	MOVEA.L	SECSTRT_2,A6
	JSR	-210(A6)
	ADDQ.L	#4,A7
	MOVEQ	#0,D0
	MOVEA.L	(A7)+,A6
	RTS

Open	JSR	LAB_0009
	TST.L	D0
	BEQ.W	LAB_0008
	MOVEA.L	D0,A6
	ADDQ.W	#1,32(A6)
	BCLR	#3,LAB_002A
LAB_0008:
	RTS
LAB_0009:
	MOVE.L	A6,D0
	RTS

Close	JSR	LAB_000C
	MOVEQ	#0,D0
	SUBQ.W	#1,32(A6)
	BNE.W	LAB_000B
	BTST	#3,LAB_002A
	BEQ.W	LAB_000B
	JSR	Expunge
LAB_000B:
	RTS
LAB_000C:
	RTS
	nop

Expunge	MOVEM.L	D2,-(A7)
	TST.W	32(A6)
	BEQ.W	LAB_000E
	BSET	#3,LAB_002A
	MOVEQ	#0,D0
	BRA.W	LAB_000F
LAB_000E:
	MOVE.L	LAB_0029,D2
	MOVEA.L	A6,A1
	MOVE.L	A6,-(A7)
	MOVEA.L	SECSTRT_2,A6
	JSR	-252(A6)
	MOVEA.L	(A7)+,A6
	MOVE.L	A6,-(A7)
	JSR	LAB_0019(PC)
	EXG	D0,D0
	ADDQ.L	#4,A7
	MOVEQ	#0,D0
	MOVEA.L	A6,A1
	MOVE.W	16(A6),D0
	SUBA.L	D0,A1
	ADD.W	18(A6),D0
	MOVE.L	A6,-(A7)
	MOVEA.L	SECSTRT_2,A6
	JSR	-210(A6)
	MOVEA.L	(A7)+,A6
	MOVE.L	D2,D0
LAB_000F:
	MOVEM.L	(A7)+,D2
	RTS
	NOP
	
Reserved:
	moveq.l #0,d0
	rts
	
LAB_0011:
	MOVEQ	#0,D0
	BRA.S	LAB_0014
LAB_0012:
	MOVE.L	D0,D1
	ASL.L	#2,D1
	MOVEA.L	#LAB_002F,A1
	MOVE.L	0(A1,D1.L),D1
	CMPI.L	#$ffffffff,D1
	BNE.S	LAB_0013
	MOVE.L	D0,LAB_002E
	RTS
LAB_0013:
	ADDQ.L	#1,D0
LAB_0014:
	BRA.S	LAB_0012
	DS.W	1
LAB_0015:
	MOVEM.L	D2-D3/A6,-(A7)
	MOVEA.L	16(A7),A6
	JSR	LAB_0011
	MOVE.L	LAB_002E,D3
	CLR.L	LAB_002D
	MOVEQ	#0,D2
	BRA.S	LAB_0018
LAB_0016:
	MOVE.L	D2,D0
	ASL.L	#2,D0
	MOVEA.L	#LAB_002F,A1
	TST.L	0(A1,D0.L)
	BEQ.S	LAB_0017
	MOVE.L	D2,D0
	ASL.L	#2,D0
	MOVEA.L	#LAB_002F,A1
	MOVEA.L	0(A1,D0.L),A0
	JSR	(A0)
LAB_0017:
	ADDQ.L	#1,LAB_002D
	ADDQ.L	#1,D2
LAB_0018:
	CMP.L	D3,D2
	BLT.S	LAB_0016
	MOVEM.L	(A7)+,D2-D3/A6
	RTS
LAB_0019:
	MOVEM.L	D2/A6,-(A7)
	MOVEA.L	12(A7),A6
	MOVE.L	LAB_002E,D2
	SUB.L	LAB_002D,D2
	BRA.S	LAB_001C
LAB_001A:
	MOVE.L	D2,D0
	ASL.L	#2,D0
	MOVEA.L	#LAB_0030,A1
	TST.L	0(A1,D0.L)
	BEQ.S	LAB_001B
	MOVE.L	D2,D0
	ASL.L	#2,D0
	MOVEA.L	#LAB_0030,A1
	MOVEA.L	0(A1,D0.L),A0
	JSR	(A0)
LAB_001B:
	ADDQ.L	#1,D2
LAB_001C:
	CMP.L	LAB_002E,D2
	BLT.S	LAB_001A
	MOVEM.L	(A7)+,D2/A6
	RTS
	DS.L	2
	DC.W	$0003

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
	move.l LMBAR(a4),d0
	rol.w #8,d0	
	swap d0
	rol.w #8,d0
	and.b #$f0,d0
	bra.s Error

BootPowerPC:
	movem.l d1-a6,-(a7)
	move.l #"STRT",d5
	bra.s StrtPPC
	
CauseInterrupt:
	movem.l d1-a6,-(a7)
	move.l #"HEAR",d5
StrtPPC	bsr.s FindSonnet
	addq.l #1,d1
	beq.s Error
	move.l PCSRBAR(a4),d0
	rol.w #8,d0
	swap d0
	rol.w #8,d0
	move.l d0,a0
	move.l d5,IMR0(a0)
Error	nop
	move.l 4.w,a6
	jsr _LVOCacheClearU(a6)
	movem.l (a7)+,d1-a6
	nop
	rts

FindSonnet:
	moveq.l #0,d2
	moveq.l #$3f,d1				;Now follow some nasty absolute values
CpLoop	move.l #$40800000,a4
	move.l d2,d0
	lsl.l #3,d0
	lsl.l #8,d0
	add.l d0,a4
	move.l (a4),d4
	cmp.l #$FFFFFFFF,d4
	beq Error2
	cmp.l #$57100400,d4
	beq.s Sonnet
	addq.l #1,d2	
	dbf d1,CpLoop
Error2	move.l d4,d1	
Sonnet	rts

RunPPC				rts
WaitForPPC			rts
GetCPU				rts
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

Run68K				rts
WaitFor68K			rts
SPrintF				rts
Run68KLowLevel			rts
AllocVecPPC			rts
FreeVecPPC			rts
CreateTaskPPC			rts
DeleteTaskPPC			rts
FindTaskPPC			rts
InitSemaphorePPC		rts
FreeSemaphorePPC		rts
AddSemaphorePPC			rts
RemSemaphorePPC			rts
ObtainSemaphorePPC		rts
AttemptSemaphorePPC		rts
ReleaseSemaphorePPC		rts
FindSemaphorePPC		rts
InsertPPC			rts
AddHeadPPC			rts
AddTailPPC			rts
RemovePPC			rts
RemHeadPPC			rts
RemTailPPC			rts
EnqueuePPC			rts
FindNamePPC			rts
FindTagItemPPC			rts
GetTagDataPPC			rts
NextTagItemPPC			rts
AllocSignalPPC			rts
FreeSignalPPC			rts
SetSignalPPC			rts
SignalPPC			rts
WaitPPC				rts
SetTaskPriPPC			rts
Signal68K			rts
SetCache			rts
SetExcHandler			rts
RemExcHandler			rts
Super				rts
User				rts
SetHardware			rts
ModifyFPExc			rts
WaitTime			rts
ChangeStack			rts
LockTaskList			rts
UnLockTaskList			rts
SetExcMMU			rts
ClearExcMMU			rts
ChangeMMU			rts
GetInfo				rts
CreateMsgPortPPC		rts
DeleteMsgPortPPC		rts
AddPortPPC			rts
RemPortPPC			rts
FindPortPPC			rts
WaitPortPPC			rts
PutMsgPPC			rts
GetMsgPPC			rts
ReplyMsgPPC			rts
FreeAllMem			rts
CopyMemPPC			rts
AllocXMsgPPC			rts
FreeXMsgPPC			rts
PutXMsgPPC			rts
GetSysTimePPC			rts
AddTimePPC			rts
SubTimePPC			rts
CmpTimePPC			rts
SetReplyPortPPC			rts
SnoopTask			rts
EndSnoopTask			rts
GetHALInfo			rts
SetScheduling			rts
FindTaskByID			rts
SetNiceValue			rts
TrySemaphorePPC			rts
AllocPrivateMem			rts
FreePrivateMem			rts
ResetPPC			rts
NewListPPC			rts
SetExceptPPC			rts
ObtainSemaphoreSharedPPC	rts
AttemptSemaphoreSharedPPC	rts
ProcurePPC			rts
VacatePPC			rts
CauseInterrupt2			rts
CreatePoolPPC			rts
DeletePoolPPC			rts
AllocPooledPP			rts
FreePooledPPC			rts
RawDoFmtPPC			rts
PutPublicMsgPPC			rts
AddUniquePortPPC		rts
AddUniqueSemaphorePPC		rts
IsExceptionMode			rts



DriverID
	dc.b "WarpUp hardware driver for Sonnet Crescendo 7200 PCI",0
	cnop	0,2

	SECTION S_1,DATA

SECSTRT_2:
	DS.L	1
	dc.l	$000003ef
LAB_0029:
	DS.L	1
LAB_002A:
	DS.L	1
LAB_002B:
	DS.L	1
LAB_002C:
	DS.L	1
LAB_002D:
	DS.L	1
LAB_002E:
	DS.L	1
LAB_002F:
	DS.L	1
	dc.l	$ffffffff
LAB_0030:
	DS.L	1
	dc.l	$ffffffff
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
	dc.l	CauseInterrupt
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
	dc.l	CauseInterrupt2
	dc.l	CreatePoolPPC
	dc.l	DeletePoolPPC
	dc.l	AllocPooledPP
	dc.l	FreePooledPPC
	dc.l	RawDoFmtPPC
	dc.l	PutPublicMsgPPC
	dc.l	AddUniquePortPPC
	dc.l	AddUniqueSemaphorePPC
	dc.l	IsExceptionMode


	dc.l	$ffffffff
WARPHWLIBNAME:
	DC.B	"sonnet.library",0,0
IDSTRING:
	DC.B	"$VER: sonnet.library 1.0 (07-Feb-15)",0
	cnop	0,2
	end
