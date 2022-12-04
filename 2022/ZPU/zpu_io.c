#include "zpu_io.h"

void ioWrite(uint32_t addr, int32_t val)
{
#ifdef DO_IO
    addr -= IO_BASE;
    /* note, big endian! */
    switch (addr)
    {
        case 12:
            syscall.writeUART(val);
            break;
        case 20:
            interrupt = val != 0;
            break;
        case 28:
            timerInterval = val;
            break;
        case 32:
            timer = val != 0;
            break;
        case 0x24:
            syscall.writeUART(val);
            break;
        case 0x100:
            writeTimerSampleReg(val);
            break;
        default:
            break;
    }
#endif
}


int32_t ioRead(uint32_t addr)
{
#ifdef DO_IO
    addr -= IO_BASE;
    /* note, big endian! */
    switch (addr)
    {
        case 20:
            return interrupt ? 1 : 0;

        case 32:
            return timer ? 1 : 0;

        case 0x24:
            return syscall.readUART();

            /* FIFO empty? bit 0, FIFO full bit 1(never the case) */
        case 0x28:
            return syscall.readFIFO();

        case 0x100:
        case 0x104:
        case 0x108:
        case 0x10c:
        case 0x110:
        case 0x114:
        case 0x118:
        case 0x11c:
            return readSampledTimer(addr, 0x100);

        case 0x200:
            return readMHz();

        default:
            throw new MemoryAccessException();
    }
#endif
}
