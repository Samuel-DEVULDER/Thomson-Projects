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
#include "eval.h"
#include "error.h"
#include "arg.h"
#include "symbol.h"
#include "includ.h"

#define PRIORITY_SIGN     -1
#define PRIORITY_BRACKET  -2
 
struct EVAL_LIST {
    char sign;
    int priority;
    unsigned short operand;
    struct EVAL_LIST *next;
};

struct ALPHA_OPERATOR {
    char name[4];
    char sign;
    int priority;
    int compatibility;
};

/* For NEQ, '|' is randomly choosen since it does not exist in
 * both assembling programs on Thomson. Only for repairing.
 * '.NOT.' is repaired but rejected
 */
const struct ALPHA_OPERATOR alpha_operator[] = {
    { "   " , '<' , 5            , TRUE  },
    { "EQU" , '=' , 1            , TRUE  },
    { "DIV" , '/' , 5            , TRUE  },
    { "AND" , '&' , 4            , TRUE  },
    { "   " , '+' , 2            , TRUE  },
    { "   " , '-' , 2            , TRUE  },
    { "   " , '*' , 5            , TRUE  },
    { "OR"  , '!' , 3            , TRUE  },
    { "NEQ" , '|' , 1            , FALSE },  /* Not MACROASSEMBLER */
    { "NOT" , ':' , PRIORITY_SIGN, FALSE },  /* Rejected !!! */
    { "MOD" , '%' , 5            , FALSE },
    { "XOR" , '^' , 3            , FALSE },
    { ""    , ' ' , 0            , FALSE }
};

struct EVAL eval;
struct EVAL_LIST *eval_list = NULL;



/*
 * Add an evaluation element
 */
static struct EVAL_LIST *
add_eval (char sign, int priority, unsigned short operand)
{
    struct EVAL_LIST *new_eval;

    debug_print ("sign='%c' priority=%d operand=%04x\n",
                 sign, priority, (unsigned int)operand);

    new_eval = malloc (sizeof(struct EVAL_LIST));
    if (new_eval != NULL)
    {
        new_eval->next     = eval_list;
        new_eval->sign     = sign;
        new_eval->priority = priority;
        new_eval->operand  = operand;
        eval_list = new_eval;
    }
    return new_eval;
}



/*
 * Free an evaluation element
 */
void delete_chain (void)
{
    struct EVAL_LIST *eval_next;

    debug_print ("%s\n", "");

    eval_next = eval_list->next;
    free (eval_list);
    eval_list = eval_next;
}



/*
 * Read a numeric value
 */
static int read_numeric_value (void)
{
    int i;
    char c;
    int radix = 10;  /* radix 10 if neither prefix nor suffix */
    char prefix_radix_char = '\0';
    char suffix_radix_char = '\0';
    int prefix_radix = 0;
    int suffix_radix = 0;

    debug_print ("%s\n", "");

    if (arg_Read() == CHAR_SIGN)
    {
        prefix_radix_char = *arg_buf;

        switch (prefix_radix_char)
        {
            case '%':
                prefix_radix = 2;
                break;

            case '@':
                prefix_radix = 8;
                break;

            case '&':
                prefix_radix = 10;
                break;

            case '$':
                prefix_radix = 16;
                break;

            default:
                return error_Printf (ERROR_TYPE_ERROR,
                                     "%s is not a valid prefix radix",
                                     arg_FilteredChar (prefix_radix_char));
        }
        (void)arg_Read();
    }

    /* argument to upper case if ASSEMBLER 1.0 */
    if (scan.soft < SOFT_MACROASSEMBLER)
    {
        arg_Upper (arg_buf);
    }

    /* read suffix radix character */
    if (strlen (arg_buf) > 0)
    {
        suffix_radix_char = arg_buf[strlen (arg_buf) - 1];
    }

    /* check suffix radix character */
    switch (toupper ((int)suffix_radix_char))
    {
        case 'U':
            suffix_radix = 2;
            break;

        case 'Q':
        case 'O':
            suffix_radix = 8;
            break;

        case 'T':
            suffix_radix = 10;
            break;

        case 'H':
            suffix_radix = 16;
            break;
    }

    /* prefix/suffix is valid if at least
     * one of both is defined or they are equal */
    if ((prefix_radix != 0)
     && (suffix_radix != 0)
     && (prefix_radix != suffix_radix))
    {
        return error_Printf (ERROR_TYPE_ERROR,
                             "the prefix radix %s does not match " \
                             "with the suffix radix %s",
                             arg_FilteredChar (prefix_radix_char),
                             arg_FilteredChar (suffix_radix_char));
    }

    if ((prefix_radix != 0) || (suffix_radix != 0))
    {
        radix = prefix_radix | suffix_radix;
    }

    /* no binary radix in ASSEMBLER */
    if ((radix == 2) && (scan.soft < SOFT_MACROASSEMBLER))
    {
        return error_Printf (ERROR_TYPE_ERROR,
                             "ASSEMBLER 1.0 does not support binary " \
                             "numbers");
    }

    /* error if no operand */
    if (((int)strlen(arg_buf)-((suffix_radix != 0) ? 1 : 0)) == 0)
    {
        return error_Printf (ERROR_TYPE_ERROR,
                             "missing information");
    }

    /* read value with radix */
    for (i=0; i<(int)strlen(arg_buf)-((suffix_radix != 0) ? 1 : 0); i++)
    {
        if (isxdigit((int)arg_buf[i]) == 0)
        {
            return error_Printf (ERROR_TYPE_ERROR,
                                 "%s in the expression '%s' is not " \
                                 "a valid digit",
                                 arg_FilteredChar (arg_buf[i]),
                                 arg_buf);
        }

        c = (toupper((int)arg_buf[i]) < 'A') 
                    ? arg_buf[i]-'0'
                    : toupper ((int)arg_buf[i])-'A'+'\xa';
        if (((int)c  & 0xff) >= radix)
        {
            return error_Printf (ERROR_TYPE_ERROR,
                                 "%s in the expression '%s' does " \
                                 "not match with the radix %d",
                                 arg_FilteredChar (arg_buf[i]),
                                 arg_buf,
                                 radix);
        }

        eval.operand = (unsigned short)(((int)eval.operand * radix) + (int)c);
    }
    return NO_ERROR;
}



/*
 * Read the PC value
 */
static void read_pc_value (void)
{
    debug_print ("%s\n", "");

    eval.operand = run.pc;
    run.ptr++;
}



/*
 * Read an alphabetical value
 */
static int read_alpha_value (void)
{
    int i;
    char c;

    debug_print ("%s\n", "");

    eval.operand = 0;

    for (i=0; i<2; i++)
    {
        if (*run.ptr == '\'')
        {
            c = *(++run.ptr);
            if ((i == 1) && (scan.soft < SOFT_MACROASSEMBLER))
            {
                return error_Printf (ERROR_TYPE_ERROR,
                                     "ASSEMBLER 1.0 does not support " \
                                     "double ASCII definitions");
            }

            if (c < '\0')
            {
                return error_Printf (ERROR_TYPE_ERROR,
                                     "%s if not a valid ASCII character",
                                      arg_FilteredChar (c));
            }

            if ((c == '\0') || (c == ' '))
            {
                c = '\xd';
            }

            eval.operand <<= 8;
            eval.operand |= (unsigned short)c & 0xff;
            run.ptr++;
        }
    }
    return NO_ERROR;
}



/*
 * Read a symbol value
 */
static int read_symbol_value (void)
{
    int err = NO_ERROR;

    debug_print ("%s\n", "");

    (void)arg_Read();

    /* argument to upper case if ASSEMBLER 1.0 */
    if (scan.soft < SOFT_MACROASSEMBLER)
    {
        arg_Upper (arg_buf);
    }

    /* read the symbol value */
    err = symbol_Do (arg_buf, 0, SYMBOL_READ);
    if (err != SYMBOL_ERROR_NONE)
    {
        if ((err != SYMBOL_ERROR_MULTIPLY_DEFINED)
         && (err != SYMBOL_ERROR_LONE))
        {
            (void)symbol_DisplayError (arg_buf, err);
        }
        return ERR_ERROR;
    }

    /* check if symbol is not a macro */
    if (eval.type == SYMBOL_TYPE_MACRO)
    {
        eval.operand = 0x0000;
        return error_Printf (ERROR_TYPE_ERROR,
                             "The symbol '%s' is a macro, not a label",
                             arg_buf);
    }
    return NO_ERROR;
}



/*
 * Read an operand value
 */
static int read_value (void)
{
    char sign;

    debug_print ("%s\n", "");

    eval.operand = 0;

    /* record signs and brackets */
    do
    {
        sign = '\0';
        switch (*run.ptr)
        {
            /* special case for ".NOT." */
            case '.':
                if (((char)toupper((int)run.ptr[1]) == 'N')
                 && ((char)toupper((int)run.ptr[2]) == 'O')
                 && ((char)toupper((int)run.ptr[3]) == 'T')
                 && ((char)toupper((int)run.ptr[4]) == '.'))
                {
                    if (scan.soft >= SOFT_MACROASSEMBLER)
                    {
                        return error_Printf (ERROR_TYPE_ERROR,
                             "only ASSEMBLER 1.0 supports the sign " \
                             "'.NOT.'");
                    }
                    sign = ':';
                    if (add_eval (sign, PRIORITY_SIGN, 0) == NULL)
                    {
                        return error_Printf (ERROR_TYPE_FATAL,
                                             "not enough memory");
                    }
                    run.ptr += 5;
                }
                break;

            /* sign */
            case '+':
            case '-':
            case ':':
                sign = *(run.ptr++);
                if ((sign == ':') && (scan.soft < SOFT_MACROASSEMBLER))
                {
                    return error_Printf (ERROR_TYPE_ERROR,
                                         "ASSEMBLER 1.0 does not support " \
                                         "the sign ':'");
                }
                if (add_eval (sign, PRIORITY_SIGN, 0) == NULL)
                {
                    return error_Printf (ERROR_TYPE_FATAL,
                                         "not enough memory");
                }
                break;

            /* round bracket */
            case '(':
                sign = *(run.ptr++);
                if (add_eval  ('\0', PRIORITY_BRACKET, 0) == NULL)
                {
                    return error_Printf (ERROR_TYPE_FATAL,
                                         "not enough memory");
                }
                break;
        }
    } while (sign != '\0');

    /* read a numeric value */
    switch (*run.ptr)
    {
        /* read a numerical value */
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case '&':
        case '@':
        case '%':
        case '$':
            if (read_numeric_value () != NO_ERROR)
            {
                return ERR_ERROR;
            }
            break;

        case '.':    /* read the program counter value */
        case '*':
            read_pc_value ();
            break;

        case '\'':   /* read an ASCII value */
            if (read_alpha_value () != NO_ERROR)
            {
                return ERR_ERROR;
            }
            break;
        
        default:    /* read a symbol value or error */
            /* read a symbol value */
            if (arg_IsAlpha (*run.ptr) == TRUE)
            {
                if (read_symbol_value () != NO_ERROR)
                {
                    return ERR_ERROR;
                }
            }
            else
            {
                /* reading value is not possible */
                return error_Printf (ERROR_TYPE_ERROR,
                                     "expect value after operator, have %s",
                                     arg_FilteredChar(*run.ptr));
            }
            break;
    }
    return NO_ERROR;
}



/*
 * Read an operator
 */
static int read_operator (void)
{
    int i = 0;

    switch (arg_Read())
    {
        case CHAR_SIGN:
            break;

        case CHAR_END:
            return error_Printf (ERROR_TYPE_ERROR,
                                 "no operator, reach end of operand");

        default:
            return error_Printf (ERROR_TYPE_ERROR,
                                 "expected operator, have '%s'",
                                 arg_buf);
    } 

    debug_print ("run.ptr='%s' operator='%s'\n", run.ptr, arg_buf);

    /* read alphabetical operator */
    if (*arg_buf == '.')
    {
        if (scan.soft >= SOFT_MACROASSEMBLER)
        {
            return error_Printf (ERROR_TYPE_ERROR,
                                 "only ASSEMBLER 1.0 supports alphabetical " \
                                 "operators");
        }

        if (arg_Read() != CHAR_ALPHA)
        {
            return error_Printf (ERROR_TYPE_ERROR,
                                 "expected alphabetical char, have '%s'",
                                 arg_buf);
        }

        arg_Upper (arg_buf);
        i = 0;
        while ((alpha_operator[i].name[0] != '\0')
            && (strcmp (alpha_operator[i].name, arg_buf) != 0))
        {
            i++;
        }

        if (alpha_operator[i].name[0] == '\0')
        {
            return error_Printf (ERROR_TYPE_ERROR,
                                 "alphabetical operator '%s' is unknown",
                                 arg_buf);
        }

        if (*run.ptr != '.')
        {
            return error_Printf (ERROR_TYPE_ERROR,
                                 "an alphabetical operator must end with " \
                                 "a '.'");
        }

        eval.sign = alpha_operator[i].sign;
        run.ptr++;
    }
    else
    /* read sign operator */
    {
        i = 0;
        while ((alpha_operator[i].name[0] != '\0')
            && (*arg_buf != alpha_operator[i].sign))
        {
            i++;
        }

        if (alpha_operator[i].name[0] == '\0')
        {
            return error_Printf (ERROR_TYPE_ERROR,
                                 "operator %s is unknown",
                                 arg_FilteredChar (*arg_buf));
        }

        if (*arg_buf == '|')
        {
            return error_Printf (ERROR_TYPE_ERROR,
                                 "ASSEMBLER 1.0 does not support '|' " \
                                 "operator");
        }

        if ((alpha_operator[i].compatibility == FALSE)
         && (scan.soft < SOFT_MACROASSEMBLER))
        {
            return error_Printf (ERROR_TYPE_ERROR,
                                 "ASSEMBLER 1.0 does not support %s " \
                                 "operator",
                                 arg_FilteredChar (*arg_buf));
        }

        eval.sign = *arg_buf;
    }

    /* reject 'NOT' */
    if (eval.sign == ':')
    {
        return error_Printf (ERROR_TYPE_ERROR,
                             "operator ':' is unknown");
    }

    eval.priority = alpha_operator[i].priority;

    return NO_ERROR;
}



/*
 * Calculator
 */
static int calculate (void)
{
    debug_print ("eval_list->sign='%c'\n", eval_list->sign);

    switch (eval_list->sign)
    {
        case '+':
            eval_list->operand += eval.operand;
            break;

        case '-':
            eval_list->operand -= eval.operand;
            break;

        case '&':
            eval_list->operand &= eval.operand;
            break;

        case '!':
            eval_list->operand |= eval.operand;
            break;

        case '^':
            eval_list->operand ^= eval.operand;
            break;

        case '=':
            eval_list->operand = (eval_list->operand == eval.operand)
                                  ? (unsigned short)0xffff
                                  : (unsigned short)0x0000;
            break;

        case '|':
            eval_list->operand = (eval_list->operand != eval.operand)
                                  ? (unsigned short)0xffff
                                  : (unsigned short)0x0000;
            break;

        case '*':
            eval_list->operand *= eval.operand;
            break;

        case '/':
            if (eval.operand == 0)
            {
                return error_Printf (ERROR_TYPE_ERROR, "division by 0");
            }
            else
            {
                eval_list->operand /= eval.operand;
            }
            break;

        case '%':
            if (eval.operand == 0)
            {
                return error_Printf (ERROR_TYPE_ERROR, "division by 0");
            }
            else
            {
                eval_list->operand %= eval.operand;
            }
            break;

        case '<':
            if ((short signed)eval.operand >= 0)
            {
                eval_list->operand <<= eval.operand;
            }
            else
            {
                eval_list->operand >>= (-eval.operand);
            }
            break;
    }
    eval.operand = eval_list->operand;
    return NO_ERROR;
}



/*
 * Evaluation of signs and brackets
 */
static int signs_and_brackets (void)
{
    debug_print ("%s\n", "");

    while (eval_list != NULL)
    {
        /* if sign */
        while ((eval_list != NULL)
            && (eval_list->priority == PRIORITY_SIGN))
        {
            switch (eval_list->sign)
            {
                case '+':
                    break;

                case '-':
                    eval.operand = -eval.operand;
                    break;

                case ':':
                    eval.operand = ~eval.operand;
                    break;
            }
            delete_chain ();
        }

        /* if closed bracket */
        if (*run.ptr != ')')
        {
            return NO_ERROR;
        }

        run.ptr++;

        /* calculate result between brackets */
        while ((eval_list != NULL)
            && (eval_list->priority != PRIORITY_BRACKET))
        {
            if (calculate () != NO_ERROR)
            {
                return ERR_ERROR;
            }
            
            eval.sign = '\0';
            eval.priority = eval_list->priority;
            delete_chain ();
        }
        if (eval_list == NULL)
        {
            return error_Printf (ERROR_TYPE_ERROR,
                                 "no element left in operand");
        }
        else
        {
            delete_chain ();
        }
    }

    return NO_ERROR;
}



/*
 * Evaluation of the operand
 */
static int evaluate_operand (void)
{
    debug_print ("%s\n", "");

    while (TRUE == TRUE)
    {
        /* read operand */
        if (read_value () != NO_ERROR)
        {
            return ERR_ERROR;
        }

        if (signs_and_brackets () != NO_ERROR)
        {
            return ERR_ERROR;
        }

        /* exit if end of operand */
        if ((*run.ptr == '\0')
         || (*run.ptr == ' ')
         || (*run.ptr == ',')
         || (*run.ptr == ']'))
        {
            return NO_ERROR;
        }

        /* read operator */
        if (read_operator () != NO_ERROR)
        {
            return ERR_ERROR;
        }

        /* calculate strong priorities */
        if ((eval_list != NULL)
         && (eval_list->priority >= 0)
         && (eval.priority <= eval_list->priority))
        {
            while ((eval_list != NULL)
                && (eval_list->priority >= 0)
                && (eval.priority <= eval_list->priority))
            {
                if (calculate () != NO_ERROR)
                {
                    return ERR_ERROR;
                }

                delete_chain ();
            }
        }
        if (add_eval (eval.sign, eval.priority, eval.operand) == NULL)
        {
            return error_Printf (ERROR_TYPE_FATAL,
                                 "not enough memory");
        }
    }
    return NO_ERROR;
}


/*
 * Evaluate and close calculation
 */
static int evaluation (void)
{
    debug_print ("%s\n", "");

    if (evaluate_operand () != NO_ERROR)
    {
        return ERR_ERROR;
    }

    /* close calculation */
    while (eval_list != NULL)
    {
        /* error if opened bracket */
        if (eval_list->priority == PRIORITY_BRACKET)
        {
            return error_Printf (ERROR_TYPE_ERROR,
                                 "missing right parenthese");
        }

        /* calculate next */
        if (calculate () != NO_ERROR)
        {
            return ERR_ERROR;
        }
        delete_chain ();
    }

    return NO_ERROR;
}


/* ------------------------------------------------------------------------- */


/*
 * Evaluate the operand
 */
int Eval (void)
{
    int err;

    debug_print ("%s\n", "");

    eval.forward = FALSE;

    err = evaluation ();
    if (err != NO_ERROR)
    {
        eval.operand = 0x0000;
    }

    /* free evaluation list */
    while (eval_list != NULL)
    {
        delete_chain ();
    }

    return err;
}

