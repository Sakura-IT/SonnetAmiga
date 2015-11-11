#Sonnet Memory Map
#0x00000000	Zero Page				0x003000	12288
#0x00003000	Exceptions/Scheduler			0x004000	16384
#0x00007000	Semaphores				0x000200	512
#0x00007200	Semaphore memory			0x000200	512
#0x00007400	Idle Task				0x000c00	3072
#0x00008000	System Stack				0x008000	32768
#0x00010000	Free memory				0x0e0000	917504
#0x00100000	Message FIFOs				0x010000	65536	Must be 0x100000 aligned
#0x00110000	Message Frames 2x4096xPP_SIZE+48	0x180000
#0x00290000	Free memory				
#0x02f00000	Room for the page table			0x100000	1048576 (for 128MB addressing)

#Overhead = 3.5MB

#Sonnet Base:
.set SonnetBase,0
.set SysBase,4
.set PPCMemHeader,8
.set DOSBase,12
.set CPUHID0,16
.set CPUHID1,20
.set CPUSDR1,24
.set RunningTask,28				#Pointer
.set ReadyTasks,32				#MLH	; 102(Base)
.set WaitingTasks,44				#MLH	; 116(Base)
.set Init,56
.set Atomic,60
.set TaskListSem,64				#Pointer
.set Semaphores,68				#MLH
.set SemListSem,80				#Pointer
.set PortListSem,84				#Pointer
.set Ports,88					#MLH
.set L2STATE,100
.set MCTask,104					#Pointer
.set TaskException,108				#Pointer
.set DState,112
.set DLockState,113
.set ExceptionMode,114
.set RescheduleFlag,115				#626
.set AllTasks,116				#MLH
.set NewTasks,128				#MLH, Shared, 32 aligned
.set SnoopSem,140				#Pointer
.set SnoopList,144				#MLH (424)
.set CurrentPort,156				#610
.set NumAllTasks,160				#630
.set IdSysTasks,164				#662
.set IdDefTasks,168				#666
.set MemSem,172
.set PowerPCBase,176
.set Break,180
.set LowActivityPrio,184			#658
.set LowActivityPrioOffset,188			#670
.set PortInUse,192				#628	; See CurrentPort
.set PowerDebugMode,193				#18737
.set RTGType,194
.set UNUSED,195
.set AlignmentExcHigh,196
.set AlignmentExcLow,200
.set WaitListSem,204				#18150
.set CPUInfo,208
.set SysStackPointer,212
.set ViolationAddress,216			#Pointer
.set MemSize,220
.set L2Size,224
.set RTGBase,228

#LibBase:

.set LIST_REMOVEDTASKS,130
.set LIST_REMOVEDEXC,382
.set LIST_READYEXC,368
.set LIST_INSTALLEDEXC,356
.set LIST_EXCINTERRUPT,344
.set LIST_EXCIABR,332
.set LIST_EXCPERFMON,320
.set LIST_EXCTRACE,308
.set LIST_EXCSYSTEMCALL,296
.set LIST_EXCDECREMENTER,284
.set LIST_EXCFPUN,272
.set LIST_EXCPROGRAM,260
.set LIST_EXCALIGN,248
.set LIST_EXCIACCESS,236
.set LIST_EXCDACCESS,224
.set LIST_EXCMCHECK,212
.set LIST_WAITTIME,396
.set FLAG_WAIT,627

.set EXCDATA_TYPE,8				#Always NT_INTERRUPT
.set EXCDATA_PRI,9				#This
.set EXCDATA_NAME,10
.set EXCDATA_CODE,14
.set EXCDATA_DATA,18
.set EXCDATA_TASK,22
.set EXCDATA_FLAGS,26
.set EXCDATA_EXCID,30
.set EXCDATA_UNKNOWN1,34
.set EXCDATA_UNKNOWN2,38
.set EXCDATA_UNKNOWN3,42			#Up and including this copied to MEM
.set EXCDATA_LASTEXC,46
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
.set EXCRETURN_ABORT,1
.set XCO_SIZE,8
.set EC_SIZE,424

.set BASE_STOREBAT0,482
.set IBATU0Store,482
.set IBATL0Store,486
.set DBATU0Store,490
.set DBATL0Store,494
.set BASE_STOREBAT1,498
.set IBATU1Store,498
.set IBATL1Store,502
.set DBATU1Store,506
.set DBATL1Store,510
.set BASE_STOREBAT2,514
.set IBATU2Store,514
.set IBATL2Store,518
.set DBATU2Store,522
.set DBATL2Store,526
.set BASE_STOREBAT3,530
.set IBATU3Store,530
.set IBATL3Store,534
.set DBATU3Store,538
.set DBATL3Store,542

.set BASE_INVALBATS,546

.set TASKPPC_BAT0,0
.set TASKPPC_BAT1,16
.set TASKPPC_BAT2,32
.set TASKPPC_BAT3,48

.set CHMMU_BAT0,0
.set CHMMU_BAT1,1
.set CHMMU_BAT2,2
.set CHMMU_BAT3,3

.set CHMMU_STANDARD,1
.set CHMMU_BAT,2

.set _LVOAllocMem,		-198
.set _LVOFreeMem,		-210
.set _LVOFindName,		-276
.set _LVOSignal,		-306
.set _LVOPutMsg,		-366
.set _LVOVPrintF,		-954

.set SysStack,			0x10000			#Length max $8000
.set IdleTask,			0x7400

.set MEMF_PUBLIC,		0x00000001
.set MEMF_FAST,			0x00000004
.set MEMF_CLEAR,		0x00010000
.set MEMF_PPC,			0x00002000

.set SonnetBusClock,66666666			#66.6 MHz
.set SonnetTimerFreq,(SonnetBusClock/8)		#Default when EICR=0x4 at bits 30-28
.set SwitchFreq,50				#50Hz
.set Quantum,(SonnetTimerFreq/SwitchFreq)	#1/50s

.set EXCATTR_CODE,		0x80101000		#
.set EXCATTR_DATA,		0x80101001		#
.set EXCATTR_TASK,		0x80101002		#
.set EXCATTR_EXCID,		0x80101003		#
.set EXCATTR_FLAGS,		0x80101004		#
.set EXCATTR_NAME,		0x80101005		#
.set EXCATTR_PRI,		0x80101006		#

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

.set HINFO_ALEXC_HIGH,		0x80103000		#For GetHALInfo
.set HINFO_ALEXC_LOW,		0x80103001

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
.set HW_NOTAVAILABLE,0
.set HW_AVAILABLE,-1

.set POOL_PUDDLELIST,0
.set POOL_BLOCKLIST,12
.set POOL_REQUIREMENTS,24
.set POOL_PUDDLESIZE,28
.set POOL_TRESHSIZE,32
.set POOL_SIZE,36

.set SPRG0,272
.set SPRG1,273
.set SPRG2,274
.set SPRG3,275

.set CONFIG_ADDR,0xFEC0
.set CONFIG_DAT,0xFEE0
.set CMD_BASE,0x8000
.set VEC_BASE,0xFFF0
.set EUMBBAR,0x78			#At 0x80000000 (Sonnet side)
.set EUMB,0x8000
.set EUMBEPICPROC,0x8006
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

# WIMG bit settings  - Lower PTE
.set PTE_WRITE_THROUGH,		0x00000008
.set PTE_CACHE_INHIBITED,	0x00000004
.set PTE_COHERENT,		0x00000002
.set PTE_GUARDED,		0x00000001

# Protection bits - Lower BAT
.set BAT_NO_ACCESS,		0x00000000
.set BAT_READ_ONLY,		0x00000001
.set BAT_READ_WRITE,		0x00000002

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

.set LH_HEAD,0
.set LH_TAILPRED,8
.set T_PROCTIME,1
.set TASKATTR_CODE,0x80100000
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
.set MN_MCTASK,188
.set MH_ATTRIBUTES,14			# characteristics of this region
.set MH_FIRST,16			# first free region
.set MH_LOWER,20			# lower memory bound
.set MH_UPPER,24			# upper memory bound+1
.set MH_FREE,28				# number of free bytes
.set MC_NEXT,0
.set MC_BYTES,4
.set MH_SIZE,32
.set PP_CODE,MN_PPSTRUCT
.set PP_OFFSET,PP_CODE+4
.set PP_FLAGS,PP_CODE+8
.set PP_REGS,PP_CODE+20
.set PP_FREGS,PP_CODE+80
.set PP_SIZE,144
.set PPB_THROW,2
.set NT_INTERRUPT,2
.set NT_MESSAGE,5
.set NT_FREEMSG,6
.set NT_REPLYMSG,7
.set NT_MEMORY,10
.set LN_SUCC,0
.set LN_PRED,4
.set LN_TYPE,8
.set LN_PRI,9
.set LN_NAME,10
.set LN_SIZE,14
.set ATTEMPT_SUCCESS,-1
.set ATTEMPT_FAILURE,0
.set CMP_EQUAL,0
.set CMP_DESTGREATER,-1
.set CMP_DESTLESS,1
.set TC_MEMENTRY,74
.set LH_TAILPRED,8
.set LH_HEAD,0
.set LH_TAIL,4
.set NT_PPCTASK,100
.set NT_MSGPORTPPC,101
.set NT_MIRRORMSG,102
.set NT_XMSGPPC,103
.set TASKATTR_EXITCODE,0x80100001
.set TASKATTR_NAME,0x80100002
.set TASKATTR_PRI,0x80100003
.set TASKATTR_STACKSIZE,0x80100004
.set TASKATTR_R2,0x80100005
.set TASKATTR_R3,0x80100006
.set TASKATTR_R4,0x80100007
.set TASKATTR_R5,0x80100008
.set TASKATTR_R6,0x80100009
.set TASKATTR_R7,0x8010000A
.set TASKATTR_R8,0x8010000B
.set TASKATTR_R9,0x8010000C
.set TASKATTR_R10,0x8010000D
.set TASKATTR_SYSTEM,0x8010000E
.set TASKATTR_MOTHERPRI,0x8010000F
.set TASKATTR_BAT,0x80100010
.set TASKATTR_PRIVATE,0x80100011
.set TASKATTR_NICE,0x80100012
.set TASKATTR_INHERITR2,0x80100013
.set TASKATTR_ATOMIC,0x80100014
.set TASKATTR_NOTIFYMSG,0x80100015
.set SNOOP_CODE,0x80103000
.set SNOOP_DATA,0x80103001
.set SNOOP_TYPE,0x80103002
.set SNOOP_START,1
.set SNOOP_EXIT,2
.set TASKPPC_ATOMIC,32
.set TASKPPC_SYSTEM,1
.set TASKPPC_BAT,2
.set TASKPPC_EMULATOR,4
.set TASKPPC_STACKSIZE,92
.set TASKPPC_STACKMEM,96
.set TASKPPC_CONTEXTMEM,100
.set TASKPPC_TASKPTR,104
.set TASKPPC_FLAGS,108
.set TASKPPC_LINK,112
.set TASKLINK_SIG,12
.set TASKLINK_USED,16
.set TASKPPC_BATSTORAGE,130
.set TASKPPC_TIMESTAMP2,160
.set TASKPPC_ELAPSED2,168
.set TASKPPC_PRIORITY,180
.set TASKPPC_PRIOFFSET,184
.set TASKPPC_POWERPCBASE,188
.set TASKPPC_ID,208
.set TASKPPC_NICE,212
.set TASKPPC_CHOWN,8
.set TASKLINK_TASK,120
.set TASKPPC_QUANTUM,176
.set TASKPPC_DESIRED,192
.set TASKPPC_ID,208
.set TASKPPC_MSGPORT,216
.set TASKPPC_TASKPOOLS,220
.set TASKPPC_POOLMEM,238
.set TASKPPC_MESSAGERIP,242
.set TASKPPC_STARTMSG,248
.set TASKPPC_CTMEM,256
.set TASKPPC_SSPPC_RESERVE,800
.set TASKPPC_PORT,832
.set TASKPPC_NAME,932
.set SYS_SIGALLOC,0xFFFF
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
.set TS_RUN,2
.set TS_READY,3
.set TS_WAIT,4
.set TS_REMOVED,6
.set TS_CHANGING,7
.set SSM_SEMAPHORE,20
.set ML_NUMENTRIES,14
.set ML_SIZE,16
.set ME_ADDR,0
.set ME_LENGTH,4
.set MLH_HEAD,0
.set TV_SECS,0
.set TV_MICRO,4
.set WAITTIME_TIME1,14
.set WAITTIME_TIME2,18
.set WAITTIME_TASK,22
.set TAG_DONE,0
