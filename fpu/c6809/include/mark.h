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


#ifndef INCLUDE_MARK_H
#define INCLUDE_MARK_H 1

struct CYCLE {
    int count; /* Nombre de cycles de base (-1 si pas) */
    int plus;  /* Nombre de cycles ajoutés (-1 si pas) */
    int total; /* Total du nombre de cycles */
};

struct INFO {
    struct CYCLE cycle;
    int size;
};

extern int check[4][2];
extern struct INFO info;

extern void mark_SourceInit (void);
extern void mark_LineInit (void);
extern void mark_Read (void);

#endif




