ARCH		= $(shell uname -m | sed s,i[3456789]86,ia32,)

OBJS		= efi-test.o
TARGET		= efi-test.efi

EFIINC		= /usr/include/efi
EFIINCS		= -I$(EFIINC) -I$(EFIINC)/$(ARCH) -I$(EFIINC)/protocol
LIB		= /usr/lib
EFILIB		= /usr/lib
EFI_CRT_OBJS	= $(EFILIB)/crt0-efi-$(ARCH).o
EFI_LDS		= $(EFILIB)/elf_$(ARCH)_efi.lds

CFLAGS		= $(EFIINCS) -fno-stack-protector -fpic \
		  -fshort-wchar -mno-red-zone -Wall -O2  -std=gnu11
ifeq ($(ARCH),x86_64)
  CFLAGS += -DEFI_FUNCTION_WRAPPER
endif

LDFLAGS		= -nostdlib -znocombreloc -T $(EFI_LDS) -shared \
		  -Bsymbolic -L $(EFILIB) -L $(LIB) $(EFI_CRT_OBJS)

all: $(TARGET)

efi-test.so: $(OBJS)
	ld $(LDFLAGS) $(OBJS) -o $@ -lefi -lgnuefi

%.efi: %.so
	objcopy -j .text -j .sdata -j .data -j .dynamic \
		-j .dynsym  -j .rel -j .rela -j .reloc \
		--target=efi-app-$(ARCH) $^ $@

clean:
	rm -f $(OBJS) $(TARGET) efi-test.so
