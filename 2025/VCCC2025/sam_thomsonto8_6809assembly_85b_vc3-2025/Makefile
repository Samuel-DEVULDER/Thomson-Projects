DISK=disk.sap

ALL=$(wildcard *.ass)

ifeq ($(OS),Windows_NT)
EXE=.exe
else
EXE=
endif

ROOT=../../..

C6809=$(ROOT)/c6809/c6809$(EXE)
SAPFS=$(ROOT)/sapfs/sapfs$(EXE)
TEODIR=$(ROOT)/TEO_WIN_187_BETA3_20220907/

BIN=$(ALL:%.ass=build/%.BIN)

all: compile $(DISK)

compile: $(C6809) $(SAPFS) $(DISK)

list:	compile
	less codes.lst

clean: 
	rm -rf build/

build/%.BIN: %.ass 
	test -d build || mkdir build
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
	cp basic/* build/sapdir
	-rm *.fd *.FD 2>/dev/null
	for e in ASM BIN; do \
		cp build/*.$$e build/sapdir; \
	done

w:	$(DISK) 
	cp $^ VCCC2025.sap
	cd $(TEODIR) && ./teo_win32_allegro.exe \
	--disk0='$(shell cygpath -w $(PWD)/VCCC2025.sap)' \
	--cass='$(shell cygpath -w $(PWD)/VCCC2025.k7)' \
	--memo='$(shell cygpath -w $(PWD)/rom/assembleur-6809-v3_memo7.rom)'
