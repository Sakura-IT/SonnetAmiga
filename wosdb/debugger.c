/* $VER: debugger.c V0.4a (05.03.00)
 *
 * This file is part of the WarpOS debugger 'wosdb'
 * Copyright (c) 1999-2001  Frank Wille
 *
 *
 * v0.4a (05.03.00) phx
 *       HUNK_RELOC32SHORT or HUNK_DREL32 hunks are correctly recognized now.
 * v0.4  (26.02.00) phx
 *       Fixed wosdb_symbol(), which returns the correct symbol for
 *       stack frame trace backs now. Didn't work before, because symbols
 *       are not sorted by address.
 * v0.3a (07.05.99) phx
 *       wosdb_load() allows passing of an argument string to the
 *       program to be debugged.
 *       "@_..." and "@x..." symbol names are recognized.
 * v0.3  (04.05.99) phx
 *       Replaced initial LR of debugged task by an own ProgramExit()
 *       function, which notifies the debugger about the task's termination.
 *       Stepping into or setting a breakpoint in ProgramExit() leads to
 *       an immediate termination of the debugged task.
 * v0.2  (02.05.99) phx
 *       wosdb_validaddr(): checks whether an address belongs to the
 *       debugged program.
 * v0.1  (01.05.99) phx
 *       First usable version.
 * v0.0  (17.04.99) phx
 *       File created.
 */

#include <stdio.h>
#include <ctype.h>
#include <exec/execbase.h>
#include <exec/memory.h>
#include <dos/dos.h>
#include <dos/dostags.h>
#include <dos/doshunks.h>
#include <powerpc/powerpc.h>
#include <powerpc/tasksPPC.h>
#include <proto/exec.h>
#include <proto/dos.h>
#include <proto/powerpc.h>
#include "debugger.h"


APTR oldRunPPC;             /* original RunPPC() vector */
extern LONG newRunPPC();    /* new RunPPC() function (68k) */

/* the exception handlers (PPC assembler source) */
extern ULONG ExceptionCatch(struct EXCContext *);
extern ULONG ExceptionLeave(struct EXCContext *);
extern ULONG ProgramExit(ULONG);  /* notifies debugger */
extern void ProgramExitEnd();
extern void clearIABR(void);
extern ULONG readIABR(void);

/* exceptions */
struct EXCContext ec;
struct SpecRegs spr;
struct TaskPPC *thisTask;       /* this task */
struct TaskPPC *dbTask = NULL;  /* debugged task */
int sigExcept;                  /* task-exception signal */
int sigFinish;                  /* task-finished signal */
int sigRun = SIGBREAKB_CTRL_D;  /* continue debugged task */
BOOL sTrace = FALSE;            /* single step trace mode */
BOOL bTrace = FALSE;            /* branch trace mode */

/* debugged task */
ULONG initialLR;                /* init. LR (return addr) of debugged task */
ULONG result;                   /* result code of a finished PPC task */
static BOOL taskloaded = FALSE;
static ULONG stacksize = 0x10000;
static int priority = 0;
static void *xhdlC = NULL;      /* exception handler locks (catch/leave) */
static void *xhdlL = NULL;
static void *taskpool = NULL;   /* mem pool for all task allocations */
static int nSecs;               /* number of sections (68k section incl.) */
static int nSyms;               /* number of total symbols */
static struct Section *firstSec;/* first section of debugged task */
static struct MinList breakpoints;

static char buffer[1024];       /* multi-purpose buffer */


ULONG r2(void) = "\tmr\tr3,r2"; /* gets TOC-pointer */



static long getsymval(char *symname)
{
  struct Section *sec = firstSec;
  struct Symbol *sym;

  while (sec) {
    sym = sec->symbols;
    while (sym) {
      if (!strcmp(sym->name,symname))
        return ((long)sym->addr);
      sym = sym->next;
    }
    sec = sec->next;
  }
  return (0);
}


static char *getvalue(long *val,char *buf)
{
  if (isdigit((unsigned char)*buf)) {
    /* numerical constant */
    sscanf(buf++,"%li",val);
    if (*buf=='x' || *buf=='x')
      buf++;
    while (isxdigit((unsigned char)*buf))
      buf++;
  }

  else if (*buf=='@' && *(buf+1)!='_' && *(buf+1)!='x') {
    /* register contents */
    int r;

    buf++;
    if (*buf == 'r' || *buf == 'R') {
      sscanf(++buf,"%i",&r);
      *val = (long)ec.ec_GPR[r];
      while (isdigit((unsigned char)*buf))
        buf++;
    }
    else if ((*buf&0xdf) == 'L' && (*(buf+1)&0xdf) == 'R') {
      *val = (long)ec.ec_LR;
      buf += 2;
    }
    else if ((*buf&0xdf) == 'C' && (*(buf+1)&0xdf) == 'T' &&
             (*(buf+2)&0xdf) == 'R') {
      *val = (long)ec.ec_CTR;
      buf += 3;
    }
    else if ((*buf&0xdf) == 'P' && (*(buf+1)&0xdf) == 'C') {
      *val = (long)ec.ec_UPC.ec_SRR0;
      buf += 2;
    }
  }

  else {
    /* symbol value */
    char *p = buffer;

    while (isalnum((unsigned char)*buf) || *buf=='_' || *buf=='@') {
      *p++ = *buf++;
    }
    *p = '\0';
    *val = getsymval(buffer);
  }
  return (buf);
}


static struct enode *exptree(void *expool,char *buf)
{
  struct enode *on=NULL,*vn,*rn;

  for (;;) {
    while (isspace((unsigned char)*buf))
      buf++;

    if (*buf == '(') {
      /* evaluate term */
      int lev=1;

      if ((vn = exptree(expool,++buf)) == NULL)
        return (NULL);
      while (lev>0) {
        if (*buf == '(')
          lev++;
        else if (*buf == ')')
          lev--;
        buf++;
      }
      if (vn->operation != OPERAND)
        vn->u.priority = TERMPRI;
    }
    else {
      if ((vn = AllocPooledPPC(expool,sizeof(struct enode))) == NULL)
        return (NULL);
      vn->root = on;
      vn->left = vn->right = NULL;
      vn->operation = OPERAND;
      buf = getvalue(&vn->u.value,buf);
    }

    if (on != NULL)
      on->right = vn;
    else
      rn = vn;
    while (isspace((unsigned char)*buf))
      buf++;
    if (*buf=='\0' || *buf=='\n' || *buf==')')
      return (rn);

    /* get operation */
    if ((on = AllocPooledPPC(expool,sizeof(struct enode))) == NULL)
      return (NULL);
    on->right = NULL;
    switch (*buf++) {
      case '+':
        on->operation = PLUS;
        on->u.priority = PLUSPRI;
        break;
      case '-':
        on->operation = MINUS;
        on->u.priority = MINUSPRI;
        break;
      case '*':
        on->operation = MULT;
        on->u.priority = MULTPRI;
        break;
      case '/':
        on->operation = DIV;
        on->u.priority = DIVPRI;
        break;
      default:
        return (NULL);
    }

    if (on->u.priority <= rn->u.priority || rn->operation == OPERAND) {
      on->root = NULL;
      rn->root = on;
      on->left = rn;
      rn = on;
    }
    else {
      on->root = rn;
      rn->right->root = on;
      on->left = rn->right;
      rn->right = on;
    }
  }
}


static long calctree(struct enode *n)
{
  if (n->operation == OPERAND) {
    return (n->u.value);
  }
  else {
    long x = calctree(n->left);
    long y = calctree(n->right);

    switch (n->operation) {
      case PLUS:
        return (x+y);
      case MINUS:
        return (x-y);
      case MULT:
        return (x*y);
      case DIV:
        return (x/y);
      default:
        return (0);
    }
  }
}


static BPTR read_sections(char *name)
{
  BPTR seglist;

  if (seglist = LoadSeg(name)) {
    ULONG *p;
    struct Section *s = NULL;

    /* get length and address of all sections */
    p = (ULONG *)BADDR(seglist);
    nSecs = 0;
    while (p) {
      if (s) {
        s->next = AllocPooledPPC(taskpool,sizeof(struct Section));
        s = s->next;
      }
      else
        firstSec = s = AllocPooledPPC(taskpool,sizeof(struct Section));
      if (s) {
        s->next = NULL;
        s->addr = (ADDR)(p+1);
        s->len = *(p-1);
        s->symbols = NULL;
        nSecs++;
        p = (ULONG *)BADDR(*p);
      }
      else {
        /* out of memory */
        DeletePoolPPC(taskpool);
        taskpool = NULL;
        UnLoadSeg(seglist);
        return (0);
      }
    }
  }
  return (seglist);
}


static ULONG filesize(FILE *fp)
{
  long oldpos,size;

  if ((oldpos = ftell(fp)) >= 0)
    if (fseek(fp,0,SEEK_END) >= 0)
      if ((size = ftell(fp)) >= 0)
        if (fseek(fp,oldpos,SEEK_SET) >= 0)
          return ((ULONG)size);
  return (0);
}


static void get_debug_info(char *name)
{
  FILE *f;
  ULONG size;
  ULONG *hunks;
  UWORD *hunks16;

  nSyms = 0;
  if (f = fopen(name,"r")) {
    if (size = filesize(f)) {
      if (hunks = AllocPooledPPC(taskpool,size)) {
        if (fread(hunks,1,size,f) == size) {
          if (*hunks++ == HUNK_HEADER) {
            int i,n,cnt;
            struct Section *s = firstSec;
            struct Symbol *lastsym,*newsym;
            ULONG type;

            n = *hunks;
            hunks += n ? (n+2) : 1;
            n = *hunks;
            hunks += n+3;
            if (n > nSecs)
              n = nSecs;

            /* scan all n sections for debugging information */
            for (i=0; i<n; i++,s=s->next) {
              lastsym = s->symbols;
              while ((type = *hunks++) != HUNK_END) {

                switch (type & 0xffff) {
                  case HUNK_CODE:
                  case HUNK_DATA:
                  case HUNK_NAME:
                  case HUNK_DEBUG:
                    hunks += *hunks+1;
                    break;

                  case HUNK_BSS:
                    hunks++;
                    break;

                  case HUNK_RELOC32:
                    while ((cnt = *hunks++) != 0)
                      hunks += cnt+1;
                    break;

                  case HUNK_RELOC32SHORT:
                  case HUNK_DREL32:  /* V37 RELOC32SHORT */
                    hunks16 = (UWORD *)hunks;
                    while ((cnt = *hunks16++) != 0)
                      hunks16 += cnt+1;
                    if ((ULONG)hunks16 & 3)
                      hunks16++;  /* 32-bit alignment */
                    hunks = (ULONG *)hunks16;
                    break;

                  case HUNK_SYMBOL:
                    while ((cnt = *hunks++) != 0) {
                      if (newsym = AllocPooledPPC(taskpool,
                                                  sizeof(struct Symbol))) {
                        if (newsym->name = AllocPooledPPC(taskpool,
                                                          (cnt<<2)+1)) {
                          memcpy(newsym->name,hunks,cnt<<2);
                          *(newsym->name+(cnt<<2)) = '\0';
                          newsym->addr = s->addr + *(hunks+cnt);
                          newsym->next = NULL;

                          if (lastsym)
                            lastsym->next = newsym;
                          else
                            s->symbols = newsym;
                          lastsym = newsym;
                          nSyms++;
                        }
                      }
                      hunks += cnt+1;
                    }
                    break;

                  default:
                    /* hunk type not supported - bail out! */
                    fclose(f);
                    return;
                }
              }
            }
          }
        }
      }
    }
    fclose(f);
  }
}


static BOOL setbreakpt(ADDR addr,BOOL tmp)
{
  struct Breakpoint *b,*next,*new;

  if (!taskloaded)
    return (FALSE);
  addr = (ADDR)((ULONG)addr & ~3);
  for (b = (struct Breakpoint *)breakpoints.mlh_Head;
       next = (struct Breakpoint *)b->n.mln_Succ; b = next) {
    if (b->addr == addr) {
      b->temporary = tmp;
      return (TRUE);
    }
    if (b->addr > addr)
      break;
  }
  if (new = AllocPooledPPC(taskpool,sizeof(struct Breakpoint))) {
    new->addr = addr;
    new->contents = *(ULONG *)addr;
    new->temporary = tmp;
    _insertbefore(&new->n,&b->n);
    *(ULONG *)addr = TRAP_INS;
    SetCache(CACHE_DCACHEFLUSH,addr,4);
    SetCache(CACHE_ICACHEINV,0,0);
    return (TRUE);
  }
  return (FALSE);
}


static BOOL clrbreakpt(ADDR addr,BOOL tmp)
{
  struct Breakpoint *b,*next;

  if (!taskloaded)
    return (FALSE);
  addr = (ADDR)((ULONG)addr & ~3);
  for (b = (struct Breakpoint *)breakpoints.mlh_Head;
       next = (struct Breakpoint *)b->n.mln_Succ; b = next) {
    if (b->addr > addr)
      break;
    if (b->addr == addr) {
      if (tmp==TRUE && b->temporary==FALSE)
        continue;
      _remove(&b->n);
      *(ULONG *)addr = b->contents;
      SetCache(CACHE_DCACHEFLUSH,addr,4);
      SetCache(CACHE_ICACHEINV,0,0);
      FreePooledPPC(taskpool,b,sizeof(struct Breakpoint));
      return (TRUE);
    }
  }
  return (FALSE);
}


static void remallbrkpts()
{
  struct Breakpoint *b,*next;

  if (!taskloaded)
    return;
  for (b = (struct Breakpoint *)breakpoints.mlh_Head;
       next = (struct Breakpoint *)b->n.mln_Succ; b = next) {
    _remove(&b->n);
    *(ULONG *)b->addr = b->contents;
    SetCache(CACHE_DCACHEFLUSH,b->addr,4);
    SetCache(CACHE_ICACHEINV,0,0);
    FreePooledPPC(taskpool,b,sizeof(struct Breakpoint));
  }
  clearIABR();
}


BOOL wosdb_setbreakpoint(ADDR addr)
{
  return (setbreakpt(addr,FALSE));
}


BOOL wosdb_tempbreakpoint(ADDR addr)
{
  return (setbreakpt(addr,TRUE));
}


BOOL wosdb_clearbreakpoint(ADDR addr)
{
  return (clrbreakpt(addr,FALSE));
}


struct Breakpoint *wosdb_hidebreakpoint(ADDR addr)
/* If the specified address matches a breakpoint, then hide it by */
/* temporarily restoring the original contents */
{
  struct Breakpoint *b,*next;
  ADDR a1 = (ADDR)((ULONG)addr & ~3);
  ADDR a2 = (ADDR)(((ULONG)addr+3) & ~3);

  if (!taskloaded)
    return (NULL);
  for (b = (struct Breakpoint *)breakpoints.mlh_Head;
       next = (struct Breakpoint *)b->n.mln_Succ; b = next) {
    if (b->addr > a2)
      return (NULL);
    if (b->addr == a1 || b->addr == a2) {
      *(ULONG *)addr = b->contents;
      SetCache(CACHE_DCACHEFLUSH,addr,4);
      SetCache(CACHE_ICACHEINV,0,0);
      return (b);
    }
  }
  return (NULL);
}


void wosdb_showbreakpoint(struct Breakpoint *b)
/* Reactivate a breakpoint, which was hidden by wosdb_hidebreakpoint() */
{
  if (b != NULL && taskloaded) {
    *(ULONG *)b->addr = TRAP_INS;
    SetCache(CACHE_DCACHEFLUSH,b->addr,4);
    SetCache(CACHE_ICACHEINV,0,0);
  }
}


struct LoadFile *wosdb_load(char *name,char *args)
{
  static struct LoadFile loadfile;
  struct LoadFile *lf = NULL;
  BPTR seglist;
  struct TagItem ti[16];

  if (taskpool = CreatePoolPPC(0,0x4000,0x2000)) {
    if (seglist = read_sections(name)) {
      get_debug_info(name);
      loadfile.name = name;
      loadfile.sections = nSecs;
      loadfile.symbols = nSyms;
      loadfile.firstsec = firstSec;
      loadfile.breakpoints = &breakpoints;
      loadfile.specregs = &spr;

      /* patch RunPPC() to set a breakpoint for the first instruction */
      oldRunPPC = SetFunction((struct Library *)PowerPCBase,
                              -30, /* RunPPC() LVO */
                              (APTR)newRunPPC);
      SetCache(CACHE_DCACHEFLUSH,&oldRunPPC,4);

      /* install a global exception handler to capture the new task */
      ti[0].ti_Tag = EXCATTR_CODE;
      ti[0].ti_Data = (ULONG)ExceptionCatch;
      ti[1].ti_Tag = EXCATTR_DATA;
      ti[1].ti_Data = r2();
      ti[2].ti_Tag = EXCATTR_EXCID;
      ti[2].ti_Data = EXCF_PROGRAM;
      ti[3].ti_Tag = EXCATTR_FLAGS;
      ti[3].ti_Data = EXCF_GLOBAL | EXCF_LARGECONTEXT;
      ti[4].ti_Tag = EXCATTR_PRI;
      ti[4].ti_Data = 127;
      ti[5].ti_Tag = TAG_DONE;

      if (xhdlC = SetExcHandler(ti)) {
        /* launch the task, which will immediately run in our breakpoint */

        ti[0].ti_Tag = NP_Seglist;
        ti[0].ti_Data = (ULONG)seglist;
        ti[1].ti_Tag = NP_FreeSeglist;
        ti[1].ti_Data = TRUE;
        ti[2].ti_Tag = NP_Name;
        ti[2].ti_Data = (ULONG)name;
        ti[3].ti_Tag = NP_StackSize;
        ti[3].ti_Data = stacksize;
        ti[4].ti_Tag = NP_Priority;
        ti[4].ti_Data = (ULONG)priority;
        ti[5].ti_Tag = NP_Cli;
        ti[5].ti_Data = TRUE;
        ti[6].ti_Tag = NP_Input;
        ti[6].ti_Data = (ULONG)Input();
        ti[7].ti_Tag = NP_Output;
        ti[7].ti_Data = (ULONG)Output();
        ti[8].ti_Tag = NP_Error;
        ti[8].ti_Data = (ULONG)Output();
        ti[9].ti_Tag = NP_CloseInput;
        ti[9].ti_Data = FALSE;
        ti[10].ti_Tag = NP_CloseOutput;
        ti[10].ti_Data = FALSE;
        ti[11].ti_Tag = NP_CloseError;
        ti[11].ti_Data = FALSE;
        ti[12].ti_Tag = NP_CommandName;
        ti[12].ti_Data = (ULONG)name;
        ti[13].ti_Tag = NP_Arguments;
        ti[13].ti_Data = (ULONG)args;
        ti[14].ti_Tag = TAG_DONE;
        if (CreateNewProc(ti)) {   /* start program and */
          WaitPPC(1L<<sigExcept);  /* wait for breakpoint exception */

          /* undo RunPPC()-patch and remove global handler */
          SetFunction((struct Library *)PowerPCBase,-30,oldRunPPC);
          RemExcHandler(xhdlC);

          /* install local handlers for exception-catch and */
          /* exception-leave */
          ti[0].ti_Tag = EXCATTR_CODE;
          ti[0].ti_Data = (ULONG)ExceptionCatch;
          ti[1].ti_Tag = EXCATTR_DATA;
          ti[1].ti_Data = r2();
          ti[2].ti_Tag = EXCATTR_TASK;
          ti[2].ti_Data = (ULONG)dbTask;
          ti[3].ti_Tag = EXCATTR_EXCID;
          ti[3].ti_Data = EXCF_MCHECK | EXCF_DACCESS | EXCF_IACCESS |
                          EXCF_ALIGN | EXCF_PROGRAM | EXCF_FPUN |
                          EXCF_TRACE | EXCF_IABR;
          ti[4].ti_Tag = EXCATTR_FLAGS;
          ti[4].ti_Data = EXCF_LOCAL | EXCF_LARGECONTEXT;
          ti[5].ti_Tag = EXCATTR_PRI;
          ti[5].ti_Data = 126;
          ti[6].ti_Tag = TAG_DONE;
          if (xhdlC = SetExcHandler(ti)) {
            ti[0].ti_Tag = EXCATTR_CODE;
            ti[0].ti_Data = (ULONG)ExceptionLeave;
            ti[1].ti_Tag = EXCATTR_DATA;
            ti[1].ti_Data = r2();
            ti[2].ti_Tag = EXCATTR_TASK;
            ti[2].ti_Data = (ULONG)dbTask;
            ti[3].ti_Tag = EXCATTR_EXCID;
            ti[3].ti_Data = EXCF_PROGRAM;
            ti[4].ti_Tag = EXCATTR_FLAGS;
            ti[4].ti_Data = EXCF_LOCAL | EXCF_LARGECONTEXT;
            ti[5].ti_Tag = EXCATTR_PRI;
            ti[5].ti_Data = 127;
            ti[6].ti_Tag = TAG_DONE;
            if (xhdlL = SetExcHandler(ti)) {
              taskloaded = TRUE;
              NewListPPC((struct List *)&breakpoints);

              /* Set breakpoint to PPC-task start address. */
              /* WarpOS now calls the task-code by a "blrl", so we can */
              /* find the start address in the LR register. */
              wosdb_tempbreakpoint((ADDR)ec.ec_LR);
              ec.ec_UPC.ec_SRR0 += 4;  /* skip "trap" instruction */

              /* let the task continue to run */
              SignalPPC(dbTask,1L<<sigRun);

              /* wait for exception at start-address */
              WaitPPC(1L<<sigExcept);  /* wait for breakpoint exception */
              clrbreakpt((ADDR)ec.ec_UPC.ec_PC,TRUE);

              /* set our own exit-function to notify the debugger */
              /* on task's termination */
              initialLR = ec.ec_LR;
              ec.ec_LR = (ULONG)ProgramExit;

              lf = &loadfile;
            }
            else
              RemExcHandler(xhdlC);
          }
        }
        else {
          SetFunction((struct Library *)PowerPCBase,-30,oldRunPPC);
          RemExcHandler(xhdlC);
        }
      }
      else
        SetFunction((struct Library *)PowerPCBase,-30,oldRunPPC);

      if (!lf) {
        /* something failed, free all */
        xhdlC = xhdlL = NULL;
        DeletePoolPPC(taskpool);
      }
    }
  }
  return (lf);
}


void wosdb_unload()
{
  if (dbTask) {
    remallbrkpts();
    if (xhdlL) {
      RemExcHandler(xhdlL);
      xhdlL = NULL;
    }
    if (xhdlC) {
      RemExcHandler(xhdlC);
      xhdlC = NULL;
    }
    DeleteTaskPPC(dbTask);
    dbTask = NULL;
  }
  if (taskpool) {
    DeletePoolPPC(taskpool);
    taskpool = NULL;
  }
  taskloaded = FALSE;
}


ULONG wosdb_cont(BOOL strace,BOOL btrace)
/* start debugged task */
{
  struct Breakpoint *bp;
  ULONG sigmsk,eid;

  sTrace = strace;
  bTrace = btrace;

  bp = wosdb_hidebreakpoint((ADDR)ec.ec_UPC.ec_PC);
  SignalPPC(dbTask,1L<<sigRun);  /* run task */
  /* wait for next exception */
  sigmsk = WaitPPC((1L<<sigExcept) | (1L<<sigFinish));
  wosdb_showbreakpoint(bp);
  clearIABR();

  if (sigmsk & (1L<<sigFinish)) {
    /* task has finished... release it */
    wosdb_unload();
    return (EXCF_FINISHED);
  }

  if (ec.ec_ExcID == EXCF_PROGRAM &&
      *(ULONG *)ec.ec_UPC.ec_PC == TRAP_INS) {
    /* we have run into one of our breakpoints */
    clrbreakpt((ADDR)ec.ec_UPC.ec_PC,TRUE);  /* remove temp. breakpt. */
    eid = EXCF_BRKPT;
  }
  else
    eid = ec.ec_ExcID;

  /* check if we accidently entered our own ProgramExit() function */
  if (ec.ec_UPC.ec_SRR0 >= (ULONG)ProgramExit &&
      ec.ec_UPC.ec_SRR0 < (ULONG)ProgramExitEnd) {
    /* finish task */
    sTrace = bTrace = FALSE;
    remallbrkpts();
    SignalPPC(dbTask,1L<<sigRun);
    WaitPPC(1L<<sigFinish);
    wosdb_unload();
    eid = EXCF_FINISHED;
  }
  return (eid);
}


ULONG wosdb_taskresult()
{
  return (result);
}


char *wosdb_exceptinfo()
{
  switch (ec.ec_ExcID) {
    case EXCF_MCHECK:
      sprintf(buffer,"MACHINE CHECK");
      break;
    case EXCF_DACCESS:
      sprintf(buffer,"DATA ACCESS");
      break;
    case EXCF_IACCESS:
      sprintf(buffer,"INSTRUCTION ACCESS");
      break;
    case EXCF_INTERRUPT:
      sprintf(buffer,"EXTERNAL INTERRUPT");
      break;
    case EXCF_ALIGN:
      sprintf(buffer,"ALIGNMENT");
      break;
    case EXCF_PROGRAM:
      sprintf(buffer,"PROGRAM");
      break;
    case EXCF_FPUN:
      sprintf(buffer,"FP UNAVAILABLE");
      break;
    case EXCF_TRACE:
      sprintf(buffer,"TRACE");
      break;
    case EXCF_PERFMON:
      sprintf(buffer,"PERF MON");
      break;
    case EXCF_IABR:
      sprintf(buffer,"BREAKPOINT");
      break;
    default:
      sprintf(buffer,"UNKNOWN");
      break;
  }
  return (buffer);
}


char *wosdb_symbol(ADDR p)
/* returns string with symbol and offset, if a symbol exists */
{
  struct Section *sec = firstSec;
  struct Symbol *sym;
  char *label = NULL;
  ULONG offs = 0xffffffff;

  while (sec) {
    if (p >= sec->addr && p < (sec->addr+sec->len)) {
      sym = sec->symbols;
      while (sym) {
        /* @@@ this would be easier and faster when symbols are sorted */
        if (sym->addr <= p) {
          if ((p - sym->addr) < offs) {
            offs = p - sym->addr;
            label = sym->name;
          }
        }
        sym = sym->next;
      }
      if (label) {
        sprintf(buffer,"%s+%lx",label,offs);
        return (buffer);
      }
      else
        break;
    }
    sec = sec->next;
  }
  return (NULL);
}


char *wosdb_label(ADDR p)
/* returns string with symbol, if current address matches symbol addr. */
{
  struct Section *sec = firstSec;
  struct Symbol *sym;

  while (sec) {
    if (p >= sec->addr && p < (sec->addr+sec->len)) {
      sym = sec->symbols;
      while (sym) {
        if (sym->addr == p)
          return (sym->name);
        sym = sym->next;
      }
      break;
    }
    sec = sec->next;
  }
  return (NULL);
}


void wosdb_opersymbols(struct DisasmPara_PPC *dp,int len)
/* try to replace values in operand by symbols */
{
  ADDR a;
  char *op,*p,*sym;

  /* find beginning of last operand */
  op = p = dp->operands;
  while (*p) {
    if (*p++ == ',')
      op = p;
  }

  switch (dp->type) {

    case PPCINSTR_BRANCH:
      a = (ADDR)dp->iaddr + (long)dp->displacement;
      if (sym = wosdb_label(a))
        sprintf(op,"%s",sym);
      break;

    case PPCINSTR_LDST:
      a = (ADDR)(ec.ec_GPR[dp->sreg] + (long)dp->displacement);
      if (sym = wosdb_label(a))
        sprintf(op,"%s(r%d)",sym,(int)dp->sreg);
      break;
  }
}


int wosdb_validaddr(ADDR addr)
/* 0: invalid address */
/* 1: address belongs to normal RAM or 0x00000004 */
/* 2: address belongs to a section of the debugged program */
{
  int rc = 0;
  struct MemHeader *mh = (struct MemHeader *)SysBase->MemList.lh_Head;
  struct MemHeader *nextmh;

  addr = (ADDR)((ULONG)addr & ~3);
  while (nextmh = (struct MemHeader *)mh->mh_Node.ln_Succ) {
    if (addr >= (ADDR)((ULONG)mh->mh_Lower & ~255) &&
        addr < (ADDR)(((ULONG)mh->mh_Upper+255) & ~255)) {
      rc++;
      break;
    }
    mh = nextmh;
  }
  if (rc==0 && (ULONG)addr==4)  /* ExecBase 0x0004 is legal */
    rc++;

  if (rc!=0 && taskloaded) {
    struct Section *s = firstSec;

    while (s) {
      if (addr >= s->addr && addr < (s->addr+s->len)) {
        rc++;
        break;
      }
      s = s->next;
    }
  }

  return (rc);
}


ULONG wosdb_getexp(char *buf)
{
  void *expool;
  struct enode *root;
  ULONG val = 0;

  if (expool = CreatePoolPPC(0,0x1000,0x1000)) {
    if (root = exptree(expool,buf))
      val = (ULONG)calctree(root);
    DeletePoolPPC(expool);
  }
  return (val);
}


struct SpecRegs *wosdb_getspecregs()
{
  return (&spr);
}


struct EXCContext *wosdb_init()
{
  if ((sigExcept = AllocSignalPPC(-1)) < 0)
    return (NULL);
  if ((sigFinish = AllocSignalPPC(-1)) < 0) {
    FreeSignalPPC(sigExcept);
    return (NULL);
  }
  thisTask = FindTaskPPC(NULL);
  return (&ec);
}


void wosdb_exit()
{
  wosdb_unload();
  FreeSignalPPC(sigFinish);
  FreeSignalPPC(sigExcept);
}
