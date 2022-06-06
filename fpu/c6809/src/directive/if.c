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

#include "defs.h"
#include "if.h"
#include "error.h"
#include "eval.h"
#include "arg.h"

#define IF_LEVEL_MAX  16

enum {
    IF_IFNE = 0,
    IF_IFEQ,
    IF_IFGT,
    IF_IFLT,
    IF_IFGE,
    IF_IFLE
};
 
enum {
    IF_TRUE = 0,
    IF_TRUE_ELSE,
    IF_FALSE,
    IF_FALSE_ELSE,
    IF_STOP
};

struct IF_LIST {
    int status;
    int level;
    struct IF_LIST *next;
};

static int level = 0;
static struct IF_LIST *first_if = NULL;



static void add_to_list (int status)
{
    struct IF_LIST *new_list;

    run.if_line = run.line;

    new_list = malloc (sizeof(struct IF_LIST));
    if (new_list != NULL)
    {
        new_list->status = status;
        new_list->next = first_if;
        first_if = new_list;
        level++;
    }
    else
    {
        (void)error_Printf (ERROR_TYPE_FATAL,
                            "not enough memory");
    }
}
    


/*
 * Free list element
 */
static void remove_from_list (void)
{
    struct IF_LIST *prev_list;

    prev_list = first_if->next;
    free (first_if);
    first_if = prev_list;
    level--;
}



void update_lock (void)
{
    switch (first_if->status)
    {
        case IF_FALSE_ELSE :
        case IF_TRUE :
            run.locked &= ~LOCK_IF;
            break;

        default :
            run.locked |= LOCK_IF;
            break;
    }
}



static int assemble_if (int condition, char *label_name)
{
    int result = FALSE;

    run.ptr = arg_SkipSpaces (run.ptr);

    if (run.locked != 0)
    {
        if ((run.locked & LOCK_IF) != 0)
        {
            add_to_list (IF_STOP);
        }
        return NO_ERROR;
    }

    if (label_name[0] != '\0')
    {
        (void)error_Printf (ERROR_TYPE_ERROR,
                            "conditional directive does not support label");
    }

    if ((level == (IF_LEVEL_MAX+1))
     && (scan.soft <= SOFT_MACROASSEMBLER))
    {
        return error_Printf (ERROR_TYPE_ERROR,
                             "MACROASSEMBLER support a maximum of %d " \
                             "embedded IF, have %d embedded IF",
                             IF_LEVEL_MAX,
                             level);
    }

    Eval();

    switch (condition)
    {
        case IF_IFNE :
            result = (eval.operand != 0) ? TRUE : FALSE;
            break;

        case IF_IFEQ :
            result = (eval.operand == 0) ? TRUE : FALSE;
            break;

        case IF_IFGT :
            result = ((signed short)eval.operand >  0) ? TRUE : FALSE;
            break;

        case IF_IFLT :
            result = ((signed short)eval.operand <  0) ? TRUE : FALSE;
            break;

        case IF_IFGE :
            result = ((signed short)eval.operand >= 0) ? TRUE : FALSE;
            break;

        case IF_IFLE :
            result = ((signed short)eval.operand <= 0) ? TRUE : FALSE;
            break;
    }

    switch (first_if->status)
    {
        case IF_TRUE :
        case IF_FALSE_ELSE :
            add_to_list ((result == TRUE) ? IF_TRUE : IF_FALSE);
            break;

        default :
            add_to_list (IF_STOP);
            break;
    }
    update_lock ();

    return NO_ERROR;
}


/* ------------------------------------------------------------------------- */


int Ass_IF (char *label_name)
{
    return assemble_if (IF_IFNE, label_name);
}



int Ass_IFNE (char *label_name)
{
    return assemble_if (IF_IFNE, label_name);
}



int Ass_IFEQ (char *label_name)
{
    return assemble_if (IF_IFEQ, label_name);
}



int Ass_IFGT (char *label_name)
{
    return assemble_if (IF_IFGT, label_name);
}



int Ass_IFLT (char *label_name)
{
    return assemble_if (IF_IFLT, label_name);
}



int Ass_IFGE (char *label_name)
{
    return assemble_if (IF_IFGE, label_name);
}



int Ass_IFLE (char *label_name)
{
    return assemble_if (IF_IFLE, label_name);
}



int Ass_ELSE (char *label_name)
{
    if ((run.locked & ~LOCK_IF) == 0)
    {
        if (label_name[0] != '\0')
        {
            (void)error_Printf (ERROR_TYPE_ERROR,
                                "ELSE directive does not support label");
        }

        if (level <= 1)
        {
            return error_Printf (ERROR_TYPE_ERROR, "ELSE without IF");
        }

        switch (first_if->status)
        {
            case IF_TRUE_ELSE  :
            case IF_FALSE_ELSE :
                 return error_Printf (ERROR_TYPE_ERROR,
                                      "too many ELSEs for an IF");
            case IF_TRUE :
                first_if->status = IF_TRUE_ELSE;
                break;
        
            case IF_FALSE :
                first_if->status = IF_FALSE_ELSE;
                break;

            default :
                break;
        }

        update_lock ();
    }
    return NO_ERROR;
}



int Ass_ENDC (char *label_name)
{
    int err = NO_ERROR;

    if ((run.locked & ~LOCK_IF) == 0)
    {
        if (label_name[0] != '\0')
        {
            (void)error_Printf (ERROR_TYPE_ERROR,
                                "ENDC directive does not support label");
        }

        if (level <= 1)
        {
            err = error_Printf (ERROR_TYPE_ERROR, "ENDC without IF");
        }
        else
        {
            remove_from_list ();
        }

        update_lock ();
    }
    return err;
}



/*
 * Return if level
 */
int if_Level (void)
{
    return level;
}



/*
 * Free list chain
 */
void if_SourceFree (void)
{
    while (first_if != NULL)
    {
        remove_from_list ();
    }
}



/*
 * Initialize conditional status
 */
void if_SourceInit (void)
{    
    add_to_list (IF_TRUE);
    update_lock ();
}

