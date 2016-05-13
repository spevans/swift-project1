/*
 * fakelib/libc.c
 *
 * Created by Simon Evans on 07/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * Fake libc calls used by both Linux/ELF and OSX/Mach-O libswiftCore
 *
 */

#include "klibc.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"


// Default FILE * for stdio, faked values
// Linux symbol names
void *stderr = (void *)0xF2;
void *stdin = (void *)0xF0;
void *stdout = (void *)0xF1;


void
abort()
{
        koops("abort() called");
}


/*
 * I/O functions
 */

int
putchar(int ch)
{
        print_char(ch);
        return ch;
}
#if 0
int
putchar_unlocked(int ch)
{
        return putchar(ch);
}
#endif

int
_IO_putc(int ch, void *stream)
{
        debugf("putc('%c', %p)\n", ch, stream);
        if (stream != stderr && stream != stdout) {
                koops("putc stream = %p", stream);
        }
        print_char(ch);
        return ch;
}


int
fputc(int ch, void *stream)
{
        return _IO_putc(ch, stream);
}


int
putc(int ch, void *stream)
{
        return _IO_putc(ch, stream);
}

#if 0
int
fputs(const char *s, void *stream)
{
        debugf("fputs(\"%s\",%p)\n", s, stream);
        if (stream != stderr && stream != stdout) {
                koops("fputs stream = %p", stream);
        }
        print_string(s);

        return 0;
}
#endif

void
flockfile(void *stream)
{
        debugf("flockfile(%p)\n", stream);
        if (stream != stderr && stream != stdout) {
                koops("flockfile stream = %p", stream);
        }

}

size_t
fwrite(const void *ptr, size_t size, size_t nmemb, void *stream)
{
        debugf("fwrite(\"%s\", %lu, %lu, %p)", ptr, size, nmemb, stream);
        if (stream != stderr && stream != stdout) {
                koops("fwrite stream = %p", stream);
        }
        size_t len;
        if (__builtin_umull_overflow(size, nmemb, &len)) {
                koops("fwrite size too large (%lu,%lu)", size, nmemb);
        }
        print_string_len(ptr, len);

        return len;
}


void
funlockfile(void *stream)
{
        if (stream != stderr && stream != stdout) {
                koops("funlockfile stream = %p", stream);
        }
}


UNIMPLEMENTED(close)
UNIMPLEMENTED(read)
UNIMPLEMENTED(getline)


ssize_t
write(int fd, const void *buf, size_t nbyte)
{
        debugf("write(fd=%d, buf=%p nbyte=%lu)\n", fd, buf, nbyte);

        if (fd == 1 || fd == 2) {
                print_string_len(buf, nbyte);
        } else {
                koops("write() with fd = %d\n", fd);
        }
        return nbyte;
}


/*
 * printf
 */

int
fprintf(void *stream, const char *format, ...)
{
        if (stream != stderr && stream != stdout) {
                koops("fprintf stream = %p", stream);
        }
        va_list argp;
        va_start(argp, format);
        int len = kvprintf(format, argp);
        va_end(argp);

        return len;
}


int
vasprintf(char **strp, const char * restrict format, va_list argp)
{
        char buf[128];

        debugf("vasprintf(%p,%s)\n", strp, format);

        // len = number of characters in final string, not that fit in buffer
        // excludes terminating '\0'
        int len = kvsnprintf(buf, 128, format, argp);
        *strp = malloc(len + 1);
        if (*strp == NULL) {
                return -1;
        }

        if (len > 127) {
                return kvsnprintf(buf, len + 1, format, argp);
        } else {
                memcpy(*strp, buf, len + 1);
        }

        return len;
}


int
asprintf(char **strp, const char * restrict format, ...)
{
        va_list argp;
        va_start(argp, format);
        kvprintf(format, argp);
        // asprintf seems to only be used for assert() and fatal error messages
        // so stop here
        stop();
        int len = vasprintf(strp, format, argp);
        va_end(argp);

        return len;
}


int
vsnprintf(char * restrict buf, size_t size, const char *format, va_list argp)
{
        debugf("vsnprintf(%s)\n", format);
        int len = kvsnprintf(buf, size, format, argp);

        return len;
}


int
snprintf(char * restrict buf, size_t size, const char * restrict format, ...)
{
        debugf("snprintf(\"%s\", %lu)\n", format, size);
        va_list argp;
        va_start(argp, format);
        int len = kvsnprintf(buf, size, format, argp);
        va_end(argp);

        return len;
}


/*
 * Misc
 */

/* Only works for anonymous mmap (fd == -1), ignore protection settings for now
 * This is used to emulate the large malloc that stdlib does in
 * stdlib/public/runtime/Metadata.cpp (which is remapped to malloc here anyway)
 */
void
*mmap(void *addr, size_t len, int prot, int flags, int fd, unsigned long offset)
{
        if (fd != -1) {
                koops("mmap with fd=%d!", fd);
        }

        void *result = malloc(len);
        debugf("mmap(addr=%p, len=%lX, prot=%X, flags=%X, fd=%d, offset=%lX)=%p\n",
                addr, len, prot, flags, fd, offset, result);

        return result;
}


/* This is hopefully only used on the result of the above mmap */
int
munmap(void *addr, size_t length)
{
        debugf("munmap(addr=%p, len=%lX\n", addr, length);
        free(addr);

        return 0;
}


UNIMPLEMENTED(__divti3)
UNIMPLEMENTED(sysconf)
UNIMPLEMENTED(backtrace)


/* Floating point functions.
 * If using stdlib without FP functions these are not needed and MMX,SSE can
 * be disabled
 */

#if USE_FP
UNIMPLEMENTED(arc4random)
UNIMPLEMENTED(arc4random_uniform)
UNIMPLEMENTED(ceil)


float ceilf(float f)
{
        long result = (long)f;
        if ((float)result < f) {
                result++;
        }
        float resultf = (float)result;
        debugf("ceilf(%ld)=%ld\n", (long)f, (long)resultf);

        return resultf;
}

UNIMPLEMENTED(cos)
UNIMPLEMENTED(cosf)
UNIMPLEMENTED(exp)
UNIMPLEMENTED(exp2)
UNIMPLEMENTED(exp2f)
UNIMPLEMENTED(expf)
UNIMPLEMENTED(floor)
UNIMPLEMENTED(floorf)
UNIMPLEMENTED(fmod)
UNIMPLEMENTED(fmodf)
UNIMPLEMENTED(fmodl)
UNIMPLEMENTED(log)
UNIMPLEMENTED(log10)
UNIMPLEMENTED(log10f)
UNIMPLEMENTED(log2)
UNIMPLEMENTED(log2f)
UNIMPLEMENTED(logf)
UNIMPLEMENTED(nearbyint)
UNIMPLEMENTED(nearbyintf)
UNIMPLEMENTED(rint)
UNIMPLEMENTED(rintf)
UNIMPLEMENTED(round)
UNIMPLEMENTED(roundf)
UNIMPLEMENTED(sin)
UNIMPLEMENTED(sinf)
UNIMPLEMENTED(strtod_l)
UNIMPLEMENTED(strtof_l)
UNIMPLEMENTED(strtold_l)
UNIMPLEMENTED(trunc)
UNIMPLEMENTED(truncf)

#endif
