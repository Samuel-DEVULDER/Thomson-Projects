#!/bin/sh
export PATH="../gcc.linux/bin:$PATH"
zpu-elf-gcc -phi -DTIME dhry_1.c dhry_2.c -fomit-frame-pointer -O3 -Wl,--relax -Wl,--gc-sections -o dhrystone.elf
zpu-elf-size *.elf
zpu-elf-objcopy -O binary dhrystone.elf dhrystone.bin
cp dhrystone.bin ../roadshow/dhryston.bin
#cp dhrystone.bin ../build/
#sh ../build/makefirmware.sh dhrystone.bin dhrystone.zpu



