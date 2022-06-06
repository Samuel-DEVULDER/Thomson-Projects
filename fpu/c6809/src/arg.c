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
#ifndef S_SPLINT_S
#   include <ctype.h>
#endif

#include "defs.h"
#include "arg.h"
#include "includ.h"

struct REGISTER_TABLE {
    char name[4]; /* Register name */
    int code;     /* Register unique/group code */
};

static const struct REGISTER_TABLE register_table[12] = {
    {   "A", REG_A   },
    {   "B", REG_B   },
    {   "D", REG_D   },
    {   "X", REG_X   },
    {   "Y", REG_Y   },
    {   "U", REG_U   },
    {   "S", REG_S   },
    {  "CC", REG_CC  },
    {  "DP", REG_DP  },
    {  "PC", REG_PC  },
    { "PCR", REG_PCR },
    {    "", 0       }
};

char arg_buf[TEXT_MAX_SIZE+1];


static int get_argument (void)
{
    int i = 0;

    /* get argument (alphabetical+numerical character) */
    while ((i < TEXT_MAX_SIZE)
     && ((arg_IsAlpha(run.ptr[i]) == TRUE)
      || (isdigit ((int)run.ptr[i]) != 0)))
    {
        i++;
    }

    /* always 1 character at least */
    if (i == 0)
    {
        i = 1;
    }

    strncat (arg_buf, run.ptr, (size_t)MIN (i, TEXT_MAX_SIZE));

    debug_print ("run.ptr='%s' arg_buf='%s' i=%d\n", run.ptr, arg_buf, i);

    run.ptr += i;

    return arg_IsAlpha (*arg_buf);
}



/* ------------------------------------------------------------------------- */


/*
 * Skip the spaces
 */
char *arg_SkipSpaces (char *p)
{
    debug_print ("%s\n", "");

    while (*p == ' ')
    {
        p++;
    }

    return p;
}


/*
 * Prevent from displaying strange characters
 */
#define FILTERED_CHAR_LENGTH   5
char *arg_FilteredChar (char c)
{
    static char filtered[FILTERED_CHAR_LENGTH+1];

    filtered[0] = '\0';

    if ((((int)c & 0xff) > 0x20) && (((int)c & 0xff) < 0x7f))
    {
        (void)sprintf (filtered, "'%c'", c);
    }
    else
    {
        (void)sprintf (filtered, "'$%02x'", (unsigned int)c & 0xff);
    }
    return filtered;
}



/*
 * Check if argument is a 6809 register
 */
int arg_IsRegister (char *argument)
{
    int i;
    int code = -1;
    char upper_name[ARG_MAX_SIZE+2];

    debug_print ("argument='%s'\n", argument);

    if ((int)strlen (argument) < 4)
    {
        upper_name[0] = '\0';
        strcat (upper_name, argument);
        arg_Upper (upper_name);

        for (i=0; (register_table[i].name[0] != '\0') && (code == -1); i++)
        {
            if (strcmp (upper_name, register_table[i].name) == 0)
            {
                code = i;
            }
        }
    }
    return code;
}



/*
 * Check if character is alphabetical
 */
int arg_IsAlpha (char c)
{
    int flag = FALSE;

    debug_print ("char='%x'\n", (unsigned int)c & 0xff);

    switch (scan.soft)
    {
        case SOFT_ASSEMBLER_TO :
        case SOFT_ASSEMBLER_MO :
            if (isalpha((int)c) != 0)
            {
                flag = TRUE;
            }
            break;

        default :
            if ((isalpha((int)c) != 0) || ((char)c == '_'))
            {
                flag = TRUE;
            }
            break;
    }
    return flag;
}



/*
 * Upper-case a string
 */
void arg_Upper (char *p)
{
    debug_print ("p='%s'\n", p);

    while (*p != '\0')
    {
        *p = (char)toupper ((int)*p);
        p++;
    }
}



/*
 * Read an argument
 */
int arg_Read (void)
{
    int i;
    int code;

    arg_buf[0] = '\0';

    if (((int)*run.ptr & 0xff) <= 0x20)  /* end of argument */
    {
        code = CHAR_END;
    }
    else
    if (get_argument () == TRUE)         /* if alphabetical */
    {
        i = arg_IsRegister (arg_buf);
        if (i >= 0)
        {
            code = register_table[i].code;
        }
        else
        {
            code = CHAR_ALPHA;
        }
    }
    else
    if (isdigit((int)*arg_buf) != 0)     /* if numerical */
    {
        code = CHAR_NUMERIC;
    }
    else
    {
        code = CHAR_SIGN;                /* otherwise, sign */
    }

    return code;
}




