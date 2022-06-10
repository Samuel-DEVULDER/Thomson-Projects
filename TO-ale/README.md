# Idée

La diskette parait vide, et pourtant elle bouge. En effet tout tient dans le bootblock de 256 octets.

# Histoire

Il m'arrive une bien curieuse histoire. Alors voilà: Ca fait longtemps que je n'avais pas touché à mon TO9 et de la poussière commençait sérieusement à s'accumuler dessus. J'avais honte de le laisser dans un tel état; alors récemment, je me suis décidé à l'allumer pour voir s'il fonctionnait encore. Et là, surprise, au boot du basic je suis tombé sur ceci:
![](images/TOale.gif)
Cela se apparait que ce soit avec le basic 128 ou le basic 1.0, avec les menus 3/4 ou D/E. Impossible d'y échapper.

J'étais bien en peine avec mon TO... un bug, une sorte d'araignée en fait, en avait pris possession et dessinait des toiles partout à l'écran. Super, mais comment je reprends la main? J'appuie sur le bouton RESET. Je retourne au menu, mais lorsque je reviens au basic, alors ca repart pour un tour! Zut alors.. Bon je tente le tout pour le tout et lorsque le dessin est fini, je reste appuyé sur ctrl-c et là... magie... le basic reprend la main comme si de rien était. Ouf, la machine peut donc encore être utilisée.

Je me suis dit que puisque ce truc réagit au ctrl-c, c'était peut-être un programme basic, mais la diskette présente dans le lecteur ne contient aucun fichier. Mystère! Je contacte une connaissance qui bosse dans l'entomologie et je lui montre les photos d'écran. Elle me dit reconnaitre le type de toile laissé par une araignée d'écran à 8pattes^w bits. D'habitude les toiles sont assez rectiligne,
![figure de Moivre](https://i0.wp.com/amstrad.eu/uploads/fichiers/articles/amstradcpc/programmation/listings/moivres/moivre6.jpg?resize=341%2C333)
mais celle-ci fait de bien curieux louvoiements. Cette araignée a un certain sens de la fantaisie, ce qui explique son nom savant: A.L.E (Araignée Loufoque d'Ecran ;) ). En plaçant la diskette dans un MO6, on constate que rien ne se passe. Cette ALE est donc spécifique à la gamme TO, aussi nous avons baptisée cette sous-espèce une TOALE (se prononce toile, un bon moyen mnémotechnique :langue: ).

Normalement cette espèce vit non loin du secteur de boot, mais il me dit avoir dans son vivarium une espèce cousine résidant sur K7. Effectivement son comportement est très similaire à celle qui hante mon TO9:
![](images/penweb.gif)
L'avantage c'est qu'elle est semi-apprivoisée et que son code génétique est disponible. Les première constatation sur cette cousine indique qu'elle est minuscule (moins de 255 octets), et s'est adaptée à toutes les machines de la gamme TO. Elle n'a pas de grande exigences mémoire, et se contente de se nourrir de 2 ou 3 routines du moniteur.

Pour les curieux voici le code génétique de la bestiole apprivoisée
```
****************************************
* debut  : $9000
* fin    : $90FB
* taille : 252
****************************************

        org        $9000

init    fcb        $34,$7E,$C6,$90,$1F
        fcb        $9B,$BE,$E7,$C6,$9D
        fcb        $C6,$00,$00,$30,$1F
        fcb        $26,$F8,$0F,$64,$9E
        fcb        $7E,$9F,$8E,$10,$9E
        fcb        $86,$10,$9F,$97,$9D
        fcb        $C6,$08,$0C,$CE,$91
        fcb        $4C,$36,$30,$4A,$26
        fcb        $FB,$DF,$AE,$DF,$9D
        fcb        $9D,$C6,$32,$C8,$9D
        fcb        $52,$9D,$61,$4A,$26
        fcb        $FB,$5F,$DD,$7C,$DD
        fcb        $84,$86,$14,$97,$64
        fcb        $9D,$61,$4A,$26,$FB
        fcb        $5A,$26,$F4,$AD,$46
        fcb        $C1,$03,$26,$C2,$35
        fcb        $7E,$3F,$CE,$E8,$00
        fcb        $AD,$C4,$C6,$0C,$AD
        fcb        $43,$C6,$58,$F7,$60
        fcb        $19,$39,$34,$46,$86
        fcb        $7B,$4A,$2C,$10,$9D
        fcb        $C6,$F8,$10,$97,$7D
        fcb        $9D,$C6,$F8,$10,$97
        fcb        $85,$9D,$C6,$0A,$14
        fcb        $97,$64,$9D,$DA,$00
        fcb        $00,$00,$A0,$01,$3F
        fcb        $9D,$DA,$00,$00,$00
        fcb        $64,$00,$C7,$DC,$7E
        fcb        $9D,$B6,$00,$00,$FD
        fcb        $60,$3D,$DC,$86,$9D
        fcb        $B6,$00,$00,$FD,$60
        fcb        $3F,$CE,$00,$00,$37
        fcb        $30,$ED,$5E,$DC,$8E
        fcb        $ED,$5C,$11,$83,$91
        fcb        $4C,$26,$03,$CE,$00
        fcb        $00,$DF,$9D,$35,$46
        fcb        $6E,$4C,$35,$40,$E3
        fcb        $C4,$E3,$C4,$E3,$C4
        fcb        $47,$56,$47,$56,$ED
        fcb        $C4,$6E,$42,$35,$40
        fcb        $CC,$03,$F9,$3D,$C3
        fcb        $00,$00,$97,$CE,$D7
        fcb        $C9,$A6,$41,$3D,$AB
        fcb        $C4,$6E,$42,$35,$40
        fcb        $37,$16,$47,$47,$47
        fcb        $30,$86,$A6,$5C,$AC
        fcb        $C4,$23,$09,$AE,$5E
        fcb        $58,$28,$02,$E6,$5D
        fcb        $50,$4F,$36,$16,$EB
        fcb        $C4,$29,$02,$E7,$C4
        fcb        $6E,$46

        end        init
```
Nous essayons en ce moment de faire un séquençage ASM pour retrouver le code correspondant, mais sa structure interne la rend opaque aux méthodes d'analyse standard (impossible de suivre les JSR jusqu'au bout). Dès que nous auront son code source, nous publierons ici plus d'infos. En attendant, vous pouvez retaper le code dans n'importe quel assembleur ou même en basic. Pour ceux qui n'ont pas le temps de faire cela, il existe une version archivée sur le site de [Puls](http://www.pulsdemos.com/toale.html).

# Analyse

Comme promis voici le séquençage ASM de la bestiole:
```
/*--------------------------------------------------------------*
 * Compilé avec C6809 v0.83                                     *
 *--------------------------------------------------------------*
 * Fichier source      : TO-ale.ass
 * Fichier destination : TO-ale.BIN
 * Contenu :
 *     Main     0:TO-ale.ASM   6666
 *--------------------------------------------------------------*/

Macro Pass
Pass1
Pass2
      2                           ***************************************
      3                           * Une araignee loufoque d'ecran (ALE)
      4                           * du genre TO 8pattes^w bits.
      5                           * ==> TO-ALE <== (se prononce toile)
      6                           *
      7                           * Elle se balade a l'ecran avec un fil
      8                           * a la patte et laisse trainer de
      9                           * jolies toiles un peu partout.
     10                           *
     11                           * Sortie par ctrl-c.
     12                           *
     13                           * Compilation avec:
     14                           * - c6809 (-c -am -oOP)
     15                           *   http://www.pulsdemos.com/c6809.html
     16                           * - macro assembler 3.6 (A/IM)
     17                           *   http://tinyurl.com/btqz57a
     18                           *
     19                           * Samuel Devulder Mars 2012
     20                           ***************************************
     22        9000                      org    $9000
     23
     24                  603D     PLOTX  equ    $603D
     25                  603F     PLOTY  equ    $603F
     26                  6019     STATUS equ    $6019
     27
     28                           * profondeur maxi historique
     29                  0014     HISTORY       equ    20
     30
     31                           ***************************************
     32                           * boucle:
     33                           *       REPEAT
     34                           *       ....
     35                           *       WHILE   condition
     36                           ***************************************
     37                           REPEAT macro
     38                           loop   set    *
     39                                  endm
     40                           WHILE  macro
     41                                  b\0    loop
     42                                  endm
     43                           
     44                           ***************************************
     45                           * Filtrage:
     46                           *       FILTER  <lbl>
     47                           *
     48                           * Defini:
     49                           *      F<lbl> = valeur filtree sur 2
     50                           *                octets
     51                           * Calcule:
     52                           *       F<lbl> = (3*F<lbl> + D)/4
     53                           ***************************************
     54                           FILTR  macro
     55                                  jsr    <filtr
     56                           F\0    fdb    0
     57                                  endm
     58
     59                           ***************************************
     60                           * Mouvement physique:
     61                           *       PHYS  symbol,val,max
     62                           *
     63                           * Defini:
     64                           *      P<symbol> = position (2 octet)
     65                           *      V<symbol> = vitesse (1 octet)
     66                           *      A<symbol> = accel. (1 octet)
     67                           *
     68                           * Calcule:
     69                           * Mise a jour la position en fonction
     70                           * de la vitesse et de l'acceleration.
     71                           * Si la position depasse max, alors
     72                           * l'acceleration est stopee et la vit.
     73                           * est inversee (et doublee).
     74                           *
     75                           * La vitesse et l'acceleration sont
     76                           * definies au format signe 5.3 avec
     77                           * saturation pour la vitesse.
     78                           ***************************************
     79                           PHYS   macro
     80                                  jsr    <phys
     81                           V\0    fcb    0
     82                           A\0    fcb    0
     83                           P\0    fdb    \1,\2
     84                                  endm
     85                           
     86                           ***************************************
     87                           * Generateur aleatoire:
     88                           *
     89                           *      RND    offset,max
     90                           *
     91                           * Calcule:
     92                           * A = nb aleatoire entre offset et
     93                           *     offset+max-1.
     94                           ***************************************
     95                           RND    macro
     96                                  jsr    <rnd
     97                                  fcb    \0,\1
     98                                  endm
     99
    100                           ***************************************
    101                           * Point d'entree
    102                           ***************************************
    103                  90              setdp  *<-8
    104  5+9   9000 34   7E       ini    pshs   d,x,y,u,dp
    105  2     9002 C6   90              ldb    #*<-8
    106  6     9004 1F   9B              tfr    b,dp
    107                           ***************************************
    108                           * initialisation du generateur rnd
    109                           ***************************************
    110  6     9006 BE   E7C6            ldx    $E7C6  ! timer
                                  ****   REPEAT
     38                  9009     loop   set    *
                                  ****   RND   0,0
     96  7     9009 9D   C6              jsr    <rnd
     97        900B 00 00                fcb    0,0
    113  4+1   900D 30   1F              leax   -1,x
                                  ****   WHILE  ne
     41  3     900F 26   F8              bne    loop
    115                           ***************************************
    116                           * nouveau dessin
    117                           ***************************************
    118  6     9011 0F   64       start  clr    <PV    ! reset traj
    119  5     9013 9E   7E              ldx    <PX    ! init FX,FY
    120  5     9015 9F   8E              stx    <FX
    121  6     9017 109E 86              ldy    <PY
    122  6     901A 109F 97              sty    <FY
                                  ****   RND    8,HISTORY-8
     96  7     901D 9D   C6              jsr    <rnd
     97        901F 08 0C                fcb    8,HISTORY-8
    124  3     9021 CE   914C            ldu    #HFIN  ! init histo.
                                  ****   REPEAT
     38                  9024     loop   set    *
    126  5+4   9024 36   30              pshu   x,y
    127  2     9026 4A                   deca
                                  ****   WHILE  ne
     41  3     9027 26   FB              bne    loop
    129  5     9029 DF   AE              stu    <HDEB
    130  5     902B DF   9D              stu    <HPTR
    131                           ***************************************
    132                           * affichage dessin
    133                           ***************************************
                                  ****   RND    50,200
     96  7     902D 9D   C6              jsr    <rnd
     97        902F 32 C8                fcb    50,200
    135  7     9031 9D   52              jsr    <cls   ! eff. ecran
                                  ****   REPEAT
     38                  9033     loop   set    *
    137  7     9033 9D   61              jsr    <draw
    138  2     9035 4A                   deca
                                  ****   WHILE  ne
     41  3     9036 26   FB              bne    loop
    140                           ***************************************
    141                           * fin trace combine a l'attente
    142                           ***************************************
    143  2     9038 5F                   clrb          ! fin trace
    144  5     9039 DD   7C              std    <VX    ! zero vitesse
    145  5     903B DD   84              std    <VY    ! zero accel
    146  2     903D 86   14       wait   lda    #HISTORY
    147  4     903F 97   64              sta    <PV
                                  ****   REPEAT
     38                  9041     loop   set    *
    149  7     9041 9D   61              jsr    <draw
    150  2     9043 4A                   deca
                                  ****   WHILE  ne
     41  3     9044 26   FB              bne    loop
    152  2     9046 5A                   decb
    153  3     9047 26   F4              bne    wait
    154                           ***************************************
    155                           * lecture clavier, detection BREAK.
    156                           ***************************************
    157  7+1   9049 AD   46              jsr    6,u    ! GETC
    158  2     904B C1   03              cmpb   #3     ! ctrl-c
    159  3     904D 26   C2              bne    start
    160  5+9   904F 35   7E              puls   d,x,y,u,dp
    161                           ***************************************
    162                           * SWI est transparent pour le basic.
    163                           * On passe donc sur le cls si on est
    164                           * lance depuis le basic. Sinon sous
    165                           * Assembler on s'arrete la.
    166                           ***************************************
    167  19    9051 3F                   swi           ! rts
    168                           ***************************************
    169                           * Effacement ecran + forme seule +
    170                           * curseur eteint.
    171                           *
    172                           * Retourne U=$E800 B=ecrase
    173                           ***************************************
    174  3     9052 CE   E800     cls    ldu    #$E800
    175  7+0   9055 AD   C4              jsr    ,u     ! reset
    176  2     9057 C6   0C              ldb    #12
    177  7+1   9059 AD   43              jsr    3,u    ! PUTC
    178  2     905B C6   58              ldb    #88
    179  5     905D F7   6019            stb    STATUS ! forme seule
    180  5     9060 39                   rts           ! curs eteint
    181                           ***************************************
    182                           * Affiche une ligne:
    183                           * - bouge PX, PY en fonction de la
    184                           *   vitesse et l'acceleration.
    185                           * - effectue un filtre passe bas
    186                           *   (FX, FY)
    187                           * - depile dans (X,Y) la 1ere coord de
    188                           *   l'historique et empile la nouvelle.
    189                           * - tracage de ligne (FX,FY)-(X,Y)
    190                           * - si fin de traj determine une
    191                           *   nouvelle acceleration et duree
    192                           *
    193                           * En entree: U=$E800.
    194                           * En sortie: X et Y coord extremite
    195                           *            ligne tracee.
    196                           ***************************************
    197  5+4   9061 34   46       draw   pshs   d,u
    198  2     9063 86   7B              lda    #123
    199                  9064     PV     set    *-1    ! fin traj ?
    200  2     9065 4A                   deca
    201  3     9066 2C   10              bge    draw1  ! non => phys
                                  ****   RND    -8,16
     96  7     9068 9D   C6              jsr    <rnd
     97        906A F8 10                fcb    -8,16
    203  4     906C 97   7D              sta    <AX    ! acceleration
                                  ****   RND    -8,16
     96  7     906E 9D   C6              jsr    <rnd
     97        9070 F8 10                fcb    -8,16
    205  4     9072 97   85              sta    <AY
                                  ****   RND    10,20
     96  7     9074 9D   C6              jsr    <rnd
     97        9076 0A 14                fcb    10,20
    207  4     9078 97   64       draw1  sta    <PV
                                  ****   PHYS   X,160,319
     80  7     907A 9D   DA              jsr    <phys
     81        907C 00            VX     fcb    0
     82        907D 00            AX     fcb    0
     83        907E 00A0 013F     PX     fdb    160,319
                                  ****   PHYS   X,100,199
     80  7     9082 9D   DA              jsr    <phys
     81        9084 00            VY     fcb    0
     82        9085 00            AY     fcb    0
     83        9086 0064 00C7     PY     fdb    100,199
    210  5     908A DC   7E              ldd    <PX    ! filtre passe
                                  ****   FILTR  X      ! bas
     55  7     908C 9D   B6              jsr    <filtr
     56        908E 0000          FX     fdb    0
    212  6     9090 FD   603D            std    PLOTX  ! lisser la
    213  5     9093 DC   86              ldd    <PY    ! trajectoire
                                  ****   FILTR  Y
     55  7     9095 9D   B6              jsr    <filtr
     56        9097 0000          FY     fdb    0
    215  6     9099 FD   603F            std    PLOTY
    216  3     909C CE   0000            ldu    #0     ! depilage
    217                  909D     HPTR   set    *-2    ! old coord
    218  5+4   909F 37   30              pulu   x,y    ! empilage
    219  5+1   90A1 ED   5E              std    -2,u   ! new coord
    220  5     90A3 DC   8E              ldd    <FX
    221  5+1   90A5 ED   5C              std    -4,u
    222  5     90A7 1183 914C            cmpu   #HFIN  ! buf. circul.
    223  3     90AB 26   03              bne    main1
    224  3     90AD CE   0000            ldu    #0
    225                  90AE     HDEB   set    *-2
    226  5     90B0 DF   9D       main1  stu    <HPTR
    227  5+4   90B2 35   46              puls   d,u
    228  3+1   90B4 6E   4C              jmp    12,u   ! DRAW
    229                           ***************************************
    230                           * filtrage: FX = (D + 3*FX)/4
    231                           * entree: D contient PX, S pointe sur
    232                           *         l'adresse de FX.
    233                           * sortie: U ecrase
    234                           ***************************************
    235  5+2   90B6 35   40       filtr  puls   u
    236  6+0   90B8 E3   C4              addd   ,u     ! D+FX
    237  6+0   90BA E3   C4              addd   ,u     ! D+2*FX
    238  6+0   90BC E3   C4              addd   ,u     ! D+3*FX
    239  2     90BE 47                   asra
    240  2     90BF 56                   rorb
    241  2     90C0 47                   asra
    242  2     90C1 56                   rorb          ! D=(D+3*FX)/4
    243  5+0   90C2 ED   C4              std    ,u     ! FX=D
    244  3+1   90C4 6E   42              jmp    2,u    ! retour
    245                           ***************************************
    246                           * Genere un nombre pseudo aleatoire sur
    247                           * 8 bit. C'est une version modifiee
    248                           * du multiply with carry. La periode
    249                           * de la sequence est 31870. Compact
    250                           * et rapide, que demander de plus?
    251                           *
    252                           * en entree: S pointe sur (offset,max)
    253                           * en sortie: A=un nombre random entre
    254                           *              offset et offset+max-1
    255                           *            B, U ecrase
    256                           ***************************************
    257  5+2   90C6 35   40       rnd    puls   u
    258  3     90C8 CC   03F9            ldd    #3*256+249
    259  11    90CB 3D                   mul
    260  4     90CC C3   0000     rnd1   addd   #0
    261  4     90CF 97   CE              sta    <rnd1+2
    262  4     90D1 D7   C9              stb    <rnd+1+2
    263  4+1   90D3 A6   41              lda    1,u
    264  11    90D5 3D                   mul
    265  4+0   90D6 AB   C4              adda   ,u
    266  3+1   90D8 6E   42              jmp    2,u
    267                           ***************************************
    268                           * Mise a jour d'une position via la
    269                           * loi physique.
    270                           *
    271                           * entree : S pointe sur l'adresse de
    272                           *          fcb VIT,ACC
    273                           *          fdb POS,MAX
    274                           * sortie : POS, VIT mis a jour
    275                           *          U, X, D ecrase
    276                           ***************************************
    277  5+2   90DA 35   40       phys   puls   u
    278  5+4   90DC 37   16              pulu   d,x    ! A=vit B=acc
    279  2     90DE 47                   asra          ! X=pos
    280  2     90DF 47                   asra
    281  2     90E0 47                   asra
    282  4+1   90E1 30   86              leax   a,x    ! X=pos+vit/8
    283  4+1   90E3 A6   5C              lda    -4,u
    284  6+0   90E5 AC   C4              cmpx   ,u     ! X<0 ou X>MAX?
    285  3     90E7 23   09              bls    phys1
    286  5+1   90E9 AE   5E              ldx    -2,u   ! oui=>rebond
    287  2     90EB 58                   aslb          ! accel*=2
    288  3     90EC 28   02              bvc    phys0
    289  4+1   90EE E6   5D              ldb    -3,u
    290  2     90F0 50            phys0  negb          ! accel=-accel
    291  2     90F1 4F                   clra          ! vit=0
    292  5+4   90F2 36   16       phys1  pshu   d,x
    293  4+0   90F4 EB   C4              addb   ,u     ! vit=vit+acc
    294  3     90F6 29   02              bvs    phys2  ! satur?
    295  4+0   90F8 E7   C4              stb    ,u
    296  3+1   90FA 6E   46       phys2  jmp    6,u    ! retour
    297                           ***************************************
    298                           * historique
    299                           ***************************************
    300        90FC                      rmb    4*HISTORY
    301                  914C     HFIN   set    *
    302                  9000            end    ini
```

A la lecture de ce code, on comprend pourquoi le débuggeur ne peut suivre les JSR jusqu'au bout: le JSR est suivi de données qui sont lues par la sub-routine, et le flot de contrôle reprends quelques octets plus loin.

C'est une technique très interessante quand on doit passer des constantes à une sous-routine et que l'on a peu de place. Habituellement, on charge les données dans des registres juste avant l'appel. Ici, on fait juste un simple JSR qui est suivi par les données. Du coup lors de l'appel, le CPU n'empile pas l'adresse de retour, mais l'adresse des données. Dans la sous-routine, cette adresse est récupérée dans un registre (typiquement U), et les constantes sont alors disponibles directement en relatif par rapport à U. On peut ainsi avoir bien plus de données que de registres disponibles tout en s'épargnant le pré-chargement. Le code de la routine est d'ailleurs plus simple: on se se pré-occupe plus de sauvegarder les données qui auraient été passées par des registres, on va uniquement aller les chercher quand on en a besoin. Le code en est grandement simplifié. Enfin le retour de sous-routine ne se fait pas par un RTS standard (normal: le sommet de la pile contenait l'adresse des données et en plus il a été dépilé), mais par un simple JMP <taille-donnée>,U qui fait gagner 1 cycle par rapport au RTS. On est donc à la fois gagnant en taille et en vitesse.

C'est une technique assez rigolote à mettre en oeuvre, et elle fait vraiment gagner plusieurs dizaine d'octets sur le code de TOale. Sans elle le code machine déborderait de beaucoup la taille d'un bloc (255octets).

# Liens

* [logicielsmoto](http://www.logicielsmoto.com/phpBB/viewtopic.php?f=10&t=446)
* [pouet](https://www.pouet.net/prod.php?which=59046)
* [puls](http://www.pulsdemos.com/toale.html)
