
.global		@_PPC_Code,_SysBase,_DOSBase,_PowerPCBase,_LinkerDB


#************************************************************************************************

.section "ppccode","acrx",0x1005	#MUST be in Sonnet memory!
		
#************************************************************************************************

@_PPC_Code:

.long			PPC_Code

PPC_Code:		stw	r2,20(r1)
			mflr	r0
			stw	r0,8(r1)
			mfcr	r0
			stw	r0,4(r1)
			stw	r13,-4(r1)
			subi	r13,r1,4
			stwu	r1,-1024(r1)

			nop
			
			lwz	r1,0(r1)
			lwz	r13,-4(r1)
			lwz	r0,8(r1)
			mtlr	r0
			lwz	r0,4(r1)
			mtcr	r0
			lwz	r2,20(r1)
			
			blr
			

#************************************************************************************************

.section "ppcdata","adrw",0x1005	#MUST be in Sonnet memory!
		
#************************************************************************************************

_LinkerDB:
.long		0
_SysBase:
.long		0
_DOSBase:
.long		0
_PowerPCBase:
.long		0
			