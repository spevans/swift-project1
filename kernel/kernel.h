/*
 * kernel/kernel.h
 *
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Header file used by Swift to access certain C functions
 *
 */

#define EXPORTED_SYMBOL(x) void *x##_addr();

EXPORTED_SYMBOL(_text_start);
EXPORTED_SYMBOL(_text_end);
EXPORTED_SYMBOL(_data_start);
EXPORTED_SYMBOL(_data_end);
EXPORTED_SYMBOL(_bss_start);
EXPORTED_SYMBOL(_bss_end);

void set_print_functions_to_swift();
void hlt();
