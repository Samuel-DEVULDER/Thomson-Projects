#include <stdio.h>
#include <stdlib.h>

#include "zpu.h"
#include "zpu_memory.h"
#include "zpu_io.h"
#include "zpu_load.h"

extern uint32_t pc;

static uint32_t memory[MEMORY_INTS];

void memoryInitialize()
{
    uint8_t* pByte = (uint8_t*)memory;
    for (uint32_t address = 0; address < (MEMORY_INTS*4); address++)
    {
        *pByte++ = ZPU_BREAKPOINT;  // Sets all RAM to ZPU break point
    }
}

uint32_t memoryReadLong(uint32_t address)
{
    // The PHI platform UART status port
    if (address == 0x80000024)
    {
        //return ioRead(address);
	return (0x100);
    }
    // The ??? platform UART status port
    if (address == 0x080A000C)
    {
        //return ioRead(address);
	return (0x100);
    }
    address = address & MEMORY_MASK;
    if ((address & 0x3) != 0)
    {
        printf ("Read LONG not aligned: PC=%08x, addr=%08x\n", pc, address);
        //exit(1);
    }
    if (address < (MEMORY_INTS*4))
    {
        return (memory[address/4]);
    }
    else
    {
        printf ("Read LONG out of range\n");
        exit (1);
    }
}

void memoryWriteLong(uint32_t address, uint32_t value)
{
    // The PHI platform UART port
    if (address == 0x80000024)
    {
	fprintf(stderr, "%c", (char)value);
	return;
    }
    // The ??? platform UART port
    if (address == 0x080A000C)
    {
	fprintf(stderr, "%c", (char)value);
	return;
    }
    address = address & MEMORY_MASK;
    if ((address & 0x3) != 0)
    {
        printf ("Write LONG not aligned\n");
        exit(1);
    }
    else if (address < (MEMORY_INTS*4))
    {
        memory[address/4] = value;
    }
    else
    {
        printf ("Write LONG out of range: addr=%08x, val=%08x\n", address, value);
        exit (1);
    }
}

uint16_t memoryReadWord(uint32_t address)
{
    address = address & MEMORY_MASK;
    if ((address & 0x1) != 0)
    {
        printf ("Read WORD not aligned\n");
        exit (1);
    }
    if (address < (MEMORY_INTS*4))
    {
        uint8_t* pByte = (uint8_t*)memory + (address ^ 0x02);
	return (*((uint16_t*)pByte));
    }
    else
    {
        printf ("Read WORD out of range\n");
    }
}

void memoryWriteWord(uint32_t address, uint16_t value)
{
    address = address & MEMORY_MASK;
    if ((address & 0x1) != 0)
    {
        printf ("Write WORD not aligned\n");
        exit (1);
    }
    if (address < (MEMORY_INTS*4))
    {
        uint8_t* pByte = (uint8_t*)memory + (address ^ 0x02);
	*((uint16_t*)pByte) = value;
    }
    else
    {
        printf ("Write WORD out of range\n");
    }
}

uint8_t memoryReadByte(uint32_t address)
{
    address = address & MEMORY_MASK;
    if (address < (MEMORY_INTS*4))
    {
        uint8_t* pByte = (uint8_t*)memory + (address ^ 0x03);
        //uint8_t* pByte = (uint8_t*)memory + address;
	return (*pByte);
    }
    else
    {
        printf ("Read BYTE out of range\n");
        exit (1);
    }
}

void memoryWriteByte(uint32_t address, uint8_t value)
{
    address = address & MEMORY_MASK;
    if (address < (MEMORY_INTS*4))
    {
        uint8_t* pByte = (uint8_t*)memory + (address ^ 0x03);
        //uint8_t* pByte = (uint8_t*)memory + address;
	*pByte = value;
    }
    else
    {
        printf ("Read BYTE out of range\n");
        exit (1);
    }
}

void memoryDisplayLong(uint32_t address, uint32_t length)
{
	for (int i = 0; i < length; i++)
	{
		printf("%08x %08x\n", address + i*4, memoryReadLong(address + i*4));
	}
}

uint32_t memorySize()
{
	return(MEMORY_SIZE);
}

