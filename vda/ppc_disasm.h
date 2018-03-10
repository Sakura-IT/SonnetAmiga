/* $VER: ppc_disasm.h V1.6 (09.12.2011)
 *
 * Disassembler module for the PowerPC microprocessor family
 * Copyright (c) 1998-2001,2009,2011 Frank Wille
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


#ifndef PPC_DISASM_H
#define PPC_DISASM_H


/* version/revision */
#define PPCDISASM_VER 1
#define PPCDISASM_REV 6


/* typedefs */
typedef unsigned int ppc_word;
#ifndef NULL
#define NULL (0L)
#endif


/* general defines */
#define PPCIDXMASK      0xfc000000
#define PPCIDX2MASK     0x000007fe
#define PPCDMASK        0x03e00000
#define PPCAMASK        0x001f0000
#define PPCBMASK        0x0000f800
#define PPCCMASK        0x000007c0
#define PPCMMASK        0x0000003e
#define PPCCRDMASK      0x03800000
#define PPCCRAMASK      0x001c0000
#define PPCLMASK        0x00600000
#define PPCOE           0x00000400
#define PPCVRC          0x00000400
#define PPCDST          0x02000000
#define PPCSTRM         0x00600000

#define PPCIDXSH        26
#define PPCDSH          21
#define PPCASH          16
#define PPCBSH          11
#define PPCCSH          6
#define PPCMSH          1
#define PPCCRDSH        23
#define PPCCRASH        18
#define PPCLSH          21
#define PPCIDX2SH       1

#define PPCGETIDX(x)    (((x)&PPCIDXMASK)>>PPCIDXSH)
#define PPCGETD(x)      (((x)&PPCDMASK)>>PPCDSH)
#define PPCGETA(x)      (((x)&PPCAMASK)>>PPCASH)
#define PPCGETB(x)      (((x)&PPCBMASK)>>PPCBSH)
#define PPCGETC(x)      (((x)&PPCCMASK)>>PPCCSH)
#define PPCGETM(x)      (((x)&PPCMMASK)>>PPCMSH)
#define PPCGETCRD(x)    (((x)&PPCCRDMASK)>>PPCCRDSH)
#define PPCGETCRA(x)    (((x)&PPCCRAMASK)>>PPCCRASH)
#define PPCGETL(x)      (((x)&PPCLMASK)>>PPCLSH)
#define PPCGETIDX2(x)   (((x)&PPCIDX2MASK)>>PPCIDX2SH)
#define PPCGETSTRM(x)   (((x)&PPCSTRM)>>PPCDSH)


/* Disassembler structure, the interface to the application */

struct DisasmPara_PPC {
  ppc_word *instr;              /* pointer to instruction to disassemble */
  ppc_word *iaddr;              /* instr.addr., usually the same as instr */
  char *opcode;                 /* buffer for opcode, min. 10 chars. */
  char *operands;               /* operand buffer, min. 24 chars. */
/* changed by disassembler: */
  unsigned char type;           /* type of instruction, see below */
  unsigned char flags;          /* additional flags */
  unsigned short sreg;          /* register in load/store instructions */
  ppc_word displacement;        /* branch- or load/store displacement */
};

#define PPCINSTR_OTHER      0   /* no additional info for other instr. */
#define PPCINSTR_BRANCH     1   /* branch dest. = PC+displacement */
#define PPCINSTR_LDST       2   /* load/store instruction: displ(sreg) */
#define PPCINSTR_IMM        3   /* 16-bit immediate val. in displacement */

#define PPCF_ILLEGAL   (1<<0)   /* illegal PowerPC instruction */
#define PPCF_UNSIGNED  (1<<1)   /* unsigned immediate instruction */
#define PPCF_SUPER     (1<<2)   /* supervisor level instruction */
#define PPCF_64        (1<<3)   /* 64-bit only instruction */
#define PPCF_ALTIVEC   (1<<4)   /* AltiVec instruction */


/* ppc_disasm.o prototypes */
#ifndef PPC_DISASM_C
extern ppc_word *PPC_Disassemble(struct DisasmPara_PPC *);
#endif

#endif
