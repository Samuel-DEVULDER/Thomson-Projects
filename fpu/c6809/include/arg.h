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


#ifndef INCLUDE_ARG_H
#define INCLUDE_ARG_H 1

#define REGS_PCR     0x100
#define REGS_CCDPPC  0x200
#define REGS_ABD     0x400
#define REGS_XYUS    0x800
/* ISREG = all registers but PCR */
#define ISREG        ( REGS_CCDPPC | REGS_ABD | REGS_XYUS )

/* Registers base values are put in order for TFR/EXG */
#define REG_D        ( 0x00 + REGS_ABD )
#define REG_X        ( 0x01 + REGS_XYUS )
#define REG_Y        ( 0x02 + REGS_XYUS )
#define REG_U        ( 0x03 + REGS_XYUS )
#define REG_S        ( 0x04 + REGS_XYUS )
#define REG_PC       ( 0x05 + REGS_CCDPPC )
#define REG_A        ( 0x08 + REGS_ABD )
#define REG_B        ( 0x09 + REGS_ABD )
#define REG_CC       ( 0x0a + REGS_CCDPPC )
#define REG_DP       ( 0x0b + REGS_CCDPPC )
#define REG_PCR      ( 0x0f + REGS_PCR )

/* special codes */
#define CHAR_END     0
#define CHAR_NUMERIC 0x10
#define CHAR_ALPHA   0x11
#define CHAR_SIGN    0x12

extern char *arg_SkipSpaces (char *p);
extern char *arg_FilteredChar (char c);
extern int  arg_IsRegister (char *argument);
extern int  arg_IsAlpha (char c);
extern void arg_Upper (char *p);
extern int  arg_Read (void);

extern char arg_buf[];

#endif




