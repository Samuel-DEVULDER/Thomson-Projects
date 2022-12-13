MAIN=ROCKFORT

DISK=$(MAIN).sap

ifeq ($(OS),Windows_NT)
EXE=.exe
else
EXE=
endif

C6809=../../c6809/c6809$(EXE)
SAPFS=../../sapfs/sapfs$(EXE)
EXOBIN=../../exobin/exobin.buggy$(EXE)

TEODIR=../../TEO_WIN_187_BETA3_20220907/

ASM=$(wildcard *.ass)
BIN=$(ASM:%.ass=build/%.BIN)

all: compile fill_sapdir

EXO=$(ASM:%.ass=build/%.EXO) 

compile: $(C6809) $(SAPFS) $(EXOBIN) $(EXO)
	@ls -l $(ASM:%.ass=build/%.EXO)

list:	compile
	less codes.lst

clean: 
	rm -rf build sapdir  $(DISK)

build:
	test -d build || mkdir -p build
	
build/%.BIN: build/%.ass build		
	cd build && ../$(C6809) -c -am -oOP ../$< `echo ../$@ | tr a-z A-Z` 
	
build/%.ass: %.ass build TEXTE.ASM
	perl -e 'while(<>) {if(/@TEXT.ASM@/) {open FILE,"TEXTE.ASM"; print <FILE>; close FILE;} else {print;}}' $< > $@

build/%.EXO: build/%.BIN
	$(EXOBIN) -x "$<"
	
$(SAPFS): 
	cd $(dir $@) && make "CC=$(CC) -Dlinux" sapfs

$(EXOBIN): 
	cd $(dir $@) && make $(notdir $(EXOBIN))

%$(EXE): %.c
	$(CC) "$<" -Ofast -o "$@"
	
fill_sapdir:
	test -d sapdir || mkdir -p sapdir
	-cp build/*.ASM sapdir  2>/dev/null	
	-cp build/*.BIN sapdir 2>/dev/null
	-cp build/*.EXO sapdir 2>/dev/null
	-cp *.BA* sapdir 2>/dev/null
	$(SAPFS) -c $(DISK)
	$(SAPFS) -a $(DISK) sapdir/*
	
test: all $(DISK)
	cp $(DISK) $(TEODIR)/disk.sap
	cd $(TEODIR) && ./teo_win32_allegro.exe -r -0 disk.sap
	