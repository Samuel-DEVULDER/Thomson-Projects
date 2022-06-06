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
#   include <ctype.h>
#endif

#include "defs.h"
#include "error.h"
#include "includ.h"
#include "macro.h"
#include "if.h"
#include "mark.h"
#include "bin.h"
#include "arg.h"
#include "symbol.h"
#include "display.h"
#include "assemble.h"

struct INSTRUCTION {
    char name[7];      /* instruction name */
    int code;          /* instruction code */
    int cycles;        /* cycles base */
    int has_operand;   /* if instruction has operand */
    int (*prog)(void); /* instruction program */
};

struct DIRECTIVE {
     char name[7];      /* directive name */
     int soft;          /* SOFT_ASSEMBLER_MO/TO/SOFT_MACROASSEMBLER */
     int forced;        /* if directive must be executed anyway */
     int has_operand;   /* if directive has operand */
     int (*prog)(char *label_name); /* directive program */
};

/* instruction list */
extern int Ass_Inherent (void);
extern int Ass_All (void);
extern int Ass_Immediate (void);
extern int Ass_NotImmed (void);
extern int Ass_ShortBr (void);
extern int Ass_Transfer (void);
extern int Ass_LongBr (void);
extern int Ass_Lea (void);
extern int Ass_SStack (void);
extern int Ass_UStack (void);

/* directive list */
extern int Ass_CALL (char *label_name);
extern int Ass_ECHO (char *label_name);
extern int Ass_ELSE (char *label_name);
extern int Ass_END (char *label_name);
extern int Ass_ENDC (char *label_name);
extern int Ass_ENDM (char *label_name);
extern int Ass_EQU (char *label_name);
extern int Ass_FCB (char *label_name);
extern int Ass_FCC (char *label_name);
extern int Ass_FCN (char *label_name);
extern int Ass_FCS (char *label_name);
extern int Ass_FDB (char *label_name);
extern int Ass_GOTO (char *label_name);
extern int Ass_IF (char *label_name);
extern int Ass_IFEQ (char *label_name);
extern int Ass_IFGE (char *label_name);
extern int Ass_IFGT (char *label_name);
extern int Ass_IFLE (char *label_name);
extern int Ass_IFLT (char *label_name);
extern int Ass_IFNE (char *label_name);
extern int Ass_INCBIN (char *label_name);
extern int Ass_INCDAT (char *label_name);
extern int Ass_INCLUD (char *label_name);
extern int Ass_MACRO (char *label_name);
extern int Ass_OPT (char *label_name);
extern int Ass_ORG (char *label_name);
extern int Ass_PAGE (char *label_name);
extern int Ass_PRINT (char *label_name);
extern int Ass_RMB (char *label_name);
extern int Ass_RMD (char *label_name);
extern int Ass_SET (char *label_name);
extern int Ass_SETDP (char *label_name);
extern int Ass_STOP (char *label_name);
extern int Ass_TITLE (char *label_name);
extern int Ass_BLANK (char *label_name);

static const struct INSTRUCTION instruction[] = {
     { "ABX"  , 0x003A,  3, FALSE, Ass_Inherent  },  /*   0 */
     { "ADCA" , 0x0089,  4, TRUE , Ass_All       },  /*   1 */
     { "ADCB" , 0x00C9,  4, TRUE , Ass_All       },  /*   2 */
     { "ADDA" , 0x008B,  4, TRUE , Ass_All       },  /*   3 */
     { "ADDB" , 0x00CB,  4, TRUE , Ass_All       },  /*   4 */
     { "ADDD" , 0x00C3,  6, TRUE , Ass_All       },  /*   5 */
     { "ANDA" , 0x0084,  4, TRUE , Ass_All       },  /*   6 */
     { "ANDB" , 0x00C4,  4, TRUE , Ass_All       },  /*   7 */
     { "ANDCC", 0x001C,  3, TRUE , Ass_Immediate },  /*   8 */
     { "ASLA" , 0x0048,  2, FALSE, Ass_Inherent  },  /*   9 */
     { "ASLB" , 0x0058,  2, FALSE, Ass_Inherent  },  /*  10 */
     { "ASL"  , 0x0008,  6, TRUE , Ass_NotImmed  },  /*  11 */
     { "ASRA" , 0x0047,  2, FALSE, Ass_Inherent  },  /*  12 */
     { "ASRB" , 0x0057,  2, FALSE, Ass_Inherent  },  /*  13 */
     { "ASR"  , 0x0007,  6, TRUE , Ass_NotImmed  },  /*  14 */
     { "BITA" , 0x0085,  4, TRUE , Ass_All       },  /*  15 */
     { "BITB" , 0x00C5,  4, TRUE , Ass_All       },  /*  16 */
     { "BRA"  , 0x0020,  3, TRUE , Ass_ShortBr   },  /*  17 */
     { "BRN"  , 0x0021,  3, TRUE , Ass_ShortBr   },  /*  18 */
     { "BHI"  , 0x0022,  3, TRUE , Ass_ShortBr   },  /*  19 */
     { "BLS"  , 0x0023,  3, TRUE , Ass_ShortBr   },  /*  20 */
     { "BCC"  , 0x0024,  3, TRUE , Ass_ShortBr   },  /*  21 */
     { "BHS"  , 0x0024,  3, TRUE , Ass_ShortBr   },  /*  22 */
     { "BCS"  , 0x0025,  3, TRUE , Ass_ShortBr   },  /*  23 */
     { "BLO"  , 0x0025,  3, TRUE , Ass_ShortBr   },  /*  24 */
     { "BNE"  , 0x0026,  3, TRUE , Ass_ShortBr   },  /*  25 */
     { "BEQ"  , 0x0027,  3, TRUE , Ass_ShortBr   },  /*  26 */
     { "BVC"  , 0x0028,  3, TRUE , Ass_ShortBr   },  /*  27 */
     { "BVS"  , 0x0029,  3, TRUE , Ass_ShortBr   },  /*  28 */
     { "BPL"  , 0x002A,  3, TRUE , Ass_ShortBr   },  /*  29 */
     { "BMI"  , 0x002B,  3, TRUE , Ass_ShortBr   },  /*  30 */
     { "BGE"  , 0x002C,  3, TRUE , Ass_ShortBr   },  /*  31 */
     { "BLT"  , 0x002D,  3, TRUE , Ass_ShortBr   },  /*  32 */
     { "BGT"  , 0x002E,  3, TRUE , Ass_ShortBr   },  /*  33 */
     { "BLE"  , 0x002F,  3, TRUE , Ass_ShortBr   },  /*  34 */
     { "BSR"  , 0x008D,  7, TRUE , Ass_ShortBr   },  /*  35 */
     { "CLRA" , 0x004F,  2, FALSE, Ass_Inherent  },  /*  36 */
     { "CLRB" , 0x005F,  2, FALSE, Ass_Inherent  },  /*  37 */
     { "CLR"  , 0x000F,  6, TRUE , Ass_NotImmed  },  /*  38 */
     { "CMPA" , 0x0081,  4, TRUE , Ass_All       },  /*  39 */
     { "CMPB" , 0x00C1,  4, TRUE , Ass_All       },  /*  40 */
     { "CMPD" , 0x1083,  7, TRUE , Ass_All       },  /*  41 */
     { "CMPS" , 0x118C,  7, TRUE , Ass_All       },  /*  42 */
     { "CMPU" , 0x1183,  7, TRUE , Ass_All       },  /*  43 */
     { "CMPX" , 0x008C,  6, TRUE , Ass_All       },  /*  44 */
     { "CMPY" , 0x108C,  7, TRUE , Ass_All       },  /*  45 */
     { "COMA" , 0x0043,  2, FALSE, Ass_Inherent  },  /*  46 */
     { "COMB" , 0x0053,  2, FALSE, Ass_Inherent  },  /*  47 */
     { "COM"  , 0x0003,  6, TRUE , Ass_NotImmed  },  /*  48 */
     { "CWAI" , 0x003C, 20, TRUE , Ass_Immediate },  /*  49 */
     { "DAA"  , 0x0019,  2, FALSE, Ass_Inherent  },  /*  50 */
     { "DECA" , 0x004A,  2, FALSE, Ass_Inherent  },  /*  51 */
     { "DECB" , 0x005A,  2, FALSE, Ass_Inherent  },  /*  52 */
     { "DEC"  , 0x000A,  6, TRUE , Ass_NotImmed  },  /*  53 */
     { "EORA" , 0x0088,  4, TRUE , Ass_All       },  /*  54 */
     { "EORB" , 0x00C8,  4, TRUE , Ass_All       },  /*  55 */
     { "EXG"  , 0x001E,  8, TRUE , Ass_Transfer  },  /*  56 */
     { "INCA" , 0x004C,  2, FALSE, Ass_Inherent  },  /*  57 */
     { "INCB" , 0x005C,  2, FALSE, Ass_Inherent  },  /*  58 */
     { "INC"  , 0x000C,  6, TRUE , Ass_NotImmed  },  /*  59 */
     { "JMP"  , 0x000E,  3, TRUE , Ass_NotImmed  },  /*  60 */
     { "JSR"  , 0x009D,  7, TRUE , Ass_All       },  /*  61 */
     { "LBRA" , 0x0016,  5, TRUE , Ass_LongBr    },  /*  62 */
     { "LBRN" , 0x1021,  5, TRUE , Ass_LongBr    },  /*  63 */
     { "LBHI" , 0x1022,  6, TRUE , Ass_LongBr    },  /*  64 */
     { "LBLS" , 0x1023,  6, TRUE , Ass_LongBr    },  /*  65 */
     { "LBCC" , 0x1024,  6, TRUE , Ass_LongBr    },  /*  66 */
     { "LBHS" , 0x1024,  6, TRUE , Ass_LongBr    },  /*  67 */
     { "LBCS" , 0x1025,  6, TRUE , Ass_LongBr    },  /*  68 */
     { "LBLO" , 0x1025,  6, TRUE , Ass_LongBr    },  /*  69 */
     { "LBNE" , 0x1026,  6, TRUE , Ass_LongBr    },  /*  70 */
     { "LBEQ" , 0x1027,  6, TRUE , Ass_LongBr    },  /*  71 */
     { "LBVC" , 0x1028,  6, TRUE , Ass_LongBr    },  /*  72 */
     { "LBVS" , 0x1029,  6, TRUE , Ass_LongBr    },  /*  73 */
     { "LBPL" , 0x102A,  6, TRUE , Ass_LongBr    },  /*  74 */
     { "LBMI" , 0x102B,  6, TRUE , Ass_LongBr    },  /*  75 */
     { "LBGE" , 0x102C,  6, TRUE , Ass_LongBr    },  /*  76 */
     { "LBLT" , 0x102D,  6, TRUE , Ass_LongBr    },  /*  77 */
     { "LBGT" , 0x102E,  6, TRUE , Ass_LongBr    },  /*  78 */
     { "LBLE" , 0x102F,  6, TRUE , Ass_LongBr    },  /*  79 */
     { "LBSR" , 0x0017,  9, TRUE , Ass_LongBr    },  /*  80 */
     { "LDA"  , 0x0086,  4, TRUE , Ass_All       },  /*  81 */
     { "LDB"  , 0x00C6,  4, TRUE , Ass_All       },  /*  82 */
     { "LDD"  , 0x00CC,  5, TRUE , Ass_All       },  /*  83 */
     { "LDS"  , 0x10CE,  6, TRUE , Ass_All       },  /*  84 */
     { "LDU"  , 0x00CE,  5, TRUE , Ass_All       },  /*  85 */
     { "LDX"  , 0x008E,  5, TRUE , Ass_All       },  /*  86 */
     { "LDY"  , 0x108E,  6, TRUE , Ass_All       },  /*  87 */
     { "LEAS" , 0x0032,  4, TRUE , Ass_Lea       },  /*  88 */
     { "LEAU" , 0x0033,  4, TRUE , Ass_Lea       },  /*  89 */
     { "LEAX" , 0x0030,  4, TRUE , Ass_Lea       },  /*  90 */
     { "LEAY" , 0x0031,  4, TRUE , Ass_Lea       },  /*  91 */
     { "LSLA" , 0x0048,  2, FALSE, Ass_Inherent  },  /*  92 */
     { "LSLB" , 0x0058,  2, FALSE, Ass_Inherent  },  /*  93 */
     { "LSL"  , 0x0008,  6, TRUE , Ass_NotImmed  },  /*  94 */
     { "LSRA" , 0x0044,  2, FALSE, Ass_Inherent  },  /*  95 */
     { "LSRB" , 0x0054,  2, FALSE, Ass_Inherent  },  /*  96 */
     { "LSR"  , 0x0004,  6, TRUE , Ass_NotImmed  },  /*  97 */
     { "MUL"  , 0x003D, 11, FALSE, Ass_Inherent  },  /*  98 */
     { "NEGA" , 0x0040,  2, FALSE, Ass_Inherent  },  /*  99 */
     { "NEGB" , 0x0050,  2, FALSE, Ass_Inherent  },  /* 100 */
     { "NEG"  , 0x0000,  6, TRUE , Ass_NotImmed  },  /* 101 */
     { "NOP"  , 0x0012,  2, FALSE, Ass_Inherent  },  /* 102 */
     { "ORA"  , 0x008A,  4, TRUE , Ass_All       },  /* 103 */
     { "ORB"  , 0x00CA,  4, TRUE , Ass_All       },  /* 104 */
     { "ORCC" , 0x001A,  3, TRUE , Ass_Immediate },  /* 105 */
     { "PSHS" , 0x0034,  5, TRUE , Ass_SStack    },  /* 106 */
     { "PSHU" , 0x0036,  5, TRUE , Ass_UStack    },  /* 107 */
     { "PULS" , 0x0035,  5, TRUE , Ass_SStack    },  /* 108 */
     { "PULU" , 0x0037,  5, TRUE , Ass_UStack    },  /* 109 */
     { "ROLA" , 0x0049,  2, FALSE, Ass_Inherent  },  /* 110 */
     { "ROLB" , 0x0059,  2, FALSE, Ass_Inherent  },  /* 111 */
     { "ROL"  , 0x0009,  6, TRUE , Ass_NotImmed  },  /* 112 */
     { "RORA" , 0x0046,  2, FALSE, Ass_Inherent  },  /* 113 */
     { "RORB" , 0x0056,  2, FALSE, Ass_Inherent  },  /* 114 */
     { "ROR"  , 0x0006,  6, TRUE , Ass_NotImmed  },  /* 115 */
     { "RTI"  , 0x003B, 15, FALSE, Ass_Inherent  },  /* 116 */
     { "RTS"  , 0x0039,  5, FALSE, Ass_Inherent  },  /* 117 */
     { "SBCA" , 0x0082,  4, TRUE , Ass_All       },  /* 118 */
     { "SBCB" , 0x00C2,  4, TRUE , Ass_All       },  /* 119 */
     { "SEX"  , 0x001D,  2, FALSE, Ass_Inherent  },  /* 120 */
     { "STA"  , 0x0097,  4, TRUE , Ass_All       },  /* 121 */
     { "STB"  , 0x00D7,  4, TRUE , Ass_All       },  /* 122 */
     { "STD"  , 0x00DD,  5, TRUE , Ass_All       },  /* 123 */
     { "STS"  , 0x10DF,  6, TRUE , Ass_All       },  /* 124 */
     { "STU"  , 0x00DF,  5, TRUE , Ass_All       },  /* 125 */
     { "STX"  , 0x009F,  5, TRUE , Ass_All       },  /* 126 */
     { "STY"  , 0x109F,  6, TRUE , Ass_All       },  /* 127 */
     { "SUBA" , 0x0080,  4, TRUE , Ass_All       },  /* 128 */
     { "SUBB" , 0x00C0,  4, TRUE , Ass_All       },  /* 129 */
     { "SUBD" , 0x0083,  6, TRUE , Ass_All       },  /* 130 */
     { "SWI"  , 0x003F, 19, FALSE, Ass_Inherent  },  /* 131 */
     { "SWI2" , 0x103F, 20, FALSE, Ass_Inherent  },  /* 132 */
     { "SWI3" , 0x113F, 20, FALSE, Ass_Inherent  },  /* 133 */
     { "SYNC" , 0x0013,  4, FALSE, Ass_Inherent  },  /* 134 */
     { "TFR"  , 0x001F,  6, TRUE , Ass_Transfer  },  /* 135 */
     { "TSTA" , 0x004D,  2, FALSE, Ass_Inherent  },  /* 136 */
     { "TSTB" , 0x005D,  2, FALSE, Ass_Inherent  },  /* 137 */
     { "TST"  , 0x000D,  6, TRUE , Ass_NotImmed  },  /* 138 */
     { ""     , 0x0000,  0, FALSE, Ass_All       }   /* 139 */
};

static const struct DIRECTIVE directive[] = {
     { "CALL"   , SOFT_MACROASSEMBLER, FALSE, TRUE , Ass_CALL   },
     { "ECHO"   , SOFT_MACROASSEMBLER, FALSE, FALSE, Ass_ECHO   },
     { "ELSE"   , SOFT_MACROASSEMBLER, TRUE , FALSE, Ass_ELSE   },
     { "END"    , 0                  , FALSE, TRUE , Ass_END    },
     { "ENDC"   , SOFT_MACROASSEMBLER, TRUE , FALSE, Ass_ENDC   },
     { "ENDIF"  , SOFT_MACROASSEMBLER, TRUE , FALSE, Ass_ENDC   },
     { "ENDM"   , SOFT_MACROASSEMBLER, TRUE , FALSE, Ass_ENDM   },
     { "EQU"    , 0                  , FALSE, TRUE , Ass_EQU    },
     { "FCB"    , 0                  , FALSE, TRUE , Ass_FCB    },
     { "FCC"    , 0                  , FALSE, FALSE, Ass_FCC    },
     { "FCN"    , SOFT_MACROASSEMBLER, FALSE, FALSE, Ass_FCN    },
     { "FCS"    , SOFT_MACROASSEMBLER, FALSE, FALSE, Ass_FCS    },
     { "FDB"    , 0                  , FALSE, TRUE , Ass_FDB    },
     { "GOTO"   , SOFT_MACROASSEMBLER, FALSE, TRUE , Ass_GOTO   },
     { "IF"     , SOFT_MACROASSEMBLER, TRUE , TRUE , Ass_IF     },
     { "IFEQ"   , SOFT_MACROASSEMBLER, TRUE , TRUE , Ass_IFEQ   },
     { "IFGE"   , SOFT_MACROASSEMBLER, TRUE , TRUE , Ass_IFGE   },
     { "IFGT"   , SOFT_MACROASSEMBLER, TRUE , TRUE , Ass_IFGT   },
     { "IFLE"   , SOFT_MACROASSEMBLER, TRUE , TRUE , Ass_IFLE   },
     { "IFLT"   , SOFT_MACROASSEMBLER, TRUE , TRUE , Ass_IFLT   },
     { "IFNE"   , SOFT_MACROASSEMBLER, TRUE , TRUE , Ass_IFNE   },
     { "INCBIN" , SOFT_MACROASSEMBLER, FALSE, FALSE, Ass_INCBIN },
     { "INCDAT" , SOFT_MACROASSEMBLER, FALSE, FALSE, Ass_INCDAT },
     { "INCLUD" , 0                  , FALSE, FALSE, Ass_INCLUD },
     { "MACRO"  , SOFT_MACROASSEMBLER, TRUE , FALSE, Ass_MACRO  },
     { "OPT"    , SOFT_MACROASSEMBLER, FALSE, TRUE , Ass_OPT    },
     { "ORG"    , 0                  , FALSE, TRUE , Ass_ORG    },
     { "PAGE"   , 0                  , FALSE, FALSE, Ass_PAGE   },
     { "PRINT"  , SOFT_MACROASSEMBLER, FALSE, FALSE, Ass_PRINT  },
     { "RMB"    , 0                  , FALSE, TRUE , Ass_RMB    },
     { "RMD"    , SOFT_MACROASSEMBLER, FALSE, TRUE , Ass_RMD    },
     { "SET"    , 0                  , FALSE, TRUE , Ass_SET    },
     { "SETDP"  , 0                  , FALSE, TRUE , Ass_SETDP  },
     { "STOP"   , SOFT_MACROASSEMBLER, FALSE, FALSE, Ass_STOP   },
     { "TITLE"  , 0                  , FALSE, FALSE, Ass_TITLE  },
     { "*"      , 0                  , FALSE, FALSE, Ass_BLANK  },
     { ""       , 0                  , FALSE, FALSE, Ass_BLANK  },
     { ""       , -1                 , FALSE, FALSE, Ass_TITLE  }
};

static char software_name[4][20] = {
    "ASSEMBLER 1.0 on MO",
    "ASSEMBLER 1.0 on TO",
    "MACROASSEMBLER",
    "c6809"
};



static int filter_label (char *label_name)
{
    int err = 0;

    if (label_name[0] != '\0')
    {
        if (arg_IsAlpha (*label_name) != TRUE)
        {
            err = error_Printf (
                ERROR_TYPE_ERROR,
                "the label '%s' is invalid",
                label_name);
        }

        if ((scan.soft < SOFT_MACROASSEMBLER)
         && (strlen (label_name) > LABEL_MAX_SIZE))
        {
            err = error_Printf (
                ERROR_TYPE_ERROR,
                "ASSEMBLER 1.0 does not support " \
                "labels longer than %d characters and the " \
                "label '%s' is %d characters long",
                LABEL_MAX_SIZE,
                label_name,
                strlen(label_name));
        }

        if ((scan.soft == SOFT_MACROASSEMBLER)
         && (strlen (label_name) > ARG_MAX_SIZE))
        {
            err = error_Printf (
                ERROR_TYPE_ERROR,
                "MACROASSEMBLER does not support " \
                "labels longer than %d characters and the " \
                "label '%s' is %d characters long",
                ARG_MAX_SIZE,
                label_name,
                strlen(label_name));
        }
    }
    return err;
}



static int is_instruction (char *argument)
{
    int i;
    int code = -1;
    char command_upper_name[ARG_MAX_SIZE+2];

    debug_print ("%s\n", "");

    command_upper_name[0] = '\0';
    strcat (command_upper_name, argument);
    arg_Upper (command_upper_name);

    for (i = 0; (code == -1) && (instruction[i].name[0] != '\0'); i++)
    {
        if (strcmp (command_upper_name, instruction[i].name) == 0)
        {
            code = i;
        }
    }
    return code;
}



static int is_directive (char *argument)
{
    int i;
    int code = -1;
    char command_upper_name[ARG_MAX_SIZE+2];

    debug_print ("command_name='%s'\n", argument);

    command_upper_name[0] = '\0';
    strcat (command_upper_name, argument);
    arg_Upper (command_upper_name);

    for (i = 0; (code == -1) && (directive[i].soft != -1); i++)
    {
        if (strcmp (command_upper_name, directive[i].name) == 0)
        {
            code = i;
        }
    }
    return code;
}


    
static int execute_instruction (int i, char *label_name)
{
    debug_print ("%s\n", "");

    (void)assemble_RecordLabel (label_name);

    fetch.buf[0] = (char)((unsigned int)instruction[i].code >> 8);
    fetch.buf[1] = (char)instruction[i].code;
    info.cycle.count = instruction[i].cycles;

    return (*instruction[i].prog)();
}



static int execute_directive (int i, char *label_name)
{
    int err;

    debug_print ("%s\n", "");

    if (scan.soft < directive[i].soft)
    {
        err =  error_Printf (
                  ERROR_TYPE_ERROR,
                  "%s does not support the '%s' directive",
                  software_name[scan.soft],
                  directive[i].name);
    }
    else
    {
        err = (*directive[i].prog)(label_name);
    }
    return err;
}



static int execute_command (char *label_name, char *command_name)
{
    int i;
    int err;

    debug_print ("label_name='%s' command_name='%s'\n",
                 label_name, command_name);

    if ((i = is_instruction (command_name)) >= 0)
    {
        err = execute_instruction (i, label_name);
    }
    else
    if ((i = is_directive (command_name)) >= 0)
    {
        err = execute_directive (i, label_name);
    }
    else
    {
        err = macro_Execute (label_name, command_name);
    }
    return err;
}



/*
 * Assemble the line
 */
static void assemble_line (void)
{
    int i;
    char command_name[ARG_MAX_SIZE+1];
    char label_name[ARG_MAX_SIZE+1];

    debug_print ("\n\n%s\n\n", "--------------------------------------------");

    label_name[0] = '\0';
    command_name[0] = '\0';

    bin_InitFetch ();
    mark_LineInit ();

    /* quit eventually the current includ */
    includ_ManageLevel ();
    if (run.exit == TRUE)
    {
        return;
    }

    includ_GetLine();

    /* check first character */
    switch (*run.ptr)
    {
        case '\0':
        case '*':
            return;

        case '(':
            mark_Read ();
            return;

        case '/':
            run.locked ^= LOCK_COMMENT;
            if ((run.locked & LOCK_COMMENT) != 0)
                 run.comment_line = run.line;
            return;

        default:
            if ((run.locked & LOCK_COMMENT) != 0)
            {
                return;
            }
            break;
    }

    /* expanse the macro line if necessary */
    (void)macro_Expansion ();

    /* read the label */
    if (*run.ptr > ' ')
    {
        (void)arg_Read ();
        if (scan.soft < SOFT_MACROASSEMBLER)
        {
            arg_Upper (arg_buf);
        }
        strcat (label_name, arg_buf);
    }

    /* skip spaces */
    run.ptr = arg_SkipSpaces (run.ptr);

    /* read the command */
    (void)arg_Read ();
    if (scan.soft < SOFT_MACROASSEMBLER)
    {
        arg_Upper (arg_buf);
    }
    strcat (command_name, arg_buf);

    /* if assembly locked */
    if (run.locked != 0)
    {
        i = is_directive (command_name);
        if (i >= 0)
        {
            if (directive[i].forced == TRUE)
            {
                (void)execute_command (label_name, command_name);
            }
        }
        return;
    }
    /* execute instruction/directive/macro */
    if (execute_command (label_name, command_name) == NO_ERROR)
    {
#if 0
        /* Check if end of expression */
        if ((isspace ((int)*run.ptr) == 0)
         && (*run.ptr != '\0'))
        {
            (void)error_Printf (
                ERROR_TYPE_ERROR,
                "expected CR or SPACE at end of expression, have %s",
                arg_FilteredChar (*run.ptr));
        }
#endif
    }

    /* compute cycles */
    if (info.cycle.count != -1)
    {
        info.cycle.total += info.cycle.count;
        check[0][1] += info.cycle.count;
    }
    if (info.cycle.plus  != -1)
    {
        info.cycle.total += info.cycle.plus ;
        check[0][1] += info.cycle.plus;
    }
}


/* ------------------------------------------------------------------------- */


int assemble_RecordLabel (char *label_name)
{
    int err = NO_ERROR;
    int symbol_err = SYMBOL_ERROR_NONE;

    if (label_name[0] != '\0')
    {
        err = filter_label (label_name);
        if (err == NO_ERROR)
        {
            symbol_err = symbol_Do (label_name, run.pc, SYMBOL_TYPE_LABEL);
            if ((symbol_err == SYMBOL_ERROR_MULTIPLY_DEFINED)
             || (symbol_err == SYMBOL_ERROR_LONE))
            {
                (void)symbol_DisplayError (label_name, symbol_err);
            }
            
            if (symbol_err != SYMBOL_ERROR_NONE)
            {
                err = ERR_ERROR;
            }
        }
    }
    return err;
}



int assemble_NameIsReserved (char *argument)
{
    int flag = FALSE;

    debug_print ("%s\n", "");

    if ((is_instruction (argument) >= 0)
     || (is_directive (argument) >= 0)
     || (arg_IsRegister (argument) >= 0))
        flag = TRUE;

    return flag;
}



int assemble_HasOperand (char *argument)
{
    int i;
    int flag = FALSE;

    debug_print ("%s\n", "");

    if ((i = is_instruction (argument)) >= 0)
    {
        flag = instruction[i].has_operand;
    }
    else
    if ((i = is_directive (argument)) >= 0)
    {
        flag = directive[i].has_operand;
    }

    return flag;
}



/*
 * Assemble the source
 */
void assemble_Source (char *file_name, char *pass_string, int pass)
{
    debug_print ("%s\n", "");

    /* initialize assembling parameters */
    run.exit  = FALSE;
    run.dp    = 0x0000;
    run.pc    = 0x0000;
    run.exec  = 0x0000;
    run.locked = 0;

    (void)display_Line ("%s\n", pass_string);
    run.pass = pass;

    error_SourceInit ();
    if_SourceInit ();
    mark_SourceInit ();
    macro_SourceInit ();
    memmove (&run.opt, &scan.opt, OPT_SIZEOF*sizeof(int));

    /* load first includ */
    if (includ_SourceInit (file_name) == NO_ERROR)
    {
        /* assembly loop */
        while ((run.exit == FALSE) && (error_FatalErrorCode () == NO_ERROR))
        {
            display_Set (PRINT_COMMENT);
            assemble_line();
            display_Code ();
            bin_FlushFetch ();
        }

        if (error_FatalErrorCode () == NO_ERROR)
        {
            /* error if not end and Assembler 1.0 */
            if ((run.exit == FALSE)
             && (scan.soft < SOFT_MACROASSEMBLER))
            {
                (void)error_Printf (
                    ERROR_TYPE_ERROR,
                    "ASSEMBLER 1.0 needs always an END directive");
            }
        }

        /* error if macro is running */
        if ((run.locked & LOCK_MACRO) != 0)
        {
            (void)error_Printf (
                ERROR_TYPE_FATAL,
                "MACRO definition at line %d without ENDM",
                run.macro_line);
        }

        /* error if condition is running */
        if (if_Level () > 1)
        {
            (void)error_Printf (
                ERROR_TYPE_FATAL,
                "IF definition at line %d without ENDC",
                run.if_line);
        }
    }

    if_SourceFree ();
    includ_SourceFree ();
    macro_SourceFree ();
}

