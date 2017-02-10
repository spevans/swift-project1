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


/*
 * memory
 */

//_operator delete(void*)
void _ZdlPv(void *this) {
        debugf("%p->delete()\n", this);
        free(this);
}


//_operator new(unsigned long)
void *_Znwm(unsigned long size) {

        void *result = malloc(size);
        debugf("(_Znwm)new(%lu)=%p\n", size, result);
        return result;
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

UNIMPLEMENTED(__cxa_demangle)
UNIMPLEMENTED(__overflow)
UNIMPLEMENTED(_ZNKSt8__detail20_Prime_rehash_policy14_M_need_rehashEmmm)

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
