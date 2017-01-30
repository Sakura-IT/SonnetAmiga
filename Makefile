HOST=aos3	# pass unix on any unix-like

ASM68K=vasmm68k_mot
ASMPPC=vasmppc_std
LD=vlink
CC=vc
LHA=lha
IRA=ira

LOCAL_INC_DIR=../common
LOCAL_INCS=$(LOCAL_INC_DIR)/ppcdefines.i $(LOCAL_INC_DIR)/ppcmacros-std.i $(LOCAL_INC_DIR)/pci.i $(LOCAL_INC_DIR)/sonnet_lib.i $(LOCAL_INC_DIR)/sonnet_libppc.i

POSIXLIB_CCPARAM=-I$(POSIXLIB)/include
POSIXLIB_LDPARAM=$(POSIXLIB)/AmigaOS3/posix.lib

IRAPARAM=-M68020
ASM68KPARAM=-m68020up -allmp -Fhunk -I$(LOCAL_INC_DIR)
ASMPPCPARAM=-many -mppc32 -mavec -Fhunk -I$(LOCAL_INC_DIR)

DISTRIBUTION=sonnet.lha

SONNETLIB_N=sonnetlib
SONNETLIB_LIB=sonnet.library
SONNETRUN_N=sonnetrun
SONNETRUN_SONNETPATCH=sonnetpatch
TOOLS_N=tools
TOOLS_GETINFO=getinfo
TOOLS_GETINFOPPC=getinfo_ppc
TOOLS_INITSONNET=InitSonnet
SONNETO_N=dev-startup
SONNETO_DIR=dev/startup
SONNETO_O=sonnet.o
SONNETO_X=x.o
WOSDB_N=wosdb
WOSDB_WOSDB=wosdb

export

all : $(SONNETLIB_N) $(SONNETRUN_N) $(SONNETO_N) $(TOOLS_N) $(WOSDB_N)

$(SONNETLIB_N) :
	$(MAKE) -C $(SONNETLIB_N)

$(SONNETRUN_N) :
	$(MAKE) -C $(SONNETRUN_N)

$(TOOLS_N) :
	$(MAKE) -C $(TOOLS_N)

$(SONNETO_N) :
	$(MAKE) -C $(SONNETO_DIR) 

$(WOSDB_N) :
	$(MAKE) -C $(WOSDB_N)

disasm68k :
	$(MAKE) -C $(SONNETLIB_N) disasm68k
	$(MAKE) -C $(TOOLS_N) disasm68k
	
clean :
	$(MAKE) -C $(SONNETLIB_N) clean
	$(MAKE) -C $(SONNETRUN_N) clean
	$(MAKE) -C $(SONNETO_DIR) clean
	$(MAKE) -C $(TOOLS_N) clean
	$(MAKE) -C $(WOSDB_N) clean
	$(RM) $(DISTRIBUTION)

distribution :
	$(LHA) a $(DISTRIBUTION) $(SONNETLIB_N)/$(SONNETLIB_LIB) $(TOOLS_N)/$(TOOLS_GETINFO) $(TOOLS_N)/$(TOOLS_GETINFOPPC) $(TOOLS_N)/$(TOOLS_INITSONNET) $(SONNETRUN_N)/$(SONNETRUN_SONNETPATCH) $(SONNETO_DIR)/$(SONNETO_O) $(SONNETO_DIR)/$(SONNETO_X) $(WOSDB_N)/$(WOSDB_WOSDB) README.md

.PHONY: $(SONNETLIB_N) $(SONNETRUN_N) $(TOOLS_N) $(SONNETO_N) $(WOSDB_N)

include Makefile.inc.$(HOST)

