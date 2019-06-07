# Copyright (c) 2015-2019 Dennis van der Boon
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
.include	sonnet_libppc.i
.include	ppcmacros-std.i
.include	ppcdefines.i
.global		@_PPC_Code,_SysBase,_DOSBase,_PowerPCBase,_LinkerDB

.set		_LVOVPrintF,-954
.set		PP_SIZE,144
.set		PP_CODE,0
.set		PP_OFFSET,4
.set		PP_FLAGS,8
.set		PP_STACKPTR,12
.set		PP_STACKSIZE,16
.set		PP_REGS,20
.set		PPCINFO_CPU,		0x80102000
.set		PPCINFO_PVR,		0x80102001
.set		PPCINFO_ICACHE,		0x80102002
.set		PPCINFO_DCACHE,		0x80102003
.set		PPCINFO_PAGETABLE,	0x80102004
.set		PPCINFO_TABLESIZE,	0x80102005
.set		PPCINFO_BUSCLOCK,	0x80102006
.set		PPCINFO_CPUCLOCK,	0x80102007

#		-- Link this to template_68k.s --

#;************************************************************************************************

.section "ppccode","acrx"
		
#;************************************************************************************************

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

			la	r4,Tags-_LinkerDB(r2)
			
			CALLPOWERPC GetInfo

			la	r4,Args-_LinkerDB(r2)
			la	r5,Tags-_LinkerDB(r2)

			lwz	r6,12(r5)			#PVR Only as test
			stw	r6,4(r4)

			la	r4,infotext-_LinkerDB(r2)	#d1
			la	r22,Args-_LinkerDB(r2)		#d2
									
			RUN68K	_DOSBase,VPrintF
		
			lwz	r1,0(r1)
			lwz	r13,-4(r1)
			lwz	r0,8(r1)
			mtlr	r0
			lwz	r0,4(r1)
			mtcr	r0
			lwz	r2,20(r1)
			
			blr
			
#************************************************************************************************

.section "ppcdata","adrw"
		
#************************************************************************************************

_LinkerDB:
.long		0
_SysBase:
.long		0
_DOSBase:
.long		0
_PowerPCBase:
.long		0

Args:
.long		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

Tags:
.long		PPCINFO_CPU,0,PPCINFO_PVR,0,PPCINFO_CPUCLOCK,0,PPCINFO_BUSCLOCK,0
.long		PPCINFO_ICACHE,0,PPCINFO_DCACHE,0,PPCINFO_PAGETABLE,0,PPCINFO_TABLESIZE,0
.long		0,0
	
infotext:
.byte		"CPU:                   %s   (PVR = %08lx)",10
.byte		"CPU clock:             %ld.%06ld MHz",10
.byte		"Bus clock:             %ld.%06ld MHz",10
.byte		"Instruction Cache:     %s",10
.byte		"Data Cache:            %s",10
.byte		"Page table location:   %08lx",10
.byte		"Page table size:       %ld KBytes",10
.byte		"PPC Uptime:            %ld.%06ld seconds",10
.byte		"CPU load:              %ld.%02ld%%",10
.byte		"System load:           %ld.%02ld%%",10,0


			
