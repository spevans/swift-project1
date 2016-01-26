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

#include <stddef.h>
#include <stdint.h>
#include <stdarg.h>
#include "x86funcs.h"
#include "mm.h"

// Export as [symbol]_addr suitable to use as an arg to UnsafePointer()
#define EXPORTED_SYMBOL_AS_VOIDPTR(x) extern const void *x##_addr;

// Export as [symbol]_addr as a unitptr_t to be manipulated as a UInt64
#define EXPORTED_SYMBOL_AS_UINTPTR(x) extern uintptr_t x##_addr;

EXPORTED_SYMBOL_AS_VOIDPTR(_text_start);
EXPORTED_SYMBOL_AS_VOIDPTR(_text_end);
EXPORTED_SYMBOL_AS_VOIDPTR(_rodata_start);
EXPORTED_SYMBOL_AS_VOIDPTR(_rodata_end);
EXPORTED_SYMBOL_AS_VOIDPTR(_data_start);
EXPORTED_SYMBOL_AS_VOIDPTR(_data_end);
EXPORTED_SYMBOL_AS_VOIDPTR(_bss_start);
EXPORTED_SYMBOL_AS_VOIDPTR(_bss_end);
EXPORTED_SYMBOL_AS_UINTPTR(_kernel_start);
EXPORTED_SYMBOL_AS_UINTPTR(_kernel_end);
EXPORTED_SYMBOL_AS_UINTPTR(initial_tls_end);
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
EXPORTED_SYMBOL_AS_UINTPTR(test_breakpoint);
EXPORTED_SYMBOL_AS_UINTPTR(_kernel_stack);
EXPORTED_SYMBOL_AS_VOIDPTR(irq_dispatch_table);
EXPORTED_SYMBOL_AS_UINTPTR(initial_pml4);
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

void set_print_functions_to_swift();
void early_print_string(const char *text);
void early_print_string_len(const char *text, size_t len);
int kvprintf(const char *fmt, va_list args) __attribute__ ((format (printf, 1, 0)));
int kvsnprintf(char *buf, size_t size, const char *fmt, va_list args) __attribute__ ((format (printf, 3, 0)));
int kvlprintf(const char *fmt, size_t len, va_list args);
void bochs_print_string(const char *str, size_t len);
void dump_registers(struct exception_regs *registers);

int memcmp(const void *s1, const void *s2, size_t count);


static inline uintptr_t
ptr_value(const void *ptr)
{
        return (uintptr_t)ptr;
}

#endif  // __KERNEL_H__
