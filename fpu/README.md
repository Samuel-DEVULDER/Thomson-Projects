In this project I play around a "new" floating-point representation that is relatively compact and fast for the mc6809.

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
