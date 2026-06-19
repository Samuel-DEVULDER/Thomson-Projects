* Title:      Bloody Run
* Category:   Intro 1024 bytes
* Size:       1024 bytes
* Features:   Raster tubes + anim + 3 voices music
* Made for:   Forever Party 2014
* 
* Group:      PULS (http://www.pulsdemos.com)
* Author(s):  François Mouret (alias Prehisto)
* Contact:    fjjm@orange.fr
* 
* Machine(s): Thomson TO8, TO8D, TO9+ (6809e @ 1Mhz) with or without memory extension.
* Format:     Standard binary thomson file. Can be launched with 
*                   CLEAR,&H9E00:BANK3:LOADM"BLODYRUN",,R
*             For convenience, AUTO.BAT is provided on the floppy.
* Packer:     None. Code is just optimized.
* 
* Remarks:    1) 34 long seconds to wait before start.
*             2) Restarting the computer is needed to stop it.
*             3) Music is few measures of William Tell by Rossini (final part).
*             4) Source code is available on the disk.
*             5) It is really a crazy bloody run !
*             6) The format of this README is copyright Samuel Devulder ;)

NVOICE  equ   3
  
* ExtraMon registers
VALTYP  equ   $6105
FACLO   equ   $6151
COULEUR equ   $619f
TRATYP  equ   $61a0
XXXX    equ   $61a1
YYYY    equ   $61a3
XR      equ   $61a9
YT      equ   $61ab
FILFLG  equ   $61ef
AXEV    equ   $61f0
AXEH    equ   $61f1


* Extra registers
Zero    equ   $6101
cCount  equ   $6105
sValue  equ   $61d6
sFreq   equ   $61d7
sNote   equ   $61d8
cCom    equ   $61d9
blkPal  equ   $61dd
  
        org   $9e22

        setdp $61

*--------------------------------------
* Start of program
*--------------------------------------
debut   equ   *
        clr   >$60ff Hard reset required
        ldx   #$60de Area set to $00
        lbsr  fixpal Palette to 0
        lbsr  PrintS
        pulu  cc,a,b,dp,x,y,s
        stx   $602f Set SWI interrupt
        call  0+$80 Reset ExtraMon
        sta   <XR+1 X1 window
        stb   <YT+1 Y1 window
        sty   $627d Set gfx pattern
        tfr   s,y
        tfr   pc,s
        com   <FILFLG Full elipse
*--------------------------------------
* Create cosinus list
*--------------------------------------
* U already points to lCos
cosin equ *
        leax  ,u
        lda   #4  For REAL type
        swi     
        fcb   50  FAC into REAL
        fcb   62+$80 Startvalue->FAC
cos1    swi 
        fcb   47  FAC=COS(FAC)
        fcb   64+$80 FAC->ARG
        leax  9,u
        swi 
        fcb   62  Mult->FAC
        fcb   56  FAC=FAC*ARG
        fcb   64+$80 FAC->ARG
        leax  9,u
        lda   #2  For INT type
        swi 
        fcb   62  Add->FAC
        fcb   54  FAC=FAC+ARG
        fcb   50+$80 FAC into INT
        ldb   <FACLO  ! Record int
        stb   ,y+ ! value of FAC
        leax  ,u
        lda   #4  For REAL type
        swi 
        fcb   50  FAC into REAL
        fcb   62  StartValue->FAC
        fcb   64+$80 FAC->ARG
        leax  5,u
        swi 
        fcb   62  Step->FAC
        fcb   54+$80 FAC=FAC+ARG
        leax  ,u  ! FAC->StartValue
        call  63+$80 !
        dec   4,u
        bne   cos1
        leau  11,u
        com   <cCom
        bne   cosin
*--------------------------------------
* Create music sample
*--------------------------------------
* U points already to Score
        bsr   smp6  Init bank ptr
* Define frequency
smp0    ldb   ,u+ Read note again
        andb  #$1f  Frequency offset
        leay  <lFreq-1,pcr Freq list
        ldb   b,y Read frequency
        andb  #$7f  Limit frequency
        stb   <sFreq Block size/Freq
* Define tempo
        clr   <sNote Note=0 for silence
        lda   -1,u  Read note value
        beq   smp8  Next voice
        bita  #$e0  Test type of note
        beq   smp1  Silence if 0
        ldb   #$08  ! Tempo for
        mul         ! played note
        com   <sNote Activate note
smp1    anda  #$1f  !
        asla        ! Tempo silence
        asla        !
        ldb #234    !
        mul         ! * block size
        tfr d,y     !
        clr   <sValue Value set to 0
* Manage frequency
smp2    lda   <sFreq  Init frequency
        com   <sValue Record start value
smp3    deca          ! Skip if not time
        bmi   smp2    ! to change value
* Record value
        ldb   <sValue Read value
        andb  <sNote
        andb  #$3f/NVOICE ! current val
smp4    leax  ,x  Add value (addb ,x)
        stb   ,x+ Write value
* Next bank if necessary
        cmpx  #16380
        blo   smp5
        ldb   >$e7e6
        incb
        bsr   smp7
* Next value
smp5    leay  -1,y  ! Next
        bne   smp3  ! value
* Next Note
        bra   smp0  Next note
smp6    ldd   #$eb65 Start bank (5)
smp7    orb   #$80  Code for bank
        stb   ,x  Write next bank
        stb   >$e7e6 Update bank switch
        ldx   #$0000 Start pointer
        rts
lFreq   equ   *
        fcb   40
        fcb   59
        fcb   79
        fcb   30
        fcb   47
        fcb   27
        fcb   24
        fcb   32
        fcb   53
        fcb   63
        fcb   20
        fcb   23
* Display a message
PrintS  ldu   #mScrol
prtf0   ldb   ,u+
        jsr   $e803
        bne   prtf0
        rts
* Next voice
smp8    bsr   smp6  Bank start
        sta   >smp4 LEAX -> ADDB
        tst   ,u  ! Next voice
        bne   smp0  !
Create  equ   *
        dec   <cCount
*--------------------------------------
* Create circles (colors 3-7)
*--------------------------------------
        bsr   PrintS
circle equ  *
        ldb   <cCount Read screen number
        ldx   #Cosin+256 Cosinus ptr
        abx 
        ldy   #4
circ0   lda   #7
circ1   ldb   4*5,x ! X center
        addb  #9
        stb   <XXXX+1 !
        ldb   ,x    ! Y center
        addb  #22
        stb   <YYYY+1 !
        sta   <COULEUR Set colour
        ldb   #10
        bsr   circf
        clr   <COULEUR Set colour
        ldb   #8
        bsr   circf
        leax  4,x
        deca  
        cmpa  #3
        bhs   circ1
        leay  -1,y  Counter - 1
        bne   circ0
*--------------------------------------
* Create text map (color 1)
*--------------------------------------
        ldb   #$60
        stb   >$e7e6
        inc   <COULEUR
        ldu   #$0000+320-40-20
        ldy   #200
ptxt0   ldx   #160
        leay  -1,y
ptxt1   leau  -1,u
        cmpu  <Zero
        beq   ptxt4
        lda   #8
ptxt2   leax  -1,x
        beq   ptxt0
        lsr   ,u
        bcc   ptxt3
        swi
        fcb   28  CHOIX
        fcb   25+$80 PSETXY
ptxt3   deca
        bne   ptxt2
        bra   ptxt1

* Draw a full circle
circf   stb   <AXEV
        lsrb
        stb   <AXEH
        swi
        fcb   28  CHOIX
        fcb   24+$80 CIRCLE
        rts

ptxt4   equ   *
*--------------------------------------
* Draw runners (color 2)
*--------------------------------------
        inc   <COULEUR
run01   ldx   #-96+12+4
        leax  -4,x
        stx   >run01+1
        ldb   <cCount
run0    ldy   <Zero
        subb  #2
        bpl   run2
        addb  #6
run2    pshs  b,x,y,u
        lda   #15
        mul
        ldu   #rCoord
        leau  b,u
* A is set to 0 at that point
run3    bsr   rgetxy
        beq   run5
        swi
        fcb   28  CHOIX
        fcb   25+$80 PSETXY
run4    bsr   rgetxy
        beq   run3
        call  26+$80 LINE
        bra   run4

rpoint  ldb   ,u+
        coma
        beq   rpt0
        lsrb
        lsrb
        lsrb
        lsrb
        leau  -1,u
rpt0    andb  #$0f
        rts

* Get 4 bits value
rgetxy  bsr   rpoint
        beq   rgetx0
        ldx   3,s
        abx 
        bsr   rpoint
        ldy   5,s
        aslb
        leay  b,y
rgetx0  rts

run5    puls  b,x,y,u
        leax  8,x
        leay  2,y
        call  26+$80 LINE
        leax  1,x
        leay  -2,y
        call  27+$80 BOX
        leax  -8-1+8,x
        leay  31,y
        cmpy  #31*6
        blo   run2
        leax  -8*6+16,x
        cmpx  #164
        blt   run0

*--------------------------------------
* Copy screens
*--------------------------------------
* A is already set to 0
        ldb   <cCount
        decb  
        bmi   cpysc1
        bne   cpysc0
        ldb   #$f-1
cpysc0  addb  #$61
        bsr   copy
        lbra  Create

* Copy screen bank
copy    std   >$e7e5
        ldu   #$a000
        ldx   <Zero
copy0   lda   $2000,u
        ldb   ,u+
        stb   $2000,x
        sta   ,x+
        cmpx  #8000
        blo   copy0
        lda   #$04
        sta   >$e7e5
        rts

* Copy screen bank 1
cpysc1  leas  <copy,pcr
        ldd   #$0f61
        bsr   copy
cpysc2  equ   *
echo  Must be $$a000 -> $*
*--------------------------------------
* Prepare loop
*--------------------------------------
        setdp $e7
* Initialize direct page register
        ldb   #$e7  ! Initialize
        tfr   b,dp  ! direct page
* Activate sound
        clr   <$e7cf
        ldd   #$3f04
        sta   <$e7cd
        stb   <$e7cf
* Calibrate raster verticaly
        ldx   #Palett
        bsr   fixpal
* Calibrate raster horizontaly
        ldx   #$0fff Color 0
        ldd   #$0865 Offset color 8
        bsr   colent
* Calibrate raster
RLINE   equ   231+64
        ldx   #RLINE*8+1
calib   leax  -1,x
        bne   calib
        leax  ,x
* Initialize registers
        bra   loop0 Start loop

* Calibrate raster verticaly
fixpal  lda   #$ff
colent  jmp   $ec00

nop1    tfr   a,a
        bra   loop1
nop2    mul
        nop
nop3    bra   loop5
*--------------------------------------
* Start of the loop
* 1 time
*--------------------------------------
* Manage sound
loop    ldb   ,s  ! Skip if not
        bpl   nop1  ! bank number
loop0   lds   #$0000 Start pointer
        stb   >$e7e6 Activate bank
* Manage tube color
loop1   ldu   #Tubes
loop2   ldy   #Tubes+156
        stu   >loop2+2
        sty   >loop1+1
* Prepare color cycling
loop3   ldu   #PalCyc-2 Palette ptr
* Switch screen
loop4   ldb   #$c0
        addb  #$40  Switch screen
        stb   <$e7dd Activate screen
        stb   >loop4+1 Switch code
* Prepare color cycling
        bne   nop2
        leau  2,u
        cmpu  #PalCyc+10
        blo   nop3
        ldu   #PalCyc
loop5 equ *
        ldd   #(8<8)+146
        std   >nLoop
        tfr   a,a
* Apply tube color
loop6   ldb   ,y  Read color
        clr   <$e7db Color 0
        stb   <$e7da Activate color
        sex       ! Delete color
        sta   ,y+ ! in list
* Generate sound
        ldb   ,s+
        stb   <$e7cd
        com   >lCom
        beq   loop
* ----------------------
* Color cycling program
* 1 time
* ----------------------
        ldb   #3*2
        stb   <$e7db
        ldd   ,u
        stb   <$e7da
        sta   <$e7da
        ldd   2,u
        stb   <$e7da
        sta   <$e7da
        ldd   4,u
        stb   <$e7da
        sta   <$e7da
        ldd   6,u
        stb   <$e7da
        sta   <$e7da
        ldd   8,u
        stb   <$e7da
        sta   <$e7da
        inc   >tube4+1 Prepare tubes
        nop
        nop
colcyc  equ   *
* Apply tube color
        ldb   ,y  Read color
        clr   <$e7db  Color 0
        stb   <$e7da Activate color
        sex       ! Delete color
        sta   ,y+ ! in list
* Generate sound
        ldb   ,s+
        stb   <$e7cd
        stu   >loop3+1
        nop
        clra
* ----------------------
* Creation of the next tubes list
* 8 times
* ----------------------
* Tubes colors list
tube3   tfr   a,b
tube4   addb  #$00
        ldx   #Cosin+128 Sinus table
        ldb   b,x
        addb  #9
        ldx   >loop2+2 Color list
        abx            Color pointer
        ldb   #$ee
        stb   3,x
        stb   4,x
        stb   5,x
        decb
        stb   2,x
        stb   6,x
        ldb   #$cc
        stb   1,x
        stb   7,x
        ldb   #$aa
        stb   0,x
        stb   8,x
        adda  #8
tube5   leax  ,x
* Apply tube color
        ldb   ,y  Read color
        clr   <$e7db Color 0
        stb   <$e7da Activate color
        ldb   #$ff  ! Delete color
        stb   ,y+ ! in list
* Generate sound
        ldb   ,s+
        stb   <$e7cd
        dec   >nLoop
        bne   tube3
* ----------------------
* Blank
* 146 times
blank equ *
        ldb   #8     2
blank0  decb         2
        lbne  blank0 6(5)
        inc   >nLoop
        dec   >nLoop+1 Loop counter
        bne   tube5
* ----------------------
* Loop
* ----------------------
        jmp   loop6

* Personnal SWI interrupt
mathsw  ldu   10,s  Read PC in stack
maths0  ldb   ,u  Read code
        andb  #$7f
        jsr   $ec0c Jump to ExtraMon
        ldb   ,u+
        bpl   maths0
        stu   10,s  Update PC in stack
        rti

mScrol  equ   * Must end with 0
        fcb   $1b,$5e
        fcb   $0c
        fcc   "BLOODY RUN Puls 2014"
lCom    equ   *
        fcb   0
Regs    equ   * Must be here
        fcb   $50            CC
        fcb   159            A
        fcb   199            B
        fcb   $61            DP
        fdb   mathsw         X
        fdb   $e845+(96*8)-1 Y
        fdb   Free           S
lCos    equ   * Must end with $0000
        fcb   $00,$00,$00,$00
        fcb   0
        fcb   $7b,$c9,$0f,$da
        fcb   $86,$70
lCos2   equ   * Must end with $0000
        fcb   $00,$00,$00,$00
        fcb   4*5*4*2
        fcb   $7d,$a0,$d9,$7b
        fcb   $87,$0c
Score   equ   * Must end with 0
        fcb   $01,$61,$01,$61,$01,$41
        fcb   $44,$46,$47,$61,$01,$61
        fcb   $01,$24,$27,$46,$48,$41
        fcb   $61,$01,$61,$01,$41,$44
        fcb   $46,$47,$24,$27,$6b,$01
        fcb   $2b,$2c,$27,$26,$84,$24
        fcb   $00
        fcb   $02,$42,$02,$42,$02,$22
        fcb   $45,$81,$01,$42,$02,$42
        fcb   $03,$41,$49,$4a,$01,$42
        fcb   $02,$42,$02,$23,$45,$81
        fcb   $02,$88,$04,$81,$21
        fcb   $00
        fcb   $03,$23,$03,$23,$0b,$23
        fcb   $03,$23,$0b,$23,$03,$23
        fcb   $13,$45,$47,$25
        fcb   $00
        fcb   $00
PalCyc  equ   *
        fdb   $111  Black
        fdb   $11f  Red
        fdb   $1ff  Yellow
        fdb   $1f1  Green
        fdb   $f11  Blue
        fdb   $111  Black
        fdb   $11f  Red
        fdb   $1ff  Yellow
        fdb   $1f1  Green
rCoord  equ   *
        fcb   $4b,$59,$9a,$77,$8a,$6e
        fcb   $8f,$08,$75,$58,$27,$5a
        fcb   $60,$77,$00
        fcb   $4f,$3e,$6b,$77,$a9,$7b
        fcb   $8d,$07,$65,$48,$28,$5b
        fcb   $50,$77,$00
        fcb   $3f,$1d,$5b,$77,$b8,$9c
        fcb   $bd,$07,$55,$38,$29,$5a
        fcb   $30,$77,$00
        fcb   $2e,$2c,$5b,$78,$a8,$9d
        fcb   $bd,$07,$55,$28,$28,$6a
        fcb   $30,$78,$00
        fcb   $1c,$2a,$6b,$77,$aa,$ae
        fcb   $ce,$07,$55,$38,$27,$5a
        fcb   $40,$77,$00
        fcb   $2b,$39,$7b,$78,$9a,$9e
        fcb   $bf,$0a,$66,$48,$26,$4a
        fcb   $60,$78,$00
Palett equ  *
        fdb   $fff
        fdb   $530
        fdb   $111

echo  &*-debut
        rmb   64
Free    equ   *
Cosin   rmb   256+4*5*4*2
nLoop   rmb   3
Tubes   rmb   156*2

        end   debut
