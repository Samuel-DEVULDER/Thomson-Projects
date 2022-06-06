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
#include "arg.h"
#include "bin.h"
#include "mark.h"
#include "includ.h"
#include "assemble.h"
#include "symbol.h"

static unsigned char stack_table[12] = {
    '\x06',   /* D  = 0x00 */
    '\x10',   /* X  = 0x01 */
    '\x20',   /* Y  = 0x02 */
    '\x40',   /* U  = 0x03 */
    '\x40',   /* S  = 0x04 */
    '\x80',   /* PC = 0x05 */
    '\xff',   /* ?? = 0x06 */
    '\xff',   /* ?? = 0x07 */
    '\x02',   /* A  = 0x08 */
    '\x04',   /* B  = 0x09 */
    '\x01',   /* CC = 0x0A */
    '\x08'    /* DP = 0x0B */
};



static int pushpull (int exclude)
{
    int err = NO_ERROR;
    int reg = 0;

    debug_print ("%s\n", "");

    info.cycle.plus = 0;
    fetch.buf[2] = '\x00';
    fetch.size = 2;

    run.ptr = arg_SkipSpaces (run.ptr);

    do
    {
        /* Ok if register */
        reg = arg_Read ();
        if ((reg & ISREG) != 0)
        {
            /* Complete operande */
            reg &= 0xff;

            if ((char)(fetch.buf[2] & stack_table[reg]) != '\x00')
            {
                err = error_Printf (ERROR_TYPE_ERROR,
                                    "double definition of '%s' in register " \
                                    "list",
                                    arg_buf);
            }

            info.cycle.plus += (reg > (REG_PC & 0xff)) ? 1 : 2;
            fetch.buf[2] |= stack_table[reg];

            /* Exclude U for PULU/PSHU and S for PULS/PSHS */
            if (reg == exclude)
            {
                err = error_Printf (ERROR_TYPE_ERROR,
                                    "'%s' should be excluded from the list " \
                                    "of registers",
                                    arg_buf);
            }
        }
        else
        {
            err = error_Printf (ERROR_TYPE_ERROR,
                                "expected a 6809 register, have '%s'",
                                arg_buf);
        }
    } while (*(run.ptr++) == ',');

    run.ptr--;

    if (arg_Read () != CHAR_END)
    {
        err = error_Printf (ERROR_TYPE_ERROR,
                            "Unexpected argument in register list (%s)",
                            arg_buf);
    }

    display_Set (PRINT_TWO_FOR_TWO);

    return err;
}


/* ------------------------------------------------------------------------- */


/*
 * PSHS/PULS
 */
int Ass_SStack (void)
{
    debug_print ("%s\n", "");

    return pushpull (REG_S);
}



/*
 * PSHU/PULU
 */
int Ass_UStack (void)
{
    debug_print ("%s\n", "");

    return pushpull (REG_U);
}
