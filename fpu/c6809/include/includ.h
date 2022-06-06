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

#ifndef INCLUDE_INCLUD_H
#define INCLUDE_INCLUD_H 1

struct INCLUD_LIST {
     struct SOURCE_LIST *source;
     char *text;
     char *end;
     char *ptr;
     int  line;
     struct INCLUD_LIST *next;
};

extern struct INCLUD_LIST *top_includ;

extern struct SOURCE_LIST *includ_GetFromSource (void);
extern void includ_CheckIfEnd (void);
extern void includ_GetLine (void);
extern void includ_ManageLevel (void);
extern int  includ_FirstLoad (char *file_name);
extern int  includ_SourceInit (char *file_name);
extern void includ_SourceFree (void);

#endif




