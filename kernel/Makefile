TOPDIR := ..
include $(TOPDIR)/Makedefs

SWIFT_MODULE := SwiftKernel
SWIFT_OBJS := SwiftKernel.o
SWIFT_SRCS :=	init/startup.swift		\
		init/GDT.swift			\
		klib/Extensions.swift		\
		klib/MemoryBufferReader.swift	\
		mm/memory.swift			\
		devices/cpu.swift		\
		devices/PCI.swift		\
		devices/tty.swift		\
		devices/pit8254.swift		\
		devices/pic8259.swift		\
		traps/exceptions.swift		\
		traps/IDT.swift

KERNEL_OBJS := init/init.o mm/mm.o klib/klib.o traps/traps.o SwiftKernel.o

SUBDIRS := klib devices mm traps init


all: kernel.o

.PHONY: kernel.o

kernel.o: SwiftKernel.o
	for dir in $(SUBDIRS); do $(MAKE) -C $$dir || exit; done
	ld -r -no_eh_labels -o $@ $(KERNEL_OBJS)

$(SWIFT_OBJS): $(SWIFT_SRCS)
	$(SWIFTC) $(SWIFTC_FLAGS) -whole-module-optimization -module-name $(SWIFT_MODULE) -emit-object -o $@ $^

clean:
	rm -f *.bin *.o *.s
	set -e; for dir in $(SUBDIRS); do $(MAKE) -C $$dir clean; done

