/*
 * include/x86defs.h
 *
 * Created by Simon Evans on 03/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Header file for x86 specific data structures
 *
 */

#ifndef __X86_DEFS_H__
#define __X86_DEFS_H__

// Descriptor table info used for both GDT and IDT
struct dt_info {
        uint16_t limit;
        void *address;
} __attribute__((packed));


struct idt_entry {
        uint16_t addr_lo;
        uint16_t selector;
        uint8_t unused;
        uint8_t flags;
        uint16_t addr_mid;
        uint32_t addr_hi;
        uint32_t reserved;
} __attribute__((packed));


struct exception_regs {
        uint64_t es;
        uint64_t ds;
        uint64_t rax;
        uint64_t rbx;
        uint64_t rcx;
        uint64_t rdx;
        uint64_t rsi;
        uint64_t rdi;
        uint64_t r8;
        uint64_t r9;
        uint64_t r10;
        uint64_t r11;
        uint64_t r12;
        uint64_t r13;
        uint64_t r14;
        uint64_t r15;
        uint64_t rbp;
        uint64_t fs;
        uint64_t gs;
        uint64_t error_code;
        uint64_t rip;
        uint64_t cs;
        uint64_t eflags;
        uint64_t rsp;
        uint64_t ss;
};


struct cpuid_result {
        union {
                struct {
                        uint32_t eax;
                        uint32_t ebx;
                        uint32_t ecx;
                        uint32_t edx;
                } regs;
                // Used to access the result as a string
                // for functions returning cpu name etc
                char bytes[33];
        } u;
};


// SMBIOS Entry Point structure (EPS)
struct smbios_header {
        char anchor[4];         // '_SM_'
        uint8_t esp_checksum;
        uint8_t ep_length;
        uint8_t major_version;
        uint8_t minor_version;
        uint16_t max_structure_size;
        uint8_t eps_revision;
        uint8_t formatted_area[5];
        char dmi_anchor[5];     // '_DMI_'
        uint8_t intermediate_checksum;
        uint16_t table_length;
        uint32_t table_address;
        uint16_t entry_count;
        uint8_t bcd_revision;
} __attribute__((packed));


// NR_INTERRUPTS is a #define and seems to be mapped to an Int32
#define NR_INTERRUPTS  256L
#define NR_TRAPS 32     // CPU faults and exceptions 0 - 31
#define NR_IRQS 16L     // hardware IRQs
extern struct idt_entry idt[NR_INTERRUPTS];
extern void (*trap_dispatch_table[NR_TRAPS])(struct exception_regs *);

typedef void (*irq_handler)(long irq);
extern irq_handler irq_dispatch_table[];

#endif  // __X86_DEFS_H__
