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
#include <stdbool.h>
#include <unistd.h>
#include <err.h>
#include <fcntl.h>
#include <string.h>

#define HUNK_SIZE_MASK	0x3FFFFFFF
#define HUNK_SIZE_MEMF	0xC0000000

#define HUNK_HEADER	0x3F3

struct hunkheader {
	uint32_t table_size;
	uint32_t first_hunk;
	uint32_t last_hunk;
} hh;

struct hunkinfo {
	uint32_t type;
	uint32_t size;
	uint8_t mem_flags;
	uint32_t mem_ext;
};

void usage(char *myname);

bool read32be(int fd, uint32_t *);
static uint32_t as32be(const uint8_t*);

int
main(int argc, char *argv[])
{
	int ifd, i;

	uint32_t hunk, tmp;
	struct hunkinfo *hi;	

	if (argc != 2) {
		usage(argv[0]);
		return(1);
	}	

	ifd = open(argv[1], O_RDONLY);
	if (ifd < 0) { 
		perror("Unable to open hunkfile");
		return(2);
	}

	read32be(ifd, &hunk);
	if (hunk != HUNK_HEADER) {
		fprintf(stderr, "Not an AmigaOS hunk file\n");
		return(3);
	}
		
	printf("HUNK_HEADER\n");

	read32be(ifd, &tmp);
	if (tmp != 0) {
		fprintf(stderr, "Resident library list should be empty in load files\n");	
		return(3);
	}

	read32be(ifd, &hh.table_size);
	read32be(ifd, &hh.first_hunk);
	read32be(ifd, &hh.last_hunk);
	printf("\tHunk table size: %d\n", hh.table_size);
	printf("\tFirst hunk: %d\n", hh.first_hunk);
	printf("\tLast hunk: %d\n", hh.last_hunk);

	hi = (struct hunkinfo *) malloc(hh.table_size * sizeof(struct hunkinfo));
	memset(hi, 0, (size_t) (hh.table_size * sizeof(struct hunkinfo)));

	for (i = 0; i < hh.table_size; i++) {
		read32be(ifd, &tmp);
		hi[i].size = tmp & HUNK_SIZE_MASK;
		hi[i].mem_flags = (tmp & HUNK_SIZE_MEMF) >> 30;
		printf("\tHunk %d size: %d longwords\n", i, hi[i].size); 
		if (hi[i].mem_flags != 0)
			printf("\t\tFlags: %d\n", hi[i].mem_flags);
		if (hi[i].mem_flags == 3) {
			read32be(ifd, &hi[i].mem_ext); 
			printf("\t\tExtended memory attribute: %x", hi[i].mem_ext);
		}
	}

	close(ifd);

	return(0);
}

bool
read32be(int fd, uint32_t *buf) {
	uint8_t tmpbuf[4];
	int n;

	n = read(fd, &tmpbuf, sizeof(tmpbuf));

	*buf = as32be(tmpbuf);

	return true;
}

static uint32_t
as32be(const uint8_t* in)
{
    return (in[0] << 24) | (in[1] << 16) | (in[2] << 8) | in[3];
}

void
usage(char *myname) {
	printf("%s: hunkfile\n", myname);
}

