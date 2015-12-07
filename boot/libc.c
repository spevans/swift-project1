#include <stdint.h>
#include <stddef.h>
#include <stdarg.h>
#include "klib.h"

#define UNIMPLEMENTED(x)  void x() { koops(__func__); }

#pragma GCC diagnostic ignored "-Wunused-parameter"

extern uintptr_t _bss_end;
typedef long dispatch_once_t;



void
hlt()
{
        asm volatile ("hlt" : : : "memory");
        __builtin_unreachable ();
}

// defined constants
unsigned long vm_page_mask = 4095;
void *__stderrp = NULL; // FILE *
void *__stdinp = NULL; // FILE *
void *__stdoutp = NULL; // FILE *
void *stderr = NULL; // FILE *
void *stdin = NULL; // FILE *
void *stdout = NULL; // FILE *



void dyld_stub_binder() {
        koops("dyld_stub_binder");
}

void
__assert_rtn(const char *function, const char *file, int line, const char *err)
{
        kprintf("assert:%s:%s:%d:%s\n", file, function, line, err);
}


void
__assert_fail()
{
        koops("__assert_fail");
}


//void __bzero() { koops("Calling __bzero\n"); }

void __divti3() { koops("Calling __divti3\n"); }

void __error() { koops("Calling __error\n"); }

void _dyld_register_func_for_add_image() { koops("Calling _dyld_register_func_for_add_image\n"); }

void __getdelim() {
        koops("__getdelim");
}


int *__errno_location (void) 
{
        koops("__errno_location\n");
}


void _IO_putc()
{
        koops("_IO_putc\n");
}

//typedef struct __asl_object_s *asl_object_t;
typedef void *asl_object_t;
int asl_log(asl_object_t client, asl_object_t msg, int level, const char *format, ...)
{
        kprintf("asl_log(level=%d)\n", level);
        va_list argp;
        kvprintf(format, argp);
        va_end(argp);

        return 0;
}

void abort() { koops("Calling abort\n"); }

void asprintf() { koops("Calling asprintf\n"); }

void ceil() { koops("Calling ceil\n"); }

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


void cos() { koops("Calling cos\n"); }

void cosf() { koops("Calling cosf\n"); }

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

void dlopen()
{
        koops("dlopen\n");
}


void dlclose()
{
        koops("dlclose\n");
}

void dl_iterate_phdr()
{
        koops("dl_iterate_phdr\n");
}



void dlsym() { koops("Calling dlsym\n"); }

void exp() { koops("Calling exp\n"); }

void exp2() { koops("Calling exp2\n"); }

void exp2f() { koops("Calling exp2f\n"); }

void expf() { koops("Calling expf\n"); }

void flockfile() { koops("Calling flockfile\n"); }

void floor() { koops("Calling floor\n"); }

void floorf() { koops("Calling floorf\n"); }

void fmod() { koops("Calling fmod\n"); }

void fmodf() { koops("Calling fmodf\n"); }

void fmodl() { koops("Calling fmodl\n"); }

void fprintf() { koops("Calling fprintf\n"); }

void fputc()
{
        koops("fputc\n");
}

void fwrite()
{
        koops("fwrite\n");
}

void free(void *ptr)
{
        kprintf("free(%p)\n", ptr);
}



//void freelocale() { koops("Calling freelocale\n"); }

void funlockfile() { koops("Calling funlockfile\n"); }

void getline() { koops("Calling getline\n"); }

void getsectiondata() { koops("Calling getsectiondata\n"); }

void log() { koops("Calling log\n"); }

void log10() { koops("Calling log10\n"); }

void log10f() { koops("Calling log10f\n"); }

void log2() { koops("Calling log2\n"); }

void log2f() { koops("Calling log2f\n"); }

void logf() { koops("Calling logf\n"); }

static uint64_t heap = (uint64_t)&_bss_end;

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

        kprintf("malloc(%lu), result=%p heap=%lX\n", size, result, heap);

        return result;
}

void malloc_default_zone() { koops("Calling malloc_default_zone\n"); }

void malloc_size() { koops("Calling malloc_size\n"); }

void malloc_usable_size()
{
        koops("malloc_usable_size\n");
}

void malloc_zone_from_ptr() { koops("Calling malloc_zone_from_ptr\n"); }

void memchr() { koops("Calling memchr\n"); }

void memcmp() { koops("Calling memcmp\n"); }

//void memcpy() { koops("Calling memcpy\n"); }

void *memcpy(void *restrict dst, const void *restrict src, size_t n)
{
        kprintf("memcpy(dst=%p,src=%p,count=%lu\n", dst, src, n);
        __memcpy(dst, src, n);
        return dst;
}


void memmove() { koops("Calling memmove\n"); }


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


void memset_pattern8()
{
        koops("memset_pattern8");
}


void nearbyint() { koops("Calling nearbyint\n"); }

void nearbyintf() { koops("Calling nearbyintf\n"); }

void newlocale() {
        koops("Calling newlocale\n");
}

void uselocale() {
        koops("uselocale\n");
}

//void printf() { koops("Calling printf\n"); }

typedef int pthread_once_t;

int
pthread_once(pthread_once_t *once_control, void (*init_routine)(void))
{
        kprintf("pthread_once(%p,%d %p)\n", once_control, *once_control, init_routine);
        init_routine();
        kprintf("init_routine finished\n");
        return 0;
}

UNIMPLEMENTED(__pthread_key_create)

void pthread_mutex_init() { koops("Calling pthread_mutex_init\n"); }

void pthread_mutex_lock() { koops("Calling pthread_mutex_lock\n"); }

void pthread_mutex_unlock() { koops("Calling pthread_mutex_unlock\n"); }

void pthread_rwlock_rdlock()
{
        koops("pthread_rwlock_rdlock");
}


void pthread_rwlock_unlock()
{
        koops("pthread_rwlock_unlock");
}


void pthread_rwlock_wrlock()
{
        koops("pthread_rwlock_wrlock");
}

void putc() { koops("Calling putc\n"); }

void putchar() { koops("Calling putchar\n"); }

void read()
{
        koops("read");
}


void rint() { koops("Calling rint\n"); }

void rintf() { koops("Calling rintf\n"); }

void round() { koops("Calling round\n"); }

void roundf() { koops("Calling roundf\n"); }


void sin() { koops("Calling sin\n"); }

void sinf() { koops("Calling sinf\n"); }

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


void snprintf_l() { koops("Calling snprintf_l\n"); }

void strchr() { koops("Calling strchr\n"); }

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
        int d0;
        size_t res;
        asm volatile("cld\n\t"
                     "repne\n\t"
                     "scasb"
                     : "=c" (res), "=&D" (d0)
                     : "1" (s), "a" (0), "0" (0xffffffffu)
                     : "memory");
        return ~res - 1;
}


void strncmp() { koops("Calling strncmp\n"); }

void strndup() { koops("Calling strndup\n"); }

void strtod_l() { koops("Calling strtod_l\n"); }

void strtof_l() { koops("Calling strtof_l\n"); }

void strtold_l() { koops("Calling strtold_l\n"); }


void sysconf() { koops("Calling sysconf\n"); }

void trunc() { koops("Calling trunc\n"); }

void truncf() { koops("Calling truncf\n"); }

void vasprintf() { koops("Calling vasprintf\n"); }


void vsnprintf()
{
        koops("vsnprintf()\n");
}

void write() { koops("Calling write\n"); }

void __stack_chk_fail()
{
        koops("__stack_chk_fail");
}

void __stack_chk_guard() {
        koops("__stack_chk_guard");
}

// Unicode
void ucol_closeElements_52()
{
        koops(__func__);
}

void ucol_next_52() {
        koops(__func__);
}

void ucol_open_52() {
        koops(__func__);
}

void ucol_openElements_52() {
        koops(__func__);
}

void ucol_setAttribute_52() {
        koops(__func__);
}

void ucol_strcoll_52() {
        koops(__func__);
}
void ucol_strcollIter_52()
{
        koops(__func__);
}

void uiter_setString_52()
{
        koops(__func__);
}
void uiter_setUTF8_52()
{
        koops(__func__);
}
void u_strToLower_52()
{
        koops(__func__);
}
void u_strToUpper_52() {
        koops(__func__);
}
