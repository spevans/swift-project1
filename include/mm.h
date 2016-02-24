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

#include <stddef.h>
#include "fbcon.h"
#include "efi.h"

#define KERNEL_VIRTUAL_BASE       0x40100000UL  // 1GB
#define PHYSICAL_MEM_BASE       0x2000000000UL  // 128GB

#define PAGE_SIZE 4096UL
#define PAGE_MASK 4095UL
#define PAGE_SHIFT 12UL


// Structure for boot information passed from BIOS loader to kernel
// Changes must also update boot/memory.asm
struct bios_boot_params {
        char signature[8];      // ASCIIZ string 'BIOS'
        size_t size;            // Size of entire table including embedded data and signature
        void *kernel_phys_addr;
        void *e820_map;
        size_t e820_entries;    // Number of e820 memory map entries
        char data[0];
}  __attribute__((packed));


struct efi_boot_params {
        char signature[8];      // ASCIIZ string 'EFI'
        size_t size;            // Size of entire table including embedded data and signature
        void *kernel_phys_addr;
        void *memory_map;
        size_t memory_map_size;
        size_t memory_map_desc_size;
        struct frame_buffer fb;
        uint64_t nr_efi_config_entries;
        efi_config_table_t *efi_config_table;
}  __attribute__((packed));


extern void *(*alloc_pages)(size_t count);
extern void (*free_pages)(void *pages, size_t count);
void *malloc(size_t size);
void free(void *ptr);

#endif  // __MM_H__
