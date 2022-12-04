#ifndef ZPU_H
#define ZPU_H

#define ZPU_IM               128
#define ZPU_BREAKPOINT       0
#define ZPU_PUSHSP           2
#define ZPU_POPPC            4
#define ZPU_ADD              5
#define ZPU_AND              6
#define ZPU_OR               7
#define ZPU_LOAD             8
#define ZPU_NOT              9
#define ZPU_FLIP             10
#define ZPU_NOP              11
#define ZPU_STORE            12
#define ZPU_POPSP            13
#define ZPU_ADDSP            16
#define ZPU_EMULATE          32
#define ZPU_LOADH            34
#define ZPU_STOREH           35
#define ZPU_LESSTHAN         36
#define ZPU_LESSTHANOREQUAL  37
#define ZPU_ULESSTHAN        38
#define ZPU_ULESSTHANOREQUAL 39
#define ZPU_SWAP             40
#define ZPU_MULT             41
#define ZPU_LSHIFTRIGHT      42
#define ZPU_ASHIFTLEFT       43
#define ZPU_ASHIFTRIGHT      44
#define ZPU_CALL             45
#define ZPU_EQ               46
#define ZPU_NEQ              47
#define ZPU_NEG              48
#define ZPU_SUB              49
#define ZPU_XOR              50
#define ZPU_LOADB            51
#define ZPU_STOREB           52
#define ZPU_DIV              53
#define ZPU_MOD              54
#define ZPU_EQBRANCH         55
#define ZPU_NEQBRANCH        56
#define ZPU_POPPCREL         57
#define ZPU_CONFIG           58
#define ZPU_PUSHPC           59
#define ZPU_SYSCALL          60
#define ZPU_PUSHSPADD        61
#define ZPU_MULT16X16        62
#define ZPU_CALLPCREL        63
#define ZPU_STORESP          64
#define ZPU_LOADSP           96

#define VECTORSIZE           0x20
#define VECTOR_RESET         0
#define VECTOR_INTERRUPT     1
#define VECTORBASE           0x0


// Define these if emulation of any ops is desired
//#define EMULATE_PUSHSPADD         1
//#define EMULATE_POPPCREL          1
//#define EMULATE_SUB               1
//#define EMULATE_XOR               1
//#define EMULATE_LOADB             1
//#define EMULATE_STOREB            1
//#define EMULATE_LOADH             1
//#define EMULATE_STOREH            1
//#define EMULATE_LESSTHAN          1
//#define EMULATE_LESSTHANOREQUAL   1
//#define EMULATE_ULESSTHAN         1
//#define EMULATE_ULESSTHANOREQUAL  1
//#define EMULATE_EQUBRANCH         1
//#define EMULATE_NEQBRANCH         1
//#define EMULATE_MULT              1
//#define EMULATE_DIV               1
//#define EMULATE_MOD               1
//#define EMULATE_LSHIFTRIGHT       1
//#define EMULATE_ASHIFTLEFT        1
//#define EMULATE_ASHIFTRIGHT       1
//#define EMULATE_CALL              1
//#define EMULATE_CALLPCREL         1
//#define EMULATE_EQ                1
//#define EMULATE_NEQ               1
//#define EMULATE_NEG               1
//#define EMULATE_CONFIG            1


void zpu_reset();
void zpu_execute();

#endif // ZPU_H
