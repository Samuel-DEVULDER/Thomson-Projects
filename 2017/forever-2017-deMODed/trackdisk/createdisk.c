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
#define DISK_SIZE     (16*256*160)
#define SECTOR_SIZE   256

enum {
    P_BANK = 0,
    P_SECTOR_COUNT,
    P_START_TRACK,
    P_START_SECTOR,
    P_LOAD_ADDRESS0,
    P_LOAD_ADDRESS1,
    P_FIRST_SECTOR_SIZE,
    P_FIRST_SECTOR_POS,
    P_LAST_SECTOR_SIZE,
    P_SIZEOF,
    P_EXEC_ADDRESS0 = P_SIZEOF,
    P_EXEC_ADDRESS1
};

/*
static int raw_to_mfm [256] = {
    0x5455, 0x5495, 0x5425, 0x54a5, 0x5449, 0x5489, 0x5429, 0x54a9,
    0x5452, 0x5492, 0x5422, 0x54a2, 0x544a, 0x548a, 0x542a, 0x54aa,
    0x9454, 0x9494, 0x9424, 0x94a4, 0x9448, 0x9488, 0x9428, 0x94a8,
    0x9452, 0x9492, 0x9422, 0x94a2, 0x944a, 0x948a, 0x942a, 0x94aa,
    0x2455, 0x2495, 0x2425, 0x24a5, 0x2449, 0x2489, 0x2429, 0x24a9,
    0x2452, 0x2492, 0x2422, 0x24a2, 0x244a, 0x248a, 0x242a, 0x24aa,
    0xa454, 0xa494, 0xa424, 0xa4a4, 0xa448, 0xa488, 0xa428, 0xa4a8,
    0xa452, 0xa492, 0xa422, 0xa4a2, 0xa44a, 0xa48a, 0xa42a, 0xa4aa,
    0x4855, 0x4895, 0x4825, 0x48a5, 0x4849, 0x4889, 0x4829, 0x48a9,
    0x4852, 0x4892, 0x4822, 0x48a2, 0x484a, 0x488a, 0x482a, 0x48aa,
    0x8854, 0x8894, 0x8824, 0x88a4, 0x8848, 0x8888, 0x8828, 0x88a8,
    0x8852, 0x8892, 0x8822, 0x88a2, 0x884a, 0x888a, 0x882a, 0x88aa,
    0x2855, 0x2895, 0x2825, 0x28a5, 0x2849, 0x2889, 0x2829, 0x28a9,
    0x2852, 0x2892, 0x2822, 0x28a2, 0x284a, 0x288a, 0x282a, 0x28aa,
    0xa854, 0xa894, 0xa824, 0xa8a4, 0xa848, 0xa888, 0xa828, 0xa8a8,
    0xa852, 0xa892, 0xa822, 0xa8a2, 0xa84a, 0xa88a, 0xa82a, 0xa8aa,
    0x5255, 0x5295, 0x5225, 0x52a5, 0x5249, 0x5289, 0x5229, 0x52a9,
    0x5252, 0x5292, 0x5222, 0x52a2, 0x524a, 0x528a, 0x522a, 0x52aa,
    0x9254, 0x9294, 0x9224, 0x92a4, 0x9248, 0x9288, 0x9228, 0x92a8,
    0x9252, 0x9292, 0x9222, 0x92a2, 0x924a, 0x928a, 0x922a, 0x92aa,
    0x2255, 0x2295, 0x2225, 0x22a5, 0x2249, 0x2289, 0x2229, 0x22a9,
    0x2252, 0x2292, 0x2222, 0x22a2, 0x224a, 0x228a, 0x222a, 0x22aa,
    0xa254, 0xa294, 0xa224, 0xa2a4, 0xa248, 0xa288, 0xa228, 0xa2a8,
    0xa252, 0xa292, 0xa222, 0xa2a2, 0xa24a, 0xa28a, 0xa22a, 0xa2aa,
    0x4a55, 0x4a95, 0x4a25, 0x4aa5, 0x4a49, 0x4a89, 0x4a29, 0x4aa9,
    0x4a52, 0x4a92, 0x4a22, 0x4aa2, 0x4a4a, 0x4a8a, 0x4a2a, 0x4aaa,
    0x8a54, 0x8a94, 0x8a24, 0x8aa4, 0x8a48, 0x8a88, 0x8a28, 0x8aa8,
    0x8a52, 0x8a92, 0x8a22, 0x8aa2, 0x8a4a, 0x8a8a, 0x8a2a, 0x8aaa,
    0x2a55, 0x2a95, 0x2a25, 0x2aa5, 0x2a49, 0x2a89, 0x2a29, 0x2aa9,
    0x2a52, 0x2a92, 0x2a22, 0x2aa2, 0x2a4a, 0x2a8a, 0x2a2a, 0x2aaa,
    0xaa54, 0xaa94, 0xaa24, 0xaaa4, 0xaa48, 0xaa88, 0xaa28, 0xaaa8,
    0xaa52, 0xaa92, 0xaa22, 0xaaa2, 0xaa4a, 0xaa8a, 0xaa2a, 0xaaaa
};
*/

struct ENTRY {
    int  bank;
    char name[TEXT_MAX_SIZE];
    int  exec;
    int  start;
    int  size;
    struct ENTRY *next;
};
struct ENTRY *first_entry = NULL;

static unsigned short int crc ;



static struct ENTRY *find_last_entry (struct ENTRY *entry)
{
    struct ENTRY *last_entry = NULL;

    while (entry != NULL)
    {
        last_entry = entry;
        entry = entry->next;
    }
    return last_entry;
}



static struct ENTRY *append_entry (struct ENTRY *entry, int bank, char *name, int exec)
{
    struct ENTRY *new_entry = NULL;
    struct ENTRY *last_entry = NULL;

    new_entry = malloc (sizeof (struct ENTRY));
    if (new_entry != NULL)
    {
        memset (new_entry, 0x00, sizeof (struct ENTRY));
        strcpy (new_entry->name, name);
        new_entry->bank = bank;
        new_entry->exec = exec;
        
        last_entry = find_last_entry (entry);
        if (last_entry == NULL)
            entry = new_entry;
        else
            last_entry->next = new_entry;
    }
    return entry;
}



static void free_entries (struct ENTRY *entry)
{
    struct ENTRY *next_entry = NULL;

    while (entry != NULL)
    {
        next_entry = entry->next;
        free (entry);
        entry = next_entry;
    }
}



void display_sector (char *buffer, int side, int track, int sector)
{
    int pos = ((((track*2)+side)*16)+sector)*256;
    int x;
    int y;
    
    for (y=0; y<16; y++)
    {
        printf ("%06x ", pos);
        for (x=0; x<16; x++)
        {
            printf (" %02x", (int)buffer[pos++]&0xff);
        }
        printf ("\n");
    }
}



static void chop (char *str)
{
    int i = (int)strlen(str)-1;

    while ((i >= 0) && (isspace((int)str[i])))
        str[i--] = '\0';
}
    


static char *skip_spaces (char *str)
{
    int i = 0;

    while (isspace((int)str[i]))
        str++;
    return str;
}

    

static char *base_name (char *file_name)
{
    char *p;

    if (((p = strrchr (file_name, (int)'\\')) != NULL)
     || ((p = strrchr (file_name, (int)'/')) != NULL))
        p++;
    else
        p = file_name;
    return p;
}



static char *split_extension (char *file_name)
{
    char *extension = file_name + strlen(file_name);

    if (strrchr (base_name(file_name), (int)'.') != NULL)
    {
        extension = strrchr (file_name, (int)'.');
        extension[0] = '\0';
        extension++;
    }
    return extension;
}



/*
 * Get the size of the list
 */
static int get_list_size (char *list_name)
{
    struct stat st;
    int size = 0;
    char string[TEXT_MAX_SIZE+1] = "";
    FILE *list_file;
    char *bin_name;
    FILE *bin_file;
    int bank;
    int exec;
    char *p;

    list_file = fopen (list_name, "rb");
    if (list_file != NULL)
    {
        while (fgets (string, TEXT_MAX_SIZE, list_file) != NULL)
        {
            if (isdigit ((int)string[0]) != 0)
            {
                chop (string);
                bank = strtol (string, &p, 10);
                bin_name = skip_spaces (p);
                
                if (stat(bin_name, &st) == 0)
                {
                    bin_file = fopen (bin_name, "rb");
                    if (bin_file != NULL)
                    {
                        fseek (bin_file, (size_t)st.st_size-2, SEEK_SET);
                        exec = (fgetc(bin_file)&0xff)<<8;
                        exec += fgetc(bin_file)&0xff;
                        size += P_SIZEOF + ((exec == 0) ? 0 : 2);
                        fclose(bin_file);
                        first_entry = append_entry (first_entry, bank, bin_name, exec);
                    }
                    else
                    {
                        printf("**** Can not open '%s'\n", bin_name);
                    }
                }
                else
                {
                    printf("**** Can not open '%s'\n", bin_name);
                }
            }
        }
        fclose (list_file);
    }
    else
    {
        printf("**** Can not open '%s'\n", list_name);
    }
    return size;
}



/*
 * Encode the boot
 */
void encode_boot (char *buffer)
{
    int i;

    /* Encode boot */
    for (i=0; i<127; i++)
        buffer[i] = -buffer[i];

    /* Activate the BASIC2 boot */
    memcpy (&buffer[128-8], "BASIC2\0\x55", 8);

    /* Update checksum */
    for (i=0; i<127; i++)
        buffer[127] -= buffer[i];
}



/*
 * Load a binary Thomson-like file
 */
static char *load_binary_file (struct ENTRY *entry)
{
    int hunk_type = 0;
    int hunk_addr = 0;
    int hunk_size = 0;
    struct stat st;
    FILE *file = NULL;
    char *buf = NULL;

    if (stat(entry->name, &st) == 0)
    {
        buf = malloc ((size_t)st.st_size);
        if (buf != NULL)
        {
            file = fopen (entry->name, "rb");
            if (file != NULL)
            {
                entry->size = 0;
                entry->start = -1;
                while (hunk_type == 0)
                {
                    hunk_type = fgetc(file)&0xff;
                    hunk_size = (fgetc(file)&0xff)<<8;
                    hunk_size += fgetc(file)&0xff;
                    hunk_addr = (fgetc(file)&0xff)<<8;
                    hunk_addr += fgetc(file)&0xff;

                    if (entry->start == -1)
                        entry->start = hunk_addr;

                    if (hunk_size != 0)
                    {
                        fread (buf+entry->size, 1, (size_t)hunk_size, file);
                        entry->size += hunk_size;
                    }
                }

                fclose(file);
            }
        }
    }
    if (file == NULL)
    {
        printf("Can not open '%s'\n", entry->name);
    }

    return buf;
}



static void load_files (char *disk_buffer, char *list_name)
{
    int list_size;
    char *list;
    int pos = 0;
    char *file_buffer;
    int size;
    int number = -1;
    struct ENTRY *entry = NULL;

    list_size = get_list_size(list_name);
    printf ("-------------------------------------"\
            "-------------------------------------\n");
    printf ("%-4s %-5s %-20s %-6s %-4s %-4s %-4s %-7s %s\n",
            "N°",
            "Bank",
            "Name",
            "Size",
            "Addr",
            "End ",
            "Exec",
            " Pos",
            "Occup"
    );
    printf ("-------------------------------------"\
            "-------------------------------------\n");

    for (entry=first_entry; entry!=NULL; entry=entry->next)
    {
        file_buffer = load_binary_file (entry);
        if ((file_buffer != NULL) && (entry->size > 0))
        {
            if ((pos+entry->size) <= DISK_SIZE)
            {
                memmove (disk_buffer+pos, file_buffer, (size_t)entry->size);

                if (entry == first_entry)
                {
                    list = disk_buffer + entry->size;
                    entry->size += list_size;

                    printf (
                        "     %-4d %-20s %-6d %04x %04x      %-7d %d%%\n",
                         entry->bank,
                         base_name(entry->name),
                         entry->size,
                         entry->start,
                         entry->start+entry->size-1,
                         DISK_SIZE-(pos%DISK_SIZE)-entry->size,
                         (((pos%DISK_SIZE)+entry->size)*100)/DISK_SIZE
                    );
                    pos = entry->size;
                    /* update number of loader sectors to load */
                    disk_buffer[128] = ((pos-256)+255)/256;
                }
                else
                {
                    list[P_BANK] = (char)(entry->bank+((entry->exec!=0)?0x80:0x00));
                    list[P_SECTOR_COUNT] = (char)(((pos%256)+entry->size+255)/256);
                    list[P_START_TRACK] = (char)(pos/(16*256));
                    list[P_START_SECTOR] = (char)((pos%(16*256))/256);
                    list[P_LOAD_ADDRESS0] = (char)(entry->start>>8);
                    list[P_LOAD_ADDRESS1] = (char)(entry->start&0xff);
                    size = 256-(pos%256);
                    list[P_FIRST_SECTOR_SIZE] = (char)(MIN(entry->size,size));
                    list[P_FIRST_SECTOR_POS] = (char)(pos%256);
                    list[P_LAST_SECTOR_SIZE] = (char)((pos+entry->size)%256);

                    if (number <= 0)
                    {
                        printf ("    ");
                    }
                    else
                    {
                        printf ("%-4d", number);
                    }

                    printf (
                         " %-4d %-20s %-6d %04x %04x",
                         entry->bank,
                         base_name(entry->name),
                         entry->size,
                         entry->start,
                         entry->start+entry->size-1
                    );
                    if (entry->exec!=0)
                    {
                        printf (" %04x", entry->exec);
                        list[P_EXEC_ADDRESS0] = (char)((entry->exec>>8)&0xff);
                        list[P_EXEC_ADDRESS1] = (char)(entry->exec&0xff);
                        list += (size_t)(P_SIZEOF+2);
                    }
                    else
                    {
                        printf ("     ");
                        list += (size_t)P_SIZEOF;
                    }
                    printf (" %-7d %d%%\n",
                         DISK_SIZE-(pos%DISK_SIZE)-entry->size,
                         (((pos%DISK_SIZE)+entry->size)*100)/DISK_SIZE);

                    pos += entry->size;
                }
                number++;
            }
            else
            {
                printf ("**** File '%s' exceed disk size\n", entry->name);
            }
            free (file_buffer);
        }
    }
    printf ("-------------------------------------"\
            "-------------------------------------\n");

    encode_boot (disk_buffer);
}

#if 0
/*
--------------------------------------------------------------------------
                                    HFE
--------------------------------------------------------------------------
*/

#define GENERIC_SHUGGART_DD_FLOPPYMODE 0x07 
#define HFE_TRACK_SIZE                 0x61b0
#define HFE_SECTOR_SIZE                0x0200

static size_t HFE_write_byte (FILE *file, int value)
{
    char wbuf[1];
    
    wbuf[0] = (char)value;
    return fwrite (wbuf, 1, 1, file);
}



static size_t HFE_write_word (FILE *file, int value)
{
    char wbuf[2];
    
    wbuf[0] = (char)value;
    wbuf[1] = (char)(value>>8);
    return fwrite (wbuf, 1, 2, file);
}



static void HFE_complete_block (FILE *file, size_t size)
{
    while (size < HFE_SECTOR_SIZE)
    {
        size += HFE_write_byte (file, 0xff);
    }
}


static void HFE_write_open (char *file_name)
{
    FILE *file
    size_t size;
    char signature[] = "HXCPICFE";
    
    hfe_buf = malloc ((HFE_TRACK_SIZE+0x1ff)&-0x1ff);
    if (hfe_buf == NULL)
    {
        printf ("**** Not enough memory for '%s'\n", file_name);
        return file;
    }

    file = fopen (file_name, "wb");
    if (file == NULL)
    {
        printf ("**** Can not open '%s'\n", file_name);
        return file;
    }

    memset (hfe_buf, 0xff, HFE_TRACK_SIZE);

    /* "HXCPICFE" 48 58 43 50 49 43 46 45 */
    memcpy (hfe_buf, signature, 8);
    /* Revision 0 00 */
    hfe_buf[8] = 0x00;
    /* Number of track in the file 50 */
    hfe_buf[9] = 0x50;
    /* Number of valid side (Not used by the emulator) 01 */
    hfe_buf[10] = 0x01;
    /* Encoding mode (Not used actually !) 00 */
    hfe_buf[11] = 0x00;
    /* Bitrate in Kbit/s. Ex : 250=250000bits/s FA 00 */
    hfe_buf[12] = 0xfa;
    hfe_buf[13] = 0x00;
    /* Rotation per minute (Not used by the emulator) 00 00 */
    hfe_buf[14] = 0xfa;
    hfe_buf[15] = 0x00;
    size += hfe_write_word (file, 0x0000);
    /* Floppy interface mode. 07 */
    size += HFE_write_byte (file, GENERIC_SHUGGART_DD_FLOPPYMODE);
    /* Free 01 */
    size += HFE_write_byte (file, 0x01);
    /* Offset of the track list LUT in block of 512 bytes 01 00 */
    size += hfe_write_word (file, 0x0001);
    /* The Floppy image are write protected ? FF */
    size += HFE_write_byte (file, 0x00);
    /* 0xFF : Single Step - 0x00 Double Step mode */
    size += HFE_write_byte (file, 0xff);
    /* 0x00 : Use an alternate track_encoding for track 0 Side 0 */
    size += HFE_write_byte (file, 0xff);
    /* alternate track_encoding for track 0 Side 0 */
    size += HFE_write_byte (file, 0xff);
    /* 0x00 : Use an alternate track_encoding for track 0 Side 1 */
    size += HFE_write_byte (file, 0xff);
    /* alternate track_encoding for track 0 Side 1 */
    size += HFE_write_byte (file, 0xff);

    

    size = 0;
    for (i=0; i<80, i++)    
    {
        size += hfe_write_word (file, i*0x0031+0x0002);
        size += hfe_write_word (file, HFE_TRACK_SIZE);
    }

    HFE_complete_block (file, size);

    return file;
}



static int HFE_compute_crc (unsigned char *buffer, int length, int start_value)
{
    int i;
    int crc_high = (start_value >> 8) & 0xff;
    int crc_low  = start_value & 0xff;
    int c;

    for (i=0; i<length; i++)
    {
        c = (crc_high ^ (int)*(buffer++)) & 0xff;
        c ^= (c >> 4);
        crc_low ^= (c >> 3);
        crc_high = ((c << 4) ^ crc_low) & 0xff;
        crc_low = ((c << 5) ^ c) & 0xff;
    }
    return (crc_high << 8) | crc_low;
}



static size_t HFE_write_sector_data (FILE *file, size_t size, int value, int type)
{

    static +
    int last_val = 0xaaaa;

    /* get word value */
    if (type == 0)
    {
        val = raw_to_mfm[value];
    }
    else
    {
        val = MFM_SYNCHRO_WORD;
    }

    /* set first clock bit if necessary */
    if (((last_val & 0x0080) | (val & 0x0200)) == 0)
        val |= 0x0100;

    if (size == 256)
    {
        fseek (file, 256L, SEEK_CUR);
        size = 0;
    }


    return size;
}



static size_t HFE_write_sector_field (FILE *file, int count, size_t size, int value, int type)
{
    while (count > 0)
    {
        size = HFE_write_sector_data  (size, value, type);
    }
    return size;
}



static void HFE_write_sector (FILE *file, int side, int track, int sector)
{
    FILE *file
    size_t size;

    size = 0;

    /* Write info field */
    size = HFE_write_sector_field (file, 32, size, MFM_GAP_DATA_VALUE, 0);
    size = HFE_write_sector_field (file, 12, size, MFM_PRE_SYNC_DATA_VALUE, 0);
    size = HFE_write_sector_field (file, 3, size, MFM_SYNCHRO_DATA_VALUE, 1);
    size = HFE_write_sector_data  (file, size, MFM_INFO_ID, 0);
    size = HFE_write_sector_data  (file, size, track, 0);
    size = HFE_write_sector_data  (file, size, MFM_HEAD_NUMBER, 0);
    size = HFE_write_sector_data  (file, size, sector, 0);
    size = HFE_write_sector_data  (file, size, MFM_SIZE_ID, 0);
    
    crc = HFE_compute_crc (header, 4, MFM_CRC_INFO_INIT);
    size = HFE_write_sector_data  (file, size, crc>>8, 0);
    size = HFE_write_sector_data  (file, size, crc, 0);

    /* Write sector field */
    size = HFE_write_sector_field (file, 22, size, MFM_GAP_DATA_VALUE, 0);
    size = HFE_write_sector_field (file, 12, size, MFM_PRE_SYNC_DATA_VALUE, 0);
    size = HFE_write_sector_field (file, 3, size, MFM_SYNCHRO_DATA_VALUE, 1);
    size = HFE_write_sector_data  (file, size, MFM_SECTOR_ID, 0);
    for (i=0; i<256, i++)
        size = HFE_write_sector_data (file, size, (int)buffer[i], 0);
    crc = HFE_compute_crc (buffer, 256, MFM_CRC_DATA_INIT);
    size = HFE_write_sector_data  (file, size, crc>>8, 0);
    size = HFE_write_sector_data  (file, size, crc, 0);
    size = HFE_write_sector_field (file, 12, size, MFM_GAP_DATA_VALUE, 0);
}

    
    
static void HFE_write_close (FILE *file)
{
    fclose (file);
    free (hfe_buf);
}
#endif

/*
--------------------------------------------------------------------------
                                    SAP
--------------------------------------------------------------------------
*/


static FILE *SAP_write_open (char *file_name)
{
    FILE *file = NULL;
    char sap_string[] = "\1SYSTEME D'ARCHIVAGE PUKALL S.A.P. (c) Alexandre PUKALL Avril 1998";

    file = fopen (file_name, "wb");
    if (file != NULL)
    {
        fwrite (sap_string, 1, strlen (sap_string), file);
    }
    else
    {
        printf ("**** Can not open '%s'\n", file_name);
    }
    return file;
}



/*
 * Compute SAP sector CRC
 */
static void crc_pukall(unsigned short int c)
{
    unsigned short int puktable[] = {
        0x0000, 0x1081, 0x2102, 0x3183,
        0x4204, 0x5285, 0x6306, 0x7387,
        0x8408, 0x9489, 0xa50a, 0xb58b,
        0xc60c, 0xd68d, 0xe70e, 0xf78f
    };
    unsigned short int index;

    index = (crc ^ c) & 0x000f;
    crc = ((crc>>4) & 0x0fff) ^ puktable[index];
    c >>= 4;
    c &= 0x000f;
    index = (crc ^ c) & 0x000f;
    crc = ((crc>>4) & 0x0fff) ^ puktable[index];
}



#define SAP_MAGIC_NUM  0xB3
static void SAP_write_sector (FILE *file, char *buffer, int track, int sector)
{
    int i;
    unsigned char sap_buf[SECTOR_SIZE+6];

    sap_buf[0] = 0;
    sap_buf[1] = 0;
    sap_buf[2] = (unsigned char)track;
    sap_buf[3] = (unsigned char)sector;

    crc = 0xffff;
    crc_pukall ((unsigned short int)sap_buf[0]);
    crc_pukall ((unsigned short int)sap_buf[1]);
    crc_pukall ((unsigned short int)sap_buf[2]);
    crc_pukall ((unsigned short int)sap_buf[3]);
    for (i=0; i<SECTOR_SIZE; i++)
    {
        crc_pukall ((unsigned short int)buffer[i]);
        sap_buf[i+4] = (buffer[i]&0xff) ^ SAP_MAGIC_NUM;
    }
    sap_buf[SECTOR_SIZE+4] = ((crc >> 8) & 0xff);
    sap_buf[SECTOR_SIZE+5] = (crc & 0xff);
    fwrite (sap_buf, 1, SECTOR_SIZE+6, file);
    fflush (file);
}



static void SAP_write_close (FILE *file)
{
    fclose (file);
}


/*
--------------------------------------------------------------------------
                                     FD
--------------------------------------------------------------------------
*/


static FILE *FD_write_open (char *file_name)
{
    FILE *file = NULL;

    file = fopen (file_name, "wb");
    if (file == NULL)
    {
        printf ("**** Can not open '%s'\n", file_name);
    }
    return file;
}



static void FD_write_sector (FILE *file, char *buffer)
{
    fwrite (buffer, 1, SECTOR_SIZE, file);
    fflush (file);
}



static void FD_write_close (FILE *file)
{
    fclose (file);
}


/*
--------------------------------------------------------------------------
*/


/*
 * Create FD disk
 */
static void create_disk (char *buffer, char *file_name)
{
    /* Entrelacement 7 : 01 08 0f 06 0d 04 0b 02 09 10 07 0e 05 0c 03 0a */
    /*         1 sur 2 : 01 0f 0d 0b 09 07 05 03 08 06 04 02 10 0e 0c 0a */
    const uint8_t sector_list[] = {
        0x01, 0x0f, 0x0d, 0x0b,
        0x09, 0x07, 0x05, 0x03,
        0x08, 0x06, 0x04, 0x02,
        0x10, 0x0e, 0x0c, 0x0a
    };

    int side;
    int track;
    int sector;
    int pos;
    int ptr;
    FILE *file;
    char *extension;
    char name[TEXT_MAX_SIZE+1];
    char sap_name[TEXT_MAX_SIZE+1];

    name[0] = '\0';
    sprintf (name, "%s", file_name);
    extension = split_extension (name);

    if (strcmp (extension, "sap") != 0)
    {
        file = FD_write_open (file_name);
    }

    for (side=0; side<2; side++)
    {
        if (strcmp (extension, "sap") == 0)
        {
            sap_name[0] = '\0';
            sprintf (sap_name, "%s_%d.%s", name, side, extension);
            file = SAP_write_open (sap_name);
        }

        if (file != NULL)
        {
            for (track=0; track<80; track++)
            {
                for (sector=1; sector<=16; sector++)
                {
                    pos = 0;
                    while (sector_list[(pos+((track*2)&0x06))&0x0f] != sector)
                        pos++;

                    ptr = ((((track*2)+side)*16)+pos)*256;
                    
                    if (strcmp (extension, "sap") == 0)
                        SAP_write_sector (file, buffer+ptr, track, sector);
                    else
                        FD_write_sector (file, buffer+ptr);
                }
            }
            if (strcmp (extension, "sap") == 0)
                SAP_write_close (file);
        }
    }
    if ((strcmp (extension, "sap") != 0) && (file != NULL))
        FD_write_close (file);
}



static int create (char *list_name, char *fd_name)
{
    char *fd_buffer;

    fd_buffer = malloc (DISK_SIZE);
    if (fd_buffer == NULL)
    {
        (void)printf ("*** Not enough memory\n");
        return EXIT_FAILURE;
    }
    
    memset (fd_buffer, 0x00, DISK_SIZE);
    load_files (fd_buffer, list_name);
    create_disk (fd_buffer, fd_name);
    free (fd_buffer);
    free_entries(first_entry);

    return EXIT_SUCCESS;
}



/*
 * Info
 */
static int info (void)
{
    printf ("create - Prehisto (c) 2017\n");
    printf ("    Usage:\n");
    printf ("      createdisk <list_of_files> <fd_or_sap_disk_name>\n");
    return EXIT_FAILURE;
}



/*
 * Main program
 */
int main(int argc, char *argv[])
{
    char list_name[TEXT_MAX_SIZE+1] = "";
    char disk_name[TEXT_MAX_SIZE+1] = "";

    /* Check argument number */
    if (argc != 3)
    {
        (void)printf ("**** Missing argument\n");
        return info();
    }

    snprintf (list_name, TEXT_MAX_SIZE, "%s", argv[1]);
    chop (list_name);
    snprintf (disk_name, TEXT_MAX_SIZE, "%s", argv[2]);
    chop (disk_name);
    return create (list_name, disk_name);
}

