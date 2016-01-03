/*
 * kernel/kernel.h
 *
 * Created by Simon Evans on 16/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * Header file used by Swift to access certain C functions
 *
 */

#ifndef __KERNEL_H__
#define __KERNEL_H__

#include <stdint.h>
#include "x86funcs.h"

#define EXPORTED_SYMBOL(x) extern const void *x##_addr;


EXPORTED_SYMBOL(_text_start);
EXPORTED_SYMBOL(_text_end);
EXPORTED_SYMBOL(_data_start);
EXPORTED_SYMBOL(_data_end);
EXPORTED_SYMBOL(_bss_start);
EXPORTED_SYMBOL(_bss_end);


void set_print_functions_to_swift();
int kvprintf(const char *fmt, va_list args) __attribute__ ((format (printf, 1, 0)));
int kvsprintf(char *buf, const char *fmt, va_list args) __attribute__ ((format (printf, 2, 0)));


#endif  // __KERNEL_H__
