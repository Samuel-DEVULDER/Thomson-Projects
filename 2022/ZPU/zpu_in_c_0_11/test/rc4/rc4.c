#ifndef ZPU
#include "stdio.h"
#endif


unsigned int ukrap = 0x33333333;


void putnum(unsigned int num)
{
  char  buf[9];
  int   cnt;
  char  *ptr;
  int   digit;

  ptr = buf;
  for (cnt = 7 ; cnt >= 0 ; cnt--)
  {
    digit = (num >> (cnt * 4)) & 0xf;

    if (digit <= 9)
      *ptr++ = (char) ('0' + digit);
    else
      *ptr++ = (char) ('a' - 10 + digit);
  }

  *ptr = (char) 0;

#ifdef ZPU
  print (buf);
#else
  printf (buf);
#endif
}



int main()
{
    ukrap = 100;
    ukrap = 12 % ukrap;

    printf("Modulus = %d\n", ukrap);

    return 0;
}

