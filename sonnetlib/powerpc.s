; Copyright (c) 2015-2019 Dennis van der Boon
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

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
	include dos/var.i
	include dos/doshunks.i
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
	XREF	FreeMsgFramePPC,StartSystem
	
	IFD	_IFUSION_
	
	XREF	WarpIllegal
	
	ENDC

	XREF 	PPCCode,PPCLen,MCPort,Init,SysBase,PowerPCBase,DOSBase,sonnet_PosSize,PageTableSize
	XREF	UtilityBase
	XDEF	_PowerPCBase,FunctionsLen,LibFunctions

;********************************************************************************************

	SECTION LibBody,CODE

;********************************************************************************************


		moveq.l #-1,d0
		rts

ROMTAG		dc.w	RTC_MATCHWORD
		dc.l	ROMTAG
		dc.l	ENDSKIP
		dc.b	0					;WAS RTF_AUTOINIT
		dc.b	17					;RT_VERSION
		dc.b	NT_LIBRARY				;RT_TYPE
		dc.b	0					;RT_PRI
		dc.l	PowerName
		dc.l	PowerIDString
		dc.l	LIBINIT

ENDSKIP		ds.w	1

LIBINIT		movem.l d1-a6,-(a7)

		move.l 4.w,a6
		lea Buffer(pc),a4
		move.l a0,(a4)				;SegList
		move.l a6,LExecBase-Buffer(a4)
		move.w AttnFlags(a6),d0
		and.w #AFF_68040|AFF_68060,d0
		bne.s CorrectCPU
		
		lea CPUReqError(pc),a2
		bra PrintError

CorrectCPU	lea MemList(a6),a0
		lea MemName(pc),a1
		jsr _LVOFindName(a6)			;Check for sonnet memory (old sonnet.library)

		tst.l d0
		beq.s NoSonnetLib

		lea PowerPCError(pc),a2
		bra PrintError

NoSonnetLib	lea LibList(a6),a0
		lea PowerName(pc),a1			;Check for WarpOS
		jsr _LVOFindName(a6)

		tst.l d0
		beq.s NoWOS

		lea PowerPCError(pc),a2
		bra PrintError

NoWOS		lea DosLib(pc),a1
		moveq.l #37,d0
		jsr _LVOOpenLibrary(a6)

		move.l d0,DosBase-Buffer(a4)
		tst.l d0
		bne GotDOS				;Open dos.library

		lea LDOSError(pc),a2
		bra PrintError

GotDOS		lea utillib(pc),a1
		moveq.l #0,d0
		jsr _LVOOpenLibrary(a6)
		move.l d0,UtilBase-Buffer(a4)

		moveq.l #PCI_VERSION,d0			;Minimal version of pci.library
		lea pcilib(pc),a1
		jsr _LVOOpenLibrary(a6)

		move.l d0,PCIBase-Buffer(a4)
		tst.l d0
		bne.s FndPCI
		
		lea LPCIError(pc),a2
		bra PrintError

FndPCI		lea ExpLib(pc),a1
		moveq.l #37,d0
		jsr _LVOOpenLibrary(a6)			;Open expansion.library

		move.l d0,ExpBase-Buffer(a4)
		tst.l d0
		bne.s GotExp

		lea LExpError(pc),a2
		bra PrintError		

GotExp		move.l d0,a6
		sub.l a0,a0
		move.l #VENDOR_ELBOX,d0			;ELBOX
		moveq.l #MEDIATOR_MKII,d1		;Mediator MKII
		jsr _LVOFindConfigDev(a6)		;Find A3000/A4000 mediator
		tst.l d0
		bne.s FoundMed
		
		sub.l a0,a0
		move.l #VENDOR_ELBOX,d0			;ELBOX
		moveq.l #MEDIATOR_MKIII,d1		;Mediator MKIII
		jsr _LVOFindConfigDev(a6)		;Find A3000/A4000 mediator
		tst.l d0
		bne.s FoundMed

		sub.l a0,a0
		move.l #VENDOR_ELBOX,d0			;ELBOX
		moveq.l #MEDIATOR_1200TX,d1		;Mediator 1200TX
		jsr _LVOFindConfigDev(a6)		;Find 1200TX mediator
		tst.l d0
		bne.s FoundMed1200

WeirdMed	lea MedError(pc),a2
		bra PrintError

FoundMed1200	sub.l a0,a0
		move.l #VENDOR_ELBOX,d0			;ELBOX
		moveq.l #MEDIATOR_1200LOGIC,d1		;Mediator Logic stuff for A1200
		jsr _LVOFindConfigDev(a6)
		move.l LExecBase(pc),a6
		tst.l d0
		beq.s WeirdMed
				
		move.l PCIBase(pc),a1
		move.w LIB_REVISION(a1),d0
		cmp.w #MIN_SUB_VERSION,d0
		bge.s CorrectRev

		lea LPCIError(pc),a2
		bra PrintError
		
CorrectRev	move.l d0,MediatorType-Buffer(a4)
		bra.s TestForMPC107

FoundMed	sub.l a0,a0
		move.l #VENDOR_ELBOX,d0			;ELBOX
		move.l #MEDIATOR_LOGIC,d1		;Mediator Logic board for A3/4000
		jsr _LVOFindConfigDev(a6)
		tst.l d0
		bne.s GotCorrMed
		
		sub.l a0,a0
		move.l #VENDOR_ELBOX,d0			;ELBOX
		move.l #MEDIATOR_LOGICIII,d1		;Mediator Logic board MKIII for A3/4000
		jsr _LVOFindConfigDev(a6)
		tst.l d0
		beq.s WeirdMed

GotCorrMed	move.l d0,a1
		move.l cd_BoardSize(a1),d0		;Start address Configspace Mediator
		cmp.l #$20000000,d0
		beq TestForMPC107			;WindowSize 512MB?

		lea MedWindowJ(pc),a2
		bra PrintError

TestForMPC107	moveq.l #MAX_PCI_SLOTS-1,d6
		move.l PCIBase(pc),a6

NextCard	move.l d6,d0
		lsl.l #3,d0
		moveq.l #PCI_OFFSET_ID,d1
		jsr _LVOPCIConfigReadLong(a6)
		cmp.l #-1,d0
		beq.s NoCard

		lea CardList(pc),a2
LoopCard	move.l (a2)+,d1
		beq.s NoCard
		
		cmp.l d1,d0
		beq FoundCfg				;Find ConfigDev number of PPC card
		bra.s LoopCard
		
NoCard		dbf d6,NextCard

NoCardError	lea NBridgeError(pc),a2
		bra PrintError	
		
CardList	dc.l DEVICE_MPC107<<16|VENDOR_MOTOROLA,DEVICE_HARRIER<<16|VENDOR_MOTOROLA
		dc.l DEVICE_MPC8343E<<16|VENDOR_FREESCALE,DEVICE_HAWK<<16|VENDOR_MOTOROLA,0
		
FoundCfg	lsl.l #3,d6
		move.l d6,ConfigDevNum-Buffer(a4)	;Number of the PPC card.
		bra.s AllCorrect

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

AllCorrect	move.l PCIBase(pc),d0
		bra.s CheckVGA
		
CheckATI	move.w #VENDOR_ATI,d0
		move.w d0,d5
		moveq.l #0,d2
		jmp _LVOPCIFindCard(a6)			;Check for ATI 92xx	

CheckVGA	move.l d0,a6
		lea PPCPCIS(pc),a2
LoopPPCList	move.w (a2)+,d0
		beq.s EndOfPPCList
		
		move.w (a2)+,d1
		moveq.l #0,d2
		jsr _LVOPCIFindCard(a6)			;Check for PPC card
		move.l d0,d6
		bne.s GotPPCCard
		bra.s LoopPPCList

EndOfPPCList	lea PPCCardError(pc),a2
		bra PrintError
		
PPCPCIS		dc.w VENDOR_MOTOROLA,DEVICE_MPC107,VENDOR_MOTOROLA,DEVICE_HARRIER,VENDOR_FREESCALE
		dc.w DEVICE_MPC8343E,VENDOR_MOTOROLA,DEVICE_HAWK,0
		
		cnop 0,4

GotPPCCard	move.w #VENDOR_3DFX,d0
		move.w d0,d5
		move.w #DEVICE_VOODOO45,d1
		moveq.l #0,d2
		jsr _LVOPCIFindCard(a6)			;Check for Voodoo4/5
		tst.l d0		
		beq.s Nxt3DFX
		move.l d0,a2
		addq.l #1,d5
Use3DFX		move.l PCI_SPACE0(a2),d4
		move.l PCI_SPACELEN0(a2),d7
		lsl.l #1,d7
		bra.s FoundGfx
	
Nxt3DFX		move.w #VENDOR_3DFX,d0
		move.w d0,d5
		move.w #DEVICE_VOODOO3,d1		;Check for Voodoo3
		moveq.l #0,d2
		jsr _LVOPCIFindCard(a6)
		tst.l d0		
		beq.s Not3DFX
		move.l d0,a2
		bra.s Use3DFX
			
Not3DFX		lea ATIs(pc),a3
NextATI		move.l (a3)+,d1
		beq.s NoATI
		
		bsr CheckATI
		tst.l d0
		bne.s GotATI
		bra.s NextATI
		
NoATI		lea VGAError(pc),a2
		bra PrintError

ATIs		dc.l	DEVICE_RV280PRO,DEVICE_RV280_1,DEVICE_RV280_2,DEVICE_RV280MOB,DEVICE_RV280SE,0		

GotATI		move.l d0,a2
		move.l PCI_SPACE2(a2),d4
		move.l d4,GfxConfig-Buffer(a4)
		move.l PCI_SPACE0(a2),d4
		move.l PCI_SPACELEN0(a2),d7

FoundGfx	and.w #$fff0,d7				;remove bits like PREFETCH.
		neg.l d7
		move.l d4,GfxMem-Buffer(a4)
		move.w d5,GfxType-Buffer(a4)
		move.l d6,SonAddr-Buffer(a4)
		move.l d7,GfxLen-Buffer(a4)
		move.l MediatorType(pc),d0
		beq.s NoNegMemAddr

		btst #31,d4
		beq.s NoNegMemAddr

		lea NoPPCPCI(pc),a2
		bra PrintError

NoNegMemAddr	bsr GetENVs

		moveq.l #0,d6
				
DoItAgain	move.l LExecBase(pc),a6
		lea MemList(a6),a0
		lea PCIMem(pc),a1			;Check for PCI DMA (GFX) memory
		jsr _LVOFindName(a6)
		move.l d0,d7
		beq EndItHere

		move.l d7,a2
		move.l (a2),a1
		tst.l (a1)
		beq.s EndItHere

		move.l MH_LOWER(a2),d0
		move.l MH_UPPER(a2),d1
		sub.l d0,d1

		move.l #$1000000,d3
		move.l #$ff000000,d4
		moveq.l #-1,d2				;0 = no BAT, 1 = 64MB, 2 = 128MB, 3 = 256MB, 4 = 512MB
Next		lsl.l #1,d3
		lsl.l #1,d4
		addq.l #1,d2
		and.l d4,d0
		cmp.l d3,d1
		bcs.s GotBATSize
		bne.s Next

GotBATSize	move.l d2,d1
		beq.s NotSupported
		subq.l #4,d1
		bpl.s NotSupported
		cmp.w #VENDOR_ATI,GfxType(pc)
		beq.s NotSupported
		
		moveq.l #-15,d3
		move.l d0,StartBAT-Buffer(a4)
		move.l d2,SizeBAT-Buffer(a4)
		bra.s MemSupported

NotSupported	moveq.l #-20,d3
MemSupported	move.b d3,LN_PRI(a2)
		jsr _LVODisable(a6)
		move.l d7,a1
		jsr _LVORemove(a6)
		lea MemList(a6),a0
		move.l d7,a1
		jsr _LVOEnqueue(a6)			;Move gfx memory to back to prevent
		jsr _LVOEnable(a6)			;mem list corruption if BE screenmode switch

		tst.l d6
		bne.s EndItHere
		moveq.l #1,d6
		bra DoItAgain
		
EndItHere	move.l SonAddr(pc),a2
		cmp.w #DEVICE_HARRIER,PCI_DEVICEID(a2)
		beq SetupHarrier

		cmp.w #DEVICE_MPC8343E,PCI_DEVICEID(a2)
		beq SetupKiller

		tst.l d7
		bne.s FndDMAMem

		move.l GfxMem(pc),d0
		bne.s DirtyPCIMem

		lea MemVGAError(pc),a2			;use a FORCE flag? debugdebug
		bra PrintError

FndDMAMem	move.l #$20000,d0
		move.l #MEMF_PUBLIC|MEMF_PPC,d1
		jsr _LVOAllocVec(a6)
		move.l d0,ROMMem-Buffer(a4)
		tst.l d0				;Allocate fake ROM in VGA Mem
		bne.s GotVGAMem

		lea MemVGAError(pc),a2
		bra PrintError

DirtyPCIMem	add.l #$600000,d0			;My eyes hurt! Startup using unallocated VGA Memory

GotVGAMem	add.l #$10000,d0
		and.w #0,d0				;Align ROM on $10000

		cmp.w #DEVICE_HAWK,PCI_DEVICEID(a2)
		beq SetupHawk

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

		move.l #$48002f00,d6
		move.l d6,(a5)				;PPC branch to code outside exception space (0x3000)
		move.l (a5),d0
		cmp.l d6,d0				;Should be cache inhibited for this to work
		beq.s WritableMem

		lea MemVGAError(pc),a2			;use a FORCE flag? debugdebug
		bra PrintError
		
WritableMem	lea $2f00(a5),a5
		lea PPCCode(pc),a2
		move.l #PPCLen,d6
		lsr.l #2,d6
		subq.l #1,d6

loop2		move.l (a2)+,(a5)+			;Copy code to 0x3000
		dbf d6,loop2

		move.l #$abcdabcd,BASE_CODEWORD(a1)	;Code Word
		move.l #$abcdabcd,BASE_MEM(a1)		;Sonnet Mem Start (Translated to PCI)
		move.l #$abcdabcd,BASE_MEMLEN(a1)	;Sonnet Mem Len
		move.l GfxMem(pc),BASE_GFXMEM(a1)
		move.l GfxLen(pc),BASE_GFXLEN(a1)
		move.l GfxType(pc),BASE_GFXTYPE(a1)
		move.l GfxConfig(pc),BASE_GFXCONFIG(a1)
		move.l ENVOptions(pc),BASE_ENV1(a1)
		move.l ENVOptions+4(pc),BASE_ENV2(a1)
		move.l ENVOptions+8(pc),BASE_ENV3(a1)	;No extra VGA memory for MPC107 (not enough mapping windows)
		move.l a1,-(a7)
		
		jsr _LVOCacheClearU(a6)

		move.l PCIBase(pc),a6
		move.l ConfigDevNum(pc),d0
		moveq.l #PCI_OFFSET_COMMAND,d1
		jsr _LVOPCIConfigReadWord(a6)

		move.l d0,d2
		or.w #BUS_MASTER_ENABLE,d2
		move.l ConfigDevNum(pc),d0
		moveq.l #PCI_OFFSET_COMMAND,d1
		jsr _LVOPCIConfigWriteWord(a6)		;Start MPC107. Does not work on Sonnet.

		move.l LExecBase(pc),a6
		move.l (a7)+,a1			
		move.l #WP_TRIG01,WP_CONTROL(a3)	;Negate HRESET. Now code gets executed
							;at 0xfff00100 which jumps to 0xfff03000
							;Only available on Sonnet
ReturnInitPPC	move.l	#$EC0000,d7			;Simple Time-out timer

Wait		subq.l #1,d7
		beq.s TimeOut
		move.l BASE_CODEWORD(a1),d5
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
		move.l BASE_MEM(a1),d5
		move.l d5,SonnetBase-Buffer(a4)
		move.l d5,a0
		move.l PageTableSize(a0),d3
		add.l d7,d5
		move.l BASE_MEMLEN(a1),d6
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

		move.l a0,a1				;Set up PPC memory on 68k side:
		move.l d5,a0
		move.w #$0a01,LN_TYPE(a0)		;TYPE and PRI
		move.l a1,LN_NAME(a0)
		move.w #MEMF_PUBLIC|MEMF_FAST|MEMF_PPC,14(a0)
		lea MH_SIZE(a0),a1
		move.l a1,MH_FIRST(a0)
		clr.l (a1)

		move.l d6,d1
		sub.l #32,d1
		sub.l d3,d1				;for pagetable
		move.l d1,MC_BYTES(a1)
		move.l a1,MH_LOWER(a0)
		add.l a0,d6
		sub.l d3,d6				;for pagetable
		move.l d6,MH_UPPER(a0)
		move.l d1,MH_FREE(a0)
		move.l a0,a1
		move.l a0,a5

		jsr _LVODisable(a6)
		lea MemList(a6),a0
		move.l SonAddr(pc),a2
		
		cmp.w #DEVICE_MPC107,PCI_DEVICEID(a2)
		bne.s SkipCorrection
		
		sub.l #NoMemAccess,d5			;Should fix it to be the same as Harrier/Killer
		move.l d5,PCI_SPACE0(a2)
		moveq.l #0,d6
		sub.l d7,d6
		move.l d6,PCI_SPACELEN0(a2)		;Correct MemSpace0 in the PCI database
SkipCorrection	jsr _LVOEnqueue(a6)			;Add the memory node

		lea POWERDATATABLE(pc),a2
		bsr MakeLibrary
		move.l d0,_PowerPCBase-Buffer(a4)
		tst.l d0
		bne.s GotLibMade

NotLibMade	jsr _LVOEnable(a6)
		lea LSetupError(pc),a2
		bra PrintError

GotLibMade	

		move.l SonnetBase(pc),a1
		move.l d0,PowerPCBase(a1)
		move.l a5,PPCMemHeader(a1)		;Memheader at $8
		move.l a1,(a1)				;Sonnet relocated mem at $0
		move.l a6,SysBase(a1)
		move.l DosBase(pc),DOSBase(a1)
		move.l UtilBase(pc),UtilityBase(a1)

		move.l d0,a1
		addq.w #1,LIB_OPENCNT(a1)		;Prevent closure and all kinds of problems
		jsr _LVOAddLibrary(a6)
		
		move.l _PowerPCBase(pc),a0
		move.l LExecBase(pc),PPC_SYSLIB(a0)
		move.l DosBase(pc),PPC_DOSLIB(a0)

		lea WARPFUNCTABLE(pc),a0		;Set up a fake warp.library
		lea WARPDATATABLE(pc),a1		;Some programs do a version
		sub.l a2,a2				;check on this
		moveq.l #124,d0
		moveq.l #0,d1
		jsr _LVOMakeLibrary(a6)
		
		tst.l d0
		bne.s GotWarp
		
		lea NoWarpLibError(pc),a2
		bra PrintError
		
GotWarp		move.l d0,a1
		jsr _LVOAddLibrary(a6)

		move.l #$4000,d0
		moveq.l #0,d1
		jsr _LVOAllocVec(a6)			;No Error code yet
		tst.l d0
		bne.s GotBuffMem
	
		lea GenMemError(pc),a2
		bra PrintError
		
GotBuffMem	move.l d0,FIFOBuffer-Buffer(a4)
		lea MyInterrupt(pc),a1
		lea SonInt(pc),a2
		move.b Options68K+1(pc),d0
		beq.s GotMyInt
		
		lea SonInt1200(pc),a2
GotMyInt	move.l a2,IS_CODE(a1)
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
		jsr _LVOPCIAddIntServer(a6)		;Attach PPC card to PCI Interrupt Chain

		move.l SonAddr(pc),a0
		jsr _LVOPCIEnableInterupt(a6)		;Enable interrupt

		lea PrcTags(pc),a1
		move.l a1,d1
		move.l DosBase(pc),a6
		jsr _LVOCreateNewProc(a6)		;Start up Master Control
							;It will start phase 2 of PPC setup
		move.l d0,d7

		move.l LExecBase(pc),a6
		jsr _LVOEnable(a6)

		tst.l d7
		bne.s PPCInit

		lea MasterError(pc),a2
		bra PrintError

PPCInit		move.l	#$EC0000,d7			;Simple Time-out timer		
DoTimer		subq.l #1,d7
		bne.s ContTimer

		lea PPCCrash(pc),a2
		bra PrintError
		
ContTimer	move.l SonnetBase(pc),a1
		move.l Init(a1),d0
		cmp.l #"REDY",d0			;Phase 2 of PPC setup completed?
		bne.s DoTimer

		move.l SonAddr(pc),a2
		cmp.w #DEVICE_HARRIER,PCI_DEVICEID(a2)
		beq.s NoOutBound107
		cmp.w #DEVICE_MPC8343E,PCI_DEVICEID(a2)
		beq.s NoOutBound107

		move.l GfxMem(pc),d0			;Amiga PCI Memory
		move.l PCI_SPACE1(a2),a3		;PCSRBAR Sonnet
		or.b #28,d0				;512MB
		rol.w #8,d0
		swap d0
		rol.w #8,d0
		and.b #$fe,d0
		move.l d0,OTWR(a3)			;0x40000000 or 0x60000000
		add.b #$60,d0
		move.l d0,OMBAR(a3)			;0xa0000000 - 0xc0000000
		
NoOutBound107	jsr _LVODisable(a6)

		moveq.l #MEMF_PUBLIC,d1
		move.l #$4000,d2
		moveq.l #0,d3
		
		bsr ChangeStack68K			;Enlarge RamLib stack
		
		move.l #_LVOLoadSeg,a0			;Set system patches
		lea NewOldLoadSeg(pc),a3
		move.l a3,d0
		move.l DosBase(pc),a1
		jsr _LVOSetFunction(a6)			;LoadSeg to correctly scatter-load WarpOS exes
		lea LoadSegAddress(pc),a3
		move.l d0,(a3)
		
		move.l #_LVONewLoadSeg,a0
		lea NewNewLoadSeg(pc),a3
		move.l a3,d0
		move.l DosBase(pc),a1
		jsr _LVOSetFunction(a6)			;NewLoadSeg to correctly scatter-load WarpOS exes
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
		
		move.l #_LVOAllocMem,a0
		lea NewAlloc(pc),a3
		move.l a3,d0
		move.l a6,a1
		jsr _LVOSetFunction(a6)			;To force memory allocations to MEMF_PPC
		lea AllocMemAddress(pc),a3
		move.l d0,(a3)

		move.b Options68K+2(pc),d0
		beq NoStackPatch

		move.l #_LVOCreateProc,a0
		lea CP1200(pc),a3
		move.l a3,d0
		move.l DosBase(pc),a1
		jsr _LVOSetFunction(a6)			;To force memory allocations to MEMF_PPC
		lea CPAddress(pc),a3
		move.l d0,(a3)		
		
		move.l #_LVOCreateNewProc,a0
		lea CNP1200(pc),a3
		move.l a3,d0
		move.l DosBase(pc),a1
		jsr _LVOSetFunction(a6)			;To force memory allocations to MEMF_PPC
		lea CNPAddress(pc),a3
		move.l d0,(a3)		
		
		move.l #_LVORunCommand,a0
		lea RC1200(pc),a3
		move.l a3,d0
		move.l DosBase(pc),a1
		jsr _LVOSetFunction(a6)			;To force memory allocations to MEMF_PPC
		lea RCAddress(pc),a3
		move.l d0,(a3)		
		
		move.l #_LVOSystemTagList,a0
		lea STL1200(pc),a3
		move.l a3,d0
		move.l DosBase(pc),a1
		jsr _LVOSetFunction(a6)			;To force memory allocations to MEMF_PPC
		lea STLAddress(pc),a3
		move.l d0,(a3)
		
NoStackPatch	jsr _LVOCacheClearU(a6)

		lea MirrorList(pc),a3			;Make a list for PPC Mirror Tasks
		move.l a3,LH_TAILPRED(a3)
		addq.l #4,a3
		clr.l (a3)
		move.l a3,-(a3)

		jsr _LVOEnable(a6)

		move.l SonAddr(pc),a2
		cmp.w #DEVICE_MPC8343E,PCI_DEVICEID(a2)
		bne NoZen

		lea ZenInterrupt(pc),a1
		lea ZenInt(pc),a2
		move.l a2,IS_CODE(a1)
		lea ZenIntData(pc),a2
		move.l a2,IS_DATA(a1)
		lea ZenIntName(pc),a2
		move.l a2,LN_NAME(a1)
		move.b #-50,LN_PRI(a1)
		move.b #NT_INTERRUPT,LN_TYPE(a1)
		moveq.l #INTB_VERTB,d0
		jsr _LVOAddIntServer(a6)

NoZen		move.l _PowerPCBase(pc),a6
		move.l _LVOStartSystem+2(a6),a1
		addq.l #4,a1
		lea KrytenTags(pc),a0

		move.l a1,4(a0)
		addq.l #4,a1
		move.l a1,12(a0)
		move.l a6,20(a0)
		bsr CreatePPCTask
		
		tst.l d0
		bne.s GotPPCControl
		
		lea PPCTaskError(pc),a2
		bra PrintError

GotPPCControl	move.l LExecBase(pc),a6
		moveq.l #46,d0
		lea ppclib(pc),a1
		jsr _LVOOpenLibrary(a6)			;Open ppc.library for LoadSeg() patch

		tst.l d0
		beq Clean

		move.l d0,a2
		move.w LIB_REVISION(a2),d0
		cmp.w #41,d0				;everything before 46.41 is probably P5. 
		bge Clean
		
		lea WrongPPCLib(pc),a2
		bra PrintError

;********************************************************************************************

SetupHarrier	movem.l d0-a0/a2-a6,-(a7)
		move.l PCIBase(pc),a6

		move.l ConfigDevNum(pc),d0
		moveq.l #PCI_OFFSET_COMMAND,d1
		jsr _LVOPCIConfigReadWord(a6)

		move.l d0,d2
		or.w #MEMORY_SPACE_ENABLE,d2
		move.l ConfigDevNum(pc),d0
		moveq.l #PCI_OFFSET_COMMAND,d1
		jsr _LVOPCIConfigWriteWord(a6)		;Enable Read/Write to PCI space

		move.l ConfigDevNum(pc),d0
		moveq.l #PCFS_MPAT,d1	
		jsr _LVOPCIConfigReadLong(a6)		;Read PCFS_MPAT

		move.l d0,d2
		or.l #PCFS_MPAT_GBL|PCFS_MPAT_ENA,d2	;Enables PCSF_MPBAR for reading/writing
		move.l ConfigDevNum(pc),d0
		moveq.l #PCFS_MPAT,d1
		jsr _LVOPCIConfigWriteLong(a6)		;Write PCFS_MPAT

		move.l #$00f0ffff,d0			;Set 4K PCI Memory (swapped and negged)
		moveq.l #0,d1				;Dummy bar 0
		move.l SonAddr(pc),a0
		jsr _LVOPCIAllocMem(a6)			;Get space for PMEP

		move.l d0,d2
		beq PCIMemErr

		move.l d2,PMEPAddr-Buffer(a4)
		move.l ConfigDevNum(pc),d0
		moveq.l #PCFS_MBAR,d1
		jsr _LVOPCIConfigWriteLong(a6)		;Set PCFS_MPBAR to location of PMEP (ie I2O etc)

		move.l ConfigDevNum(pc),d0
		moveq.l #PCFS_ITAT0,d1
		jsr _LVOPCIConfigReadLong(a6)		;Read PCFS_ITAT0 (Address Translation)

		move.l d0,d2
		or.l #PCFS_ITAT0_GBL|PCFS_ITAT0_ENA,d2		;Enable PCFS_ITAT0 for reading/writing
								;and enable snooping of transactions
		move.l ConfigDevNum(pc),d0
		moveq.l #PCFS_ITAT0,d1
		jsr _LVOPCIConfigWriteLong(a6)		;Write PCFS_ITAT0

		move.l ConfigDevNum(pc),d0
		moveq.l #PCFS_ITAT1,d1
		jsr _LVOPCIConfigReadLong(a6)		;Read PCFS_ITAT1 (Another address translation unit)

		move.l d0,d2
		or.l #PCFS_ITAT1_GBL|PCFS_ITAT1_ENA|PCFS_ITAT1_WPE|PCFS_ITAT1_RAE,d2

		move.l ConfigDevNum(pc),d0
		moveq.l #PCFS_ITAT1,d1
		jsr _LVOPCIConfigWriteLong(a6)		;Enable PCFS_ITAT1, Snooping, Write-Post and Read-Ahead

		move.l #$00f0ffff,d0			;Set 4K PCI Memory (swapped and negged)
		moveq.l #1,d1				;Dummy bar 1
		move.l SonAddr(pc),a0
		jsr _LVOPCIAllocMem(a6)			;Get space for XCSR

		move.l d0,d2
		beq PCIMemErr

		move.l d2,XCSRAddr-Buffer(a4)
		move.l ConfigDevNum(pc),d0
		moveq.l #PCFS_ITBAR0,d1
		jsr _LVOPCIConfigWriteLong(a6)		;Set PCFS_ITBAR0 with inbound PCI address (XCSR)

		move.l #PPC_XCSR_BASE|PCFS_ITSZ_4K,d2
		move.l ConfigDevNum(pc),d0
		moveq.l #PCFS_ITOFSZ0,d1		;Relocate to PCI XCSRAddr
		jsr _LVOPCIConfigWriteLong(a6)		;Set size & offset for inbound PCI address

		move.l XCSRAddr(pc),a3
		move.l #XCSR_XPAT_BAM_ENA|XCSR_XPAT_AD_DELAY15,d2
		move.l d2,XCSR_XPAT0(a3)				;Clear XCSR_XPAT0_REN/WEN
		move.l d2,XCSR_XPAT1(a3)				;And XPAT1 to disable on-board ROM startup
		move.l d2,XCSR_XPAT2(a3)
		move.l d2,XCSR_XPAT3(a3)				;Let's just do them all..
		
		move.l XCSR_SDBAA(a3),d6
		move.l XCSR_BXCS(a3),d2
		and.l #XCSR_SDBA_SIZE,d6
		btst #XCSR_BXCS_BP0H,d2
		bne.s NoReset

		bset #XCSR_BXCS_BP0H,d2			;Reset Processor 0 when already running.
		move.l d2,XCSR_BXCS(a3)

NoReset		move.l #$20000000,d0
		move.l MediatorType(pc),d1
		bne.s AllocPCI1200
		
		cmp.l #XCSR_SDBA_16M8,d6
		beq.s Is128
		
		tst.l d6
		bne.s Is256
		
		move.b Options68K+3(pc),d0
		bne.s Is2562
		or.l #XCSR_SDBA_16M8,XCSR_SDBAA(a3)
		bra.s Is128
			
Is2562		or.l #XCSR_SDBA_32M8,XCSR_SDBAA(a3)				
Is256		move.l #$000000f0,d0			;Set 256MB PCI Memory (swapped and negged)
		moveq.l #2,d1				;Dummy bar 2
		move.l SonAddr(pc),a0
		jsr _LVOPCIAllocMem(a6)			;Get space for PPC RAM

AllocPCI1200	move.l #PPC_RAM_BASE|PCFS_ITSZ_256MB,d4
		move.l #$10000000,d7
		move.l d0,d2
		bne.s AtLeast256

Is128		move.l #$000000f8,d0
		moveq.l #2,d1
		move.l SonAddr(pc),a0
		jsr _LVOPCIAllocMem(a6)

		move.l #PPC_RAM_BASE|PCFS_ITSZ_128MB,d4
		move.l #$08000000,d7
		move.l d0,d2		
		beq PCIMemErr
		
		moveq.l #0,d5
		cmp.l #XCSR_SDBA_16M8,d6
		beq PCIMemHar
		
		tst.l d6
		bne.s NoIs128
		
		move.b Options68K+3(pc),d0
		beq PCIMemHar
		
NoIs128		move.l #$000000fc,d0			;Try to squeeze out an extra 64MB
		moveq.l #4,d1
		move.l SonAddr(pc),a0		
		jsr _LVOPCIAllocMem(a6)
		move.l d0,d5
		beq PCIMemHar
		
		move.l #$04000000,d0
		bra Do192

AtLeast256	move.l MediatorType(pc),d0
		bne.s PCIMemHar				;No 512MB on Amiga 1200.

		cmp.l #XCSR_SDBA_64M8,d6
		bne.s PCIMemHar

		move.l #$000000f8,d0			;add more mem for 512MB cards.
		moveq.l #4,d1
		move.l SonAddr(pc),a0		
		jsr _LVOPCIAllocMem(a6)

		move.l d0,d5
		beq.s PCIMemHar

		move.l #$08000000,d0			;add 128mb extra RAM.
Do192		move.l d5,d3
		add.l d0,d3
		cmp.l d3,d2
		beq.s ConsecutiveMem			;Memory is one block. Otherwise failure.

		moveq.l #0,d5
		bra.s PCIMemHar

ConsecutiveMem	add.l d0,d7
		add.l d0,d4
		move.l d5,SonnetBase-Buffer(a4)
		bra.s SkipBase

PCIMemHar	move.l d2,SonnetBase-Buffer(a4)
SkipBase	move.l ConfigDevNum(pc),d0
		moveq.l #PCFS_ITBAR1,d1
		jsr _LVOPCIConfigWriteLong(a6)		;Set PCFS_ITBAR1 with inbound PCI address (PPC RAM)

		move.l d4,d2
		btst #28,d7
		bne.s Got256MB

		btst #26,d7
		bne.s Got256MB				;Not named correctly...

		move.l #PPC_RAM_BASE|PCFS_ITSZ_128MB,d2
Got256MB	move.l ConfigDevNum(pc),d0
		moveq.l #PCFS_ITOFSZ1,d1
		jsr _LVOPCIConfigWriteLong(a6)		;Set size & offset for RAM ($0 256MB)

		tst.l d5
		beq.s NoMoreMem

		move.l ConfigDevNum(pc),d0
		moveq.l #PCFS_ITAT2,d1
		jsr _LVOPCIConfigReadLong(a6)		;Read PCFS_ITAT1 (Another address translation unit)

		move.l d0,d2
		or.l #PCFS_ITAT1_GBL|PCFS_ITAT1_ENA|PCFS_ITAT1_WPE|PCFS_ITAT1_RAE,d2

		move.l ConfigDevNum(pc),d0
		moveq.l #PCFS_ITAT2,d1
		jsr _LVOPCIConfigWriteLong(a6)		;Enable PCFS_ITAT2, Snooping, Write-Post and Read-Ahead

		move.l SonnetBase(pc),d2
		move.l ConfigDevNum(pc),d0
		moveq.l #PCFS_ITBAR2,d1
		jsr _LVOPCIConfigWriteLong(a6)		;Set PCFS_ITBAR1 with inbound PCI address (PPC RAM)

		move.l #PPC_RAM_BASE|PCFS_ITSZ_64MB,d2
		btst #26,d7
		bne.s AddOnly64
		
		move.l #PPC_RAM_BASE|PCFS_ITSZ_128MB,d2
AddOnly64	move.l ConfigDevNum(pc),d0
		moveq.l #PCFS_ITOFSZ2,d1
		jsr _LVOPCIConfigWriteLong(a6)		;Set size & offset for RAM ($0 64MB or 128MB)

NoMoreMem	move.l #$0000fcff,d0					;Set 256kb PCI Memory (swapped and negged)
		moveq.l #3,d1						;Dummy bar 3
		move.l SonAddr(pc),a0
		jsr _LVOPCIAllocMem(a6)					;Get space for PPC MPIC (Just a dummy, not accessable)

		move.l d0,d2
		beq PCIMemErr

		move.l d2,MPICAddr-Buffer(a4)
		or.l #XCSR_MBAR_ENA,d2
		move.l d2,XCSR_MBAR(a3)					;Set location of MPIC (256kb boundary) plus MBAR_ENA

		moveq.l #0,d0
		moveq.l #0,d2
		moveq.l #0,d3

		move.l PCIBase(pc),a1
		move.w pcibase_MemWindow(a1),d0				;setup mapping of mediator PCI window
		move.w #$2000,d3					;512MB
		move.l MediatorType(pc),d4
		beq.s BigBox1

		move.w #$3000,d0					;Fixed for A1200
		move.w #$1000,d3					;256MB

BigBox1		sub.w #$6000,d2						;Calculate offset
		move.l d0,d1
		add.w #$6000,d1	
		move.l d1,d0
		swap d1
		add.w d3,d0
		or.w d0,d1				
		swap d2
		or.b #XCSR_OTAT_ENA|XCSR_OTAT_WPE|XCSR_OTAT_SGE|XCSR_OTAT_RAE|XCSR_OTAT_MEM,d2
		move.l d2,XCSR_OTAT0(a3)
		move.l d1,XCSR_OTAD0(a3)
		move.l #XCSR_SDGC_ENRV_ENA,d3
		tst.l d6
		bne.s SkipRamSettings

		or.l #XCSR_SDGC_MXRR_7,d3
		move.l #XCSR_SDTC_DEFAULT,XCSR_SDTC(a3)			;Set RAM settings.
		move.l #XCSR_SDBA_16M8,XCSR_SDBAA(a3)			;Set SDRAM bank A to 16Mx8 / 128MBytes as default
		move.b Options68K+3(pc),d2
		beq.s SkipRamSettings

		move.l #XCSR_SDBA_32M8,XCSR_SDBAA(a3)			;Set SDRAM bank A to 32Mx8 / 256MBytes as alternative

SkipRamSettings	move.l XCSR_SDBAA(a3),d2
		or.l #XCSR_SDBA_ENA,d2
		move.l d2,XCSR_SDBAA(a3)
		move.l XCSR_SDGC(a3),d2					;Read General Control Register SDGC
		or.l d3,d2						;Set MXRR to required Refresh Rate
		move.l d2,XCSR_SDGC(a3)					;and remap using ENRV from $fff00000 to $0
		move.w #XCSR_XARB_PRKCPU0|XCSR_XARB_ENA,XCSR_XARB(a3)	;Set external arbiter to park on CPU 0.
		move.l a3,a4

		move.l SonnetBase(pc),a3
		lea $10000(a3),a1
		lea $3000(a1),a5
		move.l #$48012f00,$100(a3)				;Start vector PPC

		lea PPCCode(pc),a2
		move.l #PPCLen,d6
		lsr.l #2,d6
		subq.l #1,d6
loopHarrier	move.l (a2)+,(a5)+					;Copy code to 0x13000
		dbf d6,loopHarrier

		move.l #$abcdabcd,BASE_CODEWORD(a1)			;Code Word
		
		move.l XCSR_SDBAA(a4),d6
		and.l #XCSR_SDBA_SIZE,d6
		cmp.l #XCSR_SDBA_16M8,d6
		beq.s NoMemWrap

		move.l a1,a2
		add.l #$8000000,a2
		cmp.l #$abcdabcd,BASE_CODEWORD(a2)
		bne.s NoMemWrap 
		
		move.l XCSR_SDBAA(a4),d6
		and.l #~XCSR_SDBA_SIZE,d6
		or.l #XCSR_SDBA_16M8,d6
		move.l d6,XCSR_SDBAA(a4)
		
		movem.l (a7)+,d0-a0/a2-a6
		lea MemWrapError(pc),a2
		bra PrintError		
		
NoMemWrap	move.l GfxMem(pc),BASE_GFXMEM(a1)
		move.l GfxLen(pc),BASE_GFXLEN(a1)		
		move.l GfxType(pc),BASE_GFXTYPE(a1)
		move.l GfxConfig(pc),BASE_GFXCONFIG(a1)
		move.l ENVOptions(pc),BASE_ENV1(a1)
		move.l ENVOptions+4(pc),BASE_ENV2(a1)
		move.l ENVOptions+8(pc),BASE_ENV3(a1)
		move.l a1,-(a7)

		move.l SonnetBase(pc),BASE_MEM(a1)
		move.l d7,BASE_MEMLEN(a1)				;Set available memory.
		move.l MPICAddr,BASE_XPMI(a1)				;XPMI (MPIC)
		move.l StartBAT(pc),BASE_STARTBAT(a1)
		move.l SizeBAT(pc),BASE_SIZEBAT(a1)

		move.l LExecBase(pc),a6
		jsr _LVOCacheClearU(a6)

		move.l XCSRAddr(pc),a3
		move.l XCSR_BXCS(a3),d2
		bclr #XCSR_BXCS_BP0H,d2					;Clear Processor 0 Hold off and start running PPC
		move.l d2,XCSR_BXCS(a3)

		move.l PMEPAddr(pc),a3
		moveq.l #0,d2
		move.l d2,PMEP_MIMS(a3)					;Clear OPIM to generate PCI interrupts

		move.l (a7)+,a1
		movem.l (a7)+,d0-a0/a2-a6	

		bra ReturnInitPPC

;*********************************************************

PCIMemErr	movem.l (a7)+,d0-a0/a2-a6
		lea PCIMemError(pc),a2
		bra PrintError

;********************************************************************************************

SetupKiller	movem.l d0-a0/a2-a6,-(a7)
		move.l PCIBase(pc),a6

		move.l ConfigDevNum(pc),d0
		moveq.l #PCI_OFFSET_COMMAND,d1
		jsr _LVOPCIConfigReadWord(a6)

		move.l d0,d2
		or.w #BUS_MASTER_ENABLE,d2
		move.l ConfigDevNum(pc),d0
		moveq.l #PCI_OFFSET_COMMAND,d1
		jsr _LVOPCIConfigWriteWord(a6)		;Enable Read/Write to PCI space

		move.l #$20000000,d0
		move.l MediatorType(pc),d1
		bne.s AllocKil1200

		move.l #$000000fc,d0			;Set 64MB PCI Memory (swapped and negged)
		moveq.l #1,d1				;Dummy bar 1
		move.l SonAddr(pc),a0
		jsr _LVOPCIAllocMem(a6)			;Get space for Killer Memory

AllocKil1200	move.l d0,d2
		beq PCIMemErr

		move.l d2,SonnetBase-Buffer(a4)		;Set base
		move.l #$04000000,d7			;and length default Killer NIC memory (64MB)

		move.l SonAddr(pc),a2
		move.l PCI_SPACE0(a2),a3		;Get config block

		moveq.l #12,d1
		lsr.l d1,d2
		move.l d2,IMMR_PIBAR0(a3)		;Set PCI memory base
		move.l #$0,d0				;Set local memory base
		move.l d0,IMMR_PITAR0(a3)
		move.l #PIWAR_EN|PIWAR_PF|PIWAR_RTT_SNOOP|PIWAR_WTT_SNOOP|PIWAR_IWS_64MB,d1
		move.l d1,IMMR_PIWAR0(a3)		;Set attributes of inbound window

		moveq.l #0,d1
		move.l d1,IMMR_POCMR0(a3)
		move.l d1,IMMR_POCMR1(a3)		;Disable all windows
		move.l d1,IMMR_POCMR2(a3)
		move.l d1,IMMR_POCMR3(a3)
		move.l d1,IMMR_POCMR4(a3)
		move.l d1,IMMR_POCMR5(a3)

		moveq.l #12,d1				;Set-up of outbound window to PCI space of gfx cards
		move.l GfxMem(pc),d2
		move.l PCIBase(pc),a2
		move.l pcibase_MemWindow(a2),d3

		btst #25,d2
		beq.s NoOdd64

		move.l d2,d0
		bclr #25,d2

NoOdd64		move.l #LAWAR_EN|LAWAR_512MB,d5
		move.l MediatorType(pc),d4
		beq.s BigBox2

		move.l #$30000000,d3
		move.l #LAWAR_EN|LAWAR_256MB,d5

BigBox2		add.l #$60000000,d3
		move.l d3,IMMR_PCILAWBAR1(a3)

		btst #25,d0
		bne.s DefaultSizeW

		move.l GfxLen(pc),d4
		move.l #POCMR_EN|POCMR_CM_256MB,d6
		btst.l #28,d4
		bne.s DoWindow1

		move.l #POCMR_EN|POCMR_CM_64MB,d6
		btst.l #26,d4
		bne.s DoWindow1

DefaultSizeW	move.l #POCMR_EN|POCMR_CM_128MB,d6	;default
		
DoWindow1	move.l d5,IMMR_PCILAWAR1(a3)
		btst #27,d4
		beq.s No128ATI

		btst #27,d2
		beq.s No128ATI
		
		add.l d4,d3
No128ATI	lsr.l d1,d2
		lsr.l d1,d3
		move.l d3,IMMR_POBAR0(a3)
		move.l d2,IMMR_POTAR0(a3)		
		move.l d6,IMMR_POCMR0(a3)

		move.l GfxConfig(pc),d2
		beq.s NoATIConfig
		
		move.l d2,d3				;make Radeon config block available to PPC
		add.l #$60000000,d3
		move.l #POCMR_EN|POCMR_CM_64KB,d6
		lsr.l d1,d2
		lsr.l d1,d3
		move.l d3,IMMR_POBAR2(a3)
		move.l d2,IMMR_POTAR2(a3)		
		move.l d6,IMMR_POCMR2(a3)

NoATIConfig	move.l SizeBAT(pc),d4
		beq.s NoSecWin

DoSecWin	move.l StartBAT(pc),d2
		move.l d2,d3
		add.l #$60000000,d3

		move.l #POCMR_EN|POCMR_CM_256MB,d6
		btst.l #28,d4
		bne.s DoWindow2

		move.l #POCMR_EN|POCMR_CM_64MB,d6
		btst.l #26,d4
		bne.s DoWindow2

		move.l #POCMR_EN|POCMR_CM_128MB,d6	;default

DoWindow2	lsr.l d1,d2
		lsr.l d1,d3

		move.l d3,IMMR_POBAR1(a3)
		move.l d2,IMMR_POTAR1(a3)		
		move.l d6,IMMR_POCMR1(a3)

NoSecWin	move.l SonnetBase(pc),a2
		move.l #$48000000,$fc(a2)		;This is a loop in PPC assembly
		move.l #$4bfffffc,$100(a2)		;Going to park the CPU

		move.l LExecBase(pc),a6

		bsr ResetCPU

		lea $10000(a2),a1
		lea $3000(a1),a5
		move.l #$48012f00,$100(a2)		;Start vector PPC with a jump in PPC assembly

		move.l #IMMR_ADDR_DEFAULT,IMMR_IMMRBAR(a3)

		lea PPCCode(pc),a2
		move.l #PPCLen,d6
		lsr.l #2,d6
		subq.l #1,d6
loopKiller	move.l (a2)+,(a5)+			;Copy code to 0x13000
		dbf d6,loopKiller

		move.l #$abcdabcd,BASE_CODEWORD(a1)	;Code Word
		move.l SonnetBase(pc),BASE_MEM(a1)
		move.l d7,BASE_MEMLEN(a1)
		move.l GfxMem(pc),BASE_GFXMEM(a1)
		move.l GfxLen(pc),BASE_GFXLEN(a1)		
		move.l GfxType(pc),BASE_GFXTYPE(a1)
		move.l GfxConfig(pc),BASE_GFXCONFIG(a1)
		move.l ENVOptions(pc),BASE_ENV1(a1)
		move.l ENVOptions+4(pc),BASE_ENV2(a1)
		move.l ENVOptions+8(pc),BASE_ENV3(a1)
		move.l StartBAT(pc),BASE_STARTBAT(a1)
		move.l SizeBAT(pc),BASE_SIZEBAT(a1)

		bsr ResetCPU

		move.l #SIMSR_L_MU,IMMR_SIMSR_L(a3)	;Enable Message Units Interrupts on the PPC
		
		movem.l (a7)+,d0-a0/a2-a6
		
		bra ReturnInitPPC

;******************************************************

ResetCPU	move.l a1,-(a7)
		jsr _LVOCacheClearU(a6)
		move.l (a7)+,a1

		move.l SonnetBase(pc),a2
		move.l #"RSTE",IMMR_RPR(a3)
		move.l IMMR_RCER(a3),d1
		move.l d1,IMMR_RCR(a3)			;Reset the PowerPC CPU (SOFT)

		move.l #$10000,d0
WaitReset	subq.l #1,d0
		bne.s WaitReset				;Dirty Ass Wait Loop.....
		
		moveq.l #0,d2
		move.l d2,$1f0(a2)
		move.l IMMR_RSR(a3),d1
		move.l d1,IMMR_RSR(a3)			;Clear reset status
		rts

;********************************************************************************************

SetupHawk	movem.l d0-a0/a2-a6,-(a7)
		move.l PCIBase(pc),a6
		move.l d0,d5				;VGA 'ROM'
		move.l d0,a5
		move.l #$48012f00,d6			;Start vector PPC
		move.l d6,$100(a5)			;PPC branch to code outside exception space (0x3000)
		move.l $100(a5),d0
		cmp.l d6,d0				;Should be cache inhibited for this to work
		beq.s WritableVMem

		lea MemVGAError(pc),a2			;use a FORCE flag? debugdebug
		bra PrintError

WritableVMem	move.l #$0000f0ff,d0			;Set 1MB PCI Memory (negged and swapped)
		moveq.l #0,d1				;Dummy bar 0 (Really dummy, not linked to BAR0)
		move.l SonAddr(pc),a0			;It will hold PHB, SMC and external reg set
		jsr _LVOPCIAllocMem(a6)			;Get space for Killer Memory

		move.l d0,d2				;Should be 1MB aligned (pci.lib takes care of it)
		beq PCIMemErr

		move.l d0,d6				;For offset
		swap d2
		add.w #$10,d2				;Size = 1MB
		or.l d6,d2

		move.l ConfigDevNum(pc),d0
		move.l #HAWK_PCI_PSADD0,d1
		jsr _LVOPCIConfigWriteLong(a6)

		move.l ConfigDevNum(pc),d0
		move.l #HAWK_PCI_PSOFFATT0,d1
		move.l #HAWK_SMC_BASE,d2			
		sub.l d6,d2
		or.l #$d2,d2
		jsr _LVOPCIConfigWriteLong(a6)

		move.l d6,a2
		cmp.l #VENDOR_MOTOROLA<<16|DEVICE_HAWK,(a2)
		bne CardSetupErr

		moveq.l #0,d0					;Total RAM
		moveq.l #0,d2
		move.l HAWK_SMC_RAMENSZ_1(a2),d1
		bne.s TestMem

StartTest2	move.l HAWK_SMC_RAMENSZ_2(a2),d1
		beq.s EndMemTest

TestMem2	moveq.l #1,d2

TestMem		moveq.l #3,d3
NextBank	rol.l #8,d1
		btst #HAWM_SMC_RAMX_ENA,d1
		beq.s NotEnabledBank

		bclr #HAWM_SMC_RAMX_ENA,d1
		lea MemSizes(pc),a1
LoopSizes	move.l (a1)+,d7
		beq.s NotEnabledBank

		move.l (a1)+,d4
		cmp.b d7,d1
		bne.s LoopSizes

		add.l d4,d0		
NotEnabledBank	dbf d3,NextBank

		tst.l d2
		beq.s StartTest2

EndMemTest	move.l d0,d7
		beq NoMemError

		neg.l d0
		rol.w #8,d0
		swap d0
		rol.w #8,d0

		moveq.l #2,d1				;Dummy bar 2 (Really dummy, not linked to BAR2)
		move.l SonAddr(pc),a0
		jsr _LVOPCIAllocMem(a6)			;Get space for Hawk Memory

		move.l d0,d2
		beq PCIMemErr 

		move.l d0,SonnetBase-Buffer(a4)
		add.l d7,d2
		swap d2
		add.l d0,d2

		move.l ConfigDevNum(pc),d0
		move.l #HAWK_PCI_PSADD1,d1
		jsr _LVOPCIConfigWriteLong(a6)

		move.l SonnetBase(pc),d0		
		move.l #HAWK_RAM_BASE,d2
		sub.l d0,d2
		add.l #$d2,d2
		move.l ConfigDevNum(pc),d0
		move.l #HAWK_PCI_PSOFFATT1,d1
		jsr _LVOPCIConfigWriteLong(a6)

		move.l ConfigDevNum(pc),d0
		move.l #HAWK_PCI_MMBAR,d1
		jsr _LVOPCIConfigReadLong(a6)

		move.l d0,a4					;MPIC
		move.l #HAWK_MPIC_PROCINIT_P0|HAWK_MPIC_PROCINIT_P1,d0
		move.l d0,HAWK_MPIC_PROCINIT(a4)		;Hold CPU in reset

		move.l HAWK_SMC_ROMA(a2),d0
		or.b #HAWK_SMC_ROMA_RV,d0
		eor.b #HAWK_SMC_ROMA_RV,d0			;turn off Flash A being Boot ROM
		move.l d0,HAWK_SMC_ROMA(a2)

		move.l a2,a3
		add.l #HAWM_SMCPHB_OFFSET,a3			;PHB
		move.l #$fff0fff1,HAWK_PHB_XSADD0(a3)		;Reset vector range $fff00000-$fff10000

		move.l #$fff00000,d0				;point reset vector table to our own VGA 'ROM'
		sub.l d5,d0
		add.l #$d2,d0
		move.l d0,HAWK_PHB_XSOFFATT0(a3)

		move.l d5,a3
		lea $10000(a3),a1
		lea $3000(a1),a5

		lea PPCCode(pc),a2
		move.l #PPCLen,d6
		lsr.l #2,d6
		subq.l #1,d6
loopHawk	move.l (a2)+,(a5)+					;Copy code to 0x13000
		dbf d6,loopHawk

		move.l #$abcdabcd,BASE_CODEWORD(a1)			;Code Word
		move.l GfxMem(pc),BASE_GFXMEM(a1)
		move.l GfxLen(pc),BASE_GFXLEN(a1)		
		move.l GfxType(pc),BASE_GFXTYPE(a1)
		move.l GfxConfig(pc),BASE_GFXCONFIG(a1)
		move.l ENVOptions(pc),BASE_ENV1(a1)
		move.l ENVOptions+4(pc),BASE_ENV2(a1)
		move.l ENVOptions+8(pc),BASE_ENV3(a1)
		move.l a1,-(a7)

		move.l SonnetBase(pc),BASE_MEM(a1)
		move.l d7,BASE_MEMLEN(a1)				;Set available memory.
		move.l MPICAddr,BASE_XPMI(a1)				;XPMI (MPIC)
		move.l StartBAT(pc),BASE_STARTBAT(a1)
		move.l SizeBAT(pc),BASE_SIZEBAT(a1)

		move.l LExecBase(pc),a6
		jsr _LVOCacheClearU(a6)

		moveq.l #0,d0
		move.l d0,HAWK_MPIC_PROCINIT(a4)			;Negate reset state
		move.l (a7)+,a1

		movem.l (a7)+,d0-a0/a2-a6

		bra ReturnInitPPC

;*********************************************************

NoMemError	movem.l (a7)+,d0-a0/a2-a6
		lea SonnetMemError(pc),a2
		bra PrintError

;*********************************************************

CardSetupErr	movem.l (a7)+,d0-a0/a2-a6
		lea CardStateError(pc),a2
		bra PrintError

;*********************************************************

MemSizes	dc.l 1,$02000000,2,$04000000,3,$04000000,4,$08000000,5,$08000000
		dc.l 6,$08000000,7,$10000000,8,$10000000,9,$20000000,0,0

;********************************************************************************************

PrintError	bsr.s PrintError2
		moveq.l #0,d0
		move.l d0,_PowerPCBase-Buffer(a4)
		bra Clean

PrintError2	move.l LExecBase(pc),a6			;Put up a requester and give out
		lea IntuitionLib(pc),a1			;an error message
		moveq.l #33,d0
		jsr _LVOOpenLibrary(a6)
		tst.l d0
		bne.s DoPrErr
		move.l #$84010000,d7			;Halt the system
		jmp _LVOAlert(a6)

DoPrErr		move.l d0,a6
		lea PowerName(pc),a0
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
		jmp _LVOCloseLibrary(a6)
		
;********************************************************************************************

MakeLibrary
		movem.l d1-a6,-(a7)			;Sets up library base and function table		
		move.l #FunctionsLen,d0
		move.l #MEMF_PUBLIC|MEMF_PPC|MEMF_REVERSE|MEMF_CLEAR,d1
		bsr AllocVec32				;Reserve space for the function table
		tst.l d0				;to be copied to PPC memory
		beq NoFun
		
		move.l d0,PPCCodeMem-Buffer(a4)
		move.l d0,a1
		lea LibFunctions,a0			;debugdebug Made this non-PC relative
		move.l #FunctionsLen,d1
		lsr.l #2,d1
		subq.l #1,d1
MoveSon		move.l (a0)+,(a1)+
		dbf d1,MoveSon				;Do the copy to PPC memory		
		
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

GetENVs		move.l DosBase(pc),a6
		lea ENVOptions(pc),a5
		lea EnEDOMem(pc),a1
		bsr DoENV
		bmi.s NoEDOMem
		move.b (a3),(a5)
NoEDOMem	lea EnDebug(pc),a1
		bsr DoENV
		bmi.s NoEnDebug
		move.b (a3),1(a5)
NoEnDebug	lea EnAlignExc(pc),a1
		bsr DoENV
		bmi.s NoEnAlignExc
		move.b (a3),2(a5)
NoEnAlignExc	lea DisL2Cache(pc),a1
		bsr DoENV
		bmi.s NoDisL2Cache
		move.b (a3),3(a5)
NoDisL2Cache	lea DisL2Flush(pc),a1
		bsr DoENV
		bmi.s NoDisL2Flush
		move.b (a3),4(a5)
NoDisL2Flush	lea EnPageSetup(pc),a1
		bsr DoENV
		bmi.s NoEnPageSetup
		move.b (a3),5(a5)
NoEnPageSetup	lea EnDAccessExc(pc),a1
		bsr DoENV
		bmi.s NoEnDAccessExc
		move.b (a3),6(a5)
NoEnDAccessExc	lea SetCMemDiv(pc),a1
		bsr DoENV
		bmi.s NoSetCMemDiv
		move.b (a3),7(a5)
NoSetCMemDiv	move.l SonAddr(pc),a3
		move.b PCI_REVISION(a3),11(a5)		;Check for Sonnet or Nortel (12 or 13)
		lea DisHunkPatch(pc),a1
		bsr DoENV
		lea Options68K(pc),a5
		bmi.s NoDisHunkPatch
		move.b (a3),(a5)
NoDisHunkPatch	lea SetCPUComm(pc),a1
		bsr DoENV
		moveq.l #1,d2
		move.l MediatorType(pc),d1
		beq.s DoneCPUComm
		move.b d2,(a3)
DoneCPUComm	move.b (a3),1(a5)
		lea EnStackPatch(pc),a1
		bsr DoENV
		moveq.l #1,d2
		move.l MediatorType(pc),d1
		beq.s DoneStackP
		move.b d2,(a3)
DoneStackP	move.b (a3),2(a5)
		lea HarMem(pc),a1
		bsr DoENV
		bmi.s NoHarMem
		move.b (a3),3(a5)
NoHarMem	rts

;*********************************************

DoENV		move.l a1,d1
		lea ENVBuff(pc),a1
		move.l a1,a3
		move.b #0,(a3)
		move.l a1,d2
		moveq.l #4,d3
		move.l #GVF_GLOBAL_ONLY,d4
		jsr _LVOGetVar(a6)
		tst.l d0
		bpl.s GotENV
		move.b #0,(a3)
GotENV		and.b #$07,(a3)
		tst.l d0
		rts

;********************************************************************************************

IntuitionLib	dc.b "intuition.library",0
DosLib		dc.b "dos.library",0
ExpLib		dc.b "expansion.library",0
pcilib		dc.b "pci.library",0
ppclib		dc.b "ppc.library",0
utillib		dc.b "utility.library",0
MemName		dc.b "ppc memory",0
PCIMem		dc.b "pcidma memory",0
IntName		dc.b "Gort",0
ZenIntName	dc.b "Zen",0
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
		lea MasterControlPort(pc),a0
		move.l d0,(a0)
		move.l d6,Init(a4)			;Start phase 2 of PPC setup
		move.l d0,d6				;which moves it from fff00000 to 00000000
		jsr _LVOCacheClearU(a6)			;and sets up all the exception handlers
		
		move.b Options68K+1(pc),d0
		bne NextMsg1200

NextMsg		move.l d6,a0
		jsr _LVOWaitPort(a6)			;we wait for messages from our 68k interrupt
		
GetLoop		move.l d6,a0
		jsr _LVOGetMsg(a6)

		move.l d0,d7
		bne.s CheckMsg
		
		move.l d6,a0
		clr.l MP_MSGLIST+MLH_TAIL(a0)		;SoftCinema bug/quirk?
		bra.s NextMsg
							
CheckMsg	move.l ThisTask(a6),a1
		bset #TB_PPC,TC_FLAGS(a1)
		move.l d0,a1	
		move.b LN_TYPE(a1),d0
		cmp.b #NT_REPLYMSG,d0
		bne.s NoXReply
	
		move.l LN_NAME(a1),d0
		bne MsgRXMSG
		
		lea IllegalMsg(pc),a2
		bsr PrintError2
		bra.s GetLoop
		
NoXReply	move.l MN_IDENTIFIER(a1),d0
		cmp.l #"T68K",d0			;Message to 68K
		beq MsgMir68
		cmp.l #"LL68",d0			;Low level message to 68K
		beq MsgLL68
		cmp.l #"FREE",d0			;Async FreeMem/FreeVec() call. Not implemented in ppcfunctions.p
		beq MsgFree
		cmp.l #"DBG!",d0			;Print debug info
		beq PrintDebug
		cmp.l #"DBG2",d0			;Print debug info
		beq PrintDebug2
		cmp.l #"CRSH",d0			;Print WarpOS like crash window
		beq Crashed
		bra.s GetLoop

;********************************************************************************************
;********************************************************************************************

NextMsg1200	move.l d6,a0
		moveq.l #0,d0
		move.l d0,d1
		move.b MP_SIGBIT(a0),d1
		bset d1,d0
		jsr _LVOWait(a6)			;we wait for messages from our 68k interrupt	

GetLoop1200	move.l d6,a0
		jsr _LVOGetMsg(a6)

		move.l d0,d7
		bne CheckMsg1200
		
		jsr _LVODisable(a6)

CheckFIFO	move.l ThisTask(a6),a2
		bset #TB_PPC,TC_FLAGS(a2)
		move.w FIFORead(pc),d0
		move.w FIFOWrite(pc),d1
		cmp.w d1,d0
		beq.s EmptyFIFO		
		
		move.l FIFOBuffer(pc),a2
		move.l (0,a2,d0.w*4),a1
		addq.w #1,d0
		and.w #$fff,d0
		lea FIFORead(pc),a2
		move.w d0,(a2)
		
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
		beq StoreD
		move.l a1,d0
		bra.s CheckMsg1200

EmptyFIFO	jsr _LVOEnable(a6)

		move.l d6,a0
		clr.l MP_MSGLIST+MLH_TAIL(a0)		;SoftCinema bug/quirk?
		bra NextMsg1200
							
CheckMsg1200	move.l d0,a1	
		move.b LN_TYPE(a1),d0
		cmp.b #NT_REPLYMSG,d0
		bne.s NoXReply1200
	
		move.l LN_NAME(a1),d0
		bne.s MsgRXMSG
		
		lea IllegalMsg(pc),a2
		bsr PrintError2
		bra GetLoop1200
		
NoXReply1200	move.l MN_IDENTIFIER(a1),d0
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
		bra GetLoop1200

ReturnLoop	move.b Options68K+1(pc),d0
		bne GetLoop1200
		bra GetLoop

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
		bra ReturnLoop

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

		bra ReturnLoop

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
		bra ReturnLoop
		
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
CopyPPCName	move.b (a0)+,d0
		move.b d0,(a2)+
		dbf d2,CopyPPCName

		move.l #"_68K",(a2)+			;add _68K to PPC mirror task name
		clr.b (a2)
		move.l d1,d2
		move.l ThisTask(a6),a1
		bclr #TB_PPC,TC_FLAGS(a1)		
		move.l DosBase(pc),a6
		lea Prc2Tags(pc),a1
		move.l a7,12(a1)
		move.l a1,d1
		jsr _LVOCreateNewProc(a6)		;start the process

		add.l d2,a7
		move.l (a7)+,a1
		move.l LExecBase(pc),a6
		move.l ThisTask(a6),a0
		bset #TB_PPC,TC_FLAGS(a0)
		tst.l d0
		beq.s MsgMir68
		move.l d0,a0
		move.l MN_ARG1(a1),TC_SIGALLOC(a0)	;set up the allocated signals
		lea pr_MsgPort(a0),a0
		jsr _LVOPutMsg(a6)

		bra ReturnLoop

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
		bra ReturnLoop
		
;********************************************************************************************		
;********************************************************************************************

MirrorTask	move.l LExecBase(pc),a6			;Mirror task for PPC task
		move.l ThisTask(a6),a3			;set up by MsgMir68

		lea pr_MsgPort(a3),a0
		move.l a0,d6
		jsr _LVOWaitPort(a6)

		bclr #TB_PPC,TC_FLAGS(a3)

		jsr _LVOCreateMsgPort(a6)		;Make a seperate msgport to prevent
		
		bset #TB_PPC,TC_FLAGS(a3)

		tst.l d0				;DOS packet gurus
		bne GotMirMsgPort

		lea GenMemError(pc),a2
		bsr PrintError2

HaltMirror	bra.s HaltMirror	
		
GotMirMsgPort	move.l d0,-(a7)
		
CleanUp		move.l d6,a0
		jsr _LVOGetMsg(a6)			;Make sure the original msgport is empty
		tst.l d0
		beq.s SetUpStuff
		
		move.l d0,a1
		move.l (a7),a0
		jsr _LVOPutMsg(a6)
		bra.s CleanUp

SetUpStuff	move.l (a7),a0
		move.b MP_SIGBIT(a0),d1
		moveq.l #0,d5
		bset d1,d5
		move.l d5,d6
		add.w #$fff,d6
		not.l d6

GoWaitPort	move.l (a7),a0
		move.l ThisTask(a6),a1
		
		move.l TC_SIGALLOC(a1),d0
		and.l #$fffff000,d0			;Do not act on system signals except the CTRL ones

		jsr _LVOWait(a6)

		move.l d0,d1
		and.l d5,d0
		bne.s ResetSigs1
		
		and.l d6,d1
		beq.s GoWaitPort

		bsr CrossSignals			;If other signals are detected than the

		bra.s GoWaitPort
				
ResetSigs1	and.l d6,d1
		move.l ThisTask(a6),a0
		or.l d1,TC_SIGRECVD(a0)			;Reset 68k signals that were negated by the Wait()
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

PrcTags		dc.l NP_Entry,MasterControl,NP_Name,PrcName,NP_Priority,1,NP_StackSize,$20000,TAG_END
PrcName		dc.b "MasterControl",0

		cnop 0,4
		
Prc2Tags	dc.l NP_Entry,MirrorTask,NP_Name,Prc2Name,NP_Priority,0,NP_StackSize,$20000,TAG_END
Prc2Name	dc.b "Joshua",0

		cnop 0,4

KrytenTags	dc.l TASKATTR_CODE,0,TASKATTR_NAME,0,TASKATTR_R3,0,TASKATTR_SYSTEM,-1,TAG_END

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
		bne.s GiveError
	
		lea PPCCrashNoWin(pc),a2
		bsr PrintError2
		bra.s SkipToEnd
		
GiveError	lea CrashMessage(pc),a0
		move.l a0,d2		
		move.l SonnetBase(pc),a0
		move.l a0,d3
		add.l #FIFO_BASE+$100,d3
		move.l d3,a5				;value of PPC register r0 is at offset 76
		tst.l (a5)
		bne.s NotKernelPanic
		
		lea KernelPanic(pc),a2
		move.l a2,(a5)
		
NotKernelPanic	jsr _LVOVFPrintf(a6)

		move.l 76(a5),d0
		lea PPCErrSem(pc),a2
		cmp.l #"ESEM",d0
		beq.s OutputErrWin

		lea PPCErrFifo(pc),a2
		cmp.l #"EFIF",d0
		beq.s OutputErrWin

		lea PPCErrAsync(pc),a2
		cmp.l #"ESNC",d0
		beq.s OutputErrWin

		lea PPCErrMem(pc),a2
		cmp.l #"EMEM",d0		
		beq.s OutputErrWin
		
		lea PPCErrorTimeOut(pc),a2
		cmp.l #"ETIM",d0
		beq.s OutputErrWin
		
		bra.s SkipToEnd
		
OutputErrWin	bsr PrintError2
		
SkipToEnd	movem.l (a7)+,d0-a6
		bra NextMsg

;********************************************************************************************

SonInt:		movem.l d1-a6,-(a7)			;68K interrupt which distributes

		move.l LExecBase(pc),a6			;messages send by the PPC
		moveq.l #0,d5
ReChek		move.l SonAddr(pc),a2

		cmp.w #DEVICE_MPC8343E,PCI_DEVICEID(a2)
		beq.s IntK

		cmp.w #DEVICE_HARRIER,PCI_DEVICEID(a2)
		bne NoIntH

		move.l PMEPAddr(pc),a2
		move.l PMEP_MIST(a2),d3
		beq DidInt
		bra.s NxtMsg

IntK		move.l PCI_SPACE0(a2),a2		;Get config block
		move.l IMMR_OMISR(a2),d3
		and.l #IMMR_OMISR_OM0I,d3
		beq DidInt
		move.l #IMMR_OMISR_OM0I,IMMR_OMISR(a2)	;Ack Interrupt
		bra.s NxtMsg

NoIntH		move.l EUMBAddr(pc),a2
		move.l OMISR(a2),d3
		and.l #OPQI,d3
		beq DidInt

NxtMsg		bsr GetMsgFrame
		move.l a1,d3
		cmp.l #-1,d3
		beq ReChek
		moveq.l #-1,d5

		moveq.l #11,d4
		bsr.s InvMsg				;PCI memory is cache inhibited for 68k?
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
		beq StoreD		
		
CommandMaster	move.l MN_MCPORT(a1),a0
		jsr _LVOPutMsg(a6)
		bra NxtMsgLoop

DidInt		move.l d5,d0
		movem.l (a7)+,d1-a6
		tst.l d0				;Clear Z flag if server handled interrupt
		rts					;Set Z flag if we did not handle interrupt

InvMsg		cinvl dc,(a1)				;040+
		lea L1_CACHE_LINE_SIZE_040(a1),a1	;Cache_Line 040/060 = 16 bytes
		dbf d4,InvMsg				;12x16 = MsgLen (192 bytes)
		rts

IntData		dc.l 0

;********************************************************************************************

SonInt1200:	movem.l d1-a6,-(a7)			;68K interrupt which distributes

		moveq.l #0,d5				;messages send by the PPC
		move.l LExecBase(pc),a6
		jsr _LVODisable(a6)

		moveq.l #0,d4
		move.l MediatorType(pc),d0
		beq.s NoWindowShift

		move.l PCIBase(pc),a6
		jsr _LVOPCIGetZorroWindow(a6)

		move.l d0,d7
NoWindowShift	move.l SonAddr(pc),a2
		move.w PCI_DEVICEID(a2),d4
		cmp.w #DEVICE_MPC8343E,d4
		beq.s Got1200K

		cmp.w #DEVICE_HARRIER,d4
		bne.s No1200H

		move.l PMEPAddr(pc),a2
		bra.s Got1200H

Got1200K	move.l PCI_SPACE0(a2),a2		;Get config block
		bra.s Got1200H

No1200H		move.l EUMBAddr(pc),a2
Got1200H	move.l a2,d6		
		
		bsr ShiftWindow

		cmp.w #DEVICE_MPC8343E,d4
		beq.s Int1200K

		cmp.w #DEVICE_HARRIER,d4
		bne.s NoInt1200H

		move.l PMEP_MIST(a2),d3
		beq DoNothingYet
		bra.s NxtMsg1200

Int1200K	move.l IMMR_OMISR(a2),d3
		and.l #IMMR_OMISR_OM0I,d3
		beq DoNothingYet
		move.l #IMMR_OMISR_OM0I,IMMR_OMISR(a2)	;Ack Interrupt
		bra.s NxtMsg1200

NoInt1200H	move.l OMISR(a2),d3
		and.l #OPQI,d3
ReUseK		beq.s DoNothingYet

NxtMsg1200	cmp.w #DEVICE_MPC8343E,d4
		beq.s GetMsg1200K
		
		move.l d6,a2
		cmp.w #DEVICE_HARRIER,d4
		bne.s NoGetMsg1200H

		bsr GetMsgFrameHar
		bra.s GotMsg1200H
		
GetMsg1200K	bsr GetMsgFrameK
		bra.s GotMsg1200H
		
NoGetMsg1200H	move.l OFQPR(a2),a1
GotMsg1200H	move.l a1,d3
		move.l d3,d5
		cmp.l #-1,d3
		beq EmptyQueue

		cmp.w #DEVICE_MPC8343E,d4
		beq.s PrevDone

		cmp.w #DEVICE_HARRIER,d4
		beq.s PrevDone

		lea Previous2(pc),a1
		move.l (a1),d5
		cmp.l d5,d3
		beq.s NxtMsg1200		
		move.l d3,(a1)

PrevDone	moveq.l #1,d5
		move.l FIFOBuffer(pc),a1
		lea FIFOWrite(pc),a2
		move.w (a2),d0
		move.l d3,(0,a1,d0.w*4)
		addq.w #1,d0
		and.w #$fff,d0
		move.w d0,(a2)
		bra.s NxtMsg1200					
							
EmptyQueue	move.l LExecBase(pc),a6			;messages send by the PPC
		move.l MasterControlPort(pc),a1
		move.l a1,d0
		beq.s DoNothingYet
		
		moveq.l #0,d0
		move.l d0,d1
		move.b MP_SIGBIT(a1),d1
		bset d1,d0
		move.l MP_SIGTASK(a1),a1		
		jsr _LVOSignal(a6)
				
DoNothingYet	move.l MediatorType(pc),d0
		beq.s NoWindowShiftB

		move.l PCIBase(pc),a6
		move.l d7,d0
		jsr _LVOPCISetZorroWindow(a6)
		
		move.l LExecBase(pc),a6
NoWindowShiftB	jsr _LVOEnable(a6)
		move.l d5,d0

		movem.l (a7)+,d1-a6
		tst.l d0
		rts

NxtMsgLoop	move.b Options68K+1(pc),d0
		beq NxtMsg
		bra CheckFIFO

;********************************************************************************************

StoreD		move.l MN_IDENTIFIER(a1),d7		;Handles indirect access from PPC
		move.l MN_IDENTIFIER+4(a1),d0		;to Amiga Memory
		move.l MN_IDENTIFIER+8(a1),a0

		cmp.l #"PUTB",d7
		beq.s PutB
		cmp.l #"PUTH",d7
		beq.s PutH
		cmp.l #"PUTW",d7
		bne NxtMsgLoop
		move.l d0,(a0)
Putted		move.l #"DONE",d7
		move.l d7,MN_IDENTIFIER(a1)
		move.l a1,a0
		bsr FreeMsgFrame

		bra NxtMsgLoop

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

		bra NxtMsgLoop

;********************************************************************************************		
		
MsgT68k		move.l MN_MIRROR(a1),a0			;Handles messages to 68K (mirror)tasks
		move.l a0,d1
		beq CommandMaster
		cmp.l #"END!",d0
		beq DoPutMsg

		move.l d1,a2
		move.l MP_SIGTASK(a2),a2
		move.l MN_ARG1(a1),TC_SIGALLOC(a2)

DoPutMsg	jsr _LVOPutMsg(a6)
		bra NxtMsgLoop

;********************************************************************************************

MsgFPPC		move.l MN_ARG1(a1),d0
		move.l MN_REPLYPORT(a1),a2
		move.l MP_SIGTASK(a2),a2
		move.l d0,TC_SIGALLOC(a2)
		jsr _LVOReplyMsg(a6)			;Ends the RunPPC function
		bra NxtMsgLoop
		
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

		bra NxtMsgLoop
		
;********************************************************************************************
;********************************************************************************************

ZenInt		movem.l d1-a6,-(a7)

		move.l MediatorType(pc),d0
		beq.s NoZenShift

		move.l PCIBase(pc),a6
		jsr _LVOPCIGetZorroWindow(a6)

		move.l d0,d7
		
NoZenShift	move.l SonAddr(pc),a2
		move.l PCI_SPACE0(a2),a2		;Get config block
		
		bsr ShiftWindow
		
		move.l IMMR_OMISR(a2),d3
		and.l #IMMR_OMISR_OM0I,d3
		bne DoNotChkInt

		move.l SonnetBase(pc),a2
		add.l #FIFO_BASE,a2
		
		bsr ShiftWindow
		
		move.l FIFO_MIOPT(a2),d1		;Compare Outgoing Post Tail with
		move.l FIFO_MIOPH(a2),d2		;Outgoing Post Header. Equal means empty
		cmp.l d1,d2
		beq DoNotChkInt

		move.w #INTF_PORTS,INTENA
		
		move.b Options68K+1(pc),d0
		beq.s DoSonInt

		bsr SonInt1200
		bra.s DoneSonInt
		
DoSonInt	bsr SonInt

DoneSonInt	move.w #INTF_SETCLR|INTF_INTEN|INTF_PORTS,INTENA

DoNotChkInt	move.l MediatorType(pc),d0
		beq.s NoZenShiftB

		move.l PCIBase(pc),a6
		move.l d7,d0
		jsr _LVOPCISetZorroWindow(a6)

NoZenShiftB	movem.l (a7)+,d1-a6
		moveq.l #0,d0
		rts

ZenIntData	dc.l 0

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
		move.l d0,a6
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
		nop					;DEBUG Library should not be expunged due to patches not being released
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
		movem.l d1-a6,-(a7)			;No 604e cards at the moment, so we

		moveq.l #HW_CPUTYPE,d1			;Only return 603e G3 and G4

		RUNPOWERPC	_PowerPCBase,SetHardware

		and.w #$0,d0
		swap d0
		cmp.w #$7000,d0
		beq.s G3
		cmp.w #$8000,d0
		beq.s G4
		cmp.w #$8083,d0
		beq.s MPC8343E
		and.w #$0fff,d0
		subq.l #8,d0
		beq.s G3
		subq.l #4,d0
		beq.s G4
		moveq.l #0,d0
		bra.s ExCPU

MPC8343E	move.l #CPUF_603E,d0
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
		movem.l d0-d7/a1-a6,-(a7)
		move.l LExecBase(pc),a6
		jsr _LVODisable(a6)

TooFast4U	move.l SonAddr(pc),a2
		cmp.w #DEVICE_MPC8343E,PCI_DEVICEID(a2)
		beq.s CreateKilMsg
		
		cmp.w #DEVICE_HARRIER,PCI_DEVICEID(a2)
		bne.s DoNotCreateH
		
		move.l PMEPAddr(pc),a2
		move.l PMEP_MIIQ(a2),a0
		bra.s CreatedMsg
	
CreateKilMsg	move.l SonnetBase(pc),a2
		add.l #FIFO_BASE,a2
		move.l FIFO_MIIFT(a2),d1
		move.l d1,a0
		addq.l #4,d1
		and.w #$3fff,d1
		move.l d1,FIFO_MIIFT(a2)
		move.l (a0),a0
		bra.s CreatedMsg	
	
DoNotCreateH	move.l EUMBAddr(pc),a2
		move.l IFQPR(a2),a0
		
CreatedMsg	lea Previous(pc),a2
		move.l (a2),a1
		cmp.l a1,a0
		beq.s TooFast4U				;To prevent duplicates (Is there a better way?)
		move.l a0,(a2)
		move.l a0,a3
		jsr _LVOEnable(a6)
		move.l a3,a0
		movem.l (a7)+,d0-d7/a1-a6
		rts

;********************************************************************************************
;
;	void SendMsgFrame(MessageFrame)) // a0
;
;********************************************************************************************

SendMsgFrame:
		movem.l d0-a6,-(a7)
		move.l LExecBase(pc),a6
		jsr _LVODisable(a6)

		move.l SonAddr(pc),a2		
		cmp.w #DEVICE_MPC8343E,PCI_DEVICEID(a2)
		beq.s SendKilMsg
		
		cmp.w #DEVICE_HARRIER,PCI_DEVICEID(a2)
		bne.s DoNotSendH

		move.l PMEPAddr(pc),a2
		move.l a0,PMEP_MIIQ(a2)	
		bra.s SendMsg
	
SendKilMsg	move.l SonnetBase(pc),a2
		add.l #FIFO_BASE,a2
		move.l FIFO_MIIPH(a2),d1
		move.l d1,a3
		addq.l #4,d1
		and.w #$3fff,d1
		move.l d1,FIFO_MIIPH(a2)
		move.l a0,(a3)
		move.l SonAddr(pc),a2
		move.l PCI_SPACE0(a2),a3		;Get config block
		move.l a0,IMMR_IMR0(a3)			;Trigger interrupt
		bra.s SendMsg	

DoNotSendH	move.l EUMBAddr(pc),a2
		move.l a0,IFQPR(a2)			;Send the message to the PPC

SendMsg		
		jsr _LVOEnable(a6)
		movem.l (a7)+,d0-a6
		rts

;********************************************************************************************
;
;	void FreeMsgFrame(MessageFrame) // a0
;
;********************************************************************************************
		
FreeMsgFrame:
		movem.l d0-a6,-(a7)			;Return a PPC message to the free
		move.l LExecBase(pc),a6
		jsr _LVODisable(a6)

		move.l #"FREE",MN_IDENTIFIER(a0)		
		move.l SonAddr(pc),a2			;messages pool
		
		cmp.w #DEVICE_MPC8343E,PCI_DEVICEID(a2)
		beq.s FreeK
		
		cmp.w #DEVICE_HARRIER,PCI_DEVICEID(a2)
		bne.s DoNotFreeH

		move.l XCSRAddr(pc),a2
		move.l XCSR_MIOFH(a2),d1		;Get from Outgoing Free Header
		move.l d1,d2
		addq.l #4,d1
		and.w #$3fff,d1				;Wrap the queue to 16K (4K entries)
		move.l SonnetBase(pc),d3
		add.l d2,d3
		move.l d3,a3
		move.l a0,(a3)				;Free the PPC message
		move.l d1,XCSR_MIOFH(a2)		;Update Outgoing Free Header
		bra.s FreeMsgH

FreeK		move.l SonnetBase(pc),a2
		add.l #FIFO_BASE,a2
		move.l FIFO_MIOFH(a2),d1		;Get from Outgoing Free Header
		move.l d1,d2
		addq.l #4,d1
		and.w #$3fff,d1				;Wrap the queue to 16K (4K entries)
		move.l d2,a3
		move.l a0,(a3)				;Free the PPC message
		move.l d1,FIFO_MIOFH(a2)		;Update Outgoing Free Header
		bra.s FreeMsgH
	
DoNotFreeH	move.l EUMBAddr(pc),a2			
		move.l a0,OFQPR(a2)		
FreeMsgH	
		jsr _LVOEnable(a6)
		movem.l (a7)+,d0-a6
		rts
		
;********************************************************************************************
;
;	MessageFrame = GetMsgFrame(void) // a1
;
;********************************************************************************************

GetMsgFrame:
		movem.l d0-d7/a0/a2-a6,-(a7)		;Get next message send from the PPC
		move.l LExecBase(pc),a6
		jsr _LVODisable(a6)

TooFast4U2	move.l SonAddr(pc),a2			;if available
		cmp.w #DEVICE_MPC8343E,PCI_DEVICEID(a2)
		beq.s GetK

		cmp.w #DEVICE_HARRIER,PCI_DEVICEID(a2)
		bne.s DoNotGetH

		move.l XCSRAddr(pc),a2
		move.l XCSR_MIOPT(a2),d1		;Compare Outgoing Post Tail with
		move.l XCSR_MIOPH(a2),d2		;Outgoing Post Header. Equal means empty
		cmp.l d1,d2
		bne.s DoQueue
		
		moveq.l #-1,d3				;Give -1 when empty.
		move.l d3,a1
		bra.s GotMsgH
		
GetK		move.l SonnetBase(pc),a2
		add.l #FIFO_BASE,a2
		move.l FIFO_MIOPT(a2),d1		;Compare Outgoing Post Tail with
		move.l FIFO_MIOPH(a2),d2		;Outgoing Post Header. Equal means empty
		cmp.l d1,d2
		bne.s DoQueueK
		
		moveq.l #-1,d3				;Give -1 when empty.
		move.l d3,a1
		bra.s GotMsgH

DoQueueK	move.l d1,d2
		addq.l #4,d1
		and.w #$3fff,d1				;Wrap queue to 16K (4K entries)
		move.l d2,a3
		move.l d1,FIFO_MIOPT(a2)
		move.l (a3),a1
		bra.s GotMsgH

DoQueue		move.l d1,d2
		addq.l #4,d1
		and.w #$3fff,d1				;Wrap queue to 16K (4K entries)
		move.l SonnetBase(pc),d3
		add.l d2,d3
		move.l d3,a3
		move.l (a3),a1				;Get PPC message.
		move.l d1,XCSR_MIOPT(a2)		;Update Outgoing Post Tail;
		bra.s GotMsgH

DoNotGetH	move.l EUMBAddr(pc),a2	
		move.l OFQPR(a2),a1

GotMsgH		moveq.l #-1,d1
		cmp.l a1,d1
		beq.s NoPrev

		lea Previous2(pc),a0
		move.l (a0),a2
		cmp.l a1,a2
		beq TooFast4U2			;To prevent duplicates (Is there a better way?)
		move.l a1,(a0)
NoPrev		move.l a1,a4
		jsr _LVOEnable(a6)
		move.l a4,a1
		movem.l (a7)+,d0-d7/a0/a2-a6
		rts

;********************************************************************************************

GetMsgFrameHar:
		movem.l d1-d3/a0/a2-a3,-(a7)		;Get next message send from the PPC

TooFast4Har	move.l XCSRAddr(pc),a2

		bsr ShiftWindow

		move.l XCSR_MIOPT(a2),d1		;Compare Outgoing Post Tail with
		move.l XCSR_MIOPH(a2),d2		;Outgoing Post Header. Equal means empty
		cmp.l d1,d2
		bne.s DoQueueHar
		moveq.l #-1,d3				;Give -1 when empty.
		bra.s GotMsgHar
		
DoQueueHar	move.l d1,d2
		addq.l #4,d1
		and.w #$3fff,d1				;Wrap queue to 16K (4K entries)
		move.l SonnetBase(pc),d3
		add.l d2,d3
		move.l d3,a2
		
		bsr ShiftWindow
		
		move.l (a2),d3				;Get PPC message.
		move.l XCSRAddr(pc),a2
		
		bsr ShiftWindow
		
		move.l d1,XCSR_MIOPT(a2)		;Update Outgoing Post Tail;
GotMsgHar	moveq.l #-1,d1
		move.l d3,a1
		cmp.l a1,d1
		beq.s NoPrevHar

		lea Previous2(pc),a0
		move.l (a0),a2
		cmp.l a1,a2
		beq.s TooFast4Har			;To prevent duplicates (Is there a better way?)
		move.l a1,(a0)
NoPrevHar	movem.l (a7)+,d1-d3/a0/a2-a3
		rts

;********************************************************************************************

GetMsgFrameK:
		movem.l d1-d3/a0/a2-a3,-(a7)		;Get next message send from the PPC

TooFast4Kil	move.l SonnetBase(pc),a2
		add.l #FIFO_BASE,a2
		
		bsr ShiftWindow
		
		move.l FIFO_MIOPT(a2),d1		;Compare Outgoing Post Tail with
		move.l FIFO_MIOPH(a2),d2		;Outgoing Post Header. Equal means empty
		cmp.l d1,d2
		bne.s DoQueueKil
		
		moveq.l #-1,d3				;Give -1 when empty.
		move.l d3,a1
		bra.s GotMsgKil

DoQueueKil	move.l d1,d2
		addq.l #4,d1
		and.w #$3fff,d1				;Wrap queue to 16K (4K entries)
		move.l d2,a3
		move.l d1,FIFO_MIOPT(a2)
		move.l a3,a2
		
		bsr ShiftWindow
		
		move.l (a2),d3

GotMsgKil	moveq.l #-1,d1
		move.l d3,a1
		cmp.l a1,d1
		beq.s NoPrevKil

		lea Previous2(pc),a0
		move.l (a0),a2
		cmp.l a1,a2
		beq.s TooFast4Kil			;To prevent duplicates (Is there a better way?)
		move.l a1,(a0)
NoPrevKil	movem.l (a7)+,d1-d3/a0/a2-a3
		rts

;********************************************************************************************

ShiftWindow	move.l MediatorType(pc),d0
		beq.s ExitShift

		move.l a2,d0
		move.l a2,d6
		and.l #$3fffff,d6
		add.l #$200000,d6
		jsr _LVOPCISetZorroWindow(a6)
		move.l d6,a2
ExitShift	rts

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
;		Patches to re-direct stack memory
;
;********************************************************************************************
		
CP1200		move.l a3,-(a7)
		pea ReturnPatch2(pc)
		move.l CPAddress(pc),-(a7)
		bra.s CommonPatch

CNP1200		move.l a3,-(a7)
		pea ReturnPatch2(pc)
		move.l CNPAddress(pc),-(a7)
		bra.s CommonPatch

STL1200		move.l a3,-(a7)
		pea ReturnPatch(pc)
		move.l STLAddress(pc),-(a7)
		bra.s CommonPatch

RC1200		move.l a3,-(a7)
		pea ReturnPatch(pc)
		move.l RCAddress(pc),-(a7)
		move.l LExecBase(pc),a3
		move.l ThisTask(a3),a3
		bclr #TB_PPC,TC_FLAGS(a3)
		bra.s DiffRunComm

CommonPatch	move.l LExecBase(pc),a3
		move.l ThisTask(a3),a3
		bset #TB_WARN,TC_FLAGS(a3)
DiffRunComm	move.l 8(a7),a3
		rts

ReturnPatch	move.l a3,(a7)
		move.l LExecBase(pc),a3
		move.l ThisTask(a3),a3
		bclr #TB_WARN,TC_FLAGS(a3)
		move.l (a7)+,a3
		rts

ReturnPatch2	move.l a3,(a7)
		move.l LExecBase(pc),a3
		move.l ThisTask(a3),a3
		bclr #TB_WARN,TC_FLAGS(a3)		;When EnStackPatch = 1 makes FreeSpace movies slow.
		btst #TB_PPC,TC_FLAGS(a3)
		beq.s DontFlagPPC
		move.l d0,a3
		bset #TB_PPC,TC_FLAGS(a3)
DontFlagPPC	move.l (a7)+,a3
		rts
		
;********************************************************************************************
;
;		AllocMem() Patch
;
;********************************************************************************************

AmigaAMP	btst #TB_PPC,TC_FLAGS(a3)			;Check if task was tagged by powerpc.library
		bne DoBit

		lea CheckValues(pc),a2				;AmigaAMP v3 patches
		move.l (a2)+,d6
CVLoop		move.l (a2)+,d7
		cmp.l d0,d7
		beq DoBit
		dbf d6,CVLoop

BufferAMP2	cmp.l #$4000,d0					;AmigaAMP v2 lazy patch
		blt NoBit

		cmp.b #$54,d0
		bne NoBit
		bra DoBit

CheckValues	dc.l	2,$c094,$904,$4d4

NewAlloc	move.l AllocMemAddress(pc),-(a7)		
		tst.w d1					;Patch code - Test for attribute $0000 (Any)
		beq.s Best
		btst #2,d1					;If FAST requested, redirect
		bne.s Best					
		btst #0,d1					;If not PUBLIC requested, exit
		beq NoFast
		btst #1,d1					;If CHIP requested, exit
		bne NoFast
		nop						;Let everything else through..?		
		
Best		movem.l d6-d7/a2-a3,-(a7)
		move.l ThisTask(a6),a3
		
		btst #TB_WARN,TC_FLAGS(a3)
		bne NoBit
		
		move.b ThisTask(a6),d7
		and.b #$f0,d7
		beq.s NotAPPCMemTask

		move.b SonnetBase(pc),d6
		and.b #$e0,d6
		and.b #$e0,d7
		eor.b d6,d7
		bne.s NotAPPCMemTask

		moveq.l #1,d6
		bset #TB_PPC,TC_FLAGS(a3)
		bra GoCheck					;bra DoBit

NotAPPCMemTask	moveq.l #0,d6
GoCheck		cmp.b #NT_PROCESS,LN_TYPE(a3)			;Is it a DOS process?
		bne.s IsTask
		move.l pr_CLI(a3),d7				;Was this task started by CLI?
		bne IsHell					;If yes, go there
		
IsTask		move.l LN_NAME(a3),d7				;Has the task a name?
		beq NoBit					;If no then exit
		move.l d7,a2

FindEnd		move.b (a2)+,d7
		bne.s FindEnd
		move.l -5(a2),d7
Checkers	cmp.l #"2005",d7				;Task has name with 2005 at end?
		beq.s DoBit					;if yes, then redirect to PPC memory
		cmp.l #"aAMP",d7
		beq AmigaAMP
		cmp.l #"_68K",d7
		beq.s DoBit
		cmp.l #"_PPC",d7
		beq.s DoBit
		cmp.l #"sk_0",d7
		beq.s DoBit
		cmp.l #"sk_1",d7
		beq.s DoBit
		cmp.l #"peed",d7
		beq.s NoBit
		tst.l d6
		beq.s NotPPCTask
		cmp.l #".exe",d7
		beq.s FreeBit
NotPPCTask	btst #TB_PPC,TC_FLAGS(a3)			;Check if task was tagged by powerpc.library
ToSpace		bne.s DoBit					;If yes, then redirect to PPC memory
		bra.s NoBit

FreeBit		move.l -9(a2),d7				;Checking for FreeSpace
		cmp.l #"pace",d7		
		bra.s ToSpace

IsHell		lsl.l #2,d7
		move.l d7,a2
		move.l cli_CommandName(a2),d7			;Get name of task started by CLI
		beq.s NoBit

		lsl.l #2,d7
		move.l d7,a2
		clr.l d7
		move.b (a2)+,d7
		subq.l #4,d7
		bmi.s NoBit

		add.l d7,a2
		move.l (a2),d7
		addq.l #5,a2
		bra Checkers

DoBit		bset #MEMB_PPC,d1				;Set attribute MEMF_PPC
NoBit		movem.l (a7)+,d6-d7/a2-a3
NoFast		rts
		
;********************************************************************************************
;
;		LoadSeg() Patch
;
;********************************************************************************************

NewOldLoadSeg	move.l LoadSegAddress(pc),-(a7)

Loader		movem.l d2-a6,-(a7)
		move.l d1,d5
		beq NoInternal

		move.l LExecBase(pc),a3
		move.l ThisTask(a3),a3
		move.l LN_NAME(a3),a3
		cmp.l #"DefI",(a3)				;Dirty DefIcons Fix
		beq NoInternal

		move.l #MODE_OLDFILE,d2
		jsr _LVOOpen(a6)
		move.l d0,d4
		beq ExitSeg

		moveq.l #0,d2
		moveq.l #DOS_FIB,d1
		jsr _LVOAllocDosObject(a6)
		move.l d0,d7
		beq CloseError

		move.l d4,d1
		move.l d7,d2
		jsr _LVOExamineFH(a6)

		move.l d7,a1
		move.l fib_Protection(a1),d6		
		swap d6

		moveq.l #DOS_FIB,d1
		move.l d7,d2
		jsr _LVOFreeDosObject(a6)

		move.l d6,d3
		and.b #3,d3
		beq.s DoInternalSeg			;Not marked at all
		cmp.b #2,d3
		beq DoNormalSeg				;Marked normal file

DoInternalSeg	move.l LExecBase(pc),a3
		sub.l a0,a0
		pea _LVOFreeMem(a3)
		pea AllocFunc(pc)
		pea InternalRead(pc)
		move.l a7,a1
		clr.l -(a7)
		move.l a7,a2
		move.l d4,d0		
		move.l ThisTask(a3),a3
		bset #TB_PPC,TC_FLAGS(a3)		;set bit				
		jsr _LVOInternalLoadSeg(a6)

		lea 16(a7),a7
		move.l d0,d7
		bmi.s UhOhverlay
				
CloseError	move.l d4,d1
		jsr _LVOClose(a6)
		
		move.l d7,d0
		move.l d7,d1
		beq ExitSeg				;There was no seglist returned
		bra.s IsNormalSeg

UhOhverlay	move.l d7,d1
		neg.l d1
		bra.s DontDoOverlay			;Overlay files are not supported at the moment

IsNormalSeg	move.l d6,d3
		and.b #3,d3
		bne ExitSeg				;Marked PPC file. No need to search.

FindPower	move.l d7,d2				;Search for PPC, then mark file with prot bits
NextSeg		lsl.l #2,d2		
		move.l d2,a1
		move.l -4(a1),d2
		lea 3(a1),a5

NextName	lea 1(a5),a2
		move.l a2,a5
		moveq.l #1,d3
		subq.l #1,d2
		bmi.s EndSeg

		cmp.l #"RACE",(a2)
		beq.s WarpRaceMod

		lea PowerName(pc),a3

CmpLoop		tst.b (a3)
		beq.s WarpRaceMod

		move.b (a2)+,d1
		cmp.b (a3)+,d1
		bne.s NextCheck
		bra.s CmpLoop

NextCheck	tst.l d3
		beq.s NextName

		lea AMPName(pc),a3			;Say that AmigaAMP is also PPC
		move.l a5,a2
		subq.l #1,d3
		bra.s CmpLoop

WarpRaceMod	bset #0,d6
		move.l d6,d2
		move.l d5,d1
		swap d2
		jsr _LVOSetProtection(a6)		;Mark file being PPC
		move.l d7,d0
		move.l d7,d1
		bra.s ExitSeg

EndSeg		move.l (a1),d2
		bne NextSeg

		move.l d7,d1

DontDoOverlay	jsr _LVOUnLoadSeg(a6)
DoNormalSeg	move.l LExecBase(pc),a1
		move.l ThisTask(a1),a1
		bclr #TB_PPC,TC_FLAGS(a1)		;clear bit
		move.l d5,d1
		bset #1,d6
		move.l d6,d2
		swap d2
		jsr _LVOSetProtection(a6)		;Mark file being Non-PPC
		move.l d5,d1
		bra.s NoInternal
		
ExitSeg		movem.l (a7)+,d2-a6
		lea 4(a7),a7
		rts

NoInternal	movem.l (a7)+,d2-a6
		rts

;**********************************************

InternalRead	jsr _LVORead(a6)
		movem.l d0-a6,-(a7)
		move.b Options68K(pc),d0
		bne.s NoHunkPatch
		move.l d2,a2
		cmp.l #HUNK_HEADER,(a2)
		bne.s NoHunkPatch
		move.l 4(a2),d0
		bne.s NoHunkPatch
		move.l 12(a2),d0
		bne.s NoHunkPatch
		move.l 8(a2),d0
		move.l 16(a2),d1
		sub.l d1,d0
		subq.l #1,d0
		bne.s NoHunkPatch
		cmp.l #$71E,20(a2)
		beq.s TestCyber1
		cmp.l #$84E,20(a2)
		beq.s TestCyber2
		
NoCyber		btst #6,20(a2)
		bne.s NoHunkPatch
		bset #7,20(a2)
NoHunkPatch	movem.l (a7)+,d0-a6
		rts

TestCyber1	cmp.l #$710,24(a2)			;Exceptions to moving hunks to FastRAM (dirty)
Testing		beq.s NoHunkPatch
		bra.s NoCyber

TestCyber2	cmp.l #$EE,24(a2)
		bra.s Testing

;**********************************************

AllocFunc:	lea Options68K(pc),a0			;InternalLoadSeg() Memory allocation function
		tst.b (a0)
		bne.s NoHunkPatch2

		move.l ThisTask(a6),a0
		bclr #TB_PPC,TC_FLAGS(a0)
		cmp.l #MEMF_PUBLIC|MEMF_FAST,d1
		beq.s DoNormMem				;force marked hunks into Amiga mem
		cmp.l #MEMF_PUBLIC|MEMF_CHIP,d1
		beq.s DoNormMem
		bset #TB_PPC,TC_FLAGS(a0)

NoHunkPatch2	and.l #MEMF_CLEAR,d1
		or.l #MEMF_PUBLIC|MEMF_PPC,d1		;attributes are FIXED to PPC memory

DoNormMem	jsr _LVOAllocMem(a6)
		move.l ThisTask(a6),a0
		bset #TB_PPC,TC_FLAGS(a0)
		rts

;********************************************************************************************
;
;		NewLoadSeg() Patch
;
;********************************************************************************************

NewNewLoadSeg	move.l NewLoadSegAddress(pc),-(a7)
		tst.l d2
		beq Loader
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

DoneMirList	move.l d6,a1
		bclr #TB_PPC,TC_FLAGS(a1)
		jsr _LVOCreateMsgPort(a6)
		tst.l d0
		bne.s GotMsgPort
		
GiveASyncErr	moveq.l #PPERR_MISCERR,d7
		bra EndIt

GotMsgPort	move.l d0,Port(a5)
		move.l #MEMF_PUBLIC|MEMF_CLEAR,d1
		moveq.l #MT_SIZE,d0
		jsr _LVOAllocVec(a6)

		tst.l d0
		bne.s GotMTMem
	
		moveq.l #PPERR_MISCERR,d7		;Only DOS processes supported
		bra EndIt
		
GotMTMem	move.l d6,a1
		bset #TB_PPC,TC_FLAGS(a1)		
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
		bne.s GotTaskMem

		moveq.l #PPERR_MISCERR,d7		;Only DOS processes supported
		bra EndIt

GotTaskMem	move.l LExecBase(pc),a6
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
CpName		move.b (a1)+,d1
		move.b d1,(a2)
		tst.b d1
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
		move.l TC_SIGRECVD(a2),d0
		move.l d0,d1
		move.l Port(a5),a1
		move.b MP_SIGBIT(a1),d2
		bclr d2,d0
		and.l #$fffff000,d0
		move.l d0,MN_SIGNALS(a0)		;Send current 68K signals to PPC (active CPU)
		eor.l d0,TC_SIGRECVD(a2)		;Reset the sent signals to zero on the 68K.
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
		bsr PrintError2
		bra Cannot

SetupCp		move.l a3,a1
		lea MN_PPSTRUCT(a0),a2
		moveq.l #PP_SIZE/4-1,d0

CpMsg2		move.l (a3)+,d1
		move.l d1,(a2)+
		dbf d0,CpMsg2

		bsr SendMsgFrame
		
		move.l PP_FLAGS(a1),d1			;Asynchronous RunPPC Call
		btst.l #PPB_ASYNC,d1
		beq SigsSetup
		
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

SigsSetup	move.l Port(a5),a0
		move.b MP_SIGBIT(a0),d1
		moveq.l #0,d5
		bset d1,d5
		move.l d5,d6
		add.w #$fff,d6
		not.l d6

WaitPktLoop	move.l ThisTask(a6),a1
		cmp.b #0,LN_PRI(a1)
		blt.s NoAdjustPri
		move.b #0,LN_PRI(a1)			;Kludge to prevent high pri stuff blocking
							;the system like Heretic II.
NoAdjustPri	move.l TC_SIGALLOC(a1),d0		
		and.l #$fffff000,d0

		jsr _LVOWait(a6)

		move.l d0,d1
		and.l d5,d0
		bne.s ResetSigs2

		and.l d6,d1
		beq.s WaitPktLoop

		bsr CrossSignals			;If other signals are detected than the

		bra.s WaitPktLoop

ResetSigs2	and.l d6,d1
		move.l ThisTask(a6),a0
		or.l d1,TC_SIGRECVD(a0)			;Reset 68K signals that were negated by Wait().

GtLoop		move.l Port(a5),a0
		jsr _LVOGetMsg(a6)
		
		tst.l d0
		beq.s WaitPktLoop

		move.l d0,a0
		move.l MN_IDENTIFIER(a0),d0
		cmp.l #"FPPC",d0
		beq.s DizDone
		cmp.l #"T68K",d0
		bne.s GtLoop
		bsr.s Runk862
		bra.s GtLoop

DizDone		move.l a0,a2
		move.l ThisTask(a6),a1
		move.l MN_ARG2(a2),d0
		or.l d0,TC_SIGRECVD(a1)			;Activate 68K signals as received from PPC.
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
CpBck		move.l (a2)+,d7
		move.l d7,(a1)+
		dbf d0,CpBck
		moveq.l #PPERR_SUCCESS,d7
		bsr FreeMsgFrame
		bra.s EndIt

Cannot		moveq.l #-1,d7
EndIt		move.l d7,d0
		movem.l (a7)+,d1-a6
		unlk a5
		rts
		
;********************************************************************************************

Runk862		move.l MirrorNode(a5),a1
		move.l MN_PPC(a0),MT_MIRROR(a1)
Runk86		link a3,#-16
		lea -16(a3),a3
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
		
NoFPU		movem.l d0-a6,-(a7)			;68k routines called from PPC
		move.l a0,-(a7)
		move.l ThisTask(a6),a1
		move.l MN_ARG2(a0),d0
		or.l d0,TC_SIGRECVD(a1)			;Activate signals as received from PPC.	
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
		move.l PP_STACKSIZE(a5),d1
		beq NoStckPtr

		move.l a3,a2
		move.l #$2e7a0008,(a2)+
		move.w #$4ef9,(a2)+
		move.l #xBack,(a2)+
		move.l a7,(a2)+
		move.l LExecBase(pc),a6
		jsr _LVOCacheClearU(a6)

		move.l PP_STACKPTR(a5),a0
		lea 24(a0),a0				;Offset into stack must be 24 (see docs Run68K)
		move.l PP_STACKSIZE(a5),d1
		moveq.l #CACHE_DCACHEINV,d0
		bsr SetCache68K

		move.l PP_STACKPTR(a5),a0
		lea 24(a0),a0				;See above about offset
		move.l PP_STACKSIZE(a5),d0
		addq.l #3,d0
		and.l #$fffffffc,d0			;Make it 4 aligned
		move.l a7,a1
		sub.l d0,a1
		move.l a1,a7
		jsr _LVOCopyMem(a6)
		move.l a3,-(a7)				;Return function
		bra StckPtr

NoStckPtr	pea xBack(pc)
StckPtr		move.l PP_CODE(a5),a0
		move.l MediatorType(pc),d0
		beq.s DoNormalFunc
	
		move.l PP_OFFSET(a5),d0
		cmp.l #-42,d0
		beq.s DoRead1200
		
DoNormalFunc	add.l PP_OFFSET(a5),a0
		move.l a0,-(a7)		
		lea PP_REGS(a5),a6
		movem.l (a6)+,d0-a5
		move.l (a6),a6
		rts

DoRead1200	add.l PP_OFFSET(a5),a0
		move.l a0,-(a7)		
		lea PP_REGS(a5),a6
		movem.l (a6),d0-a4

		move.l LExecBase(pc),a6
		move.l ThisTask(a6),a3
		bset #TB_WARN,TC_FLAGS(a3)
		move.l d3,d0
		moveq.l #0,d1
		jsr _LVOAllocVec(a6)
		
		move.l ThisTask(a6),a3
		bclr #TB_WARN,TC_FLAGS(a3)

		lea BufCopySrc(pc),a1
		move.l d0,(a1)
		move.l d2,BufCopyDst-BufCopySrc(a1)
		move.l d3,BufCopySz-BufCopySrc(a1)

		lea PP_REGS(a5),a6
		move.l d0,8(a6)				;Replace buffer destination		
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
		move.l LExecBase(pc),a6
		move.l BufCopySrc(pc),d1
		beq.s NoBufCopy

		move.l d1,a0
		move.l BufCopyDst(pc),a1
		move.l BufCopySz(pc),d0
		jsr _LVOCopyMem(a6)
		move.l BufCopySrc(pc),a1
		jsr _LVOFreeVec(a6)
		lea BufCopySrc(pc),a1
		moveq.l #0,d1
		move.l d1,(a1)

NoBufCopy	btst #AFB_FPU40,AttnFlags+1(a6)
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
DoReslt		move.l (a1)+,d7
		move.l d7,(a3)+
		dbf d1,DoReslt
		
		move.l #"DONE",MN_IDENTIFIER(a0)
		move.l ThisTask(a6),a1
		move.l a1,MN_ARG2(a0)
		move.l TC_SIGALLOC(a1),MN_ARG1(a0)
		move.l TC_SIGRECVD(a1),d7
		move.l $1c(a7),d6			;Get d6 (signal mask) from stack
		and.l d6,d7
		move.l d7,MN_ARG0(a0)			;Send current active 68K signals to PPC.
		eor.l d7,TC_SIGRECVD(a1)		;Reset sent signals to zero for 68K.
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
		
NoFPU2		move.l a7,a0
		lea 16(a0),a0
		unlk a0		
		rts
		
;********************************************************************************************

CrossSignals	bsr CreateMsgFrame

		moveq.l #MSG_LEN/4-1,d0
		move.l a0,a2
ClearMsg	clr.l (a2)+
		dbf d0,ClearMsg

		move.l #"LLPP",MN_IDENTIFIER(a0)
		move.l d1,MN_ARG0(a0)
		move.l ThisTask(a6),a3
		move.l a3,MN_ARG1(a0)

		bra SendMsgFrame

;********************************************************************************************
;
;	PPCState = GetPPCState(void) // d0
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
		or.l #MEMF_PUBLIC|MEMF_PPC,d1		;attributes are FIXED to PPC memory

		jsr _LVOAllocVec(a6)
		move.l ThisTask(a6),a0
		bset #TB_PPC,TC_FLAGS(a0)
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
		move.l SonAddr(pc),a2
		cmp.w #DEVICE_MPC8343E,PCI_DEVICEID(a2)
		beq.s CausedK
		
		moveq.l #-1,d1
		cmp.w #DEVICE_HARRIER,PCI_DEVICEID(a2)
		bne.s NoCauseH
		
		move.l PMEPAddr(pc),a2
		move.l d1,PMEP_MGIM0(a2)
		bra.s CausedIt

CausedK		move.l PCI_SPACE0(a2),a2
		move.l #IMMR_IDR_IDR0,IMMR_IDR(a2)
		bra.s CausedIt

NoCauseH	move.l EUMBAddr(pc),a2
		move.l d1,IMR0(a2)

CausedIt	movem.l (a7)+,d1-a6
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
PatchError	rts

;********************************************************************************************

		cnop	0,4

Buffer
SegList			ds.l	1
PPCCodeMem		ds.l	1
_PowerPCBase		ds.l	1
SonnetBase		ds.l	1
DosBase			ds.l	1
ExpBase			ds.l	1
PCIBase			ds.l	1
LExecBase		ds.l	1
UtilBase		ds.l	1
ROMMem			ds.l	1
GfxMem			ds.l	1
GfxLen			ds.l	1
GfxType			ds.l	1
GfxConfig		ds.l	1
ComProc			ds.l	1
SonAddr			ds.l	1
EUMBAddr		ds.l	1
PMEPAddr		ds.l	1
XCSRAddr		ds.l	1
MPICAddr		ds.l	1
AddTaskAddress		ds.l	1
RemTaskAddress		ds.l	1
OpenLibAddress		ds.l	1
AllocMemAddress		ds.l	1
CPAddress		ds.l	1
CNPAddress		ds.l	1
RCAddress		ds.l	1
STLAddress		ds.l	1
LoadSegAddress		ds.l	1
NewLoadSegAddress	ds.l	1
MasterControlPort	ds.l	1
FIFOBuffer		ds.l	1
FIFORead		ds.w	1
FIFOWrite		ds.w	1
ConfigDevNum		ds.l	1
MediatorType		ds.l	1
MirrorList		ds.l	3
RemSysTask		ds.l	1
BufCopySrc		ds.l	1
BufCopyDst		ds.l	1
BufCopySz		ds.l	1
Previous		ds.l	1
Previous2		ds.l	1
StartBAT		ds.l	1
SizeBAT			ds.l	1
Options68K		ds.l	1
ENVBuff			ds.l	1
ENVOptions		ds.l	3
MyInterrupt		ds.b	IS_SIZE

	cnop	0,4

ZenInterrupt		ds.b	IS_SIZE

	cnop	0,4
	
WARPDATATABLE:
	INITBYTE	LN_TYPE,NT_LIBRARY
	INITLONG	LN_NAME,WarpName
	INITBYTE	LIB_FLAGS,LIBF_SUMMING|LIBF_CHANGED
	INITWORD	LIB_VERSION,5
	INITWORD	LIB_REVISION,1
	INITLONG	LIB_IDSTRING,WarpIDString
	ds.l	1

POWERDATATABLE:
	INITBYTE	LN_TYPE,NT_LIBRARY
	INITLONG	LN_NAME,PowerName
	INITBYTE	LIB_FLAGS,LIBF_SUMMING|LIBF_CHANGED
	INITWORD	LIB_VERSION,17
	INITWORD	LIB_REVISION,13
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
	dc.l	StartSystem

EndFlag		dc.l	-1
WarpName	dc.b	"warp.library",0
WarpIDString	dc.b	"$VER: warp.library 5.1 (22.3.17)",0
PowerName	dc.b	"powerpc.library",0
PowerIDString	dc.b	"$VER: powerpc.library 17.13b (19.12.20)",0
DebugString	dc.b	"Process: %s Function: %s r4,r5,r6,r7 = %08lx,%08lx,%08lx,%08lx",10,0
DebugString2	dc.b	"Process: %s Function: %s r3 = %08lx",10,0
		
PowerPCError	dc.b	"Other PPC library already active (WarpOS/Sonnet)",0
LDOSError	dc.b	"Could not open dos.library V37+",0
LExpError	dc.b	"Could not open expansion.library V37+",0
LPCIError	dc.b	"Could not open pci.library V13.8+",0
MedError	dc.b	"Could not find a supported Mediator board",0
PPCCardError	dc.b	"No PPC card detected",0
NBridgeError	dc.b	"No supported PPC PCI bridge detected",0
VGAError	dc.b	"No supported VGA card detected",0
MemVGAError	dc.b	"Could not allocate VGA memory",0
PPCMMUError	dc.b	"Error during MMU setup of PPC",0
GenMemError	dc.b	"General memory allocation error",0
LSetupError	dc.b	"Error during library function setup",0
NoWarpLibError	dc.b	"Could not set up fake warp.library",0
SonnetMemError	dc.b	"No memory detected on the PPC card",0
SonnetUnstable	dc.b	"Memory corruption detected during setup",0
PPCCrash	dc.b	"PowerPC CPU possibly crashed during setup",0
NoPPCFound	dc.b	"PowerPC CPU not responding",0
StackRunError	dc.b	"RunPPC Stack transfer error",0
MedWindowJ	dc.b	"Mediator WindowSize jumper incorrectly configured",0
IllegalMsg	dc.b	"Illegal message received by MasterControl",0
WrongPPCLib	dc.b	"Phase 5 ppc.library detected. Please remove it",0
MasterError	dc.b	"Error setting up 68K MasterControl process",0
PPCTaskError	dc.b	"Error setting up Kryten PPC process",0
PCIMemError	dc.b	"Could not allocate sufficient PCI memory",0
CPUReqError	dc.b	"This library requires a 68LC040 or better",0
NoPPCPCI	dc.b	"PPCPCI environment not set in ENVARC:Mediator",0
PPCErrMem	dc.b	"PPC memory list corruption detected",0
PPCErrAsync	dc.b	"Async Run68K function not supported",0
PPCErrSem	dc.b	"PPC Semaphore in illegal state",0
PPCErrFifo	dc.b	"PPC received an illegal command packet",0
PPCCrashNoWin	dc.b	"PPC crashed but could not output crash window",0
PPCErrorTimeOut	dc.b	"PPC timed out while waiting on 68k",0
MemWrapError	dc.b	"PPC memory wrapping error detected. Please reboot!",0
CardStateError	dc.b	"PPC card in unsupported state",0
KernelPanic	dc.b	"Kernel Panic!",0
AMPName		dc.b	"AmigaAMP",0

ConWindow	dc.b	"CON:0/20/680/250/PowerPC Exception/AUTO/CLOSE/WAIT/"
		dc.b	"INACTIVE",0		

EnEDOMem	dc.b	"sonnet/EnEDOMem",0			;0
EnDebug		dc.b	"sonnet/Debug",0			;1
EnAlignExc	dc.b	"sonnet/EnAlignExc",0			;2
DisL2Cache	dc.b	"sonnet/DisL2Cache",0			;3
DisL2Flush	dc.b	"sonnet/DisL2Flush",0			;4
EnPageSetup	dc.b	"sonnet/EnPageSetup",0			;5
EnDAccessExc	dc.b	"sonnet/EnDAccessExc",0			;6
DisHunkPatch	dc.b	"sonnet/DisHunkPatch",0			;7
SetCMemDiv	dc.b	"sonnet/SetCMemDiv",0			;8
SetCPUComm	dc.b	"sonnet/SetCPUComm",0			;9
EnStackPatch	dc.b	"sonnet/EnStackPatch",0			;10
HarMem		dc.b	"sonnet/Harrier256MB",0			;11

		cnop	0,4
		
CrashMessage	dc.b	"Task name: '%s'  Task address: %08lx",10
		dc.b	"Exception: %s",10,10
		dc.b	"SRR0: %08lx    SRR1:  %08lx     MSR:   %08lx    HID0: %08lx",10
		dc.b	"PVR:  %08lx    DAR:   %08lx     DSISR: %08lx    SDR1: %08lx",10
		dc.b	"DEC:  %08lx    TBU:   %08lx     TBL:   %08lx    XER:  %08lx",10
		dc.b	"CR:   %08lx    FPSCR: %08lx     LR:    %08lx    CTR:  %08lx",10,10
		dc.b	"R0-R3:   %08lx %08lx %08lx %08lx   IBAT0: %08lx %08lx",10
		dc.b	"R4-R7:   %08lx %08lx %08lx %08lx   IBAT1: %08lx %08lx",10
		dc.b	"R8-R11:  %08lx %08lx %08lx %08lx   IBAT2: %08lx %08lx",10
		dc.b	"R12-R15: %08lx %08lx %08lx %08lx   IBAT3: %08lx %08lx",10
		dc.b	"R16-R19: %08lx %08lx %08lx %08lx   DBAT0: %08lx %08lx",10
		dc.b	"R20-R23: %08lx %08lx %08lx %08lx   DBAT1: %08lx %08lx",10
		dc.b	"R24-R27: %08lx %08lx %08lx %08lx   DBAT2: %08lx %08lx",10
		dc.b	"R28-R31: %08lx %08lx %08lx %08lx   DBAT3: %08lx %08lx",10,10

		IFD	_FULLERROR_

		dc.b	"F0-F3:    %s   %s   %s   %s",10		;Unused at the moment
		dc.b	"F4-F7:    %s   %s   %s   %s",10
		dc.b	"F8-F11:   %s   %s   %s   %s",10
		dc.b	"F12-F15:  %s   %s   %s   %s",10
		dc.b	"F16-F19:  %s   %s   %s   %s",10
		dc.b	"F20-F23:  %s   %s   %s   %s",10
		dc.b	"F24-F27:  %s   %s   %s   %s",10
		dc.b	"F28-F31:  %s   %s   %s   %s",10,10

		dc.b	"V0-V3:    %s   %s   %s   %s",10		;Unused at the moment
		dc.b	"V4-V7:    %s   %s   %s   %s",10
		dc.b	"V8-V11:   %s   %s   %s   %s",10
		dc.b	"V12-V15:  %s   %s   %s   %s",10
		dc.b	"V16-V19:  %s   %s   %s   %s",10
		dc.b	"V20-V23:  %s   %s   %s   %s",10
		dc.b	"V24-V27:  %s   %s   %s   %s",10
		dc.b	"V28-V31:  %s   %s   %s   %s",10,10

		ENDC

		dc.b	0

RContinue	dc.b	"Continue",0

		cnop	0,4

Requester	dc.l	$14
		ds.l	4
		
EndCP		end
