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
#include <string.h>

#include "defs.h"
#include "error.h"
#include "display.h"
#include "eval.h"
#include "includ.h"
#include "source.h"
#include "arg.h"



static void display_binary_number (int number)
{
    unsigned int i;
    int digit;
    int flag = -1;

    (void)display_Error ("%%");

    for (i = 0x8000; i != 0; i >>= 1)
    {
        digit = (((unsigned int)number & i) == 1) ? 1 : 0;
        flag = (digit == 1) ? 1 : flag;
        if (flag >= 0)
        {
            (void)display_Error ("%1d", digit);
        }
    }
}



static int display_print (void)
{
    char c;

    while (*run.ptr != '\0')
    {
        c = *(run.ptr++);
        if (strchr ("%@&$", c) != NULL)
        {
            Eval();

            switch (c)
            {
                case '%':
                    display_binary_number ((int)eval.operand);
                    break;

                case '@':
                    (void)display_Error ("@%o", eval.operand);
                    break;

                case '&':
                    (void)display_Error ("%d", (int)eval.operand);
                    break;

                case '$':
                    (void)display_Error ("$%04X", (unsigned int)eval.operand);
                    break;
            }
        }
        else
        {
            (void)display_Error ("%c", c);
        }
    }
    return NO_ERROR;
}


/* ------------------------------------------------------------------------- */


#define OPERAND_LENGTH   20
int Ass_ECHO (char *label_name)
{
    int err = NO_ERROR;

    debug_print ("%s\n", "");

    if (run.pass == PASS2)
    {
        if (label_name[0] != '\0')
        {
            (void)error_Printf (ERROR_TYPE_ERROR,
                               "the ECHO directive does not support label");
        }

        run.ptr = arg_SkipSpaces (run.ptr);

        display_Code ();
        display_Set (PRINT_NONE);
        err = display_print ();
        (void)display_Error ("\n");
    }

    run.ptr = strchr (run.ptr, '\0');

    return err;
}



int Ass_PRINT (char *label_name)
{
    debug_print ("%s\n", "");

    if (label_name[0] != '\0')
    {
        (void)error_Printf (ERROR_TYPE_ERROR,
                            "the PRINT directive does not support label");
    }

    run.ptr = arg_SkipSpaces (run.ptr);

    if (run.pass == PASS1)
    {    
        (void)fprintf (stderr, "%s\n", run.ptr);
    }

    run.ptr = strchr (run.ptr, '\0');

    return NO_ERROR;
}

