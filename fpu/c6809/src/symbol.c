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
#ifndef S_SPLINT_S
#   include <ctype.h>
#endif

#include "defs.h"
#include "symbol.h"
#include "error.h"
#include "display.h"
#include "eval.h"

#define SYMBOL_FLAG_DEFINED        0x80
#define SYMBOL_FLAG_MULTIPLE       0x40
#define SYMBOL_FLAG_SET            0x20
#define SYMBOL_FLAG_MACRO          0x10
#define SYMBOL_FLAG_LABEL          0x08
#define SYMBOL_FLAG_ARG            0x04
#define SYMBOL_FLAG_FORWARD 0x02

enum {
    SYMBOL_ORDER_ALPHABETICAL = 0,
    SYMBOL_ORDER_ERROR,
    SYMBOL_ORDER_TYPE,
    SYMBOL_ORDER_TIME
};

struct SYMBOL_DATA {
    char *name;
    unsigned short value;
    int flag;
    int type;
    int error;
    int time;
};

struct SYMBOL_LIST {
    struct SYMBOL_DATA *data;
    struct SYMBOL_LIST *next;
};

struct ERROR_TABLE {
    char string[9];
    int type;
};

struct TYPE_TABLE {
    char string[6];
    int type;
};

static const struct ERROR_TABLE error_table[] = {
    { "Unknown ",  SYMBOL_ERROR_NOT_DEFINED      },
    { "Multiply",  SYMBOL_ERROR_MULTIPLY_DEFINED },
    { "        ",  SYMBOL_ERROR_NONE             }
};

static const struct TYPE_TABLE type_table[] = {
    { "???  ",  SYMBOL_READ       },
    { "Arg  ",  SYMBOL_TYPE_ARG   },
    { "Set  ",  SYMBOL_TYPE_SET   },
    { "Equ  ",  SYMBOL_TYPE_EQU   },
    { "Label",  SYMBOL_TYPE_LABEL },
    { "Macro",  SYMBOL_TYPE_MACRO }
};

static int symbol_order = SYMBOL_ORDER_ALPHABETICAL;
static struct SYMBOL_LIST *first_symbol = NULL;



/*
 *  Create a new symbol
 */
static struct SYMBOL_LIST *create_symbol (char *name)
{
    struct SYMBOL_LIST *symbol = NULL;

    debug_print ("%s\n", "");

    symbol = malloc (sizeof(struct SYMBOL_LIST));
    if (symbol != NULL)
    {
        memset (symbol, 0x00, sizeof(struct SYMBOL_LIST));
        symbol->data = malloc (sizeof(struct SYMBOL_DATA));
        if (symbol->data != NULL)
        {
            memset (symbol->data, 0x00, sizeof(struct SYMBOL_DATA));
            symbol->data->name = malloc (strlen(name)+1);
            if (symbol->data->name != NULL)
            {
                symbol->data->name[0] = '\0';
                strcat (symbol->data->name, name);
                symbol->data->value = 0;
                symbol->data->flag = 0;
                symbol->data->time = 0;
            }
            else
            {
                free (symbol->data);
                free (symbol);
                symbol = NULL;
            }
        }
        else
        {
            free (symbol);
            symbol = NULL;
        }
    }
    return symbol;
}



/*
 * Enregistre une ligne de symbole de fin d'assemblage
 */
static void print_symbol (struct SYMBOL_LIST *symbol)
{
    int error = 0;
    int type = 0;

    debug_print ("%s\n", "");

    while(symbol->data->error != error_table[error].type)
    {
        error++;
    }

    while(symbol->data->type != type_table[type].type)
    {
        type++;
    }

    (void)display_Line (
        "% 6dx %s %s %04X %s\n",
        symbol->data->time,
        error_table[error].string,
        type_table[type].string,
        (unsigned int)symbol->data->value & 0xffff,
        symbol->data->name);
}



static struct SYMBOL_LIST *get_symbol_pointer (char *name)
{
    struct SYMBOL_LIST *symbol = NULL;
    struct SYMBOL_LIST *symbol_found = NULL;

    debug_print ("%s\n", "");

    for (symbol=first_symbol;
         (symbol!=NULL) && (symbol_found == NULL);
         symbol=symbol->next)
    {
        if (strcmp (name, symbol->data->name) == 0)
        {
            symbol_found = symbol;
        }
    }
    return symbol_found;
}



/*
 * Return the symbol pointer
 *   Create the symbol if not found
 */
static struct SYMBOL_LIST *return_symbol_pointer (char *name)
{
    struct SYMBOL_LIST *symbol = NULL;

    debug_print ("%s\n", "");

    symbol = get_symbol_pointer (name);

    if (symbol == NULL)
    {
        symbol = create_symbol (name);
        if (symbol != NULL)
        {
            symbol->next = first_symbol;
            first_symbol = symbol;
        }
    }
    return symbol;
}



/*
 * Put the symbol list in alphabetical order (case non sensitive)
 */
static void put_symbol_list_in_alphabetical_order (void)
{
    int i = 0;
    struct SYMBOL_LIST *symbol1;
    struct SYMBOL_LIST *symbol2;
    struct SYMBOL_DATA *symbol_data;

    debug_print ("%s\n", "");

    for (symbol1 = first_symbol; symbol1 != NULL; symbol1 = symbol1->next)
    {
        for (symbol2 = symbol1; symbol2 != NULL; symbol2 = symbol2->next)
        {
            while((symbol1->data->name[i] != '\0')
               && (symbol2->data->name[i] != '\0')
               && (toupper ((int)symbol1->data->name[i])
                == toupper ((int)symbol2->data->name[i])))
            {
                i++;
            }

            if (toupper ((int)symbol1->data->name[i])
              > toupper ((int)symbol2->data->name[i]))
            {
                symbol_data = symbol1->data;
                symbol1->data = symbol2->data;
                symbol2->data = symbol_data;
            }
        }
    }
}


/* ------------------------------------------------------------------------- */


/*
 * Manage the symbol calls
 *  1. Add eventually the symbol to the list
 *  2. Update eventually the symbol
 *  3. Read the symbol
 */
int symbol_Do (char *name, unsigned short value, int type)
{
    int err = SYMBOL_ERROR_NONE;
    struct SYMBOL_LIST *symbol = NULL;

    symbol = return_symbol_pointer (name);

    debug_print ("name='%s' value=%04x type=%s\n",
                 name,
                 value,
                 type_table[type].string);

    if (symbol == NULL)
    {
        return error_Printf (ERROR_TYPE_FATAL, "not enough memory");
    }

    if (type == SYMBOL_READ)
    {
        if ((symbol->data->flag & SYMBOL_FLAG_DEFINED) == 0)
        {
            err = SYMBOL_ERROR_NOT_DEFINED;

            if (run.pass == PASS1)
            {
                symbol->data->flag |= SYMBOL_FLAG_FORWARD;
            }
        }

        if (run.pass == PASS1)
        {
            symbol->data->time++;
        }

        if ((symbol->data->flag & SYMBOL_FLAG_MULTIPLE) != 0)
        {
            err = SYMBOL_ERROR_MULTIPLY_DEFINED;
        }

        if ((symbol->data->flag & SYMBOL_FLAG_FORWARD) != 0)
        {
            eval.forward = TRUE;
        }
    }
    else
    {
        if ((symbol->data->flag & SYMBOL_FLAG_DEFINED) == 0)
        {
            symbol->data->flag |= SYMBOL_FLAG_DEFINED;

            switch (type)
            {
                case SYMBOL_TYPE_MACRO:
                    symbol->data->flag |= SYMBOL_FLAG_MACRO;
                    break;

                case SYMBOL_TYPE_SET:
                    symbol->data->flag |= SYMBOL_FLAG_SET;
                    break;

                case SYMBOL_TYPE_LABEL:
                    symbol->data->flag |= SYMBOL_FLAG_LABEL;
                    break;

                case SYMBOL_TYPE_ARG:
                    symbol->data->flag |= SYMBOL_FLAG_ARG;
                    break;
            }

            symbol->data->value = value;
        }
        else
        {
            if ((run.pass == PASS2)
             && (scan.lone_symbols_warning == TRUE)
             && (symbol->data->time == 0))
            {
                err = SYMBOL_ERROR_LONE;
            }

            if (symbol->data->value != value)
            {
                if (((symbol->data->flag & SYMBOL_FLAG_SET) != 0)
                 && (type == SYMBOL_TYPE_SET))
                {
                    symbol->data->value = value;
                }
                else
                {
                    symbol->data->flag |= SYMBOL_FLAG_MULTIPLE;
                    err = SYMBOL_ERROR_MULTIPLY_DEFINED;
                }
            }
        }

        if ((run.pass == PASS2) && (err != SYMBOL_ERROR_NONE))
        {
            symbol->data->error = err;
            eval.error = err;
        }
    }

    eval.type = SYMBOL_TYPE_EQU;
    if ((symbol->data->flag & SYMBOL_FLAG_SET) != 0)
    {
        eval.type = SYMBOL_TYPE_SET;
    }
    else
    if ((symbol->data->flag & SYMBOL_FLAG_MACRO) != 0)
    {
        eval.type = SYMBOL_TYPE_MACRO;
    }
    else
    if ((symbol->data->flag & SYMBOL_FLAG_LABEL) != 0)
    {
        eval.type = SYMBOL_TYPE_LABEL;
    }
    else
    if ((symbol->data->flag & SYMBOL_FLAG_ARG) != 0)
    {
        eval.type = SYMBOL_TYPE_ARG;
    }

    eval.operand = symbol->data->value;

    return err;
}



int symbol_DisplayError (char *name, int err)
{
    if (run.pass == PASS2)
    {
        switch (err)
        {
            case SYMBOL_ERROR_NOT_DEFINED:
                (void)error_Printf (ERROR_TYPE_ERROR,
                                    "'%s' is unknown ",
                                    name);
                break;

            case SYMBOL_ERROR_MULTIPLY_DEFINED:
                (void)error_Printf (ERROR_TYPE_ERROR,
                                    "'%s' is defined more than once",
                                    name);
                break;

            case SYMBOL_ERROR_LONE:
                (void)error_Printf (ERROR_TYPE_WARNING,
                                    "the symbol '%s' is lone",
                                    name);
                break;
        }
    }
    return ERR_ERROR;
}



/*
 * Display symbols list
 */
#define SYMBOL_DISPLAY_LIST_LENGTH  40
void symbol_DisplayList (void)
{
    int i = 0;
    int time = 0;
    int nexttime = 0;
    int prevtime = 0;
    struct SYMBOL_LIST *symbol;

    debug_print ("%s\n", "");

    /* count symbols */
    for (symbol=first_symbol; symbol!=NULL; symbol=symbol->next)
    {
        i++;
    }

    /* display symbols count */
    (void)display_Line ("\n%06d Total Symbols\n", i);

    put_symbol_list_in_alphabetical_order ();

    switch (symbol_order)
    {
        case SYMBOL_ORDER_ALPHABETICAL:
            for (symbol=first_symbol; symbol!=NULL; symbol=symbol->next)
            {
                print_symbol (symbol);
            }
            break;

        case SYMBOL_ORDER_ERROR:
            for(i=0; i<3; i++)
            {
                for (symbol=first_symbol; symbol!=NULL; symbol=symbol->next)
                {
                    if (symbol->data->error == error_table[i].type)
                    {
                        print_symbol (symbol);
                    }
                }
            }
            break;

        case SYMBOL_ORDER_TYPE:
            for(i=0; i<5; i++)
            {
                for (symbol=first_symbol; symbol!=NULL; symbol=symbol->next)
                {
                    if (symbol->data->type == type_table[i].type)
                    {
                        print_symbol (symbol);
                    }
                }
            }
            break;

        case SYMBOL_ORDER_TIME:
            do
            {
                prevtime = nexttime;
                nexttime = 0x7fffffff;

                for (symbol=first_symbol; symbol!=NULL; symbol=symbol->next)
                {
                    if ((symbol->data->time > time)
                     && (symbol->data->time < nexttime))
                    {
                        nexttime = symbol->data->time;
                    }

                    if (symbol->data->time == time)
                    {
                        print_symbol (symbol);
                    }
                }
                time = nexttime;
            } while (nexttime != prevtime);
            break;
    }
    display_CR ();
}



/*
 * Set code order
 */
void symbol_SetErrorOrder (void)
{
    symbol_order = SYMBOL_ORDER_ERROR;
}



/*
 * Set type order
 */
void symbol_SetTypeOrder (void)
{
    symbol_order = SYMBOL_ORDER_TYPE;
}



/*
 * Set time order
 */
void symbol_SetTimeOrder (void)
{
    symbol_order = SYMBOL_ORDER_TIME;
}



/*
 * Free symbol list
 */
void symbol_FreeAll (void)
{
    struct SYMBOL_LIST *next_symbol;

    debug_print ("%s\n", "");

    while (first_symbol != NULL)
    {
        if (first_symbol->data != NULL)
        {
            if (first_symbol->data->name != NULL)
            {
                free (first_symbol->data->name);
            }
            free (first_symbol->data);
        }
        next_symbol = first_symbol->next;
        free (first_symbol);
        first_symbol = next_symbol;
    }
}

