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
 
#include <stdio.h>

#include "defs.h"
#include "error.h"
#include "display.h"
#include "bin.h"
#include "eval.h"
#include "arg.h"
#include "assemble.h"
#include "symbol.h"


int Ass_LongBr (void)
{
    int err = NO_ERROR;

    debug_print ("%s\n", "");

    fetch.size = 3;

    run.ptr = arg_SkipSpaces (run.ptr);

    if (Eval() == NO_ERROR)
    {
        eval.operand -= run.pc + fetch.size +
                        ((fetch.buf[0] != '\x00') ? 1 : 0);
    }
    else
    {
        eval.operand = 0xfffe;
        err = ERR_ERROR;
    }

    if (((signed short)eval.operand >= -128)
     && ((signed short)eval.operand <= 127)
     && (scan.opt [OPT_OP] == TRUE))
    {
        err = error_Printf (ERROR_TYPE_OPTIMIZE,
                           "the long branch could be reduced to a " \
                            "short branch (from -128 to 127)");
    }

    fetch.buf[2] = (char)(eval.operand >> 8);
    fetch.buf[3] = (char)eval.operand;

    display_Set (PRINT_TWO_FOR_THREE);

    return err;
}
