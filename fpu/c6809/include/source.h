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
 
#ifndef INCLUDE_SOURCE_H
#define INCLUDE_SOURCE_H 1

enum {
    SOURCE_TYPE_FROM = 0,
    SOURCE_TYPE_ASM,
    SOURCE_TYPE_MAIN
};

struct SOURCE_LIST {
     char *name;       /* File name */
     char *buf;        /* Buffer pointer */
     char *end;        /* End pointer */
     int  line;        /* Line number */
     int  encoding;    /* Text encoding */
     struct SOURCE_LIST *from;  /* Link to from source */
     struct SOURCE_LIST *asm_next;  /* Next asm source */
     struct SOURCE_LIST *from_next; /* Next from source */
};

extern char *source_GetLine (char *buf, char *end);
extern int  source_GetDescriptor (char *ptr, char *extension);
extern char *source_LinePointer (void);
extern int  source_Encoding (void);
extern void source_FreeAll (void);

extern struct SOURCE_LIST *source_IncludLoad (void);
extern struct SOURCE_LIST *source_FirstLoad (char *file_name);
extern int source_OpenBin (char *extension);

extern struct SOURCE_LIST *first_from_source;

#endif

