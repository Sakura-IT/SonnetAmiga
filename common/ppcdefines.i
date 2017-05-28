# Copyright (c) 2015-2017 Dennis van der Boon
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#Sonnet Memory Map
#0x00000000	Zero Page				0x003000	12288
#0x00003000	Exceptions/Scheduler			0x005000	20480
#0x00100000	Message FIFOs				0x010000	65536	Must be 0x100000 aligned
#0x00200000	Message Frames 2x4096xPP_SIZE+48	0x180000
#0x00380000	Idle Task				0x000c00	3072
#0x00381000	System Stack				0x0EF000	32768
#0x00400000	Free memory
#0x7xf00000	Room for the page table			0x100000	1048576 (for 128MB addressing)


#Overhead = 5MB

#Sonnet Base:

.set SonnetBase,0
.set SysBase,4
.set PPCMemHeader,8
.set DOSBase,12
.set MCPort,16
.set Init,20					#Pointer
.set PowerPCBase,24

.set AdListStart,64
.set AdListEnd,68
.set RTGType,72
.set RTGBase,76
.set RunPPCStart,80
.set ViolationAddress,84			#Pointer
.set MemSize,88

.set option_EnEDOMem,0
.set option_EnDebug,1
.set option_EnAlignExc,2
.set option_DisL2Cache,3
.set option_DisL2Flush,4
.set option_EnPageSetup,5
.set option_EnDAccessExc,6

#LibBase:					All this stuff is PPC only! No access allowed from 68k!

.set sonnet_DebugLevel,72
.set sonnet_EnAlignExc,73
.set sonnet_EnDAccessExc,74
.set sonnet_TaskExitCode,76
.set sonnet_SonnetBase,80
.set sonnet_Atomic,84
.set sonnet_TaskExcept,88			#684
.set sonnet_MemSize,92
.set sonnet_MCPort,96
.set sonnet_L2Size,100
.set sonnet_CurrentL2Size,104
.set sonnet_L2STATE,108
.set sonnet_CPUSDR1,112
.set sonnet_CPUHID0,116
.set sonnet_CPUSpeed,120
.set sonnet_CPUInfo,124

.set LIST_WAITINGTASKS,128
.set LIST_ALLTASKS,144
.set LIST_SNOOP,160
.set LIST_SEMAPHORES,176
.set LIST_REMOVEDEXC,192
.set LIST_READYEXC,208
.set LIST_INSTALLEDEXC,224
.set LIST_EXCINTERRUPT,240
.set LIST_EXCIABR,256
.set LIST_EXCPERFMON,272
.set LIST_EXCTRACE,288
.set LIST_EXCSYSTEMCALL,304
.set LIST_EXCDECREMENTER,320
.set LIST_EXCFPUN,336
.set LIST_EXCPROGRAM,352
.set LIST_EXCALIGN,368
.set LIST_EXCIACCESS,384
.set LIST_EXCDACCESS,400
.set LIST_EXCMCHECK,416
.set LIST_EXCSYSMAN,432
.set LIST_EXCTHERMAN,448
.set LIST_WAITTIME,464
.set LIST_PORTS,480
.set LIST_NEWTASKS,496
.set LIST_READYTASKS,512
.set LIST_REMOVEDTASKS,528
.set LIST_MSGQUEUE,544

.set sonnet_SysBase,566
.set sonnet_WaitListSem,570			#18150
.set sonnet_TaskListSem,574
.set sonnet_SemListSem,578
.set sonnet_PortListSem,582
.set sonnet_SnoopSem,586
.set sonnet_MemSem,590

.set AlignmentExcHigh,594
.set AlignmentExcLow,598
.set DataExcHigh,602
.set DataExcLow,606
.set CurrentPort,610

.set sonnet_DosBase,614

.set sonnet_AltivecOn,621
.set sonnet_ExceptionMode,622
.set DoDFlushAll,623
.set DState,624
.set DLockState,625
.set RescheduleFlag,626
.set FLAG_WAIT,627
.set PortInUse,628
.set BusyCounter,629
.set NumAllTasks,630
.set ThisPPCProc,634
.set StartTBL,638
.set CurrentTBL,642
.set CPULoad,646
.set SystemLoad,650
.set Table_NICE,654
.set LowActivityPrio,658
.set IdSysTasks,662
.set IdDefTasks,666
.set LowActivityPrioOffset,670
.set TaskListSem,674
.set SemListSem,726
.set PortListSem,778
.set SnoopSem,830
.set MemSem,882
.set WaitListSem,934
.set SemMemory,992
.set sonnet_ExceptionBATs,1184
.set sonnet_StoredBATs,1248
.set sonnet_SystemBATs,1312

.set sonnet_PosSize,1376			#Library PosSize

.set EXCDATA_TYPE,8				#Always NT_INTERRUPT
.set EXCDATA_PRI,9				#This
.set EXCDATA_NAME,10
.set EXCDATA_CODE,14
.set EXCDATA_DATA,18
.set EXCDATA_TASK,22
.set EXCDATA_FLAGS,26
.set EXCDATA_EXCID,30
.set EXCDATA_REMOVALTIME,34
.set EXCDATA_TIMEBASEUPPER,38
.set EXCDATA_TIMEBASELOWER,42			#Up and including this copied to MEM
.set EXCDATA_LASTEXC,46
.set SIZE_EXCNODE,EXCDATA_LASTEXC
.set EXCDATA_MCHECK,50
.set EXCDATA_DACCESS,54
.set EXCDATA_IACCESS,58
.set EXCDATA_ALIGN,62
.set EXCDATA_PROGRAM,66
.set EXCDATA_FPUN,70
.set EXCDATA_DECREMENTER,74
.set EXCDATA_SYSTEMCALL,78
.set EXCDATA_TRACE,82
.set EXCDATA_PERFMON,86
.set EXCDATA_IABR,90
.set EXCDATA_INTERRUPT,94
.set SIZE_EXCDATA,EXCDATA_INTERRUPT+4
.set EXCRETURN_ABORT,1
.set XCO_SIZE,8
.set EC_SIZE,424

.set TASKPPC_BAT0,0
.set TASKPPC_BAT1,16
.set TASKPPC_BAT2,32
.set TASKPPC_BAT3,48

.set CHMMU_BAT0,0
.set CHMMU_BAT1,1
.set CHMMU_BAT2,2
.set CHMMU_BAT3,3

.set BASE_STOREBAT0,sonnet_StoredBATs
.set BASE_STOREBAT1,sonnet_StoredBATs+16
.set BASE_STOREBAT2,sonnet_StoredBATs+32
.set BASE_STOREBAT3,sonnet_StoredBATs+48

.set CHMMU_STANDARD,1
.set CHMMU_BAT,2

.set BASE_INVALBATS,546

.set CONTEXT_CODE,		0
.set CONTEXT_SRR1,		4
.set CONTEXT_LR,		8
.set CONTEXT_CR,		12
.set CONTEXT_CTR,		16
.set CONTEXT_XER,		20
.set CONTEXT_REGS,		24		#128 bytes long
.set CONTEXT_STACK,		28		#r1
.set CONTEXT_TOC,		32		#r2
.set CONTEXT_R3,		36
.set CONTEXT_R4,		40
.set CONTEXT_R5,		44
.set CONTEXT_R6,		48
.set CONTEXT_R7,		52
.set CONTEXT_R8,		56
.set CONTEXT_R9,		60
.set CONTEXT_R10,		64
.set CONTEXT_FREGS,		152		#256 bytes long
.set CONTEXT_BATS,		412		#64 bytes long
.set CONTEXT_SEGMENTS,		480		#64 bytes long		
.set CONTEXT_LENGTH,		1076		#544		#End of context

.set MACHINESTATE_DEFAULT,	PSL_IR|PSL_DR|PSL_FP|PSL_PR|PSL_EE|PSL_ME

.set _LVOAllocMem,		-198
.set _LVOFreeMem,		-210
.set _LVOFindName,		-276
.set _LVOSignal,		-306
.set _LVOPutMsg,		-366
.set _LVOVPrintF,		-954
.set _LVOAllocVec,		-684
.set _LVOFreeVec,		-690

.set SysStack,			0x400000		#Length max $a0000
.set IdleTask,			0x380000		#Address of idle task

.set MEMF_PUBLIC,		0x00000001
.set MEMF_CHIP,			0x00000002
.set MEMF_FAST,			0x00000004
.set MEMF_CLEAR,		0x00010000
.set MEMF_PPC,			0x00002000
.set MEMF_REVERSE,		0x00040000

.set MEMB_CHIP,			0x1

.set SonnetBusClock,66666666			#66.6 MHz
.set DecTimerFreq,(SonnetBusClock/4)		#Dec goes at 1/4 of Bus clock
.set SwitchFreq,50				#
.set Quantum,(DecTimerFreq/SwitchFreq)		#
.set QuickQuantum,50

.set EXCATTR_CODE,		0x80101000		#
.set EXCATTR_DATA,		0x80101001		#
.set EXCATTR_TASK,		0x80101002		#
.set EXCATTR_EXCID,		0x80101003		#
.set EXCATTR_FLAGS,		0x80101004		#
.set EXCATTR_NAME,		0x80101005		#
.set EXCATTR_PRI,		0x80101006		#
.set EXCATTR_TIMEDREMOVAL,	0x80101007		#

.set PPCINFO_CPU,		0x80102000		#CPU type (see below)
.set PPCINFO_PVR,             	0x80102001		#PVR value
.set PPCINFO_ICACHE,          	0x80102002		#Instruction cache state
.set PPCINFO_DCACHE,          	0x80102003		#Data cache state
.set PPCINFO_PAGETABLE,       	0x80102004		#Page table location
.set PPCINFO_TABLESIZE,       	0x80102005		#Page table size
.set PPCINFO_BUSCLOCK,        	0x80102006		#PPC bus clock
.set PPCINFO_CPUCLOCK,        	0x80102007		#PPC CPU clock
.set PPCINFO_CPULOAD,         	0x80102008		#Total CPU usage *100 [%]
.set PPCINFO_SYSTEMLOAD,      	0x80102009		#Total system load *100 [%]
.set PPCINFO_L2CACHE,		0x8010200A		#State of L2 Cache (on/off)
.set PPCINFO_L2STATE,		0x8010200B		#L2 in copyback or writethrough?
.set PPCINFO_L2SIZE,		0x8010200C		#Size of L2 Cache

.set HINFO_ALEXC_HIGH,		0x80103000		#For GetHALInfo
.set HINFO_ALEXC_LOW,		0x80103001
.set HINFO_DSEXC_HIGH,		0x80103002
.set HINFO_DSEXC_LOW,		0x80103003

.set SCHED_REACTION,		0x80104000		#Reaction time of low-activity tasks
			
.set CPUF_G3,			0x00200000
.set CPUF_G4,			0x00400000
.set CPUF_750,			0x00200000
.set CPUF_7400,			0x00400000

.set EXC_GLOBAL,0            				#global handler
.set EXC_LOCAL,1             				#task dependant handler
.set EXC_SMALLCONTEXT,2      				#small context structure
.set EXC_LARGECONTEXT,3      				#large context structure
.set EXC_ACTIVE,4            				#private

.set EXCF_GLOBAL,		0x00000001
.set EXCF_LOCAL,		0x00000002
.set EXCF_SMALLCONTEXT,		0x00000004
.set EXCF_LARGECONTEXT,		0x00000008
.set EXCF_ACTIVE,		0x00000010

.set EXCF_MCHECK,		0x00000004
.set EXCF_DACCESS,		0x00000008
.set EXCF_IACCESS,		0x00000010
.set EXCF_INTERRUPT,		0x00000020
.set EXCF_ALIGN,		0x00000040
.set EXCF_PROGRAM,		0x00000080
.set EXCF_FPUN,			0x00000100
.set EXCF_DECREMENTER,		0x00000200
.set EXCF_SYSTEMCALL,		0x00001000
.set EXCF_TRACE,		0x00002000
.set EXCF_PERFMON,		0x00008000
.set EXCF_IABR,			0x00080000
.set EXCF_SYSMAN,		0x00100000
.set EXCF_THERMAN,		0x00800000
.set EXCF_VMXUN,		0x01000000

.set EXC_MCHECK,2            				#machine check exception
.set EXC_DACCESS,3           				#data access exception
.set EXC_IACCESS,4           				#instruction access exception
.set EXC_INTERRUPT,5         				#external interrupt (V15+)
.set EXC_ALIGN,6             				#alignment exception
.set EXC_PROGRAM,7           				#program exception
.set EXC_FPUN,8              				#FP unavailable exception
.set EXC_DECREMENTER,9					#Decrementer exception
.set EXC_SYSTEMCALL,12					#sc instruction exception
.set EXC_TRACE,13            				#trace exception
.set EXC_PERFMON,15          				#performance monitor exception
.set EXC_IABR,19 					#IA breakpoint exception
.set EXC_SYSMAN,20					#system management exception
.set EXC_THERMAN,23					#thermal management exception

.set FPF_EN_OVERFLOW,0        				#enable overflow exception
.set FPF_EN_UNDERFLOW,1       				#enable underflow exception
.set FPF_EN_ZERODIVIDE,2      				#enable zerodivide exception
.set FPF_EN_INEXACT,3         				#enable inexact op. exception
.set FPF_EN_INVALID,4         				#enable invalid op. exception
.set FPF_DIS_OVERFLOW,5       				#disable overflow exception
.set FPF_DIS_UNDERFLOW,6      				#disable underflow exception
.set FPF_DIS_ZERODIVIDE,7     				#disable zerodivide exception
.set FPF_DIS_INEXACT,8        				#disable inexact op. exception
.set FPF_DIS_INVALID,9        				#disable invalid op. exception

.set FPF_ENABLEALL,		0x0000001f		#enable all FP exceptions
.set FPF_DISABLEALL,		0x000003e0		#disable all FP exceptions

.set SDR1,25
.set VRSAVE,256
.set IABR,1010
.set DABR,1013

.set HID0,1008
.set HID0_NHR,			0x00010000
.set HID0_ICFI,			0x00000800
.set HID0_DCFI,			0x00000400
.set HID0_ICE,			0x00008000
.set HID0_DCE,			0x00004000
.set HID0_ILOCK,		0x00002000
.set HID0_DLOCK,		0x00001000
.set HID0_SGE,			0x00000080
.set HID0_BTIC,			0x00000020
.set HID0_BHTE,			0x00000004
.set HID1,1009

.set PICR1,0xA8			#Processor Interface Configuration Register 1
.set PICR1_CF_MP_MULTI,		0x00000003
.set PICR1_SPEC_PCI,		0x00000004
.set PICR1_CF_APARK,		0x00000008
.set PICR1_CF_LOOP_SNOOP,	0x00000010
.set PICR1_CF_LE_MODE,		0x00000020
.set PICR1_ST_GATH_EN,		0x00000040
.set PICR1_NO_BUS_WIDTH_CHECK,	0x00000080
.set PICR1_TEA_EN,		0x00000400
.set PICR1_MCP_EN,		0x00000800
.set PICR1_FLASH_WR_EN,		0x00001000
.set PICR1_CF_LBA_EN,		0x00002000
.set PICR1_PROC_TYPE_7XX,	0x00040000
.set VAL_PICR1,			PICR1_SPEC_PCI|PICR1_CF_APARK|PICR1_CF_LOOP_SNOOP|PICR1_ST_GATH_EN|PICR1_TEA_EN|PICR1_MCP_EN|PICR1_FLASH_WR_EN|PICR1_PROC_TYPE_7XX

.set PICR2,0xAC			#Processor Interface Configuration Register 2
.set PICR2_CF_LBCLAIM_WS,	0x00000600
.set VAL_PICR2,			PICR2_CF_LBCLAIM_WS

.set PMCR1,0x70			#Peripheral Logic Power Management Configuration Register 1
.set PMCR1_SLEEP,		0x0008
.set PMCR1_NAP,			0x0010
.set PMCR1_DOZE,		0x0020
.set PMCR1_BR1_WAKE,		0x0040
.set PMCR1_PM,			0x0080
.set PMCR1_LP_REF_EN,		0x1000
.set PMCR1_NO_SLEEP_MSG,	0x4000
.set PMCR1_NO_NAP_MSG,		0x8000
.set PMCR1_NO_MSG,		0xC000
.set VAL_PMCR1,			PMCR1_DOZE|PMCR1_BR1_WAKE|PMCR1_LP_REF_EN|PMCR1_NO_MSG

.set CACHE_DCACHEOFF,1
.set CACHE_DCACHEON,2
.set CACHE_DCACHELOCK,3
.set CACHE_DCACHEUNLOCK,4
.set CACHE_DCACHEFLUSH,5
.set CACHE_ICACHEOFF,6
.set CACHE_ICACHEON,7
.set CACHE_ICACHELOCK,8
.set CACHE_ICACHEUNLOCK,9
.set CACHE_ICACHEINV,10
.set CACHE_DCACHEINV,11
.set CACHE_L2CACHEON,12
.set CACHE_L2CACHEOFF,13
.set CACHE_L2WTON,14
.set CACHE_L2WTOFF,15
.set CACHE_TOGGLEDFLUSH,16

.set IMIMR,0x104		#Inbound Message Interrupt Mask Register
.set IMISR,0x100		#Inbound Message Interrupt Status Register

.set IMISR_IM0I,		0x00000001		#Inbound Message 0 Interrupt
.set IMISR_IM1I,		0x00000002		#Inbound Message 1 Interrupt
.set IMISR_IPQI,		0x00000020		#Inbound Post Queue Interrupt

.set PCI_COMMAND,0x4
.set OMBAR,0x2300		#Outbound Memory Base Address Register
.set OTWR,0x2308		#Outbound Translation Window Register
.set ITWR,0x2310		#Inbound Translation Window Register
.set LMBAR,0x10			#Local Memory Base Address Register
.set IMR0,0x50			#Inbound Message Register 0
.set MSAR1,0x80			#Memory Start Address Register 1
.set MSAR2,0x84			#Memory Start Address Register 2
.set MESAR1,0x88		#Memory Extended Start Address Register 1
.set MESAR2,0x8C		#Memory Extended Start Address Register 2
.set MEAR1,0x90			#Memory End Address Register 1
.set MEAR2,0x94			#Memory End Address Register 2
.set MEEAR1,0x98		#Memory Extended End Address Register 1
.set MEEAR2,0x9C		#Memory Extended End Address Register 2
.set MBEN,0xA0			#Memory Bank Enable

.set IFHPR,0x120		#Inbound Free_FIFO Head Pointer Register
.set IFTPR,0x128		#Inbound Free_FIFO Tail Pointer Register
.set IPHPR,0x130		#Inbound Post_FIFO Head Pointer Register
.set IPTPR,0x138		#Inbound Post_FIFO Tail Pointer Register
.set OFHPR,0x140		#Outbound Free_FIFO Head Pointer Register
.set OFTPR,0x148		#Outbound Free_FIFO Tail Pointer Register
.set OPHPR,0x150		#Outbound Post_FIFO Head Pointer Register
.set OPTPR,0x158		#Outbound Post_FIFO Tail Pointer Register
.set QBAR,0x170			#Queue Base Address Register
.set MUCR,0x164			#Message Unit Control Register
.set MUCR_CQS_FIFO4K,		0x00000002
.set MUCR_CQE_ENABLE,		0x00000001

.set MCCR1,0xF0			#Memory Control Configuration Register 1
.set MCCR2,0xF4			#Memory Control Configuration Register 2
.set MCCR3,0xF8			#Memory Control Configuration Register 3
.set MCCR4,0xFC			#Memory Control Configuration Register 4

.set SRR1_TRAP,14

.set srr1,27
.set srr0,26
.set ibat0u,528
.set ibat0l,529
.set ibat1u,530
.set ibat1l,531
.set ibat2u,532
.set ibat2l,533
.set ibat3u,534
.set ibat3l,535
.set dbat0u,536
.set dbat0l,537
.set dbat1u,538
.set dbat1l,539
.set dbat2u,540
.set dbat2l,541
.set dbat3u,542
.set dbat3l,543
.set l2cr,1017

.set EPIC_GCR,0x41020		#Global Configuration Register
.set EPIC_PCTPR,0x60080		#Processor Current Task Priority Register
.set EPIC_FRR,0x41000		#Feature Reporting Register
.set EPIC_GTBCR0,0x41110	#Global Timer Base Count Register 0
.set EPIC_GTVPR0,0x41120	#Global Timer Vector/Priority Register 0
.set EPIC_EICR,0x41030		#EPIC interrupt Configuration Register
.set EPIC_IVPR0,0x50200		#Interrupt Vector/Priority Register 0
.set EPIC_IVPR3,0x50260		#Interrupt Vector/Priority Register 3
.set EPIC_IVPR4,0x50280		#Interrupt Vector/Priority Register 4
.set EPIC_IIVPR3,0x510c0	#I2C Interrupt Vector/Priority Register 3

.set I2C_ADR,			0x3000		#I2C Address Register
.set I2C_FDR,			0x3004		#I2C Frequency Divider Register
.set I2C_CCR,			0x3008		#I2C Control Register
.set I2C_CSR,			0x300c		#I2C Status Register
.set I2C_CDR,			0x3010		#I2C Data Register
.set I2C_CCR_MEN,		0x80		#Control Register - Module Enable
.set I2C_CCR_MSTA,		0x20		#Control Register - Master/Slave Mode Start
.set I2C_CCR_MTX,		0x10		#Control Register - Transmit/Receive Mode Select
.set I2C_CCR_TXAK,		0x8		#Control Register - Transfer Acknowledge
.set I2C_CCR_RSTA,		0x4		#Control Register - Repeat Start
.set I2C_CSR_MIF,		0x2		#Status Register - Module Interrupt

.set HW_TRACEON,1				#enable singlestep mode
.set HW_TRACEOFF,2				#disable singlestep mode
.set HW_BRANCHTRACEON,3				#enable branch trace mode
.set HW_BRANCHTRACEOFF,4			#disable branch trace mode
.set HW_FPEXCON,5				#enable FP exceptions
.set HW_FPEXCOFF,6				#disable FP exceptions
.set HW_SETIBREAK,7				#set instruction breakpoint
.set HW_CLEARIBREAK,8				#clear instruction breakpoint
.set HW_SETDBREAK,9				#set data breakpoint (604[E] only)
.set HW_CLEARDBREAK,10
.set HW_CPUTYPE,11				#Private
.set HW_SETDEBUGMODE,12				#Private
.set HW_PPCSTATE,13				#Private
.set HW_NOTAVAILABLE,0
.set HW_AVAILABLE,-1

.set POOL_PUDDLELIST,0
.set POOL_BLOCKLIST,12
.set POOL_REQUIREMENTS,24
.set POOL_PUDDLESIZE,28
.set POOL_TRESHSIZE,32
.set POOL_SIZE,44				#Room for MLN

.set SPRG0,272
.set SPRG1,273
.set SPRG2,274
.set SPRG3,275

.set CONFIG_ADDR,0xFEC0
.set CONFIG_DAT,0xFEE0
.set CMD_BASE,0x80000000
.set EUMBBAR,0x78			#At 0x80000000 (Sonnet side)
.set EUMB,0xF0000000
.set EUMBEPICPROC,EUMB+0x60000
.set EPIC_IACK,0xa0
.set EPIC_EOI,0xb0

.set	PSL_VEC,	0x02000000	#/* ..6. AltiVec vector unit available */
.set	PSL_SPV,	0x02000000	#/* B... (e500) SPE enable */
.set	PSL_UCLE,	0x00400000	#/* B... user-mode cache lock enable */
.set	PSL_POW,	0x00040000	#/* ..6. power management */
.set	PSL_WE,		PSL_POW		#/* B4.. wait state enable */
.set	PSL_TGPR,	0x00020000	#/* ..6. temp. gpr remapping (mpc603e) */
.set	PSL_CE,		PSL_TGPR	#/* B4.. critical interrupt enable */
.set	PSL_ILE,	0x00010000	#/* ..6. interrupt endian mode (1 == le) */
.set	PSL_EE,		0x00008000	#/* B468 external interrupt enable */
.set	PSL_PR,		0x00004000	#/* B468 privilege mode (1 == user) */
.set	PSL_FP,		0x00002000	#/* B.6. floating point enable */
.set	PSL_ME,		0x00001000	#/* B468 machine check enable */
.set	PSL_FE0,	0x00000800	#/* B.6. floating point mode 0 */
.set	PSL_SE,		0x00000400	#/* ..6. single-step trace enable */
.set	PSL_DWE,	PSL_SE		#/* .4.. debug wait enable */
.set	PSL_UBLE,	PSL_SE		#/* B... user BTB lock enable */
.set	PSL_BE,		0x00000200	#/* ..6. branch trace enable */
.set	PSL_DE,		PSL_BE		#/* B4.. debug interrupt enable */
.set	PSL_FE1,	0x00000100	#/* B.6. floating point mode 1 */
.set	PSL_IP,		0x00000040	#/* ..6. interrupt prefix */
.set	PSL_IR,		0x00000020	#/* .468 instruction address relocation */
.set	PSL_IS,		PSL_IR		#/* B... instruction address space */
.set	PSL_DR,		0x00000010	#/* .468 data address relocation */
.set	PSL_DS,		PSL_DR		#/* B... data address space */
.set	PSL_PM,		0x00000008	#/* ..6. Performance monitor */
.set	PSL_PMM,	PSL_PM		#/* B... Performance monitor */
.set	PSL_RI,		0x00000002	#/* ..6. recoverable interrupt */
.set	PSL_LE,		0x00000001	#/* ..6. endian mode (1 == le) */

# general BAT defines for bit settings to compose BAT regs
# represent all the different block lengths
# The BL field	 is part of the Upper Bat Register

.set BAT_BL_128K,		0x00000000
.set BAT_BL_256K,		0x00000004
.set BAT_BL_512K,		0x0000000C
.set BAT_BL_1M,			0x0000001C
.set BAT_BL_2M,			0x0000003C
.set BAT_BL_4M,			0x0000007C
.set BAT_BL_8M,			0x000000FC
.set BAT_BL_16M,		0x000001FC
.set BAT_BL_32M,		0x000003FC
.set BAT_BL_64M,		0x000007FC
.set BAT_BL_128M,		0x00000FFC
.set BAT_BL_256M,		0x00001FFC

# supervisor/user valid mode definitions  - Upper BAT
.set BAT_VALID_SUPERVISOR,	0x00000002
.set BAT_VALID_USER,		0x00000001
.set BAT_INVALID,		0x00000000

# WIMG bit settings  - Lower BAT
.set BAT_WRITE_THROUGH,		0x00000040
.set BAT_CACHE_INHIBITED,	0x00000020
.set BAT_COHERENT,		0x00000010
.set BAT_GUARDED,		0x00000008

# Some BAT Examples

.set VGA_VIRTUAL,		0x62000000
.set VGA_BASE,			0xA2000000

.set IBAT3L_VAL,(VGA_BASE | BAT_READ_WRITE)
.set IBAT3U_VAL,(VGA_VIRTUAL | BAT_BL_32M | BAT_VALID_SUPERVISOR | BAT_VALID_USER)
.set DBAT3L_VAL,(VGA_BASE | BAT_WRITE_THROUGH | BAT_READ_WRITE)
.set DBAT3U_VAL,(VGA_VIRTUAL | BAT_BL_32M | BAT_VALID_SUPERVISOR | BAT_VALID_USER)

# PageTable Access bits

.set PP_USER_RW,2
.set PP_SUPERVISOR_RW,0

# WIMG bit settings  - Lower PTE
.set PTE_WRITE_THROUGH,		0x00000008
.set PTE_CACHE_INHIBITED,	0x00000004
.set PTE_COHERENT,		0x00000002
.set PTE_GUARDED,		0x00000001
.set PTE_COPYBACK,		0x00000000

# Protection bits - Lower BAT
.set BAT_NO_ACCESS,		0x00000000
.set BAT_READ_ONLY,		0x00000001
.set BAT_READ_WRITE,		0x00000002

# Tags for CreateTaskPPC
.set TASKATTR_CODE,		0x80100000
.set TASKATTR_EXITCODE,		0x80100001
.set TASKATTR_NAME,		0x80100002
.set TASKATTR_PRI,		0x80100003
.set TASKATTR_STACKSIZE,	0x80100004
.set TASKATTR_R2,		0x80100005
.set TASKATTR_R3,		0x80100006
.set TASKATTR_R4,		0x80100007
.set TASKATTR_R5,		0x80100008
.set TASKATTR_R6,		0x80100009
.set TASKATTR_R7,		0x8010000A
.set TASKATTR_R8,		0x8010000B
.set TASKATTR_R9,		0x8010000C
.set TASKATTR_R10,		0x8010000D
.set TASKATTR_SYSTEM,		0x8010000E
.set TASKATTR_MOTHERPRI,	0x8010000F
.set TASKATTR_BAT,		0x80100010
.set TASKATTR_PRIVATE,		0x80100011
.set TASKATTR_NICE,		0x80100012
.set TASKATTR_INHERITR2,	0x80100013
.set TASKATTR_ATOMIC,		0x80100014
.set TASKATTR_NOTIFYMSG,	0x80100015

# Bit defines for the L2CR register
.set L2CR_L2E,			0x80000000 		# bit 0 - enable
.set L2CR_L2PE,			0x40000000 		# bit 1 - data parity
.set L2CR_L2SIZ_2M,		0x00000000	 	# bits 2-3 2 MB; MPC7400 ONLY!
.set L2CR_L2SIZ_1M,		0x30000000 		# bits 2-3 1MB
.set L2CR_L2SIZ_HM,		0x20000000 		# bits 2-3 512K
.set L2CR_L2SIZ_QM,		0x10000000 		# bits 2-3 256K; MPC750 ONLY
.set L2CR_L2CLK_1,		0x02000000 		# bits 4-6 Clock Ratio div 1
.set L2CR_L2CLK_1_5,		0x04000000 		# bits 4-6 Clock Ratio div 1.5
.set L2CR_L2CLK_2,		0x08000000 		# bits 4-6 Clock Ratio div 2
.set L2CR_L2CLK_2_5,		0x0a000000 		# bits 4-6 Clock Ratio div 2.5
.set L2CR_L2CLK_3,		0x0c000000 		# bits 4-6 Clock Ratio div 3
.set L2CR_L2RAM_BURST,		0x01000000 		# bits 7-8 burst SRAM
.set L2CR_DO,			0x00400000 		# bit 9 Disable caching of instr. in L2
.set L2CR_L2I,			0x00200000 		# bit 10 Global invalidate bit
.set L2CR_TS,			0x00040000 		# bit 13 Test support on 
.set L2CR_L2WT,			0x00080000		# bit 12 write-through
.set L2CR_L2OH_5,		0x00000000 		# bits 14-15 Output Hold time = 0.5ns*/
.set L2CR_L2OH_1,		0x00010000 		# bits 14-15 Output Hold time = 1.0ns*/
.set L2CR_L2OH_INV,		0x00020000 		# bits 14-15 Output Hold time = 1.0ns*/
.set L2CR_L2IP,			0x00000001

.set L2CR_SIZE_1MB,		0x3000
.set L2CR_SIZE_512KB,		0x2000
.set L2CR_SIZE_256KB,		0x1000
.set L2CR_TS_OFF,		0x0004

.set L2_ADR_INCR,		0x100
.set L2_SIZE_1M,		0x1000
.set L2_SIZE_HM,		0x800
.set L2_SIZE_QM,		0x400

.set L2_SIZE_1M_U,		0x0010
.set L1_CACHE_LINE_SIZE,32

# Node defines
.set NT_TASK,1
.set NT_INTERRUPT,2
.set NT_MESSAGE,5
.set NT_FREEMSG,6
.set NT_REPLYMSG,7
.set NT_MEMORY,10
.set NT_PROCESS,13
.set NT_PPCTASK,100
.set NT_MSGPORTPPC,101
.set NT_XMSG68K,102
.set NT_XMSGPPC,103

.set LN_SUCC,0
.set LN_PRED,4
.set LN_TYPE,8
.set LN_PRI,9
.set LN_NAME,10
.set LN_SIZE,14

#Task defines
.set TC_FLAGS,14
.set TC_STATE,15
.set TC_SIGALLOC,18
.set TC_SIGWAIT,22
.set TC_SIGRECVD,26
.set TC_SIGEXCEPT,30
.set TC_EXCEPTDATA,38
.set TC_EXCEPTCODE,42
.set TC_SPREG,54
.set TC_SPLOWER,58
.set TC_SPUPPER,62
.set TC_MEMENTRY,74

.set TS_RUN,2
.set TS_READY,3
.set TS_WAIT,4
.set TS_REMOVED,6
.set TS_CHANGING,7
.set TS_ATOMIC,8

.set TASKPTR_TASK,14

.set TASKPPC_SYSTEM,0
.set TASKPPC_BAT,1
.set TASKPPC_EMULATOR,2
.set TASKPPC_CHOWN,3
.set TASKPPC_ATOMIC,5

.set TASKPPC_STACKSIZE,92
.set TASKPPC_STACKMEM,96
.set TASKPPC_CONTEXTMEM,100
.set TASKPPC_TASKPTR,104
.set TASKPPC_FLAGS,108
.set TASKPPC_LINK,112

.set TASKLINK_TASK,120
.set TASKLINK_SIG,124
.set TASKLINK_USED,128

.set TASKPPC_BATSTORAGE,130
.set TASKPPC_CORE,134
.set TASKPPC_TABLELINK,138
.set TASKPPC_TABLE,146
.set TASKPPC_DEBUGDATA,150
.set TASKPPC_PAD,154
.set TASKPPC_TIMESTAMP,156
.set TASKPPC_TIMESTAMP2,160
.set TASKPPC_ELAPSED,164
.set TASKPPC_ELAPSED2,168
.set TASKPPC_TOTALELAPSED,172
.set TASKPPC_QUANTUM,176
.set TASKPPC_PRIORITY,180
.set TASKPPC_PRIOFFSET,184
.set TASKPPC_POWERPCBASE,188
.set TASKPPC_DESIRED,192
.set TASKPPC_CPUUSAGE,196
.set TASKPPC_BUSY,200
.set TASKPPC_ACTIVITY,204
.set TASKPPC_ID,208
.set TASKPPC_NICE,212
.set TASKPPC_MSGPORT,216
.set TASKPPC_TASKPOOLS,220
.set TASKPPC_POOLMEM,238
.set TASKPPC_MESSAGERIP,242
.set TASKPPC_STARTMSG,248
.set TASKPPC_MIRROR68K,252
.set TASKPPC_MIRRORPORT,256
.set TASKPPC_CTMEM,272
.set TASKPPC_LENGTH,TASKPPC_CTMEM
.set TASKPPC_SSPPC_RESERVE,1344				#800
.set TASKPPC_PORT,1376					#832
.set TASKPPC_ALLTASK,1476				#932
.set TASKPPC_SSPPC_RESERVE2,1504			#960
.set TASKPPC_INTPORT,1536				#992
.set TASKPPC_NAME,1636					#1092

.set SYS_SIGALLOC,0xFFFF

.set T_PROCTIME,1

#Various defines
.set SS_NESTCOUNT,14
.set SS_WAITQUEUE,16
.set SS_OWNER,40
.set SS_QUEUECOUNT,44
.set SSPPC_SUCCESS,-1
.set SSPPC_NOMEM,0
.set SSPPC_RESERVE,46
.set SSPPC_LOCK,50
.set SSPPC_SIZE,52

.set PA_SIGNAL,0
.set PF_ACTION,3

.set UNIPORT_SUCCESS,-1
.set UNIPORT_NOTUNIQUE,0
.set UNISEM_SUCCESS,-1
.set UNISEM_NOTUNIQUE,0

.set PUBMSG_SUCCESS,-1
.set PUBMSG_NOPORT,0

.set SIGB_SINGLE,4
.set SIGF_SINGLE,16
.set SIGB_DOS,8
.set SIGF_DOS,256
.set SIGF_WAIT,1024

.set MP_FLAGS,14
.set MP_SIGBIT,15
.set MP_SIGTASK,16
.set MP_MSGLIST,20
.set MP_PPC_INTMSG,34
.set MP_PPC_SEM,48

.set pr_MsgPort,92

.set MN_STARTALLOC,10
.set MN_REPLYPORT,14
.set MN_LENGTH,18
.set MN_SIZE,20
.set MN_IDENTIFIER,20
.set MN_MIRROR,24
.set MN_PPC,28
.set MN_PPSTRUCT,32
.set MN_ARG2,176
.set MN_ARG1,180
.set MN_ARG0,184
.set MN_MCPORT,188
.set MN_STACKFRAME,188			# depends on MN type

.set MH_ATTRIBUTES,14			# characteristics of this region
.set MH_FIRST,16			# first free region
.set MH_LOWER,20			# lower memory bound
.set MH_UPPER,24			# upper memory bound+1
.set MH_FREE,28				# number of free bytes
.set MH_SIZE,32

.set ME_ADDR,0
.set ME_LENGTH,4

.set ML_NUMENTRIES,14
.set ML_SIZE,16

.set MC_NEXT,0
.set MC_BYTES,4

.set PPERR_SUCCESS,0
.set PPERR_ASYNCERR,1
.set PPERR_MISCERR,3
.set PP_CODE,MN_PPSTRUCT
.set PP_OFFSET,PP_CODE+4
.set PP_FLAGS,PP_CODE+8
.set PP_STACKPTR,PP_CODE+12
.set PP_STACKSIZE,PP_CODE+16
.set PP_REGS,PP_CODE+20
.set PP_FREGS,PP_CODE+80
.set PP_SIZE,144
.set PPB_ASYNC,0
.set PPB_LINEAR,1
.set PPB_THROW,2
.set PPB_INTASYNC,5
.set PPF_INTASYNC,32

.set ATTEMPT_SUCCESS,-1
.set ATTEMPT_FAILURE,0

.set CMP_EQUAL,0
.set CMP_DESTGREATER,-1
.set CMP_DESTLESS,1

.set MLH_HEAD,0

.set LH_TAILPRED,8
.set LH_HEAD,0
.set LH_TAIL,4

.set SNOOP_CODE,0x80103000
.set SNOOP_DATA,0x80103001
.set SNOOP_TYPE,0x80103002
.set SNOOP_START,1
.set SNOOP_EXIT,2

.set SSM_SEMAPHORE,20

.set TV_SECS,0
.set TV_MICRO,4

.set WAITTIME_TIME1,14
.set WAITTIME_TIME2,18
.set WAITTIME_TASK,22

.set TAG_DONE,0
.set MEMERR_SUCCESS,0

.set PPCSTATEF_POWERSAVE,1	    	# PPC is in power save mode
.set PPCSTATEF_APPACTIVE,2    		# PPC application tasks are active
.set PPCSTATEF_APPRUNNING,4		# PPC apllication task is running
