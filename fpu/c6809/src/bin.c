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

#include "defs.h"
#include "bin.h"
#include "error.h"
#include "mark.h"


#define BIN_MAX_SIZE  65536 

enum{
    FILE_BIN = 0,
    FILE_LINEAR,
    FILE_HYBRID,
    FILE_DATA
};

struct BIN_FILE {
    int  flag;      /* hunk flag */
    unsigned short size; /* hunk size */
    unsigned short addr; /* hunk address */
    FILE *file;     /* file handler */
    char *buffer;   /* work buffer */
    int  type;      /* binary type */
};

static struct BIN_FILE bin_write = { 0, 0, 0, NULL, NULL, FILE_BIN };
static struct BIN_FILE bin_read = { 0, 0, 0, NULL, NULL, FILE_BIN };
static char write_file_name[TEXT_MAX_SIZE+1];
static char read_file_name[TEXT_MAX_SIZE+1];

struct FETCH_PARAMS fetch;




static void reset_bin_header (void)
{
    bin_write.flag = 0x00;
    bin_write.size = 0x0000;
    bin_write.addr = run.pc;
}



/*
 * Write a binary hunk
 */
static void write_hunk (void)
{
    char header[5];

    if ((bin_write.file != NULL) && (bin_write.buffer != NULL))
    {
        switch (bin_write.type)
        {
            case FILE_BIN:
            case FILE_LINEAR:
            case FILE_HYBRID:
                header[0] = (char)bin_write.flag;
                header[1] = (char)(bin_write.size >> 8);
                header[2] = (char)bin_write.size;
                header[3] = (char)(bin_write.addr >> 8);
                header[4] = (char)bin_write.addr;
                (void)fwrite (header, 1, 5, bin_write.file);
                break;
        }

        if (bin_write.size != 0)
        {
            (void)fwrite (bin_write.buffer,
                          1,
                          (size_t)bin_write.size,
                          bin_write.file);
        }
    }
    reset_bin_header ();
}




static void open_and_alloc (void)
{
    reset_bin_header ();

    bin_write.buffer = malloc (BIN_MAX_SIZE+256);
    if (bin_write.buffer == NULL)
    {
        (void)fclose (bin_write.file);
        bin_write.file = NULL;
        (void)error_Printf (ERROR_TYPE_FATAL, "not enough memory");
    }

    bin_write.file = fopen (write_file_name, "wb");
    if (bin_write.file == NULL)
    {
        (void)error_Printf (ERROR_TYPE_ERROR,
                            "can not open file '%s'",
                            write_file_name);
    }
}


/*
 * Write a char
 */
static void write_char (char c)
{
    static int first = TRUE;

    if ((run.pass == PASS2)
     && (run.locked == 0)
     && (run.opt[OPT_NO] == FALSE))
    {
        if (first == TRUE)
        {
            open_and_alloc ();
            first = FALSE;
        }

        if ((run.pc != (bin_write.addr + bin_write.size))
         || ((bin_write.type == FILE_BIN) && (bin_write.size == 0x0080))
         || (bin_write.size == 0xffff))
        {

            switch (bin_write.type)
            {
                case FILE_DATA :
                case FILE_LINEAR :
                    if (run.pc != (bin_write.addr+bin_write.size))
                    {
                        (void)error_Printf (ERROR_TYPE_WARNING,
                                            "the binary file '%s' is not linear",
                                            write_file_name);
                    }
                    break;
            }
            write_hunk ();
        }

        if (bin_write.buffer != NULL)
        {
            bin_write.buffer[bin_write.size++] = c;
        }
    }
    run.pc++;
    info.size++;
    check[1][1]++;
}



/*
 * Read a char (BIN file)
 */
static int read_BIN_char (void)
{
    size_t size;
    char header[5];
    char bus[1];

    if (bin_read.file == NULL)
    {
        return ERR_END_OF_FILE;
    }

    if (bin_read.size == 0x0000)
    {
        size = fread (header, 1, 5, bin_read.file);
        if (size != 5)
        {
            return error_Printf (ERROR_TYPE_FATAL,
                                 "can not read file '%s'",
                                 read_file_name);
        }

        bin_read.flag =  (int)header[0] & 0xff;
        bin_read.size = (unsigned short)(((int)header[1] & 0xff) << 8);
        bin_read.size |= (unsigned short)((int)header[2] & 0xff);
        bin_read.addr = (unsigned short)(((int)header[3] & 0xff) << 8);
        bin_read.addr |= (unsigned short)((int)header[4] & 0xff);
    }

    if (bin_read.flag != 0xff)
    {
        size = fread (bus, 1, 1, bin_read.file);
        if (size != 1)
        {
            return error_Printf (ERROR_TYPE_FATAL,
                                 "can not read file '%s'",
                                 read_file_name);
        }
        bin_read.size--;
    }
    else
    {
        if (bin_read.size == 0x0000)
        {
            return ERR_END_OF_FILE;
        }
        else
        {
            return error_Printf (ERROR_TYPE_FATAL,
                                 "can not read file '%s'",
                                 read_file_name);
        }
    }

    return (int)bus[0]&0xff;
}



/*
 * Read a char (DATA file)
 */
static int read_DATA_char (void)
{
    size_t size;
    char bus[1];

    if (bin_read.file == NULL)
    {
        return ERR_END_OF_FILE;
    }
  
    size = fread (bus, 1, 1, bin_read.file);
    if (size != 1)
    {
        if (feof (bin_read.file) != 0)
        {
            return ERR_END_OF_FILE;
        }
        else
        {
            return error_Printf (ERROR_TYPE_FATAL,
                                 "can not read file '%s'",
                                 read_file_name);
        }
    }
    return (int)bus[0]&0xff;
}


/* ------------------------------------------------------------------------- */


/*
 * Read the binary fetch (read mode)
 */
int bin_ReadChar (void)
{
    int c = ERR_END_OF_FILE;

    switch (bin_read.type)
    {
        case FILE_BIN:
            c = read_BIN_char ();
            break;

        case FILE_DATA:
            c = read_DATA_char ();
            break;
    }
    return c;
}



/*
 * Close the binary file (read mode)
 */
void bin_ReadClose (void)
{
    if (bin_read.file != NULL)
    {
        (void)fclose (bin_read.file);
        bin_read.file = NULL;
    }
}



/*
 * Open the binary file (read mode)
 */
int bin_ReadOpen (char *file_name, char *extension)
{
    read_file_name[0] = '\0';
    strncat (read_file_name, file_name, TEXT_MAX_SIZE);

    bin_read.file = fopen (file_name, "rb");
    if (bin_read.file == NULL)
    {
        return error_Printf (ERROR_TYPE_FATAL,
                             "can not open file '%s'",
                             read_file_name);
    }

    bin_read.type = (strcmp (extension, "BIN") == 0) ? FILE_BIN : FILE_DATA;
    bin_read.size = 0;
    bin_read.flag = 0;

    return NO_ERROR;
}



/*
 * Flush the binary fetch
 */
void bin_FlushFetch (void)
{
    int i;

    if (fetch.size != 0)
    {
        if (fetch.buf[0] != '\x00')
        {
            write_char ((char)fetch.buf[0]);
        }

        for (i=0; i<(int)fetch.size; i++)
        {
            write_char ((char)fetch.buf[i+1]);
        }
    }
    fetch.size = 0;
    fetch.buf[0] = '\x00';
}



/*
 * Write the binary fetch (write mode)
 */
void bin_WriteChar (char c)
{
    if (fetch.size == 4)
    {
        bin_FlushFetch ();
    }

    fetch.buf[++fetch.size] = c;
}



/*
 * Close the binary file (write mode)
 */
void bin_WriteClose (void)
{
    /* eventually write the current hunk */
    write_hunk ();

    /* eventually write the last block */
    if (bin_write.type != FILE_DATA)
    {
        bin_write.flag = 0xff;
        bin_write.size = 0x0000;
        bin_write.addr = run.exec;
        write_hunk ();
    }

    if (bin_write.buffer != NULL)
    {
        free (bin_write.buffer);
        bin_write.buffer = NULL;
    }

    if (bin_write.file != NULL)
    {
        (void)fclose (bin_write.file);
        bin_write.file = NULL;
    }
}



void bin_InitFetch (void)
{
    fetch.size = 0;
    fetch.buf[0] = '\x00';
}



void bin_WriteOpen (char *file_name)
{
    write_file_name[0] = '\0';
    strncat (write_file_name, file_name, TEXT_MAX_SIZE);
}



/*
 * Set output file as non linear (standard BIN)
 */
void bin_SetNonLinearFile (void)
{
    bin_write.type = FILE_BIN;
}



/*
 * Set output file as linear
 */
void bin_SetLinearFile (void)
{
    bin_write.type = FILE_LINEAR;
}



/*
 * Set output file as data
 */
void bin_SetDataFile (void)
{
    bin_write.type = FILE_DATA;
}



/*
 * Set output file as hybrid
 */
void bin_SetHybridFile (void)
{
    bin_write.type = FILE_HYBRID;
}





