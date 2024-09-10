TOPDIR := ../..
include $(TOPDIR)/Makedefs

EFI_CFLAGS := -ggdb -Wall -std=gnu11 -Wextra -Werror	\
	-fpic -fshort-wchar 				\
	-target x86_64-none-unknown-elf 		\
	-ffreestanding -nostdlib -fno-builtin 		\
	-fno-stack-protector -fno-omit-frame-pointer	\
	-fno-common -mno-red-zone -fno-unwind-tables	\
	-I$(TOPDIR)/include -DEFI

all: efi_header.bin efi_body.o efi_entry.o

efi_main.o: efi_main.c
	$(CC) $(EFI_CFLAGS) -c -o $@ $<

efi_elf.o: efi_elf.c
	$(CC) $(EFI_CFLAGS) -c -o $@ $<

kprintf.o: ../../klibc/kprintf.c
	$(CC) $(EFI_CFLAGS) -c -o $@ $<

efi_body.o: efi_main.o efi_elf.o kprintf.o
	#partial link
	${LD} -r -e efi_main --gc-sections -z noexecstack -o $@ $^

clean:
	rm -f *.bin *.o *.s *.so *.efi *.elf *.map
