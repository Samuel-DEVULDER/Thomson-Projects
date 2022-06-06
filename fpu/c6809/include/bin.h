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

#ifndef INCLUDE_BIN_H
#define INCLUDE_BIN_H 1

#define FETCH_MAX_SIZE   16

struct FETCH_PARAMS {
    char buf[1+FETCH_MAX_SIZE];
    unsigned short size;
};

extern struct FETCH_PARAMS fetch;

extern void bin_InitFetch (void);
extern int  bin_ReadChar (void);
extern void bin_ReadClose (void);
extern int  bin_ReadOpen (char *file_name, char *extension);
extern void bin_FlushFetch (void);
extern void bin_WriteChar (char c);
extern void bin_WriteClose (void);
extern void bin_WriteOpen (char *file_name);

/* setters */
extern void bin_SetNonLinearFile (void);
extern void bin_SetLinearFile (void);
extern void bin_SetDataFile (void);
extern void bin_SetHybridFile (void);

#endif




