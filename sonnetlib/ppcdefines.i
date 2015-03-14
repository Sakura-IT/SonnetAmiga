
#Sonnet Base:
.set SonnetBase,0
.set PowerPCBase,4
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
.set TempMirror,108				#Pointer	HACK

.set Debug,112

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

.set HID0,1008
.set HID0_NHR,			0x00010000
.set HID0_ICFI,			0x00000800
.set HID0_DCFI,			0x00000400
.set HID0_ICE,			0x00008000
.set HID0_DCE,			0x00004000
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

.set PPC_MSR_FP,		0x00002000
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
