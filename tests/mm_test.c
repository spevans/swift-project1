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
#include "mm.h"

void init_mm(void);

const void *_heap_start[128][PAGE_SIZE];
const void *_heap_end = &_heap_start[128];

int main()
{
        printf("_heap_start: %p\n_heap_end: %p\n", &_heap_start, &_heap_end);
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

unsigned int read_int_nest_count() {
        return 0;
}
