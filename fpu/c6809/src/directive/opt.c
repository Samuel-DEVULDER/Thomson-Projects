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
#include "opt.h"
#include "error.h"
#include "arg.h"
#include "includ.h"

struct OPTION_TABLE {
    char name[3]; /* Option name */
    int type;     /* Option code */
};

static const struct OPTION_TABLE option_table[6] = {
   { "NO", OPT_NO }, /* No object */
   { "OP", OPT_OP }, /* Optimization */
   { "SS", OPT_SS }, /* Separated lines (off) */
   { "WE", OPT_WE }, /* Wait for error (off) */
   { "WL", OPT_WL }, /* Display lines (off) */
   { "WS", OPT_WS }  /* Display symbols */
};



static int record_option (void)
{
    int i;
    int status;

    do
    {
        status = TRUE;

        if (*run.ptr == '.')
        {
            status = FALSE;
            run.ptr++;
        }

        if (arg_Read () != CHAR_ALPHA)
        {
            arg_Upper (arg_buf);
            return error_Printf (ERROR_TYPE_ERROR,
                                 "the OPT directive does not support " \
                                 "the '%s' option",
                                 arg_buf);
        }

        arg_Upper (arg_buf);
        i = 0;
        while ((i < 6) && (strcmp (arg_buf, option_table[i].name) != 0))
        {
            i++;
        }

        if (i == 6)
        {
            return error_Printf (ERROR_TYPE_ERROR,
                                 "the OPT directive does not support " \
                                 "the '%s' option",
                                 arg_buf);
        }

        run.opt[option_table[i].type] = status;

    } while((arg_Read () != CHAR_END) && (*arg_buf == '/'));

    return NO_ERROR;
}


/* ------------------------------------------------------------------------- */


int Ass_OPT (char *label_name)
{
    if ((*run.ptr == '\0')
     || ((run.pass != SCANPASS) && (run.pass != PASS2)))
    {
        return NO_ERROR;
    }

    if (label_name[0] != '\0')
    {
        (void)error_Printf (ERROR_TYPE_ERROR,
                            "the OPT directive does not support label");
    }

    run.ptr = arg_SkipSpaces (run.ptr);

    return record_option ();
}





