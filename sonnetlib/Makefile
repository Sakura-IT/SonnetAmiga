vasmm68k_mot -m68020up -Fhunk sonnet.s -o sonnet.o
vasmppc_std -many -mppc32 -Fhunk confirminterrupt.p -o confirminterrupt.o
vasmppc_std -many -mppc32 -Fhunk setupppc.p -o setupppc.o
vlink -s sonnet.o setupppc.o confirminterrupt.o -o sonnet.library