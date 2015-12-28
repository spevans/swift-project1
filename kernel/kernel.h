/*
 * kernel/kernel.h
 *
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Header file used by Swift to access certain C functions
 *
 */
#include <stdint.h>

#define EXPORTED_SYMBOL(x) void *x##_addr();

EXPORTED_SYMBOL(_text_start);
EXPORTED_SYMBOL(_text_end);
EXPORTED_SYMBOL(_data_start);
EXPORTED_SYMBOL(_data_end);
EXPORTED_SYMBOL(_bss_start);
EXPORTED_SYMBOL(_bss_end);

void set_print_functions_to_swift();
void hlt();
int kvprintf(const char *fmt, va_list args) __attribute__ ((format (printf, 1, 0)));

void outb(uint16_t port, uint8_t data);
void outw(uint16_t port, uint16_t data);
void outl(uint16_t port, uint32_t data);
uint8_t inb(uint16_t port);
uint16_t inw(uint16_t port);
uint32_t inl(uint16_t port);
