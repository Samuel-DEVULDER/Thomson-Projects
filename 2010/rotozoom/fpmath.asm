(main)xx.asm
****************************************
* FPMATH.ASM
*
* Routines arithmetiques en fixed point
* 8.8. Elles sont definies comme des
*	macros representant des pseudo
* instructions supplementaires.
*
* Les arguments sont passes via la pile
* U. Cependant le sommet de la pile est
* le registre D lui-meme permettant un
* acces tres rapide au sommet contenant
* le resultat des routines.
*
* Dans la description des routines, la
* pile est la partie gauche. 'n'
* represente un nombre en point fixe,
* 'd' un entier et '_' le reste de la
* pile.
*
* Note: Pour des raisons de vitesse, on
* ne se preoccupe pas de l'arrondi, des
* debordements, de positionner les flags
* de CC (sauf fpcmp/fptst) et le code
* s'auto-modifie.
*
* (c) Samuel DEVULDER, 2010
****************************************

* Reglette d'alignement
*      ^      ^		^
* lbl  opcode arg     comment
*      v      v		v

****************************************
* n,_ --> n,n,_
****************************************
fpdup  	macro
	pshu	d
	endm
****************************************
* n,_ --> _
****************************************
fpdrop	macro
	pulu	d
	endm
****************************************
* _ --> n,_
****************************************
fppush	macro
	pshu	d
	ldd	\0
	endm
****************************************
* n,m,_ --> m,n,_
****************************************
fpswap	macro
	pshs	x
	ldx	,u
	pshs	x
	std	,u
	puls	d,x
	endm
****************************************
* m,n,_ --> n,m,n,_
****************************************
fpover	macro
	pshu	d
	ldd	2,u
	endm
****************************************
* n,m,_ --> n+m,_
****************************************
fpadd 	macro
	addd	,u++
	endm
****************************************
* n,m,_ --> n-m,_
****************************************
fpsub 	macro
	subd	,u++
	endm
****************************************
* fpadd/fpsub
* n,_ --> sat(n),_
* sature le resultat du fpadd fpsub
* précédent
****************************************
fpsat	macro
	bvc	*+9	
	ldd	#0	
	adcb	#$FF	
	adca	#$7F	
	endm
****************************************
* n,m,_ --> n,m,_
* compare n avec m.
****************************************
fpcmp 	macro
	cmpd	,u
	endm
****************************************
* n,_ --> n,_
* compare n avec 0
****************************************
fptst 	macro
	subd	#0
	endm
****************************************
* n,_ --> sign(n),_
****************************************
fpsign	macro
	jsr	fpsign1
	endm
fpsign1	subd	#0
	bgt	fpsign2
	blt	fpsign3
	rts
fpsign2	ldd	#256
	rts
fpsign3	ldd	#-256
	rts
****************************************
* n,_ --> -n,_
****************************************
fpneg 	macro
	nega
	negb
	sbca	#0
	endm
****************************************
* n,_ --> abs(n),_
****************************************
fpabs 	macro
	tsta
	bge	*+2+4
	nega
	negb
	sbca	 #0
	endm
****************************************
* n,_ --> trunc(n),_
* Effacement la partie fractionnaire.
****************************************
fptrunc	macro
	clrb
	endm
****************************************
* n,_ --> int(n+0.5),_
****************************************
fpround	macro
	addd	#128
	clrb
	endm
****************************************
* n,_ --> frac(n),_
* Effacement la partie entiere.
****************************************
fpfrac	macro
	clra
	endm
****************************************
* d,_ --> fixedpoint(d),_
* -128<=d<=127
****************************************
int2fp	macro
	tfr	b,a
	clrb
	endm
****************************************
* n,_ --> int(n),_
* le sommet de la pile est un entier
* 16bits en sortie.
****************************************
fp2int	macro
	tfr	a,b
	sex
	endm
****************************************
* n,_ --> n*2,_
****************************************
fpmul2	macro
	lslb
	rola
	endm
****************************************
* n,_ --> n/2,_
****************************************
fpdiv2	macro
	asra
	rorb
	endm
****************************************
* n,m,_ --> n*m,_
****************************************
fpmul 	macro
	jsr	fpmul_1
	endm
* Explications:
* (u[0]+u[1]/256) * (u[2]+u[3]/256)*256
*  = u[0]*u[2]*256 (a)
*  + u[1]*u[2]	   (b)
*  + u[0]*u[3]     (c)
*  + u[1]*u[3]/256 (d)
fpmul_1	std	,--u
	beq	fpmul_0
	eora	2,u	calcul signe
	pshs	a,x
	lda	,u	calcul abs(arg1)
	bge	fpmul_2
	nega		negd
	negb
	sbca	#0
	std	,u
fpmul_2	ldd	2,u	calcul abs(arg2)
	beq	fpmul_00
	bge	fpmul_3
	nega		negd
	negb
	sbca	#0
	std	2,u
fpmul_3	lda	1,u	(d)
	mul
	sta	*+3+2
	ldx	#$00ff
	lda	,u	(c)
	ldb	3,u
	mul
	leax	d,x
	ldd	1,u	(b)
	mul
	leax	d,x
	lda	,u	(a)
	ldb	2,u
	mul
	stb	*+3+2
	leax	$1100,x
	tfr	b,a
	clrb
	leax	d,x
	tfr	x,d
	tst	,s+
	bge	fpmul_4
	nega
	negb
	sbca	#0
fpmul_4	leau	4,u
	puls	x,pc
fpmul_00
	leau	7,u	sortie si arg2=0
	rts
fpmul_0	leau	4,u     sortie si arg1=0
	rts
****************************************
* n,m,_ --> n/m,_
****************************************
fpdiv	macro
	jsr	fpdiv_1
	endm
* Explications: calculer DDDD / XXXX en
* fixed point revient a calculer
* DDDD00 / 00XXXX en multi-precision
* entiere 24bits. On applique donc
* l'algo de division entiere classique
* avec decalage et soustraction, cf:
*    http://courses.cs.vt.edu/~cs1104/
*    BuildingBlocks/divide.030.html
* sur les nombres DDDD00 et 00XXXX.
fpdiv_1	std	,--u
	beq	fpmul_0
	eora	2,u	calcul signe
	sta	,-s
	lda	,u	abs(arg1)
	bge	fpdiv_2
	nega		negd
	negb
	sbca	#0
	std	,u
fpdiv_2	ldd	2,u	abs(arg2)
	beq	fpdiv_0	div by zero
	bge	fpdiv_3
	nega		negd
	negb
	sbca	#0
	std	2,u
fpdiv_3	Ldd	#24
	stb	,-s
	clrb
	std	,--s
	bsr	fpdiv_loop
	ldd	,u	diviseur
	tst	3,s
	bge	fpdiv_4
	nega		negd
	negb
	sbca	#0
fpdiv_4	leau	4,u
	leas	4,s
	rts
fpdiv_0	subd	#$7FFF	overflow
	tst	,s+
	bge	fpdiv_5
	nega		negd
	negb
	sbca	#0
fpdiv_5	leau	4,u
	rts
* Etat des piles en ce point de code:
* Pile U: 0 1  2 3
*		  DDDD XXXX
* Pile S: 0 1  2
*		  0000 18
* On peut les reorganiser pour que ca
* colle avec l'ago de division.
*     S2  __U2U3    S0 A B   U0U1S1
*
*     24  00XXXX    000000   DDDD00
*     ^^  ^^^^^^    ^^^^^^   ^^^^^^
*     ctr divisor dividend quotient
*
* On decale dividende et quotient en
* ajoutant le bit C a droite
fpdiv_loop
	rol	1,s
	rol	1,u
	rol	,u
	rolb
	rola
	rol	,s
* Ici on compare dividend (S0AABB) avec
* le divisior (00XXXX). En fait on
* effectue par avance la soustraction.
	subd   2,u
* si le poid faible AABB est plus grand
* que XXXX alors dividend>=divisor
* alors on soustrait (deja fait) et on
* ajoute 0 au quotient.
	bcc	fpdiv_6
* Sinon le poids faible est plus petit.
* On compare le poids fort (S0) a zero.
	tst	,s
* s'il est >0, donc dividend>=divisor,
* on soustrait (deja fait) et on ajoute
* 0 au quotient.
	bne	fpdiv_6
* sinon on ne soustrait pas (on annule)
* et on ajoute 1 au quotient
	addd	2,u
	bra	fpdiv_7
* la soustraction est deja faite sauf
* pour le poids fort. On force C=0 pour
* le quotient.
fpdiv_6	dec	,s
	andcc	#254
* on fait cela 3*8 = 24 fois
fpdiv_7	dec	2,s
	bne	fpdiv_loop
* D contient le diviseur, et U0U1 le
* quotient
	rts
****************************************
* n,m,_ --> n%m,_
****************************************
fprem	macro
	jsr    fprem_1
	endm
fprem_1	std	,--u
	beq	fpmul_0
	eora	2,u	calcul signe
	sta	,-s
	lda    	,u	calc abs(arg1)
	bge	fprem_2
	nega
	negb
	sbca	#0
	std	,u
fprem_2	ldd	2,u	calc abs(arg2)
	lbeq	fpdiv_0	div by zero
	bge	fprem_3
	nega
	negb
	sbca	#0
	std	2,u
fprem_3	ldd	#24
	stb	,-s
	clrb
	std	,--s
	bsr	fpdiv_loop
* En fait je ne sais pas si le reste doit
* etre signe ou pas
	tst	3,s
	bge	fprem_4
	nega
	negb
	sbca	#0
fprem_4	leau	4,u
	leas	4,s
	rts
****************************************
* n,_ --> n*n,_
****************************************
fpsqr	macro
	fpdup
	fpmul
	endm
****************************************
* n,_ --> sqrt(n),_
* calcule la racine carrée de n.
****************************************
fpsqrt	macro
	jsr	fpsqrt0
	endm
* Algo: Turkowski Fixed Point Square
* Root, 3 October 1994. Apple.
* remLo = x;
fpsqrt0	std	,--s
	bgt	fpsqrt1
	leas	2,s
	ldd	#0
	rts
* count = (NBITS>>1) + (FRACBITS>>1)
fpsqrt1	ldd	#12
	stb	,-s
* remHi = 0; /* Clear high part of partial remainder */
	clrb
	pshs	d
* root = 0; /* Clear root */
	pshs	d
* testDiv
	leas	-2,s
* root <<= 1; /* Get ready for the next bit in the root */
fpsqrt2	lslb
	rola
	std	2,s
* testDiv = (root << 1) + 1; /* Test radical */
	lslb
	rola
	orb	#1
	std	,s
* remHi = (remHi<<2) | (remLo>>30); 
* remLo <<= 2; /* get 2 bits of arg */
	lsl	8,s
	rol	7,s
	rol	5,s
	rol	4,s	
	lsl	8,s
	rol	7,s
	ldd	4,s
	rolb
	rola
	std	4,s
* if (remHi >= testDiv) {
	subd	,s
	bcs	fpsqrt3
* remHi -= testDiv;
	std	4,s
* root++
	ldd	#1
	addd	2,s
	bra	fpsqrt4
fpsqrt3	ldd	2,s
* } while (count-- != 0);
fpsqrt4	dec	6,s
	bne	fpsqrt2
* return(root);
	leas	9,s
	rts
*****************************************
* n,_ --> n,_ mais ecrit n avec au plus 2
* chiffres après la virgule à l'adresse
* pointee par x. A l'arrivée x pointe
* sur le "\0" final. Si n est entier, la
* partie décimale n'est pas affichée. 
* Il faut prévoir un buffer de 7 char au
* plus (pour écrire -127.99).
*****************************************
fptoa	macro
	jsr	fptoa1
	endm
fptoa1	pshs	d
	orb	,s
	bne	fptoa3
* cas nul	
	ldb	#'0
	stb	,x+
	bra	fptoa2
fptoa3	tsta
	bge	fptoa4
* cas negatif:
	ldb	#'-
	stb	,x+
	ldb	1,s
	nega
	negb
	sbca	#0
* cas positif:
fptoa4	pshs	d
	ldb	,s
	beq	fptoa6
* 1er et 2eme digit
	clra
	lslb
	rola
	lslb
	rola
	lslb
	rola
	lslb
	sta	,s
	adca	,s
	daa
	lslb
	sta	,s
	adca	,s
	daa
	lslb
	sta	,s
	adca	,s
	daa
	lslb
	sta	,s
	adca	,s
	daa
	lslb
	sta	,s
	adca	,s
	daa
	bcc	fptoa5
* digits 1, 2 et 3
	ldb	#'1
	stb	,x+
	sta	,s
	lsra
	lsra
	lsra
	lsra
	adda	#'0
	sta	,x+
	ldb	#15
	andb	,s+
	addb	#'0
	stb	,x+
	bra	fptoa7
* digit 2
fptoa5	sta	,s
	lsra
	lsra
	lsra
	lsra
	beq	fptoa6
	adda	#'0
	sta	,x+
* digit 3
fptoa6	ldb	#15
	andb	,s+
	addb	#'0
	stb	,x+
* partie fractionnaire
fptoa7	ldb	,s+
	beq	fptoa2	entier pur
	lda	#'.
	sta	,x+
	lda	#10
	mul
	adda	#'0
	sta	,x+
	lda	#10
	mul
	adda	#'0
	sta	,x+
	leas	2,s
fptoa2	clr	,x
	puls	d,pc
*****************************************
* n,_ --> cos(n),_ 
* cos est périodique de période 2 (i.e.
* pi = 1.
*****************************************
fpcos	macro
* cos(x) = sin(x + pi/2)
	addd	#128
	jsr	fpsin1
	endm
*****************************************
* n,_ --> sin(n),_ 
* sin est périodique de période 2 (i.e.
* pi = 1.
*****************************************
fpsin	macro
	jsr	fpsin1
	endm
fpsin1	anda	#1
	beq	fpsin2
	bsr	fpsin2
* sin(pi+x) = -sin(x)
	nega
	negb
	sbca	#0
	rts
fpsin2	tstb
	bge	fpsin4
	blt	fpsin3
* sin(pi/2) = 1
	ldd	#256
	rts
* sin(pi/2 + x) = sin(pi/2 - x)
fpsin3	negb
fpsin4	pshs	x
	ldx	#fpsintab
	abx
	ldb	,x
	clra
	puls	x,pc
fpsintab
        fcb     0,3,6,9,12,15,18,21,25
	fcb	28,31,34,37,40,43,46,49
	fcb	53,56,59,62,65,68,71,74
	fcb	77,80,83,86,89,92,95,97
	fcb	100,103,106,109,112,115
	fcb	117,120,123,126,128,131
	fcb	134,136,139,142,144,147
	fcb	149,152,155,157,159,162
	fcb	164,167,169,171,174,176
	fcb	178,181,183,185,187,189
	fcb	191,193,195,197,199,201
	fcb	203,205,207,209,211,212
	fcb	214,216,217,219,221,222
	fcb	224,225,227,228,230,231
	fcb	232,234,235,236,237,238
	fcb	239,241,242,243,244,244
	fcb	245,246,247,248,249,249
	fcb	250,251,251,252,252,253
	fcb	253,254,254,254,255,255
	fcb	255,255,255,255,255
*****************************************
* n,_ --> tan(n),_ 
*****************************************
fptan	macro
	fpdup		n,n,_
	fpcos		cos(n),n,_
	fpswap		n,cos(n),_
	fpsin		sin(n),cos(n),_
	fpdiv		sin(n)/cos(n),_
	endm
*****************************************
* n,_ --> exp(n),_
*****************************************
fpexp	macro
	jsr	fpexp1
	endm
fpexp1	tsta
	bge	fpexp2
* exp(-x) = 1/exp(x)
	fpneg
	bsr	fpexp2
	fppush	#256
	fpdiv
	rts
* exp(1243/256) > 128	overflow!
fpexp2	cmpd	#1442
	ble	fpexp3
	ldd	#$7fff
	rts
* exp(a.bc) = exp(a.00)
*           * exp(0.b0)
*           * exp(0.0c)
fpexp3	pshs	b,x
	lsla
	ldx	#fpexpt1
	ldd	a,x
	fpdup
	lda	#240
	anda	,s
	lsra
	lsra
	lsra
	ldx	#fpexpt2
	ldd	a,x
	fpdup
	lda	#15
	anda	,s
	lsla
	ldx	#fpexpt2
	ldd	a,x
	fpmul
	fpmul
	leas	1,s
	puls	x,pc
fpexpt1	fdb	256,695,1891,5141,13977
fpexpt2	fdb	256,272,290,308,328,349
	fdb	372,396,422,449,478,509
	fdb	541,576,614,653
fpexpt3	fdb	256,257,258,259,260,261
	fdb	262,263,264,265,266,267
	fdb	268,269,270,271,272
* FIN FPMATH.ASM
