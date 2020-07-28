# -*- mode: BSDmakefile; tab-width: 8; -*-
TOPDIR := ..
include $(TOPDIR)/Makedefs
GITVER := $(shell git rev-parse HEAD)


SWIFT_MODULE := SwiftKernel
SWIFT_OBJS := SwiftKernel.o
_SWIFT_SRCS :=	init/startup.swift		\
		init/bootparams.swift		\
		init/biosboot.swift		\
		init/efiboot.swift		\
		init/smbios.swift		\
		init/GDT.swift			\
		klib/Extensions.swift		\
		klib/extensions/integer.swift	\
		klib/extensions/bitarray.swift	\
		klib/extensions/bytearray.swift \
		klib/extensions/dwordarray.swift \
		klib/MemoryBufferReader.swift	\
		klib/CircularBuffer.swift	\
		klib/ReservationManager.swift	\
		klib/printf.swift		\
		mm/init.swift			\
		mm/address.swift		\
		mm/page.swift			\
		mm/alloc.swift			\
		mm/symbols.swift		\
		devices/acpi/acpi.swift		\
		devices/acpi/boot.swift		\
		devices/acpi/ecdt.swift		\
		devices/acpi/facp.swift		\
		devices/acpi/facs.swift		\
		devices/acpi/hpet.swift		\
		devices/acpi/madt.swift		\
		devices/acpi/mcfg.swift		\
		devices/acpi/sbst.swift		\
		devices/acpi/srat.swift		\
		devices/acpi/waet.swift		\
		devices/acpi/amlparser.swift 	\
		devices/acpi/amltypes.swift	\
		devices/acpi/amltype1opcodes.swift \
		devices/acpi/amltype2opcodes.swift \
		devices/acpi/amlnamedobject.swift  \
		devices/acpi/amlresourcedata.swift \
		devices/acpi/amlutils.swift	\
		devices/acpi/amlmethod.swift	\
		devices/acpi/acpiglobalobjects.swift \
		devices/pci/access.swift	\
		devices/pci/bus.swift		\
		devices/pci/device.swift	\
		devices/devicemanager.swift	\
		devices/cpu.swift		\
		devices/isa.swift		\
		devices/piix.swift		\
		devices/tty.swift		\
		devices/kbd8042.swift		\
		devices/ps2keyboard.swift	\
		devices/pit8254.swift		\
		devices/pic8259.swift		\
		devices/qemufwcf.swift		\
		devices/apic.swift		\
		devices/ioapic.swift		\
		devices/cmos.swift		\
		traps/exceptions.swift		\
		traps/interrupt.swift		\
		traps/IDT.swift			\
		tasks/tasks.swift		\
		tasks/shell.swift		\
		vm/vmx.swift			\
		vm/vmcs.swift

CWD := $(shell pwd)
SWIFT_SRCS := $(addprefix $(CWD)/, $(_SWIFT_SRCS)) init/version.swift

KERNEL_OBJS := init/init.o traps/traps.o vm/vmentry.o SwiftKernel.o
SUBDIRS := devices mm traps init vm
HEADERS = $(TOPDIR)/include/*.h

all: kernel.o

.PHONY: kernel.o

init/version.swift: ../.git/index
	echo making version.swift for $(GITVER)
	echo 'let gitBuildVersion="$(GITVER)"' > init/version.swift

kernel.o: SwiftKernel.o
	for dir in $(SUBDIRS); do $(MAKE) -C $$dir || exit; done
	ld -r -no_eh_labels -o $@ $(KERNEL_OBJS)

$(SWIFT_OBJS): $(SWIFT_SRCS) $(HEADERS) init/version.swift
	$(KSWIFTC) $(KSWIFTC_FLAGS) -whole-module-optimization -module-name $(SWIFT_MODULE) -emit-object -o $@ $(SWIFT_SRCS)

SwiftKernel.sil: $(SWIFT_SRCS) $(HEADERS)
	$(KSWIFTC) $(KSWIFTC_FLAGS) -whole-module-optimization -module-name $(SWIFT_MODULE) -emit-sil -o $@ $(SWIFT_SRCS)

SwiftKernel.silgen: $(SWIFT_SRCS) $(HEADERS)
	$(KSWIFTC) $(KSWIFTC_FLAGS) -whole-module-optimization -module-name $(SWIFT_MODULE) -emit-silgen -o $@ $(SWIFT_SRCS)


sil: SwiftKernel.sil

clean:
	rm -f *.bin *.o *.s *.sil
	rm -f init/version.swift
	set -e; for dir in $(SUBDIRS); do $(MAKE) -C $$dir clean; done
