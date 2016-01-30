**
**  startup.asm  V2.3
**
**  VBCC startup code for PowerPC programs using WarpOS/PowerOpen
**  (c)1998-2004,2011 by Frank Wille
**
**
** Entered with:
** d0 = dosCmdLen
** a0 = CmdBuf
**
** Calls:
**  int _ppc_startup(int argc, char *argv[])  in vc.lib
** For Workbench startup: argc=0, argv=WBenchMsg
**
**
** Global Data:
** _PowerPCBase WarpOS powerpc.library
** _SysBase	The usual pointer to the ExecBase structure.
** _DOSBase	dos.library V37, undefined for MINSTART
** _stdin, _stdout, _stderr : Private! Will be used by vbcc's _main()
**		startup routine to initialize ANSI-stdio.
**		Undefined for MINSTART.
** _WBenchMsg	Pointer to WB-startup message, when started from WB.
**		Undefined, if WBSTART was not set.
**
**
** Linking of WarpOS programs (e.g. by using vlink):
**  vlink -oprog startup.o prog.o vc.lib x.o
**
**
**  V2.3  05-Jan-11  phx
**        Define _errno here, for compatbility with 68k startup code.
**  V2.2  10-Oct-08  phx
**        vbcc 0.9
**  V2.1  02-Jun-04  phx
**        There was one byte too less allocated for the command name. Fixed.
**  V2.0  17-Jan-03  phx
**        Removed obsolete pr_ReturnAddr dependancy. This will no
**        longer work with OS4.x.
**  V1.3  26-Apr-02  phx
**        _WBenchMsg for SAS/C V6.x compatibility.
**  V1.2  04-Nov-00  phx
**        vc.lib's malloc/realloc/free require powerpc.library V15, so this
**        startup code will exit with minor versions.
**  V1.1  21-Dec-98  phx
**        Included vbcc compiler version string.
**  V1.0  29-Oct-98  phx
**        Use _LinkerDB. vlink 0.6 no longer uses a small data offset
**        of 0x8000 but 0x7ffe. This startup code will not run will
**        older versions of vlink.
**  V0.4  16-Jun-98  phx
**        Erroneously opened "NIL" instead of "NIL:".
**        TOCD-hack was removed, because vbccppc supports elementary
**        data types in TOC now.
**  V0.3  10-Mar-98  phx
**        Prefix for TOC symbols is "@_" and not "@".
**  V0.2  07-Mar-98  phx
**        This version seems to work! warpup.o has to be linked from
**        startup.o and buf.o, which implements a buffer-zone against
**        cache-alignment problems. The buffer at the end of each section
**        is supplied by x.o, which always has to be linked as the last
**        object.
**  V0.1  03-Mar-98  phx
**        Calls _ppc_startup(), which is a PowerPC-assembler function
**        and is now responsible for calling _main(argc, argv).
**        exit() and _exit() are no longer here, as they have to be
**        PPC functions too.
**        Renamed "tocd" into ".tocd".
**  V0.0  27-Feb-98  phx
**        created
**

	idnt	"startup.asm"

; System Includes
        include "exec/types.i"
        include "exec/alerts.i"
        include "exec/memory.i"
        include "libraries/dos.i"
        include "libraries/dosextens.i"
        include "workbench/startup.i"


; WarpOS Include
	include	"powerpc/powerpc.i"

CALLSYS	macro
	CALLLIB	_LVO\1
	endm


; Defines
VER		equ	2
REV		equ	3
ABSEXECBASE	equ	4
POWERPC_VER	equ	15	; required version of powerpc.library
VBCC_VER	macro
		dc.b	"VBCC 0.9"
		endm

; exec.library LVOs
_LVOCloseLibrary equ	-414
_LVOFindTask	equ	-294
_LVOForbid	equ	-132
_LVOGetMsg	equ	-372
_LVOOpenLibrary	equ	-552
_LVOReplyMsg	equ	-378
_LVOWaitPort	equ	-384

; dos.library LVOs
_LVOCurrentDir	equ	-126
_LVOOpen	equ	-30
_LVOClose	equ	-36
_LVOInput	equ	-54
_LVOOutput	equ	-60

; powerpc.library LVOs (M68k)
_LVORunPPC	equ	-30
_LVOAllocVec32	equ	-54
_LVOFreeVec32	equ	-60



; Code
	section	"startup",code

; ".tocd" section can be accessed base relative for M68k
	near	a4,1

; global symbols from tocd
	xdef	_PowerPCBase
	xdef	_SysBase
	xdef	_DOSBase
	xdef	_WBenchMsg
	xdef	__WBenchMsg	; SAS/C V6.x compatibility
	xdef	__stdin
	xdef	__stdout
	xdef	__stderr
	xdef	_errno

; vc.lib entry point (this is already a PowerPC function!)
	xref	__ppc_startup

; _LinkerDB linker symbol defines the small data base (M68k: a4, PPC: r2)
	xref	_LinkerDB


startup:
	bra.b	0$
	VBCC_VER
0$:	move.l	d0,d2
	move.l	a0,a2
	lea	_LinkerDB,a4
	move.l	sp,initialSP(a4)
	move.l	ABSEXECBASE.w,a6
	move.l	a6,_SysBase(a4)		; exec.library base pointer
	sub.l	a1,a1
	CALLSYS	FindTask		; a5: get current M68k task pointer
	move.l	d0,a5
	moveq	#37,d0
	lea	DOSName(pc),a1
	CALLSYS	OpenLibrary
	move.l	d0,_DOSBase(a4)		; dos.library V37 base pointer
	beq	error
	moveq	#POWERPC_VER,d0
	lea	PowerPCName(pc),a1
	CALLSYS	OpenLibrary
	move.l	d0,_PowerPCBase(a4)	; powerpc.library base pointer
	beq	error

; estimate max number of required argv slots
	move.l	a2,a0
	moveq	#0,d3
	moveq	#4,d4			; 3 should be enough, but...
	move.l	pr_CLI(a5),d1
	bne	2$
	moveq	#2,d4			; alloc 2 argv's for WB startup
	moveq	#8,d2			; fake command line size
	bra	3$
1$:	cmp.b	#' ',d0			; count blanks in command line
	bne	2$
	addq.w	#1,d4
2$:	move.b	(a0)+,d0
	bne	1$
	lsl.l	#2,d1
	move.l	d1,a0
	move.l	cli_CommandName(a0),d1
	lsl.l	#2,d1
	move.l	d1,a0
	move.b	(a0)+,d3		; d3: size of command name
	clr.b	0(a0,d3.l)
	move.l	a0,d6			; d6: CLI CommandName

; allocate memory for argv slots and buffer
3$:	move.l	_PowerPCBase(a4),a6
	move.l	d4,d0
	lsl.l	#2,d0			; bytes needed for argv slots
	move.l	d0,d5
	add.l	d2,d0			;  plus command line size
	add.l	d3,d0			;  plus command name size
	addq.l	#1,d0
	move.l	#MEMF_PUBLIC|MEMF_CLEAR,d1
	CALLSYS	AllocVec32
	move.l	d0,argv_slots(a4)
	beq	error
	subq.l	#1,d4			; d4: max argc
	move.l	d0,a3			; a3: argv slots
	lea	0(a3,d5.l),a1		; a1: argv buffer

; allocate and initialize PPStruct on stack
	sub.w	#PP_SIZE,sp
	move.l	#__ppc_startup,PP_CODE(sp) ; set PowerPC function to call
	clr.l	PP_OFFSET(sp)
	clr.l	PP_FLAGS(sp)
	clr.l	PP_STACKPTR(sp)
	clr.l	PP_STACKSIZE(sp)
	move.l	a4,PP_REGS+12*4(sp)	; save tocd in r2 for PowerPC
	tst.l	d3
	beq	fromWorkbench		; started from Workbench


; CLI Startup Code
fromCLI:
; d2 = dos command line length
; d3 = size of command name
; d4 = max argc
; d6 = CLI command name pointer
; a1 = argv buffer
; a2 = dos command line buffer
; a3 = argv
; a4 = tocd base pointer
; a5 = Task
; a6 = PowerPCBase
; SP = PPStruct
	move.l	a3,PP_REGS+1*4(sp)	; save argv in r4 for PowerPC
	move.l	d6,a0
	move.l	a1,(a3)+		; argv[0] : copy command name
1$:	move.b	(a0)+,(a1)+
	bne	1$
	moveq	#1,d5			; d5: argc = 1

; kill trailing control characters in command line
	lea	0(a2,d2.l),a0
2$:	cmp.b	#' ',-(a0)
	dbhi	d2,2$
	clr.b	1(a0)

; start gathering arguments into buffer
nextarg:
	move.b	(a2)+,d0
	beq	arg_ok
	cmp.b	#' ',d0
	beq	nextarg
	cmp.b	#9,d0
	beq	nextarg
	cmp.l	d4,d5			; argc overflow?
	beq	arg_ok
	move.l	a1,(a3)+		; store argv-pointer
	addq.w	#1,d5			; ++argc
	cmp.b	#'"',d0
	beq	3$			; process quotes
1$:	move.b	d0,(a1)+
	move.b	(a2)+,d0
	beq	arg_ok
	cmp.b	#' ',d0
	bne	1$
2$:	clr.b	(a1)+			; terminate argument
	bra	nextarg
3$:	move.b	(a2)+,d0
	beq	arg_ok
	cmp.b	#'"',d0
	beq	2$
	cmp.b	#'*',d0			; BCPL escape character?
	bne	10$
	moveq	#-$21,d0
	and.b	(a2)+,d0
	cmp.b	#'N',d0			; newline?
	bne	4$
	moveq	#10,d0
	bra	10$
4$:	cmp.b	#'E',d0			; escape?
	bne	10$
	moveq	#27,d0
10$:	move.b	d0,(a1)+
	bra	3$			; next quoted character
arg_ok:
	clr.b	(a1)			; null terminate the arguments
	clr.l	(a3)
	move.l	d5,PP_REGS+0*4(sp)	; save argc in r3 for PowerPC

; init standard input/output handle
	move.l	_DOSBase(a4),a6
	CALLSYS	Input
	move.l	d0,__stdin(a4)
	CALLSYS	Output
	move.l	d0,__stdout(a4)
	move.l	d0,__stderr(a4)
	bra	do_main			; run __ppc_startup() function

; Workbench Startup Code
fromWorkbench:
; a5 = Task
; SP = PPStruct
	bsr	getWBMsg
	move.l	d0,_WBenchMsg(a4)
	move.l	d0,__WBenchMsg(a4)
	move.l	d0,PP_REGS+1*4(sp)	; save WBenchMsg in r4 for PowerPC
	clr.l	PP_REGS+0*4(sp)		; argc=0, passed in r3 for PowerPC
	move.l	_DOSBase(a4),a6
	move.l	d0,a2
	move.l	sm_ArgList(a2),d0	; get first WB argument
	beq	1$
	move.l	d0,a0
	move.l	wa_Lock(a0),d1		; set current directory
	CALLSYS	CurrentDir
1$:
; open "NIL:" for WB standard input/output handles
	lea	NilName(pc),a0
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2
	CALLSYS	Open
	move.l	d0,__stdin(a4)
	move.l	d0,__stdout(a4)
	move.l	d0,__stderr(a4)
; set the console task, so Open( "*", mode ) will work
	move.l	d0,pr_CIS(a5)
	move.l	d0,pr_COS(a5)
	lsl.l	#2,d0
	move.l	d0,a0
	move.l	fh_Type(a0),d0
	beq	do_main
	move.l	d0,pr_ConsoleTask(a5)


; call __ppc_startup() with PowerPC
do_main:
	move.l	_PowerPCBase(a4),a6
	move.l	sp,a0
	CALLSYS	RunPPC			; calls __ppc_startup(argc,argv)
	move.l	PP_REGS+0*4(sp),d2	; return code from r3
	bra	exit


getWBMsg:
; a5 = Task
	move.l	_SysBase(a4),a6
	lea	pr_MsgPort(a5),a0
	CALLSYS	WaitPort
	lea	pr_MsgPort(a5),a0
	CALLSYS	GetMsg
	rts


error:
; if an OpenLibrary() or AllocMem() failed...
	moveq	#RETURN_FAIL,d2
	tst.l	pr_CLI(a5)
	bne	exit
	bsr	getWBMsg

exit:
; a4 = tocd pointer
; a5 = Task

; restore initial stack pointer
	move.l	initialSP(a4),sp

; return WBenchMsg and close WB-output, if started from Workbench
	move.l	_SysBase(a4),a2
	move.l	_WBenchMsg(a4),d3
	beq	1$
	move.l	_DOSBase(a4),a6
	move.l	__stdout(a4),d1
	CALLSYS	Close
	move.l	a2,a6
	CALLSYS	Forbid
	move.l	d3,a1
	CALLSYS	ReplyMsg

; free memory and close libraries
1$:	move.l	_PowerPCBase(a4),d0
	beq	2$
	move.l	d0,a6
	move.l	argv_slots(a4),a1
	CALLSYS	FreeVec32
	move.l	a6,a1
	move.l	a2,a6
	CALLSYS	CloseLibrary
2$:	move.l	a2,a6
	move.l	_DOSBase(a4),d0
	beq	3$
	move.l	d0,a1
	CALLSYS	CloseLibrary

; return to the Shell / Workbench
3$:	move.l	d2,d0
	rts


DOSName:
	dc.b	"dos.library",0
PowerPCName:
	dc.b	"powerpc.library",0
NilName:
	dc.b	"NIL:",0

	dc.b	"vbccWOS startup ",$30+VER,$2e,$30+REV,0



	section	".tocd",data

tocd_base:
		dcb.b	32,0	; Buffer against cache alignment problems
; This section can be accessed base relative by the PowerPC with
; PowerOpen ABI. Its address can always be found in r2.

_PowerPCBase:	dc.l	0
_SysBase:	dc.l	0
_DOSBase:	dc.l	0
_WBenchMsg:	dc.l	0
__WBenchMsg:	dc.l	0	; SAS/C V6.x compatibility
__stdin:	dc.l	0
__stdout:	dc.l	0
__stderr:	dc.l	0
_errno:		dc.l	0
argv_slots:	dc.l	0
initialSP:	dc.l	0
