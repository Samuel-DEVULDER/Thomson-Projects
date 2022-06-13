DISK=rotozoom.sap

ifeq ($(OS),Windows_NT)
EXE=.exe
else
EXE=
endif

C6809=../../c6809/c6809$(EXE)
SAPFS=../../sapfs/sapfs$(EXE)

ASM=$(wildcard *.ass)

all: compile fill_sapdir #test

compile: $(C6809) $(ASM:%.ass=build/%.BIN) 

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
	
#main.asm: rotozoom.ass
#	sh inline_inc.sh $@ $< >$@_
#	mv $@_ $@
#	../windows/c6809.exe -am -c -oOP/CM $@ $*.bin
	
fill_sapdir: $(SAPFS)
	test -d build/sapdir || mkdir -p build/sapdir
	-cp basic/*.BAT build/sapdir
	-cp basic/*.BAS build/sapdir
	-cp build/*.ASM build/sapdir
	-cp build/*.BIN build/sapdir
	$(SAPFS) -c $(DISK)
	$(SAPFS) -a $(DISK) build/sapdir/*

test:	
	../teo/teow.exe -fast -window -m MASS6809.M7 -disk0 `cygpath -w -s "$(PWD)/sapdir"`
	