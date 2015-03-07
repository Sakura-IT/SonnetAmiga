OBJ_GETINFO=getinfo.o
GETINFO_EXE=getinfo

all: $(GETINFO_EXE) 

$(GETINFO_EXE) : $(OBJ_GETINFO)
	$(LD) -s $(OBJ_GETINFO) -o $(GETINFO_EXE)

%.o : %.p $(INCLUDES)
	$(ASMPPC) $(ASMPPCPARAM) -o $@ $< 

%.o : %.s $(INCLUDES)
	$(ASM68K) $(ASM68KPARAM) -o $@ $<

clean :
	$(RM) $(OBJ_GETINFO) $(GETINFO_EXE)

