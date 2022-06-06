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
#ifndef S_SPLINT_S
#   include <ctype.h>
#endif

#include "defs.h"
#include "error.h"
#include "display.h"
#include "bin.h"
#include "arg.h"
#include "mark.h"
#include "eval.h"
#include "includ.h"
#include "assemble.h"
#include "symbol.h"

#define BIT_NO_MODE     0
#define BIT_IMMEDIATE   (1<<0)
#define BIT_LEA         (1<<1)
#define BIT_EXTENDED    (1<<2)
#define BIT_DIRECT      (1<<3)
#define BIT_INDIRECT    (1<<4)

#define SIZE_0_BIT    0
#define SIZE_5_BITS   5
#define SIZE_8_BITS   8
#define SIZE_16_BITS  16

static int immediate_size[16] = {
    SIZE_8_BITS,  /* x0 */
    SIZE_8_BITS,  /* x1 */
    SIZE_8_BITS,  /* x2 */
    SIZE_16_BITS, /* x3 */
    SIZE_8_BITS,  /* x4 */
    SIZE_8_BITS,  /* x5 */
    SIZE_8_BITS,  /* x6 */
    SIZE_0_BIT,   /* x7 */
    SIZE_8_BITS,  /* x8 */
    SIZE_8_BITS,  /* x9 */
    SIZE_8_BITS,  /* xa */
    SIZE_8_BITS,  /* xb */
    SIZE_16_BITS, /* xc */
    SIZE_0_BIT,   /* xd */
    SIZE_16_BITS, /* xe */
    SIZE_0_BIT    /* xf */
};

static int recordtype = PRINT_COMMENT;


static int direct_and_extended_addressing (int mode)
{
    int size;
    int err = NO_ERROR;

    debug_print ("%s\n\n", "");

    size = SIZE_16_BITS;

    if ((unsigned short)(eval.operand & 0xff00) == run.dp)
    {
        size = SIZE_8_BITS;     /* 8 bits if MSB = DP */
    }

    if ((mode & BIT_INDIRECT) != 0)
    {
        size = SIZE_16_BITS;    /* 16 bits if indirect mode */
    }

    if (eval.forward == TRUE)
    {
        size = SIZE_16_BITS;    /* 16 bits if not defined at start */
    }

    if ((mode & BIT_EXTENDED) != 0)
    {
        size = SIZE_16_BITS;    /* 16 bits if forced to extended */
    }

    if ((mode & BIT_DIRECT) != 0)
    {
        size = SIZE_8_BITS ;    /* 8 bits if forced to direct */
    }

    switch (size)
    {
        case SIZE_8_BITS:
            fetch.size = 2;
            fetch.buf[2] = (char)eval.operand;
            recordtype = PRINT_TWO_FOR_TWO;
            
            if ((unsigned short)(eval.operand & 0xff00) != run.dp)
            {
                err = error_Printf (ERROR_TYPE_ERROR,
                                    "the SETDP is set to $%02X and does " \
                                    "not match with the address $%04X, you " \
                                    "should better use a 16 bits mode",
                                    (unsigned int)((run.dp >> 8) & 0xff),
                                    (int)eval.operand & 0xffff);
            }

            if ((mode & BIT_INDIRECT) != 0)
            {
                err = error_Printf (ERROR_TYPE_ERROR,
                                    "indirect mode is not allowed in "\
                                    "direct and extended addressing mode");
            }
            break;

        case SIZE_16_BITS:
            if ((mode & BIT_INDIRECT) == 0)
            {
                info.cycle.count++;
                fetch.size = 3;
                fetch.buf[1] |= ((mode & BIT_IMMEDIATE) != 0) ? '\x30' : '\x70';
                fetch.buf[2] = (char)(eval.operand >> 8);
                fetch.buf[3] = (char)eval.operand;

                if (((unsigned short)(eval.operand & 0xff00) == run.dp)
                 && (scan.opt [OPT_OP] == TRUE))
                {
                    err = error_Printf (ERROR_TYPE_OPTIMIZE,
                                    "the SETDP is set to $%02X so the " \
                                    "address $%04X could be changed into " \
                                    "direct mode",
                                    (int)(run.dp >> 8) & 0xff,
                                    (int)eval.operand & 0xffff);
                }

                recordtype = PRINT_TWO_FOR_THREE;
            }
            else
            {
                info.cycle.plus = 2;
                fetch.size = 4;

                if ((mode & BIT_LEA) == 0)
                {
                    fetch.buf[1] += ((mode & BIT_IMMEDIATE) != 0)
                                     ? '\x10' : '\x60';
                }

                fetch.buf[2] = '\x9f';
                fetch.buf[3] = (char)(eval.operand >> 8);
                fetch.buf[4] = (char)eval.operand;
                recordtype = PRINT_THREE_FOR_FOUR;
            }
            break;
    }

    if ((mode & BIT_LEA) != 0)
    {
        err = error_Printf (ERROR_TYPE_ERROR, "Incorrect operand");
    }

    return err;
}



static int indexed_addressing_with_offset_and_pcr (int mode)
{
    int err = NO_ERROR;
    int size;
    unsigned short pc_pos;

    debug_print ("run.pc=%04x eval.operand=%04x\n",
                 run.pc,
                 eval.operand);

    pc_pos = (unsigned short)(eval.operand
                             - (run.pc + 3
                              + ((fetch.buf[0] == '\x00') ? 0 : 1)));

    size = (((signed short)pc_pos >= -128)
         && ((signed short)pc_pos <= 127))
             ? SIZE_8_BITS : SIZE_16_BITS;

    if (eval.forward == TRUE)
    {
        size = SIZE_16_BITS;    /* 16 bits if not defined at start */
    }

    if ((mode & BIT_EXTENDED) != 0)
    {
        size = SIZE_16_BITS;    /* 16 bits if forced to extended */
    }

    if ((mode & BIT_DIRECT) != 0)
    {
        size = SIZE_8_BITS;     /* 8 bits if forced to direct */
    }
 
    switch (size)
    {
        case SIZE_8_BITS :
            info.cycle.plus = 1;
            fetch.size = 3;
            fetch.buf[2] = '\x8c';
            fetch.buf[3] = (char)pc_pos;

            if (((signed short)pc_pos < -128)
             || ((signed short)pc_pos > 127))
            {
                err = error_Printf (ERROR_TYPE_ERROR,
                                    "the offset of this indexed addressing " \
                                    "mode must be limited to 8 bits (from " \
                                    "-128 to 127)");
            }

            recordtype = PRINT_THREE_FOR_THREE;
            break;

        case SIZE_16_BITS :
            if (((signed short)pc_pos >= -128)
             && ((signed short)pc_pos <= 127)
             && (scan.opt [OPT_OP] == TRUE))
            {
                err = error_Printf (ERROR_TYPE_OPTIMIZE,
                                    "the offset of the indexed addressing " \
                                    "mode could be reduced to 8 bits");
            }
            pc_pos--;
            info.cycle.plus = 5;
            fetch.size = 4;
            fetch.buf[2] = '\x8d';
            fetch.buf[3] = (char)(pc_pos >> 8);
            fetch.buf[4] = (char)pc_pos;

            recordtype = PRINT_THREE_FOR_FOUR;
            break;
    }
    return err;
}



static int indexed_addressing_without_offset (int mode)
{
    int err = NO_ERROR;
    int rcode;

    debug_print ("%s\n", "");

    fetch.size = 2;

    if ((mode & BIT_LEA) == 0)
    {
        fetch.buf[1] += ((mode & BIT_IMMEDIATE) != 0) ? '\x10' : '\x60';
    }

    if (*(++run.ptr) == '-')
    {
        info.cycle.plus = 2;
        fetch.buf[2] = '\x82';
        if (*(++run.ptr) == '-')
        {
            info.cycle.plus = 3;
            fetch.buf[2] = '\x83';
            run.ptr++;
        }
        rcode = arg_Read ();
        if ((rcode & REGS_XYUS) == 0)
        {
            err = error_Printf (ERROR_TYPE_ERROR,
                                "indexed addressing without offset needs an" \
                                "address register (X, Y, U or S) and not " \
                                "'%s'", arg_buf);
        }
    }
    else
    {
        rcode = arg_Read ();
        if ((rcode & REGS_XYUS) != 0)
        {
            info.cycle.plus = 0;
            fetch.buf[2] = '\x84';
            if (*run.ptr == '+')
            {
                info.cycle.plus = 2;
                fetch.buf[2] = '\x80';
                run.ptr++;
                if (*run.ptr == '+')
                {
                    info.cycle.plus = 3;
                    fetch.buf[2] = '\x81';
                    run.ptr++;
                }
            }
        }
        else
        {
            err = error_Printf (ERROR_TYPE_ERROR,
                                "indexed addressing without offset needs an" \
                                "address register (X, Y, U or S) and not " \
                                "'%s'", arg_buf);
        }
    }

    fetch.buf[2] |= (char)((unsigned int)((rcode & 0xff) - 1) << 5);

    if ((mode & BIT_INDIRECT) != 0)
    {
        if ((err == NO_ERROR)
         && (((fetch.buf[2] & '\x9f') == '\x82')
          || ((fetch.buf[2] & '\x9f') == '\x80')))
        {
            err = error_Printf (ERROR_TYPE_ERROR,
                                "indexed addressing with autoincrement "\
                                "by 1 is not allowed in indirect mode");
        }
    }

    recordtype = PRINT_TWO_FOR_TWO;

    return err;
}



static int indexed_addressing_with_register (int mode)
{
    int err = NO_ERROR;
    int rcode;

    debug_print ("%s\n", "");

    fetch.size = 2;
    if ((mode & BIT_LEA) == 0)
    {
        fetch.buf[1] += ((mode & BIT_IMMEDIATE) != 0) ? '\x10' : '\x60';
    }

    if ((mode & BIT_DIRECT) != 0)
    {
        err = error_Printf (ERROR_TYPE_ERROR,
                            "direct mode is not allowed in indexed" \
                            "addressing mode with register");
    }

    if ((mode & BIT_EXTENDED) != 0)
    {
        err = error_Printf (ERROR_TYPE_ERROR,
                            "extended mode is not allowed in indexed" \
                            "addressing mode with register");
    }

    switch ((char)toupper((int)*run.ptr))
    {
        case 'A':
            fetch.buf[2] = '\x86';
            info.cycle.plus = 1;
            break;

        case 'B':
            fetch.buf[2] = '\x85';
            info.cycle.plus = 1;
            break;

        case 'D':
            fetch.buf[2] = '\x8b';
            info.cycle.plus = 4;
            break;
    }
    run.ptr += 2;
    recordtype = PRINT_TWO_FOR_TWO;

    rcode = arg_Read ();
    if ((rcode & REGS_XYUS) == 0)
    {
        err = error_Printf (ERROR_TYPE_ERROR,
                            "addressing with register needs an " \
                            "address register (X, Y, U, S) and not '%s'",
                            arg_buf);
    }

    fetch.buf[2] |= (char)((unsigned int)((rcode & 0xff) - 1) << 5);

    return err;
}



static int immediate_addressing (int mode)
{
    int err = NO_ERROR;

    debug_print ("%s\n", "");

    info.cycle.count -= 2;
    run.ptr++;

    if ((mode & BIT_IMMEDIATE) == 0)
    {
        err = error_Printf (ERROR_TYPE_ERROR,
                            "must be immediate addressing mode");
    }

    Eval();

    switch (immediate_size [(int)fetch.buf[1] & 0x0F])
    {
        case SIZE_8_BITS :
            fetch.size = 2;
            fetch.buf[2] = (char)eval.operand;

            if (((signed short)eval.operand < -256)
             || ((signed short)eval.operand > 255))
            {
                err = error_Printf (ERROR_TYPE_ERROR,
                                    "the value of the immediate addressing " \
                                    "mode ($%04x) must be limited to 8 bits.",
                                    eval.operand & 0xffff);
            }

            display_Set (PRINT_TWO_FOR_TWO);
            break;

        case SIZE_16_BITS :
            fetch.size = 3;
            fetch.buf[2] = (char)(eval.operand >> 8);
            fetch.buf[3] = (char)eval.operand;
            display_Set (PRINT_TWO_FOR_THREE);
            break;
        
        default :
            err = error_Printf (ERROR_TYPE_ERROR,
                                "immediate addressing is not allowed in "\
                                "this mode");
            break;
    }
    return err;
}



static int indexed_addressing_with_offset_and_register (int mode, int rcode)
{
    int err = NO_ERROR;
    int size;

    debug_print ("%s\n", "");

    size = SIZE_16_BITS;

    if (((signed short)eval.operand >= -128)
     && ((signed short)eval.operand <= 127))
    {
        size = SIZE_8_BITS;
    }

    if (((signed short)eval.operand >= -16)
     && ((signed short)eval.operand <= 15))
    {
        size = ((mode & BIT_INDIRECT) != 0) ? SIZE_8_BITS : SIZE_5_BITS;
    }

    if (eval.forward == TRUE)
    {
        size = SIZE_16_BITS;  /* 16 bits if not defined at start */
    }

    if ((mode & BIT_EXTENDED) != 0)
    {
        size = SIZE_16_BITS;  /* 16 bits if forced to extended */
    }

    if ((mode & BIT_DIRECT) != 0)
    {
        size = SIZE_8_BITS;   /* 8 bits if forced to direct */
    }

    switch (size)
    {
        case SIZE_5_BITS:
            info.cycle.plus = 1;
            fetch.size = 2;
            fetch.buf[2] = (char)(0x00 | (eval.operand&0x1f));
            recordtype = PRINT_TWO_FOR_TWO;
            break;

        case SIZE_8_BITS:
            info.cycle.plus = 1;
            fetch.size = 3;
            fetch.buf[2] = '\x88';
            fetch.buf[3] = (char)eval.operand;
            if (((signed short)eval.operand < -128)
             || ((signed short)eval.operand > 127))
            {
                err = error_Printf (ERROR_TYPE_ERROR,
                                    "the offset of the indexed addressing " \
                                    "mode must be limited to 8 bits (from " \
                                    "-128 to 127)");
            }
            recordtype = PRINT_THREE_FOR_THREE;
            break;

        case SIZE_16_BITS:
            info.cycle.plus = 4;
            fetch.size = 4;
            fetch.buf[2] = '\x89';
            fetch.buf[3] = (char)(eval.operand >> 8);
            fetch.buf[4] = (char)eval.operand;
            recordtype = PRINT_THREE_FOR_FOUR;
            break;
    }

    if (scan.opt [OPT_OP] == TRUE)
    {
        if ((eval.operand == 0)
         && (size > SIZE_0_BIT)
         && ((mode & BIT_INDIRECT) == 0))
        {
            err = error_Printf (ERROR_TYPE_OPTIMIZE,
                                "the offset of the indexed addressing mode "\
                                "could be removed");
        }
        else
        if (((signed short)eval.operand >= -16)
         && ((signed short)eval.operand <= 15)
         && (size > SIZE_5_BITS)
         && ((mode & BIT_INDIRECT) == 0))
        {
            err = error_Printf (ERROR_TYPE_OPTIMIZE,
                                "the offset of the indexed addressing mode "\
                                "could be reduced to 5 bits (from -16 to 15)");
        }
        else
        if (((signed short)eval.operand >= -128)
         && ((signed short)eval.operand <= 127)
         && (size > SIZE_8_BITS))
        {
            err = error_Printf (ERROR_TYPE_OPTIMIZE,
                                "the offset of the indexed addressing mode "\
                                "could be reduced to 8 bits (from -128 to "\
                                "127)");
        }
    }
    
    fetch.buf[2] |= (char)((unsigned int)((rcode & 0xff) - 1) << 5);
    return err;
}



static int addressing_with_offset (int mode)
{
    int err = NO_ERROR;
    int rcode;

    debug_print ("%s\n", "");

    Eval();

    if (*run.ptr == ',')
    {
        if ((mode & BIT_LEA) == 0)
        {
            fetch.buf[1] += ((mode & BIT_IMMEDIATE) != 0) ? '\x10' : '\x60';
        }

        run.ptr++;
        rcode = arg_Read ();

        if ((rcode & REGS_PCR) != 0)
        {
            err = indexed_addressing_with_offset_and_pcr (mode);
        }
        else
        if ((rcode & REGS_XYUS) != 0)
        {
            err = indexed_addressing_with_offset_and_register (mode, rcode);
        }
        else
        {
            err = error_Printf (ERROR_TYPE_ERROR,
                                "addressing with offset needs an" \
                                "address register (X, Y, U, S or PCR) " \
                                "and not '%s'",
                                arg_buf);
        }
    }
    else 
    {
        err = direct_and_extended_addressing (mode);
    }
    return err;
}



int all_type (int mode)
{
    int err = NO_ERROR;

    debug_print ("%s\n", "");

    fetch.buf[2] = '\x00';
    fetch.size = 2;

    run.ptr = arg_SkipSpaces (run.ptr);
    
    switch (*run.ptr)
    {
        case '#':
            return immediate_addressing (mode);

        case '<':
            mode |= BIT_DIRECT;
            run.ptr++;
            break;

        case '>':
            mode |= BIT_EXTENDED;
            run.ptr++;
            break;
    }

    if (*run.ptr == '[') 
    {
        mode |= BIT_INDIRECT;
        run.ptr++;
    }

    if ((fetch.buf[1] & '\x80') != '\0')
    {
        fetch.buf[1] |= '\x10';
    }

    if (((toupper((int)*run.ptr) == 'A')
      || (toupper((int)*run.ptr) == 'B')
      || (toupper((int)*run.ptr) == 'D'))
     && (*(run.ptr+1) == ','))
    {
        if (indexed_addressing_with_register (mode) != NO_ERROR)
        {
            err = ERR_ERROR;
        }
    }
    else
    if (*run.ptr == ',')
    {
        if (indexed_addressing_without_offset (mode) != NO_ERROR)
        {
            err = ERR_ERROR;
        }
    }
    else
    {
        if (addressing_with_offset (mode) != NO_ERROR)
        {
            err = ERR_ERROR;
        }
    }

    /* Check if indirect mode (']') */
    if ((mode & BIT_INDIRECT) != 0)
    {
        info.cycle.plus += (info.cycle.plus == -1) ? 4 : 3;
        fetch.buf[2] |= '\x10';

        if (*run.ptr != ']')
        {
            err = error_Printf (ERROR_TYPE_ERROR,
                                "opening square bracket is not closed");
        }
        run.ptr++;
    }

    display_Set (recordtype);

    return err;
}


/* ------------------------------------------------------------------------- */


int Ass_All (void)
{
    debug_print ("run.pc=%04X\n", run.pc);

    return all_type (BIT_IMMEDIATE);
}



int Ass_NotImmed (void)
{
    debug_print ("run.pc=%04X\n", run.pc);

    return all_type (BIT_NO_MODE);
}



int Ass_Lea (void)
{
    debug_print ("run.pc=%04X\n", run.pc);

    return all_type (BIT_LEA);
}

