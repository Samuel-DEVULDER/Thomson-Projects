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

#include <stdlib.h>
#include <string.h>
#ifndef S_SPLINT_S
#   include <ctype.h>
#endif

#include "defs.h"
#include "macro.h"
#include "error.h"
#include "display.h"
#include "arg.h"
#include "symbol.h"
#include "eval.h"
#include "includ.h"
#include "source.h"
#include "assemble.h"
#include "if.h"

#define MACRO_ARGS_MAX   10

struct MACRO_ARG_LIST {
     char *name;
     int  line;
     char *text;
     char *arg[MACRO_ARGS_MAX];
     struct MACRO_ARG_LIST *next;
	 int quiet; /* sam */
};

struct MACRO_LIST {
     unsigned short id;
     int  line;
     char *text;
     struct MACRO_LIST *next;
	 int quiet; /* sam */
};

static struct MACRO_LIST *first_macro = NULL;
static struct MACRO_ARG_LIST *first_macroarg = NULL;
static int macro_level = 0;
static unsigned short macro_id = 0;


static struct MACRO_LIST *add_macro (void)
{
    struct MACRO_LIST *new_macro;

    debug_print ("%s\n", "");

    new_macro = malloc(sizeof(struct MACRO_LIST));
    if (new_macro != NULL)
    {
        new_macro->id = macro_id;
        new_macro->line = run.line;
        new_macro->text = run.text;
        new_macro->next = first_macro;
		
		/* sam: QUIET argument */
		new_macro->quiet = 0;
		run.ptr = arg_SkipSpaces (run.ptr);
		if(arg_Read ()!=CHAR_END) {
			arg_Upper (arg_buf);
			if(strcmp(arg_buf,"QUIET")==0)
				new_macro->quiet = 1;
			else {
				error_Printf (ERROR_TYPE_ERROR,
                                 "the MACRO directive does not support " \
                                 "the '%s' option",
                                 arg_buf);
				free(new_macro);
				return NULL;
			}
		}

        first_macro = new_macro;
    }
    return new_macro;
}



static void remove_macro_args_entry (void)
{
    int i;
    struct MACRO_ARG_LIST *macroarg_next;

    debug_print ("%s\n", "");

    macroarg_next = first_macroarg->next;

    if (first_macroarg->name != NULL)
    {
        free (first_macroarg->name);
    }

    for (i=0; i<MACRO_ARGS_MAX; i++)
    {
        if (first_macroarg->arg[i] != NULL)
        {
            free (first_macroarg->arg[i]);
        }
    }

    free (first_macroarg);
    first_macroarg = macroarg_next;
    macro_level--;
}



/*
 * Add the macro arguments
 */
static struct MACRO_ARG_LIST *add_macro_args (char *macroname)
{
    int i = 0;
    char line_copy[TEXT_MAX_SIZE+1];
    size_t line_size = (scan.soft == SOFT_UPDATE) ? TEXT_MAX_SIZE : 40;
    char *arg;
    struct MACRO_ARG_LIST *new_macroarg = NULL;

    debug_print ("%s\n", "");

    new_macroarg = malloc (sizeof(struct MACRO_ARG_LIST));
    if (new_macroarg != NULL)
    {
        memset (new_macroarg, 0x00, sizeof(struct MACRO_ARG_LIST));
        new_macroarg->next = first_macroarg;
        first_macroarg = new_macroarg;

        new_macroarg->name = malloc (strlen (macroname) + 1);
        if (new_macroarg->name != NULL)
        {
            new_macroarg->name[0] = '\0';
            strcat (new_macroarg->name, macroname);
            new_macroarg->line = run.line;
            new_macroarg->text = run.text;
			new_macroarg->quiet = run.quiet;

			
            if ((strlen(line_copy)+strlen(run.ptr)) > line_size)
            {
                (void)error_Printf (ERROR_TYPE_ERROR,
                                    "the buffer for the macro argument " \
                                    "is too short (%d characters max)",
                                    line_size);
            }

            line_copy[0] = '\0';    
            strncat (line_copy, run.ptr, sizeof(line_copy)-1);
            arg = strtok (line_copy, ", ");

            while ((arg != NULL) && (arg[0] > ' '))
            {
                new_macroarg->arg[i] = malloc (strlen (arg) + 1);
                if (new_macroarg->arg[i] != NULL)
                {
                    new_macroarg->arg[i][0] = '\0';
                    strcat (new_macroarg->arg[i], arg);
                }
                else
                {
                    remove_macro_args_entry ();
                    return NULL;
                }
                i++;
                arg = strtok (NULL, ", ");
            }
            macro_level++;
        }
        else
        {
            remove_macro_args_entry ();
            new_macroarg = NULL;
        }
    }
    return new_macroarg;
}



static void print_macro_message (char *direction, char *macroname)
{
    if (run.pass == PASS2)
    {
        (void)display_Line (
            "%35s... %s Macro '%s'\n",
            "",
            direction,
            macroname);
        display_Set (PRINT_NONE);
    }
}


/* ------------------------------------------------------------------------- */


/*
 * Assembling of MACRO directive
 */
int Ass_MACRO (char *label_name)
{
    int err = NO_ERROR;

    debug_print ("%s\n", "");

    macro_id++;
    run.macro_line = run.line;

    if ((run.locked & ~LOCK_MACRO) == 0)
    {
        if (label_name[0] == '\0')
        {
            return error_Printf (ERROR_TYPE_ERROR,
                                 "the directive MACRO needs a label");
        }

        if (run.pass == PASS1)
        {
            /* TODO must check if already exist */
            if (add_macro () == NULL)
            {
                return error_Printf (ERROR_TYPE_FATAL,
                                     "not enough memory");
            }
        }

        if ((macro_level > 0)
         || ((run.locked & LOCK_MACRO) != 0))
        {
            err = error_Printf (ERROR_TYPE_ERROR,
                                "embedding macros is not allowed");
        }
        else
        if (assemble_NameIsReserved (label_name) == TRUE)
        {
            err = error_Printf (ERROR_TYPE_ERROR,
                                "the label '%s' is reserved and must not " \
                                "be used for a macro",
                                label_name);
        }
        else
        if ((if_Level () > 1) && (scan.soft == SOFT_MACROASSEMBLER))
        {
            err = error_Printf (ERROR_TYPE_ERROR,
                                "MACROASSEMBLER does not support the use " \
                                "of MACRO directive inside a conditionnal " \
                                "assembling");
        }
        else
        if (run.pass == PASS1)
        {
            err = symbol_Do (label_name, macro_id, SYMBOL_TYPE_MACRO);
        }
    }

    run.locked |= LOCK_MACRO;

    return err;
}



/*
 * Assembling of ENDM directive
 */
int Ass_ENDM (char *label_name)
{
    int err = NO_ERROR;

    debug_print ("%s\n", "");

    if ((run.locked & ~LOCK_MACRO) == 0)
    {
        if (label_name[0] != '\0')
        {
            (void)error_Printf (ERROR_TYPE_ERROR,
                                "ENDM directive does not support label");
        }

        if (run.pass == PASS1)
        {
            if (first_macro == NULL)
            {
                return error_Printf (ERROR_TYPE_FATAL,
                                     "ENDM without MACRO");
            }
        }

        if (macro_level > 0)
        {
            if (first_macroarg != NULL)
            {
				if(run.quiet==0)
                print_macro_message ("Exit", first_macroarg->name);

                run.text  = first_macroarg->text;
                run.line  = first_macroarg->line;
				run.quiet = first_macroarg->quiet; /* sam */
                remove_macro_args_entry ();
            }
            else
            {
                err =  error_Printf (ERROR_TYPE_FATAL,
                                     "ENDM without MACRO");
            }
        }
        else
        if ((run.locked & LOCK_MACRO) == 0)
        {
            err =  error_Printf (ERROR_TYPE_FATAL,
                                 "ENDM without MACRO");
        }
    }
    run.locked &= ~LOCK_MACRO;
    return err;
}



/*
 * Expand the macro line
 */
int macro_Expansion (void)
{
    int i;
    char *backslash;
    struct MACRO_ARG_LIST *macroarg = NULL;
    static char line_buffer[TEXT_MAX_SIZE+1];

    debug_print ("%s\n", "");

    if (macro_level > 0)
    {
        line_buffer[0] = '\0';
        while ((backslash = strchr (run.ptr, '\\')) != NULL)
        {
            strncat (line_buffer, run.ptr, (size_t)(backslash-run.ptr));
            run.ptr = backslash+1;

            if (isdigit ((int)*run.ptr) == 0)
            {
                return error_Printf (ERROR_TYPE_ERROR,
                                     "expect decimal digit, have %s",
                                     arg_FilteredChar (*run.ptr));
            }

            i = (int)(*(run.ptr++) - '0');

            for (macroarg = first_macroarg;
                 (macroarg != NULL)
                 && (macroarg->arg[i] != NULL)
                 && (macroarg->arg[i][0] == '\\');
                 macroarg = macroarg->next)
            {
                if (isdigit ((int)macroarg->arg[i][1]) == 0)
                {
                    return error_Printf (ERROR_TYPE_ERROR,
                                         "expect decimal digit, have %s",
                                         arg_FilteredChar (macroarg->arg[i][1]));
                }

                i = (int)(macroarg->arg[i][1] - '0');
            }

            if ((macroarg == NULL) || (macroarg->arg[i] == NULL))
            {
                return error_Printf (ERROR_TYPE_ERROR,
                                     "impossible to find the value of " \
                                     "the macro argument");
            }

            strcat (line_buffer, macroarg->arg[i]);
        }
        strcat (line_buffer, run.ptr);
        
        run.ptr = source_LinePointer ();
        run.ptr[0] = '\0';
        strncat (run.ptr, line_buffer, TEXT_MAX_SIZE);
    }
    return NO_ERROR;
}



int macro_Execute (char *label_name, char *command_name)
{
    struct MACRO_LIST *macro_list;

    debug_print ("%s\n", "");

    if (scan.soft < SOFT_MACROASSEMBLER)
    {
        return error_Printf (ERROR_TYPE_ERROR,
                             "ASSEMBLER 1.0 does not support the macro " \
                             "calls");
    }

    if (label_name[0] != '\0')
    {
        return error_Printf (ERROR_TYPE_ERROR,
                             "macro calls do not support label");
    }

    if (run.locked != 0)
    {
        return NO_ERROR;
    }

    if (assemble_NameIsReserved (command_name) == TRUE)
    {
        return error_Printf (ERROR_TYPE_ERROR,
                             "the name '%s' is reserved and must not be " \
                             "used as a macro name",
                             command_name);
    }

    run.ptr = arg_SkipSpaces (run.ptr);

    if (symbol_Do (command_name, 0, SYMBOL_READ) != NO_ERROR)
    {
        return ERR_ERROR;
    }

    if (eval.type != SYMBOL_TYPE_MACRO)
    {
        return error_Printf (ERROR_TYPE_ERROR,
                             "label '%s' already exists but is not a macro " \
                             "name",
                             command_name);
    }

    switch (macro_level)
    {
        case 8:
            if (scan.soft == SOFT_MACROASSEMBLER)
            {
                return error_Printf (ERROR_TYPE_ERROR,
                                     "more than 8 embedded macros is not " \
                                     "allowed in MACROASSEMBLER");
            }
            break;

        case 500:
            return error_Printf (ERROR_TYPE_ERROR,
                                 "it seems that the macro '%s' is calling " \
                                 "itself, execution interrupted",
                                 command_name);
    }

    if (add_macro_args (command_name) == NULL)
    {
        return error_Printf (ERROR_TYPE_FATAL,
                             "not enough memory");
    }

    for (macro_list = first_macro;
         (macro_list != NULL) && (macro_list->id != eval.operand);
         macro_list = macro_list->next);

    if (macro_list == NULL)
    {
        return error_Printf (ERROR_TYPE_ERROR,
                             "macro '%s' not found",
                             command_name);
    }

	if(macro_list->quiet==0)
    print_macro_message ("Enter", command_name);

    run.ptr = strchr (run.ptr, '\0');

    run.text = macro_list->text;
    run.line = macro_list->line;
	run.quiet = macro_list->quiet; /* sam */
	
    return NO_ERROR;
}



/* 
 * Return macro level
 */
int macro_Level (void)
{
    return macro_level;
}



/*
 * Initialize source assembly
 */
void macro_SourceInit (void)
{
    macro_level = 0;
    macro_id = 0;
}



/*
 * Free macro arguments list
 */
void macro_SourceFree (void)
{
    struct MACRO_ARG_LIST *next_macroarg;

    debug_print ("%s\n", "");

    while (first_macroarg != NULL)
    {
        next_macroarg = first_macroarg->next;
        remove_macro_args_entry ();
        first_macroarg = next_macroarg;
    }
}



/*
 * Free macro list
 */
void macro_FreeAll (void)
{
    struct MACRO_LIST *next_macro;

    debug_print ("%s\n", "");

    while (first_macro != NULL)
    {
        next_macro = first_macro->next;
        first_macro->text = NULL;
        free (first_macro);
        first_macro = next_macro;
    }
}





