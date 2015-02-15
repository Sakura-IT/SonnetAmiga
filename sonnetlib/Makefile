vasmm68k_mot -m68020up -Fhunk sonnet.s -o sonnet.o
vasmppc_std -many -mppc32 -Fhunk ppcfunctions.p -o ppcfunctions.o
vasmppc_std -many -mppc32 -Fhunk setupppc.p -o setupppc.o
vlink -s sonnet.o setupppc.o ppcfunctions.o -o sonnet.library
copy sonnet.library libs: