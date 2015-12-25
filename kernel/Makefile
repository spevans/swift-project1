TOPDIR := ..
include $(TOPDIR)/Makedefs

SWIFT_MODULE := SwiftKernel
SWIFT_OBJS := startup.o tty.o
SWIFT_SRCS := $(patsubst %.o,%.swift,$(SWIFT_OBJS))
KERNEL_OBJS := init.o klibc.o early_tty.o kprintf.o string.o $(SWIFT_OBJS)

SUBDIRS := mm


all: kernel.o

kernel.o: $(KERNEL_OBJS)
	for dir in $(SUBDIRS); do $(MAKE) -C $$dir; done
	ld -r -no_eh_labels -o $@ $^ mm/mm.o

$(SWIFT_OBJS): $(SWIFT_SRCS)
	$(SWIFTC) $(SWIFTC_FLAGS) -module-name $(SWIFT_MODULE) $^

clean:
	rm -f *.bin *.o *.s
	set -e; for dir in $(SUBDIRS); do $(MAKE) -C $$dir clean; done

