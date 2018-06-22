* Copyright (c) 2015-2017 Dennis van der Boon
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.

	IFND AFF_68060
AFF_68060		EQU	$0080
	ENDC

SonBase			EQU	0
PPCMemHeader		EQU	8
PPERR_MISCERR		EQU	3
TF_PPC			EQU	4
TB_PPC			EQU	2
TB_WARN			EQU	1
L1_CACHE_LINE_SIZE_040	EQU	16
PCI_OFFSET_COMMAND	EQU 	$4
PCI_OFFSET_ID		EQU	0
MEMORY_SPACE_ENABLE	EQU	$2
BUS_MASTER_ENABLE	EQU	$4
MAX_PCI_SLOTS		EQU	6
IMR0			EQU 	$50
IMR1			EQU	$54
OMISR			EQU 	$30
OMIMR			EQU 	$34
IFQPR			EQU	$40
OFQPR			EQU	$44
OMR0			EQU 	$58
OMR1			EQU 	$5C
LMBAR			EQU 	$10
PCSRBAR			EQU 	$14
OMBAR			EQU 	$300
OTWR			EQU 	$308
OPQI			EQU	$20000000
WP_CONTROL		EQU 	$F48
WP_TRIG01		EQU 	$c0000000
MEMF_PPC		EQU 	$2000
MEMB_PPC		EQU	13
TASKPPC_NAME		EQU	1720
NoMemAccess		EQU	$480000
PageTableSize		EQU	$100000
MSG_LEN			EQU	192
MN_ARG0			EQU	184
MN_ARG1			EQU	180
MN_ARG2			EQU	176
MN_MCPORT		EQU	188
MN_STACKFRAME		EQU	188
_LVORawPutChar		EQU	-516	* Private function in Exec
NT_XMSG68K		EQU	102
VENDOR_ELBOX		EQU	$89e
VENDOR_ATI		EQU	$1002
VENDOR_3DFX		EQU	$121a
VENDOR_MOTOROLA		EQU	$1057
DEVICE_MPC107		EQU	$0004
DEVICE_VOODOO3		EQU	$0005
DEVICE_VOODOO4		EQU	$0007
DEVICE_VOODOO45		EQU	$0009
DEVICE_HARRIER		EQU	$480B
DEVICE_RV280PRO		EQU	$5960
DEVICE_RV280MOB		EQU	$5C63
DEVICE_RV280SE		EQU	$5964
MEDIATOR_MKII		EQU	33
MEDIATOR_1200TX		EQU	60
MEDIATOR_LOGIC		EQU	161
MEDIATOR_1200LOGIC	EQU	-68			* = 188
PCI_VERSION		EQU	13
HW_CPUTYPE		EQU	11	* Private
HW_SETDEBUGMODE		EQU	12	* Private
HW_PPCSTATE		EQU	13	* Private
EXCF_SYSTEMCALL		EQU	$00001000
EXCF_SYSMAN		EQU	$00100000
EXCF_THERMAN		EQU	$00800000
EXCF_VMXUN		EQU	$01000000

* Harrier Stuff

PCFS_MBAR		EQU	$10
PCFS_ITBAR0		EQU	$14
PCFS_ITBAR1		EQU	$18
PCFS_MPAT		EQU	$44
PCFS_ITOFSZ0		EQU	$48
PCFS_ITAT0		EQU	$4C
PCFS_ITOFSZ1		EQU	$50
PCFS_ITAT1		EQU	$54
PCFS_MPAT_ENA		EQU	$00000080
PCFS_MPAT_GBL		EQU	$00010000
PCFS_ITAT0_ENA		EQU	$00000080
PCFS_ITAT0_GBL		EQU	$00010000
PCFS_ITAT1_ENA		EQU	$00000080
PCFS_ITAT1_WPE		EQU	$00000020
PCFS_ITAT1_RAE		EQU	$00000010
PCFS_ITAT1_GBL		EQU	$00010000
PCFS_ITSZ_4K		EQU	$00
PCFS_ITSZ_256MB		EQU	$10
PPC_XCSR_BASE		EQU	$FEFF0000
PPC_RAM_BASE		EQU	$00000000

XCSR_OTAT0_ENA		EQU	$80
XCSR_OTAT0_WPE		EQU	$10
XCSR_OTAT0_SGE		EQU	$08
XCSR_OTAT0_RAE		EQU	$04
XCSR_OTAT0_MEM		EQU	$02
XCSR_XPAT_BAM_ENA	EQU	$20000000
XCSR_XPAT_AD_DELAY15	EQU	$00F00000
XCSR_SDBA_32M8		EQU	$00080000
XCSR_SDBA_ENA		EQU	$00000100
XCSR_SDGC_MXRR_7	EQU	$30000000
XCSR_SDGC_ENRV_ENA	EQU	$00800000
;XCSR_SDTC_DEFAULT	EQU	$07130000
XCSR_SDTC_DEFAULT	EQU	$13331100
XCSR_BXCS_P0H_ENA	EQU	$00100000
XCSR_MBAR_ENA		EQU	$00010000
XCSR_MBAR		EQU	$E0
XCSR_SDGC		EQU	$100
XCSR_SDTC		EQU	$104
XCSR_SDBAA		EQU	$110
XCSR_XPAT0		EQU	$154
XCSR_XPAT1		EQU	$15C
XCSR_BXCS		EQU	$204
XCSR_OTAD0		EQU	$220
XCSR_OTAT0		EQU	$224
XCSR_MIOFH		EQU	$2C0
XCSR_MIOPH		EQU	$2C8
XCSR_MIOPT		EQU	$2CC

PMEP_MIST		EQU	$30
PMEP_MIMS		EQU	$34
PMEP_MIIQ		EQU	$40
PMEP_MIOQ		EQU	$44
PMEP_MGIM0		EQU	$2A0

* Extended libbase (PPCBase)

PPC_SysLib		EQU	34
PPC_DosLib		EQU	38
PPC_SegList		EQU	42
PPC_NearBase		EQU	46
PPC_Flags		EQU	50
PPC_DosVer		EQU	51
PPC_PPCLib		EQU	52

FUNC_CNT	 SET	-30		* Skip 4 standard vectors
FUNCDEF		 MACRO
_LVO\1		 EQU	FUNC_CNT
FUNC_CNT	 SET	FUNC_CNT-6	* Standard offset-6 bytes each
		 ENDM
