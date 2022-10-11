CC=gcc
CFLAGS=-O3 -Wall
RM=rm

ifeq ($(OS),Windows_NT)
	EXE=.exe
else
	EXE=
endif

MANIFEST=$(wildcard *.manifest)
DSK=$(MANIFEST:%.manifest=%.fd)

ASM=$(wildcard asm/*.ass) $(wildcard trackdisk/asm/*.ASS)

BIN:=$(ASM:asm/%.ass=bin/%.bin)
BIN:=$(BIN:trackdisk/asm/%.ASS=bin/%.bin)

M0D=$(shell ls mods/*/*.[mM][oO][dD] | sed 's%mods/.*/\(.*\).mod%m0ds/\1.m0d%i')
M0D_ORG=6b00

TGZ=$(shell basename "$(PWD)").tgz

LUA=tools/lua$(EXE)
C6809=tools/c6809$(EXE)
DISKTO=tools/diskto$(EXE)

ALL=$(DSK)

all: $(ALL)
	ls -l $(DSK)
	
z:
	@echo '$(ASM)'
	@echo '$(BIN)'
	@echo '$(MOD)'
	@echo '$(M0D)'
	
clean:
	-$(RM) 2>/dev/null *.fd *.sap codes.lst *.ASM *.stackdump
	
fullclean: clean
	-$(RM) 2>/dev/null m0d/* bin/* $(C6809) $(DISKTO) $(LUA)
	-cd lua52/src && make -f Makefile.std clean && $(RM) lua$(EXE) luac$(EXE)
	
norm:
	@for i in mods/*/*; do case $$i in *\ *) mv -v "$$i" `echo "$$i" | tr ' ' '_'`;; esac; done
	
tgz: fullclean $(TGZ)

%.tgz: ../% ./*/. ./*/*/.
	@echo > "$@"
	@cd .. && tar czf "$*/$@" $* --exclude=*.zip --exclude=tools/teo --exclude=*.tgz --exclude=dc* --exclude=*/attic/*
	@tar tvf "$@"
	@du "$@"

gz: $(FD)
	-@rm *.sap.gz *.fd.gz
	gzip *.sap *.fd
	
$(LUA): lua52/src $(wildcard lua52/src/*)
	@echo Compining "$@" ...
	@cd $< && export MAKE="make -f Makefile.std" && $$MAKE CC="$(CC)" CFLAGS="$(CFLAGS)" generic 
	@cp $</$(notdir $@) "$@"
	@strip "$@"
	
$(DSK): $(BIN) $(M0D) $(DISKTO)
$(M0D): $(LUA) tools/mod2m0d.lua Makefile
$(BIN): $(C6809) Makefile

tools/%$(EXE): trackdisk/%.c
	$(CC) $(CFLAGS) -o "$@" "$<"
	@sleep 1 && strip "$@"

tools/%$(EXE): c6809/%.c
	$(CC) $(CFLAGS) -o "$@" "$<"
	@sleep 1 && strip "$@"

m0ds/%.m0d: mods/*/%.param
m0ds/%.m0d: mods/*/%.[mM][oO][dD]
	@echo
	@$(LUA) tools/mod2m0d.lua "-o$@" "$<" `cat 2>/dev/null "mod/*/$*.param"` -org=0x$(M0D_ORG)

bin/%.bin: trackdisk/asm/%.ASS
	-$(C6809) -c -bh -am -oOP "$<" "$@"
bin/%.bin: asm/%.ass
	-$(C6809) -c -bh -am -oOP "$<" "$@" '-dsong=$$$(M0D_ORG)'

%.fd: %.manifest
	$(DISKTO) "$<" "$*" 

test: $(DSK)
	 tools/teo/teow$(EXE) --reset --window --memo=`cygpath -w -s "$(PWD)/../teo/MASS6809.M7"` --disk0=`cygpath -w -s "$(PWD)/$<"`

test2: $(DSK)
	 ../teo/teow$(EXE) -window -m MASS6809.M7 -disk0 `cygpath -w -s "$(PWD)/$<"`

TEODIR=../../TEO_WIN_187_BETA3_20220907/
tst: $(DSK)
	cp $(DSK:%.fd=%.sap) $(TEODIR)/disk.sap
	cd $(TEODIR) && ./teo_win32_allegro.exe -r -0 disk.sap
