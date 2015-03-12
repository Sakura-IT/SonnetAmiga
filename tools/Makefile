OBJ_GETINFO=getinfo.o
GETINFO_EXE=getinfo

OBJ_TEMPLATE=template_68k.o template_ppc.o
TEMPLATE_EXE=template

all: $(GETINFO_EXE) $(TEMPLATE_EXE)

$(GETINFO_EXE) : $(OBJ_GETINFO)
	$(LD) -s $(OBJ_GETINFO) -o $(GETINFO_EXE)

$(TEMPLATE_EXE) : $(OBJ_TEMPLATE)
	$(LD) -s $(OBJ_TEMPLATE) -o $(TEMPLATE_EXE)

%.o : %.p $(INCLUDES)
	$(ASMPPC) $(ASMPPCPARAM) -o $@ $< 

%.o : %.s $(INCLUDES)
	$(ASM68K) $(ASM68KPARAM) -o $@ $<

clean :
	$(RM) $(OBJ_GETINFO) $(GETINFO_EXE) $(OBJ_TEMPLATE) $(TEMPLATE_EXE)

