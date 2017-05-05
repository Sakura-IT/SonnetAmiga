CC	= vc +warpos
AS68K	= vasmm68k_mot -Fhunk
ASPPC	= vasmppc_std -Fhunk
COPTS	= -amiga-align -DBIGENDIAN -dontwarn=129

all: wosdb

OBJECTS = stdui.o debugger.o asmdebugger.o ppc_disasm.o exchandler.o \
          newRunPPC.o

wosdb: $(OBJECTS)
	$(CC) -v -o wosdb $(OBJECTS) -lm -lamiga

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

