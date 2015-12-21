TOPDIR := ..
include $(TOPDIR)/Makedefs

SWIFT_MODULE := SwiftKernel
SWIFT_OBJS := startup.o tty.o
SWIFT_SRCS := $(patsubst %.o,%.swift,$(SWIFT_OBJS))
KERNEL_OBJS := init.o klibc.o early_tty.o mm.o kprintf.o string.o $(SWIFT_OBJS)


all: kernel.o

kernel.o: $(KERNEL_OBJS)
	ld -r -no_eh_labels -o $@ $^

$(SWIFT_OBJS): $(SWIFT_SRCS)
	$(SWIFTC) $(SWIFTC_FLAGS) -module-name $(SWIFT_MODULE) $^

clean:
	rm -f *.bin *.o *.s mm_test

mm_test: mm_test.c mm.c
	$(CC) -ggdb -Wall -Wextra -Werror -fno-builtin -fno-stack-protector -I$(TOPDIR)/kernel -o $@ $^
