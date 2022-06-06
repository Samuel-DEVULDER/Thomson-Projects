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
#include "arg.h"
#include "bin.h"
#include "includ.h"
#include "assemble.h"
#include "symbol.h"

int Ass_Transfer (void)
{
    int err = NO_ERROR;
    char reg1[ARG_MAX_SIZE+1];
    char reg2[ARG_MAX_SIZE+1];
    int rcode;

    debug_print ("%s\n", "");

    reg1[0] = '\0';
    reg2[0] = '\0';

    fetch.size = 2;

    run.ptr = arg_SkipSpaces (run.ptr);

    /* First register */
    rcode = arg_Read ();
    if ((rcode & ISREG) == 0)
    {
        err = error_Printf (ERROR_TYPE_ERROR,
                            "expected a 6809 register, have '%s'",
                            arg_buf);
    }
    strcat (reg1, arg_buf);

    fetch.buf[2] = (char)((unsigned int)(rcode & 0xff) << 4);

    /* Skip coma */
    if (*(run.ptr++) != ',')
    {
        err = error_Printf (ERROR_TYPE_ERROR,
                            "a comma is missing after the 6809 register '%s'",
                            reg1);
    }

    /* Second register */
    rcode = arg_Read ();
    if ((rcode & ISREG) == 0)
    {
        err = error_Printf (ERROR_TYPE_ERROR,
                            "expected a 6809 register, have '%s'",
                            arg_buf);
    }
    strcat (reg2, arg_buf);

    fetch.buf[2] |= (char)rcode;

    /* Check if register error */
    if (((fetch.buf[2] & '\x88') != '\x00')
     && ((fetch.buf[2] & '\x88') != '\x88'))
    {
        err = error_Printf (ERROR_TYPE_ERROR,
                            "size of 6809 register '%s' and '%s' does not" \
                            "match",
                            reg1,
                            reg2);
    }

    display_Set (PRINT_TWO_FOR_TWO);

    return err;
}
