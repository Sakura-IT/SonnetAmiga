
.global		@_PPC_Code

#;************************************************************************************************

#.section "ppccode","acrx",0x1005	#MUST be in Sonnet memory!
.section "ppccode","acrx"		#code ($3E9) plus memory attributes not working atm.
		
#;************************************************************************************************

@_PPC_Code:

.long			PPC_Code

PPC_Code:		nop
			blr