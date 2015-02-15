ASM68K=vasmm68k_mot
ASMPPC=vasmppc_std
LD=vlink

ASM68KPARAM=-m68020up -Fhunk
ASMPPCPARAM=-many -mppc32 -Fhunk

OBJECTS68K=sonnet.o
OBJECTSPPC=setupppc.o ppcfunctions.o
INCLUDES=ppcdefines.i pci.i

RMRF=rm -rf
EXECUTABLE=sonnet.library

all: $(EXECUTABLE) 

$(EXECUTABLE) : $(OBJECTS68K) $(OBJECTSPPC)
	$(LD) -s $(OBJECTS68K) $(OBJECTSPPC) -o $(EXECUTABLE)

%.o : %.p $(INCLUDES)
	$(ASMPPC) $(ASMPPCPARAM) -o $@ $< 

%.o : %.s $(INCLUDES)
	$(ASM68K) $(ASM68KPARAM) -o $@ $<

clean :
	$(RMRF) $(OBJECTS) $(EXECUTABLE)

