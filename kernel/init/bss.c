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

#include "kernel.h"
#include "klibc.h"

// Interrupt Descriptor Table - Swift doesnt support fixed length arrays yet
struct idt_entry idt[NR_TRAPS]  __attribute__((aligned(PAGE_SIZE)));
// The dispatch table from the IDT stubs to the actual handlers
void (*trap_dispatch_table[NR_TRAPS])(struct exception_regs *);

