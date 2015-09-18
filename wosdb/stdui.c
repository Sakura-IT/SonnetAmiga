/* $VER: stdui.c V0.4c (12.02.01)
 *
 * This file is part of the WarpOS debugger 'wosdb'
 * Copyright (c) 1999-2001  Frank Wille
 *
 *
 * v0.4c (12.02.01) phx
 *       The 'g'-command with an unknown symbol caused a data access
 *       exception.
 *       Updated to year 2001.
 * v0.3b (30.01.00) phx
 *       Updated to year 2000.
 * v0.3a (06.05.99) phx
 *       '?' is not repeatable.
 *       The program to be debugged may have an argument string.
 * v0.3  (04.05.99) phx
 *       'S' shows all symbols.
 * v0.2  (02.05.99) phx
 *       Disassembly and memory dump display only valid memory regions.
 *       Command 'tb' shows stack frame trace-back.
 * v0.1  (01.05.99) phx
 *       First usable version.
 * v0.0  (17.04.99) phx
 *       File created.
 */

#include <powerpc/powerpc.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "debugger.h"


/* status() */
#define ST_EXC 1        /* print name of exception */
#define ST_SPEC 2       /* print all special registers */
#define ST_FPR 4        /* print FPU registers */


static struct EXCContext *dbcontext;
static int taskloaded = 0;


static char *get_option_arg(int,char *[],int *);
static void show_version();
static void show_help();
static void debugger_loop(char *,char *);



main(int argc,char *argv[])
{
  static char argbuf[1024];
  char *p = argbuf;
  int i;
  char *filename = NULL;

  /* parse arguments */
  for (i=1; i<argc; i++) {
    if (filename) {
      char *s = argv[i];

      *p++ = ' ';
      while (*p = *s++)
        p++;
    }
    else {
      if (argv[i][0] == '-') {
        switch (argv[i][1]) {

          case 'h':
          case '?':
            show_help();
            exit(1);

          case 'v':
            show_version();
            exit(1);

          default:
            printf("Unknown option '%c' ignored.\n",argv[i][1]);
            break;
        }
      }
      else
        filename = argv[i];
    }
  }

  *p++ = '\n';
  *p = '\0';
  debugger_loop(filename,argbuf);
  exit(0);
}


static char *get_option_arg(int argc,char *argv[],int *i)
/* get pointer to the string, which either directly follows the option
   character or is stored in the next argument */
{
  if (argv[*i][2])
    return (&argv[*i][2]);
  else {
    if (++*i<argc) {
      if (argv[*i][0]!='-' || isdigit(argv[*i][1]))  /* another option? */
        return (argv[*i]);
      else
        --*i;
    }
  }
  return NULL;
}


static void show_version()
{
  printf(NAME " V%d.%d%c (c)1999-2001 by Frank Wille\n"
         "build date: " __DATE__ ", " __TIME__ "\n\n",
         VERSION,REVISION,PLEVEL?('a'+PLEVEL-1):' ');
}


static void show_help()
{
  show_version();

  printf("\nUsage: " NAME " [-hv?] [file name] [arguments]\n");
}


static void printgpr()
{
  int i;
  char r[8];

  for (i=0; i<32; i++) {
    if (i%8 == 0) {
      sprintf(r,"R%d-R%d:",i,i+7);
      printf("%-8s ",r);
    }
    printf("%08lx%c",dbcontext->ec_GPR[i],(i%8==7)?'\n':' ');
  }
}


static void printfpr()
{
  int i;
  char r[8];

  for (i=0; i<32; i++) {
    if (i%4 == 0) {
      sprintf(r,"F%d-F%d:",i,i+3);
      printf("%-8s    ",r);
    }
    printf("%-16.4e",dbcontext->ec_FPR[i]);
    if (i%4 == 3)
      printf("\n");
  }
}


static void printregs(int fpr)
{
  printf("MSR:   %08lx   XER:   %08lx   CR:    %08lx   FPSCR: %08lx\n"
         "LR:    %08lx   CTR:   %08lx\n\n",
         dbcontext->ec_SRR1,
         dbcontext->ec_XER,
         dbcontext->ec_CR,
         dbcontext->ec_FPSCR,
         dbcontext->ec_LR,
         dbcontext->ec_CTR);
  printgpr();
  if (fpr) {
    printf("\n");
    printfpr();
  }
}


static void printspecregs()
{
  struct SpecRegs *sr = wosdb_getspecregs();

  printf("HID0:  %08lx   HID1:  %08lx   TBL:   %08lx   TBU:   %08lx\n"
         "PVR:   %08lx   DEC:   %08lx   SDR1:  %08lx   EAR:   %08lx\n"
         "SRR0:  %08lx   SRR1:  %08lx   DAR:   %08lx   DSISR: %08lx\n",
         sr->srHID0,sr->srHID1,sr->srTBL,sr->srTBU,
         sr->srPVR,sr->srDEC,sr->srSDR1,sr->srEAR,
         dbcontext->ec_UPC.ec_SRR0,dbcontext->ec_SRR1,
         dbcontext->ec_DAR,dbcontext->ec_DSISR);
}


static void printinstr(ADDR addr)
{
  struct Breakpoint *bp;
  struct DisasmPara_PPC dp;
  char opcode[10];
  char operands[256];
  char *lab;

  if (wosdb_validaddr(addr) != 0) {
    dp.opcode = opcode;
    dp.operands = operands;
    dp.instr = dp.iaddr = (ppc_word *)addr;
    bp = wosdb_hidebreakpoint((ADDR)dp.iaddr);
    PPC_Disassemble(&dp);

    wosdb_opersymbols(&dp,256);
    if (lab = wosdb_label(addr))
      printf("%-26.26s%c%-7s %s\n",lab,bp?'>':' ',opcode,operands);
    else
      printf("%08lx:  %08lx       %c%-7s %s\n",
             (ULONG)addr,*(ULONG *)addr,bp?'>':' ',opcode,operands);
    wosdb_showbreakpoint(bp);
  }

  else
    printf("%08lx:  ********        ---     ---\n",(ULONG)addr);
}


static void printasc(unsigned char *p,int sep,int cnt)
{
  unsigned char c;
  char buf[20];
  int i,v;

  for (i=0; i<sep; buf[i++]=' ');
  for (i=0; i<cnt; i++) {
    if ((i&3)==0)
      v = wosdb_validaddr((ADDR)p);
    if (v != 0) {
      c = *p++;
      buf[sep+i] = (char)((((c)>=0x20 && (c)<=0x7e) ||
                         ((c)>=0xa0 && (c)!=0xad)) ? c : '.');
    }
    else
      buf[sep+i] = '.';
  }
  buf[sep+cnt] = '\0';
  printf("%s\n",buf);
}


static void printbreakpoints(struct MinList *bplist)
{
  struct Breakpoint *b,*next;
  int n=1;
  char *lab;

  for (b = (struct Breakpoint *)(bplist->mlh_Head);
       next = (struct Breakpoint *)b->n.mln_Succ; b = next) {
    printf("#%d: 0x%08lx %c",n++,(ULONG)b->addr,b->temporary?'T':' ');
    if (lab = wosdb_label(b->addr))
      printf(" %s\n",lab);
    else
      printf("\n");
  }
}


static void status(int flags)
{
  if (flags & ST_EXC)
    printf("\n%s\n",wosdb_exceptinfo());
  if (flags & ST_SPEC)
    printspecregs();
  printregs(flags & ST_FPR);
  printf("\n");
  printinstr((ADDR)dbcontext->ec_UPC.ec_PC);
}


static void finished()
{
  printf("Task finished. Return code = 0x%08lx\n",wosdb_taskresult());
  taskloaded = 0;
}


static char *skipeq(char *p)
{
  while (*p != '=' && *p != '\0')
    p++;
  if (*p++ == '\0')
    return (NULL);
  while (isspace((unsigned char)*p))
    p++;
  return (p);
}


static void printhelp()
{
  printf("+\t\tskip to next instruction\n");
  printf("-\t\tskip to previous instruction\n");
  printf("?\t\tshow help\n");
  printf("? <exp>\t\tevaluate expression\n");
  printf("@r<n> = <exp>\tset GP register\n");
  printf("@f<n> = <flt>\tset FPU register\n");
  printf("L \"name\" [args]\tload WOS program for debugging\n");
  printf("U\t\tunload current program\n");
  printf("S\t\tshow all symbols\n");
  printf("b\t\tshow all breakpoints\n");
  printf("b <exp>\t\tset breakpoint\n");
  printf("bt <exp>\tset temporary breakpoint\n");
  printf("bc <exp>\tclear breakpoint\n");
  printf("--press return--");
  getchar();
  printf("d [<exp>]\tdisassemble\n");
  printf("fpr\t\tshow FPU registers\n");
  printf("g\t\trun program\n");
  printf("g <exp>\t\trun program until address reached\n");
  printf("gpr\t\tshow GP registers\n");
  printf("m [<exp>]\tmemory dump\n");
  printf("n\t\tbreak at next instruction\n");
  printf("r\t\tshow all registers and current instruction\n");
  printf("s\t\tstep single instruction\n");
  printf("tb\t\tshow stack frame trace-back\n");
  printf("x\t\texit debugger, unload debug task\n");
}


static void debugger_loop(char *filename,char *start_args)
{
  char cmdbuf[80],lastcmdbuf[80];
  int i,r,exit = 0;
  ULONG xcid,x;
  ADDR addr = 0;  /* current addr for mem-dump or disassembly */
  int nlines = 8; /* number of lines to display for mem-dump/disasm. */
  char *s;
  struct Breakpoint *bp;
  struct LoadFile *lf;

  printf("\n** " NAME " V%d.%d%c\n"
         "** (c)1999-2001 by Frank Wille <frank@phoenix.owl.de>\n",
         VERSION,REVISION,PLEVEL?('a'+PLEVEL-1):' ');

  if (dbcontext = wosdb_init()) {
    if (filename) {
      /* load and stop WOS program */
      if (lf = wosdb_load(filename,start_args)) {
        printf("Loaded %d sections with %d symbols.\n",
               lf->sections,lf->symbols);
        status(ST_EXC|ST_SPEC|ST_FPR);  /* show regs and cur. instruction */
        taskloaded = 1;
      }
      else {
        printf("Can't load \"%s\".\n",filename);
      }
    }

    /* the main loop */
    while (!exit) {
      printf("wosdb>");
      fflush(stdout);
      gets(cmdbuf);
      if (cmdbuf[0] == '\0')
        strcpy(cmdbuf,lastcmdbuf);
      else
        strcpy(lastcmdbuf,cmdbuf);

      switch (cmdbuf[0]) {

        case '+':                              /* PC++ */
          if (!taskloaded)
            break;
          printinstr((ADDR)(dbcontext->ec_UPC.ec_SRR0 += 4));
          break;

        case '-':                              /* PC-- */
          if (!taskloaded)
            break;
          printinstr((ADDR)(dbcontext->ec_UPC.ec_SRR0 -= 4));
          break;

        case '?':                              /* display expression */
          if (cmdbuf[1] == ' ') {
            x = wosdb_getexp(&cmdbuf[2]);
            printf("= 0x%08lx\n= %ld\n",x,(long)x);
          }
          else {                               /* print help */
            printhelp();
            lastcmdbuf[0] = '\0';
          }
          break;

        case '@':                              /* set register */
          if (!taskloaded)
            break;
          if (cmdbuf[1] == 'r' || cmdbuf[1] == 'R') {
            sscanf(&cmdbuf[2],"%i",&r);
            if (s = skipeq(&cmdbuf[2]))
              dbcontext->ec_GPR[r] = (ULONG)wosdb_getexp(s);
          }
          else if (cmdbuf[1] == 'f' || cmdbuf[1] == 'F') {
            sscanf(&cmdbuf[2],"%i",&r);
            if (s = skipeq(&cmdbuf[2])) {
              double df;

              sscanf(s,"%lf",&df);
              dbcontext->ec_FPR[r] = df;
            }
          }
          break;

        case 'L':                              /* load program */
          if (taskloaded) {
            printf("Unloading current task.\n");
            wosdb_unload();
            taskloaded = 0;
          }
          if (cmdbuf[1] == ' ') {
            static char fname[256];
            static char args[1024];
            char *a = args;

            /* get program name and arguments */
            s = &cmdbuf[2];
            i = 0;
            while (*s != '\"' && *s != '\0')
              s++;
            if (*s == '\"') {
              s++;
              while (*s != '\"' && *s != '\0')
                fname[i++] = *s++;
              fname[i] = '\0';
              if (*s == '\"')
                s++;
              while (isspace((unsigned char)*s))
                s++;
              while (*a = *s++)
                a++;
              *a++ = '\n';
              *a = '\0';

              /* load and stop WOS program */
              if (lf = wosdb_load(fname,args)) {
                printf("Loaded %d sections with %d symbols.\n",
                       lf->sections,lf->symbols);
                status(ST_EXC|ST_SPEC|ST_FPR);
                taskloaded = 1;
              }
              else {
                printf("Can't load \"%s\".\n",fname);
                taskloaded = 0;
              }
              break;
            }
          }
          printf("Missing file name.\n");
          break;

        case 'S':                              /* print all symbols */
          if (taskloaded) {
            struct Section *sec = lf->firstsec;
            struct Symbol *sym;
            int scnt=0;

            while (sec) {
              printf("Section %d at 0x%08lx size 0x%08lx:\n",
                     scnt++,(ULONG)sec->addr,sec->len);
              sym = sec->symbols;
              while (sym) {
                printf("\t0x%08lx  %s\n",(ULONG)sym->addr,sym->name);
                sym = sym->next;
              }
              sec = sec->next;
            }
          }
          break;

        case 'U':                              /* unload program */
          if (taskloaded) {
            printf("Unloading current task.\n");
            wosdb_unload();
            taskloaded = 0;
          }
          break;

        case 'b':                              /* breakpoint */
          if (!taskloaded)
            break;
          if (cmdbuf[1] == ' ') {
            /* set normal breakpoint */
            if (!wosdb_setbreakpoint((ADDR)wosdb_getexp(&cmdbuf[2])))
              printf("Can't set breakpoint!\n");
          }
          else if (cmdbuf[1] == 'c' && cmdbuf[2] == ' ') {
            /* clear breakpoint */
            wosdb_clearbreakpoint((ADDR)wosdb_getexp(&cmdbuf[3]));
          }
          else if (cmdbuf[1] == 't' && cmdbuf[2] == ' ') {
            /* set temporary breakpoint */
            if (!wosdb_tempbreakpoint((ADDR)wosdb_getexp(&cmdbuf[3])))
              printf("Can't set temporary breakpoint!\n");
          }
          else {
            /* show all breakpoints */
            printbreakpoints(lf->breakpoints);
          }
          break;

        case 'd':                              /* disassemble */
          if (cmdbuf[1] == ' ') {
            addr = (ADDR)((ULONG)wosdb_getexp(&cmdbuf[2]) & ~3);
            lastcmdbuf[1] = '\0';
          }
          for (i=0; i<nlines; i++,addr+=4) {
            printinstr(addr);
          }
          break;

        case 'f':                             /* show fpr */
          if (!taskloaded)
            break;
          if (cmdbuf[1] == 'p' && cmdbuf[2] == 'r') {
            /* show floating point registers */
            printfpr();
          }
          break;

        case 'g':                              /* go, show gpr */
          if (!taskloaded)
            break;
          if (cmdbuf[1] == 'p' && cmdbuf[2] == 'r') {
            /* show general purpose registers */
            printgpr();
          }
          else if (cmdbuf[1] == ' ') {
            /* run until address reached */
            ADDR bpt = (ADDR)wosdb_getexp(&cmdbuf[2]);

            if (bpt) {
              wosdb_tempbreakpoint(bpt);
              xcid = wosdb_cont(FALSE,FALSE); /* run until breakpoint reached */
              if (xcid==EXCF_FINISHED)
                finished();
              else
                status(xcid==EXCF_BRKPT ? 0 : ST_EXC|ST_SPEC);
            }
          }
          else {
            /* run until end */
            xcid = wosdb_cont(FALSE,FALSE);
            if (xcid==EXCF_FINISHED)
              finished();
            else
              status(xcid==EXCF_BRKPT ? 0 : ST_EXC|ST_SPEC);
          }
          break;

        case 'm':                              /* memory dump */
          if (cmdbuf[1] == ' ') {
            addr = (ADDR)((ULONG)wosdb_getexp(&cmdbuf[2]) & ~3);
            lastcmdbuf[1] = '\0';
          }
          for (i=0; i<(nlines*4); i++,addr+=4) {
            if (s = wosdb_label(addr)) {
              if (i&3) {
                char spc[32];
                int si;

                for (si=0; si<(4-(i&3))*9; spc[si++]=' ');
                spc[si] = '\0';
                printf("%s",spc);
                printasc(addr-(i&3)*4,3,(i&3)*4);
                if ((i = (i+3) & ~3) >= (nlines*4))
                  break;
              }
              printf("%-15.15s ",s);
            }
            else if ((i&3) == 0)
              printf("%08lx:       ",(ULONG)addr);

            if (wosdb_validaddr(addr) != 0) {
              bp = wosdb_hidebreakpoint(addr);
              printf("%08lx ",*(ULONG *)addr);
              wosdb_showbreakpoint(bp);
            }
            else
              printf("******** ");
            if ((i&3) == 3)
              printasc(addr-12,3,16);
          }
          break;

        case 'n':                              /* next */
          if (!taskloaded)
            break;
          wosdb_tempbreakpoint((ADDR)dbcontext->ec_UPC.ec_PC + 4);
          xcid = wosdb_cont(FALSE,FALSE);  /* break at next instruction */
          if (xcid==EXCF_FINISHED)
            finished();
          else
            status(xcid==EXCF_BRKPT ? 0 : ST_EXC|ST_SPEC);
          break;

        case 'r':                              /* show registers */
          if (!taskloaded)
            break;
          status(ST_EXC|ST_SPEC|ST_FPR);  /* show regs and cur. instruction */
          break;

        case 's':                              /* step */
          if (!taskloaded)
            break;
          xcid = wosdb_cont(TRUE,FALSE);  /* step one instruction */
          if (xcid==EXCF_FINISHED)
            finished();
          else
            status(xcid==EXCF_TRACE ? 0 : ST_EXC|ST_SPEC);
          break;

        case 't':                              /* stack frame trace-back */
          if (cmdbuf[1] == 'b') {
            int depth = 0;
            ULONG *tb = (ULONG *)dbcontext->ec_GPR[1];
            ADDR ra;

            if (!taskloaded)
              break;
            while (tb = (ULONG *)*tb) {
              ra = (ADDR)*(tb+2);
              if (wosdb_validaddr(ra) != 0) {
                printf("\n> Level %d: Stack Frame 0x%08lx"
                       "  Return Addr 0x%08lx",
                       ++depth,(ULONG)tb,(ULONG)ra);
                if (s = wosdb_symbol(ra))
                  printf(" %s\n",s);
                else
                  printf("\n");
                printinstr(ra-4);
              }
            }
          }
          break;

        case 'x':                              /* exit */
          exit = 1;  /* exit debugger */
          if (taskloaded)
            wosdb_unload();
          break;
      }
    }

    wosdb_exit();
  }
}
