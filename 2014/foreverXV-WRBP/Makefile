MAIN=WRBP

DISK=$(MAIN).sap
K7=$(DISK:.sap=.k7)

ASM=$(MAIN).ass
BIN=$(ASM:%.ass=build/%.BIN)
EXO=$(ASM:%.ass=build/%.EXO)
ZIK=zik/Cauldron2_V1.mid

ifeq ($(OS),Windows_NT)
EXE=.exe
else
EXE=
endif

C6809=../../c6809/c6809$(EXE)
SAPFS=../../sapfs/sapfs$(EXE)
EXOBIN=./exobin/exobin

TEODIR=../../TEO_WIN_187_BETA3_20220907/

all: compile fill_sapdir
	@ls -l sapdir

compile: $(C6809) $(SAPFS) $(EXOBIN) $(EXO) 
	
list:	compile
	less build/codes.lst

clean: 
	-cd $(dir $(EXOBIN)) && make clean
	rm -rf build sapdir $(EXOBIN) $(DISK)

build:
	test -d build || mkdir -p build

build/%.BIN: %_proto.ass build $(ZIK)
	cat "$<" > "build/$*.ass"
	echo >> "build/$*.ass"
	perl zik/midi_conv.pl -d -i "$(ZIK)" >> "build/$*.ass"
	cd build && ../$(C6809) -c -am -oOP "$*.ass" `echo ../$@ | tr a-z A-Z` 

build/%.BIN: %.ass build
	cd build && ../$(C6809) -c -am -oOP ../$< `echo ../$@ | tr a-z A-Z` 
	
build/%.EXO: build/%.BIN
	$(EXOBIN) -x "$<"

$(SAPFS): 
	cd $(dir $@) && make "CC=$(CC) -Dlinux" sapfs

$(EXOBIN): $(EXOBIN:%=%.c)
	cd $(dir $@) && make $(notdir $(EXOBIN))

%$(EXE): %.c
	$(CC) "$<" -Ofast -o "$@"

sapdir:
	test -d sapdir || mkdir -p sapdir


fill_sapdir: sapdir
	-cp basic/*.BA*	sapdir  2>/dev/null	
	-cp build/*.ASM sapdir  2>/dev/null	
	-cp build/*.BIN sapdir 2>/dev/null
	-cp build/*.EXO sapdir 2>/dev/null
	$(SAPFS) -c $(DISK)
	$(SAPFS) -a $(DISK) sapdir/*
	
$(K7): 
	echo >$@ -n

test: all $(DISK)
	cp $(DISK) $(TEODIR)/disk.sap
	cd $(TEODIR) && ./teo_win32_allegro.exe -r -0 disk.sap