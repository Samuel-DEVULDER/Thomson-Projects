# Makefile for "Oh la belle bleue"

DISK=olbb.sap

EXE=.exe
C6809=../../c6809/c6809$(EXE)
SAPFS=../../sapfs/sapfs$(EXE)

IMAGES=$(wildcard images/*.gif) $(wildcard images/*.png)
ASM=$(wildcard *.ass)

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

test: $(DISK)
	../teo/teow$(EXE) -fast -window -m MASS6809.M7 -disk1 `cygpath -w -s "$(PWD)/disk.sap"` -disk0 `cygpath -w -s "$(PWD)/tmp.sap"`
#	-k7 `cygpath -w -s "$(PWD)/$(MAIN).k7"`

w:	compile fill_sapdir $(DISK)
	../teo/teow$(EXE) -window -m MASS6809.M7 -disk1 `cygpath -w -s "$(PWD)/disk.sap"` -disk0 `cygpath -w -s "$(PWD)/sapdir"`

go:	compile fill_sapdir $(DISK)
	../teo/teow$(EXE) -m MASS6809.M7 -disk1 `cygpath -w -s "$(PWD)/disk.sap"` -disk0 `cygpath -w -s "$(PWD)/sapdir"`
	