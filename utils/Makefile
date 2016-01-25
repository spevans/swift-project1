TOPDIR := ..
include $(TOPDIR)/Makedefs


all: mkdiskimg

mkdiskimg: mkdiskimg.swift linux.h
	$(SWIFTC) -I $(FOUNDATION) -I $(COREFOUNDATION) -L $(FOUNDATION) -Xlinker -rpath=$(FOUNDATION) -import-objc-header linux.h -emit-executable -o $@ $<

clean:
	rm -f mkdiskimg

