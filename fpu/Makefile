ALL=$(wildcard *.ass)
DISK=disk.sap
K7=$(DISK:.sap=.k7)
IMAGES=

all: compile fill_sapdir w

compile: $(IMAGES) $(ALL:.ass=.BIN)

list:	compile
	less codes.lst

clean: 
	rm *.BIN

%.BIN: %.ass tools/c6809.exe
	tools/c6809.exe -c -bh -am -oOP $< `echo $@|tr a-z A-Z`
	
tools/%.exe: c6809/%.c
	gcc -O3 -fomit-frame-pointer "$<" -o "$@"
	
$(DISK): fill_sapdir
	tools/sapfs -c $@
	tools/sapfs -a $@ sapdir
	
$(K7): 
	echo >$@ -n

fill_sapdir: compile
	-mkdir sapdir
	-rm *.fd *.FD
	-cp *.EXO sapdir
	-cp *.BAS sapdir
	-cp *.BAT sapdir
	-cp *.ASM sapdir
	-cp *.BIN sapdir

w:	$(DISK) $(K7)
	../teo/teow.exe -window -m MASS6809.M7 -disk0 `cygpath -w -s "$(PWD)/$(DISK)"`
	cd sapdir && ../tools/sapfs.exe --extract-all ../$(DISK)
