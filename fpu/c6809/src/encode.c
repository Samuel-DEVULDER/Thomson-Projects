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

#include "defs.h"
#include "source.h"

#define CHAR_TYPE_CODE    (0<<24)
#define CHAR_TYPE_OFFSET  (1<<24)
#define CHAR_TYPE_ERROR   (2<<24)
#define CHAR_TYPE_MASK    (CHAR_TYPE_CODE|CHAR_TYPE_OFFSET|CHAR_TYPE_ERROR)

enum {
    ENCODING_ISO_8859_1 = 1,
    ENCODING_MAC_ROMAN,
    ENCODING_UTF8
};

struct ENCODING_TABLE {
    int  iso_8859_1;  /* windows */
    int  cp_850;      /* ms-dos */
    int  mac_roman;   /* MacRoman */
    int  utf8;        /* unix */
    int  asm_code;    /* thomson assembler code */
    char acc[3];      /* thomson accent code */
};

static const struct ENCODING_TABLE encoding_table[] = {
    { 0x7f, 0xdb, 0x7f, 0xe29688, 0x7f, "\x7f"   },  /* CHR$(127) */
    { 0xa0, 0xff, 0xca, 0xc2a0  , 0x7f, "?"      },  /* non-breaking space */
    { 0xa1, 0xad, 0xc1, 0xc2a1  , 0   , "?"      },  /* inverted exclamation */
    { 0xa2, 0xbd, 0xa2, 0xc2a2  , 0   , "?"      },  /* cent */
    { 0xa3, 0x9c, 0xa3, 0xc2a3  , 0   , "?"      },  /* pound sign */
    { 0xa4, 0xcf, 0xdb, 0xc2a4  , 0   , "?"      },  /* currency */
    { 0xa5, 0xbe, 0xb4, 0xc2a5  , 0   , "?"      },  /* yen */
    { 0xa6, 0xdd, 0   , 0xc2a6  , 0   , "?"      },  /* broken bar */
    { 0xa7, 0xf5, 0xa4, 0xc2a7  , 0   , "?"      },  /* section sign */
    { 0xa8, 0xf9, 0xac, 0xc2a8  , 0   , "?"      },  /* trema */
    { 0xa9, 0xb8, 0xa9, 0xc2a9  , 0   , "?"      },  /* copyright */
    { 0xaa, 0xa6, 0xbb, 0xc2aa  , 0   , "?"      },  /* a superscript */
    { 0xab, 0xae, 0xc7, 0xc2ab  , 0   , "?"      },  /* opening guillemet */
    { 0xac, 0xaa, 0xc2, 0xc2ac  , 0   , "?"      },  /* negation */
    { 0xad, 0xc4, 0xd1, 0xc2ad  , 0   , "?"      },  /* soft hyphen */
    { 0xae, 0xa9, 0xa8, 0xc2ae  , 0   , "?"      },  /* registered trademark */
    { 0xaf, 0xee, 0   , 0xc2af  , 0   , "?"      },  /* macron */
    { 0xb0, 0xf8, 0xa1, 0xc2b0  , 0   , "?"      },  /* degree */
    { 0xb1, 0xf1, 0xb1, 0xc2b1  , 0   , "?"      },  /* plus-minus sign */
    { 0xb2, 0xfd, 0   , 0xc2b2  , 0   , "?"      },  /* square */
    { 0xb3, 0xfc, 0   , 0xc2b3  , 0   , "?"      },  /* cube */
    { 0xb4, 0xef, 0xd5, 0xc2b4  , 0   , "?"      },  /* acute accent */
    { 0xb5, 0xe6, 0xb5, 0xc2b5  , 0   , "?"      },  /* micro sign */
    { 0xb6, 0xf4, 0xa6, 0xc2b6  , 0   , "?"      },  /* pilcrow */
    { 0xb7, 0xfa, 0xe1, 0xc2b7  , 0   , "?"      },  /* interpunct */
    { 0xb8, 0xf7, 0xfc, 0xc2b8  , 0   , "?"      },  /* cedilla */
    { 0xb9, 0xfb, 0   , 0xc2b9  , 0   , "?"      },  /* unicode superscript */
    { 0xba, 0xa7, 0xbc, 0xc2ba  , 0   , "?"      },  /* ordinal director */
    { 0xbb, 0xaf, 0xc8, 0xc2bb  , 0   , "?"      },  /* closing guillemet */
    { 0xbc, 0xac, 0   , 0xc2bc  , 0   , "?"      },  /* 1/4 */
    { 0xbd, 0xab, 0   , 0xc2bd  , 0   , "?"      },  /* 1/2 */
    { 0xbe, 0xf3, 0   , 0xc2be  , 0   , "?"      },  /* 3/4 */
    { 0xbf, 0xa8, 0xc0, 0xc2bf  , 0   , "?"      },  /* inverted question */
    { 0xc0, 0xb7, 0xcb, 0xc380  , 0   , "?"      },  /* A grave */
    { 0xc1, 0xb5, 0xe7, 0xc381  , 0   , "?"      },  /* A acute */
    { 0xc2, 0xb6, 0xe5, 0xc382  , 0   , "?"      },  /* A circumflex */
    { 0xc3, 0xc7, 0xcc, 0xc383  , 0   , "?"      },  /* A tilde */
    { 0xc4, 0x8e, 0x80, 0xc384  , 0   , "?"      },  /* A diaeresis */
    { 0xc5, 0x8f, 0x81, 0xc385  , 0   , "?"      },  /* A ring  */
    { 0xc6, 0x92, 0xae, 0xc386  , 0   , "?"      },  /* AEsh */
    { 0xc7, 0x80, 0x82, 0xc387  , 0   , "?"      },  /* C cedilla */
    { 0xc8, 0xd4, 0xe9, 0xc388  , 0   , "?"      },  /* E grave */
    { 0xc9, 0x90, 0x83, 0xc389  , 0   , "?"      },  /* E acute */
    { 0xca, 0xd2, 0xe6, 0xc38a  , 0   , "?"      },  /* E circumflex */
    { 0xcb, 0xd3, 0xe8, 0xc38b  , 0   , "?"      },  /* E diaeresis */
    { 0xcc, 0xde, 0xed, 0xc38c  , 0   , "?"      },  /* I grave */
    { 0xcd, 0xd6, 0xea, 0xc38d  , 0   , "?"      },  /* I acute */
    { 0xce, 0xd7, 0xeb, 0xc38e  , 0   , "?"      },  /* I circumflex */
    { 0xcf, 0xd8, 0xec, 0xc38f  , 0   , "?"      },  /* I diaeresis */
    { 0xd0, 0xd1, 0   , 0xc390  , 0   , "?"      },  /* Eth */
    { 0xd1, 0xa5, 0x84, 0xc391  , 0   , "?"      },  /* N tilde */
    { 0xd2, 0xe3, 0xf1, 0xc392  , 0   , "?"      },  /* O grave */
    { 0xd3, 0xe0, 0xee, 0xc393  , 0   , "?"      },  /* O acute */
    { 0xd4, 0xe2, 0xef, 0xc394  , 0   , "?"      },  /* O circumflex */
    { 0xd5, 0xe5, 0xcd, 0xc395  , 0   , "?"      },  /* O tilde */
    { 0xd6, 0x99, 0x85, 0xc396  , 0   , "?"      },  /* O diaeresis */
    { 0xd7, 0x9e, 0   , 0xc397  , 0   , "?"      },  /* multiplication sign */
    { 0xd8, 0x9d, 0xaf, 0xc398  , 0   , "?"      },  /* O danish */
    { 0xd9, 0xeb, 0xf4, 0xc399  , 0   , "?"      },  /* U grave */
    { 0xda, 0xe9, 0xf2, 0xc39a  , 0   , "?"      },  /* U acute */
    { 0xdb, 0xea, 0xf3, 0xc39b  , 0   , "?"      },  /* U circumflex */
    { 0xdc, 0x9a, 0x86, 0xc39c  , 0   , "?"      },  /* U diaeresis */
    { 0xdd, 0xed, 0   , 0xc39d  , 0   , "?"      },  /* Y acute */
    { 0xde, 0xe7, 0   , 0xc39e  , 0   , "?"      },  /* uppercase thorn */
    { 0xdf, 0xe1, 0xa7, 0xc39f  , 0   , "?"      },  /* esszet */
    { 0xe0, 0x85, 0x88, 0xc3a0  , 0x84, "Aa"     },  /* a grave */
    { 0xe1, 0xa0, 0x87, 0xc3a1  , 0x81, "Ba"     },  /* a acute */
    { 0xe2, 0x83, 0x89, 0xc3a2  , 0x82, "Ca"     },  /* a circumflex */
    { 0xe3, 0xc6, 0x8b, 0xc3a3  , 0   , "?"      },  /* a tilde */
    { 0xe4, 0x84, 0x8a, 0xc3a4  , 0x83, "Ha"     },  /* a diaeresis */
    { 0xe5, 0x86, 0x8c, 0xc3a5  , 0   , "?"      },  /* a ring */
    { 0xe6, 0x91, 0xbe, 0xc3a6  , 0   , "?"      },  /* aesh */
    { 0xe7, 0x87, 0x8d, 0xc3a7  , 0x80, "Kc"     },  /* c cedilla */
    { 0xe8, 0x8a, 0x8f, 0xc3a8  , 0x88, "Ae"     },  /* e grave */
    { 0xe9, 0x82, 0x8e, 0xc3a9  , 0x85, "Be"     },  /* e acute */
    { 0xea, 0x88, 0x90, 0xc3aa  , 0x86, "Ce"     },  /* e circumflex */
    { 0xeb, 0x89, 0x91, 0xc3ab  , 0x87, "He"     },  /* e diaeresis */
    { 0xec, 0x8d, 0x93, 0xc3ac  , 0   , "?"      },  /* i grave */
    { 0xed, 0xa1, 0x92, 0xc3ad  , 0   , "?"      },  /* i acute */
    { 0xee, 0x8c, 0x94, 0xc3ae  , 0x89, "Ci"     },  /* i circumflex */
    { 0xef, 0x8b, 0x95, 0xc3af  , 0x8a, "Hi"     },  /* i diaeresis */
    { 0xf0, 0xd0, 0   , 0xc3b0  , 0   , "?"      },  /* eth */
    { 0xf1, 0xa4, 0x96, 0xc3b1  , 0   , "?"      },  /* n tilde */
    { 0xf2, 0x95, 0x98, 0xc3b2  , 0   , "?"      },  /* o grave */
    { 0xf3, 0xa2, 0x97, 0xc3b3  , 0   , "?"      },  /* o acute */
    { 0xf4, 0x93, 0x99, 0xc3b4  , 0x8b, "Co"     },  /* o circumflex */
    { 0xf5, 0xe4, 0x9b, 0xc3b5  , 0   , "?"      },  /* o tilde         */
    { 0xf6, 0x94, 0x9a, 0xc3b6  , 0x8c, "Ho"     },  /* o diaeresis */
    { 0xf7, 0xf6, 0xd6, 0xc3b7  , 0   , "?"      },  /* obelus */
    { 0xf8, 0x9b, 0xbf, 0xc3b8  , 0   , "?"      },  /* o danish */
    { 0xf9, 0x97, 0x9d, 0xc3b9  , 0x8f, "Au"     },  /* u grave */
    { 0xfa, 0xa3, 0x9c, 0xc3ba  , 0   , "?"      },  /* u acute */
    { 0xfb, 0x96, 0x9e, 0xc3bb  , 0x8d, "Cu"     },  /* u circumflex */
    { 0xfc, 0x81, 0x9f, 0xc3bc  , 0x8e, "Hu"     },  /* u diaeresis */
    { 0xfd, 0xec, 0   , 0xc3bd  , 0   , "?"      },  /* y acute */
    { 0xfe, 0xe8, 0   , 0xc3be  , 0   , "?"      },  /* lowercase thorn */
    { 0xff, 0x98, 0xd8, 0xc3bf  , 0   , "?"      },  /* y diaeresis */
    { 0   , 0   , 0   , 0       , 0   , "?"      }   /* - not found - */
};

static int mac_roman = FALSE;



static int get_char_type (char **text)
{
    int i = -1;
    unsigned int code = 0;
    unsigned int first_code = 0;

    debug_print ("%s\n", "");

    if ((((int)(*(*text+0)) & 0xff) >= 0x20)
     && (((int)(*(*text+0)) & 0xff) <= 0x7f))
    {
        i = ((int)*((*text)++) & 0xff) | CHAR_TYPE_CODE;
    }
    else
#ifdef MACINTOSH_TOOL
    if ((source_Encoding () == ENCODING_MAC_ROMAN)
#else
    if ((source_Encoding () == ENCODING_ISO_8859_1)
#endif
     && ((*(*text+0)) < '\0')
     && ((*(*text+1)) > '\0'))
    {
        code = (unsigned int)*((*text)++) & 0xff;

#ifdef MACINTOSH_TOOL
        for (i = 0; encoding_table[i].iso_8859_1 > 0; i++)
        {
            if (code == (unsigned int)encoding_table[i].mac_roman)
            {
                break;
            }
        }
        i |= (encoding_table[i].mac_roman ==  0) ? CHAR_TYPE_ERROR
                                                 : CHAR_TYPE_OFFSET;
#else
        for (i = 0; encoding_table[i].iso_8859_1 > 0; i++)
        {
            if (code == (unsigned int)encoding_table[i].iso_8859_1)
            {
                break;
            }
        }
        i |= (encoding_table[i].iso_8859_1 == 0) ? CHAR_TYPE_ERROR
                                                 : CHAR_TYPE_OFFSET;
#endif
    }
    else
    if ((source_Encoding () == ENCODING_UTF8)
     && (((int)(*(*text+0)) & 0xff) >= 0xc2)
     && (((int)(*(*text+0)) & 0xff) <= 0xf4)
     && (((int)(*(*text+1)) & 0x80) != 0))
    {
        first_code = (unsigned int)*((*text)++) & 0xff;
        code = first_code;

        if ((first_code >= 0xc2)
         && (first_code <= 0xf4)
         && (((int)(*(*text)) & 0x80) != 0x00))
        {
            code <<= 8;
            code |= (unsigned int)*((*text)++) & 0xff;
        }

        if ((first_code >= 0xe0)
         && (first_code <= 0xf4)
         && (((int)(*(*text)) & 0x80) != 0x00))
        {
            code <<= 8;
            code |= (unsigned int)*((*text)++) & 0xff;
        }

        if ((first_code >= 0xf0)
         && (first_code <= 0xf4)
         && (((int)(*(*text)) & 0x80) != 0x00))
        {
            code <<= 8;
            code |= (unsigned int)*((*text)++) & 0xff;
        }

        for (i = 0; encoding_table[i].iso_8859_1 > 0; i++)
        {
            if (code == (unsigned int)encoding_table[i].utf8)
            {
                break;
            }
        }
        i |= (encoding_table[i].asm_code < 0) ? CHAR_TYPE_ERROR
                                              : CHAR_TYPE_OFFSET;
    }
    else
    {
        i = (int)'?' | CHAR_TYPE_ERROR;
        (*text)++;
    }    

    return i;
}


/* ------------------------------------------------------------------------- */



/*
 * Get the encoding code of a text
 */
void encode_SetForMac (void)
{
    mac_roman = TRUE;
}



/*
 * Get the encoding code of a text
 */
int encode_Get (char *start, char *end)
{
    int code;
    int simple_code = 0;

    while (start < (end-1))
    {
        if (start[0] < '\0')
        {
            if (start[1] > '\0')
            {
                simple_code++;
            }
            else
            if ((((int)(start[0]) & 0xff) >= 0xc2)
             && (((int)(start[0]) & 0xff) <= 0xf4)
             && (start[1] < '\0'))
            {
                while (start[1] < '\0')
                {
                    start++;
                }
            }
        }
        start++;
    }

    if (simple_code != 0)
    {
#ifdef MACINTOSH_TOOL
        code = ENCODING_MAC_ROMAN;
#else
        code = ENCODING_ISO_8859_1;
#endif
    }
    else
    {
        code = ENCODING_UTF8;
    }

    return code;
}



/*
 * Get the accent (ACC) char coding
 */
int encode_AccChar (char **text)
{
    int i = get_char_type (text);

    debug_print ("%x\n", (unsigned int)i);

    switch (i & CHAR_TYPE_MASK)
    {
        case CHAR_TYPE_OFFSET:
            i = (int)((((unsigned int)encoding_table[i&0xff].acc[0] & 0xff) << 8)
                     | ((unsigned int)encoding_table[i&0xff].acc[1] & 0xff));
            break;

        case CHAR_TYPE_ERROR:
            i = (int)'?';
            break;

        case CHAR_TYPE_CODE:
            i &= 0xff;
            break;
    }

    return i;
}



/*
 * Get the Assembler char coding
 */
char encode_AsmChar (char **text)
{
    char c;
    int i = get_char_type (text);

    debug_print ("i=%x\n", (unsigned int)i);

    switch (i & CHAR_TYPE_MASK)
    {
        case CHAR_TYPE_ERROR:
            c = '?';
            break;

        case CHAR_TYPE_OFFSET:
            c = (char)encoding_table[i&0xff].asm_code;
            break;

        default:
            c = (char)i;
            break;
    }

    return c;
}





