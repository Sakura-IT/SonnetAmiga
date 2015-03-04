ASM68K=vasmm68k_mot
ASMPPC=vasmppc_std
LD=vlink
LHA=lha
RMRF=rm -rf

ASM68KPARAM=-I$(INCLUDE_I) -m68020up -Fhunk
ASMPPCPARAM=-many -mppc32 -Fhunk

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
	$(RMRF) $(OBJ_GETINFO) $(GETINFO_EXE)

distribution : $(GETINFO_EXE)
	$(LHA) a $(DISTRNAME) $(GETINFO_EXE)

