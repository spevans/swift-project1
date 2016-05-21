/*
 * fakelib/misc.c
 *
 * Created by Simon Evans on 21/05/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Fake libc calls used by Linux/ELF libswiftCore
 *
 */

#include "klibc.h"
#define __USE_GNU
#include <link.h>
#include <dlfcn.h>

#pragma GCC diagnostic ignored "-Wunused-parameter"


extern void *swift2_protocol_conformances_start;
// Dummy empty structure for dl_iterate_phdr
static struct dl_phdr_info empty_dl_phdr_info = { .dlpi_addr = 0 };


void
__assert_fail (const char *err, const char *file,
               unsigned int line, const char *function)
{
        debugf("assert:%s:%s:%d:%s\n", file, function, line, err);
        hlt();
}

void
abort()
{
        koops("abort() called");
}


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


// Fake a handle if opening NULL (this binary) else oops
void *
dlopen(const char *filename, int flag)
{
        if (filename != NULL) {
                koops("dlopen called with filename=%s", filename);
        }

        debugf("dlopen(%s,%X)\n", filename, flag);
        return (void *)1;
}


// Hardcoded to allow lookup of 1 known symbol, enough for now
void *
dlsym(void *handle, const char *symbol)
{
        debugf("dlsym(%p, \"%s\")=", handle, symbol);
        if (handle != (void *)1) {
                koops("dlsym(): bad handle: %p", handle);
        }
        if (!strcmp(symbol, ".swift2_protocol_conformances_start")) {
                debugf("%p\n", &swift2_protocol_conformances_start);

                return &swift2_protocol_conformances_start;
        } else {
                koops("dlsym(): bad symbol: %s\n", symbol);
        }
}


int
dladdr(const void *addr, Dl_info *info)
{
        // FIXME: Dummy implementation for now, returns `not found'
        kprintf("dladdr() required for %p\n", addr);

        // info declared as nonnull in dlfcn.h
        info->dli_fname = NULL;
        info->dli_fbase = NULL;
        info->dli_sname = NULL;
        info->dli_saddr = NULL;

        return 0;
}


// Sanity check the handle
int
dlclose(void *handle)
{
        debugf("dlclose(%p)\n", handle);
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
        debugf("dl_iterate_phdr(%p,%p)\n", callback, data);
        int res = callback(&empty_dl_phdr_info, sizeof(struct dl_phdr_info), data);

        return res;
}


UNIMPLEMENTED(__divti3)
UNIMPLEMENTED(sysconf)
UNIMPLEMENTED(backtrace)


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


// Unused functions either not currently used by stdlib or have been commented
// out in the kernel-lib branch
#if 0

void
bzero(void *dest, size_t count)
{
        memset(dest, 0, count);
}

#endif
