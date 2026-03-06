# -*- mode: BSDmakefile; tab-width: 8; -*-

TOPDIR := ../../..
include $(TOPDIR)/Makedefs


OBJS := main.o bss.o entry.o vmentry.o timer.o

all: arch.o

arch.o: $(OBJS)
	$(LD) -r -z noexecstack -o $@ $^

clean:
		rm -f *.o
