��    W      �     �      �  [   �     �  9   �  (   3     \     i  	   y     �  	   �     �     �     �  (   �     	     -	     M	     h	     �	     �	     �	     �	     �	  ,   �	     
  :   6
  1   q
  9   �
  6   �
       "   .  )   Q     {  %   �  #   �  +   �  +     1   /  1   a  %   �  +   �  1   �  1     /   I     y     �     �     �  .   �  +   	     5     O  !   j  5   �  "   �  0   �          &     F  )   c     �     �  %   �  &   �          &  !   :     \  !   w  !   �  2   �  2   �  2   !  0   T  -   �  ;   �  	   �     �                     /     G     b      w     �     �     �  \   �     "  3   =  %   q     �     �     �     �     �     �     �       ,   &     S  0   h  !   �     �      �     �          ,     >  -   G     u  :   �  1   �  9   �  <   9     v  $   �  )   �     �  "   �  #     0   9  -   j  /   �  ,   �     �  ,     2   @  /   s  B   �     �        1   %     W  K   t  L   �  0        >  /   T  O   �  +   �  8         9  (   J     s  :   �  +   �     �  #     &   5  !   \     ~      �     �     �     �  A     A   Y  A   �  9   �  1     @   I  
   �     �     �     �     �     �     �     �           0      C      P   ;   J          >       ?   I           D   H   -      .   2          :   <   !           F   5   "            7   V           8          4            1      T   *   K       %                    Q                 L   U   )   &           ,      +   
           S   3      C                      G       	                 B   /                  A          #   =   @       $          O      E       6   R       M           (              0   N   9   W       '                  
The following ARM specific disassembler options are supported for use with
the -M switch:
 # <dis error: %08x> # internal disassembler error, unrecognised modifier (%c) # internal error, undefined modifier(%c) $<undefined> %02x		*unknown* (unknown) *unknown operands type: %d* *unknown* <function code %d> <illegal precision> <internal disassembler error> <internal error in opcode table: %s %s>
 <unknown register %d> Address 0x%x is out of bounds.
 Bad case %d (%s) in %s:%d
 Bad immediate expression Bad register in postincrement Bad register in preincrement Bad register name Don't understand %x 
 Hmmmm %x Illegal limm reference in last instruction!
 Internal disassembler error Internal error:  bad sparc-opcode.h: "%s", %#.8lx, %#.8lx
 Internal error: bad sparc-opcode.h: "%s" == "%s"
 Internal error: bad sparc-opcode.h: "%s", %#.8lx, %#.8lx
 Internal: Non-debugged code (test-case missing): %s:%d Label conflicts with `Rx' Label conflicts with register name Small operand was not an immediate number Unknown error %d
 Unrecognised disassembler option: %s
 Unrecognised register name set: %s
 Unrecognized field %d while building insn.
 Unrecognized field %d while decoding insn.
 Unrecognized field %d while getting int operand.
 Unrecognized field %d while getting vma operand.
 Unrecognized field %d while parsing.
 Unrecognized field %d while printing insn.
 Unrecognized field %d while setting int operand.
 Unrecognized field %d while setting vma operand.
 attempt to set y bit when using + or - modifier bad instruction `%.50s' bad instruction `%.50s...' branch operand unaligned branch to odd offset branch value not in range and to an odd offset branch value not in range and to odd offset branch value out of range can't cope with insert %d
 displacement value is not aligned displacement value is not in range and is not aligned displacement value is out of range ignoring least significant bits in branch offset illegal bitmask immediate value is out of range immediate value must be even immediate value not in range and not even index register in load range invalid conditional option invalid register for stack adjustment invalid register operand when updating jump hint unaligned junk at end of line missing mnemonic in syntax string offset not a multiple of 4 offset not between -2048 and 2047 offset not between -8192 and 8191 operand out of range (%ld not between %ld and %ld) operand out of range (%ld not between %ld and %lu) operand out of range (%lu not between %lu and %lu) operand out of range (%lu not between 0 and %lu) syntax error (expected char `%c', found `%c') syntax error (expected char `%c', found end of instruction) undefined unknown unknown	0x%02x unknown	0x%04lx unknown	0x%04x unknown constraint `%c' unknown operand shift: %x
 unknown pop reg: %d
 unrecognized form of instruction unrecognized instruction value out of range Project-Id-Version: opcodes 2.12.91
PO-Revision-Date: 2002-09-07 19:35+0200
Last-Translator: Keld Simonsen <keld@dkuug.dk>
Language-Team: Danish <dansk@klid.dk>
MIME-Version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-Transfer-Encoding: 8bit
 
F�lgende ARM-specifikke disassembleralternativ underst�ttes for brug
sammen med flaget -M:
 # <disassemblerfejl: %08x> # intern disassembler-fejl, ukendt modifikator (%c) # intern fejl, ukendt modifikator(%c) $<udefineret> %02x		*ukendt* (ukendt) *ukendt operandstype: %d* *ukendt* <funktionskode %d> <ugyldig pr�cision> <intern fejl i disassembleren> <intern fejl i instruktionstabellen: %s %s>
 <ukendt register %d> Adressen 0x%x ligger uden for tilladte gr�nser.
 Fejlagtig 'case' %d (%s) i %s:%d
 Forkert umiddelbart udtryk Forkert register i postinkrement Forkert register i pr�inkrement Forkert registernavn Forst�r ikke %x 
 Hmmmm %x Ugyldig limm-reference i sidste instruktion!
 Intern fejl i disassembleren Intern fejl:  d�rlig sparc-opcode.h: "%s", %#.8lx, %#.8lx
 Intern fejl: d�rlig sparc-opcode.h: "%s" == "%s"
 Intern fejl: d�rlig sparc-opcode.h: "%s", %#.8lx, %#.8lx
 Internt: ikke-fejltestet kode (test-tilf�lde mangler): %s:%d Etikette konflikter med 'Rx' Etikette konflikter med registernavn Lille operand var ikke et umiddelbart tal Ukendt fejl %d
 Ukendt disassembleralternativ: %s
 Ukendt registernavn er angivet: %s
 Ukendt felt %d ved konstruktion af instruktion.
 Ukendt felt %d ved afkodning af instruktion.
 Ukendt felt %d ved hentning af heltalsoperand.
 Ukendt felt %d ved hentning af vma-operand.
 Ukendt felt %d ved tolkning.
 Ukendt felt %d ved udskrift af instruktion.
 Ukendt felt %d ved indstilling af heltalsoperand.
 Ukendt felt %d ved indstilling af vma-operand.
 fors�g p� at s�tte y-bitten n�r modifikatoren + eller - blev brugt fejlagtig instruktion "%.50s" fejlagtig instruktion "%.50s..." operanden for betinget hop ligger p� sk�v adresse betinget hop til ulige afs�t v�rdien for betinget hop er ikke indenfor intervallet og til et ulige afs�t v�rdien for betinget hop er ikke inden for intervallet og til et ulige afs�t v�rdien for betinget hop er uden for intervallet kan ikke inds�tte %d
 forskydningsv�rdien ligger ikke p� lige adresse forskydningsv�rdien er ikke indenfor intervallet og ligger ikke p� lige adresse forskydningsv�rdien er uden for intervallet ignorerer mindste betydende bit i afs�t for betinget hop ugyldig bitmaske umiddelbar v�rdi er uden for intervallet umiddelbar v�rdi skal v�re lige umiddelbar v�rdi er ikke indenfor intervallet og ikke lige indeksregistret er i indl�sningsintervallet ugyldigt betinget flag ugyldigt register for stakjustering ugyldig registeroperand ved opdatering hopper�det ligger p� sk�v adresse snavs ved slutning p� linjen Mangler mnemonic i syntaksstreng afs�t ikke et produkt af 4 afs�t ikke mellem -2048 og 2047 afs�t ikke mellem -8192 og 8191 operanden er uden for intervallet (%ld er ikke mellem %ld og %ld) operanden er uden for intervallet (%ld er ikke mellem %ld og %lu) operanden er uden for intervallet (%lu er ikke mellem %lu og %lu) operanden uden for intervallet (%lu ikke mellem 0 og %lu) syntaksfejl (tegnet "%c" forventedes, fandt "%c") syntaksfejl (tegnet "%c" forventedes, fandt slut p� instruktion) udefineret ukendt ukendt	0x%02x ukendt	0x%04lx ukendt	0x%04x ukendt begr�nsning "%c" ukendt operandskiftning: %x
 ukendt pop-register: %d
 ukendt form af instruktion ukendt instruktion v�rdien er uden for intervallet 