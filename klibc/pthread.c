/*
 * klibc/pthread.c
 *
 * Created by Simon Evans on 02/04/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * pthread functions used by Swift Stdlib
 *
 */

#include "klibc.h"
#include <pthread.h>

#pragma GCC diagnostic ignored "-Wunused-parameter"

/*
 * pthread - minimal implementation of functions used to satisfy a single
 * threaded version.
 */

int
pthread_mutex_init(pthread_mutex_t *restrict mutex,
                   const pthread_mutexattr_t *restrict attr)
{
        debugf("pthread_mutex_init(%p,%p)\n", mutex, attr);
        memset(mutex, 0, sizeof(pthread_mutex_t));
        return 0;
}

int
pthread_mutex_destroy(pthread_mutex_t *mutex)
{
        debugf("pthread_mutex_destroy(%p)\n", mutex);
        return 0;
}


int
pthread_mutex_lock(pthread_mutex_t *mutex)
{
        debugf("pthread_mutex_lock(%p)\n", mutex);
        return 0;
}

int
pthread_mutex_trylock (pthread_mutex_t *mutex)
{
        debugf("pthread_mutex_trylock(%p)\n", mutex);
        return 0;
}


int
pthread_mutex_unlock(pthread_mutex_t *mutex)
{
        debugf("pthread_mutex_unlock(%p)\n", mutex);
        return 0;
}


int
pthread_mutexattr_init(pthread_mutexattr_t *attr)
{
        debugf("pthread_mutexattr_init(%p)\n", attr);
        memset(attr, 0, sizeof(pthread_mutexattr_t));
        return 0;
}


int
pthread_mutexattr_settype (pthread_mutexattr_t *attr, int kind)
{
        debugf("pthread_mutexattr_settype(%p, %d)\n", attr, kind);
        return 0;
}


int
pthread_mutexattr_destroy(pthread_mutexattr_t *attr)
{
        debugf("pthread_mutexattr_destroy(%p)\n", attr);
        return 0;
}


int
pthread_cond_init(pthread_cond_t *restrict cond,
                  const pthread_condattr_t *restrict cond_attr)
{
        debugf("pthread_cond_init(%p,%p)\n", cond, cond_attr);
        memset(cond, 0, sizeof(pthread_cond_t));
        return 0;
}


int
pthread_cond_destroy(pthread_cond_t *restrict cond)
{
        debugf("pthread_cond_destroy(%p)\n", cond);
        return 0;
}


int
pthread_cond_signal(pthread_cond_t *restrict cond)
{
        debugf("pthread_cond_signal(%p)\n", cond);
        return 0;
}


int
pthread_cond_broadcast(pthread_cond_t *restrict cond)
{
        debugf("pthread_cond_broadcast(%p)\n", cond);
        return 0;
}


int
pthread_cond_wait(pthread_cond_t *restrict cond,
                   pthread_mutex_t *restrict mutex)
{
        debugf("pthread_cond_wait(%p, %p)\n", cond, mutex);
        return 0;
}


int
pthread_rwlock_init(pthread_rwlock_t *restrict rwlock,
                    const pthread_rwlockattr_t *restrict attr)
{
        debugf("pthread_rwlock_init(%p, %p)\n", rwlock, attr);
        return 0;
}


int
pthread_rwlock_destroy(pthread_rwlock_t *rwlock)
{
        debugf("pthread_rwlock_destroy(%p)\n", rwlock);
        return 0;
}


int
pthread_rwlock_tryrdlock(pthread_rwlock_t *rwlock)
{
        debugf("pthread_rwlock_tryrdlock(%p)\n", rwlock);
        return 0;
}


int
pthread_rwlock_rdlock(pthread_rwlock_t *rwlock)
{
        debugf("pthread_rwlock_rdlock(%p)\n", rwlock);
        return 0;
}


int
pthread_rwlock_trywrlock(pthread_rwlock_t *rwlock)
{
        debugf("pthread_tryrwlock_wrlock(%p)\n", rwlock);
        return 0;
}


int
pthread_rwlock_wrlock(pthread_rwlock_t *rwlock)
{
        debugf("pthread_rwlock_wrlock(%p)\n", rwlock);
        return 0;
}


int
pthread_rwlock_unlock(pthread_rwlock_t *rwlock)
{
        debugf("pthread_rwlock_unlock(%p)\n", rwlock);
        return 0;
}


pthread_t
pthread_self(void)
{
        debugf("pthread_self()\n");
        return 1;
}


// Used as a weak symbol to detect libpthread
int
__pthread_key_create (pthread_key_t *key,  void (*destructor) (void *))
{
        debugf("pthread_key_create(%p,%p)\n", key, destructor);
        koops("UNIMPLEMENTED: %s", __func__);
}

int
pthread_key_create (pthread_key_t *key, void (*destructor) (void *))
{
        return __pthread_key_create(key, destructor);
}


void *
pthread_getspecific (pthread_key_t __key)
{
        koops("UNIMPLEMENTED: %s", __func__);
}


// Store POINTER in the thread-specific data slot identified by KEY.
int
pthread_setspecific (pthread_key_t __key, const void *__pointer)
{
        koops("UNIMPLEMENTED: %s", __func__);
}


// swift_once_f() used to implemented swift_once() in the stdlib
void
swift_once_f(uintptr_t *predicate, void (*function)(void *), void *context)
{
        debugf("swift_oncef(%p, %p, %p) [%lu]\n", predicate, function, context,
               *predicate);

        if (!*predicate) {
                *predicate = 1;
                function(context);
        }
}


//swift::swift_once_f(unsigned long*, void (*)(void*), void*)
void
_ZN5swift12swift_once_fEPmPFvPvES1_(uintptr_t *predicate, void (*function)(void *), void *context)
{
        swift_once_f(predicate, function, context);
}
