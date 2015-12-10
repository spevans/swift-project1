#include "klibc.h"


#pragma GCC diagnostic ignored "-Wunused-parameter"

extern uintptr_t _bss_end;
static uint64_t heap = (uint64_t)&_bss_end;


void
hlt()
{
        asm volatile ("hlt" : : : "memory");
        __builtin_unreachable ();
}



void free(void *ptr)
{
        kprintf("free(%p)\n", ptr);
}



void *mmap(void *addr, size_t len, int prot, int flags, int fd, int64_t offset) {
        const int align = 4096-1;

        heap = (heap + align) & ~align;
        char *result = (char *)heap;
        heap += len;

        kprintf("mmap=(addr=%p,len=%lX,prot=%X,flags=%X,fd=%d,offset=%lX)=%p\n",
                addr, len, prot, flags, fd, offset, result);

        return result;
}


void *malloc(size_t size)
{
        const int align = 16-1;

        heap = (heap + align) & ~align;
        char *result = (char *)heap;
        heap += size;

        //kprintf("malloc(%lu), result=%p heap=%lX\n", size, result, heap);

        return result;
}


int
memcmp(const void *s1, const void *s2, size_t n)
{
        kprintf("memcmp(%p,%p,%lu)=", s1, s2, n);

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
                      : "0" (s1), "1" (s2), "2" (n)
                      : "memory");

        kprintf("%d\n", res);
        return res;
}



//void memcpy() { koops("Calling memcpy\n"); }

void *memcpy(void *restrict dst, const void *restrict src, size_t n)
{
        kprintf("memcpy(dst=%p,src=%p,count=%lu\n", dst, src, n);
        __memcpy(dst, src, n);
        return dst;
}


UNIMPLEMENTED(memmove)


void *
memset(void *s, char c, size_t count)
{
        kprintf("memset(%p,%d,%lu)\n", s, c, count);

        int d0, d1, d2;
        asm volatile ("cld\n\t"
                      "rep\n\t"
                      "stosb"
                      : "=&D" (d0), "=&a" (d1), "=&c" (d2)
                      : "0" (s), "1" (c), "2" (count) : "memory");
        return s;
}


UNIMPLEMENTED(memset_pattern8)
UNIMPLEMENTED(strchr)

int
strcmp(const char *cs, const char *ct)
{
        kprintf("strcmp(%s, %s)\n", cs, ct);
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

void strdup() { koops("Calling strdup\n"); }


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


UNIMPLEMENTED(strncmp)
UNIMPLEMENTED(strndup)
