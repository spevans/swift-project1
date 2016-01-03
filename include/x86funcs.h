/*
 * include/x86funcs.h
 *
 * Created by Simon Evans on 03/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Header file for x86 specific instructions. Most functions are one
 * instruction and by making them static inline Swift will include them
 * directly into the output making them inline assembly
 *
 * Larger functions are in kernel/klib/x86.asm as I find NASM format asm
 * easier to read/write then gas format
 *
 */

#ifndef __X86_FUNCS_H__
#define __X86_FUNCS_H__
#include "x86defs.h"

static inline void
hlt()
{
        asm volatile ("hlt" : : : "memory");
        __builtin_unreachable();
}

static inline void
lgdt(const struct dt_info *gdt)
{
        asm volatile ("lgdt (%0)" : : "r" (gdt) : "memory");
}


static inline void
sgdt(struct dt_info *gdt)
{
        asm volatile ("sgdt (%0)" : : "r" (gdt) : "memory");
}


static inline void
lidt(const struct dt_info *gdt)
{
        asm volatile ("lidt (%0)" : : "r" (gdt) : "memory");
}

static inline void
sidt(struct dt_info *gdt)
{
        asm volatile ("sidt (%0)" : : "r" (gdt) : "memory");
}


static inline void
outb(uint16_t port, uint8_t data)
{
        asm volatile ("outb %0, %1" : : "a" (data), "d" (port));
}


static inline uint8_t
inb(uint16_t port)
{
        uint8_t data;
        asm volatile ("inb %1, %0" : "=a" (data) : "d" (port));
        return data;
}


static inline void
outw(uint16_t port, uint16_t data)
{
        asm volatile ("outw %0, %1" : : "a" (data), "d" (port));
}


static inline uint16_t
inw(uint16_t port)
{
        uint16_t data;
        asm volatile ("inw %1, %0" : "=a" (data) : "d" (port));
        return data;
}


static inline void
outl(uint16_t port, uint32_t data)
{
        asm volatile ("outl %0, %1" : : "a" (data), "d" (port));
}


static inline uint32_t
inl(uint16_t port)
{
        uint32_t data;
        asm volatile ("inl %1, %0" : "=a" (data) : "d" (port));
        return data;
}


// kernel/klib/x86.asm functions
void reload_segments();


#endif  // __X86_FUNCS_H__
