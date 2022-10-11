/*
 *  Create JETPAC disks (FD and SAP)
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
#define DISK_SIZE   (16*256*80)
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

static char fd_name[TEXT_MAX_SIZE];
static FILE *fd_file = NULL;
static char sap_name[TEXT_MAX_SIZE];
static FILE *sap_file = NULL;



static int my_getc (FILE *file)
{
    char buf[1];

    (void)fread (buf, 1, 1, file);
    
    return (int)buf[0]&0xff;
}



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
        return p+1;
    return file_name;
}

static char *truncate(char *txt, int max) 
{
		static char buf[32];
		int i;
		if(max >= sizeof(buf)) max = sizeof(buf)-1;
		for(i=0; i<max && txt[i]; ++i) buf[i] = txt[i];
		buf[i] = 0;
		return buf;
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
                        exec = my_getc (bin_file) << 8;
                        exec += my_getc (bin_file);
                        size += P_SIZEOF + ((exec == 0) ? 0 : 2);
                        fclose(bin_file);
                        first_entry = append_entry (first_entry,
                                                    bank,
                                                    bin_name,
                                                    exec);
                    }
                    else
                    {
                        printf("Can not open '%s'\n", bin_name);
                    }
                }
                else
                {
                    printf("Can not open '%s'\n", bin_name);
                }
            }
        }
        fclose (list_file);
    }
    else
    {
        printf("Can not open '%s'\n", list_name);
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
                    hunk_type = my_getc (file);
                    hunk_size = my_getc (file) << 8;
                    hunk_size += my_getc (file);
                    hunk_addr = my_getc (file) << 8;
                    hunk_addr += my_getc (file);

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



/*
 * Mise à jour des registres
 */
static void load_files (char *disk_buffer, char *list_name)
{
    int list_size;
    char *list = NULL;
    int pos = 0;
    char *file_buffer;
    int size;
    int nentry = 0;
    struct ENTRY *entry = NULL;

    list_size = get_list_size(list_name) - P_SIZEOF;
    printf ("\n");
    
    printf ("----------------------------------------" \
            "----------------------------------------\n");
    printf ("%s %-13s %s %s %s %s %s %s %s %s %-4s %-4s %-6s %-8s%s\n",
            "N°", "Name", "Bk", "Ns", "Tk", "Sc", "Addr", "Ss", "Sp",
            "Sl", "Exec", "End", "Size", "Pos", "Remain %");
    printf ("----------------------------------------" \
            "----------------------------------------\n");

    nentry = 0;
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
                    printf (
                         "   %-13s %02x %8s %04x %8s %-4s %04x %-6d %-8d%6d %d%%\n",
                         truncate(base_name(entry->name),13),
                         entry->bank,
                         "",
                         entry->start,
                         "",
                         "6200",
                         entry->start+entry->size+list_size-1,
                         entry->size,
                         0,
                         DISK_SIZE-(pos%DISK_SIZE)-entry->size,
                         (((pos%DISK_SIZE)+entry->size)*100)/DISK_SIZE
                    );
                    list = disk_buffer + entry->size;
                    pos = entry->size + list_size;
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

                    nentry++;
                    printf ("%02x %-13s ",
                        nentry,
                        truncate(base_name(entry->name),13)
                    );
                    printf ("%02x %02x %02x %02x %02x%02x %02x %02x %02x",
                        list[P_BANK]&0xff,
                        list[P_SECTOR_COUNT]&0xff,
                        list[P_START_TRACK]&0xff,
                        list[P_START_SECTOR]&0xff,
                        list[P_LOAD_ADDRESS0]&0xff,
                        list[P_LOAD_ADDRESS1]&0xff,
                        list[P_FIRST_SECTOR_SIZE]&0xff,
                        list[P_FIRST_SECTOR_POS]&0xff,
                        list[P_LAST_SECTOR_SIZE]&0xff
                    );

                    if (entry->exec!=0)
                    {
                        list[P_EXEC_ADDRESS0] = (char)(entry->exec>>8);
                        list[P_EXEC_ADDRESS1] = (char)(entry->exec&0xff);

                        printf (" %02x%02x", 
                            list[P_EXEC_ADDRESS0]&0xff,
                            list[P_EXEC_ADDRESS1]&0xff
                        );
                        list += (size_t)(P_SIZEOF+2);
                    }
                    else
                    {
                        printf ("     ");
                        list += (size_t)P_SIZEOF;
                    }

                    printf (" %04x %-6d %-8d%6d %d%%\n",
                        entry->start+entry->size-1,
                        entry->size,
                        pos,
                        DISK_SIZE-(pos%DISK_SIZE)-entry->size,
                        (((pos%DISK_SIZE)+entry->size)*100)/DISK_SIZE
                    );

                    pos += entry->size;
                }
            }
            else
            {
                printf ("File '%s' exceed disk size\n", entry->name);
            }
            free (file_buffer);
        }
    }

    printf ("----------------------------------------" \
            "----------------------------------------\n");
    printf ("\n");

    encode_boot (disk_buffer);
}


/* --------------------------------- SAP ---------------------------------- */


static FILE *SAP_write_open (char *file_name)
{
    char sap_string[] = "\1SYSTEME D'ARCHIVAGE PUKALL S.A.P. " \
                        "(c) Alexandre PUKALL Avril 1998";

    sprintf (sap_name, "%s.sap", file_name);
    sap_file = fopen (sap_name, "wb");
    if (sap_file != NULL)
    {
        fwrite (sap_string, 1, strlen (sap_string), sap_file);
    }
    else
    {
        printf ("Can not open '%s'\n", sap_name);
    }
    return sap_file;
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
static void SAP_write_track (char *ptrack, int track)
{
    int i;
    int sector;
    unsigned char sap_buf[SECTOR_SIZE+6];

    for (sector=0; sector<16; sector++)
    {
        sap_buf[0] = 0;
        sap_buf[1] = 0;
        sap_buf[2] = (unsigned char)track;
        sap_buf[3] = (unsigned char)(sector+1);

        crc = 0xffff;
        crc_pukall ((unsigned short int)sap_buf[0]);
        crc_pukall ((unsigned short int)sap_buf[1]);
        crc_pukall ((unsigned short int)sap_buf[2]);
        crc_pukall ((unsigned short int)sap_buf[3]);
        for (i=0; i<SECTOR_SIZE; i++)
        {
            crc_pukall ((unsigned short int)ptrack[sector*256+i]);
            sap_buf[i+4] = (ptrack[sector*256+i]&0xff) ^ SAP_MAGIC_NUM;
        }
        sap_buf[SECTOR_SIZE+4] = ((crc >> 8) & 0xff);
        sap_buf[SECTOR_SIZE+5] = (crc & 0xff);
        fwrite (sap_buf, 1, SECTOR_SIZE+6, sap_file);
    }
    fflush (sap_file);
}



static void SAP_write_close (void)
{
    if (sap_file != NULL)
    {
        fclose (sap_file);
        sap_file = NULL;
    }
}


/* --------------------------------- FD ----------------------------------- */


static FILE *FD_write_open (char *file_name)
{
    sprintf (fd_name, "%s.fd", file_name);
    fd_file = fopen (fd_name, "wb");
    if (fd_file == NULL)
    {
        printf ("**** Can not open '%s'\n", fd_name);
    }
    return fd_file;
}



static void FD_write_track (char *ptrack)
{
    (void)fwrite (ptrack, 1, 256*16, fd_file);
    fflush (fd_file);
}



static void FD_write_close (void)
{
    if (fd_file != NULL)
    {
        fclose (fd_file);
        fd_file = NULL;
    }
}



/*
 * Create disk
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

    int track;
    int sector;
    char *ptrack;
    int nsect;
    int offset;

    ptrack = malloc (256*16);
    if (ptrack != NULL)
    {
        if (FD_write_open (file_name) != NULL)
        {
            if (SAP_write_open (file_name) != NULL)
            {
                for (track=0; track<80; track++)
                {
                    offset = (track*2)&0x06;
                    for (sector=0; sector<16; sector++)
                    {
                        nsect = sector_list[offset]-1;
                        memmove (ptrack+nsect*256, buffer, 256);
                        offset += 1;
                        offset &= 0xf;
                        buffer += 256;
                    }

                    /* include SAP track */
                    SAP_write_track (ptrack, track);

                    /* include FD track */
                    FD_write_track (ptrack);
                }
                SAP_write_close ();
            }
            FD_write_close ();
        }
        free (ptrack);
    }
    else
    {
        printf ("Out of memory\n");
    }
}



static int diskto (char *list_name, char *fd_name)
{
    char *fd_buffer;

    fd_buffer = (char *)malloc (DISK_SIZE);
    if (fd_buffer == NULL)
    {
        (void)printf ("*** Not enough memory\n");
        return EXIT_FAILURE;
    }
    
    memset (fd_buffer, 0xe5, DISK_SIZE);
    load_files (fd_buffer, list_name);
    create_disk (fd_buffer, fd_name);
    free (fd_buffer);
    free_entries(first_entry);

    return EXIT_SUCCESS;
}



/*
 * Info
 */
static int info (char *argv[])
{
    printf ("%s - Prehisto (c) 2019\n", base_name (argv[0]));
    printf ("    Usage:\n");
    printf ("      %s <list_of_files> <disk_name>\n", base_name (argv[0]));
    return EXIT_FAILURE;
}



/*
 * Main program
 */
int main(int argc, char *argv[])
{
    char list_name[TEXT_MAX_SIZE+1] = "";
    char fd_name[TEXT_MAX_SIZE+1] = "";

    /* Check argument number */
    if (argc != 3)
    {
        (void)printf ("Missing argument\n");
        return info(argv);
    }

    snprintf (list_name, TEXT_MAX_SIZE, "%s", argv[1]);
    chop (list_name);
    snprintf (fd_name, TEXT_MAX_SIZE, "%s", argv[2]);
    chop (fd_name);
    return diskto (list_name, fd_name);
}

