TOPDIR := ..
include $(TOPDIR)/Makedefs

SWIFT_MODULE :=
SWIFT_OBJS :=
SWIFT_SRCS := $(patsubst %.o,%.swift,$(SWIFT_OBJS))
KERNEL_OBJS := init/init.o mm/mm.o devices/devices.o klib/klib.o

SUBDIRS := klib devices mm init


all: kernel.o

.PHONY: kernel.o

kernel.o:
	for dir in $(SUBDIRS); do $(MAKE) -C $$dir || exit; done
	ld -r -no_eh_labels -o $@ $(KERNEL_OBJS)

$(SWIFT_OBJS): $(SWIFT_SRCS)
	$(SWIFTC) $(SWIFTC_FLAGS) -module-name $(SWIFT_MODULE) $^

clean:
	rm -f *.bin *.o *.s
	set -e; for dir in $(SUBDIRS); do $(MAKE) -C $$dir clean; done

