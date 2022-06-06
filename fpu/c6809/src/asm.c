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
#include "asm.h"
#include "arg.h"
#include "source.h"
#include "assemble.h"
#include "encode.h"

static FILE *asm_file;
static int asm_cr_count = 0;
static int asm_total_size = 0;
static int asm_comment = FALSE;



/*
 * Get the next expression in an ASM line and make it upper case
 */
static char *get_expression (char *text)
{
    char *p;
    static char expression[TEXT_MAX_SIZE+1];

    debug_print ("%s\n", "");

    expression[0] = '\0';

    p = strchr (text, (int)' ');

    if (p == NULL)
    {
        strcat (expression, text);
    }
    else
    if ((p-text) != 0)
    {
        strncat (expression, text, (size_t)(p-text));
    }

    return expression;
}



/*
 * Write a CR in a ASM file
 */
static void write_asm_cr (void)
{
    char cr[] = "\xd";

    debug_print ("%s\n", "");

    if (asm_file != NULL)
    {
        (void)fwrite (cr, 1, 1, asm_file);
    }

    asm_total_size += 3; /* line number (16bits) / size (8bits) */
}



/*
 * Create the ASM line
 */
static void crunch_line (char *text, char *asm_text)
{
    int i = 0;
    char c;
    int asm_space_count = 0;

    debug_print ("%s\n", "");

    while ((*text != '\0') && (i < ARG_MAX_SIZE))
    {
        c = encode_AsmChar (&text);
        if (c == ' ')
        {
            asm_space_count++;
        }
        else
        {
            while (asm_cr_count > 0)
            {
                write_asm_cr ();
                asm_cr_count--;
            }

            while (asm_space_count > 0)
            {
                *(asm_text++) = (char)(0xf0 | MIN (asm_space_count, 15));
                asm_space_count -= MIN (asm_space_count, 15);
                asm_total_size++;
            }

            *(asm_text++) = c;
            asm_total_size++;
        }
        i++;
    }
    *(asm_text++) = '\0';
    asm_cr_count++;
}



/*
 * Adjust case for ASSEMBLER
 */
static void adjust_case (char *asm_text)
{
    char *asm_arg = NULL;

    debug_print ("%s\n", "");

    if ((asm_comment == FALSE)
     && (*asm_text != '\0')
     && (*asm_text != '*'))
    {
        /* label to upper case */
        asm_arg = get_expression (asm_text);
        arg_Upper (asm_arg);
        if (asm_arg[0] != '\0')
        {
            memmove (asm_text, asm_arg, strlen (asm_arg));
        }

        /* instruction/directive to upper case */
        asm_text = arg_SkipSpaces (asm_text + strlen (asm_arg));
        asm_arg = get_expression (asm_text);
        arg_Upper (asm_arg);
        if (assemble_NameIsReserved (asm_arg) == TRUE)
        {
            /* operand to upper case */
            memmove (asm_text, asm_arg, strlen (asm_arg));
            if (assemble_HasOperand (asm_arg) == TRUE)
            {
                asm_text = arg_SkipSpaces (asm_text + strlen (asm_arg));
                asm_arg = get_expression (asm_text);
                arg_Upper (asm_arg);
                memmove (asm_text, asm_arg, strlen (asm_arg));
            }
        }
    }
}



/*
 * Compare two strings (case insensitive)
 */
static int str_i_cmp (char *text, const char *string)
{
    int i = 0;

    while ((string[i] != '\0')
        && (text[i] != '\0')
        && ((char)toupper ((int)text[i]) == string[i]))
    {
        i++;
    }
    return ((((int)text[i] & 0xff) <= 0x20) && (string[i] == '\0'))
             ? TRUE : FALSE;
}



/*
 * Correct line
 */
static void correct_line (char *asm_text)
{
    char *asm_arg = NULL;

    debug_print ("%s\n", "");

    if ((asm_comment == FALSE)
     && (*asm_text != '\0')
     && (*asm_text != '*'))
    {
        asm_arg = get_expression (asm_text);
        asm_text = arg_SkipSpaces (asm_text + strlen (asm_arg));
        if (*asm_text != '\0')
        {
            /* replace 'ENDIF' by 'ENDC' */
            if (str_i_cmp (asm_text, "ENDIF") == TRUE)
            {
                /* replace 'i' with a 'c' */
                asm_text[3] = (isupper ((int)asm_text[3]) != 0) ? 'C' : 'c';
                /* replace 'f' with a space */
                asm_text[4] = ' ';
            }
        }
    }
}


/* ------------------------------------------------------------------------- */


/*
 * Write a line in the ASM file
 */
void asm_WriteLine (char *text)
{
    char asm_text[ARG_MAX_SIZE+1];

    debug_print ("asm_file=%p\n", (void*)asm_file);

    if (text[0] != '(')  /* No mark allowed */
    {
        correct_line (text);

        if (scan.soft < SOFT_MACROASSEMBLER)
        {
            adjust_case (text);
        }

        asm_text[0] = '\0';
        crunch_line (text, asm_text);

        if ((text[0] == '/')
         && (asm_comment == FALSE))
        {
            asm_comment = TRUE;
        }

        if ((asm_comment == FALSE)
         || ((asm_comment == TRUE)
          && (scan.soft >= SOFT_MACROASSEMBLER)))
        {
            if (asm_file != NULL)
            {
                (void)fwrite (asm_text, 1, (size_t)strlen(asm_text), asm_file);
            }
        }

        if ((text[0] == '/')
         && (asm_comment == TRUE))
        {
            asm_comment = FALSE;
        }
    }
}



/*
 * Close the ASM file
 */
int asm_Close (void)
{
    debug_print ("%s\n", "");

    if (asm_file != NULL)
    {
        /* Last char must be CR */
        write_asm_cr ();

        (void)fclose (asm_file);
        asm_file = NULL;
    }
    return asm_total_size;
}



/*
 * Open the ASM file
 */
void asm_Open (char *file_name)
{
    debug_print ("%s\n", file_name);

    asm_file = fopen (file_name, "wb");

    asm_cr_count = 0;
    asm_total_size = 0;
    asm_comment = FALSE;
}

