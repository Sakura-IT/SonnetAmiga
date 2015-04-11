
#Sonnet Base:
.set SonnetBase,0
.set SysBase,4
.set PPCMemHeader,8
.set CPUInfo,12
.set CPUHID0,16
.set CPUHID1,20
.set CPUSDR1,24
.set RunningTask,28				#Pointer
.set ReadyTasks,32				#MLH
.set WaitingTasks,44				#MLH
.set Init,56
.set Atomic,60
.set TaskListSem,64				#Pointer
.set Semaphores,68				#MLH
.set SemListSem,80				#Pointer
.set PortListSem,84				#Pointer
.set Ports,88					#MLH
.set ViolationAddress,100			#Pointer
.set MCTask,104					#Pointer
.set TaskException,108				#Pointer
.set DState,112
.set DLockState,113
.set ExceptionMode,114
.set Interrupt,115
.set AllTasks,116				#MLH
.set SnoopSem,128				#Pointer
.set SnoopList,132				#MLH (424)
.set NewTasks,144				#MLH
.set CurrentPort,156
.set NumAllTasks,160				#630
.set IdSysTasks,164				#662
.set IdDefTasks,168				#666
.set MemSem,172
.set PowerPCBase,176
.set UNUSED,188

.set SonnetBusClock,66666666			#66.6 MHz
.set SonnetTimerFreq,(SonnetBusClock/8)		#Default when EICR=0x4 at bits 30-28
.set SwitchFreq,50				#50Hz
.set Quantum,(SonnetTimerFreq/SwitchFreq)	#1/50s

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

.set SDR1,25

.set CPUF_G3,			0x00200000
.set CPUF_G4,			0x00400000
.set CPUF_750,			0x00200000
.set CPUF_7400,			0x00400000

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

.set PICR1,0xA8
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

.set PICR2,0xAC
.set PICR2_CF_LBCLAIM_WS,	0x00000600
.set VAL_PICR2,			PICR2_CF_LBCLAIM_WS

.set PMCR1,0x70
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

.set IMIMR,0x104
.set PCI_COMMAND,0x4
.set OMBAR,0x2300
.set OTWR,0x2308
.set ITWR,0x2310
.set LMBAR,0x10
.set IMR0,0x50
.set MSAR1,0x80
.set MSAR2,0x84
.set MESAR1,0x88
.set MESAR2,0x8C
.set MEAR1,0x90
.set MEAR2,0x94
.set MEEAR1,0x98
.set MEEAR2,0x9C
.set MBEN,0xA0

.set MCCR1,0xF0
.set MCCR2,0xF4
.set MCCR3,0xF8
.set MCCR4,0xFC
.set PVR,287


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

.set EPIC_GCR,0x41020
.set EPIC_PCTPR,0x60080
.set EPIC_FRR,0x41000
.set EPIC_GTBCR0,0x41110
.set EPIC_GTVPR0,0x41120
.set EPIC_EICR,0x41030
.set EPIC_IVPR0,0x50200
.set EPIC_IVPR3,0x50260
.set EPIC_IVPR4,0x50280
.set EPIC_IIVPR3,0x510c0

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
.set L2CR_DO,			0x00400000 		# bit 9 Enable caching of instr. in L2
.set L2CR_L2I,			0x00200000 		# bit 10 Global invalidate bit
.set L2CR_TS,			0x00040000 		# bit 13 Test support on 
.set L2CR_TS_OFF,		~L2CR_TS   		# bit 13 Test support off
.set L2CR_L2OH_5,		0x00000000 		# bits 14-15 Output Hold time = 0.5ns*/
.set L2CR_L2OH_1,		0x00010000 		# bits 14-15 Output Hold time = 1.0ns*/
.set L2CR_L2OH_INV,		0x00020000 		# bits 14-15 Output Hold time = 1.0ns*/
.set L2CR_L2IP,			0x00000001

# first, set address ranges for the devices I’m mapping with the BATs. 
# The memory model for my board has ROM at fff000000 and RAM at 0x00000000. 

.set PROM_BASE,0xFC000000	# IOSPACE and 'ROM'
.set PRAM_BASE,0x00000000
.set VROM_BASE,PROM_BASE
.set VRAM_BASE,PRAM_BASE
.set PCI_BASE,0x80000000
.set IBAT0L_VAL,(PROM_BASE | BAT_CACHE_INHIBITED | BAT_READ_WRITE)
.set IBAT0U_VAL,(VROM_BASE | BAT_VALID_SUPERVISOR | BAT_VALID_USER|BAT_BL_64M)
.set DBAT0L_VAL,IBAT0L_VAL
.set DBAT0U_VAL,IBAT0U_VAL
.set IBAT1L_VAL,(PRAM_BASE | BAT_READ_WRITE)
.set IBAT1U_VAL,(VRAM_BASE | BAT_BL_256M | BAT_VALID_SUPERVISOR | BAT_VALID_USER)
.set DBAT1L_VAL,IBAT1L_VAL
.set DBAT1U_VAL,IBAT1U_VAL
.set IBAT2L_VAL,(PRAM_BASE|BAT_READ_WRITE)
.set IBAT2U_VAL,(VRAM_BASE|BAT_BL_64M|BAT_VALID_SUPERVISOR|BAT_VALID_USER)
.set DBAT2L_VAL,IBAT2L_VAL
.set DBAT2U_VAL,IBAT2U_VAL
.set IBAT3L_VAL,(PCI_BASE | BAT_CACHE_INHIBITED | BAT_READ_WRITE)
.set IBAT3U_VAL,(PCI_BASE | BAT_BL_256M | BAT_VALID_SUPERVISOR | BAT_VALID_USER)
.set DBAT3L_VAL,(PCI_BASE | BAT_CACHE_INHIBITED | BAT_READ_WRITE)
.set DBAT3U_VAL,(PCI_BASE | BAT_BL_256M | BAT_VALID_SUPERVISOR | BAT_VALID_USER)

.set L1_CACHE_LINE_SIZE,32

.set MH_FIRST,16
.set MH_FREE,28
.set MC_BYTES,4
.set MC_NEXT,0
.set LH_HEAD,0
.set LH_TAILPRED,8
.set T_PROCTIME,1
.set TASKATTR_CODE,0x80100000
.set SS_NESTCOUNT,14
.set SS_WAITQUEUE,16
.set SS_OWNER,40
.set SS_QUEUECOUNT,44
.set SSPPC_RESERVE,46
.set SSPPC_LOCK,50
.set PA_SIGNAL,0
.set MP_FLAGS,14
.set MP_SIGBIT,15
.set MP_SIGTASK,16
.set MP_MSGLIST,20
.set MP_PPC_INTMSG,34
.set MP_PPC_SEM,48
.set pr_MsgPort,92
.set MN_SIZE,20
.set MN_IDENTIFIER,20
.set MN_MIRROR,24
.set MN_PPSTRUCT,28
.set PP_SIZE,144
.set NT_MESSAGE,5
.set LN_SUCC,0
.set LN_TYPE,8
.set LN_NAME,10
.set ATTEMPT_SUCCESS,-1
.set ATTEMPT_FAILURE,0
.set TC_MEMENTRY,74
.set LH_TAILPRED,8
.set LH_HEAD,0
.set LH_TAIL,4
.set NT_PPCTASK,100
.set NT_PPCMSGPORT,101
.set LN_PRI,9
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
.set TASKPPC_BATSTORAGE,130
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
.set SYS_SIGALLOC,0xFFFF
.set TC_FLAGS,14
.set TC_STATE,15
.set TC_SIGALLOC,18
.set TC_SIGWAIT,22
.set TC_SIGRECVD,26
.set TC_SIGEXCEPT,30
.set TC_EXCEPTCODE,42
.set TC_EXCEPTDATA,38
.set TC_SPREG,54
.set TC_SPLOWER,58
.set TC_SPUPPER,62
.set TS_RUN,2
.set TS_READY,3
.set TS_REMOVED,6
.set TS_CHANGING,7
.set SSM_SEMAPHORE,20
.set ML_NUMENTRIES,14
.set ML_SIZE,16
.set ME_ADDR,0
.set ME_LENGTH,4
