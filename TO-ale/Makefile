MAIN=TO-ale

DISK=$(MAIN).sap
EXE=.exe
C6809=../c6809/c6809$(EXE)
SAPFS=../sapfs/sapfs$(EXE)

ASM=$(wildcard *.ass)

all: compile fill_sapdir #test

compile: $(C6809) $(SAPFS) $(ASM:%.ass=build/%.BIN) 

list:	compile
	less codes.lst

clean: 
	rm -rf build sapdir mkboot.sap

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
	cp *.BAS sapdir
	$(SAPFS) -c $(DISK)
	$(SAPFS) -c mkboot.sap
	$(SAPFS) -a mkboot.sap sapdir/*

test:	
	../teo/teow.exe -fast -window -m MASS6809.M7 -disk1 `cygpath -w -s "$(PWD)/TO-ale.sap"` -disk0 `cygpath -w -s "$(PWD)/sapdir"`
#	-k7 `cygpath -w -s "$(PWD)/$(MAIN).k7"`
	