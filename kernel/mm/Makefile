TOPDIR := ../..
include $(TOPDIR)/Makedefs

SWIFT_MODULE := 
SWIFT_OBJS := 
SWIFT_SRCS := 
OBJS := pages.o malloc.o


all: mm.o

mm.o: $(OBJS)
	ld -r -no_eh_labels -o $@ $^

mm_test: mm_test.c mm.c
	$(CC) -ggdb -Wall -Wextra -Werror -fno-builtin -fno-stack-protector -I$(TOPDIR)/kernel -o $@ $^

clean:
	rm -f *.bin *.o *.s mm_test
