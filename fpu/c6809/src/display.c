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
#include "display.h"
#include "eval.h"
#include "bin.h"
#include "mark.h"
#include "source.h"

static FILE *lst_file = NULL;
static int display_style = PRINT_COMMENT;



/*
 * Return line number string
 */
#define LINE_STRING_LENGTH_STR  "7"
static void line_string (void)
{
    debug_print ("%s\n", "");

    switch (display_style)
    {
        case PRINT_BYTES_ONLY:
        case PRINT_WORDS_ONLY:
            (void)display_Line ("%"LINE_STRING_LENGTH_STR"s  ", "");
            break;

        default:
            (void)display_Line ("% "LINE_STRING_LENGTH_STR"d  ", run.line);
            break;
    }
}
            


/*
 * Return program counter string
 */
#define PC_STRING_LENGTH      4
#define PC_STRING_LENGTH_STR  "4"
static void pc_string (void)
{
    int pos = 0;

    debug_print ("%s\n", "");

    switch (display_style)
    {
        case PRINT_COMMENT:
        case PRINT_LIKE_END:
        case PRINT_LIKE_DP:
            break;

        default:
            pos += display_Line ("%0"PC_STRING_LENGTH_STR"X", run.pc);
            break;
    }

    for (; pos<(PC_STRING_LENGTH+2); pos++)
    {
        (void)display_Line (" ");
    }
}



/*
 * Return cycles string
 */
#define CYCLE_STRING_LENGTH      6
static void cycle_string (void)
{
    int pos = 0;

    debug_print ("%s\n", "");

    switch (display_style)
    {
        case PRINT_COMMENT:
        case PRINT_BYTES:
        case PRINT_BYTES_ONLY:
        case PRINT_WORDS:
        case PRINT_WORDS_ONLY:
        case PRINT_LIKE_END:
        case PRINT_LIKE_DP:
            break;

        default:
            if (info.cycle.count != -1)
            {
                pos += display_Line ("%d", info.cycle.count);
    
                if (info.cycle.plus != -1)
                {
                    pos += display_Line ("+%d", info.cycle.plus);
                }
            }
            break;
    }

    for (; pos<CYCLE_STRING_LENGTH; pos++)
    {
         (void)display_Line (" ");
    }
}



/*
 * Return opcode string
 */
static int opcode_string (void)
{
    int pos = 0;

    debug_print ("%02X %02X\n", (unsigned int)fetch.buf[0]&0xff,
                                (unsigned int)fetch.buf[1]&0xff);

    if (fetch.buf[0] != '\x00')
    {
        pos += display_Line ("%02X%02X",
                             (unsigned int)fetch.buf[0]&0xff,
                             (unsigned int)fetch.buf[1]&0xff);
    }
    else
    {
        pos += display_Line ("  %02X", (unsigned int)fetch.buf[1]&0xff);
    }

    return pos;
}



/*
 * Return binary codes string
 */
#define BINARY_STRING_LENGTH  18
static void binary_string (void)
{
    int i;
    int pos = 0;

    debug_print ("display_style=%d\n", display_style);

    switch (display_style)
    {
        case PRINT_BYTES:
        case PRINT_BYTES_ONLY:
        case PRINT_WORDS:
        case PRINT_WORDS_ONLY:
            for (i=0; i<(int)fetch.size; i++)
            {
                if (i != 0)
                {
                    pos += display_Line (" ");
                }

                pos += display_Line ("%02X",
                                     (unsigned int)fetch.buf[1+i]&0xff);

                if (display_style >= PRINT_WORDS)
                {
                    i++;
                    pos += display_Line ("%02X",
                                         (unsigned int)fetch.buf[1+i]&0xff);
                }
            }
            break;

        case PRINT_LIKE_END:
            pos += display_Line (
                "%10s%04X",
                "",
                eval.operand);
            break;

        case PRINT_LIKE_DP:
            pos += display_Line (
                "%10s%02X",
                "",
                (unsigned int)(run.dp >> 8)&0xff);
            break;

        case PRINT_ONE_FOR_ONE:
            pos += opcode_string ();
            break;

        case PRINT_TWO_FOR_TWO:
            pos += opcode_string ();
            pos += display_Line (
                " %02X",
                (unsigned int)fetch.buf[2]&0xff);
            break;

        case PRINT_TWO_FOR_THREE:
            pos += opcode_string ();
            pos += display_Line (
                " %02X%02X",
                (unsigned int)fetch.buf[2]&0xff,
                (unsigned int)fetch.buf[3]&0xff);
            break;

        case PRINT_THREE_FOR_THREE:
            pos += opcode_string ();
            pos += display_Line (
                " %02X %02X",
                (unsigned int)fetch.buf[2]&0xff,
                (unsigned int)fetch.buf[3]&0xff);
            break;

        case PRINT_THREE_FOR_FOUR:
            pos += opcode_string ();
            pos += display_Line (
                " %02X %02X%02X",
                (unsigned int)fetch.buf[2]&0xff,
                (unsigned int)fetch.buf[3]&0xff,
                (unsigned int)fetch.buf[4]&0xff);
            break;
    }

    for (; pos<BINARY_STRING_LENGTH; pos++)
    {
        (void)display_Line (" ");
    }
}



static void source_string (void)
{
    debug_print ("%s\n", "");

    switch (display_style)
    {
        case PRINT_BYTES_ONLY:
        case PRINT_WORDS_ONLY:
            (void)display_Line ("\n");
            break;

        default:
            (void)display_Line ("%s\n", source_LinePointer());
            break;
    }
}


/* ------------------------------------------------------------------------- */


/*
void display_Snprintf ( char *s, size_t n, const char *format, ... )
{
    int pos;
    char *buf;
    va_list args;

    va_start (args, format);

    buf = malloc (4000);
    if (buf != NULL)
    {
        buf[0] = '\0';
        (void)vsprintf (buf, format, args);
        strncat (s, buf, n);
    }

    va_end (args);
    return pos;
}
*/


/*
 * Display the code
 */
void display_Code (void)
{
    debug_print (
        "display_style=%d run.locked=%d run.pass=%d (PASS2=%d)\n",
        display_style,
        run.locked,
        run.pass,
        PASS2);

    if ((run.pass != PASS2)
     || (display_style == PRINT_NONE))
    {
        return;
    }

    line_string ();
    cycle_string ();
    pc_string ();
    binary_string ();
    source_string ();
}


/*
 * Write a line in the list file (+ terminal output eventually)
 */
int display_Line (const char *format, ... )
{
    int pos = 0;
    va_list args;

    debug_print ("%s\n", "");

    va_start (args, format);

    if (lst_file != NULL)
    {
        pos = vfprintf (lst_file, format, args);
    }

    va_end (args);

    return pos;
}



void display_ErrorVAList (const char *format, va_list args)
{
    char string[300];

    string[0] = '\0';
    vsprintf (string, format, args);

    (void)fprintf (stderr, "%s", string);

    if (lst_file != NULL)
    {
        (void)fprintf (lst_file, "%s", string);
    }
}



/*
 * Display an error
 */
void display_Error (const char *format, ... )
{
    va_list args;

    debug_print ("%s\n", "");

    va_start (args, format);

    display_ErrorVAList (format, args);

    va_end (args);
}



/*
 * Write a CR in the list file (+ terminal output eventually)
 */
void display_CR (void)
{
    debug_print ("%s\n", "");

    (void)display_Line ("\n");
}



/*
 * Close the LST file
 */
void display_Close (void)
{
    debug_print ("%s\n", "");

    if (lst_file != NULL)
    {
        (void)fclose (lst_file);
        lst_file = NULL;
    }
}



/*
 * Open the LST file
 */
void display_Open (char *file_name)
{
    debug_print ("%s\n", "");

    lst_file = fopen (file_name, "wb");
}



void display_Set (int style)
{
	/* sam */
	if(run.quiet) switch(style) {
		case PRINT_COMMENT:
        case PRINT_PC:
        case PRINT_LIKE_END:
        case PRINT_LIKE_DP:
        style = PRINT_NONE;
		break;
		
		default:
		/* style = PRINT_BYTES_ONLY; */ /* sam: optionnal */
		break;
	}
	
	display_style = style;
}

