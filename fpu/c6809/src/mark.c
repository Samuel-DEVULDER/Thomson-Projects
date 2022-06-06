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
#include "mark.h"
#include "asm.h"
#include "error.h"
#include "arg.h"
#include "display.h"
#include "eval.h"
#include "includ.h"

enum {
    NO_MARK = 0,
    MAIN_MARK,
    INFO_MARK,
    CHECK_MARK,
    INCLUDE_MARK
};

struct MARK_TABLE {
    char name[8];  /* mark name */
    int type;      /* mark type */
};

const struct MARK_TABLE mark_table[] = {
    { "main"   , MAIN_MARK    },
    { "info"   , INFO_MARK    },
    { "check"  , CHECK_MARK   },
    { "include", INCLUDE_MARK },
    { ""       , NO_MARK      }
};

int check[4][2];
struct INFO info;



static char *skip_space (char *p)
{
    while (*p == ' ')
    {
        p++;
    }

    return p;
}



/*
 * Manage INFO mark
 */
#define INFO_MARK_LENGTH   40
static void info_mark (void)
{
    (void)display_Line (
        ">%d cycles/%d bytes\n",
        info.cycle.total,
        info.size);
    
    info.cycle.total = 0;
    info.size = 0;

    display_Set (PRINT_NONE);
}



/*
 * Manage CHECK mark
 */
#define CHECK_MARK_LENGTH   40
static void check_mark (void)
{
    int i;

    run.ptr++;
    run.ptr = skip_space (run.ptr);
    if(*run.ptr == '\0')
    {
        check[0][0] = 0;
        check[0][1] = 0;
        check[1][0] = 0;
        check[1][1] = 0;
    }
    else
    {
        i = 0;
        while ((((int)*run.ptr &0xff) > 0x20) && (i < 2))
        {
            if ((*run.ptr != ',') && (*run.ptr > ' '))
            {
                if (Eval() != NO_ERROR)
                {
                    return;
                }

                check[i][0] = (int)eval.operand;

                if ((check[i][0] != 0) && (check[i][0] != check[i][1]))
                {
//                    error_Print (ERR_CHECK_ERROR);
                    (void)display_Line (
                        "Check [%d,%d]\n",
                        check[i][0],
                        check[i][1]);
                }
            }

            if (*run.ptr == ',')
            {
                run.ptr++;
            }
        }
        check[0][1] = 0;
        check[1][1] = 0;
    }
    display_Set (PRINT_NONE);
}



/*
 * Return the mark code or an error
 */
static int get_mark_code (void)
{
    int i;
    int mark_code = 0;

    /* skip bracket */
    run.ptr++;

    /* read argument */
    if (arg_Read () != CHAR_ALPHA)
    {
        return error_Printf (ERROR_TYPE_ERROR,
                             "'%s' is not a valid mark",
                             arg_buf);
    }

    /* search argument */
    for (i=0; mark_table[i].type != NO_MARK; i++)
    {
        if (strcmp (arg_buf, mark_table[i].name) == 0)
        {
            mark_code = mark_table[i].type;
        }
    }

    if(*run.ptr != ')')
    {
        return error_Printf (ERROR_TYPE_ERROR,
                             "missing closing parenthese for mark '%s'",
                             arg_buf);
    }
    run.ptr++;

    run.ptr = skip_space (run.ptr);

    return mark_code;
}


/* ------------------------------------------------------------------------- */


void mark_SourceInit (void)
{
    info.cycle.total = 0;
    info.size = 0;

    check[0][0] = 0;
    check[0][1] = 0;
    check[1][0] = 0;
    check[1][1] = 0;
}



void mark_LineInit (void)
{
    info.cycle.count = -1;
    info.cycle.plus  = -1;
}



/*
 * Read a mark
 */
void mark_Read (void)
{
    switch (get_mark_code ())
    {
        case INFO_MARK:
            if ((run.pass == PASS2)
             && (run.locked == 0))
            {
                info_mark ();
            }
            break;

        case CHECK_MARK:
            if ((run.pass == PASS2)
             && (run.locked == 0))
            {
                check_mark ();
            }
            break;

        case MAIN_MARK:
        case INCLUDE_MARK:
            includ_CheckIfEnd ();
            display_Set (PRINT_NONE);
            break;
    }
}





