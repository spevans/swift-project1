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
#include "acpi.h"
#include "swift.h"
#include "x86funcs.h"
#include "mm.h"
#include "efi.h"
#include "usb.h"
#include "io.h"


// Symbols to export as [symbol]_addr
extern const void * _Nonnull _text_start;
extern const void * _Nonnull _text_end;
extern const void * _Nonnull _rodata_start;
extern const void * _Nonnull _rodata_end;
extern const void * _Nonnull _data_start;
extern const void * _Nonnull _data_end;
extern const void * _Nonnull _bss_start;
extern const void * _Nonnull _bss_end;
extern const void * _Nonnull _heap_start;
extern const void * _Nonnull _heap_end;
extern const void * _Nonnull _kernel_start;
extern const void * _Nonnull _kernel_end;
extern const void * _Nonnull _guard_page;
extern const void * _Nonnull _stack_start;
extern const void * _Nonnull _kernel_stack;
extern const void * _Nonnull _ist1_stack_top;
extern const void * _Nonnull initial_pml4;
extern const void * _Nonnull physmap_pml3;
extern const void * _Nonnull physmap_pml2;
extern const void * _Nonnull physmap_pml1;
extern const void * _Nonnull kernmap_pml3;
extern const void * _Nonnull kernmap_pml2;
extern const void * _Nonnull kernmap_pml1;
extern const void * _Nonnull fontdata_8x16;

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
void irq0_stub(void);
void irq1_stub(void);
void irq2_stub(void);
void irq3_stub(void);
void irq4_stub(void);
void irq5_stub(void);
void irq6_stub(void);
void irq7_stub(void);
void irq8_stub(void);
void irq9_stub(void);
void irq10_stub(void);
void irq11_stub(void);
void irq12_stub(void);
void irq13_stub(void);
void irq14_stub(void);
void irq15_stub(void);
void irq16_stub(void);
void irq17_stub(void);
void irq18_stub(void);
void irq19_stub(void);
void irq20_stub(void);
void irq21_stub(void);
void irq22_stub(void);
void irq23_stub(void);
void irq24_stub(void);
void irq25_stub(void);
void irq26_stub(void);
void irq27_stub(void);
void irq28_stub(void);
void irq29_stub(void);
void irq30_stub(void);
void irq31_stub(void);
void irq32_stub(void);
void irq33_stub(void);
void irq34_stub(void);
void irq35_stub(void);
void irq36_stub(void);
void irq37_stub(void);
void irq38_stub(void);
void irq39_stub(void);
void irq40_stub(void);
void irq41_stub(void);
void irq42_stub(void);
void irq43_stub(void);
void irq44_stub(void);
void irq45_stub(void);
void irq46_stub(void);
void irq47_stub(void);
void irq48_stub(void);
void irq49_stub(void);
void irq50_stub(void);
void irq51_stub(void);
void irq52_stub(void);
void irq53_stub(void);
void irq54_stub(void);
void irq55_stub(void);
void irq56_stub(void);
void irq57_stub(void);
void irq58_stub(void);
void irq59_stub(void);
void irq60_stub(void);
void irq61_stub(void);
void irq62_stub(void);
void irq63_stub(void);
void irq64_stub(void);
void irq65_stub(void);
void irq66_stub(void);
void irq67_stub(void);
void irq68_stub(void);
void irq69_stub(void);
void irq70_stub(void);
void irq71_stub(void);
void irq72_stub(void);
void irq73_stub(void);
void irq74_stub(void);
void irq75_stub(void);
void irq76_stub(void);
void irq77_stub(void);
void irq78_stub(void);
void irq79_stub(void);
void irq80_stub(void);
void irq81_stub(void);
void irq82_stub(void);
void irq83_stub(void);
void irq84_stub(void);
void irq85_stub(void);
void irq86_stub(void);
void irq87_stub(void);

void apic_int0_stub(void);
void apic_int1_stub(void);
void apic_int2_stub(void);
void apic_int3_stub(void);
void apic_int4_stub(void);
void apic_int5_stub(void);
void apic_int6_stub(void);

// kprintf
int kvlprintf(const char * _Nonnull fmt, size_t len, va_list args);
int kprintf1arg(const char * _Nonnull fmt, long l1);
int kprintf2args(const char * _Nonnull fmt, long l1, long l2);
int kprintf3args(const char * _Nonnull fmt, long l1, long l2, long l3);

// klibc
void abort(void);
void debugger_hook(void);
void stack_trace(uintptr_t rsp, uintptr_t rbp);
void dump_registers(struct exception_regs * _Nonnull registers);
int memcmp(const void * _Null_unspecified s1, const void * _Null_unspecified s2, size_t count);
void serial_print_char(const char ch);

// kernel/traps/entry.asm
unsigned int read_int_nest_count(void);
void run_first_task(void);
void set_interrupt_manager(const void * _Nonnull im);

// early_tty interface for TTY.EarlyTTY driver
typedef uint16_t text_coord;
extern void (* _Nonnull etty_print_char)(text_coord x, text_coord y, const unsigned char ch);
extern void (* _Nonnull etty_clear_screen)(void);
extern void (* _Nonnull etty_scroll_up)(void);
text_coord etty_chars_per_line(void);
text_coord etty_total_lines(void);
text_coord etty_get_cursor_x(void);
text_coord etty_get_cursor_y(void);
void etty_set_cursor_x(text_coord x);
void etty_set_cursor_y(text_coord y);
void early_print_string_len(const char * _Nonnull text, size_t len);

// timer.asm
uint64_t current_ticks(void);
void timer_callback(void);
void sleep_in_milliseconds(uint64_t);

uint64_t _cacheReadTest(uint8_t * _Nullable p, uint64_t count, uint8_t * _Nullable result);
uint64_t _cacheWriteTest(uint8_t * _Nullable p, uint64_t count, uint8_t data);
#endif  // __KERNEL_H__
