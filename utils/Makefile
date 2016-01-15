TOPDIR := ..
include $(TOPDIR)/Makedefs
SWIFTC := $(SWIFTDIR)/usr/bin/swiftc

all: mkdiskimg

mkdiskimg: mkdiskimg.swift linux.h
	$(SWIFTC) -import-objc-header linux.h -emit-executable -o $@ $<

clean:
	rm -f mkdiskimg

