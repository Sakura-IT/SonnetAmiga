/* $VER: vdappc V1.6 (26.11.2017)
 *
 * Simple PowerPC file and memory disassembler.
 * Copyright (c) 1998-2017  Frank Wille
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "ppc_disasm.h"

#define VERSION 1
#define REVISION 6

const char *_ver = "$VER: vdappc 1.6 (26.11.2017)\r\n";


int main(int argc,char *argv[])
{
  FILE *fh = NULL;
  unsigned char buf[sizeof(ppc_word)];
  unsigned char *p,*e;
  unsigned long foff=0;
  struct DisasmPara_PPC dp;
  char opcode[10];
  char operands[24];

  if ((argc!=2 && argc!=3) || !strncmp(argv[1],"-h",2) || argv[1][0]=='?') {
    printf("vdappc V%d.%d  (c)1998-2017 by Frank Wille\n"
           "PowerPC disassembler V%d.%d  (c)1998-2001,2009,2011 "
           "by Frank Wille\n"
           "Build date: " __DATE__ ", " __TIME__ "\n\n"
           "Usage: %s <file> | <address> [<end-address>]\n",
           VERSION,REVISION,PPCDISASM_VER,PPCDISASM_REV,argv[0]);
    return 1;
  }

  /* initialize DisasmPara */
  dp.opcode = opcode;
  dp.operands = operands;

  if (isdigit((unsigned int)argv[1][0])) {
    sscanf(argv[1],"%i",(int *)&p);
    if (argc == 3)
      sscanf(argv[2],"%i",(int *)&e);
    else
      e = 0;
  }
  else {
    /* open file */
    if (!(fh = fopen(argv[1],"rb"))) {
      fprintf(stderr,"%s: Can't open %s!\n",argv[0],argv[1]);
      return 10;
    }
    dp.instr = (ppc_word *)buf;
    p = buf;
  }

  for (;;) {
    /* disassembler loop */
    if (fh) {
      if (fread(buf,1,sizeof(ppc_word),fh) != sizeof(ppc_word))
        break;  /* EOF */
      dp.iaddr = (ppc_word *)foff;

    }
    else {
      if (e == 0 || p < e)
        dp.instr = dp.iaddr = (ppc_word *)p;
      else
        break;
    }

    PPC_Disassemble(&dp);

    printf("%08lx:  %02x%02x%02x%02x\t%s\t%s\n",fh?foff:(unsigned long)p,
           p[0],p[1],p[2],p[3],opcode,operands);
    if (fh)
      foff += sizeof(ppc_word);
    else
      p += sizeof(ppc_word);
  }

  /* cleanup */
  if (fh)
    fclose(fh);
  return 0;
}
