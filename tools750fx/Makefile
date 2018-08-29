OBJ_GETSPEED=getspeed_68k.o getspeed_ppc.o
GETSPEED_EXE=getspeed

OBJ_GETTEMP=gettemp_68k.o gettemp_ppc.o
GETTEMP_EXE=gettemp

OBJ_SETSPEED=setspeed_68k.o setspeed_ppc.o
TEMPLATE_EXE=setspeed

ASMPPCPARAM+=-I../sonnetlib

all: $(GETSPEED_EXE) $(GETTEMP_EXE) $(SETSPEED_EXE)


$(GETSPEED_EXE) : $(OBJ_GETSPEED)
	$(LD) -s $(OBJ_GETSPEED) -o $(GETSPEED_EXE)

$(GETTEMP_EXE) : $(OBJ_GETTEMP)
	$(LD) -s $(OBJ_GETTEMP) -o $(GETTEMP_EXE)

$(SETSPEED_EXE) : $(OBJ_SETSPEED)
	$(LD) -s $(OBJ_SETSPEED) -o $(SETSPEED_EXE)

%.o : %.p $(LOCAL_INCS)
	$(ASMPPC) $(ASMPPCPARAM) -o $@ $< 

%.o : %.s $(LOCAL_INCS)
	$(ASM68K) $(ASM68KPARAM) -o $@ $<

clean :
	$(RM) $(OBJ_GETSPEED) $(GETSPEED_EXE)
	$(RM) $(OBJ_GETTEMP) $(GETTEMP_EXE)
	$(RM) $(OBJ_SETSPEED) $(SETSPEED_EXE)


