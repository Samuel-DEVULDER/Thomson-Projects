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
#   include <sys/stat.h>
#endif

#include "defs.h"
#include "opt.h"
#include "macro.h"
#include "source.h"
#include "includ.h"
#include "error.h"
#include "arg.h"
#include "symbol.h"
#include "display.h"
#include "bin.h"
#include "eval.h"
#include "asm.h"
#include "assemble.h"

enum {
    OPTION_HELP = 1,
    OPTION_OPTIMIZE,
    OPTION_SYMBOLS_NONE,
    OPTION_SYMBOLS_BY_ERROR,
    OPTION_SYMBOLS_BY_TYPE,
    OPTION_SYMBOLS_BY_TIME,
    OPTION_LONE_SYMBOLS,
    OPTION_BINARY_NOT_LINEAR,
    OPTION_BINARY_LINEAR,
    OPTION_BINARY_HYBRID,
    OPTION_BINARY_DATA,
    OPTION_SET_VALUE,
    OPTION_CREATE_ASM_FILES,
    OPTION_ASSEMBLER_MO,
    OPTION_ASSEMBLER_TO,
    OPTION_ASSEMBLER_MACRO,
    OPTION_ASSEMBLER_SOFT
};

struct OPTION_LIST {
    char name[40];
    char arg[15];
    int  code;
    char info[72];
};

static const struct OPTION_LIST option_list[24] = {
    { "--help", "", OPTION_HELP, "This help"},

    { "Optimizing:", "", 0, "" },

    { "--optimize", "", OPTION_OPTIMIZE, "Notify the optimizing" },

    { "Symbols", "", 0, "" },

    { "--symbols-none" , "", OPTION_SYMBOLS_NONE,
        "Do not display the symbol list (default)"  },

    { "--symbols-by-error", "", OPTION_SYMBOLS_BY_ERROR,
        "Display the symbol list in error order" },

    { "--symbols-by-type" , "", OPTION_SYMBOLS_BY_TYPE,
        "Display the symbol list in type order"  },

    { "--symbols-by-time" , "", OPTION_SYMBOLS_BY_TIME,
        "Display the symbol list in time order" },

    { "--lone-symbols" , "", OPTION_LONE_SYMBOLS,
        "Display a warning if the symbol is lone"  },

    { "Binary output", "", 0, "" },

    { "--binary-data"  , "", OPTION_BINARY_DATA,
        "Create a simple data binary (default)" },
    { "--binary-not-linear", "", OPTION_BINARY_NOT_LINEAR,
        "Create a non-linear Thomson binary /" \
        "(blocks of 128 bytes maximum)" },
    { "--binary-linear", "", OPTION_BINARY_LINEAR, 
        "Create a linear Thomson binary (one block)"  },
    { "--binary-hybrid", "", OPTION_BINARY_HYBRID,
        "Create an hybrid Thomson binary /" \
        "(blocks of variable size)" },

    { "Argument passing", "", 0, "" },

    { "-d", " label=value", OPTION_SET_VALUE,
        "Set the value of an argument" },

    { "ASM creation (Thomson specific)", "", 0, "" },

    { "--create-asm-files", "", OPTION_CREATE_ASM_FILES,
        "Create the ASM Thomson files" },

    { "Compiler type", "", 0, "" },

    { "--assembler-soft" , "", OPTION_ASSEMBLER_SOFT,
        "Compile without restrictions (default)" },
    { "--assembler-macro", "", OPTION_ASSEMBLER_MACRO,
        "Compile like MACROASSEMBLER (Thomson specific)" },
    { "--assembler-mo", "", OPTION_ASSEMBLER_MO,
        "Compile like ASSEMBLER 1.0 (Thomson MO specific)"  },
    { "--assembler-to", "", OPTION_ASSEMBLER_TO,
        "Compile like ASSEMBLER 1.0 (Thomson TO specific)"  },

    { "", "", 0, "" }   /* end of list */
};

static int create_asm_files = FALSE;

struct RUN run;
struct SCAN scan;



static void chop (char *str)
{
    int i = (int)strlen(str)-1;

    while ((i >= 0) && (isspace((int)str[i])))
    {
        str[i--] = '\0';
    }
}



static char *base_name (char *file_name)
{
    char *p;

    if (((p = strrchr (file_name, '\\')) == NULL)
     && ((p = strrchr (file_name, '/')) == NULL))
    {
        p = file_name-1;
    }

    return p+1;
}



static char *new_extension_name (char *file_name, char *extension)
{
    char *p;
    static char path_name[TEXT_MAX_SIZE+1];

    path_name[0] = '\0';
    strncat (path_name, file_name, TEXT_MAX_SIZE);

    if ((p = strrchr (path_name, '.')) == NULL)
    {
        p = path_name+strlen(path_name);
    }

    p[0] = '\0';
    strcat (p, extension);

    return path_name;
}



/*
 * Display the help
 */
static int help (char *argv[])
{
    int i;
    int pos;
    size_t size;
    char option_info[TEXT_MAX_SIZE+1];
    char *p;

    (void)fprintf (stderr, "\n");
    (void)fprintf (stderr, "%s : Macro/Assembler 6809 compiler\n",
                   base_name(argv[0]));
    (void)fprintf (stderr, "  Francois MOURET (c) %s v 0.90 - may 2017\n",
                   base_name(argv[0]));
    (void)fprintf (stderr, "\n");
    (void)fprintf (stderr, "Usage: %s [options] <source_file>\n",
                   base_name(argv[0]));
    (void)fprintf (stderr, "\n");
    (void)fprintf (stderr, "  Options :\n");
    (void)fprintf (stderr, "\n");
    
    size = 0;
    for (i=0; option_list[i].name[0] != '\0'; i++)
    {
        if (option_list[i].name[0] == '-')
        {
            size = MAX (size, (strlen (option_list[i].name)
                             + strlen (option_list[i].arg) + 4 + 2));
        }
    }
    
    for (i=0; option_list[i].name[0] != '\0'; i++)
    {
        if (option_list[i].name[0] == '-')
        {
            pos = fprintf (stderr,
                           "    %s%s",
                           option_list[i].name,
                           option_list[i].arg);

            option_info[0] = '\0';
            (void)strncat (option_info, option_list[i].info, TEXT_MAX_SIZE);

            p = strtok (option_info, "/");

            while (p != NULL)
            {
                while ((size_t)pos < size)
                    pos += fprintf (stderr, " ");

                pos += fprintf (stderr, "%s\n", p);
                p = strtok (NULL, "/");
                pos = 0;
            }
        }
        else
        {
            (void)fprintf (stderr, "\n  %s :\n", option_list[i].name);
        }
    }
    (void)fprintf (stderr, "\n");
    return EXIT_SUCCESS;
}



static void set_value (char *arg)
{
    int pass;
    char label[ARG_MAX_SIZE+1];
    char my_argv[TEXT_MAX_SIZE+1] = "";

    (void)strncat (my_argv, arg, TEXT_MAX_SIZE);
    chop (my_argv);

    run.ptr = my_argv;
    if (arg_Read () == CHAR_ALPHA)
    {
        label[0] = '\0';
        strcat(label,arg_buf);
        if ((arg_Read () == CHAR_SIGN) && (arg_buf[0] == '='))
        {
            if (Eval() == NO_ERROR)
            {
                pass = run.pass;
                run.pass = PASS1;
                (void)symbol_Do (label, eval.operand, SYMBOL_TYPE_ARG);
                run.pass = pass;
            }
        }
    }
}



/*
 * Display the error and the advice
 */
static int print_advice (char *argv[], char *argument, char *errorstring)
{
    (void)fprintf (stderr, "*** %s : %s\n", argument, errorstring);
    (void)fprintf (stderr, "Type '%s --help' to display help\n",
                   base_name(argv[0]));
    return EXIT_FAILURE;
}



/*
 * Main program
 */
static int assemble (int argc, char *argv[])
{
    int i;
    int found;
    char my_argv[TEXT_MAX_SIZE] = "";
    char file_name[TEXT_MAX_SIZE];
    int argp;

    memset(&run, 0, sizeof(run));
     run.pass = SCANPASS;
    memset(&scan, 0, sizeof(scan));
     scan.opt[OPT_NO] = FALSE;
     scan.opt[OPT_OP] = FALSE;
     scan.opt[OPT_SS] = FALSE;
     scan.opt[OPT_WE] = FALSE;
     scan.opt[OPT_WL] = FALSE;
     scan.opt[OPT_WS] = FALSE;
     scan.soft = SOFT_UPDATE;
     scan.lone_symbols_warning = FALSE;
     bin_SetDataFile ();

    file_name[0] = '\0';

    /* read command line options */
    if (argc < 2)
    {
        return help (argv);
    }

    for (argp=1; argp<argc; argp++)
    {
        my_argv[0] = '\0';
        (void)strncat (my_argv, argv[argp], TEXT_MAX_SIZE);
        chop (my_argv);

        if (my_argv[0] == '-')
        {
            found = FALSE;
            for (i=0; option_list[i].name[0] != '\0'; i++)
            {
                if ((option_list[i].name[0] == '-')
                 && (strcmp (option_list[i].name, my_argv) == 0))
                {
                    found = TRUE;
                    switch (option_list[i].code)
                    {
                        case OPTION_HELP:
                            return help (argv);

                        case OPTION_OPTIMIZE:
                            scan.opt [OPT_OP] = TRUE;
                            break;

                        case OPTION_SYMBOLS_NONE:
                            scan.opt [OPT_WS] = FALSE;
                            break;

                        case OPTION_SYMBOLS_BY_ERROR:
                            symbol_SetErrorOrder ();
                            scan.opt [OPT_WS] = TRUE;
                            break;

                        case OPTION_SYMBOLS_BY_TYPE:
                            symbol_SetTypeOrder ();
                            scan.opt [OPT_WS] = TRUE;
                            break;

                        case OPTION_SYMBOLS_BY_TIME:
                            symbol_SetTimeOrder ();
                            scan.opt [OPT_WS] = TRUE;
                            break;

                        case OPTION_LONE_SYMBOLS:
                            scan.lone_symbols_warning = TRUE;
                            break;

                        case OPTION_BINARY_NOT_LINEAR:
                            bin_SetNonLinearFile ();
                            break;

                        case OPTION_BINARY_LINEAR:
                            bin_SetLinearFile ();
                            break;

                        case OPTION_BINARY_HYBRID:
                            bin_SetHybridFile ();
                            break;

                        case OPTION_BINARY_DATA:
                            bin_SetDataFile ();
                            break;

                        case OPTION_SET_VALUE:
                            set_value (argv[++argp]);
                            break;

                        case OPTION_CREATE_ASM_FILES:
                            create_asm_files = TRUE;
                            break;

                        case OPTION_ASSEMBLER_MO:
                            scan.soft = SOFT_ASSEMBLER_MO;
                            break;

                        case OPTION_ASSEMBLER_TO:
                            scan.soft = SOFT_ASSEMBLER_TO;
                            break;

                        case OPTION_ASSEMBLER_MACRO:
                            scan.soft = SOFT_MACROASSEMBLER;
                            break;

                        case OPTION_ASSEMBLER_SOFT:
                            scan.soft = SOFT_UPDATE;
                            break;

                        default:
                            return print_advice (argv, my_argv,
                                                 "Unknown option");
                    }
                }
            }
            if (found == FALSE)
            {
                return print_advice (argv, my_argv, "Unknown option");
            }
        }
        else
        {
            if (file_name[0] == '\0')
            {
                (void)strncat (file_name, my_argv, TEXT_MAX_SIZE);
            }
            else
            {
                return print_advice  (argv, my_argv, "Too many files");
            }
        }
    }

    /* check file name */
    if (file_name[0] == '\0')
    {
        return print_advice (argv, my_argv, "Missing 6809 assembler file");
    }

    display_Open (new_extension_name (file_name, ".lst"));
    bin_WriteOpen (new_extension_name (file_name, ".BIN"));

    assemble_Source (file_name, "Pass1", PASS1);
    if (error_FatalErrorCode () != NO_ERROR)
    {
        return EXIT_FAILURE;
    }

    assemble_Source (file_name, "Pass2", PASS2);
    if (error_FatalErrorCode () != NO_ERROR)
    {
        return EXIT_FAILURE;
    }
               
    if (scan.opt[OPT_WS] == TRUE)
    {
        symbol_DisplayList ();
    }

    return EXIT_SUCCESS;    
}


/* ------------------------------------------------------------------------- */


int main (int argc, char *argv[])
{
    int err;

    err = assemble (argc, argv);

    if (create_asm_files == TRUE)
    {
        source_CreateAsmFiles ();
    }

    bin_WriteClose ();
    display_Close ();

    symbol_FreeAll ();
    macro_FreeAll ();
    source_FreeAll ();

    return err;
}

