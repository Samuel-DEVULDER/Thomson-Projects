In this project I play around a "new" floating-point representation that is relatively compact and fast for the mc6809.

The idea is to have a  3 byte floating-point number. One byte is the signed exponent (E), why the 2 remaining ones are the (signed) mantissa (N).
> EEEEEEEE NNNNNNNN NNNNNNNN
>   E=EXPO
>   N=-32768 .. 32767
which represents the number:
>   x = N * 2**E

The number is not normalized and there is no implicit 1 like in IEEE754 in order to make operations perform faster. The exponent is kept the same as the input and only modified when the mantissa cannot represent all the bits. This mean that as long as the exponent is the same, simple operations like addition/subtraction/comparison are pretty fast since no shift is required.
