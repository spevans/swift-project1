/*
 * tests/tests.c
 *
 * Created by Simon Evans on 01/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Test wrapper
 */

#include <stdio.h>


extern void _TF5Tests8runTestsFT_T_(void);
// print function required by kprintf
int (*print_string)(const char *) = puts;


int main()
{
        // Tests.runTests()
        _TF5Tests8runTestsFT_T_();
        return 0;
}
        



