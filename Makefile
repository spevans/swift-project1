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

iso: boot-hd.img
	rm -rf iso_tmp boot-cd.iso efi.img
	mkdir -p iso_tmp/efi/boot iso_tmp/boot
	cp boot-hd.img iso_tmp/boot.img
	#cp boot/efi-test.efi iso_tmp/efi/boot
	cp boot/efi_header.efi iso_tmp/efi/boot/bootx64.efi
	/sbin/mkfs.msdos -C iso_tmp/boot/efi.img 240
	mmd -i iso_tmp/boot/efi.img ::efi
	mmd -i iso_tmp/boot/efi.img ::efi/boot
	mcopy -i iso_tmp/boot/efi.img boot/efi_header.efi ::efi/boot
	#mcopy -i iso_tmp/boot/efi.img boot/efi-test.efi ::efi-test.efi
	#mcopy -i iso_tmp/boot/efi.img boot/efi-header.efi ::efi/boot/bootx64.efi
	#mcopy -i iso_tmp/boot/efi.img boot/efi-test.efi ::efi/boot/bootx64.efi
	xorrisofs -J -joliet-long -cache-inodes -isohybrid-mbr isohdppx.bin 	 \
	-b boot.img -c boot.cat -boot-load-size 4 -boot-info-table -no-emul-boot \
	-eltorito-alt-boot -e boot/efi.img -no-emul-boot -isohybrid-gpt-basdat 	 \
	-isohybrid-apm-hfsplus -o boot-cd.iso iso_tmp

clean:
	rm -f boot-hd.img boot-cd.iso kernel.elf kernel.bin kernel.map kernel.dmp
	rm -rf iso_tmp
	set -e; for dir in $(SUBDIRS); do $(MAKE) -C $$dir clean; done
	make -C tests clean
