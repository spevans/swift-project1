TOPDIR := .
include $(TOPDIR)/Makedefs

ALL_SOURCES := $(shell find boot klibc kernel include -name '*.swift' -o -name '*.asm' -o -name '*.[ch]')
KERNEL_OBJS := kernel/kernel.o klibc/klibc.o
SUBDIRS := boot kernel klibc
# See https://github.com/swiftlang/swift/issues/75678 for propper fix (when it is fixed!) for the Unicode Data Tables
#EXTRA_LIBS := $(KSWIFTLIBDIR)/libswiftUnicodeDataTables.a
EXTRA_LIBS :=  /Users/spse/src/swift-project/build/Ninja-DebugAssert/swift-macosx-arm64/stdlib/public/stubs/Unicode/CMakeFiles/embedded-unicode-x86_64-unknown-none-elf.dir/*.o


.PHONY: all iso clean kernel

all: iso

iso: output/boot-cd.iso


output/kernel.elf: $(ALL_SOURCES)
	mkdir -p $(MODULE_DIR) output
	$(RUNNER) make -C klibc
	$(RUNNER) make -C kernel
	# initial link must be via ELF to produce a GOT
	$(LD) --no-demangle -static -Tlinker.script -Map=output/kernel.map -z max-page-size=0x1000 -o output/kernel.elf $(KERNEL_OBJS) $(KSWIFTLIBS) $(EXTRA_LIBS)


output/kernel.dmp: output/kernel.elf
	(objdump -d output/kernel.elf -Mintel | $(SWIFT)-demangle > output/kernel.dmp)


output/kernel.efi: output/kernel.elf
	$(MAKE) -C boot/uefi
	$(OBJCOPY) -I binary -O elf64-x86-64 -B i386:x86-64 output/kernel.elf output/kernel.elf.obj
	$(LD) --no-demangle -static -gc-sections -Tboot/uefi/efi_linker.script -Map=output/efi_body.map -o output/efi_body.bin boot/uefi/efi_body.o
	$(SWIFT) run -c release --package-path utils efi_patch boot/uefi/efi_header.bin output/efi_body.bin output/kernel.map output/kernel.efi


output/kernel.bin: output/kernel.elf
	echo Converting output/kernel.elf to output/kernel.bin
	$(OBJCOPY) -O binary output/kernel.elf output/kernel.bin


output/boot-hd.img: output/kernel.bin
	$(MAKE) -C boot
	$(SWIFT) run -c release --package-path utils mkdiskimg boot/bootsector.bin boot/boot16to64.bin output/kernel.bin output/boot-hd.img


ISO=output/boot-cd.iso
ISO_TMP=output/iso_tmp
BOOT_IMG=$(ISO_TMP)/boot.img
EFI_IMG=$(ISO_TMP)/boot/efi.img
output/boot-cd.iso: output/boot-hd.img output/kernel.efi
#	rm -rf $(ISO_TMP) $(ISO)
	mkdir -p $(ISO_TMP)/efi/boot $(ISO_TMP)/boot
	cp output/boot-hd.img $(BOOT_IMG)
	cp output/kernel.efi $(ISO_TMP)/efi/boot/bootx64.efi
	dd if=/dev/zero of=$(EFI_IMG) bs=1024 count=30240
	# mformat -i <img> should be enough but the version in the Docker image is too old
	mformat -T 60480 -h 16 -s 63 -H 0 -i $(EFI_IMG)
	mmd -i $(EFI_IMG) ::efi
	mmd -i $(EFI_IMG) ::efi/boot
	mcopy -i $(EFI_IMG) output/kernel.efi ::efi/boot
	# uncomment line below to make bootable EFI ISO
	mcopy -i $(EFI_IMG) output/kernel.efi ::efi/boot/bootx64.efi
	xorrisofs -J -joliet-long 			\
		-isohybrid-mbr boot/isohdr.bin 		\
		-isohybrid-gpt-basdat 			\
		-isohybrid-apm-hfsplus			\
		-b boot.img -c boot.cat			\
		-boot-load-size 4			\
		-boot-info-table -no-emul-boot		\
		-eltorito-alt-boot -e boot/efi.img -no-emul-boot	\
		-o output/boot-cd.iso output/iso_tmp
#	rm -r $(ISO_TMP)

clean:
	rm -rf output/*
	set -e; for dir in $(SUBDIRS); do $(MAKE) -C $$dir clean; done
