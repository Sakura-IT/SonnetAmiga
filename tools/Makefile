OBJ_GETINFO=getinfo.o
GETINFO_EXE=getinfo

DISTRNAME=tools.lha

all: $(GETINFO_EXE) 

$(GETINFO_EXE) : $(OBJ_GETINFO)
	$(LD) -s $(OBJ_GETINFO) -o $(GETINFO_EXE)

%.o : %.p $(INCLUDES)
	$(ASMPPC) $(ASMPPCPARAM) -o $@ $< 

%.o : %.s $(INCLUDES)
	$(ASM68K) $(ASM68KPARAM) -o $@ $<

clean :
	$(RM) $(OBJ_GETINFO) $(GETINFO_EXE)

distribution : $(GETINFO_EXE)
	$(LHA) a $(DISTRNAME) $(GETINFO_EXE)

