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

#ifndef INCLUDE_SYMBOL_H
#define INCLUDE_SYMBOL_H 1

enum {
    SYMBOL_READ = 0,
    SYMBOL_TYPE_ARG,
    SYMBOL_TYPE_SET,
    SYMBOL_TYPE_EQU,
    SYMBOL_TYPE_LABEL,
    SYMBOL_TYPE_MACRO
};

enum {
    SYMBOL_ERROR_NONE = 0,
    SYMBOL_ERROR_NOT_DEFINED,
    SYMBOL_ERROR_MULTIPLY_DEFINED,
    SYMBOL_ERROR_LONE
};

extern int  symbol_Do (char *name, unsigned short value, int type);
extern int  symbol_DisplayError (char *name, int err);
extern void symbol_DisplayList (void);
extern void symbol_SetErrorOrder (void);
extern void symbol_SetTypeOrder (void);
extern void symbol_SetTimeOrder (void);
extern void symbol_FreeAll (void);

#endif




