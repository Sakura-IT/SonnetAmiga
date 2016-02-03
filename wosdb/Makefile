CC	= vc +sonnet
LD	= vlink
AS68K	= vasmm68k_mot -Fhunk
ASPPC	= vasmppc_std -Fhunk
COPTS	= -amiga-align -DBIGENDIAN -dontwarn=129

LDFLAGS = -bamigaehf -x -Rshort -Bstatic -Cvbcc -nostdlib
LDHUNKATTR = -hunkattr .text=0x2005 -hunkattr newRunPPC=0x2005 -hunkattr .tocd=0x2005 -hunkattr .rodata=0x2005 -hunkattr .data=0x2005 -hunkattr .ctors=0x2005 -hunkattr .dtors=0x2005 -hunkattr .bss=0x2005
VBCC_WARPOS_TARGET = $(VBCC)/ppc-warpos

all: wosdb

OBJECTS = stdui.o debugger.o asmdebugger.o ppc_disasm.o exchandler.o \
          newRunPPC.o


wosdb: $(OBJECTS)
#	$(CC) -v -o wosdb $(OBJECTS) -lm -lamiga
	$(LD) -t $(LDFLAGS) $(VBCC_WARPOS_TARGET)/lib/sonnet.o $(OBJECTS) -lm -lamiga -s -Rshort -L$(VBCC_WARPOS_TARGET)/lib -lvc $(VBCC_WARPOS_TARGET)/lib/x.o  $(LDHUNKATTR) -o $@ 
# XXX: can we avoid calling ld manually here by configuring vbcc correctly?

stdui.o: stdui.c debugger.h ppc_disasm.h
	$(CC) $(COPTS) -c -o $@ $<  

debugger.o: debugger.c debugger.h ppc_disasm.h
	$(CC) $(COPTS) -c -o $@ $<  

asmdebugger.o: asmdebugger.s warpos_lvo.i
	$(ASPPC) -o $@ $<  

ppc_disasm.o: ppc_disasm.c ppc_disasm.h
	$(CC) $(COPTS) -c -o $@ $<  

exchandler.o: exchandler.s warpos_lvo.i
	$(ASPPC) -o $@ $<  

newRunPPC.o: newRunPPC.asm
	$(AS68K)  -o $@ $<  

clean :
	$(RM) $(OBJECTS) wosdb 

