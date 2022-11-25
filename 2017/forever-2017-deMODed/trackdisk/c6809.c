/*
 *  C6809 - Compilateur macro-assembler pour Thomson (MacroAssembler-like)
 *
 *  Programme principal
 *
 *  Copyright (C) mars 2010 François Mouret
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
#include <ctype.h>
#include <string.h>
#include <sys/stat.h>

#ifndef TRUE
#   define TRUE 1
#endif

#ifndef FALSE
#   define FALSE 0
#endif

#ifndef NULL
#   define NULL 0
#endif


/***********************************************************************
 *
 *     Variables globales
 *
 ***********************************************************************/

#define CHAR127 '|'       /* Caractère de remplacement pour CHR$(127) */
#define ARGV_MAX_SIZE 300
#define LINE_MAX_SIZE 75  /* Taille maximum de la ligne à afficher */
#define ARG_MAX_SIZE  40  /* Taille maximum d'un argument */
#define ASM_MAX_SIZE 29000 /* Taille maximum en octets pour un fichier ASM */

/* Correspondance caractères 'Occidental ISO-8859' */
unsigned char acc_table[] = {
    0xE7, /* ç */
    0xE1, /* á */
    0xE2, /* â */
    0xE4, /* ä */ 
    0xE0, /* à */
    0xE9, /* é */
    0xEA, /* ê */
    0xEB, /* ë */
    0xE8, /* è */
    0xEE, /* î */
    0xEF, /* ï */
    0xF4, /* ô */
    0xF6, /* ö */
    0xFB, /* û */
    0xFC, /* ü */
    0xF9  /* ù */
} ;

FILE *fp_lst = NULL ;       /* Pour listing d'assemblage */
FILE *fp_asm = NULL ;       /* Pour sauvegarde au format ASM */
char linebuffer[LINE_MAX_SIZE+2] ; /* Buffer de ligne */
char *line ;          /* Pointeur de ligne */
char *filebuffer ;    /* Buffer de source */
char *source ;        /* Pointeur de source */
char arg[ARG_MAX_SIZE+2] ;        /* Buffer d'argument */
char labelname[ARG_MAX_SIZE+2] ;  /* Buffer du nom d'étiquette */


/* -------------------------------------------------------------------
 * Pour scan du source
 */
enum{
    SOFT_ASSEMBLER,
    SOFT_MACROASSEMBLER,
    SOFT_UPDATE
} ;
enum{
    TO_COMPUTER, 
    TO7_COMPUTER,
    MO_COMPUTER
} ;
enum{
    OPT_NO, /* Pas de code objet */
    OPT_OP, /* Optimisation */
    OPT_SS, /* Lignes séparées (sans effet) */
    OPT_WE, /* Attente à l'erreur (sans effet) */
    OPT_WL, /* Affiche les lignes à l'assemblage */
    OPT_WS, /* Affiche les symboles à l'assemblage */
    OPT_SIZEOF
} ;
struct {
    int opt[OPT_SIZEOF] ; /* Table des options initiales (passage d'argument) */
    int computer ;   /* Type de machine sélectionnée */
    int soft ;       /* Type d'assembleur sélectionné */
    int symb_order ; /* Ordre d'affichage des symboles */
    int err_order ;  /* Ordre d'affichage des erreurs */
    int limit ;      /* Taille limite d'une ligne */
} scan ;


/*-------------------------------------------------------------------
 * Pour assemblage du source
 */
enum{
    SCANPASS,  /* Pass de scan */
    MACROPASS, /* Pass de macro */
    PASS1,     /* Pass 1 d'assemblage */
    PASS2      /* Pass 2 d'assemblage */
} ;
enum {
    UNLOCKED,
    IF_LOCK,
    MACRO_LOCK,
    COMMENT_LOCK = 4
} ;

struct {
    char *source ; /* Pointeur courant sur le source */
    int line ;     /* Numéro de ligne courante */
    int pass ;     /* Numéro du pass d'assemblage */
    int locked ;   /* Bloque l'enregistrement des codes machine */
    int exit ;     /* Demande l'arrêt de l'assemblage si directive 'END' */
    int size ;             /* Taille de l'assemblage */
    unsigned char code[5] ; /* Buffer d'assemblage */
    unsigned char dp ;     /* Valeur du DP */
    unsigned short pc ;    /* Valeur du PC */
    unsigned short exec ;  /* Valeur de l'adresse d'exécution */
    int regcode ;          /* Code du registre éventuel (délivré par ScanLine()) */
    int opt[OPT_SIZEOF] ;  /* Table des options courantes */
} run ;


/*-------------------------------------------------------------------
 * Pour évaluation d'opérande
 */
struct {
    int priority ;         /* Priorité de l'opérateur */
    char sign ;            /* Signe de l'opérateur */
    signed short operand ; /* Valeur opérande */
    int type ;             /* SET_VALUE/EQU_VALUE/LABEL_VALUE/MACRO_VALUE
                            * renvoyé par DoSymbol() (et donc Eval())*/
    int pass ;             /* Pass de la dernière évaluation */
} eval ;


/*-------------------------------------------------------------------
 * Pour assemblage conditionnel
 */
enum {
    IF_TRUE,
    IF_TRUE_ELSE,
    IF_FALSE,
    IF_FALSE_ELSE,
    IF_STOP
} ;
struct {
    int count ;   /* Compteur de degrés d'assemblage conditionnel */
    int buf[17] ; /* Buffer des degrés d'assemblage conditionnel */
} ifc ;


/*-------------------------------------------------------------------
 * Pour macro
 */
struct {
    int count ; /* Identificateur de macro */
    int level ; /* Degré d'appel de macro */
} macro ;


/*-------------------------------------------------------------------
 * Pour marquage 'info'
 */
struct {
    struct {
        int count ; /* Nombre de cycles de base (-1 si pas) */
        int plus ;  /* Nombre de cycles ajoutés (-1 si pas) */
        int total ; /* Total du nombre de cycles */
    } cycle ;
    int size ; /* Taille du code assemblé parcouru */
} info ;


/*-------------------------------------------------------------------
 * Pour marquage 'check'
 */
int check[4][2] ;


/*-------------------------------------------------------------------
 * Pour INCLUD
 */
struct INCLIST {
     struct INCLIST *prev ; /* Pointeur sur l'INCLUD précédent */
     int  drive ;    /* Numéro de lecteur */
     char name[13] ; /* Nom du fichier : xxxxxxxx.xxx */
     int  line  ;    /* Numéro de ligne de l'INCLUD */
     int  count ;    /* Compteur d'INCLUD */
     char *start ;   /* Pointeur sur début du code d'INCLUD */
     char *end ;     /* Pointeur sur fin du code d'INCLUD */
} ;

struct INCLIST *first_includ ;

/*-------------------------------------------------------------------
 * Liste des codes d'erreur
 */
enum {
    NO_ERROR,      /* Pas d'erreur */
    ERR_ERROR,     /* Erreur */
/* Erreurs affichées sans condition */
    ERR_DUPLICATE_MAIN,
    ERR_DUPLICATE_NAME,
    ERR_FILE_NOT_FOUND,
    ERR_ILLEGAL_CHAR,
    ERR_IO_ERROR,
    ERR_MISSING_MAIN,
    ERR_WRONG_MARK,
    ERR_EMBEDDED_MACRO,
    ____BREAK_ERROR,
/* Erreurs affichées seulement au pass 2 de l'assemblage avec
 * affichage de la ligne du source */
    ERR_BAD_ELSE,
    ERR_BAD_FILE_FORMAT,
    ERR_BAD_FILE_NAME,
    ERR_BAD_LABEL,
    ERR_BAD_MACRO_NAME,
    ERR_BAD_OPERAND,
    ERR_BAD_OPCODE,
    ERR_BAD_PARAM,
    ERR_DIVISION_BY_ZERO,
    ERR_ENDM_WITHOUT_MACRO,
    ERR_EXPRESSION_ERROR,
    ERR_IF_OUT_OF_RANGE,
    ERR_ILLEGAL_INCLUDE,
    ERR_ILLEGAL_LABEL,
    ERR_ILLEGAL_OPERAND,
    ERR_INCLUDE_OUT_OF_RANGE,
    ERR_LABEL_NAME_TOO_LONG,
    ERR_MACRO_ERROR,
    ERR_MACRO_INTO_IF_RANGE,
    ERR_MACRO_OUT_OF_RANGE,
    ERR_MISSING_ENDC,
    ERR_MISSING_IF,
    ERR_MISSING_INFORMATION,
    ERR_MISSING_LABEL,
    ERR_MISSING_OPERAND,
    ERR_MULTIPLY_DEFINED_SYMBOL,
    ERR_OPERAND_IS_MACRO,
    ERR_SYMBOL_ERROR,
    ERR_UNDEFINED_MACRO,
/* Erreurs affichées seulement au pass 2 de l'assemblage mais
 * sans afficher la ligne du source
 * Pour certaines, l'erreur n'est pas affichée en 'return'
 * pour que le pass 1 ne récupère pas une erreur dans le cas où
 * l'étiquette se trouve après le branchement, alors que le pass
 * 2 n'en récupèrera aucune si l'étiquette a été répertoriée au
 * pass 1 */
    ____NO_LINE_ERROR,
    ERR_LINE_TOO_LONG,
    ERR_0_BIT,
    ERR_5_BITS,
    ERR_8_BITS,
    ERR_BINARY_NOT_LINEAR,
    ERR_BRANCH_OUT_OF_RANGE,
    ERR_CHECK_ERROR,
    ERR_DP_ERROR,
    ERR_OPERAND_OUT_OF_RANGE,
    ERR_FORCE_TO_DP,
    ERR_LONE_SYMBOL,
    ERR_MISSING_END_STATEMENT,
    ERR_MISSING_ENDM,
    ERR_MISSING_SLASH,
    ERR_REGISTER_ERROR
} ;


/*
 * Capitalise un caractère
 */
unsigned char upper_case(char c)
{
    if((c >= 'a') && (c <= 'z'))
        c &= 0xDF ;
    return c ;
}

/*
 * Capitalise une chaîne de caractères
 */
void upper_string(char *p)
{
    while(*p != '\0')
    {
        if((*p >= 'a') && (*p <= 'z'))
            *p &= 0xDF ;
        p++ ;
    }
}


/***********************************************************************
 *
 * Analyse et copie d'une ligne du source pour scan/assemblage
 *
 ***********************************************************************/

#define COLON_300 300
#define COLON_40  40

/* Stocke la ligne suivante
 * - Les tabulations sont transformées en série d'espace
 * - La validité des caractères accentués est vérifiée
 * - La taille de la ligne est vérifiée
 */
int GetLine(void)
{
    int i ;
    int space ;
    int error = NO_ERROR ;
    int size = 0 ;

    run.source = source ;
    line = linebuffer ;
    *line = '\0' ;

    while ((size < LINE_MAX_SIZE-1)
        && (*source != 0x00)
        && (*source != 0x0A)
        && (*source != 0x0D))
    {
        /* Caractère de tabulation */
        if(*source == 0x09)
        {
            space = 7 - (size % 7) ;
            for(i=0;i<space;i++)
                *(line++) = 0x20 ;
            size += space ;
        }
        else
        /* Caractères accentués */
        if ((unsigned char)*source > 0x7F)
        {
            i = 0 ;
            while((i<16) && ((unsigned char)*source != acc_table[i])) i++ ;
            if (i == 16)
                error = ERR_ILLEGAL_CHAR ;
            *(line++) = *source ;
            size++ ;
        }
        else
        /* Caractères de commande */
        if ((unsigned char)*source < 0x20)
            error = ERR_ILLEGAL_CHAR ;
        else {
            *(line++) = *source ;
            size++ ; }
        source++ ;
    }

    /* Clôt la ligne */
    *(line++) = '\0' ;

    /* Notifie le dépassement */
    if(size > scan.limit)
        error = ERR_LINE_TOO_LONG ;

    /* Va jusqu'au bout de la ligne */
    while ((*source != 0x00)
        && (*source != 0x0A)
        && (*source != 0x0D)) {
           size++ ;
           source++ ; }
    switch(*source)
    {
        case 0x0A : if (*(source+1) == 0x0D) source++ ; break ;
        case 0x0D : if (*(source+1) == 0x0A) source++ ; break ;
    }
    source++ ;

    /* Elimine les caractères inutiles de fin de ligne */
    while (((unsigned char)*(--line) <= 0x20)
        && (size > 0)) {
        *(line) = 0x00 ;
        size-- ; }

    /* Initialise les paramètres de lignes */
    run.line++ ;
    line = linebuffer ;

    return error ;
}


/***********************************************************************
 *
 * Traitement des erreurs
 *
 ***********************************************************************/

/* La liste err_table est dans l'ordre pour l'affichage par code d'erreur */
#define ETSTRINGSIZE 24
const struct {
    char string[ETSTRINGSIZE] ; /* Message de l'erreur */
    int code ;                  /* Code de l'erreur */
  } err_table[] = {
  /* Erreurs de scan prioritaires */
    { "Missing (main)"          , ERR_MISSING_MAIN            },
    { "Duplicate (main)"        , ERR_DUPLICATE_MAIN          },
    { "Duplicate Name"          , ERR_DUPLICATE_NAME          },
    { "Line Too Long"           , ERR_LINE_TOO_LONG           },
    { "Illegal Char"            , ERR_ILLEGAL_CHAR            },
    { "Wrong Mark"              , ERR_WRONG_MARK              },
  /* Erreurs d'assemblage prioritaires (PASS1) */
    { "File Not Found"          , ERR_FILE_NOT_FOUND          },
    { "I/O Error"               , ERR_IO_ERROR                },
    { "Missing Endm"            , ERR_MISSING_ENDM            },
    { "Bad File Format"         , ERR_BAD_FILE_FORMAT         },
    { "Bad File Name"           , ERR_BAD_FILE_NAME           },
    { "Include Out Of Range"    , ERR_INCLUDE_OUT_OF_RANGE    },
  /* Erreurs d'optimisation */
    { "0 bit"                   , ERR_0_BIT                   },
    { "5 bits"                  , ERR_5_BITS                  },
    { "8 bits"                  , ERR_8_BITS                  },
    { "Lone Symbol"             , ERR_LONE_SYMBOL             },
    { "Force To DP"             , ERR_FORCE_TO_DP             },
  /* Erreurs courantes */
    { "Expression Error"        , ERR_EXPRESSION_ERROR        },
    { "Branch Out Of Range"     , ERR_BRANCH_OUT_OF_RANGE     },
    { "Bad Operand"             , ERR_BAD_OPERAND             },
    { "Bad Label"               , ERR_BAD_LABEL               },
    { "Bad Opcode"              , ERR_BAD_OPCODE              },
    { "Missing Operand"         , ERR_MISSING_OPERAND         },
    { "Multiply Defined Symbol" , ERR_MULTIPLY_DEFINED_SYMBOL },
    { "Operand Out Of Range"    , ERR_OPERAND_OUT_OF_RANGE    },
    { "Symbol Error"            , ERR_SYMBOL_ERROR            },
    { "DP Error"                , ERR_DP_ERROR                },
    { "Division By Zero"        , ERR_DIVISION_BY_ZERO        },
  /* Erreur de condition */
    { "If Out Of Range"         , ERR_IF_OUT_OF_RANGE         },
    { "Missing If"              , ERR_MISSING_IF              },
    { "Missing Endc"            , ERR_MISSING_ENDC            },
    { "Bad Else"                , ERR_BAD_ELSE                },
  /* Erreur de macro */
    { "Illegal Include"         , ERR_ILLEGAL_INCLUDE         },
    { "Bad Macro Name"          , ERR_BAD_MACRO_NAME          },
    { "Macro Error"             , ERR_MACRO_ERROR             },
    { "Macro Into If Range"     , ERR_MACRO_INTO_IF_RANGE     },
    { "Macro Out Of Range"      , ERR_MACRO_OUT_OF_RANGE      },
  /* Erreur peu courantes */
    { "Bad Param"               , ERR_BAD_PARAM               },
    { "Check Error"             , ERR_CHECK_ERROR             },
    { "Embedded Macro"          , ERR_EMBEDDED_MACRO          },
    { "Missing Information"     , ERR_MISSING_INFORMATION     },
    { "Missing Label"           , ERR_MISSING_LABEL           },
    { "Illegal Label"           , ERR_ILLEGAL_LABEL           },
    { "Label Name Too Long"     , ERR_LABEL_NAME_TOO_LONG     },
    { "Illegal Operand"         , ERR_ILLEGAL_OPERAND         },
    { "Operand Is Macro"        , ERR_OPERAND_IS_MACRO        },
    { "Register Error"          , ERR_REGISTER_ERROR          },
    { "Binary Not Linear"       , ERR_BINARY_NOT_LINEAR       },
    { "DP Error"                , ERR_DP_ERROR                },
    { "Endm Without Macro"      , ERR_ENDM_WITHOUT_MACRO      },
    { "Undefined Macro"         , ERR_UNDEFINED_MACRO         },
    { "Missing Slash"           , ERR_MISSING_SLASH           },
    { "Missing End Statement"   , ERR_MISSING_END_STATEMENT   }
} ;
#define ETSIZE (int)sizeof(err_table)/(int)sizeof(err_table[0])

struct ERRLIST {
    struct ERRLIST *next ; /* Pointeur sur section suivante */
    int error ;    /* Numéro de l'erreur */
    int line ;     /* Numéro de la ligne */
    char *source ; /* Ponteur sur la ligne du source */
} ;

struct ERRLIST *first_error ;

/*
 * Initialise le chaînage des erreurs
 *
 * Le premier élément de la liste (pointé par first_error) ne contient
 * qu'un pointeur 'next', et le numéro de sa ligne est à 0
 * Ainsi, le pointeur first_error est invariable
 */
void InitErrorChain(void)
{
    first_error = malloc(sizeof(struct ERRLIST)) ;
    first_error->line = 0 ;
    first_error->next = NULL ;
}

/*
 * Libère la mémoire pour le chaînage des erreurs
 */
void FreeErrorChain(void)
{
    struct ERRLIST *current_error ;

    while ((current_error = first_error))
    {
        first_error = first_error->next ;
        free(current_error) ;
    }
}

/*
 * Limite la taille de la ligne à afficher
 */
void MakeLimitedLine(char *formatstring)
{
    int size = LINE_MAX_SIZE - (int)strlen(formatstring) ;
    if (size > 0)
        strncat(formatstring,linebuffer,LINE_MAX_SIZE - (int)strlen(formatstring)) ;
    formatstring[LINE_MAX_SIZE] = '>' ;
    formatstring[LINE_MAX_SIZE+1] = '>' ;
    formatstring[LINE_MAX_SIZE+2] = '\0' ;
}

/*
 * Affiche une erreur pour la liste de fin d'assemblage
 */
void PrintErrorListLine(struct ERRLIST *rlist)
{
    char formatstring[LINE_MAX_SIZE+3] ;
    char fmt[30] ;

    sprintf(fmt,"%%%ds %% 7d ",ETSTRINGSIZE) ;
    sprintf(formatstring,fmt,
                         err_table[rlist->error].string,
                         rlist->line) ;
    source = rlist->source ;
    GetLine() ;
    MakeLimitedLine(formatstring) ;
    fprintf(fp_lst,"%s\n",formatstring) ;
}

/*
 * Affiche/Enregistre les erreurs pour l'assemblage
 */
int PrintError(int code)
{
    int i ;
    struct ERRLIST *current_error ;
    struct ERRLIST *found_error ;
    struct ERRLIST *new_error ;
    char formatstring[LINE_MAX_SIZE+3] ;
    char filestring[15] ;

    if ((code != NO_ERROR)
     && (code != ERR_ERROR))
    {
        /* Recherche la position de l'erreur */
        i = 0 ;
        while((i<ETSIZE) && (code != err_table[i].code)) i++ ;
        code = i ;

        /* Filtrage d'affichage
         * L'erreur doit être affichée à tous les coups ou seulement au
         * pass 2
         */
        if ((run.pass == SCANPASS)
         || (err_table[code].code < ____BREAK_ERROR)
        || ((err_table[code].code > ____BREAK_ERROR) && (run.pass == PASS2)))
        {
            /* Affiche/Enregistre l'erreur */
            filestring[0] = '\0' ;
            if ((first_includ != NULL)
             && (first_includ->count != 0))
                sprintf(filestring,"%d:%s",
                                   first_includ->drive,
                                   first_includ->name) ;
            sprintf(formatstring,"(%d)%s %s",
                                 run.line,
                                 filestring,
                                 err_table[code].string) ;
            fprintf(fp_lst,"%s\n",formatstring) ;
            printf("%s\n",formatstring) ;

            /* Affiche éventuellement la ligne du source */
            sprintf(formatstring, "% 7d ", run.line) ;
            MakeLimitedLine(formatstring) ;
            if (err_table[code].code < ____NO_LINE_ERROR)
                fprintf(fp_lst,"%s\n",formatstring) ;
            if (run.opt[OPT_WL] == FALSE)
                printf("%s\n",formatstring) ;

            /* Collecte les erreurs pour fin d'assemblage
               Le programme en profite pour ranger les erreurs dans
               l'ordre croissant des numéros de lignes */
            current_error = first_error ;
            do {
               found_error   = current_error ;
               current_error = current_error->next ;
            } while((current_error != NULL) 
                 && (current_error->line <= run.line)) ;
            new_error = malloc(sizeof(struct ERRLIST)) ;
            found_error->next = new_error ;
            new_error->next   = current_error ;
            new_error->error  = code ;
            new_error->line   = run.line ;
            new_error->source = run.source ;
        }
        code = ERR_ERROR ;
    }
    return code ;
}

enum{
    INITIAL_ORDER,
    ERROR_ORDER,
    TYPE_ORDER,
    TIME_ORDER
} ;

/*
 * Enregistre les erreurs de fin d'assemblage
 */
void PrintErrorList(void)
{
    int i = 0 ;
    struct ERRLIST *current_error ;

    current_error = first_error ;
    while((current_error = current_error->next) != NULL)
        i++ ;
    printf("\n%06d Total Errors\n",i) ;
    fprintf(fp_lst, "\n%06d Total Errors\n",i) ;

    if (i != 0)
    {
        current_error = first_error ;
        switch(scan.err_order)
        {
            case INITIAL_ORDER :
                current_error = first_error ;
                while((current_error = current_error->next) != NULL)
                    PrintErrorListLine(current_error) ;
                break ;
            case ERROR_ORDER :
                for(i=0;i<ETSIZE;i++)
                {
                    current_error = first_error ;
                    while((current_error = current_error->next) != NULL)
                        if (current_error->error == i)
                            PrintErrorListLine(current_error) ;
                }
                break ;
        }
    }
}


/***********************************************************************
 *
 * Lecture d'un argument
 *
 ***********************************************************************/

/*
 * Teste si caractère alphabétique
 */
int is_alpha(unsigned char c)
{
    switch(scan.soft)
    {
        case SOFT_ASSEMBLER :
            return ((upper_case(c) >= 'A') && (upper_case(c) <= 'Z')) ? TRUE : FALSE ;
            break ;
        default :
            return (((upper_case(c) >= 'A') && (upper_case(c) <= 'Z'))
                  || (c == '_')) ? TRUE : FALSE ;
            break ;
    }
    return FALSE ;
}

/*
 * Teste si caractère numérique
 */
int is_numeric(unsigned char c)
{
    return ((c >= '0') && (c <= '9')) ? TRUE : FALSE ;
}

/* Les valeurs de registres sont dans l'ordre pour TFR/EXG */
enum {
    REG_D = 0x00,
    REG_X,
    REG_Y,
    REG_U,
    REG_S,
    REG_PC,
    REG_A = 0x08,
    REG_B,
    REG_CC,
    REG_DP,
    REG_PCR = 0x0F,
    NUMERIC_CHAR,
    ALPHA_CHAR,
    SIGN_CHAR
} ;

/* Le bit ISREG set à déterminer s'il s'agit d'un registre hors PCR */
enum {
    END_CHAR,
    ISREG = 0x8000,
    REGS_PCR = 0x0004,
    REGS_CCDPPC = 0x8005,
    REGS_ABD,
    REGS_XYUS
} ;

int ScanLine(void)
{
    int i ;
    char *p ;
    char regbuf[4] ;
    
    const struct {
         char name[4] ; /* Nom du registre */
         int code ;     /* Code du registre */
         int group ;    /* Code du groupe du registre */
      } Regs_T[11] = {
        {   "A", REG_A  , REGS_ABD    },
        {   "B", REG_B  , REGS_ABD    },
        {   "D", REG_D  , REGS_ABD    },
        {   "X", REG_X  , REGS_XYUS   },
        {   "Y", REG_Y  , REGS_XYUS   },
        {   "U", REG_U  , REGS_XYUS   },
        {   "S", REG_S  , REGS_XYUS   },
        {  "CC", REG_CC , REGS_CCDPPC },
        {  "DP", REG_DP , REGS_CCDPPC },
        {  "PC", REG_PC , REGS_CCDPPC },
        { "PCR", REG_PCR, REGS_PCR    }
    } ;
#define RTSIZE (int)sizeof(Regs_T)/(int)sizeof(Regs_T[0])

    *arg = '\0' ;
    if (*line <= ' ') return END_CHAR ;

    /* Capture d'au moins un caractère jusqu'à fin élément */
    p = arg ;
    i = 0 ;
    if ((is_alpha(*line) == TRUE) || (is_numeric(*line) == TRUE))
    {
        while (((is_alpha(*line) == TRUE) || (is_numeric(*line) == TRUE)) && (i < 41))
        {
            *(p++) = *(line++) ;
            i++ ;
        }
        while ((is_alpha(*line) == TRUE) || (is_numeric(*line) == TRUE))
            line++ ;
    }
    else *(p++) = *(line++) ;

    *p = '\0' ;

    /* Si alphabétique */
    if (is_alpha(*arg) == TRUE)
    {
        if ((int)strlen(arg) < 4)
        {
            regbuf[0] = '\0' ;
            strcat(regbuf,arg) ;
            upper_string(regbuf) ;
            for(i=0;i<RTSIZE;i++)
                if (!strcmp(regbuf,Regs_T[i].name)) {
                    run.regcode = Regs_T[i].code ;
                    return (Regs_T[i].group) ; }
        }
        return ALPHA_CHAR ;
    }

    /* Si numérique */
    if (is_numeric(*arg) == TRUE) return NUMERIC_CHAR ;

    /* Sinon, signe */
    return SIGN_CHAR ;
}


/***********************************************************************
 *
 * Enregistrement de la ligne de code dans le listing
 *
 ***********************************************************************/

#define CODE_STRING_SIZE 18

enum{
    PRINT_EMPTY,
    PRINT_LINE,
    PRINT_NO_CODE,
    PRINT_BYTES,
    PRINT_BYTES_ONLY,
    PRINT_WORDS,
    PRINT_WORDS_ONLY,
    PRINT_PC,
    PRINT_LIKE_END,
    PRINT_LIKE_DP,
    PRINT_ONE_FOR_ONE,
    PRINT_TWO_FOR_TWO,
    PRINT_TWO_FOR_THREE,
    PRINT_THREE_FOR_THREE,
    PRINT_THREE_FOR_FOUR
} ;

/*
 * Enregistre la ligne de code
 */
int RecordLine(int drawmode)
{
    int i ;
    int size ;
    char opcodestring[5] ;
    char bytestring[6] ;
    char codestring[CODE_STRING_SIZE+2] ;
    char cyclestring[6] ;
    char formatstring[LINE_MAX_SIZE+3] ;
    char fmt[20] ;

    if (run.pass != PASS2) return NO_ERROR ;

    if (run.locked) drawmode = PRINT_NO_CODE ;

    /* Prépare la chaîne de l'opcode */
    if (run.code[0])
        sprintf(opcodestring,"%02X%02X",run.code[0],run.code[1]) ;
    else
        sprintf(opcodestring,"%02X  ",run.code[1]) ;

    /* Prépare la chaîne des cycles */
    cyclestring[0] = '\0' ;
    if ((drawmode != PRINT_NO_CODE) && (info.cycle.count != -1))
    {
        if (info.cycle.plus != -1)
            sprintf(cyclestring,"%d+%d",
                                info.cycle.count,
                                info.cycle.plus) ;
        else
            sprintf(cyclestring,"%d",info.cycle.count) ;
    }

    formatstring[0] = '\0' ;
    codestring[0] = '\0' ;
    
    switch(drawmode)
    {
        case PRINT_EMPTY :
        case PRINT_NO_CODE :
            break ;
        case PRINT_BYTES :
        case PRINT_BYTES_ONLY :
        case PRINT_WORDS :
        case PRINT_WORDS_ONLY :
            size = ((drawmode == PRINT_BYTES) || (drawmode == PRINT_BYTES_ONLY)) ? 1 : 2 ;
            sprintf(codestring,"%04X ",run.pc) ;
            for(i=0;i<run.size;i+=size)
            {
                if (i != 0) strcat(codestring," ") ;
                if (size == 1)
                    sprintf(bytestring,"%02X",run.code[i+1]) ;
                else
                    sprintf(bytestring,"%02X%02X",run.code[i+1],run.code[i+2]) ;
                strcat(codestring,bytestring) ;
            }
            break ;
        case PRINT_PC :
            sprintf(codestring,"%04X",run.pc) ;
            break ;
        case PRINT_LIKE_END :
            sprintf(codestring,"%10s%04X","",(unsigned short)eval.operand) ;
            break ;
        case PRINT_LIKE_DP :
            sprintf(codestring,"%10s%02X","",run.dp) ;
            break ;
        case PRINT_ONE_FOR_ONE :
            sprintf(codestring,"%04X %s",
                run.pc,
                opcodestring) ;
            break ;
        case PRINT_TWO_FOR_TWO :
            sprintf(codestring,"%04X %s %02X",
                run.pc,
                opcodestring,
                run.code[2]) ;
            break ;
        case PRINT_TWO_FOR_THREE :
            sprintf(codestring,"%04X %s %02X%02X",
                run.pc,
                opcodestring,
                run.code[2],
                run.code[3]) ;
            break ;
        case PRINT_THREE_FOR_THREE :
            sprintf(codestring,"%04X %s %02X %02X",
                run.pc,
                opcodestring,
                run.code[2],
                run.code[3]) ;
            break ;
        case PRINT_THREE_FOR_FOUR :
            sprintf(codestring,"%04X %s %02X %02X%02X",
                run.pc,
                opcodestring,
                run.code[2],
                run.code[3],
                run.code[4]) ;
            break ;
    }
    
    switch(drawmode)
    {
        case PRINT_EMPTY :
            sprintf(formatstring,"% 7d",run.line) ;
            break ;
        case PRINT_BYTES_ONLY :
        case PRINT_WORDS_ONLY :
            sprintf(formatstring,"%14s %s","",codestring) ;
            break ;
        default :
            sprintf(fmt,"%% 7d  %%-5s %%-%ds ",CODE_STRING_SIZE) ;
            sprintf(formatstring,fmt,run.line,cyclestring,codestring) ;
            MakeLimitedLine(formatstring) ;
            break ;
    }

    fprintf(fp_lst,"%s\n",formatstring) ;

    /* Affiche la ligne de code dans la fenêtre si WL */
    if (run.opt[OPT_WL] == TRUE)
        printf("%s\n",formatstring) ;

    return NO_ERROR ;
}


/***********************************************************************
 *
 * Opérations disque pour le fichier binaire
 *
 ***********************************************************************/

FILE *fp_bin ;

enum{
    BIN_FILE,
    LINEAR_FILE,
    HYBRID_FILE,
    DATA_FILE
} ;

struct {
    char flag ; /* Flag on/off binaire */
    size_t size ; /* Taille du hunk */
    size_t addr ; /* Adresse du hunk */
    char *data;   /* Buffer de hunk */
    int type ; /* Type de fichier : BIN_FILE/LINEAR_FILE/DATA_FILE */
    long int pos ; /* Position du header précédent */
} bin ;

/*
 * Sauve le header de fichier binaire
 */
void SaveBinHeader(char flag, size_t size, size_t addr)
{
    fputc (flag, fp_bin) ;
    fputc (size >> 8, fp_bin) ;
    fputc (size, fp_bin) ;
    fputc (addr >> 8, fp_bin) ;
    fputc (addr, fp_bin) ;
}

/*
 * Sauve éventuellement le bloc courant
 */
void SaveBinBlock(void)
{
    if (bin.size != 0)
    {
        switch (bin.type)
        {
            case DATA_FILE :
                if ((size_t)run.pc != (bin.addr + bin.size))
                    PrintError (ERR_BINARY_NOT_LINEAR) ;
                break;

            case LINEAR_FILE :
              /*                if (bin.size > 0xFFFF) */
                if ((size_t)run.pc != (bin.addr + bin.size))
                    PrintError (ERR_BINARY_NOT_LINEAR) ;
                SaveBinHeader (bin.flag, bin.size, bin.addr) ;
                break;

            default :
                SaveBinHeader (bin.flag, bin.size, bin.addr) ;
                break;
        }
        fwrite (bin.data, sizeof(char), bin.size, fp_bin) ;
    }
}


/*
 * Sauve une donnée binaire
 */
void SaveBinChar(unsigned char c)
{
    if ((run.pass == PASS2)
     && (run.locked == UNLOCKED)
     && (run.opt[OPT_NO] == FALSE))
    {
        if (((size_t)run.pc != (bin.addr + bin.size))
         || ((bin.type == BIN_FILE) && (bin.size == 0x0080))
         || (bin.size == 0xffff)
         || (bin.size == 0x0000))
        {
            /* Sauve éventuellement le bloc courant */
            SaveBinBlock() ;

            /* Initialise le bloc suivant */
            bin.flag = 0x00 ;
            bin.size = 0x0000 ;
            bin.addr = run.pc ;
        }
        bin.data[bin.size++] = c ;
    }
    run.pc++ ;
    info.size++ ;
    check[1][1]++ ;
}

/*
 * Ferme le fichier binaire
 */
void CloseBin(void)
{
    /* Sauve éventuellement le bloc courant */
    SaveBinBlock() ;

    /* Sauve éventuellement le bloc de clôture */
    if (bin.type != DATA_FILE)
        SaveBinHeader((char)0xFF,0x00,run.exec) ;
    if (bin.data != NULL)
    {
        free (bin.data);
        bin.data = NULL;
    }
    fclose(fp_bin) ;
}

/*
 * Ouvre le fichier binaire
 */
int OpenBin(char *name)
{
     bin.data = NULL;
     bin.size = 0x0000 ;
    if ((fp_bin = fopen(name,"wb")) == NULL)
        return PrintError(ERR_IO_ERROR) ;
    bin.data = (char *)malloc(65536);

    return NO_ERROR ;
}


/***********************************************************************
 *
 * Traitement des symboles
 *
 ***********************************************************************/

enum{
    ARG_VALUE,
    READ_VALUE,
    SET_VALUE,
    EQU_VALUE,
    LABEL_VALUE,
    MACRO_VALUE
} ;

struct SYMBLIST {
    struct SYMBLIST *next ;
    char name[ARG_MAX_SIZE+2] ; /* Nom du symbole */
    unsigned short value ; /* Valeur du symbole */
    int error ; /* NO_ERROR/ERR_EXPRESSION_ERROR/ERR_MULTIPLY_DEFINED_SYMBOL */
    int type ;  /* SET_VALUE/EQU_VALUE/LABEL_VALUE/MACRO_VALUE */
    int time ;  /* Compteur d'apparition */
    int pass ;  /* Numéro de pass de la dernière définition */
} ;

struct SYMBLIST *first_symbol ;

/*
 * Initialise le chaînage des symboles
 *
 * Le premier élément de la liste (pointé par first_symbol) ne contient
 * éventuellement qu'un pointeur 'next', et le premier caractère de son
 * nom est '\0'
 * Ainsi, le pointeur first_symbol est invariable
 */
void InitSymbolChain(void)
{
    first_symbol = malloc(sizeof(struct SYMBLIST)) ;
    first_symbol->next = NULL ;
    first_symbol->name[0] = '\0' ;
}

/*
 * Libère la mémoire pour le chaînage des symboles
 */
void FreeSymbolChain(void)
{
    struct SYMBLIST *current_symbol ;
    while ((current_symbol = first_symbol))
    {
        first_symbol = first_symbol->next ;
        free(current_symbol) ;
    }
}

/* Compare deux noms de symboles
 * Le programme renvoie 5 valeurs :
 * -2 = le 1er nom est inférieur (majuscule != minuscule)
 * -1 = le 1er nom est inférieur (majuscule = minuscule)
 *  0 = les deux noms sont égaux
 *  1 = le 1er nom est supérieur (majuscule = minuscule)
 *  2 = le 1er nom est supérieur (majuscule != minuscule)
 */
int CompareSymbolNames(char *string1, char *string2)
{
    int i = 0, j = 0 ;

    while((*(string1+i) != '\0')
       && (*(string2+i) != '\0')
       && (*(string1+i) == *(string2+i)))
        i++ ;

    j = i ;
    while((*(string1+j) != '\0')
       && (*(string2+j) != '\0')
       && (upper_case(*(string1+j)) == upper_case(*(string2+j))))
        j++ ;

    if (upper_case(*(string1+j)) < upper_case(*(string2+j))) return -1 ;
    if (upper_case(*(string1+j)) > upper_case(*(string2+j))) return 1 ;
    if (*(string1+i) < *(string2+i)) return -2 ;
    if (*(string1+i) > *(string2+i)) return 2 ;
    return 0 ;
}

/*
 * - Ajoute éventuellement un symbole à la liste
 * - Met éventuellement le symbole à jour
 * - Lit le symbole
 */
int DoSymbol(char *name, unsigned short value, int type)
{
    int match = 0 ;
    struct SYMBLIST *prev_symbol   = NULL ;
    struct SYMBLIST *insert_symbol = NULL ;
    struct SYMBLIST *found_symbol  = NULL ;
    struct SYMBLIST *new_symbol    = NULL ;

    /* Recherche le symbole dans la liste
     * Le programme en profite pour ranger les symboles dans l'ordre
     * alphabétique sans distinction entre majuscule et minuscule */
    insert_symbol = NULL ;
    found_symbol = first_symbol ;
    do {
        if (insert_symbol == NULL)
            prev_symbol = found_symbol ;
        if ((found_symbol = found_symbol->next) != NULL)
        {
            match = CompareSymbolNames(name,found_symbol->name) ;
            if ((match == -1) || (match == 0))
                insert_symbol = found_symbol ;
        }
    } while((found_symbol != NULL) && (match > 0)) ;

    /* Si trouvé */
    if ((found_symbol != NULL) && (match == 0))
    {
        /* Actualise le pass si argument de commande */
        if (found_symbol->type == ARG_VALUE)
            found_symbol->pass = run.pass ;

        if (type == READ_VALUE)
        {
            eval.type = (found_symbol->type == ARG_VALUE) ? EQU_VALUE : found_symbol->type ;
            eval.operand = found_symbol->value ;
            if (found_symbol->pass < run.pass)
                eval.pass = found_symbol->pass ;
            switch(run.pass)
            {
                case PASS1 :
                    found_symbol->time++ ;
                    break ;
                case PASS2 :
                    if ((found_symbol->time == 0)
                      && (run.opt[OPT_OP] == TRUE))
                        PrintError(ERR_LONE_SYMBOL) ;
                    if (found_symbol->error != NO_ERROR)
                        return PrintError(found_symbol->error) ;
                    break ;
            }
        }
        else
        {
            switch(run.pass)
            {
                case PASS1 :
                    /* Mise à jour si symbole non défini */
                    if ((found_symbol->pass) == MACROPASS)
                    {
                        found_symbol->pass  = PASS1 ; 
                        found_symbol->type  = type ;
                        found_symbol->error = NO_ERROR ;
                        found_symbol->value = value ;
                    }
                    /* Si symboles de même valeur et de même nature ou SET,
                     * mise à jour de la valeur, sinon répertorie une erreur */
                    if (((found_symbol->type == SET_VALUE)
                      || (found_symbol->value == value))
                     && (found_symbol->type == type))
                        found_symbol->value = value ;
                    else
                        found_symbol->error = ERR_MULTIPLY_DEFINED_SYMBOL ;
                    break ;
                case PASS2 :
                    /* Mise à jour du pass */
                    if ((found_symbol->pass) == PASS1)
                        found_symbol->pass = PASS2 ;
                    /* Mise à jour si SET */
                    if (found_symbol->type == SET_VALUE)
                        found_symbol->value = value ;
                    /* Affiche éventuellement l'erreur */
                    if (found_symbol->error != NO_ERROR)
                        return PrintError(found_symbol->error) ;
                    break ;
            }
        }
    }

    /* Si pas trouvé */
    else
    {
        if ((run.pass == PASS1)
         || (type == ARG_VALUE))
        {
            /* Positionne l'enregistrement dans la liste */
            new_symbol = malloc(sizeof(struct SYMBLIST)) ;
            if (insert_symbol == NULL)
                insert_symbol = prev_symbol ;
            else
            if (CompareSymbolNames(name,insert_symbol->name) < 0)
                insert_symbol = prev_symbol ;
            /* Enregistre le symbole */
            new_symbol->next = insert_symbol->next ;
            insert_symbol->next = new_symbol ;
            new_symbol->name[0] = '\0' ;
            strcat(new_symbol->name,name) ;
            new_symbol->value = value ;
            new_symbol->error = NO_ERROR ;
            new_symbol->type = type ;
            new_symbol->time = 0 ;
            new_symbol->pass = PASS1 ;
            if (type == READ_VALUE)
            {            
                new_symbol->type = EQU_VALUE ;
                new_symbol->pass = MACROPASS ;
                new_symbol->time++ ;
                new_symbol->error = ERR_EXPRESSION_ERROR ;
            }
            eval.pass = new_symbol->pass ;
            eval.type = EQU_VALUE ;
        }
        else
            return PrintError(ERR_SYMBOL_ERROR) ;
    }

    return NO_ERROR ;
}

/*
 * Enregistre une ligne de symbole de fin d'assemblage
 */
void PrintSymbolLine(struct SYMBLIST *slist)
{
    const struct {
        char string[9] ; /* Message de l'erreur */
        int type ;       /* Code de l'erreur */
      } ErrorTable[3] = {
        { "        ",  NO_ERROR                    },
        { "Unknown ",  ERR_EXPRESSION_ERROR        },
        { "Multiply",  ERR_MULTIPLY_DEFINED_SYMBOL }
    } ;

    const struct {
        char string[6] ; /* Message du type de valeur */
        int type ;       /* Type de la valeur */
      } TypeTable[6] = {
        { "Arg  ",  ARG_VALUE   },
        { "Equ  ",  EQU_VALUE   },
        { "Set  ",  SET_VALUE   },
        { "Label",  LABEL_VALUE },
        { "Macro",  MACRO_VALUE }
    } ;

    int error = 0 ;
    int type = 0 ;
    char errorstring[LINE_MAX_SIZE+2] ;

    while(slist->error != ErrorTable[error].type) error++ ;
    while(slist->type != TypeTable[type].type) type++ ;

    sprintf(errorstring, "% 6dx %s %s %04X %s",
                         slist->time,
                         ErrorTable[error].string,
                         TypeTable[type].string,
                         (unsigned short)slist->value,
                         slist->name) ;
    fprintf(fp_lst, "%s\n", errorstring) ;
    /* Affiche la ligne si WS */
    if (run.opt[OPT_WS] == TRUE)
        printf("%s\n", errorstring) ;
}


/*
 * Enregistre les symboles de fin d'assemblage
 */
void PrintSymbolList(void)
{
    int ErrorOrderList[] = {
        ERR_EXPRESSION_ERROR,
        ERR_MULTIPLY_DEFINED_SYMBOL,
        NO_ERROR
    } ;
    int TypeOrderList[]  = {
        ARG_VALUE,
        EQU_VALUE,
        SET_VALUE,
        LABEL_VALUE,
        MACRO_VALUE
    } ;
    int i = 0 ;
    int time = 0, nexttime = 0, prevtime = 0 ;
    struct SYMBLIST *current_symbol ;

    /* Compte les symboles */
    current_symbol = first_symbol ;
    while((current_symbol = current_symbol->next) != NULL) i++ ;

    /* Affiche si au moins un symbole */
    if (i)
    {
        printf("\n%06d Total Symbols\n",i) ;
        fprintf(fp_lst, "\n%06d Total Symbols\n",i) ;

        switch(scan.symb_order)
        {
            case INITIAL_ORDER :
                current_symbol = first_symbol ;
                while((current_symbol = current_symbol->next) != NULL)
                    PrintSymbolLine(current_symbol) ;
                break ;
            case ERROR_ORDER :
                for(i=0;i<3;i++)
                {
                    current_symbol = first_symbol ;
                    while((current_symbol = current_symbol->next) != NULL)
                        if (current_symbol->error == ErrorOrderList[i])
                            PrintSymbolLine(current_symbol) ;
                }
                break ;
            case TYPE_ORDER :
                for(i=0;i<5;i++)
                {
                    current_symbol = first_symbol ;
                    while((current_symbol = current_symbol->next) != NULL)
                        if (current_symbol->type == TypeOrderList[i])
                            PrintSymbolLine(current_symbol) ;
                }
                break ;
            case TIME_ORDER :
                do
                {
                    prevtime = nexttime ;
                    nexttime = 0x7FFFFFFF ;
                    current_symbol = first_symbol ;
                    while((current_symbol = current_symbol->next) != NULL)
                    {
                        if ((current_symbol->time > time)
                         && (current_symbol->time < nexttime))
                            nexttime = current_symbol->time ;
                        if (current_symbol->time == time)
                            PrintSymbolLine(current_symbol) ;
                    }
                    time = nexttime ;
                } while(nexttime != prevtime) ;
                break ;
        }
        fprintf(fp_lst,"\n") ;
    }
}


/***********************************************************************
 *
 *  Evaluateur d'opérande
 *
 ***********************************************************************/

struct EVALLIST {
    struct EVALLIST *prev ; /* Pointeur sur section précédente */
    char sign ;    /* Signe opérateur */
    int priority ; /* Priorité de l'opérateur */
    int operand ;  /* Valeur opérande */
} ;

struct EVALLIST *current_eval = NULL ;

/*
 * Ajoute un chaînage à l'évaluation
 *
 * Le premier élément de la liste
 * ne contient éventuellement qu'un
 * pointeur 'next', et sa priorité
 * de calcul est à 0
 */
void NewEvalChain(char sign, int priority, short operand)
{
    struct EVALLIST *prev_eval ;
    prev_eval = current_eval ;
    current_eval = malloc(sizeof(struct EVALLIST)) ;
    current_eval->prev     = prev_eval ;
    current_eval->sign     = sign ;
    current_eval->priority = priority ;
    current_eval->operand  = operand ;
}

/*
 * Libère un maillon du chaînage d'évaluation
 */
void DeleteEvalChain(void)
{
    struct EVALLIST *prev_eval ;
    prev_eval = current_eval->prev ;
    free(current_eval) ;
    current_eval = prev_eval ;
}

/*
 * Libère le chaînage d'évaluation
 */
int FreeEvalChain(int error)
{
    while(current_eval != NULL)
        DeleteEvalChain() ;
    return error ;
}

/*
 * Lecture d'une valeur d'opérande
 */
int ReadValue(void)
{
    int i ;
    unsigned char c ;
    char base, prefix_base, suffix_base ;
    char *p ;
    char sign = 0 ;

    eval.operand = 0 ;

    do
    {
        do
        {
            sign = '\0' ;
            /* Cas spécial de '.NOT.' */
            if (*line == '.')
            {
                p = line++ ;
                i = ScanLine() ;
                upper_string(arg) ;
                if ((i == ALPHA_CHAR)
                 && (!strcmp("NOT",arg))
                 && (*line == '.'))
                {
                    if (scan.soft != SOFT_ASSEMBLER)
                        return PrintError(ERR_EXPRESSION_ERROR) ;
                    line++ ;
                    sign = ':' ;
                }
                else line = p ;
            }
            else

            /* Repérage des opérateurs de signe */
            if ((*line == '+')
             || (*line == '-')
             || (*line == ':'))
            {
                sign = *(line++) ;
                if ((sign == ':') && (scan.soft == SOFT_ASSEMBLER))
                    return PrintError(ERR_EXPRESSION_ERROR) ;
            }
            /* Enregistre éventuellement le signe */
            if (sign)
                NewEvalChain(sign,0x80,0) ;
        } while(sign) ;

        sign = 0 ;
        if (*line == '(')
        {
            /* Enregistre la parenthèse ouvrante */
            line++ ;
            NewEvalChain('\0',0,0) ;
            sign = '(' ;
        }
    } while(sign) ;

    /* Récupération d'une valeur numérique :
     *                 (0-9, $, %, @ ou &)nombre(U, Q, O, T ou H)
     * Les bases préfixées et suffixées peuvent être déterminées
     * toutes deux, mais il y a erreur si elles ne correspondent
     * pas.
     */
    
    if ((is_numeric(*line) == TRUE)
      || (*line == '&')
      || (*line == '@')
      || (*line == '%')
      || (*line == '$'))
    {
       prefix_base = 0 ;
       if (ScanLine() == SIGN_CHAR)
       {
           switch(*arg)
           {
               case '%': prefix_base =  2 ; break ;
               case '@': prefix_base =  8 ; break ;
               case '&': prefix_base = 10 ; break ;
               case '$': prefix_base = 16 ; break ;
           }
           ScanLine() ;
       }
       suffix_base = 0 ;
       switch (upper_case(*(arg + (int)strlen(arg) - 1)))
       {
           case 'U': suffix_base = 2  ; break ;
           case 'Q':
           case 'O': suffix_base = 8  ; break ;
           case 'T': suffix_base = 10 ; break ;
           case 'H': suffix_base = 16 ; break ;
       }

       /* Le rapport préfixe/suffixe est valide si au
        * moins l'un des deux est indéfini ou s'ils
        * sont égaux */
       if ((prefix_base != 0)
        && (suffix_base != 0)
        && (suffix_base != prefix_base))
           return PrintError(ERR_EXPRESSION_ERROR) ;
       /* Base 10 si ni préfixe ni suffixe définis */
       if ((base = (prefix_base | suffix_base)) == 0) base = 10 ;
       /* Rejette le binaire pour ASSEMBLER */
       /* Erreur si pas d'opérande */
       if (((base == 2) && (scan.soft == SOFT_ASSEMBLER))
        || (((int)strlen(arg)-((suffix_base != 0) ? 1 : 0)) == 0))
           return PrintError(ERR_EXPRESSION_ERROR) ;

       for(i=0;i<(int)strlen(arg)-((suffix_base != 0) ? 1 : 0);i++)
       {
           if ((arg[i] > '9') && (arg[i] < 'A'))
               return PrintError(ERR_EXPRESSION_ERROR) ;
           c = (arg[i] < 'A') ? arg[i] -'0' : upper_case(arg[i]) -'A' + 10 ;
           if (c >= base) return PrintError(ERR_EXPRESSION_ERROR) ;
           eval.operand = (eval.operand * base) + c ;
       }
    }

    /* Récupération de la valeur du pointeur de programme
     *                 '.' ou '*' */
    else
    if ((*line == '.') || (*line == '*'))
    {
        eval.operand = run.pc ;
        line++ ;
    }

    /* Récupération d'une valeur ASCII
     *                 '[caractère]['caractère]
     * Une apostrophe sèche donne 0x0D
     * Doublet de déclaration seulement pour MACROASSEMBLER
     */
    else
    if (*line == '\'')
    {
        eval.operand = 0 ;
        for(i=0;i<2;i++)
        {
            if (*line == '\'')
            {
                line++ ;
                c = *line ;
                if (((i == 1) && (scan.soft == SOFT_ASSEMBLER))
                 || (c > 0x7F))
                    return PrintError(ERR_EXPRESSION_ERROR) ;
                if ((c == 0x00) || (c == 0x20)) c = 0x0D ;
                else {
                    if (c == CHAR127) c = 0x20 ;
                    line++ ; }
                eval.operand = (eval.operand << 8) | c ;
            }
        }
    }
    else

    /* Récupèration d'une valeur de symbole */
    if (is_alpha(*line) == TRUE)
    {
        ScanLine() ;
        if (scan.soft == SOFT_ASSEMBLER) upper_string(arg) ;
        if (DoSymbol (arg, 0, READ_VALUE) != NO_ERROR)
            return ERR_ERROR ;
        if (eval.type == MACRO_VALUE)
            return PrintError(ERR_OPERAND_IS_MACRO) ;
    }

    /* Pas de récupération possible */
    else 
        return PrintError(ERR_MISSING_OPERAND) ;

    return NO_ERROR ;
}


/*
 * Lecture d'un signe opérateur
 */

int ReadOperator(void)
{
    /* Pour NEQ, l'opérateur "|" est arbitraire, celui-ci n'existant
     * dans aucun des deux assembleurs sur Thomson
     * Il sert seulement à faciliter le repérage de l'opérateur
     * '.NOT.' est repéré mais rejeté
     */
    const struct {
        char string[4] ; /* Nom ASSEMBLER de l'opérateur */
        char sign ;      /* Signe de l'opérateur */
        int priority ;   /* Priorité de l'opérateur */
        int compatibility ; /* Compatibilté du signe avec ASSEMBLER */
      } AlphaOperator[12] = {
        { "   " , '<' , 5, TRUE  },
        { "EQU" , '=' , 1, TRUE  },
        { "DIV" , '/' , 5, TRUE  },
        { "AND" , '&' , 4, TRUE  },
        { "   " , '+' , 2, TRUE  },
        { "   " , '-' , 2, TRUE  },
        { "   " , '*' , 5, TRUE  },
        { "OR"  , '!' , 3, TRUE  },
        { "NEQ" , '|' , 1, FALSE },  /* Pas MACROASSEMBLER */
        { "NOT" , ':' , 0, FALSE },  /* Rejeté !!! */
        { "MOD" , '%' , 5, FALSE },
        { "XOR" , '^' , 3, FALSE }
    } ;

    int i = 0 ;

    if (ScanLine() != SIGN_CHAR)
        return PrintError(ERR_EXPRESSION_ERROR) ;
    if (*arg == '.')
    {
        if ((scan.soft != SOFT_ASSEMBLER)
         || (ScanLine() != ALPHA_CHAR))
            return PrintError(ERR_EXPRESSION_ERROR) ;
        upper_string(arg) ;
        i = 0 ;
        while ((i < 12) && (strcmp(AlphaOperator[i].string,arg))) i++ ;
        if ((i == 12) || (*line != '.'))
            return PrintError(ERR_EXPRESSION_ERROR) ;
        eval.sign = AlphaOperator[i].sign ;
        line++ ;
    }
    else
    {
        i = 0 ;
        while ((i < 12) && (*arg != AlphaOperator[i].sign)) i++ ;
        if ((i == 12)
         || (*arg == '|')
         || ((AlphaOperator[i].compatibility == FALSE)
          && (scan.soft == SOFT_ASSEMBLER)))
            return PrintError(ERR_EXPRESSION_ERROR) ;
        eval.sign = *arg ;
    }

    /* Rejette 'NOT' */
    if (eval.sign == ':')
        return PrintError(ERR_EXPRESSION_ERROR) ;

    eval.priority = AlphaOperator[i].priority ;

    return NO_ERROR ;
}

/*
 * Programme calculateur
 */
int CalculateEval(void)
{
    unsigned short n1 = current_eval->operand,
                   n2 = eval.operand ;

    switch(current_eval->sign)
    {
        case '+' : n1 += n2 ; break ;
        case '-' : n1 -= n2 ; break ;
        case '&' : n1 &= n2 ; break ;
        case '!' : n1 |= n2 ; break ;
        case '^' : n1 ^= n2 ; break ;
        case '=' : n1 = (n1 == n2) ? 0xFFFF : 0x0000 ;
                   break ;
        case '|' : n1 = (n1 != n2) ? 0xFFFF : 0x0000 ;
                   break ;
        case '*' : n1 *= n2 ; break ;
        case '/' : if (n2 == 0)
                       return PrintError(ERR_DIVISION_BY_ZERO) ;
                   else n1 /= n2 ;
                   break ;
        case '%' : if (n2 == 0)
                       return PrintError(ERR_DIVISION_BY_ZERO) ;
                   else n1 %= n2 ;
                   break ;
        case '<' : if ((signed short)n2 >= 0) n1 <<= n2 ; else n1 >>= (signed short)(-n2) ;
                   break ;
    }
    eval.operand = n1 ;
    return NO_ERROR ;
}



/*
 * Evaluation de l'opérande
 */
int Eval(void)
{
    struct EVALLIST *prev_eval = NULL ;
    int again = FALSE ;

    eval.pass = run.pass ;

    current_eval = malloc(sizeof(struct EVALLIST)) ;
    current_eval->prev     = NULL ;
    current_eval->sign     = '\0' ;
    current_eval->priority = 0 ;
    current_eval->operand  = 0 ;

    do
    {
        /* Récupère l'argument d'opérande */
        if (ReadValue() == ERR_ERROR)
            return FreeEvalChain(ERR_ERROR) ;

        do
        {
            again = FALSE ;

            /* Applique les opérateurs de signe */
            while(current_eval->priority == 0x80)
            {
                switch(current_eval->sign)
                {
                    case '+' : break ;
                    case '-' : eval.operand = -eval.operand ; break ;
                    case ':' : eval.operand = ~eval.operand ; break ;
                }
                DeleteEvalChain() ;
            }

            /* Exécute les parenthèses fermantes */
            if (*line == ')')
            {
               line++ ;
                /* Calcule le contenu des parenthèses*/
                while(current_eval->priority != 0)
                {
                    if (CalculateEval() != NO_ERROR)
                        return FreeEvalChain(ERR_ERROR) ;
                    eval.sign     = 0 ;
                    eval.priority = current_eval->priority ;
                    DeleteEvalChain() ;
                }
                if (current_eval->prev == NULL)
                    FreeEvalChain(PrintError(ERR_EXPRESSION_ERROR)) ;
                DeleteEvalChain() ;
                again = TRUE ;
            }
        } while(again == TRUE) ;

        again = FALSE ;
        /* Récupère opérateur si pas fin d'opérande */
        if ((*line != '\0')
         && (*line != ' ')
         && (*line != CHAR127)
         && (*line != ',')
         && (*line != ']'))
        {
            /* Récupère l'opérateur */
            if (ReadOperator() == ERR_ERROR)
                return FreeEvalChain(ERR_ERROR) ;
            /* Effectue le calcul sur les priorités fortes */
            if ((current_eval->priority != 0)
             && (eval.priority <= current_eval->priority))
            {
                while(((prev_eval = current_eval->prev) != NULL)
                    && (current_eval->priority != 0)
                    && (eval.priority <= current_eval->priority))
                {
                    if (CalculateEval() != NO_ERROR)
                        return FreeEvalChain(ERR_ERROR) ;
                    DeleteEvalChain() ;
                }
            }
            NewEvalChain(eval.sign,eval.priority,eval.operand) ;
            again = TRUE ;
        }
    } while(again == TRUE) ;

    /* Finit les calculs en fermant les sections */
    while(current_eval->prev != NULL)
    {
        /* Erreur si parenthèse ouverte */
        if (current_eval->priority == 0)
            return FreeEvalChain(PrintError(ERR_EXPRESSION_ERROR)) ;
        /* Effectue le calcul */
        if (CalculateEval() != NO_ERROR)
            return FreeEvalChain(ERR_ERROR) ;
        DeleteEvalChain() ;
    }
    return FreeEvalChain(NO_ERROR) ;
}


/***********************************************************************
 *
 * Assemblage des instructions
 *
 ***********************************************************************/
 
/*-------------------------------------------------------------------
 * Assemblage opérande pour tout type
 * Assemblage opérande pour tout type sauf immédiat
 * Assemblage opérande pour LEAx
 */
int Ass_AllType(int immediate, int lea)
{
    int extended_mode = FALSE ;
    int direct_mode   = FALSE ;
    int indirect_mode = FALSE ;

    unsigned char c = 0 ;
    int regs ;
    int mode ;
    int recordtype = PRINT_NO_CODE ;

    run.code[2] = 0x00 ;
    run.size = 2 ;

    /* Adressage immédiat */

    mode = 0 ;
    if (*line == '#')
    {
        info.cycle.count -= 2 ;
        line++ ;
        if (immediate == FALSE) return PrintError(ERR_EXPRESSION_ERROR) ;
        if(Eval() != NO_ERROR) return ERR_ERROR ;
        c = run.code[1] & 0x0F ;
        if (c == 0x03) mode = 16 ;
        else if ((c < 0x0C) && (c != 0x07)) mode = 8 ;
        else if ((c & 0x01) == 0) mode = 16 ;
        else return PrintError(ERR_BAD_OPERAND) ;
        switch(mode)
        {
            case 8 :
                run.size = 2 ;
                run.code[2] = eval.operand & 0xFF ;
                if ((eval.operand < -256) || (eval.operand > 255))
                    PrintError(ERR_OPERAND_OUT_OF_RANGE) ;
                return RecordLine(PRINT_TWO_FOR_TWO) ;
                break ;
            case 16 :
                run.size = 3 ;
                run.code[2] = eval.operand >> 8 ;
                run.code[3] = eval.operand & 0xFF ;
                return RecordLine(PRINT_TWO_FOR_THREE) ;
                break ;
            
            default :
                return PrintError(ERR_BAD_OPERAND) ;
                break ;
         }
    }

    if (*line == '<') direct_mode = TRUE ;
    if (*line == '>') extended_mode = TRUE ;
    if ((direct_mode == TRUE) || (extended_mode == TRUE)) line++ ;

    if (*line == '[') 
    {
        indirect_mode = TRUE ;
        line++ ; 
    }

    if (run.code[1] & 0x80) run.code[1] |= 0x10 ;

    /* Adressage indexé avec registre 8 bits   c,z */

    if (((upper_case(*line) == 'A')
      || (upper_case(*line) == 'B')
      || (upper_case(*line) == 'D'))
     && (*(line+1) == ','))
    {
        run.size = 2 ;
        if(lea == FALSE) run.code[1] += (immediate == TRUE) ? 0x10 : 0x60 ;

        if((direct_mode == TRUE) || (extended_mode == TRUE))
            return PrintError(ERR_BAD_OPERAND) ;

        switch(upper_case(*line))
        {
            case 'A' : run.code[2] = 0x86 ; info.cycle.plus = 1 ; break ;
            case 'B' : run.code[2] = 0x85 ; info.cycle.plus = 1 ; break ;
            case 'D' : run.code[2] = 0x8B ; info.cycle.plus = 4 ; break ;
        }
        line += 2 ;
        if (ScanLine() != REGS_XYUS)
            return PrintError(ERR_BAD_OPERAND) ;
        run.code[2] |= (run.regcode - 1) << 5 ;
        recordtype = PRINT_TWO_FOR_TWO ;
    }

    /* Adressage indexé sans offset  ,z  ,z+  ,z++  ,-z'  ,--z */

    else
    if (*line == ',')
    {
        run.size = 2 ;
        if(lea == FALSE) run.code[1] += (immediate == TRUE) ? 0x10 : 0x60 ;
        line++ ;

        if (*line == '-')
        {
            info.cycle.plus = 2 ;
            run.code[2] = 0x82 ;
            line++ ;
            if (*line == '-')
            {
                info.cycle.plus = 3 ;
                run.code[2] = 0x83 ;
                line++ ;
            }
            if (ScanLine() != REGS_XYUS)
                return PrintError(ERR_BAD_OPERAND) ;
        }
        else
        if (ScanLine() == REGS_XYUS)
        {
            info.cycle.plus = 0 ;
            run.code[2] = 0x84 ;
            if (*line == '+')
            {
                info.cycle.plus = 2 ;
                run.code[2] = 0x80 ;
                line++ ;
                if (*line == '+')
                {
                    info.cycle.plus = 3 ;
                    run.code[2] = 0x81 ;
                    line++ ;
                }
            }
        }
        else
            return PrintError(ERR_BAD_OPERAND) ;

        run.size = 2 ;
        run.code[2] |= (run.regcode - 1) << 5 ;
        if ((((run.code[2] & 0x9F) == 0x82) || ((run.code[2] & 0x9F) == 0x80))
         && (indirect_mode == TRUE))
            return PrintError(ERR_BAD_OPERAND) ;

        recordtype = PRINT_TWO_FOR_TWO ;
    }

    /* Adressage indexé avec offset  $xx,z  $xx,PCR */

    else
    {
        if (Eval() != NO_ERROR) return ERR_ERROR ;

        if(*line == ',')
        {
            if (lea == FALSE) run.code[1] += (immediate == TRUE) ? 0x10 : 0x60 ;
            line++ ;
            regs = ScanLine() ;

            /* Adressage indexé avec offset et PCR   $xx,PCR */
            if (regs == REGS_PCR)
            {
                eval.operand -= run.pc + 3 + ((run.code[0] == 0) ? 0 : 1);
                mode = ((eval.operand >= -128) && (eval.operand <= 127)) ? 8 : 16 ;
                if (eval.pass < run.pass) mode = 16 ;   /* 16 bits si non répertorié */
                if (extended_mode == TRUE) mode = 16 ;  /* 16 bits si étendu forcé */
                if (direct_mode == TRUE) mode = 8 ;     /* 8 bits si direct forcé */
                switch(mode)
                {
                    case 8 :
                        info.cycle.plus = 1 ;
                        run.size = 3 ;
                        run.code[2] = 0x8C ;
                        run.code[3] = eval.operand & 0xFF ;
                        if ((eval.operand < -128) || (eval.operand > 127))
                            PrintError(ERR_OPERAND_OUT_OF_RANGE) ;
                        recordtype = PRINT_THREE_FOR_THREE ;
                        break ;
                    case 16 :
                        eval.operand-- ;
                        info.cycle.plus = 5 ;
                        run.size = 4 ;
                        run.code[2] = 0x8D ;
                        run.code[3] = (eval.operand >> 8) & 0xFF ;
                        run.code[4] = eval.operand & 0xFF ;
                        if (((eval.operand + 1 >= -128) && (eval.operand <= 127))
                          && (run.opt[OPT_OP] == TRUE))
                            PrintError(ERR_8_BITS) ;
                        recordtype = PRINT_THREE_FOR_FOUR ;
                        break ;
                }
            }

            /* Adressage indexé avec offset  $xx,z */
            else
            if (regs == REGS_XYUS)
            {
                mode = 16 ;
                if ((eval.operand >= -128) && (eval.operand <= 127)) mode = 8 ;
                if ((eval.operand >= -16)  && (eval.operand <= 15))  mode = 5 ;
                if (0 && /* sam: disabled */
					eval.pass < run.pass)  mode = 16 ;  /* 16 bits si non répertorié */
                if (extended_mode == TRUE) mode = 16 ;  /* 16 bits si étendu forcé */
                if (direct_mode == TRUE)   mode = 8 ;   /* 8 bits si direct forcé */
                if ((mode == 5) && (indirect_mode == TRUE)) mode = 8 ;
                switch(mode)
                {
                    case 5 :
                        info.cycle.plus = 1 ;
                        run.size = 2 ;
                        run.code[2] = 0x00 | (eval.operand & 0x1F) ;
                        recordtype = PRINT_TWO_FOR_TWO ;
                        break ;
                    case 8 :
                        info.cycle.plus = 1 ;
                        run.size = 3 ;
                        run.code[2] = 0x88 ;
                        run.code[3] = eval.operand & 0xFF ;
                        if ((eval.operand < -128) || (eval.operand > 127))
                            PrintError(ERR_OPERAND_OUT_OF_RANGE) ;
                        recordtype = PRINT_THREE_FOR_THREE ;
                        break ;
                    case 16 :
                        info.cycle.plus = 4 ;
                        run.size = 4 ;
                        run.code[2] = 0x89 ;
                        run.code[3] = (eval.operand >>  8) & 0xFF ;
                        run.code[4] = eval.operand & 0xFF ;
                        recordtype = PRINT_THREE_FOR_FOUR ;
                        break ;
                }
                if ((run.opt[OPT_OP] == TRUE))
                {
                    if ((eval.operand == 0)
                     && (mode > 0)
                     && (indirect_mode == FALSE))
                        PrintError(ERR_0_BIT) ;
                    else
                    if ((eval.operand >= -16)
                     && (eval.operand <= 15)
                     && (mode > 5)
                     && (indirect_mode == FALSE)) 
                        PrintError(ERR_5_BITS) ;
                    else
                    if ((eval.operand >= -128)
                     && (eval.operand <= 127)
                     && (mode > 8))
                        PrintError(ERR_8_BITS) ;
                }
                run.code[2] |= (run.regcode - 1) << 5 ;
            }
            else return PrintError(ERR_BAD_OPERAND) ;
        }
        else 
        {
            /* Adressage direct et étendu */
            if (lea == TRUE)
                return PrintError(ERR_BAD_OPERAND) ;

            mode = 16 ;
            if (((eval.operand >> 8) & 0xFF) == run.dp) mode = 8 ; /* 8 bits si MSB = DP */
            if (indirect_mode == TRUE) mode = 16 ;  /* 16 bits si mode indirect */
            if (eval.pass < run.pass)  mode = 16 ;  /* 16 bits si non répertorié */
            if (extended_mode == TRUE) mode = 16 ;  /* 16 bits si étendu forcé */
            if (direct_mode == TRUE)   mode = 8  ;  /* 8 bits si direct forcé */
            switch(mode)
            {
                case 8 :
                    run.size = 2 ;
                    run.code[2] = eval.operand & 0xFF ;
                    if (indirect_mode == TRUE)
                        return PrintError(ERR_BAD_OPERAND) ;
                    if (((eval.operand >> 8) & 0xFF) != run.dp)
                        PrintError(ERR_DP_ERROR) ;
                    recordtype = PRINT_TWO_FOR_TWO ;
                    break ;
                case 16 :
                    if (indirect_mode == FALSE)
                    {
                        info.cycle.count++ ;
                        run.size = 3 ;
                        run.code[1] |= (immediate == TRUE) ? 0x30 : 0x70 ;
                        run.code[2] = (eval.operand >> 8) & 0xFF ;
                        run.code[3] = eval.operand & 0xFF ;
                        if ((((eval.operand >> 8) & 0xFF) == run.dp)
                          && (run.opt[OPT_OP] == TRUE))
                            PrintError(ERR_FORCE_TO_DP) ;
                        recordtype = PRINT_TWO_FOR_THREE ;
                    } else {
                        info.cycle.plus = 2;
                        run.size = 4 ;
                        if (lea == FALSE) run.code[1] += (immediate == TRUE) ? 0x10 : 0x60 ;
                        run.code[2] = 0x9F ;
                        run.code[3] = (eval.operand >> 8) & 0xFF ;
                        run.code[4] = eval.operand & 0xFF ;
                        recordtype = PRINT_THREE_FOR_FOUR ;
                    }
                    break ;
            }
        }
    }

    /* Vérifie la présence d'un ']' pour le mode indirect */
    if (indirect_mode == TRUE)
    {
        info.cycle.plus += (info.cycle.plus == -1) ? 4 : 3 ;
        run.code[2] |= 0x10 ;
        if(*line != ']')
            return PrintError(ERR_BAD_OPERAND) ;
        line++ ;
    }
    return RecordLine(recordtype) ;
}

/*
 * Assemblage opérande pour tout type
 */
int Ass_All (void)
{
    return Ass_AllType (TRUE, FALSE) ;
}

/*
 * Assemblage opérande pour tout type sauf immédiat
 */
int Ass_NotImmed (void)
{
    return Ass_AllType (FALSE, FALSE) ;
}

/*
 * Assemblage opérande pour LEAx
 */
int Ass_Lea (void)
{
    return Ass_AllType (FALSE, TRUE) ;
}

/*-------------------------------------------------------------------
 * Assemblage opérande pour immédiat
 */
int Ass_Immediate(void)
{
    run.size = 2 ;
    if (*line != '#')
        return PrintError(ERR_BAD_OPERAND) ;
    line++ ;
    if (Eval()) return ERR_ERROR ;
    if ((eval.operand < -256) || (eval.operand > 255))
        PrintError(ERR_OPERAND_OUT_OF_RANGE) ;
    run.code[2] = eval.operand ;
    return RecordLine(PRINT_TWO_FOR_TWO) ;
}

/*-------------------------------------------------------------------
 * Assemblage opérande pour TFR/EXG
 */
int Ass_Transfer(void)
{
    run.size = 2 ;
    /* Premier registre */
    if ((ScanLine() & ISREG) == 0)
        return PrintError(ERR_BAD_OPERAND) ;
    run.code[2] = run.regcode << 4 ;
    /* Passe la virgule */
    if (*line++ != ',')
        return PrintError(ERR_BAD_OPERAND) ;
    /* Deuxième registre */
    if ((ScanLine() & ISREG) == 0)
        return PrintError(ERR_BAD_OPERAND) ;
    run.code[2] |= run.regcode ;
    /* Vérifie si erreur de registre
     * Les bits 3 et 7 sont les bits de taille des registres
     * Par masquage, on doit donc obtenir ou 0x88 ou 0x00 */
    if (((run.code[2] & 0x88) != 0x00)
     && ((run.code[2] & 0x88) != 0x88))
        PrintError(ERR_REGISTER_ERROR) ;
    return RecordLine(PRINT_TWO_FOR_TWO) ;
}

/*-------------------------------------------------------------------
 * Assemblage opérande pour PSHx/PULx
 */
int Ass_Stack(int exclude)
{
    unsigned char StackTable[10] = {
        0x06,   /* D  = 0x00 */
        0x10,   /* X  = 0x01 */
        0x20,   /* Y  = 0x02 */
        0x40,   /* U  = 0x03 */
        0x40,   /* S  = 0x04 */
        0x80,   /* PC = 0x05 */
        0x02,   /* A  = 0x08 */
        0x04,   /* B  = 0x09 */
        0x01,   /* CC = 0x0A */
        0x08    /* DP = 0x0B */
    } ;

    int reg = 0;

    info.cycle.plus = 0 ;
    run.code[2] = 0 ;
    run.size = 2 ;
    do
    {
        /* Erreur si pas registre */
        if ((ScanLine() & ISREG) == 0)
            return PrintError(ERR_BAD_OPERAND) ;
        /* Complète l'opérande */
        reg = (run.regcode > REG_PC) ? run.regcode - 2 : run.regcode ;
        if ((run.code[2] & StackTable[reg]) != 0)
            PrintError(ERR_REGISTER_ERROR) ;
        info.cycle.plus += (run.regcode > REG_PC) ? 1 : 2 ;
        run.code[2] |= StackTable[reg] ;
        /* Exclut U pour PULU/PSHU et S pour PULS/PSHS */
        if (run.regcode == exclude)
            return PrintError(ERR_BAD_OPERAND) ;
    } while (*(line++) == ',') ;
    line--;
    if (ScanLine() != END_CHAR)
        return PrintError(ERR_BAD_OPERAND) ;
    return RecordLine(PRINT_TWO_FOR_TWO) ;
}

/*
 * Assemblage opérande pour PSHS/PULS
 */
int Ass_SStack(void)
{
    return Ass_Stack(REG_S) ;
}

/*
 * Assemblage opérande pour PSHS/PULS
 */
int Ass_UStack(void)
{
    return Ass_Stack(REG_U) ;
}

/*-------------------------------------------------------------------
 * Assemblage opérande pour inhérent
 */
int Ass_Inherent(void)
{
    run.size = 1 ;
    return RecordLine(PRINT_ONE_FOR_ONE) ;
}

/*-------------------------------------------------------------------
 * Assemblage opérande pour branchements courts
 */
int Ass_ShortBr(void)
{
    if (Eval() != NO_ERROR) return ERR_ERROR ;
    run.size = 2 ;
    run.code[2] = 0xFE ;
    eval.operand -= run.pc + run.size ;
    if ((eval.operand < -128) || (eval.operand > 127))
        PrintError(ERR_BRANCH_OUT_OF_RANGE) ;
    else
        run.code[2] = eval.operand & 0xFF ;
    return RecordLine(PRINT_TWO_FOR_TWO) ;
}

/*-------------------------------------------------------------------
 * Assemblage opérande pour branchements longs
 */
int Ass_LongBr(void)
{
    if (Eval() != NO_ERROR) return ERR_ERROR ;
    run.size = 3 ;
    run.code[2] = 0xFF ;
    run.code[3] = 0xFD ;
    eval.operand -= run.pc + run.size + ((run.code[0] != 0) ? 1 : 0) ;
    if (((eval.operand >= -128) && (eval.operand <= 127))
      && (run.opt[OPT_OP] == TRUE))
        PrintError(ERR_8_BITS) ;
    run.code[2] = (eval.operand >> 8) & 0xFF ;
    run.code[3] = eval.operand & 0xFF ;
    return RecordLine(PRINT_TWO_FOR_THREE) ;
}

/*-------------------------------------------------------------------
 * Liste des instructions
 */
const struct {
     char name[7] ;       /* Nom de l'instruction */
     unsigned char page ; /* Flag de page (0x00, 0x10 ou 0x11) */
     unsigned char code ; /* Code de l'instruction */
     int cycles ;         /* Base de cycles */
     int ifuppercase ;    /* Pour création de fichiers Assembler
                           * TRUE  = Opérande
                           * FALSE = Pas d'opérande */
     int (*prog)(void) ;  /* Programme de traitement */
  } inst_table[] = {
     { "ABX"  , 0x00, 0x3A,  3, FALSE, Ass_Inherent  },
     { "ADCA" , 0x00, 0x89,  4, TRUE , Ass_All       },
     { "ADCB" , 0x00, 0xC9,  4, TRUE , Ass_All       },
     { "ADDA" , 0x00, 0x8B,  4, TRUE , Ass_All       }, 
     { "ADDB" , 0x00, 0xCB,  4, TRUE , Ass_All       }, 
     { "ADDD" , 0x00, 0xC3,  6, TRUE , Ass_All       }, 
     { "ANDA" , 0x00, 0x84,  4, TRUE , Ass_All       }, 
     { "ANDB" , 0x00, 0xC4,  4, TRUE , Ass_All       }, 
     { "ANDCC", 0x00, 0x1C,  2, TRUE , Ass_Immediate },
     { "ASLA" , 0x00, 0x48,  2, FALSE, Ass_Inherent  },
     { "ASLB" , 0x00, 0x58,  2, FALSE, Ass_Inherent  },
     { "ASL"  , 0x00, 0x08,  6, TRUE , Ass_NotImmed  },
     { "ASRA" , 0x00, 0x47,  2, FALSE, Ass_Inherent  },
     { "ASRB" , 0x00, 0x57,  2, FALSE, Ass_Inherent  },
     { "ASR"  , 0x00, 0x07,  6, TRUE , Ass_NotImmed  },
     { "BITA" , 0x00, 0x85,  4, TRUE , Ass_All       }, 
     { "BITB" , 0x00, 0xC5,  4, TRUE , Ass_All       }, 
     { "BRA"  , 0x00, 0x20,  3, TRUE , Ass_ShortBr   },
     { "BRN"  , 0x00, 0x21,  3, TRUE , Ass_ShortBr   },
     { "BHI"  , 0x00, 0x22,  3, TRUE , Ass_ShortBr   },
     { "BLS"  , 0x00, 0x23,  3, TRUE , Ass_ShortBr   },
     { "BCC"  , 0x00, 0x24,  3, TRUE , Ass_ShortBr   },
     { "BHS"  , 0x00, 0x24,  3, TRUE , Ass_ShortBr   },
     { "BCS"  , 0x00, 0x25,  3, TRUE , Ass_ShortBr   },
     { "BLO"  , 0x00, 0x25,  3, TRUE , Ass_ShortBr   },
     { "BNE"  , 0x00, 0x26,  3, TRUE , Ass_ShortBr   },
     { "BEQ"  , 0x00, 0x27,  3, TRUE , Ass_ShortBr   },
     { "BVC"  , 0x00, 0x28,  3, TRUE , Ass_ShortBr   },
     { "BVS"  , 0x00, 0x29,  3, TRUE , Ass_ShortBr   },
     { "BPL"  , 0x00, 0x2A,  3, TRUE , Ass_ShortBr   },
     { "BMI"  , 0x00, 0x2B,  3, TRUE , Ass_ShortBr   },
     { "BGE"  , 0x00, 0x2C,  3, TRUE , Ass_ShortBr   },
     { "BLT"  , 0x00, 0x2D,  3, TRUE , Ass_ShortBr   },
     { "BGT"  , 0x00, 0x2E,  3, TRUE , Ass_ShortBr   },
     { "BLE"  , 0x00, 0x2F,  3, TRUE , Ass_ShortBr   },
     { "BSR"  , 0x00, 0x8D,  7, TRUE , Ass_ShortBr   },
     { "CLRA" , 0x00, 0x4F,  2, FALSE, Ass_Inherent  },
     { "CLRB" , 0x00, 0x5F,  2, FALSE, Ass_Inherent  },
     { "CLR"  , 0x00, 0x0F,  6, TRUE , Ass_NotImmed  },
     { "CMPA" , 0x00, 0x81,  4, TRUE , Ass_All       }, 
     { "CMPB" , 0x00, 0xC1,  4, TRUE , Ass_All       }, 
     { "CMPD" , 0x10, 0x83,  7, TRUE , Ass_All       }, 
     { "CMPS" , 0x11, 0x8C,  7, TRUE , Ass_All       }, 
     { "CMPU" , 0x11, 0x83,  7, TRUE , Ass_All       }, 
     { "CMPX" , 0x00, 0x8C,  6, TRUE , Ass_All       }, 
     { "CMPY" , 0x10, 0x8C,  7, TRUE , Ass_All       }, 
     { "COMA" , 0x00, 0x43,  2, FALSE, Ass_Inherent  },
     { "COMB" , 0x00, 0x53,  2, FALSE, Ass_Inherent  },
     { "COM"  , 0x00, 0x03,  6, TRUE , Ass_NotImmed  },
     { "CWAI" , 0x00, 0x3C, 20, TRUE , Ass_Immediate },
     { "DAA"  , 0x00, 0x19,  2, FALSE, Ass_Inherent  },
     { "DECA" , 0x00, 0x4A,  2, FALSE, Ass_Inherent  },
     { "DECB" , 0x00, 0x5A,  2, FALSE, Ass_Inherent  },
     { "DEC"  , 0x00, 0x0A,  6, TRUE , Ass_NotImmed  },
     { "EORA" , 0x00, 0x88,  4, TRUE , Ass_All       }, 
     { "EORB" , 0x00, 0xC8,  4, TRUE , Ass_All       }, 
     { "EXG"  , 0x00, 0x1E,  8, TRUE , Ass_Transfer  },
     { "INCA" , 0x00, 0x4C,  2, FALSE, Ass_Inherent  },
     { "INCB" , 0x00, 0x5C,  2, FALSE, Ass_Inherent  },
     { "INC"  , 0x00, 0x0C,  6, TRUE , Ass_NotImmed  },
     { "JMP"  , 0x00, 0x0E,  3, TRUE , Ass_NotImmed  },
     { "JSR"  , 0x00, 0x9D,  7, TRUE , Ass_All       }, 
     { "LBRA" , 0x00, 0x16,  5, TRUE , Ass_LongBr    },
     { "LBRN" , 0x10, 0x21,  5, TRUE , Ass_LongBr    },
     { "LBHI" , 0x10, 0x22,  6, TRUE , Ass_LongBr    },
     { "LBLS" , 0x10, 0x23,  6, TRUE , Ass_LongBr    },
     { "LBCC" , 0x10, 0x24,  6, TRUE , Ass_LongBr    },
     { "LBHS" , 0x10, 0x24,  6, TRUE , Ass_LongBr    },
     { "LBCS" , 0x10, 0x25,  6, TRUE , Ass_LongBr    },
     { "LBLO" , 0x10, 0x25,  6, TRUE , Ass_LongBr    },
     { "LBNE" , 0x10, 0x26,  6, TRUE , Ass_LongBr    },
     { "LBEQ" , 0x10, 0x27,  6, TRUE , Ass_LongBr    },
     { "LBVC" , 0x10, 0x28,  6, TRUE , Ass_LongBr    },
     { "LBVS" , 0x10, 0x29,  6, TRUE , Ass_LongBr    },
     { "LBPL" , 0x10, 0x2A,  6, TRUE , Ass_LongBr    },
     { "LBMI" , 0x10, 0x2B,  6, TRUE , Ass_LongBr    },
     { "LBGE" , 0x10, 0x2C,  6, TRUE , Ass_LongBr    },
     { "LBLT" , 0x10, 0x2D,  6, TRUE , Ass_LongBr    },
     { "LBGT" , 0x10, 0x2E,  6, TRUE , Ass_LongBr    },
     { "LBLE" , 0x10, 0x2F,  6, TRUE , Ass_LongBr    },
     { "LBSR" , 0x00, 0x17,  9, TRUE , Ass_LongBr    },
     { "LDA"  , 0x00, 0x86,  4, TRUE , Ass_All       }, 
     { "LDB"  , 0x00, 0xC6,  4, TRUE , Ass_All       }, 
     { "LDD"  , 0x00, 0xCC,  5, TRUE , Ass_All       }, 
     { "LDS"  , 0x10, 0xCE,  6, TRUE , Ass_All       }, 
     { "LDU"  , 0x00, 0xCE,  5, TRUE , Ass_All       }, 
     { "LDX"  , 0x00, 0x8E,  5, TRUE , Ass_All       }, 
     { "LDY"  , 0x10, 0x8E,  6, TRUE , Ass_All       }, 
     { "LEAS" , 0x00, 0x32,  4, TRUE , Ass_Lea       },
     { "LEAU" , 0x00, 0x33,  4, TRUE , Ass_Lea       },
     { "LEAX" , 0x00, 0x30,  4, TRUE , Ass_Lea       },
     { "LEAY" , 0x00, 0x31,  4, TRUE , Ass_Lea       },
     { "LSLA" , 0x00, 0x48,  2, FALSE, Ass_Inherent  },
     { "LSLB" , 0x00, 0x58,  2, FALSE, Ass_Inherent  },
     { "LSL"  , 0x00, 0x08,  6, TRUE , Ass_NotImmed  },
     { "LSRA" , 0x00, 0x44,  2, FALSE, Ass_Inherent  },
     { "LSRB" , 0x00, 0x54,  2, FALSE, Ass_Inherent  },
     { "LSR"  , 0x00, 0x04,  6, TRUE , Ass_NotImmed  },
     { "MUL"  , 0x00, 0x3D, 11, FALSE, Ass_Inherent  },
     { "NEGA" , 0x00, 0x40,  2, FALSE, Ass_Inherent  },
     { "NEGB" , 0x00, 0x50,  2, FALSE, Ass_Inherent  },
     { "NEG"  , 0x00, 0x00,  6, TRUE , Ass_NotImmed  },
     { "NOP"  , 0x00, 0x12,  2, FALSE, Ass_Inherent  },
     { "ORA"  , 0x00, 0x8A,  4, TRUE , Ass_All       }, 
     { "ORB"  , 0x00, 0xCA,  4, TRUE , Ass_All       }, 
     { "ORCC" , 0x00, 0x1A,  2, TRUE , Ass_Immediate },
     { "PSHS" , 0x00, 0x34,  5, TRUE , Ass_SStack    },
     { "PSHU" , 0x00, 0x36,  5, TRUE , Ass_UStack    },
     { "PULS" , 0x00, 0x35,  5, TRUE , Ass_SStack    },
     { "PULU" , 0x00, 0x37,  5, TRUE , Ass_UStack    },
     { "ROLA" , 0x00, 0x49,  2, FALSE, Ass_Inherent  },
     { "ROLB" , 0x00, 0x59,  2, FALSE, Ass_Inherent  },
     { "ROL"  , 0x00, 0x09,  6, TRUE , Ass_NotImmed  },
     { "RORA" , 0x00, 0x46,  2, FALSE, Ass_Inherent  },
     { "RORB" , 0x00, 0x56,  2, FALSE, Ass_Inherent  },
     { "ROR"  , 0x00, 0x06,  6, TRUE , Ass_NotImmed  },
     { "RTI"  , 0x00, 0x3B, 15, FALSE, Ass_Inherent  },
     { "RTS"  , 0x00, 0x39,  5, FALSE, Ass_Inherent  },
     { "SBCA" , 0x00, 0x82,  4, TRUE , Ass_All       }, 
     { "SBCB" , 0x00, 0xC2,  4, TRUE , Ass_All       }, 
     { "SEX"  , 0x00, 0x1D,  2, FALSE, Ass_Inherent  },
     { "STA"  , 0x00, 0x97,  4, TRUE , Ass_All       }, 
     { "STB"  , 0x00, 0xD7,  4, TRUE , Ass_All       }, 
     { "STD"  , 0x00, 0xDD,  5, TRUE , Ass_All       }, 
     { "STS"  , 0x10, 0xDF,  6, TRUE , Ass_All       }, 
     { "STU"  , 0x00, 0xDF,  5, TRUE , Ass_All       }, 
     { "STX"  , 0x00, 0x9F,  5, TRUE , Ass_All       }, 
     { "STY"  , 0x10, 0x9F,  6, TRUE , Ass_All       }, 
     { "SUBA" , 0x00, 0x80,  4, TRUE , Ass_All       }, 
     { "SUBB" , 0x00, 0xC0,  4, TRUE , Ass_All       }, 
     { "SUBD" , 0x00, 0x83,  6, TRUE , Ass_All       }, 
     { "SWI"  , 0x00, 0x3F, 19, FALSE, Ass_Inherent  },
     { "SWI2" , 0x10, 0x3F, 20, FALSE, Ass_Inherent  },
     { "SWI3" , 0x11, 0x3F, 20, FALSE, Ass_Inherent  },
     { "SYNC" , 0x00, 0x13,  4, FALSE, Ass_Inherent  },
     { "TFR"  , 0x00, 0x1F,  6, TRUE , Ass_Transfer  },
     { "TSTA" , 0x00, 0x4D,  2, FALSE, Ass_Inherent  },
     { "TSTB" , 0x00, 0x5D,  2, FALSE, Ass_Inherent  },
     { "TST"  , 0x00, 0x0D,  6, TRUE , Ass_NotImmed  }
};
#define ITSIZE (int)sizeof(inst_table)/(int)sizeof(inst_table[0])


/***********************************************************************
 *
 * Assemblage des directives
 *
 ***********************************************************************/
 
/*
 * Récupération d'un descripteur de fichier
 */
struct {
    int drive ;     /* Numéro du lecteur */
    char name[14] ; /* Nom du fichier : xxxxxxxx.xxx */
} desc ;

int GetDescriptor(char *suffix)
{
    int i ;

    if ((*line != '\0')
     && (*(line+1) == ':'))
    {
        if ((*line <= '0') && (*line > '4'))
            return PrintError(ERR_BAD_FILE_NAME) ;
        desc.drive = *line - '0' ;
        line += 2 ;
    }

    desc.name[0] = '\0' ;
    for(i=0;i<9;i++)
    {
        if ((*line == 0x20)
         || (*line == 0x00)
         || (*line == CHAR127)
         || (*line == '.'))
            break ;
        if ((*line == '(')
         || (*line == ')')
         || (*line == ':')
         || ((*line & 0xFF) > 0x7F))
            return PrintError(ERR_BAD_FILE_NAME) ;
        strncat(desc.name,line++,1) ;
    }

    if ((i > 8) || (i == 0))
        return PrintError(ERR_BAD_FILE_NAME) ;

    if (*line == '.')
    {
        strcat(desc.name,".") ;
        line++ ;
        for(i=0;i<4;i++)
        {
            if ((*line == 0x20)
             || (*line == CHAR127)
             || (*line == 0x00))
                break ;
            if ((*line == '(')
             || (*line == ')')
             || (*line == ':')
             || (*line == '.')
             || ((*line & 0xFF) > 0x7F))
                return PrintError(ERR_BAD_FILE_NAME) ;
            strncat(desc.name,line++,1) ;
        }
        if (i > 3)
            return PrintError(ERR_BAD_FILE_NAME) ;
    }
    else
    {
        strcat(desc.name,".") ;
        strcat(desc.name,suffix) ;
    }

    return NO_ERROR ;
}

/*-------------------------------------------------------------------
 * Assemblage des directives Fill
 */

enum{
    FCB_TYPE,
    FCC_TYPE,
    FCN_TYPE,
    FCS_TYPE,
    FDB_TYPE
} ;

/*
 * Enregistre la liste des codes
 */
int RecordFC(int flag, int type)
{
    int i ;
    if (run.size != 0)
    {
        RecordLine(flag) ;
        flag = (type == FDB_TYPE) ? PRINT_WORDS_ONLY : PRINT_BYTES_ONLY ;
        for(i=0;i<run.size;i++)
            SaveBinChar(run.code[i+1]) ;
        run.size = 0 ;
    }
    return flag ;
}

/*
 * Enregistre la liste des codes si buffer plein
 */
int RecordFCIf(unsigned char c, int flag, int type)
{
    if(run.size == 4)
        flag = RecordFC(flag,type) ;
    run.code[++run.size] = c ;
    return flag ;
}

int Ass_All_FC(int type)
{
    int i ;
    int flag = (type == FDB_TYPE) ? PRINT_WORDS : PRINT_BYTES ;
    int flagexit = FALSE ;
    unsigned char charend = '\0' ;
    
    char asciitable[][2] = {
        "Kc",    /* c cédille      */
        "Ba",    /* a accent aigu  */
        "Ca",    /* a accent circ  */
        "Ha",    /* a tréma        */
        "Aa",    /* a accent grave */
        "Be",    /* e accent aigu  */
        "Ce",    /* e accent circ  */
        "He",    /* e tréma        */
        "Ae",    /* e accent grave */
        "Ci",    /* i accent circ  */
        "Hi",    /* i tréma        */
        "Co",    /* o accent circ  */
        "Ho",    /* o tréma        */
        "Cu",    /* u accent circ  */
        "Hu",    /* u tréma        */
        "Au"     /* u accent grave */
    } ;

    run.size = 0 ;

    if ((type != FCB_TYPE) && (type != FDB_TYPE))
    {
        if (*line == '\0')
            return PrintError(ERR_MISSING_INFORMATION) ;
        else
            charend = *(line++) ;
    }

    do
    {
        switch(type)
        {
            case FCB_TYPE :
                if (Eval() != NO_ERROR) return ERR_ERROR ;
                if ((eval.operand < -256 ) || (eval.operand > 255))
                    PrintError(ERR_OPERAND_OUT_OF_RANGE) ;
                flag = RecordFCIf(eval.operand & 0xFF, flag, type) ;
                if (*line == ',') line++ ; else flagexit = TRUE ;
                break ;
            case FDB_TYPE :
                if (Eval() != NO_ERROR) return ERR_ERROR ;
                flag = RecordFCIf((eval.operand >> 8) & 0xFF, flag, type) ;
                flag = RecordFCIf(eval.operand & 0xFF, flag, type) ;
                if (*line == ',') line++ ; else flagexit = TRUE ;
                break ;
            default :
                if (*line == '\0')
                    return PrintError(ERR_MISSING_INFORMATION) ;
                else
                if (*line == charend)
                {
                    flagexit = TRUE ;
                    if ((type == FCN_TYPE)
                     && (run.size > 0))
                        run.code[run.size] |= 0x80 ;
                    line++ ;
                }
                else
                if ((unsigned char)*line > 0x7F)
                {
                    if (scan.soft == SOFT_ASSEMBLER)
                        return PrintError(ERR_BAD_OPERAND) ;
                    i = 0 ;
                    while (*line != acc_table[i]) i++ ;
                    flag = RecordFCIf(0x16, flag, type) ;
                    flag = RecordFCIf(asciitable[i][0], flag, type) ;
                    flag = RecordFCIf(asciitable[i][1], flag, type) ;
                    line++ ;
                }
                else
                if (*line >= 0x20)
                {
                    if (*line == CHAR127)
                        flag = RecordFCIf(' ', flag, type) ;
                    else
                        flag = RecordFCIf(*line, flag, type) ;
                    line++ ;
                }
                break ;
        }
    } while(flagexit == FALSE) ;

    if (type == FCS_TYPE) {
        flag = RecordFCIf(0x00, flag, type) ; }

    if (run.size != 0)
        RecordFC(flag, type) ;

    return NO_ERROR ;
}


int Ass_FCB(void)
{
    return Ass_All_FC(FCB_TYPE) ;
}

int Ass_FCC(void)
{
    return Ass_All_FC(FCC_TYPE) ;
}

int Ass_FCS(void)
{
    return Ass_All_FC(FCS_TYPE) ;
}

int Ass_FCN(void)
{
    return Ass_All_FC(FCN_TYPE) ;
}

int Ass_FDB(void)
{
    return Ass_All_FC(FDB_TYPE) ;
}

/*-------------------------------------------------------------------
 * Assemblage des réservations mémoire
 */

int Ass_PrintWithPcr(unsigned short pcr2)
{
    unsigned short pcr1 ;
    pcr1 = run.pc ;
    run.pc = pcr2 ;
    RecordLine(PRINT_PC) ;
    run.pc = pcr1 ;
    return NO_ERROR ;
}

int Ass_RMx(int size)
{
    int i ;
    int count ;
    unsigned short pcr = run.pc ;

    run.size = 0 ;
    if (Eval() != NO_ERROR) return ERR_ERROR ; 
    if ((count = eval.operand) < 0)
        return PrintError(ERR_BAD_OPERAND) ;
    if(*line != ',')
        run.pc += count * size ;
    else
    {
        if (scan.soft == SOFT_ASSEMBLER)
            return PrintError(ERR_BAD_OPERAND) ;
        line++ ;
        if (Eval() != NO_ERROR) return ERR_ERROR ;
        if ((size == 1)
         && ((eval.operand < -256) || (eval.operand > 255)))
            return PrintError(ERR_BAD_OPERAND) ;
        for(i=0;i<count;i++)
        {
            if (size == 2)
                SaveBinChar((eval.operand >> 8) & 0xFF) ;
            SaveBinChar(eval.operand & 0xFF) ;
        }
    }
    return Ass_PrintWithPcr(pcr) ;
}

int Ass_RMB(void)
{
    return Ass_RMx(1) ;
}

int Ass_RMD(void)
{
    return Ass_RMx(2) ;
}

/*-------------------------------------------------------------------
 * Assemblage des directives MO
 */

int Ass_Special_MO(void)
{
    if ((scan.soft == SOFT_ASSEMBLER)
     && (scan.computer != MO_COMPUTER))
        return PrintError(ERR_BAD_OPCODE) ;
    return NO_ERROR ;
}

int Ass_CALL_And_GOTO(unsigned char jump)
{
    if (Ass_Special_MO() != NO_ERROR) return ERR_ERROR ;
    run.size = 2 ;
    if (Eval() != NO_ERROR) return ERR_ERROR ;
    if((eval.operand < 0) || (eval.operand > 255))
        return PrintError(ERR_BAD_OPERAND) ;
    run.code[0] = 0x00 ;
    run.code[1] = 0x3F ;
    run.code[2] = (eval.operand & 0xFF) | jump ;
    return RecordLine(PRINT_TWO_FOR_TWO) ;     
}

int Ass_CALL(void)
{
    return Ass_CALL_And_GOTO(0x00) ;
}

int Ass_GOTO(void)
{
    return Ass_CALL_And_GOTO(0x80) ;
}

int Ass_STOP(void)
{
    if (Ass_Special_MO() != NO_ERROR) return ERR_ERROR ;
    run.size = 3 ;
    run.code[0] = 0x00 ;
    run.code[1] = 0xBD ;
    run.code[2] = 0xB0 ;
    run.code[3] = 0x00 ;
    return RecordLine(PRINT_TWO_FOR_THREE) ;
}

/*-------------------------------------------------------------------
 * Assemblage des déclarations
 */

int Ass_SET_And_EQU(int type)
{
    if (Eval() != NO_ERROR) return ERR_ERROR ;
    if (DoSymbol(labelname,eval.operand,type) != NO_ERROR)
        return ERR_ERROR ;
    return RecordLine(PRINT_LIKE_END) ;
}

int Ass_SET(void)
{
    return Ass_SET_And_EQU(SET_VALUE) ;
}

int Ass_EQU(void)
{
    return Ass_SET_And_EQU(EQU_VALUE) ;
}

/*-------------------------------------------------------------------
 * Assemblage des includes
 */

struct SRCLIST {
     struct SRCLIST *next ; /* Pointeur sur section suivante */
     unsigned char drive ;  /* Numéro de lecteur */
     char name[13] ; /* Nom du fichier xxxxxxxx.xxx */
     int line  ;     /* Numéro de ligne */
     int asm_size  ; /* Taille ASM compressé */
     char *start ;   /* Pointeur sur début du source */
     char *end ;     /* Pointeur sur fin du source */
} ;

struct SRCLIST *first_source ;
struct SRCLIST *current_source ;

/*
 * Initialise le chaînage des includes
 */
void InitIncludChain(void)
{
    first_includ = malloc(sizeof(struct INCLIST)) ;
    first_includ->prev = NULL ;
    first_includ->line = first_source->line ;
    first_includ->count = 0 ;
    first_includ->drive  = first_source->drive ;
    first_includ->name[0] = '\0' ;
    strcat(first_includ->name,first_source->name) ;
    first_includ->start = first_source->start ;
    first_includ->end   = first_source->end ;
}

/*
 * Libère la mémoire pour le chaînage des includes
 */
void FreeIncludChain(void)
{
    struct INCLIST *last_includ ;
    while((last_includ = first_includ))
    {
        first_includ = first_includ->prev ;
        free(last_includ) ;
    }
}

/*
 * Engage une séquence d'include
 */
int Ass_Start_INC(char *suffix)
{
    if (((run.locked & MACRO_LOCK) || (macro.level))
      && (scan.soft == SOFT_MACROASSEMBLER))
         return PrintError(ERR_ILLEGAL_INCLUDE) ;
    if(GetDescriptor(suffix) != NO_ERROR) return ERR_ERROR ;
    return NO_ERROR ;
}


/*
 * Assemble les INCLUD
 */
int Ass_INCLUD(void)
{
    struct INCLIST *prev_includ = NULL ;

    if (Ass_Start_INC("ASM") != NO_ERROR)
        return ERR_ERROR ;
    if (run.pass > MACROPASS)
    {
        /* Recherche l'include dans la liste des sources */
        current_source = first_source ;
        while((current_source != NULL)
           && (strcmp(current_source->name,desc.name)))
            current_source = current_source->next ;

        /* Erreur si INCLUD introuvable */
        if (current_source == NULL)
            return PrintError(ERR_FILE_NOT_FOUND) ;

        /* Met l'includ courant à jour */
        first_includ->start = source ;
        first_includ->line = run.line ;
        /* Crée le nouvel includ */
        prev_includ = first_includ ;
        first_includ = malloc(sizeof(struct INCLIST)) ;
        first_includ->prev  = prev_includ ;
        first_includ->drive  = current_source->drive ;
        first_includ->name[0] = '\0' ;
        strcat(first_includ->name, current_source->name) ;
        first_includ->line  = current_source->line ;
        first_includ->start = current_source->start ;
        first_includ->end   = current_source->end ;
        first_includ->count = prev_includ->count + 1 ;
        source = first_includ->start ;
        run.line = first_includ->line ;
        RecordLine(PRINT_NO_CODE) ;
    }
    return NO_ERROR ;
}

/*
 * Erreur 'Bad File Format' pour les INCBIN
 */
int Ass_BadFileFormat(FILE *fp_file)
{
    fclose(fp_file) ;
    return PrintError(ERR_BAD_FILE_FORMAT) ;
}

/*
 * Assemble les INCBIN
 */
int Ass_INCBIN(void)
{
    FILE *fp_file;
    int flag = 0 ;
    int size = 0 ;
    int i ;
    unsigned short pcr = run.pc ;

    if (Ass_Start_INC("BIN") != NO_ERROR)
        return ERR_ERROR ;
    if ((fp_file = fopen(desc.name,"rb")) == NULL)
        return PrintError(ERR_FILE_NOT_FOUND) ;

    if (feof(fp_file)) return Ass_BadFileFormat(fp_file) ;
    flag = fgetc(fp_file) ;
    if (feof(fp_file)) return Ass_BadFileFormat(fp_file) ;
    while (flag == 0x00)
    {
        size = (fgetc(fp_file) & 0xff) << 8 ;
        if (feof(fp_file)) return Ass_BadFileFormat(fp_file) ;
        size |= (fgetc(fp_file) & 0xff) ;
        if (feof(fp_file)) return Ass_BadFileFormat(fp_file) ;
        fgetc(fp_file) ;
        if (feof(fp_file)) return Ass_BadFileFormat(fp_file) ;
        fgetc(fp_file) ;
        if (feof(fp_file)) return Ass_BadFileFormat(fp_file) ;
        for(i=0;i<size;i++)
        {
            SaveBinChar(fgetc(fp_file)) ;
            if (feof(fp_file)) return Ass_BadFileFormat(fp_file) ;
        }
        flag = fgetc(fp_file) ;
        if (feof(fp_file)) return Ass_BadFileFormat(fp_file) ;
    }
    if (flag != 0xFF)
        return Ass_BadFileFormat(fp_file) ;
    if ((fgetc(fp_file) != 0x00)
     || (feof(fp_file)))
        return Ass_BadFileFormat(fp_file) ;
    if ((fgetc(fp_file) != 0x00)
     || (feof(fp_file)))
        return Ass_BadFileFormat(fp_file) ;
    fgetc(fp_file) ;
    if (feof(fp_file))
        return Ass_BadFileFormat(fp_file) ;
    fclose(fp_file) ;

    return Ass_PrintWithPcr(pcr) ;
}

/*
 * Assemble les INCDAT
 */
int Ass_INCDAT(void)
{
    int i;
    FILE *fp_file ;
    struct stat st;
    unsigned short pcr = run.pc ;

    if (Ass_Start_INC("") != NO_ERROR)
        return ERR_ERROR ;

    if (stat(desc.name, &st) == 0)
    {
        if ((fp_file = fopen(desc.name,"rb")) ==  NULL)
            return PrintError(ERR_FILE_NOT_FOUND) ;
        for (i=0; i<(int)st.st_size; i++)
        {
            SaveBinChar(fgetc(fp_file)) ;
        }
    }
    else
        return PrintError(ERR_FILE_NOT_FOUND) ;

    fclose(fp_file) ;
    return Ass_PrintWithPcr(pcr) ;
}

/*-------------------------------------------------------------------
 * Assemblage d'affichage
 */

int Ass_ECHO(void)
{
    char c ;
    int i ;
    char operand[18] ;
    char echoline[LINE_MAX_SIZE+2] ;

    if ((run.pass == PASS2)
     && (run.opt[OPT_WL] == FALSE))
    {
        echoline[0] = '\0' ;
        while(*line != 0)
        {
            operand[0] = '\0' ;
            switch (c = *(line++))
            {
                case '%':
                    if (Eval() != NO_ERROR) return ERR_ERROR ;
                    strcat(operand,"%") ;
                    i = 0x8000 ;
                    while(((eval.operand & i) == 0) && (i != 1))
                        i >>= 1 ;
                    while(i != 0) {
                        if (eval.operand & i) strcat(operand,"1") ;
                        else  strcat(operand,"0") ;
                        i >>= 1 ; }
                    break ;
                case '@':
                    if (Eval() != NO_ERROR) return ERR_ERROR ;
                    sprintf(operand,"@%o",eval.operand & 0xFFFF) ;
                    break ;
                case '&':
                    if (Eval() != NO_ERROR) return ERR_ERROR ;
                    sprintf(operand,"%d",eval.operand & 0xFFFF) ;
                    break ;
                case '$':
                    if (Eval() != NO_ERROR) return ERR_ERROR ;
                    sprintf(operand,"$%04X",eval.operand & 0xFFFF) ;
                    break ;
                default :
                    strncat(echoline,&c,1) ;
                    break ;
            }
            strcat(echoline,operand) ;
        }
        printf("%s\n",echoline) ;
    }
    return RecordLine(PRINT_NO_CODE) ;
}

int Ass_PRINT(void)
{
    if ((run.pass == PASS1)
     && (run.opt[OPT_WL] == FALSE))
        printf("%s\n",line) ;
    return RecordLine(PRINT_NO_CODE) ;
}

/*-------------------------------------------------------------------
 * Assemblage de mise en page
 */

int Ass_TITLE(void)
{
    return RecordLine(PRINT_NO_CODE) ;
}

int Ass_PAGE(void)
{
    if (*line != '\0')
        return PrintError(ERR_ILLEGAL_OPERAND) ;
    return RecordLine(PRINT_NO_CODE) ;
}

/*-------------------------------------------------------------------
 * Assemblage conditionnel
 */

enum {
    IF_IFNE,
    IF_IFEQ,
    IF_IFGT,
    IF_IFLT,
    IF_IFGE,
    IF_IFLE
} ;

int Ass_All_IF(int condition)
{
    int result = FALSE ;

    if (run.locked & (COMMENT_LOCK | MACRO_LOCK))
        return RecordLine(PRINT_NO_CODE) ;
    if ((ifc.count == 16)
      && (scan.soft == SOFT_MACROASSEMBLER))
        return PrintError(ERR_IF_OUT_OF_RANGE) ;
    if (Eval() != NO_ERROR) return ERR_ERROR ;
    switch(condition)
    {
        case IF_IFNE : result = (eval.operand != 0) ; break ;
        case IF_IFEQ : result = (eval.operand == 0) ; break ;
        case IF_IFGT : result = (eval.operand >  0) ; break ;
        case IF_IFLT : result = (eval.operand <  0) ; break ;
        case IF_IFGE : result = (eval.operand >= 0) ; break ;
        case IF_IFLE : result = (eval.operand <= 0) ; break ;
    }

    ifc.count++ ;
    if ((ifc.buf[ifc.count - 1] == IF_TRUE)
     || (ifc.buf[ifc.count - 1] == IF_FALSE_ELSE))
        ifc.buf[ifc.count] = (result == TRUE) ? IF_TRUE : IF_FALSE ;
    else
        ifc.buf[ifc.count] = IF_STOP ;

    run.locked &= ~IF_LOCK ;
    if (ifc.buf[ifc.count] != IF_TRUE) run.locked |= IF_LOCK ;

    return RecordLine(PRINT_NO_CODE) ;
}

int Ass_IF(void)
{
    return Ass_All_IF(IF_IFNE) ;
}

int Ass_IFNE(void)
{
    return Ass_All_IF(IF_IFNE) ;
}

int Ass_IFEQ(void)
{
    return Ass_All_IF(IF_IFEQ) ;
}

int Ass_IFGT(void)
{
    return Ass_All_IF(IF_IFGT) ;
}

int Ass_IFLT(void)
{
    return Ass_All_IF(IF_IFLT) ;
}

int Ass_IFGE(void)
{
    return Ass_All_IF(IF_IFGE) ;
}

int Ass_IFLE(void)
{
    return Ass_All_IF(IF_IFLE) ;
}

int Ass_ELSE(void)
{
    if (run.locked & (COMMENT_LOCK | MACRO_LOCK))
        return RecordLine(PRINT_NO_CODE) ;

    if (ifc.count == 0)
        return PrintError(ERR_MISSING_IF) ;

    switch(ifc.buf[ifc.count])
    {
        case IF_TRUE_ELSE  :
        case IF_FALSE_ELSE :
             return PrintError(ERR_BAD_ELSE) ;
             break ;
        case IF_STOP :
            break ;
        default :
            ifc.buf[ifc.count] = (ifc.buf[ifc.count] == IF_TRUE) ? IF_TRUE_ELSE : IF_FALSE_ELSE ;
            break ;
    }
    run.locked &= ~IF_LOCK ;
    if (ifc.buf[ifc.count] != IF_FALSE_ELSE) run.locked |= IF_LOCK ;

    return RecordLine(PRINT_NO_CODE) ;
}

int Ass_ENDC(void)
{
    if (run.locked & (COMMENT_LOCK | MACRO_LOCK))
        return RecordLine(PRINT_NO_CODE) ;

    if (ifc.count == 0)
        return PrintError(ERR_MISSING_IF) ;

    ifc.count-- ;
    run.locked &= ~IF_LOCK ;
    if ((ifc.buf[ifc.count] != IF_FALSE_ELSE)
     && (ifc.buf[ifc.count] != IF_TRUE)) run.locked |= IF_LOCK ;

    return RecordLine(PRINT_NO_CODE) ;
}

/*-------------------------------------------------------------------
 * Assemblage des macros
 */

struct MACROLIST {
     struct MACROLIST *next ; /* Pointeur sur section suivante */
     int count  ;    /* Identificateur de macro */
     int line  ;     /* Numéro de ligne */
     char *arg[10] ; /* Liste des arguments */
     char *start ;   /* Pointeur sur début de macro */
     char *end ;     /* Pointeur sur fin de macro */
} ;

struct MACROLIST *first_macro ;
struct MACROLIST *current_macro ;
extern int CheckIfReservedName(void) ;

struct MACROARGLIST {
     struct MACROARGLIST *prev ; /* Pointeur sur section précedente */
     int  line ;     /* Numéro de ligne */
     char *ptr ;     /* Ptr sur macro */
     char *arg[10] ; /* Liste des arguments de macro */
} ;

struct MACROARGLIST *current_macroarg ;

/*
 * Initialise le chaînage des macros
 */
void InitMacroChain(void)
{
    first_macro = malloc(sizeof(struct MACROLIST)) ;
    first_macro->next  = NULL ;
    first_macro->line  = 0 ;
    first_macro->start = NULL ;
    first_macro->end   = NULL ;
    current_macro = first_macro ;
}

/*
 * Libère la mémoire pour le chaînage des macros
 */
void FreeMacroChain(void)
{
    while((current_macro = first_macro))
    {
        first_macro = first_macro->next ;
        free(current_macro) ;
    }
}


int Ass_MACRO(void)
{
    if (run.locked & (COMMENT_LOCK + IF_LOCK))
        return RecordLine(PRINT_NO_CODE) ;

    macro.count++ ;
    if (macro.level)
        return PrintError(ERR_EMBEDDED_MACRO) ;
    else
    if (run.pass == MACROPASS)
    {
        current_macro->next = malloc(sizeof(struct MACROLIST)) ;
        current_macro = current_macro->next ;
        current_macro->next  = NULL ;
        current_macro->count = macro.count ;
        current_macro->line  = run.line ;
        current_macro->start = source ;
        current_macro->end   = NULL ;
    }
    else
    {
        /* Erreur si une macro a déjà été déclarée */
        if (run.locked & MACRO_LOCK)
            return PrintError(ERR_EMBEDDED_MACRO) ;
        /* Erreur si le nom de la macro est réservé */
        if (CheckIfReservedName() != NO_ERROR)
            return ERR_ERROR ;
        /* Erreur éventuelle si assemblage conditionnel en cours */
        if ((ifc.count > 0) && (scan.soft == SOFT_MACROASSEMBLER))
            return PrintError(ERR_MACRO_INTO_IF_RANGE) ;
        /* Déclare la macro */
        if (DoSymbol(labelname,macro.count,MACRO_VALUE) != NO_ERROR)
            return ERR_ERROR ;
        /* Active le bit macro */
        run.locked |= MACRO_LOCK ;
        RecordLine(PRINT_NO_CODE) ;
    }
    return NO_ERROR ;
}


int Ass_ENDM(void)
{
    struct MACROARGLIST *prev_macroarg ;

    if (run.locked & (COMMENT_LOCK + IF_LOCK))
        return RecordLine(PRINT_NO_CODE) ;

    if (macro.level)
    {
        if (current_macroarg->prev == NULL)
            return PrintError(ERR_ENDM_WITHOUT_MACRO) ;
        prev_macroarg = current_macroarg->prev ;
        free(current_macroarg) ;
        current_macroarg = prev_macroarg ;
        source   = current_macroarg->ptr ;
        run.line = current_macroarg->line ;
        macro.level-- ;
        return NO_ERROR ;
    }
    else
    if (run.pass == MACROPASS)
    {
        if (current_macro->end != NULL)
            return PrintError(ERR_ENDM_WITHOUT_MACRO) ;
        current_macro->end = source ;
    }
    else
    if ((run.locked & MACRO_LOCK) == 0)
        return PrintError(ERR_ENDM_WITHOUT_MACRO) ;

    run.locked &= ~MACRO_LOCK ;
    return RecordLine(PRINT_NO_CODE) ;
}

/*-------------------------------------------------------------------
 * Assemblage des autres directives
 */

int Ass_ORG(void)
{
    if (Eval() != NO_ERROR) return ERR_ERROR ;
    run.pc = eval.operand ;
    return RecordLine(PRINT_PC) ;
}

int Ass_SETDP(void)
{
    if (Eval() != NO_ERROR) return ERR_ERROR ;
    if((eval.operand < -256) || (eval.operand > 255))
        return PrintError(ERR_BAD_OPERAND) ;
    run.dp = eval.operand & 0xFF ;
    return RecordLine(PRINT_LIKE_DP) ;
}

int Ass_END(void)
{
    eval.operand = 0 ;
    if ((*line != '\0')
     && (*line != ' ')
     && (*line != CHAR127))
    {
        if (Eval() != NO_ERROR) return ERR_ERROR ;
        run.exec = eval.operand ;
    }
    run.exit = TRUE ;
    return RecordLine(PRINT_LIKE_END) ;
}

int Ass_OPT(void)
{
    const struct {
        char name[3] ; /* Nom du switch d'option */
        int type ;     /* Code du switch d'option */
      } OptTable[6] = {
       { "NO", OPT_NO }, /* Pas d'objet */
       { "OP", OPT_OP }, /* Optimisation */
       { "SS", OPT_SS }, /* Lignes séparées   (inactif) */
       { "WE", OPT_WE }, /* Attend à l'erreur (inactif) */
       { "WL", OPT_WL }, /* Affiche lignes */
       { "WS", OPT_WS }  /* Affiche symboles */
    } ;

    int i ;
    int status ;

    if ((*line == '\0')
     || ((run.pass != SCANPASS) && (run.pass != PASS2)))
        return NO_ERROR ;
    do
    {
        status = TRUE ;
        if (*line == '.') { status = FALSE ; line++ ; }
        if (ScanLine() != ALPHA_CHAR)
            return PrintError(ERR_BAD_PARAM) ;
        upper_string(arg) ;
        i = 0 ;
        while ((i < 6) && (strcmp(arg,OptTable[i].name))) i++ ;
        if (i == 6)
            return PrintError(ERR_BAD_PARAM) ;
        run.opt[OptTable[i].type] = status ;
    } while((ScanLine() != END_CHAR) && (*arg == '/')) ;

    return RecordLine(PRINT_NO_CODE) ;
}

/*-------------------------------------------------------------------
 * Liste des directives
 */
enum {
    NO_LABEL, /* Pas d'étiquette */
    LABEL,    /* Etiquette éventuelle */
    A_LABEL   /* Etiquette obligatoire */
} ;
const struct DIRECTTABLE {
     char name[7] ;    /* Nom de la directive */
     int iflabel ;     /* NO_LABEL/LABEL/A_LABEL */
     int soft ;        /* SOFT_ASSEMBLER/SOFT_MACROASSEMBLER */
     int ifprint ;     /* TRUE = exécution inconditionnelle */
     int ifuppercase ; /* Pour création de fichiers Assembler
                        * TRUE  = Opérande supposée
                        * FALSE = Pas d'opérande */
     int (*prog)(void) ; /* Programme de traitement */
  } direct_table[] = {
     { "CALL"   , LABEL   , SOFT_MACROASSEMBLER, FALSE, TRUE , Ass_CALL   },
     { "ECHO"   , NO_LABEL, SOFT_MACROASSEMBLER, FALSE, FALSE, Ass_ECHO   },
     { "ELSE"   , NO_LABEL, SOFT_MACROASSEMBLER, TRUE , FALSE, Ass_ELSE   },
     { "END"    , NO_LABEL, SOFT_ASSEMBLER     , FALSE, TRUE , Ass_END    },
     { "ENDC"   , NO_LABEL, SOFT_MACROASSEMBLER, TRUE , FALSE, Ass_ENDC   },
     { "ENDM"   , NO_LABEL, SOFT_MACROASSEMBLER, TRUE , FALSE, Ass_ENDM   },
     { "EQU"    , A_LABEL , SOFT_ASSEMBLER     , FALSE, TRUE , Ass_EQU    },
     { "FCB"    , LABEL   , SOFT_ASSEMBLER     , FALSE, TRUE , Ass_FCB    },
     { "FCC"    , LABEL   , SOFT_ASSEMBLER     , FALSE, FALSE, Ass_FCC    },
     { "FCN"    , LABEL   , SOFT_MACROASSEMBLER, FALSE, FALSE, Ass_FCN    },
     { "FCS"    , LABEL   , SOFT_MACROASSEMBLER, FALSE, FALSE, Ass_FCS    },
     { "FDB"    , LABEL   , SOFT_ASSEMBLER     , FALSE, TRUE , Ass_FDB    },
     { "GOTO"   , LABEL   , SOFT_MACROASSEMBLER, FALSE, TRUE , Ass_GOTO   },
     { "IF"     , NO_LABEL, SOFT_MACROASSEMBLER, TRUE , TRUE , Ass_IF     },
     { "IFEQ"   , NO_LABEL, SOFT_MACROASSEMBLER, TRUE , TRUE , Ass_IFEQ   },
     { "IFGE"   , NO_LABEL, SOFT_MACROASSEMBLER, TRUE , TRUE , Ass_IFGE   },
     { "IFGT"   , NO_LABEL, SOFT_MACROASSEMBLER, TRUE , TRUE , Ass_IFGT   },
     { "IFLE"   , NO_LABEL, SOFT_MACROASSEMBLER, TRUE , TRUE , Ass_IFLE   },
     { "IFLT"   , NO_LABEL, SOFT_MACROASSEMBLER, TRUE , TRUE , Ass_IFLT   },
     { "IFNE"   , NO_LABEL, SOFT_MACROASSEMBLER, TRUE , TRUE , Ass_IFNE   },
     { "INCBIN" , NO_LABEL, SOFT_MACROASSEMBLER, FALSE, FALSE, Ass_INCBIN },
     { "INCDAT" , NO_LABEL, SOFT_MACROASSEMBLER, FALSE, FALSE, Ass_INCDAT },
     { "INCLUD" , NO_LABEL, SOFT_ASSEMBLER     , FALSE, FALSE, Ass_INCLUD },
     { "MACRO"  , A_LABEL , SOFT_MACROASSEMBLER, TRUE , FALSE, Ass_MACRO  },
     { "OPT"    , NO_LABEL, SOFT_MACROASSEMBLER, FALSE, TRUE , Ass_OPT    },
     { "ORG"    , NO_LABEL, SOFT_ASSEMBLER     , FALSE, TRUE , Ass_ORG    },
     { "PAGE"   , NO_LABEL, SOFT_ASSEMBLER     , FALSE, FALSE, Ass_PAGE   },
     { "PRINT"  , NO_LABEL, SOFT_MACROASSEMBLER, FALSE, FALSE, Ass_PRINT  },
     { "RMB"    , LABEL   , SOFT_ASSEMBLER     , FALSE, TRUE , Ass_RMB    },
     { "RMD"    , LABEL   , SOFT_MACROASSEMBLER, FALSE, TRUE , Ass_RMD    },
     { "SET"    , A_LABEL , SOFT_ASSEMBLER     , FALSE, TRUE , Ass_SET    },
     { "SETDP"  , NO_LABEL, SOFT_ASSEMBLER     , FALSE, TRUE , Ass_SETDP  },
     { "STOP"   , LABEL   , SOFT_MACROASSEMBLER, FALSE, FALSE, Ass_STOP   },
     { "TITLE"  , NO_LABEL, SOFT_ASSEMBLER     , FALSE, FALSE, Ass_TITLE  }
};
#define DTSIZE (int)sizeof(direct_table)/(int)sizeof(direct_table[0])

/*
 * Vérifie si le nom de macro est réservé
 */
int CheckIfReservedName(void)
{
    int i ;
    char macrname[ARG_MAX_SIZE+2] ;

    macrname[0] = '\0' ;
    strcat(macrname,labelname) ;
    upper_string(macrname) ;

    /* Vérifie si le nom de macro est celui d'une instruction */
    for(i=0;i<ITSIZE;i++)
        if (!strcmp(inst_table[i].name,macrname))
            return PrintError(ERR_BAD_MACRO_NAME) ;

    /* Vérifie si le nom de macro est celui d'une directive */
    for(i=0;i<DTSIZE;i++)
        if (!strcmp(direct_table[i].name,macrname))
            return PrintError(ERR_BAD_MACRO_NAME) ;

    return NO_ERROR ;
}


/***********************************************************************
 *
 * Assemblage de la ligne de code
 *
 ***********************************************************************/

/*
 * Passe les espaces
 */
void SkipSpaces(void)
{
    while(*line == 0x20)
        line++ ;
}

/*
 * Initialise le chaînage des arguments de macros
 */
void InitMacroArgChain(void)
{
    int i ;
    current_macroarg = malloc(sizeof(struct MACROARGLIST)) ;
    current_macroarg->prev = NULL ;
    for(i=0;i<10;i++) current_macroarg->arg[i] = NULL ;
}

/*
 * Libère la mémoire pour le chaînage des arguments de macros
 */
void FreeMacroArgChain(void)
{
    struct MACROARGLIST *last_macroarg ;
    while((last_macroarg = current_macroarg))
    {
        current_macroarg = current_macroarg->prev ;
        free(last_macroarg) ;
    }
}

/*
 * Assemble la ligne
 */
int AssembleLine(void)
{
    struct MACROARGLIST *prev_macroarg ;
    struct INCLIST *prev_includ = NULL ;
    int i ;
    int done = FALSE ;
    int label = FALSE ;
    char macroname[ARG_MAX_SIZE+2] ;
    char argname[ARG_MAX_SIZE+2] ;
    char ll[LINE_MAX_SIZE+2] ;
    int argn ;
    int error = NO_ERROR ;

    run.size = 0 ;
    info.cycle.count = -1 ;
    info.cycle.plus  = -1 ;

    /* Retour éventuel d'includ */
    if ((first_includ->count != 0)
     && (source == first_includ->end))
    {
        prev_includ = first_includ->prev ;
        free(first_includ) ;
        first_includ = prev_includ ;
        run.line = first_includ->line ;
        source = first_includ->start ;
    }

    GetLine() ;

    if (*line == '\0') return RecordLine(PRINT_EMPTY) ;

    /*
     * Traitement du marquage
     */
    if ((*line == '(') && (run.pass == PASS2))
    {
        line++ ;
        ScanLine() ;
        if (!strcmp(arg,"info"))
        {
            fprintf(fp_lst,"----------------\n") ;
            fprintf(fp_lst,"%d cycle(s)\n",info.cycle.total) ;
            fprintf(fp_lst,"%d byte(s)\n",info.size) ;
            fprintf(fp_lst,"----------------\n") ;
            info.cycle.total = 0 ;
            info.size = 0 ;
        }
        else
        if (!strcmp(arg,"check"))
        {
            line++ ;
            SkipSpaces() ;
            if(*line == '\0')
            {
                check[0][0] = 0 ; /* Cycles limite */
                check[0][1] = 0 ; /* Cycles */
                check[1][0] = 0 ; /* Taille limite */
                check[1][1] = 0 ; /* Taille */
            }
            else
            {
                i = 0 ;
                while ((*line > 0x20) && (i < 2))
                {
                    if ((*line != ',')
                     && (*line > 0x20))
                    {
                        if (Eval() != NO_ERROR) return ERR_ERROR ;
                        check[i][0] = eval.operand ;
                        if ((check[i][0] != 0)
                         && (check[i][0] != check[i][1]))
                        {
                            PrintError(ERR_CHECK_ERROR) ;
                            printf("Check[%d,%d]\n",check[0][1],check[1][1]) ;
                            fprintf(fp_lst,"Check [%d,%d]\n",check[0][1],check[1][1]) ;
                        }
                    }
                    if (*line == ',') line++ ;
                }
                check[0][1] = 0 ;
                check[1][1] = 0 ;
            }
        }
        return NO_ERROR ;
    }

    /*
     * Reconstruction de la ligne si exécution de macro
     */
    if (macro.level)
    {
        i = 0 ;
        ll[0] = '\0' ;
        while (linebuffer[i] != 0)
        {
            if (linebuffer[i] == '\\')
            {
                i++ ;
                /* Récupère le numéro de l'argument de macro */
                if (is_numeric(linebuffer[i]) == FALSE)
                    return PrintError(ERR_MACRO_ERROR) ;
                argn = linebuffer[i++] - '0' ;
                /* Interprète l'argument de macro */
                prev_macroarg = current_macroarg ;
                while((prev_macroarg->arg[argn] != NULL)
                   && (prev_macroarg->arg[argn][0] == '\\'))
                {
                    if (prev_macroarg->prev == NULL)
                        return PrintError(ERR_MACRO_ERROR) ;
                    if (is_numeric(prev_macroarg->arg[argn][1]) == FALSE)
                        return PrintError(ERR_MACRO_ERROR) ;
                    argn = prev_macroarg->arg[argn][1] - '0' ;
                    prev_macroarg = prev_macroarg->prev ;
                }
                if (prev_macroarg->arg[argn] != NULL)
                    strcat(ll,prev_macroarg->arg[argn]) ;
            }
            else
                strncat(ll,&linebuffer[i++],1) ;
        }
        linebuffer[0] = '\0' ;
        strcat(linebuffer,ll) ;
    }
    else
    {
        if (strchr (line, (int)'\\') != NULL)
           return RecordLine(PRINT_EMPTY);
    }
    

    /*
     * Traitement étiquette/commentaire
     */
    if (*line != 0x20)
    {
        /* Traitement du slash de commentaire */
        if (*line == '/') {
            run.locked ^= COMMENT_LOCK ;
            return RecordLine(PRINT_NO_CODE) ; }
        /* Traitement de l'astérisque de commentaire */
        if ((*line == '*')
         || (run.locked & COMMENT_LOCK))
            return RecordLine(PRINT_NO_CODE) ;
        /* Lecture de l'étiquette */
        if (ScanLine() != ALPHA_CHAR)
            return PrintError(ERR_BAD_LABEL) ;
        if (((scan.soft == SOFT_ASSEMBLER) && ((int)strlen(arg) > 6))
         || ((scan.soft == SOFT_MACROASSEMBLER) && ((int)strlen(arg) > ARG_MAX_SIZE)))
            return PrintError(ERR_LABEL_NAME_TOO_LONG) ;
        labelname[0] = '\0' ;
        strcat(labelname,arg) ;
        if (scan.soft == SOFT_ASSEMBLER)
            upper_string(labelname) ;
        label = TRUE ;
    }
        

    /*
     * Traitement étiquette sèche
     */
    SkipSpaces() ;
    if ((*line == '\0')
      || (*line == '*'))
    {
        if ((label == TRUE)
         && (run.pass > MACROPASS))
        {
            if (DoSymbol(labelname,run.pc,LABEL_VALUE) != NO_ERROR)
                return ERR_ERROR ;
            return RecordLine(PRINT_PC) ;
        }
        return RecordLine(PRINT_NO_CODE) ;
    } 

    /*
     * Récupération de l'instruction
     */
    if (ScanLine() != ALPHA_CHAR)
        return PrintError(ERR_BAD_OPCODE) ;
    SkipSpaces() ;
    macroname[0] = '\0' ;
    strcat(macroname,arg) ;

    run.size = 0 ;
    run.code[0] = 0 ;

    /* Traitement de l'instruction */
    upper_string(arg) ;
    if (run.pass > MACROPASS)
    {
        i = 0 ;
        while((i<ITSIZE) && (done == FALSE))
        {
            if(!strcmp(inst_table[i].name,arg))
            {
                run.code[0] = inst_table[i].page ;
                run.code[1] = inst_table[i].code ;
                info.cycle.count = inst_table[i].cycles ;
                if (run.locked == UNLOCKED)
                {
                    if ((label == TRUE)
                     && (DoSymbol(labelname,run.pc,LABEL_VALUE) != NO_ERROR))
                        return ERR_ERROR ;
                    upper_string(arg) ;
                    error = (*inst_table[i].prog)() ;
                }
                else RecordLine(PRINT_NO_CODE) ;
                done = TRUE ;
            }
            i++ ;
        }
    }

    /* Traitement de la directive */

    if (done == FALSE)
    {
        i = 0 ;
        while((i<DTSIZE) && (done == FALSE))
        {
            if(!strcmp(direct_table[i].name,arg))
            {
                if ((scan.soft == SOFT_ASSEMBLER)
                 && (direct_table[i].soft != SOFT_ASSEMBLER))
                    return PrintError(ERR_BAD_OPCODE) ;

                /* Au pass de macro, seules les directives
                 * MACRO et ENDM doivent passer
                 * Aux pass 1 et 2, seules les directives
                 * qui ne se trouvent ni dans une zone de
                 * commentaire, ni dans une déclaration de
                 * macro, ni dans un IF faux (sauf les
                 * directives de condition, etc...) doivent
                 * passer */
                if (((run.pass == MACROPASS)
                  && (strcmp(direct_table[i].name,"MACRO"))
                  && (strcmp(direct_table[i].name,"ENDM")))
                 || ((run.pass > MACROPASS)
                  && (run.locked)
                  && (direct_table[i].ifprint == FALSE)))
                    return RecordLine(PRINT_NO_CODE) ;

                switch (direct_table[i].iflabel)
                {
                    case NO_LABEL :
                        if (label == TRUE)
                            return PrintError(ERR_ILLEGAL_LABEL) ;
                        break ;
                    case A_LABEL :
                        if (label == FALSE)
                            return PrintError(ERR_MISSING_LABEL) ;
                        break ;
                    case LABEL :
                        if ((label == TRUE)
                         && (DoSymbol(labelname,run.pc,LABEL_VALUE) != NO_ERROR))
                            return ERR_ERROR ;
                        break ;
                }
                error = (*direct_table[i].prog)() ;
                done = TRUE ;
            }
            i++ ;
        }
    }


    /* Traitement de la macro */
    if ((done == FALSE) && (run.pass > MACROPASS))
    {
        if (scan.soft == SOFT_ASSEMBLER)
            return PrintError(ERR_BAD_OPCODE) ;
        if (run.locked)
            return RecordLine(PRINT_NO_CODE) ;
        if (DoSymbol(macroname,0,READ_VALUE) != NO_ERROR)
            return ERR_ERROR ;
        if (eval.type != MACRO_VALUE)
            return PrintError(ERR_UNDEFINED_MACRO) ;

        /* Limite le nombre d'imbrications */
        if ((macro.level == 8)
         && (scan.soft == SOFT_MACROASSEMBLER))
            return PrintError(ERR_MACRO_OUT_OF_RANGE) ;
        macro.level++ ;

        /* Sauvegarde les arguments de macro */
        current_macroarg->line = run.line  ;
        current_macroarg->ptr = source ;
        prev_macroarg = current_macroarg ;
        current_macroarg = malloc(sizeof(struct MACROARGLIST)) ;
        current_macroarg->prev = prev_macroarg ;
        for(i=0;i<10;i++) current_macroarg->arg[i] = NULL ;
        if (*line != '\0')
        {
            i = 0 ;
            while ((*line != '\0')
                && (*line != ' ')
                && (i < 10))
            {
                if ((i) && (*(line++) != ','))
                    return PrintError(ERR_MACRO_ERROR) ;
                argname[0] = '\0' ;
                while((*line != '\0')
                   && (*line != ' ')
                   && (*line != ','))
                    strncat(argname,line++,1) ;
                current_macroarg->arg[i] = malloc(strlen(argname)+1) ;
                current_macroarg->arg[i][0] = '\0' ;
                strcat(current_macroarg->arg[i],argname) ;
                i++ ;
            }
        }
        /* Recherche la macro dans la liste */
        current_macro = first_macro ;
        while(current_macro->count != (unsigned short)eval.operand)
            current_macro = current_macro->next ;
        /* Lance l'exécution de la macro */
        source = current_macro->start ;
        run.line = current_macro->line ;
    }

    /* Effectue le total des cycles */
    if (info.cycle.count != -1)
    {
        info.cycle.total += info.cycle.count ;
        check[0][1] += info.cycle.count ;
    }
    if (info.cycle.plus  != -1)
    {
        info.cycle.total += info.cycle.plus  ;
        check[0][1] += info.cycle.plus ;
    }

    /* Sauvegarde des octets de code */
    if ((run.size != 0) && (error == NO_ERROR))
    {
        if(run.code[0])
            SaveBinChar(run.code[0]) ;
        for(i=0;i<run.size;i++)
            SaveBinChar(run.code[i+1]) ;
    }

    return NO_ERROR ;
}




/***********************************************************************
 *
 * Chargement et traitement du fichier source
 *
 ***********************************************************************/

enum{
    NO_MARK,
    MAIN_MARK,
    INFO_MARK,
    CHECK_MARK,
    INCLUDE_MARK
} ;

const struct {
    char name[8] ; /* Nom du marquage */
    int type ;      /* Type du marquage */
  } mark[] = {
      { "main"   , MAIN_MARK    },
      { "info"   , INFO_MARK    },
      { "check"  , CHECK_MARK   },
      { "include", INCLUDE_MARK }
} ;
#define MTSIZE  (int)sizeof(mark)/(int)sizeof(mark[0])

struct {
    int status ;  /* TRUE = création des fichiers ASM */
    int comment ; /* Flag de passage d'un '/' de commentaire */
    int top ;     /* Compteur de lignes vides de début de source */
    int bottom ;  /* Compteur de lignes vides de fin de source */
} create ;


/*
 * Initialise le chaînage des sources
 */
void InitSourceChain(void)
{
    first_source = malloc(sizeof(struct SRCLIST)) ;
    first_source->next = NULL ;
    first_source->start = NULL ;
}


/*
 * Libère la mémoire pour le chaînage des sources
 */
void FreeSourceChain(void)
{
    while((current_source = first_source))
    {
        first_source = first_source->next ;
        free(current_source) ;
    }
}


/*
 * Ferme le fichier ASM courant
 */
void CloseASM(void)
{
    if (fp_asm != NULL)
        fclose(fp_asm) ;
}


int RecordSourceChainIf(void)
{
    int i = 0 ;
    int accent ;
    int markflag = NO_MARK ;
    struct SRCLIST *next_source ;
    char crunchedline[ARG_MAX_SIZE+2] ;
    char *p = line ;
    unsigned char c = '\0' ;
    int spaces = 0 ;

    int done = FALSE ;
    int flag = FALSE ;
    int csize = 0 ;

    /*
     * Crée la ligne au format ASM
     */
    if (*line != '(')
    {
        while((*line != '\0') && ((line - p) < COLON_40))
        {
            /* Filtre les caractères */
            switch(c = (unsigned char)*(line++))
            {
                case CHAR127 : c = 0x7F ; break ;
                case 0x20 :
                    spaces++ ;
                    while(*line == 0x20)
                    {
                        spaces++ ;
                        line++ ;
                    }
                    break ;
                default :
                    if (c > 0x7F)
                    {
                        accent = 0 ;
                        while((accent<16) && (c != acc_table[accent])) accent++ ;
                        if (accent == 16) c = '?' ; else c = 0x80 + accent ;
                    }
                    break ;
            }
            /* Ajoute un caractère si valide */
            if (c > 0x20)
            {
                /* Ajoute les lignes vides préalables */
                if (create.top)
                {
                    while(create.bottom > 0)
                    {
                        if ((fp_asm != NULL) && (create.status == TRUE))
                            fputc(0x0D,fp_asm) ;
                        current_source->asm_size += create.bottom * 3 ;
                        create.bottom-- ;
                    }
                }
                create.bottom = 0 ;

                /* Ajoute les espaces préalables */
                while (spaces >= 15)
                {
                    crunchedline[csize++] = (char)0xFF ;
                    spaces -= 15 ;
                }
                if (spaces) crunchedline[csize++] = spaces | 0xF0 ;
                spaces = 0 ;

                /* Ajoute le caractère */
                crunchedline[csize++] = c ;
            }
        }
        crunchedline[csize++] = 0x0D ;
        if (crunchedline[0] != 0x0D) create.top = 1 ;
            else if (create.top) create.bottom++ ;
        if ((create.top != 0) && (create.bottom == 0))
        {
            current_source->asm_size += 3 + csize - 1 ;

            /*
             * Capitalise les lettres si compatibilité Assembler demandée
             */

            if ((scan.soft == SOFT_ASSEMBLER)
             && (create.status == TRUE))
            {
                line = &crunchedline[0] ;
                /* Traitement de l'étiquette */
                if (*line == '/') create.comment ^= COMMENT_LOCK ;
                else
                if ((create.comment == 0)
                 && (*line != '\0')
                 && (*line != '*')
                 && (*line != '/'))
                {
                    while (((unsigned char)*line <= 0xF0) && (*line != 0x0D))
                    {
                        *(line) = upper_case((unsigned char)*(line)) ;
                        line++ ;
                    }
                    while ((unsigned char)*line > 0xF0) line++ ;

                    /* Traitement de l'instruction/directive/macro */
                    if ((*line != 0x0D) && (*line != '*'))
                    {
                        i = 0 ;
                        while (((unsigned char)*line <= 0xF0) && (*line != 0x0D))
                        {
                           *line = upper_case(*line) ;
                           arg[i++] = *(line++) ;
                        }
                        arg[i] = '\0' ;
                        while ((unsigned char)*line > 0xF0) line++ ;

                        if (*line != 0x0D)
                        {
                            /* Recherche si opérande pour instruction */
                            upper_string(arg) ;
                            i = 0 ;
                            while((i<ITSIZE) && (done == FALSE))
                            {
                                if(!strcmp(inst_table[i].name,arg))
                                {
                                    flag = inst_table[i].ifuppercase ;
                                    done = TRUE ;
                                }
                                i++ ;
                            }

                            /* Recherche si opérande pour directive */
                            i = 0 ;
                            while((i<DTSIZE) && (done == FALSE))
                            {
                                if(!strcmp(direct_table[i].name,arg))
                                {
                                    flag = direct_table[i].ifuppercase ;
                                    done = TRUE ;
                                }
                                i++ ;
                            }

                            /* Traitement de l'opérande éventuelle */
                            if ((done == TRUE) && (flag == TRUE))
                            {
                                while (((unsigned char)*line < 0xF0) && (*line != 0x0D))
                                {
                                    if ((*line == '\'')
                                     && (*(line + 1) != 0x0D))
                                        line++ ;
                                    else
                                        *line = upper_case((unsigned char)*line) ;
                                    line++ ;
                                }
                            }
                        }
                    }
                }
            }

            /*
             * Sauvegarde éventuellement la ligne au format ASM
             */

            if ((fp_asm != NULL)
             && (create.status == TRUE))
                fwrite(crunchedline,sizeof(char),csize,fp_asm) ;
        }
        return NO_ERROR ;
    }

    /* Vérifie la validité du marquage */
    line++ ;
    if (ScanLine() != ALPHA_CHAR)
        return PrintError(ERR_WRONG_MARK) ;
    for(i=0;i<MTSIZE;i++)
        if (!strcmp(arg,mark[i].name))
            markflag = mark[i].type ;
    if (markflag == NO_MARK)
        return PrintError(ERR_WRONG_MARK) ;
    if(*(line++) != ')')
        return PrintError(ERR_WRONG_MARK) ;

    /* Traite le marquage */
    switch(markflag)
    {
        case MAIN_MARK :
        case INCLUDE_MARK :
            CloseASM() ;
            SkipSpaces() ;
            if (GetDescriptor("ASM") != NO_ERROR)
                return ERR_ERROR ;
            /* Vérifie l'unicité du nom de source */
            next_source = first_source ;
            do {
                current_source = next_source ;
                if (!strcmp(current_source->name,desc.name))
                    return PrintError(ERR_DUPLICATE_NAME) ;
            } while((next_source = next_source->next) != NULL) ;

            /* Enregistre la déclaration */
            switch(markflag)
            {
                case MAIN_MARK :
                    /* Met à jour le 'main' */
                    current_source = first_source ;
                    if (current_source->start != NULL)
                        return PrintError(ERR_DUPLICATE_MAIN) ;
                    break ;
                case INCLUDE_MARK :
                    /* Chaîne l'include */
                    current_source->next = malloc(sizeof(struct SRCLIST)) ;
                    current_source = current_source->next ;
                    current_source->next = NULL ;
                    break ;
            }
            /* Enregistre les paramètres de l'include */
            current_source->drive = desc.drive ;
            current_source->name[0] = '\0' ;
            strcat(current_source->name,desc.name) ;
            current_source->line = run.line ;
            current_source->start = source ;
            current_source->asm_size = 0 ;
            create.top = 0 ;
            create.bottom = 0 ;
            create.comment = 0 ;
            /* Ouvre le fichier suivant */
            if (create.status == TRUE)
                fp_asm = fopen(current_source->name,"wb") ;
            break ;
    }
    return NO_ERROR ;
}


/*
 * Chargement du fichier source
 */
int LoadFile(char *name)
{
    FILE *fp_file ;

    int fsize = 1 ;
    int error ;

    if (!(fp_file = fopen(name,"rb")))
    {
        printf("*** Impossible d'ouvrir '%s'\n",name) ;
        return ERR_ERROR ;
    }
    fseek(fp_file, 0, SEEK_END) ;
    fsize = ftell(fp_file) ;
    fclose(fp_file) ;
    filebuffer = malloc(fsize+1) ;
    fp_file = fopen(name,"rb") ;
    fread(filebuffer, sizeof(char), fsize, fp_file) ;
    fclose(fp_file) ;
    filebuffer[fsize] = '\0' ;

    run.line = 0 ;
    source = filebuffer ;
    current_source = first_source ;
    while (source < filebuffer+fsize)
    {
        /* Sauve le pointeur de fin du source précédent */
        current_source->end = source ;
        
        /* Récupère la ligne */
        if ((error = GetLine()) != NO_ERROR)
            return PrintError(error) ;
        RecordSourceChainIf() ;
    }
    CloseASM() ;
    current_source->end = source ;
    if (first_source->start == NULL)
        return PrintError(ERR_MISSING_MAIN) ;

    return NO_ERROR ;
}


/*
 * Assemble le source
 */
void AssembleSource(int pass)
{
    int i = 0 ;

    const struct {
        char string[11] ; /* Message de pass */
        int type ;        /* Code de pass */
    } PassTable[3] = {
        { "Macro Pass", MACROPASS },
        { "Pass1"     , PASS1     },
        { "Pass2"     , PASS2     },
    } ;

    /* Notifie le pass d'assemblage */
    run.pass = pass ;
    if ((run.pass == MACROPASS)
     && (scan.soft == SOFT_ASSEMBLER))
        return ;
    while(PassTable[i].type != run.pass) i++ ;
    fprintf(fp_lst,"%s\n", PassTable[i].string) ;
    printf("%s\n", PassTable[i].string) ;

    /* Initialise les variables d'assemblage */
    run.exit  = FALSE ;
    macro.count  = 0 ;
    run.dp    = 0x00 ;
    run.pc    = 0x0000 ;
    run.exec  = 0x0000 ;
    ifc.count = 0 ;
    ifc.buf[0]  = IF_TRUE ;
    run.locked = UNLOCKED ;
    info.cycle.total = 0 ;
    info.size = 0 ;
    check[0][0] = 0 ;
    check[0][1] = 0 ;
    check[1][0] = 0 ;
    check[1][1] = 0 ;
    macro.level = 0 ;
    memcpy(&run.opt, &scan.opt, sizeof(run.opt)) ;

    /* Initialise les listes d'includes/arguments de macros */
    InitIncludChain() ;
    InitMacroArgChain() ;

    /* Assemble les lignes des sources */
    source   = first_source->start ;
    run.line = first_source->line ;
    while((run.exit == FALSE)
       && (source != first_source->end))
        AssembleLine() ;

    /* Erreur si macro en cours */
    if (run.locked & MACRO_LOCK)
        PrintError(ERR_MISSING_ENDM) ;
    /* Erreur si commentaire en cours */
    if (run.locked & COMMENT_LOCK)
        PrintError(ERR_MISSING_SLASH) ;
    /* Traite les erreurs si pas END */
    if (run.exit == FALSE)
    {
        /* Erreur si assemblage conditionnel en cours */
        if (ifc.count != 0)
            PrintError(ERR_MISSING_ENDC) ;
        /* Erreur si ASSEMBLER et pas 'END' */
        if (scan.soft == SOFT_ASSEMBLER)
            PrintError(ERR_MISSING_END_STATEMENT) ;
    }
    /* Libère les listes d'includes/arguments de macros */
    FreeIncludChain() ;
    FreeMacroArgChain() ;
}



/***********************************************************************
 *
 * Programme principal
 *
 ***********************************************************************/

/*
 * Vérifie si pas de dépassement de capacité de l'ASM
 */
void CheckSourceSize(int size, char *name)
{
    if (size > 29000)
    {
        fprintf(fp_lst,"*** Le fichier '%s' pourrait être trop grand pour être chargé\n", name) ;
        printf("*** Le fichier '%s' pourrait etre trop grand pour etre charge\n", name) ;
    }
}

/*
 * Enregistre l'en-tête de listing
 */
void PrintListHeader(char *fload, char *fsave)
{
    struct SRCLIST *current_source ;
    fprintf(fp_lst,"/*--------------------------------------------------------------*\n") ;
    fprintf(fp_lst," * Compilé avec C6809 v0.83                                     *\n") ; 
    fprintf(fp_lst," *--------------------------------------------------------------*\n") ;
    fprintf(fp_lst," * Fichier source      : %s\n",fload) ;
    fprintf(fp_lst," * Fichier destination : %s\n",fsave) ;
    fprintf(fp_lst," * Contenu :\n") ;
    CheckSourceSize(first_source->asm_size, first_source->name) ;
    fprintf(fp_lst," *     Main     %1d:%-12s %d\n",
                               first_source->drive,
                               first_source->name,
                               first_source->asm_size) ;
    current_source = first_source ;
    if ((current_source = current_source->next) != NULL)
    {
        do {
            CheckSourceSize(current_source->asm_size, current_source->name) ;
            fprintf(fp_lst," *     Include  %1d:%-12s %d\n",
                               current_source->drive,
                               current_source->name,
                               current_source->asm_size) ;
        } while((current_source = current_source->next) != NULL) ;
    }
    fprintf(fp_lst," *--------------------------------------------------------------*/\n") ;
    fprintf(fp_lst,"\n") ;
}

/*
 * Referme toutes les déclarations
 */
int CloseAll(void)
{
    /* Libération des mémoires */
    FreeErrorChain() ;   /* Erreurs  */
    FreeSymbolChain() ;  /* Symboles */
    FreeSourceChain() ;  /* Sources  */
    FreeMacroChain() ;   /* Macros   */

    /* Fermeture des fichiers */
    fclose(fp_lst) ;
    return 0 ;
}


/*
 * Affichage de l'aide
 */
void PrintHelp(void)
{
    printf("\n") ;
    printf("Compilateur Macro/Assembler-like\n") ;
    printf("  Francois MOURET (c) C6809 v 0.83 - mars 2010\n") ;
    printf("\n") ;
    printf("C6809 [options] fichier_source fichier_destination\n") ;
    printf("\n") ;
    printf("  options :\n") ;
    printf("  -h  aide de ce programme\n") ;
    printf("  -o  option(s) d'assemblage (NO, OP, SS, WE, WL et WS)\n") ;
    printf("      les parametres d'option (tous desactives par defaut) doivent\n") ;
    printf("      etre separes par des '/'\n") ;
    printf("  -b  type de la sortie (binaire non lineaire par defaut)\n") ;
    printf("      l  binaire lineaire\n") ;
    printf("      h  binaire hybride\n") ;
    printf("      d  donnee\n") ;
    printf("  -d  passage d'argument (<symbole>=<valeur>)\n") ;
    printf("  -c  cree les fichiers ASM au format Thomson\n") ;
    printf("  -q  notifie le depassement de 40 caracteres par ligne (300 par defaut)\n") ;
    printf("  -e  groupe les messages d'erreur du listing (ordre de ligne par defaut)\n") ;
    printf("  -s  ordre d'affichage des symboles du listing (alphabetique par defaut)\n") ;
    printf("      e  par erreur de symbole\n") ;
    printf("      t  par type de symbole\n") ;
    printf("      n  par frequence d'utilisation\n") ;
    printf("  -a  Notifie la compatibilite (assembleur virtuel par defaut)\n") ;
    printf("      a  ASSEMBLER1.0 et ASSEMBLER 2.0\n") ;
    printf("      m  MACROASSEMBLER 3.6\n") ;
    printf("  -m  + TO/TO7/MO machine de travail (TO par defaut)\n") ;
    exit(CloseAll()) ;
}

/*
 * Affichage de l'erreur et du conseil
 */
void PrintAdvice(char *argument, char *errorstring)
{
    printf("*** %s : %s\n", argument, errorstring) ;
    printf("Taper 'C6809 -h' pour afficher l'aide\n") ;
    exit(CloseAll()) ;
}



/*
 * Programme principal
 */
int main(int argc, char *argv[])
{
    int i ;
    int fcount = 0 ;
    char label[ARG_MAX_SIZE+2] = "";
    char my_argv[ARGV_MAX_SIZE] = "";
    char fload[ARGV_MAX_SIZE] = "";
    char fsave[ARGV_MAX_SIZE] = "";
    int argp ;

    const struct {
        char name[4] ; /* Nom de l'option */
        int type ;     /* Code de l'option */
      } Computer[3] = {
            { "TO" , TO_COMPUTER  },
            { "TO7", TO7_COMPUTER },
            { "MO" , MO_COMPUTER  }
    } ;

   /*
    * Initialisation du programme
    */
    memset(&bin, 0, sizeof(bin)) ;
     bin.type = BIN_FILE ;
    memset(&run, 0, sizeof(run)) ;
     run.pass        = SCANPASS ;
     run.opt[OPT_NO] = FALSE ;
     run.opt[OPT_OP] = FALSE ;
     run.opt[OPT_SS] = FALSE ;
     run.opt[OPT_WE] = FALSE ;
     run.opt[OPT_WL] = FALSE ;
     run.opt[OPT_WS] = FALSE ;
    memset(&scan, 0, sizeof(scan)) ;
     scan.computer   = TO_COMPUTER ;
     scan.soft       = SOFT_UPDATE ;
     scan.symb_order = INITIAL_ORDER ;
     scan.err_order  = INITIAL_ORDER ;
     scan.limit      = COLON_300 ;
     scan.opt[OPT_NO] = FALSE ;
     scan.opt[OPT_OP] = FALSE ;
     scan.opt[OPT_SS] = FALSE ;
     scan.opt[OPT_WE] = FALSE ;
     scan.opt[OPT_WL] = FALSE ;
     scan.opt[OPT_WS] = FALSE ;
    memset(&macro, 0, sizeof(macro)) ;
    memset(&create, 0, sizeof(create)) ;
     create.status  = FALSE ;
     create.comment = 0 ;

    /*
     * Ouverture du fichier de liste
     */
    if ((fp_lst = fopen("codes.lst","w")) == NULL) {
        printf("*** Impossible d'ouvrir le fichier 'codes.lst'\n") ;
        return 0 ; }

    /* Initialisation des listes */
    InitErrorChain() ;   /* Erreurs  */
    InitSymbolChain() ;  /* Symboles */
    InitSourceChain() ;  /* Sources  */
    InitMacroChain() ;   /* Macros   */

   /*
    * Traitement des arguments de lancement
    */
    if(argc < 2) PrintHelp() ;

    for(argp=1; argp<argc; argp++)
    {
        snprintf (my_argv, (strlen(argv[argp])+1 > (size_t)ARGV_MAX_SIZE)
                               ? (size_t)ARGV_MAX_SIZE : strlen(argv[argp])+1,
                           "%s", argv[argp]);
        my_argv[(int)strlen(my_argv)] = '\0';
        for (i=(int)strlen(my_argv); i>=0; i--)
             if (my_argv[i] <= 0x20)
                 my_argv[i] = '\0';
             else break;
             
        if (my_argv[0] == '-')
        {
            switch ((int)strlen(my_argv))
            {
                case 2 :
                    switch(my_argv[1])
                    {
                        case 'h' : PrintHelp() ; break ;
                        case 'c' : create.status  = TRUE        ; break ;
                        case 'q' : scan.limit     = COLON_40    ; break ;
                        case 'e' : scan.err_order = ERROR_ORDER ; break ;
                        case 'd' :
                        case 'a' :
                        case 'b' : 
                        case 's' :
                        case 'o' :
                            PrintAdvice (my_argv, "Option incomplete") ;
                            break ;
                        default :
                            PrintAdvice (my_argv, "Option inconnue") ;
                            break ;
                    }
                    break ;
                case 3 :
                    switch(my_argv[1])
                    {
                        case 'b' :
                            switch(my_argv[2])
                            {
                                case 'l' : bin.type = LINEAR_FILE ; break ;
                                case 'd' : bin.type = DATA_FILE   ; break ;
                                case 'h' : bin.type = HYBRID_FILE ; break ;
                                case 's' : break ;
                                default :
                                    PrintAdvice(my_argv, "Parametre d'option inconnu") ;
                                    break ;
                            }
                            break ;
                        case 's' :
                            switch(my_argv[2])
                            {
                                case 'e' : scan.symb_order = ERROR_ORDER ; break ;
                                case 't' : scan.symb_order = TYPE_ORDER  ; break ;
                                case 'n' : scan.symb_order = TIME_ORDER  ; break ;
                                default :
                                    PrintAdvice(my_argv,"Parametre d'option inconnu") ;
                                    break ;
                            }
                            break ;
                        case 'a' :
                            switch(my_argv[2])
                            {
                                case 'a' : scan.soft = SOFT_ASSEMBLER      ; break ;
                                case 'm' : scan.soft = SOFT_MACROASSEMBLER ; break ;
                                default :
                                    PrintAdvice (my_argv, "Parametre d'option inconnu") ;
                                    break ;
                            }
                            break ;
                             
                        default :
                            PrintAdvice (my_argv, "Option inconnue") ;
                            break ;
                    }
                    break ;
                default :
                    switch(my_argv[1])
                    {
                        case 'o' :
                            line = &my_argv[2] ;
                            Ass_OPT() ;
                            memcpy(&scan.opt, &run.opt, sizeof(run.opt)) ;
                            break ;
                        case 'm' :
                            upper_string(&my_argv[2]) ;
                            i = 0 ;
                            while((i<3) && (!strcmp(&my_argv[2],Computer[i].name))) i++ ;
                            if (i == 3)
                                PrintAdvice (my_argv, "Parametre d'option inconnu") ;
                            else scan.computer = Computer[i].type ;
                            break ;
                        case 'd' :
                            i = ERR_ERROR ;
                            line = &my_argv[2] ;
                            if (ScanLine() == ALPHA_CHAR)
                            {
                                label[0] = '\0' ;
                                strcat(label,arg) ;
                                if ((ScanLine() == SIGN_CHAR)
                                 && (arg[0] == '='))
                                {
                                    if (Eval() == NO_ERROR)
                                    {
                                        run.pass = PASS1 ;
                                        i = DoSymbol(label,eval.operand,ARG_VALUE) ;
                                        run.pass = SCANPASS ;
                                    }
                                }
                            }
                            if (i != NO_ERROR) PrintAdvice (my_argv, "Erreur de parametrage") ;
                            break ;
                        default :
                            PrintAdvice (my_argv, "Option inconnue") ;
                            break ;
                    }
                    break ;
            }
        }
        else
        {
            switch(fcount)
            {
                case 0 : snprintf (fload, ARGV_MAX_SIZE, "%s", my_argv); break ;
                case 1 : snprintf (fsave, ARGV_MAX_SIZE, "%s", my_argv); break ;
                default :
                    PrintAdvice (my_argv, "Argument excedentaire") ;
                    break ;
            }
            fcount++ ;
        }
    }

    /*
     * Vérification des arguments de lancement
     */
    if (fload == NULL) PrintAdvice(fload,"Fichier source manquant") ;
    if (fsave == NULL) PrintAdvice(fsave,"Fichier destination manquant") ;
    if(!strchr(fload,'.')) PrintAdvice(fload,"Suffixe de fichier necessaire") ;
    if(!strchr(fsave,'.')) PrintAdvice(fsave,"Suffixe de fichier necessaire") ;

    /*
     * Assemblage du source
     */
    if (LoadFile(fload) == NO_ERROR)
    {
        if (OpenBin(fsave) == NO_ERROR)
        {
            /* Engagement pour le listing */
            PrintListHeader(fload,fsave) ;

            /* Assemblage du source */
            AssembleSource(MACROPASS) ;
            AssembleSource(PASS1) ;
            AssembleSource(PASS2) ;

            /* Enregistrement des erreurs */
            PrintErrorList() ;

            /* Enregistrement des symboles */
            PrintSymbolList() ;

            CloseBin() ;
        }

        if (filebuffer != NULL) free(filebuffer) ;
    }

    return CloseAll() ;
}
