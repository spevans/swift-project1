/*
 * klibc/io.c
 *
 * Created by Simon Evans on 21/05/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Fake io calls used by libswiftCore
 *
 */

#include "klibc.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

// Default FILE * for stdio, faked values
// Linux symbol names
void *stderr = (void *)0xF2;
void *stdin = (void *)0xF0;
void *stdout = (void *)0xF1;


/*
 * I/O functions
 */

int
fprintf(void *stream, const char *format, ...)
{
        if (stream != stderr && stream != stdout) {
                koops("fprintf stream = %p", stream);
        }
        va_list argp;
        va_start(argp, format);
        int len = kvprintf(format, argp);
        va_end(argp);

        return len;
}


int
printf(const char *format, ...)
{
        va_list argp;
        va_start(argp, format);
        int len = kvprintf(format, argp);
        va_end(argp);

        return len;
}

int
puts(const char *str)
{
        kprint(str);
        kprint("\n");
        return 0;
}


int
fputs(const char *string, void *stream)
{
        return fprintf(stream, "%s", string);
}


int
fputc(int c, void *stream)
{
        if (stream != stderr && stream != stdout) {
                koops("fputc stream = %p", stream);
        }
        early_print_char((char)c);
        return 0;
}


size_t
fwrite(const void *ptr, size_t size, size_t nmemb, void *stream)
{
        debugf("fwrite(%p, %lu, %lu, %p)", ptr, size, nmemb, stream);
        if (stream != stderr && stream != stdout) {
                koops("fwrite stream = %p", stream);
        }
        size_t len;
        if (__builtin_umull_overflow(size, nmemb, &len)) {
                koops("fwrite size too large (%lu,%lu)", size, nmemb);
        }
        early_print_string_len(ptr, len);

        return len;
}


ssize_t
write(int fd, const void *buf, size_t nbyte)
{
        debugf("write(fd=%d, buf=%p nbyte=%lu)\n", fd, buf, nbyte);

        if (fd == 1 || fd == 2) {
                early_print_string_len(buf, nbyte);
        } else {
                koops("write() with fd = %d\n", fd);
        }
        return nbyte;
}
