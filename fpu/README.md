In this project I play around a "new" floating-point representation that is relatively compact and fast for the mc6809.

The idea is to have a  3 byte floating-point number. One byte is the signed exponent, why the 2 remaining ones are the (signed) mantissa. The number is not normalized to make operations perform faster. The exponent is lazily modified and will be kept the same as the input unless an overflow occurs. This mean that as long as the exponent is the same simple operations like addition/subtraction/comparison are pretty fast since no shift is needed.
