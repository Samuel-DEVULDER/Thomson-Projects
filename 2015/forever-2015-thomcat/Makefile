ALL=$(wildcard *.ass)
DISK=Forever-2015.sap
K7=$(DISK:.sap=.k7)
K7=$(DISK:.sap=.k7)

ASM=$(wildcard *.ass)
BIN=$(ASM:%.ass=build/%.BIN)
EXO=$(ASM:%.ass=build/%.EXO)

ifeq ($(OS),Windows_NT)
EXE=.exe
else
EXE=
endif

C6809=../../c6809/c6809$(EXE)
SAPFS=../../sapfs/sapfs$(EXE)
EXOBIN=../../exobin/exobin.buggy$(EXE)

TEODIR=../../TEO_WIN_187_BETA3_20220907/

all: compile fill_sapdir 

compile: $(C6809) $(SAPFS) $(DAT) $(BIN)

list:	compile
	less codes.lst

clean: 
	rm -rf build sapdir  $(DISK)
	
build:
	test -d build || mkdir -p build

build/%.BIN: %.ass build build/%.dat
	cd build && ../$(C6809) -c -bh -am -oOP ../$< `echo ../$@ | tr a-z A-Z` 
	
build/%.EXO: build/%.BIN
	$(EXOBIN) -x "$<"
	
build/%.dat: %.dat
	cp "$<" "$@"
	
$(SAPFS): 
	cd $(dir $@) && make "CC=$(CC) -Dlinux" sapfs

$(EXOBIN): $(EXOBIN:%$(EXE)=%.c)
	cd $(dir $@) && make $(notdir $(EXOBIN))

%$(EXE): %.c
	$(CC) "$<" -Ofast -o "$@"

$(DISK): fill_sapdir
	ls -l sapdir/
	$(SAPFS) -c $@
	$(SAPFS) -a $@ sapdir/*
	
$(K7): 
	echo >$@ -n
	
x%.gif: %.gif
	-perl img_to7_9exp.pl $*.gif

sapdir:
	test -d sapdir || mkdir -p sapdir

fill_sapdir: compile sapdir
	-cp bas/*.BA*	sapdir  2>/dev/null	
	-cp build/*.ASM sapdir  2>/dev/null	
	-cp build/*.BIN sapdir 2>/dev/null
	
test: all $(DISK)
	cp $(DISK) $(TEODIR)/disk.sap
	cd $(TEODIR) && ./teo_win32_allegro.exe -r -0 disk.sap
