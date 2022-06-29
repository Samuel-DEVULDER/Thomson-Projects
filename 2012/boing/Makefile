MAIN=BOING

DISK=$(MAIN).sap

ifeq ($(OS),Windows_NT)
EXE=.exe
else
EXE=
endif

C6809=../../c6809/c6809$(EXE)
SAPFS=../../sapfs/sapfs$(EXE)

ASM=$(wildcard *.ass)

all: compile fill_sapdir

compile: $(C6809) $(SAPFS) $(ASM:%.ass=build/%.BIN) 

list:	compile
	less codes.lst

clean: 
	rm -rf build sapdir 
	
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