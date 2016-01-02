TOPDIR := .
include $(TOPDIR)/Makedefs

KERNEL_OBJS := kernel/kernel.o fakelib/fakelib.o


ifeq ($(UNAME_S), Darwin)
	LINKER := static_linker/build/Debug/static_linker
endif

SUBDIRS := boot kernel fakelib


.PHONY: kernel.bin clean

all: kernel.bin disk_image

kernel.bin:
	mkdir -p $(MODULE_DIR)
	set -e; for dir in $(SUBDIRS); do $(MAKE) -C $$dir; done
ifeq ($(UNAME_S), Linux)
	# initial link must be via ELF to produce a GOT
	ld --no-demangle -static -Tlinker.script -Map=kernel.map -o kernel.elf $(KERNEL_OBJS) $(SWIFTLIB)
	objcopy -O binary kernel.elf kernel.bin
endif

ifeq ($(UNAME_S), Darwin)
	$(LINKER) --output=$@ --baseAddress=0x100000 --mapfile=kernel.map $(KERNEL_OBJS) $(SWIFTLIB)
endif

disk_image: boot kernel.bin
	$(SWIFT) utils/mkdiskimg.swift boot/bootsector.bin boot/boot16to64.bin kernel.bin disk_image

clean:
	rm -f disk_image kernel.elf kernel.bin kernel.map
	set -e; for dir in $(SUBDIRS); do $(MAKE) -C $$dir clean; done
	make -C tests clean
