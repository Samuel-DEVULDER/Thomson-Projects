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

#ifndef INCLUDE_MACRO_H
#define INCLUDE_MACRO_H 1

struct MACRO {
    int count;   /* macro id */
    int level;   /* macro level */
};

extern struct MACRO macro;

extern int  macro_Expansion (void);
extern int  macro_Execute (char *label_name, char *command_name);
extern int  macro_Level (void);
extern void macro_SourceInit(void);
extern void macro_SourceFree(void);
extern void macro_FreeAll(void);

#endif




