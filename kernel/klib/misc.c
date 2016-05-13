/*
 * kernel/klibc/misc.c
 *
 * Created by Simon Evans on 10/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * Miscellaneous functions mostly string/memory
 *
 */

#include "klibc.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"


void
koops(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    kprintf("OOPS: ");
    kvprintf(fmt, args);
    va_end(args);
    stop();
}


void *
memset(void *dest, int c, size_t count)
{
        debugf("memset(%p,%u,%lu)\n", dest, (uint8_t)c, count);

        int d0, d1, d2;
        asm volatile ("cld\n\t"
                      "rep\n\t"
                      "stosb"
                      : "=&D" (d0), "=&a" (d1), "=&c" (d2)
                      : "0" (dest), "1" (c), "2" (count) : "memory");
        return dest;
}


int
strcmp(const char *cs, const char *ct)
{
        debugf("strcmp(%s, %s)\n", cs, ct);
        int d0, d1;
        int res;
        asm volatile("cld\n\t"
                     "1:\tlodsb\n\t"
                     "scasb\n\t"
                     "jne 2f\n\t"
                     "testb %%al,%%al\n\t"
                     "jne 1b\n\t"
                     "xorl %%eax,%%eax\n\t"
                     "jmp 3f\n"
                     "2:\tsbbl %%eax,%%eax\n\t"
                     "orb $1,%%al\n"
                     "3:"
                     : "=a" (res), "=&S" (d0), "=&D" (d1)
                     : "1" (cs), "2" (ct)
                     : "memory");
        return res;
}


char *
strcpy(char *dest, const char *src)
{
        int d0, d1, d2;
        asm volatile("cld\n\t"
                     "1:\tlodsb\n\t"
                     "stosb\n\t"
                     "testb %%al,%%al\n\t"
                     "jne 1b"
                     : "=&S" (d0), "=&D" (d1), "=&a" (d2)
                     : "0" (src), "1" (dest) : "memory");
        return dest;
}


size_t
strlen(const char *s)
{
        size_t d0;
        size_t res;
        asm volatile("cld\n\t"
                     "repne\n\t"
                     "scasb"
                     : "=c" (res), "=&D" (d0)
                     : "1" (s), "a" (0), "0" (0xffffffffffffffffu)
                     : "memory");
        return ~res - 1;
}


char *
strdup(const char *s)
{
        size_t len = strlen(s);
        char *dup = malloc(len + 1);
        if (dup != NULL) {
                strcpy(dup, s);
        }

        return dup;
}


char *
strndup(const char *s, size_t n)
{
        size_t len = strlen(s);
        if (len > n) {
                len = n;
        }

        char *dup = malloc(len + 1);
        if (dup != NULL) {
                memcpy(dup, s, len);
                *(dup + len) = '\0';
        }

        return dup;
}


UNIMPLEMENTED(memset_pattern8)
UNIMPLEMENTED(strncmp)
