#ifndef ZPU_SYSCALL_H
#define ZPU_SYSCALL_H

#include <stdint.h>

// syscall ID numbers
#define SYS_READ  4
#define SYS_WRITE 5

void sysinitialize();

void syscall(uint32_t sp);

#endif