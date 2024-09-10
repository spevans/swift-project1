TOPDIR := ..
include $(TOPDIR)/Makedefs

all: bootsector.bin isohdr.bin boot16to64.bin
	make -C uefi

boot16to64.bin: boot16to64.asm utils.asm a20.asm cpu_check.asm page_tables.asm pmode_loader.asm memory.asm
	$(NASM) $(NASM_FLAGS) -fbin -o $@ $<

clean:
	make -C uefi clean
	rm -f *.bin *.o *.s *.so *.efi *.elf *.map
