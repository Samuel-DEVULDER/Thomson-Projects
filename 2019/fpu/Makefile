DISK=disk.sap

ALL=$(wildcard *.ass)

ifeq ($(OS),Windows_NT)
EXE=.exe
else
EXE=
endif

C6809=../../c6809/c6809$(EXE)
SAPFS=../../sapfs/sapfs$(EXE)

BIN=$(ALL:%.ass=build/%.BIN)

all: compile $(DISK)

compile: $(C6809) $(SAPFS) $(DISK)

list:	compile
	less codes.lst

clean: 
	rm -rf build/

build/%.BIN: %.ass 
	ted -d build || mkdir build
	cd build && ../$(C6809) -c -bh -am -oOP ../$< `echo $*.BIN|tr a-z A-Z`
	
$(DISK): $(BIN) fill_sapdir
	$(SAPFS) -c $@
	$(SAPFS) -a $@ build/sapdir/*
	
$(SAPFS): 
	cd $(dir $@) && make "CC=$(CC) -Dlinux" sapfs

%$(EXE): %.c
	$(CC) "$<" -Ofast -o "$@"

fill_sapdir: compile
	test -d build/sapdir || mkdir -p build/sapdir
	-rm *.fd *.FD
	for e in ASM BIN; do \
		cp build/*.$$e build/sapdir; \
	done

w:	$(DISK) $(K7)
	../teo/teow.exe -window -m MASS6809.M7 -disk0 `cygpath -w -s "$(PWD)/$(DISK)"`
	cd sapdir && ../tools/sapfs.exe --extract-all ../$(DISK)
