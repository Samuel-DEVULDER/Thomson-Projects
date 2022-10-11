MAIN=BOING

DISK=$(MAIN).sap

ifeq ($(OS),Windows_NT)
EXE=.exe
else
EXE=
endif

C6809=../../c6809/c6809$(EXE)
SAPFS=../../sapfs/sapfs$(EXE)

TEODIR=../../TEO_WIN_187_BETA3_20220907/

ASM=$(wildcard *.ass)
BIN=$(ASM:%.ass=build/%.BIN)

all: compile fill_sapdir

compile: $(C6809) $(SAPFS) $(ASM:%.ass=build/%.BIN) 

list:	compile
	less codes.lst

clean: 
	rm -rf build sapdir  $(DISK)
	
build/%.BIN: %.ass
	test -d build || mkdir -p build
	cd build && ../$(C6809) -c -am -oOP ../$< ../$@
	
$(SAPFS): 
	cd $(dir $@) && make "CC=$(CC) -Dlinux" sapfs

%$(EXE): %.c
	$(CC) "$<" -Ofast -o "$@"
	
fill_sapdir:
	test -d sapdir || mkdir -p sapdir
	cp build/*.ASM sapdir
	cp build/*.BIN sapdir
	cp bas/*.BA* sapdir
	$(SAPFS) -c $(DISK)
	$(SAPFS) -a $(DISK) sapdir/*
	
test: all $(DISK)
	cp $(DISK) $(TEODIR)/disk.sap
	cd $(TEODIR) && ./teo_win32_allegro.exe -r -0 disk.sap
	