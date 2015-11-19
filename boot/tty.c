#include <stdint.h>

char *screen = (char *)0xB8000;

void print_string(char *str)
{
        while(*str) {
                *screen++ = *str++;
                *screen++ = 0x7;
        }
        // move to next line
        uintptr_t s = (uintptr_t)(screen - 0xB8000);
        s += 159;
        s -= s % 160;
        screen = (char *)(0xB8000 + s);
}

void init_tty()
{
        print_string("init_tty()");
        print_string("line 2");
        print_string("line 3");
        print_string("line 4");
        print_string("line 5");
        print_string("line 6");
}
