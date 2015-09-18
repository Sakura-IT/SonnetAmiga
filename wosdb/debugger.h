/* $VER: debugger.h V0.3a (06.05.99)
 *
 * This file is part of the WarpOS debugger 'wosdb'
 * Copyright (c) 1999-2001  Frank Wille
 *
 *
 * v0.3a (06.05.99) phx
 *       Removed wosdb_breakpointlist() - struct LoadFile is sufficient.
 *       wosdb_load() supports argument string.
 * v0.2  (02.05.99) phx
 *       wosdb_validaddr(): checks whether an address belongs to the
 *       debugged program.
 * v0.1  (01.05.99) phx
 *       First usable version.
 * v0.0  (17.04.99) phx
 *       File created.
 */

#ifndef DEBUGGER_H
#define DEBUGGER_H

#include <exec/lists.h>
#ifndef PPC_DISASM_H
#include "ppc_disasm.h"
#endif


#define NAME "wosdb"
#define VERSION 0
#define REVISION 4
#define PLEVEL 3

#define TRAP_INS      0x7fe00008  /* trap instruction */

/* pseudo exceptions */
#define EXCF_BRKPT    0x40000000  /* trap instruction encountered */
#define EXCF_FINISHED 0x80000000  /* task finished */

typedef UBYTE *ADDR;


struct SpecRegs {
  ULONG srHID0;
  ULONG srHID1;
  ULONG srPVR;
  ULONG srSDR1;
  ULONG srEAR;
  ULONG srDEC;
  ULONG srTBU;
  ULONG srTBL;
};


struct Symbol {
  struct Symbol *next;
  char *name;
  ADDR addr;
};


struct Section {
  struct Section *next;
  ADDR addr;
  ULONG len;
  struct Symbol *symbols;
};


struct Breakpoint {
  struct MinNode n;
  ADDR addr;
  ULONG contents;
  BOOL temporary;
};


struct LoadFile {
  char *name;
  int sections;
  int symbols;
  struct Section *firstsec;
  struct MinList *breakpoints;
  struct SpecRegs *specregs;
};


/* expression evaluation */

struct enode {
  struct enode *root;
  struct enode *left;
  struct enode *right;
  int operation;
  union {
    int priority;
    long value;
  } u;
};

#define OPERAND 0
#define PLUS 1
#define MINUS 2
#define MULT 3
#define DIV 4
#define PLUSPRI 0
#define MINUSPRI 0
#define MULTPRI 1
#define DIVPRI 1
#define TERMPRI 2


/* assembler inlines */
void _remove(void *n) =
        "\tlwz\tr5,4(r3)\n"
        "\tlwz\tr4,0(r3)\n"
        "\tstw\tr4,0(r5)\n"
        "\tstw\tr5,4(r4)";

void _insertbefore(void *n,void *sn) =
        "\tlwz\tr5,4(r4)\n"
        "\tstw\tr4,0(r3)\n"
        "\tstw\tr5,4(r3)\n"
        "\tstw\tr3,0(r5)\n"
        "\tstw\tr3,4(r4)";


/* wosdb prototypes */
BOOL wosdb_setbreakpoint(ADDR);
BOOL wosdb_tempbreakpoint(ADDR);
BOOL wosdb_clearbreakpoint(ADDR);
struct Breakpoint *wosdb_hidebreakpoint(ADDR);
void wosdb_showbreakpoint(struct Breakpoint *);
struct LoadFile *wosdb_load(char *,char *);
void wosdb_unload(void);
ULONG wosdb_cont(BOOL,BOOL);
ULONG wosdb_taskresult(void);
char *wosdb_exceptinfo(void);
char *wosdb_symbol(ADDR);
char *wosdb_label(ADDR);
void wosdb_opersymbols(struct DisasmPara_PPC *,int);
int wosdb_validaddr(ADDR);
ULONG wosdb_getexp(char *);
struct SpecRegs *wosdb_getspecregs(void);
struct EXCContext *wosdb_init(void);
void wosdb_exit(void);

#endif /* DEBUGGER_H */
