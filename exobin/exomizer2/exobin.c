/**
 * exobin
 *    Compress a binary thomson file. To be compiled & linked along with exomizer2 code.
 *
 * (c) Samuel Devulder 2017.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>

#include <sys/stat.h>
#include <sys/types.h>
#include <dirent.h>

#include "membuf_io.h"
#include "exo_helper.h"


#ifndef TRUE
#define TRUE    1
#define FALSE   0
#endif

static void convert(char *infile, char *outfile);
static void *alloc(int size);
static void process(char *filename);
static int get8(FILE *f);
static int get16(FILE *f);
static int writeChunk(FILE *f, int type, int len, int *addr, char *buf, int buf_len);
static int endsWithIgnoreCase(char *s, char *end);

int main(int ac, char **av) {
    int i;
    
    LOG_INIT_CONSOLE(LOG_WARNING);
        
    for(i=1; i<ac; ++i) {
        struct stat buf;
        
        if(!strcmp(av[i], "-h") || !strcmp(av[i], "--help") || !strcmp(av[i], "?")) {
            fprintf(stderr, "Usage: %s [?|-h|--help]\n", av[0]);
            fprintf(stderr, "       <files.bin or folder>\n");
            fprintf(stderr, "\n\n");
            fprintf(stderr, "Compresse un binaire thomson. Le fichier resultat est place a cote\n");
            fprintf(stderr, "du fichier source, mais avec l'extension B1N au lieu de BIN.\n");
            fprintf(stderr, "\n");
            
            exit(EXIT_SUCCESS);
        } else  if(!stat(av[i], &buf)) {
            if(S_ISDIR(buf.st_mode)) {
                DIR *dir = opendir(av[i]);
                if(dir) {
                    struct dirent *dirent;
                    while((dirent = readdir(dir))!=NULL) if(endsWithIgnoreCase(dirent->d_name, ".BIN")) {
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
    char *out = alloc(3+strlen(filename));
    char *s;
    
    /* change extension */
    strcpy(out, filename);
    for(s=out; *s; ++s) {}
    while(s>out && *s!='.') --s;
    if(*s=='.') strcpy(s, ".B1N");
    else        strcat(s, ".B1N");
    
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

int total = 0, total2 = 0, total3 = 0, num = 0;

/**
 * converts BIN file "infile" to B1N file "outfile"
 */
static void convert(char *infile, char *outfile) {
	FILE *in, *out;
	int c, insize=0,outsize=0;
	
	char *name = infile;
    while(*name) ++name;
    while(name>infile) {
        if(*name=='/' || *name=='\\') {++name; break;}
        --name;
    }
	
	
	if(!(in=fopen(infile,"rb"))) {
		perror(infile);
		return;
	}
	if(!(out=fopen(outfile,"wb"))) {
		perror(outfile);
		if(in) fclose(in);
		return;
	}
	while((c=get8(in))>=0) {
		int typ = c, len = get16(in), i;
		int addr = typ==0x00 || typ==0xff ? get16(in) : 0;
        char *buf;

		if(len<0 || addr<0)  {c=-1; break;}
		buf=alloc(len);
		
		for(i=0;i<len;++i) {
			if((c=get8(in))<0) break;
			buf[i] = c;
		}
		if(c<0) break;

		/* printf("type=$%02x\n",typ); */
				
		if(typ==0xff) {
			insize  += 5;
			outsize += 5;
			if(!writeChunk(out,typ,0,&addr,NULL,0)) {
				perror(outfile);
				break;
			}
		} else if(typ==0x00) {
			struct membuf inbuf[1];
			struct membuf outbuf[1];
			struct crunch_info info[1];
			static struct crunch_options options[1] = { CRUNCH_OPTIONS_DEFAULT };
			char *buf2=buf;
			int len2=len;
			
			insize += 5+len;	

			membuf_init(outbuf);
			membuf_init(inbuf);
			membuf_append(inbuf, buf, len);
			crunch_backwards(inbuf, outbuf, options, info);
			reverse_buffer(membuf_get(outbuf), membuf_memlen(outbuf));
			
			/* printf("%d -> %d\n", membuf_memlen(inbuf), membuf_memlen(outbuf)); */
			
			if(membuf_memlen(outbuf)<len) {
				typ  = 1;
				addr = addr + len;
				buf2 = membuf_get(outbuf);
				len2 = membuf_memlen(outbuf);
				len  = len2+2;
			}
			if(!writeChunk(out,typ,len,&addr,buf2,len2)) {
				perror(outfile);
				break;
			}
			
			membuf_free(outbuf);
			membuf_free(inbuf);
			
			outsize += 5+len;	
		} else {
			insize  += 3+len;	
			outsize += 3+len;	
			if(!writeChunk(out,typ,len,NULL,buf,len)) {
				perror(outfile);
				break;
			}
		}
	
		
		free(buf);
	}
	if(c<0 && !feof(in)) {
		perror(infile);
	}
	fclose(in);
	fclose(out);
	
	++num;
    total += outsize;
    total2 += insize;

    fprintf(stdout, "%-20s : %5d -> %5d (%3d%%) (avg/%d : %d -> %d (%d%%))\n",
        name, 
        insize, outsize, (100*outsize)/(insize?insize:1),
        num,
        total2/num, total/num, (100*total)/(total2?total2:1));
    fflush(stdout);
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

static int writeChunk(FILE *f, int type, int len, int *addr, char *buf, int buf_len) {
	int ok = 1;
	char 
	b=type;    ok = ok && fwrite(&b,1,1,f)==1; 
	b=len>>8;  ok = ok && fwrite(&b,1,1,f)==1; 
	b=len&255; ok = ok && fwrite(&b,1,1,f)==1; 
	if(addr) {
		b=(*addr)>>8;  ok = ok && fwrite(&b,1,1,f)==1; 
		b=(*addr)&255; ok = ok && fwrite(&b,1,1,f)==1; 		
	}
	if(buf_len)  {
		ok = ok && fwrite(buf,1,buf_len,f)==buf_len;
	}
	return ok;
}

static int endsWithIgnoreCase(char *s, char *end) {
    char *t = s, *u=end;
    while(*t) ++t;
    while(*u) ++u;
    while(--u>=end && --t>=s && tolower((int)*u) != tolower((int)*t));
    return u<end;
}
