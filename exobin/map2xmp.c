/**
 * map2xmp
 *    Translate a MAP file into a packed file
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <sys/stat.h>
#include <sys/types.h>
#include <dirent.h>

#include "membuf_io.h"
#include "exo_helper.h"

typedef struct {
	unsigned short	length;
	unsigned char	mode;
	unsigned char	width;
	unsigned char	height;
	unsigned char	has_extension;
	unsigned char	data[16000];
	unsigned char	extension[38];
} IMG;

#define RAMA	0
#define RAMB	8000

#ifndef TRUE
#define TRUE	1
#define	FALSE	0
#endif

static void convert(char *infile, char *outfile);
static void *alloc(int size);
static IMG  *read_map(char *infile);
static void optim(IMG *img);
static void process(char *filename);
static void membuf_cpy_plane(struct membuf *buf, unsigned char *data, unsigned char width, unsigned char height);
#if 0
static void save_ppm(char *filename, unsigned char *data);
#endif

int total = 0, total2 = 0, total3 = 0, num = 0;

int main(int ac, char **av) {
	int i;
	
	LOG_INIT_CONSOLE(LOG_WARNING);
	    
	for(i=1; i<ac; ++i) {
		struct stat buf;
		
		if(!stat(av[i], &buf)) {
			if(S_ISDIR(buf.st_mode)) {
				DIR *dir = opendir(av[i]);
				if(dir) {
					struct dirent *dirent;
					while((dirent = readdir(dir))!=NULL) {
						char *s = alloc(strlen(av[i]) + strlen(dirent->d_name) + 2);
						strcpy(s, av[i]);
						strcat(s, "/");
						strcat(s, dirent->d_name);
						process(s);
						free(s);
					}
					closedir(dir);
				}
			} else if(S_ISREG(buf.st_mode)) {
				process(av[i]);
			}
		}
	}
	
	
	LOG_FREE;
	
	return EXIT_SUCCESS;
}

/**
 * compress the given file
 */
static void process(char *filename) {
	char *out = alloc(4+strlen(filename));
	char *s;
	
	/* change extension */
	strcpy(out, filename);
	for(s=out; *s; ++s) {}
	while(s>out && *s!='.') --s;
	if(*s=='.')	strcpy(s, ".xmp");
	else		strcat(s, ".xmp");
	
	convert(filename, out);
		
	free(out);
}
	
/**
 * A calloc() that checks out of memory.
 */
static void *alloc(int size) {
	void *p = calloc(size, 1);
	if(p==NULL) {fprintf(stderr, "Out of memory!\n"); exit(EXIT_FAILURE);}
	return p;
}

/**
 * converts MAP file "infile" to EXO file "outfile"
 */
static void convert(char *infile, char *outfile) {
	IMG *img = read_map(infile);
	struct membuf inbuf[1];
	struct membuf outbuf[1];
	struct membuf tmpbuf[1];
	struct crunch_info info[1];
	static struct crunch_options options[1] = { CRUNCH_OPTIONS_DEFAULT };
	char *name = infile;
	/* int t3; */
	
	if(!img) return;
	
	while(*name) ++name;
	while(name>infile) {
		if(*name=='/' || *name=='\\') {++name; break;}
		--name;
	}
	
	optim(img);	
	
	/* save_ppm("ramb.ppm", img->data + RAMA); */
	/* save_ppm("ramd.ppm", img->data + RAMB); */
	
	/* data_start = membuf_memlen(inbuf); */
	
	membuf_init(tmpbuf);
	membuf_init(outbuf);
#if 0
	membuf_append(outbuf, "xmp", 4);
	membuf_append_char(outbuf, img->mode);
	if(img->has_extension) {
		membuf_append_char(outbuf, (char)0xA5);
		membuf_append_char(outbuf, (char)0x5A);
		membuf_append(outbuf, img->extension, sizeof(img->extension));
	}
	membuf_append_char(outbuf, img->width);
	membuf_append_char(outbuf, img->height);
#endif
	
	/* compress RAMA & RAMB separately */
	membuf_init(inbuf);
	
	/*
	membuf_append(inbuf, img->data+RAMA, 40*200);
	membuf_append(inbuf, img->data+RAMB, 40*200);
	{
		char *p = membuf_get(inbuf);
		int i;
		for(i=8000-40; --i>=0;) {
			p[RAMA+i+40] ^= p[RAMA+i];
			p[RAMB+i+40] ^= p[RAMB+i];
		}
	}
	
	crunch(inbuf, outbuf, options, info);
	total3 += (t3 = membuf_memlen(outbuf));
	
	membuf_truncate(outbuf, 0);
	*/
	
	membuf_truncate(inbuf, 0);
/*	membuf_truncate(outbuf, 0); */
	membuf_cpy_plane(inbuf, img->data + RAMA, img->width, img->height<<3);
	crunch_backwards(inbuf, outbuf, options, info);
	reverse_buffer(membuf_get(outbuf), membuf_memlen(outbuf));
	membuf_append(tmpbuf, membuf_get(outbuf), membuf_memlen(outbuf));
	
	#if 1
	membuf_truncate(inbuf, 0);
	membuf_truncate(outbuf, 0);
	membuf_cpy_plane(inbuf, img->data + RAMB, img->width, img->height<<3);
	crunch_backwards(inbuf, outbuf, options, info);
	reverse_buffer(membuf_get(outbuf), membuf_memlen(outbuf));
	membuf_append(tmpbuf, membuf_get(outbuf), membuf_memlen(outbuf));
	#endif
	
	++num;
	total += membuf_memlen(tmpbuf);
	total2 += img->length;
	
	fprintf(stdout, "%s : %d -> %d (#%d : %d -> %d)\n", name, 
		img->length, membuf_memlen(tmpbuf), num, total2, total);
	
	
	/*
	membuf_truncate(outbuf, 0);
	crunch_backwards(inbuf, outbuf, options, info);
	fprintf(stdout, "%s : <<< %d -> %d\n", name, img->length, membuf_memlen(outbuf));
	*/
	
        
	/*
        LOG(LOG_NORMAL, (" Literal sequences are %sused and",
                         info->literal_sequences_used ? "" : "not "));
        LOG(LOG_NORMAL, (" the safety offset is %d.\n",
                         info->needed_safety_offset));

	*/
	write_file(outfile, tmpbuf);
	
	membuf_free(tmpbuf);
	membuf_free(outbuf);
	membuf_free(inbuf);
}

/**
 * Optimizes the image by creating more redundant blocks
 */
static void optim(IMG *img) {
	short i, p;
	
	/* only available for non-interlaced modes */
	if(img->mode != 0) return;
	
	for(p=i=0; i<40; ++i, p-=40*199-1) {
		unsigned char j, d, d1, d2;
		
		d  = img->data[RAMA + p];
		d2 = ((d1 = img->data[RAMB + p] ^ 192)>>3) & 15;	/* fg color */
		d1 = (d1 & 7) | ((d1>>4) & 8);						/* bg color */
		
		for(j=1; j<200; ++j) {
			unsigned char c = d, c1 = d1, c2 = d2;
			
			p+=40;
			
			d  = img->data[RAMA + p];
			d2 = ((d1 = img->data[RAMB + p] ^ 192)>>3) & 15;
			d1 = (d1 & 7) | ((d1>>4) & 8);
			
			/* only one color, try to reuse the color of the previous raw */
			/* reorder to have d2>d1 to create more redundant portions */
			if(0 && d1>d2) {
				unsigned char t = d1;
				d1 = d2; d2 = t; d ^= 0xFF;
			}
			if(d == 0xff) d1 = c1; else
			if(d == 0x00) d2 = c2; else
			if(d1 == d2) d = c;
			/* reorder to have d2>d1 to create more redundant portions */
			if(0 && d1>d2) {
				unsigned char t = d1;
				d1 = d2; d2 = t; d ^= 0xFF;
			}
			img->data[RAMA + p] = d;
			img->data[RAMB + p] = ((d2<<3) | (d1&7) | ((d1 & 8)<<4)) ^ 192;
		}
	}
	if(0) {
		int i;
		for(i=0;i<16000;++i) img->data[i] = 0xAA;
	}
}

/**
 * decompress a chunk of a map FILE
 */
static char *decomp(FILE *f, IMG *img) {
	char *PEOF = "Premature end of file";
	unsigned char interleaved = img->mode!=0;
	unsigned char y = img->height<<3;
	unsigned char x = img->width;
	unsigned short p = RAMA;
	unsigned short u = 0;
	unsigned short s = 0;
	
	do {
		unsigned char len, val, literal;
		
		if(fread(&len, sizeof(len), 1, f)!=1) return PEOF;
		if(len == 0) {
			literal = TRUE;
			if(fread(&len, sizeof(len), 1, f)!=1) return PEOF;
			if(len==0) return NULL;
		} else {
			literal = FALSE;
			if(fread(&val, sizeof(val), 1, f)!=1) return PEOF;
		}
		
		do {
			if(literal && fread(&val, sizeof(val), 1, f)!=1) return PEOF;
			img->data[p + u] = val; u += 40;
			
			/* last line? */
			if(--y == 0) {
				/* new column */
				y = img->height<<3;
				u = ++s;
				
				if(interleaved) {
					if(p == RAMA) {p = RAMB; u = --s;}
					else          {p = RAMA;}
				}
				
				/* last column ? */
				if(--x == 0) {
					unsigned char buf[2];
					
					/* closing bytes */
					if(fread(buf, 1, 2, f)!=2) return PEOF;
					if(buf[0]!=0 || buf[1]!=0) return "Invalid closing bytes";

					/* if not interleaved and first pass do it once again */
					if(!interleaved && p == RAMA) {
						x = img->width;
						p = RAMB; 
						u = s = 0;
					} else {
						/* otherwise finished */
						return NULL;
					}
				}
			}
		} while(--len);
	} while (TRUE);
}

static IMG *read_map(char *infile) {
	int len;
	unsigned char buf[41];
	
	char *msg = "bad file content";
	IMG *img = alloc(sizeof(IMG));
	FILE *f = fopen(infile, "rb");
	
	if(f==NULL) {msg = "Can't read file"; goto error;}
	
	/*
	 * expected: 0, len>>8, len&255, 0, 0
	 */
	msg = "Can't read start signature";
	if(fread(buf, sizeof(*buf), 5, f)!=5) goto error;
	msg = "Invalid start signature";
	if(buf[0] || buf[3] || buf[4]) goto error;
	len = buf[1]; len = (len<<8) | buf[2];
	
	/* 
	 * get effective length
	 */
	msg = "Can't get file length";
	if(fseek(f, -5L, SEEK_END)) goto error;
	img->length = ftell(f)+5;
	msg = "Invalid file length";
	if(img->length!=len+10) goto error;
	
	/*
         * expected: 255,0,0,0,0
	 */
	msg = "Can't read end signature";
	if(fread(buf, sizeof(*buf), 5, f)!=5) goto error;
	msg = "Invalid end signature";
	if(buf[0]!=0xff || buf[1] || buf[2] ||buf[3] || buf[4]) goto error;
	
	/*
	 * rewind
	 */
	msg = "Can't rewind";
	if(fseek(f, 5L, SEEK_SET)) goto error;
	
	/* expected: <mode>,<width>,<height> */
	msg = "Can't read image dimension";
	if(fread(buf, sizeof(*buf), 3, f)!=3) goto error;
	img->mode   = buf[0];
	img->width  = buf[1] + 1;
	img->height = buf[2] + 1;
	
	/* decompress */
	msg = decomp(f, img);
	if(msg) goto error;
	
	/* tosnap extension */
	if(fread(&buf, 40, 1, f) == 1) {
		int i;
		
		/* misaligned? */
		while(buf[38]!=0xA5 || buf[39]!=0x5A) {
			unsigned char t;
			if(fread(&t, sizeof(t), 1, f) == 1) {
				for(i=0; i<40; ++i) buf[i] = buf[i+1];
				buf[39] = t;
			} else break;
		}
		
		/* found */
		if(buf[38]==0xA5 && buf[39]==0x5A) {
			img->has_extension = 1;
			for(i = 0; i<38; ++i) img->extension[i] = buf[i];
		}
	}
	
	fclose(f);
	return img;
error:
	if(f)	fclose(f);
	if(msg) fprintf(stderr, "Can't load MAP file: %s (%s)\n", infile, msg);
	if(img) free(img);
	return NULL;
	
}

static void membuf_cpy_plane(struct membuf *buf, unsigned char *data, unsigned char width, unsigned char height) {
	short p = 0;
	while(width--) {
		short u = p++;
		short l = height;
		while(l--) {membuf_append_char(buf, data[u]); u += 40;}
	}
}

#if 0
static void save_ppm(char *filename, unsigned char *data) {
	FILE *f = fopen(filename, "wb");
	short i;
	static unsigned char buf[6] = {0,0,0,255,255,255};
	
	fprintf(f, "P6\n320 200 255\n");
	for(i=8000; i--;) {
		unsigned short v = *data++;
		unsigned char j;
		for(j=8; j--; v<<=1) fwrite(&buf[v & 128 ? 3 : 0], 3, 1, f);
	}
	
	fclose(f);
}
#endif