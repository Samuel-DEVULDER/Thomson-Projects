what?

A ZPU virtual processor capable of adressing the whole memory, and able to run C code generated by gcc.

ZPU is a 32 bit stack-based processor. Its opcodes are just 1 byte long. There exist a C compiler for it (gcc). This makes it the perfect environment to make it emulate by an 8 bit machines.

Status?

work in progress.

Specs:

https://en.m.wikipedia.org/wiki/ZPU_(microprocessor)
https://github.com/zylin/zpu/blob/master/zpu/docs/zpu_arch.html
https://forums.parallax.com/discussion/119711/zog-a-zpu-processor-core-for-the-prop-gnu-c-c-and-fortran-now-replaces-s

Compiler:
https://github.com/zylin/zpugcc/
https://github.com/zylin/zpugcc/blob/master/toolchain/gcc/libgloss/zpu/crt0.S
