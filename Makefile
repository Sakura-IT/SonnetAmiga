HOST=aos3	# pass unix on any unix-like

ASM68K=vasmm68k_mot
ASMPPC=vasmppc_std
LD=vlink
CC=vc
LHA=lha

LOCAL_INC_DIR=../common
LOCAL_INCS=$(LOCAL_INC_DIR)/ppcdefines.i $(LOCAL_INC_DIR)/ppcmacros-std.i $(LOCAL_INC_DIR)/pci.i $(LOCAL_INC_DIR)/sonnet_lib.i $(LOCAL_INC_DIR)/sonnet_libppc.i

ASM68KPARAM=-m68020up -allmp -Fhunk -I$(LOCAL_INC_DIR)
ASMPPCPARAM=-many -mppc32 -mavec -Fhunk -I$(LOCAL_INC_DIR)

DISTRIBUTION=sonnet.lha

SONNETLIB_N=sonnetlib
POWERLIB_LIB=powerpc.library
TOOLS_N=tools
TOOLS_GETINFO=getinfo
TOOLS_GETINFOPPC=getinfo_ppc
TOOLS_INITPPC=InitPPC
TOOLS_BOGOMIPS=bogomips
WOSDB_N=wosdb
WOSDB_WOSDB=wosdb
VDA_VDAPPC=vdappc

export

all :  $(SONNETLIB_N) $(TOOLS_N) $(WOSDB_N) $(VDA_VDAPPC)

$(SONNETLIB_N) :
	$(MAKE) -C $(SONNETLIB_N)

$(TOOLS_N) :
	$(MAKE) -C $(TOOLS_N)

$(WOSDB_N) :
	$(MAKE) -C $(WOSDB_N)

$(VDA_VDAPPC) :
	$(MAKE) -C $(VDA_VDAPPC)

clean :
	$(MAKE) -C $(SONNETLIB_N) clean
	$(MAKE) -C $(TOOLS_N) clean
	$(MAKE) -C $(WOSDB_N) clean
	$(MAKE) -C $(VDA_VDAPPC) clean
	$(RM) $(DISTRIBUTION)

distribution :
	$(LHA) ao5 $(DISTRIBUTION) $(SONNETLIB_N)/$(POWERLIB_LIB) $(TOOLS_N)/$(TOOLS_GETINFO) $(TOOLS_N)/$(TOOLS_GETINFOPPC) $(TOOLS_N)/$(TOOLS_INITPPC) $(WOSDB_N)/$(WOSDB_WOSDB) $(TOOLS_N)/$(TOOLS_BOGOMIPS) README.md

.PHONY: $(SONNETLIB_N) $(SONNETRUN_N) $(TOOLS_N) $(WOSDB_N) $(VDA_VDAPPC)

include Makefile.inc.$(HOST)

