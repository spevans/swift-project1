TOPDIR := ../..
include $(TOPDIR)/Makedefs

SWIFT_MODULE := MM
SWIFT_OBJS := memory.o
SWIFT_SRCS := $(patsubst %.o,%.swift,$(SWIFT_OBJS))
OBJS := pages.o malloc.o


all: mm.o

mm.o: $(OBJS)
	ld -r -no_eh_labels -o $@ $^

$(SWIFT_OBJS): $(SWIFT_SRCS)
	$(SWIFTC) $(SWIFTC_FLAGS) -emit-object -module-name $(SWIFT_MODULE) $^
	$(SWIFTC) $(SWIFTC_FLAGS) -emit-module -module-name $(SWIFT_MODULE) -o $(MODULE_DIR)/$(SWIFT_MODULE).swiftmodule $^

mm_test: mm_test.c mm.c
	$(CC) -ggdb -Wall -Wextra -Werror -fno-builtin -fno-stack-protector -I$(TOPDIR)/kernel -o $@ $^

clean:
	rm -f *.bin *.o *.s $(MODULE_DIR)/$(SWIFT_MODULE).* mm_test
