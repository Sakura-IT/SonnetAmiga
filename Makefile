HOST=aos3	# pass unix on any unix-like

ASM68K=vasmm68k_mot
ASMPPC=vasmppc_std
LD=vlink
LHA=lha

ASM68KPARAM=-m68020up -Fhunk -no-opt
ASMPPCPARAM=-many -mppc32 -Fhunk    

DISTRIBUTION=sonnet.lha

SONNETLIB_N=sonnetlib
SONNETLIB_LIB=sonnet.library
TOOLS_N=tools
TOOLS_GETINFO=getinfo

export

all : $(SONNETLIB_N) $(TOOLS_N)

$(SONNETLIB_N) :
	$(MAKE) -C $(SONNETLIB_N)

$(TOOLS_N) :
	$(MAKE) -C $(TOOLS_N)
	
clean :
	$(MAKE) -C $(SONNETLIB_N) clean
	$(MAKE) -C $(TOOLS_N) clean
	$(RM) $(DISTRIBUTION)

distribution :
	$(LHA) a $(DISTRIBUTION) $(SONNETLIB_N)/$(SONNETLIB_LIB) $(TOOLS_N)/$(TOOLS_GETINFO)

.PHONY: $(SONNETLIB_N) $(TOOLS_N)

include Makefile.inc.$(HOST)

