TOPDIR := ..
include $(TOPDIR)/Makedefs

FAKELIB_OBJS := libc.o

ifeq ($(UNAME_S), Linux)
	FAKELIB_OBJS := $(FAKELIB_OBJS) linux_libc.o linux_libcpp.o
endif

ifeq ($(UNAME_S), Darwin)
	LINKER := ../static_linker/build/Debug/static_linker
	FAKELIB_OBJS := $(FAKELIB_OBJS) osx_libc.o osx_libcpp.o libobj.o
endif


all: fakelib.o

fakelib.o: $(FAKELIB_OBJS)
	echo OBJS = $(FAKELIB_OBJS)
	ld -r -no_eh_labels -o $@ $^

clean:
	rm -f *.o *.s
