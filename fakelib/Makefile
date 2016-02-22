TOPDIR := ..
include $(TOPDIR)/Makedefs

FAKELIB_OBJS := libc.o linux_libc.o linux_libcpp.o


all: fakelib.o

fakelib.o: $(FAKELIB_OBJS)
	echo OBJS = $(FAKELIB_OBJS)
	ld -r -no_eh_labels -o $@ $^

clean:
	rm -f *.o *.s
