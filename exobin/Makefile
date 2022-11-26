EXO2=magli143-exomizer-bcf43222703e/src
VPATH=.:$(EXO2)/
ifeq ($(OS),Windows_NT)
	EXE=.exe
else
	EXE=
endif

ALL=exobin$(EXE) map2xmp$(EXE)

all: $(ALL)

clean: myclean

include $(EXO2)/Makefile

CC:=$(CC) -I$(EXO2)/

MAP_OBJS = match.o search.o optimal.o output.o membuf_io.o \
           chunkpool.o radix.o exo_helper.o exodec.o progress.o exo_util.o vec.o \
	   map2xmp.o
BIN_OBJS = match.o search.o optimal.o output.o membuf_io.o \
           chunkpool.o radix.o exo_helper.o exodec.o progress.o exo_util.o vec.o \
	   exobin.o
	   
map2xmp$(EXE): deps $(MAP_OBJS) $(SHARED_OBJS)
	@echo "Linking $@"
	@$(CC) $(LDFLAGS) -o $@ $(MAP_OBJS) $(SHARED_OBJS)

exobin$(EXE): deps $(BIN_OBJS) $(SHARED_OBJS)
	@echo "Linking $@"
	@$(CC) $(LDFLAGS) -o $@ $(BIN_OBJS) $(SHARED_OBJS)

myclean:
	-@$(RM) $(MAP_OBJS) $(BIN_OBJS) $(SHARED_OBJS)  $(ALL)
	-@$(MAKE) -f $(EXO2)/Makefile clean
