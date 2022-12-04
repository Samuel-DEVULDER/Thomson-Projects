#include <stdio.h>
#include <stdlib.h>

#include "zpu_load.h"
#include "zpu_memory.h"


void zpu_load(char *fileName)
{
    //   char* fileName = "../roadshow/a.bin";
	FILE* f;
	int bytesRead;
	int address;
	uint8_t inByte;

	// printf("f=%s\n", fileName);

	f = fopen(fileName, "r");
	if (f == 0)
	{
		printf("Failed to open %s\n", fileName);
		perror("");
		exit(0);
	}

	for (address = 0; address < memorySize(); address++)
	{
		bytesRead = fread(&inByte, 1, 1, f);
		if (bytesRead!=1 && ferror(f))
		{
			printf("Error reading RAM image from %s\n", fileName);
			perror("");
			exit(1);
		}
		if (feof(f))
		{
			break;
		}
		memoryWriteByte(address, inByte);
	}
	//printf("Loaded %d bytes from RAM image from %s\n", address, fileName);
	fclose(f);
}

