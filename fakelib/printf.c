/*
 * fakelib/printf.c
 *
 * Created by Simon Evans on 21/05/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Fake printf calls used by libswiftCore
 *
 */

#include "klibc.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

/*
 * printf
 */

int
vasprintf(char **strp, const char * restrict format, va_list argp)
{
        char buf[128];

        debugf("vasprintf(%p,%s)\n", strp, format);

        // len = number of characters in final string, not that fit in buffer
        // excludes terminating '\0'
        int len = kvsnprintf(buf, 128, format, argp);
        *strp = malloc(len + 1);
        if (*strp == NULL) {
                return -1;
        }

        if (len > 127) {
                return kvsnprintf(buf, len + 1, format, argp);
        } else {
                memcpy(*strp, buf, len + 1);
        }

        return len;
}


int
asprintf(char **strp, const char * restrict format, ...)
{
        va_list argp;
        va_start(argp, format);
        kvprintf(format, argp);
        // asprintf seems to only be used for assert() and fatal error messages
        // so stop here
        stop();
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
        debugf("snprintf(\"%s\", %lu)\n", format, size);
        va_list argp;
        va_start(argp, format);
        int len = kvsnprintf(buf, size, format, argp);
        va_end(argp);

        return len;
}
