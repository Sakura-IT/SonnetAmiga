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

/* This is a proof-of-concept standalone binary patcher. */

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
#define HUNK_END	0x3F2

#define MEMF_CHIP	0x1	/* << 30 */
#define MEMF_FAST	0x2	/* << 30 */

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
	uint32_t relocs;
};

void usage(char *);
bool read32be(int fd, uint32_t *);
uint32_t as32be(const uint8_t*);
bool hunk_header_parse(int);
bool hunk_all_parse(int);
void hunk_info_print(void);
void snprintf_memf(char *str, size_t bufsize, uint8_t memf);

static struct hunkinfo *hi;	

int
main(int argc, char *argv[])
{
	int ifd;

	if (argc != 2) {
		usage(argv[0]);
		return 1;
	}	

	ifd = open(argv[1], O_RDONLY);
	if (ifd < 0) { 
		perror("Unable to open hunkfile");
		return 2;
	}

	if (!hunk_header_parse(ifd)) {
		close(ifd);
		return 3;
	}

	if(!hunk_all_parse(ifd)) {
		close(ifd);
		return 3;
	}

	hunk_info_print();

	close(ifd);
	return EXIT_SUCCESS;
}

bool
hunk_all_parse(int ifd)
{
	uint32_t current_hunk;
	uint32_t subhunkid, tmp;

	current_hunk = hh.first_hunk;

	while (current_hunk <= hh.last_hunk) {
		read32be(ifd, &hi[current_hunk].type); 
		lseek(ifd, (hi[current_hunk].size+1) * sizeof(uint32_t), SEEK_CUR);

		read32be(ifd, &subhunkid);
		if (subhunkid != HUNK_END) {
			// probably a relocation 
			hi[current_hunk].relocs = subhunkid;
		
			read32be(ifd, &tmp);	
			while (tmp != HUNK_END) {
				read32be(ifd, &tmp);	
			}
		}	
		current_hunk++;
	}	

	return true;
}

bool
hunk_header_parse(int ifd)
{
	int i;
	uint32_t hunk, tmp;


	read32be(ifd, &hunk);
	if (hunk != HUNK_HEADER) {
		fprintf(stderr, "Not an AmigaOS hunk file\n");
		return false;
	}
		
	printf("HUNK_HEADER\n");

	read32be(ifd, &tmp);
	if (tmp != 0) {
		fprintf(stderr, "Resident library list should be empty in load files\n");	
		return false;
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
		if (hi[i].mem_flags == 3) 
			read32be(ifd, &hi[i].mem_ext); 
	}

	return true;
}

void
hunk_info_print(void)
{
	int i;
	char *memf_str;
	const size_t memf_bufsize = 32;

	memf_str = malloc(sizeof(char) * memf_bufsize);

	for (i = 0; i < hh.table_size; i++) {
		printf("\tHunk %d type: %#x\n", i, hi[i].type);
		printf("\t\tSize: %d Amiga longwords (%ld bytes)\n",
		    hi[i].size, hi[i].size * sizeof(uint32_t)); 
		snprintf_memf(memf_str, memf_bufsize, hi[i].mem_flags);
		printf("\t\tFlags: %s\n", memf_str);
		if (hi[i].mem_flags == 3) 
			printf("\t\tExtended memory attribute: %#x\n", hi[i].mem_ext);
		if (hi[i].relocs) {
			printf("\t\tRelocation: %#x\n", hi[i].relocs);
		}
	}
}

bool
read32be(int fd, uint32_t *buf) {
	uint8_t tmpbuf[4];
	int n;

	n = read(fd, &tmpbuf, sizeof(tmpbuf));

	if (n != 4) {
		fprintf(stderr, "Unaligned data!\n"); /* XXX: inform where */
		return false;
	}

	*buf = as32be(tmpbuf);
	return true;
}

uint32_t
as32be(const uint8_t* in)
{
    return (in[0] << 24) | (in[1] << 16) | (in[2] << 8) | in[3];
}

void
usage(char *myname) {
	printf("%s: hunkfile\n", myname);
}

void
snprintf_memf(char *str, size_t bufsize, uint8_t memf)
{
	memset(str, 0, bufsize);

	if ( (memf & MEMF_CHIP) && (memf & MEMF_FAST) ) 
		snprintf(str, bufsize, "Extended mem attributes");
	else if (memf & MEMF_CHIP) 
		snprintf(str, bufsize, "MEMF_CHIP");
	else if (memf & MEMF_FAST) 
		snprintf(str, bufsize, "MEMF_FAST");
	else 
		snprintf(str, bufsize, "None (implied MEMF_PUBLIC)");

}

