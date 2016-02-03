## $VER: warpos_lvo.i V0.0 (19.04.99)
##
## This file is part of the WarpOS debugger 'wosdb'
## Copyright (c) 1999  Frank Wille
##
##
## v0.0  (19.04.99) phx
##       Copied from ppclibemu V0.4, modified CALLWOS macro.
##


## powerpc.library LVOs
.set	RunPPC              ,       -30
.set	WaitForPPC          ,       -36
.set	GetCPU              ,       -42
.set	PowerDebugMode      ,       -48
.set	AllocVec32          ,       -54
.set	FreeVec32           ,       -60
.set	SPrintF68K          ,       -66
.set	AllocXMsg           ,       -72
.set	FreeXMsg            ,       -78
.set	PutXMsg             ,       -84
.set	GetPPCState         ,       -90

.set	Run68K              ,       -300
.set	WaitFor68K          ,       -306
.set	SPrintF             ,       -312
.set	Run68KLowLevel      ,       -318
.set	AllocVecPPC         ,       -324
.set	FreeVecPPC          ,       -330
.set	CreateTaskPPC       ,       -336
.set	DeleteTaskPPC       ,       -342
.set	FindTaskPPC         ,       -348
.set	InitSemaphorePPC    ,       -354
.set	FreeSemaphorePPC    ,       -360
.set	AddSemaphorePPC     ,       -366
.set	RemSemaphorePPC     ,       -372
.set	ObtainSemaphorePPC  ,       -378
.set	AttemptSemaphorePPC ,       -384
.set	ReleaseSemaphorePPC ,       -390
.set	FindSemaphorePPC    ,       -396
.set	InsertPPC           ,       -402
.set	AddHeadPPC          ,       -408
.set	AddTailPPC          ,       -414
.set	RemovePPC           ,       -420
.set	RemHeadPPC          ,       -426
.set	RemTailPPC          ,       -432
.set	EnqueuePPC          ,       -438
.set	FindNamePPC         ,       -444
.set	FindTagItemPPC      ,       -450
.set	GetTagDataPPC       ,       -456
.set	NextTagItemPPC      ,       -462
.set	AllocSignalPPC      ,       -468
.set	FreeSignalPPC       ,       -474
.set	SetSignalPPC        ,       -480
.set	SignalPPC           ,       -486
.set	WaitPPC             ,       -492
.set	SetTaskPriPPC       ,       -498
.set	Signal68K           ,       -504
.set	SetCache            ,       -510
.set	SetExcHandler       ,       -516
.set	RemExcHandler       ,       -522
.set	Super               ,       -528
.set	User                ,       -534
.set	SetHardware         ,       -540
.set	ModifyFPExc         ,       -546
.set	WaitTime            ,       -552
.set	ChangeStack         ,       -558
.set	LockTaskList        ,       -564
.set	UnLockTaskList      ,       -570
.set	SetExcMMU           ,       -576
.set	ClearExcMMU         ,       -582
.set	ChangeMMU           ,       -588
.set	GetInfo             ,       -594
.set	CreateMsgPortPPC    ,       -600
.set	DeleteMsgPortPPC    ,       -606
.set	AddPortPPC          ,       -612
.set	RemPortPPC          ,       -618
.set	FindPortPPC         ,       -624
.set	WaitPortPPC         ,       -630
.set	PutMsgPPC           ,       -636
.set	GetMsgPPC           ,       -642
.set	ReplyMsgPPC         ,       -648
.set	FreeAllMem          ,       -654
.set	CopyMemPPC          ,       -660
.set	AllocXMsgPPC        ,       -666
.set	FreeXMsgPPC         ,       -672
.set	PutXMsgPPC          ,       -678
.set	GetSysTimePPC       ,       -684
.set	AddTimePPC          ,       -690
.set	SubTimePPC          ,       -696
.set	CmpTimePPC          ,       -702
.set	SetReplyPortPPC     ,       -708
.set	SnoopTask           ,       -714
.set	EndSnoopTask        ,       -720
.set	GetHALInfo          ,       -726
.set	SetScheduling       ,       -732
.set	FindTaskByID        ,       -738
.set	SetNiceValue        ,       -744


.macro CALLWOS function, register
	.ifnb \register
		mr r3,\register
	.endif
	lwz r0,\function+2(r3)
	mtlr r0
	blrl
.endm

