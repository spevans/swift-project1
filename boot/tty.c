#include <stdint.h>

extern void halt();


char *const screen = (char *)0xB8000;
unsigned int offset;
static char *hex = "0123456789ABCDEF";


void newline()
{
        // move to next line
        offset += 159;
        offset -= offset % 160;
}


void print_char(char ch)
{
        *(screen + offset++) = ch;
        *(screen + offset++) = 0x7;
}


void print_nibble(int value)
{
        //static char *hex = "0123456789ABCDEF";
        print_char(hex[value & 0xf]);
}


void print_byte(int value)
{

        print_nibble(value & 0xf);
        print_nibble((value >> 4) & 0xf);
}


void print_word(int value)
{
        print_byte(value & 0xff);
        print_byte((value >> 8) & 0xff);
}


void print_dword(unsigned int value)
{
        print_word(value & 0xffff);
        print_word((value >> 16) & 0xffff);
}

void print_string(char *str)
{
        while(*str) {
                *(screen + offset++) = *str++;
                *(screen + offset++) = 0x7;
        }
        newline();
}

void init_tty()
{
        unsigned int old_offset = offset;
        offset = 0;
        print_dword(0xFEEBDAED);
        print_char(' ');
        print_dword(0xDEADBEEF);
        print_char(' ');
        print_dword(old_offset);
        newline();
        print_dword(0xAABBCCDD);
        newline();
        print_string("init_tty()");
        print_string("line 2");
        print_string("line 3");
        print_string("line 4");
        print_string("line 5");
        print_string("line 6");
}
