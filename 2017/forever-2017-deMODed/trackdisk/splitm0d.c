/*
 *  Create trackdisk FD
 *  Prehisto (c) 2017
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
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdint.h>
#include <sys/stat.h>


#ifndef TRUE
#   define TRUE 1
#endif

#ifndef FALSE
#   define FALSE 0
#endif

#ifndef MAX
#   define MAX(a,b)  ((a)>(b)?(a):(b))
#endif

#ifndef MIN
#   define MIN(a,b)  ((a)<(b)?(a):(b))
#endif

#define TEXT_MAX_SIZE 300
#define FILE_SIZE   65536


static char extension[TEXT_MAX_SIZE];



static void chop (char *str)
{
    int i = (int)strlen(str)-1;

    while ((i >= 0) && (isspace(str[i])))
        str[i--] = '\0';
}
    


static void get_extension (char *file_name)
{
    char *p;

    extension[0] = '\0';

    if ((p = strrchr (file_name, (int)'.')) != NULL)
    {
        strcpy (extension, p);
        *p = '\0';
    }
}



static FILE *read_BIN_open (char *file_name)
{
    FILE *file = NULL;
    struct stat st;

    if (stat(file_name, &st) == 0)
    {
        file = fopen (file_name, "rb");
    }

    if (file == NULL)
    {
        printf ("Can not read-open '%s'\n", file_name);
    }
        
    return file;
}



static char *read_BIN_data (FILE *file)
{
    int size;
    char *buf = NULL;
    unsigned char header[5];

    fread (header, 1, 5, file);
    size = (int)((header[1]&0xff)<<8);
    size += (int)(header[2]&0xff);

    buf = malloc ((size_t)(size+5));
    if (buf != NULL)
    {
        memcpy (buf, header, 5);
        if (size > 0)
        {
            fread (buf+5, 1, (size_t)size, file);
        }
    }
    return buf;
}




static void read_BIN_close (FILE *file)
{
    fclose (file);
}




static FILE *write_BIN_open (char *file_name, int addr)
{
    FILE *file = NULL;
    unsigned char header[5];

    file = fopen (file_name, "wb");
    if (file != NULL)
    {
        header[0] = 0x00;
        header[1] = 0x00;
        header[2] = 0x00;
        header[3] = (unsigned char)((addr>>8)&0xff);
        header[4] = (unsigned char)(addr&0xff);
        fwrite (header, 1, 5, file);
    }
    else
    {
        printf ("Can not write-open '%s'\n", file_name);
    }

    return file;
}



static void write_BIN_data (FILE *file, char *buf, int size)
{
    fwrite (buf, 1, (size_t)size, file);
}



static void write_BIN_close (FILE *file, char *file_name, int size)
{
    unsigned char header[5];

    header[0] = 0xff;
    header[1] = 0x00;
    header[2] = 0x00;
    header[3] = 0x00;
    header[4] = 0x00;
    fwrite (header, 1, 5, file);
    fflush (file);
    fclose (file);
    
    header[1] = (unsigned char)((size>>8)&0xff);
    header[2] = (unsigned char)(size&0xff);
    file = fopen (file_name, "rb+");
    if (file != NULL)
    {
        fread (header, 1, 1, file);
        fseek(file, 1L, SEEK_SET);
        fwrite (header+1, 1, 2, file);
        fflush (file);
        fclose (file);
    }
    else
    {
        printf ("Can not write-close '%s'\n", file_name);
    }
}



/*
 * Split a M0D file
 */
static FILE *split_M0D_file (char *M0D_name)
{
    int type = 0;
    int addr = 0;
    int size = 0;
    FILE *file_in = NULL;
    FILE *file_out = NULL;
    char *buf = NULL;
    unsigned char header[5];
    char file_name[TEXT_MAX_SIZE] = "";

    memset (header, 0x00, 5);

    file_name[0] = '\0';
    sprintf (file_name, "%s%s", M0D_name, extension);
    file_in = read_BIN_open (file_name);
    if (file_in != NULL)
    {
        while (type == 0)
        {
            buf = read_BIN_data (file_in);
            if (buf != NULL)
            {
                type = (int)(buf[0]&0xff);
                if (type == 0)
                {
                    size = (int)((buf[1]&0xff)<<8) + (int)(buf[2]&0xff);
                    addr = (int)((buf[3]&0xff)<<8) + (int)(buf[4]&0xff);

                    if ((size != 0) && (addr < 0xe000))
                    {
                        file_name[0] = '\0';
                        sprintf (file_name, "%s_%04X%s", M0D_name, addr, extension);
                        file_out = write_BIN_open (file_name, addr);
                        if (file_out != NULL)
                        {
                            write_BIN_data (file_out, buf+5, size);
                            write_BIN_close (file_out, file_name, size);
                        }
                    }
                }
                free (buf);
            }
        }
        read_BIN_close (file_in);
    }
    return file_in;
}


/*
 * Join M0D files
 */
static FILE *join_M0D_file (char *M0D_name)
{
    FILE *file = NULL;
    char *buf1 = NULL;
    char *buf2 = NULL;
    int size1 = 0;
    int size2 = 0;
    int total_size = 0;
    int addr1 = 0;
    int addr2 = 0;
    char file_name[TEXT_MAX_SIZE] = "";
    char command[TEXT_MAX_SIZE] = "";
    struct stat st;

    file_name[0] = '\0';
    sprintf (file_name, "%s_C000%s", M0D_name, extension);
    if (stat(file_name, &st) == 0)
    {
        /* Read "_C000" file */
        file = read_BIN_open (file_name);
        if (file != NULL)
        {
            buf1 = read_BIN_data (file);
            read_BIN_close (file);
            size1 = (int)((buf1[1]&0xff)<<8) + (int)(buf1[2]&0xff);
            addr1 = (int)((buf1[3]&0xff)<<8) + (int)(buf1[4]&0xff);
            addr1 -= 0xc000;
            command[0] = '\0';
            sprintf (command, "rm -f %s", file_name);
            system (command);
        }
    }
        
    file_name[0] = '\0';
    sprintf (file_name, "%s_A000%s", M0D_name, extension);
    if (stat(file_name, &st) == 0)
    {
        /* Read "_A000" file */
        file = read_BIN_open (file_name);
        if (file != NULL)
        {
            buf2 = read_BIN_data (file);
            read_BIN_close (file);
            size2 = (int)((buf2[1]&0xff)<<8) + (int)(buf2[2]&0xff);
            addr2 = (int)((buf2[3]&0xff)<<8) + (int)(buf2[4]&0xff);
            addr2 -= 0xa000-0x2000;
            command[0] = '\0';
            sprintf (command, "rm -f %s", file_name);
            system (command);
        }
    }

    /* Write output file */
    file = NULL;
    if (size1 > 0)
    {
        file_name[0] = '\0';
        sprintf (file_name, "%s_%04X%s", M0D_name, addr1, extension);
        file = write_BIN_open (file_name, addr1);
        write_BIN_data (file, buf1+5, size1);
        total_size = size1;
    }

    if (size2 > 0)
    {
        if ((size1 > 0) && ((addr1+size1) != addr2))
        {
            write_BIN_close (file, file_name, size1);
            file = NULL;
            total_size = 0;
        }
        if (file == NULL)
        {
            file_name[0] = '\0';
            sprintf (file_name, "%s_%04X%s", M0D_name, addr2, extension);
            file = write_BIN_open (file_name, addr2);
        }
        write_BIN_data (file, buf2+5, size2);
        total_size += size2;
    }
    
    if (file != NULL)
        write_BIN_close (file, file_name, total_size);

    if (buf1 != NULL)
        free (buf1);

    if (buf2 != NULL)
        free (buf2);
    
    return file;
}



static int splitM0D (char *M0D_name)
{
    split_M0D_file (M0D_name);
    join_M0D_file (M0D_name);
    return EXIT_SUCCESS;
}



/*
 * Info
 */
static int info (char *argv[])
{
    printf ("%s - Prehisto (c) 2017\n", argv[0]);
    printf ("    Usage:\n");
    printf ("      %s <file_M0D>\n", argv[0]);
    return EXIT_FAILURE;
}



/*
 * Main program
 */
int main(int argc, char *argv[])
{
    char M0D_name[TEXT_MAX_SIZE+1] = "";

    /* Check argument number */
    if (argc != 2)
    {
        (void)printf ("Missing argument\n");
        return info(argv);
    }

    snprintf (M0D_name, TEXT_MAX_SIZE, "%s", argv[1]);
    chop (M0D_name);
    get_extension (M0D_name);

    return splitM0D (M0D_name);
}

