# -*- mode: BSDmakefile; tab-width: 8; -*-
TOPDIR := ..
include $(TOPDIR)/Makedefs
GITVER := $(shell git rev-parse HEAD)

SWIFT_MODULE := SwiftKernel
SWIFT_OBJS := SwiftKernel.o
SWIFT_SRCS := $(shell find `pwd` -name '*.swift' | egrep -v 'version.swift|/teststub/') init/version.swift

KSWIFTC_FLAGS := -g -O -Xcc -mno-red-zone -Xcc -mcmodel=kernel				\
	-Xcc -Wall -Xcc -Wextra -Xcc -std=gnu11	-Xcc -mno-mmx -Xcc -mno-sse -Xcc -mno-sse2	\
	-enable-experimental-feature FullTypedThrow 						\
	-parse-as-library -import-objc-header $(TOPDIR)/include/kernel.h -warnings-as-errors	\
	-Xfrontend -warn-long-function-bodies=60000 -DKERNEL -DACPI				\
	-target x86_64-unknown-none-elf -Xcc -ffreestanding -Xfrontend -disable-stack-protector	\
	-enable-experimental-feature Embedded -Xfrontend -embedded-runtime-variant=kernel 	\
	-Xfrontend -load-plugin-executable -Xfrontend $(PRINTF_MACROS)\#PrintfMacros

all: kernel.o


KERNEL_OBJS := arch/x86_64/arch.o SwiftKernel.o
HEADERS = $(TOPDIR)/include/*.h

arch/x86_64/arch.o:
	make -C arch/x86_64

init/version.swift: ../.git/index
	echo making version.swift for $(GITVER)
	echo 'let gitBuildVersion: StaticString = "$(GITVER)"' > init/version.swift

kernel.o: $(KERNEL_OBJS)
	$(LD) -r -z noexecstack -o $@ $(KERNEL_OBJS) $(SWIFTLIBDIR)/libswiftUnicodeDataTables.a

SwiftKernel.o: $(SWIFT_SRCS) $(HEADERS)
	# swiftc doesnt always seem to update the timestamp after building the delete the output file to be
	# sure that a new file is created
	rm -f $@
	$(SWIFTC) $(KSWIFTC_FLAGS) -whole-module-optimization -module-name $(SWIFT_MODULE) -emit-object -o $@ $(SWIFT_SRCS)

clean:
	find . -name '*.bin' -o -name '*.o' |xargs rm
	rm -f init/version.swift
