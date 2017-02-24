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


// std::__throw_system_error(int)
void
_ZSt20__throw_system_errori(int error)
{
        koops("System error: %d", error);
}


// std::__throw_out_of_range_fmt(char const*, ...)
void
_ZSt24__throw_out_of_range_fmtPKcz(char const *fmt, ...)
{
        va_list args;
        va_start(args, fmt);

        kprintf("\nOut of range");
        int len = kvprintf(fmt, args);
        va_end(args);
        koops("");
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


UNIMPLEMENTED(__cxa_demangle)
UNIMPLEMENTED(__overflow)
UNIMPLEMENTED(_ZNKSt8__detail20_Prime_rehash_policy14_M_need_rehashEmmm)

// std::ios_base::Init::Init()
void
_ZNSt8ios_base4InitC1Ev()
{
        return;
}

UNIMPLEMENTED(_ZNSt8ios_base4InitD1Ev) // std::ios_base::Init::~Init()


// Unused
#if 0

//std::__throw_out_of_range(char const*)
void
_ZSt20__throw_out_of_rangePKc(char const *error)
{
        koops("Out of range: %s", error);
}

//std::condition_variable::condition_variable()
void
_ZNSt18condition_variableC1Ev(void *cv)
{
        memset(cv, 0, 48);
        debugf("creating condition variable @ %p\n", cv);
}


//std::condition_variable::notify_all()
void
_ZNSt18condition_variable10notify_allEv(void *cv)
{
        debugf("notify_all called on %p\n", cv);
}

//std::condition_variable::wait(std::unique_lock<std::mutex>&)
UNIMPLEMENTED(_ZNSt18condition_variable4waitERSt11unique_lockISt5mutexE)

#endif
