.PHONY=all tests clean obj update
CXX=g++
CC=gcc

GMATCH=$(findstring g++,$(CXX))

CLHASH_CHECKOUT = "&& git checkout master"
WARNINGS=-Wall -Wextra -Wno-char-subscripts \
		 -Wpointer-arith -Wwrite-strings -Wdisabled-optimization \
		 -Wformat -Wcast-align -Wno-unused-function -Wno-unused-parameter \
		 -pedantic -DUSE_PDQSORT -Wunused-variable \
		-Wduplicated-branches -Wdangling-else  # -Wconversion
ifndef EXTRA
	EXTRA:=
endif
ifndef INCPLUS
	INCPLUS:=
endif
ifndef EXTRA_LD
	EXTRA_LD:=
endif
DBG:=
OS:=$(shell uname)
FLAGS=

OPT_MINUS_OPENMP= -O3 -funroll-loops\
	  -pipe -fno-strict-aliasing -march=native -mpclmul $(FLAGS) $(EXTRA)
OPT=$(OPT_MINUS_OPENMP) -fopenmp
XXFLAGS=-fno-rtti
CXXFLAGS=$(OPT) $(XXFLAGS) -std=c++17 $(WARNINGS)
CXXFLAGS_MINUS_OPENMP=$(OPT_MINUS_OPENMP) $(XXFLAGS) -std=c++1z $(WARNINGS) -Wno-cast-align -Wno-gnu-zero-variadic-macro-arguments
CCFLAGS=$(OPT) $(CFLAGS) -std=c11 $(WARNINGS)
LIB=-lz
LD=-L. $(EXTRA_LD)

ifneq (,$(findstring g++,$(CXX)))
	ifeq ($(shell uname),Darwin)
		ifeq (,$(findstring clang,$(CXX)))
			POPCNT_CXX:=clang
		else
			POPCNT_CXX:=$(CXX)
		endif
	else
		POPCNT_CXX:=$(CXX)
	endif
endif

OBJS=$(patsubst %.c,%.o,$(wildcard src/*.c) bonsai/klib/kthread.o) $(patsubst %.cpp,%.o,$(wildcard src/*.cpp)) bonsai/klib/kstring.o clhash.o
DOBJS=$(patsubst %.c,%.do,$(wildcard src/*.c) bonsai/klib/kthread.o) $(patsubst %.cpp,%.do,$(wildcard src/*.cpp)) bonsai/klib/kstring.o clhash.o
ZOBJS=$(patsubst %.c,%.zo,$(wildcard src/*.c) bonsai/klib/kthread.o) $(patsubst %.cpp,%.zo,$(wildcard src/*.cpp)) bonsai/klib/kstring.o clhash.o

TEST_OBJS=$(patsubst %.cpp,%.o,$(wildcard test/*.cpp))
ZTEST_OBJS=$(patsubst %.cpp,%.zo,$(wildcard test/*.cpp))

EXEC_OBJS=$(patsubst %.cpp,%.o,$(wildcard bin/*.cpp))
ZW_OBJS=$(patsubst %.c,%.o,$(wildcard ../zstd/zlibWrapper/*.c)) libzstd.a

EX=$(patsubst src/%.cpp,%,$(wildcard src/*.cpp))


ZSTD_INCLUDE_DIRS=bonsai/zstd/zlibWrapper bonsai/zstd/lib/common bonsai/zstd/lib
ZSTD_INCLUDE=$(patsubst %,-I%,$(ZSTD_INCLUDE_DIRS))
ZFLAGS=-DZWRAP_USE_ZSTD=1
ZCOMPILE_FLAGS= $(ZFLAGS) -lzstd
ALL_ZOBJS=$(ZOBJS) $(ZW_OBJS)
INCLUDE=-Ibonsai/clhash/include -I.  -Ibonsai/libpopcnt -Iinclude -Ibonsai/circularqueue $(ZSTD_INCLUDE) $(INCPLUS) -Ibonsai/hll/vec -Ibonsai/pdqsort -Ibonsai -Ibonsai/bonsai/include/



all: $(EX)

update:
	for i in circularqueue clhash cppitertools hll klib kraken kspp libpopcnt linear pdqsort tinythreadpp zstd; \
        do cd ../$$i && git checkout master && git pull && cd ../bonsai; \
    done

libzstd.a:
	cd bonsai/bonsai && make libzstd.a && cp libzstd.a ../../

bonsai/klib/kstring.o:
	cd bonsai/bonsai && make ../klib/kstring.o && cd ../.. && \
	cd bonsai/bonsai && make ../klib/kthread.o && cd ../..

bonsai/bonsai/clhash.o:
	cd bonsai/bonsai && make clhash.o && cd ../..

OBJ=bonsai/klib/kstring.o bonsai/klib/kthread.o bonsai/bonsai/clhash.o

test/%.o: test/%.cpp
	$(CXX) $(CXXFLAGS) $(DBG) $(INCLUDE) $(LD) -c $< -o $@ $(LIB)

test/%.zo: test/%.cpp
	$(CXX) $(CXXFLAGS) $(DBG) $(INCLUDE) $(LD) -c $< -o $@ $(ZCOMPILE_FLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(DBG) $(INCLUDE) $(LD) -DNDEBUG -c $< -o $@ $(LIB)

%.do: %.cpp
	$(CXX) $(CXXFLAGS) $(DBG) $(INCLUDE) $(LD) -c $< -o $@ $(LIB)

%: src/%.cpp libzstd.a $(OBJ)
	$(CXX) $(CXXFLAGS) $(DBG) $(INCLUDE) $(LD) $(OBJ) -DNDEBUG $< -o $@ $(LIB)

%_s: src/%.cpp libzstd.a
	$(CXX) $(CXXFLAGS) $(DBG) $(INCLUDE) $(LD) $(OBJ) -static-libstdc++ -static-libgcc -DNDEBUG $< -o $@ $(LIB)

#%_z: src/%.cpp $(ALL_ZOBJS)
#	$(CXX) $(CXXFLAGS) $(DBG) $(INCLUDE) $(LD) $(ALL_ZOBJS) -DNDEBUG $< -o $@ $(ZCOMPILE_FLAGS) $(LIB)
#
#%_sz: src/%.cpp $(ALL_ZOBJS)
#	$(CXX) $(CXXFLAGS) $(DBG) $(INCLUDE) $(LD) $(ALL_ZOBJS) -static-libstdc++ -static-libgcc -DNDEBUG $< -o $@ $(ZCOMPILE_FLAGS) $(LIB)
#
#%_d: src/%.cpp $(DOBJS)
#	$(CXX) $(CXXFLAGS) $(DBG) $(INCLUDE) $(LD) $(DOBJS) $< -o $@ $(LIB)

clean:
	echo 'This needs to be written!'

mostlyclean:
	rm -f $(ZOBJS) $(ZTEST_OBJS) $(ZW_OBJS) $(OBJS) $(DEX) $(ZEX) $(EX) $(TEST_OBJS) $(DOBJS) unit lib/*o src/*o