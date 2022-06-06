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

#include "defs.h"
#include "includ.h"
#include "error.h"
#include "display.h"
#include "bin.h"
#include "source.h"
#include "macro.h"
#include "arg.h"
#include "if.h"

struct INCLUD_LIST *top_includ = NULL;
static struct INCLUD_LIST *first_includ = NULL;
static int includ_count = 0;
static int inc_flag = PRINT_BYTES;



/*
 * Flush INCBIN/INCDAT data buffer
 */
static void flush_inc (void)
{
    if (fetch.size < 4)
    {
        display_Set (inc_flag);
        display_Code ();
    }
    bin_FlushFetch ();
}



/*
 * Record INCBIN/INCDAT data
 */
static void record_inc (char c)
{
    bin_WriteChar (c);
    if (fetch.size == 4)
    {
        display_Set (inc_flag);
        display_Code ();
        inc_flag = PRINT_BYTES_ONLY;
    }
}



/*
 * Open an include
 */
static int open_include (void)
{
    int err = NO_ERROR;
    debug_print ("%s\n", "");
       
    switch (scan.soft)
    {
        case SOFT_ASSEMBLER_TO:
        case SOFT_ASSEMBLER_MO:
            if (macro_Level() > 1)
            {
                err = error_Printf (
                    ERROR_TYPE_ERROR,
                    "ASSEMBLER 1.0 does not support " \
                    "to call an INCLUD from an INCLUD");
            }
            break;

        case SOFT_MACROASSEMBLER:
            if ((run.locked & LOCK_MACRO) != 0)
            {
                err = error_Printf (
                    ERROR_TYPE_ERROR,
                    "MACROASSEMBLER does not support " \
                    "to call an INCLUD from a MACRO");
            }
            else
            if (macro_Level() > 8)
            {
                err = error_Printf (
                    ERROR_TYPE_ERROR,
                    "MACROASSEMBLER does not support " \
                    "more than 8 embedded INCLUD");
            }
            break;

        default:
            break;
    }
    return err;
}



/*
 * Remove an INCLUD
 */
static void remove_includ (void)
{
    struct INCLUD_LIST *current_includ;

    debug_print ("%s\n", "");

    run.text = top_includ->text;
    run.line = top_includ->line;

    current_includ = top_includ->next;
    free (top_includ);
    top_includ = current_includ;

    includ_count--;
}



/*
 * Add an INCLUD
 */
static struct INCLUD_LIST *add_includ (struct SOURCE_LIST *source)
{
    struct INCLUD_LIST *new_includ;

    debug_print ("%s\n", "");

    new_includ = malloc (sizeof (struct INCLUD_LIST));
    if (new_includ != NULL)
    {
        new_includ->text = run.text;
        new_includ->line = run.line;

        new_includ->source = source;
        new_includ->next = top_includ;
        top_includ = new_includ;

        if (first_includ == NULL)
            first_includ = new_includ;

        run.line = source->line;
        run.text = source->buf;
        includ_count++;
    }
    return new_includ;
}    



/*
 * Read An INCBIN/INCDAT
 */
static int read_raw_file (char *extension, char *label_name)
{
    int c = 0;
    int err = ERR_ERROR;

    debug_print ("%s\n", "");

    inc_flag = PRINT_BYTES;

    if (label_name[0] != '\0')
    {
        (void)error_Printf (
            ERROR_TYPE_ERROR,
            "include directives do not support label");
    }

    run.ptr = arg_SkipSpaces (run.ptr);

    if (open_include () == NO_ERROR)
    {
        if (source_OpenBin (extension) == NO_ERROR)
        {
            while (c >= 0)
            {
                c = bin_ReadChar ();
                if (c >= 0)
                {
                    record_inc ((char)c);
                }
            }

            flush_inc ();
            display_Set (PRINT_NONE);
            bin_ReadClose ();

            switch (c)
            {
                case ERR_END_OF_FILE:
                    err = NO_ERROR;
                    break;

                default:
                    break;
            }
        }
    }
    return err;
}



static void print_includ_message (char *direction, char *includname)
{
    if (run.pass == PASS2)
    {
        (void)display_Line (
            "====================================== %s Includ '%s'\n",
            direction,
            includname);
        display_Set (PRINT_NONE);

        /* point to end of line */
        run.ptr = strchr (run.ptr, '\0');
    }
}


/* ------------------------------------------------------------------------- */


/*
 * Get FROM source
 */
struct SOURCE_LIST *includ_GetFromSource (void)
{
    return top_includ->source->from;
}



/*
 * INCLUD directive
 */
int Ass_INCLUD (char *label_name)
{
    int err;
    struct INCLUD_LIST *new_includ = NULL;
    struct SOURCE_LIST *source;

    debug_print ("%s\n", "");

    if (label_name[0] != '\0')
    {
        (void)error_Printf (ERROR_TYPE_ERROR,
                            "INCLUD directive does not support label");
    }

    run.ptr = arg_SkipSpaces (run.ptr);

    err = ERR_ERROR;
    if (open_include () == NO_ERROR)
    {
        source = source_IncludLoad ();
        if (source != NULL)
        {
            new_includ = add_includ (source);
            if (new_includ != NULL)
            {
                print_includ_message ("Enter", source->name);
                err = NO_ERROR;
            }
            else
            {
                (void)error_Printf (ERROR_TYPE_FATAL, "not enough memory");
            }
        }
    }

    return err;
}



/*
 * INCBIN directive
 */
int Ass_INCBIN (char *label_name)
{
    debug_print ("%s\n", "");

    return read_raw_file ("BIN", label_name);
}



/*
 * INCDAT directive
 */
int Ass_INCDAT (char *label_name)
{
    debug_print ("%s\n", "");

    return read_raw_file ("", label_name);
}



/*
 * Get current line
 */
void includ_GetLine (void)
{
    debug_print ("%s\n", "");

    run.text = source_GetLine (run.text, top_includ->source->end);
    run.ptr = source_LinePointer ();
    run.line++;
}



void includ_CheckIfEnd (void)
{
    debug_print ("includ_count=%d\n", includ_count);

    if (includ_count > 1)
    {
        remove_includ ();
        print_includ_message ("Re-enter", top_includ->source->name);
    }
    else
    {
        run.exit = TRUE;
        display_Set (PRINT_NONE);
    }
    
}



/*
 * Quit eventually the current includ
 */
void includ_ManageLevel (void)
{
    debug_print ("includ_count=%d\n", includ_count);

    if (run.text == top_includ->source->end)
    {
        includ_CheckIfEnd ();

        /* error if comment is running */
        if ((run.locked & LOCK_COMMENT) != 0)
        {
            (void)error_Printf (
                ERROR_TYPE_FATAL,
                "comment definition at line %d not closed",
                run.comment_line);
            run.locked &= ~LOCK_COMMENT;
        }
    }
}



/*
 * Init include assembly
 */
int includ_SourceInit (char *file_name)
{
    int err = ERR_ERROR;
    struct INCLUD_LIST *new_includ = NULL;
    struct SOURCE_LIST *source;

    source = source_FirstLoad (file_name);
    if (source != NULL)
    {
        new_includ = add_includ (source);
        if (new_includ != NULL)
        {
            run.text = new_includ->source->buf;
            run.line = new_includ->source->line;
            err = NO_ERROR;
        }
        else
        {
            (void)error_Printf (ERROR_TYPE_FATAL, "not enough memory");
        }
    }

    return err;
}



/*
 * Free include ressources
 */
void includ_SourceFree (void)
{
    debug_print ("%s\n", "");

    while (top_includ != NULL)
    {
        remove_includ ();
    }
}
