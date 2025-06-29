/*
 * kernel/init/bss.c
 *
 * Created by Simon Evans on 01/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * BSS declarations for data structures that cant be declared directly
 * in Swift as they require alignment, packing etc. Also C fixed size
 * arrays cant currently be declared either in Swift at the moment
 *
 */

#include "klibc.h"
#include "mm.h"

#define bss_page  __attribute__((__section__(".bss..allocated_pages"))) __attribute__((aligned(PAGE_SIZE)))

// Interrupt Descriptor Table - Swift doesnt support fixed length arrays yet
struct idt_entry idt[NR_INTERRUPTS] bss_page;
// The dispatch table from the IDT stubs to the actual handlers
void (*trap_dispatch_table[NR_TRAPS])(struct exception_regs *);
void (*irq_dispatch_table[NR_IRQS])();

#define PAGE_TABLE_SIZE 4096

uint8_t initial_pml4[PAGE_TABLE_SIZE] bss_page;
uint8_t physmap_pml3[PAGE_TABLE_SIZE] bss_page;
uint8_t kernmap_pml3[PAGE_TABLE_SIZE] bss_page;
uint8_t physmap_pml2[PAGE_TABLE_SIZE] bss_page;
uint8_t kernmap_pml2[PAGE_TABLE_SIZE] bss_page;
uint8_t physmap_pml1[PAGE_TABLE_SIZE][8] bss_page;
uint8_t kernmap_pml1[PAGE_TABLE_SIZE][8] bss_page;


#define EXPORT_SYMBOL_TO_SWIFT(x) const void *x##_addr = &x;

EXPORT_SYMBOL_TO_SWIFT(irq_dispatch_table)
