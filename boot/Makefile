all: disk_image

bootsector.bin : bootsector.asm
	nasm -fbin -o $@ $<

boot16to64.bin : boot16to64.asm utils.asm a20.asm cpu_check.asm page_tables.asm
	nasm -fbin -o $@ $<

disk_image : bootsector.bin boot16to64.bin
	cat $^ > $@
clean:
	rm -f *.bin
