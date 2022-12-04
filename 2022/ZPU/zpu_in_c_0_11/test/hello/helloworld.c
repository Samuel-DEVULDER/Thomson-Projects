#include "stdio.h"

static int result;

unsigned int fibo (unsigned int n)
{
    if (n <= 1)
    {
        return (n);
    }
    else
    {
        return fibo(n - 1) + fibo(n - 2);
    }
}


int main(int argc, char* argv[])
{
    iprintf("Helloworld.\n");
    // Show some FIBO sequence
    for (int n = 23; n <= 26; n++)
    {
        result = fibo(n);
        iprintf ("fibo(%d) = %d\n", n, result);
    }
    iprintf("Bye.\n");
    return (0);
}

