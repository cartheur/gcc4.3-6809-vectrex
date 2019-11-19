CC=/usr/local/libexec/gcc/m6809-unknown-none/4.3.[46]/cc1
CXX=/usr/local/libexec/gcc/m6809-unknown-none/4.3.[46]/cc1plus
#CFLAGS= -Os -g 
#CFLAGS= -O3 -mint8 -msoft-reg-count=0
CFLAGS = -O3 -quiet -fno-gcse -fno-toplevel-reorder -fverbose-asm -W -Wall -Wextra -Wconversion -Werror -Wno-comment -Wno-unused-parameter -Wno-return-type -fomit-frame-pointer -mint8 -msoft-reg-count=0 -fno-time-report -fdiagnostics-show-option
# These includes may modify CFLAGS
include make/6809.mk
include make/g++.mk
include make/gcc.mk

AS=/usr/local/bin/as6809
AFLAGS=-l -og -sy

LN=/usr/local/bin/aslink
LFLAGS= -m -u -ws -b .text=0x0 

BINS  = pong.bin
OBJS  = $(BINS:.bin=.o) crt0.o
CRT0  = $(BINS:.bin=crt0.o)
RELS  = $(BINS:.bin=.rel)
LSTS  = $(BINS:.bin=.lst)
LSTS += $(BINS:.bin=crt0.lst)
CLST  = $(BINS:.bin=crt0.lst)
RSTS  = $(BINS:.bin=.rst)
RSTS += $(BINS:.bin=crt0.rst)
HLRS  = $(BINS:.bin=.hlr)
HLRS += $(BINS:.bin=crt0.hlr)
MAPS  = $(BINS:.bin=.map)
ROMS  = $(BINS:.bin=.rom)
RAMS  = $(BINS:.bin=.ram)
SYMS  = $(BINS:.bin=.sym)
SYMS += $(BINS:.bin=crt0.sym)
ASRC  = $(BINS:.bin=.s)
ASRC += $(BINS:.bin=crt0.s)
S19S  = $(BINS:.bin=.s19)
S19S += $(BINS:.bin=_ram.s19)

CLEAN_LIST= $(S19S) $(CRT0) $(ASRC) $(OBJS) $(RELS) $(LSTS) $(CLST) $(RSTS) $(MAPS) *~ $(RAMS) $(ROMS) $(SYMS) $(BINS) $(HLRS)

.PHONY: clean all

all: $(BINS)

clean:
	$(RM) $(CLEAN_LIST)

%.bin: %.s19 %_ram.s19
	# Extract ram section into .ram
	srec_cat $*_ram.s19 -offset -0xc880 -o $*.ram -binary || echo -n
	@touch $*.ram
	# Extract rom section into .rom
	srec_cat $*.s19 -o $*.rom -binary
	# Concatenate .rom and .ram into .bin
	cat $*.rom $*.ram > $*.bin

# Link .o files
%.s19 %_ram.s19: %.o %crt0.o
	# Link .o files to .s19, _ram.s19, .rst, .map
	$(LN) $(LFLAGS) $*.s19 $*crt0.o $*.o

# Produce .o from .asm
%.o: %.asm
	# Assemble .asm to .rel
	$(AS) $(AFLAGS) $<
	mv $*.rel $*.o

# Produce .asm from crt0.tpl (template) by replacing placeholders with target base name
%.asm:
	cat make/crt0.tpl | sed -e s/XXX/`echo $* | sed -e "s/crt0//" | tr '[:lower:]' '[:upper:]'`/ > $*.asm

# Is this useful?
# .s.o:
# 	$(AS) $(AFLAGS) $<
# 	mv $*.rel $*.o

%.o: src/%.c
	$(CC) $< -dumpbase $* $(CFLAGS) -auxbase $* -o $*.s
	$(AS) $(AFLAGS) $*.s
	mv $*.rel $*.o

%.o: src/%.cpp
	# Compile .cpp to asm file (.s)
	$(CXX) $< -dumpbase $* $(CFLAGS) -auxbase $* -o $*.s
	# Assemble .s to .rel, .lst, .hlr, .sym
	$(AS) $(AFLAGS) $*.s
	# Rename .rel to .o
	mv $*.rel $*.o
