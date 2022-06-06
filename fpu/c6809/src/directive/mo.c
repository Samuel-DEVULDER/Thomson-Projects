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
#include "bin.h"
#include "symbol.h"
#include "arg.h"
#include "assemble.h"


#define TYPE_CALL   0x00
#define TYPE_GOTO   0x80



static int special_mo (void)
{
    int err = NO_ERROR;

    debug_print ("%s\n", "");

    if (scan.soft == SOFT_ASSEMBLER_TO)
    {
        err = error_Printf (ERROR_TYPE_ERROR,
                            "ASSEMBLER 1.0 on TO does not support MO " \
                            "directives");
    }

    return err;
}



int call_and_goto (int jump, char *label_name)
{
    int err = NO_ERROR;

    debug_print ("%s\n", "");

    if (special_mo () != NO_ERROR)
    {
        return ERR_ERROR;
    }

    if (assemble_RecordLabel (label_name) != NO_ERROR)
    {
        return ERR_ERROR;
    }

    fetch.size = 2;

    run.ptr = arg_SkipSpaces (run.ptr);

    Eval();
    if ((eval.operand & 0xff00) != 0x0000)
    {
        err = error_Printf (ERROR_TYPE_ERROR,
                            "the code of the MO call must be " \
                            "limited to a range from 0 to 255, have " \
                            "'%04X'",
                            (int)eval.operand & 0xffff);
    }

    fetch.buf[0] = '\x00';
    fetch.buf[1] = '\x3f';
    fetch.buf[2] = (char)(eval.operand | (unsigned short)jump);

    display_Set (PRINT_TWO_FOR_TWO);

    return err;
}


/* ------------------------------------------------------------------------- */


int Ass_CALL(char *label_name)
{
    debug_print ("%s\n", "");

    return call_and_goto (TYPE_CALL, label_name);
}



int Ass_GOTO(char *label_name)
{
    debug_print ("%s\n", "");

    return call_and_goto (TYPE_GOTO, label_name);
}



int Ass_STOP(char *label_name)
{
    int err = ERR_ERROR;

    debug_print ("%s\n", "");

    if (special_mo () == NO_ERROR)
    {
        if (assemble_RecordLabel (label_name) == NO_ERROR)
        {
            fetch.size = 3;
            fetch.buf[0] = '\x00';
            fetch.buf[1] = '\xbd';
            fetch.buf[2] = '\xb0';
            fetch.buf[3] = '\x00';

            display_Set (PRINT_TWO_FOR_THREE);
            err = NO_ERROR;
        }
    }

    return err;
}





