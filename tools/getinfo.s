FUNC_CNT	SET	-30		* Skip 4 standard vectors
FUNCDEF		MACRO
_LVO\1		EQU	FUNC_CNT 
FUNC_CNT	SET	FUNC_CNT-6	* Standard offset-6 bytes each
		ENDM   

		include powerpc/powerpc.i

		include powerpc/powerpc_lib.i
		include exec/exec_lib.i
		include dos/dos_lib.i
		
PPCINFO_L2CACHE	EQU	$8010200A		;State of L2 Cache (on/off)
PPCINFO_L2STATE	EQU	$8010200B		;L2 in copyback or writethrough?
PPCINFO_L2SIZE	EQU	$8010200C
AlignmentExcLow	EQU	604
DataExcLow	EQU	612

;************************************************************************************************

		section code

;************************************************************************************************		
		
		movem.l d0-a6,-(a7)
		lea infotext,a4
		move.l 4.w,a6
		moveq.l #37,d0
		lea DosLib-infotext(a4),a1
		jsr _LVOOpenLibrary(a6)
		tst.l d0
		beq NoLib
		move.l d0,DosBase-infotext(a4)
		moveq.l #0,d0
		lea PowerPCLib-infotext(a4),a1
		jsr _LVOOpenLibrary(a6)
		tst.l d0
		beq NoLib
		move.l d0,_PowerPCBase-infotext(a4)
		move.l d0,a6
		lea Tags-infotext(a4),a1
		move.l a1,d1
		
		RUNPOWERPC	_PowerPCBase,GetInfo

		lea Time-infotext(a4),a1
		move.l a1,d1
		
		RUNPOWERPC	_PowerPCBase,GetSysTimePPC
		
		lea Tags-infotext(a4),a2
		
		move.l DosBase-infotext(a4),a6
		move.l a4,d1
		lea Args-infotext(a4),a1
		move.l	4(a2),d2
		cmp.l #CPUF_G3,d2
		bne.s NoG3
		lea CPU_750-infotext(a4),a3
		move.l a3,0(a1)
		bra.s GoPVR
		
NoG3		cmp.l #CPUF_G4,d2
		bne.s NoG4
		lea CPU_7400-infotext(a4),a3
		move.l a3,0(a1)
		bra.s GoPVR

NoG4		lea CPU_Unknown-infotext(a4),a3
		move.l a3,0(a1)
		
GoPVR		move.l 12(a2),4(a1)
		move.l 20(a2),d2
		move.l #1000000,d3
		divu.l d3,d2
		move.l d2,8(a1)
		
		move.l 28(a2),d2
		move.l d2,d4
		move.l #1000000,d3
		divu.l d3,d2
		move.l d2,16(a1)
		mulu.l d3,d2
		sub.l d2,d4
		move.l d4,20(a1)
		
		move.l 36(a2),d2
		subq.l #1,d2
		tst.l d2
		bne.s NoOU
		lea CACHE_ON_U-infotext(a4),a3
		move.l a3,24(a1)
		bra.s DCache
		
NoOU		subq.l #1,d2
		bne.s NoOL
		lea CACHE_ON_L-infotext(a4),a3
		move.l a3,24(a1)
		bra.s DCache

NoOL		subq.l #2,d2
		bne.s NoOFU
		lea CACHE_OFF_U-infotext(a4),a3
		move.l a3,24(a1)

NoOFU		lea CACHE_OFF_L-infotext(a4),a3
		move.l a3,24(a1)
		
DCache		move.l 44(a2),d2
		subq.l #1,d2
		tst.l d2
		bne.s NoOU2
		lea CACHE_ON_U-infotext(a4),a3
		move.l a3,28(a1)
		bra.s L2Info
		
NoOU2		subq.l #1,d2
		bne.s NoOL2
		lea CACHE_ON_L-infotext(a4),a3
		move.l a3,28(a1)
		bra.s L2Info

NoOL2		subq.l #2,d2
		bne.s NoOFU2
		lea CACHE_OFF_U-infotext(a4),a3
		move.l a3,28(a1)

NoOFU2		lea CACHE_OFF_L-infotext(a4),a3
		move.l a3,28(a1)
		
L2Info		move.l 68(a2),d2
		beq.s NoL2
		lea L2CACHE_ON-infotext(a4),a3
		move.l a3,64(a1)
		bra.s L2State
		
NoL2		lea L2CACHE_OFF-infotext(a4),a3
		move.l a3,64(a1)

L2State		move.l 76(a2),d2
		beq.s NoL2WT
		lea L2WT-infotext(a4),a3
		move.l a3,68(a1)
		bra.s Done		
		
NoL2WT		lea L2CB-infotext(a4),a3
		move.l a3,68(a1)
		
Done		move.l 52(a2),d2
		move.l d2,32(a1)
		move.l 60(a2),d2
		move.l d2,36(a1)
		
		move.l 84(a2),d2
		move.l #1024,d3
		divu.l d3,d2		
		move.l d2,72(a1)
		
		move.l _PowerPCBase-infotext(a4),a3
		move.l 	AlignmentExcLow(a3),d2
		move.l d2,76(a1)
		move.l 	DataExcLow(a3),d2
		move.l d2,80(a1)
		
		move.l a1,d2
		jsr _LVOVPrintf(a6)
				
NoLib		movem.l (a7)+,d0-a6
		rts

;************************************************************************************************

		section ppcdata,data,$2005	;MUST be in Sonnet memory!
		
;************************************************************************************************		

infotext        dc.b    "CPU:                   %s   (PVR = %08lx)",10
		dc.b    "CPU clock:             %ld.%06ld MHz",10
		dc.b    "Bus clock:             %ld.%06ld MHz",10
		dc.b    "Instruction Cache:     %s",10
		dc.b    "Data Cache:            %s",10
		dc.b    "Page table location:   %08lx",10
		dc.b    "Page table size:       %ld KBytes",10
		dc.b    "PPC Uptime:            %ld.%06ld seconds",10
		dc.b    "CPU load:              %ld.%02ld%%",10
		dc.b    "System load:           %ld.%02ld%%",10
		dc.b	"L2 Cache:              %s",10
		dc.b	"L2 State:              %s",10
		dc.b	"L2 Size:               %ld KBytes",10
		dc.b	"FPU Align Emulation:   %ld times",10
		dc.b	"DSI Emulation:         %ld times",10
		dc.b    0

CPU_603         dc.b    "PPC 603",0
CPU_603E        dc.b    "PPC 603E",0
CPU_604         dc.b    "PPC 604",0
CPU_604E        dc.b    "PPC 604E",0
CPU_620         dc.b    "PPC 620",0
CPU_750		dc.b	"PPC 750",0
CPU_7400	dc.b	"PPC 7400",0
CPU_Unknown     dc.b    "UNKNOWN",0
CACHE_ON_U      dc.b    "ON and UNLOCKED",0
CACHE_OFF_U     dc.b    "OFF and UNLOCKED",0
CACHE_ON_L      dc.b    "ON and LOCKED",0
CACHE_OFF_L     dc.b    "OFF and LOCKED",0
L2CACHE_ON	dc.b	"ENABLED",0
L2CACHE_OFF	dc.b	"DISABLED",0
L2WT		dc.b	"WRITE-THROUGH",0
L2CB		dc.b	"COPY-BACK",0

		cnop    0,4
Args		dc.l	0,0,0,0,0,0,0,0,0,0
Time		dc.l	0,0
		dc.l	0,0,0,0,0,0
		dc.l	0,0,0,0
		
DosBase		dc.l	0
_PowerPCBase	dc.l	0

DosLib		dc.b 	"dos.library",0
		cnop	0,2
PowerPCLib	dc.b	"sonnet.library",0
		cnop	0,4
	
Tags		dc.l	PPCINFO_CPU,0,PPCINFO_PVR,0,PPCINFO_CPUCLOCK,0,PPCINFO_BUSCLOCK,0
		dc.l	PPCINFO_ICACHE,0,PPCINFO_DCACHE,0,PPCINFO_PAGETABLE,0,PPCINFO_TABLESIZE,0
		dc.l	PPCINFO_L2CACHE,0,PPCINFO_L2STATE,0,PPCINFO_L2SIZE,0
		dc.l	0,0
	
;************************************************************************************************

