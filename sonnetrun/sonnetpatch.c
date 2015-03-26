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

#include <sys/queue.h>

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
	uint32_t num;
	uint32_t type;
	uint32_t size;
	uint8_t mem_flags;
	uint32_t mem_ext;
	uint32_t relocs;
	TAILQ_ENTRY(hunkinfo) tqe;
};

void usage(char *);
bool read32be(int fd, uint32_t *);
uint32_t as32be(const uint8_t*);
bool hunk_header_parse(int);
bool hunk_all_parse(int);
void hunk_info_print(void);
void snprintf_memf(char *str, size_t bufsize, uint8_t memf);

TAILQ_HEAD(, hunkinfo) hiq_head;

int
main(int argc, char *argv[])
{
	int ifd;
	int copt, opt_patchit;
	char *myname;
	char *opt_patchtok;

	opt_patchit = 0;
	myname = argv[0];

	while ((copt = getopt(argc, argv, "p:")) != -1) {
		switch (copt) {
		case 'p':
			opt_patchit = 1;
			while ((opt_patchtok = strsep(&optarg, ",")) != NULL)
				printf("%s\n", opt_patchtok); //XXX
			break;
		case 'h':
		case '?':
		default:
			usage(myname);
			return 1;
		}
	}
	argc -= optind;	
	argv += optind;

	if (argc != 1) {
		usage(myname);
		return 1;
	}

	ifd = open(argv[0], O_RDONLY);
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

	// XXX: TAILQ cleanup
	close(ifd);
	return EXIT_SUCCESS;
}

bool
hunk_all_parse(int ifd)
{
	uint32_t current_hunk;
	uint32_t subhunkid, tmp;
	struct hunkinfo *tmphip, *hip;

	current_hunk = 0; /* we start search just after header */

	while (current_hunk <= hh.last_hunk) {

		/* extract a pointer for the current hunk from the queue */
		TAILQ_FOREACH(tmphip, &hiq_head, tqe) {
			if(tmphip->num == current_hunk)
				hip = tmphip;	
		}

		read32be(ifd, &hip->type); 
		lseek(ifd, (hip->size+1) * sizeof(uint32_t), SEEK_CUR);

		read32be(ifd, &subhunkid);
		if (subhunkid != HUNK_END) {
			hip->relocs = subhunkid;
		
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
	struct hunkinfo *hip;

	TAILQ_INIT(&hiq_head);

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
	printf("\tFirst hunk to load: %d\n", hh.first_hunk);
	printf("\tLast hunk to load: %d\n", hh.last_hunk);

	for (i = 0; i < hh.table_size; i++) {
		read32be(ifd, &tmp);
		hip = (struct hunkinfo *) malloc(sizeof(struct hunkinfo));
		memset(hip, 0, sizeof(struct hunkinfo));
		hip->num = i;
		hip->size = tmp & HUNK_SIZE_MASK;
		hip->mem_flags = (tmp & HUNK_SIZE_MEMF) >> 30;
		if (hip->mem_flags == 3) 
			read32be(ifd, &hip->mem_ext); 
		TAILQ_INSERT_TAIL(&hiq_head, hip, tqe);
	}

	return true;
}

void
hunk_info_print(void)
{
	int i;
	char *memf_str;
	struct hunkinfo *hip;

	const size_t memf_bufsize = 32;

	memf_str = malloc(sizeof(char) * memf_bufsize);

	TAILQ_FOREACH(hip, &hiq_head, tqe) {
		printf("\tHunk %d type: %#x\n", hip->num, hip->type);
		printf("\t\tSize: %d Amiga longwords (%ld bytes)\n",
		    hip->size, hip->size * sizeof(uint32_t)); 
		snprintf_memf(memf_str, memf_bufsize, hip->mem_flags);
		printf("\t\tFlags: %s\n", memf_str);
		if (hip->mem_flags == 3) 
			printf("\t\tExtended memory attribute: %#x\n", 
			    hip->mem_ext);
		if (hip->relocs) {
			printf("\t\tRelocation: %#x\n", hip->relocs);
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
	printf("%s: [-p hnum...] hunkfile\n", myname);
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

