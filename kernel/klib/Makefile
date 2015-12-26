TOPDIR := ../..
include $(TOPDIR)/Makedefs

SWIFT_MODULE :=
SWIFT_OBJS :=
SWIFT_SRCS := $(patsubst %.o,%.swift,$(SWIFT_OBJS))
OBJS := $(SWIFT_OBJS) misc.o string.o kprintf.o

all: klib.o

klib.o: $(OBJS)
	ld -r -no_eh_labels -o $@ $^

$(SWIFT_OBJS): $(SWIFT_SRCS)
	$(SWIFTC) $(SWIFTC_FLAGS) -module-name $(SWIFT_MODULE) $^

clean:
	rm -f *.bin *.o *.s

