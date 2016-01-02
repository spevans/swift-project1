/*
 * kernel/kernel.h
 *
 * Created by Simon Evans on 16/12/2015.
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Header file used by Swift to access certain C functions
 *
 */

#ifndef __KERNEL_H__
#define __KERNEL_H__

#include <stdint.h>

#define EXPORTED_SYMBOL(x) extern const void *x##_addr;


EXPORTED_SYMBOL(_text_start);
EXPORTED_SYMBOL(_text_end);
EXPORTED_SYMBOL(_data_start);
EXPORTED_SYMBOL(_data_end);
EXPORTED_SYMBOL(_bss_start);
EXPORTED_SYMBOL(_bss_end);


void set_print_functions_to_swift();
void hlt();
int kvprintf(const char *fmt, va_list args) __attribute__ ((format (printf, 1, 0)));
int kvsprintf(char *buf, const char *fmt, va_list args) __attribute__ ((format (printf, 2, 0)));

// CPU.asm functions

void outb(uint16_t port, uint8_t data);
void outw(uint16_t port, uint16_t data);
void outl(uint16_t port, uint32_t data);
uint8_t inb(uint16_t port);
uint16_t inw(uint16_t port);
uint32_t inl(uint16_t port);

// Descriptor table info used for both GDT and IDT
struct dt_info {
        uint16_t size;
        void *address;
} __attribute__((packed));

void lgdt(const struct dt_info *info);
void sgdt(struct dt_info *info);
void reload_segments();

#endif  // __KERNEL_H__
