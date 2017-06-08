TOPDIR := .
include $(TOPDIR)/Makedefs

KERNEL_OBJS := kernel/kernel.o klibc/klibc.o
SUBDIRS := boot kernel klibc utils
EXTRA_LIBS := $(SWIFTDIR)/usr/lib/swift/clang/lib/linux/libclang_rt.builtins-x86_64.a

.PHONY: clean kernel

all: kernel output/boot-hd.img

kernel:
ifneq ($(UNAME_S), Linux)
	@echo This only builds on linux && exit 1
endif
	mkdir -p $(MODULE_DIR) output
	set -e; for dir in $(SUBDIRS); do $(MAKE) -C $$dir; done
	# initial link must be via ELF to produce a GOT
	ld --no-demangle -static -Tlinker.script -Map=output/kernel.map -o output/kernel.elf $(KERNEL_OBJS) $(SWIFTLIBS) $(EXTRA_LIBS)

output/kernel.elf: kernel

output/kernel.bin: output/kernel.elf
	objcopy -O binary $^ $@
	#utils/foverride $@ output/kernel.map _swift_stdlib_putchar_unlocked putchar
	(objdump -d output/kernel.elf -Mintel | $(SWIFT)-demangle > output/kernel.dmp) &


output/kernel.efi: output/kernel.bin boot/efi_entry.asm boot/efi_main.c klibc/kprintf.c
	make -C boot
	objcopy	-I binary -O elf64-x86-64 -B i386:x86-64 output/kernel.bin output/kernel.bin.obj
	ld --no-demangle -static -Tboot/efi_linker.script -Map=output/efi_body.map -o output/efi_body.bin boot/efi_entry.o boot/efi_main.o boot/kprintf.o
	utils/.build/release/efi_patch boot/efi_header.bin output/efi_body.bin output/kernel.map output/kernel.efi


output/boot-hd.img: boot output/kernel.bin
	utils/.build/release/mkdiskimg boot/bootsector.bin boot/boot16to64.bin output/kernel.bin output/boot-hd.img

test:
	make -C kernel/klib
	make -C tests

iso: output/boot-cd.iso

output/boot-cd.iso: output/boot-hd.img output/kernel.efi
	rm -rf output/iso_tmp output/boot-cd.iso output/efi.img
	mkdir -p output/iso_tmp/efi/boot output/iso_tmp/boot
	cp output/boot-hd.img output/iso_tmp/boot.img
	cp output/kernel.efi output/iso_tmp/efi/boot/bootx64.efi
	/sbin/mkfs.msdos -C output/iso_tmp/boot/efi.img 12288
	mmd -i output/iso_tmp/boot/efi.img ::efi
	mmd -i output/iso_tmp/boot/efi.img ::efi/boot
	mcopy -i output/iso_tmp/boot/efi.img output/kernel.efi ::efi/boot
	# uncomment line below to make bootable EFI ISO
	mcopy -i output/iso_tmp/boot/efi.img output/kernel.efi ::efi/boot/bootx64.efi
	xorrisofs -J -joliet-long -isohybrid-mbr boot/isohdr.bin \
	-b boot.img -c boot.cat -boot-load-size 4 -boot-info-table -no-emul-boot \
	-eltorito-alt-boot -e boot/efi.img -no-emul-boot -isohybrid-gpt-basdat 	 \
	-isohybrid-apm-hfsplus -o output/boot-cd.iso output/iso_tmp
	rm -r output/iso_tmp

clean:
	rm -rf output/*
	set -e; for dir in $(SUBDIRS); do $(MAKE) -C $$dir clean; done
	make -C tests clean
