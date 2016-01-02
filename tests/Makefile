TOPDIR := ..
include $(TOPDIR)/Makedefs

SWIFT_MODULE := Tests
SWIFT_OBJS := StringTests.o
SWIFT_SRCS := $(patsubst %.o,%.swift,$(SWIFT_OBJS))
OBJS := $(SWIFT_OBJS) 

SOLIBDIR := $(SWIFTDIR)/usr/lib/swift/linux
SOLIB := $(SWIFTDIR)/usr/lib/swift/linux/libswiftCore.so
XCTLIB := $(SWIFTDIR)/usr/lib/swift/linux/libXCTest.so

all: runtests

$(SWIFT_OBJS): $(SWIFT_SRCS)
	$(SWIFTC) $(SWIFTC_FLAGS) -emit-object -module-name $(SWIFT_MODULE) $^

tests: $(SWIFT_OBJS) tests.c ../kernel/klib/kprintf.c
	$(CC) -DTESTS -o $@ tests.c ../kernel/klib/kprintf.c $(SWIFT_OBJS) ../kernel/klib/Extensions.o -Xlinker -rpath=$(SOLIBDIR) $(SOLIB) $(XCTLIB)

runtests: tests
	./tests

clean:
	rm -f *.o tests
