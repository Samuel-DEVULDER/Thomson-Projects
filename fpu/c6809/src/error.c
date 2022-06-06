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
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include "defs.h"
#include "error.h"
#include "display.h"
#include "source.h"
#include "includ.h"

static char error_type[4][12] = {
    "optimize",
    "warning",
    "error",
    "fatal error"
};

static int fatal_error_code = NO_ERROR;


/* ------------------------------------------------------------------------- */


int error_Printf (int type, const char *format, ...)
{
    int err = NO_ERROR;
    va_list args;

    debug_print ("type=%d run.pass=%d ERROR_TYPE_FATAL=%d format=\"%s\"\n",
                 type, run.pass, ERROR_TYPE_FATAL, format);

    switch (type)
    {
        case ERROR_TYPE_FATAL:
            fatal_error_code = ERR_ERROR;
            break;

        case ERROR_TYPE_OPTIMIZE:
            if ((run.opt[OPT_OP] == FALSE)
             || (run.pass < PASS2))
            {
                err = ERR_ERROR;
            }
            break;

        default :
            if (run.pass < PASS2)
            {
                err = ERR_ERROR;
            }
            break;
    }

    if (err == NO_ERROR)
    {
        /* file pathes */
        if ((top_includ != NULL)
         && (top_includ->source != NULL)
         && (top_includ->source->from != NULL))
        {
            /* display FROM file name if exists */
            if (top_includ->source->from->name != NULL)
            {
                display_Error ("%s:", top_includ->source->from->name);
            }

            /* display ASM file name if exists */
            if ((top_includ->source->from != top_includ->source)
             && (top_includ->source->name != NULL))
            {
                display_Error ("'%s':", top_includ->source->name);
            }
        }

        /* line number */
        if (run.line != 0)
        {
            display_Error ("%d:", run.line);
        }

        /* error type */
        display_Error (" %s: ", error_type[type]);

        /* arguments */
        va_start (args, format);
        display_ErrorVAList (format, args);
        va_end (args);

        display_Error ("\n");

        err = ERR_ERROR;
    }

    return err;
}



/*
 * Return last fatal error code
 */
int error_FatalErrorCode (void)
{
    debug_print ("%s\n", "");

    return fatal_error_code;
}



/*
 * Initialize error chain
 */
void error_SourceInit (void)
{
    debug_print ("%s\n", "");

    fatal_error_code = NO_ERROR;
}

