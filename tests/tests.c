/*
 * tests/tests.c
 *
 * Created by Simon Evans on 01/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Test wrapper
 */

#include <stdio.h>
#include <string.h>
#include <assert.h>

extern void _TF5Tests8runTestsFT_T_(void);

int ksnprintf(char *buf, size_t size, const char *fmt, ...) __attribute__ ((format (printf, 3, 4)));
int kprintf(const char *fmt, ...) __attribute__ ((format (printf, 1, 2)));


// used by kprintf
void
early_print_char(const char ch)
{
        putchar(ch);
}


int main()
{
        char buf[128];

        size_t len;
        size_t n = 1;
        do {
                len = ksnprintf(buf, n, "This is a long string: %s %d", "with more text", 123);
                kprintf("len = %lu n = %lu, buf = #%s#\n", len, n, buf);
                n *= 2;
                assert(strlen(buf) <= n );
        } while (strlen(buf) < len);

        // Tests.runTests()
        _TF5Tests8runTestsFT_T_();

        return 0;
}
