   ORG   $6300

safe SET 0

* MACRO to align operation correctly wrt "opBASIC"
_basic      MACRO NOXEPAND
(info)
tmp  SET  opBREAKPT+32*\0
   IFGT  *-tmp
      ERROR overflow
   ELSE
      RMB   tmp-*,$12  ; align znf fill with NOPs
   ENDC
            ENDM

excode      MACRO NOEXPAND
tmp  SET  opLOADH+32*(\0-34)
   IFGT  *-tmp
      ERROR overflow
   ELSE
      RMB   tmp-*,$12  ; align znf fill with NOPs
   ENDC
   ENDM

   SETDP */256

* loads a continuated immediate value
* B=xxxxxxx0 (value*2)
opIM_nxt
   LSR   ,U          ; rotate TOS 7 bits left
   LDA   1,U
   RORA
   STA   ,U          ; byte 0 is byte 1 rotated right once
   LDA   2,U
   RORA
   STA   1,U         ; byte 1 is byte 2 rotated right once
   LDA   3,U
   RORA              ; byte 2 is byte 3 rotated right once
   RORB              ; push bit back to value
   STD   2,U         ; write lower word
   LDB   [fetch+1]   ; is next opcode an opIm?
   BMI   incPC       ; yes => just increment PC
   LDA   #$81        ; no => disable hook ($81=CMPA)
   STA   <opIM       ; (write CMPA as the first instructon of opIM)
   BRA   incPC       ; next instruction (B already fetched)


* loads a 7 bit immediate value
* B=xxxxxxx0 (value*2)
opIM
   BRN   opIM_nxt    ; hook to go to continued version (dynamic code)
   ASRB              ; left align signed value
   SEX               ; extends sign to A ($00 or $FF)
   PSHU  D           ; push lower word
   STA   ,-U         ; push high byte (sign)
   STA   ,-U         ; push high byte (sign)
   LDB   [fetch+1]   ; is next _basic an immediate value?
   BPL   incPC       ; no => no change in hook. just update the PC reg.
   LDA   #$20        ; yes => mak hook go to opIM_nxt ($20=BRA)
   STA   <opIM       ; (write a BRA as the first instructio, of opIM)
   BRA   incPC       ; next instruction (B already fetched)

* safe version of getAddr for long values
getAddrL
   IF safe
   LDB   #%11111100
   ANDB  3,U         ; just clear the 2 lower bits of TOS
   STB   3,U
   ENDC

* make X points to the address in TOS (stack unmodified)
getAddr
   LDD   2,U         ; load lower part of the address
   ANDA  #$30        ; clear high bits
   ADDA  #$a0        ; make it point to $A000...$DFFF
   TFR   D,X         ; X opdated
   LDD   1,U         ; load 16kb page section of address

* updates page when neeeded
* D=high bytes of the 24bits address
updatePage
   ANDB  #$c0        ; just keep the 2 top bits
   CMPD  #page       ; compare wit current page index
page equ *-2         ; page index (dynamic code)
   BEQ   donePage    ; same => just return
   STD   <page       ; different => update page index
   LSLB              ; compute the proper memory bank
   ROLA
   LSLB
   ROLA '
* map proper bank onto $A000...$DFFF space
* A=bank number
chgBank
   STA   $e7e6       ; need to check, might use PIA instead
donePage
   RTS               ; done

* restore the page back to the instruction page
updatePC
   LDD  #PC_HI       ; load instruction page
PC_HI SET *-2        ; instruction page (dynamic code)
   BSR  updatePage   ; update page if needed

* fetches and execute an instruction
fetch
   LDB   >$a000      ; load instruction byte
PC_LO equ *-2

* increments PC register
incPC
   INC   <PC_LO+1    ; update lower byte of the PC
   BNE   decode      ; no overflow => just decode instruction
   INC   <PC_LO      ; update upper part of the PC
   LDA   <PC_LO
   CMPA  #$E0        ; crossing $E000 ?
   BNE   decode      ; no => just decode the instruction
   LDA   #$A0        ; yes => next instruction page
   STA   <PC_LO      ; make PC point to $A000
   PSHS  B           ; saves current _basic
   LDD   <PC_HI      ; advance instruction page
   ADDD  #$40        ; by 16kb (a memory bank)
   STD   <PC_HI      ; update instruction page
   PULS  B
   BSR   updatePage  ; update bank

* deccdes the current _basic (in B)
decode
   LSLB              ; double the _basic
   BCS   opIM        ; _basic=1xxxxxxx ? yes => immediate value
   LSLB              ; ELSE make B = xxxxxx00
   BCS   opLDSTsp    ; _basic=01xxxxxx ? yes => LDsp_x or STsp_x
   BMI   opEMULATE_x ; _basic=001xxxxx ? yes => emulate_x
   BITB  #%01000000  ; _basic=0001xxxx ? yes => addsp_x
   BNE   opADDSP_x   ; at this point _basic=0000xxxx
   LSLB
   LSLB
   LSLB
   LDX   #opBREAKPT
   ABX
   ABX
   JMP   ,X          ; jump tp BRAKPT+_basic*32

opEMULATE_x
   LDX   #opLOADH-34*32
   LSLB              ; lookup table here to
   LSLB              ; _basic*16
   ABX               ; use ABX because B is unsigned byte
   ABX               ; X=lo1dH-34*32+_basic*32
   JMP   ,X

* COMmon part between opLD and opST depending on N flag
opLDSTsp
   BPL   opSTORESP_x

***************************************
* Load on stack the value at stack[x]
* B=-xxxxx00 (4*x)
***************************************
opLOADSP_x
   ANDB  %01111100   ; clear bit 7 of 4*x
   LEAX  B,U         ; X points to source
   LDD   ,X          ; load high word
   LDX   2,X         ; load low word
   PSHU  D,X         ; push 32 bits
   BRA   fetch       ; next instruction

* Write top of stack at stack[x]
* B=0xxxxx00 (4*x)
opSTORESP_x
   LEAX  B,U         ; X point to dest (bit7 already 0)
   LDD   ,U          ; load high word
   STD   ,X          ; store high word
   LDD   2,U         ; load low word
   STD   2,X         ; store low word
   LEAU  4,U         ; adjust the stack
   BRA   fetch       ; next instructio,

* Adds to TOS the value at stack[x]
* B=0--xxxx00 (4*x)
opADDSP_x
   ANDB  %00111100   ; make 4*x postitive
   LEAX  B,U         ; X point to source
   LDD   2,X         ; load low word of source
   ADDD  2,U         ; add low word of TOS
   STD   2,U         ; store result to TOS (lower word)
   LDD   ,X          ; load high word of source
   ADCB  1,U         ; add with carry the TOS (high word)
   ADCA  ,U          ; second byte
   STD   ,U          ; store result to TOS (high word)
   BRA   fetch       ; next instruction

opBREAKPT
   BRA   opBREAKPT   ; do nothing (breakpoint)

* Pushes stack address
   _basic %0010
opPUSHSP
   LDD   #0          ; stack address is $0000:9xxx
   LEAX  ,U          ; this should be mapped to
   PSHU  D,X         ; bank 0, $Dxxx
   JMP   <fetch

   _basic %0100
opPOPPC
   LDD   2,U         ; lower word of PC
   ANDA  #$03        ; map 16k address to $A000...$DFFF
   ADDA  #$A0
   STD   <fetch+1    ; update pc reg
   LDD   1,U         ; load page field
   STD   <PC_HI      ; upodate high word of PC
   LEAU  4,U         ; fixup stack
   JMP   <updatePC+3 ; update page etc

   _basic %0101
opADD
   LEAU  4,U         ; add TOS with NOS
   LDD   2,U         ; load lower word of NOS
   ADDD  -2,U        ; adds lower word of TOS
   STD   2,U         ; store result to NOS lower part
   LDD   ,U          ; load NOS top word
   ADCB  -3,U        ; adds TOS top word
   ADCA  -4,U        ; with carry
   STD   ,U          ; store uppdr world result
   JMP   <fetch      ; next intruction

   _basic %0110
opAND
   LDD   ,U          ; bitwise "and" of TOS with NOS
   LEAU  4,U
   ANDA  ,U
   ANDB  2,U
   STD   ,U
   LDD   -2,U
   ANDA  2,U
   ANDB  3,U
   STD   2,U
   JMP   <fetch

   _basic %0111
opOR
   LDD   ,U          ; bitwise "or" of TOS with NOS
   LEAU  4,U
   ORA   ,U
   ORB   2,U
   STD   ,U
   LDD   -2,U
   ORA   2,U
   ORB   3,U
   STD   2,U
   JMP   <fetch

   _basic %1000
opLOAD
   JSR   <getAddrL   ; convert adress
   LDD   ,X          ; load high word
   STD   ,U          ; store in TOS
   LDD   2,X         ; load lower word
   STD   2,U         ; store in TOS
   JMP   <updatePC   ; resync PC page and execute next instruction

   _basic %1001
opNOT
   COM   ,U          ; bitwise complement of TOS
   COM   1,U
   COM   2,U
   COM   3,U
   JMP   <fetch

flip2
   LSLA              ; helper to flip A and B bits
   RORB
   ROLA
   RORB
   ROLA
   RORB
   ROLA
   RORB
   ROLA
   RORB
   ROLA
   RORB
   ROLA
   RORB
   ROLA
   RORB
   ADCA  #0
   RTS

   _basic %1010
opFLIP
   LDA   ,U          ; flips the bits of tje TOS
   LDB   3,U
   BSR   flip2
   STA   ,U
   STB   3,U
   LDD   1,U
   BSR   flip2
   STD   1,U
   JMP   <fetch

   _basic %1011
opNOP
   JMP   <fetch      ; do nothing

   _basic %1100
opSTORE
   JSR   <getAddrL   ; convert TOS to address & set page
   LDD   4,U
   STD   ,X
   LDD   6,U
   STD   2,X
   LEAU  8,U
   JMP   <updatePC   ; page has been modified, ensure PC-page is back

   _basic %1101
opPOPSP
   PULU  D,X         ; change SP with the value of TOS
   LEAU  ,X          ; presumably we just keep the lower part of the address
   JMP   <fetch


   excode 34
opLOADH
   JSR   <getAddr    ; loads 16 bits
   LEAU  4,U
   LDX   ,X
   BMI   opLoadH2
   LDD   #0
opLoadH1
   PSHU  D,X
   JMP   <updatePC
opLoadH2
   LDD   #-1
   PSHU  D,X
   JMP   <updatePC

   excode 35
opSTOREH
   JSR   <getAddr    ; stores 16 bitx
   LEAU  8,U
   LDD   -2,U
   STD   ,X
   JMP   <updatePC

   excode 36
opLESSTHAN
   LDD   ,U
   LEAU  4,U
   SUBD  ,U
   BLT   TOS_1
   BGT   TOS_0
   LDD   -2,U
   SUBD  2,U
   BMI   TOS_1

* writes 0 on top of stack
TOS_0
   LDD   #0
   STD   ,U
   STD   2,U
   JMP   <fetch

   excode 37
opLESSTHANOREQUAL
   LDD   ,U
   LEAU  4,U
   SUBD  ,U
   BGT   TOS_0
   BLT   TOS_1
   LDD   -2,U
   SUBD  2,U
   BPL   TOS_0

* write 1 on top of stack
TOS_1
   LDD   #0
   STD   ,U
   INCB
   STD   2,U
   JMP   <fetch
