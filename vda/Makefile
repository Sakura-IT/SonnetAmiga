CC	= vc +warpos
AS68K	= vasmm68k_mot -Fhunk
ASPPC	= vasmppc_std -Fhunk
COPTS	= -amiga-align -DBIGENDIAN -dontwarn=129

all: vdappc

OBJECTS = vdappc.o ppc_disasm.o

vdappc: $(OBJECTS)
	$(CC) -v -o vdappc $(OBJECTS) -lm -lamiga

vdappc.o: vdappc.c ppc_disasm.h
	$(CC) $(COPTS) -c -o $@ $<  

ppc_disams.o: ppc_disasm.c ppc_disasm.h
	$(CC) $(COPTS) -c -o $@ $<  

clean :
	$(RM) $(OBJECTS) vdappc 

