TOPDIR := ..
include $(TOPDIR)/Makedefs


all: bootsector.bin boot16to64.bin

bootsector.bin : bootsector.asm
	nasm -fbin -o $@ $<

boot16to64.bin : boot16to64.asm utils.asm a20.asm cpu_check.asm page_tables.asm pmode_loader.asm memory.asm
	nasm -fbin -o $@ $<

clean:
	rm -f *.bin *.o *.s
