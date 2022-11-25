# Makefile for HNY2013

DISK=hny2013.sap

ifeq ($(OS),Windows_NT)
EXE=.exe
else
EXE=
endif

C6809=../../c6809/c6809$(EXE)
SAPFS=../../sapfs/sapfs$(EXE)
TEODIR=../../TEO_WIN_187_BETA3_20220907/

IMAGES=$(wildcard images/*.gif)
ASM=$(wildcard asm/*.ass)
BIN=$(ASM:%.ass=build/%.BIN)

all: compile fill_sapdir #test 

compile: $(IMAGES:images/%=build/x%) $(C6809) $(ASM:asm/%.ass=build/%.BIN) 

list:	compile
	less codes.lst

clean: 
	rm -rf build/*

$(SAPFS): 
	cd $(dir $@) && make "CC=$(CC) -Dlinux" sapfs

%$(EXE): %.c
	$(CC) "$<" -Ofast -o "$@"

build/%.BIN: asm/%.ass
	test -d build || mkdir -p build/
	cd build && ../$(C6809) -c -am -oOP ../$< ../$@

build/x%.gif: images/%.gif
	test -d build || mkdir -p build/
	cd build && perl ../converters/img_to7_9exp.pl ../$<
	
fill_sapdir: $(SAPFS) empty_disk/bootbk.sap
	test -d build/sapdir || mkdir -p build/sapdir
	cp basic/*.BAS build/sapdir
	cp build/*.ASM build/sapdir
	cp build/*.BIN build/sapdir
	cp build/*.mp* build/sapdir
	cp build/snow.BIN build/sapdir/AUTO.BIN
	cp empty_disk/bootbk.sap $(DISK)
	# $(SAPFS) -c $(DISK)
	$(SAPFS) -a $(DISK) build/sapdir/*

test: all $(DISK)
	cp $(DISK) $(TEODIR)/disk.sap
	cd $(TEODIR) && ./teo_win32_allegro.exe -r -0 disk.sap
	
w:	compile fill_sapdir $(DISK)
	../teo/teow$(EXE) -window -m MASS6809.M7 -disk1 `cygpath -w -s "$(PWD)/disk.sap"` -disk0 `cygpath -w -s "$(PWD)/sapdir"`

go:	compile fill_sapdir $(DISK)
	../teo/teow$(EXE) -m MASS6809.M7 -disk1 `cygpath -w -s "$(PWD)/disk.sap"` -disk0 `cygpath -w -s "$(PWD)/sapdir"`
	