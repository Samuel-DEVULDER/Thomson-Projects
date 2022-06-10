# Makefile for HNYé013

DISK=hny2013.sap

EXE=.exe
C6809=../c6809/c6809$(EXE)
SAPFS=../sapfs/sapfs$(EXE)

IMAGES=$(wildcard images/*.gif)
ASM=$(wildcard asm/*.ass)

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
	test -d build || mkdirs build/
	cd build/ && ../$(C6809) -c -am -oOP ../$< ../$@

build/x%.gif: images/%.gif
	test -d build || mkdirs build/
	cd build && perl ../converters/img_to7_9exp.pl ../$<
	
#main.asm: rotozoom.ass
#	sh inline_inc.sh $@ $< >$@_
#	mv $@_ $@
#	../windows/c6809$(EXE) -am -c -oOP/CM $@ $*.bin
	
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

test: $(DISK)
	../teo/teow$(EXE) -fast -window -m MASS6809.M7 -disk1 `cygpath -w -s "$(PWD)/disk.sap"` -disk0 `cygpath -w -s "$(PWD)/tmp.sap"`
#	-k7 `cygpath -w -s "$(PWD)/$(MAIN).k7"`

w:	compile fill_sapdir $(DISK)
	../teo/teow$(EXE) -window -m MASS6809.M7 -disk1 `cygpath -w -s "$(PWD)/disk.sap"` -disk0 `cygpath -w -s "$(PWD)/sapdir"`

go:	compile fill_sapdir $(DISK)
	../teo/teow$(EXE) -m MASS6809.M7 -disk1 `cygpath -w -s "$(PWD)/disk.sap"` -disk0 `cygpath -w -s "$(PWD)/sapdir"`
	