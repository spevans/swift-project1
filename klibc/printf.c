/*
 * klibc/printf.c
 *
 * Created by Simon Evans on 21/05/2016.
 * Copyright © 2016, 2018 Simon Evans. All rights reserved.
 *
 * Fake printf calls used by libswiftCore
 *
 */

#include "klibc.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

/*
 * printf
 */
extern int kvasnprintf(char **strp, const char *fmt, va_list args);

int
vasprintf(char **strp, const char * restrict format, va_list argp)
{
        debugf("vasprintf(%p,%s)\n", strp, format);

        // len = number of characters in final string, not that fit in buffer
        // excludes terminating '\0'
        return kvasnprintf(strp, format, argp);
}


int
asprintf(char **strp, const char * restrict format, ...)
{
        va_list argp;

        va_start(argp, format);
        int len = vasprintf(strp, format, argp);
        va_end(argp);

        return len;
}


int
vsnprintf(char * restrict buf, size_t size, const char *format, va_list argp)
{
        debugf("vsnprintf(%s)\n", format);
        int len = kvsnprintf(buf, size, format, argp);

        return len;
}


int
snprintf(char * restrict buf, size_t size, const char * restrict format, ...)
{
        va_list argp;

        debugf("snprintf(\"%s\", %lu)\n", format, size);
        va_start(argp, format);
        int len = kvsnprintf(buf, size, format, argp);
        va_end(argp);

        return len;
}
