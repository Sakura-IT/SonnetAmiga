OBJECTS68K=powerpc.o
OBJECTSPPC=setupppc.o ppcfunctions.o

EXECUTABLE=powerpc.library

all: $(EXECUTABLE)

$(EXECUTABLE) : $(OBJECTS68K) $(OBJECTSPPC)
	$(LD) -mrel -s $(OBJECTS68K) $(OBJECTSPPC) -o $(EXECUTABLE)

%.o : %.p $(LOCAL_INCS) 
	$(ASMPPC) $(ASMPPCPARAM) -o $@ $< 

%.o : %.s $(LOCAL_INCS)
	$(ASM68K) $(ASM68KPARAM) -o $@ $<

clean :
	$(RM) $(OBJECTSPPC) $(EXECUTABLE) $(OBJECTS68K)

