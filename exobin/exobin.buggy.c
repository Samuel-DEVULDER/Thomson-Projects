/**
 * exobin
 *    Compress a binary thomson file
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include <sys/stat.h>
#include <sys/types.h>
#include <dirent.h>

#include "membuf_io.h"
#include "exo_helper.h"


#ifndef TRUE
#define TRUE	1
#define	FALSE	0
#endif

typedef struct {
	char mem[65536];
	int min,max,exe;
} BIN;

#define HEXADDR_NONE -1
#define HEXADDR_AUTO -2

static void convert(char *infile, char *outfile, int hexaddr);
static void *alloc(int size);
static BIN  *read_bin(char *infile);
static void process(char *filename, int hexaddr);
static int get8(FILE *f);
static int get16(FILE *f);
static int endsWithIgnoreCase(char *s, char *end);

int total = 0, total2 = 0, total3 = 0, num = 0;

int main(int ac, char **av) {
	int i;
	int hexaddr = HEXADDR_NONE;
	
	LOG_INIT_CONSOLE(LOG_WARNING);
	    
	for(i=1; i<ac; ++i) {
		struct stat buf;
		
		if(!strcmp(av[i], "-h") || !strcmp(av[i], "--help") || !strcmp(av[i], "?")) {
			fprintf(stderr, "Usage: %s [?|-h|--help] [-x[HEXADDR]] <files.bin or folder>\n",av[0]);
			fprintf(stderr, "\n\n");
			fprintf(stderr, "Compresse un binaire thomson. Le fichier resultat est place a cote\n");
			fprintf(stderr, "du fichier source, mais avec l'extension EXO au lieu de BIN.\n");
			fprintf(stderr, "\n");
			fprintf(stderr, "L'option -x produit une binaire auto-extractible. HEXADDR contient\n");
			fprintf(stderr, "l'addresse hexadecimale du chargement. Si HEXADDR est absent, une\n");
			fprintf(stderr, "une adresse est choisie automatiquement (eventuellement en ram video).\n");
			exit(EXIT_SUCCESS);
		} else if(av[i][0]=='-' && av[i][1]=='x') {
		        if(av[i][2]) {
			       char *s = av[i]+2;
			       int t = 0;
			       while((*s>='0' && *s<='9') || 
				     (*s>='a' && *s<='f') || 
				     (*s>='A' && *s<='F')) {
					t <<= 4;
					if(*s>='0' && *s<='9') t += *s - '0';
					if(*s>='a' && *s<='f') t += *s - 'a' + 10;
					if(*s>='A' && *s<='F') t += *s - 'A' + 10;
					++s;
			       }
			       hexaddr = t & 0xFFFF;
			} else {
			       hexaddr = HEXADDR_AUTO;
			}
		} else 	if(!stat(av[i], &buf)) {
			if(S_ISDIR(buf.st_mode)) {
				DIR *dir = opendir(av[i]);
				if(dir) {
					struct dirent *dirent;
					while((dirent = readdir(dir))!=NULL) if(endsWithIgnoreCase(dirent->d_name, ".BIN")) {
						char *s = alloc(strlen(av[i]) + strlen(dirent->d_name) + 2);
						strcpy(s, av[i]);
						strcat(s, "/");
						strcat(s, dirent->d_name);
						process(s, hexaddr);
						free(s);
					}
					closedir(dir);
				}
			} else if(S_ISREG(buf.st_mode)) {
				process(av[i], hexaddr);
			}
		}
	}
	
	
	LOG_FREE;
	
	return EXIT_SUCCESS;
}

/**
 * compress the given file
 */
static void process(char *filename, int hexaddr) {
	char *out = alloc(3+strlen(filename));
	char *s;
	
	/* change extension */
	strcpy(out, filename);
	for(s=out; *s; ++s) {}
	while(s>out && *s!='.') --s;
	if(*s=='.')	strcpy(s, ".EXO");
	else		strcat(s, ".EXO");
	
	convert(filename, out, hexaddr);
		
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

unsigned char binary[] = {
0x86,0x80,		/* 8000 86   80              lda    #*<-8     */
0x1F,0x8B,		/* 8002 1F   8B              tfr    a,dp      */
0xCE,0x83,0xE7, 	/* 8004 CE   83E7            ldu    #biba     */
0x31,0xC4,		/* 8007 31   C4              leay   ,u        */
0x5F,			/* 8009 5F                   clrb             */
0xD7,0x89,		/* 800A D7   89              stb    <bitbuf+1 */
0x4F,			/* 800C 4F            nxt    clra             */
0x34,0x06,		/* 800D 34   06              pshs   a,b       */
0xC5,0x0F,		/* 800F C5   0F              bitb   #$0f      */
0x26,0x03,		/* 8011 26   03              bne    skp       */
0x8E,0x00,0x01,		/* 8013 8E   0001            ldx    #$0001    */
0xC6,0x04,		/* 8016 C6   04       skp    ldb    #4        */
0x8D,0x6A,		/* 8018 8D   6A              bsr    getbits   */
0xE7,0xC0,		/* 801A E7   C0              stb    ,u+       */
0x53,			/* 801C 53                   comb             */
0x69,0xE4,		/* 801D 69   E4       roll   rol    ,s        */
0x49,			/* 801F 49                   rola             */
0x5C,			/* 8020 5C                   incb             */
0x2B,0xFA,		/* 8021 2B   FA              bmi    roll      */
0xE6,0xE4,		/* 8023 E6   E4              ldb    ,s        */
0xAF,0xC1,		/* 8025 AF   C1              stx    ,u++      */
0x30,0x8B,		/* 8027 30   8B              leax   d,x       */
0x35,0x06,              /* 8029 35   06              puls   a,b       */
0x5C,			/* 802B 5C                   incb             */
0xC1,0x34,		/* 802C C1   34              cmpb   #52       */
0x26,0xDC,		/* 802E 26   DC              bne    nxt       */
0xCE,0xA9,0x02,		/* 8030 CE   A902     go     ldu    #DEB+LEN  */
0xC6,0x01,		/* 8033 C6   01       mloop  ldb    #1        */
0x8D,0x4D,		/* 8035 8D   4D              bsr    getbits   */
0x26,0x17,		/* 8037 26   17              bne    cpy       */
0xD7,0x44,		/* 8039 D7   44              stb    <idx+1    */
0x8C,			/* 803B 8C                   fcb    $8c       */
0x0C,0x44,		/* 803C 0C   44       rbl    inc    <idx+1    */
0x5C,			/* 803E 5C                   incb             */
0x8D,0x43,		/* 803F 8D   43              bsr    getbits   */
0x27,0xF9,		/* 8041 27   F9              beq    rbl       */
0xC6,0x00,		/* 8043 C6   00       idx    ldb    #$00      */
0xC1,0x10,		/* 8045 C1   10              cmpb   #$10      */
0x10,0x27,0x1F,0xB5,	/* 8047 1027 1FB5            lbeq   EXE       */
0x25,0x0F,		/* 804B 25   0F              blo    coffs     */
0x5A,			/* 804D 5A                   decb             */
0x8D,0x34,		/* 804E 8D   34              bsr    getbits   */
0x1F,0x01,		/* 8050 1F   01       cpy    tfr    d,x       */
0xA6,0xA2,		/* 8052 A6   A2       cpyl   lda    ,-y       */
0xA7,0xC2,		/* 8054 A7   C2              sta    ,-u       */
0x30,0x1F,		/* 8056 30   1F              leax   -1,x      */
0x26,0xF8,		/* 8058 26   F8              bne    cpyl      */
0x20,0xD7,		/* 805A 20   D7              bra    mloop     */
0x8D,0x3F,		/* 805C 8D   3F       coffs  bsr    cook      */
0x34,0x06,		/* 805E 34   06              pshs   d         */
0x8E,0x80,0xA8,         /* 8060 8E   80A8            ldx    #tab1     */
0x10,0x83,0x00,0x03,	/* 8063 1083 0003            cmpd   #$03      */
0x24,0x01,		/* 8067 24   01              bhs    scof      */
0x3A,			/* 8069 3A                   abx              */
0x8D,0x16,		/* 806A 8D   16       scof   bsr    getbix    */
0xEB,0x03,		/* 806C EB   03              addb   3,x       */
0x8D,0x2D,		/* 806E 8D   2D              bsr    cook      */
0xDD,0x78,		/* 8070 DD   78              std    <offs+2   */
0x35,0x10,		/* 8072 35   10              puls   x         */
0x33,0x5F,		/* 8074 33   5F       cpy2   leau   -1,u      */
0xA6,0xC9,0x55,0X55,	/* 8076 A6   C9 5555  offs   lda    $5555,u   */
0xA7,0xC4,		/* 807A A7   C4              sta    ,u        */
0x30,0x1F,		/* 807C 30   1F              leax   -1,x      */
0x26,0xF4,		/* 807E 26   F4              bne    cpy2      */
0x20,0xB1,		/* 8080 20   B1              bra    mloop     */
0xE6,0x84,		/* 8082 E6   84       getbix ldb    ,x        */
0x6F,0xE2,		/* 8084 6F   E2       getbits clr   ,-s       */
0x6F,0xE2,		/* 8086 6F   E2              clr    ,-s       */
0x86,0x55,		/* 8088 86   55       bitbuf lda    #$55      */
0x20,0x09,		/* 808A 20   09              bra    get3      */
0xA6,0xA2,		/* 808C A6   A2       get1   lda    ,-y       */
0x46,			/* 808E 46            get2   rora             */
0x27,0xFB,		/* 808F 27   FB              beq    get1      */
0x69,0x61,		/* 8091 69   61              rol    1,s       */
0x69,0xE4,		/* 8093 69   E4              rol    ,s        */
0x5A,			/* 8095 5A            get3   decb             */
0x2A,0xF6,		/* 8096 2A   F6              bpl    get2      */
0x97,0x89,		/* 8098 97   89              sta    <bitbuf+1 */
0xEC,0xE1,		/* 809A EC   E1              ldd    ,s++      */
0x39,			/* 809C 39                   rts              */
0x8E,0x83,0xE7,		/* 809D 8E   83E7     cook   ldx    #biba     */
0x3A,			/* 80A0 3A                   abx              */
0x58,			/* 80A1 58                   aslb             */
0x3A,			/* 80A2 3A                   abx              */
0x8D,0xDD,		/* 80A3 8D   DD              bsr    getbix    */
0xE3,0x01,		/* 80A5 E3   01              addd   1,x       */
0x39,			/* 80A7 39                   rts              */
0x04,0x02,0x04,		/* 80A8 04 02 04      tab1   fcb    4,2,4     */
0x10,0x30,0x20		/* 80AB 10 30 20             fcb    16,48,32  */
			/* 80AE                      incdat FILE.exo  */
			/* 83E7               biba   rmb    156       */
};

/**
 * converts BIN file "infile" to EXO file "outfile"
 */
static void convert(char *infile, char *outfile, int hexaddr) {
	BIN *bin = read_bin(infile);
	struct membuf inbuf[1];
	struct membuf outbuf[1];
	struct crunch_info info[1];
	static struct crunch_options options[1] = { CRUNCH_OPTIONS_DEFAULT };
	char *name = infile;
	int len;
	int decomp_size;
	
	if(!bin) return;
	
	while(*name) ++name;
        while(name>infile) {
		if(*name=='/' || *name=='\\') {++name; break;}
		--name;
        }
	
	/*data_start = membuf_memlen(inbuf);*/
	
	membuf_init(outbuf);
	membuf_init(inbuf);
	len = bin->max - bin->min;
	membuf_append(inbuf, bin->mem + bin->min, len);
	
	crunch_backwards(inbuf, outbuf, options, info);
	/*reverse_buffer(membuf_get(outbuf), membuf_memlen(outbuf));*/
	
	decomp_size = 156 + sizeof(binary) + membuf_memlen(outbuf);
	if(hexaddr == HEXADDR_AUTO) {
		hexaddr = bin->min - decomp_size;
		if(!((0x4000<=hexaddr && hexaddr+decomp_size<=0x5F40) ||
	             (0x6100<=hexaddr && hexaddr+decomp_size<=0xE000))) 
		hexaddr = 0x5f40 - decomp_size;
		while(hexaddr>=0x4000 &&
		     ((hexaddr+0x44)>>8) != ((hexaddr + 0x89)>>8)) --hexaddr;
	}
	
	/* validation */
	if(hexaddr != HEXADDR_NONE) {
		fprintf(stderr, "%s: debut decomp: $%04x ", name, hexaddr);
		if(((hexaddr+0x44)>>8) != ((hexaddr + 0x89)>>8)) {
			fprintf(stderr, "KO (PAGE-BOUNDARY CROSSING)\n");
			hexaddr = HEXADDR_NONE;
		} else if((bin->min<=hexaddr && hexaddr<bin->max) || 
		   (bin->min<=hexaddr+decomp_size-1 && hexaddr+decomp_size-1<bin->max)) {
			fprintf(stderr, "KO (COLLISION)\n");
			hexaddr = HEXADDR_NONE;
		} else if(hexaddr<0x4000 || hexaddr+decomp_size>0xE000) {
			fprintf(stderr, "KO (ROM)\n");
			hexaddr = HEXADDR_NONE;
		} else if((0x4000<=hexaddr && hexaddr+decomp_size<=0x5F40) ||
			  (0x6100<=hexaddr && hexaddr+decomp_size<=0xE000)) {
			fprintf(stderr, "OK\n");
		} else {
		        fprintf(stderr, "KO (PAGE0 CROSSING)\n");
			hexaddr = HEXADDR_NONE;
		}
	}

	if(hexaddr != HEXADDR_NONE) {
		int len    = sizeof(binary) + membuf_memlen(outbuf);
		int biba   = hexaddr + len;
		int idx    = hexaddr+0x43;
		int offs   = hexaddr+0x76;
		int bitbuf = hexaddr+0x88;
		int tab1   = hexaddr+0xA8;
		char *buf  = membuf_get(outbuf);
		
		int i;
		for(i=0; i<sizeof(binary); ++i) bin->mem[hexaddr + i] = binary[i];
		for(i=membuf_memlen(outbuf); --i>=0;)
			bin->mem[hexaddr + sizeof(binary)+i] = buf[i];
		
		bin->mem[hexaddr + 0x01] = (idx+1)>>8;
		bin->mem[hexaddr + 0x05] = (biba)>>8;
		bin->mem[hexaddr + 0x06] = (biba)&255;
		bin->mem[hexaddr + 0x0B] = (bitbuf+1)&255;
		bin->mem[hexaddr + 0x31] = bin->max>>8;
		bin->mem[hexaddr + 0x32] = bin->max&255;
		bin->mem[hexaddr + 0x3A] = (idx+1)&255;
		bin->mem[hexaddr + 0x3D] = (idx+1)&255;
		bin->mem[hexaddr + 0x49] = (bin->exe - (hexaddr+0x47+4))>>8;
		bin->mem[hexaddr + 0x4A] = (bin->exe - (hexaddr+0x47+4))&255;
		bin->mem[hexaddr + 0x61] = (tab1)>>8;
		bin->mem[hexaddr + 0x62] = (tab1)&255;
		bin->mem[hexaddr + 0x71] = (offs+2)&255;
		bin->mem[hexaddr + 0x99] = (bitbuf+1)&255;
		bin->mem[hexaddr + 0x9E] = (biba)>>8;
		bin->mem[hexaddr + 0x9F] = (biba)&255;
		
		membuf_truncate(outbuf, 0);
		
		membuf_append_char(outbuf, 0x00);
		membuf_append_char(outbuf, len>>8);
		membuf_append_char(outbuf, len&255);
		membuf_append_char(outbuf, hexaddr>>8);
		membuf_append_char(outbuf, hexaddr&255);
		for(i=0; i<len; ++i)
			membuf_append_char(outbuf, bin->mem[hexaddr + i]);
		
		membuf_append_char(outbuf, (char)0xFF);
		membuf_append_char(outbuf, 0x00);
		membuf_append_char(outbuf, 0x00);
		membuf_append_char(outbuf, hexaddr>>8);
		membuf_append_char(outbuf, hexaddr&255);
	}
	
	++num;
	total += membuf_memlen(outbuf);
	total2 += len;
	
	fprintf(stdout, "%s ($%04x): %d -> %d (%d%%) (avg #%d : %d -> %d (%d%%))\n", 
		name, bin->exe,
		len, membuf_memlen(outbuf), (100*membuf_memlen(outbuf))/len,
		num, 
		total2/num, total/num, (100*total)/total2);
	
	
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
	write_file(outfile, outbuf);
	
	membuf_free(outbuf);
	membuf_free(inbuf);
	free(bin);
}

static BIN *read_bin(char *infile) {
	FILE *f = fopen(infile, "rb");
	BIN *bin = NULL;
	if(f!=NULL) {
		int c;
		bin = alloc(sizeof(BIN));
		bin->min = sizeof(bin->mem);
		bin->max = 0;
		while((c=get8(f))>=0) {
			int len = get16(f), adr;
			if(len<0) {c=len; break;}
			if(c==0xFF) {
				if((c = get16(f))<0) break;
				bin->exe = c;
				break;
			} else if(c==0x00) {
				if((c = get16(f))<0) break;
				adr = c;
				if(adr<0x6100) {
					fprintf(stderr, "Can't write below page 0 ($%04X)\n", adr); 
					break;
				}
				if(adr<bin->min) bin->min = adr;
				while(len--) {
					if((c=get8(f))<0) break;
					if(adr>=0xE000) {
						fprintf(stderr, "Can't write in ROM space ($%04X)\n", adr); 
						break;
					}
					bin->mem[adr++] = c;
				}
				if(adr>bin->max) bin->max = adr;
			} else {
				fprintf(stderr, "Skipping unknown chunk (len=%d)\n", len);
				while(len--) if((c=get8(f))<0) break;
			}
		}
		if(c<0) {perror(infile); free(bin); bin = NULL;}
		fclose(f);
	} else perror(infile);
	return bin;
}

static int get8(FILE *f) {
	int c = fgetc(f);
	if(c==EOF) return -1;
	return c;
}

static int get16(FILE *f) {
	int t = get8(f), r;
	if(t<0) return t;
	r = get8(f);
	if(r<0) return r;
	return (t<<8) | r;
}

static int endsWithIgnoreCase(char *s, char *end) {
	char *t = s, *u=end;
	while(*t) ++t;
	while(*u) ++u;
	while(--u>=end && --t>=s && tolower((int)*u) != tolower((int)*t));
	return u<end;
}