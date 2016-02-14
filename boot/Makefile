TOPDIR := ..
include $(TOPDIR)/Makedefs

EFI_CFLAGS := $(CFLAGS) -fno-stack-protector  -mno-red-zone -fpic -fshort-wchar  -fno-unwind-tables
AFLAGS := -f bin -p$(TOPDIR)/include/macros.asm

all: bootsector.bin boot16to64.bin efi_header.bin efi_entry.o efi_main.o kprintf.o

bootsector.bin : bootsector.asm
	nasm $(AFLAGS) -o $@ $<

boot16to64.bin : boot16to64.asm utils.asm a20.asm cpu_check.asm page_tables.asm pmode_loader.asm memory.asm
	nasm $(AFLAGS) -o $@ $<


efi_header.bin: efi_header.asm
	nasm $(AFLAGS) -o $@ $<

efi_main.o: efi_main.c
	$(CC) $(EFI_CFLAGS) -c -o $@ $<

kprintf.o: ../kernel/klib/kprintf.c
	$(CC) $(EFI_CFLAGS) -c -o $@ $<

clean:
	rm -f *.bin *.o *.s *.so *.efi *.elf *.map
