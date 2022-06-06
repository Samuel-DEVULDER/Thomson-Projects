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
 
#include "defs.h"
#include "error.h"
#include "display.h"
#include "eval.h"
#include "bin.h"
#include "includ.h"
#include "symbol.h"
#include "source.h"
#include "arg.h"
#include "encode.h"
#include "assemble.h"

#define SIZE_BYTE   1
#define SIZE_WORD   2

static int fcx_flag = PRINT_BYTES;



/*
 * Record fcx data
 */
static void record_fcx (char c)
{
    debug_print ("%s\n", "");

    if (fetch.size == 4)
    {
        display_Set (fcx_flag);
        display_Code ();

        if (fcx_flag == PRINT_BYTES)
        {
            fcx_flag = PRINT_BYTES_ONLY;
        }
        else
        if (fcx_flag == PRINT_WORDS)
        {
            fcx_flag = PRINT_WORDS_ONLY;
        }
    }
    bin_WriteChar (c);
}



/*
 * Initialize the FCx sequence
 */
static int init_fcx (int flag, char *label_name)
{
    fetch.size = 0;
    fcx_flag = flag;

    return assemble_RecordLabel (label_name);
}



/*
 * Close the FCx sequence
 */
static void close_fcx (void)
{
    if (fetch.size > 0)
    {
        display_Set (fcx_flag);
        display_Code ();
    }
    bin_FlushFetch ();

    display_Set (PRINT_NONE);
}



/*
 * Assemble the FCC data
 */
static int assemble_fcc_data (void)
{
    int i;
    char fcx_eol;

    debug_print ("%s\n", "");

    run.ptr = arg_SkipSpaces (run.ptr);

    if (((int)*run.ptr & 0xff) > 0x20)
    {
        fcx_eol = *(run.ptr++);
    }
    else
    {
        return error_Printf (ERROR_TYPE_ERROR,
                             "missing operand");
    }

    do
    {
        if (*run.ptr == '\0')
        {
            return error_Printf (ERROR_TYPE_ERROR,
                                 "missing closing character");
        }
        else
        if (*run.ptr < '\0')
        {
            if (scan.soft < SOFT_MACROASSEMBLER)
            {
                (void)error_Printf (ERROR_TYPE_ERROR,
                                    "ASSEMBLER 1.0 does not support " \
                                    "extra-characters in a FCB list");
            }
            i = encode_AccChar (&run.ptr);

            if ((i & 0xff) != 0x00)
            {
                record_fcx ('\x16');
                record_fcx ((char)((unsigned int)i >> 8));
                record_fcx ((char)i);
            }
            else
            {
                if (i == (int)((unsigned int)'?' << 8))
                {
                    (void)error_Printf (ERROR_TYPE_WARNING,
                                        "an invalid character has been " \
                                        "replaced with a '?' in the FCB list");
                }
                record_fcx ((char)((unsigned int)i >> 8));
            }
        }
        else
        if (*run.ptr >= ' ')
        {
            record_fcx (*run.ptr);
            run.ptr++;
        }

    } while (*run.ptr != fcx_eol);

    run.ptr++;
    return NO_ERROR;
}



/*
 * Assemble the FCB
 */
static int assemble_fcb (char *label_name)
{
    debug_print ("%s\n", "");

    run.ptr = arg_SkipSpaces (run.ptr);

    if (init_fcx (PRINT_BYTES, label_name) != NO_ERROR)
    {
        return ERR_ERROR;
    }

    do
    {
        Eval();

        if (((eval.operand & 0xff00) != 0x0000)
         && ((eval.operand & 0xff00) != 0xff00))
        {
            (void)error_Printf (ERROR_TYPE_ERROR,
                                "the value for the FCB " \
                                "must be limited to a range from -255 " \
                                "to 255, have '%04X'",
                                (int)eval.operand & 0xffff);
        }

        record_fcx ((char)eval.operand);

    } while (*(run.ptr++) == ',');

    run.ptr--;

    close_fcx ();

    return NO_ERROR;
}



/*
 * Assemble the FDB
 */
static int assemble_fdb (char *label_name)
{
    debug_print ("%s\n", "");

    run.ptr = arg_SkipSpaces (run.ptr);

    if (init_fcx (PRINT_WORDS, label_name) != NO_ERROR)
    {
        return NO_ERROR;
    }

    do
    {
        Eval();

        record_fcx ((char)(eval.operand >> 8));
        record_fcx ((char)eval.operand);

    } while (*(run.ptr++) == ',');

    run.ptr--;

    close_fcx ();

    return NO_ERROR;
}



/*
 * Assemble the FCC
 */
static int assemble_fcc (char *label_name)
{
    int err;

    debug_print ("%s\n", "");

    err = init_fcx (PRINT_BYTES, label_name);
    
    if (err == NO_ERROR)
    {
        err = assemble_fcc_data ();
    }

    close_fcx ();

    return err;
}



/*
 * Assemble the FCN
 */
static int assemble_fcn (char *label_name)
{
    int err;

    debug_print ("%s\n", "");

    err = init_fcx (PRINT_BYTES, label_name);
    
    if (err == NO_ERROR)
    {
        err = assemble_fcc_data ();

        if (err == NO_ERROR)
        {
            fetch.buf[fetch.size] |= 0x80;
        }
    }

    close_fcx ();

    return err;
}



/*
 * Assemble the FCS
 */
static int assemble_fcs (char *label_name)
{
    int err;

    debug_print ("%s\n", "");

    err = init_fcx (PRINT_BYTES, label_name);

    if (err == NO_ERROR)
    {
        err = assemble_fcc_data ();

        if (err == NO_ERROR)
        {
            record_fcx ('\x00');
        }
    }

    close_fcx ();

    return err;
}


/* ------------------------------------------------------------------------- */


int Ass_FCB (char *label_name)
{
    debug_print ("label_name='%s'\n", label_name);

    return assemble_fcb (label_name);
}



int Ass_FCC (char *label_name)
{
    debug_print ("label_name='%s'\n", label_name);

    return assemble_fcc (label_name);
}



int Ass_FCS (char *label_name)
{
    debug_print ("label_name='%s'\n", label_name);

    return assemble_fcs (label_name);
}



int Ass_FCN (char *label_name)
{
    debug_print ("label_name='%s'\n", label_name);

    return assemble_fcn (label_name);
}



int Ass_FDB (char *label_name)
{
    debug_print ("label_name='%s'\n", label_name);

    return assemble_fdb (label_name);
}

