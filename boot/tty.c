#include <stdint.h>

extern void halt();


char *const screen = (char *)0xB8000;
unsigned int offset;


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
        static char *hex = "0123456789ABCDEF";
        print_char(hex[value & 0xf]);
}


void print_nibble2(int value)
{
        char *hex2 = "0123456789abcdef";
        print_char(hex2[value & 0xf]);
}


void print_byte(int value)
{
        print_nibble2((value >> 4) & 0xf);
        print_nibble(value & 0xf);
}


void print_word(int value)
{
        print_byte((value >> 8) & 0xff);
        print_byte(value & 0xff);
}


void print_dword(unsigned int value)
{
        print_word((value >> 16) & 0xffff);
        print_word(value & 0xffff);

}


void print_qword(uint64_t value)
{
        print_dword((value >> 32) & 0xffffffff);
        print_dword(value & 0xffffffff);
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
        //offset = 0;
        print_dword(0xFEEBDAED);
        print_char(' ');
        print_dword(0xDEADBEEF);
        print_char(' ');
        print_dword(old_offset);
        newline();
        print_dword(0xAABBCCDD);
        newline();
        print_dword(0x76543210);
        newline();
        print_qword(0x1234567890ABCDEF);
        print_string("init_tty()");
        print_string("line 2");
        print_string("line 3");
        print_string("line 4");
        print_string("line 5");
        print_string("line 6");
}
