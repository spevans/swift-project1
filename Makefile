TOPDIR := .
include $(TOPDIR)/Makedefs

KERNEL_OBJS := kernel/kernel.o fakelib/fakelib.o


ifeq ($(UNAME_S), Darwin)
	LINKER := static_linker/build/Debug/static_linker
endif

SUBDIRS := boot kernel fakelib utils


.PHONY: clean

all: output/boot-hd.img

output/kernel.elf:
	mkdir -p $(MODULE_DIR) output
	set -e; for dir in $(SUBDIRS); do $(MAKE) -C $$dir; done
ifeq ($(UNAME_S), Linux)
	# initial link must be via ELF to produce a GOT
	ld --no-demangle -static -Tlinker.script -Map=output/kernel.map -o output/kernel.elf $(KERNEL_OBJS) $(SWIFTLIB)

output/kernel.bin: output/kernel.elf
	objcopy -O binary $^ $@
	utils/foverride $@ output/kernel.map _swift_stdlib_putchar_unlocked putchar
	objdump -D output/kernel.elf > output/kernel.dmp
endif

ifeq ($(UNAME_S), Darwin)
	$(LINKER) --output=$@ --baseAddress=0x100000 --mapfile=kernel.map $(KERNEL_OBJS) $(SWIFTLIB)
endif

output/kernel.efi: boot output/kernel.bin
	objcopy	-I binary -O elf64-x86-64 -B i386:x86-64 output/kernel.bin output/kernel.bin.obj
	ld --no-demangle -static -Tboot/efi_linker.script -Map=output/efi_body.map -o output/efi_body.bin boot/efi_entry.o boot/efi_main.o
	utils/efi_patch boot/efi_header.bin output/efi_body.bin output/kernel.efi


output/boot-hd.img: boot output/kernel.bin
	utils/mkdiskimg boot/bootsector.bin boot/boot16to64.bin output/kernel.bin output/boot-hd.img

test:
	make -C kernel/klib
	make -C tests

iso: output/boot-cd.iso

output/boot-cd.iso: output/boot-hd.img output/kernel.efi
	rm -rf output/iso_tmp output/boot-cd.iso output/efi.img
	mkdir -p output/iso_tmp/efi/boot output/iso_tmp/boot
	cp output/boot-hd.img output/iso_tmp/boot.img
	cp output/kernel.efi output/iso_tmp/efi/boot/bootx64.efi
	/sbin/mkfs.msdos -C output/iso_tmp/boot/efi.img 10240
	mmd -i output/iso_tmp/boot/efi.img ::efi
	mmd -i output/iso_tmp/boot/efi.img ::efi/boot
	mcopy -i output/iso_tmp/boot/efi.img output/kernel.efi ::efi/boot
	# uncomment line below to make bootable EFI ISO
	mcopy -i output/iso_tmp/boot/efi.img output/kernel.efi ::efi/boot/bootx64.efi
	xorrisofs -J -joliet-long -cache-inodes -isohybrid-mbr isohdppx.bin 	 \
	-b boot.img -c boot.cat -boot-load-size 4 -boot-info-table -no-emul-boot \
	-eltorito-alt-boot -e boot/efi.img -no-emul-boot -isohybrid-gpt-basdat 	 \
	-isohybrid-apm-hfsplus -o output/boot-cd.iso output/iso_tmp
	rm -r output/iso_tmp

clean:
	rm -rf output/*
	set -e; for dir in $(SUBDIRS); do $(MAKE) -C $$dir clean; done
	make -C tests clean
