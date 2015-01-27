	SUPER
	NOEXE

	include ppcdefines.i
	XDEF	ConfirmInterrupt

;********************************************************************************************

ConfirmInterrupt

	lis	r3,EUMBEPICPROC
	lwz	r4,$a0(r3)			;Read IACKR to acknowledge it
	eieio
	
	lis	r3,EUMB
	lis	r4,$100				;Clear IM0 bit to clear interrupt
	stw	r4,$100(r3)
	eieio

	clearreg r4
	lis	r3,EUMBEPICPROC
	sync
	stw	r4,$b0(r3)			;Write 0 to EOI to End Interrupt

	blr

;********************************************************************************************