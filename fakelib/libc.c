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
// OSX symbol names
void *__stderrp = (void *)0xF2;
void *__stdinp = (void *)0xF0;
void *__stdoutp = (void *)0xF1;

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
 * pthread
 */

typedef struct pthread_mutex pthread_mutex_t;
typedef struct pthread_mutexaddr pthread_mutexattr_t;
typedef struct pthread_rw_lock pthread_rwlock_t;


int
pthread_mutex_init(pthread_mutex_t *restrict mutex, const pthread_mutexattr_t *restrict attr)
{
        debugf("pthread_mutex_init(%p,%p)\n", mutex, attr);
        return 0;
}


int
pthread_mutex_lock(pthread_mutex_t *mutex)
{
        debugf("pthread_mutex_lock(%p)\n", mutex);
        return 0;
}

int
pthread_mutex_unlock(pthread_mutex_t *mutex)
{
        debugf("pthread_mutex_unlock(%p)\n", mutex);
        return 0;
}


int
pthread_rwlock_rdlock(pthread_rwlock_t *rwlock)
{
        debugf("pthread_rwlock_rdlock(%p)\n", rwlock);
        return 0;
}


int
pthread_rwlock_unlock(pthread_rwlock_t *rwlock)
{
        debugf("pthread_rwlock_unlock(%p)\n", rwlock);
        return 0;
}


int
pthread_rwlock_wrlock(pthread_rwlock_t *rwlock)
{
        debugf("pthread_rwlock_wrlock(%p)\n", rwlock);
        return 0;
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


int
_IO_putc(int ch, void *stream)
{
        debugf("putc:(%c,%p)\n", ch, stream);
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


ssize_t
write(int fd, const void *buf, size_t nbyte)
{
        debugf("write(fd=%d, buf=%p nbyte=%lu\n", fd, buf, nbyte);

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
        // FIXME, needs a ksnprintf
        debugf("vasprintf(%p,%s)\n", strp, format);
        *strp = malloc(4080);
        int len = kvsprintf(*strp, format, argp);

        return len;
}


int
asprintf(char **strp, const char * restrict format, ...)
{
        debugf("asprintf(%p,%s)\n", strp, format);
        va_list argp;
        va_start(argp, format);
        int len = vasprintf(strp, format, argp);
        va_end(argp);

        return len;
}


int
vsnprintf(char * restrict buf, size_t size, const char *format, va_list argp)
{
        // FIXME: use the size, would need an ksnprintf
        debugf("vsnprintf(%s)\n", format);
        int len = ksprintf(buf, format, argp);

        return len;
}


int
snprintf(char * restrict buf, size_t size, const char * restrict format, ...)
{
        // FIXME: use the size, would need an ksnprintf
        debugf("snprintf(%s)\n", format);
        va_list argp;
        va_start(argp, format);
        int len = ksprintf(buf, format, argp);
        va_end(argp);

        return len;
}


/*
 * Math functions
 */

UNIMPLEMENTED(__divti3)
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


/*
 * Misc
 */


/* Only works for anonymous mmap (fd == -1), ignore protection settings for now
 * This is used to emulate the large malloc that stdlib does (which is remapped to malloc
 * here anyway
 */
void *mmap(void *addr, size_t len, int prot, int flags, int fd, unsigned long offset) {
        if (fd != -1) {
                koops("mmap with fd=%d!", fd);
        }

        void *result = malloc(len);
        debugf("mmap=(addr=%p,len=%lX,prot=%X,flags=%X,fd=%d,offset=%lX)=%p\n",
                addr, len, prot, flags, fd, offset, result);

        return result;
}


UNIMPLEMENTED(strtod_l)
UNIMPLEMENTED(strtof_l)
UNIMPLEMENTED(strtold_l)

UNIMPLEMENTED(sysconf)
UNIMPLEMENTED(trunc)
UNIMPLEMENTED(truncf)
