TOPDIR := ../..
include $(TOPDIR)/Makedefs

SWIFT_MODULE := MM
SWIFT_OBJS := memory.o
SWIFT_SRCS := $(patsubst %.o,%.swift,$(SWIFT_OBJS))


all:

$(SWIFT_OBJS): $(SWIFT_SRCS)
	$(SWIFTC) $(SWIFTC_FLAGS) -emit-object -module-name $(SWIFT_MODULE) $^
	$(SWIFTC) $(SWIFTC_FLAGS) -emit-module -module-name $(SWIFT_MODULE) -o $(MODULE_DIR)/$(SWIFT_MODULE).swiftmodule $^

clean:
	rm -f *.bin *.o *.s $(MODULE_DIR)/$(SWIFT_MODULE).* mm_test
