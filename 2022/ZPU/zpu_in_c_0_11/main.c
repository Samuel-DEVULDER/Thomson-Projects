#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "zpu.h"
#include "zpu_load.h"

// Print usage instructions
void usage()
{
    printf ("ZOG v0.11\n");
}


int main(int argc, char *argv[])
{
    usage();
    // printf("%d %s %s\n", argc, argv[0], argv[1]);
    zpu_reset();
	zpu_load(argc>=2 && argv[1] ? argv[1] : "test.bin");
    zpu_execute();
}
