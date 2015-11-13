all: disk_image

bootsector.bin : bootsector.asm
	nasm -fbin -o $@ $<

kernel.bin: kernel.asm
	nasm -fbin -o $@ $<

boot16to64.bin : boot16to64.asm utils.asm a20.asm cpu_check.asm page_tables.asm pmode_loader.asm
	nasm -fbin -o $@ $<

disk_image : bootsector.bin boot16to64.bin kernel.bin
	./mkdiskimg.swift bootsector.bin boot16to64.bin kernel.bin disk_image

clean:
	rm -f *.bin disk_image
