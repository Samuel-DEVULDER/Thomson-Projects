DISK=disk.sap

ALL=$(wildcard *.ass)

all: compile $(DISK)

compile: tools/c6809.exe $(ALL:.ass=.BIN)

list:	compile
	less codes.lst

clean: 
	rm *.BIN *.ASM

%.BIN: %.ass 
	tools/c6809.exe -c -bh -am -oOP $< `echo $@|tr a-z A-Z`
	
tools/%.exe: ../c6809/%.c
	gcc -O3 -fomit-frame-pointer "$<" -o "$@"
	
$(DISK): fill_sapdir
	tools/sapfs -c $@
	tools/sapfs -a $@ sapdir

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
