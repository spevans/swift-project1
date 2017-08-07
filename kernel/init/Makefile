TOPDIR := ../..
include $(TOPDIR)/Makedefs

SWIFT_MODULE := Init
SWIFT_OBJS := startup.o GDT.o
SWIFT_SRCS := $(patsubst %.o,%.swift,$(SWIFT_OBJS))
# Note main.o needs to be first so that the entry point is at the correct address
OBJS := main.o bss.o

all: init.o

init.o: $(OBJS)
	ld -r -no_eh_labels -o $@ $^

$(SWIFT_OBJS): $(SWIFT_SRCS)
	$(KSWIFTC) $(KSWIFTC_FLAGS) -emit-object -module-name $(SWIFT_MODULE) $^
	$(KSWIFTC) $(KSWIFTC_FLAGS) -emit-module -module-name $(SWIFT_MODULE) -o $(MODULE_DIR)/$(SWIFT_MODULE).swiftmodule $^

clean:
	rm -f *.bin *.o *.s $(MODULE_DIR)/$(SWIFT_MODULE).*
