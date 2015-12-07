UNAME_S := $(shell uname -s)

KERNEL_OBJS := kernel.o klib.o startup.o

ifeq ($(UNAME_S), Linux)
	SWIFTC := /home/spse/swift-2.2-SNAPSHOT-2015-12-01-b-ubuntu14.04/usr/bin/swiftc
	NASM_OBJ_FLAGS := -felf64
	# initial link must be via ELF to produce a GOT
#	LINKER_CMD := ld -static -Tlinker_script1 -o kernel_prebin.o kernel.o startup.o /home/spse/swift-2.2-SNAPSHOT-2015-12-01-b-ubuntu14.04/usr/lib/swift_static/linux/libswiftCore.a klib.o -Map=kernel2.map && ld  -T linker.script -Map=kernel.map -o kernel.bin
	LINKER_CMD := ld -static -Tlinker.script -Map=kernel.map -o kernel.elf
endif

ifeq ($(UNAME_S), Darwin)
	SWIFTC := /usr/bin/swiftc
	NASM_OBJ_FLAGS := -fmacho64
	LINKER := ../static_linker/build/Debug/static_linker
	LINKER_CMD := $(LINKER) --output=$@ --baseAddress=0x100000 --mapfile=kernel.map kernel.o startup.o klib.o ../libswiftCore.dylib
	KERNEL_OBJS := $(KERNEL_OBJS) $(LINKER)
endif


CFLAGS := -Wall -Wextra -Werror -fno-builtin -fno-stack-protector -O2


all: disk_image

%.o: %.c
	clang $(CFLAGS) -S -o $(patsubst %.o,%.s,$@) $<
	clang $(CFLAGS) -c -o $@ $<

bootsector.bin : bootsector.asm
	nasm -fbin -o $@ $<

boot16to64.bin : boot16to64.asm utils.asm a20.asm cpu_check.asm page_tables.asm pmode_loader.asm
	nasm -fbin -o $@ $<

startup.o: startup.swift
	$(SWIFTC) -emit-object -parse-as-library -o startup.o startup.swift
	$(SWIFTC) -emit-assembly -parse-as-library -o startup.s startup.swift

kernel.o: kernel.asm
	nasm $(NASM_OBJ_FLAGS) -o $@ $<

klib.o: libc.o libcpp.o libobj.o tty.o
	ld -r -no_eh_labels -o $@ $^



kernel.bin: $(KERNEL_OBJS)
ifeq ($(UNAME_S), Linux)
	ld -static -Tlinker.script -Map=kernel.map -o kernel.elf
	objcopy -O binary kernel.elf kernel.bin
endif

ifeq ($(UNAME_S), Darwin)
	$(LINKER) --output=$@ --baseAddress=0x100000 --mapfile=kernel.map kernel.o startup.o klib.o ../libswiftCore.dylib
endif

disk_image : bootsector.bin boot16to64.bin kernel.bin
	./mkdiskimg.swift bootsector.bin boot16to64.bin kernel.bin disk_image

clean:
	rm -f *.bin *.o *.s disk_image kernel.map kernel.elf
