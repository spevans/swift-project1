/*
 * kernel/klibc.c
 *
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Miscellaneous functions mostly string/memory
 *
 */

#include "klibc.h"


#pragma GCC diagnostic ignored "-Wunused-parameter"


void
hlt()
{
        asm volatile ("hlt" : : : "memory");
        __builtin_unreachable ();
}


int
memcmp(const void *s1, const void *s2, size_t count)
{
        dprintf("memcmp(%p,%p,%lu)=", s1, s2, count);

        int d0, d1, d2;
        int res;

        asm volatile ("cld\n\t"
                      "repe\n\t"
                      "cmpsb\n\t"
                      "je 1f\n\t"
                      "movl $1,%%eax\n\t"
                      "jb 1f\n\t"
                      "negl %%eax\n"
                      "1:"
                      : "=&D" (d0), "=&S" (d1), "=&c" (d2), "=&a" (res)
                      : "0" (s1), "1" (s2), "2" (count)
                      : "memory");

        dprintf("%d\n", res);

        return res;
}


void
*memcpy(void *restrict dest, const void *restrict src, size_t count)
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
                      : "0" (src), "1" (dest), "2" (count)
                      : "memory", "cx");
        return dest;
}


UNIMPLEMENTED(memmove)


void *
memset(void *dest, char c, size_t count)
{
        dprintf("memset(%p,%u,%lu)\n", dest, (uint8_t)c, count);

        int d0, d1, d2;
        asm volatile ("cld\n\t"
                      "rep\n\t"
                      "stosb"
                      : "=&D" (d0), "=&a" (d1), "=&c" (d2)
                      : "0" (dest), "1" (c), "2" (count) : "memory");
        return dest;
}


UNIMPLEMENTED(memset_pattern8)



int
strcmp(const char *cs, const char *ct)
{
        dprintf("strcmp(%s, %s)\n", cs, ct);
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
strcpy(char *restrict dest, const char *restrict src)
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


UNIMPLEMENTED(strchr)
UNIMPLEMENTED(strdup)
UNIMPLEMENTED(strncmp)
UNIMPLEMENTED(strndup)
