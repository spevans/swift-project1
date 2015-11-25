#include <stdint.h>

extern void halt();


char *const screen = (char *)0xB8000;
unsigned int offset;
extern uintptr_t _text_start;
extern uintptr_t _text_end;
extern uintptr_t _data_start;
extern uintptr_t _data_end;
extern uintptr_t _bss_start;
extern uintptr_t _bss_end;



const char *strings[] = { "hello", "there" };

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


void print_string(char *str)
{
        while(*str) {
                char ch = *str++;
                if (ch == '\n') {
                        newline();
                } else {
                        *(screen + offset++) = ch;
                        *(screen + offset++) = 0x7;
                }
        }
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


void print_sections()
{
        print_string("screen: ");
        print_qword((uintptr_t)screen);
        newline();
        print_string("_text_start: ");
        print_qword((uintptr_t)&_text_start);
        newline();
        print_string("_text_end:   ");
        print_qword((uintptr_t)&_text_end);
        newline();

        print_string("_data_start: ");
        print_qword((uintptr_t)&_data_start);
        newline();

        print_string("_data_end:   ");
        print_qword((uintptr_t)&_data_end);
        newline();

        print_string("_bss_start:  ");
        print_qword((uintptr_t)&_bss_start);
        newline();

        print_string("_bss_end:    ");
        print_qword((uintptr_t)&_bss_end);
        newline();

}

void init_tty()
{
        offset = 0;
        print_string("init_tty()\n");
        newline();
        print_sections();
        print_qword(0x1234567890ABCDEF);

}
