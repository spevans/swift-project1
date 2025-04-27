TOPDIR := ..
include $(TOPDIR)/Makedefs

OBJS := misc.o string.o kprintf.o printf.o  \
		x86_string.o x86_misc.o koops.o early_tty.o malloc.o

all: klibc.o

klibc.o: $(OBJS) ../include/klibc.h ../include/x86funcs.h ../include/x86defs.h ../include/mm.h
	$(LD) -z noexecstack -r -o $@ $(OBJS)

clean:
	rm -f *.o *.s
