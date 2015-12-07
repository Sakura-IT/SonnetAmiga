*----------------------------------------------------------------
*
*   PCI Structure
*
*----------------------------------------------------------------

PCI_List	EQU	100
PCI_MemType	EQU	0		;EQ=MEM NE=IO

_LVOPCIFindCard			=	-30
_LVOPCIFindCardbyClass		=	-36
_LVOPCIFindCardbyNumber		=	-42
_LVOPCIEnableInterupt		=	-48
_LVOPCIDisableInterrupt		=	-54
_LVOPCICheckInterrupt		=	-60
_LVOPCIGetZorroWindow		=	-66
_LVOPCISetZorroWindow		=	-72
_LVOPCIAddIntServer		=	-78
_LVOPCIRemoveIntServer		=	-84
_LVOPCIConfigReadByte		=	-90
_LVOPCIConfigReadWord		=	-96
_LVOPCIConfigReadLong		=	-102
_LVOPCIConfigWriteByte		=	-108
_LVOPCIConfigWriteWord		=	-114
_LVOPCIConfigWriteLong		=	-120
_LVOPCIEnablePPCInterrupt	=	-126			;Uncertain. Checks ppc.library and f60020
_LVOPCIDisablePPCInterrupt	=	-132			;Uncertain. Checks ppc.library and f60020
_LVOPCIShutDown			=	-138			;Only works on TX (ID 60) and SX (ID 40)
_LVOPCIInstallVGARAM		=	-144

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
    APTR	PCI_CARDBUS		;Cardbus CIS Pointer	(84)
    APTR	PCI_VENDOR		;Vendor Name		(88)
    APTR	PCI_DEVICE		;Vendor Device		(92)
    ULONG	PCI_UNKNOWN1		;Unknown		(96)
    ULONG	PCI_UNKNOWN2		;Unknown		(100)
    ULONG	PCI_LATGRANTPINLINE	;Max latency etc.	(104)
    LABEL   	PCI_SIZE


