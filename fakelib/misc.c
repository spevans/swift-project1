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

#define _UNISTD_H   // Avoid including all of unistd.h
#include <bits/confname.h>


#pragma GCC diagnostic ignored "-Wunused-parameter"


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


long
sysconf(int name)
{
        switch(name) {
        case _SC_PAGESIZE:
                return PAGE_SIZE;

        case _SC_NPROCESSORS_ONLN:
                return 1;

        default:
                koops("UNIMPLEMENTED sysconf: name = %d\n", name);
        }
}


UNIMPLEMENTED(__divti3)
UNIMPLEMENTED(backtrace)


// Unicode (libicu)
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
UNIMPLEMENTED(ucol_closeElements_55)
UNIMPLEMENTED(ucol_next_55)
UNIMPLEMENTED(ucol_open_55)
UNIMPLEMENTED(ucol_openElements_55)
UNIMPLEMENTED(ucol_setAttribute_55)
UNIMPLEMENTED(ucol_strcoll_55)
UNIMPLEMENTED(uiter_setString_55)
UNIMPLEMENTED(uiter_setUTF8_55)
UNIMPLEMENTED(u_strToLower_55)
UNIMPLEMENTED(u_strToUpper_55)
UNIMPLEMENTED(ucol_strcollIter_55)
