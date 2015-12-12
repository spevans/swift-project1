#include "klibc.h"


char *const screen = (char *)0xB8000;
extern uintptr_t _text_start;
extern uintptr_t _text_end;
extern uintptr_t _data_start;
extern uintptr_t _data_end;
extern uintptr_t _bss_start;
extern uintptr_t _bss_end;


const char *strings[] = { "hello", "there" };




static inline void *
memset(void *s, char c, size_t count)
{
        int d0, d1, d2;
        asm volatile ("cld\n\t"
                      "rep\n\t"
                      "stosb"
                      : "=&D" (d0), "=&a" (d1), "=&c" (d2)
                      : "0" (s), "1" (c), "2" (count) : "memory");
        return s;
}


static inline void *
memsetw(void *s, uint16_t w, size_t count)
{
        int d0, d1, d2;
        asm volatile ("cld\n\t"
                      "rep\n\t"
                      "stosw"
                      : "=&D" (d0), "=&a" (d1), "=&c" (d2)
                      : "0" (s), "1" (w), "2" (count) : "memory");
        return s;
}

static inline char *
stpcpy(char *dest, const char *src)
{
    /* Need the `volatile' keyword so gcc doesn't assume it's free
       of side-effects (because of the output operand). */
    asm volatile ("cld\n\t"
                  "1:\tlodsb\n\t"
                  "stosb\n\t"
                  "testb %%al,%%al\n\t"
                  "jne 1b\n\t"
                  "decl %%edi"
                  : "=D" (dest)
                  : "S" (src), "0" (dest)
                  : "ax", "memory");
    return dest;
}


void *
__memcpy(void *dest, const void *src, size_t n)
{
        int d0, d1, d2, d3;
        asm volatile ("cld\n\t"
                      "movl %%edx, %%ecx\n\t"
                      "shrl $2,%%ecx\n\t"
                      "rep ; movsl\n\t"
                      "testb $1,%%dl\n\t"
                      "je 1f\n\t"
                      "movsb\n"
                      "1:\ttestb $2,%%dl\n\t"
                      "je 2f\n\t"
                      "movsw\n"
                      "2:\n"
                      : "=&S" (d0), "=&D" (d1), "=&d" (d2), "=&a" (d3)
                      : "0" (src), "1" (dest), "2" (n)
                      : "memory", "cx");
    return dest;
}



void
print_string_len(const char *text, size_t len)
{
        static int cursor_x, cursor_y;
        char *cursor_char = (screen + (cursor_y * 80 * 2) + (cursor_x * 2));
        char c;

        while(len--) {
                c = *text++;
                if((c == '\n') || (cursor_x >= 80)) {
                        cursor_x = 0;
                        if(++cursor_y >= 25) {
                                __memcpy(screen, screen + 160, 24 * 160);
                                memsetw(screen + (24 * 160), 0x0720, 160);
                                cursor_y--;
                        }
                        cursor_char = (screen + (cursor_y * 80 * 2)
                                       + (cursor_x * 2));
                        if(c == '\n')
                                continue;
                }
                else if(c == '\t') {
                        int new_x = (cursor_x + 8) & ~7;
                        memsetw(cursor_char, 0x0720, new_x - cursor_x);
                        cursor_x = new_x;
                        cursor_char = (screen + (cursor_y * 80 * 2)
                                       + (cursor_x * 2));
                        continue;
                }
                *cursor_char++ = c;
                *cursor_char++ = 0x07;
                cursor_x++;
        }
}


void
print_string(const char *text)
{
        print_string_len(text, strlen(text));
}


static char printf_buf[1024];
#define IS_DIGIT(c) (((c) >= '0') && ((c) <= '9'))

/* Flags */
#define PF_MINUS 1
#define PF_PLUS  2
#define PF_SPC   4
#define PF_HASH  8
#define PF_ZERO  16
#define PF_SHORT 32
#define PF_LONG  64

/* Syntax of format specifiers in FMT is
                `% [FLAGS] [WIDTH] [.PRECISION] [TYPE] CONV'
   (without the spaces). FLAGS can be any of:

        `-' Left justify the contents of the field.
        `+' Put a plus character in front of positive signed integers.
        ` ' Put a space in from of positive signed integers (only if no `+').
        `#' Put `0' before octal numbers and `0x' or `0X' before hex ones.
        `0' Pad right-justified fields with zeros, not spaces.
        `*' Use the next argument as the field width.

   WIDTH is a decimal integer defining the field width (for justification
   purposes). Right justification is the default, use the `-' flag to
   change this.

   TYPE is an optional type conversion for integer arguments, it can be
   either `h' to specify a `short int' or `l' to specify a `long int'.

   CONV defines how to treat the argument, it can be one of:

        `i', `d'	A signed decimal integer.
        `u', `Z'	An unsigned decimal integer.
        `b'		Unsigned binary integer.
        `o'		A signed octal integer.
        `x', `X'	An unsigned hexadecimal integer, `x' gets lower-
                        case hex digits, `X' upper.
        `p'		A pointer, printed in hexadecimal with a preceding
                        `0x' (i.e. like `%#x') unless the pointer is NULL
                        when `(nil)' is printed.
        `c'		A character.
        `s'		A string.  */

/* If you're a goto-purist please avert your eyes.. There's more goto
   statements in this function than in every other piece of code I've
   ever written 8-) */

void
kvsprintf(char *buf, const char *fmt, va_list args)
{
        static const int FALSE = 0;
        static const int TRUE = 1;
        char c, *orig = buf;
    while((c = *fmt++) != 0)
    {
        if(c != '%')
            *buf++ = c;
        else
        {
            if(*fmt != '%')
            {
                int flags = 0;
                int width = 0;
                int precision = 0;
                int len = 0, num_len;
                unsigned long arg;

            again:
                switch((c = *fmt++))
                {
                case '-':
                    flags |= PF_MINUS;
                    goto again;

                case '*':
                    /* dynamic field width. */
                    width = va_arg(args, int);
                    goto again;

                case '+':
                    flags |= PF_PLUS;
                    goto again;

                case ' ':
                    flags |= PF_SPC;
                    goto again;

                case '#':
                    flags |= PF_HASH;
                    goto again;

                case '0':
                    flags |= PF_ZERO;
                    goto again;

                case '1': case '2': case '3': case '4': case '5':
                case '6': case '7': case '8': case '9':
                    while(IS_DIGIT(c))
                    {
                        width = width * 10 + (c - '0');
                        c = *fmt++;
                    }
                    fmt--;
                    goto again;

                case 'h':
                    flags |= PF_SHORT;
                    goto again;

                case 'l':
                case 'z':
                    flags |= PF_LONG;
                    goto again;

                case '.':
                    if((c = *fmt++) == '*')
                        precision = va_arg(args, int);
                    else
                    {
                        while(IS_DIGIT(c))
                        {
                            precision = precision * 10 + (c - '0');
                            c = *fmt++;
                        }
                        fmt--;
                    }
                    goto again;
                }

                if(flags & PF_LONG)
                        arg = va_arg(args, unsigned long long);
                else if(flags & PF_SHORT)
                    arg = (int16_t)va_arg(args, int);
                else
                    arg = (int32_t)va_arg(args, int);

                switch(c)
                {
                    char tmpbuf[40];
                    char *tmp;
                    char *digits;
                    int radix;
                    int is_signed;

                case 'n':
                    /* Store the number of characters output so far in *arg. */
                    *(int *)arg = buf - orig;
                    break;

                case 'i':
                case 'd':
                    is_signed = TRUE;
                    goto do_decimal;

                case 'u':
                case 'Z':
                    is_signed = FALSE;
                do_decimal:
                    digits = "0123456789";
                    radix = 10;
                    goto do_number;

                case 'o':
                    is_signed = TRUE;
                    digits = "01234567";
                    radix = 8;
                    if(flags & PF_HASH)
                    {
                        *buf++ = '0';
                        len++;
                    }
                    goto do_number;

                case 'b':
                    is_signed = FALSE;
                    digits = "01";
                    radix = 2;
                    if(flags & PF_HASH)
                    {
                        buf = stpcpy(buf, "0b");
                        len += 2;
                    }
                    goto do_number;

                case 'p':
                    if(arg == 0)
                    {
                        /* NULL pointer */
                        arg = (uint32_t)"(nil)";
                        goto do_string;
                    }
                    flags |= PF_HASH;
                    /* FALL THROUGH */

                case 'x':
                    digits = "0123456789abcdef";
                    if(flags & PF_HASH)
                    {
                        buf = stpcpy(buf, "0x");
                        len += 2;
                    }
                    goto do_hex;
                case 'X':
                    digits = "0123456789ABCDEF";
                    if(flags & PF_HASH)
                    {
                        buf = stpcpy(buf, "0X");
                        len += 2;
                    }
                do_hex:
                    is_signed = FALSE;
                    radix = 16;
                    /* FALL THROUGH */

                do_number:
                    if(is_signed)
                    {
                        if((long)arg < 0)
                        {
                            *buf++ = '-';
                            arg = (uint32_t)(0 - (long)arg);
                            len++;
                        }
                        else if(flags & PF_PLUS)
                        {
                            *buf++ = '+';
                            len++;
                        }
                        else if(flags & PF_SPC)
                        {
                            *buf++ = ' ';
                            len++;
                        }
                    }
                    num_len = len;
                    tmp = tmpbuf;
                    if(arg == 0)
                    {
                        *tmp++ = digits[0];
                        len++;
                    }
                    else
                    {
                        while(arg > 0)
                        {
                            *tmp++ = digits[arg % radix];
                            len++;
                            arg /= radix;
                        }
                    }
                    num_len = len - num_len;
                    if(precision != 0 && num_len < precision)
                    {
                        while(num_len--)
                        {
                            *tmp++ = digits[0];
                            len++;
                        }
                    }
                    if(width > len)
                    {
                        if(flags & PF_MINUS)
                        {
                            /* left justify. */
                            while(tmp != tmpbuf)
                                *buf++ = *(--tmp);
                            memset(buf, ' ', width - len);
                            buf += width - len;
                        }
                        else
                        {
                            memset(buf, (flags & PF_ZERO) ? '0' : ' ',
                                   width - len);
                            buf += width - len;
                            while(tmp != tmpbuf)
                                *buf++ = *(--tmp);
                        }
                    }
                    else
                    {
                        while(tmp != tmpbuf)
                            *buf++ = *(--tmp);
                    }
                    break;

                case 'c':
                    if(width > 1)
                    {
                        if(flags & PF_MINUS)
                        {
                            *buf = (char)c;
                            memset(buf+1, ' ', width - 1);
                            buf += width;
                        }
                        else
                        {
                            memset(buf, (flags & PF_ZERO) ? '0' : ' ', width - 1);
                            *buf += width;
                            buf[-1] = (char)c;
                        }
                    }
                    else
                        *buf++ = (char)arg;
                    break;

                case 's':
                do_string:
                    if((char *)arg == NULL)
                        arg = (uint32_t)"(nil)";
                    len = strlen((char *)arg);
                    if(precision > 0 && len > precision)
                        len = precision;
                    if(width > 0)
                    {
                        if(width <= len)
                            buf = stpcpy(buf, (char *)arg);
                        else
                        {
                            if(flags & PF_MINUS)
                            {
                                buf = stpcpy(buf, (char *)arg);
                                memset(buf, ' ', width - len);
                                buf += width - len;
                            }
                            else
                            {
                                memset(buf, (flags & PF_ZERO) ? '0' : ' ',
                                       width - len);
                                buf = stpcpy(buf + (width - len), (char *)arg);
                            }
                        }
                    }
                    else
                    {
                        __memcpy(buf, (char *)arg, len);
                        buf += len;
                        *buf = 0;
                    }
                    break;
                }
            }
            else
                *buf++ = *fmt++;
        }
    }
    *buf++ = 0;
}


void
ksprintf(char *buf, const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    kvsprintf(buf, fmt, args);
    va_end(args);
}

void
kvprintf(const char *fmt, va_list args)
{
        //uint32_t len;
    kvsprintf(printf_buf, fmt, args);
    //len = strlen(printf_buf);
    print_string(printf_buf);
}

void
kprintf(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    kvprintf(fmt, args);
    va_end(args);
}

void newline()
{
        // move to next line
        //offset += 159;
        //offset -= offset % 160;
        print_string("\n");
}


void print_char(char ch)
{
        kprintf("%c", ch);
}


void print_nibble(int value)
{
        static char *hex = "0123456789ABCDEF";
        print_char(hex[value & 0xf]);
}


void print_byte(int value)
{
        print_nibble((value >> 4) & 0xf);
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


void print_pointer(void *ptr)
{
        print_string("0x");
        print_qword((uintptr_t)ptr);
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
        //offset = 0;
        print_string("init_tty()");
        newline();
        print_sections();
        print_qword(0x1234567890ABCDEF);
        newline();
}

void
koops(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    print_string("OOPS: ");
    kvprintf(fmt, args);
    va_end(args);
    hlt();
}

