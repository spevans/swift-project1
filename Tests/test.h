//
//  test.h
//  project1
//
//  Created by Simon Evans on 31/07/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//

#ifndef test_h
#define test_h

#define TEST 1

#include <stdio.h>
#include "../include/mm.h"
#include "../include/acpi.h"
#include "../include/usb.h"
#include "../include/io.h"
#include "../include/x86defs.h"
//#include "../include/x86funcs.h"
#include "../include/klibc.h"

static inline int kprintf1arg(const char * _Nonnull fmt, long l1) {
    return printf(fmt, l1);
}

static inline int kprintf2args(const char * _Nonnull fmt, long l1, long l2)  {
    return printf(fmt, l1, l2);
}

static inline int kprintf3args(const char * _Nonnull fmt, long l1, long l2, long l3)  {
    return printf(fmt, l1, l2, l3);
}
#endif /* test_h */
