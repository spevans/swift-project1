TOPDIR := ..
include $(TOPDIR)/Makedefs


all: bootsector.bin boot16to64.bin efi_header.efi

bootsector.bin : bootsector.asm
	nasm -fbin -o $@ $<

boot16to64.bin : boot16to64.asm utils.asm a20.asm cpu_check.asm page_tables.asm pmode_loader.asm memory.asm
	nasm -fbin -o $@ $<


efi_header.bin: efi_header.asm
	nasm -fbin -o $@ $<


efi_header.efi: efi_header.bin efi_entry.o efi_main.o efi_linker.script
	ld --no-demangle -static -Tefi_linker.script -Map=efi.map -o efi_body.elf efi_entry.o efi_main.o
	objcopy -O binary efi_body.elf efi_body.bin
	cat efi_header.bin efi_body.bin >efi_header.efi




efi_main.o: efi_main.c
	$(CC) $(CFLAGS) -fpic -fshort-wchar  -fno-unwind-tables -c -o $@ $<

clean:
	rm -f *.bin *.o *.s *.so *.efi *.elf *.map
