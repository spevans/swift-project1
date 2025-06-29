/*
 * include/mm.h
 *
 * Created by Simon Evans on 18/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Miscellaneous definitions for memory management
 *
 */

#ifndef __MM_H__
#define __MM_H__

#include <stdint.h>


#define KERNEL_VIRTUAL_BASE     0xffffffff81000000UL    // 2^64 - 2G + 16MB
#ifndef TEST
#define PHYSICAL_MEM_BASE       0xffff800000000000UL    // 128TB
#else
#define PHYSICAL_MEM_BASE       0x0000000000001000UL    // 4K - For testing in userspace
#endif
#define MAX_PHYSICAL_MEMORY     0x20000000000UL         // 2TB Physical RAM

#ifndef TEST    // avoid clashing with "mach/arm/vm_param.h"
#define PAGE_SHIFT 12
#define PAGE_SIZE (1UL << PAGE_SHIFT)
#define PAGE_MASK (~(PAGE_SIZE - 1))
#endif

#define CODE_SELECTOR 0x08
#define DATA_SELECTOR 0x10
#define TSS_SELECTOR  0x20


struct e820_entry {
        uint64_t base_address;
        uint64_t length;
        uint32_t type;
} __attribute__((packed));


// Structure for boot information passed from BIOS loader to kernel
// Changes must also update boot/memory.asm
struct bios_boot_params {
        char signature[8];              // ASCIIZ string 'BIOS'
        size_t table_size;              // Size of entire table including embedded data and signature
        void * _Nonnull kernel_phys_addr;
        void * _Nonnull e820_map;
        size_t e820_entries;            // Number of e820 memory map entries
} __attribute__((packed));


void * _Nullable alloc_pages(size_t count);
void free_pages(void * _Nonnull pages, size_t count);
void * _Nullable malloc(size_t size);
void free(void * _Nullable ptr);
size_t malloc_usable_size (void * _Nullable ptr);

#endif  // __MM_H__
