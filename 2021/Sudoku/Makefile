MAIN=sudoku

DISK=$(MAIN).sap
K7=$(DISK:.sap=.k7)

ASM=$(wildcard *.ass)
BIN=$(ASM:%.ass=build/%.BIN)

ifeq ($(OS),Windows_NT)
EXE=.exe
else
EXE=
endif

C6809=../../c6809/c6809$(EXE)
SAPFS=../../sapfs/sapfs$(EXE)

TEODIR=../../TEO_WIN_187_BETA3_20220907/


all: compile fill_sapdir
	@ls -l sapdir

compile: $(C6809) $(SAPFS) $(BIN) $(EXO) 
	
list:	compile
	less build/codes.lst

clean: 
	rm -rf build sapdir  $(DISK)

build:
	test -d build || mkdir -p build

build/%.BIN: %.ass build
	cd build && ../$(C6809) -c -am -oOP ../$< `echo ../$@ | tr a-z A-Z` 
	
$(SAPFS): 
	cd $(dir $@) && make "CC=$(CC) -Dlinux" sapfs

%$(EXE): %.c
	$(CC) "$<" -Ofast -o "$@"

sapdir:
	test -d sapdir || mkdir -p sapdir

fill_sapdir: sapdir
	-cp bas/*.BA*	sapdir  2>/dev/null	
	-cp build/*.ASM sapdir  2>/dev/null	
	-cp build/*.BIN sapdir 2>/dev/null
	$(SAPFS) -c $(DISK)
	$(SAPFS) -a $(DISK) sapdir/*
	
$(K7): 
	echo >$@ -n

test: all $(DISK)
	cp $(DISK) $(TEODIR)/disk.sap
	cd $(TEODIR) && ./teo_win32_allegro.exe -r -0 disk.sap