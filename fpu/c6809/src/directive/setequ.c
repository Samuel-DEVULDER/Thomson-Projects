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
#include "symbol.h"
#include "arg.h"



int set_and_equ (int type, char *label_name)
{
    debug_print ("%s\n", "");

    if (label_name[0] == '\0')
    {
        return error_Printf (ERROR_TYPE_ERROR,
                             "the directive SET or EQU needs a label");
    }

    run.ptr = arg_SkipSpaces (run.ptr);

    Eval();

    if ((run.pass == PASS2) || (eval.forward == FALSE))
    {
        if (symbol_Do (label_name, eval.operand, type) != NO_ERROR)
        {
            return ERR_ERROR;
        }
    }

    display_Set (PRINT_LIKE_END);

    return NO_ERROR;
}


/* ------------------------------------------------------------------------- */


int Ass_SET (char *label_name)
{
    debug_print ("%s\n", "");

    return set_and_equ (SYMBOL_TYPE_SET, label_name);
}



int Ass_EQU (char *label_name)
{
    debug_print ("%s\n", "");

    return set_and_equ (SYMBOL_TYPE_EQU, label_name);
}





