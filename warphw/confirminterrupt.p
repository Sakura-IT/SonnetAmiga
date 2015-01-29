.include ppcdefines.i
.macro clearreg # reg
		lis \1, 0
		mr \1,\1
.endm


.global	ConfirmInterrupt
	.text

#********************************************************************************************

ConfirmInterrupt:

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

	blr

#********************************************************************************************