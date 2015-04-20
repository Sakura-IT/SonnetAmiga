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
#include <unistd.h>
#include <err.h>
#include <fcntl.h>
#include <string.h>
#include <ctype.h>
#include <assert.h>

#ifdef __VBCC__
#include "queue.h"
typedef uint8_t bool;
#define true 1
#define false 0
#else
#include <stdbool.h>
#include <sys/queue.h>
#endif

#define HUNK_UNIT	0x3E7
#define HUNK_NAME	0x3E8
#define HUNK_CODE	0x3E9
#define HUNK_DATA	0x3EA
#define HUNK_BSS	0x3EB
#define HUNK_RELOC32	0x3EC
#define HUNK_RELOC32SHORT 0x3FC
#define HUNK_RELOC16	0x3ED
#define HUNK_RELOC8	0x3EE
#define HUNK_DRELOC32	0x3F7
#define HUNK_DRELOC16	0x3F8
#define HUNK_DRELOC8	0x3F9
#define HUNK_EXT	0x3EF
#define HUNK_SYMBOL	0x3F0
#define HUNK_DEBUG	0x3F1

#define HUNK_END	0x3F2
#define HUNK_HEADER	0x3F3
#define HUNK_OVERLAY	0x3F5
#define HUNK_BREAK	0x3F6

#define HUNK_SIZE_MASK	0x3FFFFFFF
#define HUNK_SIZE_MEMF	0xC0000000

#define MEMF_CHIP	0x1	/* << 30 */
#define MEMF_FAST	0x2	/* << 30 */

#define SONNET_MEM_ID	0x00001005
/*
 * These structs do not correspond to binary format of hunk files, they are
 * used only as internal representation of hunk/patch parameters inside of
 * this program.
 */
/* Hunk definition. */
struct hunkdef {
	uint32_t id;
	const char *name;
	bool reloc;		/* is it relocation hunk? */
};
/* Hunk file header. */
struct hunkheader {
	uint32_t table_size;
	uint32_t first_hunk;
	uint32_t last_hunk;
};
/* Per-hunk information. */
struct hunkinfo {
	uint32_t num;
	uint32_t type;
	uint32_t size;
	uint8_t mem_flags;
	uint32_t mem_ext;
	uint32_t relocs;
	off_t offset;		/* where does this hunk start */
	const struct hunkdef *hd;
	const struct hunkdef *reloc_hd;
	TAILQ_ENTRY(hunkinfo) tqe;
};
/* Which hunks need to be patched. */
struct hunkpatch {
	/* TODO: make this more flexible */
	uint32_t num;
	TAILQ_ENTRY(hunkpatch) tqe;
};

void usage(char *);
bool read32be(int, uint32_t *);
uint32_t as32be(const uint8_t *);
bool copy32(int, int);
bool write32be(int, uint32_t *);
bool hunk_header_parse(int);
bool hunk_all_parse(int);
void hunk_info_print(void);
bool hunk_get_type(uint32_t, const struct hunkdef **);
bool hunk_to_patch_tokenize(char **);
bool hunk_header_patch_sonnet(int, int);
void snprintf_memf(char *, size_t, uint8_t);
bool file_close(int *);
bool file_open(int *, char *);
bool file_create(int *, char *);
#if 0 
char * strsep(char **, const char *);
#endif

const struct hunkdef hunkdefs[] = {
		/* id */	/* name */	/* relocation? */
	{	HUNK_UNIT,	"HUNK_UNIT",	false	},
	{	HUNK_NAME,	"HUNK_NAME",	false	},
	{	HUNK_CODE,	"HUNK_CODE",	false	},
	{	HUNK_DATA,	"HUNK_DATA",	false	},
	{	HUNK_BSS,	"HUNK_BSS",	false	},
	{	HUNK_RELOC32,	"HUNK_RELOC32",	true	},
	{	HUNK_RELOC32SHORT, "HUNK_RELOC32SHORT", true },
	{	HUNK_RELOC16,	"HUNK_RELOC16",	true	},
	{	HUNK_RELOC8,	"HUNK_RELOC8",	true	},
	{	HUNK_DRELOC32,	"HUNK_DRELOC32", true	},
	{	HUNK_DRELOC16,	"HUNK_DRELOC16", true	},
	{	HUNK_DRELOC8,	"HUNK_DRELOC8",	true	},
	{	HUNK_EXT,	"HUNK_EXT",	false	},
	{	HUNK_SYMBOL,	"HUNK_SYMBOL",	false	},
	{	HUNK_DEBUG,	"HUNK_DEBUG",	false	},
	{	0, NULL, false			}
}; 

struct hunkheader hh;
TAILQ_HEAD(, hunkinfo) hiq_head;
TAILQ_HEAD(, hunkpatch) hpq_head;

int
main(int argc, char *argv[])
{
	int ifd, ofd;
	int copt;
	bool opt_patchit;
	char *myname;

	opt_patchit = false;
	myname = argv[0];

	while ((copt = getopt(argc, argv, "p:")) != -1) {
		switch (copt) {
		case 'p':
			opt_patchit = true;
			if (!hunk_to_patch_tokenize(&optarg)) {
				fprintf(stderr, 
				    "Syntax error while tokenizing hunk list\n");
				return 1;
			}

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

	if (argc < 1) {
		usage(myname);
		return 1;
	}

	if (!file_open(&ifd, argv[0]))
		return 2; 

	if (opt_patchit) {
		if (!file_create(&ofd, argv[1])) {
			file_close(&ifd);
			return 2;
		}
	}

	if (!hunk_header_parse(ifd)) {
		file_close(&ifd);
		if(opt_patchit)
			file_close(&ofd);
		return 3;
	}

	if(!hunk_all_parse(ifd)) {
		file_close(&ifd);
		if(opt_patchit)
			file_close(&ofd);
		return 3;
	}

	hunk_info_print();

	if (opt_patchit) 
		if (!hunk_header_patch_sonnet(ifd, ofd)) 
			return 4;


	/* XXX: TAILQ cleanup here and above in case of errors */
	file_close(&ifd);
	return EXIT_SUCCESS;
}

bool
hunk_header_patch_sonnet(int ifd, int ofd)
{
	uint32_t rtmp, ext_mem_patch;
	struct hunkinfo *tmphip, *hip;
	struct hunkpatch *hpp;
	bool need_patching;
	int current_hunk, n;

	current_hunk = 0;
	ext_mem_patch = SONNET_MEM_ID;

	lseek(ifd, 0, SEEK_SET); /* rewind to beginning of the file */

	/* copy beginning of header as is */
	copy32(ifd, ofd);
	copy32(ifd, ofd);
	copy32(ifd, ofd);
	copy32(ifd, ofd);
	copy32(ifd, ofd);

	/* check if size definitions */
	while (current_hunk < hh.table_size) {

		hip = NULL;
		need_patching = false;

		/* extract hunkinfo for a current hunk */
		TAILQ_FOREACH(tmphip, &hiq_head, tqe) {
			if(tmphip->num == current_hunk) 
				hip = tmphip;
		}
		assert(hip != NULL);

		/* now check if the header is to be patched */
		TAILQ_FOREACH(hpp, &hpq_head, tqe) {
			if(hip->num == hpp->num)
				need_patching = true;
		}

		read32be(ifd, &rtmp);

		assert (hip->mem_flags == ((rtmp & HUNK_SIZE_MEMF) >> 30));

		if (need_patching) {
			if (hip->mem_flags & (MEMF_CHIP|MEMF_FAST)) {	
				fprintf(stderr,
				    "Hunk %d already using extended mem attributes!\n", 
				    hip->num);
				return false;
			} else {
				rtmp |= HUNK_SIZE_MEMF;
				printf("Patching hunk %d size to %x, ext. attr %x\n",
				    hip->num, rtmp, ext_mem_patch);
				write32be(ofd, &rtmp);
				write32be(ofd, &ext_mem_patch);
			}
		} else {
			write32be(ofd, &rtmp);
			if (hip->mem_flags & (MEMF_CHIP|MEMF_FAST)) {
				copy32(ifd, ofd);
			}
		}

		/* move on to next hunk size definition */
		current_hunk++;
	}

	/* just copy rest of the file as is */
	while ((n = read(ifd, &rtmp, 4)) > 0)
		write(ofd, &rtmp, n);

	return true;
}

/*
 * Convert a string of hunk numbers (as passed by getopt) into a list of 
 * structs describing which hunks need to be patched. 
 */
bool
hunk_to_patch_tokenize(char **hunklist)
{
	char *patchtok;
	struct hunkpatch *hpp;
	bool err;

	err = false;
	TAILQ_INIT(&hpq_head);

	while ((patchtok = strsep(hunklist, ",")) != 0) { /* NULL */
		printf("%s\n", patchtok); 
		hpp = (struct hunkpatch *) malloc(sizeof(struct hunkpatch));
		memset(hpp, 0, sizeof(struct hunkpatch));
		if (!isdigit(patchtok[0])) /* better check than nothing */
			err = true;
		hpp->num = atoi(patchtok);
		TAILQ_INSERT_TAIL(&hpq_head, hpp, tqe);
	}

	if (err) {
		/* XXX: clean up TAILQ  */
		return false;
	}

	return true;
}

bool
file_close(int *fd)
{
	if (close(*fd) != 0) {
		perror("Unable to close file");
		return false;
	}

	return true;
}

bool 
file_open(int *fd, char *path)
{
	*fd = open(path, O_RDONLY);
	if (*fd < 0) { 
		perror("Unable to open file");
		return false;
	}

	return true;
}

bool
file_create(int *fd, char *path) 
{
#ifdef __VBCC__
	*fd = open(path, O_RDWR | O_CREAT | O_TRUNC);
#else
	*fd = open(path, O_RDWR | O_CREAT | O_TRUNC, S_IRWXU);
#endif
	if (*fd < 0) { 
		perror("Unable to open file");
		return false;
	}
	return true;
}


/* Parse all hunks in file, extract their IDs and relocation information. */
bool
hunk_all_parse(int ifd)
{
	uint32_t current_hunk;
	uint32_t subhunkid, tmp;
	struct hunkinfo *tmphip, *hip;
	off_t offset;

	current_hunk = 0; /* we start search just after header */

	offset = lseek(ifd, 0, SEEK_CUR); /* get current offset */

	while (current_hunk < hh.table_size) {

		/* extract a pointer for the current hunk from the queue */
		TAILQ_FOREACH(tmphip, &hiq_head, tqe) {
			if(tmphip->num == current_hunk)
				hip = tmphip;	
		}

		read32be(ifd, &hip->type); 
		if (!hunk_get_type(hip->type, &hip->hd)) 
			fprintf(stderr, "Couldn't get description for %x\n", 
		    hip->type);
		hip->offset = offset;
		
		offset = lseek(ifd, (hip->size+1) * sizeof(uint32_t), SEEK_CUR);

		read32be(ifd, &subhunkid);
		if (subhunkid != HUNK_END) {
			hip->relocs = subhunkid;

			if (!hunk_get_type(hip->relocs, &hip->reloc_hd)) 
				fprintf(stderr, "Couldn't get description for %x (sub)\n", 
			    hip->type);

			read32be(ifd, &tmp);	
			while (tmp != HUNK_END) {
				read32be(ifd, &tmp);	
			}
		}	
		current_hunk++;
	} 

	return true;
}

/* Parse hunk header, extract number of the hunks and their sizes. */
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
		if (hip->mem_flags & (MEMF_CHIP|MEMF_FAST))
			read32be(ifd, &hip->mem_ext); 
		TAILQ_INSERT_TAIL(&hiq_head, hip, tqe);
	}

	return true;
}

void
hunk_info_print(void)
{
	char *memf_str;
	struct hunkinfo *hip;

	const size_t memf_bufsize = 32;

	memf_str = malloc(sizeof(char) * memf_bufsize);

	TAILQ_FOREACH(hip, &hiq_head, tqe) {

		assert(hip->hd != NULL);
		assert(hip->type != 0);
		assert(hip->offset != 0);

		printf("%s (%#x) hunk number %d at offset %#llx\n", 
		    hip->hd->name, hip->type, hip->num, hip->offset);
		printf("\tSize: %d Amiga longwords (%ld bytes)\n",
		    hip->size, hip->size * sizeof(uint32_t)); 
		snprintf_memf(memf_str, memf_bufsize, hip->mem_flags);
		printf("\tFlags: %s\n", memf_str);
		if (hip->mem_flags == 3) 
			printf("\t\tExtended memory attribute: %#x\n", 
			    hip->mem_ext);
		if (hip->relocs) {
			printf("\tRelocation: %s (%#x)\n", hip->reloc_hd->name, 
			    hip->relocs);
		}
	}

	free(memf_str);
}

bool
read32be(int fd, uint32_t *buf) 
{
	uint8_t tmpbuf[4];
	int n;
	off_t o;

	n = read(fd, &tmpbuf, sizeof(tmpbuf));

	if (n != 4) {
		o = lseek(fd, 0, SEEK_CUR);
		fprintf(stderr, "Unaligned read at %llx!\n", o); 
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

bool
write32be(int fd, uint32_t *buf) 
{
	uint8_t tmpbuf[4];
	int n;
	off_t o;

	tmpbuf[0] = (*buf >> 24) & 0xff;
	tmpbuf[1] = (*buf >> 16) & 0xff;
	tmpbuf[2] = (*buf >> 8) & 0xff;
	tmpbuf[3] = *buf & 0xff;

	n = write(fd, &tmpbuf, 4);
	if (n != 4) {
		o = lseek(fd, 0, SEEK_CUR);
		fprintf(stderr, "Unaligned write at %llx!\n", o); 
		return false;
	}

	return true;
}

bool
copy32(int ifd, int ofd)
{
	uint8_t buf[4];
	int rn, wn;
	off_t o;

	rn = read(ifd, &buf, 4);
	wn = write(ofd, &buf, 4);

	if ((rn != 4) || (wn != 4)) {
		o = lseek(ifd, 0, SEEK_CUR);
		fprintf(stderr, "Unaligned copy at %llx!\n", o); 
		return false;
	}

	return true;
}

void
usage(char *myname)
{
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

bool
hunk_get_type(uint32_t id, const struct hunkdef **ret_hd) 
{
	int i;

	i = 0;

	while(hunkdefs[i].id != 0) {
		if (hunkdefs[i].id == id) {
			*ret_hd = &hunkdefs[i];
			return true;
		}
		i++;
	}

	return false;
}

#if 0
char *
strsep(char **str, const char *delim)
{
	char *save = *str;
	if(*str == NULL)
		return NULL;
	*str = *str + strcspn(*str, delim);
	if(**str == 0)
		*str = NULL;
	else {
		**str = 0;
		(*str)++;
	}
	return save;
}
#endif

