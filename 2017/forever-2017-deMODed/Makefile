CC=gcc -s -O3

MANIFEST=$(wildcard *.manifest)
DSK=$(MANIFEST:%.manifest=%.fd)
SAP=$(DSK:.fd=_0.sap)	

ASM=$(wildcard asm/*.ass) $(wildcard trackdisk/asm/*.ASS)

BIN:=$(ASM:asm/%.ass=bin/%.bin)
BIN:=$(BIN:trackdisk/asm/%.ASS=bin/%.bin)

M0D=$(shell ls mod/*.[mM][oO][dD] | sed 's%mod/\(.*\).mod%m0d/\1.m0d%i')
M0D_ORG=6B00
M0D_SPLIT=$(shell ls mod/*.[mM][oO][dD] | sed 's%mod/\(.*\).mod%m0d/\1_$(M0D_ORG).m0d%i')

LUA=tools/lua52.exe
C6809=tools/c6809.exe
SPLITM0D=tools/splitm0d.exe
CREATEDISK=tools/createdisk.exe

ALL=$(DSK)

all: $(ALL)
	ls -l $(DSK)
	
z:
	@echo '$(MOD)'
	@echo '$(M0D)'
	@echo '$(M0D_SPLIT)'

sap: $(SAP)
	
clean:
	-rm 2>/dev/null *.fd *.sap codes.lst *.ASM *.stackdump
	
fullclean: clean
	-rm 2>/dev/null m0d/* bin/* $(C6809) $(SPLITM0D) $(CREATEDISK)
	-cd lua52/src && make -f Makefile.std clean && $(RM) lua$(EXE) luac$(EXE)
	
norm:
	@for i in mod/*; do case $$i in *\ *) mv -v "$$i" `echo "$$i" | tr ' ' '_'`;; esac; done
	
tgz: fullclean
	@tar czf `basename "$(PWD)"`.tgz . --exclude=*.zip --exclude=tools/teo --exclude=*.tgz --exclude=dc* --exclude=*/attic/*
	@tar tvf `basename "$(PWD)"`.tgz
	@du `basename "$(PWD)"`.tgz

gz: $(SAP)
	-@rm *.sap.gz *.fd.gz
	gzip *.sap *.fd
	
$(LUA): lua52/src $(wildcard lua52/src/*)
	@echo Compining "$@" ...
	@cd $< && export MAKE="make -f Makefile" && $$MAKE CC="$(CC)" CFLAGS="$(CFLAGS)" generic 
	@test -e $</$(notdir $@) && cp $</$(notdir $@) "$@" || cp $</lua "$@"
	@strip "$@"
	
lua52/src:
	test -d lua52 || mkdir lua52
	wget -q https://www.lua.org/ftp/lua-5.2.4.tar.gz -O - | tar xvzf - --strip-components=1 -Clua52/ 

$(DSK): $(BIN) $(M0D) $(M0D_SPLIT) $(CREATEDISK)
$(SAP): $(DSK)
$(M0D_SPLIT): $(SPLITM0D) tools/mod2m0d.lua Makefile
$(BIN): $(C6809) Makefile

tools/%$(EXE): trackdisk/%.c
	$(CC) $(CFLAGS) -o "$@" "$<"
	@sleep 1 && strip "$@"

tools/%$(EXE): c6809/%.c
	$(CC) $(CFLAGS) -o "$@" "$<"
	@sleep 1 && strip "$@"

bin/menu.bin: $(LUA) m0d/menu.m0d bin/list.bin img/menu.map img/info.map

bin/list.bin: deMODed.manifest tools/manifest2list.lua $(LUA) 
	$(LUA) tools/manifest2list.lua "$<" "$@"

# ftp://ftp.modland.com/pub/favourites/Protracker/Chrono/
# Chrono/S!P
m0d/menu.m0d: mod/supershort.mod
	$(LUA) tools/mod2m0d.lua "-o$@" "$<" -org=0xAB00 -volume=12 -border=nil

tools/%.exe: trackdisk/%.c
	$(CC) -o "$@" "$<"

tools/%.exe: c6809/%.c
	$(CC) -o "$@" "$<"

m0d/%.m0d: mod/%.mod  
	@echo
	$(LUA) tools/mod2m0d.lua "-o$@" "$<" `cat 2>/dev/null "mod/$*.param"` -org=0x$(M0D_ORG)
m0d/%.m0d: mod/%.MOD
	@echo
	$(LUA) tools/mod2m0d.lua "-o$@" "$<" `cat 2>/dev/null "mod/$*.param"` -org=0x$(M0D_ORG)
m0d/%.m0d: mod/%.Mod
	@echo
	$(LUA) tools/mod2m0d.lua "-o$@" "$<" `cat 2>/dev/null "mod/$*.param"` -org=0x$(M0D_ORG)
m0d/%_$(M0D_ORG).m0d: m0d/%.m0d
	$(SPLITM0D) "$<"

bin/%.bin: trackdisk/asm/%.ASS
	-$(C6809) -c -bh -am -oOP "$<" "$@"
bin/%.bin: asm/%.ass
	-$(C6809) -c -bh -am -oOP "$<" "$@"

%.fd: %.manifest
	$(CREATEDISK) "$<" "$@" 

%_0.sap: %.manifest
	$(CREATEDISK) "$<" "$*.sap" 

test: $(SAP)
	 tools/teo/teow.exe --reset --window --memo=`cygpath -w -s "$(PWD)/../teo/MASS6809.M7"` --disk0=`cygpath -w -s "$(PWD)/deMODed_0.sap"` --disk1=`cygpath -w -s "$(PWD)/deMODed_1.sap"`

test2: $(DSK)
	 ../teo/teow.exe -window -m MASS6809.M7 -disk0 `cygpath -w -s "$(PWD)/$<"`
	
TEODIR=../../TEO_WIN_187_BETA3_20220907/
tst: $(DSK)
	cp $(DSK:%.fd=%_0.sap) $(TEODIR)/disk0.sap
	cp $(DSK:%.fd=%_1.sap) $(TEODIR)/disk1.sap
	cd $(TEODIR) && ./teo_win32_allegro.exe -r -0 disk0.sap -1 disk1.sap
