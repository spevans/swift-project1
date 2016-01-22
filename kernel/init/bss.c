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

// This is a hardcoded tls section so the TLS selector can be setup early. Should really be sized to the
// .tbss + .tdata sections but this is more than is needed for now
uint64_t initial_tls[8];
const void *initial_tls_end_addr = &initial_tls[7];

// Interrupt Descriptor Table - Swift doesnt support fixed length arrays yet
struct idt_entry idt[NR_INTERRUPTS]  __attribute__((aligned(PAGE_SIZE)));
// The dispatch table from the IDT stubs to the actual handlers
void (*trap_dispatch_table[NR_TRAPS])(struct exception_regs *);
void (*irq_dispatch_table[NR_IRQS])();

uint8_t initial_pml4[PAGE_SIZE] bss_page;
uint8_t initial_page_tables[10][PAGE_SIZE] bss_page;


#define EXPORT_SYMBOL_TO_SWIFT(x) const void *x##_addr = &x;

EXPORT_SYMBOL_TO_SWIFT(irq_dispatch_table)
EXPORT_SYMBOL_TO_SWIFT(initial_pml4)
EXPORT_SYMBOL_TO_SWIFT(initial_page_tables)
