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

#ifndef INCLUDE_ERROR_H
#define INCLUDE_ERROR_H 1

enum {
    ERROR_TYPE_OPTIMIZE = 0,
    ERROR_TYPE_WARNING,
    ERROR_TYPE_ERROR,
    ERROR_TYPE_FATAL
};

#define ERR_END_OF_FILE  -1000
#define ERR_ERROR        -1
#define NO_ERROR         0

extern int  error_Printf (int type, const char *format, ...);
extern int  error_FatalErrorCode (void);
extern void error_SourceInit (void);

#endif




