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

// Export as [symbol]_addr as a unitptr_t to be manipulated as a UInt
#define EXPORTED_SYMBOL_AS_UINTPTR(x)               \
extern const void * _Nonnull x;                     \
__attribute__((section("/DISCARD/")))               \
static const uintptr_t x##_addr = (uintptr_t)&x;


// Symbols to export as [symbol]_addr
EXPORTED_SYMBOL_AS_UINTPTR(_text_start);
EXPORTED_SYMBOL_AS_UINTPTR(_text_end);
EXPORTED_SYMBOL_AS_UINTPTR(_rodata_start);
EXPORTED_SYMBOL_AS_UINTPTR(_rodata_end);
EXPORTED_SYMBOL_AS_UINTPTR(_data_start);
EXPORTED_SYMBOL_AS_UINTPTR(_data_end);
EXPORTED_SYMBOL_AS_UINTPTR(_bss_start);
EXPORTED_SYMBOL_AS_UINTPTR(_bss_end);
EXPORTED_SYMBOL_AS_UINTPTR(_kernel_start);
EXPORTED_SYMBOL_AS_UINTPTR(_kernel_end);
EXPORTED_SYMBOL_AS_UINTPTR(_guard_page);
EXPORTED_SYMBOL_AS_UINTPTR(_stack_start);
EXPORTED_SYMBOL_AS_UINTPTR(_ist1_stack_top);
EXPORTED_SYMBOL_AS_UINTPTR(initial_pml4);
EXPORTED_SYMBOL_AS_UINTPTR(fontdata_8x16);

extern void * _Nonnull const initial_tls_end_addr;

// kernel/traps/entry.asm
void run_first_task();

// Exception and trap handler entry stubs
void divide_by_zero_stub();
void debug_exception_stub();
void nmi_stub();
void single_step_stub();
void overflow_stub();
void bounds_stub();
void invalid_opcode_stub();
void unused_stub();
void double_fault_stub();
void invalid_tss_stub();
void seg_not_present_stub();
void stack_fault_stub();
void gpf_stub();
void page_fault_stub();
void fpu_fault_stub();
void alignment_exception_stub();
void mce_stub();
void simd_exception_stub();
void irq00_stub();
void irq01_stub();
void irq02_stub();
void irq03_stub();
void irq04_stub();
void irq05_stub();
void irq06_stub();
void irq07_stub();
void irq08_stub();
void irq09_stub();
void irq10_stub();
void irq11_stub();
void irq12_stub();
void irq13_stub();
void irq14_stub();
void irq15_stub();
void apic_int0_stub();
void apic_int1_stub();
void apic_int2_stub();
void apic_int3_stub();
void apic_int4_stub();
void apic_int5_stub();
void apic_int6_stub();
#endif  // __KERNEL_H__
