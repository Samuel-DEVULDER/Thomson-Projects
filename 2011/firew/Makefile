# Makefile for "Oh la belle bleue"

DISK=olbb.sap

ifeq ($(OS),Windows_NT)
EXE=.exe
else
EXE=
endif

C6809=../../c6809/c6809$(EXE)
SAPFS=../../sapfs/sapfs$(EXE)

TEODIR=../../TEO_WIN_187_BETA3_20220907/

IMAGES=$(wildcard images/*.gif) $(wildcard images/*.png)
ASM=$(wildcard *.ass)
BIN=$(ASM:%.ass=build/%.BIN)

all: compile fill_sapdir #test 

compile: \
	$(IMAGES:images/%.gif=build/x%.gif) \
	$(IMAGES:images/%.png=build/x%.gif) \
	$(C6809) \
	$(ASM:%.ass=build/%.BIN) 

list:	compile
	less codes.lst

clean: 
	rm -rf build/*

$(DISK): $(BIN) fill_sapdir
	$(SAPFS) -c $@
	$(SAPFS) -a $@ build/sapdir/*

$(SAPFS): 
	cd $(dir $@) && make "CC=$(CC) -Dlinux" sapfs

%$(EXE): %.c
	$(CC) "$<" -Ofast -o "$@"

build/%.BIN: %.ass
	test -d build || mkdir -p build/
	cd build && ../$(C6809) -c -am -oOP ../$< ../$@

build/x%.gif: images/%.png
	test -d build || mkdir -p build/
	cd build && perl ../converters/img_to7_9exp.pl ../$<

build/x%.gif: images/%.gif
	test -d build || mkdir -p build/
	cd build && perl ../converters/img_to7_9exp.pl ../$<
	
fill_sapdir: $(SAPFS)
	test -d build/sapdir || mkdir -p build/sapdir
	cp basic/*.BAT build/sapdir
	cp basic/*.BAS build/sapdir
	cp build/*.ASM build/sapdir
	cp build/*.BIN build/sapdir
	cp build/*.mp* build/sapdir
	$(SAPFS) -c $(DISK)
	$(SAPFS) -a $(DISK) build/sapdir/*

test: all $(DISK)
	cp $(DISK) $(TEODIR)/disk.sap
	cd $(TEODIR) && ./teo_win32_allegro.exe -r -0 disk.sap

w:	compile fill_sapdir $(DISK)
	../teo/teow$(EXE) -window -m MASS6809.M7 -disk1 `cygpath -w -s "$(PWD)/disk.sap"` -disk0 `cygpath -w -s "$(PWD)/sapdir"`

go:	compile fill_sapdir $(DISK)
	../teo/teow$(EXE) -m MASS6809.M7 -disk1 `cygpath -w -s "$(PWD)/disk.sap"` -disk0 `cygpath -w -s "$(PWD)/sapdir"`
	