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
#include <stdlib.h>
#ifndef S_SPLINT_S
#   include <sys/stat.h>
#endif

#include "defs.h"
#include "source.h"
#include "error.h"
#include "includ.h"
#include "asm.h"
#include "arg.h"
#include "bin.h"
#include "display.h"
#include "encode.h"

#define ASM_MAX_SIZE 29000 /* Maximum size for an ASM file */

struct FILE_DESCRIPTOR {
    char asm_name[13+1];
    char from_name[TEXT_MAX_SIZE+1];
};

static char line_buffer[TEXT_MAX_SIZE+1];

struct SOURCE_LIST *first_from_source = NULL;
struct SOURCE_LIST *main_source = NULL;



static char *skip_space (char *p)
{
    while (((int)*p & 0xff) == 0x20)
    {
        p++;
    }

    return p;
}


/*
 * Get an ASM-style descriptor
 */
static char *
get_asm_descriptor (struct FILE_DESCRIPTOR *fd, char *ptr, char *extension)
{
    int i;

    debug_print ("%s\n", "");

    if (((*ptr >= '0') && (*ptr <= '4'))
     && (*(ptr+1) == ':'))
    {
        strncat (fd->asm_name, ptr, 2);
        ptr += 2;
    }
    else
    {
        strcat (fd->asm_name, "0:");
    }

    for (i=0; i<9; i++)
    {
        if ((((unsigned int)*ptr & 0xff) <= 0x20)
         || (*ptr == '.'))
        {
            break;
        }

        if ((*ptr == '(')
         || (*ptr == ')')
         || (*ptr == ':')
         || (*ptr < '\0'))
        {
            (void)error_Printf (
                ERROR_TYPE_FATAL,
                "%s is an illegal character in a Thomson file name",
                arg_FilteredChar (*ptr));
            return NULL;
        }

        strncat (fd->asm_name, ptr, 1);
        ptr++;
    }

    if ((i > 8) || (i == 0))
    {
        (void)error_Printf (
            ERROR_TYPE_FATAL,
            "the length of a Thomson file name must not exceed 8 characters");
        return NULL;
    }

    strcat (fd->asm_name, ".");

    if (*ptr == '.')
    {
        ptr++;
        for (i=0; i<4; i++)
        {
            if (((unsigned int)*ptr & 0xff) <= 0x20)
            {
                break;
            }

            if ((*ptr == '(')
             || (*ptr == ')')
             || (*ptr == ':')
             || (*ptr == '.')
             || (*ptr < '\0'))
            {
                (void)error_Printf (
                    ERROR_TYPE_FATAL,
                    "%s is an illegal character in a Thomson file name",
                    arg_FilteredChar (*ptr));
                return NULL;
            }

            strncat (fd->asm_name, ptr, 1);
            ptr++;
        }
        if (i > 3)
        {
            (void)error_Printf (
                ERROR_TYPE_FATAL,
                "the length of a Thomson file extension " \
                "must not exceed 3 characters");
            return NULL;
        }
    }
    else
    {
        strcat (fd->asm_name, extension);
    }
    return ptr;
}



/*
 * Get the "from" descriptor
 */
static int get_from_descriptor (struct FILE_DESCRIPTOR *fd, char *ptr)
{
    char *quote;

    debug_print ("%s\n", "");

    ptr++;
    quote = strchr (ptr, (int)'"');

    if (quote == NULL)
    {
        return error_Printf (ERROR_TYPE_FATAL, "missing closing quote");
    }

    strncat (fd->from_name, ptr, (size_t)(quote-ptr));

    return NO_ERROR;
}



/*
 * Read the descriptor
 */
static int
get_descriptor (struct FILE_DESCRIPTOR *fd, char *ptr, char *extension)
{
    int err = NO_ERROR;

    debug_print ("%s\n", "");

    fd->asm_name[0] = '\0';
    fd->from_name[0] = '\0';

    ptr = skip_space (ptr);

    if (*ptr != '"')
    {
        ptr = get_asm_descriptor (fd, ptr, extension);
        if (ptr != NULL)
        {
            ptr = skip_space (ptr);
            if (strncmp (ptr , "from ", 5) == 0)
            {
                ptr = skip_space (ptr+4);
                if (*ptr == '"')
                {
                    err = get_from_descriptor (fd, ptr);
                }
                else
                {
                    err = error_Printf (ERROR_TYPE_FATAL,
                                        "missing opening quote after 'from'");
                }
            }
        }
        else
        {
            err = ERR_ERROR;
        }
    }
    else
    {
        err = get_from_descriptor (fd, ptr);
    }

    return err;
}



/*
 * Search a "(main)" mark in the first loaded file
 */
static struct SOURCE_LIST *load_main_source (struct SOURCE_LIST *from_source)
{
    char *buf;
    int line;
    struct FILE_DESCRIPTOR fd;
    struct SOURCE_LIST *source = NULL;
    struct SOURCE_LIST *found_source = from_source;

    debug_print ("%s\n", "");

    line = 0;
    buf = from_source->buf;

    while ((buf < from_source->end)
        && (strncmp (line_buffer, "(main)", 6) != 0))
    {
        buf = source_GetLine (buf, from_source->end);
        line++;
    }

    if (buf < from_source->end)
    {
        if (get_descriptor (&fd, line_buffer+6, "ASM") == NO_ERROR)
        {
            source = malloc (sizeof (struct SOURCE_LIST));
            if (source != NULL)
            {
                memset (source, 0x00, sizeof (struct SOURCE_LIST));
                source->name = malloc (strlen (fd.asm_name) + 1);
                if (source->name != NULL)
                {
                    source->name[0] = '\0';
                    strcat (source->name, fd.asm_name);
                    source->buf = buf;
                    source->end = from_source->end;
                    source->line = line;
                    source->encoding = from_source->encoding;
                    source->from = from_source;
                    source->from_next = from_source;
                    source->asm_next = from_source->asm_next;
                    from_source->asm_next = source;
                    found_source = source;
                }
                else
                {
                    (void)error_Printf (ERROR_TYPE_FATAL, "not enough memory");
                    free (source);
                }
            }
            else
            {
                (void)error_Printf (ERROR_TYPE_FATAL, "not enough memory");
            }
        }
    }

    return found_source;
}



/*
 * Load the ASM file entirely and return a boolean
 */
static int load_asm_source (struct SOURCE_LIST *source)
{
    int found = FALSE;
    size_t pos;
    struct FILE_DESCRIPTOR fd;

    debug_print ("%s\n", "");

    source->line = 0;
    source->buf = source->from_next->buf;
    while ((source->buf < source->from_next->end) && (found == FALSE))
    {
        source->buf = source_GetLine (source->buf, source->from_next->end);
        source->line++;
        if ((strncmp (line_buffer, "(include)", (pos = 9)) == 0)
         || (strncmp (line_buffer, "(main)", (pos = 6)) == 0))
        {
            if (get_descriptor (&fd, line_buffer+pos, "ASM") == NO_ERROR)
            {
                if (strcmp (fd.asm_name+2, source->name+2) == 0)
                {
                    found = TRUE;
                }
            }
        }
    }

    if (found == FALSE)
    {
        (void)error_Printf (ERROR_TYPE_FATAL,
                            "INCLUD '%s' not found",
                            fd.asm_name+2);
    }

    return found;
}



/*
 * Search the ASM file pointer in the list attached to the FROM list
 * Return NULL if not found
 */
static struct SOURCE_LIST *
asm_source_pointer (struct SOURCE_LIST *from_source, char *asm_name)
{
    struct SOURCE_LIST *source;
    struct SOURCE_LIST *found_source = NULL;

    debug_print ("%s\n", "");

    for (source = from_source->asm_next;
         (source != NULL) && (found_source == NULL);
         source = source->asm_next)
    {
        if (strcmp (source->name+2, asm_name+2) == 0)
        {
            found_source = source;
        }
    }
    return found_source;
}



/*
 * Check if the ASM file name is already in the entire list
 * Generate an error if it is
 */
static int check_duplicate_asm (char *name)
{
    int err = NO_ERROR;
    struct SOURCE_LIST *asm_source;
    struct SOURCE_LIST *from_source;

    debug_print ("%s\n", "");

    for (from_source = first_from_source;
         (from_source != NULL) && (err == NO_ERROR);
         from_source = from_source->from_next)
    {
        for (asm_source = from_source->asm_next;
             (asm_source != NULL) && (err == NO_ERROR);
             asm_source = asm_source->asm_next)
        {
            if (strcmp (asm_source->name+2, name+2) == 0)
            {
                err = error_Printf (ERROR_TYPE_FATAL,
                                    "INCLUD '%s' already exist",
                                    name);
            }
        }
    }
    return err;
}



/*
 * Get the ASM file pointer if it exists
 *  - If the ASM file name already exists, return the pointer
 *  - If the ASM file name does not exist, create a new entry in the list
 */
static struct SOURCE_LIST *
get_asm_pointer (struct SOURCE_LIST *from_source, char *asm_name)
{
    struct SOURCE_LIST *source;
    
    debug_print ("%s\n", "");

    source = asm_source_pointer (from_source, asm_name);
    if (source == NULL)
    {
        if (check_duplicate_asm (asm_name) == NO_ERROR)
        {
            source = malloc (sizeof (struct SOURCE_LIST));
            if (source != NULL)
            {
                memset (source, 0x00, sizeof (struct SOURCE_LIST));
    
                source->name = malloc (strlen (asm_name) + 1);
                if (source->name != NULL)
                {
                    source->name[0] = '\0';
                    strcat (source->name, asm_name);
                    source->end = from_source->end;
                    source->encoding = from_source->encoding;
                    source->from = from_source;
                    source->from_next = from_source;
                    if (load_asm_source (source) == TRUE)
                    {
                        source->asm_next = from_source->asm_next;
                        from_source->asm_next = source;
                    }
                    else
                    {
                        free (source->name);
                        free (source);
                        source = NULL;
                    }
                }
                else
                {
                    (void)error_Printf (ERROR_TYPE_FATAL, "not enough memory");
                    free (source);
                    source = NULL;
                }
            }
            else
            {
                (void)error_Printf (ERROR_TYPE_FATAL, "not enough memory");
                free (source);
            }
        }
    }
    
    return source;
}



/*
 * Load the FROM file entirely and return the pointer for testing
 */
static char *load_from_source (struct SOURCE_LIST *source)
{
    FILE *file;
    struct stat st;
    size_t size;

    debug_print ("%s\n", "");

    if (stat (source->name, &st) >= 0)
    {
        source->buf = malloc ((size_t)st.st_size);
        if (source->buf != NULL)
        {
            file = fopen (source->name, "rb");
            if (file != NULL)
            {
                size = fread (source->buf, 1, (size_t)st.st_size, file);
                source->end = source->buf + size;
                (void)fclose(file);
                if (size != (size_t)st.st_size)
                {
                    free (source->buf);
                    source->buf = NULL;
                    (void)error_Printf (ERROR_TYPE_FATAL,
                                        "can not read file '%s'",
                                        source->name);
                }
            }
            else
            {
                free (source->buf);
                source->buf = NULL;
                (void)error_Printf (ERROR_TYPE_FATAL,
                                    "can not load file '%s'",
                                    source->name);
            }
        }
        else
        {
            (void)error_Printf (ERROR_TYPE_FATAL, "not enough memory");
        }
    }
    else
    {
        (void)error_Printf (ERROR_TYPE_FATAL,
                            "can not read file '%s'",
                            source->name);
    }
    return source->buf;
}



/*
 * Search the FROM file pointer if it exists
 * Return NULL if not found
 */
static struct SOURCE_LIST *from_source_pointer (char *from_name)
{
    struct SOURCE_LIST *source;
    struct SOURCE_LIST *found_source = NULL;
    
    debug_print ("%s\n", "");

    for (source = first_from_source;
         (source != NULL) && (found_source == NULL);
         source = source->from_next)
    {
        if (strcmp (source->name, from_name) == 0)
        {
            found_source = source;
        }
    }

    return found_source;
}



/*
 * Get the FROM file pointer if it exists
 *  - If no FROM file name defined, keep the current one
 *  - If FROM file name defined, create a new entry in the list
 */
static struct SOURCE_LIST *get_from_pointer (struct FILE_DESCRIPTOR *fd)
{
    struct SOURCE_LIST *source;

    debug_print ("%s\n", "");

    if (fd->from_name[0] == '\0')
    {
        return includ_GetFromSource ();
    }

    source = from_source_pointer (fd->from_name);

    if (source == NULL)
    {
        source = malloc (sizeof (struct SOURCE_LIST));
        if (source != NULL)
        {
            memset (source, 0x00, sizeof (struct SOURCE_LIST));

            source->name = malloc (strlen (fd->from_name) + 1);
            if (source->name != NULL)
            {
                source->name[0] = '\0';
                strcat (source->name, fd->from_name);
                source->line = 0;
                source->from = source;
                if (load_from_source (source) != NULL)
                {
                    source->encoding = encode_Get (source->buf, source->end);
                    source->from_next = first_from_source;
                    first_from_source = source;
                }
                else
                {
                    (void)error_Printf (ERROR_TYPE_FATAL, "not enough memory");
                    free (source->name);
                    free (source);
                    source = NULL;
                }
            }
            else
            {
                (void)error_Printf (ERROR_TYPE_FATAL, "not enough memory");
                free (source);
                source = NULL;
            }
        }
        else
        {
            (void)error_Printf (ERROR_TYPE_FATAL, "not enough memory");
        }
    }
    return source;
}



static struct SOURCE_LIST *load_source (struct FILE_DESCRIPTOR *fd, int flag)
{
    struct SOURCE_LIST *source;

    debug_print ("%s\n", "");

    /* get from_source pointer */
    source = get_from_pointer (fd);
    
    if (source != NULL)
    {
        if (flag == SOURCE_TYPE_MAIN)
        {
            /* get main_source pointer from from_source pointer */
            if ((main_source == NULL)
             && (run.pass == PASS1))
            {
                main_source = load_main_source (source);
            }
            source = main_source;
        }
        else
        if (fd->asm_name[0] != '\0')
        {
            /* get asm_source pointer from from_source pointer */
            source = get_asm_pointer (source, fd->asm_name);
        }
    }
    return source;
}


/* ------------------------------------------------------------------------- */


/*
 * Get current line
 */
char *source_GetLine (char *buf, char *end)
{
    int i = 0;
    int space = 0;

    while ((buf < end)
        && (i < TEXT_MAX_SIZE)
        && (*buf != '\0')
        && (*buf != '\xa')
        && (*buf != '\xd'))
    {
        switch (*buf)
        {
            case ' ':
                space++;
                break;

            case '\x9':
                space += 7-(i%7);
                break;

            default:
                while ((space > 0) && (i < TEXT_MAX_SIZE))
                {
                    line_buffer[i++] = ' ';
                    space--;
                }
                line_buffer[i++] = *buf;
                break;
        }
        buf++;
    }
    line_buffer[i++] = '\0';

    /* reach end of line */
    while ((buf < end)
        && (*buf != '\0')
        && (*buf != '\xa')
        && (*buf != '\xd'))
    {
        buf++;
    }

    /* skip end of line characters */
    if (buf < end)
    {
        switch (*buf)
        {
            case '\xa':
                if (*(buf+1) == '\xd')
                    buf++;
                break;

            case '\xd':
                if (*(buf+1) == '\xa')
                    buf++;
                break;
        }
        buf++;
    }

    debug_print ("\n\nline='%s'\n\n", line_buffer);

    return buf;
}



char *source_LinePointer (void)
{
    return line_buffer;
}



int source_Encoding (void)
{
    struct SOURCE_LIST *source;

    source = includ_GetFromSource ();

    return source->encoding;
}



/*
 * Load the first file
 */
struct SOURCE_LIST *source_FirstLoad (char *file_name)
{
    struct FILE_DESCRIPTOR fd;
    struct SOURCE_LIST *source = NULL;

    debug_print ("file_name='%s'\n", file_name);

    fd.asm_name[0] = '\0';
    fd.from_name[0] = '\0';
    strcat (fd.from_name, file_name);

    source = load_source (&fd, SOURCE_TYPE_MAIN);

    return source;
}



/*
 * Load an INCLUD
 */
struct SOURCE_LIST *source_IncludLoad (void)
{
    struct FILE_DESCRIPTOR fd;
    struct SOURCE_LIST *source = NULL;

    debug_print ("%s\n", "");

    if (get_descriptor (&fd, run.ptr, "ASM") == NO_ERROR)
    {
        source = load_source (&fd, SOURCE_TYPE_ASM);
    }
    return source;
}



/*
 * Open a DAT or BIN file
 */
int source_OpenBin (char *extension)
{
    int err;
    struct FILE_DESCRIPTOR fd;

    debug_print ("extension='%s'\n", extension);

    err = get_descriptor (&fd, run.ptr, extension); 
    if (err == NO_ERROR)
    {
        err = bin_ReadOpen (fd.from_name, extension);
    }

    return err;
}



/*
 * Create the ASM files if resquested
 */
void source_CreateAsmFiles (void)
{
    struct SOURCE_LIST *asm_source;
    struct SOURCE_LIST *from_source;
    int size;
    char *buf;

    debug_print ("%s\n", "");

    for (from_source = first_from_source;
         from_source != NULL;
         from_source = from_source->from_next)
    {
        for (asm_source = from_source->asm_next;
             asm_source != NULL;
             asm_source = asm_source->asm_next)
        {
            asm_Open (asm_source->name+2);
            buf = asm_source->buf;
            while (buf < asm_source->end)
            {
                buf = source_GetLine (buf, asm_source->end);
                if ((strncmp (line_buffer, "(include)", 9) == 0)
                 || (strncmp (line_buffer, "(main)", 6) == 0))
                {
                    break;
                }

                asm_WriteLine (line_buffer);
            }
            size = asm_Close ();

            /* check if ASM file can be loaded In ASSEMBLER/MACROASSEMBLER */
            if (size > (ASM_MAX_SIZE-1000))
            {
                (void)display_Error (
                    "%s:'%s': ASM creation warning: file could " \
                    "be too long (%d bytes) to be loaded from " \
                    "ASSEMBLER or MACROASSEMBLER\n",
                    from_source->name,
                    asm_source->name,
                    size);
            }
        }
    }
}



/*
 * Free source ressources
 */
void source_FreeAll (void)
{
    struct SOURCE_LIST *from_source;
    struct SOURCE_LIST *asm_source;

    debug_print ("%s\n", "");

    /* free source memory */
    while ((from_source = first_from_source) != NULL)
    {
        while ((asm_source = first_from_source->asm_next) != NULL)
        {
            first_from_source->asm_next = first_from_source->asm_next->asm_next;
            free (asm_source->name);
            free (asm_source);
        }
        first_from_source = first_from_source->from_next;
        free (from_source->name);
        free (from_source);
    }
}

