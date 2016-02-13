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

#define KERNEL_VIRTUAL_BASE       0x40000000UL  // 1GB
#define PHYSICAL_MEM_BASE       0x2000000000UL  // 128GB

#define PAGE_SIZE 4096UL
#define PAGE_MASK 4095UL
#define PAGE_SHIFT 12UL

extern void *(*alloc_pages)(size_t count);
extern void (*free_pages)(void *pages, size_t count);
void *malloc(size_t size);
void free(void *ptr);

#endif  // __MM_H__
