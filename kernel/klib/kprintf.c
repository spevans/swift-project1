/*
 * kernel/klibc/kprintf.c
 *
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * printf style functions
 *
 */

#ifndef TESTS
#include "klibc.h"
#else
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#endif


extern void (early_print_char)(const char ch);
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


int
kvsprintf(char *buf, const char *fmt, va_list args)
{
        static const int FALSE = 0;
        static const int TRUE = 1;
        char c, *orig = buf;
        while((c = *fmt++) != 0) {
                if(c != '%') {
                        *buf++ = c;
                } else {
                        if(*fmt != '%') {
                                int flags = 0;
                                int width = 0;
                                int precision = 0;
                                int len = 0, num_len;
                                unsigned long arg;

                        again:
                                switch((c = *fmt++)) {
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
                                        while(IS_DIGIT(c)) {
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
                                        if((c = *fmt++) == '*') {
                                                precision = va_arg(args, int);
                                        } else {
                                                while(IS_DIGIT(c)) {
                                                        precision = precision * 10 + (c - '0');
                                                        c = *fmt++;
                                                }
                                                fmt--;
                                        }
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
                                        arg = (int32_t)va_arg(args, int);
                                }

                                switch(c) {
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
                                        if(flags & PF_HASH) {
                                                *buf++ = '0';
                                                len++;
                                        }
                                        goto do_number;

                                case 'b':
                                        is_signed = FALSE;
                                        digits = "01";
                                        radix = 2;
                                        if(flags & PF_HASH) {
                                                buf = stpcpy(buf, "0b");
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
                                                buf = stpcpy(buf, "0x");
                                                len += 2;
                                        }
                                        goto do_hex;
                                case 'X':
                                        digits = "0123456789ABCDEF";
                                        if(flags & PF_HASH) {
                                                buf = stpcpy(buf, "0x");
                                                len += 2;
                                        }
                                do_hex:
                                        is_signed = FALSE;
                                        radix = 16;
                                        /* FALL THROUGH */

                                do_number:
                                        if(is_signed) {
                                                if((long)arg < 0) {
                                                        *buf++ = '-';
                                                        arg = (uint32_t)(0 - (long)arg);
                                                        len++;
                                                }
                                                else if(flags & PF_PLUS) {
                                                        *buf++ = '+';
                                                        len++;
                                                }
                                                else if(flags & PF_SPC) {
                                                        *buf++ = ' ';
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
                                                        while(tmp != tmpbuf)
                                                                *buf++ = *(--tmp);
                                                        memset(buf, ' ', width - len);
                                                        buf += width - len;
                                                } else {
                                                        memset(buf, (flags & PF_ZERO) ? '0' : ' ',
                                                               width - len);
                                                        buf += width - len;
                                                        while(tmp != tmpbuf)
                                                                *buf++ = *(--tmp);
                                                }
                                        } else {
                                                while(tmp != tmpbuf)
                                                        *buf++ = *(--tmp);
                                        }
                                        break;

                                case 'c':
                                        if(width > 1) {
                                                if(flags & PF_MINUS) {
                                                        *buf = (char)c;
                                                        memset(buf+1, ' ', width - 1);
                                                        buf += width;
                                                } else {
                                                        memset(buf, (flags & PF_ZERO) ? '0' : ' ', width - 1);
                                                        *buf += width;
                                                        buf[-1] = (char)c;
                                                }
                                        } else {
                                                *buf++ = (char)arg;
                                        }
                                        break;

                                case 's':
                                do_string:
                                        if((char *)arg == NULL) {
                                                arg = (uint64_t)"(nil)";
                                        }
                                        len = strlen((char *)arg);
                                        if(precision > 0 && len > precision) {
                                                len = precision;
                                        }
                                        if(width > 0) {
                                                if(width <= len) {
                                                        buf = stpcpy(buf, (char *)arg);
                                                } else {
                                                        if(flags & PF_MINUS) {
                                                                buf = stpcpy(buf, (char *)arg);
                                                                memset(buf, ' ', width - len);
                                                                buf += width - len;
                                                        } else {
                                                                memset(buf, (flags & PF_ZERO) ? '0' : ' ',
                                                                       width - len);
                                                                buf = stpcpy(buf + (width - len), (char *)arg);
                                                        }
                                                }
                                        } else {
                                                memcpy(buf, (char *)arg, len);
                                                buf += len;
                                                *buf = 0;
                                        }
                                        break;
                                }
                        } else {
                                *buf++ = *fmt++;
                        }
                }
        }
        *buf++ = 0;

        return buf - orig;
}


int
ksprintf(char *buf, const char *fmt, ...)
{
        va_list args;
        va_start(args, fmt);
        int len = kvsprintf(buf, fmt, args);
        va_end(args);

        return len;
}


int
kvprintf(const char *fmt, va_list args)
{
        int len = kvsprintf(printf_buf, fmt, args);
        char *text = printf_buf;
        while(*text) {
                early_print_char(*text++);
        }

        return len;
}


int
kprintf(const char *fmt, ...)
{
        va_list args;
        va_start(args, fmt);
        int len = kvprintf(fmt, args);
        va_end(args);

        return len;
}
