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
#include "eval.h"
#include "arg.h"


int Ass_SETDP (char *label_name)
{
    debug_print ("%s\n", "");

    if (label_name[0] != '\0')
    {
        (void)error_Printf (ERROR_TYPE_ERROR,
                            "the SETDP directive does not support label");
    }

    run.ptr = arg_SkipSpaces (run.ptr);

    Eval();

    if ((eval.operand & 0xff00) != 0x0000)
    {
        (void)error_Printf (ERROR_TYPE_ERROR,
                            "the value for a SETDP must be " \
                            "limited to a range from 0 to 255");
    }

    run.dp = (unsigned short)(eval.operand << 8);

    display_Set (PRINT_LIKE_DP);

    return NO_ERROR;
}





