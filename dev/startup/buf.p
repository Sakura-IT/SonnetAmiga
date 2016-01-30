##
##  buf.s
##
##  VBCC startup code for PowerPC programs using WarpOS/PowerOpen
##  (c)1998 by Frank Wille
##
##
## Implements a buffer-zone against cache-alignment problems at
## the beginning of each section.
##
## It will be linked with the M68k startup.o to form the final
## startup code.
##
##  V0.1  07-Mar-98  phx
##        created
##

	.file	"buf.s"

	.text
	.space	32

	.rodata
	.space	32

	.data
	.space	32

	.bss	.bss_start_buf,32
