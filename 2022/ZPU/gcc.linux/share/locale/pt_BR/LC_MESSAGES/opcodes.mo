��    W      �     �      �  [   �     �  9   �  (   3     \     i  	   y     �  	   �     �     �     �  (   �     	     -	     M	     h	     �	     �	     �	     �	     �	  ,   �	     
  :   6
  1   q
  9   �
  6   �
       "   .  )   Q     {  %   �  #   �  +   �  +     1   /  1   a  %   �  +   �  1   �  1     /   I     y     �     �     �  .   �  +   	     5     O  !   j  5   �  "   �  0   �          &     F  )   c     �     �  %   �  &   �          &  !   :     \  !   w  !   �  2   �  2   �  2   !  0   T  -   �  ;   �  	   �     �                     /     G     b      w     �     �  3  �  c   �     \  ?   z  +   �     �     �     	  %        >     L     b     t  7   �     �  %   �          ,  $   F  $   k     �     �     �  ,   �     �  ;     2   J  :   }  8   �     �  )     -   6     d  &   z  2   �  5   �  8   
  0   C  0   t  '   �  4   �  2     2   5  3   h     �     �     �  !   �  :     7   M     �     �  '   �  <   �  (   (  @   Q     �  !   �     �  (   �  .        A  )   \  1   �     �     �  '   �  #     *   7  *   b  5   �  5   �  5   �  3   /  5   c  A   �  
   �     �     �                 0   *   L   !   w   "   �      �      �      P   ;   J          >       ?   I           D   H   -      .   2          :   <   !           F   5   "            7   V           8          4            1      T   *   K       %                    Q                 L   U   )   &           ,      +   
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
PO-Revision-Date: 2002-07-24 04:00-0300
Last-Translator: Alexandre Folle de Menezes <afmenez@terra.com.br>
Language-Team: Brazilian Portuguese <ldp-br@bazar.conectiva.com.br>
MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Content-Transfer-Encoding: 8-bit
 
As op��es do desmontador espc�ficas para ARM a seguir n�o s�o suportadas para
uso com a op��o -M:
 # <erro de desmontador: %08x> # erro interno do desmontador, modificador (%c) n�o reconhecido # erro interno, modificador (%c) indefinido $<indefinido> %02x		*desconhecido* (desconhecido) *tipo de operandos desconhecidos: %d* *desconecida* <c�digo de fun��o %d> <precis�o ilegal> <erro interno do desmontador> <erro interno na tabela de c�digos de opera��o: %s %s>
 <registrador %d desconhecido> Endere�o 0x%x est� fora dos limites.
 Case %d errado (%s) em %s:%d
 Express�o imediata errada Registrador errado no p�s-incremento Registrador errado no pr�-incremento Nome de registrador errado N�o entendo %x 
 Hmmmm %x Refer�ncia limm ilegal na �ltima instru��o!
 Erro interno do desmontador Erro interno:  sparc-opcode.h errado: "%s", %#.8lx, %#.8lx
 Erro interno: sparc-opcode.h errado: "%s" == "%s"
 Erro interno: sparc-opcode.h errado: "%s", %#.8lx, %#.8lx
 Interno: C�digo n�o depurado (test-case faltando): %s:%d O r�tulo conflita com `Rx' O r�tulo conflita com nome de registrador O operando pequeno n�o era um n�mero imediato Erro %d desconhecido
 Op��o do desmontador desconhecida: %s
 Conjunto de nomes de registrador desconhecido: %s
 Campo %d n�o reconhecido durante constru��o de insn.
 Campo %d n�o reconhecido durante decodifica��o de insn.
 Campo %d n�o reconhecido ao obter operando int.
 Campo %d n�o reconhecido ao obter operando vma.
 Campo %d desconhecido durante an�lise.
 Campo %d n�o reconhecido durante impress�o de insn.
 Campo %d n�o reconhecido ao definir operando int.
 Campo %d n�o reconhecido ao definir operando vma.
 tentativa de setar bit y ao usar modificador + ou - instru��o `%.50s' errada instru��o `%.50s...' errada operando de desvio desalinhado desvio para um deslocamento �mpar valor do desvio fora da faixa e para um deslocamento �mpar valor do desvio fora da faixa e para deslocamento �mpar valor do desvio fora da faixa imposs�vel lidar com insert %d
 valor do deslocamento n�o est� alinhado valor do deslocamento est� fora da faixa e n�o est� alinhado valor do deslocamento est� fora da faixa ignorando os bits menos significatiovs no deslocamento do desvio m�scara de bits ilegal valor imediato est� fora da faixa o valor imediato deve ser par valor imediato fora da faixa e n�o � par registrador de �ndice na faixa de carregamento op��o condicional inv�lida registrador inv�lido para ajuste da pilha operando de registro inv�lido durante atualiza��o dica de salto desalinhada lixo no final do arquivo mnem�nico faltando na string de sintaxe deslocamento n�o � um m�ltiplo de 4 deslocamento n�o est� entre -2048 and 2047 deslocamento n�o est� entre -8192 and 8191 operando fora de faixa (%ld n�o est� entre %ld e %ld) operando fora de faixa (%ld n�o est� entre %ld e %lu) operando fora de faixa (%lu n�o est� entre %lu e %lu) operando fora de faixa (%lu n�o est� entre 0 e %lu) erro de sintaxe (esperado char `%c', encontrado `%c') erro de sintaxe (esperado char `%c', encontrado fim de instru��o) indefinido desconhecido desconhecido	0x%02x desconhecido	0x%04lx desconhecido	0x%04x restri��o `%c' desconhecida deslocamento de operando desconhecido: %x
 registrador pop desconhecido: %d
 forma de instru��o n�o reconhecida instru��o n�o reconhecida valor fora de faixa 