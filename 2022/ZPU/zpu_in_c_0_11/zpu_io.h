#ifndef ZPU_IO_H
#define ZPU_IO_H

#include <stdint.h>

#define IO_BASE              0x80000000
#define IOSIZE               32768

int32_t ioRead(uint32_t addr);

void ioWrite(uint32_t addr, int32_t val);

#endif