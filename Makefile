TOPDIR := .
include $(TOPDIR)/Makedefs

KERNEL_OBJS := kernel/kernel.o fakelib/fakelib.o


ifeq ($(UNAME_S), Darwin)
	LINKER := static_linker/build/Debug/static_linker
endif

SUBDIRS := boot kernel fakelib utils


.PHONY: clean

all: boot-hd.img

kernel.elf:
	mkdir -p $(MODULE_DIR)
	set -e; for dir in $(SUBDIRS); do $(MAKE) -C $$dir; done
ifeq ($(UNAME_S), Linux)
	# initial link must be via ELF to produce a GOT
	ld --no-demangle -static -Tlinker.script -Map=kernel.map -o kernel.elf $(KERNEL_OBJS) $(SWIFTLIB)

kernel.bin: kernel.elf
	objcopy -O binary kernel.elf kernel.bin
	objdump -D kernel.elf > kernel.dmp
endif

ifeq ($(UNAME_S), Darwin)
	$(LINKER) --output=$@ --baseAddress=0x100000 --mapfile=kernel.map $(KERNEL_OBJS) $(SWIFTLIB)
endif

boot-hd.img: boot kernel.bin
	utils/mkdiskimg boot/bootsector.bin boot/boot16to64.bin kernel.bin boot-hd.img

test:
	make -C kernel/klib
	make -C tests

iso: boot-cd.iso

boot-cd.iso: boot-hd.img
	rm -rf iso_tmp test.iso
	mkdir -p iso_tmp
	cp boot-hd.img iso_tmp/boot.img
	genisoimage -U -A "project1" -V "project1" -volset "project1" -J -joliet-long \
		-r -v -T  -b boot.img -c boot.cat -no-emul-boot -boot-load-size 4 \
		-boot-info-table -o boot-cd.iso iso_tmp

clean:
	rm -f boot-hd.img boot-cd.iso kernel.elf kernel.bin kernel.map kernel.dmp
	rm -rf iso_tmp
	set -e; for dir in $(SUBDIRS); do $(MAKE) -C $$dir clean; done
	make -C tests clean
