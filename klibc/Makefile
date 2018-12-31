TOPDIR := ..
include $(TOPDIR)/Makedefs

OBJS := misc.o string.o io.o kprintf.o printf.o pthread.o \
		libcpp.o x86_string.o x86_misc.o koops.o early_tty.o malloc.o \
		std_cxx11_string.o

all: klibc.o

klibc.o: $(OBJS) ../include/klibc.h ../include/x86funcs.h ../include/x86defs.h ../include/mm.h
	ld -r -no_eh_labels -o $@ $(OBJS)

clean:
	rm -f *.o *.s
