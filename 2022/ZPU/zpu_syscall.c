#include <stdio.h>
#include <termio.h>

#include "zpu_syscall.h"
#include "zpu_memory.h"

void sysinitialize()
{
    if (tty_break() != 0)
    {
        return exit(1);
    }
    //  tty_fix();
}


void syscall(uint32_t sp)
{
    int returnAdd = memoryReadLong(sp + 0);
    int errNoAdd = memoryReadLong(sp + 4);
    int sysCallId = memoryReadLong(sp + 8);
    int fileNo = memoryReadLong(sp + 12);
    int charIndex = memoryReadLong(sp + 16);
    int stringLength = memoryReadLong(sp + 20);
    switch (sysCallId)
    {
        case SYS_WRITE:
            for (int i = 0; i < stringLength; i++)
            {
                putchar(memoryReadByte(charIndex++));
            }
            // Return value via R0 (AKA memory address 0)
            memoryWriteLong(0, stringLength);
            break;
        case SYS_READ:
            for (int i = 0; i < stringLength; i++)
            {
                memoryWriteByte(charIndex++, tty_getchar());
            }
            // Return value via R0 (AKA memory address 0)
            memoryWriteLong(0, stringLength);
            break;
    }
}


static struct termio savemodes;
static int havemodes = 0;

int tty_break()
{
    struct termio modmodes;
    if(ioctl(fileno(stdin), TCGETA, &savemodes) < 0)
    {
        exit(1);
    }
    havemodes = 1;
    modmodes = savemodes;
    modmodes.c_lflag &= ~ICANON;
    modmodes.c_cc[VMIN] = 1;
    modmodes.c_cc[VTIME] = 0;
    return ioctl(fileno(stdin), TCSETAW, &modmodes);
}


int tty_getchar()
{
    return getchar();
}


int tty_fix()
{
    if(!havemodes)
    {
        return (0);
        return ioctl(fileno(stdin), TCSETAW, &savemodes);
    }
}
