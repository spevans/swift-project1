TOPDIR := ..
include $(TOPDIR)/Makedefs
BINS := mkdiskimg foverride efi_patch

all: $(BINS)

%: %.swift linux.h
#	$(SWIFTC) -I $(FOUNDATION) -I $(COREFOUNDATION) -L $(FOUNDATION) -Xlinker -rpath=$(FOUNDATION) -import-objc-header linux.h -emit-executable -o $@ $<
	/home/spse/swift-DEVELOPMENT-SNAPSHOT-2016-02-08-a-ubuntu14.04/usr/bin/swiftc -import-objc-header linux.h -emit-executable -o $@ $<



clean:
	rm -f $(BINS)

