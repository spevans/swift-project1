/*
 * fakelib/libc.c
 *
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Fake libc calls used by both Linux/ELF and OSX/Mach-O libswiftCore
 *
 */

#include "klibc.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

typedef long dispatch_once_t;


// defined constants
void *__stderrp = (void *)0xF2; // FILE *
void *__stdinp = (void *)0xF0; // FILE *
void *__stdoutp = (void *)0xF1; // FILE *
void *stderr = (void *)0xF2; // FILE *
void *stdin = (void *)0xF0; // FILE *
void *stdout = (void *)0xF1; // FILE *


void
abort()
{
        koops("abort() called");
}


void
__assert_rtn(const char *function, const char *file, int line, const char *err)
{
        kprintf("assert:%s:%s:%d:%s\n", file, function, line, err);
        hlt();
}


void
__assert_fail()
{
        koops("__assert_fail");
}


UNIMPLEMENTED(__divti3)
UNIMPLEMENTED(__error)
UNIMPLEMENTED(__errno_location)
UNIMPLEMENTED(__getdelim)
UNIMPLEMENTED(arc4random)
UNIMPLEMENTED(arc4random_uniform)
UNIMPLEMENTED(close)


typedef void *asl_object_t;
int asl_log(asl_object_t client, asl_object_t msg, int level, const char *format, ...)
{
        kprintf("asl_log(level=%d)\n", level);
        va_list argp;
        kvprintf(format, argp);
        va_end(argp);

        return 0;
}


int
asprintf(char **strp, const char * restrict format, ...)
{
        char buf[2048];
        // FIXME: use the size

        va_list argp;
        va_start(argp, format);
        kvsprintf(buf, format, argp);
        va_end(argp);

        size_t len = strlen(buf);
        char *result = malloc(len);
        memcpy(result, buf, len+1);
        *strp = result;

        return len;
}


UNIMPLEMENTED(ceil)

float ceilf(float f)
{
        long result = (long)f;
        if ((float)result < f) {
                result++;
        }
        float resultf = (float)result;
        kprintf("ceilf(%ld)=%ld\n", (long)f, (long)resultf);

        return resultf;
}


UNIMPLEMENTED(cos)
UNIMPLEMENTED(cosf)

//void dispatch_once() { koops("Calling dispatch_once\n"); }

//void dispatch_once_f() { koops("Calling dispatch_once_f\n"); }
typedef long dispatch_once_t;
void dispatch_once_f(dispatch_once_t *predicate, void *context, void (*function)(void *)) {
        kprintf("dispatch_once_t(%p,%p,%p)\n", predicate, context, function);
        if(*predicate == 0) {
                *predicate = ~0L;
                function(context);
        }
}

//void dladdr() { koops("Calling dladdr\n"); }

UNIMPLEMENTED(_dyld_register_func_for_add_image)
UNIMPLEMENTED(dyld_stub_binder)
UNIMPLEMENTED(dlopen)
UNIMPLEMENTED(dlclose)
UNIMPLEMENTED(dlsym)

// FIXME
int
dl_iterate_phdr(void *funcptr, void *data)
{
        kprintf("dl_iterate_phdr(%p,%p)\n", funcptr, data);
        return 0;
}



UNIMPLEMENTED(exp)
UNIMPLEMENTED(exp2)
UNIMPLEMENTED(exp2f)
UNIMPLEMENTED(expf)

void
flockfile(void *file)
{
        kprintf("flockfile(%p)\n", file);
}


UNIMPLEMENTED(floor)
UNIMPLEMENTED(floorf)
UNIMPLEMENTED(fmod)
UNIMPLEMENTED(fmodf)
UNIMPLEMENTED(fmodl)
UNIMPLEMENTED(fprintf)
UNIMPLEMENTED(fwrite)



UNIMPLEMENTED(funlockfile)
UNIMPLEMENTED(getline)
UNIMPLEMENTED(getsectiondata)
UNIMPLEMENTED(log)
UNIMPLEMENTED(log10)
UNIMPLEMENTED(log10f)
UNIMPLEMENTED(log2)
UNIMPLEMENTED(log2f)
UNIMPLEMENTED(logf)


//UNIMPLEMENTED(malloc_zone_from_ptr)

UNIMPLEMENTED(memchr)

UNIMPLEMENTED(nearbyint)
UNIMPLEMENTED(nearbyintf)
UNIMPLEMENTED(newlocale)
UNIMPLEMENTED(uselocale)

//void printf() { koops("Calling printf\n"); }




__thread void* _ZSt15__once_callable;
__thread void (*_ZSt11__once_call)();

void __once_proxy()
{
        kprintf("__once_proxy_func() __once_call=%p\n", _ZSt11__once_call);
        if (_ZSt11__once_call) _ZSt11__once_call();
        print_string("__once_proxy_func() finished\n");
}



typedef int pthread_once_t;

int
pthread_once(pthread_once_t *once_control, void (*init_routine)(void))
{
        kprintf("pthread_once(%p,%d %p)\n", once_control, *once_control, init_routine);
        init_routine();
        kprintf("init_routine finished\n");
        return 0;
}


#  define __SIZEOF_PTHREAD_MUTEX_T 40
#  define __SIZEOF_PTHREAD_MUTEXATTR_T 4

typedef struct __pthread_internal_list
{
  struct __pthread_internal_list *__prev;
  struct __pthread_internal_list *__next;
} __pthread_list_t;
typedef union
{
  struct __pthread_mutex_s
  {
    int __lock;
    unsigned int __count;
    int __owner;
    unsigned int __nusers;
    /* KIND must stay at this position in the structure to maintain
       binary compatibility.  */
    int __kind;
    short __spins;
    short __elision;
    __pthread_list_t __list;
# define __PTHREAD_MUTEX_HAVE_PREV      1
# define __PTHREAD_MUTEX_HAVE_ELISION   1
  } __data;
  char __size[__SIZEOF_PTHREAD_MUTEX_T];
  long int __align;
} pthread_mutex_t;

typedef union
{
  char __size[__SIZEOF_PTHREAD_MUTEXATTR_T];
  int __align;
} pthread_mutexattr_t;

typedef unsigned int pthread_key_t;

int __pthread_key_create (pthread_key_t *key,
                          void (*destructor) (void *))
{
        kprintf("pthread_key_create(%p,%p)\n", key, destructor);
        koops("unimplemented");
}


int
pthread_mutex_init(pthread_mutex_t *restrict mutex, const pthread_mutexattr_t *restrict attr)
{
        kprintf("pthread_mutex_init(%p,%p)\n", mutex, attr);
        return 0;
}


int
pthread_mutex_lock(pthread_mutex_t *mutex)
{
        kprintf("pthread_mutex_lock(%p)\n", mutex);
        return 0;
}

int
pthread_mutex_unlock(pthread_mutex_t *mutex)
{
        kprintf("pthread_mutex_unlock(%p)\n", mutex);
        return 0;
}

#  define __SIZEOF_PTHREAD_RWLOCK_T 56

typedef union
{
  struct
  {
    int __lock;
    unsigned int __nr_readers;
    unsigned int __readers_wakeup;
    unsigned int __writer_wakeup;
    unsigned int __nr_readers_queued;
    unsigned int __nr_writers_queued;
    int __writer;
    int __shared;
    unsigned long int __pad1;
    unsigned long int __pad2;
    /* FLAGS must stay at this position in the structure to maintain
       binary compatibility.  */
    unsigned int __flags;
# define __PTHREAD_RWLOCK_INT_FLAGS_SHARED      1
  } __data;
  char __size[__SIZEOF_PTHREAD_RWLOCK_T];
  long int __align;
} pthread_rwlock_t;



int
pthread_rwlock_rdlock(pthread_rwlock_t *rwlock)
{
        //kprintf("pthread_rwlock_rdlock(%p)\n", rwlock);
        return 0;
}


int
pthread_rwlock_unlock(pthread_rwlock_t *rwlock)
{
        //kprintf("pthread_rwlock_unlock(%p)\n", rwlock);
        return 0;
}


int
pthread_rwlock_wrlock(pthread_rwlock_t *rwlock)
{
        //kprintf("pthread_rwlock_wrlock(%p)\n", rwlock);
        return 0;
}


int
putchar(int ch)
{
        print_char(ch);
        return ch;
}


int
_IO_putc(int ch, void *stream)
{
        kprintf("putc:(%c,%p)\n", ch, stream);
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


UNIMPLEMENTED(read)
UNIMPLEMENTED(rint)
UNIMPLEMENTED(rintf)
UNIMPLEMENTED(round)
UNIMPLEMENTED(roundf)
UNIMPLEMENTED(sin)
UNIMPLEMENTED(sinf)

int
snprintf(char * restrict buf, size_t size, const char * restrict format, ...)
{
        // FIXME: use the size
        kprintf("snprintf(%s)=", format);
        va_list argp;
        ksprintf(buf, format, argp);
        va_end(argp);
        print_string(buf);

        return strlen(buf);
}


UNIMPLEMENTED(snprintf_l)
UNIMPLEMENTED(strtod_l)
UNIMPLEMENTED(strtof_l)
UNIMPLEMENTED(strtold_l)

UNIMPLEMENTED(sysconf)
UNIMPLEMENTED(trunc)
UNIMPLEMENTED(truncf)
UNIMPLEMENTED(vasprintf)
UNIMPLEMENTED(vsnprintf)

ssize_t
write(int fd, const void *buf, size_t nbyte)
{
        kprintf("write(fd=%d, buf=%p nbyte=%lu\n",
                fd, buf, nbyte);

        if (fd == 1 || fd == 2) {
                print_string_len(buf, nbyte);
        } else {
                koops("write() with fd = %d\n", fd);
        }
        return nbyte;
}



UNIMPLEMENTED(__stack_chk_fail)
UNIMPLEMENTED(__stack_chk_guard)

// Unicode
UNIMPLEMENTED(ucol_closeElements_52)
UNIMPLEMENTED(ucol_next_52)
UNIMPLEMENTED(ucol_open_52)
UNIMPLEMENTED(ucol_openElements_52)
UNIMPLEMENTED(ucol_setAttribute_52)
UNIMPLEMENTED(ucol_strcoll_52)
UNIMPLEMENTED(uiter_setString_52)
UNIMPLEMENTED(uiter_setUTF8_52)
UNIMPLEMENTED(u_strToLower_52)
UNIMPLEMENTED(u_strToUpper_52)
UNIMPLEMENTED(ucol_strcollIter_52)
