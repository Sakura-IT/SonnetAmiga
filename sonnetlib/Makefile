OBJECTS68K=sonnet.o
OBJECTSPPC=ppcfunctions.o setupppc.o

EXECUTABLE=sonnet.library
EXECUTABLE_RS=sonnet.library.rs

all: $(EXECUTABLE) 

disasm68k : $(EXECUTABLE_RS)

$(EXECUTABLE) : $(OBJECTS68K) $(OBJECTSPPC)
	$(LD) -s $(OBJECTS68K) $(OBJECTSPPC) -o $(EXECUTABLE)

%.o : %.p $(LOCAL_INCS) sonnet_libppc.i
	$(ASMPPC) $(ASMPPCPARAM) -o $@ $< 

%.o : %.s $(LOCAL_INCS) pci.i sonnet_lib.i
	$(ASM68K) $(ASM68KPARAM) -o $@ $<

%.rs : %
	$(IRA) $(IRAPARAM) $< $@

clean :
	$(RM) $(OBJECTS68K) $(OBJECTSPPC) $(EXECUTABLE) $(EXECUTABLE_RS)

