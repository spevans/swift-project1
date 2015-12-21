/*
 * fakelib/linux_libc.c
 *
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Fake libc calls used by Linux/ELF libswiftCore
 *
 */

#include "klibc.h"
#define __USE_GNU
#include <link.h>
#include <dlfcn.h>

#pragma GCC diagnostic ignored "-Wunused-parameter"

typedef int pthread_once_t;
typedef unsigned int pthread_key_t;

extern void *swift2_protocol_conformances_start;
// Dummy empty structure for dl_iterate_phdr
static struct dl_phdr_info empty_dl_phdr_info = { .dlpi_addr = 0 };


void
__assert_fail (const char *err, const char *file,
               unsigned int line, const char *function)
{
        dprintf("assert:%s:%s:%d:%s\n", file, function, line, err);
        hlt();
}


// Fake a handle if opening NULL (this binary) else oops
void *
dlopen(const char *filename, int flag)
{
        if (filename != NULL) {
                koops("dlopen called with filename=%s", filename);
        }

        dprintf("dlopen(%s,%X)\n", filename, flag);
        return (void *)1;
}


// Hardcoded to allow lookup of 1 known symbol, enough for now
void *
dlsym(void *handle, const char *symbol)
{
        dprintf("dlsym(%p,%s)=", handle, symbol);
        if (handle != (void *)1) {
                koops("dlsym(): bad handle: %p", handle);
        }
        if (!strcmp(symbol, ".swift2_protocol_conformances_start")) {
                dprintf("%p\n", &swift2_protocol_conformances_start);

                return &swift2_protocol_conformances_start;
        } else {
                koops("dlsym(): bad symbol: %s\n", symbol);
        }
}


// Sanity check the handle
int
dlclose(void *handle)
{
        dprintf("dlclose(%p)\n", handle);
        if (handle != (void *)1) {
                koops("dlclose(): bad handle: %p", handle);
        }
        return 0;
}


// Hardcoded to return an empty structure, the caller of this only
// cares about the filename anyway and can deal with it being NULL
int
dl_iterate_phdr(int (*callback) (struct dl_phdr_info *info,
                                 size_t size, void *data), void *data)
{
        dprintf("dl_iterate_phdr(%p,%p)\n", callback, data);
        int res = callback(&empty_dl_phdr_info, sizeof(struct dl_phdr_info), data);
        dprintf("dl_iteratre_phdr finished=%d\n", res);
        return res;
}


__thread void* _ZSt15__once_callable;
__thread void (*_ZSt11__once_call)();

void __once_proxy()
{
        dprintf("__once_proxy_func() __once_call=%p\n", _ZSt11__once_call);
        if (_ZSt11__once_call) {
                _ZSt11__once_call();
        }
}


int
pthread_once(pthread_once_t *once_control, void (*init_routine)(void))
{
        dprintf("pthread_once(%p,%d %p)\n", once_control, *once_control, init_routine);
        if (*once_control == 0) {
                dprintf("running %p ... ", init_routine);
                init_routine();
                dprintf(" finished\n");
                (*once_control)++;
        }
        return 0;
}


int __pthread_key_create (pthread_key_t *key,
                          void (*destructor) (void *))
{
        dprintf("pthread_key_create(%p,%p)\n", key, destructor);
        koops("unimplemented");
}


UNIMPLEMENTED(__getdelim)
UNIMPLEMENTED(__errno_location)
UNIMPLEMENTED(newlocale)
UNIMPLEMENTED(uselocale)


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
