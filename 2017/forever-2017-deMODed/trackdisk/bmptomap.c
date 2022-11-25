/*
 *  Convert a BMP file into a packed Thomson BIN file
 *  Prehisto (c) 2015
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
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <ctype.h>
#include <stdint.h>
#include <math.h>

#ifndef TRUE
#   define TRUE 1
#endif

#ifndef FALSE
#   define FALSE 0
#endif

#ifndef MAX
#   define MAX(a,b)   ((a)>(b)?(a):(b))
#endif

#ifndef MIN
#   define MIN(a,b)   ((a)<(b)?(a):(b))
#endif


#define TEXT_MAX_SIZE 300

#define MAP_WIDTH     40 
#define MAP_HEIGHT    200
#define MAP_SIZE      16000
#define PALETTE_SIZE  16

#define CODE_SHIFT   3
#define SPECIAL_COLOR_MAX  ((1<<CODE_SHIFT)-2)
#define TYPE_SIZE_MAX      (1<<(8-CODE_SHIFT))
#define CODE_MASK          (0xff>>(8-CODE_SHIFT))


enum {
    COMMAND_WRITE = 0,
    COMMAND_FLUSH
};

enum {
    TYPE_EQUAL = 0,
    TYPE_NOT_EQUAL,
    TYPE_END
};


enum {
    GFX_BITMAP16 = 0,
    GFX_40COLUMNS
};

struct LIST {
    unsigned char color;
    int type;
    int counter;
};

static struct LIST list[MAP_HEIGHT+1];
static int special_color[256];
static int color_list[256];

static int flag_gfx_type = GFX_BITMAP16;
static float png_gamma = 1.0;

static FILE *log_file = NULL;

static int map_palette[PALETTE_SIZE];



static void chop (char *str)
{
    int i = (int)strlen(str)-1;

    while ((i >= 0) && (isspace(str[i])))
        str[i--] = '\0';
}


/*
--------------------------------------------------------------------------------
                                     BMP
--------------------------------------------------------------------------------
*/


static int read_le_2 (FILE *file)
{
    int val = 0;
    unsigned char buf[2];
    
    fread (buf, 1, 2, file);
    val = ((int)buf[0]<<8) + (int)buf[1];

    return val;
}



static int read_be_2 (FILE *file)
{
    int val = 0;
    unsigned char buf[2];
    
    fread (buf, 1, 2, file);
    val = ((int)buf[1]<<8) + (int)buf[0];

    return val;
}



static int read_be_4 (FILE *file)
{
    int val = 0;
    unsigned char buf[4];
    
    fread (buf, 1, 4, file);
    val = ((int)buf[3]<<24)
        + ((int)buf[2]<<16)
        + ((int)buf[1]<<8)
        + (int)buf[0];

    return val;
}



static unsigned char *BMP_load_error (char *file_name, char *message)
{
    printf ("*** ERROR Open BMP '%s' : %s\n", file_name, message);
    return NULL;
}




static int BMP_color_convert (int color)
{
    int base = (color & 0xf0) + ((color & 0xf0) >> 4);

    if (((color - base) > (0x11 / 2))
     && (color < 0xf0))
        color += 0x10;

    return (color >> 4) & 0x0f;
}



/*
 * Load a BMP file
 */
static unsigned char *BMP_load (char *file_name)
{
    int i;
    int BitsOffset;
    int HeaderSize;
    int SizeImage;
    int ClrImportant;
    size_t size;
    int color;
    FILE *file = NULL;
    unsigned char *buf = NULL;
 
    file = fopen (file_name, "rb");
    if (file == NULL)
    {
        fclose (file);
        return BMP_load_error (file_name, "Can not open file");
    }

    /* BITMAP_FILE_HEADER */
    read_le_2 (file);    /* Signature */
    read_be_4 (file);    /* bfSize */
    read_be_2 (file);    /* Reserved */
    read_be_2 (file);    /* Reserved */
    BitsOffset = read_be_4 (file); /* bfOffBits */

    /* BITMAP_INFO_HEADER */
    HeaderSize = read_be_4 (file); /* biSize */
    read_be_4 (file);    /* biWidth  */
    read_be_4 (file);    /* biHeight */
    read_be_2 (file);    /* biPlanes */
    read_be_2 (file);    /* biBitCount */
    read_be_4 (file);    /* biCompression */
    SizeImage = read_be_4 (file); /* biSizeImage */
    read_be_4 (file);    /* biXPelsPerMeter */
    read_be_4 (file);    /* biYPelsPerMeter */
    read_be_4 (file);    /* biClrUsed */
    ClrImportant = read_be_4 (file); /* biClrImportant */

    if ((ClrImportant == 0) || (ClrImportant > PALETTE_SIZE))
        ClrImportant = PALETTE_SIZE;

    /* Read and convert color map */
    memset (map_palette, 0x00, sizeof(int)*PALETTE_SIZE);
    fseek (file, (long int)(HeaderSize+0x0e), SEEK_SET);
    for (i=0; i<ClrImportant; i++)
    {
        color = read_be_4 (file);
        map_palette[i] = BMP_color_convert ((color>>16)&0Xff)
                      + (BMP_color_convert ((color>>8)&0xff) << 4)
                      + (BMP_color_convert (color&0xff) << 8);
    }

    /* Read image */
    fseek (file, (long int)BitsOffset, SEEK_SET);
    buf = malloc (SizeImage);
    if (buf == NULL)
    {
        fclose (file);
        return BMP_load_error (file_name, "Not enough memory");
    }
    size = fread (buf, 1, (size_t)SizeImage, file);
    fclose(file);
    if (size != (size_t)SizeImage)
    {
        free (buf);
        return BMP_load_error (file_name, "Can not load bitmap");
    }

    return buf;
}



static void BMP_create_from_png (char *file_name, char *bmp_name)
{
    int width;
    int height;
    char command[TEXT_MAX_SIZE];
    
    switch (flag_gfx_type)
    {
        case GFX_BITMAP16 :
            width = MAP_WIDTH*4;
            height = MAP_HEIGHT;
            break;

        case GFX_40COLUMNS :
            width = MAP_WIDTH*8;
            height = MAP_HEIGHT;
            break;
    }

    command[0] = '\0';
    sprintf (command, "convert " \
                      "%s " \
                      "-quality 100 " \
                      "-scale %d\\!x%d\\! " \
                      "-colors 16 " \
                      "-compress none " \
                      "-gamma %f " \
                      "-type palette " \
                      "BMP3:%s",
                      file_name,
                      width,
                      height,
                      png_gamma,
                      bmp_name);
    system (command);
}



static unsigned char *BMP_load_image (char *file_name)
{
    unsigned char *buf = NULL;
    char bmp_name[TEXT_MAX_SIZE];
    char command[TEXT_MAX_SIZE];

    /* create BMP file */
    bmp_name[0] = '\0';
    sprintf (bmp_name, "%s.bmp", file_name);
    BMP_create_from_png (file_name, bmp_name);
    
    /* Load BMP image */
    buf = BMP_load (bmp_name);

    /* delete BMP file */
    command[0] = '\0';
    sprintf (command, "rm -f %s.bmp", file_name);
//    system (command);

    return buf;
}


/*
--------------------------------------------------------------------------------
                                 COMPRESSION
--------------------------------------------------------------------------------
*/


static void fill_list (unsigned char *buf)
{
    int i = 0;
    int prev;
    int ibuf = 0;

    while (ibuf < MAP_HEIGHT)
    {
        prev = buf[ibuf++];
        list[i].color = prev;
        if (ibuf < MAP_HEIGHT)
        {
            if (buf[ibuf] == prev)
            {
                list[i].type = TYPE_EQUAL;

                list[i].counter = 1;
                while ((ibuf < MAP_HEIGHT)
                    && (buf[ibuf] == prev))
                {
                    list[i].counter++;
                    prev = buf[ibuf++];
                }
                if (list[i].counter>2)
                    color_list[prev] += list[i].counter;
                i++;
            }
            else
            {
                list[i].type = TYPE_NOT_EQUAL;
                list[i].counter = 1;
                while ((ibuf < MAP_HEIGHT)
                    && (buf[ibuf] != prev)
                    && (buf[ibuf] != buf[ibuf+1]))
                {
                    list[i].counter++;
                    prev = buf[ibuf++];
                }
                if (list[i].counter == 1)
                    list[i].type = TYPE_EQUAL;
                i++;
            }
        }
        else
        {
            list[i].type = TYPE_EQUAL;
            list[i].counter = 1;
            i++;
        }
    }
    list[i].type = TYPE_END;
}



static void SpecialColors_get (unsigned char *buf, int size)
{
    int i;
    int color_found;
    int color;

    memset (color_list, 0x00, 256*sizeof(int));

    for (i=0; i<size; i+=MAP_HEIGHT)
    {
        fill_list (buf+i);
    }

    for (i=0; i<256; i++)
    {
        color_found = 0;
        for (color=0; color<256; color++)
        {
            if (color_list[color] > color_list[color_found])
                color_found = color;
        }
        special_color[i] = color_found;
        color_list[color_found] = -1;
    }
}



static void SpecialColors_write (FILE *file, unsigned char *buf, int size)
{
    int i;
    unsigned char data[1];

    SpecialColors_get (buf, size);

    if (log_file != NULL)
        fprintf (log_file, "Special Colors =");

    for (i=0; i<SPECIAL_COLOR_MAX; i++)
    {
        data[0] = special_color[i];
        fwrite (data, 1, 1, file);
        if (log_file != NULL)
            fprintf (log_file, " %02x", special_color[i]);
    }
    if (log_file != NULL)
        fprintf (log_file, "\n");
}



static int SpecialColors_is (unsigned char value)
{
    int i;

    for (i=0; i<SPECIAL_COLOR_MAX; i++)
        if (((int)value&0xff) == special_color[i])
            break;

    return i;
}



static void clean_list (void)
{
    int i;
    int done;

    do
    {
        done = FALSE;
        i = 0;

        while (list[i].type != TYPE_END)
        {
            /* Not equal / Not equal */
            if ((list[i].type == TYPE_NOT_EQUAL)
             && (list[i+1].type == TYPE_NOT_EQUAL))
            {
                list[i].type = TYPE_NOT_EQUAL;
                list[i].counter += list[i+1].counter;
                memmove (&list[i+1],&list[i+2],sizeof(struct LIST)*(MAP_HEIGHT-i-2));
                done = TRUE;
            }

            /* Not equal / Equal / Not equal */

            else
            if ((list[i].type == TYPE_NOT_EQUAL)
             && (list[i+1].type == TYPE_EQUAL)
             && (list[i+2].type == TYPE_NOT_EQUAL)
             && (list[i+1].counter <= 1)
             && ((((list[i].counter+list[i+2].counter)%TYPE_SIZE_MAX)+list[i+1].counter) < TYPE_SIZE_MAX)
             && (SpecialColors_is(list[i+1].color) < SPECIAL_COLOR_MAX))
            {
                list[i].type = TYPE_NOT_EQUAL;
                list[i].counter += list[i+1].counter+list[i+2].counter;

                memmove (&list[i+1],&list[i+3],sizeof(struct LIST)*(MAP_HEIGHT-i-3));
                done = TRUE;
            }
            else
            if ((list[i].type == TYPE_NOT_EQUAL)
             && (list[i+1].type == TYPE_EQUAL)
             && (list[i+2].type == TYPE_NOT_EQUAL)
             && (list[i+1].counter <= 2)
             && ((((list[i].counter+list[i+2].counter)%TYPE_SIZE_MAX)+list[i+1].counter) < TYPE_SIZE_MAX)
             && (SpecialColors_is(list[i+1].color) == SPECIAL_COLOR_MAX))
            {
                list[i].type = TYPE_NOT_EQUAL;
                list[i].counter += list[i+1].counter+list[i+2].counter;
                memmove (&list[i+1],&list[i+3],sizeof(struct LIST)*(MAP_HEIGHT-i-3));
                done = TRUE;
            }
            else

            /* Not equal / Equal */
            
            if ((list[i].type == TYPE_NOT_EQUAL)
             && (list[i+1].type == TYPE_EQUAL)
             && (list[i+1].counter <= 1)
             && (((list[i].counter%TYPE_SIZE_MAX)+list[i+1].counter) < TYPE_SIZE_MAX)
             && (SpecialColors_is(list[i+1].color) < SPECIAL_COLOR_MAX))
            {
                list[i].type = TYPE_NOT_EQUAL;
                list[i].counter += list[i+1].counter;
                memmove (&list[i+1],&list[i+2],sizeof(struct LIST)*(MAP_HEIGHT-i-2));
                done = TRUE;
            }
            else
            if ((list[i].type == TYPE_NOT_EQUAL)
             && (list[i+1].type == TYPE_EQUAL)
             && (list[i+1].counter <= 2)
             && (((list[i].counter%TYPE_SIZE_MAX)+list[i+1].counter) < TYPE_SIZE_MAX)
             && (SpecialColors_is(list[i+1].color) == SPECIAL_COLOR_MAX))
            {
                list[i].type = TYPE_NOT_EQUAL;
                list[i].counter += list[i+1].counter;
                memmove (&list[i+1],&list[i+2],sizeof(struct LIST)*(MAP_HEIGHT-i-2));
                done = TRUE;
            }
            else
            if ((list[i].type == TYPE_EQUAL)
             && (list[i+1].type == TYPE_NOT_EQUAL)
             && (list[i].counter <= 1)
             && (((list[i].counter%TYPE_SIZE_MAX)+list[i+1].counter) < TYPE_SIZE_MAX)
             && (SpecialColors_is(list[i].color) < SPECIAL_COLOR_MAX))
            {
                list[i].type = TYPE_NOT_EQUAL;
                list[i].counter += list[i+1].counter;
                memmove (&list[i+1],&list[i+2],sizeof(struct LIST)*(MAP_HEIGHT-i-2));
                done = TRUE;
            }
            else
            if ((list[i].type == TYPE_EQUAL)
             && (list[i+1].type == TYPE_NOT_EQUAL)
             && (list[i].counter <= 2)
             && (((list[i].counter%TYPE_SIZE_MAX)+list[i+1].counter) < TYPE_SIZE_MAX)
             && (SpecialColors_is(list[i].color) == SPECIAL_COLOR_MAX))
            {
                list[i].type = TYPE_NOT_EQUAL;
                list[i].counter += list[i+1].counter;
                memmove (&list[i+1],&list[i+2],sizeof(struct LIST)*(MAP_HEIGHT-i-2));
                done = TRUE;
            }

            /* Equal / Equal */

            else
            if ((list[i].type == TYPE_EQUAL)
             && (list[i+1].type == TYPE_EQUAL)
             && ((list[i].counter+list[i+1].counter) <= 3)
             && (SpecialColors_is(list[i].color) == SPECIAL_COLOR_MAX)
             && (SpecialColors_is(list[i+1].color) == SPECIAL_COLOR_MAX))
            {
                list[i].type = TYPE_NOT_EQUAL;
                list[i].counter += list[i+1].counter;
                memmove (&list[i+1],&list[i+2],sizeof(struct LIST)*(MAP_HEIGHT-i-2));
                done = TRUE;
            }
            else
            if ((list[i].type == TYPE_EQUAL)
             && (list[i+1].type == TYPE_EQUAL)
             && ((list[i].counter+list[i+1].counter) <= 2)
             && (SpecialColors_is(list[i].color) == SPECIAL_COLOR_MAX)
             && (SpecialColors_is(list[i+1].color) < SPECIAL_COLOR_MAX))
            {
                list[i].type = TYPE_NOT_EQUAL;
                list[i].counter += list[i+1].counter;
                memmove (&list[i+1],&list[i+2],sizeof(struct LIST)*(MAP_HEIGHT-i-2));
                done = TRUE;
            }
            else
            if ((list[i].type == TYPE_EQUAL)
             && (list[i+1].type == TYPE_EQUAL)
             && ((list[i].counter+list[i+1].counter) <= 2)
             && (SpecialColors_is(list[i].color) < SPECIAL_COLOR_MAX)
             && (SpecialColors_is(list[i+1].color) == SPECIAL_COLOR_MAX))
            {
                list[i].type = TYPE_NOT_EQUAL;
                list[i].counter += list[i+1].counter;
                memmove (&list[i+1],&list[i+2],sizeof(struct LIST)*(MAP_HEIGHT-i-2));
                done = TRUE;
            }
            i++;
        }
    } while (done == TRUE);
}


/*
--------------------------------------------------------------------------------
                                     MAP
--------------------------------------------------------------------------------
*/



static void MAP_create_bmp16 (unsigned char *org_buf, unsigned char *dst_buf)
{
    int i = 0;
    int plane;
    int x;
    int y;
    unsigned char *ptr;

    for (plane=0; plane<2; plane++)
    {
        for (x=0; x<MAP_WIDTH; x++)
        {
            for (y=0; y<MAP_HEIGHT; y++)
            {
                ptr = org_buf + MAP_WIDTH*2*(MAP_HEIGHT-1-y) + x*2 + plane;
                dst_buf[i++] = ptr[0];
            }
        }
    }
}



static void MAP_create_40cols (unsigned char *org_buf, unsigned char *dst_buf)
{
    int i = 0;
    int pos;
    int x;
    int y;
    unsigned char *ptr;
    int color_byte;
    int form_byte;
    int color0 = 0;
    int color1 = 0;

    for (x=0; x<MAP_WIDTH; x++)
    {
        for (y=0; y<MAP_HEIGHT; y++)
        {
            ptr = org_buf + MAP_WIDTH*4*(MAP_HEIGHT-1-y) + x*4;
                
            /* define forme byte */
            color0 = -1;
            color1 = (int)(ptr[0] >> 4) & 0x0f;
            form_byte = 0;
            for (pos=0; pos<4; pos++)
            {
                form_byte <<= 1;
                if (((int)(ptr[pos]>>4) & 0x0f) == color1)
                    form_byte |= 1;
                else
                    color0 = (int)(ptr[pos]>>4) & 0x0f;
                  
                form_byte <<= 1;
                if (((int)ptr[pos] & 0x0f) == color1)
                    form_byte |= 1;
                else
                    color0 = (int)ptr[pos] & 0x0f;
            }

            /* define color0 eventually */
            if (color0 == -1)
                color0 = color1;
                
            /* define color byte */
            color_byte = (color0<<4)+color1;

            /* record and next */             
            dst_buf[i] = form_byte;
            dst_buf[i+MAP_SIZE/2] = color_byte;
            i++;
        }
    }
}



static void MAP_optimize_40cols (unsigned char *buf)
{
    int i;
    int curr_color;
    int curr_form;
    int prev_color = (int)buf[MAP_SIZE/2+1]&0xff;
    int prev_form  = (int)buf[0+1]&0xff;
    int inv_color;

    for (i=0; i<(MAP_SIZE/2); i++)
    {
        curr_form = (int)buf[i]&0xff;
        curr_color = (int)buf[i+MAP_SIZE/2]&0xff;
        inv_color = ((curr_color&0xf0)>>4) + ((curr_color&0x0f)<<4);

        if (curr_color != prev_color)
        {
            /* form = 0x00 ; same background color */
            if (((curr_color&0xf0) == (prev_color&0xf0))
             && (curr_form == 0x00))
            {
                buf[i+MAP_SIZE/2] = prev_color;
            }
            else

            /* form = 0xff ; same foreground color */
            if (((curr_color&0x0f) == (prev_color&0x0f))
             && (curr_form == 0xff))
            {
                buf[i+MAP_SIZE/2] = prev_color;
            }
            else

            /* colors inverted */
            if (prev_color == inv_color)
            {
                buf[i] ^= 0xff;
                buf[i+MAP_SIZE/2]= inv_color;
            }
            else

            /* forms inverted */
            if (curr_form == (prev_form^0xff))
            {
                buf[i] ^= 0xff;
                buf[i+MAP_SIZE/2]= inv_color;
            }
            else

            /* if foreground color = background color and same foreground color */
            if (((curr_color&0xf0) == (prev_color&0xf0))
             && (((curr_color>>4)&0x0f) == (curr_color&0xf)))
            {
                buf[i] = prev_form;
            }
        }

        prev_color = curr_color;
        prev_form = curr_color;
    }
}



static void MAP_adjust_40cols (unsigned char *buf)
{
    int i;

    for (i=(MAP_SIZE/2); i<MAP_SIZE; i++)
    {
        buf[i] = (((buf[i]&0xf)<<3)^0x40)+(((~(buf[i]>>4))<<4)&0x80)+((buf[i]>>4)&0x07);
    }
}



static unsigned char *MAP_create (unsigned char *org_buf)
{
    unsigned char *dst_buf = malloc (MAP_SIZE+MAP_HEIGHT);

    if (dst_buf != NULL)
    {
        memset (dst_buf, 0x00, MAP_SIZE);

        switch (flag_gfx_type)
        {
            case GFX_BITMAP16 :
                MAP_create_bmp16 (org_buf, dst_buf);
                break;

            case GFX_40COLUMNS :
                MAP_create_40cols (org_buf, dst_buf);
                MAP_optimize_40cols (dst_buf);
                MAP_adjust_40cols (dst_buf);
                break;
        }
    }
    free (org_buf);

    return dst_buf;
}



static FILE *MAP_write_open (char *file_name)
{
    FILE *file = NULL;
    unsigned char header[5];

    file = fopen (file_name, "wb");
    if (file != NULL)
    {
        header[0] = 0x00;
        header[1] = 0x00;
        header[2] = 0x00;
        header[3] = 0xa0;
        header[4] = 0x00;
        fwrite (header, 1, 5, file);
    }
    else
    {
        printf ("*** Can not open %s\n", file_name);
    }
    return file;
}



static void MAP_write_close (FILE *file, char *file_name)
{
    struct stat st;
    unsigned char header[5];

    header[0] = 0xff;
    header[1] = 0x00;
    header[2] = 0x00;
    header[3] = 0x00;
    header[4] = 0x00;
    fwrite (header, 1, 5, file);
    fclose (file);

    if (stat(file_name, &st) == 0)
    {
        if (log_file != NULL)
            fprintf (log_file, "Size = %d\n", (int)st.st_size);

        /* update BIN size */
        file = fopen (file_name, "rb+");
        fread (&header[0], 1, 1, file);
        header[1] = ((st.st_size-10)>>8)&0xff;
        header[2] = (st.st_size-10)&0xff;
        fwrite (&header[1], 1, 2, file);
        fclose (file);
   }
}



static void MAP_write_column (FILE *file, unsigned char *buf)
{
    int i = 0;
    int l;
    int ibuf = 0;
    int color;
    int code;
    int count;
    unsigned char data[1];

    while (list[i].type != TYPE_END)
    {
        if (list[i].type == TYPE_EQUAL)
        {
            for (; list[i].counter>0; list[i].counter-=TYPE_SIZE_MAX)
            {
                count = MIN (list[i].counter, TYPE_SIZE_MAX);
                if (log_file != NULL)
                    fprintf (log_file, "[%3d] eq %-3d  ", ibuf, count);
                color = SpecialColors_is(list[i].color);
                if (color < SPECIAL_COLOR_MAX)
                {
                    code = ((count-1)<<CODE_SHIFT)+(color+2);
                    if (log_file != NULL)
                        fprintf (log_file, " %02x (%02x)\n", code, (int)buf[ibuf]);
                    data[0] = code;
                    fwrite (data, 1, 1, file);
                }
                else
                {
                    code = ((count-1)<<CODE_SHIFT)+1;
                    if (log_file != NULL)
                        fprintf (log_file, " %02x %02x\n", code, (int)buf[ibuf]);
                    data[0] = code;
                    fwrite (data, 1, 1, file);
                    fwrite (&buf[ibuf], 1, 1, file);
                }
                ibuf += count;
            }
        }
        else
        {
            for (; list[i].counter>0; list[i].counter-=TYPE_SIZE_MAX)
            {
                count = MIN (list[i].counter, TYPE_SIZE_MAX);
                code = ((count-1)<<CODE_SHIFT)+0;
                if (log_file != NULL)
                    fprintf (log_file, "[%3d] ne %-3d  ", ibuf, list[i].counter);
                data[0] = code;
                fwrite (data, 1, 1, file);
                if (log_file != NULL)
                    fprintf (log_file, " %02x", code);
                for (l=0;l<count;l++)
                {
                    if (log_file != NULL)
                        fprintf (log_file, " %02x", (int)buf[ibuf]);
                    fwrite (&buf[ibuf], 1, 1, file);
                    ibuf++;
                }
                if (log_file != NULL)
                    fprintf (log_file, "\n");
            }
        }
        i++;
    }
}



static void MAP_write_plane (FILE *file, unsigned char *buf)
{
    int i;

    for (i=0; i<MAP_WIDTH; i++)
    {
        if (log_file != NULL)
            fprintf (log_file, "----------- Column %d -----------\n", i);
        fill_list(buf);
        clean_list();
        MAP_write_column (file, buf);
        buf += MAP_HEIGHT;
    }
}



static void MAP_write_header (FILE *file, int map_code)
{
    int i;
    unsigned char data[32];

    /* write code */
    data[0] = (unsigned char)(map_code>>8);
    data[1] = (unsigned char)map_code;
    fwrite (data, 1, 2, file);
    if (log_file != NULL)
        fprintf (log_file, "Code = %02x\n", map_code);

    /* write palette */
    if (log_file != NULL)
        fprintf (log_file, "Palette = ");
    for (i=0; i<16; i++)
    {
        data[i*2] = (unsigned char)(map_palette[i]>>8);
        data[i*2+1] = (unsigned char)map_palette[i];
        if (log_file != NULL)
            fprintf (log_file, "%03x ", map_palette[i]);
    }
    fwrite (data, 1, 32, file);
    if (log_file != NULL)
        fprintf (log_file, "\n");
}



static int bmptobin (char *png_name, char *map_name)
{
    FILE *file;
    int code;
    unsigned char *buf;

    buf = BMP_load_image (png_name);
    if (buf == NULL)
    {
        return EXIT_FAILURE;
    }

    buf = MAP_create (buf);
    if (buf == NULL)
    {
        return EXIT_FAILURE;
    }

    file = MAP_write_open (map_name);
    if (file == NULL)
    {
        free (buf);
        return EXIT_FAILURE;
    }

    switch (flag_gfx_type)
    {
        case GFX_BITMAP16:
            code = 0x7b40;
            break;

        case GFX_40COLUMNS:
            code = 0x0000;
            break;
    }

    MAP_write_header (file, code);
    SpecialColors_write (file, buf, MAP_SIZE/2);
    MAP_write_plane (file, buf);
    SpecialColors_write (file, buf+MAP_SIZE/2, MAP_SIZE/2);
    MAP_write_plane (file, buf+MAP_SIZE/2);
    MAP_write_close (file, map_name);

    free (buf);

    return EXIT_SUCCESS;
}



static int info (char *argv[])
{
    printf ("%s - Prehisto (c) 2017\n", argv[0]);
    printf ("    Usage:\n");
    printf ("      %s [options] <PNG_file_name> <BIN_file_name>[ <log_name>]\n", argv[0]);
    printf ("         Options:\n");
    printf ("            --bitmap16  : force conversion in bitmap16\n");
    printf ("            --40columns : force conversion in 40 columns\n");
    printf ("            --gamma x.x : set gamma correction multiplier\n");
    return EXIT_FAILURE;
}



#define MAX_FILE 3
int main (int argc, char *argv[])
{
    int i;
    int err;
    int nfile = 0;
    char file_name[MAX_FILE][TEXT_MAX_SIZE];

    for (i=0; i<MAX_FILE; i++)
        file_name[i][0] = '\0';

    /* Check argument number */
    if (argc < 3)
    {
        return info(argv);
    }
    
    for (i=1; i<argc; i++)
    {
        if (argv[i][0] == '-')
        {
            if (strcmp (argv[i], "--bitmap16") == 0)
            {
                flag_gfx_type = GFX_BITMAP16;
            }
            else
            if (strcmp (argv[i], "--40columns") == 0)
            {
                flag_gfx_type = GFX_40COLUMNS;
            }
            else
            if (strcmp (argv[i], "--gamma") == 0)
            {
                png_gamma = strtof (argv[i+1], NULL);
                i++;
            }
            else
            {
                printf ("*** Options '%s' unknown\n", argv[i]);
                return info(argv);
            }
        }   
        else
        {
            if (nfile < MAX_FILE)
            {
                strcpy(file_name[nfile], argv[i]);
                chop (file_name[nfile]);
            }
            else
            {
                printf ("*** Too many file names (%s)\n", argv[i]);
                return info(argv);
            }
            nfile++;
        }
    }

    for (i=0; i<(MAX_FILE-1); i++)
       if (file_name[i][0] == '\0')
           return info(argv);

    if (file_name[MAX_FILE-1] != '\0')
        log_file = fopen (file_name[MAX_FILE-1], "wb");

    err = bmptobin (file_name[0], file_name[1]);

    if (log_file != NULL)
        fclose (log_file);

    return err;
}

