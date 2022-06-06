/*
 *  C6809 - Macro-assembler compiler for Thomson (MacroAssembler-like)
 *
 *  Copyright (C) mars 2017 François Mouret
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */


#ifndef INCLUDE_DEFS_H
#define INCLUDE_DEFS_H 1

#include <stdio.h>

#ifndef TRUE
#   define TRUE 1
#endif

#ifndef FALSE
#   define FALSE 0
#endif

#ifndef NULL
#   define NULL 0
#endif

#ifndef MIN
#   define MIN(a,b)  (((a)<(b))?(a):(b))
#endif

#ifndef MAX
#   define MAX(a,b)  (((a)>(b))?(a):(b))
#endif

#define TEXT_MAX_SIZE   300
#define ARG_MAX_SIZE    40
#define LABEL_MAX_SIZE  6

#ifdef DEBUG
#define DEBUG_TEST 1
#else
#define DEBUG_TEST 0
#endif

#define debug_print(fmt, ...) \
        do { if (DEBUG_TEST) { \
          (void)fprintf (stdout, "%s:%d:%s(): "fmt, \
          __FILE__, __LINE__, __func__, __VA_ARGS__); \
          (void)fflush (stdout); } \
        } while (0)

#define LOCK_IF       (1<<1)
#define LOCK_MACRO    (1<<2)
#define LOCK_COMMENT  (1<<4)

#define SCANPASS  1
#define PASS1     2
#define PASS2     3

enum {
    SOFT_ASSEMBLER_MO = 0,
    SOFT_ASSEMBLER_TO,
    SOFT_MACROASSEMBLER,
    SOFT_UPDATE
};

enum {
    OPT_NO = 0,  /* no object */
    OPT_OP,      /* optimizing request */
    OPT_SS,      /* separated lines (no effect) */
    OPT_WE,      /* wait at each error (no effect) */
    OPT_WL,      /* display lines */
    OPT_WS,      /* display symbol list */
    OPT_SIZEOF
};

struct SCAN {
    int opt[OPT_SIZEOF]; /* user-defined option table */
    int soft;        /* user-defined assembler */
    int display_error;
    int lone_symbols_warning;
};

struct RUN {
    char buf[TEXT_MAX_SIZE+1]; /* buffer of the current line */
    int  pass;     /* pass number */
    int  locked;   /* assembly lock */
    int  exit;     /* assembly stop */
    char *text;    /* text pointer */
    char *ptr;     /* line pointer */
    int  line;     /* line number  */
    int  comment_line; /* comment line number  */
    int  macro_line;   /* macro line number  */
    int  if_line;      /* if line number  */
    unsigned short dp;
    unsigned short pc;
    unsigned short exec;
    int opt[OPT_SIZEOF];  /* current option table */
	int quiet;            /* sam: quiet output */
};

extern struct RUN run;
extern struct SCAN scan;

#endif




