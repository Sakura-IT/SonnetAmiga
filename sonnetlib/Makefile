OBJECTS68K=sonnet.o
OBJECTSPPC=ppcfunctions.o setupppc.o
INCLUDES=ppcdefines.i pci.i

EXECUTABLE=sonnet.library

all: $(EXECUTABLE) 

$(EXECUTABLE) : $(OBJECTS68K) $(OBJECTSPPC)
	$(LD) -s $(OBJECTS68K) $(OBJECTSPPC) -o $(EXECUTABLE)

%.o : %.p $(INCLUDES)
	$(ASMPPC) $(ASMPPCPARAM) -o $@ $< 

%.o : %.s $(INCLUDES)
	$(ASM68K) $(ASM68KPARAM) -o $@ $<

clean :
	$(RM) $(OBJECTS68K) $(OBJECTSPPC) $(EXECUTABLE)

