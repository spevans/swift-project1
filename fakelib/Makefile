TOPDIR := ..
include $(TOPDIR)/Makedefs

FAKELIB_OBJS := misc.o math.o io.o printf.o pthread.o libcpp.o std_string.o


all: fakelib.o

fakelib.o: $(FAKELIB_OBJS)
	echo OBJS = $(FAKELIB_OBJS)
	ld -r -no_eh_labels -o $@ $^

clean:
	rm -f *.o *.s
