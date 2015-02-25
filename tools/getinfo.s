		
		include powerpc/powerpc.i

		include powerpc/powerpc_lib.i
		include exec/exec_lib.i
		include dos/dos_lib.i
		
		section code
		
		
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
		move.l d0,PowerPCBase-infotext(a4)
		move.l d0,a6
		
		lea -PP_SIZE(a7),a7
		movem.l d0-a6,PP_REGS(a7)
		move.l a7,a0
		move.l a6,PP_CODE(a7)
		move.l #_LVOGetInfo+2,PP_OFFSET(a7)
		jsr _LVORunPPC(a6)				;No parameter parsing (HACK)
		movem.l PP_REGS(a7),d0-a6
		lea PP_SIZE(a7),a7		
		
		move.l	#$7c000000,a2				;HACK
		add.l $70(a2),a2
		
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

NoOL		subq.l #1,d2
		bne.s NoOFU
		lea CACHE_OFF_U-infotext(a4),a3
		move.l a3,24(a1)

NoOFU		lea CACHE_OFF_L-infotext(a4),a3
		move.l a3,24(a1)
		
DCache		move.l 44(a2),d2
		tst.l d2
		bne.s NoOU2
		lea CACHE_ON_U-infotext(a4),a3
		move.l a3,28(a1)
		bra.s Done
		
NoOU2		subq.l #1,d2
		bne.s NoOL2
		lea CACHE_ON_L-infotext(a4),a3
		move.l a3,28(a1)
		bra.s Done

NoOL2		subq.l #1,d2
		bne.s NoOFU2
		lea CACHE_OFF_U-infotext(a4),a3
		move.l a3,28(a1)

NoOFU2		lea CACHE_OFF_L-infotext(a4),a3
		move.l a3,28(a1)
		
Done		move.l 52(a2),d2
		move.l d2,32(a1)
		move.l 60(a2),d2
		move.l d2,36(a1)
		
		move.l a1,d2
		jsr _LVOVPrintf(a6)
				
NoLib		movem.l (a7)+,d0-a6
		rts



		section data
infotext        dc.b    "CPU:                   %s   (PVR = %08lx)",10
		dc.b    "CPU clock:             %ld.%06ld MHz",10
		dc.b    "Bus clock:             %ld.%06ld MHz",10
		dc.b    "Instruction Cache:     %s",10
		dc.b    "Data Cache:            %s",10
		dc.b    "Page table location:   %08lx",10
		dc.b    "Page table size:       %ld KBytes",10
		dc.b    "Time base content:     %08lx %08lx",10
		dc.b    "CPU load:              %ld.%02ld%%",10
		dc.b    "System load:           %ld.%02ld%%",10
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

		cnop    0,4
Args		dc.l	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0		
DosBase		dc.l	0
PowerPCBase	dc.l	0

DosLib		dc.b 	"dos.library",0
		cnop	0,2
PowerPCLib	dc.b	"sonnet.library",0
		cnop	0,4		
		
PPCInfo_Tags
		dc.l    PPCINFO_CPU
Tag_CPU         dc.l    0
		dc.l    PPCINFO_PVR
Tag_PVR         dc.l    0
		dc.l    PPCINFO_ICACHE
Tag_ICACHE      dc.l    0
		dc.l    PPCINFO_DCACHE
Tag_DCACHE      dc.l    0
		dc.l    PPCINFO_PAGETABLE
Tag_PAGETABLE   dc.l    0
		dc.l    PPCINFO_TABLESIZE
Tag_TABLESIZE   dc.l    0
		dc.l    PPCINFO_BUSCLOCK
Tag_BUSCLOCK    dc.l    0
		dc.l    PPCINFO_CPUCLOCK
Tag_CPUCLOCK    dc.l    0
		dc.l    PPCINFO_CPULOAD
Tag_CPULOAD     dc.l    0
		dc.l    PPCINFO_SYSTEMLOAD
Tag_SYSTEMLOAD  dc.l    0
		dc.l    0