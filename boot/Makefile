TOPDIR := ..
include $(TOPDIR)/Makedefs

EFI_CFLAGS := $(CFLAGS) -fno-stack-protector  -mno-red-zone -fpic -fshort-wchar  -fno-unwind-tables

all: bootsector.bin isohdr.bin boot16to64.bin efi_header.bin efi_entry.o efi_main.o kprintf.o


boot16to64.bin: boot16to64.asm utils.asm a20.asm cpu_check.asm page_tables.asm pmode_loader.asm memory.asm
	$(NASM) $(NASM_FLAGS) -fbin -o $@ $<


efi_main.o: efi_main.c
	$(CC) $(EFI_CFLAGS) -c -o $@ $<

kprintf.o: ../klibc/kprintf.c
	$(CC) $(EFI_CFLAGS) -c -o $@ $<

clean:
	rm -f *.bin *.o *.s *.so *.efi *.elf *.map
