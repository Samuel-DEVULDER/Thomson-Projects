DISK=disk.sap

ALL=$(wildcard *.ass)

ifeq ($(OS),Windows_NT)
EXE=.exe
else
EXE=
endif

C6809=../../c6809/c6809$(EXE)
SAPFS=../../sapfs/sapfs$(EXE)
TEODIR=../../TEO_WIN_187_BETA3_20220907/

BIN=$(ALL:%.ass=build/%.BIN)

all: compile $(DISK)

compile: $(C6809) $(SAPFS) $(DISK)

list:	compile
	less codes.lst

clean:
	rm -rf build/

bin: $(BIN)

build/%.BIN: %.ass
	test -d build || mkdir build
	cp roadshow/*.bin build
	cd build && ../$(C6809) -c -bh -am -oOP ../$< `echo $*.BIN|tr a-z A-Z`

$(DISK): $(BIN) fill_sapdir
	# $(SAPFS) -c $@
	cp empty_disk/bootbk.sap "$@"
	$(SAPFS) -a $@ build/sapdir/*

$(SAPFS):
	cd $(dir $@) && make "CC=$(CC) -Dlinux" sapfs

%$(EXE): %.c
	$(CC) "$<" -Ofast -o "$@"

fill_sapdir: compile
	test -d build/sapdir || mkdir -p build/sapdir
	-rm *.fd *.FD
	for e in ASM BIN bin; do \
		cp build/*.$$e build/sapdir; \
	done
	mv build/sapdir/ZPU.BIN build/sapdir/AUTO.BIN

test:	$(DISK)
	cp $(DISK) $(TEODIR)/disk.sap
	cd $(TEODIR) && ./teo_win32_allegro.exe -r -0 disk.sap

stat: ../../dcmoto-printer.txt
	perl < $< -e '%a=(); while(<>) {chomp;$$a{substr($$_, 110)}++;}; @a = sort { $$a{$$a} <=> $$a{$$b} } (keys(%a)); foreach $$i (@a) {print $$a{$$i},"\t$$i\n";}'

stat2: ../../dcmoto-printer.txt
	perl < $< -e '%a=(); $$b=""; while(<>) {chomp;$$a=$$b;$$b=substr($$_, 110);$$a{sprintf("%-10s %-10s", $$a, $$b)}++;}; @a = sort { $$a{$$a} <=> $$a{$$b} } (keys(%a)); foreach $$i (@a) {print $$a{$$i},"\t$$i\n";}'

stat3: ../../dcmoto-printer.txt
	perl < $< -e '%a=(); $$b=""; $$c=""; while(<>) {chomp;($$a,$$b,$$c)=($$b,$$c,substr($$_, 110));$$a{sprintf("%-10s %-10s %-10s", $$a, $$b, $$c)}++;}; @a = sort { $$a{$$a} <=> $$a{$$b} } (keys(%a)); foreach $$i (@a) {print $$a{$$i},"\t$$i\n";}'

stat4: ../../dcmoto-printer.txt
	perl < $< -e '%a=(); while(<>) {chomp;($$a,$$b,$$c,$$d)=($$b,$$c,$$d,substr($$_, 110));$$a{sprintf("%-10s %-10s %-10s %-10s", $$a, $$b, $$c, $$d)}++;}; @a = sort { $$a{$$a} <=> $$a{$$b} } (keys(%a)); foreach $$i (@a) {print $$a{$$i},"\t$$i\n";}'
	
memmap: ../../dcmoto_trace.txt 
	cp build/codes.lst ../..
	cd ../..; \
	../DCMoto_MemMap/MemMap-v1.2-win-x86/lua.exe \
	../DCMoto_MemMap/MemMap-v1.2-win-x86/memmap.lua \
	-mach=to -equ -reset -hot -smooth -html; \
	explorer memmap.html
