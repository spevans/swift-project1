TOPDIR := ..
include $(TOPDIR)/Makedefs

SWIFT_MODULE := Tests
SWIFT_OBJS := Tests.o
SWIFT_SRCS := $(patsubst %.o,%.swift,$(SWIFT_OBJS))
OBJS := $(SWIFT_OBJS) 

SOLIBDIR := $(SWIFT3DIR)/usr/lib/swift/linux
SOLIB := $(SOLIBDIR)/libswiftCore.so
XCTLIB := $(SOLIBDIR)/libXCTest.so
FOUNDATIONLIB := $(SOLIBDIR)/libFoundation.so
SGLIBC := $(SOLIBDIR)/libswiftGlibc.so
ONONELIB := $(SOLIBDIR)/libswiftSwiftOnoneSupport.so
EXTRALIBS := $(SOLIB) $(XCTLIB) $(FOUNDATIONLIB) $(SGLIBC) $(ONONELIB)

all: tests runtests
.PHONY: tests


SFLAGS := -g -parse-as-library -import-objc-header ../include/kernel.h -whole-module-optimization -emit-object
CFLAGS := -ggdb  -I../include -Xlinker -rpath=$(SOLIBDIR) $(EXTRALIBS)
CFILES := testrunner.c ../klibc/kprintf.c

tests: tests.swift ../kernel/klib/Extensions.swift 
	$(SWIFT3C) $(SFLAGS) -o $@.o $^
	$(CC) $(CFLAGS) $(CFILES) -o $@ $@.o	

acpitest: acpitest.swift ../kernel/devices/acpi.swift  ../kernel/devices/acpi/*.swift ../kernel/klib/Extensions.swift
	$(SWIFT3C) $(SFLAGS) -o $@.o $^
	$(CC) $(CFLAGS) $(CFILES) -o $@ $@.o


runtests: tests acpitest
	./tests
	./acpitest acpi_tables/*.acpi

clean:
	rm -f *.o tests acpitest
