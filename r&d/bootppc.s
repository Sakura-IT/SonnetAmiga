

COMMAND		EQU $4				
PCSRBAR		EQU $14				
OMBAR		EQU $300			
OTWR		EQU $308			
WP_CONTROL	EQU $F48		
WP_TRIG01	EQU $c0000000
mh_Upper	EQU 24

MMU		EQU 1		

	incdir	include:
	include	lvo/exec_lib.i
	include	exec/memory.i
	include pci.i
	include mmu/mmutags.i
	include mmu/context.i
	include	lvo/mmu_lvo.i

	XREF PPCCode,PPCLen

;********************************************************************************************

Main	movem.l d0-a6,-(a7)
	move.l 4.w,a6
	
	lea 322(a6),a0
	lea MemName(pc),a1
	jsr _LVOFindName(a6)
	tst.l d0
	bne.s Exit
	lea 322(a6),a0
	lea PCIMem(pc),a1
	jsr _LVOFindName(a6)
	tst.l d0
	bne.s FndMem
	bra Dirty				;No initialized VGA found
Exit	movem.l (a7)+,d0-a6
	rts
Exit2	move.l a5,a1
	jsr _LVOCloseLibrary(a6)	
	bra.s Exit
	
FndMem	move.l d0,d7
	moveq.l #0,d0
	lea pcilib(pc),a1
	jsr _LVOOpenLibrary(a6)
	tst.l d0
	beq.s Exit
	move.l d0,a5
	
	move.l PCI_List(a5),a2
Loop1	move.l LN_SUCC(a2),d6
	beq.s Exit2
	move.l PCI_VENDORID(a2),d1
	cmp.l #$10570004,d1
	beq.s Sonnet
Loop2	move.l d6,a2
	bra.s Loop1	
	
Sonnet	move.l d7,a0
	move.l mh_Upper(a0),d1
	sub.l #$10000,d1
	and.w #0,d1
	move.l d1,a1
	move.l #$10000,d0
	jsr _LVOAllocAbs(a6)
	tst.l d0
	beq.s Exit2

	move.l d0,a4
	move.l a4,a1
	lea $100(a4),a4
	
	move.l PCI_SPACE1(a2),a3		;PCSRBAR Sonnet
	or.b #15,d0				;64kb
	rol.w #8,d0
	swap d0
	rol.w #8,d0
	move.l d0,OTWR(a3)
	move.l #$0000F0FF,OMBAR(a3)		;Processor outbound mem at $FFF00000
	
	move.l a2,d4
EndDrty	lea PPCCode(pc),a2
	move.l #PPCLen,d6
	lsr.l #2,d6
	subq.l #1,d6	

loop2	move.l (a2)+,(a4)+
	dbf d6,loop2
	jsr _LVOCacheClearU(a6)
	
Shark	move.l #$abcdabcd,$6004(a1)		;Code Word
	move.l #$abcdabcd,$6008(a1)		;Sonnet Mem Start (Translated to PCI)
	move.l #$abcdabcd,$600c(a1)		;Sonnet Mem Len
	
	tst.l d4
	bne.s NoCmm
	move.l d5,a4
	move.l COMMAND(A4),d5
	bset #26,d5				;Set Bus Master bit
	move.l d5,COMMAND(a4)

NoCmm	move.l #WP_TRIG01,WP_CONTROL(a3)	;Negate HRESET

Wait	move.l $6004(a1),d5
	cmp.l #"Boon",d5
	bne.s Wait
	
	IFD MMU
	bsr FunkyMMU
	tst.l d0
	beq.s NoReloc
	move.l #$1000000,d5
	move.l d0,d6
	bra.s Reloc
	
	ENDC
	
NoReloc	move.l #$80000,d7			;Set stack
	move.l $6008(a1),d5
	add.l d7,d5
	move.l $600c(a1),d6
	sub.l d7,d6
	move.l d6,d7
	
	
Reloc	moveq.l #16,d0
	move.l #MEMF_PUBLIC|MEMF_CLEAR|MEMF_REVERSE,d1
	jsr _LVOAllocVec(a6)
	tst.l d0
	beq Exit2
	move.l d0,a0
	lea MemName(pc),a1
	move.l (a1),(a0)
	move.l 4(a1),4(a0)
	move.l 8(a1),8(a0)
	move.l 12(a1),12(a0)
		
	move.l a0,a1
	move.l d5,a0
	move.w #$0a01,8(a0)
	move.l a1,10(a0)
	move.w #$0005,14(a0)
	lea 32(a0),a1
	move.l a1,16(a0)
	clr.l (a1)
	move.l d6,d1
	sub.l #32,d1
	move.l d1,4(a1)
	move.l a1,20(a0)
	add.l a0,d6
	move.l d6,24(a0)
	move.l d1,28(a0)
	move.l a0,a1	
	
	jsr _LVOForbid(a6)	
	lea 322(a6),a0
	tst.l d4
	beq.s NoPCILb
	move.l d4,a2
	move.l d5,PCI_SPACE0(a2)
	subq.l #1,d7
	moveq.l #-1,d5
	sub.l d7,d5
	move.l d5,PCI_SPACELEN0(a2)
NoPCILb	jsr _LVOEnqueue(a6)
	jsr _LVOPermit(a6)
	
	tst.l d4
	beq Exit	
	bra Exit2

;********************************************************************************************

Dirty	moveq.l #0,d2				;Make less dirty by using expansion.library
	moveq.l #$3f,d1				;Now follows some nasty absolute values
	move.l #$40000000,a0			;Start Mediator config
	move.b #$60,(a0)			;Start PCI Mem ($60000000)
CpLoop	move.l #$40800000,a4			;Start PCI config
	move.l d2,d0
	lsl.l #3,d0
	lsl.l #8,d0
	add.l d0,a4
	move.l (a4),d4
	cmp.l #$FFFFFFFF,d4
	beq Exit
	rol.w #8,d4
	swap d4
	rol.w #8,d4
	cmp.l #$00041057,d4
	beq.s SharkPPC
	cmp.l #$0005121a,d4
	beq VooDoo3
VooDone	addq.l #1,d2	
	dbf d1,CpLoop
	bra Exit

SharkPPC
	move.l #$62B00000,a5
	move.l a5,a1
	lea $100(a5),a5
	
	move.l #$00300064,d5			;EUMB at $64003000
	move.l d5,PCSRBAR(a4)
	move.l COMMAND(a4),d5
	bset #25,d5				;Set PCI Memory bit
	move.l d5,COMMAND(a4)
	
	move.l #$64003000,a3			;EUMB at $64003000
	move.l #$0F00B062,OTWR(a3)		;Host outbound PCI mem at $62B00000, 64kb (Code in GFXMem?)
	move.l #$0000F0FF,OMBAR(a3)		;Processor outbound mem at $FFF00000

	move.l OTWR(a3),d5
	moveq.l #0,d4
	move.l a4,d5
	lea $100(a1),a4
	bra EndDrty


VooDoo3	movem.l d0-a6,-(a7)
	move.l	#$62,d5				;Set BAR Voodoo at $62000000
	move.l d5,$14(a4)
	move.l COMMAND(a4),d5
	bset #25,d5				;Set PCI Memory bit (Voodoo3)
	move.l d5,COMMAND(a4)
	movem.l (a7)+,d0-a6
	bra VooDone
;********************************************************************************************

	IFD MMU

FunkyMMU					;make address on 68k appear same as on Sonnet
	movem.l d1-a6,-(a7)			;can't use first 16MB though...
	lea MMUTags(pc),a2
	move.l #$1000000,d7
	move.l $6008(a1),d6
	add.l d7,d6
	move.l d6,4(a2)
	move.l $600c(a1),d5
	moveq.l #0,d0
	lea mmulib(pc),a1
	jsr _LVOOpenLibrary(a6)
	move.l d0,d7
	beq.s NoMMU
	move.l d0,a6
	jsr _LVODefaultContext(a6)
	move.l d0,d6
	beq.s NoMMU2
	move.l d0,a0				;Context
	move.l #MAPP_REMAPPED|MAPP_COPYBACK,d1	;flags
	moveq.l #-1,d2				;Mask
	move.l #$1000000,a1			;Logical
	move.l d5,d0				;Size
	sub.l a1,d0
	move.l d0,d5
	lea MMUTags(pc),a2
	jsr _LVOSetPropertiesA(a6)
	tst.l d0
	beq.s NoMMU2
	move.l d6,a0
	jsr _LVORebuildTree(a6)
	move.l d7,a1
	move.l 4.w,a6
	jsr _LVOCloseLibrary(a6)
	move.l d5,d0
	movem.l (a7)+,d1-a6
	rts	
	
NoMMU2	move.l d7,a1
	move.l 4.w,a6
	jsr _LVOCloseLibrary(a6)
NoMMU	movem.l (a7)+,d1-a6
	moveq.l #0,d0
	rts	

;********************************************************************************************

MMUTags	dc.l MAPTAG_DESTINATION,$7d000000,TAG_DONE,0

mmulib	dc.b "mmu.library",0
	cnop	0,2
	
	ENDC
	
pcilib	dc.b "pci.library",0
	cnop	0,2
MemName	dc.b "Sonnet memory",0
	cnop	0,2
PCIMem	dc.b "pcidma memory",0	
	cnop	0,4
	
;********************************************************************************************	

	