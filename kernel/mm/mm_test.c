/*
 * kernel/mm_test.c
 *
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * malloc() test functions
 *
 */

#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>


void init_mm(void);


int main()
{
        init_mm();
        for (size_t i = 0; i < 65; i++) {
                malloc(16);
                fflush(stdout);
        }
        return 1;
}


void hlt()
{
        exit(1);
}


void kprintf(char *fmt, ...)
{
        va_list args;
        va_start(args, fmt);
        vprintf(fmt, args);
        va_end(args);
}


void koops(char *fmt, ...)
{
        printf("OOPS: ");
        va_list args;
        va_start(args, fmt);
        vprintf(fmt, args);
        va_end(args);
        exit(1);
}
