CC	= vc +warpos
AS68K	= phxass quiet noexe
ASPPC	= pasm -F2 -ms -mo
COPTS	= -amiga-align -DBIGENDIAN -dontwarn=129


all: wosdb

OBJECTS = stdui.o debugger.o asmdebugger.o ppc_disasm.o exchandler.o \
          newRunPPC.o


wosdb: $(OBJECTS)
	$(CC) -o wosdb $(OBJECTS) -lm -lamiga


stdui.o: stdui.c debugger.h ppc_disasm.h
	$(CC) $(COPTS) -c stdui.c

debugger.o: debugger.c debugger.h ppc_disasm.h
	$(CC) $(COPTS) -c debugger.c

asmdebugger.o: asmdebugger.s warpos_lvo.i
	$(ASPPC) asmdebugger.s

ppc_disasm.o: ppc_disasm.c ppc_disasm.h
	$(CC) $(COPTS) -c ppc_disasm.c

exchandler.o: exchandler.s warpos_lvo.i
	$(ASPPC) exchandler.s

newRunPPC.o: newRunPPC.asm
	$(AS68K) newRunPPC.asm
