/*
 * fakelib/osx_libc.c
 *
 * Created by Simon Evans on 15/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * Fake libc calls used by OSX/Mach-O libswiftCore
 *
 */

#include "klibc.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"


typedef long dispatch_once_t;
void dispatch_once_f(dispatch_once_t *predicate, void *context, void (*function)(void *)) {
        debugf("dispatch_once_t(%p,%p,%p)\n", predicate, context, function);
        if(*predicate == 0) {
                *predicate = ~0L;
                function(context);
        }
}


typedef void *asl_object_t;
int asl_log(asl_object_t client, asl_object_t msg, int level, const char *format, ...)
{
        debugf("asl_log(level=%d)\n", level);
        va_list argp;
        kvprintf(format, argp);
        va_end(argp);

        return 0;
}


void
__assert_rtn(const char *function, const char *file, int line, const char *err)
{
        debugf("assert:%s:%s:%d:%s\n", file, function, line, err);
        hlt();
}


void
__bzero(void *dest, size_t count)
{
        memset(dest, 0, count);
}


UNIMPLEMENTED(_dyld_register_func_for_add_image)
UNIMPLEMENTED(dyld_stub_binder)
UNIMPLEMENTED(dlsym)
UNIMPLEMENTED(getline)
UNIMPLEMENTED(getsectiondata)
UNIMPLEMENTED(__error)
UNIMPLEMENTED(malloc_zone_from_ptr)
UNIMPLEMENTED(snprintf_l)
