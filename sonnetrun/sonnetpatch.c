/*
 * sonnetrun/sonnetpatch - Patch WarpOS executables to load in 0x1005 memory.
 *
 * Copyright (c) 2015 SonnetAmiga project 
 *
 * This code is derived from software contributed to the SonnetAmiga project 
 * by Radoslaw Kujawa.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* Just a skeleton for now... */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <err.h>
#include <fcntl.h>

void usage(char *myname);

static uint32_t as32be(const uint8_t* in)
{
    return (in[0] << 24) | (in[1] << 16) | (in[2] << 8) | in[3];
}

int
main(int argc, char *argv[])
{
	int ifd, n;

	uint8_t hunk[4];

	if (argc != 2) {
		usage(argv[0]);
		return(1);
	}	

	ifd = open(argv[1], O_RDONLY);
	if (ifd < 0) { 
		perror("Unable to open hunkfile");
		return(2);
	}

	while((n = read(ifd, &hunk, sizeof(hunk)) > 0)) {
		printf("\t%X\n", as32be(hunk));
	}

	close(ifd);

	return(0);
}

void
usage(char *myname) {
	printf("%s: hunkfile\n", myname);
}

