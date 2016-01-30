##
##  x.s
##
##  VBCC startup code for PowerPC programs using WarpOS/PowerOpen
##  (c)1998 by Frank Wille
##
##
## Implements a buffer-zone against cache-alignment problems at
## the end of each section.
##
## x.o must always be linked as the last object of a program!
##
##  V0.1  07-Mar-98  phx
##        created
##

	.file	"x.s"

	.tocd
	.space	32

	.text
	.space	32

	.rodata
	.space	32

	.data
	.space	32

	.bss	.bss_end_buf,32
