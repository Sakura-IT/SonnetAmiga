/*
 *                Standalone BogoMips program
 *
 * Based on code Linux kernel code in init/main.c and
 * include/linux/delay.h
 *
 * For more information on interpreting the results, see the BogoMIPS
 * Mini-HOWTO document.
 *
 * version: 1.3 
 *  author: Jeff Tranter (Jeff_Tranter@Mitel.COM)
 *
 * Added a PPC delay function as found in Linux kernel 2.4.16.
 * Added WarpOS specific timer functions.
 */

#include <stdio.h>
#include <time.h>
#include <proto/powerpc.h>
#include <devices/timer.h>

#ifdef CLASSIC_BOGOMIPS
/* the original code from the Linux kernel */
static __inline__ void delay(int loops)
{
  __asm__(".align 2,0x90\n1:\tdecl %0\n\tjns 1b": :"a" (loops):"ax");
}
#endif

#ifdef QNX_BOGOMIPS
/* version for QNX C compiler */
void delay(int loops);
#pragma aux delay = \
     "l1:"       \
     "dec eax"   \
     "jns l1"    \
     parm nomemory [eax] modify exact nomemory [eax];
#endif

#ifdef POWERPC
static void delay(int loops) = "\tmtctr\t3\n.xx:\tbdnz\t.xx";
#endif

#ifdef PORTABLE_BOGOMIPS
/* portable version */
static void delay(int loops)
{
  long i;
  for (i = loops; i >= 0 ; i--)
    ;
}
#endif

int
main(void)
{
  unsigned long loops_per_sec = 1;
  unsigned long ticks = 0;
  struct timeval tv;
  struct timeval tv2;
  
  printf("Calibrating delay loop.. ");
  fflush(stdout);
  
  while ((loops_per_sec <<= 1)) {
    GetSysTimePPC(&tv2);
    delay(loops_per_sec);
    GetSysTimePPC(&tv);
    SubTimePPC(&tv, &tv2);
    ticks = (tv.tv_secs*50) + (tv.tv_micro/20000);
    if (ticks >= CLOCKS_PER_SEC) {
      loops_per_sec = (loops_per_sec / ticks) * CLOCKS_PER_SEC;
      printf("ok - %lu.%02lu BogoMips\n",
 	     loops_per_sec/500000,
	     (loops_per_sec/5000) % 100
	     );
      return 0;
    }
  }
  printf("failed\n");
  return -1;
}
