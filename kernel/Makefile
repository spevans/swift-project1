TOPDIR := ..
include $(TOPDIR)/Makedefs

KERNEL_OBJS := init.o klibc.o startup.o tty.o


all: kernel.o

startup.o: startup.swift
	$(SWIFTC) -emit-object -parse-as-library -o startup.o startup.swift
	$(SWIFTC) -emit-assembly -parse-as-library -o startup.s startup.swift

kernel.o: $(KERNEL_OBJS)
	ld -r -no_eh_labels -o $@ $^

clean:
	rm -f *.bin *.o *.s
