# Makefile to compile and link a test program from test.c for the ZPU architecture
# Creates a raw binary RAM image to load - test.bin
# Creates an assembler listing file - test.lst

# The compiler/linker
CC=gcc

# Compiler flags. Compile only, debug info, all warnings, optimize for size
CFLAGS=-c -g -Wall -O3 -std=c99 -I.

#Linker flags. phi platform, shrink(relax) immediates, remove unwanted sections
LDFLAGS= -static

# Source files, add more here if you have
SOURCES=main.c zpu.c zpu_memory.c zpu_io.c zpu_syscall.c zpu_load.c

# Create a list of object file names from source file names
OBJECTS=$(SOURCES:.c=.o)

# The program to build
EXECUTABLE=zpu

# Binary output file name
BINARY=$(EXECUTABLE).bin

#Listing output file name
LISTING=$(EXECUTABLE).lst

# By default build an executeable, a raw binary RAM image and an assembler listing file
all: $(SOURCES) $(EXECUTABLE)

# Link the executable from object files
$(EXECUTABLE): $(OBJECTS)
	$(CC) $(LDFLAGS) $(OBJECTS) -o $@

# Compile .c files into objexts .o
.c.o:
	$(CC) $(CFLAGS) $< -o $@

# Clean up
clean:
	rm -rf *.o $(EXECUTABLE)

