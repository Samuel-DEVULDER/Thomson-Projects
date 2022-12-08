# EXO2=magli143-exomizer-bcf43222703e/src
EXO2=exomizer2/src
VPATH=.:$(EXO2)/
ifeq ($(OS),Windows_NT)
	EXE=.exe
else
	EXE=
endif

ALL=exobin$(EXE) exobin.buggy$(EXE) map2xmp$(EXE)

all: $(ALL)

clean: myclean

include $(EXO2)/Makefile

CC:=$(CC) -I$(EXO2)/

OBJS = match.o search.o optimal.o output.o membuf_io.o \
       chunkpool.o radix.o exo_helper.o exodec.o progress.o \
	   exo_util.o vec.o 
	   
%.o: $(EXO2)%.c
	cd $(EXO2) && make $< && cp $< ..
	   
%$(EXE): %.o deps $(OBJS) $(SHARED_OBJS)
	@echo "Linking $@"
	@$(CC) $(LDFLAGS) -o $@ $< $(OBJS) $(SHARED_OBJS)

myclean:
	-@$(RM) $(BIN) $(SHARED_OBJS) $(ALL:$(EXE)=.o) $(ALL)
	-@cd $(EXO2) && $(MAKE) -f Makefile clean
