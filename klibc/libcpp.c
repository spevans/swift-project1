/*
 * klibc/libcpp.c
 *
 * Created by Simon Evans on 21/05/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Fake libcpp calls used by Linux/ELF libswiftCore
 *
 */

#include "klibc.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-variable"

const void *const __dso_handle __attribute__ ((__visibility__ ("hidden")))
  = &__dso_handle;

/*
 * memory
 */

//_operator new(unsigned long)
void *_Znwm(unsigned long size)
{
        void *result = malloc(size);
        debugf("new(%lu)=%p\n", size, result);
        return result;
}


//_operator delete(void*)
void _ZdlPv(void *this)
{
        debugf("delete(%p)\n", this);
        free(this);
}


// operator new[](unsigned long size)
void *_Znam(unsigned long size)
{
        void *result = malloc(size);
        debugf("new[](%lu)=%p\n", size, result);
        return result;
}


// operator delete[](void *)
void _ZdaPv(void *this)
{
        debugf("delete[](%p)\n", this);
        free(this);
}


// std::__throw_length_error(char const*)
void
_ZSt20__throw_length_errorPKc(char const *error)
{
        koops("OOPS! Length error: %s", error);
}


// std::__throw_logic_error(char const*)
void
_ZSt19__throw_logic_errorPKc(char const *error)
{
        koops("Logic error: %s", error);
}


// std::__throw_bad_alloc()
void
_ZSt17__throw_bad_allocv()
{
        koops("Bad Alloc");
}


// std::__throw_bad_function_call()
void
_ZSt25__throw_bad_function_callv()
{
        koops("bad function call");
}


int
__cxa_guard_acquire(void *guard)
{
        debugf("__cxa_guard_acquire(%p)\n", guard);
        return 0;
}

void __cxa_guard_release(void *guard)
{
        debugf("__cxa_guard_release(%p)\n", guard);
}


int
__cxa_atexit(void (*func) (void *), void *arg, void *dso_handle)
{
        debugf("__cxa_atexit(%p, %p, %p)\n", func, arg, dso_handle);
        // Exit never occurs so ignore this handler, return success
        return 0;
}


// Just return that the name could not be demangled so that the name gets
// passed to the swift symbol demangler. A full demangler implementation
// is quite large and not needed at the moment.
char *
__cxa_demangle(const char *mangled_name, char * output_buffer,
               size_t *length, int *status)
{
    if (status) {
        *status = -2; // 'Not a valid C++ name'
    }
    return NULL;
}


void
__cxa_pure_virtual()
{
        koops("__cxa_pure_virtual");
}

// std::ios_base::Init::Init()
void
_ZNSt8ios_base4InitC1Ev()
{
        return;
}


// std::thread::hardware_concurrency()
// see also misc.c:sysconf()
int _ZNSt6thread20hardware_concurrencyEv()
{
        return 1;
}


UNIMPLEMENTED(_ZNSt8ios_base4InitD1Ev) // std::ios_base::Init::~Init()

// std::__detail::_Prime_rehash_policy::_M_need_rehash(unsigned long, unsigned long, unsigned long) const

struct rehash_pair { size_t first; size_t second; }
_ZNKSt8__detail20_Prime_rehash_policy14_M_need_rehashEmmm(
        unsigned long bucket_count, unsigned long element_count, unsigned long load)
{
        // TODO: Fix this correclty
        struct rehash_pair pair = { 0, 0x12345678 };
        return pair;
}
