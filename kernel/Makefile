# -*- mode: BSDmakefile; tab-width: 8; -*-
TOPDIR := ..
include $(TOPDIR)/Makedefs
GITVER := $(shell git rev-parse HEAD)

SWIFT_MODULE := SwiftKernel
SWIFT_OBJS := SwiftKernel.o
SWIFT_SRCS := $(shell find `pwd` -name '*.swift' | grep -v version.swift) init/version.swift

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

kernel.o: $(KERNEL_OBJS)
	ld -r -no_eh_labels -o $@ $(KERNEL_OBJS)

SwiftKernel.o: $(SWIFT_SRCS) $(HEADERS)
	# swiftc doesnt always seem to update the timestamp after building the delete the output file to be
	# sure that a new file is created
	rm -f $@
	$(KSWIFTC) $(KSWIFTC_FLAGS) -whole-module-optimization -module-name $(SWIFT_MODULE) -emit-object -o $@ $(SWIFT_SRCS)

clean:
	find . -name '*.bin' -o -name '*.o' |xargs rm
	rm -f init/version.swift
