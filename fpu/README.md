# What is this ?
In this project I play around a "new" floating-point representation that is relatively compact and fast for the mc6809. During the developpent I got mad with local temporary labels. I ran out of meaningful names, so used a classical lbl1, lbl2, ... naming strategy. This was nice, but t some point I had to add move some part of the code, and the the nice numbering got shuffled. The source code looked totally messy. So I developped a TOOL to write structured assembly code which is not filled with random labels.

# Idea behind the floating-point format
The idea is to have a  3 byte floating-point number. One byte is the biased exponent (E), and the 2 remaining bytes are the (signed) mantissa (N).
```
    EEEEEEEE NNNNNNNN NNNNNNNN
    E=BIASED-EXPO
    N=-32768 .. 32767
``` 
which represents the signed and possibly nul number:
```
    x = N * 2**(E-128)
```
when `E!=0`, and `x = 0` otherwise.

The numbers are not normalized (there are many representations for zero) and there is no implicit 1 like in IEEE754 in order to make operations perform faster. 

The exponent is kept as much the same as the "biggest" input. It is only modified when the mantissa cannot represent all the bits and some bits are to be lost beacause of trunctation. Notice that for speed reasons the mantissa is not shifted by a single bit but rather on full bytes. This mean we can loose a lot of precision from time to time just to keep the operations perform fast. That's the trade-off. However as long as the exponents are the same, simple operations like addition/subtraction/comparison which are prety freequent but slow due to mantissa alignment are here pretty fast here.

# Floating point implementation

## May the FORTH be with you

The various operations performed by the code uses a two-stack approach like in Forth. The U-stack will hold the floating-point values whereas the S-stack will hold the return values (e.g. standard stack). This allow operations to be easily chained without lots oft data transfer.

For speed reasons the X and D registers can be trashed. 

## List of implemented operations

The label is followed by a (before -- after) resprentation to show how it operates on the stack.

### Arithmetic

* fpabs ( f -- |f| ) 
  Absolute value.

* fpneg ( f -- -f )
  Additive inverse.

* fpsub ( f g -- f-g )
  Subtraction.

* fpadd ( f g -- f+g )
  Addition.

* fpmul ( f g -- f*g )
  Multiplication.

* fm_m10 ( f -- 10*f )
  Quickly multiply by 10. This is useful for I/O operations.

* fpshl ( f -- 2*f ) 
  Quickly double a value.
  
* fpinv ( f -- 1/f )
  Multiplicative inverse. The multiplicative inverse of 0 is +/- the biggest float available.

* fpdiv ( f g -- f/g )
  Division.

* fpmod ( f g -- f % g )
  Modulo.

* fprem ( f g -- f rem g )
  Remainder.

* fpsqr ( f -- f^2 )
  Squares a value.

* fpsqrt ( f -- sqrt(f) )
  Square root.

* fpfrac ( f -- frac(f) ) 
  Removes integer part (sign is kept).

* fptrunc ( f -- trunc(f) ) 
  Removes fractionnal part.

* fpfloor ( f -- floor(f) ) 
  Rounds to -infinity.

* fpceil ( f -- ceil(f) ) 
  Rounds to +infinity.

* fpround ( f -- round(f) ) 
  Round to nearest integer.

### Transcendental operations

* fpln ( f -- ln(f) ) 
  Natural logarithm.

* fppow ( f g -- f**g )
  Power function.

* fpexp ( f -- exp(x) )
  Exponentiation.

* fptan ( f -- tan(f) )
  Tangent operation.
  
* fpcos ( f -- cos(f) )
  Cosine.

* fpsine ( f -- sin(f) )
  Sine.

* fpatan ( f -- atan(f) )
  Reciprocal of tangent.

* fpgammap1 ( f -- gamma(f+1) ) 
  Approximate factorial via Ramanujan formula
  
### Misc

* fppi ( -- pi )
  Pushes PI on the stack.

* fprnd ( -- rnd ) 0 < rnd <1 period:65535
  Pushes a random value beween 0 and 1 (both excluded). 

* fpinvsqrt ( f -- 1/sqrt(abs(f)) )

# Structed ASM 
In the implementation I work with a structed ASM build on block of code using macros which will generate the appropriates labels to perform various block-type. This helps writing structured ASM not poluted by bady-named labels. If you look at `fpu.ass` you'll only see global labels. The local ones usually present to implements loops and conditionnal code are all hidden inside the blocks.

## DO..DONE
The basic block is the 
```
DO
   SOMETHING
   USEFUL
DONE
```
construct. Inside each block there exist an `EXIT` and `REDO` label. This mean you can jump out of the block with a simple `BRA EXIT`, or loop back to the beginning if the result of some instruction doesn't set the Z flag with a `BNE REDO` for instance. Example:
```
DO
   JSR GETC ; reads a key
   CMPB #10 ; look for new-line caracter
   BNE REDO
DONE
```

## DO..WHILE
Actually using the branch-to-REDO is a pretty common and useful scheme, so it has a shortcut:
```
DO 
   SOMETHING
WHILE <cc>
```
which is the same as
```
DO
   SOMETHING
   B<cc> REDO
DONE
```
Example:
```
DO
   JSR GETC ; reads a key
   CMPB #10 ; look for NL
WHILE ne
```
## Block nesting
Blocks can be nested upto 3 times (more depth can be added easily). One can EXIT or REDO any enclosing blocks by using one of 
* EXIT/REDO: exit/redo current block
* EXIT2/REDO2: exit redo the block that immediately encloses the current block
* EXIT3/REDO3: exit redo the top-level block (recall ony a depth of 3 is allowed).
Using these relative labels we can construct some very useful blocks. Calling EXIT2 out of context is meaningless and produces and unspecified behavior.

## DOIF cc..DOELIF cc...DOELIF cc..DOELSE...DONE
Using the DO/DONE construct, it is possible to write a structured IF/ENDIF of some kind:
```
DO
  JSR GETC 
  CMPB #10
  BEQ EXIT ; if B equals 10, do not perform the following
  LDB #7
  JSR PUTC ; beep
DONE
```
This is also a very frequent construct, so it has a short-cut as well:
```
JSR GETC 
CMPB #10
DOIF ne
  LDB #7
  JSR PUTC ; beep
DONE
```
Notice here that the condition is inverted. We perform the beep only if B is not equal to 10.

Of course sometimes we want to perform something **else** when a condition is not met. This is done using the DOELSE block
```
DOIF cc
   PERFORM 1
DOELSE
   PERFORM 2
DONE
```
which is a short-cut for
```
DO
   DO
     B<not-cc> EXIT
     PERFORM 1
     BRA EXIT2
   DONE
   PERFORM 2
DONE
```
Notice how we use the EXIT2 label to get out of two nested blocks.

Sometimes we can have another DOIF in the ELSE..DONE block. Instead of nesting DOIF which makes the code somehow unreadable, a DOELIF cc block is provided. For example
```
ASLB
DOIF vs
   Ooops we had an overlow
DOELIF cs
   Carry is set without overflow
DOELSE
   Well register B has just been doubled
DONE
```
Which is nothing more than the following code, but written in a much readable form (in my opinion at least):
```
   ASLB
   BVC lab1
   Ooops we had an overlow
   BRA lab4
lab2
   BCC lab3
   Carry is set without overflow
   BRA lab4
lab3
   Well register B has just been doubled
lab4
```
Please note that the condition refers to the one present at the DOIF. Any CC modification in the blocks doesn't affect other IFs.

## How is is working?
The DO/DONE blocks construct uses a stack of 16 bits values. These is implemented using the capababilites of the Macro-processor. The stack is limited in depth. Current maximum depth is 10 values pushed. It seem to be sufficient for merly complex code like thiso one implementing a floating-point library. A stack-overflow message will be printed during the compilation if the maximal stack depth is too small.
