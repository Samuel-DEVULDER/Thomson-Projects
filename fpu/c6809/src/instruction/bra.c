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
 
#include "defs.h"
#include "error.h"
#include "eval.h"
#include "display.h"
#include "bin.h"
#include "arg.h"
#include "assemble.h"
#include "symbol.h"


int Ass_ShortBr (void)
{
    int err = NO_ERROR;

    fetch.size = 2;
    fetch.buf[2] = '\xfe';

    run.ptr = arg_SkipSpaces (run.ptr);

    err = Eval();
    eval.operand -= run.pc + (signed short)fetch.size;

    if (((signed short)eval.operand < -128)
     || ((signed short)eval.operand > 127))
    {
        if (err == NO_ERROR)
        {
            err = error_Printf (ERROR_TYPE_ERROR, "Branch out of range");
        }
    }
    else
    {
        if (err == NO_ERROR)
        {
            fetch.buf[2] = (char)eval.operand;
        }
    }
    
    if (err != NO_ERROR)
    {
        eval.operand = 0x0000;
    }

    display_Set (PRINT_TWO_FOR_TWO);

    return err;
}

