MAIN=elvisliv

DISK=$(MAIN).sap

ifeq ($(OS),Windows_NT)
EXE=.exe
else
EXE=
endif

C6809=../../c6809/c6809$(EXE)
SAPFS=../../sapfs/sapfs$(EXE)
EXOBIN=../../exobin/exobin.buggy$(EXE)
MP2XMP=../../exobin/map2xmp$(EXE)
TEODIR=../../TEO_WIN_187_BETA3_20220907/

ALL=$(wildcard *.ass)
BIN=$(ALL:%.ass=build/%.BIN)
IMAGES=xIMG01.xmp xIMG02.xmp xIMG03.xmp xIMG04.xmp xIMG05.xmp xIMG05a.xmp xIMG06.xmp\
xIMG07.xmp xIMG08.xmp xIMG09.xmp xIMG10.xmp xIMG11.xmp xIMG12.xmp \
xIMG15.xmp xIMG16.xmp xIMG17.xmp xIMG18.xmp xIMG19.xmp xIMG20.xmp \
xIMG21.xmp xIMG22.xmp xIMG23.xmp xIMG24.xmp xIMG25.xmp xIMG26.xmp xIMG27.xmp \
xIMG28.xmp xIMG29.xmp xIMG30.xmp xIMG31.xmp xIMG32.xmp xIMG33.xmp xIMG34.xmp \
xIMG35.xmp xIMG36.xmp xIMG38.xmp xIMG39.xmp
IMAGES:=$(IMAGES:%=build/%)
# xIMG13.xmp xIMG14.xmp xIMG37.xmp 

all: compile fill_sapdir

compile: $(C6809) $(SAPFS) $(MP2XMP)  $(BIN) $(IMAGES) 

list:	compile
	less codes.lst

clean: 
	rm -rf build sapdir  $(DISK)
	
build/%.EXO: build/%.BIN
	$(EXOBIN) -x "$<"
	
build/%.BIN: %.ass		
	test -d build || mkdir -p build
	cd build && ../$(C6809) -c -am -oOP ../$< `echo ../$@ | tr a-z A-Z` 

build/x%.map: img/%.png
	-cd build && perl ../img_to7_9exp.pl ../$<
build/x%.map: img/%.gif
	-cd build && perl ../img_to7_9exp.pl ../$<
build/x%.map: img/%.jpg
	-cd build && perl ../img_to7_9exp.pl ../$<
build/%.xmp: build/%.map
	$(MP2XMP) $<
	
#main.asm: rotozoom.ass
#	sh inline_inc.sh $@ $< >$@_
#	mv $@_ $@
#	../windows/c6809.exe -am -c -oOP/CM $@ $*.bin
	
build/AUTO.BIN: build/elvisliv.BIN
	cp "$<" "$@"

$(SAPFS): 
	cd $(dir $@) && make "CC=$(CC) -Dlinux" sapfs

$(EXOBIN): 
	cd $(dir $@) && make $(notdir $(EXOBIN))
	
$(MP2XMP): 
	cd $(dir $@) && make $(notdir $(MP2XMP))

%$(EXE): %.c
	$(CC) "$<" -Ofast -o "$@"
	
fill_sapdir: build/AUTO.BIN
	test -d build/sapdir || mkdir -p build/sapdir
	cp intro/* build/sapdir
	cp build/*.xmp build/sapdir
	cp build/elvisliv.BIN build/sapdir/AUTO.BIN
	cp empty_disk/bootbk.sap $(DISK)
	# $(SAPFS) -c $(DISK)
	$(SAPFS) -a $(DISK) build/sapdir/*

test: all $(DISK)
	cp $(DISK) $(TEODIR)/disk.sap
	cd $(TEODIR) && ./teo_win32_allegro.exe -r -0 disk.sap