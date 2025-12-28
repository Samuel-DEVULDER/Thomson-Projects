      ORG   $0000

* 132 bytes long

START  LDD   #12*256
       BSR   PRINT
       BSR   FLAKE
       BSR   DOWN8
       JMP   $CD03           ; Warmstart

DOWN8  BSR   DOWN4
DOWN4  BSR   DOWN2
DOWN2  BSR   DOWN
       BRA   DOWN

FLAKE  CLRB
       BSR   M10
       LDB   #4

R4     BSR   R2
R2     BSR   R1
R1     BSR   M4
       BSR   T3
       BSR   T3
       ADDB  #4
       BSR   M10
       ADDB  #3
       BSR   M5
       BSR   T3
       LDA   #32
       BSR   CH
       ADDB  #4
       BSR   M4
       BSR   M4
       ADDB  #3
       RTS

T3     BSR   T1
       DECB
       BSR   T1
       ADDB  #3
       BRA   M3

T1     DECB
       BSR   M2
       ADDB  #4
       BRA   M2

M10    BSR   M5       ; move 10 steps
M5     BSR   M1       ; move 5 steps
M4     BSR   M1       ; move 4 steps
M3     BSR   M1       ; move 3 steps
M2     BSR   M1       ; move 2 steps
M1     ANDB  #7       ; move 1 step
       LEAY  <DIR,PCR ; primtive step table
       LDA   B,Y
       JSR   A,Y
       LDA   #'*      ; load A with STAR
CH     BSR   PRINT    ; print char in B
       BRA   LEFT     ; backspace

DNRGHT BSR   RIGHT    ; move down-right
       FCB   $8C      ; cmpx #nnnn
DNLEFT BSR   LEFT     ; move down-left
       BRA   DOWN
UPLEFT BSR   LEFT     ; move up-left
       FCB   $8C      ; cmpx #nnnn
UPRGHT BSR   RIGHT    ; move up-right
UP     LDA   #11
       FCB   $8C      ; cmpx #nnnn
DOWN   LDA   #10      ; move down
       FCB   $8C      ; cmpx #nnnn
RIGHT  LDA   #9       ; move right
       FCB   $8C      ; cmpx #nnnn
LEFT   LDA   #8       ; move left
PRINT  JMP   $CD18    ; PUTCHR (FLEX9)

DIR    FCB   RIGHT-DIR,UPRGHT-DIR
       FCB   UP-DIR,UPLEFT-DIR
       FCB   LEFT-DIR,DNLEFT-DIR
       FCB   DOWN-DIR,DNRGHT-DIR

       END   START
