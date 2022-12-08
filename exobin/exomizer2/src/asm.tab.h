/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

#ifndef YY_YY_ASM_TAB_H_INCLUDED
# define YY_YY_ASM_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 1
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    INCLUDE = 258,                 /* INCLUDE  */
    IF = 259,                      /* IF  */
    DEFINED = 260,                 /* DEFINED  */
    MACRO = 261,                   /* MACRO  */
    MACRO_STRING = 262,            /* MACRO_STRING  */
    ORG = 263,                     /* ORG  */
    ERROR = 264,                   /* ERROR  */
    ECHO1 = 265,                   /* ECHO1  */
    INCBIN = 266,                  /* INCBIN  */
    INCLEN = 267,                  /* INCLEN  */
    INCWORD = 268,                 /* INCWORD  */
    RES = 269,                     /* RES  */
    WORD = 270,                    /* WORD  */
    BYTE = 271,                    /* BYTE  */
    LDA = 272,                     /* LDA  */
    LDX = 273,                     /* LDX  */
    LDY = 274,                     /* LDY  */
    STA = 275,                     /* STA  */
    STX = 276,                     /* STX  */
    STY = 277,                     /* STY  */
    AND = 278,                     /* AND  */
    ORA = 279,                     /* ORA  */
    EOR = 280,                     /* EOR  */
    ADC = 281,                     /* ADC  */
    SBC = 282,                     /* SBC  */
    CMP = 283,                     /* CMP  */
    CPX = 284,                     /* CPX  */
    CPY = 285,                     /* CPY  */
    TSX = 286,                     /* TSX  */
    TXS = 287,                     /* TXS  */
    PHA = 288,                     /* PHA  */
    PLA = 289,                     /* PLA  */
    PHP = 290,                     /* PHP  */
    PLP = 291,                     /* PLP  */
    SEI = 292,                     /* SEI  */
    CLI = 293,                     /* CLI  */
    NOP = 294,                     /* NOP  */
    TYA = 295,                     /* TYA  */
    TAY = 296,                     /* TAY  */
    TXA = 297,                     /* TXA  */
    TAX = 298,                     /* TAX  */
    CLC = 299,                     /* CLC  */
    SEC = 300,                     /* SEC  */
    RTS = 301,                     /* RTS  */
    JSR = 302,                     /* JSR  */
    JMP = 303,                     /* JMP  */
    BEQ = 304,                     /* BEQ  */
    BNE = 305,                     /* BNE  */
    BCC = 306,                     /* BCC  */
    BCS = 307,                     /* BCS  */
    BPL = 308,                     /* BPL  */
    BMI = 309,                     /* BMI  */
    BVC = 310,                     /* BVC  */
    BVS = 311,                     /* BVS  */
    INX = 312,                     /* INX  */
    DEX = 313,                     /* DEX  */
    INY = 314,                     /* INY  */
    DEY = 315,                     /* DEY  */
    INC = 316,                     /* INC  */
    DEC = 317,                     /* DEC  */
    LSR = 318,                     /* LSR  */
    ASL = 319,                     /* ASL  */
    ROR = 320,                     /* ROR  */
    ROL = 321,                     /* ROL  */
    BIT = 322,                     /* BIT  */
    SYMBOL = 323,                  /* SYMBOL  */
    STRING = 324,                  /* STRING  */
    LAND = 325,                    /* LAND  */
    LOR = 326,                     /* LOR  */
    LNOT = 327,                    /* LNOT  */
    LPAREN = 328,                  /* LPAREN  */
    RPAREN = 329,                  /* RPAREN  */
    COMMA = 330,                   /* COMMA  */
    COLON = 331,                   /* COLON  */
    X = 332,                       /* X  */
    Y = 333,                       /* Y  */
    HASH = 334,                    /* HASH  */
    PLUS = 335,                    /* PLUS  */
    MINUS = 336,                   /* MINUS  */
    MULT = 337,                    /* MULT  */
    DIV = 338,                     /* DIV  */
    MOD = 339,                     /* MOD  */
    LT = 340,                      /* LT  */
    GT = 341,                      /* GT  */
    EQ = 342,                      /* EQ  */
    NEQ = 343,                     /* NEQ  */
    ASSIGN = 344,                  /* ASSIGN  */
    GUESS = 345,                   /* GUESS  */
    NUMBER = 346,                  /* NUMBER  */
    vNEG = 347,                    /* vNEG  */
    LABEL = 348                    /* LABEL  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 145 "asm.y"

    i32 num;
    char *str;
    struct atom *atom;
    struct expr *expr;

#line 164 "asm.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;


int yyparse (void);


#endif /* !YY_YY_ASM_TAB_H_INCLUDED  */
