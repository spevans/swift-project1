/*
 * include/kernel.h
 *
 * Created by Simon Evans on 16/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * Header file used by Swift to access certain C functions
 *
 */

#ifndef __KERNEL_H__
#define __KERNEL_H__

#include <stddef.h>
#include <stdint.h>
#include <stdarg.h>
#include "klibc.h"
#include "acpi.h"

// Export as [symbol]_ptr of type UnsafePointer<Void>
#define EXPORTED_SYMBOL_AS_VOIDPTR(x) \
        static inline const void *x##_ptr() { extern uintptr_t x; return &x; }

// Export as [symbol]_ptr of type UnsafePointer<t>
#define EXPORTED_SYMBOL_AS_PTR(x, t) \
        static inline const t *x##_ptr() { extern t x; return &x; }

// Export as [symbol]_addr as a unitptr_t to be manipulated as a UInt
#define EXPORTED_SYMBOL_AS_UINTPTR(x) \
        static inline uintptr_t x##_addr() { extern uintptr_t x; return (uintptr_t)&x; }

EXPORTED_SYMBOL_AS_VOIDPTR(_text_start);
EXPORTED_SYMBOL_AS_VOIDPTR(_text_end);
EXPORTED_SYMBOL_AS_VOIDPTR(_rodata_start);
EXPORTED_SYMBOL_AS_VOIDPTR(_rodata_end);
EXPORTED_SYMBOL_AS_VOIDPTR(_data_start);
EXPORTED_SYMBOL_AS_VOIDPTR(_data_end);
EXPORTED_SYMBOL_AS_VOIDPTR(_bss_start);
EXPORTED_SYMBOL_AS_VOIDPTR(_bss_end);
EXPORTED_SYMBOL_AS_VOIDPTR(_kernel_start);
EXPORTED_SYMBOL_AS_VOIDPTR(_kernel_end);
EXPORTED_SYMBOL_AS_VOIDPTR(_guard_page);
EXPORTED_SYMBOL_AS_VOIDPTR(_stack_start);
EXPORTED_SYMBOL_AS_VOIDPTR(_kernel_stack);
EXPORTED_SYMBOL_AS_VOIDPTR(initial_pml4);
EXPORTED_SYMBOL_AS_UINTPTR(divide_by_zero_stub);
EXPORTED_SYMBOL_AS_UINTPTR(debug_exception_stub);
EXPORTED_SYMBOL_AS_UINTPTR(nmi_stub);
EXPORTED_SYMBOL_AS_UINTPTR(single_step_stub);
EXPORTED_SYMBOL_AS_UINTPTR(overflow_stub);
EXPORTED_SYMBOL_AS_UINTPTR(bounds_stub);
EXPORTED_SYMBOL_AS_UINTPTR(invalid_opcode_stub);
EXPORTED_SYMBOL_AS_UINTPTR(unused_stub);
EXPORTED_SYMBOL_AS_UINTPTR(double_fault_stub);
EXPORTED_SYMBOL_AS_UINTPTR(invalid_tss_stub);
EXPORTED_SYMBOL_AS_UINTPTR(seg_not_present_stub);
EXPORTED_SYMBOL_AS_UINTPTR(stack_fault_stub);
EXPORTED_SYMBOL_AS_UINTPTR(gpf_stub);
EXPORTED_SYMBOL_AS_UINTPTR(page_fault_stub);
EXPORTED_SYMBOL_AS_UINTPTR(fpu_fault_stub);
EXPORTED_SYMBOL_AS_UINTPTR(alignment_exception_stub);
EXPORTED_SYMBOL_AS_UINTPTR(mce_stub);
EXPORTED_SYMBOL_AS_UINTPTR(simd_exception_stub);
EXPORTED_SYMBOL_AS_UINTPTR(irq00_stub);
EXPORTED_SYMBOL_AS_UINTPTR(irq01_stub);
EXPORTED_SYMBOL_AS_UINTPTR(irq02_stub);
EXPORTED_SYMBOL_AS_UINTPTR(irq03_stub);
EXPORTED_SYMBOL_AS_UINTPTR(irq04_stub);
EXPORTED_SYMBOL_AS_UINTPTR(irq05_stub);
EXPORTED_SYMBOL_AS_UINTPTR(irq06_stub);
EXPORTED_SYMBOL_AS_UINTPTR(irq07_stub);
EXPORTED_SYMBOL_AS_UINTPTR(irq08_stub);
EXPORTED_SYMBOL_AS_UINTPTR(irq09_stub);
EXPORTED_SYMBOL_AS_UINTPTR(irq10_stub);
EXPORTED_SYMBOL_AS_UINTPTR(irq11_stub);
EXPORTED_SYMBOL_AS_UINTPTR(irq12_stub);
EXPORTED_SYMBOL_AS_UINTPTR(irq13_stub);
EXPORTED_SYMBOL_AS_UINTPTR(irq14_stub);
EXPORTED_SYMBOL_AS_UINTPTR(irq15_stub);
EXPORTED_SYMBOL_AS_PTR(fontdata_8x16, uint8_t);

extern void * const initial_tls_end_addr;
void run_first_task();

#endif  // __KERNEL_H__
