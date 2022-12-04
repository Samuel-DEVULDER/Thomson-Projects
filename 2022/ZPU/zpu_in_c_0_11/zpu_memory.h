#ifndef ZPU_MEMORY_H
#define ZPU_MEMORY_H

#include <stdint.h>

// Memory size must be a power of 2.
#define MEMORY_SIZE (1024 * 1024)
#define MEMORY_MASK (MEMORY_SIZE - 1)
#define MEMORY_INTS (MEMORY_SIZE / 4)

void memoryInitialize();

uint32_t memoryReadLong(uint32_t address);

void memoryWriteLong(uint32_t address, uint32_t value);

uint8_t memoryReadByte(uint32_t address);

void memoryWriteByte(uint32_t address, uint8_t value);

uint16_t memoryReadWord(uint32_t address);

void memoryWriteWord(uint32_t address, uint16_t value);

void memoryDisplayLong(uint32_t address, uint32_t length);

uint32_t memorySize();
#endif

