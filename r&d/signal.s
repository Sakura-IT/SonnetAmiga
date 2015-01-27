	OPT	P=68060/68851
	OPT	NOLINE
	OPT	AMIGA

IMR0		EQU $50

	incdir	include:
	include system/system.gs
	include	exec/memory.i
	include pci.i

;********************************************************************************************

	movem.l d0-a6,-(a7)
	move.l	4.w,a6
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
	
Sonnet	move.l PCI_SPACE1(a2),a3
	
	move.l #$deadc0de,IMR0(a3)

Exit2	move.l a5,a1
	jsr _LVOCloseLibrary(a6)	
Exit	movem.l (a7)+,d0-a6
	rts

;********************************************************************************************	

pcilib	dc.b "pci.library",0
	cnop	0,2
