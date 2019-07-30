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
#include "swift.h"

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
EXPORTED_SYMBOL_AS_UINTPTR(_heap_start);
EXPORTED_SYMBOL_AS_UINTPTR(_heap_end);
EXPORTED_SYMBOL_AS_UINTPTR(_kernel_start);
EXPORTED_SYMBOL_AS_UINTPTR(_kernel_end);
EXPORTED_SYMBOL_AS_UINTPTR(_guard_page);
EXPORTED_SYMBOL_AS_UINTPTR(_stack_start);
EXPORTED_SYMBOL_AS_UINTPTR(_ist1_stack_top);
EXPORTED_SYMBOL_AS_UINTPTR(initial_pml4);
EXPORTED_SYMBOL_AS_UINTPTR(fontdata_8x16);

extern struct task_state_segment task_state_segment;

// Exception and trap handler entry stubs
void divide_by_zero_stub(void);
void debug_exception_stub(void);
void nmi_stub(void);
void single_step_stub(void);
void overflow_stub(void);
void bounds_stub(void);
void invalid_opcode_stub(void);
void unused_stub(void);
void double_fault_stub(void);
void invalid_tss_stub(void);
void seg_not_present_stub(void);
void stack_fault_stub(void);
void gpf_stub(void);
void page_fault_stub(void);
void fpu_fault_stub(void);
void alignment_exception_stub(void);
void mce_stub(void);
void simd_exception_stub(void);
void irq00_stub(void);
void irq01_stub(void);
void irq02_stub(void);
void irq03_stub(void);
void irq04_stub(void);
void irq05_stub(void);
void irq06_stub(void);
void irq07_stub(void);
void irq08_stub(void);
void irq09_stub(void);
void irq10_stub(void);
void irq11_stub(void);
void irq12_stub(void);
void irq13_stub(void);
void irq14_stub(void);
void irq15_stub(void);
void apic_int0_stub(void);
void apic_int1_stub(void);
void apic_int2_stub(void);
void apic_int3_stub(void);
void apic_int4_stub(void);
void apic_int5_stub(void);
void apic_int6_stub(void);

#endif  // __KERNEL_H__
