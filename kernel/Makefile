# -*- mode: BSDmakefile; tab-width: 8; -*-
TOPDIR := ..
include $(TOPDIR)/Makedefs
GITVER := $(shell git rev-parse HEAD)


SWIFT_MODULE := SwiftKernel
SWIFT_OBJS := SwiftKernel.o
_SWIFT_SRCS :=	init/startup.swift				\
		init/bootparams.swift				\
		init/biosboot.swift				\
		init/efiboot.swift				\
		init/smbios.swift				\
		init/GDT.swift					\
		init/MemoryRange.swift				\
		klib/Extensions.swift				\
		klib/extensions/integer.swift			\
		klib/extensions/bitarray.swift			\
		klib/extensions/bytearray.swift			\
		klib/extensions/dwordarray.swift		\
		klib/MemoryBufferReader.swift			\
		klib/BitmapAllocator.swift			\
		klib/CircularBuffer.swift			\
		klib/ReservationManager.swift			\
		klib/printf.swift				\
		mm/init.swift					\
		mm/address.swift				\
		mm/page.swift					\
		mm/alloc.swift					\
		mm/symbols.swift				\
		mm/MMIORegion.swift				\
		devices/acpi/acpi.swift				\
		devices/acpi/ACPIGenericAddressStructure.swift	\
		devices/acpi/boot.swift				\
		devices/acpi/ecdt.swift				\
		devices/acpi/facp.swift				\
		devices/acpi/facs.swift				\
		devices/acpi/hpet.swift				\
		devices/acpi/madt.swift				\
		devices/acpi/mcfg.swift				\
		devices/acpi/sbst.swift				\
		devices/acpi/srat.swift				\
		devices/acpi/waet.swift				\
		devices/acpi/amlparser.swift			\
		devices/acpi/amltypes.swift			\
		devices/acpi/amltype1opcodes.swift		\
		devices/acpi/amltype2opcodes.swift		\
		devices/acpi/amlnamedobject.swift		\
		devices/acpi/amlresourcedata.swift		\
		devices/acpi/amlutils.swift			\
		devices/acpi/amlmethod.swift			\
		devices/acpi/amlnamespacemodifier.swift		\
		devices/acpi/acpiglobalobjects.swift		\
		devices/pci/pcibus.swift			\
		devices/pci/pciconfigspace.swift		\
		devices/pci/pcidevice.swift			\
		devices/pci/pcideviceclass.swift		\
		devices/pci/PCIInterruptLinkDevice.swift	\
		devices/pci/PCIRoutingTable.swift		\
		devices/usb/usb.swift				\
		devices/usb/usb-configdescriptor.swift		\
		devices/usb/usb-controlrequest.swift		\
		devices/usb/usb-device.swift			\
		devices/usb/usb-devicedescriptor.swift		\
		devices/usb/usb-devicequalifier.swift		\
		devices/usb/usb-endpointdescriptor.swift	\
		devices/usb/usb-hiddescriptor.swift		\
		devices/usb/usb-hid.swift			\
		devices/usb/usb-hub.swift			\
		devices/usb/usb-interfacedescriptor.swift	\
		devices/usb/hcd-ehci.swift			\
		devices/usb/hcd-xhci.swift			\
		devices/usb/uhci-buffers.swift			\
		devices/usb/uhci-hcd.swift			\
		devices/usb/uhci-pipe.swift			\
		devices/usb/uhci-queuehead.swift		\
		devices/usb/uhci-registers.swift		\
		devices/usb/uhci-transferdescriptor.swift	\
		devices/bus.swift				\
		devices/device.swift				\
		devices/devicemanager.swift			\
		devices/driver.swift				\
		devices/cpu.swift				\
		devices/isa.swift				\
		devices/tty.swift				\
		devices/kbd8042.swift				\
		devices/ps2keyboard.swift			\
		devices/pit8254.swift				\
		devices/pic8259.swift				\
		devices/qemufwcf.swift				\
		devices/apic.swift				\
		devices/ioapic.swift				\
		devices/cmos.swift				\
		devices/Timer.swift				\
		traps/exceptions.swift				\
		traps/interrupt.swift				\
		traps/IDT.swift					\
		traps/IRQSetting.swift				\
		tasks/tasks.swift				\
		tasks/shell.swift				\
		vm/vmx.swift					\
                vm/vmcs.swift

CWD := $(shell pwd)
SWIFT_SRCS := $(addprefix $(CWD)/, $(_SWIFT_SRCS)) init/version.swift

all: kernel.o


init/main.o: init/main.asm
init/bss.o: init/bss.c
traps/entry.o: traps/entry.asm
vm/vmentry.o: vm/vmentry.asm
devices/timer.o: devices/timer.asm

init/init.o: init/main.o init/bss.o
	ld -r -no_eh_labels -o $@ $^

KERNEL_OBJS := init/init.o traps/entry.o vm/vmentry.o devices/timer.o SwiftKernel.o
HEADERS = $(TOPDIR)/include/*.h

init/version.swift: ../.git/index
	echo making version.swift for $(GITVER)
	echo 'let gitBuildVersion="$(GITVER)"' > init/version.swift

kernel.o: SwiftKernel.o $(KERNEL_OBJS)
	ld -r -no_eh_labels -o $@ $(KERNEL_OBJS)

$(SWIFT_OBJS): $(SWIFT_SRCS) $(HEADERS) init/version.swift
	$(KSWIFTC) $(KSWIFTC_FLAGS) -whole-module-optimization -module-name $(SWIFT_MODULE) -emit-object -o $@ $(SWIFT_SRCS)

clean:
	rm -f *.bin *.o *.s *.sil
	rm -f init/version.swift
