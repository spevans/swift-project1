TOPDIR := ..
include $(TOPDIR)/Makedefs
BINS := mkdiskimg foverride efi_patch

all: $(BINS)

%: %.swift linux.h
	$(SWIFT3C) -import-objc-header linux.h -emit-executable -o $@ $<

clean:
	rm -f $(BINS)
