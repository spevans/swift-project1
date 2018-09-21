/*
 * klibc/kprintf.c
 *
 * Copyright © 2015 - 2018 Simon Evans. All rights reserved.
 *
 * printf style functions.
 *
 */

#ifndef TESTS
#include "klibc.h"
#else
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#endif


void early_print_char(const char ch);
void early_print_string(const char *text);
typedef void (*print_char_func)(void *data, char ch);

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


static inline void
_print_char(print_char_func print_func, void *data, int *count, const char ch)
{
        print_func(data, ch);
        (*count)++;
}


static inline void
_print_string(print_char_func print_func, void *data, int *count, const char *str)
{
        while(*str) {
                print_func(data, *str);
                str++;
                (*count)++;
        }
}


static inline void
_print_repeat(print_char_func print_func, void *data, int *count, const char ch, size_t repeat)
{
        while(repeat--) {
                print_func(data, ch);
                (*count)++;
        }
}


static inline char
next_char(const char **s, size_t *len)
{
        if (**s == '\0' || *len == 0) {
                return 0;
        }
        char ch = **s;
        (*len)--;
        (*s)++;

        return ch;
}


static int
__kvprintf(print_char_func print_func, void *data, const char *fmt, size_t fmtlen, va_list args)
{
        static const int FALSE = 0;
        static const int TRUE = 1;
        char c;
        int count = 0;

        while((c = next_char(&fmt, &fmtlen)) != 0) {
                if(c != '%') {
                        _print_char(print_func, data, &count, c);
                } else {
                        c = next_char(&fmt, &fmtlen);
                        if (c == 0) { // Error, incomplete format string
                                return -1;
                        } else if(c != '%') {
                                int flags = 0;
                                int width = 0;
                                int precision = 0;
                                int len = 0, num_len;
                                uintptr_t arg;
                                fmt--;
                                fmtlen++;

                        again:
                                c = next_char(&fmt, &fmtlen);
                                if (c == 0) {
                                        return -1;
                                }
                                switch(c) {
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

                                case '1': case '2': case '3':
                                case '4': case '5': case '6':
                                case '7': case '8': case '9':
                                        while(IS_DIGIT(c)) {
                                                width = width * 10 + (c - '0');
                                                c = next_char(&fmt, &fmtlen);
                                                if (c == 0) {
                                                        return -1;
                                                }
                                        }
                                        fmt--;
                                        fmtlen++;
                                        goto again;

                                case 'h':
                                        flags |= PF_SHORT;
                                        goto again;

                                case 'l':
                                case 'z':
                                        flags |= PF_LONG;
                                        goto again;

                                case '.':
                                        c = next_char(&fmt, &fmtlen);
                                        if (c == 0) {
                                                return -1;
                                        }
                                        if(c == '*') {
                                                precision = va_arg(args, int);
                                        } else {
                                                while(IS_DIGIT(c)) {
                                                        precision = precision * 10 + (c - '0');
                                                        c = next_char(&fmt, &fmtlen);
                                                        if (c == 0) {
                                                                return -1;
                                                        }
                                                }
                                                fmt--;
                                                fmtlen++;
                                        }
                                        goto again;

                                case 't':
                                        flags |= PF_LONG;
                                        goto again;

                                case 'p':
                                        flags |= PF_LONG;
                                        break;
                                }

                                if(flags & PF_LONG) {
                                        arg = va_arg(args, unsigned long long);
                                } else if(flags & PF_SHORT) {
                                        arg = (int16_t)va_arg(args, int);
                                } else {
                                        arg = (uintptr_t)va_arg(args, uintptr_t);
                                }

                                switch(c) {
                                        char tmpbuf[40];
                                        char *tmp;
                                        char *digits;
                                        int radix;
                                        int is_signed;

                                case 'n':
                                        /* Store the number of characters output so far in *arg. */
                                        *(int *)arg = count;
                                        break;

                                case 'i':
                                case 'd':
                                        is_signed = TRUE;
                                        goto do_decimal;

                                case 'u':
                                case 'Z':
                                        arg &= UINT_MAX;
                                        is_signed = FALSE;
                                do_decimal:
                                        digits = "0123456789";
                                        radix = 10;
                                        goto do_number;

                                case 'o':
                                        is_signed = TRUE;
                                        digits = "01234567";
                                        radix = 8;
                                        if(flags & PF_HASH) {
                                                _print_char(print_func, data,
                                                            &count, '0');
                                                len++;
                                        }
                                        goto do_number;

                                case 'b':
                                        is_signed = FALSE;
                                        digits = "01";
                                        radix = 2;
                                        if(flags & PF_HASH) {
                                                _print_string(print_func, data,
                                                              &count, "0b");
                                                len += 2;
                                        }
                                        goto do_number;

                                case 'p':
                                        if(arg == 0) {
                                                /* NULL pointer */
                                                arg = (uint64_t)"(nil)";
                                                goto do_string;
                                        }
                                        flags |= PF_HASH;
                                        /* FALL THROUGH */

                                case 'x':
                                        digits = "0123456789abcdef";
                                        if(flags & PF_HASH) {
                                                _print_string(print_func, data,
                                                              &count, "0x");
                                                len += 2;
                                        }
                                        goto do_hex;
                                case 'X':
                                        digits = "0123456789ABCDEF";
                                        if(flags & PF_HASH) {
                                                _print_string(print_func, data,
                                                              &count, "0x");
                                                len += 2;
                                        }
                                do_hex:
                                        is_signed = FALSE;
                                        radix = 16;
                                        /* FALL THROUGH */

                                do_number:
                                        if(is_signed) {
                                                if((long)arg < 0) {
                                                        _print_char(print_func, data, &count, '-');
                                                        arg = (uint32_t)(0 - (long)arg);
                                                        len++;
                                                }
                                                else if(flags & PF_PLUS) {
                                                        _print_char(print_func, data, &count, '+');
                                                        len++;
                                                }
                                                else if(flags & PF_SPC) {
                                                        _print_char(print_func, data, &count, ' ');
                                                        len++;
                                                }
                                        }
                                        num_len = len;
                                        tmp = tmpbuf;
                                        if(arg == 0) {
                                                *tmp++ = digits[0];
                                                len++;
                                        } else {
                                                while(arg > 0) {
                                                        *tmp++ = digits[arg % radix];
                                                        len++;
                                                        arg /= radix;
                                                }
                                        }
                                        num_len = len - num_len;
                                        if(precision != 0 && len < precision) {
                                                while(len < precision) {
                                                        *tmp++ = digits[0];
                                                        len++;
                                                }
                                        }
                                        if(width > len) {
                                                if(flags & PF_MINUS) {
                                                        /* left justify. */
                                                        while(tmp != tmpbuf) {
                                                                _print_char(print_func, data, &count, *(--tmp));
                                                        }
                                                        _print_repeat(print_func, data, &count, ' ', width - len);
                                                } else {
                                                        _print_repeat(print_func, data, &count, (flags & PF_ZERO) ? '0' : ' ', width - len);
                                                        while(tmp != tmpbuf) {
                                                                _print_char(print_func, data, &count, *(--tmp));
                                                        }
                                                }
                                        } else {
                                                while(tmp != tmpbuf) {
                                                        _print_char(print_func, data, &count, *(--tmp));
                                                }
                                        }
                                        break;

                                case 'c':
                                        if(width > 1) {
                                                if(flags & PF_MINUS) {
                                                        _print_char(print_func, data, &count, c);
                                                        _print_repeat(print_func, data, &count, ' ', width - 1);
                                                } else {
                                                        _print_repeat(print_func, data, &count,
                                                                      (flags & PF_ZERO) ? '0' : ' ', width - 1);
                                                        _print_char(print_func, data, &count, c);
                                                }
                                        } else {
                                                _print_char(print_func, data, &count, (char)arg);
                                        }
                                        break;

                                case 's':
                                do_string:
                                        if((char *)arg == NULL) {
                                                arg = (uintptr_t)"(nil)";
                                        }
                                        len = strlen((char *)arg);
                                        if(precision > 0 && len > precision) {
                                                len = precision;
                                        }
                                        if(width > 0) {
                                                if(width <= len) {
                                                        _print_string(print_func, data, &count, (char *)arg);
                                                } else {
                                                        if(flags & PF_MINUS) {
                                                                _print_string(print_func, data, &count, (char *)arg);
                                                                _print_repeat(print_func, data, &count, ' ', width - len);
                                                        } else {
                                                                _print_repeat(print_func, data, &count, (flags & PF_ZERO) ? '0' : ' ', width - len);
                                                                _print_string(print_func, data, &count, (char *)arg);
                                                        }
                                                }
                                        } else {
                                                char *p = (char *)arg;
                                                while(len--) {
                                                        print_func(data, *p++);
                                                        count++;
                                                }
                                        }
                                        break;
                                }
                        } else {
                                _print_char(print_func, data, &count, c);
                        }
                }
        }

        return count;
}


struct string_buf {
        char *data;
        size_t count;
        size_t max_len;
};


static void
b_print_char(void *buf_p, char ch)
{
        struct string_buf *buf = buf_p;
        if (buf->count+1 < buf->max_len) {
                *(buf->data + buf->count) = ch;
                buf->count++;
                *(buf->data + buf->count) = '\0';
        }
}


int
kvsnprintf(char *buf, size_t size, const char *fmt, va_list args)
{
        struct string_buf string_buf = { .data = buf, .count = 0,
                                         .max_len = size };
        if (size < 1) {
                return 0;
        }
        *buf = '\0';

        return __kvprintf(b_print_char, &string_buf, fmt, SIZE_MAX, args);
}


int
ksnprintf(char *buf, size_t size, const char *fmt, ...)
{
        va_list args;
        va_start(args, fmt);
        int len = kvsnprintf(buf, size, fmt, args);
        va_end(args);

        return len;
}


static void
k_print_char(void *data __attribute__((unused)), char ch)
{
        early_print_char(ch);
}


int
kvprintf(const char *fmt, va_list args)
{
        return __kvprintf(k_print_char, NULL, fmt, SIZE_MAX, args);
}


int
kvlprintf(const char *fmt, size_t len, va_list args)
{
        return __kvprintf(k_print_char, NULL, fmt, len, args);
}

int
kprintf(const char *fmt, ...)
{
        va_list args;
        va_start(args, fmt);
        int len = __kvprintf(k_print_char, NULL, fmt, SIZE_MAX, args);
        va_end(args);

        return len;
}

int
kprintf1arg(const char *fmt, long l1)
{
        return kprintf(fmt, l1);
}

int
kprintf2args(const char *fmt, long l1, long l2)
{
        return kprintf(fmt, l1, l2);
}

int
kprintf3args(const char *fmt, long l1, long l2, long l3)
{
        return kprintf(fmt, l1, l2, l3);
}


#ifndef TESTS
// Print to the bochs console, requires 'port_e9_hack: enabled=1' in the bochsrc
static void
bochs_print_char(void *data __attribute__((unused)), const char c)
{
        outb(0xe9, c);
}


void
bochs_print_string(const char *str, size_t len)
{
        while(*str) {
                if (len == 0) {
                        return;
                }
                outb(0xe9, *str++);
                len--;
        }
}

// bprintf, printf but to the bochs console, used by debugf
int
bprintf(const char *fmt, ...)
{
        va_list args;
        va_start(args, fmt);
        int len = __kvprintf(bochs_print_char, NULL, fmt, SIZE_MAX, args);
        va_end(args);

        return len;
}


#ifndef EFI
static void
serial_print_func(void *data __attribute__((unused)), const char c)
{
        serial_print_char(c);
}


int
serial_printf(const char *fmt, ...)
{
        va_list args;
        va_start(args, fmt);
        int len = __kvprintf(serial_print_func, NULL, fmt, SIZE_MAX, args);
        va_end(args);

        return len;
}
#endif // EFI


#endif // TEST
