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

#define KERNEL_VIRTUAL_BASE     0xffffffff80100000UL    // 1GB
#define PHYSICAL_MEM_BASE       0xffff800000000000UL    // 128TB
#define MAX_PHYSICAL_MEMORY     0x1000000000UL          // 64GB Physical RAM
#define TLS_END_ADDR            0x1FF8UL

#define PAGE_SIZE 4096UL
#define PAGE_MASK 4095UL
#define PAGE_SHIFT 12UL

#define CODE_SELECTOR 0x08
#define DATA_SELECTOR 0x10
#define TLS_SELECTOR  0x18
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


struct efi_boot_params {
        char signature[8];      // ASCIIZ string 'EFI'
        size_t size;            // Size of entire table including embedded data and signature
        void * _Nonnull kernel_phys_addr;
        void * _Nonnull memory_map;
        uint64_t memory_map_size;
        uint64_t memory_map_desc_size;
        struct frame_buffer fb;
        uint64_t nr_efi_config_entries;
        const efi_config_table_t * _Nonnull efi_config_table;
        const Elf64_Sym * _Nonnull symbol_table;
        uint64_t symbol_table_size;
        const char * _Nonnull string_table;
        uint64_t string_table_size;
}  __attribute__((packed));


// Used by dladdr()
typedef struct {
    const char * _Nullable dli_fname;        /* File name of defining object.  */
    void * _Nullable dli_fbase;              /* Load address of that object.  */
    const char * _Nullable dli_sname;        /* Name of nearest symbol.  */
    void * _Nullable dli_saddr;              /* Exact value of nearest symbol.  */
} Dl_info;


int dladdr(void * _Nullable addr, Dl_info * _Nonnull info);
void * _Nullable alloc_pages(size_t count);
void free_pages(void * _Nonnull pages, size_t count);
void * _Nullable malloc(size_t size);
void free(void * _Nullable ptr);
size_t malloc_usable_size (const void * _Nonnull ptr);

#endif  // __MM_H__
