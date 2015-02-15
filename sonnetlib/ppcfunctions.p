.include ppcdefines.i

.macro clearreg # reg
		lis \1, 0
		mr \1,\1
.endm

.global SetExcMMU,ClearExcMMU,ConfirmInterrupt,InsertPPC,AddHeadPPC,AddTailPPC
.global RemovePPC,RemHeadPPC,RemTailPPC,EnqueuePPC,FindNamePPC

		.text

#********************************************************************************************
#
#	void SetExcMMU(void) // Only from within Exception Handler
#
#********************************************************************************************

SetExcMMU:
		stw	r4,-8(r1)
		mfmsr	r4
		ori	r4,r4,(PSL_IR|PSL_DR)
		mtmsr	r4				#Reenable MMU
		isync
		lwz	r4,-8(r1)
		blr
	
#********************************************************************************************
#
#	void ClearExcMMU(void) // Only from within Exception Handler
#
#********************************************************************************************

ClearExcMMU:
		stw	r4,-8(r1)
		mfmsr	r4
		andi.	r4,r4,~(PSL_IR|PSL_DR)@l
		mtmsr	r4				#Disable MMU
		isync
		lwz	r4,-8(r1)
		blr	
	
#********************************************************************************************
#
#	void ConfirmInterrupt(void)
#
#********************************************************************************************

ConfirmInterrupt:
		stw	r3,-12(r1)
		stw	r4,-8(r1)
		lis	r3,EUMBEPICPROC
		lwz	r4,0xa0(r3)			#Read IACKR to acknowledge it
		eieio
	
		lis	r3,EUMB
		lis	r4,0x100			#Clear IM0 bit to clear interrupt
		stw	r4,0x100(r3)
		eieio

		clearreg r4
		lis	r3,EUMBEPICPROC
		sync
		stw	r4,0xb0(r3)			#Write 0 to EOI to End Interrupt

		lwz	r4,-8(r1)
		lwz	r3,-12(r1)
		blr

#********************************************************************************************
#
#	void InsertPPC(list, node, nodepredecessor) // r4,r5,r6 Node must be in Sonnet mem to work
#
#********************************************************************************************

InsertPPC:	
		mr.	r6,r6
		beq-	NoPred
		lwz	r3,0(r6)
		mr.	r3,r3
		beq-	Just1
		stw	r3,0(r5)
		stw	r6,4(r5)
		stw	r5,4(r3)
		stw	r5,0(r6)
		b	E1
Just1:		stw	r6,0(r5)
		lwz	r3,4(r6)
		stw	r3,4(r5)
		stw	r5,4(r6)
		stw	r5,0(r3)
		b	E1
NoPred:		lwz	r3,0(r4)			#Same as AddHeadPPC
		stw	r5,0(r4)
		stw	r3,0(r5)
		stw	r4,4(r5)
		stw	r5,4(r3)
E1:		blr	

#********************************************************************************************
#
#	void AddHeadPPC(list, node) // r4,r5 List/Node must be in Sonnet mem to work
#
#********************************************************************************************

AddHeadPPC:
		lwz	r3,0(r4)
		stw	r5,0(r4)
		stw	r3,0(r5)
		stw	r4,4(r5)
		stw	r5,4(r3)
		blr	

#********************************************************************************************
#
#	void AddTailPPC(list, node) // r4,r5 List/Node must be in Sonnet mem to work
#
#********************************************************************************************

AddTailPPC:
		addi	r4,r4,4
		lwz	r3,4(r4)
		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
		blr	

#********************************************************************************************
#
#	void RemovePPC(node) // r4 Node must be in sonnet mem to work
#
#********************************************************************************************

RemovePPC:
		lwz	r3,0(r4)
		lwz	r4,4(r4)
		stw	r4,4(r3)
		stw	r3,0(r4)
		blr	


#********************************************************************************************
#
#	void RemHeadPPC(list) // r4 List must be in Sonnet mem to work
#
#********************************************************************************************

RemHeadPPC:
		lwz	r5,0(r4)
		lwz	r3,0(r5)
		mr.	r3,r3
		beq-	E2
		stw	r3,0(r4)
		stw	r4,4(r3)
		mr	r3,r5
E2:		blr	

#********************************************************************************************
#
#	void RemTailPPC(list) // r4 List must be in Sonnet mem to work (this msg won't be repeated from now on
#
#********************************************************************************************

RemTailPPC:
		lwz	r3,8(r4)
		lwz	r5,4(r3)
		mr.	r5,r5
		beq-	E3
		stw	r5,8(r4)
		addi	r4,r4,4
		stw	r4,0(r5)
E3:		blr	

#********************************************************************************************
#
#	void EnqueuePPC(list, node) // r4,r5
#
#********************************************************************************************

EnqueuePPC:
		lbz	r3,9(r5)
		extsb	r3,r3
		lwz	r6,0(r4)
Loop1:		mr	r4,r6
		lwz	r6,0(r4)
		mr.	r6,r6
		beq-	Link1
		lbz	r7,9(r4)
		extsb	r7,r7
		cmpw	r3,r7
		ble+	Loop1
		lwz	r3,4(r4)
Link1:		stw	r5,4(r4)
		stw	r4,0(r5)
		stw	r3,4(r5)
		stw	r5,0(r3)
		blr	

#********************************************************************************************
#
#	node FindNamePPC(list, name) // r3=r4,r5
#
#********************************************************************************************


FindNamePPC:

		lwz	r3,0(r4)
		mr.	r3,r3
		beq-	E4
		subi	r8,r5,1
Loop2:		mr	r6,r3
		lwz	r3,0(r6)
		mr.	r3,r3
		beq-	E4
		lwz	r4,10(r6)
		mr	r5,r8
		subi	r4,r4,1
Loop3:		lbzu	r0,1(r4)
		lbzu	r7,1(r5)
		cmplw	r0,r7
		bne+	Loop2
		lbz	r0,0(r4)
		mr.	r0,r0
		bne+	Loop3
		mr	r3,r6
E4:		blr	

#********************************************************************************************
#
#
#
#********************************************************************************************
