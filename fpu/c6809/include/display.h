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

#ifndef INCLUDE_DISPLAY_H
#define INCLUDE_DISPLAY_H 1

enum {
    PRINT_NONE = 0,
    PRINT_COMMENT,
    PRINT_BYTES,
    PRINT_BYTES_ONLY,
    PRINT_WORDS,
    PRINT_WORDS_ONLY,
    PRINT_PC,
    PRINT_LIKE_END,
    PRINT_LIKE_DP,
    PRINT_ONE_FOR_ONE,
    PRINT_TWO_FOR_TWO,
    PRINT_TWO_FOR_THREE,
    PRINT_THREE_FOR_THREE,
    PRINT_THREE_FOR_FOUR
};

extern void display_Open (char *file_name);
extern void display_Close (void);

extern void display_Set (int style);
extern void display_Code (void);
extern int  display_Line (const char *format, ... );
extern void display_ErrorVAList (const char *format, va_list args);
extern void display_Error (const char *format, ... );
extern void display_CR (void);

#endif




