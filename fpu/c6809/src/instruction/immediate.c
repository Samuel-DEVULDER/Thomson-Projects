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
#include "display.h"
#include "bin.h"
#include "eval.h"
#include "includ.h"
#include "arg.h"
#include "assemble.h"
#include "symbol.h"


int Ass_Immediate (void)
{
    int err = NO_ERROR;

    debug_print ("%s\n\n", "");

    fetch.size = 2;

    run.ptr = arg_SkipSpaces (run.ptr);

    if (arg_Read () == CHAR_SIGN)
    {
        if (*arg_buf == '#')
        {
            Eval ();
            if (((signed short)eval.operand < -256)
             || ((signed short)eval.operand > 255))
            {
                err = error_Printf (ERROR_TYPE_ERROR,
                                    "expect 8 bits value, have "
                                    "%04X",
                                    (int)eval.operand & 0xffff);
            }
        }
        else
        {
            eval.operand = 0x0000;
            err = error_Printf (ERROR_TYPE_ERROR,
                                "expect immediate 8 bits value beginning " \
                                "with '#', have something beginning with %s",
                                arg_FilteredChar (*arg_buf));
        }
    }
    else
    {
        eval.operand = 0x0000;
        err = error_Printf (ERROR_TYPE_ERROR,
                            "expect immediate 8 bits value beginning " \
                            "with '#', have '%s'",
                            arg_buf);
    }

    display_Set (PRINT_TWO_FOR_TWO);

    fetch.buf[2] = (char)eval.operand;

    return err;
}
