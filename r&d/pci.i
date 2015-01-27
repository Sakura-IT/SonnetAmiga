*----------------------------------------------------------------
*
*   PCI Structure
*
*----------------------------------------------------------------

PCI_List	EQU	100
PCI_MemType	EQU	0		;EQ=MEM NE=IO	

 STRUCTURE  	PCI,LN_SIZE
    UWORD   	PCI_VENDORID		;Vendor ID		(14)
    UWORD	PCI_DEVICEID		;Device ID		(16)
    ULONG	PCI_CLASSCODE		;Class Code		(18)
    UBYTE	PCI_REVISION		;Revision ID		(22)
    UBYTE	PCI_INTERRUPT		;Interrupt Pin		(23)
    UWORD	PCI_SUBVENDORID		;Subsystem Vendor ID	(24)
    UWORD	PCI_SUBID		;Subsystem ID		(26)
    APTR	PCI_SPACE0		;IO/Memory Space	(28)
    ULONG	PCI_SPACELEN0		;Length of IO/Memory	(32)
    APTR	PCI_SPACE1		;IO/Memory Space	(36)
    ULONG	PCI_SPACELEN1		;Length of IO/Memory	(40)    
    APTR	PCI_SPACE2		;IO/Memory Space	(44)
    ULONG	PCI_SPACELEN2		;Length of IO/Memory	(48)    
    APTR	PCI_SPACE3		;IO/Memory Space	(52)
    ULONG	PCI_SPACELEN3		;Length of IO/Memory	(56)    
    APTR	PCI_SPACE4		;IO/Memory Space	(60)
    ULONG	PCI_SPACELEN4		;Length of IO/Memory	(64)
    APTR	PCI_SPACE5		;IO/Memory Space	(68)
    ULONG	PCI_SPACELEN5		;Length of IO/Memory	(72)
    APTR	PCI_ROMSPACE		;ROM Space		(76)
    ULONG	PCI_ROMLEN		;Length of EOM		(80)
    ULONG	PCI_UNKNOWN		;Unknown		(84)
    APTR	PCI_VENDOR		;Vendor Name		(88)
    APTR	PCI_DEVICE		;Vendor Device		(92)
    LABEL   	PCI_SIZE


