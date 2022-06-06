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
#include "includ.h"
#include "symbol.h"
#include "arg.h"
#include "assemble.h"

static int rmx_flag = PRINT_BYTES;



/*
 * Record rmx data
 */
static void record_rmx (char c)
{
    if (fetch.size == 4)
    {
        display_Set (rmx_flag);
        display_Code ();

        if (rmx_flag == PRINT_BYTES)
        {
            rmx_flag = PRINT_BYTES_ONLY;
        }
        else
        if (rmx_flag == PRINT_WORDS)
        {
            rmx_flag = PRINT_WORDS_ONLY;
        }
    }
    bin_WriteChar (c);
}



static int assemble_rmx (int flag, char *label_name)
{
    int i;
    unsigned short count;

    debug_print ("%s\n", "");

    fetch.size = 0;
    rmx_flag = flag;

    if (assemble_RecordLabel (label_name) != NO_ERROR)
    {
        return ERR_ERROR;
    }

    run.ptr = arg_SkipSpaces (run.ptr);

    if (Eval() != NO_ERROR)
    {
        return ERR_ERROR;
    }

    if ((signed short)(count = eval.operand) < 0)
    {
        return error_Printf (ERROR_TYPE_ERROR,
                             "negative size is not allowed");
    }

    if (*run.ptr != ',')
    {
        display_Set (PRINT_PC);
        display_Code ();
        display_Set (PRINT_NONE);
        run.pc += count*((rmx_flag == PRINT_BYTES) ? 1 : 2);
    }
    else
    {
        if (scan.soft < SOFT_MACROASSEMBLER)
        {
            return error_Printf (ERROR_TYPE_ERROR,
                                 "ASSEMBLER 1.0 does not support a " \
                                 "filling value for RMB directive");
        }

        run.ptr++;

        if (Eval() != NO_ERROR)
        {
            return ERR_ERROR;
        }

        if (rmx_flag == PRINT_BYTES)
        {
            if (((eval.operand&0xff00) != 0x0000)
             && ((eval.operand&0xff00) != 0xff00))
            {
                return error_Printf (ERROR_TYPE_ERROR,
                                     "the value for the filling " \
                                     "must be limited to 8 bits (from " \
                                     "-256 to 255)");
            }
        }

        for (i=0; i<(int)count; i++)
        {
            switch (rmx_flag)
            {
                case PRINT_BYTES:
                case PRINT_BYTES_ONLY:
                    record_rmx ((char)eval.operand);
                    break;
                
                case PRINT_WORDS:
                case PRINT_WORDS_ONLY:
                    record_rmx ((char)(eval.operand >> 8));
                    record_rmx ((char)eval.operand);
                    break;
            }
        }

        if (fetch.size > 0)
        {
            display_Set (rmx_flag);
            display_Code ();
        }
        bin_FlushFetch ();

        display_Set (PRINT_NONE);
    }
    return NO_ERROR;
}


/* ------------------------------------------------------------------------- */


int Ass_RMB (char *label_name)
{
    debug_print ("%s\n", "");

    return assemble_rmx (PRINT_BYTES, label_name);
}



int Ass_RMD (char *label_name)
{
    debug_print ("%s\n", "");

    return assemble_rmx (PRINT_WORDS, label_name);
}





