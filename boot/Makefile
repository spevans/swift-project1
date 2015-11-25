all: disk_image

bootsector.bin : bootsector.asm
	nasm -fbin -o $@ $<


kernel.bin: kernel.asm tty.c stubs.c ../static_linker/build/Debug/static_linker
	nasm -fmacho64 -o kernel.o $<
	clang -Wall -Wextra -Werror -c -o tty.o tty.c
	clang -Wall -Wextra -Werror -fno-builtin -c -o stubs.o stubs.c
	../static_linker/build/Debug/static_linker --output=$@ --baseAddress=0x100000 --mapfile=kernel.map kernel.o ../libswiftCore.dylib tty.o stubs.o

boot16to64.bin : boot16to64.asm utils.asm a20.asm cpu_check.asm page_tables.asm pmode_loader.asm
	nasm -fbin -o $@ $<

disk_image : bootsector.bin boot16to64.bin kernel.bin
	./mkdiskimg.swift bootsector.bin boot16to64.bin kernel.bin disk_image

clean:
	rm -f *.bin *.o disk_image kernel.map
