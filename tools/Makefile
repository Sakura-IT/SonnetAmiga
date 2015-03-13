OBJ_GETINFO=getinfo.o
GETINFO_EXE=getinfo
GETINFO_EXE_RS=getinfo.rs

OBJ_TEMPLATE=template_68k.o template_ppc.o
TEMPLATE_EXE=template
TEMPLATE_EXE_RS=template.rs

all: $(GETINFO_EXE) $(TEMPLATE_EXE)

disasm68k : $(GETINFO_EXE_RS) $(TEMPLATE_EXE_RS)

$(GETINFO_EXE) : $(OBJ_GETINFO)
	$(LD) -s $(OBJ_GETINFO) -o $(GETINFO_EXE)

$(TEMPLATE_EXE) : $(OBJ_TEMPLATE)
	$(LD) -s $(OBJ_TEMPLATE) -o $(TEMPLATE_EXE)

%.o : %.p $(INCLUDES)
	$(ASMPPC) $(ASMPPCPARAM) -o $@ $< 

%.o : %.s $(INCLUDES)
	$(ASM68K) $(ASM68KPARAM) -o $@ $<

%.rs : %
	$(IRA) $< $@

clean :
	$(RM) $(OBJ_GETINFO) $(GETINFO_EXE) $(GETINFO_EXE_RS) $(OBJ_TEMPLATE) $(TEMPLATE_EXE) $(TEMPLATE_EXE_RS)

